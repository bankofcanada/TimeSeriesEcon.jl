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
    if rng ⊈ eachindex(t)
        resize!(t, eachindex(t) ∪ rng)
    end
    return Base.maybeview(t, rng) 
end

