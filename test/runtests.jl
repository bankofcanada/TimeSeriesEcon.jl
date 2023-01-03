# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using Test
using TimeSeriesEcon

include("test_mit.jl")
include("test_tseries.jl")
include("test_mvtseries.jl")
include("test_workspace.jl")
include("test_serialize.jl")
include("test_22.jl")

@testset "findall" begin
    # findall works for TSeries
    tt = TSeries(2000Q1, rand(10))
    tb = tt .> 0.5
    @test findall(tb) isa Vector{Int}
    @test length(findall(tb)) == sum(tb)
    # findall works for MVTSeries
    tv = MVTSeries(2000Q1, (:a, :b, :c), rand(10,3))
    tm = tv .> 0.5
    @test findall(tm) isa Vector{CartesianIndex{2}}
    @test length(findall(tm)) == sum(tm)

    # getindex works with TSeries of Bool
    @test tt.values[tb.values] == tt[tb]
    # setindex works with TSeries of Bool
    @test (tt[tb] = 0.1.+(1:sum(tb)); (tt.>1) == tb)
    # broadcasting works with TSeries of Bool
    @test (tt[tb] .= -1.0; tb == (tt .< 0.0))
    
    # getindex works with MVTSeries of Bool
    @test tv.values[tm.values] == tv[tm]
    # setindex works with MVTSeries of Bool
    @test (tv[tm] = 0.1.+(1:sum(tm)); (tv.>1) == tm)
    # broadcasting works with MVTSeries of Bool
    @test (tv[tm] .= -1.0; tm == (tv .< 0.0))
    
    @test (tv[tb] == tv.values[tb.values,:])
    @test (tv[tb] = -1000*ones(sum(tb), 3); sum(tv[tb]) == -1000*3*sum(tb))
    @test (tv[tb] .= -1000; sum(tv[tb]) == -1000*3*sum(tb))


end
