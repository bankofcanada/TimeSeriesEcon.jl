# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

include("C.jl")
using .C

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



end
