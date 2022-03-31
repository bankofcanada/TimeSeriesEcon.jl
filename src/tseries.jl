# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# -------------------------------------------------------------------------------
# TSeries struct 
# -------------------------------------------------------------------------------

"""
    mutable struct TSeries{F, T, C} <: AbstractVector{T}
        firstdate::MIT{F}
        values::C
    end

Time series with frequency `F` and values of type `T` stored in a container of
type `C`. By default the type is `Float64` and the container is
`Vector{Float64}`.

### Construction:
    ts = TSeries(args...)

The standard construction is
`TSeries(firstdate::MIT, values::AbstractVector)`. If the second argument is
not given, the `TSeries` is constructed empty.

Alternatively, the first argument can be a range. In this case, the second
argument is interpreted as an initializer. If it is omitted or set to
`undef`, the storage is left uninitialized. If it is a number, the storage
is filled with it. It can also be an initializer function, such as `zeros`,
`ones` or `rand`. Lastly, if the second argument is an array, it must be
1-dimensional and of the same length as the range given in the first
argument.

If only an integer number is given, as in `TSeries(n::Integer)`, the
constructed `TSeries` will have frequency `Unit`, first date `1U` and length
`n`. An initialization argument is not allowed in this case, so the storage
remains uninitialized.

A `TSeries` can also be constructed with `copy`, `similar`, and `fill`, `ones`,
`zeros`.

### Indexing:
Indexing with an [`MIT`](@ref) or a range of [`MIT`](@ref) works as you'd
expect.

Indexing with `Integer`s works the same as with `Vector`.

Indexing with `Bool`-array works as you'd expect. For example,
`s[s .< 0.0] .*= -1` multiplies in place the negative entries of `s` by -1,
so effectively it's the same as `s .= abs.(s)`.

There are important differences between indexing with MIT and not
using MIT (i.e., using `Integer` or `Bool`-array).

* with MIT-range we return a `TSeries`, otherwise we
    return a `Vector`.

* the range can be extended (the `TSeries` resized appropriately) by
    assigning outside the current range. This works only with [`MIT`](@ref).
    With anything else you get a BoundsError if you try to assign outside the
    Integer range.

* `begin` and `end` are [`MIT`](@ref), so either use both or none of them.
    For example `s[2:end]` doesn't work because 2 is an `Int` and `end` is an
    `MIT`. You should use `s[begin+1:end]`.

Check out the tutorial at 
[https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/TimeSeriesEcon/main/](https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/TimeSeriesEcon/main/)
"""
mutable struct TSeries{F<:Frequency,T<:Number,C<:AbstractVector{T}} <: AbstractVector{T}
    firstdate::MIT{F}
    values::C
end

_vals(t::TSeries) = t.values
"""
    rawdata(t)

Return the raw storage of `t`. For a [`TSeries`](@ref) this is a `Vector`. For
an [`MVTSeries`](@ref) this is a `Matrix`.
"""
rawdata(t::TSeries) = t.values

Base.values(t::TSeries) = values(t.values)


"""
    firstdate(x)

Return the first date of the range of allocated storage for the given
[`TSeries`](@ref) or [`MVTSeries`](@ref) instance.
"""
firstdate(t::TSeries) = t.firstdate

"""
    lastdate(x)

Return the last date of the range of allocated storage for the given
[`TSeries`](@ref) or [`MVTSeries`](@ref) instance.
"""
lastdate(t::TSeries) = t.firstdate + length(t.values) - one(t.firstdate)

frequencyof(::Type{<:TSeries{F}}) where {F<:Frequency} = F

"""
    rangeof(s)

Return the stored range of the given [`TSeries`](@ref) or [`MVTSeries`](@ref)
instance.
"""
function rangeof end

rangeof(t::TSeries) = firstdate(t) .+ (0:size(t.values, 1)-1)

# -------------------------------------------------------------------------------
# some methods that make the AbstractArray infrastructure of Julia work with TSeries

Base.size(t::TSeries) = size(t.values)
Base.axes(t::TSeries) = (firstdate(t):lastdate(t),)
Base.axes1(t::TSeries) = firstdate(t):lastdate(t)

# the following are needed for copy() and copyto!() (and a bunch of Julia internals that use them)
Base.IndexStyle(::TSeries) = IndexLinear()
Base.dataids(t::TSeries) = Base.dataids(getfield(t, :values))

