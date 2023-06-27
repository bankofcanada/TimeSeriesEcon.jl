# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

# This module contains functions that are internal 
module I

using ..C
using ..TimeSeriesEcon
import ..DEFile

#############################################################################
# error handling

global debug_libdaec = :debug

export DEError
struct DEError <: Exception
    rc::Cint
    msg::String
end
Base.showerror(io::IO, err::DEError) = print(io, err.msg)
function DEError()
    global debug_libdaec
    _msg = Vector{Cchar}(undef, 512)
    rc = I._de_error!(_msg, Val(debug_libdaec))
    msg = GC.@preserve _msg unsafe_string(pointer(_msg))
    return DEError(rc, msg)
end

@inline _de_error!(msg, ::Val{:debug}) = C.de_error_source(msg, sizeof(msg))
@inline _de_error!(msg, ::Val) = C.de_error(msg, sizeof(msg))


# _check() handles results from C library calls
# return true or false
_check(::Type{Bool}, rc::Cint) = rc == 0
# return true or throw an exception
_check(rc::Cint) = rc == 0 || throw(DEError())

#############################################################################
# scalars write

const StrOrSym = Union{Symbol,AbstractString}

_to_de_scalar_val(value) = throw(ArgumentError("Unable to write value of type $(typeof(value))."))
_to_de_scalar_val(value::Integer) = value
_to_de_scalar_val(value::Real) = float(value)
_to_de_scalar_val(value::Complex) = float(value)
_to_de_scalar_val(value::StrOrSym) = string(value)

_to_de_scalar_type(val) = _to_de_scalar_type(typeof(val))
_to_de_scalar_type(::Type{T}) where {T} = error("Can't handle type $T")
_to_de_scalar_type(::Type{T}) where {T<:MIT} = C.type_date
_to_de_scalar_type(::Type{T}) where {T<:Duration} = C.type_signed
_to_de_scalar_type(::Type{T}) where {T<:Base.BitSigned} = C.type_signed
_to_de_scalar_type(::Type{T}) where {T<:Base.BitUnsigned} = C.type_unsigned
_to_de_scalar_type(::Type{T}) where {T<:Base.IEEEFloat} = C.type_float
_to_de_scalar_type(::Type{T}) where {T<:Complex{<:Base.IEEEFloat}} = C.type_complex
_to_de_scalar_type(::Type{T}) where {T<:StrOrSym} = C.type_string

_to_de_scalar_freq(val) = TimeSeriesEcon._has_frequencyof(val) ? _to_de_scalar_freq(frequencyof(val)) : C.freq_none
_to_de_scalar_freq(::Type{Unit}) = C.freq_unit
_to_de_scalar_freq(::Type{Daily}) = C.freq_daily
_to_de_scalar_freq(::Type{BDaily}) = C.freq_bdaily
_to_de_scalar_freq(::Type{Weekly}) = C.freq_weekly
_to_de_scalar_freq(::Type{Monthly}) = C.freq_monthly
_to_de_scalar_freq(::Type{Quarterly}) = C.freq_quarterly
_to_de_scalar_freq(::Type{HalfYearly}) = C.freq_halfyearly
_to_de_scalar_freq(::Type{Yearly}) = C.freq_yearly
_to_de_scalar_freq(::Type{Weekly{end_day}}) where {end_day} = C.frequency_t(C.freq_weekly + mod1(end_day, 7))
_to_de_scalar_freq(::Type{Quarterly{end_month}}) where {end_month} = C.frequency_t(C.freq_quarterly + mod1(end_month, 3))
_to_de_scalar_freq(::Type{HalfYearly{end_month}}) where {end_month} = C.frequency_t(C.freq_halfyearly + mod1(end_month, 6))
_to_de_scalar_freq(::Type{Yearly{end_month}}) where {end_month} = C.frequency_t(C.freq_yearly + mod1(end_month, 12))

_to_de_scalar_nbytes(val) = sizeof(val)
_to_de_scalar_nbytes(val::String) = sizeof(val) + 1 # Julia's sizeof() does not count the '\0' at the end

_to_de_scalar_prt(val) = Ref(val)
_to_de_scalar_prt(val::String) = pointer(val)

#############################################################################
# scalars read

