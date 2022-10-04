
"""
fconvert((F::Type{<:Daily}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:const, interpolation=:none)

Convert the Weekly time series `t` to a daily time series.

The only supported method is currently :const.

When interpolation is :linear values are interpolated in a linear fashion across days between weeks.
The recorded weekly value is ascribed to the midpoint of the week. I.e. Thursdays for weeks ending on Sundays, Wednesdays
for weeks ending on Saturdays, etc. This is done to be consistent with the handling in FAME.
For days beyond these midpoints, the linear line between the first two or last two weeks is extended to cover the entire day range.

For BusinessDaily frequencies this approach differs from the approach in FAME which interpolates for all weekdays and then drops weekends. 
To replicate that approach, first convert your weekly series to a Daily series:

`fconvert(BusinessDaily, fconvert(Daily, t, method=:linear))`

"""
function fconvert(F::Type{<:Union{Daily, BusinessDaily}}, t::Union{TSeries{Weekly{N3}},TSeries{Weekly}}; method=:const, values_base=:end) where{N3}
np = F == BusinessDaily ? 5 : 7
reference_day_adjust = 0
if @isdefined N3
    if F == BusinessDaily && N3 <= 4
        reference_day_adjust = 5 - N3
    elseif F == Daily
        reference_day_adjust = np - N3
    end
end

fi = MIT{F}(Int(firstindex(t))*np - (np-1) - reference_day_adjust)    

if method == :const
    return TSeries(fi, repeat(t.values, inner=np))
elseif method == :linear
    values = repeat(t.values, inner=np)
    val_day = F == Daily ? 4 : 3 # thursday for weekly, wednesday for businessdaily
    if values_base == :beginning
        val_day = 1
    elseif values_base == :end
        val_day = np
    end
    
    interpolation = nothing
    max_i = length(t.values)
    for i in 1:max_i
        if i < max_i
            interpolation = collect(LinRange(t.values[i], t.values[i+1], np+1))
        end
        if i == 1
            values[i:val_day] .= interpolation[np+1-val_day + 1:np+1] .- interpolation[1]
        end
        if i != max_i
            values[val_day + (i-1)*np + 1:val_day + i*np] .= interpolation[2:np+1]
        else
            values[end-(np-val_day):end] .= interpolation[1:np+1-val_day] .+ (interpolation[np+1] - interpolation[1])
        end
    end
    return TSeries(fi, values)
else
    throw(ArgumentError("Conversion method not available: $(method)."))
end
end

    
"""values_base has no purpose here"""
function fconvert(F::Type{<:Union{Daily,BusinessDaily}}, t::TSeries{<:YPFrequency}; method=:const, values_base=:end)
    date_function = F == BusinessDaily ? bdaily : daily
    d = Dates.Date(t.firstdate - 1) + Day(1)
    fi = date_function(Dates.Date(t.firstdate - 1) + Day(1), false)
    d2 = Dates.Date(rangeof(t)[end])
    li = date_function(Dates.Date(rangeof(t)[end]))
    ts = TSeries(fi:li)
    if values_base ∉ (:end, :beginning)
        throw(ArgumentError("values_base argument must be :beginning or :end."))
    end
    if method == :const
        for m in rangeof(t)
            fi_loop = date_function(Dates.Date(m-1) + Day(1), false)
            li_loop = date_function(Dates.Date(m))
            ts[fi_loop:li_loop] = repeat([t[m]], inner=length(fi_loop:li_loop))
        end
        return ts
    elseif method == :linear
        for m in reverse(rangeof(t))
            fi_loop = date_function(Dates.Date(m-1) + Day(1), false)
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


"""values_base only works with method=:const"""
function fconvert(F::Type{<:Union{Weekly, Weekly{N}}}, t::TSeries{<:YPFrequency}; method=:const, values_base=:end) where N
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
    if values_base ∉ (:end, :beginning)
        throw(ArgumentError("values_base argument must be :beginning or :end."))
    end
    if method == :const
        loop_range = values_base == :end ? rangeof(t) : reverse(rangeof(t))
        for m in loop_range 
            fi_loop = weekly(Dates.Date(m-1) + Day(1), N_effective, normalize)
            li_loop = weekly(Dates.Date(m), N_effective, normalize)
            ts[fi_loop:li_loop] = repeat([t[m]], inner=length(fi_loop:li_loop))
        end
        return ts
    elseif method == :linear
        last_fi_loop = nothing
        for m in reverse(rangeof(t))
            fi_loop = weekly(Dates.Date(m-1) + Day(1), N_effective, normalize)
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
    fconvert(F::Type{<:Daily}, t::TSeries{BusinessDaily}; method=:const, interpolation=:none)

Convert a BusinessDaily timeseries to a Daily time series covering the same date range.

By default, weekend values will be filled with NaNs. Use the `interpolation` option to change this behavior:
`:previous`: Fill weekends with the value on the day before the weekend.
`:next`: Fill weekends with the value on the day after the weekend.
`:linear`: Fill weekends with values interpolated between the day before and the day after the weekend.
"""
function fconvert(F_to::Type{<:Daily}, t::TSeries{BusinessDaily}; method=:const, interpolation=:none)
    fi = fconvert(F_to, firstdate(t))
    li = fconvert(F_to, lastdate(t))
    
    out_length = Int(li) - Int(fi) + 1
    if interpolation == :none || any(isnan.(t.values))
        out_values = Array{Number}(undef, (out_length,))
    elseif interpolation == :linear
        out_values = Array{Float64}(undef, (out_length,))
    else
        out_values = Array{eltype(t.values)}(undef, (out_length,))
    end
    shift = Int(firstdate(t)) % 5
    input_position = 1
    last_valid = NaN
    for k in 1:out_length
        mod = (k + shift - 1) % 7
        if mod < 6 && mod > 0
            out_values[k] = t.values[input_position]
            last_valid = t.values[input_position]
            input_position += 1
        else
            if interpolation == :previous
                out_values[k] = t.values[input_position-1]
            elseif interpolation == :next
                out_values[k] = t.values[input_position]
            elseif interpolation == :linear
                inter = LinRange(t.values[input_position]-1, t.values[input_position], 4)
                if mod == 6
                    out_values[k] = inter[2]
                else
                    out_values[k] = inter[3]
                end
            else
                out_values[k] = NaN
            end
            
        end
    end
    
    return TSeries(fi, out_values)
end
