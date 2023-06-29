# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

using ..TimeSeriesEcon

include("C.jl")

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

# forward declarations that need to be imported by I.jl
function new_catalog end
function store_scalar end
function load_scalar end
function store_tseries end
function store_mvtseries end
function load_tseries end
function load_mvtseries end
function writedb end
function readdb end
function set_attribute end
function get_attribute end

include("I.jl")
using .I

const StrOrSym = Union{Symbol,AbstractString}

Base.isopen(de::DEFile) = de.handle[] != C_NULL
function Base.show(io::IO, de::DEFile)
    summary(io, de)
    print(io, ": \"", de.fname, isopen(de) ? "\"" : "\" (closed)")
end
Base.unsafe_convert(::Type{C.de_file}, de::DEFile) = isopen(de) ? de.handle[] : throw(ArgumentError("File is closed."))

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

"""
    closedaec!(de)

Close a .daec file that was previously opened with [`opendaec`](@ref).
The given instance of `DEFile` is modified in place to mark it as closed.
"""
function closedaec! end

function closedaec!(de::DEFile)
    if isopen(de)
        I._check(C.de_close(de))
        de.handle[] = C_NULL
    end
    return de
end

#############################################################################
# objects

const root = C.obj_id_t(0)

function find_fullpath(de::DEFile, fullpath::AbstractString, dne_error::Bool=true)
    id = Ref{C.obj_id_t}()
    rc = C.de_find_fullpath(de, string(fullpath), id)
    if dne_error == false && rc == C.DE_OBJ_DNE
        return missing
    end
    I._check(rc)
    return id[]
end

find_object(de::DEFile, pid::C.obj_id_t, name::StrOrSym, dne_error::Bool=true) = find_object(de, pid, string(name), dne_error)
function find_object(de::DEFile, pid::C.obj_id_t, name::String, dne_error::Bool=true)
    id = Ref{C.obj_id_t}()
    rc = C.de_find_object(de, pid, name, id)
    if dne_error == false && rc == C.DE_OBJ_DNE
        return missing
    end
    I._check(rc)
    return id[]
end

function delete_object(de::DEFile, id::C.obj_id_t)
    I._check(C.de_delete_object(de, id))
    return nothing
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

function set_attribute(de::DEFile, id::C.obj_id_t, name::String, value::String)
    I._check(C.de_set_attribute(de, id, name, value))
    return nothing
end

function get_fullpath(de::DEFile, id::C.obj_id_t)
    fullpath = Ref{Ptr{Cchar}}()
    I._check(C.de_get_object_info(de, id, fullpath, C_NULL, C_NULL))
    return unsafe_string(fullpath[])
end

#############################################################################
# read and write scalars

# ###############   write scalar
function store_scalar(de::DEFile, pid::C.obj_id_t, name::String, value)
    # the value to be written
    val = I._to_de_scalar_val(value)
    val_type = I._to_de_scalar_type(val)
    val_freq = I._to_de_scalar_freq(val)
    val_nbytes = I._to_de_scalar_nbytes(val)
    id = Ref{C.obj_id_t}()
    GC.@preserve val begin
        val_ptr = I._to_de_scalar_ptr_unsafe(val)
        I._check(C.de_store_scalar(de, pid, name, val_type, val_freq, val_nbytes, val_ptr, id))
    end
    if typeof(val) != typeof(value)
        # write the actual type as an attribute, so we can recover it
        set_attribute(de, id[], "jtype", string(typeof(value)))
    end
    return id[]
end

# ###############   read scalar
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

function store_tseries(de::DEFile, pid::C.obj_id_t, name::String, value)
    ax_id = I._get_axis_of(de, value, 1)
    return I._store_array(de, pid, name, (ax_id,), value)
end

function store_mvtseries(de::DEFile, pid::C.obj_id_t, name::String, value)
    ax1_id = I._get_axis_of(de, value, 1)
    ax2_id = I._get_axis_of(de, value, 2)
    return I._store_array(de, pid, name, (ax1_id, ax2_id), value)
end

# ###############   read tseries

function load_tseries(de::DEFile, id::C.obj_id_t)
    arr = Ref{C.tseries_t}()
    I._check(C.de_load_tseries(de, id, arr))
    return I._to_julia_array(de, id, arr[])
end

function load_mvtseries(de::DEFile, id::C.obj_id_t)
    arr = Ref{C.mvtseries_t}()
    I._check(C.de_load_mvtseries(de, id, arr))
    return I._to_julia_array(de, id, arr[])
end

#############################################################################
# catalogs

function new_catalog(de::DEFile, pid::C.obj_id_t, name::String, value=nothing)
    id = Ref{C.obj_id_t}()
    I._check(C.de_new_catalog(de, pid, name, id))
    return id[]
end

#############################################################################
# recursive high-level write

# main driver
function writedb(de::DEFile, pid::C.obj_id_t, data::Workspace)
    for (name, value) in pairs(data)
        write_data(de, pid, name, value)
    end
    return nothing
end

# variations
writedb(de::DEFile, data::Workspace) = writedb(de, root, data)
writedb(de::DEFile, parent::AbstractString, data::Workspace) = writedb(de, find_fullpath(de, string(parent)), data)
function writedb(file::AbstractString, args...)
    opendaec(file) do de
        writedb(de, args...)
    end
end

function write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value)
    try
        I._write_data(de, pid, name, value)
    catch err
        parent = get_fullpath(de, pid)
        @error "Failed to write $parent/$name of type $(typeof(value))." err
        # rethrow()
    end
end


#############################################################################
# recursive high-level read

readdb(de::DEFile) = read_data(de, root)
readdb(de::DEFile, id::C.obj_id_t) = read_data(de, id)
readdb(de::DEFile, name::Symbol) = read_data(de, find_object(de, root, string(name)))
readdb(de::DEFile, catalog::AbstractString) = read_data(de, find_fullpath(de, string(catalog)))
function readdb(file::AbstractString, args...)
    opendaec(file) do de
        readdb(de, args...)
    end
end

read_data(de::DEFile, id::C.obj_id_t) = I._read_data(de, id)

#############################################################################
# closing remarks :)

for func in (:load_scalar, :load_tseries, :load_mvtseries, :delete_object, :read_data, :new_catalog)
    if func != :new_catalog
        @eval begin
            $func(de::DEFile, pid::C.obj_id_t, name::String) = $func(de, find_object(de, pid, name))
            $func(de::DEFile, pid::C.obj_id_t, name::Symbol) = $func(de, find_object(de, pid, string(name)))
        end
    end
    @eval begin
        $func(de::DEFile, name::Symbol) = $func(de, root, string(name))
        $func(de::DEFile, name::AbstractString) = $func(de, splitdir(name)...)
        $func(de::DEFile, parent::AbstractString, name::StrOrSym) = $func(de, find_fullpath(de, parent), string(name))
    end
end

for func in (:store_scalar, :store_tseries, :store_mvtseries, :write_data)
    @eval begin
        $func(de::DEFile, pid::C.obj_id_t, name::Symbol, value) = $func(de, pid, string(name), value)
        $func(de::DEFile, name::Symbol, value) = $func(de, root, string(name), value)
        $func(de::DEFile, name::AbstractString, value) = $func(de, splitdir(name)..., value)
        $func(de::DEFile, parent::AbstractString, name::StrOrSym, value) = $func(de, find_fullpath(de, parent), string(name), value)
    end
end


end
