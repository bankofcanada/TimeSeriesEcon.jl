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
fconvert(F::Type{<:Frequency}, t::UnitRange{MIT}; args...) = error("""
Conversion from $(frequencyof(t)) to $F not implemented.
""")
fconvert(F::Type{<:Frequency}, t::MIT; args...) = error("""
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
The optional `values_base` argument determines where to assign values when the
end period for the lower frequency is partway through a period in the higher frequency.
There are currently 2 options available: `:end` and `:beginning`. The default is `:end`.
`:end` means that the output period will hold the value of the input period which corresponds
to the end of the output period. `:beginning` means the value held will correspond to the value
at the beginning of the output period.
For example a Yearly{August} frequency with 20Y = 1, 21Y = 2 to Quarterly.
With values_base=:end, we would have 20Q2 = 1, 20Q3 = 2, 20Q4 = 2. 
(End of 20Q3 is September 20Y, which for the Yearly{August} series is in 21Y)
With values_base=:beginning we would have 20Q2 = 1, 20Q3 = 1, 20Q4 = 2. 
(Beginning of 20Q3 is July 20Y, which for the Yearly{August} series is in 20Y)


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
function fconvert(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=nothing, values_base=:end) where {N1,N2}
    args = Dict()
    if method !== nothing
        args[:method] = method
    end
    # if values_base !== nothing
    args[:values_base] = values_base
    # end
    N1 > N2 ? _to_higher(F_to, t; args...) : _to_lower(F_to, t; args...)
    end

"""
fconvert(F1, x::Union{MIT{F2},UnitRange{MIT{F2}}}; round_to=nothing, values_base=nothing) where {F1 <: YPFrequency, F2 <: YPFrequency}

Converts an MIT or a range of MITs to a different YPFrequency.

The optional `values_base` argument is as the conversion for a time series.

The optional `round_to` argument is used in conversions of single MITs to a lower frequency. 
It determines where to shift the output MIT to in cases where the input MIT is in between periods of the output frequency. 
The default is :current (provides the output period within which lies provided MIT).
:next provides the output period following the one in which the provided MIT lands except when the provided MIT is at the start of its current period.
:previous provides the output period preceeding the one in which the provided MIT lands except when the provided MIT is at the end of its current period.

"""
function fconvert(F_to::Type{<:YPFrequency{N1}}, Inst_from::Union{<:MIT{<:YPFrequency{N2}},<:UnitRange{<:MIT{<:YPFrequency{N2}}}}; round_to=nothing, values_base=nothing) where {N1,N2}
    args = Dict()
    if values_base !== nothing
        args[:values_base] = values_base
    end
    if round_to !== nothing
        args[:round_to] = round_to
    end
    N1 > N2 ? _to_higher(F_to, Inst_from; args...) : _to_lower(F_to, Inst_from; args...)
end


    """
    _validate_fconvert_yp(F_to, F_from; method) where {F_to <: YPFrequency, F_from <: YPFrequency}

    This helper function throws errors when conversions are attempted between unsopported YPFrequencies
    or from/to a YPFrequency with an unsupported reference month.
    """
function _validate_fconvert_yp(F_to::Type{<:YPFrequency{N1}}, F_from::Type{<:YPFrequency{N2}})  where {N1,N2}
    if N1 == N2
        error("Conversion from $F_from to $F_to not implemented.")
    end
    if N1 > N2
    (np, r) = divrem(N1, N2)
    if r != 0
        throw(ArgumentError("Cannot convert to higher frequency with $N1 ppy from $N2 ppy - not an exact multiple."))
    end
    elseif N2 > N1
        (np, r) = divrem(N2, N1)
        if r != 0
            throw(ArgumentError("Cannot convert to lower frequency with $N1 ppy from $N2 ppy - not an exact multiple."))
        end
        end
        
    if hasproperty(F_to, :parameters) && length(F_to.parameters) > 0
        months_in_period, remainder = divrem(12, N1)
        if remainder != 0
            throw(ArgumentError("Cannot convert to frequency with $N1 yearly periods and a non-default end month $(F_to.parameters[1]). 12 must be divisible by The number of yearly periods for custom end months."))
        end
        if F_to.parameters[1] ∉ tuple(collect(1:months_in_period)...)
            throw(ArgumentError("Target yearly frequency has an unsupported end month: $(F_to.parameters[1]). Must be 1-$months_in_period."))
        end
    end
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        months_in_period, remainder = divrem(12, N2)
        if remainder != 0
            throw(ArgumentError("Cannot convert from frequency with $N2 yearly periods and a non-default end month $(F_from.parameters[1]). 12 must be divisible by The number of yearly periods for custom end months."))
        end
        if F_from.parameters[1] ∉ tuple(collect(1:months_in_period)...)
            throw(ArgumentError("Source yearly frequency has an unsupported end month: $(F_from.parameters[1]). Must be 1-$months_in_period."))
        end
    end
        end

"""
    _get_shift_to_higher(F_to, F_from; method; values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    This helper function returns the number of periods by which the output of a conversion
    must be shifted down in order to account for reference-month effects of the input and output 
    frequencies when these are different from the defaults (12 for Yearly and 3 for Quarterly). 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    For the `values_base` argument see [`fconvert`](@ref)]
"""
function _get_shift_to_higher(F_to::Type{<:YPFrequency{N1}}, F_from::Type{<:YPFrequency{N2}}; values_base=:end, errors=true) where {N1,N2}
    shift_length = 0
    errors && _validate_fconvert_yp(F_to, F_from)
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        """ N1/N2 is ratio between the frequencies, one of  12, 4, or 3
        monthly from yearly: 12/1 = 12
        monthly from quarterly: 12/4 = 3
        quarterly from yearly: 4/1 = 4

        the numerator of the ceil argument is the end month for the frequency
        1-12 for yearly frequencies, 1-3 for quarterly frequencies

        the denominator of the ceil argument the number of months in each period of the input TSeries
        it is either 12 (for conversion from yearly) or 3 (for conversion from quarterly)

        together, these determine whether a shift in the base month of the input translates into
        a shift in the period of the output.

        Example 1:
          Yearly{8} to monthly -> 12/1 - floor(8 / (12/12)) -> 12 - ceil(8/1) = 12 - 8 = 4
          Since the yearly period ends in the eigth month of the year (i.e. August)
          This is fourt months earlier than the baseline assumption (end of period in twelfth month, i.e. December)
          so we need to shift the output to an earlier time by 4 months.

        Example 2:
          Quarterly{1} to monthly -> 12/4 - floor(1 / (12/12)) -> 3 - ceil(1/1) = 3 - 1 = 2
          Since the quarterly period ends in the first month of the quarter (i.e. January, April, July, October)
          This is two months earlier than the baseline assumption (end of period in third month, i.e. March)
          so we need to shift the output to an earlier time by 2 months.

        Example 3:
            Yearly{10} to quarterly ->  4/1 - floor(10 / (12/4))  = 4 - ceil(10/3) = 4 - 3 = 1
            Since October is before the end of 4th quarter, the end period for each data point is one quarter earlier.

        Example 4:
            Yearly{7} to quarterly ->  4/1 - floor(7 / (12/4))  = 4 - ceil(7/3) = 4 - 2 = 2
            Since July is before the end of the third quarter, the last quarter for which we have data at the end is Q2
            This is two quarter earlier than the baseline assumption (data for end of Q4) so we need to shift
            the output to an earlier time by 2 quarters.

        Example 5:
            Yearly{7} to quarterly{1} 
            effective_end_month = 7 + (12 / 4) - 1 = 7 + 3 - 1 = 7 + 2 = 9
            Yearly{7} to quarterly{1} ->  4/1 - floor(9 / (12/4))  = 4 - ceil(9/3) = 4 - 1 = 1
            Since July is the end of a the third quarter in a Quarterly{1} framework
            This is the same as if we were working with a Yearly{9} data and a regular Quarterly{3} target.
            We thus need to shift the results by only one Quarter.
        
        """
        rounder = floor
        if (values_base == :beginning)
            rounder = ceil
        end
        effective_end_month = F_from.parameters[1]
        if hasproperty(F_to, :parameters) && length(F_to.parameters) > 0
            effective_end_month +=  (12/N1) - F_to.parameters[1]
        end
        shift_length = Int(N1/N2 - rounder(effective_end_month / (12 / N1) ))
    end
    return shift_length
end

"""
    _get_shift_to_lower(F_to, F_from; method) where {F_to <: YPFrequency, F_from <: YPFrequency}

    This helper function returns the number of periods by which the input of a conversion
    must be shifted up in order to account for reference-month effects of the input and output 
    frequencies when these are different from the defaults (12 for Yearly and 3 for Quarterly). 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.
"""
function _get_shift_to_lower(F_to::Type{<:YPFrequency{N1}}, F_from::Type{<:YPFrequency{N2}}; errors=true) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, F_from)
    
    shift_length = 0
    if hasproperty(F_to, :parameters) && length(F_to.parameters) > 0
        # in this case we need to shift the index ranges
        shift_length += Int((12/N1) - F_to.parameters[1])
    end
    return shift_length
end

"""
    _to_higher(F_to, MIT{F_from}; values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT to a higher frequency. 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    For the `values_base` argument see [`fconvert`](@ref)]
"""
# yearly to quarterly
function _to_higher(F_to::Type{<:YPFrequency{N1}}, MIT_from::MIT{<:YPFrequency{N2}}; values_base=:end, errors=true, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(MIT_from))
    (np, r) = divrem(N1, N2)
    shift_length = _get_shift_to_higher(F_to, frequencyof(MIT_from); values_base=values_base, errors=false)
    # np = number of periods of the destination frequency for each period of the source frequency
    (y1, p1) = mit2yp(MIT_from)
    fi = MIT{F_to}(y1, (p1 - 1) * np + 1) - shift_length
    return fi
        end

"""
    _to_higher(F_to, UnitRange{MIT{F_from}}; values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT range to a higher frequency. 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    For the `values_base` argument see [`fconvert`](@ref)]
"""
function _to_higher(F_to::Type{<:YPFrequency{N1}}, range::UnitRange{<:MIT{<:YPFrequency{N2}}}; values_base=:end, errors=true, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(first(range)))
    (np, r) = divrem(N1, N2)
    fi = _to_higher(F_to, first(range), values_base=values_base, errors=false)
    li = fi + np*length(range) - 1
    return fi:li
    end
    
"""
    _to_higher(F_to, TSeries{MIT{F_from}}; method=:const, values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a TSeries to a higher frequency. 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    For the `values_base` argument see [`fconvert`](@ref)]
"""
function _to_higher(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:const, values_base=:end, errors=true, args...) where {N1,N2}
    """
    NOTE: current const method assumes we are interested in matching end-of-period values.
    FAME has other approaches (BEGINNING, AVERAGED, SUMMED, ANNUALIZED, FORMULA, HIGH, LOW)
    These are passed in an "observed" argument to the convert function.
    """
    errors && _validate_fconvert_yp(F, frequencyof(t))
    (np, r) = divrem(N1, N2)

    # np = number of periods of the destination frequency for each period of the source frequency
    fi = _to_higher(F, firstindex(t), values_base=values_base, errors=false)

    # lastindex_s = pp(y2, p2*np; N=N1))
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end

"""
    _to_lower(F_to, MIT{F_from}; values_base=:beginning, errors=true, remainder=false) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT to a lower frequency. 

    The optional `round_to` argument determines where to shift the output MIT to in cases where the input MIT is in between periods of the 
    output frequency. The default is :none (provides the output period within which lies provided MIT).
    :next provides the output period following the one in which the provided MIT lands except when the provided MIT is at the start of its current period.
    :previous provides the output period preceeding the one in which the provided MIT lands except when the provided MIT is at the end of its current period.

    Examples:
    _to_lower(Quarterly, 20M2, round_to=:current) = 20Q1
    _to_lower(Quarterly, 20M2, round_to=:next) = 20Q2
    _to_lower(Quarterly, 20M2, round_to=:previous) = 19Q4
    _to_lower(Quarterly, 20M3, round_to=:previous) = 20Q1
    _to_lower(Quarterly, 20M1, round_to=:next) = 20Q1

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    When passed the optional `remainder` argument as `true`, the function returns both the output period, and the remaining number of input periods not covered by the conversion.
    Default is `false`.
"""
function _to_lower(F_to::Type{<:YPFrequency{N1}}, MIT_from::MIT{<:YPFrequency{N2}}; round_to=:current, errors=true, remainder=false, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(MIT_from))
    (np, r) = divrem(N2, N1)
    shift_length = _get_shift_to_lower(F_to, frequencyof(MIT_from), errors=false)
    (y1, p1) = mit2yp(MIT_from + shift_length)
    (d1, r1) = divrem(p1 - 1, np)
    mit = nothing
    if round_to == :next
        mit = MIT{F_to}(y1, d1 + 1) + (r1 > 0)
    elseif round_to == :previous
        mit = MIT{F_to}(y1, d1 + 1) - (r1 < np - 1)
    elseif round_to == :current
        mit = MIT{F_to}(y1, d1 + 1)
    else
        throw(ArgumentError("Unknown round_to: $(round_to). Should be :next or :previous, or :current."))
    end
    if remainder
        return mit, r1
    end
    return mit
        end

"""
    _to_lower(F_to, UnitRange{MIT{F_from}}; errors=true, warning=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT range to a lower frequency. 
"""
function _to_lower(F_to::Type{<:YPFrequency{N1}}, range::UnitRange{<:MIT{<:YPFrequency{N2}}}; errors=true, warnings=true, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(first(range)))
    F_from = frequencyof(range)
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        #quarterly{1} to yearly
        """
        All the specialized YPFrequencies (Yearly{N}, Quarterly{N}) are based on some monthly shift.
        We therefore convert the series to monthly, before recalling fconvert on the output.
        """
        return fconvert(F_to, fconvert(Monthly, range))
    end
    fi, r1 = _to_lower(F_to, first(range); round_to=:next, errors=false, remainder=true)
    li, r2 = _to_lower(F_to, last(range); round_to=:previous, errors=false, remainder=true)
    if (r1 != 0 || r2 != 0) && warnings
        @warn "Range conversionfrom $(range) to $(F_to) has remainders: $r1, $r2."
        end
    return fi:li
        end

"""
    _to_lower(F_to, TSeries{MIT{F_from}}; method=:mean, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a TSeries to a lower frequency. 
"""
function _to_lower(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:mean, errors=true, args...) where {N1,N2}
    F_from = frequencyof(t)
    errors && _validate_fconvert_yp(F, F_from)
    (np, r) = divrem(N2, N1)
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        #quarterly{1} to yearly
        """
        All the specialized YPFrequencies (Yearly{N}, Quarterly{N}) are based on some monthly shift.
        We therefore convert the series to monthly, before recalling fconvert on the output.
        """
        return fconvert(F, fconvert(Monthly, t), method=method)
    end
    fi, r1 = _to_lower(F, t.firstdate; round_to=:next, errors=false, remainder=true)
    li, r2 = _to_lower(F, last(rangeof(t)); round_to=:previous, errors=false, remainder=true)
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


"""
    fconvert(F_to::Type{<:Union{<:YPFrequency, Weekly}}, MIT_from::MIT{<:CalendarFrequency}; round_to=:current)

Converts the provided CalendarFrequency to a YP or Weekly frequency.

The optional `round_to` argument determines where to shift the output MIT to in cases where the input MIT is in between periods of the output frequency. 
The default is :current (provides the output period within which lies provided MIT).
:next provides the output period following the one in which the provided MIT lands except when the provided MIT is at the start of its current period.
:previous provides the output period preceeding the one in which the provided MIT lands except when the provided MIT is at the end of its current period.
"""
function fconvert(F_to::Type{<:Union{<:YPFrequency, <:Weekly}}, MIT_from::MIT{<:CalendarFrequency}; round_to=:current)
    dates = [date(MIT_from)]
    out_index = _get_out_indices(F_to, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    include_weekends = frequencyof(MIT_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(MIT_from), dates, :both, include_weekends=include_weekends)
    if round_to == :next
        return fi+trunc_start
    elseif round_to == :previous
        return fi-trunc_end
    else
        return fi
    end
 end

"""
    fconvert(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly}}, range_from::Union{UnitRange{MIT{Weekly{N3}}},UnitRange{MIT{Weekly}}}; method=:both)

Converts the provided CalendarFrequency UnitRange to a YPFrequency or a Weekly frequency.

the `method` argument in this case refers to which observations of the output frequency must be covered by the input range
:begin means that the first date in each output period must be covered
:end means that the last date in each output period must be covered
:both means that both the first and last date in each output period must be covered.
Note: one can also pass :mean, :sum, which are equivalent to :both
"""
function fconvert(F_to::Type{<:Union{<:YPFrequency, <:Weekly}}, range_from::UnitRange{<:MIT{<:CalendarFrequency}}; method=:both) where {N1,N2,N3}
    dates = [date(val) for val in range_from]
    out_index = _get_out_indices(F_to, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    li = eval(Meta.parse("li = $(out_index[end])"))
    include_weekends = frequencyof(range_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(range_from), dates, method, include_weekends=include_weekends)
    return fi+trunc_start:li-trunc_end
end

"""
    fconvert(F::Type{<:Union{<:YPFrequency, <:Weekly}}, t::TSeries{<:Union{Daily, BusinessDaily}}; method=:mean)

Convert the Daily or BusinessDaily time series `t` to the desired lower frequency `F`.

The range of the result includes periods that are fully included in the range of
the input. For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.
"""
function fconvert(F::Type{<:Union{<:YPFrequency, <:Weekly}}, t::TSeries{<:Union{Daily, BusinessDaily}}; method=:mean)
    dates = [date(val) for val in rangeof(t)]
    out_index = _get_out_indices(F, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    li = eval(Meta.parse("li = $(out_index[end])"))
    include_weekends = frequencyof(t) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F, frequencyof(t), dates, method, include_weekends=include_weekends)

    if method == :mean
        ret = [mean(t.values[out_index .== target]) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(t.values[out_index .== target]) for target in unique(out_index)]
    elseif method == :begin
        ret = [t.values[out_index .== target][begin] for target in unique(out_index)]
    elseif method == :end
        ret = [t.values[out_index .== target][end] for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end


"""
    fconvert(F::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly}}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:mean, interpolation=:none)

