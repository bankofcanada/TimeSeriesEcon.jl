# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

"""
repeat_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer})

Returns a vector of length `length(x) * sum(inner)` where each value in `x`
is repeated a number of times equal to the same-index position in the vector
`inner`.

`> repeat_uneven([1,2,4], [2,1,4])`
[1, 1, 2, 4, 4, 4, 4]
"""
function repeat_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer}; kwargs...)
    out = typeof(x)(undef, sum(inner))
    pos = 1
    for i in 1:length(x)
        out[pos:pos+inner[i]-1] .= x[i]
        pos += inner[i]
    end
    return out
end
export(repeat_uneven)

"""
divide_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer})

Returns a vector of length `length(x) * sum(inner)` where each value in `x`
is divided by the the same-index position value in the vector `inner` and the resulting
value is repeated a number of times equal to the inner value.

Example:
`> divide_uneven([1,2,4], [2,1,4])`
[0.5, 0.5, 2.0, 1, 1, 1, 1]
"""
function divide_uneven(x::AbstractArray{<:Number}, inner::Vector{<:Integer}; kwargs...)
    out = typeof(x/1.0)(undef, sum(inner))
    pos = 1
    for i in 1:length(x)
        out[pos:pos+inner[i]-1] .= x[i] / inner[i]
        pos += inner[i]
    end
    return out
end
export(divide_uneven)

linear_uneven(x::AbstractArray{<:Number}, output_lengths::Vector{<:Integer}; ref=:end, kwargs...) = linear_uneven(x, output_lengths, Val(ref); kwargs...)
function linear_uneven(x::AbstractArray{<:Number}, output_lengths::Vector{<:Integer}, ref::Val{:end}; kwargs...)
    out_vals = Vector{Float64}(undef, sum(output_lengths))
    current_index = 1
    for (i,len) in enumerate(output_lengths)
        if i == 1
            step_size = (x[i+1] - x[i]) / output_lengths[i+1]
            vals = collect(LinRange(
                x[i] - output_lengths[i]*step_size,
                x[i],
                output_lengths[i]+1
            ))
            out_vals[current_index:current_index+output_lengths[i]-1] = vals[2:end]
            current_index += output_lengths[i]
        else
            vals = collect(LinRange(x[i-1], x[i], output_lengths[i]+1))
            out_vals[current_index:current_index+output_lengths[i]-1] = vals[2:end]
            current_index += output_lengths[i]
        end
    end
    return out_vals
end
function linear_uneven(x::AbstractArray{<:Number}, output_lengths::Vector{<:Integer}, ref::Val{:begin}; kwargs...)
    out_vals = Vector{Float64}(undef, sum(output_lengths))
    current_index = 1
    for (i,len) in enumerate(output_lengths)
        if i == length(x)
            step_size = (x[i] - x[i-1]) / output_lengths[i-1]
            vals = collect(LinRange(
                x[i],
                x[i] + output_lengths[i]*step_size,
                output_lengths[i]+1
            ))
            out_vals[current_index:current_index+output_lengths[i]-1] = vals[1:end-1]
            current_index += output_lengths[i]
        else
            vals = collect(LinRange(x[i], x[i+1], output_lengths[i]+1))
            out_vals[current_index:current_index+output_lengths[i]-1] = vals[1:end-1]
            current_index += output_lengths[i]
        end
    end
    return out_vals
end


# no docstring needed
function _valid_range(t::TSeries)
    fd = firstdate(t)
    ld = lastdate(t)
    while fd <= ld && istypenan(t[ld])
        ld -= 1
    end
    while fd <= ld && istypenan(t[fd])
        fd += 1
    end
    return fd:ld
end

"""
    strip(t:TSeries)

Remove leading and trailing `NaN` from the given time series. This version
creates a new [`TSeries`](@ref) instance.
"""
Base.strip(t::TSeries) = getindex(t, _valid_range(t))
"""
    strip!(t::TSeries)

Remove leading and training `NaN` from the given time series. This is
done in-place.
"""
strip!(t::TSeries) = resize!(t, _valid_range(t))
export strip!

