# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

using Dates

export DEError
export DEFile, opendaec, closedaec!, truncatedaec
export root_id, find_fullpath, find_object, delete_object
export get_attribute, set_attribute, get_fullpath
export store_scalar, load_scalar
export store_tseries, load_tseries
export store_mvtseries, load_mvtseries
export writedb, write_data
export readdb, read_data

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
[`DEFile`](@ref). The version with the do-block automatically closes the file.
Otherwise, call [`closedaec!`](@ref).
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
    Base.empty!(de::DEFile)

Delete all objects in the given open .daec file. 
"""
Base.empty!(de::DEFile) = (I._check(C.de_truncate(de)); de)

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
    rc = C.de_find_fullpath(de, string(fullpath), id)
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
    if dne_error == false && rc == C.DE_OBJ_DNE
        return missing
    end
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
delete all objects in a file, use [`truncatedaec`](@ref)

"""
function delete_object(de::DEFile, id::C.obj_id_t)
    I._check(C.de_delete_object(de, id))
    return nothing
end

"""
    get_attribute(de, object_id, attr_name)

Retrieve the value of the named attribute for the object with the given id. The
return value is either a `String` or `missing`.
"""
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

"""
    set_attribute(de, object_id, attr_name, attr_value)

Write the given attribute for the object with the given id. If an attribute with
the given name already exists, it is overwritten.
"""
function set_attribute(de::DEFile, id::C.obj_id_t, name::String, value::String)
    I._check(C.de_set_attribute(de, id, name, value))
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
    ax1_id = I._get_axis_of(de, value, 1)
    ax2_id = I._get_axis_of(de, value, 2)
    return I._store_array(de, pid, name, (ax1_id, ax2_id), value)
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
    id = Ref{C.obj_id_t}()
    I._check(C.de_new_catalog(de, pid, name, id))
    return id[]
end

#############################################################################
# recursive high-level write

"""
    writedb(de, [parent,] data)

Write the given `data` into the given .daec file `de`. If parent catalog is
specified (as a path or id), then the data is written in it, otherwise it is
written in the root catalog.

The `data` must be a `Workspace`. Each nested `Workspace` is written in a
sub-catalog recursively. All other values are written as objects of class
`class_scalar`, `class_tseries` or `class_mvtseries`, as appropriate. 

Any values that cannot be resolved as one of the object classes are skipped,
with an error message issued accordingly, without throwing an exception.

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
function writedb(file::AbstractString, args...)
    opendaec(file) do de
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
        parent = get_fullpath(de, pid)
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

readdb(de::DEFile) = readdb(de, root_id)
readdb(de::DEFile, id::C.obj_id_t) = read_data(de, id)
readdb(de::DEFile, name::Symbol) = read_data(de, find_object(de, root_id, string(name)))
readdb(de::DEFile, catalog::AbstractString) = read_data(de, find_fullpath(de, string(catalog)))
function readdb(file::AbstractString, args...)
    opendaec(file) do de
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

for func in (:load_scalar, :load_tseries, :load_mvtseries, :delete_object, :read_data, :new_catalog)
    if func != :new_catalog
        @eval begin
            $func(de::DEFile, pid::C.obj_id_t, name::String) = $func(de, find_object(de, pid, name))
            $func(de::DEFile, pid::C.obj_id_t, name::Symbol) = $func(de, find_object(de, pid, string(name)))
        end
    end
    @eval begin
        $func(de::DEFile, name::Symbol) = $func(de, root_id, string(name))
        $func(de::DEFile, name::AbstractString) = $func(de, splitdir(name)...)
        $func(de::DEFile, parent::AbstractString, name::StrOrSym) = $func(de, find_fullpath(de, parent), string(name))
    end
end

for func in (:store_scalar, :store_tseries, :store_mvtseries, :write_data)
    @eval begin
        $func(de::DEFile, pid::C.obj_id_t, name::Symbol, value) = $func(de, pid, string(name), value)
        $func(de::DEFile, name::Symbol, value) = $func(de, root_id, string(name), value)
        $func(de::DEFile, name::AbstractString, value) = $func(de, splitdir(name)..., value)
        $func(de::DEFile, parent::AbstractString, name::StrOrSym, value) = $func(de, find_fullpath(de, parent), string(name), value)
    end
end


end
