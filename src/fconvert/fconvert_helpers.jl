"""Needs docstring"""
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
    skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,nothing}=nothing)  

    Skips nans in a vector if either the provided nans option is true or if no nans option is
    passed and the :business_skip_nans option is true.

    Returns the original vector otherwise.
"""
function skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing}=nothing)  
    if nans == true || (nans === nothing && get_option(:business_skip_nans))
        ret = filter(y -> !isnan(y), x);
        if size(ret)[1] == 0
            return [NaN]
        end
        return ret
    end
    return x
end



function _get_interpolation_values(t::TSeries{F}, m::MIT{F}, values_base::Symbol) where F
    start_val = nothing
    end_val = nothing
    if length(t) == 1
        start_val = t[m]
        end_val = t[m]
    elseif (m == t.firstdate)
        if values_base == :end
            start_val = t[m] - (t[m+1] - t[m])
            end_val = t[m]
        elseif values_base == :beginning
            start_val = t[m]
            end_val = t[m+1]
        end 
    else
       if values_base == :end
            end_val =  t[m]
            start_val = t[m-1]
        elseif values_base == :beginning && m !== rangeof(t)[end]
            start_val = t[m]
            end_val = t[m+1]
        elseif values_base == :beginning
            start_val = t[m]
            end_val = t[m] + (t[m] - t[m-1])
        end 
    end
    return (start_val, end_val)
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
function _get_fconvert_truncations(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, F_from::Type{<:Union{Weekly{N4}, Weekly, Daily, BusinessDaily, Quarterly, Quarterly{N5}, Monthly, Yearly, Yearly{N6}}}, dates::Vector{Dates.Date}, method::Symbol; include_weekends=false) where {N1,N2,N3,N4, N5, N6}
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
    input_shift = Day(1)
    if F_from == Weekly
        input_shift = Day(7)
    elseif F_from <: Quarterly
        input_shift = Quarter(1)
        if @isdefined N5
            input_shift = N5 != 3 ? input_shift + Month(N5) : input_shift
        end
    elseif F_from <: Monthly
        input_shift = Month(1)
    elseif F_from <: Yearly
        input_shift = Year(1)
        if @isdefined N6
            input_shift = N6 != 12 ? input_shift + Month(N6) : input_shift
        end
    end
    # input_shift = F_from == Weekly ? Day(7) : Day(1)
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
        # out_index = ["MIT{$F_to}(Int((year-1)*12) + month)" for (year, month) in zip(years, months)]
    elseif F_to <: Quarterly
        if @isdefined N1
            months .+= (3 - N1)
            years[months .> 12] .+= 1
            months[months .> 12] .-= 12
        end
        # println(months)
        # out_index = ["$(year)Q$(quarter)" for (year, quarter) in zip(years, quarters)]
        quarters = [Int(ceil(m/3) - 1) for m in months]
        # quarters = [Int(floor((m -1)/3) + 1) for m in months]
        # println([Int(year*4) + quarter for (year, quarter) in zip(years, quarters)])
        out_index = ["MIT{$F_to}(Int($year*4) + $quarter)" for (year, quarter) in zip(years, quarters)]
    elseif F_to <: Yearly
        if @isdefined N2
            months .+= 12 - N2
            years[months .> 12] .+= 1
        end
        # out_index = ["$(year)Y" for year in years]
        out_index = ["MIT{$F_to}($year)" for year in years]
    end
    return out_index
end