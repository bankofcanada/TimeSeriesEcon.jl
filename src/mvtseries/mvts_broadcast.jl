# Copyright (c) 2020-2024, Bank of Canada
# All rights reserved.

using Base.Broadcast


# custom broadcasting style for TSeries
struct MVTSeriesStyle{F<:Frequency} <: Broadcast.BroadcastStyle end
@inline frequencyof(::Type{<:MVTSeriesStyle{F}}) where {F<:Frequency} = F

@inline Base.Broadcast.BroadcastStyle(::Type{<:MVTSeries{F}}) where {F<:Frequency} = MVTSeriesStyle{F}()
@inline Base.Broadcast.BroadcastStyle(S1::MVTSeriesStyle, S2::MVTSeriesStyle) = mixed_freq_error(S1, S2)
@inline Base.Broadcast.BroadcastStyle(S::MVTSeriesStyle{F}, ::MVTSeriesStyle{F}) where {F<:Frequency} = S

# mixing with TSeries - we treat it as a vector column
@inline Base.Broadcast.BroadcastStyle(S1::MVTSeriesStyle, S2::TSeriesStyle) = mixed_freq_error(S1, S2)
@inline Base.Broadcast.BroadcastStyle(S::MVTSeriesStyle{F}, ::TSeriesStyle{F}) where {F<:Frequency} = S

# mixing with other things - we take over as long as we have 2 dimensons or less
@inline Base.Broadcast.BroadcastStyle(S::MVTSeriesStyle, AS::Broadcast.AbstractArrayStyle{N}) where {N} = N <= 2 ? S : AS

function Base.similar(bc::Broadcast.Broadcasted{<:MVTSeriesStyle}, ::Type{ElType}) where {ElType}
    if !isa(bc.axes, Nothing) && length(bc.axes) == 2
        similar(Vector, ElType, bc.axes)
    else
        throw(DimensionMismatch("Cannot create a MVTSeries with axes $(bc.axes)."))
    end
end

@inline Base.Broadcast._eachindex(t::_MVTSAxesType) = CartesianIndices(map(length, t))

#----------------------
# two MVTSeries
function Base.Broadcast.check_broadcast_shape(shp::_MVTSAxesType, A::_MVTSAxesType)
    if any(c ∉ shp[2] for c in A[2])
        throw(DimensionMismatch("Unable to assign to missing destivation columns."))
    end
    if !(A[1] ⊆ shp[1])
        throw(DimensionMismatch("Unable to assign outside destination range."))
    end
end

function Base.Broadcast.broadcast_shape(a::_MVTSAxesType, b::_MVTSAxesType)
    return (intersect(a[1], b[1]), tuple((c for c in a[2] if c in b[2])...),)
end

function Base.Broadcast.preprocess(dest::MVTSeries, x::MVTSeries)
    return Base.Broadcast.preprocess(dest.values, x.values)
end

#----------------------
# one MVTSeries and something else
function Base.Broadcast.check_broadcast_shape(shp::_MVTSAxesType, A::Tuple{})
    Base.Broadcast.check_broadcast_shape((1:length(shp[1]), 1:length(shp[2]),), A)
end

function Base.Broadcast.check_broadcast_shape(shp::_MVTSAxesType, A::Tuple)
    Base.Broadcast.check_broadcast_shape((1:length(shp[1]), 1:length(shp[2]),), A)
end

function Base.Broadcast.broadcast_shape(a::_MVTSAxesType, b::Tuple)
    Base.Broadcast.broadcast_shape((1:length(a[1]), 1:length(a[2])), b)
    return a
end

function Base.Broadcast.check_broadcast_shape(shp::Tuple, A::_MVTSAxesType)
    Base.Broadcast.check_broadcast_shape(shp, (1:length(A[1]), 1:length(A[2]),))
end

function Base.Broadcast.broadcast_shape(b::Tuple, a::_MVTSAxesType)
    Base.Broadcast.broadcast_shape((1:length(a[1]), 1:length(a[2]),), b)
    return a
end

function Base.Broadcast.preprocess(dest::MVTSeries, x::AbstractArray)
    Base.Broadcast.preprocess(_vals(dest), x)
end

