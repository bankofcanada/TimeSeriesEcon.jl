"""
MIT:
Calendar => YP/Weekly
    values_base=:end/:begin, round_to=:current/:next/:previous

Weekly/YP ==> Daily
    options: None
Weekly/YP/Daily => Business
    options: round_to=:previous/:next/:current
Business ==> Daily
    options: None

YP ==> YP ()


======================== REFACTORED ===============================
UnitRange{MIT}
Calendar/YP => YP/Weekly
    options: trim = :both/:begin/:end
Calendar/YP => Business
    options: None
Weekly/Daily/YP => Daily
    options: None
Business => Daily
    options: None
"""


"""
fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, MIT_from::MIT{<:Union{<:CalendarFrequency,<:YPFrequency}}; values_base = :end, round_to=:current)

Converts a MIT instance to the given target frequency. There are two optional arguments.

`values_base` determines the position within the input frequency to align with the output frequency. The options are `:begin`, `:end`. The default is `:end`.

For example, 
fconvert(Quarterly, 22Y, values_base=:end) ==> 22Q4
fconvert(Quarterly, 22Y, values_base=:begin) ==> 2022Q1

`round_to` determines which period to select when the beginnings or ends of the provided MITs do 
not align. The behavior depends on the `values_base` argument.

The default is `:current`: the output period will be which contains the end/start-date of the 
input period (according to the `values_base` argument).

When values_base is :end and round_to is :previous then the output period will be the one immediately
preceeding the output period within which falls the end-date of the input period, unless this end-date 
aligns with the end-date of an output period.
When values_base is :end and round_to is :next then the output will be the same as with 
round_to = :current.

When values_base is :begin and round_to is :next, then the output period will be the one immediately 
following output period within which falls the start-date of the input period, unless this start-date
aligns with the start-date of an output period.
When values_base is :begin and round_to is :previous then the output will be the same as with 
round_to = :current.

"""
function fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, MIT_from::MIT{<:Union{<:CalendarFrequency,<:YPFrequency}}; values_base=:end, round_to=:current)
    # simple case
    if round_to == :current && values_base == :end
        return _get_out_indices(F_to, [Dates.Date(MIT_from)])[begin]
    elseif round_to == :current && values_base == :begin
        return _get_out_indices(F_to, [Dates.Date(MIT_from - 1) + Day(1)])[begin]
    end

    # error checking
    if values_base ∉ (:end, :begin)
        throw(ArgumentError("values_base argument must be :begin or :end. Received: $(values_base)."))
    end
    if round_to ∉ (:current, :previous, :next)
        throw(ArgumentError("round_to argument must be :current, :previous, or :next. Received: $(round_to)."))
    end

    # accounting for rounding
    dates = [Dates.Date(MIT_from - 1) + Day(1), Dates.Date(MIT_from)]
    out_index = _get_out_indices(F_to, dates)
    include_weekends = frequencyof(MIT_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(MIT_from), dates, :both, include_weekends=include_weekends, shift_input=false, pad_input=false)

    # values_base == :begin ==> check if the start of p1 is at the start of p2
    if values_base == :begin && (trunc_start == 0 || round_to == :current)
        # no need to round
        return out_index[begin]
    elseif values_base == :begin && round_to == :next
        # the start of MIT_from is after the start of the corresponding MIT_to
        # and we are biasing forward
        return out_index[begin] + 1
    elseif values_base == :begin && round_to == :previous
        # the start of MIT_from is after the start of the corresponding MIT_to
        # but we are biasing backwards so just return the period
        return out_index[begin]
    end

    # values_base == :end ==> check if the end of p1 is at the end of p2
    if values_base == :end && (trunc_end == 0 || round_to == :current)
        return out_index[end]
    elseif values_base == :end && round_to == :next
        # the end of the MIT_from comes before the end of the corresponding MIT_to
        # but we are biasing forwards so just return the period
        return out_index[end]
    elseif values_base == :end && round_to == :previous
        # the end of the MIT_from comes before the end of the corresponding MIT_to
        # and we are biasing backwards
        return out_index[end] - 1
    end
