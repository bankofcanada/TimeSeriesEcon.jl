# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

# This module contains functions that are internal
module I

using Dates

using ..C
using ..TimeSeriesEcon
import ..DEFile

#############################################################################
# error handling

# global debug_libdaec = :debug
global debug_libdaec = :nodebug

export DEError
"""
    struct DEError <: Exception
        ...
    end

An exception type thrown by the "libdaec" C library. It contains a numerical
code and a message.

Note that some errors thrown by the DataEcon module are of other exception
types. This one is specifically for errors from the C library.
"""
struct DEError <: Exception
    rc::Cint
    msg::String
end
Base.showerror(io::IO, err::DEError) = print(io, err.msg)
function DEError()
    global debug_libdaec
    _msg = Vector{Cchar}(undef, 512)
    rc = _de_error!(_msg, Val(debug_libdaec))
    msg = GC.@preserve _msg unsafe_string(pointer(_msg))
    return DEError(rc, msg)
end

@inline _de_error!(msg, ::Val{:debug}) = C.de_error_source(msg, sizeof(msg))
@inline _de_error!(msg, v::Val=Val(:nodebug)) = (@nospecialize(v); C.de_error(msg, sizeof(msg)))


# _check() handles results from C library calls
# return true or false
# _check(::Type{Bool}, rc::Cint) = rc == 0
# return true or throw an exception
_check(rc::Cint) = rc == 0 || throw(DEError())

#############################################################################
# scalars write

const StrOrSym = Union{Symbol,AbstractString}

_to_de_scalar_val(value) = throw(ArgumentError("Unable to write scalar value of type $(typeof(value))."))
_to_de_scalar_val(value::Integer) = value
_to_de_scalar_val(value::Real) = float(value)
_to_de_scalar_val(value::Complex) = float(value)
_to_de_scalar_val(value::StrOrSym) = string(value)
_to_de_scalar_val(value::Dates.Date) = Dates.datetime2unix(convert(DateTime, value))
_to_de_scalar_val(value::Dates.DateTime) = Dates.datetime2unix(value)
_to_de_scalar_val(value::MIT)::typeof(value) = _pack_date(value)

_pack_date(value::MIT) = value
function _pack_date(value::MIT{FR}) where {FR<:YPFrequency}
    freq = _to_de_scalar_freq(FR)
    year, period = mit2yp(value)
    de_code = Ref{Int64}(0)
    _check(C.de_pack_year_period_date(freq, year, period, de_code))
    if Int64(value) != de_code[]
        @warn "MIT codes differ between TimeSeriesEcon and DataEcon for $value: $(Int(value)) vs $(de_code[])"
    end
    return value
end
function _pack_date(value::MIT{FR}) where {FR<:CalendarFrequency}
    freq = _to_de_scalar_freq(FR)
    date = Dates.Date(value)
    year = Dates.year(date)
    month = Dates.month(date)
    day = Dates.day(date)
    de_code = Ref{Int64}(0)
    _check(C.de_pack_calendar_date(freq, year, month, day, de_code))
    if Int64(value) != de_code[]
        @warn "MIT codes differ between TimeSeriesEcon and DataEcon for $value: $(Int(value)) vs $(de_code[])"
    end
    return value
end

_to_de_scalar_type(@nospecialize(val)) = _to_de_scalar_type(typeof(val))
_to_de_scalar_type(::Type{T}) where {T<:MIT} = C.type_date
_to_de_scalar_type(::Type{T}) where {T<:Duration} = C.type_signed
_to_de_scalar_type(::Type{T}) where {T<:Bool} = C.type_signed
_to_de_scalar_type(::Type{T}) where {T<:Base.BitSigned} = C.type_signed
_to_de_scalar_type(::Type{T}) where {T<:Base.BitUnsigned} = C.type_unsigned
_to_de_scalar_type(::Type{T}) where {T<:Base.IEEEFloat} = C.type_float
_to_de_scalar_type(::Type{T}) where {T<:Complex{<:Base.IEEEFloat}} = C.type_complex
_to_de_scalar_type(::Type{T}) where {T<:StrOrSym} = C.type_string

