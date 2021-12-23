# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.


# """
#     TimeSeriesEcon

# This package is part of the StateSpaceEcon ecosystem.
# TimeSeriesEcon.jl provides functionality to work with
# low-Frequency discrete macroeconomic time-series data.

# ### Frequencies (abstract type):
#  - Unit
#  - Monthly
#  - Quarterly
#  - Yearly

# ### Types:

#  - `MIT{Frequency}` (aka "Moment In Time")
#      - a primitive type denoting monthly, quarterly, and yearly dates
#  - `TSeries{Frequency}`
#      - an `AbstractVector` that can be indexed using `MIT`

# ### Functions:

#  - `MIT` Constructors/Functions
#     - `mm(year::Int, period::Int)`: returns a monthly `MIT` type instance
#     - `qq(year::Int, period::Int)`: returns a quarterly `MIT` type instance
#     - `yy(year::Int)`: returns a yearly `MIT` type instance
#     - `ii(x::Int)`: returns a unit `MIT` type instance
#     - `year(x::MIT)`: returns a `Int64` year value associated with `x`
#     - `period(x::MIT)`: returns a `Int64` period value associated with `x`
#     - `frequencyof(x::MIT)`: returns `<: Frequency` assosicated wtih `x`


#  - Functions operating on `TSeries`
#     - `mitrange(x::TSeries)`: returns a `UnitRange{MIT{Frequency}}` for the given `x`
#     - `firstdate(x::TSeries)`: returns `MIT{Frequency}` first date associated with `x`  
#     - `lastdate(x::TSeries)`: returns `MIT{Frequency}` last date associated with `x`
#     - `ppy(x::TSeries)`: returns the number of periods per year for `x::TSeries`. (`ppy` also accepts `x::MIT` and `x::Frequency`) 
#     - `shift(x::TSeries, i::Int64)`: shifts the dates of `x` by `firstdate(x) - i`
#     - `shift!`: in-place version of `shift`
#     - `pct(x::TSeries, shift_value::Int64; islog::Bool = false)`: calculates percent rate of change of `x::TSeries`
#     - `apct(x::TSeries, islog::Bool = false)`: calculates annualized percent rate of change of `x::TSeries`
#     - `nanrm!(x::TSeries, type::Symbol=:both)`: removes `NaN` from `x::TSeries`
# """
module TimeSeriesEcon

include("momentintime.jl")
export MIT, Duration
export mm, qq, yy
export Monthly, Quarterly, Yearly, Frequency, YPFrequency, Unit
export year, period, mit2yp, ppy
export frequencyof
export U, Y, Q1, Q2, Q3, Q4
export M1, M2, M3, M4, M5, M6
export M7, M8, M9, M10, M11, M12

include("tseries.jl")
export TSeries
export firstdate, lastdate, rangeof
export typenan, istypenan

include("tsbroadcast.jl")
include("tsmath.jl")
export shift, shift!, lag, lag!, lead, lead!

include("fconvert.jl")
export overlay, fconvert

include("mvtseries.jl")
export MVTSeries
export rawdata, colnames, columns

include("recursive.jl")
export @rec

include("plotrecipes.jl")

"""
    rangeof(s; drop::Integer)

Return the stored range of `s` adjusted by dropping `drop` periods. If `drop` is
positive, we drop from the beginning and if `drop` is negative we drop from the
end. This adds convenience when using [`@rec`](@ref)

Example
```
julia> q = TSeries(20Q1:21Q4); rangeof(q; drop=1)
20Q2:21Q4

julia> rangeof(q; drop=-4)
20Q1:20Q4

julia> q[begin:begin+1] .= 1; @rec rangeof(q; drop=2) q[t] = q[t-1] + q[t-2]; q
8-element TSeries{Quarterly} with range 20Q1:21Q4:
    20Q1 : 1.0
    20Q2 : 1.0
    20Q3 : 2.0
    20Q4 : 3.0
    21Q1 : 5.0
    21Q2 : 8.0
    21Q3 : 13.0
    21Q4 : 21.0
```
"""
@inline rangeof(x::Union{TSeries, MVTSeries}; drop::Integer) = 
    (rng = rangeof(x); 
        drop > 0 ? (first(rng) + drop:last(rng)) : (first(rng):last(rng)+drop))


include("workspaces.jl")

end
