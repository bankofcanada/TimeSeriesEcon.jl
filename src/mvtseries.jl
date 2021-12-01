# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using OrderedCollections

# -------------------------------------------------------------------------------
# MVTSeries -- multivariate TSeries
# -------------------------------------------------------------------------------

mutable struct MVTSeries{
    F<:Frequency,
    T<:Number,
    C<:AbstractMatrix{T}
} <: AbstractMatrix{T}

    firstdate::MIT{F}
    columns::OrderedDict{Symbol,TSeries{F,T}}
    values::C

    # inner constructor enforces constraints
    function MVTSeries(firstdate::MIT{F},
        names::NTuple{N,Symbol},
        values::AbstractMatrix
    ) where {F<:Frequency,N}
        if N != size(values, 2)
            ArgumentError("Number of names and columns don't match:" *
                          " $N ≠ $(size(values, 2)).") |> throw
        end
        columns = OrderedDict(nm => TSeries(firstdate, view(values, :, ind))
                              for (nm, ind) in zip(names, axes(values, 2)))
        new{F,eltype(values),typeof(values)}(firstdate, columns, values)
    end

end

@inline _names_as_tuple(names::Symbol) = (names,)
@inline _names_as_tuple(names::AbstractString) = (Symbol(names),)
@inline _names_as_tuple(names) = tuple(Symbol.(names)...)


# standard constructor with default empty values
MVTSeries(fd::MIT = 1U, names = ()) = (names = _names_as_tuple(names); MVTSeries(fd, names, zeros(0, length(names))))
MVTSeries(fd::MIT, names, data::AbstractMatrix) = (names = _names_as_tuple(names); MVTSeries(fd, names, data))
# see more constructors below

@inline _vals(x::MVTSeries) = getfield(x, :values)
@inline _cols(x::MVTSeries) = getfield(x, :columns)

@inline colnames(x::MVTSeries) = keys(_cols(x))
@inline rawdata(x::MVTSeries) = _vals(x)
@inline Base.pairs(x::MVTSeries) = pairs(_cols(x))

@inline firstdate(x::MVTSeries) = getfield(x, :firstdate)
@inline lastdate(x::MVTSeries) = firstdate(x) + size(_vals(x), 1) - one(firstdate(x))
@inline frequencyof(::Type{<:MVTSeries{F}}) where {F<:Frequency} = F
@inline rangeof(x::MVTSeries) = firstdate(x):lastdate(x)

# -------------------------------------------------------------------------------
# Make MVTSeries work properly as an AbstractArray


@inline Base.size(x::MVTSeries) = size(_vals(x))
@inline Base.axes(x::MVTSeries) = (rangeof(x), tuple(colnames(x)...))
@inline Base.axes1(x::MVTSeries) = rangeof(x)

# the following are needed for copy() and copyto!() (and a bunch of Julia internals that use them)
@inline Base.IndexStyle(x::MVTSeries) = IndexStyle(_vals(x))
@inline Base.dataids(x::MVTSeries) = Base.dataids(_vals(x))

# normally only the first of the following is sufficient.
# we add few other versions of similar below
Base.similar(x::MVTSeries) = MVTSeries(firstdate(x), colnames(x), similar(_vals(x)))

# -------------------------------------------------------------------------------
# Indexing with integers and booleans - same as matrices

# Indexing with integers falls back to AbstractArray
const _FallbackType = Union{Integer,Colon,AbstractUnitRange{<:Integer},AbstractArray{<:Integer},CartesianIndex}
Base.getindex(sd::MVTSeries, i1::_FallbackType...) = getindex(_vals(sd), i1...)
Base.setindex!(sd::MVTSeries, val, i1::_FallbackType...) = setindex!(_vals(sd), val, i1...)

# -------------------------------------------------------------
# Some other constructors
# -------------------------------------------------------------

# Empty (0 variables) from range
@inline MVTSeries(T::Type{<:Number}, rng::AbstractUnitRange{<:MIT}) = MVTSeries(first(rng), (), Matrix{T}(undef, length(rng), 0))
@inline MVTSeries(rng::UnitRange{<:MIT}) = MVTSeries(Float64, rng)

# Empty from a list of variables and of specified type (first date must also be given, Frequency is not enough)
# @inline MVTSeries(fd::MIT, vars) = MVTSeries(Float64, fd, vars)
MVTSeries(T::Type{<:Number}, fd::MIT, vars) = MVTSeries(fd, vars, Matrix{T}(undef, 0, length(vars)))

