# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

import Statistics: mean

"""
    fconvert(F_to, t::TSeries)

Convert the time series `t` to the desired frequency `F_to`.
"""
fconvert(F_to::Type{<:Frequency}, t::TSeries; args...) = error("""
Conversion of TSeries from $(frequencyof(t)) to $F_to not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(F_to::Type{F}, t::TSeries{F}) where {F<:Frequency} = t

"""
fconvert(F_to::Type{<:Union{<YPFrequency,<:CalendarFrequency}}, t::TSeries{<:Union{<YPFrequency,<:CalendarFrequency}}; method = :const, values_base = :end)

Convert the time series `t` to the frequency `F_to`.

### Converting to Higher Frequency
The only method available is `method=:const`, where the value at each period of
the higher frequency is the value of the period of the lower frequency it
belongs to.
```
x = TSeries(2000Q1:2000Q3, collect(Float64, 1:3))
fconvert(Monthly, x)
```

### Converting to Lower or similar frequency
There are five methods available: `:point`, `:mean`, `:sum`, `:min`, and `:max`. The default is `:mean`.
Each MIT in the input frequency will be mapped to the output MIT within which the end date of the input MIT
falls. The corresponding values are then grouped for each output MIT and a value is determined based on the method.

* `:point`: the first or last value in each group is chosen based on the values_base argument.
* `:mean`: the values within each group are averaged.
* `:sum`: the values within each group are summed.
* `:min`: the lowest value within each group is chosen.
* `:max`: the highest value within each group is chosen.

The `values_base` determines the behavior of the `:point` method as well as the range of the output tseries when the 
methods is `:point`. When `values_base == :end` then the end of the output range will be truncated whenever 
the last MIT in the input range ends partway through an MIT in the output frequency. When `values_base == :begin` 
then the start of the output range will be truncated whenever the first MIT of the input range starts partway 
through an MIT in the output frequency.

When the method is **not** `:point`, both ends of the output range will be truncated when warranted.

Both method and values_base are ignored when converting from Daily to BDaily.

Note that the approach taken here is not always precise. Because the values in the input trange are grouped by MITs in the 
output frequency, without any further accounting for transitions and relative sizes of input and output frequencies
there may be some loss of accuracy. When more accuracy is desired, it is recommended to first convert the input tseries
to Monthly or Daily frequency, before converting it to the desired output frequency.

### Converting to Higher frequency
There are two methods available: `:const` and `:even`.
Each MIT in the input range is mapped to one or more MITs in the output frequency. The value assigned to these output MITs depends on the method.

* `:const` : the input values is assigned to each corresponding output MIT.
* `:even` : the input value is divided evenly across corresponding output MITs.

The `:linear` method is additionally available when converting a lower frequency to Daily, BDaily, or Monthly.
When method is :linear values are interpolated in a linear fashion across days/business days/months between input 
frequency periods. The specifics depends on values_base. When values_base is `:end` the values will be interpolated 
between the end-dates of adjacent periods. When values_base = `:begin` the values will be interpolated between start-dates 
of adjacent periods. Tail-end periods will have values interpolated based on the progression in the adjacent non-tail-end period.
When values_base = `:middle`, the values are interpolated between mid-points in adjacent MITs in the input period.
When converting to Daily or Business Daily, this mid-point is rounded up, so the input value will fall 
on the 16th of most months when interpolating linearly from monthly to Daily, for example. When converting to Monthly,
the mid-point is not rounded so some output series will not have the input series values present
in any of the output periods. This is the case when converting from HalfYearly to monthly, for example.

`values_base` has no effect when method is `:const` or `:even`.

```
x = TSeries(2000M1:2000M7, collect(Float64, 1:7))
fconvert(Quarterly, x; method = :sum)
fconvert(Daily, x; method = :const)
```
"""
function fconvert(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; kwargs...) where {N1, N2}
    if F_to == Monthly
        return _fconvert_higher_monthly(F_to, t; kwargs...)
    end
    N1 > N2 ? _fconvert_higher(F_to, t; kwargs...) : _fconvert_lower(F_to, t; kwargs...)
end
fconvert(F_to::Type{<:Union{Weekly,Weekly{N}}}, t::TSeries{<:YPFrequency}; method=:const, values_base=:end) where {N} = _fconvert_higher(F_to, t, method=method, values_base=values_base)
fconvert(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly{N},Yearly,Weekly,Weekly{N}}}, t::TSeries{<:CalendarFrequency}; method=:mean, values_base=:end) where {N} = _fconvert_lower(F_to, t, method=method, values_base=values_base)
fconvert(F_to::Type{<:Daily}, t::TSeries{BDaily}; method=:const, values_base=:end) = _fconvert_higher(F_to, t, method=method, values_base=values_base)
fconvert(F_to::Type{<:BDaily}, t::TSeries{Daily}; method=:mean, values_base=:begin) = _fconvert_lower(F_to, t, method=method, values_base=values_base)
fconvert(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; method=:const, values_base=:end) = _fconvert_higher(F_to, t, method=method, values_base=values_base)
function _fconvert_higher(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:const, values_base=:end, errors=true, args...) where {N1,N2}
    (np, r) = divrem(N1, N2)
    
    # trim = method == :point ? values_base : :both
    # fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month = fconvert(F_to, rangeof(t), trim=trim, parts=true)
    
    fi_to_period, fi_from_start_month, fi_to_start_month = fconvert_parts(F_to, t.firstdate, values_base=:begin)
    if values_base == :end
        mpp_to = div( 12, ppy(F_to))        
        fi_to_end_month = fi_to_start_month + mpp_to - 1
        trunc_start = fi_to_end_month < fi_from_start_month ? 1 : 0
    elseif values_base == :begin
        trunc_start = fi_to_start_month < fi_from_start_month ? 1 : 0
    end
    fi = MIT{F_to}(fi_to_period+trunc_start)
    
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    elseif method == :even
        return TSeries(fi, repeat(t.values ./ np, inner=np))
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end

# YP to Monthly (incl. linearization)
function _fconvert_higher_monthly(F_to::Type{<:Monthly}, t::TSeries{<:YPFrequency{N}}; method=:const, values_base=:end) where {N}
    np = Int(12 / N)
    
    trim = method == :point ? values_base : :both
    fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month = fconvert(F_to, rangeof(t), trim=trim, parts=true)
    if values_base == :end
        mpp_to = div( 12, ppy(F_to))        
        fi_to_end_month = fi_to_start_month + mpp_to - 1
        trunc_start = fi_to_end_month < fi_from_start_month ? 1 : 0
    elseif values_base == :begin
        trunc_start = fi_to_start_month < fi_from_start_month ? 1 : 0
    end
    fi = MIT{F_to}(fi_to_period)
    ts = TSeries(fi:fi+np*length(t) - 1)
    
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    elseif method == :even
        return TSeries(fi, repeat(t.values ./ np, inner=np))
    elseif method == :linear
        # interpolate across months between input series values
        for m in reverse(rangeof(t))
            if values_base != :middle
                fi_loop = fconvert(Monthly, m) - (np - 1)
                li_loop = fconvert(Monthly, m)
                n_months = length(fi_loop:li_loop)
                start_val, end_val = _get_interpolation_values(t, m; values_base=values_base)
                interpolated = collect(LinRange(start_val, end_val, n_months + 1))
                if values_base == :end
                    ts[fi_loop:li_loop] = interpolated[2:end]
                elseif values_base == :begin
                    ts[fi_loop:li_loop] = interpolated[1:end-1]
                end
            elseif values_base == :middle
                even = (np/2) % 1 == 0 ? 1 : 0
                start_val, end_val = _get_interpolation_values(t, m; values_base=values_base)
                
                if m == last(rangeof(t))
                    li_loop = fconvert(Monthly, m)
                    fi_loop = li_loop - floor(Int, np/2) + even
                else
                    li_loop = fconvert(Monthly, m) + ceil(Int, np/2)
                    fi_loop = li_loop - np + even
                end
                
                n_months = length(fi_loop:li_loop)
                if even == 1
                    #     ts[fi_loop:li_loop] = interpolated[2:end-1]
                    interpolated = collect(LinRange(start_val, end_val, (n_months+1)*2 - 1))[2:2:end]
                    ts[fi_loop:li_loop] = interpolated[1:n_months]
                else
                    interpolated = collect(LinRange(start_val, end_val, n_months+2*even))
                    ts[fi_loop:li_loop] = interpolated[1+even:end-even]
                end
                
                if m == first(rangeof(t))
                    fi_loop = fi
                    li_loop = fi + floor(Int, np/2)
                    n_months = length(fi_loop:li_loop)
                    diffs = interpolated[1:n_months] .- interpolated[1]
                    ts[fi_loop:li_loop] =  interpolated[1] .- reverse(diffs)
                elseif m == last(rangeof(t)) - 1
                    fi_loop = fconvert(Monthly,m) + ceil(Int, np/2) + even
                    li_loop = last(rangeof(ts))
                    n_months = length(fi_loop:li_loop)
                    diffs =   interpolated[end-n_months+1-even:end-even] .- interpolated[end]
                    ts[fi_loop:li_loop] =  interpolated[end] .- reverse(diffs)
                end 
            end
        end
        return ts
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end

# YP + Weekly to Weekly
function _fconvert_higher(F_to::Type{<:Union{Weekly,Weekly{N}}}, t::TSeries{<:Union{<:YPFrequency}}; method=:const, values_base=:end) where {N}
    dates = [Dates.Date(val) for val in rangeof(t)]
    first_date = Dates.Date(t.firstdate, :begin)
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rangeof(t), trim=values_base)
    # @show fi, li, trunc_start, trunc_end
    # @show fi, li, trunc_start, trunc_end
    # The out_indices command provides the week within which falls each of the provided dates.
    # we need to know how many weeks fall within each input period.
    # so for values_base = :end we need to know when a week ends in the following output period
    # this happens whenever the first day in the next period falls within that week.
    if values_base == :end
        # we want the first day of the following months, but we also don't want to spill over the end of the series
        dates[1:end-1] = dates[1:end-1] .+ Day(1) 
        N_effective = @isdefined(N) ? N : 7
        if dayofweek(dates[end]) == N_effective
            dates[end] += Day(1)
        end
        insert!(dates, 1, first_date) # also get the first week
    elseif values_base == :begin
        # for values_base == :begin the week of the last day of the month will always be followed by a transition
        # however, we want to make sure that the number of weeks with the first value is based off of 
        insert!(dates, 1, first_date - Day(7))
    end
    out_indices = _get_out_indices(F_to, dates)
    output_periods_per_input_period = Int.(out_indices[2:end] .-  out_indices[1:end-1])

    if method == :const 
        ret =  repeat_uneven(t.values, output_periods_per_input_period)
    elseif method == :even 
        ret =  divide_uneven(t.values, output_periods_per_input_period)
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end])
end

# BDaily to Daily (including linearization)
function _fconvert_higher(F_to::Type{<:Daily}, t::TSeries{BDaily}; method=:const, values_base=:end)
    fi = fconvert(F_to, firstdate(t))
    li = fconvert(F_to, lastdate(t))

    out_length = Int(li) - Int(fi) + 1
    ts = TSeries(fi:li, repeat([NaN], out_length))

    dates = Dates.Date.(collect(rangeof(t)))
    daysofweeks = Dates.dayofweek.(dates)
    out_dates = daily.(dates)
    ts[out_dates] .= t.values

    if method == :even
        return ts
    elseif method == :const 
        if values_base == :end
            monday_indices = out_dates[daysofweeks .== 1]
            # @show monday_indices
            # remove early mondays
            if monday_indices[1] == fi
                monday_indices = monday_indices[2:end]
            end
            ts[monday_indices .- 2] = ts[monday_indices]
            ts[monday_indices .- 1]= ts[monday_indices]
        elseif values_base == :begin
            friday_indices = out_dates[daysofweeks .== 5]
            # remove friday at end
            if friday_indices[end] == li
                friday_indices = friday_indices[1:end-1]
            end
            ts[friday_indices .+ 1] = ts[friday_indices]
            ts[friday_indices .+ 2] = ts[friday_indices]
        end
    elseif method == :linear
        monday_indices = out_dates[daysofweeks .== 1]
        friday_indices = out_dates[daysofweeks .== 5]
         # remove early mondays
         if monday_indices[1] == fi
            monday_indices = monday_indices[2:end]
        end
        # remove friday at end
        if friday_indices[end] == li
            friday_indices = friday_indices[1:end-1]
        end
        @assert(length(monday_indices) == length(friday_indices))
        if values_base ∈ (:begin, :end, :middle) # all are treated the same
            differences = ts[monday_indices] .- ts[friday_indices]
            ts[friday_indices .+ 1] = ts[friday_indices] + 1/3*differences
            ts[friday_indices .+ 2] = ts[friday_indices] + 2/3*differences
        end
    end

    return ts
end

# YP + Weekly to Daily + BDaily (incl. linearization)
"""Middle of the month will generally fall on the 16th"""
function _fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; method=:const, values_base=:end)
    date_function = F_to == BDaily ? bdaily : daily
    fi = date_function(Dates.Date(t.firstdate, :begin), bias_previous=false)
    li = date_function(Dates.Date(rangeof(t)[end]))
    ts = TSeries(fi:li)
    if values_base ∉ (:end, :begin, :middle)
        throw(ArgumentError("values_base argument must be :begin or :end. Received: $(values_base)."))
    end
    if method == :const
        for m in rangeof(t)
            fi_loop = date_function(Dates.Date(m, :begin), bias_previous=false)
            li_loop = date_function(Dates.Date(m))
            # ts[fi_loop:li_loop] = repeat([t[m]], inner=length(fi_loop:li_loop))
            ts[fi_loop:li_loop] .= t[m]
        end
        return ts
    elseif method == :even
        for m in rangeof(t)
            fi_loop = date_function(Dates.Date(m, :begin), bias_previous=false)
            li_loop = date_function(Dates.Date(m))
            rng_loop = fi_loop:li_loop
            rng_loop_length = length(rng_loop)
            ts[rng_loop] .= t[m] / rng_loop_length
            # ts[fi_loop:li_loop] .= t[m] / (Int(li_loop) - Int(fi_loop))
        end
        return ts
    elseif method == :linear
        for m in reverse(rangeof(t))
            if values_base != :middle
                fi_loop = date_function(Dates.Date(m, :begin), bias_previous=false)
                li_loop = date_function(Dates.Date(m))
                n_days = length(fi_loop:li_loop)
                start_val, end_val = _get_interpolation_values(t, m; values_base=values_base)
                interpolated = collect(LinRange(start_val, end_val, n_days + 1))
                if values_base == :end
                    ts[fi_loop:li_loop] = interpolated[2:end]
                elseif values_base == :begin
                    ts[fi_loop:li_loop] = interpolated[1:end-1]
                end
            elseif values_base == :middle
                start_val, end_val = _get_interpolation_values(t, m; values_base=values_base)
                # @show start_val, end_val
                if m == last(rangeof(t))
                    fi_loop = date_function(_date_plus_half(m, :begin), bias_previous=false)
                    li_loop = date_function(Dates.Date(m))
                else
                    fi_loop = date_function(_date_plus_half(m, :begin), bias_previous=false)
                    li_loop = date_function(_date_plus_half(m+1, :begin))
                end
                n_days = length(fi_loop:li_loop)
                """
                Mid-january: January 16th
                Mid-february February 14.5th
                Mid-March: March 16th
                Mid April: April 15.5th
                Mid May: May 16th

                January to february:
                    inclusive: 29.5 days
                February to March

                """
                interpolated = collect(LinRange(start_val, end_val, n_days))
                ts[fi_loop:li_loop] = interpolated[1:end]
                # additional fix for start
                if m == first(rangeof(t))
                    fi_loop = date_function(Dates.Date(m, :begin), bias_previous=false)
                    li_loop = date_function(_date_plus_half(m, :begin)) 
                    n_days = length(fi_loop:li_loop)
                    diffs = interpolated[1:n_days] .- interpolated[1]
                    ts[fi_loop:li_loop] =  interpolated[1] .- reverse(diffs)
                elseif m == last(rangeof(t)) - 1
                    fi_loop = date_function(_date_plus_half(m+1, :begin), bias_previous=false)
                    li_loop = date_function(Dates.Date(m+1))
                    n_days = length(fi_loop:li_loop)
                    diffs =   interpolated[end-n_days+1:end] .- interpolated[end]
                    ts[fi_loop:li_loop] =  interpolated[end] .- reverse(diffs)
                end 
            end
        end
        return ts
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end

"""
_to_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = :mean, errors = true, args...) where {N1,N2}
    Convert a TSeries to a lower frequency. 
