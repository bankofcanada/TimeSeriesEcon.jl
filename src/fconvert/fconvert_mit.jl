# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

"""
    fconvert(F_to, MIT_from::MIT)

Convert the time MIT `MIT_from` to the desired frequency `F_to`.
"""
fconvert(F_to::Type{<:Frequency}, MIT_from::MIT; args...) = error("""
Conversion of MIT from $(frequencyof(MIT_from)) to $F_to not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(F_to::Type{F}, MIT_from::MIT{F}) where {F<:Frequency} = MIT_from


"""
fconvert(F_to::Type{<:Union{<:CalendarFrequency,<:YPFrequency}}, MIT_from::MIT{<:Union{<:CalendarFrequency,<:YPFrequency}}; values_base = :end, round_to=:current)

Converts a MIT instance to the given target frequency.

`values_base` determines the position within the input frequency to align with the output frequency. The options are `:begin`, `:end`. The default is `:end`.
`round_to` is only when converting to BDaily MIT, it determines the direction in which to find the nearest business day. The options are `:previous`, `:next`, and `:current`. The default is `:previous`.
When converting to BDaily MIT the conversion will result in an error if round_to == `:current` and the date at the start/end of the provided input is in a weekend.


For example, 
fconvert(Quarterly, 22Y, values_base=:end) ==> 2022Q4
fconvert(Quarterly, 22Y, values_base=:begin) ==> 2022Q1
"""

# MIT YP => YP
# having these different signatures significantly speeds up the performance; from a few microseconds to a few nanoseconds
fconvert(F_to::Type{<:Union{<:YPFrequency}}, MIT_from::MIT{<:Union{<:YPFrequency}}; values_base=:end, round_to=:current) = _fconvert(sanitize_frequency(F_to), MIT_from, values_base=values_base, round_to=round_to)
function _fconvert(F_to::Type{<:Union{<:YPFrequency}}, MIT_from::MIT{<:Union{<:YPFrequency}}; values_base=:end, round_to=:current)
    F_from = frequencyof(MIT_from)
    values_base_adjust = values_base == :end ? 1 : 0
    rounder = values_base == :end ? ceil : floor
    from_month = Int(MIT_from+values_base_adjust) * 12 / ppy(F_from) - values_base_adjust
    from_month -= (12 / ppy(F_from)) - endperiod(F_from)
    out_period = (from_month + values_base_adjust) / (12 / ppy(F_to)) - values_base_adjust
    return MIT{F_to}(rounder(Integer, out_period))
end

# MIT Calendar => YP + Weekly
function fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, MIT_from::MIT{<:Union{Daily, BDaily, <:Weekly}}; values_base=:end, round_to=:current)
    if values_base == :end
        return _get_out_indices(sanitize_frequency(F_to), [Dates.Date(MIT_from, :end)])[begin]
    elseif values_base == :begin
        return _get_out_indices(sanitize_frequency(F_to), [Dates.Date(MIT_from, :begin)])[begin]
    end

    # error checking
    throw(ArgumentError("values_base argument must be :begin or :end. Received: $(values_base)."))
end

# MIT YP => Weekly
function fconvert(F_to::Type{<:Weekly}, MIT_from::MIT{<:YPFrequency}; values_base=:end, round_to=:current)
    if values_base == :end
        return _get_out_indices(sanitize_frequency(F_to), [Dates.Date(MIT_from, :end)])[begin]
    elseif values_base == :begin
        return _get_out_indices(sanitize_frequency(F_to), [Dates.Date(MIT_from, :begin)])[begin]
    end

    # error checking
    throw(ArgumentError("values_base argument must be :begin or :end. Received: $(values_base)."))
end

# MIT => BDaily
# function fconvert(F_to::Type{BDaily}, MIT_from::MIT{<:Union{<:Weekly,<:YPFrequency,Daily}}; values_base=:end)
    
# end
function fconvert(F_to::Type{BDaily}, MIT_from::MIT{<:Union{<:Weekly,<:YPFrequency,Daily}}; values_base=:end, round_to=:previous)
    if round_to == :previous
        return bdaily(Dates.Date(MIT_from, values_base), bias=:previous)
    elseif round_to == :next
        return bdaily(Dates.Date(MIT_from, values_base); bias=:next)
    elseif round_to == :current
        d = Dates.Date(MIT_from)
        if (dayofweek(d) >= 6)
            throw(ArgumentError("$d is on a weekend. Pass round_to = :previous or :next to convert to $F_to"))
        end
        return bdaily(d)
    else
        throw(ArgumentError("round_to argument must be :current, :previous, or :next. Received: $(round_to)."))
    end
end

# MIT => Daily
fconvert(F_to::Type{Daily}, MIT_from::MIT{<:Union{<:Weekly,<:YPFrequency}}; values_base=:end, round_to=:current) = daily(Dates.Date(MIT_from, values_base))
function fconvert(F_to::Type{<:Daily}, MIT_from::MIT{BDaily}; values_base=:end, round_to=:current)
    mod = Int(MIT_from) % 5
    if mod == 0
        mod = 5
    end
    return MIT{F_to}(Int(floor((Int(MIT_from) - 1) / 5) * 7 + mod))
end


"""
fconvert_parts(F_to::Type{<:Union{<:YPFrequency}}, MIT_from::MIT{<:Union{<:YPFrequency}}; values_base=:end, check_parameter_from=false, check_parameter_to=false)

This is a helper function used when converting TSeries or MIT UnitRanges between YPfrequencies. It provides the necessary component parts to make decisions about the completeness
    of the input tseries relative to the output frequency.
"""
function fconvert_parts(F_to::Type{<:Union{<:YPFrequency}}, MIT_from::MIT{<:Union{<:YPFrequency}}; values_base=:end)
    F_from = frequencyof(MIT_from)
    F_to = sanitize_frequency(F_to)
    mpp_from = div( 12, ppy(F_from))
    mpp_to = div( 12, ppy(F_to))

    from_month_adjustment = endperiod(F_from) - mpp_from
    to_month_adjustment = endperiod(F_to) - mpp_to

    if values_base == :begin
        from_start_month = Int(MIT_from) * mpp_from + 1 + from_month_adjustment
        to_period, rem = divrem(from_start_month - to_month_adjustment - 1,  mpp_to)
        to_start_month = to_period * mpp_to + 1 + to_month_adjustment
        return to_period, from_start_month, to_start_month
    elseif values_base == :end
        from_end_month = (Int(MIT_from) + 1) * mpp_from + from_month_adjustment
        to_period, rem = divrem(from_end_month - to_month_adjustment - 1,  mpp_to)
        to_end_month = (to_period + 1) * mpp_to + to_month_adjustment
        return to_period, from_end_month, to_end_month
    end
end



######################
#     UNITRANGE
######################
"""
    fconvert(F_to, range_from::UnitRange{MIT})

Convert the time MIT `MIT_from` to the desired frequency `F_to`.
"""
fconvert(F_to::Type{<:Frequency}, range_from::UnitRange{MIT}; args...) = error("""
Conversion of MIT UnitRange from $(frequencyof(range_from)) to $F_to not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(F_to::Type{F}, range_from::UnitRange{MIT{F}}) where {F<:Frequency} = range_from

"""
fconvert(F_to::Type{<:Union{<:CalendarFrequency,<:YPFrequency}}, MIT_from::MIT{<:Union{<:CalendarFrequency,<:YPFrequency}}; trim=:both)

Converts a MIT UnitRange to the given target frequency.

`trim` determines whether to truncate the beginning/end of the output range whenever the input range begins / ends partway through an MIT
in the output frequency. The options are `:begin`, `:end`, and `:both`. The default is `:both`.

For example, 
fconvert(Quarterly, 2022Y:2024Y) ==> 2022Q1:2024Q4
fconvert(Quarterly, 2022M2:2022M7, trim=:begin) => 2022Q2:2022Q3
fconvert(Quarterly, 2022M2:2022M7, trim=:end) => 2022Q1:2022Q2
fconvert(Quarterly, 2022M2:2022M7, trim=:both) => 2022Q2:2022Q2
"""
# MIT range: YP => YP
function fconvert(F_to::Type{<:YPFrequency}, range_from::UnitRange{<:MIT{<:YPFrequency}}; trim=:both, parts=false)
    fi_to_period, fi_from_start_month, fi_to_start_month = fconvert_parts(sanitize_frequency(F_to), first(range_from), values_base=:begin)
    li_to_period, li_from_end_month, li_to_end_month = fconvert_parts(sanitize_frequency(F_to), last(range_from), values_base=:end)
    
    if parts
        return fi_to_period, fi_from_start_month, fi_to_start_month, li_to_period, li_from_end_month, li_to_end_month
    end

    F_from = frequencyof(range_from)
    mpp_from = div( 12, ppy(F_from))
    mpp_to = div( 12, ppy(F_to))

    trunc_start = 0
    trunc_end = 0
    if mpp_from > mpp_to # to higher frequency
        trunc_start = trim !== :end && fi_to_start_month < fi_from_start_month ? 1 : 0
        trunc_end = trim !== :begin && li_to_end_month > li_from_end_month ? 1 : 0
    else # to lower frequency
        if trim == :begin || trim == :both
            if fi_to_start_month < fi_from_start_month && fi_to_start_month <= fi_from_start_month - (mpp_from - 1)
                trunc_start = 1
            end
        end
        if trim == :end || trim == :both
            if li_to_end_month > li_from_end_month && li_to_end_month >= li_from_end_month + mpp_from - 1
                trunc_end = 1
            end
        end
    end
   

    fi = MIT{sanitize_frequency(F_to)}(fi_to_period+trunc_start)
    li = MIT{sanitize_frequency(F_to)}(li_to_period-trunc_end)
    
    return fi:li
end


# range: YP + Calendar => YP + Weekly (excl. YP => YP)
fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, range_from::UnitRange{<:MIT{<:Union{Daily, BDaily, <:Weekly}}}; trim=:both, errors=true) = _fconvert_using_dates(sanitize_frequency(F_to), range_from, trim=trim, errors=errors)
fconvert(F_to::Type{<:Union{<:Weekly}}, range_from::UnitRange{<:MIT{<:Union{<:YPFrequency}}}; trim=:both, errors=true) = _fconvert_using_dates(F_to, range_from, trim=trim, errors=errors)
function _fconvert_using_dates(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, range_from::UnitRange{<:MIT{<:Union{<:CalendarFrequency}}}; trim=:both, errors=true)
    fi, li, trunc_start, trunc_end = _fconvert_using_dates_parts(F_to, range_from, trim=trim, errors=errors)
    return fi+trunc_start:li-trunc_end
