"""
YP => YP(higher)
    options:  method = :const, values_base = :begin/:end            # could use a linear method...
YP => YP(lower)
    options: method=:mean/:sum/:end/:begin
YP => YP(same)
    options: method = :mean/:begin/:end, interpolation = :none      # sum not available

"""


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
The optional `values_base` argument determines where to assign values when the
end period for the lower frequency is partway through a period in the higher frequency.
There are currently 2 options available: `:end` and `:begin`. The default is `:end`.
`:end` means that the output period will hold the value of the input period which corresponds
to the end of the output period. `:begin` means the value held will correspond to the value
at the beginning of the output period.
For example a Yearly{August} frequency with 20Y = 1, 21Y = 2 to Quarterly.
With values_base=:end, we would have 20Q2 = 1, 20Q3 = 2, 20Q4 = 2. 
(End of 20Q3 is September 20Y, which for the Yearly{August} series is in 21Y)
With values_base=:begin we would have 20Q2 = 1, 20Q3 = 1, 20Q4 = 2. 
(Beginning of 20Q3 is July 20Y, which for the Yearly{August} series is in 20Y)
This value will also affect the truncation of the results.

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
function fconvert(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = nothing, values_base = :end) where {N1,N2}
    args = Dict()
    if method !== nothing
        args[:method] = method
    end
    args[:values_base] = values_base
    if N1 > N2 
        return _to_higher(F_to, t; args...)
    elseif N1 < N2
        return _to_lower(F_to, t; args...)
    elseif N1 == 1
        return _fconvert_similar_yearly(F_to, t; args...)
    elseif N1 == 4
        return _fconvert_similar_quarterly(F_to, t; args...)
    else
        return t
    end 
end

"""
_to_higher(F_to, TSeries{MIT{F_from}}; method=:const, values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

Convert a TSeries to a higher frequency. 

The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

For the `values_base` argument see [`fconvert`](@ref)]
"""
function _to_higher(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = :const, values_base = :end, errors = true, args...) where {N1,N2}
    """
    NOTE: current const method assumes we are interested in matching end-of-period values.
    FAME has other approaches (BEGINNING, AVERAGED, SUMMED, ANNUALIZED, FORMULA, HIGH, LOW)
    These are passed in an "observed" argument to the convert function.
    """
    errors && _validate_fconvert_yp(F_to, frequencyof(t))
    (np, r) = divrem(N1, N2)
    shift_length = _get_shift_to_higher(F_to, frequencyof(t); values_base = values_base, errors = false)
    (y1, p1) = mit2yp(t.firstdate)
    fi = MIT{F_to}(y1, (p1 - 1) * np + 1) - shift_length

    if method == :const
        return TSeries(fi, repeat(t.values, inner = np))
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end


"""
    _to_lower(F_to, TSeries{MIT{F_from}}; method=:mean, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a TSeries to a lower frequency. 
"""
function _to_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = :mean, errors = true, args...) where {N1,N2}
# function _to_lower(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = :mean, errors = true) where {N1,N2}
    F_from = frequencyof(t)
    errors && _validate_fconvert_yp(F_to, F_from)
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        #quarterly{1} to yearly
        """
        All the specialized YPFrequencies (Yearly{N}, Quarterly{N}) are based on some monthly shift.
        We therefore convert the series to monthly, before recalling fconvert on the output.
        """
        return fconvert(F_to, fconvert(Monthly, t), method = method)
    end
    (np, r) = divrem(N2, N1)
    shift_length = _get_shift_to_lower(F_to, F_from, errors = false)
    (y1, p1) = mit2yp(t.firstdate + shift_length)
    (d1, r1) = divrem(p1 - 1, np)
    fi = MIT{F_to}(y1, d1 + 1) + (r1 > 0)

    (y2, p2) = mit2yp(last(rangeof(t)) + shift_length)
    (d2, r2) = divrem(p2 - 1, np)
    li = MIT{F_to}(y2, d2 + 1) - (r2 < np - 1)

    vals = t[begin+(r1>0)*(np-r1):end-(r2<np-1)*(1+r2)].values
    if method == :mean
        ret = mean(reshape(vals, np, :); dims = 1)
    elseif method == :sum
        ret = sum(reshape(vals, np, :); dims = 1)
    elseif method == :begin
        ret = reshape(vals, np, :)[begin, :]
    elseif method == :end
        ret = reshape(vals, np, :)[end, :]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
    return copyto!(TSeries(eltype(ret), fi:li), ret)
end


