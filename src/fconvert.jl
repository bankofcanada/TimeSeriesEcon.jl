# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

import Statistics: mean

#### strip and strip!

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

"""
    strip(t:TSeries)

Remove leading and trailing `NaN` from the given time series. This version
creates a new [`TSeries`](@ref) instance.
"""
Base.strip(t::TSeries) = getindex(t, _valid_range(t))
"""
    strip!(t::TSeries)

Remove leading and training `NaN` from the given time series. This is
done in-place.
"""
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
fconvert(::Type{F}, t::TSeries{F}) where {F<:Frequency} = t

"""
    fconvert(F1, x::TSeries{F2}; method) where {F1 <: YPFrequency, F2 <: YPFrequency}

Convert between frequencies derived from [`YPFrequency`](@ref).

Currently this works only when the periods per year of the higher frequency is
an exact multiple of the periods per year of the lower frequency.

### Converting to Higher Frequency
The only method available is `method=:const`, where the value at each period of
the higher frequency is the value of the period of the lower frequency it
belongs to.
```
x = TSeries(2000Q1:2000Q3, collect(Float64, 1:3))
fconvert(Monthly, x)
```

### Converting to Lower Frequency
The range of the result includes periods that are fully included in the range of
the input. For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.
```
x = TSeries(2000M1:2000M7, collect(Float64, 1:7))
fconvert(Quarterly, x; method = :sum)
```
"""
fconvert(F::Type{Quarterly}, t::TSeries{<:Union{Yearly{12}, Quarterly{3}, Monthly}}; method=nothing) = fconvert(Quarterly{3}, t, method=method)
fconvert(F::Type{Yearly}, t::TSeries{<:Union{Yearly{12}, Quarterly{3}, Monthly}}; method=nothing) = fconvert(Yearly{12}, t, method=method)
function fconvert(F::Type{<:Union{Yearly{12}, Quarterly{3}, Monthly}}, t::TSeries{<:Union{Yearly{12}, Quarterly{3}, Monthly}}; method=nothing)
    args = Dict()
    if method !== nothing
        args[:method] = method
    end
    F > frequencyof(t) ? _to_higher(F, t; args...) : _to_lower(F, t; args...)
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
    vals = t[begin+(r1>0)*(np-r1):end-(r2<np-1)*(1+r2)].values
    # println("vals = $vals")
    if method == :mean
        ret = mean(reshape(vals, np, :); dims=1)
    elseif method == :sum
        ret = sum(reshape(vals, np, :); dims=1)
    elseif method == :begin
        ret = reshape(vals, np, :)[begin, :]
    elseif method == :end
        ret = reshape(vals, np, :)[end, :]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
    return copyto!(TSeries(eltype(ret), fi:li), ret)
end

