# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

#### strip and strip!

# no docstring needed
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

#### BusinessDaily helpers

"""
skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing} = nothing)

    Skips nans in a vector if either the provided nans option is true or if no nans option is
    passed and the :business_skip_nans option is true.

    Returns the original vector otherwise.
"""
function skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing}=nothing)
    if nans == true || (nans === nothing && get_option(:business_skip_nans))
        ret = filter(y -> !isnan(y), x)
        if size(ret)[1] == 0
            return [NaN]
        end
        return ret
    end
    return x
end

### Linerar interpolation helper

function _get_interpolation_values(t::TSeries{F}, m::MIT{F}; values_base::Symbol=:end) where {F}
    start_val = nothing
    end_val = nothing
    if length(t) == 1
        start_val = t[m]
        end_val = t[m]
    elseif (m == t.firstdate)
        if values_base == :end
            start_val = t[m] - (t[m+1] - t[m])
            end_val = t[m]
        elseif values_base == :begin
            start_val = t[m]
            end_val = t[m+1]
        end
    else
        if values_base == :end
            end_val = t[m]
            start_val = t[m-1]
        elseif values_base == :begin && m !== rangeof(t)[end]
            start_val = t[m]
            end_val = t[m+1]
        elseif values_base == :begin
            start_val = t[m]
            end_val = t[m] + (t[m] - t[m-1])
        end
    end
    return (start_val, end_val)
end

### MIT range conversion

