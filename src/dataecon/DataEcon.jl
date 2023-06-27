# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

using ..TimeSeriesEcon

include("C.jl")
include("I.jl")
using .I

const StrOrSym = Union{Symbol,AbstractString}


#############################################################################
# open and close daec files

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
Base.unsafe_convert(::Type{C.de_file}, de::DEFile) = isopen(de) ? de.handle[] : throw(ArgumentError("File is closed."))
# Base.convert(::Type{C.de_file}, de::DEFile) = isopen(de) ? de.handle[] : throw(ArgumentError("File is closed."))

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
    I._check(C.de_open(fname, handle))
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
        I._check(C.de_close(de.handle[]))
        de.handle[] = C_NULL
    end
    return de
end

#############################################################################
# objects

const root = C.obj_id_t(0)

function find_fullpath(de::DEFile, fullpath::String)
    id = Ref{C.obj_id_t}()
    I._check(C.de_find_fullpath(de, fullpath, id))
    return id[]
end

function find_object(de::DEFile, pid::C.obj_id_t, name::String)
    id = Ref{C.obj_id_t}()
    I._check(C.de_find_object(de, pid, name, id))
    return id[]
end

function get_attribute(de::DEFile, id::C.obj_id_t, name::String)
    value = Ref{Ptr{Cchar}}()
    rc = C.de_get_attribute(de, id, name, value)
    if rc == C.DE_MIS_ATTR
        C.de_clear_error()
        return missing
    end
    I._check(rc)
    return unsafe_string(value[])
end

#############################################################################
# read and write scalars

export new_scalar, load_scalar

# ###############   write scalar
function new_scalar(de::DEFile, pid::C.obj_id_t, name::String, value)
    # the value to be written
    val = I._to_de_scalar_val(value)
    val_type = I._to_de_scalar_type(val)
    val_freq = I._to_de_scalar_freq(val)
    val_nbytes = I._to_de_scalar_nbytes(val)
    val_ptr = I._to_de_scalar_prt(val)
    id = Ref{C.obj_id_t}()
    I._check(C.de_new_scalar(de, pid, name, val_type, val_freq, val_nbytes, val_ptr, id))
    if typeof(val) != typeof(value)
        # write the actual type as an attribute, so we can recover it
        I._check(C.de_set_attribute(de, id[], "jtype", string(typeof(value))))
    end
    return
end

# ###############   read
function load_scalar(de::DEFile, id::C.obj_id_t)
    scalar = Ref{C.scalar_t}()
    I._check(C.de_load_scalar(de, id, scalar))
    value = I._from_de_scalar(scalar[])
    # look for attribute named "jtype" to see if we need to convert
    jtype = get_attribute(de, id, "jtype")
    if ismissing(jtype)
        return value
    end
    JT = Core.eval(Main, Meta.parse(jtype))
    return I._apply_jtype(JT, value)
end


#############################################################################
# read and write tseries

# ###############   write tseries

function new_tseries(de::DEFile, pid::C.obj_id_t, name::String, value)
    ax_id = I._get_axis_of(de.handle[], value, 1)
    ts = I._to_de_tseries(value)
    id = Ref{C.obj_id_t}()
    ptr = isnothing(ts.val) ? C_NULL : pointer(ts.val)
    I._check(C.de_new_tseries(de, pid, name, ts.type, ts.eltype, ax_id, ts.nbytes, ptr, id))
    # if eltype doesn't match, save it in attribute "jeltype"
    while true
        ET = eltype(value)
        ts.type == C.type_range && break
        ts.eltype == C.type_string && ET == String && break
        ts.eltype != C.type_string && ET == I._to_julia_scalar_type(Val(ts.eltype), Val(sizeof(ET))) && !isempty(value) && break
        I._check(C.de_set_attribute(de, id[], "jeltype", string(ET)))
        break
    end
    # if container isn't standard save it in attribute "jtype"
    while true
        ts.type == C.type_range && isa(value, UnitRange) && break
        ts.type == C.type_vector && isa(value, Vector) && break
        ts.type == C.type_tseries && isa(value, TSeries) && break
        I._check(C.de_set_attribute(de, id, "jtype", string(typeof(value))))
        break
    end
    return nothing
end

function load_tseries(de::DEFile, id::C.obj_id_t)
    tseries = Ref{C.tseries_t}()
    I._check(C.de_load_tseries(de, id, tseries))
    value = I._from_de_tseries(tseries[])
    jtype = get_attribute(de, id, "jtype")
    if !ismissing(jtype)
        return convert(jtype, value)
    end
    jeltype = get_attribute(de, id, "jeltype")
    if !ismissing(jeltype)
        JT = Core.eval(Main, Meta.parse(jeltype))
        if isempty(value)
            return JT[]
        else
            return map(v -> I._apply_jtype(JT, v), value)
        end
    end
    return value
end

#############################################################################
# closing remarks

for func in (:load_scalar, :load_tseries)
    @eval begin
        $func(de::DEFile, pid::C.obj_id_t, name::String) = $func(de, find_object(de, pid, name))
    end
end

for func in (:new_scalar, :new_tseries, :load_scalar, :load_tseries)
    @eval begin
        $func(de::DEFile, name::StrOrSym, args...) = $func(de, root, string(name), args...)
        $func(de::DEFile, parent::AbstractString, name::StrOrSym, args...) = $func(de, find_fullpath(de, parent), string(name), args...)
    end
end


end
