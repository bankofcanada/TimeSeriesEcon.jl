# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

using Test
using TimeSeriesEcon
using Statistics
using Random
using Suppressor

include("test_mit.jl")
include("test_tseries.jl")
include("test_business.jl")
include("test_mvtseries.jl")
include("test_workspace.jl")
include("test_fconvert.jl")
include("test_serialize.jl")
include("test_various.jl")
include("test_22.jl")
include("test_x13spec.jl")
if !Sys.isapple()
    include("test_x13run.jl")
end

include("test_dataecon.jl")