# normally only the first of the following is sufficient.
# we add few other versions of similar below
"""
    similar(t::TSeries, [eltype], [range])
    similar(array, [eltype], range)
    similar(array_type, [eltype], range)

Create an uninitialized [`TSeries`](@ref) with the given element type and range.

If the first argument is a [`TSeries`](@ref) then the element type and range of
the output will match those of the input, unless they are explicitly given in
subsequent arguments. If the first argument is another array or an array type,
then `range` must be given. The element type, `eltype`, can be given; if not it
will be deduced from the first argument.
"""
Base.similar(t::TSeries) = TSeries(t.firstdate, similar(t.values))

# -------------------------------------------------------------------------------

Base.hash(t::TSeries, h::UInt) = hash((t.values, t.firstdate), h)

# -------------------------------------------------------------------------------
# Indexing with integers and booleans - same as vectors

# indexing with integers is plain and simple
Base.getindex(t::TSeries, i::Int) = getindex(t.values, i)
Base.setindex!(t::TSeries, v::Number, i::Int) = (setindex!(t.values, v, i); t)

# indexing with integer arrays, ranges of integers, and Bool arrays
Base.getindex(t::TSeries, i::AbstractRange{Int}) = getindex(t.values, i)
Base.getindex(t::TSeries, i::AbstractArray{Int}) = getindex(t.values, values(i))
Base.getindex(t::TSeries, i::AbstractArray{Bool}) = getindex(t.values, values(i))
Base.setindex!(t::TSeries, v, i::AbstractRange{Int}) = (setindex!(t.values, v, i); t)
Base.setindex!(t::TSeries, v, i::AbstractArray{Int}) = (setindex!(t.values, v, values(i)); t)
Base.setindex!(t::TSeries, v, i::AbstractArray{Bool}) = (setindex!(t.values, v, values(i)); t)


# -------------------------------------------------------------
# Some constructors
# -------------------------------------------------------------

# construct undefined from range
TSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}) = TSeries(first(rng), Vector{T}(undef, length(rng)))
TSeries(rng::UnitRange{<:MIT}) = TSeries(Float64, rng)
TSeries(fd::MIT) = TSeries(fd .+ (0:-1))
TSeries(T::Type{<:Number}, fd::MIT) = TSeries(T, fd .+ (0:-1))
TSeries(n::Integer) = TSeries(1U:n*U)
TSeries(T::Type{<:Number}, n::Integer) = TSeries(T, 1U:n*U)
TSeries(rng::UnitRange{<:Integer}) = TSeries(0U .+ rng)
TSeries(T::Type{<:Number}, rng::UnitRange{<:Integer}) = TSeries(T, 0U .+ rng)
TSeries(rng::AbstractRange, ::UndefInitializer) = TSeries(Float64, rng)
TSeries(T::Type{<:Number}, rng::AbstractRange, ::UndefInitializer) = TSeries(T, rng)
TSeries(rng::UnitRange{<:MIT}, ini::Function) = TSeries(first(rng), ini(length(rng)))

Base.similar(::Type{<:AbstractArray}, T::Type{<:Number}, shape::Tuple{UnitRange{<:MIT}}) = TSeries(T, shape[1])
Base.similar(::Type{<:AbstractArray{T}}, shape::Tuple{UnitRange{<:MIT}}) where {T<:Number} = TSeries(T, shape[1])
Base.similar(::AbstractArray, T::Type{<:Number}, shape::Tuple{UnitRange{<:MIT}}) = TSeries(T, shape[1])
Base.similar(::AbstractArray{T}, shape::Tuple{UnitRange{<:MIT}}) where {T<:Number} = TSeries(T, shape[1])

# construct from range and fill with the given constant or array
Base.fill(v, shape::Tuple{UnitRange{<:MIT}}) = fill(v, shape...)
Base.fill(v, rng::UnitRange{<:MIT}) = TSeries(first(rng), fill(v, length(rng)))
TSeries(rng::UnitRange{<:MIT}, v::Number) = fill(v, rng)
TSeries(rng::UnitRange{<:MIT}, v::AbstractVector{<:Number}) =
    length(rng) == length(v) ? TSeries(first(rng), v) : throw(ArgumentError("Range and data lengths mismatch."))

