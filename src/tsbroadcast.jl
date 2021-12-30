# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using Base.Broadcast

# custom broadcasting style for TSeries
struct TSeriesStyle{F<:Frequency} <: Broadcast.BroadcastStyle end
frequencyof(::Type{<:TSeriesStyle{F}}) where {F<:Frequency} = F

Base.Broadcast.BroadcastStyle(::Type{<:TSeries{F}}) where {F<:Frequency} = TSeriesStyle{F}()
Base.Broadcast.BroadcastStyle(S1::TSeriesStyle, S2::TSeriesStyle) = mixed_freq_error(S1, S2)
Base.Broadcast.BroadcastStyle(S::TSeriesStyle{F}, ::TSeriesStyle{F}) where {F<:Frequency} = S
Base.Broadcast.BroadcastStyle(S::TSeriesStyle, AS::Broadcast.AbstractArrayStyle{N}) where {N} = N <= 1 ? S : AS

function Base.similar(bc::Broadcast.Broadcasted{<:TSeriesStyle}, ::Type{ElType}) where {ElType}
    if !isa(bc.axes, Nothing) && length(bc.axes) == 1
        return similar(Vector, ElType, bc.axes)
    else
        throw(DimensionMismatch("Cannot create a TSeries with axes $axes."))
    end
end

const _TSAxesType = Tuple{<:AbstractUnitRange{<:MIT}}

@inline Base.Broadcast._eachindex(t::_TSAxesType) = 1:length(t[1])

#----------------------
# two TSeries


function Base.Broadcast.check_broadcast_shape(shp::_TSAxesType, A::_TSAxesType)
    if !(A[1] ⊆ shp[1])
        throw(DimensionMismatch("Unable to assign outside destination range"))
    end
end

function Base.Broadcast.broadcast_shape(a::_TSAxesType, b::_TSAxesType)
    return (intersect(a[1], b[1]),)
end

function Base.Broadcast.preprocess(dest::TSeries, x::TSeries)
    Base.Broadcast.preprocess(dest.values, x.values)
end

#----------------------
# one TSeries and something else
function Base.Broadcast.check_broadcast_shape(shp::_TSAxesType, A::Tuple{})
    Base.Broadcast.check_broadcast_shape((1:length(shp[1]),), A)
end

function Base.Broadcast.check_broadcast_shape(shp::_TSAxesType, A::Tuple)
    Base.Broadcast.check_broadcast_shape((1:length(shp[1]),), A)
end

function Base.Broadcast.broadcast_shape(a::_TSAxesType, b::Tuple)
    Base.Broadcast.broadcast_shape((1:length(a[1]),), b)
    return a
end

function Base.Broadcast.check_broadcast_shape(shp::Tuple, A::_TSAxesType)
    Base.Broadcast.check_broadcast_shape(shp, (1:length(A[1]),))
end

function Base.Broadcast.broadcast_shape(b::Tuple, a::_TSAxesType)
    Base.Broadcast.broadcast_shape((1:length(a[1]),), b)
    return a
end

function Base.Broadcast.preprocess(dest::TSeries, x::AbstractArray)
    Base.Broadcast.preprocess(dest.values, x)
end

function Base.Broadcast.preprocess(dest::TSeries, x::Number)
    # Base.Broadcast.extrude(x)
    Base.Broadcast.preprocess(dest.values, x)
end

# We need code that unwraps the TSeries into a plain Vector, 
# but with the appropriate slice to align dates
begin
    ts_unwrap(ax::_TSAxesType, arg) = arg
    function ts_unwrap(ax::_TSAxesType, arg::TSeries)
        rng1 = rangeof(arg)
        rng2 = ax[1]
        return (rng1 == rng2) ?
               arg.values :
               view(arg.values, convert(Int, first(rng2) - first(rng1)) .+ (1:length(rng2)))
    end
    function ts_unwrap(ax::_TSAxesType, bc::Base.Broadcast.Broadcasted{Style}) where {Style}
        Base.Broadcast.Broadcasted{Style}(bc.f, ts_unwrap_args(ax, bc.args), bc.axes)
    end

    ts_unwrap_args(ax::_TSAxesType, ::Tuple{}) = ()
    ts_unwrap_args(ax::_TSAxesType, a::Tuple{<:Any}) = (ts_unwrap(ax, a[1]),)
    ts_unwrap_args(ax::_TSAxesType, a::Tuple) = (ts_unwrap(ax, a[1]), ts_unwrap_args(ax, Base.tail(a))...)
