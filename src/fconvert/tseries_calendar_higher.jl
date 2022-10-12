"""
Weekly => Daily/Business
    options: method = const/linear, values_base = end/begin/middle
YP => Daily/Business
    options: method = const/linear, values_base = end/begin
YP => Weekly
    options: method = const/linear, values_base = end/begin
Business => Daily
    options: method = const/linear, values_base = end/begin/middle

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



