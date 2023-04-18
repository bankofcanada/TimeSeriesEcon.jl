# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

"""
repeat_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer})

Returns a vector of length `length(x) * sum(inner)` where each value in `x`
is repeated a number of times equal to the same-index position in the vector
`inner`.

`> repeat_uneven([1,2,4], [2,1,4])`
[1, 1, 2, 4, 4, 4, 4]
"""
function repeat_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer})
    out = typeof(x)(undef, sum(inner))
    pos = 1
    for i in 1:length(x)
        out[pos:pos+inner[i]-1] .= x[i]
        pos += inner[i]
    end
    return out
end
export(repeat_uneven)

"""
divide_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer})

Returns a vector of length `length(x) * sum(inner)` where each value in `x`
is divided by the the same-index position value in the vector `inner` and the resulting
value is repeated a number of times equal to the inner value.

Example:
`> divide_uneven([1,2,4], [2,1,4])`
[0.5, 0.5, 2.0, 1, 1, 1, 1]
"""
function divide_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer})
    out = typeof(x/1.0)(undef, sum(inner))
    pos = 1
    for i in 1:length(x)
        out[pos:pos+inner[i]-1] .= x[i] / inner[i]
        pos += inner[i]
    end
    return out
end
export(divide_uneven)


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

#### BDaily helpers

"""
skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing} = nothing)

    Skips nans in a vector if either the provided nans option is true or if no nans option is
    passed and the :bdaily_skip_nans option is true.

    Returns the original vector otherwise.
"""
function skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing}=nothing, bypass::Bool=false)
    if !bypass && (nans == true || (nans === nothing && get_option(:bdaily_skip_nans)))
        ret = filter(y -> !isnan(y), x)
        if size(ret)[1] == 0
            return [NaN]
        end
        return ret
    end
    return x
end

### Linear interpolation helper
"""
_get_interpolation_values(t::TSeries{F}, m::MIT{F}; ref::Symbol=:end) where {F}

    # TODO
    This helper function takes a TSeries and a MIT within that TSeries and provides the start and end
    values used for a linear interpolation between the provided MIT and the adjacent MIT, depending
    on the direction of the interpolation. The function simplifies logic related to the handling of 
    the ends of the TSeries as well as interpolating between middle points in the MITs.
"""
function _get_interpolation_values(t::TSeries{F}, m::MIT{F}; ref::Symbol=:end) where {F}
    start_val = nothing
    end_val = nothing
    if length(t) == 1
        start_val = t[m]
        end_val = t[m]
    elseif (m == t.firstdate)
        if ref == :end
            start_val = t[m] - (t[m+1] - t[m])
            end_val = t[m]
        elseif ref == :begin
            start_val = t[m]
            end_val = t[m+1]
        elseif ref == :middle
            start_val = t[m]
            end_val =  t[m+1] 
            # start_val = t[m] - (t[m+1]-t[m]) / 2
            # end_val = t[m+1]
        end
    elseif m == last(rangeof(t))
        if ref == :end
            end_val = t[m]
            start_val = t[m-1]
        elseif ref == :begin
            start_val = t[m]
            end_val = t[m] + (t[m] - t[m-1])
        elseif ref == :middle
            start_val = t[m]
            end_val =  t[m] + (t[m] - t[m-1]) / 2
        end
    else # middle of series
        if ref == :end
            end_val = t[m]
            start_val = t[m-1]
        elseif ref == :begin 
            start_val = t[m]
            end_val = t[m+1]
        elseif ref == :middle
            start_val = t[m]
            end_val =  t[m+1] 
        end
    end
    return (start_val, end_val)
end

"""
    _date_plus_half(m::MIT{F}, ref::Symbol=:end; round=:down) where {F}

    This helper function receives an MIT and returns a date.
    
    When value_base == :end, the date will be halfway into the MIT following the provided MIT.
    When ref == :begin the date will be half way into the provided MIT.
"""
function _date_plus_half(m::MIT{F}, ref::Symbol=:end; round=:down) where {F}
    rounder = round == :up ? ceil : floor
    base_date = Dates.Date(m, ref)
    if F == Monthly
        n_days = Dates.value(base_date + Month(1) - base_date)
    elseif F <: Quarterly
        n_days = Dates.value(base_date + Quarter(1) - base_date)
    elseif F <: HalfYearly
        n_days = Dates.value(base_date + Month(6) - base_date)
    elseif F <: Yearly
        n_days = Dates.value(base_date + Year(1) - base_date)
    elseif F <: Weekly
        n_days = Dates.value(base_date + Week(1) - base_date)
    end
    n_days = rounder(n_days / 2)
    base_date += Day(n_days)
    return base_date
end

