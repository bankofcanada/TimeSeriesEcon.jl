# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

import Statistics: mean


"""
    overlay(t1, t2, ...)

Construct a [`TSeries`](@ref) in which each observation is taken from the first
non-missing observation in the list of arguments. A missing observation is one
for which [`istypenan`](@ref) returns `true`.

All [`TSeries`](@ref)` in the arguments list must be of the same frequency. The
data type of the resulting [`TSeries`](@ref) is decided by the standard
promotion of numerical types in Julia. Its range is the union of the ranges of
the arguments.
"""
@inline overlay(ts::TSeries...) = overlay(mapreduce(rangeof, union, ts), ts...)

"""
    overlay(rng, t1, t2, ...)

If the first argument is a range, it becomes the range of the resulting
[`TSeries`](@ref).
"""
function overlay(rng::AbstractRange{<:MIT}, ts::TSeries...)
    T = mapreduce(eltype, promote_type, ts)
    ret = TSeries(rng, typenan(T))
    # na = collection of periods where the entry of ret is missing (typenan(T))
    na = collect(rng)
    for t in ts
        if isempty(na)
            # if na is empty, then we've assigned all slots
            break
        end
        # keep = periods that are not yet assigned and t has valid values in them
        keep = intersect(na, rangeof(t)[values(@. !istypenan(t))])
        # assign
        ret[keep] = t[keep]
        # update na by removing the periods we just assigned
        na = setdiff(na, keep)
    end
    return ret
end
export overlay

function _valid_range(t::TSeries)
    fd = firstdate(t)
    ld = lastdate(t)
    while fd <= ld && istypenan(t[ld])
        ld -= 1
    end
    while fd <= ld && istypenan(t[fd])
        fd += 1
    end
    return fd:ld
end

Base.strip(t::TSeries) = getindex(t, _valid_range(t))
strip!(t::TSeries) = resize!(t, _valid_range(t))
export strip!

"""
    fconvert(F, t)

Convert the time series `t` to the desired frequency `F`.
"""
fconvert(F::Type{<:Frequency}, t::TSeries; args...) = error("""
Conversion from $(frequencyof(t)) to $F not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(::Type{F}, t::TSeries{F}) where {F <: Frequency} = t

"""
    fconvert(F1, t::TSeries{F2}; method) where {F1 <: YPFrequency, F2 <: YPFrequency}

Convert between frequencies of the [`YPFrequency`](@ref) variety.

TODO: describe `method` when converting to a higher frequency (interpolation)
TODO: describe `method` when converting to a lower frequency (aggregation)

"""
function fconvert(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=nothing) where {N1,N2}
    args = Dict()
    if method !== nothing
        args[:method] = method
    end
    N1 > N2 ? _to_higher(F, t; args...) : _to_lower(F, t; args...)
end

function _to_higher(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:const) where {N1,N2}
    (np, r) = divrem(N1, N2)
    if r != 0
        throw(ArgumentError("Cannot convert to higher frequency with $N1 ppy from $N2 ppy - not an exact multiple."))
    end
    # np = number of periods of the destination frequency for each period of the source frequency
    (y1, p1) = mit2yp(firstindex(t))
    # (y2, p2) = yp(lastindex(t))
    fi = MIT{F}(y1, (p1 - 1) * np + 1)
    # lastindex_s = pp(y2, p2*np; N=N1))
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end

function _to_lower(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:mean) where {N1,N2}
    (np, r) = divrem(N2, N1)
    # println("np = $np, r = $r")
    if r != 0
        throw(ArgumentError("Cannot convert to lower frequency with $N1 from $N2 - not an exact multiple."))
    end
    (y1, p1) = mit2yp(firstindex(t))
    (d1, r1) = divrem(p1 - 1, np)
    fi = MIT{F}(y1, d1 + 1) + (r1 > 0)
    # println("y1 = $y1, p1 = $p1, d1 = $d1, r1 = $r1, fi = $fi")
    (y2, p2) = mit2yp(lastindex(t))
    (d2, r2) = divrem(p2 - 1, np)
    li = MIT{F}(y2, d2 + 1) - (r2 < np - 1)
    # println("y2 = $y2, p2 = $p2, d2 = $d2, r2 = $r2, li = $li")
    ret = TSeries(eltype(t), fi:li)
    vals = t[begin + (r1 > 0) * (np - r1):end - (r2 < np-1)*(1+r2)].values
    # println("vals = $vals")
    if method == :mean
        copyto!(ret, mean(reshape(vals, np, :); dims=1))
    elseif method == :sum
        copyto!(ret, sum(reshape(vals, np, :); dims=1))
    elseif method == :begin
        copyto!(ret, reshape(vals, np, :)[begin, :])
    elseif method == :end
        copyto!(ret, reshape(vals, np, :)[end, :])
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
    return ret
end

