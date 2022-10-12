"""
Weekly => Daily/Business (higher)
    options: method = const/linear, values_base = end/begin/middle
YP => Daily/Business (higher)
    options: method = const/linear, values_base = end/begin
YP => Weekly (higher)
    options: method = const/linear, values_base = end/begin
Business => Daily (higher)
    options: method = const/linear, values_base = end/begin/middle
Daily/Business => YP/Weekly (lower)
    options:    method = :mean/sum/end/begin, nans = nothing
Weekly => YP (lower)
    options:    method=:mean/sum/end/begin, interpolation=:none/:linear
Weekly => Weekly (same)
    method = mean/sum/end/begin, interpolation = interpolation=:none/:linear
Daily => Business (lower)
    options:    none

"""


"""
fconvert(F_to::Type{<:Union{Daily,BusinessDaily}}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method = :const, values_base = :end) where {N3}

Convert the Weekly time series `t` to a Daily time series.

The only supported method is currently :const.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks.
The recorded weekly value is ascribed to the end-date of the week.I.e. Sunday for weeks ending in Sundays, 
Saturdays for weeks ending in Saturday, etc.
    
Note that the FAME software ascribes the value to the midpoint of the week when doing a linear interpolcation. 
I.e. Thursdays for weeks ending on Sundays, Wednesdays for weeks ending on Saturdays, etc. For days beyond 
these midpoints, the linear line between the first two or last two weeks is extended to cover the entire date
range. To reproduce this behavior, `pass values_base=:middle`.

Note also that the results for BusinessDaily frequencies also differ from that of the FAME software.
FAME interpolates for all weekdays and then drops weekends. 
To replicate that approach, first convert your weekly series to a Daily series:
`fconvert(BusinessDaily, fconvert(Daily, t, method=:linear))`

"""
function fconvert(F_to::Type{<:Union{Daily,BusinessDaily}}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:const, values_base=:end) where {N3}

    np = F_to == BusinessDaily ? 5 : 7
    reference_day_adjust = 0
    if @isdefined N3
        if F_to == BusinessDaily && N3 <= 4
            reference_day_adjust = 5 - N3
        elseif F_to == Daily
            reference_day_adjust = np - N3
        end
    end

    fi = MIT{F_to}(Int(firstindex(t)) * np - (np - 1) - reference_day_adjust)

    if values_base ∉ (:begin, :end, :middle)
        throw(ArgumentError("values_base argument must be :begin, :end, or :middle. Received: $(values_base)."))
    end
    if method == :const
        return TSeries(fi, repeat(t.values, inner=np))
    elseif method == :linear
        values = repeat(Float64.(t.values), inner=np)
        val_day = np
        if values_base == :begin
            val_day = 1
        elseif values_base == :middle
            val_day = F_to == Daily ? 4 : 3 # thursday for weekly, wednesday for businessdaily
        end

        interpolation = nothing
        max_i = length(t.values)
        for i in 1:max_i
            if i < max_i
                interpolation = collect(LinRange(t.values[i], t.values[i+1], np + 1))
            end
            if i == 1
                values[i:val_day] .= interpolation[np+1-val_day+1:np+1] .- interpolation[1]
            end
            if i != max_i
                values[val_day+(i-1)*np+1:val_day+i*np] .= interpolation[2:np+1]
            else
                values[end-(np-val_day):end] .= interpolation[1:np+1-val_day] .+ (interpolation[np+1] - interpolation[1])
            end
        end
        return TSeries(fi, values)
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end