end

function Base.Broadcast.preprocess(dest::TSeries, bc::Base.Broadcast.Broadcasted)
    rng = bc.axes[1]
    bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, ts_unwrap_args(bc.axes, bc.args), (1:length(rng),))
    Base.Broadcast.preprocess(dest.values, bc1)
end

#############################################################################

function Base.Broadcast.materialize!(::TSeriesStyle, dest, bc::Base.Broadcast.Broadcasted)
    return copyto!(dest, Base.Broadcast.instantiate(bc))
end

function Base.copyto!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{Nothing,_TSAxesType})
    rng = bc.axes[1]
    bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, ts_unwrap_args(bc.axes, bc.args), (1:length(rng),))
    copyto!(dest, Base.Broadcast.preprocess(dest, bc1))
end

function Base.copyto!(dest::TSeries, bc::Base.Broadcast.Broadcasted{Nothing})
    dest_rng = rangeof(dest)
    bcax = axes(bc)
    if length(bcax) != 1
        error("We got axes(bc) = $bcax with dest in $(rangeof(dest))")
    end
    if bcax[1] isa AbstractUnitRange{<:MIT}
        # common range
        rng = intersect(dest_rng, bcax[1])
        dest_inds = convert(Int, first(rng) - first(dest_rng)) .+ (1:length(rng))
        bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, ts_unwrap_args((rng,), bc.args), (1:length(rng),))
        copyto!(view(dest.values, dest_inds), Base.Broadcast.preprocess(dest.values, bc1))
    else
        copyto!(dest.values, bc)
    end
    return dest
end

function Base.Broadcast.dotview(t::TSeries, rng::AbstractUnitRange{<:MIT})
    rng ⊆ eachindex(t) ? Base.maybeview(t, rng) :
    Base.maybeview(resize!(t, union(eachindex(t), rng)), rng)
end

#############################################################################
# OLD IMPLEMENTATION
#############################################################################




# # This so far is sufficient to do things like `t .+ 5` and even `t1 .+ t2` when `t1` and `t2` have identical axes.

# # now we want to do things like `t .+ v` where `v` is a non-TSeries vector of the same length
# # we also want to do `t1 .+ t2` when t1 and t2 are of the same frequency but may have different ranges. 
# #   in this case the operation will reduce itself to the common range. 
# # we also want to do `s .= t1 .+ t2` where all three are of the same frequency but may have 
# #  different axes ranges. In this case the operation on t1 and t2 is done over their common range and 
# #  the result is stored in s over the same range. If the original range of s is smaller, it gets 
# # resized to include the broadcasted range. If the original range of s is already larger, then 
# # values outside the broadcasted range are left unchanged.


# # figure out the axes range of the result of the broadcast operation
# @inline ts_combine_axes(A, B...) = ts_broadcast_shape(axes(A), ts_combine_axes(B...))
# @inline ts_combine_axes(A, B) = ts_broadcast_shape(axes(A), axes(B))
# @inline ts_combine_axes(A) = axes(A)

# ts_broadcast_shape(shape::Tuple) = shape
# ts_broadcast_shape(::Tuple{}, shape::Tuple) = shape
# ts_broadcast_shape(shape::Tuple, ::Tuple{}) = shape
# function ts_broadcast_shape(shape1::Tuple, shape2::Tuple) 
#     if length(shape1) > 1 || length(shape2) > 1 
#         throw(ArgumentError("broadcasting TSeries with ndims > 1.")) 
#     else
#         return (mit_common_axes(shape1[1], shape2[1]),)
#     end
# end

# mit_common_axes(a::AbstractRange{<:MIT}, b::AbstractRange{<:MIT}) = mixed_freq_error(a, b)
# mit_common_axes(a::AbstractRange{MIT{F}}, b::AbstractRange{MIT{F}}) where F <: Frequency = intersect(a, b)
# mit_common_axes(a::AbstractRange{<:MIT}, b::Any) = length(a) == length(b) && first(b) == 1 ? a : throw(DimensionMismatch("Cannot broadcast with $(a) and $b."))
# mit_common_axes(a::Any, b::AbstractRange{<:MIT}) = mit_common_axes(b, a)