# Uninitialized from a range and list of variables
@inline MVTSeries(rng::UnitRange{<:MIT}, vars) = MVTSeries(Float64, rng, vars, undef)
@inline MVTSeries(rng::UnitRange{<:MIT}, vars, ::UndefInitializer) = MVTSeries(Float64, rng, vars, undef)
@inline MVTSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}, vars) = MVTSeries(T, rng, vars, undef)
MVTSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}, vars, ::UndefInitializer) =
    MVTSeries(first(rng), vars, Matrix{T}(undef, length(rng), length(vars)))
MVTSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}, vars::Symbol, ::UndefInitializer) =
    MVTSeries(first(rng), (vars,), Matrix{T}(undef, length(rng), 1))

# initialize with a function like zeros, ones, rand.
MVTSeries(rng::UnitRange{<:MIT}, vars, init::Function) = MVTSeries(first(rng), vars, init(length(rng), length(vars)))
# no type-explicit version because the type is determined by the output of init()

#initialize with a constant
MVTSeries(rng::UnitRange{<:MIT}, vars, v::Number) = MVTSeries(first(rng), vars, fill(v, length(rng), length(vars)))

# construct with a given range (rather than only the first date). We must check the range length matches the data size 1
function MVTSeries(rng::UnitRange{<:MIT}, vars, vals::AbstractMatrix{<:Number})
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
MVTSeries(fd::MIT, vars::Symbol, data::AbstractVector) = MVTSeries(fd, (vars,), reshape(data, :, 1))
MVTSeries(rng::UnitRange{<:MIT}, vars, data::AbstractVector) = MVTSeries(rng, vars, reshape(data, :, 1))
MVTSeries(rng::UnitRange{<:MIT}, vars::Symbol, data::AbstractVector) = MVTSeries(rng, (vars,), reshape(data, :, 1))

