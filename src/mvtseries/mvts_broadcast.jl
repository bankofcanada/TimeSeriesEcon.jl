# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using Base.Broadcast


# custom broadcasting style for TSeries
struct MVTSeriesStyle{F<:Frequency} <: Broadcast.BroadcastStyle end
@inline frequencyof(::Type{<:MVTSeriesStyle{F}}) where {F<:Frequency} = F

@inline Base.Broadcast.BroadcastStyle(::Type{<:MVTSeries{F}}) where {F<:Frequency} = MVTSeriesStyle{F}()
@inline Base.Broadcast.BroadcastStyle(S1::MVTSeriesStyle, S2::MVTSeriesStyle) = mixed_freq_error(S1, S2)
@inline Base.Broadcast.BroadcastStyle(S::MVTSeriesStyle{F}, ::MVTSeriesStyle{F}) where {F<:Frequency} = S

# mixing with TSeries - we treat is as a vector column
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

# disable extrusion
@inline Base.Broadcast.extrude(x::MVTSeries) = x
@inline Base.Broadcast.extrude(x::TSeries) = x

const MVTSeriesIndexType = Tuple{UnitRange{<:MIT},NTuple{N,Symbol}} where {N}

@inline mvts_get_index(x::Number, p::MIT, c::Symbol) = x
@inline mvts_get_index(x::MVTSeries, p::MIT, c::Symbol) = x[p, c]
@inline mvts_get_index(x::TSeries, p::MIT, c::Symbol) = x[p]
@inline mvts_get_index(x::Base.Broadcast.Broadcasted, p::MIT, c::Symbol) = x[p, c]

function Base.Broadcast.getindex(bc::Base.Broadcast.Broadcasted, p::MIT, c::Symbol)
    args = (mvts_get_index(arg, p, c) for arg in bc.args)
    return bc.f(args...)
end

function Base.copyto!(dest::MVTSeries, bc::Broadcast.Broadcasted{Nothing})
    bc′ = Base.Broadcast.preprocess(dest, bc)
    bcrng, bcvars = axes(bc)
    xrng, xvars = axes(dest)
    for (p, c) in Iterators.product(intersect(bcrng, xrng), intersect(bcvars, xvars))
        @inbounds dest[p, c] = bc′[p, c]
    end
    return dest
end

function do_instantiate(bc)
    shape = mvts_combine_axes(bc.args...)
    if bc.axes !== nothing
        shape = mvts_broadcast_shape(bc.axes, shape)
    end
    mvts_instantiate(bc, shape)
end

@inline function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {N,S<:Base.Broadcast.BroadcastStyle,A<:Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}}
    do_instantiate(bc)
end

@inline function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {N,S<:Base.Broadcast.AbstractArrayStyle{0},A<:Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}}
    do_instantiate(bc)
end

@inline function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,Nothing}) where {S<:MVTSeriesStyle}
    do_instantiate(bc)
end

# combine_axes works recursively
@inline mvts_combine_axes(A) = axes(A)
@inline mvts_combine_axes(A, B) = mvts_broadcast_shape(axes(A), axes(B))
@inline mvts_combine_axes(A, B...) = mvts_broadcast_shape(axes(A), mvts_combine_axes(B...))

@inline mvts_broadcast_shape(shape::Tuple) = shape
@inline mvts_broadcast_shape(::Tuple{}, shape::Tuple{}) = shape
@inline mvts_broadcast_shape(::Tuple{}, shape::Tuple) = shape
@inline mvts_broadcast_shape(shape::Tuple, ::Tuple{}) = shape
@inline mvts_broadcast_shape(shape1::Tuple{A}, shape2::Tuple) where {A} = mvts_broadcast_shape(shape2, shape1)
function mvts_broadcast_shape(shape1::Tuple, shape2::Tuple)
    if length(shape1) > 2 || length(shape2) > 2
        throw(ArgumentError("broadcasting MVTSeries with ndims > 2."))
    end
    return (mit_common_axes(shape1[1], shape2[1]),
        length(shape2) == 1 ? shape1[2] : sym_common_axes(shape1[2], shape2[2]),
    )