Convert the Weekly time series `t` to a lower frequency time series.

The range of the result includes periods that are fully included in the range of
the input. For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks. 
The recorded weekly value is ascribed to the midpoint of the week. I.e. Thursdays for weeks ending on Sundays, Wednesdays
for weeks ending on Saturdays, etc. This is done to be consistent with the handling in FAME.
For days beyond these midpoints, the linear line between the first two or last two weeks is extended to cover the entire day range.
The corresponding daily values are used when selecting or aggregating values for the various methods.
"""
function fconvert(F::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly}}, t::TSeries{<:Weekly}; method=:mean, interpolation=:none) where {N1,N2}
    dates = [date(val) for  val in rangeof(t)]

    # interpolate for weeks spanning divides
    adjusted_values = copy(t.values)
    if interpolation == :linear
        months_rotation = Day(0)
        if @isdefined N1
            months_rotation = Month(3-N1)
        end
        if @isdefined N2
            months_rotation = Month(12-N2)
        end
        overlap = zeros(Int, length(t.values))
        if F <: Monthly
            overlap .= [ Dates.month(date - Day(6)) != Dates.month(date) ? Dates.dayofmonth(date) : 0  for date in dates]
        end
        if F <: Quarterly
            overlap .= [ Dates.quarter(date - Day(6) + months_rotation) != Dates.quarter(date + months_rotation) ? Dates.dayofmonth(date) : 0  for date in dates]
        end
        if F <: Yearly
            overlap .= [ Dates.year(date - Day(6) + months_rotation) != Dates.year(date + months_rotation) ? Dates.dayofmonth(date) : 0  for date in dates]
        end
        for (i, d) in enumerate(overlap) 
            if i > 1 && d != 0
                v1 = copy(adjusted_values[i-1])
                v2 = copy(adjusted_values[i])
               if method == :end #equivalent to technique=linear, observed=end 
                    adjusted_values[i-1] = v1 + (1 - (d/7))*(v2 - v1)
                elseif method == :mean #equivalent to technique=linear, observed=averaged
                    # convert to daily with linear interpolation, then convert to monthly
                    return fconvert(F, fconvert(Daily, t; method=:const, interpolation=:linear), method=:mean)
                elseif method == :sum #equivalent to technique=linear, observed=summed
                    # shift some part of transitionary weeks between months
                    adjusted_values[i-1] = v1 + (1 - (d/7))*v2
                    adjusted_values[i] = v2 - (1 - (d/7))*v2
                elseif method == :begin #equivalent to technique=linear, observed:begin
                    v3 = copy(adjusted_values[min(i+1,length(dates))])
                    # this is equivalent to converting the series to daily with linear interpolation
                    # and selecting the value from the date corresponding to the reference date.
                    adjusted_values[i] = v2 + (1- (d/7))*(v3 - v2)
                end
            end
        end
    end
    
    # get out indices
    out_index = _get_out_indices(F, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    li = eval(Meta.parse("li = $(out_index[end])"))
    trunc_start, trunc_end = _get_fconvert_truncations(F, frequencyof(t), dates, method)

    # do the conversion
    if method == :mean
        ret = [mean(adjusted_values[out_index .== target]) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(adjusted_values[out_index .== target]) for target in unique(out_index)]
    elseif method == :begin
        ret = [adjusted_values[out_index .== target][begin] for target in unique(out_index)]
    elseif method == :end
        ret = [adjusted_values[out_index .== target][end] for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end

"""
    fconvert((F::Type{<:Daily}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:const, interpolation=:none)

Convert the Weekly time series `t` to a daily time series.

The only supported method is currently :const.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks.
The recorded weekly value is ascribed to the midpoint of the week. I.e. Thursdays for weeks ending on Sundays, Wednesdays
for weeks ending on Saturdays, etc. This is done to be consistent with the handling in FAME.
For days beyond these midpoints, the linear line between the first two or last two weeks is extended to cover the entire day range.
"""
function fconvert(F::Type{<:Daily}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:const, interpolation=:none) where{N3}
    np = 7
    reference_day_adjust = 0
    if @isdefined N3
        reference_day_adjust = 7 - N3
    end
    
    fi = MIT{Daily}(Int(firstindex(t))*7 - 6 - reference_day_adjust)
    
    if method == :const
        if interpolation == :linear
            values = repeat(t.values, inner=np)
            adjust = 3
            for i in 1:length(t.values)
                if i == 1
                    interpolated = collect(LinRange(values[i*7-adjust], values[(i+1)*7-adjust],8))
                    values[1:adjust] .= values[7-adjust] .- reverse(collect(1:adjust))*(interpolated[2]-interpolated[1])
                else
                   values[(i-1)*7-adjust:i*7-adjust] = collect(LinRange(values[(i-1)*7-adjust], values[i*7-adjust],8))
                    if i == length(t.values)
                        values[i*7-adjust+1:i*7] = values[i*7-adjust] .+ collect(1:adjust)*(values[i*7-adjust] - values[i*7-adjust-1])
                    end
                end
            end
            return TSeries(fi, values)
        else
            return TSeries(fi, repeat(t.values, inner=np))
        end
        
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end



"""
    _get_fconvert_truncations(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, F_from::Type{<:Union{Weekly{N3}, Weekly, Daily}}, dates::Vector{Dates.Date}, method::Symbol, include_weekends::Bool=false)

This function determines whether the output periods should be truncated when converting from Weekly or Daily to a lower frequency.

    It returns a pair of integers which are 1 if the start or end, respectively, of the output needs to be truncated.
Both ends are truncated when using methods :mean or :sum. IN this case, only output periods entirely covered by the input TSeries dates
will be included in the output. 

When the method is :begin, the start is truncated if the first date in the first output period is not covered by the input TSeries dates.
When the method is :end, the end is truncated if the last date in the last output period is not covered by the input TSeries dates.
"""
function _get_fconvert_truncations(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, F_from::Type{<:Union{Weekly{N4}, Weekly, Daily, BusinessDaily}}, dates::Vector{Dates.Date}, method::Symbol; include_weekends=false) where {N1,N2,N3,N4}
    trunc_start = 0
    trunc_end = 0
    overlap_function = nothing
    if F_to <: Weekly
        overlap_function = Dates.dayofweek
    elseif F_to <: Monthly
        overlap_function = Dates.dayofmonth
    elseif F_to <: Quarterly
        overlap_function = Dates.dayofquarter
    elseif F_to <: Yearly
        overlap_function = Dates.dayofyear
    end
    input_shift = F_from == Weekly ? Day(7) : Day(1)
    target_shift = Day(0)
    if @isdefined N1
        target_shift = N1 != 3 ? Month(N1) : Day(0) 
    end
    if @isdefined N2
        target_shift = N2 != 12 ? Month(N2) : Day(0) 
    end
    if @isdefined N3
        target_shift = N3 != 7 ? Day(N3) : Day(0) 
    end

    ## account for Weekends in conversion from BusinessDaily
    weekend_adjustment_start = Day(0)
    weekend_adjustment_end = Day(0)
    if include_weekends == true
        if dayofweek(dates[begin]) == 1 # First date is a Monday
            if F_to <: Weekly
                # don't do anything
            else
                if Dates.dayofmonth(dates[begin]) <= 3
                    weekend_adjustment_start = Day(Dates.dayofmonth(dates[begin]) - 1)
                end
            end
            # _dates[begin] = _dates[begin] - Day(2)
        end
        if dayofweek(dates[end]) == 5 # last date is a Friday
            if F_to <: Weekly
                # don't do anything
            elseif Dates.dayofmonth(dates[end] + Day(2)) <= 2
                    weekend_adjustment_end = Day(2 - Dates.dayofmonth(dates[end] + Day(2)))
            end
        end
        #TODO: fix for odd weekly frequencies
    end
    # println("weekends $weekend_adjustment_start, $weekend_adjustment_end")

    whole_first_period = overlap_function(dates[begin] - target_shift - input_shift - weekend_adjustment_start) > overlap_function(dates[begin] - target_shift - weekend_adjustment_start)
    whole_last_period = overlap_function(dates[end] - target_shift + Day(1) + weekend_adjustment_end) < overlap_function(dates[end] - target_shift + weekend_adjustment_end)
    if method ∈ (:mean, :sum, :both)
        trunc_start = whole_first_period ? 0 : 1
        trunc_end = whole_last_period ? 0 : 1
    elseif method == :begin
        trunc_start = whole_first_period ? 0 : 1
    elseif method == :end
        trunc_end = whole_last_period ? 0 : 1
    end

    return trunc_start, trunc_end
end

"""
    _get_out_indices(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, dates::Vector{Dates.Date})

Helper function for converting from Daily and Weekly frequencies to lower frequencies. 
Returns an array with the length of the input range, with the values of the corresponding output frequency periods.
"""
function _get_out_indices(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, dates::Vector{Dates.Date}) where {N1,N2,N3}
    months = Dates.month.(dates)
    years = Dates.year.(dates)
    
    if F_to <: Weekly
        reference_day_adjust = 0
        if @isdefined N3
            reference_day_adjust = 7 - N3
        end
        weeks = [Int(floor((Dates.value(d) -1 + reference_day_adjust)/7)) + 1 for d in dates]
        out_index = ["MIT{$F_to}($week)" for week in weeks]
    else
        months = Dates.month.(dates)
        years = Dates.year.(dates)
    end    
        
    if F_to <: Monthly
        out_index = ["$(year)M$(month)" for (year, month) in zip(years, months)]
    elseif F_to <: Quarterly
        if @isdefined N1
            months .+= 3 - N1
            years[months .> 12] .+= 1
            months[months .> 12] .-= 12
        end
        quarters = [Int(floor((m -1)/3) + 1) for m in months]
        out_index = ["$(year)Q$(quarter)" for (year, quarter) in zip(years, quarters)]
    elseif F_to <: Yearly
        if @isdefined N2
            months .+= 12 - N2
            years[months .> 12] .+= 1
        end
        out_index = ["$(year)Y" for year in years]
    end
    return out_index
end


function fconvert(F_to::Type{<:Daily}, MIT_from::MIT{BusinessDaily})
    mod = Int(MIT_from) % 5
    if mod == 0
        mod = 5
    end
    return MIT{F_to}(Int(floor((Int(MIT_from) - 1) / 5)*7 + mod))
end
fconvert(F_to::Type{<:Daily}, range_from::UnitRange{MIT{BusinessDaily}}) = fconvert(F_to, first(range_from)):fconvert(F_to, last(range_from))

"""
    fconvert(F::Type{<:Daily}, t::TSeries{BusinessDaily}; method=:const, interpolation=:none)

Convert a BusinessDaily timeseries to a Daily time series covering the same date range.

By default, weekend values will be filled with NaNs. Use the `interpolation` option to change this behavior:
`:previous`: Fill weekends with the value on the day before the weekend.
`:next`: Fill weekends with the value on the day after the weekend.
`:linear`: Fill weekends with values interpolated between the day before and the day after the weekend.
"""
function fconvert(F_to::Type{<:Daily}, t::TSeries{BusinessDaily}; method=:const, interpolation=:none)
    fi = fconvert(F_to, firstdate(t))
    li = fconvert(F_to, lastdate(t))
    
    out_length = Int(li) - Int(fi) + 1
    if interpolation == :none || any(isnan.(t.values))
        out_values = Array{Number}(undef, (out_length,))
    elseif interpolation == :linear
        out_values = Array{Float64}(undef, (out_length,))
    else
        out_values = Array{eltype(t1.values)}(undef, (out_length,))
    end
    shift = Int(firstdate(t)) % 5
    input_position = 1
    last_valid = NaN
    for k in 1:out_length
        mod = (k + shift - 1) % 7
        if mod < 6 && mod > 0
            out_values[k] = t.values[input_position]
            last_valid = t.values[input_position]
            input_position += 1
        else
            if interpolation == :previous
                out_values[k] = t.values[input_position-1]
            elseif interpolation == :next
                out_values[k] = t.values[input_position]
            elseif interpolation == :linear
                inter = LinRange(t.values[input_position]-1, t.values[input_position], 4)
                if mod == 6
                    out_values[k] = inter[2]
                else
                    out_values[k] = inter[3]
                end
            else
                out_values[k] = NaN
            end
            
        end
    end
    
    return TSeries(fi, out_values)
end