_to_de_scalar_freq(@nospecialize(val)) = C.freq_none
_to_de_scalar_freq(::MIT{F}) where{F} = _to_de_scalar_freq(F)
_to_de_scalar_freq(::Duration{F}) where{F} = _to_de_scalar_freq(F)
_to_de_scalar_freq(::Type{Unit}) = C.freq_unit
_to_de_scalar_freq(::Type{Daily}) = C.freq_daily
_to_de_scalar_freq(::Type{BDaily}) = C.freq_bdaily
# _to_de_scalar_freq(::Type{Weekly}) = C.freq_weekly
_to_de_scalar_freq(::Type{Monthly}) = C.freq_monthly
# _to_de_scalar_freq(::Type{Quarterly}) = C.freq_quarterly
# _to_de_scalar_freq(::Type{HalfYearly}) = C.freq_halfyearly
# _to_de_scalar_freq(::Type{Yearly}) = C.freq_yearly
_to_de_scalar_freq(::Type{Weekly{end_day}}) where {end_day} = C.frequency_t(C.freq_weekly + mod1(end_day, 7))
_to_de_scalar_freq(::Type{Quarterly{end_month}}) where {end_month} = C.frequency_t(C.freq_quarterly + mod1(end_month, 3))
_to_de_scalar_freq(::Type{HalfYearly{end_month}}) where {end_month} = C.frequency_t(C.freq_halfyearly + mod1(end_month, 6))
_to_de_scalar_freq(::Type{Yearly{end_month}}) where {end_month} = C.frequency_t(C.freq_yearly + mod1(end_month, 12))

_to_de_scalar_nbytes(val) = sizeof(val)
_to_de_scalar_nbytes(val::String) = sizeof(val) + 1 # Julia's sizeof() does not count the '\0' at the end

_to_de_scalar_ptr_unsafe(val) = Ref(val)
_to_de_scalar_ptr_unsafe(val::String) = pointer(val)

#############################################################################
# scalars read

_unpack_date(::Type{FR}, freq, de_code) where {FR<:Frequency} = convert(MIT{FR}, Int64(de_code))
function _unpack_date(::Type{FR}, freq, de_code) where {FR<:YPFrequency}
    year = Ref{Int32}()
    period = Ref{UInt32}()
    _check(C.de_unpack_year_period_date(freq, de_code, year, period))
    value = MIT{FR}(year[], period[])
    if Int(value) != de_code
        @warn "MIT codes differ between TimeSeriesEcon and DataEcon for $value: $(Int(value)) vs $(de_code)"
    end
    return value
end
function _unpack_date(::Type{FR}, freq, de_code) where {FR<:CalendarFrequency}
    year = Ref{Int32}()
    month = Ref{UInt32}()
    day = Ref{UInt32}()
    _check(C.de_unpack_calendar_date(freq, de_code, year, month, day))
    value = MIT{FR}(Dates.Date(year[], month[], day[]))
    if Int(value) != de_code
        @warn "MIT codes differ between TimeSeriesEcon and DataEcon for $value: $(Int(value)) vs $(de_code)"
    end
    return value
end

function _from_de_scalar(scal::C.scalar_t)
    obj_type = scal.object.obj_type
    if obj_type == C.type_string
        return unsafe_string(Ptr{UInt8}(scal.value))
    end
    T = _to_julia_scalar_type(Val(obj_type), Val(scal.frequency), Val(scal.nbytes))
    if obj_type == C.type_date
        value = unsafe_load(Ptr{Int64}(scal.value))
        value = _unpack_date(frequencyof(T), scal.frequency, value)::T
    else
        value = unsafe_load(Ptr{T}(scal.value))
    end
    return value
end

_to_julia_scalar_type(::Val{C.type_integer}, ::Val{C.freq_none}, ::Val{0}) = Int  # the default integer if size is unknown
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{C.freq_none}, ::Val{1}) = Int8
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{C.freq_none}, ::Val{2}) = Int16
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{C.freq_none}, ::Val{4}) = Int32
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{C.freq_none}, ::Val{8}) = Int64
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{C.freq_none}, ::Val{16}) = Int128
_to_julia_scalar_type(::Val{C.type_signed}, fr::Val, ::Val{8}) = Duration{_to_julia_frequency(fr)}
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{C.freq_none}, ::Val{0}) = UInt
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{C.freq_none}, ::Val{1}) = UInt8
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{C.freq_none}, ::Val{2}) = UInt16
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{C.freq_none}, ::Val{4}) = UInt32
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{C.freq_none}, ::Val{8}) = UInt64
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{C.freq_none}, ::Val{16}) = UInt128
_to_julia_scalar_type(::Val{C.type_float}, ::Val{C.freq_none}, ::Val{0}) = Float64
_to_julia_scalar_type(::Val{C.type_float}, ::Val{C.freq_none}, ::Val{2}) = Float16
_to_julia_scalar_type(::Val{C.type_float}, ::Val{C.freq_none}, ::Val{4}) = Float32
_to_julia_scalar_type(::Val{C.type_float}, ::Val{C.freq_none}, ::Val{8}) = Float64
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{C.freq_none}, ::Val{0}) = ComplexF64
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{C.freq_none}, ::Val{4}) = ComplexF16
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{C.freq_none}, ::Val{8}) = ComplexF32
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{C.freq_none}, ::Val{16}) = ComplexF64
_to_julia_scalar_type(::Val{C.type_string}, ::Val{C.freq_none}, ::Val) = String
_to_julia_scalar_type(::Val{C.type_date}, fr::Val, ::Val{8}) = MIT{_to_julia_frequency(fr)}
# _to_julia_scalar_type(::Val{C.type_other_scalar}, ::Val) = Any