"""
fconvert(F_to::Type{<:Union{Daily,BusinessDaily}}, t::TSeries{<:YPFrequency}; method = :const, values_base = :end)

Convert the YPFrequency time series `t` to a Daily or BusinessDaily time series.

The options are 
method = :const or :linear
values_base = :end or :begin

When method is :linear values are interpolated in a linear fashion across days between input frequency periods. The behavior depends on
values_base. When values_base is `:end` the values will be interpolated between the end-dates of adjacent periods. When values_base = `:begin`
the values will be interpolated between start-dates of adjacent periods. 
Tail-end periods will have values interpolated based on the progression in the adjacent non-tail-end period.

`values_base` has no effect when method is `:const`.
"""
function fconvert(F_to::Type{<:Union{Daily,BusinessDaily}}, t::TSeries{<:YPFrequency}; method=:const, values_base=:end)
    date_function = F_to == BusinessDaily ? bdaily : daily
    d = Dates.Date(t.firstdate - 1) + Day(1)
    fi = date_function(Dates.Date(t.firstdate - 1) + Day(1), false)
    d2 = Dates.Date(rangeof(t)[end])
    li = date_function(Dates.Date(rangeof(t)[end]))
    ts = TSeries(fi:li)
    if values_base ∉ (:end, :begin)
        throw(ArgumentError("values_base argument must be :begin or :end. Received: $(values_base)."))
    end
    if method == :const
        for m in rangeof(t)
            fi_loop = date_function(Dates.Date(m - 1) + Day(1), false)
            li_loop = date_function(Dates.Date(m))
            ts[fi_loop:li_loop] = repeat([t[m]], inner=length(fi_loop:li_loop))
        end
        return ts
    elseif method == :linear
        for m in reverse(rangeof(t))
            fi_loop = date_function(Dates.Date(m - 1) + Day(1), false)
            li_loop = date_function(Dates.Date(m))
            n_days = length(fi_loop:li_loop)
            start_val, end_val = _get_interpolation_values(t, m, values_base)
            interpolated = collect(LinRange(start_val, end_val, n_days + 1))
            if values_base == :end
                ts[fi_loop:li_loop] = interpolated[2:end]
            else # beginning
                ts[fi_loop:li_loop] = interpolated[1:end-1]
            end
        end
        return ts
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end


"""
fconvert(F_to::Type{<:Union{Weekly,Weekly{N}}}, t::TSeries{<:YPFrequency}; method = :const, values_base = :end) where {N}

Convert the YPFrequency time series `t` to a Weekly time series.

The options are 
method = :const or :linear
values_base = :end or :begin

When method is :const and values_base = :end the value of the given input period will be assigned to the week whose end-date aligns
with the end-date of the input period (or the preceeding week, if there is no alignment), and to the preceeding weeks up to and 
including the week containing, but not aligning with, the end-date of the preceeding input period.

When method is :const and values_base = :begin the value of the given input period will be assigned to the week whose start-date aligns
with the start-date of the input period (or the following week, if there is no alignment), and to the following weeks up to, but not 
including, the week containing the start-date of the following input period.

When method is :linear values are interpolated in a linear fashion across weeks between input frequency periods. The behavior depends on
values_base. When values_base is `:end` the values will be interpolated between the end-dates of adjacent periods. When values_base = `:begin`
the values will be interpolated between start-dates of adjacent periods. 
Tail-end periods will have values interpolated based on the progression in the adjacent non-tail-end period.

"""
function fconvert(F_to::Type{<:Union{Weekly,Weekly{N}}}, t::TSeries{<:YPFrequency}; method=:const, values_base=:end) where {N}
    N_effective = 7
    normalize = true
    if @isdefined(N)
        N_effective = N
        normalize = false
    end
    # println(N)
    fi = weekly(Dates.Date(t.firstdate - 1) + Day(1), N_effective, normalize)
    li = weekly(Dates.Date(rangeof(t)[end]), N_effective, normalize)
    ts = TSeries(fi:li)
    if values_base ∉ (:end, :begin)
        throw(ArgumentError("values_base argument must be :begin or :end. Received: $(values_base)."))
    end
    if method == :const
        loop_range = values_base == :end ? rangeof(t) : reverse(rangeof(t))
        for m in loop_range
            fi_loop = weekly(Dates.Date(m - 1) + Day(1), N_effective, normalize)
            li_loop = weekly(Dates.Date(m), N_effective, normalize)
            ts[fi_loop:li_loop] = repeat([t[m]], inner=length(fi_loop:li_loop))
        end
        return ts
    elseif method == :linear
        last_fi_loop = nothing
        for m in reverse(rangeof(t))
            fi_loop = weekly(Dates.Date(m - 1) + Day(1), N_effective, normalize)
            li_loop = weekly(Dates.Date(m), N_effective, normalize)
            if li_loop == last_fi_loop
                # prevent some overlap
                li_loop -= 1
            end
            n_periods = length(fi_loop:li_loop)
            start_val, end_val = _get_interpolation_values(t, m, values_base)
            interpolated = collect(LinRange(start_val, end_val, n_periods + 1))
            if values_base == :end
                ts[fi_loop:li_loop] = interpolated[2:end]
            else # beginning
                ts[fi_loop:li_loop] = interpolated[1:end-1]
            end
            last_fi_loop = fi_loop
        end
        return ts
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end


