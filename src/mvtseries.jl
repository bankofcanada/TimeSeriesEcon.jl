# Copyright (c) 2020-2024, Bank of Canada
# All rights reserved.

using OrderedCollections

# -------------------------------------------------------------------------------
# MVTSeries -- multivariate TSeries
# -------------------------------------------------------------------------------

"""
    mutable struct MVTSeries{F,T,C} <: AbstractMatrix{T}
        firstdate::MIT{F}
        columns::OrderedDict{Symbol,TSeries{F,T}}
        values::C
    end

Multi-variate Time series with frequency `F` with values of type `T` stored in a
container of type `C`. By default the type is `Float64` and the container is
`Matrix{Float64}`. The rows correspond to moments in time and the columns
correspond to variables. Columns are named. The values in the field `columns`
are `TSeries` whose storages are views into the corresponding columns of the
`values` matrix.

### Construction:
    x = MVTSeries(args...)

The standard construction is
```MVTSeries(firstdate::MIT, names, values)```
Here `names` should be a tuple of `Symbol`s and `values` should be a matrix
of the same number of columns as there are names in `names`. The range of
the `MVTSeries` is determined from the number of rows of `values`. If
`values` is not provided, the `MVTSeries` is constructed empty with size
`(0, length(names))``. If `names` is also not provided, the `MVTSeries` is
constructed empty with size `(0, 0)`.

The first argument can be a range.
```MVTSeries(range::AbstractUnitRange{<:MIT}, names, values)``` 
In this case the size of the `MVTSeries` is determined by the lengths of
`range` and `names`; the `values` argument is interpreted as an initializer.
If it is omitted or set to `undef`, the storage is left uninitialized. If it
is a number, the storage is filled with it. It can also be an initializer
function, such as `zeros`, `ones` or `rand`. Lastly, if the `values`
argument is an array, it must be 2-dimensional and of the correct size.

Another possibility is to construct from a collection of name-value pairs.
```MVTSeries(range; var1 = val1, var2 = val2, ...)```
The `range` argument is optional, if missing it'll be determined from the
ranges of the given values. The values can be [`TSeries`](@ref), vectors or
constants. Any vector must have the same length as the range.

An `MVTSeries` can also be constructed with `copy`, `similar`, and `fill`.

### Indexing:
Indexing with integers, integer ranges, or boolean arrays works the same as
with `Matrix`. The result from slicing with integer ranges or boolean arrays
is always a `Matrix`, i.e., the `MVTSeries` structure is lost.

Indexing with two indexes works as follows. The first index can be an
[`MIT`](@ref) or a range of [`MIT`](@ref) and it works the same as for  
[`TSeries`](@ref). The second index can be a `Symbol` or a collection of
`Symbol`s, such as a tuple or a vector. `begin` and `end` work for the
first index the same as with [`TSeries`](@ref).

Indexing with one index depends on the type. If it is `MIT` or a 
range of `MIT`, it is treated as if the second index were `:`, i.e., the 
entire row or multiple rows is returned. If the index is a `Symbol` or 
a collection of `Symbol`s, it is treated as if the first index were `:`, 
i.e., entire column or multiple columns is returned as [`TSeries`](@ref) or
`MVTSeries` respectively.

Columns can also be accessed using "dot" notation. For example `x[:a]` is the
same as `x.a`.

Check out the tutorial at 
[https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/TimeSeriesEcon/main/](https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/TimeSeriesEcon/main/)
"""
mutable struct MVTSeries{F<:Frequency,T<:Number,C<:AbstractMatrix{T}} <: AbstractMatrix{T}
    firstdate::MIT{F}
    columns::OrderedDict{Symbol,TSeries{F,T}}
    values::C

    # inner constructor enforces constraints
    function MVTSeries(firstdate::MIT{F}, names::Vector{Symbol}, values::AbstractMatrix) where {F<:Frequency}
        N = length(names)
        if N != size(values, 2)
            ArgumentError("Number of names and columns don't match:" *
                          " $N ≠ $(size(values, 2)).") |> throw
        end
        columns = OrderedDict(nm => TSeries(firstdate, view(values, :, ind))
                              for (nm, ind) in zip(names, axes(values, 2)))
        new{sanitize_frequency(F),eltype(values),typeof(values)}(firstdate, columns, values)
    end
end

_names_as_vec(names::Symbol) = Symbol[names,]
_names_as_vec(names::AbstractString) = Symbol[Symbol(names),]
_names_as_vec(names) = Symbol[Symbol(n) for n in names]


# standard constructor with default empty values
@inline MVTSeries(fd::MIT, names=()) = (names = _names_as_vec(names); MVTSeries(fd, names, zeros(0, length(names))))
@inline MVTSeries(fd::MIT, names::Union{AbstractVector,Tuple,Base.KeySet{Symbol,<:OrderedDict},Base.Generator}, data::AbstractMatrix) = begin
    names = _names_as_vec(names)
    MVTSeries(fd, names, data)
end

# MVTSeries(fd::MIT, names, data::MVTSeries) = begin
#     names = _names_as_tuple(names)
#     firstdate(data) == fd && colnames(data) == names ? data :
#         throw(ArgumentError("Failed to construct MVTSeries with $((fd, names)) from $(axes(data))"))
# end

# see more constructors below

# easy access to internals. 
_vals(x::MVTSeries) = getfield(x, :values)
_cols(x::MVTSeries) = getfield(x, :columns)
function _col(x::MVTSeries, col::Symbol)
    ret = get(getfield(x, :columns), col, nothing)
    @boundscheck (ret === nothing && Base.throw_boundserror(x, [col,]))
    return ret
