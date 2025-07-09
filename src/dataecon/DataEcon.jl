# Copyright (c) 2020-2025, Bank of Canada
# All rights reserved.

module DataEcon

using Dates

export DEError
export DEFile, opendaec, opendaecmem, closedaec!, truncatedaec
export root_id, find_fullpath, find_object, delete_object
export get_attribute, set_attribute, get_all_attributes, get_fullpath
export new_catalog, list_catalog, search_catalog, catalog_size
export store_scalar, load_scalar
export store_tseries, load_tseries
export store_mvtseries, load_mvtseries
export store_ndtseries, load_ndtseries
export writedb, write_data
export readdb, read_data

using ..TimeSeriesEcon
using ..MacroTools

include("C.jl")

function __init__()
    # === make sure the version of the loaded library and 
    #     the one that generated our C.jl are compatible 
    # version of loaded library
    lv = VersionNumber(unsafe_string(C.de_version()))
    # version of DataEcon/include/daec.h used when C.jl was generated
    hv = VersionNumber(C.DE_VERSION)
    # N.B. we have an issue with v0.3.2, which is labelled as a patch release,
    # but in fact contains a breaking change so, starting with 0.4 we use semantic
    # compatibility, and up to 0.3.x versions must match exactly

    if lv <= v"0.3.2"
        lv == hv && return
    else
        if (lv.major == hv.major)
            if lv.major == 0
                lv.minor == hv.minor && lv.patch >= hv.patch && return
            else
                lv.minor >= hv.minor && return
            end
        end
    end
    @error "DataEcon_jll $lv is incompatible. Required version is $hv."
end

const VERSION = VersionNumber(C.DE_VERSION)

#############################################################################
# open and close daec files

"""
    struct DEFile ... end

An instance of a *.daec file. Usually there's no need to create instances
directly. Use [`opendaec`](@ref) and [`closedaec!`](@ref).
"""
struct DEFile{O}
    handle::Ref{C.de_file}
    fname::String
end

# forward declarations that need to be imported by I.jl
function new_catalog end
function store_scalar end
function load_scalar end
function store_tseries end
function store_mvtseries end
function store_ndtseries end
function load_tseries end
function load_mvtseries end
function load_ndtseries end
function writedb end
function readdb end
function set_attribute end
function get_attribute end
function delete_object end
function find_object end

include("I.jl")
using .I

const StrOrSym = Union{Symbol,AbstractString}

Base.isopen(de::DEFile) = de.handle[] != C_NULL
function Base.show(io::IO, de::DEFile{OVERWRITE}) where OVERWRITE
    print(io, "DEFile: \"", de.fname, "\"")
    if isopen(de)
        OVERWRITE && print(io, " (overwrite)")
    else
        print(io, " (closed)")
    end
end
Base.unsafe_convert(::Type{C.de_file}, de::DEFile) = isopen(de) ? de.handle[] : throw(ArgumentError("File is closed."))

"""
    de = opendaec(fname; [readonly, append, overwrite])

    opendaec(fname; [readonly, append]) do de
        ...
    end

Open the .daec file named in the given `fname` string and return an instance of
[`DEFile`](@ref). The version with the do-block automatically closes the file.
When using the stand-alone version, make sure to call [`closedaec!`](@ref). See
also [`opendaecmem`](@ref)

Keyword argument `readonly` defaults to `true`.

Keyword argument `write` is the opposite of `readonly`. If both are set, `write`
takes precedence.

Keyword argument `append` defaults to `true` and results in new data being added
to the contents that may already be in the file. If set to `false`, the file
will be emptied of all its contents (if any) immediately after opening. It is an
error to call with `readonly=true` and `append=false` at the same time.

Keyword argument `truncate` is the opposite of `append`. If both are set,
`truncate` takes precedence.

Keyword argument `overwrite` controls what happens if storing an object with a
name that already exists in the file. If `overwrite` is set to `true`, the
existing object is deleted and the new object is written. Default is `false`,
which causes an error in this case.
"""
function opendaec end

function _do_open(C_open, args...)
    handle = Ref{C.de_file}()
    I._check(C_open(args..., handle))
    return handle
end

