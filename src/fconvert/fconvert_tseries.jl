# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

import Statistics: mean
# https://stackoverflow.com/questions/46321515/get-function-signatures

"""
    fconvert(F_to, t::TSeries)

Convert the time series `t` to the desired frequency `F_to`.
"""
fconvert(F_to::Type{Unit}, t::TSeries{F}; args...) where {F<:CalendarFrequency} = error("""
Conversion of TSeries from $(frequencyof(t)) to $F_to not implemented.
""")
fconvert(f::Function, F_to::Type{Unit}, t::TSeries{F}; args...)  where {F<:CalendarFrequency} = error("""
Conversion of TSeries from $(frequencyof(t)) to $F_to not implemented.
""")
fconvert(F_to::Type{<:CalendarFrequency}, t::TSeries{F}; args...) where {F<:Unit} = error("""
Conversion of TSeries from $(F) to $F_to not implemented.
""")
fconvert(f::Function, F_to::Type{<:CalendarFrequency}, t::TSeries{F}; args...) where {F<:Unit} = error("""
Conversion of TSeries from $(F) to $F_to not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(F_to::Type{F}, t::TSeries{F}; kwargs...) where {F<:Frequency} = t
fconvert(f::Function, F_to::Type{F}, t::TSeries{F}; kwargs...) where {F<:Frequency} = t

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

### Passing a custom conversion function
One can also pass a custom function as the first argument of the fconvert command. These must have a particular input and output:

Converting to a lower frequency:
    The function must accept a single argument, a vector of values, and return a single value.

Converting to a higher frequency:
    The function must accept two positional arguments and any number of keyword arguments. 
    The first positional argument will receive the vector of values from the input TSeries.
    The second positional argument is a vector of integers listing the number of output periods,
    which correspond to each input value.
    All keyword arguments are passed on to this conversion. In addition, the keyword argument `outrange`
    will be passed to the function. This argument provides the range of the resulting TSeries and can be
    useful if the function requires that one or more indicator series of the output frequency are passed.


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
    N1 > N2 ? _fconvert_higher(sanitize_frequency(F_to), t; kwargs...) : _fconvert_lower(sanitize_frequency(F_to), t; kwargs...)
end

fconvert(f::Function, F_to::Type{Weekly}, t::TSeries; kwargs...) = fconvert(f, Weekly{7}, t; kwargs...)
fconvert(f::Function, F_to::Type{Quarterly}, t::TSeries{<:Union{Daily,BDaily,<:Weekly}}; kwargs...) = fconvert(f, Quarterly{3}, t; kwargs...)
fconvert(f::Function, F_to::Type{HalfYearly}, t::TSeries{<:Union{Daily,BDaily,<:Weekly}}; kwargs...) = fconvert(f, HalfYearly{6}, t; kwargs...)
fconvert(f::Function, F_to::Type{Yearly}, t::TSeries{<:Union{Daily,BDaily,<:Weekly}}; kwargs...) = fconvert(f, Yearly{12}, t; kwargs...)
function fconvert(f::Function, F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; kwargs...) where {N1, N2}
    N1 > N2 ? _fconvert_higher(sanitize_frequency(F_to), t, f; kwargs...) : _fconvert_lower(sanitize_frequency(F_to), t, f; kwargs...)
end

fconvert(F_to::Type{<:Weekly{end_day}}, t::TSeries{<:YPFrequency}; method=:const, ref=:end) where {end_day} = _fconvert_higher(F_to, t; method=method, ref=ref)
fconvert(F_to::Type{<:Union{Yearly{N},HalfYearly{N},Quarterly{N},Monthly,Weekly{N}}}, t::TSeries{<:Union{Daily, BDaily, <:Weekly}}; method=:mean, ref=:end, kwargs...) where {N} = _fconvert_lower(F_to, t; method=method, ref=ref, kwargs...)
fconvert(F_to::Type{<:Daily}, t::TSeries{BDaily}; method=:const, ref=:end) = _fconvert_higher(F_to, t; method=method, ref=ref)
fconvert(F_to::Type{<:BDaily}, t::TSeries{Daily}; method=:mean, ref=:begin) = _fconvert_lower(F_to, t; method=method, ref=ref)
fconvert(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; method=:const, ref=:end) = _fconvert_higher(F_to, t; method=method, ref=ref)

fconvert(f::Function, F_to::Type{<:Union{Yearly{N},HalfYearly{N},Quarterly{N},Monthly,Weekly{N}}}, t::TSeries{<:Union{Daily, BDaily, <:Weekly}}; ref=:end, kwargs...) where {N} = _fconvert_lower(F_to, t, f; ref=ref, kwargs...)
fconvert(f::Function, F_to::Type{<:BDaily}, t::TSeries{Daily}; ref=:end, kwargs...) = _fconvert_lower(F_to, t, f; ref=ref, kwargs...)
fconvert(f::Function, F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; kwargs...) = _fconvert_higher(F_to, t, f; kwargs...)
fconvert(f::Function, F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}; kwargs...) where {N} = _fconvert_higher(F_to, t, f; kwargs...)


function _fconvert_higher(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:const, ref=:end, kwargs...) where {N1,N2}
    (np, r) = divrem(N1, N2)
    
    fi = _fconvert_higher_get_fi(F_to, t.firstdate, Val(ref))
    
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    elseif method == :even
        return TSeries(fi, repeat(t.values ./ np, inner=np))
    elseif method == :linear
        return TSeries(fi, linear_uneven(t.values, repeat([np], length(t)); ref=ref, kwargs...))
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end
function _fconvert_higher(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Function; ref=:end, kwargs...) where {N1,N2}
    (np, r) = divrem(N1, N2)
    
    fi = _fconvert_higher_get_fi(F_to, t.firstdate, Val(ref))
    
    ret = f(t.values, repeat([np], length(t)); ref=ref, outrange=fi:fi+np*length(t), kwargs...)
    return TSeries(fi, ret)
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

# YP + Weekly to Weekly
_fconvert_higher(F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}; method=:const, ref=:end) where {N} = _fconvert_higher(F_to, t, Val(method); ref=ref)
_fconvert_higher(F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}, method::Val{:const}; ref=:end) where {N} = _fconvert_higher(F_to, t, repeat_uneven; ref=ref)
_fconvert_higher(F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}, method::Val{:even}; ref=:end) where {N} = _fconvert_higher(F_to, t, divide_uneven; ref=ref)
_fconvert_higher(F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}, method::Val{:linear}; ref=:end) where {N} = _fconvert_higher(F_to, t, linear_uneven; ref=ref)
function _fconvert_higher(F_to::Type{Weekly{N}}, t::TSeries{<:Union{<:YPFrequency}}, f::Function; kwargs...) where {N}
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rangeof(t), trim=kwargs[:ref])
    dates = _fconvert_higher_get_dates(F_to, t, Val(kwargs[:ref]))
    
    out_indices = _get_out_indices(F_to, dates)
    output_periods_per_input_period = Int.(out_indices[2:end] .-  out_indices[1:end-1])
    ret =  f(t.values, output_periods_per_input_period; outrange=fi+trunc_start:li-trunc_end, kwargs...)

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
_fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}; method=:const, ref=:end) = _fconvert_higher(F_to, t, Val(method); ref=ref)
_fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}, method::Val{:const}; ref=:end) = _fconvert_higher(F_to, t, repeat_uneven; ref=ref)
_fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}, method::Val{:even}; ref=:end) = _fconvert_higher(F_to, t, divide_uneven; ref=ref)
_fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}, method::Val{:linear}; ref=:end) = _fconvert_higher(F_to, t, linear_uneven; ref=ref)
function _fconvert_higher(F_to::Type{<:Union{Daily,BDaily}}, t::TSeries{<:Union{<:YPFrequency, <:Weekly}}, f::Function; kwargs...)
    date_function = F_to == BDaily ? bdaily : daily
    fi = date_function(Dates.Date(t.firstdate, :begin), bias=:next)
    li = date_function(Dates.Date(rangeof(t)[end]), bias=:previous)
    if kwargs[:ref] ∉ (:end, :begin) #, :middle)
        throw(ArgumentError("ref argument must be :begin or :end. Received: $(ref)."))
    end

    output_periods_per_input_period = map(m -> Int(date_function(Dates.Date(m, :end), bias=:previous) - date_function(Dates.Date(m, :begin), bias=:next)) + 1, rangeof(t))

    ret =  f(t.values, output_periods_per_input_period; outrange=fi:li, kwargs...)
    return copyto!(TSeries(eltype(ret), fi:li), ret)
end

"""
_to_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = :mean, errors = true, args...) where {N1,N2}
    Convert a TSeries to a lower frequency. 