end


"""
    cleanedvalues(t::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}} = nothing)

    Returns a matrix of values of a BDaily MVTSeries filtered according to the provided optional arguments. 
    By default, all values are returned.

    Optional arguments:
    * `skip_all_nans` : When `true`, returns all rows for which none of the values are NaN. Displays a warning if rows are removed where some of the values are not Nan. Default is `false`.
    * `skip_holidays` : When `true`, returns all rows which do not fall on a holiday according to the holidays map set in TimeSeriesEcon.getoption(:bdaily_holidays_map). Default: `false`.
    * `holidays_map`  : Returns all rows that do not fall on a holiday according to the provided map which must be a BDaily TSeries of Booleans. Default is `nothing`.
"""
function cleanedvalues(mvts::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing)
    if holidays_map !== nothing
        return bdvalues(mvts, holidays_map=holidays_map)
    elseif skip_all_nans
        valid_rows_matrix = nans_map(mvts.values)
        if any(isnan.(mvts.values[valid_rows_matrix[:, 1], :]))
            @warn "NaNs unequal across columns. Rows with some valid values removed."
        end
        return mvts.values[valid_rows_matrix[:, 2], :]
    elseif skip_holidays
        h_map = TimeSeriesEcon.getoption(:bdaily_holidays_map)
        if !(h_map isa TSeries{BDaily})
            throw(ArgumentError("The holidays map stored in :bdaily_holidays_map is not a TSeries it is a $(typeof(h_map)). \n You may need to load one with TimeSeriesEcon.set_holidays_map()."))
        end
        return bdvalues(mvts, holidays_map=h_map)
    end
    return mvts.values
end

# creates a two-column Boolean Matrix.
# The first column is true whenever any of the series for the given MIT/row is not NaN.
# The second column is true whenever all of the series for the given MIT/row are not NaN.

function nans_map(x)
    nrows = length(x[:, 1])
    m = Matrix{Bool}(undef, (nrows, 2))
    for i in 1:nrows
        m[i, :] = [!all(isnan.(x[i, :])), !any(isnan.(x[i, :]))]
    end
    return m
end

function bdvalues(mvts::MVTSeries{BDaily}; holidays_map=nothing)
    if holidays_map === nothing
        return mvts.values
    end
    if !(holidays_map isa TSeries{BDaily})
        throw(ArgumentError("Passed holidays_map must be a TSeries{BDaily}"))
    end
    @boundscheck checkbounds(holidays_map, first(rangeof(mvts)))
    @boundscheck checkbounds(holidays_map, last(rangeof(mvts)))
    slice = holidays_map[rangeof(mvts)]
    return mvts.values[slice.values, :]
end


"""
    columns(x::MVTSeries)

Return the columns of `x` as a dictionary. 
"""
columns(x::MVTSeries) = getfield(x, :columns)

"""
    colnames(x::MVTSeries)

Return the names of the columns of `x` as an iterable.
"""
colnames(x::MVTSeries) = keys(_cols(x))
rawdata(x::MVTSeries) = _vals(x)

# some methods to make MVTSeries function like a Dict (collection of named of columns)
# Base.pairs(x::MVTSeries) = pairs(_cols(x))
"""
    pairs(data::MVTSeries; copy = false)

Returns an iterator over the named columns of `data`. Each iteration gives a
name-value pair where name is a `Symbol` and value is a [`TSeries`](@ref).

Setting `copy=true` is equivalent to `pairs(copy(data))` but slightly more
efficient.
"""
Base.pairs(x::MVTSeries; copy=false) = copy ? pairs(deepcopy(_cols(x))) : pairs(_cols(x))
Base.keys(x::MVTSeries) = keys(_cols(x))
Base.haskey(x::MVTSeries, sym::Symbol) = haskey(_cols(x), sym)
Base.get(x::MVTSeries, sym::Symbol, default) = get(_cols(x), sym, default)
Base.get(f::Function, x::MVTSeries, sym::Symbol) = get(f, _cols(x), sym)
# no get!() - can't add columns like this!!

# methods related to TSeries 
firstdate(x::MVTSeries) = getfield(x, :firstdate)
lastdate(x::MVTSeries) = firstdate(x) + size(_vals(x), 1) - one(firstdate(x))
frequencyof(::Type{<:MVTSeries{F}}) where {F<:Frequency} = F
rangeof(x::MVTSeries) = firstdate(x) .+ (0:size(_vals(x), 1)-1)
_to_unitrange(x::MVTSeries) = rangeof(x)

# -------------------------------------------------------------------------------
# Make MVTSeries work properly as an AbstractArray


Base.size(x::MVTSeries) = size(_vals(x))
Base.axes(x::MVTSeries) = (rangeof(x), [colnames(x)...])
Base.axes1(x::MVTSeries) = rangeof(x)

const _MVTSAxes1 = AbstractUnitRange{<:MIT}
const _MVTSAxes2 = Union{NTuple{N,Symbol},Vector{Symbol}} where {N}
const _MVTSAxesType = Tuple{<:_MVTSAxes1,<:_MVTSAxes2}

# the following are needed for copy() and copyto!() (and a bunch of Julia internals that use them)
Base.IndexStyle(x::MVTSeries) = IndexStyle(_vals(x))
Base.dataids(x::MVTSeries) = Base.dataids(_vals(x))

Base.eachindex(x::MVTSeries) = eachindex(_vals(x))