"""
# YP to YP
function _fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:mean, values_base=:end, errors=true) where {N1,N2}
    
    F_from = frequencyof(t)
    mpp_from = div( 12, ppy(F_from))
    mpp_to = div( 12, ppy(F_to))
    (np, r) = divrem(N2, N1)
   
    trim = method == :point ? values_base : :both
    fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month = fconvert(F_to, rangeof(t), trim=trim, parts=true)
    trunc_start = trim !== :end && fi_to_start_month < fi_from_start_month ? 1 : 0
    trunc_end = trim !== :begin && li_to_end_month > li_from_end_month ? 1 : 0
    fi = MIT{F_to}(fi_to_period+trunc_start)
    li = MIT{F_to}(li_to_period-trunc_end)
    out_range = fi:li
    
    fi_truncation_adjustment = trunc_start == 1 ? mpp_to : 0
    if method == :point
        # for the point method we just need to specify the indices in the input
        # which correspond to the MITs in the output. These will all be np apart.
        if values_base == :end
            fi_from_end_month = fi_from_start_month + mpp_from -1
            fi_to_end_month = fi_to_start_month + mpp_to -1
            months_of_missalignment = fi_to_end_month + fi_truncation_adjustment - fi_from_end_month
        elseif values_base == :begin
            months_of_missalignment = fi_to_start_month + fi_truncation_adjustment - fi_from_start_month    
        end
        periods_of_missalignment = floor(Int, months_of_missalignment / mpp_from)
        
        indices = filter(x-> x > 0, 1+periods_of_missalignment:np:length(t.values))[1:length(out_range)]
        
        ret = t.values[indices]
    else # mean/sum/min/max
        months_of_missalignment = fi_to_start_month + fi_truncation_adjustment - fi_from_start_month    
        periods_of_missalignment = floor(Int, months_of_missalignment / mpp_from)
        start_index = 1 + periods_of_missalignment
        end_index = start_index + np*length(out_range) - 1
        if start_index < 1
            # same as while start_index < 1 : start_index += np
            (d,r) = divrem(start_index, np)
            d = r !== 0 ? d + 1 : d
            start_index += d * np
        end
        if end_index > length(t.values)
            # same as while end_index > length(t.values) : end_index -= np
            (d, r) = divrem(end_index - length(t.values), np)
            d = r !== 0 ? d + 1 : d
            end_index -= d * np
        end
        vals = t.values[start_index:end_index]
        if method == :mean
            ret = mean(reshape(vals, np, :); dims=1)
        elseif method == :sum
            ret = sum(reshape(vals, np, :); dims=1)
        elseif method == :max
            ret = maximum(reshape(vals, np, :); dims=1)
        elseif method == :min
            ret = minimum(reshape(vals, np, :); dims=1)
        else
            throw(ArgumentError("Conversion method not available: $(method)."))
        end
    end
    return copyto!(TSeries(eltype(ret), out_range), ret[1:length(out_range)])
end

# Calendar to YP + Weekly
function _fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:CalendarFrequency}; method=:mean, values_base=:end) where {N}
    
    F_from = frequencyof(t)
    skip_nans = false
    rng_from = rangeof(t)
    
    if F_from == BDaily
        dates = [Dates.Date(val) for val in rng_from]
        if get_option(:bdaily_skip_holidays)
            holidays_map = get_option(:bdaily_holidays_map)
            dates = dates[holidays_map[rng_from].values]
        end
        skip_nans = get_option(:bdaily_skip_nans)
    elseif F_from == Daily
        dates = collect(Dates.Date(first(rng_from)):Day(1):Dates.Date(last(rng_from)))
    else
        dates = [Dates.Date(val) for val in rng_from]
    end

    trim = method == :point ? values_base : :both
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rng_from, trim=trim)
    out_index = _get_out_indices(F_to, dates)
    
    # do the conversion
    if method == :mean
        ret = [mean(skip_if_warranted(values(t)[out_index.==target], skip_nans)) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(skip_if_warranted(values(t)[out_index.==target], skip_nans)) for target in unique(out_index)]
    elseif method == :point && values_base == :begin
        ret = [skip_if_warranted(values(t)[out_index.==target], skip_nans)[begin] for target in unique(out_index)]
    elseif method == :point && values_base == :end
        ret = [skip_if_warranted(values(t)[out_index.==target], skip_nans)[end] for target in unique(out_index)]
    elseif method == :min 
        ret = [minimum(skip_if_warranted(values(t)[out_index.==target], skip_nans)) for target in unique(out_index)]
    elseif method == :max 
        ret = [maximum(skip_if_warranted(values(t)[out_index.==target], skip_nans)) for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end

# Daily to BDaily (method means nothing)
function _fconvert_lower(F_to::Type{<:BDaily}, t::TSeries{Daily}; method=:mean, values_base=:end)
    # options have no effect here
    fi = fconvert(F_to, firstdate(t))

    out_map_week = repeat([true], 7)
    first_day = dayofweek(Dates.Date(firstdate(t)))
    saturday = first_day == 7 ? 7 : 7 - first_day
    sunday = first_day == 7 ? 1 : saturday + 1
    out_map_week[[saturday, sunday]] .= false
    out_map = repeat(out_map_week, ceil(Int, length(t) / 7))[1:length(t)]

    return TSeries(fi, t.values[out_map])
end
