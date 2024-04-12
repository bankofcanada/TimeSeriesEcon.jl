# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# augment arraymath.jl for TSeries

# These are operations that treat a TSeries as a single object (rather than a collection of values indexed by MIT)
# Conceptually we must distinguish these operations from broadcasting (element-wise) operations.

# For example, t + s is valid if t and s are of the same TSeries type (same frequency). 
# The result of t + s is a new TSeries of the same frequency over the common range.
# In practice t + s and t .+ s produce identical results, although conceptually they're different operations.
#
# t + n is not valid because TSeries + Number doesn't work, but we can do t .+ n.
# t + v is not valid because TSeries + Vector doesn't work, but we can do t .+ v so long as length(t) == length(v).
# n*t is valid because Number * TSeries is a valid operation.
# t/n is valid (same as (1/n)*t), but n/t is not because we can't divide a Number by TSeries. We can still do n ./ t.

# function applications are not valid, so we must use dot to broadcast, e.g. log(t) throws an error, we must do log.(t)

Base.promote_shape(a::TSeries, b::TSeries) = mixed_freq_error(a, b)
Base.promote_shape(a::TSeries{F}, b::TSeries{F}) where {F<:Frequency} = intersect(eachindex(a), eachindex(b))

shape_error(A::Type, B::Type) = throw(ArgumentError("This operation is not valid for $(A) and $(B). Try using . to do it element-wise."))
shape_error(a, b) = shape_error(typeof(a), typeof(b))

Base.promote_shape(a::TSeries, b::AbstractVector) = promote_shape(_vals(a), b)
Base.promote_shape(a::AbstractVector, b::TSeries) = promote_shape(a, _vals(b))

# +, -, *, / work out of the box with the above methods for promote_shape.

# @inline function Base.isapprox(x::TSeries, y::TSeries; kwargs...)
#     shape = promote_shape(x, y)
#     isapprox(x[shape].values, y[shape].values; kwargs...)
# end

for func in (:maximum, :minimum)
    @eval begin
        Base.$func(t::TSeries; kwargs...) = $func(values(t); kwargs...)
        Base.$func(f::Function, t::TSeries; kwargs...) = $func(f, values(t); kwargs...)
    end
end

####################################################################
# Now we implement some time-series operations that do not really apply to vectors.


"""
    shift(x::TSeries, n)

Shift the dates of `x` by `n` periods. By convention positive `n` gives the lead
and negative `n` gives the lag. `shift` creates a new [`TSeries`](@ref) and
copies the data over. See [`shift!`](@ref) for in-place version.

For example:
```julia-repl
julia> shift(TSeries(2020Q1, 1:4), 1)
TSeries{Quarterly{3}} of length 4
2019Q4: 1.0
2020Q1: 2.0
2020Q2: 3.0
2020Q3: 4.0


julia> shift(TSeries(2020Q1, 1:4), -1)
TSeries{Quarterly{3}} of length 4
2020Q2: 1.0
2020Q3: 2.0
2020Q4: 3.0
2021Q1: 4.0
```
"""
shift(ts::TSeries, k::Int) = copyto!(TSeries(rangeof(ts) .- k), ts.values)