function opendaec(fname::AbstractString;
    readonly::Bool=true, write::Bool=!readonly,
    append::Bool=true, truncate::Bool=!append,
    overwrite::Bool=false   # a safer default
)
    truncate && !write && error("Cannot truncate a readonly file.")
    fname = string(fname)
    handle = _do_open(write ? C.de_open : C.de_open_readonly, fname)
    de = DEFile{overwrite}(handle, fname)
    truncate && empty!(de)
    return de
end

function opendaec(f::Function, fname::AbstractString; kwargs...)
    de = opendaec(fname; kwargs...)
    try
        f(de)
    finally
        closedaec!(de)
    end
end

"""
    de = opendaecmem(; [readonly, append, overwrite])

Open a daec file in memory. Keyword arguments `readonly` and `append` are
ignored, since in-memory databases always start empty and writable. Keyword
argument `overwrite` acts the same as in [`opendaec`](@ref).
"""
function opendaecmem(; overwrite::Bool=false)
    handle = _do_open(C.de_open_memory)
    return DEFile{overwrite}(handle, ":memory:")
end

"""
    closedaec!(de)

Close a .daec file that was previously opened with [`opendaec`](@ref). The given
instance of [`DEFile`](@ref) is modified in place to mark it as closed.
"""
function closedaec!(de::DEFile)
    if isopen(de)
        I._check(C.de_close(de))
        de.handle[] = C_NULL
    end
    return de
end

"""
    truncatedaec(de::DEFile)

Reset a daec file to a state as if it were just created.
"""
truncatedaec(de::DEFile) = (I._check(C.de_truncate(de)); de)

Base.empty!(de::DEFile) = truncatedaec(de)
Base.isempty(de::DEFile) = (catalog_size(de, root_id) == 0)

#############################################################################
# objects

"""
    const root_id

The object id of the "/" catalog. 
"""
const root_id = C.obj_id_t(0)

"""
    find_fullpath(de, fullpath, error=true)

Find the object id of the object at the given path. The path must begin with
'/', spell out all catalogs along the way, separated by '/', and name the object
in the end.

The third argument, if given, controls what happens if the object doesn't exist.
* `error=true` directs `find_fullpath` to throw an exception.
* `error=false` directs `find_fullpath` to return `missing`.

See also [`find_object`](@ref)
"""
function find_fullpath(de::DEFile, fullpath::AbstractString, dne_error::Bool=true)
    id = Ref{C.obj_id_t}()
    pref = startswith(fullpath, '/') ? "" : "/"
    rc = C.de_find_fullpath(de, pref * string(fullpath), id)
    if dne_error == false && rc == C.DE_OBJ_DNE
        return missing
    end
    I._check(rc)
    return id[]
end

"""
    find_object(de, parent_id, name, error=true)

Find and return the object id of the object identified by the given parent
catalog and name. The parent catalog `parent_id` can be set to
[`root_id`](@ref), or to the id of a catalog obtained some other way, e.g., from
[`new_catalog`](@ref) or [`find_fullpath`](@ref). The `name` of the object can
be a string or a `Symbol`. It must be the plain name, i.e. not containing any
'/'.

The fourth argument, if given, controls what happens if the object doesn't
exist.
* `error=true` directs `find_object` to throw an exception.
* `error=false` directs `find_object` to return `missing`.

See also [`find_fullpath`](@ref)
"""
function find_object end

find_object(de::DEFile, pid::C.obj_id_t, name::StrOrSym, dne_error::Bool=true) = find_object(de, pid, string(name), dne_error)
function find_object(de::DEFile, pid::C.obj_id_t, name::String, dne_error::Bool=true)
    id = Ref{C.obj_id_t}()
    rc = C.de_find_object(de, pid, name, id)
    dne_error == false && rc == C.DE_OBJ_DNE && return missing
    I._check(rc)
    return id[]
end

"""
    delete_object(de, object_id)

Delete the object with the given `object_id` from the file. It is an error to
pass the id of an object that doesn't exist.

When an object is deleted, all its data and attributes are also deleted. If the
object is a catalog, all objects in it are also deleted, including all nested
catalogs are deleted recursively. 

It is an error, and impossible, to delete the "/" (`root_id`) catalog. If you want to 
delete all objects in a file, use `Base.empty!(de)`

"""
function delete_object(de::DEFile, id::C.obj_id_t)
    I._check(C.de_delete_object(de, id))
    return nothing
end

# import ..LittleDict

