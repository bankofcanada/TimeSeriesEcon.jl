# Copyright (c) 2020-2021, Bank of Canada
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

const _MVTSAxesType = Tuple{<:AbstractUnitRange{<:MIT},NTuple{N,Symbol}} where {N}

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

function Base.Broadcast.preprocess(::MVTSeries, x::Number)
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

    # Tuple recursion boilerplate
    mvts_unwrap_args(ax::_MVTSAxesType, ::Tuple{}) = ()
    mvts_unwrap_args(ax::_MVTSAxesType, a::Tuple{<:Any}) = (mvts_unwrap(ax, a[1]),)
    mvts_unwrap_args(ax::_MVTSAxesType, a::Tuple) = (mvts_unwrap(ax, a[1]), mvts_unwrap_args(ax, Base.tail(a))...)

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
        if length(dest_rng) != length(bcax[1]) && length(dest_rng) == 1 && length(dest_nms) == length(bcax[1])
            copyto!(view(_vals(dest), 1, :), bc)
        else
            copyto!(dest.values, bc)
        end
    else
        copyto!(dest.values, bc)
    end
    return dest
end


#########################################################################################
#  OLD IMPLEMENTATION 
#    It's too complicated! Above does the same with fewer lines of code and less complex.
#########################################################################################

# # disable extrusion
# @inline Base.Broadcast.extrude(x::MVTSeries) = x
# @inline Base.Broadcast.extrude(x::TSeries) = x

# const MVTSeriesIndexType = Tuple{UnitRange{<:MIT},NTuple{N,Symbol}} where {N}

# @inline mvts_get_index(x, p::MIT, c::Symbol) = x
# @inline mvts_get_index(x::Number, p::MIT, c::Symbol) = x
# @inline mvts_get_index(x::Ref, p::MIT, c::Symbol) = x[]
# @inline mvts_get_index(x::MVTSeries, p::MIT, c::Symbol) = x[p, c]
# @inline mvts_get_index(x::TSeries, p::MIT, c::Symbol) = x[p]
# @inline mvts_get_index(x::Base.Broadcast.Broadcasted, p::MIT, c::Symbol) = x[p, c]

# function Base.Broadcast.getindex(bc::Base.Broadcast.Broadcasted, p::MIT, c::Symbol)
#     args = (mvts_get_index(arg, p, c) for arg in bc.args)
#     return bc.f(args...)
# end

# function Base.copyto!(dest::MVTSeries, bc::Broadcast.Broadcasted{Nothing})
#     bc′ = Base.Broadcast.preprocess(dest, bc)
#     bcrng, bcvars = axes(bc)
#     xrng, xvars = axes(dest)
#     for (p, c) in Iterators.product(intersect(bcrng, xrng), intersect(bcvars, xvars))
#         @inbounds dest[p, c] = bc′[p, c]
#     end
#     return dest
# end

# function Base.eachindex(bc::Broadcast.Broadcasted{<:MVTSeriesStyle})
#     bcrng, bcvars = axes(bc)
#     Iterators.product(bcrng, bcvars)
# end

# @inline Base.Broadcast.getindex(bc::Base.Broadcast.Broadcasted, pc::Tuple{<:MIT,Symbol}) = bc[pc...]

# function do_instantiate(bc)
#     shape = mvts_combine_axes(bc.args...)
#     if bc.axes !== nothing
#         shape = mvts_broadcast_shape(bc.axes, shape)
#     end
#     mvts_instantiate(bc, shape)
# end

# @inline function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {N,S<:Base.Broadcast.BroadcastStyle,A<:Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}}
#     do_instantiate(bc)
# end

# @inline function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,A}) where {N,S<:Base.Broadcast.AbstractArrayStyle{0},A<:Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}}
#     do_instantiate(bc)
# end

# @inline function Base.Broadcast.instantiate(bc::Base.Broadcast.Broadcasted{S,Nothing}) where {S<:MVTSeriesStyle}
#     do_instantiate(bc)
# end

# # combine_axes works recursively
# @inline mvts_combine_axes(A) = axes(A)
# @inline mvts_combine_axes(A, B) = mvts_broadcast_shape(axes(A), axes(B))
# @inline mvts_combine_axes(A, B...) = mvts_broadcast_shape(axes(A), mvts_combine_axes(B...))

# @inline mvts_broadcast_shape(shape::Tuple) = shape
# @inline mvts_broadcast_shape(::Tuple{}, shape::Tuple{}) = shape
# @inline mvts_broadcast_shape(::Tuple{}, shape::Tuple) = shape
# @inline mvts_broadcast_shape(shape::Tuple, ::Tuple{}) = shape
# @inline mvts_broadcast_shape(shape::Tuple{A}, ::Tuple{}) where {A} = shape
# @inline mvts_broadcast_shape(::Tuple{}, shape::Tuple{A}) where {A} = shape
# @inline mvts_broadcast_shape(shape1::Tuple{A}, shape2::Tuple) where {A} = mvts_broadcast_shape(shape2, shape1)
# function mvts_broadcast_shape(shape1::Tuple, shape2::Tuple)
#     if length(shape1) > 2 || length(shape2) > 2
#         throw(ArgumentError("broadcasting MVTSeries with ndims > 2."))
#     end
#     if length(shape2) == 2
#         return (mit_common_axes(shape1[1], shape2[1]), sym_common_axes(shape1[2], shape2[2]))
#     else # length(shape1) == 2 && length(shape2) == 1
#         if length(shape1[1]) == length(shape2[1])
#             return (mit_common_axes(shape1[1], shape2[1]), shape1[2])
#         elseif length(shape1[1]) == 1 && length(shape1[2]) == length(shape2[1])
#             return (shape1[1], sym_common_axes(shape1[2], shape2[1]))
#         else
#             throw(ArgumentError("Cannot broadcast with $shape1 and $shape2"))
#         end
#     end
# end