_to_julia_frequency(::Val{C.freq_unit}) = Unit
_to_julia_frequency(::Val{C.freq_daily}) = Daily
_to_julia_frequency(::Val{C.freq_bdaily}) = BDaily
_to_julia_frequency(::Val{C.freq_monthly}) = Monthly
_to_julia_frequency(::Val{C.freq_monthly + 1}) = Monthly
function _to_julia_frequency(::Val{CF}) where {CF}
    for (f, F) in ((C.freq_weekly => Weekly), (C.freq_quarterly => Quarterly),
        (C.freq_halfyearly => HalfYearly), (C.freq_yearly => Yearly))
        if CF & f != 0
            return F{Int(CF - f)}
        end
    end
    error("This frequency code is not supported: $(CF)")
end

_apply_jtype(::Type{Symbol}, value) = Symbol(value)
_apply_jtype(::Type{T}, value) where {T} = convert(T, value)
_apply_jtype(::Type{Dates.Date}, value) = convert(Dates.Date, Dates.unix2datetime(value))
_apply_jtype(::Type{Dates.DateTime}, value) = Dates.unix2datetime(value)


#############################################################################
# axes

function _make_axis(de::DEFile, rng::AbstractUnitRange{<:Integer})
    ax_id = Ref{C.axis_id_t}()
    _check(C.de_axis_plain(de, length(rng), ax_id))
    return ax_id[]
end

function _make_axis(de::DEFile, rng::AbstractUnitRange{<:MIT})
    ax_id = Ref{C.axis_id_t}()
    _check(C.de_axis_range(de, length(rng), _to_de_scalar_freq(frequencyof(rng)), _pack_date(first(rng)), ax_id))
    return ax_id[]
end

function _make_axis(de::DEFile, rng::AbstractVector{<:Union{Symbol,AbstractString}})
    ax_id = Ref{C.axis_id_t}()
    names = join(rng, "\n")
    _check(C.de_axis_names(de, length(rng), names, ax_id))
    return ax_id[]
end

# _get_axis_of(de::DEFile, vec::NTuple, dim=1) = _make_axis(de, Base.axes1(vec))
_get_axis_of(de::DEFile, vec::AbstractVector, dim=1) = _make_axis(de, Base.axes1(vec))
_get_axis_of(de::DEFile, vec::AbstractUnitRange, dim=1) = _make_axis(de, vec)
_get_axis_of(de::DEFile, vec::AbstractArray, dim=1) = _make_axis(de, Base.axes(vec, dim))

function _get_axis_range_firstdate(axis::C.axis_t)
    @assert axis.ax_type == C.axis_range
    FR = _to_julia_frequency(Val(axis.frequency))
    return _unpack_date(FR, axis.frequency, axis.first)
end

#############################################################################
# write tseries and mvtseries


_de_array_data(; eltype, elfreq=C.freq_none, obj_type, nbytes, val) = (; eltype, elfreq, obj_type, nbytes, val)

_to_de_array(value) = throw(ArgumentError("Unable to write value of type $(typeof(value))."))

# handle range
_to_de_array(::AbstractUnitRange) = _de_array_data(; eltype=C.type_none, obj_type=C.type_range, nbytes=0, val=C_NULL)

# handle any vector or matrix
_to_de_array(value::AbstractVecOrMat) = _to_de_array(Val(isempty(value)), value)