"""
    get_all_attributes(de, object_id; delim)
    get_all_attributes(de, fullpath; delim)
    get_all_attributes(de, parent, obj_name; delim)

Retrieve the names and value of all attributes of the given object.
They are returned in a dictionary.

Note: The optional keyword parameter `delim` can be used to override the default
delimiter, which is set to `delim="‖"` and works correctly for all attributes
used internally by this connector. You may need to override this default value
if you set custom attributes where an attribute name or value may contain the
default delimiter string. Explanation: all attributes of the given object are
read from the database in a single string delimited by `delim`. The correct
splitting of this string into individual names and values requires that none of
them contain the delimiter.

"""
function get_all_attributes(de::DEFile, id::C.obj_id_t; delim::String="‖")
    number = Ref{Int64}()
    names = Ref{Ptr{Cchar}}()
    values = Ref{Ptr{Cchar}}()
    rc = C.de_get_all_attributes(de, id, delim, number, names, values)
    I._check(rc)
    if number[] == 0
        return Dict{String,String}()
    end
    all_names = String[split(unsafe_string(names[]), delim);]
    all_values = String[split(unsafe_string(values[]), delim);]
    if length(all_names) != length(all_values)
        error("number of names and values don't match. Try a different delimiter.")
    end
    return Dict{String,String}(all_names .=> all_values)
end

"""
    get_attribute(de, object_id, attr_name)
    get_attribute(de, fullpath, attr_name)
    get_attribute(de, parent, obj_name, attr_name)

Retrieve the value of the named attribute for the object with the given id. The
return value is either a `String` or `missing`.
"""
function get_attribute(de::DEFile, id::C.obj_id_t, attr_name::String)
    value = Ref{Ptr{Cchar}}()
    rc = C.de_get_attribute(de, id, attr_name, value)
    if rc == C.DE_MIS_ATTR
        C.de_clear_error()
        return missing
    end
    I._check(rc)
    return unsafe_string(value[])
end

"""
    set_attribute(de, object_id, attr_name, attr_value)
    set_attribute(de, fullpath, attr_name, attr_value)
    set_attribute(de, parent, obj_name, attr_name, attr_value)

Write the given attribute for the object with the given id. If an attribute with
the given name already exists, it is overwritten.
"""
function set_attribute(de::DEFile, id::C.obj_id_t, name::String, attr_value::String)
    I._check(C.de_set_attribute(de, id, name, attr_value))
    return nothing
end

"""
    get_fullpath(de, object_id)

Retrieve the full path of the object with the given id. The returned value is a
`String`, unless the object doesn't exist, in which case `get_fullpath` throws
an exception.
"""
function get_fullpath(de::DEFile, id::C.obj_id_t)
    fullpath = Ref{Ptr{Cchar}}()
    I._check(C.de_get_object_info(de, id, fullpath, C_NULL, C_NULL))
    return unsafe_string(fullpath[])
end

#############################################################################
# read and write scalars

# ###############   write scalar
"""
    store_scalar(de, fullpath, value)
    store_scalar(de, parent, name, value)

Create a new object with class `class_scalar` and write the given `value` for it
in the .daec file `de`. The new object can be given either as a full path, or as
a parent and a name separately. The value must be one of the Julia types that
can be stored as a scalar, for example numbers or strings.

If the new object is named as a full path, all catalogs must already exist. This
is the case also if given as parent and name separately - the parent must be
either the full path to, or the id of, a catalog that already exists.

It is an error to name an object that already exists. In such case, call
[`delete_object`](@ref) and try again.
"""
function store_scalar(de::DEFile, pid::C.obj_id_t, name::String, value)
    I._overwrite_object(de, pid, name)
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
"""
    load_scalar(de, id)
    load_scalar(de, fullpath)
    load_scalar(de, parent, name)

Load an object of class `class_scalar` from the given .daec file `de`.

The object can be specified by its id, or by its full name. The full name can be
given as a fullpath or as a parent and a name separately.  IF given separately, 
the parent can be specified as an id or fullpath. 

Throws an exception if the object doesn't exist, or if the object's class is not
`class_scalar`.

The return value is a Julia object of an appropriate type.
"""
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