"""
    similar(t::MVTSeries, [eltype], [shape])
    similar(array, [eltype], shape)
    similar(array_type, [eltype], shape)

Create an uninitialized [`MVTSeries`](@ref) with the given element type and `shape`.

If the first argument is an [`MVTSeries`](@ref) then the element type and shape
of the output will match those of the input, unless they are explicitly given in
subsequent arguments. If the first argument is another array or an array type,
then `shape` must be given in the form of a tuple where the first element is an
MIT range and the second is a list of column names. The element type, `eltype`,
also can be given optionally; if not given it will be deduced from the first
argument.

Example: 
```
similar(Array{Float64}, (2000Q1:2001Q4, (:a, :b)))
```

"""
Base.similar(x::MVTSeries) = MVTSeries(firstdate(x), colnames(x), similar(_vals(x)))
Base.similar(x::MVTSeries, ::Type{T}) where {T} = MVTSeries(firstdate(x), colnames(x), similar(_vals(x), T))

# -------------------------------------------------------------------------------

Base.hash(x::MVTSeries, h::UInt) = hash((_vals(x), firstdate(x), colnames(x)...), h)

# -------------------------------------------------------------------------------
# Indexing with integers and booleans - same as matrices

_vals(a) = a

# Indexing with integers falls back to AbstractArray
const _FallbackType = Union{Base.BitInteger,Colon,AbstractArray{<:Base.BitInteger},CartesianIndex,AbstractArray{<:CartesianIndex},AbstractArray{Bool}}
Base.getindex(sd::MVTSeries, i1::_FallbackType...) = getindex(_vals(sd), _vals.(i1)...)
Base.setindex!(sd::MVTSeries, val, i1::_FallbackType...) = setindex!(_vals(sd), val, _vals.(i1)...)

Base.getindex(x::MVTSeries, ::Colon, ::Colon) = x

# -------------------------------------------------------------
# Some other constructors
# -------------------------------------------------------------


# Empty from a list of variables and of specified type (first date must also be given, Frequency is not enough)
# @inline MVTSeries(fd::MIT, vars) = MVTSeries(Float64, fd, vars)
MVTSeries(T::Type{<:Number}, fd::MIT, vars) = MVTSeries(fd, vars, Matrix{T}(undef, 0, length(vars)))

# Uninitialized from a range and list of variables
MVTSeries(rng::AbstractUnitRange{<:MIT}, vars) = MVTSeries(Float64, rng, vars, undef)
MVTSeries(rng::AbstractUnitRange{<:MIT}, vars, ::UndefInitializer) = MVTSeries(Float64, rng, vars, undef)
MVTSeries(T::Type{<:Number}, rng::AbstractUnitRange{<:MIT}, vars) = MVTSeries(T, rng, vars, undef)
MVTSeries(T::Type{<:Number}, rng::AbstractUnitRange{<:MIT}, vars, ::UndefInitializer) =
    MVTSeries(first(rng), vars, Matrix{T}(undef, length(rng), length(vars)))
MVTSeries(T::Type{<:Number}, rng::AbstractUnitRange{<:MIT}, vars::Symbol, ::UndefInitializer) =
    MVTSeries(first(rng), (vars,), Matrix{T}(undef, length(rng), 1))

# initialize with a function like zeros, ones, rand.
MVTSeries(rng::AbstractUnitRange{<:MIT}, vars, init::Function) = MVTSeries(first(rng), vars, init(length(rng), length(vars)))
# no type-explicit version because the type is determined by the output of init()

# initialize with a constant
MVTSeries(rng::AbstractUnitRange{<:MIT}, vars, v::Number) = MVTSeries(first(rng), vars, fill(v, length(rng), length(vars)))

# initialize all columns with a given TSeries
function MVTSeries(rng::AbstractUnitRange{<:MIT}, vars, v::TSeries)
    ret = MVTSeries(rng, vars)
    for (_, col) in pairs(ret)
        copyto!(col, rng, v)
    end
    return ret
end

function Base.fill(v::TSeries, vars)
    return MVTSeries(rangeof(v), vars, v)
end

# construct with a given range (rather than only the first date). We must check the range length matches the data size 1
function MVTSeries(rng::AbstractUnitRange{<:MIT}, vars, vals::AbstractMatrix{<:Number})
    lrng = length(rng)
    lvrs = length(vars)
    nrow, ncol = size(vals)
    if lrng != nrow || lvrs != ncol
        throw(ArgumentError("Number of periods and variables do not match size of data." *
                            " ($(lrng)×$(lvrs)) ≠ ($(nrow)×$(ncol))"
        ))
    end
    return MVTSeries(first(rng), vars, vals)
end

# construct if data is given as a vector (it must be exactly 1 variable)
MVTSeries(fd::MIT, vars, data::AbstractVector) = MVTSeries(fd, vars, reshape(data, :, 1))
MVTSeries(fd::MIT, vars::Union{Symbol,AbstractString}, data::AbstractVector) = MVTSeries(fd, (vars,), reshape(data, :, 1))
MVTSeries(rng::AbstractUnitRange{<:MIT}, vars, data::AbstractVector) = MVTSeries(rng, vars, reshape(data, :, 1))
MVTSeries(rng::AbstractUnitRange{<:MIT}, vars::Union{Symbol,AbstractString}, data::AbstractVector) = MVTSeries(rng, (vars,), reshape(data, :, 1))

# construct uninitialized by way of calling similar 
Base.similar(::Type{<:AbstractArray}, T::Type{<:Number}, shape::_MVTSAxesType) = MVTSeries(T, shape[1], shape[2])
Base.similar(::Type{<:AbstractArray{T}}, shape::_MVTSAxesType) where {T<:Number} = MVTSeries(T, shape[1], shape[2])
Base.similar(::AbstractArray, T::Type{<:Number}, shape::_MVTSAxesType) = MVTSeries(T, shape[1], shape[2])
Base.similar(::AbstractArray{T}, shape::_MVTSAxesType) where {T<:Number} = MVTSeries(T, shape[1], shape[2])