end

@inline mit_common_axes(a::UnitRange{<:MIT}, b::Base.OneTo) =
    length(b) == 1 || length(b) == length(a) ? a :
    throw(DimensionMismatch("Cannot broadcast with $a and $b."))

# mit_common_axes is the same as in TSeries
@inline sym_common_axes(a::NTuple{N1,Symbol}, b::NTuple{N2,Symbol}) where {N1,N2} = a == b ? a : tuple(intersect(a, b)...)
@inline sym_common_axes(a::NTuple{N,Symbol}, b::Any) where {N} = length(a) == length(b) && first(b) == 1 ? a : throw(DimensionMismatch("Cannot broadcast with $(a) and $b."))
@inline sym_common_axes(a::Any, b::NTuple{N,Symbol}) where {N} = sym_common_axes(b, a)


function mvts_instantiate(bc::Base.Broadcast.Broadcasted{S}, shape) where {S<:Base.Broadcast.BroadcastStyle}
    args = map(bc.args) do arg
        mvts_check_axes(shape, arg)
    end
    return Base.Broadcast.Broadcasted{S}(bc.f, args, shape)
end

struct MVTSBroadcasted{Axes,BC}
    singleton::Tuple{Bool,Bool}
    shape::Axes
    bc::BC
    function MVTSBroadcasted(shape, bc)
        bcshape = axes(bc)
        singleton = length(bcshape) == 0 ? (true, true) :
                    length(bcshape) == 1 ? (length(bcshape[1]) == 1, true) :
                    (length(bcshape[1]) == 1, length(bcshape[2]) == 1)
        # bc1 = Base.Broadcast.instantiate(bc)
        new{typeof(shape),typeof(bc)}(singleton, shape, bc)
    end
end

@inline Base.eltype(x::MVTSBroadcasted) = Base.Broadcast.combine_eltypes(x.bc.f, x.bc.args)

function mvts_get_index(x::MVTSBroadcasted, p::MIT, c::Symbol)
    ip = x.singleton[1] ? 1 : Int(p - first(x.shape[1]) + 1)
    ic = x.singleton[2] ? 1 : indexin([c], collect(x.shape[2]))[1]
    ind = CartesianIndex(ip, ic)
    x.bc[ind]
end

# nested broadcasts are processed recursively
@inline mvts_check_axes(shape::MVTSeriesIndexType, bc::Base.Broadcast.Broadcasted{<:MVTSeriesStyle}) = mvts_instantiate(bc, shape)
@inline mvts_check_axes(shape::MVTSeriesIndexType, bc::Base.Broadcast.Broadcasted{<:TSeriesStyle}) = mvts_instantiate(bc, shape)
@inline mvts_check_axes(shape::MVTSeriesIndexType, bc::Base.Broadcast.Broadcasted) = MVTSBroadcasted(shape, bc)

# MVTSs are left alone. If axes are wrong it'll error when indexing later.
@inline mvts_check_axes(shape::MVTSeriesIndexType, x::MVTSeries) = x
# TSeries are also left alone
@inline mvts_check_axes(shape::MVTSeriesIndexType, x::TSeries) = x
# Leave numbers alone too
@inline mvts_check_axes(shape::MVTSeriesIndexType, x::Number) = x
# For Vector, we wrap it in a TSeries
@inline mvts_check_axes(shape::MVTSeriesIndexType, x::AbstractVector) = TSeries(shape[1], x)
# For Matrix, we wrap them in an MVTSeries with the same dimensions
@inline mvts_check_axes(shape::MVTSeriesIndexType, x::AbstractMatrix) = MVTSeries(first(shape[1]), shape[2], x)



function Base.axes(bc::Base.Broadcast.Broadcasted{<:MVTSeriesStyle})
    bc.axes === nothing ? mvts_combine_axes(bc.args...) : bc.axes
end

function Base.axes(bc::Base.Broadcast.Broadcasted{<:MVTSeriesStyle}, d::Integer)
    1 <= d <= 2 ? axes(bc)[d] : Base.OneTo(1)
end
