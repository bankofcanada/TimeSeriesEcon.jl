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
fconvert(F_to::Type{<:Union{<YPFrequency,<:CalendarFrequency}}, t::TSeries{<:Union{<YPFrequency,<:CalendarFrequency}}; method = :const, ref = :end)

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
Each MIT in the input frequency will be mapped to the output MIT within which the start/end date of the input MIT
falls - depending on the whether ref is `:begin` or `:end`. The corresponding values are then grouped for each 
output MIT and a value is determined based on the method.

* `:mean`: the values within each group are averaged.
* `:sum`: the values within each group are summed.
* `:min`: the lowest value within each group is chosen.
* `:max`: the highest value within each group is chosen.
* `:point`: see below.

Output ranges are truncated such that each output MIT contains a full complement of input values. For example, when `ref` is
`:end`, an output MIT will be included if all MITs in the input frequency with end dates covered by the output frequency have values.
Similarly, when `ref` is `:begin` an output MIT will be included if all input MITs with start dates covered by the output MIT
have values.

The approach is different when method is `:point`. The output MIT will contain the value from the input MIT whose first/last
day falls *on or before* the first/last day of the output MIT, depending on the `ref` argument. Truncation is more generous 
than with the other methods. When `ref` is `:begin` an output MIT will be included whenever an input MIT with a value
overlaps the start_day of the output MIT. WHen `ref` is `:end` an output MIT will be included whenever there is a value
from the input MIT whose end date is either on the last day of the output MIT, or whose end date is the closest to, but not after the 
last day of the output MIT.

Both method and ref are ignored when converting from Daily to BDaily.

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
frequency periods. The specifics depends on ref. When ref is `:end` the values will be interpolated 
between the end-dates of adjacent periods. When ref = `:begin` the values will be interpolated between start-dates 
of adjacent periods. Tail-end periods will have values interpolated based on the progression in the adjacent non-tail-end period.