_eltypefreq(::Type{ET}) where {ET<:MIT} = (; eltype=C.type_date, elfreq=_to_de_scalar_freq(frequencyof(ET)))
_eltypefreq(::Type{ET}) where {ET<:Duration} = (; eltype=C.type_signed, elfreq=_to_de_scalar_freq(frequencyof(ET)))
_eltypefreq(::Type{ET}) where {ET} = (; eltype=_to_de_scalar_type(ET), elfreq=C.freq_none)

# empty array
_to_de_array(::Val{true}, value::AbstractVecOrMat{ET}) where {ET} = _de_array_data(;
    _eltypefreq(ET)...,
    obj_type=ndims(value) == 1 ? C.type_vector : C.type_matrix,
    nbytes=0,
    val=C_NULL
)

# vector of numbers
function _to_de_array(::Val{false}, value::AbstractVecOrMat{ET}) where {ET<:Number}
    val = value
    nbytes = length(value) * _to_de_scalar_nbytes(ET)
    return _de_array_data(; _eltypefreq(ET)...,
        obj_type=ndims(value) == 1 ? C.type_vector : C.type_matrix, nbytes, val)
end

_to_de_array(::Val{false}, value::AbstractVecOrMat{ET}) where {ET<:StrOrSym} = _to_de_array(Val(false), map(string, value))
function _to_de_array(::Val{false}, value::VecOrMat{String})
    nel = length(value)
    nbytes = sum(length, value) + nel
    val = Vector{UInt8}(undef, nbytes)
    _check(C.de_pack_strings(value, nel, val, Ref(nbytes)))
    return _de_array_data(; eltype=C.type_string, obj_type=ndims(value) == 1 ? C.type_vector : C.type_matrix, nbytes, val)
end

# handle bit array -- we must expand it to Array{Bool}
_to_de_array(value::BitArray) = _to_de_array(Array(value))

# handle mvtseries
function _to_de_array(value::MVTSeries)
    arr = _to_de_array(value.values)
    return _de_array_data(; arr.eltype, arr.elfreq, obj_type=C.type_mvtseries, arr.nbytes, arr.val)
end

# handle tseries
function _to_de_array(value::TSeries)
    arr = _to_de_array(value.values)
    return _de_array_data(; arr.eltype, arr.elfreq, obj_type=C.type_tseries, arr.nbytes, arr.val)
end

function _should_store_eltype(arr, value::AbstractArray{ET}) where {ET}
    isempty(value) && return true
    arr.obj_type == C.type_range && return false
    arr.eltype == C.type_other_scalar && return true
    arr.eltype == C.type_string && return ET != String
    return ET != _to_julia_scalar_type(Val(arr.eltype), Val(arr.elfreq), Val(sizeof(ET)))
end

@inline _should_store_type(v::Val, a::Any) = (@nospecialize(v, a); true)
@inline _should_store_type(::Val{C.type_range}, ::UnitRange) = false
@inline _should_store_type(::Val{C.type_vector}, ::Vector) = false
@inline _should_store_type(::Val{C.type_tseries}, ::TSeries) = false
@inline _should_store_type(::Val{C.type_matrix}, ::Matrix) = false
@inline _should_store_type(::Val{C.type_mvtseries}, ::MVTSeries) = false

_do_store_array(::Val{1}, args...) = C.de_store_tseries(args...)
_do_store_array(::Val{2}, args...) = C.de_store_mvtseries(args...)
# function _do_store_array(v::Val{N}, args...) where {N}
#     @nospecialize v
#     error("Can't store  $(N)d array.")
# end
import ..set_attribute
import ..get_attribute
# _store_array(de::DEFile, pid::C.obj_id_t, name::String, axes::NTuple{M,C.axis_id_t}, value::AbstractArray{ET,N}) where {ET,N,M} = error("Dimension mismatch: $(N)d array with $M axes.")
function _store_array(de::DEFile, pid::C.obj_id_t, name::String, axes::NTuple{N,C.axis_id_t}, value::AbstractArray{ET,N}) where {ET,N}
    id = Ref{C.obj_id_t}()
    arr = _to_de_array(value)
    GC.@preserve arr begin
        ptr = arr.nbytes == 0 ? C_NULL : pointer(arr.val)
        _check(_do_store_array(Val(N), de, pid, name, arr.obj_type, arr.eltype, arr.elfreq, axes..., arr.nbytes, ptr, id))
    end
    if _should_store_eltype(arr, value)
        set_attribute(de, id[], "jeltype", string(ET))
    end
    if _should_store_type(Val(arr.obj_type), value)
        set_attribute(de, id[], "jtype", string(typeof(value)))
    end
    return id[]
end

#############################################################################
# read tseries and mvtseries

