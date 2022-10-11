"""
# Daily/Business => YP/Weekly
    options:    method = :mean/sum/end/begin, nans = nothing
# Weekly => YP
    options:    method=:mean/sum/end/begin, interpolation=:none/:linear
Weekly => weekly
    method = mean/sum/end/begin, interpolation = interpolation=:none/:linear
# Daily => Business
    options:    none

"""

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
function fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, t::TSeries{<:Union{Daily,BusinessDaily}}; method = :mean, skip_nans::Union{Bool,Nothing} = nothing)
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
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(t), dates_all, method, include_weekends = include_weekends)

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
function fconvert(F_to::Type{<:Union{Monthly,Quarterly{N1},Quarterly,Yearly{N2},Yearly}}, t::TSeries{<:Weekly}; method = :mean, interpolation = :none) where {N1,N2}
    dates = [Dates.Date(val) for val in rangeof(t)]

    # interpolate for weeks spanning divides
    adjusted_values = copy(t.values)
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
                    return fconvert(F_to, fconvert(Daily, t; method = :linear, values_base = :end), method = :mean)
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
    out_map = repeat(out_map_week, ceil(Int, length(t)/7))[1:length(t)]
    
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
function fconvert(F_to::Type{<:Union{<:Weekly,Weekly{N1}}}, t::TSeries{<:Union{<:Weekly,Weekly{N2}}}; method = :mean, interpolation = :none) where {N1,N2}
    return fconvert(F_to, fconvert(Daily, t, method = interpolation == :linear ? :linear : :const), method = method)
end