# construct from range and fill with the given constant or array
"""
    fill(val, range)
    fill(val, range, variables)

In the first form create a [`TSeries`](@ref) with the given range. In the second
form create an [`MVTSeries`](@ref) with the given range and variables. In both
cases they are filled with the given value `val`.
"""
Base.fill(v, rng::_MVTSAxes1, vars::_MVTSAxes2) = MVTSeries(first(rng), vars, fill(v, length(rng), length(vars)))
Base.fill(v, shape::_MVTSAxesType) = fill(v, shape...)

# Empty (0 variables) from range
function MVTSeries(rng::AbstractUnitRange{<:MIT}; args...)
    isempty(args) && return MVTSeries(rng, ())
    # figure out the element type
    ET = Base.promote_eltype(values(args)...)
    MVTSeries(ET, rng; args...)
end

function MVTSeries(; args...)
    return MVTSeries(rangeof_span(values(args)...); args...)
end

# construct from a collection of TSeries
function MVTSeries(ET::Type{<:Number}, rng::AbstractUnitRange{<:MIT}; args...)
    isempty(args) && return MVTSeries(1U)
    # allocate memory
    ret = MVTSeries(rng, keys(args), typenan(ET))
    # copy data
    for (key, value) in args
        ret[:, key] .= value
    end
    return ret
end

# -------------------------------------------------------------------------------
# Dot access to columns

Base.propertynames(x::MVTSeries) = tuple(colnames(x)...)

function Base.getproperty(x::MVTSeries, col::Symbol)
    col ∈ fieldnames(typeof(x)) && return getfield(x, col)
    return _col(x, col)
end

function Base.setproperty!(x::MVTSeries, name::Symbol, val)
    name ∈ fieldnames(typeof(x)) && return setfield!(x, name, val)
    col = try
        _col(x, name)
    catch e
        if e isa BoundsError
            error("Cannot append new column this way.\n" *
                  "\tUse hcat(x; $name = value) or push!(x; $name = value).")
        else
            rethrow(e)
        end
    end
    ####  Do we need this mightalias check here? I think it's done in copyto!() so we should be safe without it.
    # if Base.mightalias(col, val)
    #     val = copy(val)
    # end
    if val isa TSeries
        rng = intersect(rangeof(col), rangeof(val))
        return copyto!(col, rng, val)
    elseif val isa Number
        return fill!(col.values, val)
    elseif val isa MVTSeries
        vcol = _col(val, name)
        rng = intersect(rangeof(col), rangeof(vcol))
        return copyto!(col, rng, vcol)
    else
        return col.values[:] = val
    end
end

# -------------------------------------------------------------------------------
# Indexing other than integers 

# some check bounds that plug MVTSeries into the Julia infrastructure for AbstractArrays
Base.checkbounds(::Type{Bool}, x::MVTSeries, p::MIT) = checkindex(Bool, rangeof(x), p)
Base.checkbounds(::Type{Bool}, x::MVTSeries, p::AbstractVector{<:MIT}) = checkindex(Bool, rangeof(x), p)
Base.checkbounds(::Type{Bool}, x::MVTSeries, c::Symbol) = haskey(_cols(x), c)
@inline function Base.checkbounds(::Type{Bool}, x::MVTSeries, INDS::_MVTSAxes2)
    cols = _cols(x)
    for c in INDS
        haskey(cols, c) || return false
    end
    return true
end

function Base.checkbounds(::Type{Bool}, x::MVTSeries, p::Union{MIT,<:AbstractVector{<:MIT}}, c::Union{Symbol,_MVTSAxes2})
    return checkbounds(Bool, x, p) && checkbounds(Bool, x, c)
end

# ---- single argument access

# single argument - MIT point - return the row as a vector (slice of .values)
Base.getindex(x::MVTSeries, p::MIT) = mixed_freq_error(x, p)
@inline function Base.getindex(x::MVTSeries{F}, p::MIT{F}) where {F<:Frequency}
    getindex(_vals(x), _ts_values_inds(x, p), :)
end

Base.setindex!(x::MVTSeries, val, p::MIT) = mixed_freq_error(x, p)
@inline function Base.setindex!(x::MVTSeries{F}, val, p::MIT{F}) where {F<:Frequency}
    setindex!(_vals(x), val, _ts_values_inds(x, p), :)
end

# single argument - MIT range
Base.getindex(x::MVTSeries, rng::AbstractVector{<:MIT}) = mixed_freq_error(x, rng)
@inline function Base.getindex(x::MVTSeries{F}, rng::AbstractUnitRange{MIT{F}}) where {F<:Frequency}
    return MVTSeries(first(rng), axes(x, 2), getindex(_vals(x), _ts_values_inds(x, rng), :))
end
@inline function Base.getindex(x::MVTSeries{F}, rng::AbstractVector{MIT{F}}) where {F<:Frequency}
    getindex(_vals(x), _ts_values_inds(x, rng), :)
end

Base.setindex!(x::MVTSeries, val, rng::AbstractVector{<:MIT}) = mixed_freq_error(x, rng)
@inline function Base.setindex!(x::MVTSeries{F}, val, rng::AbstractVector{MIT{F}}) where {F<:Frequency}
    setindex!(_vals(x), val, _ts_values_inds(x, rng), :)