#### BDaily helpers

"""
skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing} = nothing)

    Skips nans in a vector if either the provided nans option is true or if no nans option is
    passed and the :bdaily_skip_nans option is true.

    Returns the original vector otherwise.
"""
function skip_if_warranted(x::AbstractArray{<:Number}, nans::Union{Bool,Nothing}=nothing, bypass::Bool=false)
    if !bypass && (nans == true || (nans === nothing && get_option(:bdaily_skip_nans)))
        ret = filter(y -> !isnan(y), x)
        if size(ret)[1] == 0
            return [NaN]
        end
        return ret
    end
    return x
end


"""
    _get_out_indices(F_to::Type{<:Union{Monthly, Quarterly{N1}, Quarterly, Yearly{N2}, Yearly, Weekly, Weekly{N3}}}, dates::Vector{Dates.Date})

Takes an array of dates and returns an array of MITs of the `F_to` frequency corresponding to each date.
"""
_get_out_indices(F_to::Type{<:Union{Quarterly{NtQ},HalfYearly{NtH},Yearly{NtY},Weekly{NtW}}}, dates::Vector{Dates.Date}) where {NtQ,NtH,NtY,NtW} = _get_out_indices_actual(F_to, dates, check_parameter_to=true)
_get_out_indices(F_to::Type{<:Union{Monthly,Quarterly,HalfYearly,Yearly,Weekly}}, dates::Vector{Dates.Date}) = _get_out_indices_actual(F_to, dates, check_parameter_to=false)
function _get_out_indices_actual(F_to::Type{<:Union{Monthly,Quarterly{NtQ},Quarterly,HalfYearly{NtH},HalfYearly,Yearly{NtY},Yearly,Weekly,Weekly{NtW}}}, dates::Vector{Dates.Date}; check_parameter_to=false) where {NtQ,NtH,NtY,NtW}
    months = Dates.month.(dates)
    years = Dates.year.(dates)
    
    if F_to <: Weekly
        end_day = endperiod(sanitize_frequency(F_to))
        out_index = [weekly(date, end_day) for date in dates]
    else
        months = Dates.month.(dates)
        years = Dates.year.(dates)
    end

    if F_to <: Monthly
        out_index = [MIT{F_to}(year, month) for (year, month) in zip(years, months)]
    elseif F_to <: Quarterly
        if check_parameter_to
            months .+= (3 - NtQ)
            years[months.>12] .+= 1
            months[months.>12] .-= 12
        end
        quarters = [Int(ceil(m / 3)) for m in months]
        out_index = [MIT{F_to}(year, quarter) for (year, quarter) in zip(years, quarters)]
    elseif F_to <: HalfYearly
        if check_parameter_to
            months .+= (6 - NtH)
            years[months.>12] .+= 1
            months[months.>12] .-= 12
        end
        halfyears = [Int(ceil(m / 6)) for m in months]
        out_index = [MIT{F_to}(year, half) for (year, half) in zip(years, halfyears)]
    elseif F_to <: Yearly
        if check_parameter_to
            months .+= 12 - NtY
            years[months.>12] .+= 1
        end
        out_index = [MIT{F_to}(year) for year in years]
    end
    return out_index
end

function get_start_truncation_yp(ref::Val{:end}, require::Val{:single}, fi_from_start_month::Int64, fi_to_start_month::Int64, mpp_from::Int64, mpp_to::Int64)
     # we just need the first data point in the input series to feed 
    # into the first MIT in the output series
    if fi_from_start_month + (mpp_from - 1) <= fi_to_start_month + (mpp_to - 1) 
        return 0 # don't trim
    else
        return 1 #trim
    end
end
function get_start_truncation_yp(ref::Val{:end}, require::Val{:all}, fi_from_start_month::Int64, fi_to_start_month::Int64, mpp_from::Int64, mpp_to::Int64)
    # we need the first data point in the input series to either
    # a) start at the same month as the output MIT
    # b) have it's first month outside of the first output MIT and last month 
    # inside
    if fi_from_start_month == fi_to_start_month
        return 0 # don't trim
    elseif fi_from_start_month < fi_to_start_month && fi_from_start_month + (mpp_from - 1) >= fi_to_start_month
        return 0 # don't trim
    else
        return 1 # trim
    end