"""
    shift(x::TSeries{BDaily}, n, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing)

As [`shift`](@ref) but with behavor depending on the TimeSeriesEcon options `:bdaily_skip_nans`, `:bdaily_skip_holidays`
and the optional `holidays_map` argument.

When `skip_all_nans` is  `true`, any NaN values replaced with the nearest valid value. 
Replacements will come from later time periods when k >= 0 and from earlier time periods when k < 0.

When `skip_all_nans` is `false` but `skip_holidays` is `true` or a 
`holidays_map` is passed to the function, then NaN originating from Holidays will be replaced with the nearest valid value.
Replacements will come from later time periods when k >= 0 and from earlier time periods when k < 0.

Options:
* skip_all_nans : A Boolean. Default is false.
* skip_holidays : A Boolean. Default is false.
* holidays_map : A Boolean-values BDaily TSeries with true values on days which are not holidays. Default is nothing.


Example:
```julia-repl
julia> shift(TSeries(bdaily("2022-07-04"), [1,2,NaN,4]), 1, skip_all_nans=true)
4-element TSeries{TimeSeriesEcon.BDaily} with range 2022-07-01:2022-07-06:
2022-07-01 : 1.0
2022-07-04 : 2.0
2022-07-05 : 4.0
2022-07-06 : 4.0


julia> shift(TSeries(bdaily("2022-07-04"), [1,2,NaN,4]), -1, skip_all_nans=true)
4-element TSeries{TimeSeriesEcon.BDaily} with range 2022-07-05:2022-07-08:
2022-07-05 : 1.0
2022-07-06 : 2.0
2022-07-07 : 2.0
2022-07-08 : 4.0
```
"""
function shift(ts::TSeries{BDaily}, k::Int; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) 
    new_ts = copyto!(TSeries(rangeof(ts) .- k), ts.values)
    replace_nans_if_warranted!(new_ts, k; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
    return new_ts
end

"""
    replace_nans_if_warranted!(ts::TSeries, k::Integer)

An internal function used to replace NaNs in a BDaily TSeries with their next or previous valid value.
When skip_holidays is true or a holidays_map is passed the process only replaces NaNs when the source of the NaN is on a holiday.
"""
function replace_nans_if_warranted!(ts::TSeries, k::Integer; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing)
    if !skip_all_nans && !skip_holidays && holidays_map === nothing
        return
    end
    direction = k > 0 ? :next : :previous;
    ts_range = rangeof(ts)
    
    holidays = nothing
    if holidays_map !== nothing
        skip_holidays = true # overwriting global option
        holidays = holidays_map[ts_range[begin]-abs(k):ts_range[end]+abs(k)]
    elseif skip_holidays
        h_map = getoption(:bdaily_holidays_map)
        if !(h_map isa TSeries{BDaily})
            throw(ArgumentError("The holidays map stored in :bdaily_holidays_map is not a TSeries{BusinessDaily} it is a $(typeof(h_map)). \n You may need to load one with TimeSeriesEcon.set_holidays_map()."))
        end
        holidays = h_map[ts_range[begin]-abs(k):ts_range[end]+abs(k)]
    end
    
    last_valid = NaN
    if direction == :next
        for (i, val) in enumerate(reverse(ts.values))
            input_is_holiday = skip_holidays ? holidays[ts_range[end - (i-1)] + k] == false : false
            if isnan(val)
                # we are about to place a NaN in the output date
                if skip_all_nans # replace all nans
                    ts.values[end - (i-1)] = last_valid
                elseif skip_holidays && input_is_holiday
                    # we are about to place a NaN on non-holiday, but the NaN came from a holiday
                    # in this case, we should replace it with the latest non-holiday
                    ts.values[end - (i-1)] = last_valid
                elseif skip_holidays && !input_is_holiday
                    # in this case, we actually want to store the NaN to use it later
                    last_valid = val
                end
            else #output is not a NaN
                if skip_all_nans # replace all nans
                    last_valid = val
                elseif skip_holidays && !input_is_holiday
                    last_valid = val
                end
            end    
        end
    elseif direction == :previous
        for (i, val) in enumerate(ts.values)
            # output_is_holiday = skip_holidays ? holidays[ts_range[begin + (i-1)]] == false : false
            input_is_holiday = skip_holidays ? holidays[ts_range[begin + (i-1)] + k] == false : false
            if isnan(val)
                # we are about to place a NaN in the output date
                if skip_all_nans # replace all nans
                    ts.values[begin + (i-1)] = last_valid
                elseif skip_holidays && input_is_holiday
                    # we are about to place a NaN on non-holiday, but the NaN came from a holiday
                    # in this case, we should replace it with the latest non-holiday
                    ts.values[begin + (i-1)] = last_valid
                elseif skip_holidays && !input_is_holiday
                    # in this case, we actually want to store the NaN to use it later
                    last_valid = val
                end
            else #output is not a NaN
                if skip_all_nans # replace all nans
                    last_valid = val
                elseif skip_holidays && !input_is_holiday
                    last_valid = val
                end
            end 
        end
    end

end

"""
    shift!(x::TSeries, n)
    shift!(x::TSeries{BusinessDailies}, n, holidays_map=nothing)

In-place version of [`shift`](@ref).
"""
shift!(ts::TSeries, k::Int) = (ts.firstdate -= k; ts)
shift!(ts::TSeries{BDaily}, k::Int; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) = (ts.firstdate -= k; replace_nans_if_warranted!(ts, k, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map))

"""
    lag(x::TSeries, k=1)

Shift the dates of `x` by `k` period to produce the `k`-th lag of `x`. This is
the same [`shift(x, -k)`](@ref).
"""
lag(t::TSeries, k::Int=1) = shift(t, -k)
lag(t::TSeries{BDaily}, k::Int=1; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) = shift(t, -k; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)

"""
    lag!(x::TSeries, k=1)

In-place version of [`lag`](@ref)
"""
lag!(t::TSeries, k::Int=1) = shift!(t, -k)
lag!(t::TSeries{BDaily}, k::Int=1; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) = shift!(t, -k; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)

"""
    lead(x::TSeries, k=1)

Shift the dates of `x` by `k` period to produce the `k`-th lead of `x`. This is
the same [`shift(x, k)`](@ref).
"""
lead(t::TSeries, k::Int=1) = shift(t, k)
lead(t::TSeries{BDaily}, k::Int=1; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) = shift(t, k; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)

"""
    lead!(x::TSeries, k=1)

In-place version of [`lead`](@ref)
"""
lead!(t::TSeries, k::Int=1) = shift!(t, k)
lead!(t::TSeries{BDaily}, k::Int=1; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing) = shift!(t, k, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)

# Overload statistics functions
Statistics.mean(f, itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = mean(f, cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
Statistics.mean(itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = mean(identity, cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)

# Statistics.var(f, itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = mean(f, cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
Statistics.std(itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = std(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
Statistics.var(itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = var(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
Statistics.median(itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = median(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
Statistics.quantile(itr::TSeries{BDaily}, p; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = quantile(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), p, kwargs...)
Statistics.stdm(itr::TSeries{BDaily}, mean; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = stdm(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), mean, kwargs...)
Statistics.varm(itr::TSeries{BDaily}, mean; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = varm(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), mean, kwargs...)

function Statistics.cor(x::TSeries, y::TSeries;kwargs...) 
    if frequencyof(x) == frequencyof(y) && x.firstdate == y.firstdate
        return cor(x.values, y.values; kwargs...)
    else
        throw(ArgumentError("Correlations can only be implicitly run on TSeries with the same frequency and start date. Call the function with values(x), values(y) to pass the potentially missaligned data."))
    end
end
function Statistics.cov(x::TSeries, y::TSeries;kwargs...) 
    if frequencyof(x) == frequencyof(y) && x.firstdate == y.firstdate
        return cov(x.values, y.values; kwargs...)
    else
        throw(ArgumentError("Covariance can only be implicitly run on TSeries with the same frequency and start date. Call the function with values(x), values(y) to pass the potentially missaligned data."))
    end
end


Statistics.cor(x::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = cor(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
function Statistics.cor(x::TSeries{BDaily}, y::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) 
    if frequencyof(x) == frequencyof(y) && x.firstdate == y.firstdate
        return cor(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), cleanedvalues(y, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
    else
        throw(ArgumentError("Correlations can only be implicitly run on TSeries with the same frequency and start date. Call the function with cleanedvalues(x), cleanedvalues(y) to pass the potentially missaligned data."))
    end
end
Statistics.cov(itr::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) = cov(cleanedvalues(itr, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
function Statistics.cov(x::TSeries{BDaily}, y::TSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing, TSeries{BDaily}}=nothing, kwargs...) 
    if frequencyof(x) == frequencyof(y) && x.firstdate == y.firstdate
        return cov(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), cleanedvalues(y, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
    else
        throw(ArgumentError("Covariance can only be implicitly run on TSeries with the same frequency and start date. Call the function with cleanedvalues(x), cleanedvalues(y) to pass the potentially missaligned data."))
    end
end


# Statistics, MVTSeries
# Statistics.mean(x::MVTSeries; kwargs...) = mean(x.values; kwargs...)
# Statistics.mean(f, x::MVTSeries; kwargs...) = mean(f, x.values; kwargs...)
# Statistics.std(x::MVTSeries; kwargs...) = std(x.values; kwargs...)
# Statistics.var(x::MVTSeries; kwargs...) = var(x.values; kwargs...)
# Statistics.median(x::MVTSeries; kwargs...) = median(x.values; kwargs...)
# Statistics.cor(x::MVTSeries; kwargs...) = cor(x.values; kwargs...)
# Statistics.cov(x::MVTSeries; kwargs...) = cov(x.values; kwargs...)

Statistics.mean(f::Function, x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = mean(f, cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map); kwargs...)
Statistics.mean(x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = mean(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map); kwargs...)
Statistics.std(x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = std(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map); kwargs...)
Statistics.var(x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = var(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map); kwargs...)
Statistics.median(x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = median(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map); kwargs...)
Statistics.cor(x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = cor(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)
Statistics.cov(x::MVTSeries{BDaily}; skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing, kwargs...) = cov(cleanedvalues(x, skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map), kwargs...)


"""
    pct(x::Union{TSeries,MVTSeries}; shift_value::Int=-1; islog=false)

Observation-to-observation percent rate of change in x.
"""
function pct(ts::Union{TSeries,MVTSeries}, shift_value::Int=-1; islog::Bool=false)
    if islog
        a = exp.(ts)
        b = shift(exp.(ts), shift_value)
    else
        a = ts
        b = shift(ts, shift_value)
    end

    result = @. ((a - b) / b) * 100
    return result
end
function pct(ts::Union{TSeries{BDaily},MVTSeries{BDaily}}, shift_value::Int=-1; islog::Bool=false, skip_all_nans::Bool=false, skip_holidays::Bool=false, holidays_map::Union{Nothing,TSeries{BDaily}}=nothing)
    if islog
        a = exp.(ts)
        b = shift(exp.(ts), shift_value; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
    else
        a = ts
        b = shift(ts, shift_value; skip_all_nans=skip_all_nans, skip_holidays=skip_holidays, holidays_map=holidays_map)
    end

    result = @. ((a - b) / b) * 100
    return result
end

export pct

"""
    apct(x::Union{TSeries,MVTSeries}, islog::Bool)

Annualised percent rate of change in `x`.

Examples
```julia-repl
julia> x = TSeries(qq(2018, 1), Vector(1:8));

julia> apct(x)
TSeries{Quarterly{3}} of length 7
2018Q2: 1500.0
2018Q3: 406.25
2018Q4: 216.04938271604937
2019Q1: 144.140625
2019Q2: 107.35999999999999
2019Q3: 85.26234567901243
2019Q4: 70.59558517284461
```

See also: [`pct`](@ref)
"""
function apct(ts::Union{TSeries{<:YPFrequency{N}},MVTSeries{<:YPFrequency{N}}}, islog::Bool=false) where {N}
    if islog
        a = exp.(ts)
        b = shift(exp.(ts), -1)
    else
        a = ts
        b = shift(ts, -1)
    end
    return ((a ./ b) .^ N .- 1) * 100
end
export apct
apct(ts::Union{TSeries,MVTSeries}, args...) = error("apct for frequency $(frequencyof(ts)) not implemented")


"""
    ytypct(x) 

Year-to-year percent change in x. 
"""
ytypct(x::Union{TSeries{<:YPFrequency{N}},MVTSeries{<:YPFrequency{N}}}) where N = 100 * (x ./ shift(x, -ppy(x)) .- 1)
export ytypct