function _to_julia_array(de, id, arr)
    value = _from_de_array(arr)
    jtype = get_attribute(de, id, "jtype")
    if !ismissing(jtype)
        T = Core.eval(Main, Meta.parse(jtype))
        return convert(T, value)
    end
    jeltype = get_attribute(de, id, "jeltype")
    if !ismissing(jeltype)
        JT = Core.eval(Main, Meta.parse(jeltype))
        if isempty(value)
            return JT[]
        else
            return map(v -> _apply_jtype(JT, v), value)
        end
    end
    return value
end

# dispatcher
_from_de_array(arr::C.tseries_t) = _from_de_array(arr, Val(arr.object.obj_type), Val(arr.axis.ax_type))
_from_de_array(arr::C.mvtseries_t) = _from_de_array(arr, Val(arr.object.obj_type), Val(arr.axis1.ax_type), Val(arr.axis2.ax_type))

# handle type_range
_from_de_array(arr::C.tseries_t, ::Val{C.type_range}, ::Val{C.axis_plain}) = 1:arr.axis.length
function _from_de_array(arr::C.tseries_t, ::Val{C.type_range}, ::Val{C.axis_range})
    fd = _get_axis_range_firstdate(arr.axis)
    return fd .+ (0:arr.axis.length-1)
end
# _from_de_array(::C.tseries_t, ::Val{C.type_range}, ::Val{Z}) where {Z} = error("Cannot load a range of axis type $Z")

# handle type_vector
_from_de_array(::C.tseries_t, ::Val{C.type_vector}, ::Val{Z},) where {Z} = error("Cannot load a vector with axis of type $Z. Expected $(C.axis_plain)")
function _from_de_array(arr::C.tseries_t, ::Val{C.type_vector}, ::Val{C.axis_plain})
    vlen = arr.axis.length
    return _do_load_array_data(arr, Val(vlen))
end

# handle type_matrix
_from_de_array(::C.mvtseries_t, ::Val{C.type_matrix}, ::Val{Y}, ::Val{Z}) where {Y,Z} = error("Cannot load a matrix with axes of type $Y and $Z. Expected $(C.axis_plain)")
function _from_de_array(arr::C.mvtseries_t, ::Val{C.type_matrix}, ::Val{C.axis_plain}, ::Val{C.axis_plain})
    d1 = arr.axis1.length
    d2 = arr.axis2.length
    return reshape(_do_load_array_data(arr, Val(d1 * d2)), d1, d2)
end

function _do_load_array_data(arr, ::Val{0})
    ET = _to_julia_scalar_type(Val(arr.eltype), Val(arr.elfreq), Val(0))
    return ET[]
end

function _do_load_array_data(arr, v::Val{N}) where {N}
    @nospecialize v
    vlen = N::Int64
    ET = _to_julia_scalar_type(Val(arr.eltype), Val(arr.elfreq), Val(arr.nbytes ÷ vlen))
    vec = Vector{ET}(undef, vlen)
    return _my_copyto!(vec, arr)
end

# the case of other than string
function _my_copyto!(dest::Vector{T}, src) where {T}
    if src.nbytes != sizeof(dest)
        error("Inconsistent data: sizeof doesn't match.")
    end
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),
        dest, src.value, src.nbytes)
    return dest
end

# the case of string
function _do_unpack_strings(buffer, bufsize, nel)
    strvec = Vector{Ptr{Cchar}}(undef, nel)
    _check(C.de_unpack_strings(buffer, bufsize, strvec, nel))
    return map(Base.unsafe_string, strvec)
end

function _my_copyto!(dest::Vector{ET}, src) where {ET<:StrOrSym}
    strings = _do_unpack_strings(src.value, src.nbytes, length(dest))
    for i in eachindex(dest)
        dest[i] = ET(strings[i])
    end
    return dest
end

# handle type_tseries
_from_de_array(::C.tseries_t, ::Val{C.type_tseries}, ::Val{Z}) where {Z} = error("Cannot load a tseries with axis of type $Z. Expected $(C.axis_range).")
function _from_de_array(arr::C.tseries_t, ::Val{C.type_tseries}, ::Val{C.axis_range})
    vlen = arr.axis.length
    fd = _get_axis_range_firstdate(arr.axis)
    return TSeries(fd, _do_load_array_data(arr, Val(vlen)))
end

