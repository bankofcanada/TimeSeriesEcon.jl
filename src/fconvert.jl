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
# monthly to quarterly
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