for (fname, felt) in ((:zeros, :zero), (:ones, :one))
    @eval begin
        Base.$fname(rng::UnitRange{<:MIT}) = fill($felt(Float64), rng)
        Base.$fname(::Type{T}, rng::UnitRange{<:MIT}) where {T} = fill($felt(T), rng)
        Base.$fname(shape::Tuple{UnitRange{<:MIT}}) = fill($felt(Float64), shape)
        Base.$fname(::Type{T}, shape::Tuple{UnitRange{<:MIT}}) where {T} = fill($felt(T), shape)
    end
end

for (fname, felt) in ((:trues, true), (:falses, false))
    @eval begin
        Base.$fname(rng::UnitRange{<:MIT}) = TSeries(rng, $fname(length(rng)))
        Base.$fname(shape::Tuple{UnitRange{<:MIT}}) = TSeries(shape[1], $fname(length(shape[1])))
    end
end

# -------------------------------------------------------------
# Pretty printing
# -------------------------------------------------------------

function Base.summary(io::IO, t::TSeries)
    et = eltype(t) === Float64 ? "" : ",$(eltype(t))"
    ct = "" # ct = typeof(t.values) === Array{eltype(t),1} ? "" : ",$(typeof(t.values))"
    typestr = "TSeries{$(frequencyof(t))$(et)$(ct)}"
    if isempty(t)
        print(io, "Empty ", typestr, " starting ", t.firstdate)
    else
        print(IOContext(io, :compact => true), length(t.values), "-element ", typestr, " with range ", Base.axes1(t))
    end
end

Base.show(io::IO, ::MIME"text/plain", t::TSeries) = show(io, t)
function Base.show(io::IO, t::TSeries)
    summary(io, t)
    isempty(t) && return
    print(io, ":")
    limit = get(io, :limit, true)
    nval = length(t.values)
    from = t.firstdate
    nrow, ncol = displaysize(io)
    if limit && nval > nrow - 5
        top = div(nrow - 5, 2)
        bot = nval - nrow + 6 + top
        for i = 1:top
            print(io, "\n", lpad(from + (i - 1), 8), " : ", t.values[i])
        end
        print(io, "\n    ⋮")
        for i = bot:nval
            print(io, "\n", lpad(from + (i - 1), 8), " : ", t.values[i])
        end
    else
        for i = 1:nval
            print(io, "\n", lpad(from + (i - 1), 8), " : ", t.values[i])
        end
    end
end


# ------------------------------------------------------------------
# indexing with MIT
# ------------------------------------------------------------------

# this part is tricky! 
# - When querying an index that falls outside the allocated range we throw a
#   BoundsError
# - When setting a value at index outside the allocated range we resize the
#   allocation to include the given index (setting new locations to NaN)
#   

Base.getindex(t::TSeries, m::MIT) = mixed_freq_error(t, m)
@inline function Base.getindex(t::TSeries{F}, m::MIT{F}) where {F<:Frequency}
    @boundscheck checkbounds(t, m)
    fi = firstindex(t.values)
    getindex(t.values, fi + oftype(fi, m - firstdate(t)))
end

@inline _ind_range_check(x, rng::MIT) = _ind_range_check(x, rng:rng)
function _ind_range_check(x, rng::UnitRange{<:MIT})
    fi = firstindex(x.values, 1)
    fd = firstdate(x)
    stop = oftype(fi, fi + (last(rng) - fd))
    start = oftype(fi, fi + (first(rng) - fd))
    if start < fi || stop > lastindex(x.values, 1)
        Base.throw_boundserror(x, rng)
    end
    return (start, stop)
end

Base.getindex(t::TSeries, rng::AbstractRange{<:MIT}) = mixed_freq_error(t, rng)
function Base.getindex(t::TSeries{F}, rng::StepRange{MIT{F},Duration{F}}) where {F<:Frequency}
    start, stop = _ind_range_check(t, rng)
    step = oftype(stop - start, rng.step)
    return t.values[start:step:stop]
end
function Base.getindex(t::TSeries{F}, rng::UnitRange{MIT{F}}) where {F<:Frequency}
    start, stop = _ind_range_check(t, rng)
    return TSeries(first(rng), getindex(t.values, start:stop))
end