"""
fconvert(F_to::Type{<:Daily}, t::TSeries{BusinessDaily}; method = :const, values_base=:middle)

Convert the BusinessDaily time series `t` to a Daily time series.

The options are 
method = :const or :linear
values_base = :end, :begin, or :middle. Default is :middle

For method = :const, weekends and NaN values will be filled with the nearest valid value in the direction of :values_base.
They will not be replaced if values_base is set to :middle.

When method is :linear, weekends and NaN values will be filled with a linear interpolation between non-missing values.
values_base has no effect when method is set to :linear.
"""
function fconvert(F_to::Type{<:Daily}, t::TSeries{BusinessDaily}; method=:const, values_base=:middle)
    fi = fconvert(F_to, firstdate(t))
    li = fconvert(F_to, lastdate(t))

    out_length = Int(li) - Int(fi) + 1
    ts = TSeries(fi:li, repeat([NaN], out_length))

    out_dates = daily.(Dates.Date.(collect(rangeof(t))))
    ts[out_dates] .= t.values

    if values_base ∉ (:end, :begin, :middle)
        throw(ArgumentError("values_base argument must be :begin, :end, or :middle. Received: $(values_base)."))
    end
    if method ∉ (:const, :linear)
        throw(ArgumentError("method must be :const or :linear. Received: $(values_base)."))
    end
    if method == :linear || values_base != :middle
        nan_indices = findall(x -> isnan(x), ts.values)
        i = 1
        while i <= length(nan_indices)
            current_indices = [nan_indices[i]]
            while i + 1 <= length(nan_indices) && nan_indices[i+1] == current_indices[end] + 1
                i += 1
                current_indices = [current_indices..., nan_indices[i]]
            end

            if method == :const && values_base == :end && current_indices[end] < length(ts.values)
                ts.values[current_indices] .= ts.values[current_indices[end]+1]
            elseif method == :const && values_base == :begin && current_indices[begin] !== 1
                ts.values[current_indices] .= ts.values[current_indices[begin]-1]
            elseif method == :linear && current_indices[begin] !== 1 && current_indices[end] < length(ts.values)
                interpolation = collect(LinRange(ts.values[current_indices[begin]-1], ts.values[current_indices[end]+1], length(current_indices) + 2))
                ts.values[current_indices] .= interpolation[2:end-1]
            end
            i += 1
        end
        if !any(isnan.(ts.values))
            return copyto!(TSeries(eltype(ts.values[1]), fi:li), ts.values)
        end
    end

    return ts
end

