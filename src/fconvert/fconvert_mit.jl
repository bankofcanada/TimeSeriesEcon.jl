"""
fconvert(F1, x::Union{MIT{F2},UnitRange{MIT{F2}}}; round_to=nothing, values_base=nothing) where {F1 <: YPFrequency, F2 <: YPFrequency}

Converts an MIT or a range of MITs to a different YPFrequency.

The optional `values_base` argument is as the conversion for a time series.

The optional `round_to` argument is used in conversions of single MITs to a lower frequency. 
It determines where to shift the output MIT to in cases where the input MIT is in between periods of the output frequency. 
The default is :current (provides the output period within which lies provided MIT).
:next provides the output period following the one in which the provided MIT lands except when the provided MIT is at the start of its current period.
:previous provides the output period preceeding the one in which the provided MIT lands except when the provided MIT is at the end of its current period.

"""
function fconvert(F_to::Type{<:YPFrequency{N1}}, Inst_from::Union{<:MIT{<:YPFrequency{N2}},<:UnitRange{<:MIT{<:YPFrequency{N2}}}}; round_to = nothing, values_base = nothing) where {N1,N2}
    args = Dict()
    if values_base !== nothing
        args[:values_base] = values_base
    end
    if round_to !== nothing
        args[:round_to] = round_to
    end
    N1 > N2 ? _to_higher(F_to, Inst_from; args...) : _to_lower(F_to, Inst_from; args...)
end


"""
    _to_higher(F_to, UnitRange{MIT{F_from}}; values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT range to a higher frequency. 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    For the `values_base` argument see [`fconvert`](@ref)]
"""
function _to_higher(F_to::Type{<:YPFrequency{N1}}, range::UnitRange{<:MIT{<:YPFrequency{N2}}}; values_base = :end, errors = true, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(first(range)))
    (np, r) = divrem(N1, N2)
    fi = _to_higher(F_to, first(range), values_base = values_base, errors = false)
    li = fi + np * length(range) - 1
    return fi:li
end

"""
    _to_higher(F_to, MIT{F_from}; values_base=:end, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT to a higher frequency. 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    For the `values_base` argument see [`fconvert`](@ref)]
"""
# yearly to quarterly
function _to_higher(F_to::Type{<:YPFrequency{N1}}, MIT_from::MIT{<:YPFrequency{N2}}; values_base = :end, errors = true, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(MIT_from))
    (np, r) = divrem(N1, N2)
    shift_length = _get_shift_to_higher(F_to, frequencyof(MIT_from); values_base = values_base, errors = false)
    # np = number of periods of the destination frequency for each period of the source frequency
    (y1, p1) = mit2yp(MIT_from)
    fi = MIT{F_to}(y1, (p1 - 1) * np + 1) - shift_length
    return fi
end


"""
    _to_lower(F_to, UnitRange{MIT{F_from}}; errors=true, warning=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT range to a lower frequency. 
"""
function _to_lower(F_to::Type{<:YPFrequency{N1}}, range::UnitRange{<:MIT{<:YPFrequency{N2}}}; errors = true, warnings = true, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(first(range)))
    F_from = frequencyof(range)
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        #quarterly{1} to yearly
        """
        All the specialized YPFrequencies (Yearly{N}, Quarterly{N}) are based on some monthly shift.
        We therefore convert the series to monthly, before recalling fconvert on the output.
        """
        return fconvert(F_to, fconvert(Monthly, range))
    end
    fi, r1 = _to_lower(F_to, first(range); round_to = :next, errors = false, remainder = true)
    li, r2 = _to_lower(F_to, last(range); round_to = :previous, errors = false, remainder = true)
    if (r1 != 0 || r2 != 0) && warnings
        @warn "Range conversionfrom $(range) to $(F_to) has remainders: $r1, $r2."
    end
    return fi:li
end


