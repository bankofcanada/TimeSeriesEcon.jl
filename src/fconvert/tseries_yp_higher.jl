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
    args[:values_base] = values_base
    N1 > N2 ? _to_higher(F_to, t; args...) : _to_lower(F_to, t; args...)
end

"""
    _validate_fconvert_yp(F_to, F_from; method) where {F_to <: YPFrequency, F_from <: YPFrequency}

    This helper function throws errors when conversions are attempted between unsopported YPFrequencies
    or from/to a YPFrequency with an unsupported reference month.
"""
function _validate_fconvert_yp(F_to::Type{<:YPFrequency{N1}}, F_from::Type{<:YPFrequency{N2}})  where {N1,N2}
    if N1 == N2
        throw(error("Conversion from $F_from to $F_to not implemented."))
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