end
function get_start_truncation_yp(ref::Val{:begin}, require::Val{:single}, fi_from_start_month::Int64, fi_to_start_month::Int64, mpp_from::Int64, mpp_to::Int64)
    # we need the first data point in the input series to either
    # a) start at the same month as the output MIT
    # b) have it's first month outside of the first output MIT and last month 
    # inside
    if fi_from_start_month == fi_to_start_month
        return 0 # don't trim
    elseif fi_from_start_month < fi_to_start_month && fi_from_start_month + (mpp_from - 1) >= fi_to_start_month
        return 0 # don't trim
    else
        return 1 #trim
    end
end
function get_start_truncation_yp(ref::Val{:begin}, require::Val{:all}, fi_from_start_month::Int64, fi_to_start_month::Int64, mpp_from::Int64, mpp_to::Int64)
    # we need the first data point in the input series to either 
    # a) start at the same month as th eoutput MIT
    # b) start within the output MIT but not a full input period from the start
    if fi_from_start_month == fi_to_start_month
        return 0 # don't trim
    elseif fi_from_start_month > fi_to_start_month && fi_from_start_month - (mpp_from - 1) <= fi_to_start_month
        return 0 # don't trim
    else
        return 1 # trim
    end
end


function get_end_truncation_yp(ref::Val{:end}, require::Val{:single}, li_from_end_month::Int64, li_to_end_month::Int64, mpp_from::Int64, mpp_to::Int64)    
    # we need the last data point to either
    # a) land on the last month of the output range
    # b) land before the last month, but not an entire period before
    if li_from_end_month == li_to_end_month
        return 0 # don't trim
    elseif li_from_end_month < li_to_end_month && li_from_end_month + (mpp_from-1) >= li_to_end_month
        return 0 # don't trim
    else
        return 1 # trim
    end
  
end
function get_end_truncation_yp(ref::Val{:end}, require::Val{:all}, li_from_end_month::Int64, li_to_end_month::Int64, mpp_from::Int64, mpp_to::Int64)    
    # we need the last data point to either
    # a) land on the last month of the output range
    # b) land before the last month, but not an entire period before
    if li_from_end_month == li_to_end_month
        return 0 # don't trim
    elseif li_from_end_month < li_to_end_month && li_from_end_month + (mpp_from-1) >= li_to_end_month
        return 0 # don't trim
    else
        return 1 # trim
    end
end
function get_end_truncation_yp(ref::Val{:begin}, require::Val{:single}, li_from_end_month::Int64, li_to_end_month::Int64, mpp_from::Int64, mpp_to::Int64)
    # we need the last data point to either
    # a) land after the first month of the output period
    # b) land before the first month but not an entire period before
    if li_from_end_month - (mpp_from - 1) >= li_to_end_month - (mpp_to - 1)
        return 0 # don't trim
    elseif li_from_end_month - (mpp_from - 1) < li_to_end_month - (mpp_to - 1) && li_from_end_month  >= li_to_end_month - (mpp_to - 1) 
        return 0 # don't trim
    else
        return 1 # trim
    end
end
function get_end_truncation_yp(ref::Val{:begin}, require::Val{:all}, li_from_end_month::Int64, li_to_end_month::Int64, mpp_from::Int64, mpp_to::Int64)
    # we need the last input period to start on or before the end of the last output period
    if li_from_end_month > li_to_end_month && li_from_end_month - (mpp_from - 1) <= li_to_end_month
        return 0 # don't trim
    else
        return 1 # trim
    end
end