```
x = TSeries(2000M1:2000M7, collect(Float64, 1:7))
fconvert(Quarterly, x; method = :sum)
fconvert(Daily, x; method = :const)
```
"""
fconvert(F_to::Type{Weekly}, t::TSeries; kwargs...) = fconvert(Weekly{7}, t; kwargs...)
fconvert(F_to::Type{Quarterly}, t::TSeries{<:Union{Daily,BDaily,<:Weekly}}; kwargs...) = fconvert(Quarterly{3}, t; kwargs...)
fconvert(F_to::Type{HalfYearly}, t::TSeries{<:Union{Daily,BDaily,<:Weekly}}; kwargs...) = fconvert(HalfYearly{6}, t; kwargs...)
fconvert(F_to::Type{Yearly}, t::TSeries{<:Union{Daily,BDaily,<:Weekly}}; kwargs...) = fconvert(Yearly{12}, t; kwargs...)
function fconvert(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; kwargs...) where {N1, N2}
    if F_to == Monthly
        return _fconvert_higher_monthly(F_to, t; kwargs...)
    end
    N1 > N2 ? _fconvert_higher(sanitize_frequency(F_to), t; kwargs...) : _fconvert_lower(F_to, t; kwargs...)
end

fconvert(F_to::Type{<:Weekly{end_day}}, t::TSeries{<:YPFrequency}; method=:const, ref=:end) where {end_day} = _fconvert_higher(F_to, t; method=method, ref=ref)
fconvert(F_to::Type{<:Union{Yearly{N},HalfYearly{N},Quarterly{N},Monthly,Weekly{N}}}, t::TSeries{<:Union{Daily, BDaily, <:Weekly}}; method=:mean, ref=:end, kwargs...) where {N} = _fconvert_lower(F_to, t; method=method, ref=ref, kwargs...)
fconvert(F_to::Type{<:Daily}, t::TSeries{BDaily}; method=:const, ref=:end) = _fconvert_higher(F_to, t; method=method, ref=ref)
fconvert(F_to::Type{<:BDaily}, t::TSeries{Daily}; method=:mean, ref=:begin) = _fconvert_lower(F_to, t; method=method, ref=ref)
fconvert(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; method=:const, ref=:end) = _fconvert_higher(F_to, t; method=method, ref=ref)
function _fconvert_higher(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:const, ref=:end, errors=true, args...) where {N1,N2}
    (np, r) = divrem(N1, N2)
    
    fi = _fconvert_higher_get_fi(F_to, t.firstdate, Val(ref))
    
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    elseif method == :even
        return TSeries(fi, repeat(t.values ./ np, inner=np))
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end
function _fconvert_higher_get_fi(F_to::Type{<:YPFrequency{N1}}, first_mit::MIT{<:YPFrequency{N2}}, ref::Val{:end}) where {N1,N2}
    fi_to_period, fi_from_start_month, fi_to_start_month = fconvert_parts(F_to, first_mit, ref=:begin)
    mpp_to = div( 12, ppy(F_to))        
    fi_to_end_month = fi_to_start_month + mpp_to - 1
    trunc_start = fi_to_end_month < fi_from_start_month ? 1 : 0
    return MIT{F_to}(fi_to_period+trunc_start)
end
function _fconvert_higher_get_fi(F_to::Type{<:YPFrequency{N1}}, first_mit::MIT{<:YPFrequency{N2}}, ref::Val{:begin}) where {N1,N2}
    fi_to_period, fi_from_start_month, fi_to_start_month = fconvert_parts(F_to, first_mit, ref=:begin)
    trunc_start = fi_to_start_month < fi_from_start_month ? 1 : 0
    return MIT{F_to}(fi_to_period+trunc_start)
end


function _fconvert_higher_monthly(F_to::Type{<:Monthly}, t::TSeries{<:YPFrequency{N}}; method=:const, ref=:end) where {N}
    np = Int(12 / N)
    
    fi_to_period, fi_from_start_month, fi_to_start_month = fconvert_parts(sanitize_frequency(F_to), t.firstdate, ref=:begin)
    fi = MIT{F_to}(fi_to_period)
    ts = TSeries(fi:fi+np*length(t) - 1)
    
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    elseif method == :even
        return TSeries(fi, repeat(t.values ./ np, inner=np))
    elseif method == :linear
        # interpolate across months between input series values
        for m in reverse(rangeof(t))
            if ref != :middle
                fi_loop = fconvert(Monthly, m) - (np - 1)
                li_loop = fconvert(Monthly, m)
                n_months = length(fi_loop:li_loop)
                start_val, end_val = _get_interpolation_values(t, m; ref=ref)
                interpolated = collect(LinRange(start_val, end_val, n_months + 1))
                if ref == :end
                    ts[fi_loop:li_loop] = interpolated[2:end]
                elseif ref == :begin
                    ts[fi_loop:li_loop] = interpolated[1:end-1]
                end
            elseif ref == :middle
                even = (np/2) % 1 == 0 ? 1 : 0
                start_val, end_val = _get_interpolation_values(t, m; ref=ref)
                
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
function _fconvert_higher(F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}; method=:const, ref=:end) where {N}
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rangeof(t), trim=ref)
    dates = _fconvert_higher_get_dates(F_to, t, Val(ref))
    
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
function _fconvert_higher_get_dates(F_to::Type{Weekly{end_day}}, t::TSeries{<:Union{<:YPFrequency}}, ref::Val{:end}) where {end_day}
    # The out_indices command provides the week within which falls each of the provided dates.
    # we need to know how many weeks fall within each input period.
    # so for ref = :end we need to know when a week ends in the following output period
    # this happens whenever the first day in the next period falls within that week.

    # Get the last day of each month/quarter etc.
    dates = [Dates.Date(val) for val in rangeof(t)]
    # Convert to first day of each month/quarter (except for the last one)
    dates[1:end-1] = dates[1:end-1] .+ Day(1) 
    if dayofweek(dates[end]) == end_day
        dates[end] += Day(1) # add one day to the end, this will be trimmed if needed
    end
    # insert the first day of the first month/quarter at the start
    insert!(dates, 1, Dates.Date(t.firstdate, :begin) )

    return dates
end
function _fconvert_higher_get_dates(F_to::Type{Weekly{end_day}}, t::TSeries{<:Union{<:YPFrequency}}, ref::Val{:begin}) where {end_day}
    # for ref == :begin the week of the last day of the month will always be followed by a transition
    # however, we want to make sure to include the first value if warranted
       
    # get the last day of each month/quarter
    dates = [Dates.Date(val) for val in rangeof(t)]
    # get the first day of the first month/quarter
    first_date = Dates.Date(t.firstdate, :begin)
    # add it at the start
    insert!(dates, 1, first_date - Day(7)) # add the previous week, this will be trimmed if needed
    return dates
end

# BDaily to Daily (including linearization)
function _fconvert_higher(F_to::Type{<:Daily}, t::TSeries{BDaily}; method=:const, ref=:end)
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
        if ref == :end
            monday_indices = out_dates[daysofweeks .== 1]
            # @show monday_indices
            # remove early mondays
            if monday_indices[1] == fi
                monday_indices = monday_indices[2:end]
            end
            ts[monday_indices .- 2] = ts[monday_indices]
            ts[monday_indices .- 1]= ts[monday_indices]
        elseif ref == :begin
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
        if ref ∈ (:begin, :end, :middle) # all are treated the same
            differences = ts[monday_indices] .- ts[friday_indices]
            ts[friday_indices .+ 1] = ts[friday_indices] + 1/3*differences
            ts[friday_indices .+ 2] = ts[friday_indices] + 2/3*differences
        end
    end

    return ts
end

# YP + Weekly to Daily + BDaily (incl. linearization)
"""Middle of the month will generally fall on the 16th"""
function _fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; method=:const, ref=:end)
    date_function = F_to == BDaily ? bdaily : daily
    fi = date_function(Dates.Date(t.firstdate, :begin), bias=:next)
    li = date_function(Dates.Date(rangeof(t)[end]), bias=:previous)
    ts = TSeries(fi:li)
    if ref ∉ (:end, :begin) #, :middle)
        throw(ArgumentError("ref argument must be :begin or :end. Received: $(ref)."))
    end
    if method == :const
        for m in rangeof(t)
            fi_loop = date_function(Dates.Date(m, :begin), bias=:next)
            li_loop = date_function(Dates.Date(m), bias=:previous)
            # ts[fi_loop:li_loop] = repeat([t[m]], inner=length(fi_loop:li_loop))
            ts[fi_loop:li_loop] .= t[m]
        end
        return ts
    elseif method == :even
        for m in rangeof(t)
            fi_loop = date_function(Dates.Date(m, :begin), bias=:next)
            li_loop = date_function(Dates.Date(m), bias=:previous)
            rng_loop = fi_loop:li_loop
            rng_loop_length = length(rng_loop)
            ts[rng_loop] .= t[m] / rng_loop_length
            # ts[fi_loop:li_loop] .= t[m] / (Int(li_loop) - Int(fi_loop))
        end
        return ts
    elseif method == :linear
        for m in reverse(rangeof(t))
            if ref != :middle
                fi_loop = date_function(Dates.Date(m, :begin), bias=:next)
                li_loop = date_function(Dates.Date(m), bias=:previous)
                n_days = length(fi_loop:li_loop)
                start_val, end_val = _get_interpolation_values(t, m; ref=ref)
                interpolated = collect(LinRange(start_val, end_val, n_days + 1))
                if ref == :end
                    ts[fi_loop:li_loop] = interpolated[2:end]
                elseif ref == :begin
                    ts[fi_loop:li_loop] = interpolated[1:end-1]
                end
            elseif ref == :middle
                start_val, end_val = _get_interpolation_values(t, m; ref=ref)
                # @show start_val, end_val
                if m == last(rangeof(t))
                    fi_loop = date_function(_date_plus_half(m, :begin), bias=:next)
                    li_loop = date_function(Dates.Date(m), bias=:previous)
                else
                    fi_loop = date_function(_date_plus_half(m, :begin), bias=:next)
                    li_loop = date_function(_date_plus_half(m+1, :begin), bias=:previous)
                end
                n_days = length(fi_loop:li_loop)
                interpolated = collect(LinRange(start_val, end_val, n_days))
                ts[fi_loop:li_loop] = interpolated[1:end]
                # additional fix for start
                if m == first(rangeof(t))
                    fi_loop = date_function(Dates.Date(m, :begin), bias=:next)
                    li_loop = date_function(_date_plus_half(m, :begin), bias=:previous) 
                    n_days = length(fi_loop:li_loop)
                    diffs = interpolated[1:n_days] .- interpolated[1]
                    ts[fi_loop:li_loop] =  interpolated[1] .- reverse(diffs)
                elseif m == last(rangeof(t)) - 1
                    fi_loop = date_function(_date_plus_half(m+1, :begin), bias=:next)
                    li_loop = date_function(Dates.Date(m+1), bias=:previous)
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
function _fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:mean, ref=:end, errors=true) where {N1,N2}
    
    F_from = frequencyof(t)
    mpp_from = div( 12, ppy(F_from))
    mpp_to = div( 12, ppy(F_to))
    (np, r) = divrem(N2, N1)

    if method == :end
        method = :point
        ref = :end
    elseif method == :begin
        method=:point
        ref = :begin
    end
   
    fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month = fconvert(F_to, rangeof(t), trim=:both, parts=true)
    trunc_start = 0
    trunc_end = 0
    if method == :point
        trunc_start = get_start_truncation_yp(fi_from_start_month, fi_to_start_month, mpp_from, mpp_to, ref=ref, require=:single)
        trunc_end = get_end_truncation_yp(li_from_end_month, li_to_end_month, mpp_from, mpp_to, ref=ref, require=:single)
    else
        trunc_start = get_start_truncation_yp(fi_from_start_month, fi_to_start_month, mpp_from, mpp_to, ref=ref, require=:all)
        trunc_end = get_end_truncation_yp(li_from_end_month, li_to_end_month, mpp_from, mpp_to, ref=ref, require=:all)
    end

    fi = MIT{F_to}(fi_to_period+trunc_start)
    li = MIT{F_to}(li_to_period-trunc_end)
    out_range = fi:li
    
    fi_truncation_adjustment = trunc_start == 1 ? mpp_to : 0
    if method == :point
        # for the point method we just need to specify the indices in the input
        # which correspond to the MITs in the output. These will all be np apart.
        if ref == :end
            fi_from_end_month = fi_from_start_month + mpp_from -1
            fi_to_end_month = fi_to_start_month + mpp_to -1
            months_of_missalignment = fi_to_end_month + fi_truncation_adjustment - fi_from_end_month
        elseif ref == :begin
            months_of_missalignment = fi_to_start_month + fi_truncation_adjustment - fi_from_start_month    
        end
        periods_of_missalignment = floor(Int, months_of_missalignment / mpp_from)
        
        indices = filter(x-> x > 0, 1+periods_of_missalignment:np:length(t.values))[1:length(out_range)]
        
        ret = t.values[indices]
    else # mean/sum/min/max
        months_of_missalignment = fi_to_start_month + fi_truncation_adjustment - fi_from_start_month 
        if ref == :begin 
            months_of_missalignment += (mpp_from - 1)
        end
        if ref == :begin && trunc_start == 0 && fi_from_start_month > fi_to_start_month
            months_of_missalignment = 0
        end
        periods_of_missalignment = floor(Int, months_of_missalignment / mpp_from)
        # start index needs to be smarter, it's assuming too much
        start_index = 1 + periods_of_missalignment
        end_index = start_index + np*length(out_range) - 1
        if start_index < 1
            # same as while start_index < 1 : start_index += np
            (d,r) = divrem(start_index, np)
            d = r !== 0 ? d + 1 : d
            start_index += d * np
            if start_index == 0
                start_index += np
            end
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
function _fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{Daily,<:Weekly}}; method=:mean, ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N}
    
    F_from = frequencyof(t)
    rng_from = rangeof(t)

    if method == :end
        method = :point
        ref = :end
    elseif method == :begin
        method=:point
        ref = :begin
    end
    
    if F_from == Daily
        dates = collect(Dates.Date(first(rng_from)):Day(1):Dates.Date(last(rng_from)))
    elseif method != :point
        # for most methods we want to know which actual output period 
        # corresponds to the start/end of each input period
        dates = [Dates.Date(val, ref) for val in rng_from]
    else
        # for method = :point and ref = :begin we want the value for an input period
        # which overlaps an output period to correspond to that output period, so all dates
        # are based on the end of the period
        dates = [Dates.Date(val) for val in rng_from]
    end

    trim = method == :point ? ref : :both
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rng_from, trim=trim)
    out_index = _get_out_indices(F_to, dates)
    if F_from <: Weekly
        # adjust fi, and li based on the decision about the dates above.
        fi = out_index[begin]
        li = out_index[end]
    end
    
    if method == :mean
        ret = [mean(values(t)[out_index.==target]) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(values(t)[out_index.==target]) for target in unique(out_index)]
    elseif method == :point && ref == :begin
        ret = [values(t)[out_index.==target][begin] for target in unique(out_index)]
    elseif method == :point && ref == :end
        ret = [values(t)[out_index.==target][end] for target in unique(out_index)]
    elseif method == :min 
        ret = [minimum(values(t)[out_index.==target]) for target in unique(out_index)]
    elseif method == :max 
        ret = [maximum(values(t)[out_index.==target]) for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end

function _fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{BDaily}; method=:mean, ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N}
    
    F_from = frequencyof(t)
    rng_from = rangeof(t)

    if method == :end
        method = :point
        ref = :end
    elseif method == :begin
        method=:point
        ref = :begin
    end
    
   
    dates = [Dates.Date(val) for val in rng_from]
    if holidays_map !== nothing
        dates = dates[holidays_map[rng_from].values]
    elseif skip_holidays
        holidays_map = getoption(:bdaily_holidays_map)
        dates = dates[holidays_map[rng_from].values]
    end
   
    trim = method == :point ? ref : :both
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rng_from, trim=trim, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
    out_index = _get_out_indices(F_to, dates)
    
    ret = method == :mean ? Vector{Float64}() : Vector{eltype(t)}()
    for target in unique(out_index)
        target_range = collect(rng_from)[out_index .== target]
        vals = cleanedvalues(t[target_range[begin]:target_range[end]]; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
        if method == :mean
            push!(ret, mean(vals))
        elseif method == :sum
            push!(ret, sum(vals))
        elseif method == :point && ref == :begin
            push!(ret, vals[begin])
        elseif method == :point && ref == :end
            push!(ret, vals[end])
        elseif method == :min 
            push!(ret, minimum(vals))
        elseif method == :max 
            push!(ret, maximum(vals))
        else
            throw(ArgumentError("Conversion method not available: $(method)."))
        end
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end

# Daily to BDaily (method means nothing)
function _fconvert_lower(F_to::Type{<:BDaily}, t::TSeries{Daily}; method=:mean, ref=:end)
    # options have no effect here
    fi = fconvert(F_to, firstdate(t), round_to=:next)

    out_map_week = repeat([true], 7)
    first_day = dayofweek(Dates.Date(firstdate(t)))
    saturday = first_day == 7 ? 7 : 7 - first_day
    sunday = first_day == 7 ? 1 : saturday + 1
    out_map_week[[saturday, sunday]] .= false
    out_map = repeat(out_map_week, ceil(Int, length(t) / 7))[1:length(t)]

    return TSeries(fi, t.values[out_map])
end