Base.setindex!(t::TSeries, ::Number, m::MIT) = mixed_freq_error(t, m)
function Base.setindex!(t::TSeries{F}, v::Number, m::MIT{F}) where {F<:Frequency}
    # @boundscheck checkbounds(t, m)
    if m ∉ rangeof(t)
        # !! resize!() doesn't work for TSeries out of the box. we implement it below. 
        resize!(t, union(m:m, rangeof(t)))
    end
    fi = firstindex(t.values)
    setindex!(t.values, v, fi + oftype(fi, m - firstdate(t)))
end

Base.setindex!(t::TSeries, from::TSeries, m::MIT) = setindex!(t, from[m], m)

Base.setindex!(t::TSeries, ::AbstractVector{<:Number}, rng::AbstractRange{<:MIT}) = mixed_freq_error(t, rng)
function Base.setindex!(t::TSeries{F}, vec::AbstractVector{<:Number}, rng::AbstractRange{MIT{F}}) where {F<:Frequency}
    if !issubset(rng, rangeof(t))
        # !! resize!() doesn't work for TSeries out of the box. we implement it below. 
        resize!(t, union(rangeof(t), rng))
    end
    if rng isa AbstractUnitRange
        start, stop = _ind_range_check(t, rng)
        setindex!(t.values, vec, start:stop)
    elseif rng isa StepRange
        start, stop = _ind_range_check(t, rng)
        setindex!(t.values, vec, start:oftype(stop - start, rng.step):stop)
    else
        fd = firstdate(t)
        fi = firstindex(t.values, 1)
        inds = [oftype(fi, fi + (ind - fd)) for ind in rng]
        setindex!(t.values, vec, inds)
    end
end

Base.setindex!(t::TSeries{F1}, src::TSeries{F2}, rng::AbstractRange{MIT{F3}}) where {F1<:Frequency,F2<:Frequency,F3<:Frequency} = mixed_freq_error(t, src, rng)
Base.setindex!(t::TSeries{F}, src::TSeries{F}, rng::AbstractRange{MIT{F}}) where {F<:Frequency} = copyto!(t, rng, src)

"""
    typenan(x)
    typenan(T)

Return a value that indicates not-a-number of the same type as the given `x` or
of the given type `T`.

For floating point types, this is `NaN`. For integer types, we use `typemax()`.
This is not ideal, but it'll do for now.
"""
function typenan end

typenan(::T) where {T<:Real} = typenan(T)
typenan(T::Type{<:AbstractFloat}) = T(NaN)
typenan(T::Type{<:Integer}) = typemax(T)
typenan(T::Type{<:Union{MIT,Duration}}) = T(typemax(Int64))

"""
    istypenan(x)

Return `true` if the given `x` is a not-n-number of its type, otherwise return
`false`.
"""
istypenan(x) = false
istypenan(::Nothing) = true
istypenan(::Missing) = true
istypenan(x::Integer) = x == typenan(x)
istypenan(x::AbstractFloat) = isnan(x)

# n::Integer - only the length changes. We keep the starting date 
"""
    resize!(t::TSeries, n::Integer)

Extend or shrink the allocated storage for `t` to `n` entries. The first date of
`t` does not change. If allocation is extended, the new entries are set to
`NaN`.
"""
function Base.resize!(t::TSeries, n::Integer)
    lt = length(t)  # the old length 
    if lt ≠ n
        resize!(t.values, Int64(n))
        # fill new locations with NaN
        t.values[lt+1:end] .= typenan(eltype(t))
    end
    return t
end

# if range is given
"""
    resize!(t::TSeries, rng)

Extend or shrink the allocated storage for `t` so that the new range of `t`
equals the given `rng`. If `t` is extended, new entries are set to `NaN`, or the
appropriate Not-A-Number value (see [`typenan`](@ref)).
"""
Base.resize!(t::TSeries, rng::UnitRange{<:MIT}) = mixed_freq_error(t, eltype(rng))
function Base.resize!(t::TSeries{F}, rng::UnitRange{MIT{F}}) where {F<:Frequency}
    orng = rangeof(t)  # old range
    if first(rng) == first(orng)
        # if the beginning doesn't change we fallback on resize!(t, n)
        return resize!(t, length(rng))
    end
    tvals = copy(t.values) # old values - keep them safe for now
    inds_to_copy = intersect(rng, orng)
    # nrng = min(first(rng), first(orng)):max(last(rng), last(orng))
    _do = convert(Int, first(inds_to_copy) - first(rng)) + 1
    _so = convert(Int, first(inds_to_copy) - first(orng)) + 1
    _n = length(inds_to_copy)
    resize!(t.values, length(rng))
    t.firstdate = first(rng)
    # t[begin:first(inds_to_copy) - 1] .= typenan(eltype(t))
    # t[last(inds_to_copy) + 1:end] .= typenan(eltype(t))
    fill!(t.values, typenan(eltype(t)))
    copyto!(t.values, _do, tvals, _so, _n)
    return t