"""
    _to_lower(F_to, TSeries{MIT{F_from}}; method=:mean, errors=true) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a TSeries to a lower frequency. 
"""
function _to_lower(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method = :mean, errors = true, args...) where {N1,N2}
    F_from = frequencyof(t)
    errors && _validate_fconvert_yp(F, F_from)
    (np, r) = divrem(N2, N1)
    if hasproperty(F_from, :parameters) && length(F_from.parameters) > 0
        #quarterly{1} to yearly
        """
        All the specialized YPFrequencies (Yearly{N}, Quarterly{N}) are based on some monthly shift.
        We therefore convert the series to monthly, before recalling fconvert on the output.
        """
        return fconvert(F, fconvert(Monthly, t), method = method)
    end
    fi, r1 = _to_lower(F, t.firstdate; round_to = :next, errors = false, remainder = true)
    li, r2 = _to_lower(F, last(rangeof(t)); round_to = :previous, errors = false, remainder = true)
    vals = t[begin+(r1>0)*(np-r1):end-(r2<np-1)*(1+r2)].values

    # println("vals = $vals")
    if method == :mean
        ret = mean(reshape(vals, np, :); dims = 1)
    elseif method == :sum
        ret = sum(reshape(vals, np, :); dims = 1)
    elseif method == :begin
        ret = reshape(vals, np, :)[begin, :]
    elseif method == :end
        ret = reshape(vals, np, :)[end, :]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
    return copyto!(TSeries(eltype(ret), fi:li), ret)
end

fconvert(F_to::Type{Daily}, MIT_from::MIT{<:Union{Weekly,Weekly{N}}}) where {N} = daily(Dates.Date(MIT_from))
fconvert(F_to::Type{BusinessDaily}, MIT_from::MIT{<:Union{Weekly,Weekly{N}}}) where {N} = bdaily(Dates.Date(MIT_from))

function fconvert(F_to::Type{<:Union{Daily,BusinessDaily}}, range_from::UnitRange{<:MIT{<:Union{Weekly,Weekly{N}}}}) where {N}
    np = F_to == Daily ? 7 : 5
    reference_day_adjust = 0
    if @isdefined N
        reference_day_adjust = np - N
    end
    fi = MIT{F_to}(Int(first(range_from)) * np - (np - 1) - reference_day_adjust)
    li = fi + np * (length(range_from) - 1)
    return fi:li
end

fconvert(F::Type{Daily}, mit::MIT{<:YPFrequency}) = daily(Dates.Date(mit))
fconvert(F::Type{BusinessDaily}, mit::MIT{<:YPFrequency}) = bdaily(Dates.Date(mit))
fconvert(F::Type{Daily}, range_from::UnitRange{<:MIT{<:YPFrequency}}) = daily(Dates.Date(range_from[begin] - 1) + Day(1)):daily(Dates.Date(range_from[end]))
fconvert(F::Type{BusinessDaily}, range_from::UnitRange{<:MIT{<:YPFrequency}}) = bdaily(Dates.Date(range_from[begin] - 1) + Day(1)):bdaily(Dates.Date(range_from[end]))


fconvert(F::Type{Weekly}, mit::MIT{<:YPFrequency}) = weekly(Dates.Date(mit))
fconvert(F::Type{Weekly{N}}, mit::MIT{<:YPFrequency}) where {N} = weekly(Dates.Date(mit), N)

fconvert(F::Type{Weekly}, range_from::UnitRange{<:MIT{<:YPFrequency}}) = weekly(Dates.Date(range_from[begin] - 1) + Day(1)):weekly(Dates.Date(range_from[end]))
fconvert(F::Type{Weekly{N}}, range_from::UnitRange{<:MIT{<:YPFrequency}}) where {N} = weekly(Dates.Date(range_from[begin] - 1) + Day(1), N):weekly(Dates.Date(range_from[end]), N)


function fconvert(F_to::Type{<:Daily}, MIT_from::MIT{BusinessDaily})
    mod = Int(MIT_from) % 5
    if mod == 0
        mod = 5
    end
    return MIT{F_to}(Int(floor((Int(MIT_from) - 1) / 5) * 7 + mod))
end
fconvert(F_to::Type{<:Daily}, range_from::UnitRange{MIT{BusinessDaily}}) = fconvert(F_to, first(range_from)):fconvert(F_to, last(range_from))


