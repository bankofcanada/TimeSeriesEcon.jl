# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.


"""
    TimeSeriesEcon

This package is part of the StateSpaceEcon ecosystem. Provides the data types
and functionality necessary to work with macroeconomic discrete time models.

### Working with time
 * Frequencies are represented by abstract type [`Frequency`](@ref). 
 * Concrete frequencies include [`Yearly`](@ref), [`Quarterly`](@ref) and
   [`Monthly`](@ref).
 * Moments in time are represented by data type [`MIT`](@ref).
 * Lengths of time are represented by data type [`Duration`](@ref).

### Working with time series
 * Data type [`TSeries`](@ref) represents a single time series.
 * Data type [`MVTSeries`](@ref) represents a multivariate time series.

### Working with other data
 * Data type [`Workspace`](@ref) is a general purpose dictionary-like collection
   of "variable"-like objects.

### Tutorial
 * [TimeSeriesEcon tutorial](https://bankofcanada.github.io/DocsEcon.jl/dev/Tutorials/TimeSeriesEcon/main/)
"""
module TimeSeriesEcon

# other packages
using MacroTools
using RecipesBase
using OrderedCollections

# standard library
using LinearAlgebra
using Statistics
using Serialization
using Distributed
import Dates
import Dates: Date, Month, Quarter, Year, Week, Day, dayofweek, dayofmonth, dayofyear, dayofquarter, dayname, week
using TOML

include("options.jl")

include("momentintime.jl")
export MIT, Duration
# export mm, qq, yy
export daily, bdaily
export Daily, BDaily, Weekly, Monthly, Quarterly, HalfYearly, Yearly, Frequency, YPFrequency, Unit, CalendarFrequency
export year, period, mit2yp, ppy
export frequencyof
export U, Y, H1, H2, Q1, Q2, Q3, Q4
export M1, M2, M3, M4, M5, M6
export M7, M8, M9, M10, M11, M12
export @d_str, @bd_str, @w_str

include("tseries.jl")
export TSeries
export firstdate, lastdate, rangeof
export typenan, istypenan

include("tsbroadcast.jl")

include("fconvert/fconvert_helpers.jl")
include("fconvert/fconvert_mit.jl")
include("fconvert/fconvert_tseries.jl")
export overlay, fconvert

include("mvtseries.jl")
export MVTSeries
export rawdata, colnames, columns, cleanedvalues

include("tsmath.jl")
export shift, shift!, lag, lag!, lead, lead!

include("recursive.jl")
export @rec

include("plotrecipes.jl")

include("workspaces.jl")

include("serialize.jl")

include("various.jl")

include("linalg.jl")

"""
    rangeof(s; drop::Integer)

Return the stored range of `s` adjusted by dropping `drop` periods. If `drop` is
positive, we drop from the beginning and if `drop` is negative we drop from the
end. This adds convenience when using [`@rec`](@ref)

Example
```
julia> q = TSeries(20Q1:21Q4);
julia> rangeof(q; drop=1)
20Q2:21Q4

julia> rangeof(q; drop=-4)
20Q1:20Q4

julia> q[begin:begin+1] .= 1;
julia> @rec rangeof(q; drop=2) q[t] = q[t-1] + q[t-2];
julia> q
8-element TSeries{Quarterly{3}} with range 20Q1:21Q4:
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
@inline function rangeof(x::Union{TSeries,MVTSeries,Workspace}; drop::Integer)
    rng = rangeof(x)
    return drop > 0 ? (first(rng)+drop:last(rng)) : (first(rng):last(rng)+drop)
end

include("dataecon/DataEcon.jl")

end