function Base.Broadcast.preprocess(dest::MVTSeries, x::Number)
    # Base.Broadcast.extrude(x)
    Base.Broadcast.preprocess(_vals(dest), x)
end

#----------------------
# one MVTSeries and one TSeries

function Base.Broadcast.check_broadcast_shape(shp::_MVTSAxesType, A::_TSAxesType)
    if !(A[1] ⊆ shp[1])
        throw(DimensionMismatch("Unable to assign outside destination range"))
    end
end

function Base.Broadcast.broadcast_shape(a::_MVTSAxesType, b::_TSAxesType)
    return (intersect(a[1], b[1]), a[2],)
end

function Base.Broadcast.check_broadcast_shape(shp::_TSAxesType, A::_MVTSAxesType)
    if !(A[1] ⊆ shp[1])
        throw(DimensionMismatch("Unable to assign outside destination range"))
    end
    if length(A[2]) != 1
        throw(DimensionMismatch("Unable to assign MVTSeries into a TSeries unless it has one column."))
    end
end

function Base.Broadcast.broadcast_shape(b::_TSAxesType, a::_MVTSAxesType)
    return (intersect(a[1], b[1]), a[2],)
end


function Base.Broadcast.preprocess(dest::MVTSeries, x::TSeries)
    Base.Broadcast.preprocess(_vals(dest), _vals(x))
end

# We need code that unwraps the MVTSeries into a plain array, but with the appropriate slice to align dates
begin
    # recursively visit each Broadcasted argument and unwrap TSeries and MVTSeries
    mvts_unwrap(::_MVTSAxesType, arg) = arg
    function mvts_unwrap(ax::_MVTSAxesType, arg::TSeries)
        rng1 = rangeof(arg)
        rng2 = ax[1]
        if rng1 == rng2
            return _vals(arg)
        else
            inds = convert(Int, first(rng2) - first(rng1)) .+ (1:length(rng2))
            return view(_vals(arg), inds)
        end
    end
    function mvts_unwrap(ax::_MVTSAxesType, arg::MVTSeries)
        # assumption is that if we're here then ax is a subset of axes(args)
        rng1, nms1 = axes(arg)
        rng2, nms2 = ax
        if rng1 == rng2 && nms1 == nms2
            return _vals(arg)
        else
            if rng1 == rng2
                return view(_vals(arg), :, _colind(arg, nms2))
            end
            i1 = convert(Int, first(rng2) - first(rng1)) .+ (1:length(rng2))
            if nms1 == nms2
                return view(_vals(arg), i1, :)
            else
                return view(_vals(arg), i1, _colind(arg, nms2))
            end
        end
    end
    function mvts_unwrap(ax::_MVTSAxesType, bc::Base.Broadcast.Broadcasted{Style}) where {Style}
        Base.Broadcast.Broadcasted{Style}(bc.f, mvts_unwrap_args(ax, bc.args), bc.axes)
    end

    mvts_unwrap(ax::Tuple{<:AbstractVector{<:MIT},<:_MVTSAxes2}, arg) = arg
    mvts_unwrap(ax::Tuple{<:AbstractVector{<:MIT},<:_MVTSAxes2}, arg::TSeries) = view(arg, ax[1])
    mvts_unwrap(ax::Tuple{<:AbstractVector{<:MIT},<:_MVTSAxes2}, arg::MVTSeries) = view(arg, ax...)

    # Tuple recursion boilerplate
    mvts_unwrap_args(ax, ::Tuple{}) = ()
    mvts_unwrap_args(ax, a::Tuple{<:Any}) = (mvts_unwrap(ax, a[1]),)
    mvts_unwrap_args(ax, a::Tuple) = (mvts_unwrap(ax, a[1]), mvts_unwrap_args(ax, Base.tail(a))...)

end


function Base.Broadcast.preprocess(dest::MVTSeries, bc::Base.Broadcast.Broadcasted)
    rng, nms = bc.axes
    bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, mvts_unwrap_args(bc.axes, bc.args), (1:length(rng), 1:length(nms),))
    Base.Broadcast.preprocess(dest.values, bc1)
end

#############################################################################


function Base.Broadcast.materialize!(::MVTSeriesStyle, dest, bc::Base.Broadcast.Broadcasted)
    return copyto!(dest, Base.Broadcast.instantiate(bc))
end