"""
    _get_fconvert_truncations(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, F_from::Type{<:Union{Weekly{N3}, Weekly, Daily}}, dates::Vector{Dates.Date}, method::Symbol, include_weekends::Bool=false)

This function determines whether the output periods should be truncated when converting from Weekly or Daily to a lower frequency.

It returns a pair of integers which are 1 if the start or end, respectively, of the output needs to be truncated.
Both ends are truncated when using methods :mean or :sum. IN this case, only output periods entirely covered by the input TSeries dates
will be included in the output. 

When the method is :begin, the start is truncated if the first date in the first output period is not covered by the input TSeries dates.
When the method is :end, the end is truncated if the last date in the last output period is not covered by the input TSeries dates.
"""
function _get_fconvert_truncations(F_to::Type{<:Union{Weekly{N1},Weekly,Monthly,Quarterly{N2},Quarterly,Yearly{N3},Yearly}}, F_from::Type{<:Union{Weekly{N4},Weekly,Daily,BusinessDaily,Quarterly,Quarterly{N5},Monthly,Yearly,Yearly{N6}}}, dates::Vector{Dates.Date}, method::Symbol; include_weekends=false, shift_input=true, pad_input=true) where {N1,N2,N3,N4,N5,N6}
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

    # Account for input frequency
    input_shift = Day(0)
    if F_from <: Weekly
        if pad_input
            input_shift -= Day(7) - Day(1)
        end
        if shift_input && @isdefined N4
            input_shift -= Day(7 - N4)
        end
    elseif F_from <: Quarterly
        if pad_input
            input_shift -= Month(3) - Day(1)
        end
        if shift_input && @isdefined N5
            input_shift -= Month(3 - N5)
        end
    elseif F_from <: Monthly
        if (pad_input)
            input_shift -= Month(1) - Day(1)
        end
    elseif F_from <: Yearly
        if pad_input
            input_shift -= Year(1) - Day(1)
        end
        if shift_input && @isdefined N6
            input_shift -= Month(12 - N6)
        end
    end

    # Account for output frequency
    target_shift = Day(0)
    if F_to <: Weekly && @isdefined N1
        target_shift -= Day(7 - N1)
    end
    if F_to <: Quarterly && @isdefined N2
        target_shift -= Month(3 - N2)
    end
    if F_to <: Yearly && @isdefined N3
        target_shift -= Month(12 - N3)
    end

    # Account for weekends when going from BusinessDaily to a lower frequency
    weekend_adjustment_start = Day(0)
    weekend_adjustment_end = Day(0)
    if include_weekends == true
        start_weekday = dayofweek(dates[begin])
        end_weekday = dayofweek(dates[end])
        if start_weekday == 1 # First date is a Monday
            if F_to == Weekly
                # don't do anything
            elseif !(F_to <: Weekly) && Dates.dayofmonth(dates[begin]) <= 3
                weekend_adjustment_start = Day(Dates.dayofmonth(dates[begin]) - 1)
            end
            # _dates[begin] = _dates[begin] - Day(2)
        end
        if end_weekday == 5 # last date is a Friday
            if F_to == Weekly
                weekend_adjustment_end = Day(2)
            elseif !(F_to <: Weekly) && Dates.dayofmonth(dates[end] + Day(2)) <= 2
                weekend_adjustment_end = Day(2 - Dates.dayofmonth(dates[end] + Day(2)))
            end
        end
        # Accounting for odd weekly frequencies
        if F_to <: Weekly && @isdefined N1
            if N1 == 6 && end_weekday == 5
                weekend_adjustment_end = Day(1)
            elseif N1 == 7 && end_weekday == 5
                weekend_adjustment_end = Day(2)
            end
            if N1 == 6 && start_weekday == 1
                weekend_adjustment_start = Day(1)
            elseif N1 == 5 && start_weekday == 1
                weekend_adjustment_start = Day(2)
            end
        end
    end

    # println(dates[begin], ", i: ", input_shift, ", t: ", target_shift, ", w: ", weekend_adjustment_start)
    # println(dates[begin] + input_shift - target_shift - weekend_adjustment_start)
    # println(dates[end], ", i: ", input_shift, ", t: ", target_shift, ", w: ", weekend_adjustment_end)
    # println(dates[end] + input_shift - target_shift + + weekend_adjustment_end + Day(1))
    whole_first_period = overlap_function(dates[begin] + input_shift - target_shift - weekend_adjustment_start) == 1
    whole_last_period = overlap_function(dates[end] + input_shift - target_shift + weekend_adjustment_end + Day(1)) == 1

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
function _get_out_indices(F_to::Type{<:Union{Monthly,Quarterly{N1},Quarterly,Yearly{N2},Yearly,Weekly,Weekly{N3}}}, dates::Vector{Dates.Date}) where {N1,N2,N3}
    months = Dates.month.(dates)
    years = Dates.year.(dates)

    if F_to <: Weekly
        reference_day_adjust = 0
        if @isdefined N3
            reference_day_adjust = 7 - N3
        end
        weeks = [Int(floor((Dates.value(d) - 1 + reference_day_adjust) / 7)) + 1 for d in dates]
        out_index = [MIT{F_to}(week) for week in weeks]
    else
        months = Dates.month.(dates)
        years = Dates.year.(dates)
    end

    if F_to <: Monthly
        out_index = [MIT{F_to}(year, month) for (year, month) in zip(years, months)]
        # out_index = ["MIT{$F_to}(Int((year-1)*12) + month)" for (year, month) in zip(years, months)]
    elseif F_to <: Quarterly
        if @isdefined N1
            months .+= (3 - N1)
            years[months.>12] .+= 1
            months[months.>12] .-= 12
        end
        # println(months)
        # out_index = ["$(year)Q$(quarter)" for (year, quarter) in zip(years, quarters)]
        quarters = [Int(ceil(m / 3)) for m in months]
        # quarters = [Int(floor((m -1)/3) + 1) for m in months]
        # println([Int(year*4) + quarter for (year, quarter) in zip(years, quarters)])
        out_index = [MIT{F_to}(year, quarter) for (year, quarter) in zip(years, quarters)]
    elseif F_to <: Yearly
        if @isdefined N2
            months .+= 12 - N2
            years[months.>12] .+= 1
        end
        # out_index = ["$(year)Y" for year in years]
        out_index = [MIT{F_to}(year) for year in years]
    end
    return out_index
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
        if (values_base == :begin)
            rounder = ceil
        end
        effective_end_month = F_from.parameters[1]
        if hasproperty(F_to, :parameters) && length(F_to.parameters) > 0
            effective_end_month += (12 / N1) - F_to.parameters[1]
        end
        shift_length = Int(N1 / N2 - rounder(effective_end_month / (12 / N1)))
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
        shift_length += Int((12 / N1) - F_to.parameters[1])
    end
    return shift_length
end

#### Conversion checks
# TODO: expand these

_validate_fconvert_yp(F_to::Type{<:Frequency}, F_from::Type{<:Frequency}) = nothing

"""
    _validate_fconvert_yp(F_to, F_from; method) where {F_to <: YPFrequency, F_from <: YPFrequency}

    This helper function throws errors when conversions are attempted between unsupported YPFrequencies
    or from/to a YPFrequency with an unsupported reference month.
"""
function _validate_fconvert_yp(F_to::Type{<:YPFrequency{N1}}, F_from::Type{<:YPFrequency{N2}}) where {N1,N2}
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
