# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# Serialization (for parallel computing communications)

using Serialization

# ============== MIT ========================================

Base.write(io::IO, p::MIT) = write(io, Ref(p))
Base.read(io::IO, T::Type{<:MIT}) = read!(io, Ref(T(0)))[]
Base.write(io::IO, p::Duration) = write(io, Ref(p))
Base.read(io::IO, T::Type{<:Duration}) = read!(io, Ref(T(0)))[]

# ============== TSeries =====================================
# Not sure this part is really necessary, since it works with Julia's built-in
# implementation just fine

function Serialization.serialize(s::AbstractSerializer, t::TSeries)
    Serialization.serialize_type(s, typeof(t))
    write(s.io, length(t))
    write(s.io, firstdate(t))
    write(s.io, t.values)
end

function Serialization.deserialize(s::AbstractSerializer, S::Type{<:TSeries{F,T}}) where {F,T}
    n = read(s.io, Int)
    fd = read(s.io, MIT{F})
    ret = TSeries(T, fd .+ (0:n-1), undef)
    read!(s.io, ret.values)
    return ret
end

# ============== MVTSeries ===================================

# This part is a must - it works with Julia's built-in implementation, but gives
# the wrong result (. variables are not views into the raw data but separate
# TSeries!!!)

function Serialization.serialize(s::AbstractSerializer, sd::MVTSeries)
    Serialization.serialize_type(s, typeof(sd))
    write(s.io, firstdate(sd))
    write(s.io, lastdate(sd))
    serialize(s, [colnames(sd)...])
    write(s.io, rawdata(sd))
end

function Serialization.deserialize(s::AbstractSerializer, S::Type{<:MVTSeries{F,T}}) where {F,T}
    fd = read(s.io, MIT{F})
    ld = read(s.io, MIT{F})
    cols = deserialize(s)
    ret = MVTSeries(T, fd:ld, cols, undef)
    read!(s.io, rawdata(ret))
    return ret
end
