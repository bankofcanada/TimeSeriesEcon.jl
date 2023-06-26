# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

include("C.jl")
using .C

using ..TimeSeriesEcon

const StrOrSym = Union{Symbol,AbstractString}

#############################################################################
# error handling

global debug_libdaec = :debug

struct DEError <: Exception
    rc::Cint
    msg::String
end
Base.showerror(io::IO, err::DEError) = print(io, err.msg)
@inline _de_error!(msg, ::Val{:debug}) = C.de_error_source(msg, sizeof(msg))
@inline _de_error!(msg, ::Val) = C.de_error(msg, sizeof(msg))
function DEError()
    global debug_libdaec
    _msg = Vector{Cchar}(undef, 512)
    rc = _de_error!(_msg, Val(debug_libdaec))
    msg = GC.@preserve _msg unsafe_string(pointer(_msg))
    return DEError(rc, msg)
end

# _check() handles results from C library calls
# return true or false
_check(::Type{Bool}, rc::Cint) = rc == 0
# return true or throw an exception
_check(rc::Cint) = rc == 0 || throw(DEError())

#############################################################################
# open and close daec files 

export DEFile, opendaec, closedaec!

"""
    struct DEFile ... end

An instance of a *.daec file. Usually there's no need to create instances
directly. Use [`opendaec`](@ref) and [`closedaec!`](@ref).
"""
struct DEFile
    handle::Ref{C.de_file}
    fname::String
end

Base.isopen(de::DEFile) = de.handle[] != C_NULL
function Base.show(io::IO, de::DEFile)
    summary(io, de)
    print(io, ": \"", de.fname, isopen(de) ? "\"" : "\" (closed)")
end
@inline Base.unsafe_convert(::Type{C.de_file}, de::DEFile) = isopen(de) ? de.handle[] : throw(ArgumentError("File is closed."))

"""
    de = opendaec(fname)
    opendaec(fname) do de
        ...
    end

Open the .daec file named in the given `fname` string and return an instance of
`DEFile`. The version with the do-block automatically closes the file.
"""
function opendaec end

function opendaec(fname::AbstractString)
    handle = Ref{C.de_file}()
    fname = string(fname)
    _check(C.de_open(fname, handle))
    return DEFile(handle, fname)
end

function opendaec(f::Function, fname::AbstractString)
    de = opendaec(fname)
    try
        f(de)
    finally
        closedaec!(de)
    end
end

export closedaec!
"""
    closedaec!(de)

Close a .daec file that was previously opened with [`opendaec`](@ref).
The given instance of `DEFile` is modified in place to mark it as closed.
"""
function closedaec! end

function closedaec!(de::DEFile)
    if isopen(de)
        _check(C.de_close(de.handle[]))
        de.handle[] = C_NULL
    end
    return de
end

#############################################################################
# objects

const root = C.obj_id_t(0)

function find_fullpath(de::DEFile, fullpath::String)
    id = Ref{C.obj_id_t}()
    _check(C.de_find_fullpath(de, fullpath, id))
    return id[]
end

function find_object(de::DEFile, pid::C.obj_id_t, name::String)
    id = Ref{C.obj_id_t}()
    _check(C.de_find_object(de, pid, name, id))
    return id[]
end

function get_attribute(de::DEFile, id::C.obj_id_t, name::String)
    value = Ref{Ptr{Cchar}}()
    rc = C.de_get_attribute(de, id, name, value)
    if rc == C.DE_MIS_ATTR
        C.de_clear_error()
        return missing
    end
    _check(rc)
    return unsafe_string(value[])
end

#############################################################################
# read and write scalars

export new_scalar, load_scalar

# ###############   write 
function new_scalar(de::DEFile, pid::C.obj_id_t, name::String, value)
    # the value to be written
    val = _to_de_scalar_val(value)
    val_type = _to_de_scalar_type(val)
    val_freq = _to_de_scalar_freq(val)
    val_nbytes = _to_de_scalar_nbytes(val)
    val_ptr = _to_de_scalar_prt(val)
    id = Ref{C.obj_id_t}()
    _check(C.de_new_scalar(de, pid, name, val_type, val_freq, val_nbytes, val_ptr, id))
    if typeof(val) != typeof(value)
        # write the actual type as an attribute, so we can recover it
        _check(C.de_set_attribute(de, id[], "jtype", string(typeof(value))))
    end
    return
end

_to_de_scalar_val(value) = throw(ArgumentError("Unable to write value of type $(typeof(value))."))
_to_de_scalar_val(value::Integer) = value
_to_de_scalar_val(value::Real) = float(value)
_to_de_scalar_val(value::Complex) = float(value)
_to_de_scalar_val(value::StrOrSym) = string(value)

_to_de_scalar_type(val) = error("Can't handle type $(typeof(val))")
_to_de_scalar_type(::T) where {T<:MIT} = C.type_date
_to_de_scalar_type(::T) where {T<:Duration} = C.type_signed
_to_de_scalar_type(::T) where {T<:Base.BitSigned} = C.type_signed
_to_de_scalar_type(::T) where {T<:Base.BitUnsigned} = C.type_unsigned
_to_de_scalar_type(::T) where {T<:Base.IEEEFloat} = C.type_float
_to_de_scalar_type(::T) where {T<:Complex{<:Base.IEEEFloat}} = C.type_complex
_to_de_scalar_type(::T) where {T<:StrOrSym} = C.type_string

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

# ###############   read  
function load_scalar(de::DEFile, id::C.obj_id_t)
    scalar = Ref{C.scalar_t}()
    _check(C.de_load_scalar(de, id, scalar))
    value = _from_de_scalar(scalar[])
    # look for attribute named "jtype" to see if we need to convert
    jtype = get_attribute(de, id, "jtype")
    if ismissing(jtype)
        return value
    end
    JT = Meta.eval(Meta.parse(jtype))
    return _apply_jtype(JT, value)
end

function _from_de_scalar(scal::C.scalar_t)
    _type = scal.object.type
    if _type == C.type_string
        return unsafe_string(Ptr{UInt8}(scal.value))
    end
    if _type == C.type_date
        FR = _to_julia_frequency(Val(scal.frequency))
        T = _to_julia_scalar_type(Val(C.type_integer), Val(scal.nbytes))
        val = unsafe_load(Ptr{T}(scal.value))
        return convert(MIT{FR}, Int64(val))
    end
    T = _to_julia_scalar_type(Val(_type), Val(scal.nbytes))
    value = unsafe_load(Ptr{T}(scal.value))
    if _type == C.type_signed && scal.frequency != C.freq_none
        FR = _to_julia_frequency(Val(scal.frequency))
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

@inline _to_julia_frequency(::Val{C.freq_unit}) = Unit
@inline _to_julia_frequency(::Val{C.freq_daily}) = Daily
@inline _to_julia_frequency(::Val{C.freq_bdaily}) = BDaily
@inline _to_julia_frequency(::Val{C.freq_monthly}) = Monthly
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
_apply_jtype(::Type{T}, value) where T = convert(T, value)

#############################################################################
# closing remarks

for func in (:load_scalar,)
    @eval begin
        $func(de::DEFile, pid::C.obj_id_t, name::String) = $func(de, find_object(de, pid, name))
    end
end

for func in (:new_scalar, :load_scalar)
    @eval begin
        $func(de::DEFile, name::StrOrSym, args...) = $func(de, root, string(name), args...)
        $func(de::DEFile, parent::AbstractString, name::StrOrSym, args...) = $func(de, find_fullpath(de, parent), string(name), args...)
    end
end


end