"""
fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, t::TSeries{<:Union{Daily,BusinessDaily}}; method = :mean, skip_nans::Union{Bool,Nothing} = nothing)

Convert the Daily or BusinessDaily time series `t` to the desired lower frequency `F_to`.

For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.

For methods `:mean` and `:sum`, the range of the result includes periods that are fully 
included in the range of the input. For method `:begin` the output includes periods
whose start-dates fall within the input periods. For method `:end` the output includes
periods whose end-dates fall within the input periods. There is some allowance for weekends.

The `skip_nans` argument is relevant when converting from a BusinessDaily frequency. When `true`
NaN values in `t` will be skipped for determining the values in the output frequency.
The default `skip_nans` value is `nothing`. In this case, the behavior will follow the the value 
TimeSeriesEcon global option: `:business_skip_nans`. This can be overwritten by passing skip_nans=false.  
"""
function fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, t::TSeries{<:Union{Daily,BusinessDaily}}; method=:mean, skip_nans::Union{Bool,Nothing}=nothing)
    F_from = frequencyof(t)
    if F_from == BusinessDaily
        dates = [Dates.Date(val) for val in rangeof(t)]
    else
        dates = collect(Dates.Date(first(rangeof(t))):Day(1):Dates.Date(last(rangeof(t))))
    end
    dates_all = copy(dates)
    if get_option(:business_skip_holidays) && frequencyof(t) == BusinessDaily
        holidays_map = get_option(:business_holidays_map)
        dates = dates[holidays_map[rangeof(t)].values]
    end
    out_index = _get_out_indices(F_to, dates)
    fi = out_index[begin]
    li = out_index[end]
    include_weekends = frequencyof(t) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(t), dates_all, method, include_weekends=include_weekends)

    if method == :mean
        ret = [mean(skip_if_warranted(values(t)[out_index.==target], skip_nans)) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(skip_if_warranted(values(t)[out_index.==target], skip_nans)) for target in unique(out_index)]
    elseif method == :begin
        ret = [skip_if_warranted(values(t)[out_index.==target], skip_nans)[begin] for target in unique(out_index)]
    elseif method == :end
        ret = [skip_if_warranted(values(t)[out_index.==target], skip_nans)[end] for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end


"""
fconvert(F_to::Type{<:Union{Monthly,Quarterly{N1},Quarterly,Yearly{N2},Yearly}}, t::TSeries{<:Weekly}; method = :mean, interpolation = :none) where {N1,N2}

Convert the Weekly time series `t` to a lower frequency time series.

For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.

For methods `:mean` and `:sum`, the range of the result includes periods that are fully 
included in the range of the input. For method `:begin` the output includes periods
whose start-dates fall within the input periods. For method `:end` the output includes
periods whose end-dates fall within the input periods.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks. 
The recorded weekly value is ascribed to the end-date of the week.I.e. Sunday for weeks ending in Sundays, 
Saturdays for weeks ending in Saturday, etc. 

Note that the FAME software ascribes the value to the midpoint of the week when doing a linear interpolcation. 
I.e. Thursdays for weeks ending on Sundays, Wednesdays for weeks ending on Saturdays, etc. 
For days beyond these midpoints, the linear line between the first two or last two weeks is extended to cover 
the entire date range. To reproduce this behavior, call 
`fconvert(F_to, fconvert(Daily, t, method=:linear, values_base=:middle))`.

"""
function fconvert(F_to::Type{<:Union{Monthly,Quarterly{N1},Quarterly,Yearly{N2},Yearly}}, t::TSeries{<:Weekly}; method=:mean, interpolation=:none) where {N1,N2}
    dates = [Dates.Date(val) for val in rangeof(t)]

    # interpolate for weeks spanning divides
    adjusted_values = copy(Float64.(t.values))
    if interpolation ∉ (:none, :linear)
        throw(ArgumentError("interpolation argument must be :none, or :linear. Received: $(interpolation)."))
    end
    if interpolation == :linear
        months_rotation = Day(0)
        if @isdefined N1
            months_rotation = Month(3 - N1)
        end
        if @isdefined N2
            months_rotation = Month(12 - N2)
        end
        overlap = zeros(Int, length(t.values))
        if F_to <: Monthly
            overlap .= [Dates.month(date - Day(6)) != Dates.month(date) ? Dates.dayofmonth(date) : 0 for date in dates]
        end
        if F_to <: Quarterly
            overlap .= [Dates.quarter(date - Day(6) + months_rotation) != Dates.quarter(date + months_rotation) ? Dates.dayofmonth(date) : 0 for date in dates]
        end
        if F_to <: Yearly
            overlap .= [Dates.year(date - Day(6) + months_rotation) != Dates.year(date + months_rotation) ? Dates.dayofmonth(date) : 0 for date in dates]
        end
        for (i, d) in enumerate(overlap)
            if i > 1 && d != 0
                v1 = copy(adjusted_values[i-1])
                v2 = copy(adjusted_values[i])
                if method == :end #equivalent to technique=linear, observed=end 
                    adjusted_values[i-1] = v1 + (1 - (d / 7)) * (v2 - v1)
                elseif method == :mean #equivalent to technique=linear, observed=averaged
                    # convert to daily with linear interpolation, then convert to monthly
                    return fconvert(F_to, fconvert(Daily, t; method=:linear, values_base=:end), method=:mean)
                elseif method == :sum #equivalent to technique=linear, observed=summed
                    # shift some part of transitionary weeks between months
                    adjusted_values[i-1] = v1 + (1 - (d / 7)) * v2
                    adjusted_values[i] = v2 - (1 - (d / 7)) * v2
                elseif method == :begin #equivalent to technique=linear, observed:begin
                    v3 = copy(adjusted_values[min(i + 1, length(dates))])
                    # this is equivalent to converting the series to daily with linear interpolation
                    # and selecting the value from the date corresponding to the reference date.
                    adjusted_values[i] = v2 + (1 - (d / 7)) * (v3 - v2)
                end
            end
        end
    end

    # get out indices
    out_index = _get_out_indices(F_to, dates)
    fi = out_index[begin]
    li = out_index[end]
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(t), dates, method, pad_input=true)

    # do the conversion
    if method == :mean
        ret = [mean(adjusted_values[out_index.==target]) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(adjusted_values[out_index.==target]) for target in unique(out_index)]
    elseif method == :begin
        ret = [adjusted_values[out_index.==target][begin] for target in unique(out_index)]
    elseif method == :end
        ret = [adjusted_values[out_index.==target][end] for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end


"""
fconvert(F_to::Type{<:BusinessDaily}, t::TSeries{Daily})

Convert the Daily time series `t` to a BusinessDaily time series.

Values falling on weekend days are simply excluded from the output.
"""
function fconvert(F_to::Type{<:BusinessDaily}, t::TSeries{Daily})
    fi = fconvert(F_to, firstdate(t))

    out_map_week = repeat([true], 7)
    first_day = dayofweek(Dates.Date(firstdate(t)))
    saturday = first_day == 7 ? 7 : 7 - first_day
    sunday = first_day == 7 ? 1 : saturday + 1
    out_map_week[[saturday, sunday]] .= false
    out_map = repeat(out_map_week, ceil(Int, length(t) / 7))[1:length(t)]

    return TSeries(fi, t.values[out_map])
end

"""
fconvert(F_to::Type{<:Union{<:Weekly,Weekly{N1}}}, t::TSeries{<:Union{<:Weekly,Weekly{N2}}}; method = :mean, interpolation = :none) where {N1,N2}

Convert the Weekly time series `t` to a Weekly time series of a different end day.

We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.

For methods `:mean` and `:sum`, the range of the result includes periods that are fully 
included in the range of the input. For method `:begin` the output includes periods
whose start-dates fall within the input periods. For method `:end` the output includes
periods whose end-dates fall within the input periods.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks 
with the recorded weekly value landing on the end-date of each weekly period. Values for the first
weekly period will have values interpolated based on the progression in the second weekly period.
The resulting daily values are used when selecting or aggregating values according to the `method` argument.
"""
function fconvert(F_to::Type{<:Union{<:Weekly,Weekly{N1}}}, t::TSeries{<:Union{<:Weekly,Weekly{N2}}}; method=:mean, interpolation=:none) where {N1,N2}
    return fconvert(F_to, fconvert(Daily, t, method=interpolation == :linear ? :linear : :const), method=method)
end



