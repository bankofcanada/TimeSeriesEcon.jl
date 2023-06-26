# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

include("C.jl")
using .C

#############################################################################
# error handling

global debug_libdaec = :debug

export DEError
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
# open and close daec files 

end