# @inline mit_common_axes(a::UnitRange{<:MIT}, b::Base.OneTo) =
#     length(b) == 1 || length(b) == length(a) ? a :
#     throw(DimensionMismatch("Cannot broadcast with $a and $b."))

# # mit_common_axes is the same as in TSeries
# @inline sym_common_axes(a::NTuple{N1,Symbol}, b::NTuple{N2,Symbol}) where {N1,N2} = a == b ? a : tuple(intersect(a, b)...)
# @inline sym_common_axes(a::NTuple{N,Symbol}, b::Any) where {N} = length(a) == length(b) && first(b) == 1 ? a : throw(DimensionMismatch("Cannot broadcast with $(a) and $b."))
# @inline sym_common_axes(a::Any, b::NTuple{N,Symbol}) where {N} = sym_common_axes(b, a)


# function mvts_instantiate(bc::Base.Broadcast.Broadcasted{S}, shape) where {S<:Base.Broadcast.BroadcastStyle}
#     args = map(bc.args) do arg
#         mvts_check_axes(shape, arg)
#     end
#     return Base.Broadcast.Broadcasted{S}(bc.f, args, shape)
# end

# struct MVTSBroadcasted{Axes,BC}
#     singleton::Tuple{Bool,Bool}
#     shape::Axes
#     bc::BC
#     function MVTSBroadcasted(shape, bc)
#         bcshape = axes(bc)
#         singleton = length(bcshape) == 0 ? (true, true) :
#                     length(bcshape) == 1 ? (length(bcshape[1]) == 1, true) :
#                     (length(bcshape[1]) == 1, length(bcshape[2]) == 1)
#         # bc1 = Base.Broadcast.instantiate(bc)
#         new{typeof(shape),typeof(bc)}(singleton, shape, bc)
#     end
# end

# @inline Base.eltype(x::MVTSBroadcasted) = eltype(x.bc)

# function mvts_get_index(x::MVTSBroadcasted, p::MIT, c::Symbol)
#     ip = x.singleton[1] ? 1 : Int(p - first(x.shape[1]) + 1)
#     ic = x.singleton[2] ? 1 : indexin([c], collect(x.shape[2]))[1]
#     ind = CartesianIndex(ip, ic)
#     x.bc[ind]
# end

# # nested broadcasts are processed recursively
# @inline mvts_check_axes(shape::MVTSeriesIndexType, bc::Base.Broadcast.Broadcasted{<:MVTSeriesStyle}) = mvts_instantiate(bc, shape)
# @inline mvts_check_axes(shape::MVTSeriesIndexType, bc::Base.Broadcast.Broadcasted{<:TSeriesStyle}) = mvts_instantiate(bc, shape)
# @inline mvts_check_axes(shape::MVTSeriesIndexType, bc::Base.Broadcast.Broadcasted) = MVTSBroadcasted(shape, bc)

# # MVTSs are left alone. If axes are wrong it'll error when indexing later.
# @inline mvts_check_axes(shape::MVTSeriesIndexType, x::MVTSeries) = x
# # TSeries are also left alone
# @inline mvts_check_axes(shape::MVTSeriesIndexType, x::TSeries) = x
# # Leave numbers alone too
# @inline mvts_check_axes(shape::MVTSeriesIndexType, x) = x[]
# # For Vector, we wrap it in a TSeries if first dimension matches, otherwise we wrap it in a MVTSBroadcasted MVTSeries with one row . . .
# @inline mvts_check_axes(shape::MVTSeriesIndexType, x::AbstractVector) = 
#     length(shape[1]) == length(x) ? TSeries(shape[1], x) :
#         MVTSBroadcasted(shape, MVTSeries(shape[1], shape[2], reshape(x, 1, :)))

# # For Matrix, we wrap them in an MVTSeries with the same dimensions
# @inline mvts_check_axes(shape::MVTSeriesIndexType, x::AbstractMatrix) = 
#     MVTSBroadcasted(shape, MVTSeries(first(shape[1]), shape[2], x))



# function Base.axes(bc::Base.Broadcast.Broadcasted{<:MVTSeriesStyle})
#     bc.axes === nothing ? mvts_combine_axes(bc.args...) : bc.axes
# end

# function Base.axes(bc::Base.Broadcast.Broadcasted{<:MVTSeriesStyle}, d::Integer)
#     1 <= d <= 2 ? axes(bc)[d] : Base.OneTo(1)
# end