end

#
Base.copyto!(dest::TSeries, src::TSeries) = mixed_freq_error(dest, src)
Base.copyto!(dest::TSeries{F}, src::TSeries{F}) where {F<:Frequency} = copyto!(dest, rangeof(src), src)

#
Base.copyto!(dest::TSeries, drng::AbstractRange{<:MIT}, src::TSeries) = mixed_freq_error(dest, drng, src)
function Base.copyto!(dest::TSeries{F}, drng::AbstractRange{MIT{F}}, src::TSeries{F}) where {F<:Frequency}
    fullindex = union(rangeof(dest), drng)
    resize!(dest, fullindex)
    copyto!(dest.values, Int(first(drng) - firstindex(dest) + 1), src[drng].values, 1, length(drng))
    return dest
end

# nothing

# view with MIT indexing
Base.view(t::TSeries, I::AbstractRange{<:MIT}) = mixed_freq_error(t, I)
@inline function Base.view(t::TSeries{F}, I::AbstractRange{MIT{F}}) where {F<:Frequency}
    fi = firstindex(t.values)
    TSeries(first(I), view(t.values, oftype(fi, first(I) - firstindex(t) + fi):oftype(fi, last(I) - firstindex(t) + fi)))
end

# view with Int indexing
@inline function Base.view(t::TSeries, I::AbstractRange{<:Integer})
    fi = firstindex(t.values)
    TSeries(firstindex(t) + first(I) - one(first(I)), view(t.values, oftype(fi, first(I)):oftype(fi, last(I))))
end

"""
    diff(x::TSeries)
    diff(x::TSeries, k)

Construct the first difference, or the `k`-th difference, of time series `t`. If
`y = diff(x,k)` then `y[t] = x[t] - x[t+k]`. A negative value of `k` means that
we subtract a lag and positive value means that we subtract a lead. `k` not
given is the same as `k=-1`, which matches the standard definition of first
difference.
"""
Base.diff(x::TSeries, k::Integer=-1) = x - lag(x, -k)

function Base.vcat(x::TSeries, args::AbstractVector...)
    return TSeries(firstdate(x), vcat(_vals(x), args...))
end


"""
    pct(x; islog=false)

Observation-to-observation percent rate of change in x.
"""
function pct(ts::TSeries, shift_value::Int=-1; islog::Bool=false)
    if islog
        a = exp.(ts)
        b = shift(exp.(ts), shift_value)
    else
        a = ts
        b = shift(ts, shift_value)
    end

    result = @. ((a - b) / b) * 100

    TSeries(result.firstdate, result.values)
end
export pct

"""
    apct(x::TSeries, islog::Bool)

Annualised percent rate of change in `x`.

Examples
```julia-repl
julia> x = TSeries(qq(2018, 1), Vector(1:8));

julia> apct(x)
TSeries{Quarterly} of length 7
2018Q2: 1500.0
2018Q3: 406.25
2018Q4: 216.04938271604937
2019Q1: 144.140625
2019Q2: 107.35999999999999
2019Q3: 85.26234567901243
2019Q4: 70.59558517284461
```

See also: [`pct`](@ref)
"""
function apct(ts::TSeries{<:YPFrequency{N}}, islog::Bool=false) where {N}
    if islog
        a = exp.(ts)
        b = shift(exp.(ts), -1)
    else
        a = ts
        b = shift(ts, -1)
    end
    return ((a ./ b) .^ N .- 1) * 100
end
export apct
apct(ts::TSeries, args...) = error("apct for frequency $(frequencyof(ts)) not implemented")


"""
    ytypct(x) 

Year-to-year percent change in x. 
"""
ytypct(x) = 100 * (x ./ shift(x, -ppy(x)) .- 1)
export ytypct