"""
    extend_series(F_to::Type{<:Frequency}, ts::TSeries; direction=:both, method=:mean)

    This function pads the ends of a series to match a given frequency. An example would be extending a BDaily
    TSeries to the ends of the Quarters in which the end dates fall. There are two keyword arguments:

    * `method` - Determines the value to use in the extension. Default is the `:mean`, which will use the mean of the 
        existing values in the given period. The other available option is `:end` which will use the first value when
        extending the start of a series and the last value when extending the end of a series.
"""
extend_series(F_to::Type{<:Frequency}, ts::TSeries; direction=:both, method=:mean) = extend_series!(F_to, copy(ts), Val(direction); method=method)
extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:end}; method=:mean) = extend_series!(F_to, ts, direction, Val(method))
extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:begin}; method=:mean) = extend_series!(F_to, ts, direction, Val(method))
function extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:both}; method=:mean) 
    extend_series!(F_to, ts, Val(:begin), Val(method))
    extend_series!(F_to, ts, Val(:end), Val(method))
    ts
end
function extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:begin}, method::Val{:end}) 
    F_from = frequencyof(ts)
    first_mit_in_output_freq = fconvert(F_to, first(rangeof(ts)))
    desired_first_mit = fconvert(F_from, first_mit_in_output_freq, ref=:begin)
    affected_range = desired_first_mit:first(rangeof(ts))-1
    if length(affected_range) >= 1
        if frequencyof(ts) == BDaily
            ts[affected_range] .= cleanedvalues(ts; skip_all_nans=true)[begin]
        else
            ts[affected_range] .= ts[first(affected_range)+1]
        end
    end
    ts
end
function extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:begin}, method::Val{:mean}) 
    F_from = frequencyof(ts)
    first_mit_in_output_freq = fconvert(F_to, first(rangeof(ts)))
    desired_first_mit = fconvert(F_from, first_mit_in_output_freq, ref=:begin)
    affected_range = desired_first_mit:first(rangeof(ts))-1
    if length(affected_range) >= 1
        data_basis = fconvert(F_from, first_mit_in_output_freq:first_mit_in_output_freq)
        data_basis = intersect(data_basis, rangeof(ts))
        if F_from == BDaily
            ts[affected_range] .= mean(cleanedvalues(ts[data_basis]; skip_all_nans = true))    
        else
            ts[affected_range] .= mean(ts[data_basis])    
        end
    end
    ts
end
function extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:end}, method::Val{:end}) 
    F_from = frequencyof(ts)
    last_mit_in_output_freq = fconvert(F_to, last(rangeof(ts)))
    desired_last_mit = fconvert(F_from, last_mit_in_output_freq, ref=:end)
    affected_range = (last(rangeof(ts))+1):desired_last_mit
    if length(affected_range) >= 1
        if frequencyof(ts) == BDaily
            ts[affected_range] .= cleanedvalues(ts; skip_all_nans=true)[end]
        else
            ts[affected_range] .= ts[first(affected_range)-1]
        end
    end
    ts
end
function extend_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:end}, method::Val{:mean}) 
    F_from = frequencyof(ts)
    last_mit_in_output_freq = fconvert(F_to, last(rangeof(ts)))
    desired_last_mit = fconvert(F_from, last_mit_in_output_freq, ref=:end)
    affected_range = (last(rangeof(ts))+1):desired_last_mit
    if length(affected_range) >= 1
        data_basis = fconvert(F_from, last_mit_in_output_freq:last_mit_in_output_freq)
        data_basis = intersect(data_basis, rangeof(ts))
        if F_from == BDaily
            ts[affected_range] .= mean(cleanedvalues(ts[data_basis]; skip_all_nans = true))    
        else
            ts[affected_range] .= mean(ts[data_basis])    
        end
    end
    ts
end
export extend_series


# trim_series(F_to::Type{<:Frequency}, ts::TSeries; direction=:both) = extend_series!(F_to, copy(ts), Val(direction))
trim_series(F_to::Type{<:Frequency}, ts::TSeries; direction=:both) = ts[fconvert(frequencyof(ts), fconvert(F_to, rangeof(ts), trim=direction))]
export trim_series

# trim_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:end})

# trim_series!(F_to::Type{<:Frequency}, ts::TSeries, direction::Val{:begin})

# function trim_series(F_to::Type{<:Frequency}, ts::TSeries; direction=:both)
# end