function dayofhalfyear(d::Date)
    q = Dates.quarterofyear(d)
    if q == 1 || q == 3
        return Dates.dayofquarter(d)
    elseif q == 2
        first_quarter = Dates.dayofyear(Dates.Date("$(Dates.year(d))-03-31"))
        return first_quarter + Dates.dayofquarter(d)
    elseif q == 4
        first_three_quarters = Dates.dayofyear(Dates.Date("$(Dates.year(d))-08-31"))
        return first_three_quarters + Dates.dayofquarter(d)
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
function _get_fconvert_truncations(F_to::Type{<:Union{Weekly{NtW},Weekly,Monthly,Quarterly{NtQ},Quarterly,HalfYearly,HalfYearly{NtH},Yearly{NtY},Yearly}}, F_from::Type{<:Union{Weekly{NfW},Weekly,Daily,BDaily,Quarterly,Quarterly{NfQ},Monthly,HalfYearly,HalfYearly{NfH},Yearly,Yearly{NfY}}}, dates::Vector{Dates.Date}, method::Symbol; include_weekends=false, shift_input=true, pad_input=true) where {NtW,NtQ,NtY,NfW,NfQ,NfY,NtH,NfH}
    trunc_start = 0
    trunc_end = 0

    overlap_function = nothing
    if F_to <: Weekly
        overlap_function = Dates.dayofweek
    elseif F_to <: Monthly
        overlap_function = Dates.dayofmonth
    elseif F_to <: Quarterly
        overlap_function = Dates.dayofquarter
    elseif F_to <: HalfYearly
        overlap_function = dayofhalfyear
    elseif F_to <: Yearly
        overlap_function = Dates.dayofyear
    end

    # Account for input frequency
    input_shift = Day(0)
    if F_from <: Weekly
        if pad_input
            input_shift -= Day(7) - Day(1)
        end
        if shift_input && @isdefined NfW
            input_shift -= Day(7 - NfW)
        end
    elseif F_from <: Quarterly
        if pad_input
            input_shift -= Month(3) - Day(1)
        end
        if shift_input && @isdefined NfQ
            input_shift -= Month(3 - NfQ)
        end
    elseif F_from <: Monthly
        if (pad_input)
            input_shift -= Month(1) - Day(1)
        end
    elseif F_from <: HalfYearly
        if (pad_input)
            input_shift -= Month(6) - Day(1)
        end
        if shift_input && @isdefined NfH
            input_shift -= Month(6 - NfH)
        end
    elseif F_from <: Yearly
        if pad_input
            input_shift -= Year(1) - Day(1)
        end
        if shift_input && @isdefined NfY
            input_shift -= Month(12 - NfY)
        end
    end

    # Account for output frequency
    target_shift = Day(0)
    if F_to <: Weekly && @isdefined NtW
        target_shift -= Day(7 - NtW)
    end
    if F_to <: Quarterly && @isdefined NtQ
        target_shift -= Month(3 - NtQ)
    end
    if F_to <: HalfYearly && @isdefined NtH
        target_shift -= Month(6 - NtH)
    end
    if F_to <: Yearly && @isdefined NtY
        target_shift -= Month(12 - NtY)
    end

    # Account for weekends when going from BDaily to a lower frequency
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
        if F_to <: Weekly && @isdefined NtW
            if NtW == 6 && end_weekday == 5
                weekend_adjustment_end = Day(1)
            elseif NtW == 7 && end_weekday == 5
                weekend_adjustment_end = Day(2)
            end
            if NtW == 6 && start_weekday == 1
                weekend_adjustment_start = Day(1)
            elseif NtW == 5 && start_weekday == 1
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