# construct uninitialized by way of calling similar 
Base.similar(::Type{<:AbstractArray}, T::Type{<:Number}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {N} = MVTSeries(T, shape[1], shape[2])
Base.similar(::Type{<:AbstractArray{T}}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {T<:Number,N} = MVTSeries(T, shape[1], shape[2])
Base.similar(::AbstractArray, T::Type{<:Number}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {N} = MVTSeries(T, shape[1], shape[2])
Base.similar(::AbstractArray{T}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {T<:Number,N} = MVTSeries(T, shape[1], shape[2])

# construct from range and fill with the given constant or array
Base.fill(v::Number, rng::UnitRange{<:MIT}, vars::NTuple{N,Symbol}) where {N} = MVTSeries(first(rng), vars, fill(v, length(rng), length(vars)))


# -------------------------------------------------------------------------------
# Dot access to columns

Base.propertynames(x::MVTSeries) = tuple(colnames(x)...)

function Base.getproperty(x::MVTSeries, col::Symbol)
    col ∈ fieldnames(typeof(x)) && return getfield(x, col)
    columns = _cols(x)
    haskey(columns, col) && return columns[col]
    Base.throw_boundserror(x, [col,])
end

function Base.setproperty!(x::MVTSeries, name::Symbol, val)
    name ∈ fieldnames(typeof(x)) && return setfield!(x, name, val)
    columns = _cols(x)
    if !haskey(columns, name)
        error("Cannot append new column this way. " *
              "Use hcat(x; $name = value) or push!(x; $name = value).")
    end
    col = columns[name]
    ####  Do we need this mightalias check here? I think it's done in copyto!() so we should be safe without it.
    # if Base.mightalias(col, val)
    #     val = copy(val)
    # end
    if val isa TSeries
        rng = intersect(rangeof(col), rangeof(val))
        return copyto!(col, rng, val)
    elseif val isa Number
        return fill!(col.values, val)
    else
        return copyto!(col.values, val)
    end
end

# -------------------------------------------------------------------------------
# Indexing other than integers 

# some check bounds that plug MVTSeries into the Julia infrastructure for AbstractArrays
@inline Base.checkbounds(::Type{Bool}, x::MVTSeries, p::MIT) = checkindex(Bool, rangeof(x), p)
@inline Base.checkbounds(::Type{Bool}, x::MVTSeries, p::UnitRange{<:MIT}) = checkindex(Bool, rangeof(x), p)
@inline Base.checkbounds(::Type{Bool}, x::MVTSeries, c::Symbol) = haskey(_cols(x), c)
@inline function Base.checkbounds(::Type{Bool}, x::MVTSeries, INDS::Union{Vector{Symbol},NTuple{N,Symbol}}) where {N}
    cols = _cols(x)
    for c in INDS
        haskey(cols, c) || return false
    end
    return true
end

@inline function Base.checkbounds(::Type{Bool}, x::MVTSeries, p::Union{MIT,UnitRange{<:MIT}}, c::Union{Symbol,Vector{Symbol},NTuple{N,Symbol}}) where {N}
    return checkbounds(Bool, x, p) && checkbounds(Bool, x, c)
end


# ---- single argument access

# single argument - MIT point - return the row as a vector (slice of .values)
Base.getindex(x::MVTSeries, p::MIT) = mixed_freq_error(x, p)
@inline function Base.getindex(x::MVTSeries{F}, p::MIT{F}) where {F<:Frequency}
    @boundscheck checkbounds(x, p)
    fi = firstindex(_vals(x), 1)
    getindex(x.values, fi + oftype(fi, p - firstdate(x)), :)
end

Base.setindex!(x::MVTSeries, val, p::MIT) = mixed_freq_error(x, p)
@inline function Base.setindex!(x::MVTSeries{F}, val, p::MIT{F}) where {F<:Frequency}
    @boundscheck checkbounds(x, p)
    fi = firstindex(_vals(x), 1)
    setindex!(_vals(x), val, fi + oftype(fi, p - firstdate(x)), :)
end

# single argument - MIT range
Base.getindex(x::MVTSeries, rng::UnitRange{MIT}) = mixed_freq_error(x, rng)
@inline function Base.getindex(x::MVTSeries{F}, rng::UnitRange{MIT{F}}) where {F<:Frequency}
    start, stop = _ind_range_check(x, rng)
    return MVTSeries(first(rng), axes(x, 2), getindex(_vals(x), start:stop, :))
end

Base.setindex!(x::MVTSeries, val, rng::UnitRange{MIT}) = mixed_freq_error(x, rng)
@inline function Base.setindex!(x::MVTSeries{F}, val, rng::UnitRange{MIT{F}}) where {F<:Frequency}
    start, stop = _ind_range_check(x, rng)
    setindex!(_vals(x), val, start:stop, :)
end

# single argument - variable - return a TSeries of the column
@inline Base.getindex(x::MVTSeries, col::AbstractString) = getindex(x, Symbol(col))
@inline function Base.getindex(x::MVTSeries, col::Symbol)
    @boundscheck checkbounds(x, col)
    getproperty(x, col)
end

@inline Base.setindex!(x::MVTSeries, val, col::AbstractString) = setindex!(x, val, Symbol(col))
@inline function Base.setindex!(x::MVTSeries, val, col::Symbol)
    setproperty!(x, col, val)
end

# single argument - list/tuple of variables - return a TSeries of the column
@inline function Base.getindex(x::MVTSeries, col::Union{Vector{Symbol},NTuple{N,Symbol}}) where {N}
    @boundscheck checkbounds(x, col)
    names = [colnames(x)...]
    inds = indexin(col, names)
    return MVTSeries(firstdate(x), tuple(names[inds]...), getindex(_vals(x), :, inds))
end

@inline function Base.setindex!(x::MVTSeries, val, col::Union{Vector{Symbol},NTuple{N,Symbol}}) where {N}
    @boundscheck checkbounds(x, col)
    names = [colnames(x)...]
    inds = indexin(col, names)
    setindex!(x.values, val, :, inds)
end

# ---- two arguments indexing

@inline Base.getindex(x::MVTSeries, p::MIT, c) = mixed_freq_error(x, p)
@inline Base.getindex(x::MVTSeries, r::UnitRange{<:MIT}, c) = mixed_freq_error(x, r)
@inline Base.setindex!(x::MVTSeries, val, p::MIT, c) = mixed_freq_error(x, p)
@inline Base.setindex!(x::MVTSeries, val, r::UnitRange{<:MIT}, c) = mixed_freq_error(x, r)

# if one argument is Colon, fall back on single argument indexing
@inline Base.getindex(x::MVTSeries, p::MIT, ::Colon) = getindex(x, p)
@inline Base.getindex(x::MVTSeries, p::UnitRange{<:MIT}, ::Colon) = getindex(x, p)
@inline Base.getindex(x::MVTSeries, ::Colon, c::Symbol) = getindex(x, c)
@inline Base.getindex(x::MVTSeries, ::Colon, c::NTuple{N,Symbol}) where {N} = getindex(x, c)
@inline Base.getindex(x::MVTSeries, ::Colon, c::Vector{Symbol}) = getindex(x, c)

@inline Base.setindex!(x::MVTSeries, val, p::MIT, ::Colon) = setindex!(x, val, p)
@inline Base.setindex!(x::MVTSeries, val, p::UnitRange{<:MIT}, ::Colon) = setindex!(x, val, p)
@inline Base.setindex!(x::MVTSeries, val, ::Colon, c::Symbol) = setindex!(x, val, c)
@inline Base.setindex!(x::MVTSeries, val, ::Colon, c::NTuple{N,Symbol}) where {N} = setindex!(x, val, c)
@inline Base.setindex!(x::MVTSeries, val, ::Colon, c::Vector{Symbol}) = setindex!(x, val, c)

# 

_colind(x, c::Symbol) = indexin([Symbol(c)], [colnames(x)...])[1]
_colind(x, c::Tuple) = indexin(Symbol.(c), [colnames(x)...])
_colind(x, c::Vector) = indexin(Symbol.(c), [colnames(x)...])

# with a single MIT and single Symbol we return a number
# with a single MIT and multiple Symbol-s we return a Vector
# the appropriate dispatch is done in getindex on the values, so we wrap both cases in a single function
@inline function Base.getindex(x::MVTSeries{F}, p::MIT{F}, c::Union{Symbol,NTuple{N,Symbol},Vector{Symbol}}) where {F<:Frequency,N}
    @boundscheck checkbounds(x, c)
    @boundscheck checkbounds(x, p)
    fi = firstindex(_vals(x), 1)
    i1 = oftype(fi, fi + (p - firstdate(x)))
    i2 = _colind(x, c)
    getindex(x.values, i1, i2)
end

# with an MIT range and a Symbol (single column) we return a TSeries
@inline function Base.getindex(x::MVTSeries{F}, p::UnitRange{MIT{F}}, c::Symbol) where {F<:Frequency}
    @boundscheck checkbounds(x, c)
    @boundscheck checkbounds(x, p)
    start, stop = _ind_range_check(x, p)
    i1 = start:stop
    i2 = _colind(x, c)
    return TSeries(first(p), getindex(_vals(x), i1, i2))
end

# with an MIT range and a sequence of Symbol-s we return an MVTSeries
@inline function Base.getindex(x::MVTSeries{F}, p::UnitRange{MIT{F}}, c::Union{NTuple{N,Symbol},Vector{Symbol}}) where {F<:Frequency,N}
    @boundscheck checkbounds(x, c)
    @boundscheck checkbounds(x, p)
    start, stop = _ind_range_check(x, p)
    i1 = start:stop
    i2 = _colind(x, c)
    return MVTSeries(first(p), axes(x, 2)[i2], getindex(_vals(x), i1, i2))
end

# assignments

# with a single MIT we assign a number or a row-Vector
@inline function Base.setindex!(x::MVTSeries{F}, val, p::MIT{F}, c::Union{Symbol,NTuple{N,Symbol},Vector{Symbol}}) where {F<:Frequency,N}
    @boundscheck checkbounds(x, p)
    @boundscheck checkbounds(x, c)
    fi = firstindex(_vals(x), 1)
    i1 = oftype(fi, fi + (p - firstdate(x)))
    i2 = _colind(x, c)
    setindex!(x.values, val, i1, i2)
end

# with a range of MIT and a single column - we fall back on TSeries assignment
@inline function Base.setindex!(x::MVTSeries{F}, val, r::UnitRange{MIT{F}}, c::Symbol) where {F<:Frequency} 
    col = getindex(x, c)
    setindex!(col, val, r)
end

@inline function Base.setindex!(x::MVTSeries{F}, val, r::UnitRange{MIT{F}}, c::Union{Vector{Symbol}, NTuple{N,Symbol}}) where {F<:Frequency, N}
    @boundscheck checkbounds(x, r)
    @boundscheck checkbounds(x, c)
    start, stop = _ind_range_check(x, r)
    i1 = start:stop
    i2 = _colind(x, c)
    setindex!(_vals(x), val, i1, i2)
end

@inline function Base.setindex!(x::MVTSeries{F}, val::MVTSeries{F}, r::UnitRange{MIT{F}}, c::Union{Vector{Symbol}, NTuple{N,Symbol}}) where {F<:Frequency, N}
    @boundscheck checkbounds(x, r)
    @boundscheck checkbounds(x, c)
    @boundscheck checkbounds(val, r)
    @boundscheck checkbounds(val, c)
    xcols = _cols(x)
    vcols = _cols(val)
    for col in c
        setindex!(xcols[col], vcols[col], r)
    end
    return x
end

# -------------------------------------------------------------------------------

# -------------------------------------------------------------------------------
# ways add new columns (variables)

function Base.hcat(x::MVTSeries; KW...)
    y = MVTSeries(rangeof(x), tuple(colnames(x)..., keys(KW)...))
    # copyto!(y, x)
    for (k, v) in pairs(x)
        setproperty!(y, k, v)
    end
    for (k, v) in KW
        setproperty!(y, k, v)
    end
    return y
end


include("mvtseries/mvts_show.jl")
