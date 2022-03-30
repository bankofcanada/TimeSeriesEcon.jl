# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# augment arraymath.jl for TSeries

# These are operations that treat a TSeries as a single object (rather than a collection of values indexed by MIT)
# Conceptually we must distinguish these operations from broadcasting (element-wise) operations.

# For example, t + s is valid if t and s are of the same TSeries type (same frequency). 
# The result of t + s is a new TSeries of the same frequency over the common range.
# In practice t + s and t .+ s produce identical results, although conceptually they're different operations.
#
# t + n is not valid because TSeries + Number doesn't work, but we can do t .+ n.
# t + v is not valid because TSeries + Vector doesn't work, but we can do t .+ v so long as length(t) == length(v).
# n*t is valid because Number * TSeries is a valid operation.
# t/n is valid (same as (1/n)*t), but n/t is not because we can't divide a Number by TSeries. We can still do n ./ t.

# function applications are not valid, so we must use dot to broadcast, e.g. log(t) throws an error, we must do log.(t)

Base.promote_shape(a::TSeries, b::TSeries) = mixed_freq_error(a, b)
Base.promote_shape(a::TSeries{F}, b::TSeries{F}) where {F<:Frequency} = intersect(eachindex(a), eachindex(b))

shape_error(A::Type, B::Type) = throw(ArgumentError("This operation is not valid for $(A) and $(B). Try using . to do it element-wise."))
shape_error(a, b) = shape_error(typeof(a), typeof(b))

Base.promote_shape(a::TSeries, b::AbstractVector) = promote_shape(_vals(a), b)
Base.promote_shape(a::AbstractVector, b::TSeries) = promote_shape(a, _vals(b))

# +, -, *, / work out of the box with the above methods for promote_shape.

# @inline function Base.isapprox(x::TSeries, y::TSeries; kwargs...)
#     shape = promote_shape(x, y)
#     isapprox(x[shape].values, y[shape].values; kwargs...)
# end

for func in (:maximum, :minimum)
    @eval begin
        Base.$func(t::TSeries; kwargs...) = $func(t.values; kwargs...)
        Base.$func(f::Function, t::TSeries; kwargs...) = $func(f, t.values; kwargs...)
    end
end

####################################################################
# Now we implement some time-series operations that do not really apply to vectors.


"""
    shift(x::TSeries, n)

Shift the dates of `x` by `n` periods. By convention positive `n` gives the lead
and negative `n` gives the lag. `shift` creates a new [`TSeries`](@ref) and
copies the data over. See [`shift!`](@ref) for in-place version.

For example:
```julia-repl
julia> shift(TSeries(2020Q1, 1:4), 1)
TSeries{Quarterly} of length 4
2019Q4: 1.0
2020Q1: 2.0
2020Q2: 3.0
2020Q3: 4.0


julia> shift(TSeries(2020Q1, 1:4), -1)
TSeries{Quarterly} of length 4
2020Q2: 1.0
2020Q3: 2.0
2020Q4: 3.0
2021Q1: 4.0
```
"""
shift(ts::TSeries, k::Int) = copyto!(TSeries(rangeof(ts) .- k), ts.values)

"""
    shift!(x::TSeries, n)

In-place version of [`shift`](@ref).
"""
shift!(ts::TSeries, k::Int) = (ts.firstdate -= k; ts)

"""
    lag(x::TSeries, k=1)

Shift the dates of `x` by `k` period to produce the `k`-th lag of `x`. This is
the same [`shift(x, -k)`](@ref).
"""
lag(t::TSeries, k::Int=1) = shift(t, -k)

"""
    lag!(x::TSeries, k=1)

In-place version of [`lag`](@ref)
"""
lag!(t::TSeries, k::Int=1) = shift!(t, -k)

"""
    lead(x::TSeries, k=1)

Shift the dates of `x` by `k` period to produce the `k`-th lead of `x`. This is
the same [`shift(x, k)`](@ref).
"""
lead(t::TSeries, k::Int=1) = shift(t, k)

"""
    lead!(x::TSeries, k=1)

In-place version of [`lead`](@ref)
"""
lead!(t::TSeries, k::Int=1) = shift!(t, k)