end

# single argument - variable - return a TSeries of the column
Base.getindex(x::MVTSeries, col::AbstractString) = _col(x, Symbol(col))
Base.getindex(x::MVTSeries, col::Symbol) = _col(x, col)

Base.setindex!(x::MVTSeries, val, col::AbstractString) = setindex!(x, val, Symbol(col))
function Base.setindex!(x::MVTSeries, val, col::Symbol)
    setproperty!(x, col, val)
end

# single argument - list/tuple of variables - return a TSeries of the column
@inline function Base.getindex(x::MVTSeries, cols::_MVTSAxes2)
    inds = _colind(x, cols)
    return MVTSeries(firstdate(x), cols, getindex(_vals(x), :, inds))
end

@inline function Base.setindex!(x::MVTSeries, val, cols::_MVTSAxes2)
    inds = _colind(x, cols)
    setindex!(x.values, val, :, inds)
end

@inline function Base.setindex!(x::MVTSeries, val::MVTSeries, cols::_MVTSAxes2)
    colinds = _colind(x, cols)
    rng = intersect(rangeof(x), rangeof(val))
    setindex!(x.values, view(val, rng, cols), _ts_values_inds(x, rng), colinds)
end

# ---- two arguments indexing

const _SymbolOneOrCollection = Union{Symbol,_MVTSAxes2}
const _MITOneOrVector{F} = Union{MIT{F},<:AbstractVector{MIT{F}}}

Base.getindex(x::MVTSeries, p::_MITOneOrVector, ::_SymbolOneOrCollection) = mixed_freq_error(x, p)
Base.setindex!(x::MVTSeries, val, p::_MITOneOrVector, ::_SymbolOneOrCollection) = mixed_freq_error(x, p)

# if one argument is Colon, fall back on single argument indexing
Base.getindex(x::MVTSeries{F}, p::_MITOneOrVector{F}, ::Colon) where {F<:Frequency} = getindex(x, p)
Base.getindex(x::MVTSeries, ::Colon, c::_SymbolOneOrCollection) = getindex(x, c)

Base.setindex!(x::MVTSeries{F}, val, p::_MITOneOrVector{F}, ::Colon) where {F<:Frequency} = setindex!(x, val, p)
Base.setindex!(x::MVTSeries, val, ::Colon, c::_SymbolOneOrCollection) = setindex!(x, val, c)

# 

# the index is stored as the second index in the view() object which is the
# values of the TSeries of the column. See the inner constructor of MVTSeries.
_colind(x, c::Symbol) = _col(x, c).values.indices[2]
_colind(x, cols::Union{Tuple,AbstractVector}) = Int[_colind(x, Symbol(c)) for c in cols]

_mvts_access(access::Function, x::MVTSeries, ::_MITOneOrVector, ::_SymbolOneOrCollection, i1, i2) = access(_vals(x), i1, i2)
# with an MIT unit-range and a Symbol (single column) we return a TSeries
_mvts_access(access::Function, x::MVTSeries, p::AbstractUnitRange{<:MIT}, ::Symbol, i1, i2) = TSeries(first(p), access(_vals(x), i1, i2))
# with an MIT range and a sequence of Symbol-s we return an MVTSeries
_mvts_access(access::Function, x::MVTSeries, p::AbstractUnitRange{<:MIT}, ::_MVTSAxes2, i1, i2) = MVTSeries(first(p), axes(x, 2)[i2], access(_vals(x), i1, i2))

@inline function Base.getindex(x::MVTSeries{F}, p::_MITOneOrVector{F}, c::_SymbolOneOrCollection) where {F<:Frequency}
    i1 = _ts_values_inds(x, p)
    i2 = _colind(x, c)
    _mvts_access(getindex, x, p, c, i1, i2)
end

# assignments

# with a single MIT we assign a number or a row-Vector
@inline function Base.setindex!(x::MVTSeries{F}, val, p::_MITOneOrVector{F}, c::_SymbolOneOrCollection) where {F<:Frequency}
    i1 = _ts_values_inds(x, p)
    i2 = _colind(x, c)
    setindex!(_vals(x), val, i1, i2)
end

@inline function Base.setindex!(x::MVTSeries{F}, val::MVTSeries{F}, r::MIT{F}, c::Symbol) where {F<:Frequency}
    xi1 = _ts_values_inds(x, r)
    xi2 = _colind(x, c)
    vali1 = _ts_values_inds(val, r)
    vali2 = _colind(val, c)
    setindex!(_vals(x), _vals(val)[vali1, vali2], xi1, xi2)
end

@inline function Base.setindex!(x::MVTSeries{F}, val::MVTSeries{F}, r::_MITOneOrVector{F}, c::_SymbolOneOrCollection) where {F<:Frequency}
    xi1 = _ts_values_inds(x, r)
    xi2 = _colind(x, c)
    vali1 = _ts_values_inds(val, r)
    vali2 = _colind(val, c)
    setindex!(_vals(x), view(_vals(val), vali1, vali2), xi1, xi2)
end

# -------------------------------------------------------------------------------

Base.copyto!(dest::MVTSeries, src::AbstractArray) = (copyto!(dest.values, src); dest)
function Base.copyto!(dest::MVTSeries, src::MVTSeries)
    drng, dcol = axes(dest)
    srng, scol = axes(src)
    if drng == srng && dcol == scol
        return copyto!(dest, src.values)
    end
    # range to copy
    crng = intersect(drng, srng)
    isempty(crng) && return dest
    for (c, v) in pairs(src)
        if c in dcol
            copyto!(dest[c], crng, v)
        end
    end
    return dest