end


# MITRange => Daily
fconvert(F_to::Type{Daily}, range_from::UnitRange{<:MIT{<:Union{<:Weekly,Daily,<:YPFrequency}}}) = daily(Dates.Date(range_from[begin] - 1) + Day(1)):daily(Dates.Date(range_from[end]))
fconvert(F_to::Type{<:Daily}, range_from::UnitRange{MIT{BDaily}}) = daily(Dates.Date(range_from[begin])):daily(Dates.Date(range_from[end]))

# MITRange => BDaily
fconvert(F_to::Type{BDaily}, range_from::UnitRange{<:MIT{<:Union{<:CalendarFrequency}}}) = bdaily(Dates.Date(range_from[begin] - 1) + Day(1), bias=:next):bdaily(Dates.Date(range_from[end]), bias=:previous)

# MIT range: YP + Calendar => YP + Weekly
function _fconvert_using_dates_parts(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, range_from::UnitRange{<:MIT{<:Union{<:CalendarFrequency}}}; trim=:both, errors=true, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}} = nothing)
    errors && _validate_fconvert_yp(F_to, frequencyof(first(range_from)))
    if errors && trim ∉ (:both, :begin, :end)
        throw(ArgumentError("trim argument must be :both, :begin, or :end. Received: $(trim)."))
    end
    F_from = frequencyof(range_from)
    if F_to > F_from # to higher frequency
        if F_from <: BDaily
            dates = [Dates.Date(range_from[begin]), Dates.Date(range_from[end])]
            if holidays_map !== nothing
                dates = dates[holidays_map[rng_from].values]
            elseif skip_holidays
                holidays_map = get_option(:bdaily_holidays_map)
                dates = dates[holidays_map[rng_from].values]
            end
        else
            dates = [Dates.Date(range_from[begin] - 1) + Day(1), Dates.Date(range_from[end])]
        end
        out_index = _get_out_indices(F_to, dates)
        fi = out_index[1]
        trunc_start = 0
        # truncate the start if the first output period does not start within the first input period
        if trim !== :end && fconvert(F_from, fi, values_base=:begin) != range_from[begin] 
            trunc_start = 1
        end
        
        li = out_index[end]
        trunc_end = 0
        # truncate the end if the last output period ends in an input period beyond the last
        if trim !== :begin && fconvert(F_from,li, values_base=:end) != range_from[end]
            trunc_end = 1
        end
        return fi, li, trunc_start, trunc_end
    else # F_to <= F_from, to lower frequency
        if F_from <: BDaily
            if skip_holidays == true || holidays_map !== nothing
                if holidays_map === nothing
                    holidays_map = getoption(:bdaily_holidays_map)
                end
                padded_dates = padded_dates[holidays_map[rng_from].values]
                # find the nearest non-holidays to see if they are in a different output period
                pad_start_date = first(rng_from) - 1
                while holidays_map[proposed_pad_start_date] == 0
                    pad_start_date = pad_start_date - 1
                end
                pad_end_date = last(rng_from) + 1
                while holidays_map[pad_end_date] == 0
                    pad_end_date = pad_end_date + 1
                end
                padded_dates = [pad_start_date, padded_dates..., pad_end_date]
            else
                padded_dates = [Dates.Date(range_from[begin] - 1), Dates.Date(range_from[begin]), Dates.Date(range_from[end]), Dates.Date(range_from[end] + 1)]
            end
        else
            if F_to > F_from
                padded_dates = [
                    Dates.Date(range_from[begin] - 1, :begin),
                    Dates.Date(range_from[begin], :begin), 
                    Dates.Date(range_from[end]), 
                    Dates.Date(range_from[end] + 1)
                ]
            else #F_to == F_from
                padded_dates = [
                    Dates.Date(range_from[begin] - 1), 
                    Dates.Date(range_from[begin]), 
                    Dates.Date(range_from[end]), 
                    Dates.Date(range_from[end] + 1)]
            end
        end
        out_index = _get_out_indices(F_to, padded_dates)
        
        # if the first default and padded output periods are the same, then we do not have
        # the whole of the first output period
        fi = out_index[2]
        trunc_start = 0
        # truncate the start if the padded output period is the same as the first output period
        # in this case we do not have the whole of the first output period in the inputs
        if trim !== :end && out_index[1] == out_index[2]
            trunc_start = 1
        end
        li = out_index[end-1]
        trunc_end = 0
        # truncate the end if the padded end period is the same as the last output period
        # in this case we do not have the whole of the last period in the inputs
        if trim !== :begin && out_index[end] == out_index[end-1]
            trunc_end = 1
        end
        return fi, li, trunc_start, trunc_end
    end
end