"""
_fconvert_similar_yearly(F_to::Type{<:Union{<:Yearly,Yearly{N1}}}, t::TSeries{<:Union{<:Yearly,Yearly{N2}}}; method = :end, interpolation = :none, values_base=:end, args...) where {N1,N2}

An intermediate helper function for converting between similar YP frequencies with different base months..
"""
function _fconvert_similar_yearly(F_to::Type{<:Union{<:Yearly,Yearly{N1}}}, t::TSeries{<:Union{<:Yearly,Yearly{N2}}}; method = :end, interpolation = :none, values_base=:end, args...) where {N1,N2}
    np = 12
    N_to_effective = @isdefined(N1) ? N1 : np
    N_from_effective = @isdefined(N2) ? N2 : np
    return _fconvert_similar_frequency(F_to, t, N_to_effective, N_from_effective, np; method = method, interpolation = interpolation, args...)
end

"""
_fconvert_similar_quarterly(F_to::Type{<:Union{Quarterly,Quarterly{N1}}}, t::TSeries{<:Union{Quarterly,Quarterly{N2}}}; method = :end, interpolation = :none, args...) where {N1,N2}

An intermediate helper function for converting between similar YP frequencies with different base months..
"""
function _fconvert_similar_quarterly(F_to::Type{<:Union{Quarterly,Quarterly{N1}}}, t::TSeries{<:Union{Quarterly,Quarterly{N2}}}; method = :end, interpolation = :none, args...) where {N1,N2}
    np = 3
    N_to_effective = @isdefined(N1) ? N1 : np
    N_from_effective = @isdefined(N2) ? N2 : np
    return _fconvert_similar_frequency(F_to, t, N_to_effective, N_from_effective, np; method = method, interpolation = interpolation, args...)
end

"""
_fconvert_similar_frequency(F_to::Type{<:Union{Quarterly,Quarterly{N1}}}, t::TSeries{<:Union{Quarterly,Quarterly{N2}}}; method = :end, interpolation = :none, args...) where {N1,N2}

Converts a TSeries between similar YP frequencies with different base months.

Currently the only methods available are `:mean`, `:begin`, `:end`, and `:const`. The default is `"mean`.
`:const` is equivalent to `:begin` or `:end`, depending on the `values_base` argument. The default is `:end`.

There is currently no interpolation available.
"""
function _fconvert_similar_frequency(F_to::Type{<:Frequency}, t::TSeries, N_to_effective::Integer, N_from_effective::Integer, np::Integer; method = :end, interpolation = :none, values_base=:end)
    N_shift = N_to_effective - N_from_effective
    if N_shift == 0
        return TSeries(MIT{F_to}(Int(t.firstdate)), t.values)
    end
    if values_base ∉ (:end, :begin)
        throw(ArgumentError("values_base argument must be :begin or :end."))
    end
    if method == :const 
        method = values_base
    end

    if interpolation == :none
        if method == :end
            # example: December to June = -6, in this case we want the same Int
            # example: June to December = 6, in this case we want the previous year, as there is no December value for the last year in the from series
            fi = N_shift < 0 ? MIT{F_to}(Int(t.firstdate)) : MIT{F_to}(Int(t.firstdate) - 1)
            return TSeries(fi, t.values)
        elseif method == :begin
            # example: December to August = -4, in this case we want the next year, since the value at the beginning of the June year is the December value
            # example: August to December = 4, in this case we want the same Int
            fi = N_shift < 0 ? MIT{F_to}(Int(t.firstdate + 1)) : MIT{F_to}(Int(t.firstdate))
            return TSeries(fi, t.values)
        elseif method == :mean
            if N_shift < 0
                # December to August (4/12 last year, 8/12 this year) => - 4
                weights = [(abs(N_shift)) / np, (np + N_shift) / np]
                fi = MIT{F_to}(Int(t.firstdate + 1))
                values = [weights[1] * t.values[i-1] + weights[2] * t.values[i] for i in 2:length(t.values)]
                return TSeries(fi, values)
            elseif N_shift > 0
                # August to December (8/12 this year, 4/12 next year) => 4
                weights = [(np - N_shift) / np, N_shift / np]
                fi = MIT{F_to}(Int(t.firstdate))
                values = [weights[1] * t.values[i] + weights[2] * t.values[i+1] for i in 1:length(t.values)-1]
                return TSeries(fi, values)
            end
        else
            throw(ArgumentError("Conversion method not available when converting between similar frequencies: $(method) ."))
        end
    else
        throw(ArgumentError("Conversion interpolation not available: $(interpolation)."))
    end
end


