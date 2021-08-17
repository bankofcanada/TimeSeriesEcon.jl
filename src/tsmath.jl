# Copyright (c) 2020-2021, Bank of Canada
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

@inline Base.promote_shape(a::TSeries, b::TSeries) = mixed_freq_error(a, b)
@inline Base.promote_shape(a::TSeries{F}, b::TSeries{F}) where F <: Frequency = intersect(eachindex(a), eachindex(b))

@inline shape_error(A::Type,B::Type) = throw(ArgumentError("This operation is not valid for $(A) and $(B). Try using . to do it element-wise."))
@inline shape_error(a,b) = shape_error(typeof(a), typeof(b))

@inline Base.promote_shape(a::TSeries, b::AbstractVector) = shape_error(a, b)
@inline Base.promote_shape(a::AbstractVector, b::TSeries) = shape_error(a, b)

# +, -, *, / work out of the box with the above methods for promote_shape.

@inline function Base.isapprox(x::TSeries, y::TSeries; kwargs...)
    shape = promote_shape(x, y)
    isapprox(x[shape].values, y[shape].values; kwargs...)
end


####################################################################
# Now we implement some time-series operations that do not really apply to vectors.


@inline shift(ts::TSeries, k::Int) = TSeries(ts.firstdate - k, copy(ts.values))
@inline shift!(ts::TSeries, k::Int) = (ts.firstdate -= k; ts)
@inline lag(t::TSeries, k::Int=1) = shift(t, -k)
@inline lag!(t::TSeries, k::Int=1) = shift!(t, -k)
@inline lead(t::TSeries, k::Int=1) = shift(t, k)
@inline lead!(t::TSeries, k::Int=1) = shift!(t, k)

"""
    shift(x, n)
    shift!(x, n)
    lag(x, n=1)
    lag!(x, n=1)
    lead(x, n=1)
    lead!(x, n=1)

Shift, lag or lead the TSeries `x` by `n` periods.     
By convention `shift` is the same as `lead` while `lag(x,n)` is the same as `shift(x, -n)`.
The versions ending in ! do it in place, while the others create a new TSeries instance.

Examples
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

julia> x = TSeries(2020Q1, 1:4);

julia> shift!(x, 1);

julia> x
TSeries{Quarterly} of length 4
2019Q4: 1.0
2020Q1: 2.0
2020Q2: 3.0
2020Q3: 4.0
```
"""
shift, shift!, lead, lead!, lag, lag!