function _from_de_scalar(scal::C.scalar_t)
    _type = scal.object.type
    if _type == C.type_string
        return unsafe_string(Ptr{UInt8}(scal.value))
    end
    if _type == C.type_date
        FR = _to_julia_frequency(scal.frequency)
        T = _to_julia_scalar_type(Val(C.type_integer), Val(scal.nbytes))
        val = unsafe_load(Ptr{T}(scal.value))
        return convert(MIT{FR}, Int64(val))
    end
    T = _to_julia_scalar_type(Val(_type), Val(scal.nbytes))
    value = unsafe_load(Ptr{T}(scal.value))
    if _type == C.type_signed && scal.frequency != C.freq_none
        FR = _to_julia_frequency(scal.frequency)
        value = convert(Duration{FR}, Int64(value))
    end
    return value
end

_to_julia_scalar_type(::Val{C.type_integer}, ::Val{0}) = Int  # the default integer if size is unknown
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{1}) = Int8
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{2}) = Int16
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{4}) = Int32
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{8}) = Int64
_to_julia_scalar_type(::Val{C.type_integer}, ::Val{16}) = Int128
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{0}) = UInt
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{1}) = UInt8
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{2}) = UInt16
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{4}) = UInt32
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{8}) = UInt64
_to_julia_scalar_type(::Val{C.type_unsigned}, ::Val{16}) = UInt128
_to_julia_scalar_type(::Val{C.type_float}, ::Val{0}) = Float64
_to_julia_scalar_type(::Val{C.type_float}, ::Val{2}) = Float16
_to_julia_scalar_type(::Val{C.type_float}, ::Val{4}) = Float32
_to_julia_scalar_type(::Val{C.type_float}, ::Val{8}) = Float64
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{0}) = ComplexF64
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{4}) = ComplexF16
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{8}) = ComplexF32
_to_julia_scalar_type(::Val{C.type_complex}, ::Val{16}) = ComplexF64
_to_julia_scalar_type(::Val{C.type_string}, ::Val) = String
_to_julia_scalar_type(::Val{C.type_date}, ::Val{8}) = Int64

_to_julia_frequency(f::C.frequency_t) = _to_julia_frequency(Val(f))
_to_julia_frequency(::Val{C.freq_unit}) = Unit
_to_julia_frequency(::Val{C.freq_daily}) = Daily
_to_julia_frequency(::Val{C.freq_bdaily}) = BDaily
_to_julia_frequency(::Val{C.freq_monthly}) = Monthly
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


#############################################################################
# axes

function _make_axis(de::DEFile, rng::AbstractUnitRange{<:Integer})
    ax_id = Ref{C.axis_id_t}()
    _check(C.de_axis_plain(de, length(rng), ax_id))
    return ax_id[]
end

function _make_axis(de::DEFile, rng::AbstractUnitRange{<:MIT})
    ax_id = Ref{C.axis_id_t}()
    _check(C.de_axis_range(de, length(rng), _to_de_scalar_freq(rng), first(rng), ax_id))
    return ax_id[]
end

function _make_axis(de::DEFile, rng::AbstractVector{<:Union{Symbol,AbstractString}})
    ax_id = Ref{C.axis_id_t}()
    names = string(join(rng, "\n"))
    _check(C.de_axis_names(de, length(rng), names, ax_id))
    return ax_id[]
end

_get_axis_of(de::DEFile, vec::AbstractVector, dim=1) = _make_axis(de, Base.axes1(vec))
_get_axis_of(de::DEFile, vec::AbstractUnitRange, dim=1) = _make_axis(de, vec)
_get_axis_of(de::DEFile, vec::AbstractArray, dim=1) = _make_axis(de, Base.axes(vec, dim))

#############################################################################
# write tseries

_to_de_tseries(value) = throw(ArgumentError("Unable to write value of type $(typeof(value))."))

_to_de_tseries(value::AbstractUnitRange) =
    (; eltype=_to_de_scalar_type(eltype(value)), type=C.type_range, nbytes=0, val=nothing)

function _to_de_tseries(value::AbstractVector{<:Number})
    ET = eltype(value)
    if isempty(value)
        nbytes = 0
        val = nothing
    else
        nbytes = length(value) * _to_de_scalar_nbytes(ET)
        if isa(value, Vector{ET})
            val = value
        else
            val = copyto!(Vector{ET}(undef, length(value)), value)
        end
    end
    return (; eltype=_to_de_scalar_type(ET), type=C.type_vector, nbytes, val)
end

function _to_de_tseries(value::AbstractVector{<:StrOrSym})
    if isempty(value)
        nbytes = 0
        val = nothing
    else
        val = join(value, '\0') * '\0'
        nbytes = sizeof(val)
    end
    return (; eltype=C.type_string, type=C.type_vector, nbytes, val)
end

#############################################################################
# read tseries