"""
    store_tseries(de, fullpath, value)
    store_tseries(de, parent, name, value)

Create a new object with class `class_tseries` and write the given `value` for
it in the .daec file `de`. The new object can be given either as a full path, or
as a parent and a name separately. The value must be one of the Julia types that
can be stored as a 1d array, for example `TSeries`, `Vector`, `UnitRange`.

If the new object is named as a full path, all catalogs must already exist. This
is the case also if given as parent and name separately - the parent must be
either the full path to, or the id of, a catalog that already exists.

It is an error to name an object that already exists. In such case, call
[`delete_object`](@ref) and try again.
"""
function store_tseries(de::DEFile, pid::C.obj_id_t, name::String, value)
    I._overwrite_object(de, pid, name)
    ax_id = I._get_axis_of(de, value, 1)
    return I._store_array(de, pid, name, (ax_id,), value)
end

"""
    store_mvtseries(de, fullpath, value)
    store_mvtseries(de, parent, name, value)

Create a new object with class `class_mvtseries` and write the given `value` for
it in the .daec file `de`. The new object can be given either as a full path, or
as a parent and a name separately. The value must be one of the Julia types that
can be stored as a 2d array, for example `MVTSeries`, `Matrix`.

If the new object is named as a full path, all catalogs must already exist. This
is the case also if given as parent and name separately - the parent must be
either the full path to, or the id of, a catalog that already exists.

It is an error to name an object that already exists. In such case, call
[`delete_object`](@ref) and try again.
"""
function store_mvtseries(de::DEFile, pid::C.obj_id_t, name::String, value)
    I._overwrite_object(de, pid, name)
    ax1_id = I._get_axis_of(de, value, 1)
    ax2_id = I._get_axis_of(de, value, 2)
    return I._store_array(de, pid, name, (ax1_id, ax2_id), value)
end

"""
    store_ndtseries(de, fullpath, value)
    store_ndtseries(de, parent, name, value)

Create a new object with class `class_ndtseries` and write the given `value` for
it in the .daec file `de`. The new object can be given either as a full path, or
as a parent and a name separately. The value must be one of the Julia types that
can be stored as a nd array, for example `Array{T,N}`. Note that `N` must not be
greater than 5 (the current value or `DE_MAX_AXES` in "daec.h"). For N = 1 or 2,
the call is redirected to [`store_tseries`](@ref) or [`store__mvtseries`](@ref)
recpectively.

If the new object is named as a full path, all catalogs must already exist. This
is the case also if given as parent and name separately - the parent must be
either the full path to, or the id of, a catalog that already exists.

It is an error to name an object that already exists. In such case, call
[`delete_object`](@ref) and try again.
"""
function store_ndtseries end

function _store_ndtseries_body(N)
    ret = Expr(:block)
    push!(ret.args, :(I._overwrite_object(de, pid, name)))
    ax_sym = Vector{Symbol}(undef, N)
    for i = 1:N
        ax_sym[i] = Symbol(:ax, i, :_id)
        push!(ret.args, :($(ax_sym[i]) = I._get_axis_of(de, value, $i)))
    end
    push!(ret.args, :(I._store_array(de, pid, name, ($(ax_sym...),), value)))
    return ret
end

@generated function store_ndtseries(de::DEFile, pid::C.obj_id_t, name::String, value::AbstractArray{T,N}) where {T,N}
    # if N > C.DE_MAX_AXES
    #     return :(error("Maximum number of dimensions supported by DataEcon library is $(C.DE_MAX_AXES)"))
    # else
        return _store_ndtseries_body(N)
    # end
end

# ###############   read tseries

"""
    load_tseries(de, id)
    load_tseries(de, fullpath)
    load_tseries(de, parent, name)

Load an object of class `class_tseries` from the given .daec file `de`.

The object can be specified by its id, or by its full name. The full name can be
given as a fullpath or as a parent and a name separately. IF given separately,
the parent can be specified as an id or fullpath.

Throws an exception if the object doesn't exist, or if the object's class is not
`class_tseries`.

The return value is a Julia object of an appropriate type.
"""
function load_tseries(de::DEFile, id::C.obj_id_t)
    arr = Ref{C.tseries_t}()
    I._check(C.de_load_tseries(de, id, arr))
    return I._to_julia_array(de, id, arr[])
end