Takes an array of dates and returns an array of MITs of the `F_to` frequency corresponding to each date.
"""
_get_out_indices(F_to::Type{<:Union{Quarterly{NtQ},HalfYearly{NtH},Yearly{NtY},Weekly{NtW}}}, dates::Vector{Dates.Date}) where {NtQ,NtH,NtY,NtW} = _get_out_indices_actual(F_to, dates, check_parameter_to=true)
_get_out_indices(F_to::Type{<:Union{Monthly,Quarterly,HalfYearly,Yearly,Weekly}}, dates::Vector{Dates.Date}) = _get_out_indices_actual(F_to, dates, check_parameter_to=false)
function _get_out_indices_actual(F_to::Type{<:Union{Monthly,Quarterly{NtQ},Quarterly,HalfYearly{NtH},HalfYearly,Yearly{NtY},Yearly,Weekly,Weekly{NtW}}}, dates::Vector{Dates.Date}; check_parameter_to=false) where {NtQ,NtH,NtY,NtW}
    months = Dates.month.(dates)
    years = Dates.year.(dates)

    if F_to <: Weekly
        end_day = endperiod(sanitize_frequency(F_to))
        out_index = [weekly(date, end_day) for date in dates]
    else
        months = Dates.month.(dates)
        years = Dates.year.(dates)
    end

    if F_to <: Monthly
        out_index = [MIT{F_to}(year, month) for (year, month) in zip(years, months)]
    elseif F_to <: Quarterly
        if check_parameter_to
            months .+= (3 - NtQ)
            years[months.>12] .+= 1
            months[months.>12] .-= 12
        end
        quarters = [Int(ceil(m / 3)) for m in months]
        out_index = [MIT{F_to}(year, quarter) for (year, quarter) in zip(years, quarters)]
    elseif F_to <: HalfYearly
        if check_parameter_to
            months .+= (6 - NtH)
            years[months.>12] .+= 1
            months[months.>12] .-= 12
        end
        halfyears = [Int(ceil(m / 6)) for m in months]
        out_index = [MIT{F_to}(year, half) for (year, half) in zip(years, halfyears)]
    elseif F_to <: Yearly
        if check_parameter_to
            months .+= 12 - NtY
            years[months.>12] .+= 1
        end
        out_index = [MIT{F_to}(year) for year in years]
    end
    return out_index
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

function get_start_truncation_yp(fi_from_start_month, fi_to_start_month, mpp_from, mpp_to; require=:single, ref=:end)
    if ref == :end
        if require == :single
            # we just need the first data point in the input series to feed 
            # into the first MIT in the output series
            if fi_from_start_month + (mpp_from - 1) <= fi_to_start_month + (mpp_to - 1) 
                return 0 # don't trim
            else
                return 1 #trim
            end
        elseif require == :all
            # we need the first data point in the input series to either
            # a) start at the same month as the output MIT
            # b) have it's first month outside of the first output MIT and last month 
            # inside
            if fi_from_start_month == fi_to_start_month
                return 0 # don't trim
            elseif fi_from_start_month < fi_to_start_month && fi_from_start_month + (mpp_from - 1) >= fi_to_start_month
                return 0 # don't trim
            else
                return 1 # trim
            end
        end
    end
    if ref == :begin
        if require == :single
            # we need the first data point in the input series to either
            # a) start at the same month as the output MIT
            # b) have it's first month outside of the first output MIT and last month 
            # inside
            if fi_from_start_month == fi_to_start_month
                return 0 # don't trim
            elseif fi_from_start_month < fi_to_start_month && fi_from_start_month + (mpp_from - 1) >= fi_to_start_month
                return 0 # don't trim
            else
                return 1 #trim
            end
        elseif require == :all
            # we need the first data point in the input series to either 
            # a) start at the same month as th eoutput MIT
            # b) start within the output MIT but not a full input period from the start
            if fi_from_start_month == fi_to_start_month
                return 0 # don't trim
            elseif fi_from_start_month > fi_to_start_month && fi_from_start_month - (mpp_from - 1) <= fi_to_start_month
                return 0 # don't trim
            else
                return 1 # trim
            end
        end
    end
end

function get_end_truncation_yp(li_from_end_month, li_to_end_month, mpp_from, mpp_to; require=:single, ref=:end)
    if ref == :end
        if require == :single
            # todo: maybe rewrite this
            # we need the last data point to either
            # a) land on the last month of the output range
            # b) land before the last month, but not an entire period before
            if li_from_end_month == li_to_end_month
                return 0 # don't trim
            elseif li_from_end_month < li_to_end_month && li_from_end_month + (mpp_from-1) >= li_to_end_month
                return 0 # don't trim
            else
                return 1 # trim
            end
        elseif require == :all
            # we need the last data point to either
            # a) land on the last month of the output range
            # b) land before the last month, but not an entire period before
            if li_from_end_month == li_to_end_month
                return 0 # don't trim
            elseif li_from_end_month < li_to_end_month && li_from_end_month + (mpp_from-1) >= li_to_end_month
                return 0 # don't trim
            else
                return 1 # trim
            end
        end
    end
    if ref == :begin
        if require == :single
           # we need the last data point to either
           # a) land after the first month of the output period
           # b) land before the first month but not an entire period before
           if li_from_end_month - (mpp_from - 1) >= li_to_end_month - (mpp_to - 1)
                return 0 # don't trim
           elseif li_from_end_month - (mpp_from - 1) < li_to_end_month - (mpp_to - 1) && li_from_end_month  >= li_to_end_month - (mpp_to - 1) 
                return 0 # don't trim
           else
                return 1 # trim
           end
        elseif require == :all
           # we need the last input period to start on or before the end of the last output period
           if li_from_end_month > li_to_end_month && li_from_end_month - (mpp_from - 1) <= li_to_end_month
                return 0 # don't trim
           else
                return 1 # trim
           end
        end
    end
end