# dispatcher
_from_de_tseries(tseries::C.tseries_t) = _from_de_tseries(Val(tseries.object.type), Val(tseries.axis.type), tseries)

# handle type_range
_from_de_tseries(::Val{C.type_range}, ::Val{C.axis_plain}, tseries::C.tseries_t) = 1:tseries.axis.length
function _from_de_tseries(::Val{C.type_range}, ::Val{C.axis_range}, tseries::C.tseries_t)
    FR = _to_julia_frequency(tseries.axis.frequency)
    fd = reinterpret(MIT{FR}, tseries.axis.first)
    return fd .+ (0:tseries.axis.length-1)
end
_from_de_tseries(::Val{C.type_range}, ::Val{Z}, tseries::C.tseries_t) where {Z} = error("Cannot load a range of type $Z")

# handle type_vector
_from_de_tseries(::Val{C.type_vector}, ::Val{Z}, tseries::C.tseries_t) where {Z} = error("Cannot load a vector with range of type $Z. Expected $(C.axis_plain)")
function _from_de_tseries(::Val{C.type_vector}, ::Val{C.axis_plain}, tseries::C.tseries_t)
    vlen = tseries.axis.length
    if vlen == 0
        ET = _to_julia_scalar_type(Val(tseries.eltype), Val(0))
        return ET[]
    else
        ET = _to_julia_scalar_type(Val(tseries.eltype), Val(tseries.nbytes ÷ vlen))
        vec = Vector{ET}(undef, vlen)
        return _my_copyto!(vec, tseries)
    end
end

# the case of other than string
function _my_copyto!(dest::Vector{T}, src::C.tseries_t) where {T}
    if src.nbytes != sizeof(dest)
        error("Inconsistent data: sizeof doesn't match.")
    end
    ccall(:memcpy, Ptr{Cvoid}, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),
        dest, src.value, src.nbytes)
    return dest
end

# the case of string
function _my_copyto!(dest::Vector{<:StrOrSym}, src::C.tseries_t)
    str = unsafe_string(Base.unsafe_convert(Ptr{UInt8}, src.value), src.nbytes - 1)
    strvec = split(str, '\0')
    if length(strvec) != length(dest)
        error("Inconsistent data: number of elements don't match")
    end
    for i in eachindex(dest)
        dest[i] = string(strvec[i])
    end
    return dest
end


#############################################################################
# helpers for writedb

import ..new_catalog
import ..store_scalar
import ..store_tseries
import ..writedb

const StoreAsScalarType = Union{Symbol,AbstractString,Number}
const StoreAsTSeriesType = Union{AbstractVector}
const StoreAsCatalogType = Union{Workspace,AbstractDict{<:StrOrSym}}

_write_data(::DEFile, ::C.obj_id_t, name::StrOrSym, value) = error("Cannot determine the storage class of $name::$(typeof(value))")
_write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value::StoreAsScalarType) = store_scalar(de, pid, string(name), value)
_write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value::StoreAsTSeriesType) = store_tseries(de, pid, string(name), value)
function _write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, data::StoreAsCatalogType)
    pid = new_catalog(de, pid, string(name))
    return writedb(de, pid, data)
end


#############################################################################
# helpers for readdb

import ..load_scalar
import ..load_tseries
import ..readdb

function _read_data(de::DEFile, id::C.obj_id_t)
    obj = Ref{C.object_t}()
    _check(C.de_load_object(de, id, obj))
    return _read_data(de, id, Val(obj[].class))
end
_read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_scalar}) = load_scalar(de, id)
_read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_tseries}) = load_tseries(de, id)
function _read_data(de::DEFile, id::C.obj_id_t, ::Val{C.class_catalog})
    search = Ref{C.de_search}()
    I._check(C.de_list_catalog(de, id, search))
    data = Workspace()
    obj = Ref{C.object_t}()
    rc = C.de_next_object(search[], obj)
    while rc == C.DE_SUCCESS
        name = Symbol(unsafe_string(obj[].name))
        try
            if obj[].id != obj[].pid # skip recursing on self (only root would do this)
                value = _read_data(de, obj[].id, Val(obj[].class))
                push!(data, name => value)
            end
        catch err
            @error "Failed to load $name" err
            C.de_clear_error()
        end
        rc = C.de_next_object(search[], obj)
    end
    if rc == C.DE_NO_OBJ
        C.de_finalize_search(search[])
        return data
    end
    try
        _check(rc)
    catch err
        C.de_finalize_search(search[])
        rethrow(err)
    end
    return nothing
end


end