# # given the broadcasted range in `shape`, check that all arguments are of compatible shapes and convert the non-TSeries to 
# # TSeries with the appropriate range.  This is necessary because the indexing of the broadcast is done using the MIT ranges, so
# # plain vectors must be viewed as TSeries.
# ts_check_axes(shape, x) = x  # fall back for Number and other things. 
# @inline ts_check_axes(shape, t::TSeries) = 
#     shape == axes(t) ? t : 
#         # if the axes are not identical, we create a "view" into the broadcasted range
#         TSeries(first(shape[1]), view(t.values, Int(first(shape[1]) - firstindex(t)) .+ (1:length(shape[1]))))
# # For vectors other than TSeries, we create a "view" as a TSeries with the broadcasted range
# @inline ts_check_axes(shape, t::AbstractVector) = TSeries(first(shape[1]), view(t, Base.OneTo(length(shape[1]))))
# # For nested broadcasted argument, we process the same way recursively. 
# ts_check_axes(shape, bc::BC) where BC <: Base.Broadcast.Broadcasted = ts_instantiate(bc, shape)

# function ts_instantiate(bc::Base.Broadcast.Broadcasted{S}, shape) where S <: Base.Broadcast.BroadcastStyle
#     args = map(bc.args) do arg
#         ts_check_axes(shape, arg)
#     end
#     return Base.Broadcast.Broadcasted{S}(bc.f, args, shape)
# end

# function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,Nothing}) where S <: TSeriesStyle
#     shape = ts_combine_axes(bc.args...)
#     ts_instantiate(bc, shape)
# end

# # the following two specializations are necessary in order to be able to have destination on the left of .= that has a different range than the broadcasted result on the right
# function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {S <: Base.Broadcast.BroadcastStyle,A <: Tuple{<:AbstractRange{<:MIT}}}
#     shape = ts_combine_axes(bc.args...)
#     I = mit_common_axes(bc.axes[1], shape[1])
#     ts_instantiate(bc, (I,))
# end

# # function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {S <: TSeriesStyle,A <: Tuple{<:AbstractRange{<:MIT}}}
# #     shape = my_combine_axes(bc.args...)
# #     I = _common_axes(bc.axes[1], shape[1])
# #     ts_instantiate(bc, (I,))
# # end

# function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {S <: Base.Broadcast.AbstractArrayStyle{0},A <: Tuple{<:AbstractRange{<:MIT}}}
#     bc
# end

# function Base.axes(bc::Base.Broadcast.Broadcasted{<:TSeriesStyle})
#     bc.axes === nothing ? ts_combine_axes(bc.args...) : bc.axes
# end

# function Base.axes(bc::Base.Broadcast.Broadcasted{<:TSeriesStyle}, d::Integer)
#     d == 1 ? axes(bc)[1] : Base.OneTo(1)
# end

# @inline ts_get_index(x, p::MIT) = x[]
# @inline ts_get_index(x::TSeries, p::MIT) = x[p]
# @inline ts_get_index(x::Base.Broadcast.Broadcasted, p::MIT) = x[p]

# function Base.Broadcast.getindex(bc::Base.Broadcast.Broadcasted, p::MIT)
#     args = (ts_get_index(arg, p) for arg in bc.args)
#     return bc.f(args...)
# end

# # this specialization allows for the result to be stored in a TSeries
# function Base.copyto!(dest::TSeries, bc::Base.Broadcast.Broadcasted{Nothing})
#     bcrng = bc.axes[1]
#     drng = eachindex(dest)
#     if frequencyof(drng) != frequencyof(bcrng)
#         mixed_freq_error(drng, bcrng)
#     end
#     bc′ = Base.Broadcast.preprocess(dest, bc)
#     @simd for I = intersect(bcrng, drng)
#         @inbounds dest[I] = bc′[I]
#     end
#     return dest
# end

# function Base.Broadcast.dotview(t::TSeries, rng::UnitRange{<:MIT})
#     rng ⊆ eachindex(t) ? Base.maybeview(t, rng) : Base.maybeview(resize!(t, union(eachindex(t), rng)), rng)
# end