function Base.copyto!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{Nothing,_MVTSAxesType})
    rng, nms = bc.axes
    bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, mvts_unwrap_args(bc.axes, bc.args), (1:length(rng), 1:length(nms),))
    copyto!(dest, Base.Broadcast.preprocess(dest, bc1))
end

function Base.copyto!(dest::SubArray{T,2,<:MVTSeries}, bc::Base.Broadcast.Broadcasted{Nothing,<:_MVTSAxesType}) where {T}
    bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, mvts_unwrap_args(dest.indices, bc.args), map(Base.axes1, dest.indices))
    copyto!(dest, Base.Broadcast.preprocess(dest, bc1))
end

function Base.copyto!(dest::SubArray{T,2,<:MVTSeries}, bc::Base.Broadcast.Broadcasted{Nothing}) where {T}
    copyto!(view(dest.parent, dest.indices...), Base.Broadcast.preprocess(dest, bc))
end



function Base.copyto!(dest::MVTSeries, bc::Base.Broadcast.Broadcasted{Nothing})
    dest_rng, dest_nms = axes(dest)
    bcax = axes(bc)
    if bcax isa _MVTSAxesType
        # common range
        if dest_rng == bcax[1]
            rng = dest_rng
            i1 = Colon()
        else
            rng = intersect(dest_rng, bcax[1])
            i1 = convert(Int, first(rng) - first(dest_rng)) .+ (1:length(rng))
        end
        # common names
        if dest_nms == bcax[2]
            nms = dest_nms
            i2 = Colon()
        else
            nms = tuple((n for n in bcax[2] if n in dest_nms)...)
            i2 = _colind(dest, nms)
        end
        bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, mvts_unwrap_args((rng, nms,), bc.args), (1:length(rng), 1:length(nms),))
        copyto!(view(_vals(dest), i1, i2), Base.Broadcast.preprocess(_vals(dest), bc1))
    elseif bcax isa _TSAxesType
        # common range
        if dest_rng == bcax[1]
            rng = dest_rng
            i1 = Colon()
        else
            rng = intersect(dest_rng, bcax[1])
            i1 = convert(Int, first(rng) - first(dest_rng)) .+ (1:length(rng))
        end
        nms = dest_nms
        i2 = Colon()
        bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, mvts_unwrap_args((rng, nms,), bc.args), (1:length(rng), 1:length(nms),))
        copyto!(view(_vals(dest), i1, i2), Base.Broadcast.preprocess(_vals(dest), bc1))
    elseif length(bcax) == 1
        if length(dest_rng) == length(bcax[1]) && length(dest_nms) == 1
            copyto!(view(_vals(dest), :, 1), bc)
        elseif length(dest_rng) == 1 && length(dest_nms) == length(bcax[1])
            copyto!(view(_vals(dest), 1, :), bc)
        else
            copyto!(dest.values, bc)
        end
    else
        bc1 = Base.Broadcast.Broadcasted{Nothing}(bc.f, bc.args, (1:length(dest_rng), 1:length(dest_nms),))
        copyto!(dest.values, bc1)
    end
    return dest
end

#############################################################################

function Base.reindex(index::Tuple{<:AbstractVector{<:MIT},<:AbstractVector{Symbol}}, sub::Tuple{Int,Int})
    Base.@_propagate_inbounds_meta
    return (index[1][sub[1]], index[2][sub[2]])
end

Base.OneTo{T}(r::Base.OneTo{<:Duration}) where {T<:Integer} = Base.OneTo{T}(T(r.stop))


function Base.Broadcast.dotview(x::MVTSeries, rng::AbstractVector{<:MIT}, ::Colon=Colon())
    return Base.Broadcast.dotview(x, rng, axes(x, 2))
end

function Base.Broadcast.dotview(x::MVTSeries, rng::Union{MIT, AbstractUnitRange{<:MIT}}, cols::_SymbolOneOrCollection)
    return Base.maybeview(x, rng, cols)
end

@generated function Base.Broadcast.dotview(x::MVTSeries, rng::_MITOneOrVector, cols::_SymbolOneOrCollection)
    if cols <: NTuple
        return :(SubArray(x, (rng, collect(cols))))
    else
        return :(SubArray(x, (rng, cols)))
    end
end