end

# -------------------------------------------------------------------------------
# ways to add new columns (variables)

function Base.hcat(x::MVTSeries, y::MVTSeries...; KW...)
    T = Base.promote_eltype(x, y..., values(KW)...)
    kw = LittleDict{Symbol,Any}()
    for yy in y
        push!(kw, pairs(yy)...)
    end
    return MVTSeries(T, rangeof(x); pairs(x)..., kw..., KW...)
end

function Base.vcat(x::MVTSeries, args::AbstractVecOrMat...)
    return MVTSeries(firstdate(x), colnames(x), vcat(_vals(x), args...))
end

####   Views

Base.view(x::MVTSeries, I::_FallbackType...) = view(_vals(x), _vals.(I)...)
# function Base.view(x::MVTSeries{F}, I::StepRange{MIT{F}}) where {F<:Frequency} 
#     start, stop = _ind_range_check(x, I)
#     view(_vals(x), start:Int(I.step):stop, :)
# end
# function Base.view(x::MVTSeries{F}, I::StepRange{<:Integer}) where {F<:Frequency} 
#     view(_vals(x), I, :)
# end

# Base.view(::MVTSeries{F1}, ::TSeries{F2,Bool}, ::Colon=Colon()) where {F1<:Frequency,F2<:Frequency} = mixed_freq_error(F1, F2)
# Base.view(x::MVTSeries{F}, ind::TSeries{F,Bool}, ::Colon=Colon()) where {F<:Frequency} = view(x, rangeof(ind)[_vals(ind)], :)

Base.dotview(sd::MVTSeries, ::TSeries{F,Bool}) where {F<:Frequency} = mixed_freq_error(frequencyof(sd), F)
Base.dotview(sd::MVTSeries{F}, ind::TSeries{F,Bool}) where {F<:Frequency} = begin
    @boundscheck checkbounds(sd, rangeof(ind))
    dotview(_vals(sd), _vals(ind), :)
end


Base.view(x::MVTSeries, J::_SymbolOneOrCollection) = view(x, axes(x, 1), J)
Base.view(x::MVTSeries, ::Colon, J::_SymbolOneOrCollection) = view(x, axes(x, 1), J)
Base.view(x::MVTSeries, I::_MITOneOrVector, ::Colon=Colon()) = view(x, I, axes(x, 2))
Base.view(x::MVTSeries, ::Colon, ::Colon) = view(x, axes(x, 1), axes(x, 2))

function Base.view(x::MVTSeries, I::_MITOneOrVector, J::_SymbolOneOrCollection)
    i1 = _ts_values_inds(x, I)
    i2 = _colind(x, J)
    _mvts_access(Base.view, x, I, J, i1, i2)
end

Base.Broadcast.dotview(x::MVTSeries, args...) = view(x, args...)


####

include("mvtseries/mvts_broadcast.jl")
include("mvtseries/mvts_show.jl")

####  arraymath

Base.promote_shape(x::MVTSeries, y::MVTSeries) =
    axes(x, 2) == axes(y, 2) ? (intersect(rangeof(x), rangeof(y)), axes(x, 2)) :
    throw(DimensionMismatch("Columns do not match:\n\t$(axes(x,2))\n\t$(axes(y,2))"))

Base.promote_shape(x::MVTSeries, y::AbstractArray) =
    promote_shape(_vals(x), y)

Base.promote_shape(x::AbstractArray, y::MVTSeries) =
    promote_shape(x, _vals(y))

# fix axis promotion for isapprox with matrix
Base.promote_shape(x::Tuple{UnitRange{<:MIT},Vector{Symbol}}, y::Tuple{Base.OneTo{Int64},Base.OneTo{Int64}}) = (Base.OneTo(length(x[1])), Base.OneTo(length(x[2])))
Base.promote_shape(x::Tuple{Base.OneTo{Int64},Base.OneTo{Int64}}, y::Tuple{UnitRange{<:MIT},Vector{Symbol}}) = x

Base.LinearIndices(x::MVTSeries) = LinearIndices(_vals(x))

Base.:*(x::Number, y::MVTSeries) = copyto!(similar(y), *(x, y.values))
Base.:*(x::MVTSeries, y::Number) = copyto!(similar(x), *(x.values, y))
Base.:\(x::Number, y::MVTSeries) = copyto!(similar(y), \(x, y.values))
Base.:/(x::MVTSeries, y::Number) = copyto!(similar(x), /(x.values, y))

for func = (:+, :-)
    @eval function Base.$func(x::MVTSeries, y::MVTSeries)
        T = Base.promote_eltype(x, y)
        if axes(x) == axes(y)
            return copyto!(similar(x, T), $func(_vals(x), _vals(y)))
        else
            shape = promote_shape(x, y)
            return copyto!(similar(Matrix, T, shape), $func(_vals(x[shape[1]]), _vals(y[shape[1]])))
        end
    end
end

####  sum(x::MVTSeries; dims=2) -> TSeries

for (mod, funcs) in ((Base, (:sum, :prod, :minimum, :maximum, :any, :all)), (Statistics, (:median, :mean)))
    for func in funcs

        @eval @inline $mod.$func(x::MVTSeries; dims=:) =
            dims == 2 ? TSeries(firstdate(x), $func(rawdata(x); dims=dims)[:]) : $func(rawdata(x); dims=dims)

        @eval @inline $mod.$func(f, x::MVTSeries; dims=:) =
            dims == 2 ? TSeries(firstdate(x), $func(f, rawdata(x); dims=dims)[:]) : $func(f, rawdata(x); dims=dims)

    end