end

"""
    fconvert(F_to::Type{Daily}, MIT_from::MIT{<:Union{<:Weekly,<:YPFrequency}})

    Converts a MIT instance to a Daily frequency, based on the end-date of the provided MIT.
"""
fconvert(F_to::Type{Daily}, MIT_from::MIT{<:Union{<:Weekly,<:YPFrequency}}) = daily(Dates.Date(MIT_from))

"""
fconvert(F_to::Type{<:Daily}, MIT_from::MIT{BusinessDaily})

    Return a daily MIT from the end-date of the provided BusinessDaily MIT.
"""
function fconvert(F_to::Type{<:Daily}, MIT_from::MIT{BusinessDaily})
    mod = Int(MIT_from) % 5
    if mod == 0
        mod = 5
    end
    return MIT{F_to}(Int(floor((Int(MIT_from) - 1) / 5) * 7 + mod))
end

"""
fconvert(F_to::Type{BusinessDaily}, MIT_from::MIT{<:Union{<:Weekly, <:YPFrequency, Daily}}; round_to=:previous)

Converts a MIT instance to a BusinessDaily frequency. The optional parameter `round_to` determines which 
business day to return when the end-date of the input period falls on a weekend. The default behavior is `:previous`,
which returns the closest preceeding Friday. The other options are `:next` and `:current`.

Weekends will result in an ArgumentError when `:current` is provided.
"""
function fconvert(F_to::Type{BusinessDaily}, MIT_from::MIT{<:Union{<:Weekly,<:YPFrequency,Daily}}; round_to=:previous)
    if round_to == :previous
        return bdaily(Dates.Date(MIT_from))
    elseif round_to == :next
        return bdaily(Dates.Date(MIT_from); bias_previous=false)
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


"""
fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, range_from::UnitRange{<:MIT{<:Union{<:CalendarFrequency, <:YPFrequency}}}; trim = :both, errors=true)

Converts a provided MIT UnitRange to a YPFrequency or a Weekly frequency.

the `trim` argument determines which observations of the output frequency must be covered by the input range
:begin means that the end-date in each output period must be covered
:end means that the first date in each output period must be covered
:both means that both the first and last date in each output period must be covered.
Note: one can also pass :mean, :sum, which are equivalent to :both
"""
function fconvert(F_to::Type{<:Union{<:YPFrequency,<:Weekly}}, range_from::UnitRange{<:MIT{<:Union{<:CalendarFrequency,<:YPFrequency}}}; trim=:both, errors=true)
    errors && _validate_fconvert_yp(F_to, frequencyof(first(range_from)))
    if errors && trim ∉ (:both, :begin, :end)
        throw(ArgumentError("trim argument must be :both, :begin, or :end. Received: $(trim)."))
    end
    dates = [Dates.Date(range_from[begin] - 1) + Day(1), Dates.Date(range_from[end])]
    out_index = _get_out_indices(F_to, dates)
    include_weekends = frequencyof(range_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(range_from), dates, trim, include_weekends=include_weekends, shift_input=false, pad_input=false)
    return out_index[begin]+trunc_start:out_index[end]-trunc_end
end

fconvert(F_to::Type{Daily}, range_from::UnitRange{<:MIT{<:Union{<:Weekly,Daily,<:YPFrequency}}}) = daily(Dates.Date(range_from[begin] - 1) + Day(1)):daily(Dates.Date(range_from[end]))
fconvert(F_to::Type{<:Daily}, range_from::UnitRange{MIT{BusinessDaily}}) = daily(Dates.Date(range_from[begin])):daily(Dates.Date(range_from[end]))
fconvert(F_to::Type{BusinessDaily}, range_from::UnitRange{<:MIT{<:Union{<:CalendarFrequency,<:YPFrequency}}}) = bdaily(Dates.Date(range_from[begin] - 1) + Day(1), false):bdaily(Dates.Date(range_from[end]), true)