# handle type_mvtseries
_from_de_array(::C.mvtseries_t, ::Val{C.type_mvtseries}, ::Val{Y}, ::Val{Z}) where {Y,Z} = error("Cannot load an mvtseries with axes of type $Y and $Z. Expected $(C.axis_range) and $(C.axis_names).")
function _from_de_array(arr::C.mvtseries_t, ::Val{C.type_mvtseries}, ::Val{C.axis_range}, ::Val{C.axis_names})
    d1 = arr.axis1.length
    fd = _get_axis_range_firstdate(arr.axis1)
    d2 = arr.axis2.length
    cols = split(Base.unsafe_string(arr.axis2.names), '\n')
    return MVTSeries(fd, cols, reshape(_do_load_array_data(arr, Val(d1 * d2)), d1, d2))
end


#############################################################################
# helpers for writedb

import ..new_catalog
import ..store_scalar
import ..store_tseries
import ..store_mvtseries
import ..writedb

const StoreAsScalarType = Union{Symbol,AbstractString,Number,Dates.Date,Dates.DateTime}

_write_data(::DEFile, ::C.obj_id_t, name::StrOrSym, value) = error("Cannot determine the storage class of $name::$(typeof(value))")
_write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value::StoreAsScalarType) = store_scalar(de, pid, string(name), value)
# _write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value::NTuple) = store_tseries(de, pid, string(name), value)
_write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value::AbstractVector) = store_tseries(de, pid, string(name), value)
_write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value::AbstractMatrix) = store_mvtseries(de, pid, string(name), value)
function _write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, data::Workspace)
    pid = new_catalog(de, pid, string(name))
    return writedb(de, pid, data)
end


#############################################################################
# helpers for readdb

function _finalize_search(rc, search)
    try
        if rc != C.DE_NO_OBJ
            _check(rc)
        end
        C.de_finalize_search(search)
    catch err
        C.de_finalize_search(search)
        rethrow(err)
    end
end

import ..load_scalar
import ..load_tseries
import ..load_mvtseries
import ..readdb

function _read_data(de::DEFile, id::C.obj_id_t)
    obj = Ref{C.object_t}()
    _check(C.de_load_object(de, id, obj))
    return _read_data(de, id, Val(obj[].obj_class))
end
_read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_scalar}) = load_scalar(de, id)
_read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_tseries}) = load_tseries(de, id)
_read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_mvtseries}) = load_mvtseries(de, id)
function _read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_catalog})
    search = Ref{C.de_search}()
    _check(C.de_list_catalog(de, id, search))
    data = Workspace()
    obj = Ref{C.object_t}()
    rc = C.de_next_object(search[], obj)
    while rc == C.DE_SUCCESS
        name = Symbol(unsafe_string(obj[].name))
        try
            value = _read_data(de, obj[].id, Val(obj[].obj_class))
            push!(data, name => value)
        catch err
            @error "Failed to load $name" err
            C.de_clear_error()
        end
        rc = C.de_next_object(search[], obj)
    end
    _finalize_search(rc, search[])
    return data
end

#############################################################################
# helpers for list_catalog

function _list_catalog(de::DEFile, cid::C.obj_id_t, maxdepth::Int, verbose::Bool, io::IO)
    search = Ref{C.de_search}()
    _check(C.de_list_catalog(de, cid, search))
    obj = Ref{C.object_t}()
    rc = C.de_next_object(search[], obj)
    list = []
    while rc == C.DE_SUCCESS
        oname = unsafe_string(obj[].name)
        try
            fp = Ref{Ptr{Cchar}}()
            depth = Ref{Int64}()
            _check(C.de_get_object_info(de, obj[].id, fp, depth, C_NULL))
            if depth[] <= maxdepth
                if obj[].obj_class == C.class_catalog
                    verbose && print(io, "  "^(depth[] - 1), oname, '/')
                    if depth[] < maxdepth
                        verbose && println(io)
                        append!(list, _list_catalog(de, obj[].id, maxdepth, verbose, io))
                    else # depth[] == maxdepth
                        count = Ref{Int64}()
                        _check(C.de_catalog_size(de, obj[].id, count))
                        verbose && println(io, count[] == 0 ? "(empty)" : "($(count[]) objects)")
                    end
                else
                    verbose && println("  "^(depth[] - 1), " ", oname)
                    push!(list, unsafe_string(fp[]))
                end
            end
        catch err
            @error "Failed to ge info for $oname($(obj[].id))" err
            C.de_clear_error()
        end
        rc = C.de_next_object(search[], obj)
    end
    _finalize_search(rc, search[])
    return list
end

end