"""
    load_mvtseries(de, id)
    load_mvtseries(de, fullpath)
    load_mvtseries(de, parent, name)

Load an object of class `class_mvtseries` from the given .daec file `de`.

The object can be specified by its id, or by its full name. The full name can be
given as a fullpath or as a parent and a name separately. IF given separately,
the parent can be specified as an id or fullpath.

Throws an exception if the object doesn't exist, or if the object's class is not
`class_mvtseries`.

The return value is a Julia object of an appropriate type.
"""
function load_mvtseries(de::DEFile, id::C.obj_id_t)
    arr = Ref{C.mvtseries_t}()
    I._check(C.de_load_mvtseries(de, id, arr))
    return I._to_julia_array(de, id, arr[])
end

#############################################################################
# catalogs

"""
    new_catalog(de, fullpath)
    new_catalog(de, parent, name)

Create a new object with class `class_catalog` in the given .daec file `de`. The
new object can be specified either as a full path, or as a parent and a name
separately.

If the new object is named as a full path, all catalogs in the path must already
exist (except the last one, which is being created). This is the case also if
given as parent and name separately - the parent must be either the full path
to, or the id of, a catalog that already exists.

It is an error to name an object that already exists. In such case, call
[`delete_object`](@ref) and try again.
"""
function new_catalog(de::DEFile, pid::C.obj_id_t, name::String)
    I._overwrite_object(de, pid, name)
    id = Ref{C.obj_id_t}()
    I._check(C.de_new_catalog(de, pid, name, id))
    return id[]
end

@inline catalog_size(de::DEFile, name::StrOrSym) = catalog_size(de, find_fullpath(de, name))
function catalog_size(de::DEFile, pid::C.obj_id_t)
    count = Ref{Int64}()
    I._check(C.de_catalog_size(de, pid, count))
    return count[]
end

@inline list_catalog(de::DEFile, name::StrOrSym; kwargs...) = list_catalog(de, find_fullpath(de, string(name)); kwargs...)
function list_catalog(de::DEFile, cid::C.obj_id_t=root_id; quiet=false, verbose=!quiet, file::IO=Base.stdout,
    recursive=true, maxdepth::Int=recursive ? typemax(Int) : 1)
    I._list_catalog(de, cid, maxdepth, verbose, file)
end

#############################################################################
# recursive high-level write

"""
    writedb(de, [parent,] data)

    writedb(file, [parent], data; [append])

Write the given `data` into the given .daec file `de`. If parent catalog is
specified (as a path or id), then the data is written in it, otherwise it is
written in the root catalog.

The `data` must be a `Workspace`. Each nested `Workspace` is written in a
sub-catalog recursively. All other values are written as objects of class
`class_scalar`, `class_tseries` or `class_mvtseries`, as appropriate. 

Any values that cannot be resolved as one of the object classes are skipped,
with an error message issued accordingly, without throwing an exception.

The destination can be given as file path, in which case the file will be open
for writing and closed after writing completes. Keyword argument `append`
controls whether or not the file will be emptied before writing in it.

See [`write_data`](@ref).
"""
function writedb end

# main driver
function writedb(de::DEFile, pid::C.obj_id_t, data::Workspace)
    for (name, value) in pairs(data)
        write_data(de, pid, name, value)
    end
    return nothing
end

# variations
writedb(de::DEFile, data::Workspace) = writedb(de, root_id, data)
writedb(de::DEFile, parent::AbstractString, data::Workspace) = writedb(de, find_fullpath(de, string(parent)), data)
function writedb(file::AbstractString, args...; append::Bool=true, truncate::Bool=!append)
    opendaec(file; write=true, truncate) do de
        writedb(de, args...)
    end
end

"""
    write_data(de, fullpath, value)
    write_data(de, parent, name, value)

Create a new object with an appropriate class and write the given `value` for it
in the given .daec file `de`. The new object can be given either as a full path,
or as a parent and a name separately.

If the new object is specified as a full path, all catalogs must already exist.
This is the case also if given as parent and name separately - the parent must
be either the fullpath to, or the id of, a catalog that already exists.

It is an error to name an object that already exists. In such case, call
[`delete_object`](@ref) and try again.

If `data` is a [`Workspace`](@ref), it is stored as a new catalog with all
members of `data` written in it recursively. Otherwise, `write_data` calls one
of [`store_scalar`](@ref), [`store_tseries`](@ref), or
[`store_mvtseries`](@ref).
"""
function write_data(de::DEFile, pid::C.obj_id_t, name::StrOrSym, value)
    try
        I._write_data(de, pid, name, value)
    catch err
        parent = pid == 0 ? "" : get_fullpath(de, pid)
        @error "Failed to write $parent/$name of type $(typeof(value))." err
        # rethrow()
    end