end

####  reshape

# reshaped arrays are slow with MVTSeries. We must avoid them at all costs
@inline function Base.reshape(x::MVTSeries, args::Int...)
    ret = reshape(_vals(x), args...)
    if axes(ret) == axes(_vals(x))
        # reshape is no-op - return x
        return x
    else
        # reshape the matrix, but lose the MVTSeries structure - it's super slow
        # to display or not to display an error message
        # @error("Cannot reshape MVTSeries!")
        return ret
    end
end

####  diff and cumsum

shift(x::MVTSeries, k::Integer) = shift!(copy(x), k)
shift!(x::MVTSeries, k::Integer) = (x.firstdate -= k; x)
lag(x::MVTSeries, k::Integer=1) = shift(x, -k)
lag!(x::MVTSeries, k::Integer=1) = shift!(x, -k)
lead(x::MVTSeries, k::Integer=1) = shift(x, k)
lead!(x::MVTSeries, k::Integer=1) = shift!(x, k)

Base.diff(x::MVTSeries; dims=1) = diff(x, -1; dims)
Base.diff(x::MVTSeries, k::Integer; dims=1) =
    dims == 1 ? x - shift(x, k) : diff(_vals(x); dims)

Base.cumsum(x::MVTSeries; dims) = cumsum!(copy(x), _vals(x); dims)
Base.cumsum!(out::MVTSeries, in::AbstractMatrix; dims) = (cumsum!(_vals(out), in; dims); out)

####  moving average


"""
    moving(x, n)

Compute the moving average of `x` over a window of `n` periods. If `n > 0` the
window is backward-looking `(-n+1:0)` and if `n < 0` the window is forward-looking
`(0:-n-1)`.
"""
function moving end
export moving, moving_sum, moving_average

# _moving_mean!(x_ma::TSeries, x, t, window) = x_ma[t] = mean(x[t.+window])
# _moving_mean!(x_ma::MVTSeries, x, t, window) = x_ma[t, :] .= mean(x[t.+window, :]; dims=1)

# _moving_shape(x::TSeries, n) = (rangeof(x, drop=n - copysign(1, n)),)
# _moving_shape(x::MVTSeries, n) = (rangeof(x, drop=n - copysign(1, n)), axes(x, 2))

# function moving(x::Union{TSeries,MVTSeries}, n::Integer)
#     window = n > 0 ? (-n+1:0) : (0:-n-1)
#     x_ma = similar(x, _moving_shape(x, n))
#     for t in rangeof(x_ma)
#         _moving_mean!(x_ma, x, t, window)
#     end
#     return x_ma
# end

function _moving_sum(x::MVTSeries, n::Integer, avg)
    an = abs(n)
    len = size(x, 1) - an
    x_ma = MVTSeries(x.firstdate + (n > 0 ? n - 1 : 0), colnames(x), zeros(len + 1, size(x, 2)))
    for i in 1:an
        x_ma .+= x.values[i:i+len, :]
    end
    avg && (x_ma ./= an)
    return x_ma
end

function _moving_sum(x::TSeries, n::Integer, avg)
    an = abs(n)
    len = size(x, 1) - an
    x_ma = TSeries(x.firstdate + (n > 0 ? n - 1 : 0), zeros(len + 1))
    for i in 1:an
        x_ma .+= x.values[i:i+len]
    end
    avg && (x_ma ./= an)
    return x_ma
end

@inline function moving_sum(x::Union{TSeries,MVTSeries}, n::Integer)
    return _moving_sum(x, n, false)
end

@inline function moving_average(x::Union{TSeries,MVTSeries}, n::Integer)
    return _moving_sum(x, n, true)
end

@inline function moving(x::Union{TSeries,MVTSeries}, n::Integer)
    return moving_average(x, n)
end

####  undiff

"""
    undiff(dvar, [date => value])
    undiff!(var, dvar; fromdate=firstdate(dvar)-1)

Inverse of `diff`, i.e. `var` remains unchanged under `undiff!(var, diff(var))`
or `undiff(diff(var), firstdate(var)=>first(var))`. This is the same as
`cumsum`, but specific to time series.

In the case of `undiff` the second argument is an "anchor" `Pair` specifying a
known value at some time period. Typically this will be the period just before
the first date of `dvar`, but doesn't have to be. If the date falls outside the
`rangeof(dvar)` we extend dvar with zeros as necessary. If missing, this
argument defaults to `firstdate(dvar)-1 => 0`.

In the case of `undiff!`, the `var` argument provides the "anchor" value and the
storage location for the result. The `fromdate` parameter specifies the date of
the "anchor" and the anchor value is taken from `var`. See important note below.

The in-place version (`undiff!`) works only with `TSeries`. The other version
(`undiff`) works with `MVTSeries` as well as `TSeries`. In the case of
`MVTSeries` the anchor `value` must be a `Vector`, or a `Martix` with 1 row, of
the same length as the number of columns of `dvar`.

!!! note 

    In the case of `undiff!` the meaning of parameter `fromdate` is different
    from the meaning of `date` in the second argument of `undiff`. This only
    matters if `fromdate` falls somewhere in the middle of the range of `dvar`.

    In the case of `undiff!`, all values of `dvar` at, and prior to, `fromdate`
    are ignored (considered zero). Effectively, values of `var` up to, and
    including, `fromdate` remain unchanged. 

    By contrast, in `undiff` with `date => value` somewhere in the middle of the
    range of `dvar`, the operation is applied over the full range of `dvar`,
    both before and after `date`, and then the result is adjusted by adding or
    subtracting a constant such that in the end we have `result[date]=value`.

"""
function undiff end, function undiff! end
export undiff, undiff!