function fconvert(F_to::Type{<:BusinessDaily}, m::MIT{Daily})
    num_weekends = floor(Integer, Int(m) / 7)
    return MIT{BusinessDaily}(Int(m) - num_weekends * 2)
end
function fconvert(F_to::Type{<:BusinessDaily}, range::UnitRange{MIT{Daily}})
    num_weekends1 = floor(Integer, Int(range[begin]) / 7)
    num_weekends2 = floor(Integer, Int(range[end]) / 7)
    return MIT{BusinessDaily}(Int(range[begin]) - num_weekends1 * 2):MIT{BusinessDaily}(Int(range[end]) - num_weekends2 * 2)
end


"""
    _to_lower(F_to, MIT{F_from}; values_base=:beginning, errors=true, remainder=false) where {F_to <: YPFrequency, F_from <: YPFrequency}

    Convert a MIT to a lower frequency. 

    The optional `round_to` argument determines where to shift the output MIT to in cases where the input MIT is in between periods of the 
    output frequency. The default is :none (provides the output period within which lies provided MIT).
    :next provides the output period following the one in which the provided MIT lands except when the provided MIT is at the start of its current period.
    :previous provides the output period preceeding the one in which the provided MIT lands except when the provided MIT is at the end of its current period.

    Examples:
    _to_lower(Quarterly, 20M2, round_to=:current) = 20Q1
    _to_lower(Quarterly, 20M2, round_to=:next) = 20Q2
    _to_lower(Quarterly, 20M2, round_to=:previous) = 19Q4
    _to_lower(Quarterly, 20M3, round_to=:previous) = 20Q1
    _to_lower(Quarterly, 20M1, round_to=:next) = 20Q1

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.

    When passed the optional `remainder` argument as `true`, the function returns both the output period, and the remaining number of input periods not covered by the conversion.
    Default is `false`.
"""
function _to_lower(F_to::Type{<:YPFrequency{N1}}, MIT_from::MIT{<:YPFrequency{N2}}; round_to = :current, errors = true, remainder = false, args...) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, frequencyof(MIT_from))
    (np, r) = divrem(N2, N1)
    shift_length = _get_shift_to_lower(F_to, frequencyof(MIT_from), errors = false)
    (y1, p1) = mit2yp(MIT_from + shift_length)
    (d1, r1) = divrem(p1 - 1, np)
    mit = nothing
    if round_to == :next
        mit = MIT{F_to}(y1, d1 + 1) + (r1 > 0)
    elseif round_to == :previous
        mit = MIT{F_to}(y1, d1 + 1) - (r1 < np - 1)
    elseif round_to == :current
        mit = MIT{F_to}(y1, d1 + 1)
    else
        throw(ArgumentError("Unknown round_to: $(round_to). Should be :next or :previous, or :current."))
    end
    if remainder
        return mit, r1
    end
    return mit
end



function fconvert(F_to::Type{<:YPFrequency{N}}, range_from::UnitRange{<:MIT{<:YPFrequency{N}}}; method = :end) where {N}
    dates = [Dates.Date(val) for val in range_from]
    out_index = _get_out_indices(F_to, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    li = eval(Meta.parse("li = $(out_index[end])"))
    # include_weekends = frequencyof(MIT_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(range_from), dates, method, include_weekends = true)
    return fi+trunc_start:li-trunc_end
end

function fconvert(F_to::Type{<:YPFrequency{N}}, MIT_from::MIT{<:YPFrequency{N}}; round_to = :current) where {N}
    dates = [Dates.Date(MIT_from)]
    out_index = _get_out_indices(F_to, dates)
    fi = eval(Meta.parse("fi = $(out_index[begin])"))
    # include_weekends = frequencyof(MIT_from) <: BusinessDaily
    trunc_start, trunc_end = _get_fconvert_truncations(F_to, frequencyof(MIT_from), dates, :both, include_weekends = true)
    if round_to == :next
        return fi + trunc_start
    elseif round_to == :previous
        return fi - trunc_end
    else
        return fi
    end
end