end


#############################################################################
# recursive high-level read

"""
    readdb(de [, catalog])

Load all objects in a given catalog from the given .daec file and 
return them in a [`Workspace`](@ref)

If `catalog` is not given, it is assumed to be the root catalog, "/" or
`root_id`. If given, it can be specified as an id, a fullpath, or a parent and a
name separately.  The specified object must exist and be of class `class_catalog`.

All object contained in the specified catalog are loaded by [`read_data`](@ref).
"""
function readdb end

readdb(de::DEFile, id::C.obj_id_t=root_id) = read_data(de, id)
readdb(de::DEFile, name::Symbol) = (oid = find_object(de, root_id, string(name)); read_data(de, oid))
function readdb(de::DEFile, name::AbstractString)
    oid = startswith(name, '/') ? find_fullpath(de, string(name)) : find_object(de, root_id, string(name))
    read_data(de, oid)
end
function readdb(file::AbstractString, args...)
    opendaec(file; readonly=true) do de
        readdb(de, args...)
    end
end

"""
    read_data(de, id)
    read_data(de, fullpath)
    read_data(de, parent, name)

Load the specified object  from the given .daec file `de`.

The object can be specified by its id, or by its full name. The full name can be
given as a fullpath or as a parent and a name separately. If given separately,
the parent can be specified as an id or fullpath.

Throws an exception if the object doesn't exist. Otherwise, if the object
exists, `read_data` examines the class of the object and calls one of
[`load_scalar`](@ref), [`load_tseries`](@ref), or [`load_mvtseries`](@ref)
accordingly. That is unless the object has class `class_catalog`, then
`read_data` returns a `Workspace` containing the objects in that catalog loaded
by recursive calls to `read_data`.

The return value is a Julia object of an appropriate type.
"""
read_data(de::DEFile, id::C.obj_id_t) = I._read_data(de, id)

#############################################################################
# closing remarks :)

for func in (:load_scalar, :load_tseries, :load_mvtseries, :delete_object, :read_data)
    @eval begin
        $func(de::DEFile, pid::C.obj_id_t, name::String) = $func(de, find_object(de, pid, name))
    end
end
get_attribute(de::DEFile, pid::C.obj_id_t, name::String, attr_name) = get_attribute(de, find_object(de, pid, name), string(attr_name))
set_attribute(de::DEFile, pid::C.obj_id_t, name::String, attr_name, attr_val) = set_attribute(de, find_object(de, pid, name), string(attr_name), string(attr_val))
get_all_attributes(de::DEFile, pid::C.obj_id_t, name::String; delim="‖") = get_all_attributes(de, find_object(de, pid, name); delim=string(delim))

for (funcs, iargs, ikwargs) in (
    ((:load_scalar, :load_tseries, :load_mvtseries, :load_ndtseries, :delete_object, :read_data, :new_catalog), (), ()),
    ((:store_scalar, :store_tseries, :store_mvtseries, :store_ndtseries, :write_data), (:value,), ()),
    ((:get_attribute,), (:attr_name,), ()),
    ((:set_attribute,), (:attr_name, :attr_val,), ()),
    ((:get_all_attributes,), (), (Expr(:kw, :delim, "‖"),)),
)
    for func in funcs
        oargs = map(MacroTools.namify, iargs)
        okwargs = map(MacroTools.namify, ikwargs)
        @eval begin
            $func(de::DEFile, pid::C.obj_id_t, name::Symbol, $(iargs...); $(ikwargs...)) = $func(de, pid, string(name), $(oargs...); $(okwargs...))
            $func(de::DEFile, name::Symbol, $(iargs...); $(ikwargs...)) = $func(de, root_id, string(name), $(oargs...); $(okwargs...))
            $func(de::DEFile, name::AbstractString, $(iargs...); $(ikwargs...)) = $func(de, splitdir(name)..., $(oargs...); $(okwargs...))
            $func(de::DEFile, parent::AbstractString, name::StrOrSym, $(iargs...); $(ikwargs...)) = $func(de, find_fullpath(de, parent), string(name), $(oargs...); $(okwargs...))
        end
    end
end

end