"If second argument is `anchor_value::Number`, assume the anchor date is `firstdate(dvar)-1`"
undiff(dvar::TSeries, anchor_value::Number=zero(eltype(dvar))) = undiff(dvar, firstdate(dvar) - 1 => anchor_value)
"If second argument is `anchor::TSeries`, assume anchor date is `firstdate(dvar)-1` and take value form `anchor`"
undiff(dvar::TSeries, anchor_value::TSeries) = (ad = firstdate(dvar) - 1; undiff(dvar, ad => anchor_value[ad]))
"If second argument is a pair `ad::MIT => av::TSeries`, take the anchor value to be `av[ad]`"
undiff(dvar::TSeries, anchor::Pair{<:MIT,<:TSeries}) = (ad = anchor[1]; undiff(dvar, ad => anchor[2][ad]))
function undiff(dvar::TSeries, anchor::Pair{<:MIT,<:Number})
    fromdate, value = anchor
    ET = Base.promote_eltype(dvar, value)
    if fromdate ∉ rangeof(dvar)
        # our anchor is outside, extend with zeros
        dvar = overlay(dvar, fill(zero(ET), fromdate:lastdate(dvar)))
    end
    result = similar(dvar, ET)
    result .= cumsum(dvar)
    correction = value - result[fromdate]
    result .+= correction
    return result
end

function undiff!(var::TSeries, dvar::TSeries; fromdate=firstdate(dvar) - 1)
    if fromdate < firstdate(var)
        error("Range mismatch: `fromdate == $(fromdate) < $(firstdate(var)) == firstdate(var): ")
    end
    if lastdate(var) < lastdate(dvar)
        resize!(var, firstdate(var):lastdate(dvar))
    end
    for t = fromdate+1:lastdate(dvar)
        var[t] = var[t-1] + dvar[t]
    end
    return var
end

# undiff(dvar::MVTSeries) = undiff(dvar, firstdate(dvar) - 1 => zeros(eltype(dvar), size(dvar, 2)))
"If second argument is `anchor_value::Number`, assume the anchor date is `firstdate(dvar)-1`"
@inline undiff(dvar::MVTSeries, anchor_value::Number=zero(eltype(dvar))) = undiff(dvar, firstdate(dvar) - 1 => anchor_value)
"If second argument is `anchor_value::Vector`, assume the anchor date is `firstdate(dvar)-1`"
@inline undiff(dvar::MVTSeries, anchor_value::AbstractVecOrMat) = undiff(dvar, firstdate(dvar) - 1 => anchor_value)
@inline undiff(dvar::MVTSeries, anchor::Pair{<:MIT,<:Number}) = undiff(dvar, anchor[1] => fill(anchor[2], size(dvar, 2)))
@inline undiff(dvar::MVTSeries, anchor::MVTSeries) = (ad = firstdate(dvar) - 1; undiff(dvar, ad => anchor[ad]))
@inline undiff(dvar::MVTSeries, anchor::TSeries) = (ad = firstdate(dvar) - 1; undiff(dvar, ad => anchor[ad]))
@inline undiff(dvar::MVTSeries, anchor::Pair{<:MIT,<:MVTSeries}) = undiff(dvar, anchor[1] => anchor[2][anchor[1]])
@inline undiff(dvar::MVTSeries, anchor::Pair{<:MIT,<:TSeries}) = undiff(dvar, anchor[1] => anchor[2][anchor[1]])
function undiff(dvar::MVTSeries, anchor::Pair{<:MIT,<:AbstractVecOrMat})
    fromdate, value = anchor
    ET = Base.promote_eltype(dvar, value)
    if fromdate ∉ rangeof(dvar)
        # our anchor is outside, extend with zeros
        shape = axes(dvar)
        new_range = rangeof_span(fromdate, shape[1])
        tmp = dvar
        dvar = fill(zero(ET), new_range, shape[2])
        dvar .= tmp
    end
    result = similar(dvar, ET)
    result .= cumsum(dvar; dims=1)
    correction = reshape(value .- result[fromdate], 1, :)
    result .+= correction
    return result
end

########

Base.findall(A::MVTSeries) = findall(_vals(A))

Base.getindex(sd::MVTSeries, ::TSeries{F,Bool}) where {F<:Frequency} = mixed_freq_error(frequencyof(sd), F)
Base.getindex(sd::MVTSeries{F}, ind::TSeries{F,Bool}) where {F<:Frequency} = getindex(_vals(sd), _vals(ind), :)
Base.setindex!(sd::MVTSeries, ::Any, ::TSeries{F,Bool}) where {F<:Frequency} = mixed_freq_error(frequencyof(sd), F)
Base.setindex!(sd::MVTSeries{F}, val, ind::TSeries{F,Bool}) where {F<:Frequency} = setindex!(_vals(sd), val, _vals(ind), :)

"""
mapslices(f, A::MVTSeries, dims)

This functions as Base.mapslices with some specialized returns.

Returns an MVTseries when the dimensions of the result match the dimensions of A.

Returns a TSeries when the result is a vector of the same length as the range of A.

Returns a Matrix otherwise.
"""
function Base.mapslices(f, A::MVTSeries; dims)
    res = mapslices(f, A.values; dims=dims)
    if size(res) == size(A)
        res_mvts = similar(A)
        res_mvts.values = res
        return res_mvts
    elseif size(res) == (size(A)[1], 1)
        # one column
        return TSeries(rangeof(A), res[:, 1])
    end
    return res
end

