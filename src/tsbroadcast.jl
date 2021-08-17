# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using Base.Broadcast

# custom broadcasting style for TSeries
struct TSeriesStyle{F <: Frequency} <: Broadcast.BroadcastStyle end
frequencyof(::Type{<:TSeriesStyle{F}}) where F <: Frequency = F

Base.Broadcast.BroadcastStyle(::Type{<:TSeries{F}}) where F <: Frequency = TSeriesStyle{F}()
Base.Broadcast.BroadcastStyle(S1::TSeriesStyle, S2::TSeriesStyle) = mixed_freq_error(S1, S2)
Base.Broadcast.BroadcastStyle(S::TSeriesStyle{F}, ::TSeriesStyle{F}) where F <: Frequency = S
Base.Broadcast.BroadcastStyle(S::TSeriesStyle, AS::Broadcast.AbstractArrayStyle{N}) where N = N <= 1 ? S : AS

Base.similar(bc::Broadcast.Broadcasted{<:TSeriesStyle}, ::Type{ElType}) where ElType = 
    !isa(bc.axes, Nothing) && length(bc.axes) == 1 ? similar(Vector, ElType, bc.axes) : throw(DimensionMismatch("Cannot create a TSeries with axes $axes."))

# This so far is sufficient to do things like `t .+ 5` and even `t1 .+ t2` when `t1` and `t2` have identical axes.

# now we want to do things like `t .+ v` where `v` is a non-TSeries vector of the same length
# we also want to do `t1 .+ t2` when t1 and t2 are of the same frequency but may have different ranges. 
#   in this case the operation will reduce itself to the common range. 
# we also want to do `s .= t1 .+ t2` where all three are of the same frequency but may have 
#  different axes ranges. In this case the operation on t1 and t2 is done over their common range and 
#  the result is stored in s over the same range. If the original range of s is smaller, it gets 
# resized to include the broadcasted range. If the original range of s is already larger, then 
# values outside the broadcasted range are left unchanged.


# figure out the axes range of the result of the broadcast operation
@inline my_combine_axes(A, B...) = my_broadcast_shape(axes(A), my_combine_axes(B...))
@inline my_combine_axes(A, B) = my_broadcast_shape(axes(A), axes(B))
my_combine_axes(A) = axes(A)

my_broadcast_shape(shape::Tuple) = shape
my_broadcast_shape(::Tuple{}, shape::Tuple) = shape
my_broadcast_shape(shape::Tuple, ::Tuple{}) = shape
function my_broadcast_shape(shape1::Tuple, shape2::Tuple) 
    length(shape1) > 1 || length(shape2) > 1 ? 
        throw(ArgumentError("broadcasting TSeries with ndims > 1.")) : 
        (_common_axes(shape1[1], shape2[1]),)
end

_common_axes(a::AbstractRange{<:MIT}, b::AbstractRange{<:MIT}) = mixed_freq_error(a, b)
_common_axes(a::AbstractRange{MIT{F}}, b::AbstractRange{MIT{F}}) where F <: Frequency = intersect(a, b)
_common_axes(a::AbstractRange{<:MIT}, b::Any) = length(a) == length(b) && first(b) == 1 ? a : throw(DimensionMismatch("Cannot broadcast with $(a) and $b."))
_common_axes(a::Any, b::AbstractRange{<:MIT}) = _common_axes(b, a)

# given the broadcasted range in `shape`, check that all arguments are of compatible shapes and convert the non-TSeries to 
# TSeries with the appropriate range.  This is necessary because the indexing of the broadcast is done using the MIT ranges, so
# plain vectors must be viewed as TSeries.
my_check_axes(shape, x) = x  # fallback for Number and other things. 
@inline my_check_axes(shape, t::TSeries) = 
    shape == axes(t) ? t : 
        # if the axes are not identical, we create a "view" into the broadcasted range
        TSeries(first(shape[1]), view(t.values, Int(first(shape[1]) - firstindex(t)) .+ (1:length(shape[1]))))
# For vectors other than TSeries, we create a "view" as a TSeries with the broadcasted rang
@inline my_check_axes(shape, t::AbstractVector) = TSeries(first(shape[1]), view(t, Base.OneTo(length(shape[1]))))
# For nested broadcasted argument, we process the same way recursively. 
my_check_axes(shape, bc::BC) where BC <: Base.Broadcast.Broadcasted = do_instantiate(bc, shape)

function do_instantiate(bc::Base.Broadcast.Broadcasted{S}, shape) where S <: Base.Broadcast.BroadcastStyle
    args = map(bc.args) do arg
        my_check_axes(shape, arg)
    end
    return Base.Broadcast.Broadcasted{S}(bc.f, args, shape)
end

function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,Nothing}) where S <: TSeriesStyle
    shape = my_combine_axes(bc.args...)
    do_instantiate(bc, shape)
end

# the following two specializations are necessary in order to be able to have destination on the left of .= that has a different range than the broadcasted result on the rigth
function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {S <: Base.Broadcast.BroadcastStyle,A <: Tuple{<:AbstractRange{<:MIT}}}
    shape = my_combine_axes(bc.args...)
    do_instantiate(bc, (intersect(bc.axes[1], shape[1]),))
end
    
function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {S <: TSeriesStyle,A <: Tuple{<:AbstractRange{<:MIT}}}
    shape = my_combine_axes(bc.args...)
    do_instantiate(bc, (intersect(bc.axes[1], shape[1]),))
end

function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {S <: Base.Broadcast.AbstractArrayStyle{0},A <: Tuple{<:AbstractRange{<:MIT}}}
    bc
end

function Base.axes(bc::Base.Broadcast.Broadcasted{<:TSeriesStyle})
    bc.axes === nothing ? my_combine_axes(bc.args...) : bc.axes
end

function Base.axes(bc::Base.Broadcast.Broadcasted{<:TSeriesStyle}, d::Integer)
    d == 1 ? axes(bc)[1] : Base.OneTo(1)
end

# this specialization allows for the result to be stored in a TSeries
function Base.copyto!(dest::TSeries, bc::Base.Broadcast.Broadcasted{Nothing})
    bcrng = bc.axes[1]
    drng = eachindex(dest)
    if frequencyof(drng) != frequencyof(bcrng)
        mixed_freq_error(drng, bcrng)
    end
    bc′ = Base.Broadcast.preprocess(dest, bc)
    @simd for I = intersect(bcrng, drng)
        @inbounds dest[I] = bc′[I]
    end
    return dest
end

function Base.Broadcast.dotview(t::TSeries, rng::UnitRange{<:MIT})
    rng ⊆ eachindex(t) ? Base.maybeview(t, rng) : Base.maybeview(resize!(t, union(eachindex(t), rng)), rng)
end