"""
# YP to YP
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:mean, ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, Val(method); ref=ref)
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Val{:mean}; ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, mean; ref=ref)
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Val{:sum}; ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, sum; ref=ref)
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Val{:min}; ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, minimum; ref=ref)
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Val{:max}; ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, maximum; ref=ref)
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Val{:end}; ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, Val(:point); ref=:end)
_fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, f::Val{:begin}; ref=:end) where {N1,N2} = _fconvert_lower(F_to, t, Val(:point); ref=:begin)
function _fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, aggregator::Function; method=:mean, ref=:end) where {N1,N2}    
    # necessary values
    F_from = frequencyof(t)
    mpp_from = div( 12, ppy(F_from))
    mpp_to = div( 12, ppy(F_to))
    (np, r) = divrem(N2, N1)
   
    # get out_range
    fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month = fconvert(F_to, rangeof(t), trim=:both, parts=true)
    trunc_start = get_start_truncation_yp(Val(ref), Val(:all), fi_from_start_month, fi_to_start_month, mpp_from, mpp_to)
    trunc_end = get_end_truncation_yp(Val(ref), Val(:all), li_from_end_month, li_to_end_month, mpp_from, mpp_to)
    fi = MIT{F_to}(fi_to_period+trunc_start)
    li = MIT{F_to}(li_to_period-trunc_end)
    out_range = fi:li
    
    # get corresponding value indices
    # if the first index is truncated, add the necessary months to the calculation
    fi_truncation_adjustment = trunc_start == 1 ? mpp_to : 0
    # if the reference point is :begin, the end of an input period may span the start
    # of an output period, so we need to adjust for that eventuality
    begin_adjustment = ref == :begin ? mpp_from - 1 : 0
    months_of_missalignment = fi_to_start_month - fi_from_start_month + fi_truncation_adjustment + begin_adjustment
    periods_of_missalignment = floor(Int, months_of_missalignment / mpp_from)
    start_index = 1 + periods_of_missalignment
    end_index = start_index + np*length(out_range) - 1
    
    # convert values
    reshaped_vals = reshape(t.values[start_index:end_index], np, :)
    ret = [aggregator(col) for col in eachcol(reshaped_vals)]
    
    return copyto!(TSeries(eltype(ret), out_range), ret[1:length(out_range)])
end
function _fconvert_lower(F_to::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}, method::Val{:point}; ref=:end) where {N1,N2}
    # necessary values
    F_from = frequencyof(t)
    mpp_from = div( 12, ppy(F_from))
    mpp_to = div( 12, ppy(F_to))
    (np, r) = divrem(N2, N1)

    # get out_range
    fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month = fconvert(F_to, rangeof(t), trim=:both, parts=true)
    trunc_start = get_start_truncation_yp(Val(ref), Val(:single), fi_from_start_month, fi_to_start_month, mpp_from, mpp_to)
    trunc_end = get_end_truncation_yp(Val(ref), Val(:single), li_from_end_month, li_to_end_month, mpp_from, mpp_to)

    fi = MIT{F_to}(fi_to_period+trunc_start)
    li = MIT{F_to}(li_to_period-trunc_end)
    out_range = fi:li
        
    # for the point method we just need to specify the indices in the input
    # which correspond to the MITs in the output. These will all be np apart.
    fi_truncation_adjustment = trunc_start == 1 ? mpp_to : 0
    if ref == :end
        fi_from_end_month = fi_from_start_month + mpp_from -1
        fi_to_end_month = fi_to_start_month + mpp_to -1
        months_of_missalignment = fi_to_end_month - fi_from_end_month + fi_truncation_adjustment 
    elseif ref == :begin
        months_of_missalignment = fi_to_start_month - fi_from_start_month + fi_truncation_adjustment     
    end
    periods_of_missalignment = floor(Int, months_of_missalignment / mpp_from)
    
    indices = filter(x-> x > 0, 1+periods_of_missalignment:np:length(t.values))[1:length(out_range)]
    
    ret = t.values[indices]
    return copyto!(TSeries(eltype(ret), out_range), ret[1:length(out_range)])
end


# Calendar to YP + Weekly
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}; method=:mean, ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, Val(method); ref=ref, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:mean}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, mean; ref=ref, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:sum}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, sum; ref=ref, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:min}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, minimum; ref=ref, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:max}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, maximum; ref=ref, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:point}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, method, Val(ref), skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:begin}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, Val(:point), Val(:begin), skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:end}; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, Val(:point), Val(:end), skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:point}, ref::Val{:end}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, last; ref=:end, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
_fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{BDaily,Daily,<:Weekly}}, method::Val{:point}, ref::Val{:begin}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N} = _fconvert_lower(F_to, t, first; ref=:begin, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)

function _fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{<:Union{Daily,<:Weekly}}, aggregator::Function; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N}
    
    F_from = frequencyof(t)
    rng_from = rangeof(t)
    
    if F_from == Daily
        dates = collect(Dates.Date(first(rng_from)):Day(1):Dates.Date(last(rng_from)))
    elseif aggregator ∉ (first, last)
        # for most methods we want to know which actual output period 
        # corresponds to the start/end of each input period
        dates = [Dates.Date(val, ref) for val in rng_from]
    else
        # for method = :point and ref = :begin we want the value for an input period
        # which overlaps an output period to correspond to that output period, so all dates
        # are based on the end of the period
        dates = [Dates.Date(val) for val in rng_from]
    end

    trim = aggregator ∈ (first, last) ? ref : :both
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rng_from, trim=trim)
    out_index = _get_out_indices(F_to, dates)
    if F_from <: Weekly
        # adjust fi, and li based on the decision about the dates above.
        fi = out_index[begin]
        li = out_index[end]
    end
    
    ret = [aggregator(values(t)[out_index.==target]) for target in unique(out_index)]
    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end

function _fconvert_lower(F_to::Type{<:Union{Monthly,Quarterly{N},Quarterly,HalfYearly,HalfYearly{N},Yearly,Yearly{N},Weekly,Weekly{N}}}, t::TSeries{BDaily}, aggregator::Function; ref=:end, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) where {N}
    rng_from = rangeof(t)
       
    dates = [Dates.Date(val) for val in rng_from]
    if holidays_map !== nothing
        dates = dates[holidays_map[rng_from].values]
    elseif skip_holidays
        holidays_map = getoption(:bdaily_holidays_map)
        dates = dates[holidays_map[rng_from].values]
    end
   
    trim = aggregator ∈ (first, last) ? ref : :both
    if skip_all_nans == true
        nanmap = .!isnan.(t)
        if holidays_map == nothing
            holidays_map = getoption(:bdaily_holidays_map)
        end
        if holidays_map === nothing
            holidays_map = TSeries(first(rng_from)-600, trues(length(rng_from)+1200))
        end
        holidays_map[rng_from] .= holidays_map[rng_from] .& nanmap
    end
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, rng_from, trim=trim, holidays_map=holidays_map)
    out_index = _get_out_indices(F_to, dates)
    
    ret = aggregator == mean ? Vector{Float64}() : Vector{eltype(t)}()

    for target in unique(out_index)
        target_range = collect(rng_from)[out_index .== target]
        vals = cleanedvalues(t[target_range[begin]:target_range[end]]; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
        push!(ret, aggregator(vals))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end

# Daily to BDaily (method means nothing)
_fconvert_lower(F_to::Type{<:BDaily}, t::TSeries{Daily}, aggregator::Function; kwargs...) = _fconvert_lower(F_to, t; kwargs...)
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


