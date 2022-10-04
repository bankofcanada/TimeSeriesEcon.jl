"""
    fconvert(F_to::Type{<:Union{<:YPFrequency, Weekly}}, MIT_from::MIT{<:CalendarFrequency}; round_to=:current)

Converts the provided CalendarFrequency to a YP or Weekly frequency.

The optional `round_to` argument determines where to shift the output MIT to in cases where the input MIT is in between periods of the output frequency. 
The default is :current (provides the output period within which lies provided MIT).
:next provides the output period following the one in which the provided MIT lands except when the provided MIT is at the start of its current period.
:previous provides the output period preceeding the one in which the provided MIT lands except when the provided MIT is at the end of its current period.
"""
function fconvert(F_to::Type{<:Union{<:YPFrequency, <:Weekly}}, MIT_from::MIT{<:CalendarFrequency}; round_to=:current)
    dates = [Dates.Date(MIT_from)]
    out_index = _get_out_indices(F_to, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    include_weekends = frequencyof(MIT_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(MIT_from), dates, :both, include_weekends=include_weekends)
    if round_to == :next
        return fi+trunc_start
    elseif round_to == :previous
        return fi-trunc_end
    else
        return fi
    end
 end

 """
    fconvert(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly}}, range_from::Union{UnitRange{MIT{Weekly{N3}}},UnitRange{MIT{Weekly}}}; method=:both)

Converts the provided CalendarFrequency UnitRange to a YPFrequency or a Weekly frequency.

the `method` argument in this case refers to which observations of the output frequency must be covered by the input range
:begin means that the first date in each output period must be covered
:end means that the last date in each output period must be covered
:both means that both the first and last date in each output period must be covered.
Note: one can also pass :mean, :sum, which are equivalent to :both
"""
function fconvert(F_to::Type{<:Union{<:YPFrequency, <:Weekly}}, range_from::UnitRange{<:MIT{<:CalendarFrequency}}; method=:both) where {N1,N2,N3}
    dates = [Dates.Date(val) for val in range_from]
    out_index = _get_out_indices(F_to, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    li = eval(Meta.parse("li = $(out_index[end])"))
    include_weekends = frequencyof(range_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(range_from), dates, method, include_weekends=include_weekends)
    return fi+trunc_start:li-trunc_end
end



"""
    fconvert(F::Type{<:Union{<:YPFrequency, <:Weekly}}, t::TSeries{<:Union{Daily, BusinessDaily}}; method=:mean)

Convert the Daily or BusinessDaily time series `t` to the desired lower frequency `F`.

The range of the result includes periods that are fully included in the range of
the input. For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.
"""
function fconvert(F::Type{<:Union{<:YPFrequency, <:Weekly}}, t::TSeries{<:Union{Daily, BusinessDaily}}; method=:mean, nans=nothing)
    dates = [Dates.Date(val) for val in rangeof(t)]
    dates_all = copy(dates)
    if get_option(:business_skip_holidays)
        holidays_map = get_option(:business_holidays_map)
        dates = dates[holidays_map[rangeof(t)].values]
    end
    out_index = _get_out_indices(F, dates)
    # println(out_index)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    # println(F)
    # println(frequencyof(fi))
    li = eval(Meta.parse("li = $(out_index[end])"))
    include_weekends = frequencyof(t) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F, frequencyof(t), dates_all, method, include_weekends=include_weekends)
    
    if method == :mean
        ret = [mean(skip_if_warranted(values(t)[out_index .== target], nans)) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(skip_if_warranted(values(t)[out_index .== target], nans)) for target in unique(out_index)]
    elseif method == :begin
        ret = [skip_if_warranted(values(t)[out_index .== target], nans)[begin] for target in unique(out_index)]
    elseif method == :end
        ret = [skip_if_warranted(values(t)[out_index .== target], nans)[end] for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end


"""
    fconvert(F::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly}}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:mean, interpolation=:none)

Convert the Weekly time series `t` to a lower frequency time series.

The range of the result includes periods that are fully included in the range of
the input. For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks. 
The recorded weekly value is ascribed to the midpoint of the week. I.e. Thursdays for weeks ending on Sundays, Wednesdays
for weeks ending on Saturdays, etc. This is done to be consistent with the handling in FAME.
For days beyond these midpoints, the linear line between the first two or last two weeks is extended to cover the entire day range.
The corresponding daily values are used when selecting or aggregating values for the various methods.
"""
function fconvert(F::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly}}, t::TSeries{<:Weekly}; method=:mean, interpolation=:none) where {N1,N2}
    dates = [Dates.Date(val) for  val in rangeof(t)]

    # interpolate for weeks spanning divides
    adjusted_values = copy(t.values)
    if interpolation == :linear
        months_rotation = Day(0)
        if @isdefined N1
            months_rotation = Month(3-N1)
        end
        if @isdefined N2
            months_rotation = Month(12-N2)
        end
        overlap = zeros(Int, length(t.values))
        if F <: Monthly
            overlap .= [ Dates.month(date - Day(6)) != Dates.month(date) ? Dates.dayofmonth(date) : 0  for date in dates]
        end
        if F <: Quarterly
            overlap .= [ Dates.quarter(date - Day(6) + months_rotation) != Dates.quarter(date + months_rotation) ? Dates.dayofmonth(date) : 0  for date in dates]
        end
        if F <: Yearly
            overlap .= [ Dates.year(date - Day(6) + months_rotation) != Dates.year(date + months_rotation) ? Dates.dayofmonth(date) : 0  for date in dates]
        end
        for (i, d) in enumerate(overlap) 
            if i > 1 && d != 0
                v1 = copy(adjusted_values[i-1])
                v2 = copy(adjusted_values[i])
               if method == :end #equivalent to technique=linear, observed=end 
                    adjusted_values[i-1] = v1 + (1 - (d/7))*(v2 - v1)
                elseif method == :mean #equivalent to technique=linear, observed=averaged
                    # convert to daily with linear interpolation, then convert to monthly
                    return fconvert(F, fconvert(Daily, t; method=:linear, values_base=:middle), method=:mean)
                elseif method == :sum #equivalent to technique=linear, observed=summed
                    # shift some part of transitionary weeks between months
                    adjusted_values[i-1] = v1 + (1 - (d/7))*v2
                    adjusted_values[i] = v2 - (1 - (d/7))*v2
                elseif method == :begin #equivalent to technique=linear, observed:begin
                    v3 = copy(adjusted_values[min(i+1,length(dates))])
                    # this is equivalent to converting the series to daily with linear interpolation
                    # and selecting the value from the date corresponding to the reference date.
                    adjusted_values[i] = v2 + (1- (d/7))*(v3 - v2)
                end
            end
        end
    end
    
    # get out indices
    out_index = _get_out_indices(F, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    li = eval(Meta.parse("li = $(out_index[end])"))
    trunc_start, trunc_end = _get_fconvert_truncations(F, frequencyof(t), dates, method)

    # do the conversion
    if method == :mean
        ret = [mean(adjusted_values[out_index .== target]) for target in unique(out_index)]
    elseif method == :sum
        ret = [sum(adjusted_values[out_index .== target]) for target in unique(out_index)]
    elseif method == :begin
        ret = [adjusted_values[out_index .== target][begin] for target in unique(out_index)]
    elseif method == :end
        ret = [adjusted_values[out_index .== target][end] for target in unique(out_index)]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end

    return copyto!(TSeries(eltype(ret), fi+trunc_start:li-trunc_end), ret[begin+trunc_start:end-trunc_end])
end


""" this could likely be faster"""
function fconvert(F_to::Type{<:BusinessDaily}, t::TSeries{Daily})
    fi = fconvert(F_to, firstdate(t))
    li = fconvert(F_to, lastdate(t))
    
    out_length = Int(li) - Int(fi) + 1
    out_values = Array{Number}(undef, (out_length,))
    out_index = 1
    for d in rangeof(t)
        mod = Int(d) % 7
        if mod < 6 && mod > 0
            # business day
            out_values[out_index] = t[d]
            out_index += 1
        end
    end
    
    return TSeries(fi, out_values)
end