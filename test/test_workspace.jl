# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

@testset "workspace" begin
    # Create an empty workspace
    @test (Workspace(); true)
    # Add keys to the workspace
    @test (work1 = Workspace(); work1.a = 1; true)
    dict1 = Dict("a" => 1)
    @test (work1 = Workspace(dict1); work1.a == 1; true)
    @test (work1 = TimeSeriesEcon._dict_to_workspace(dict1); work1.a == 1; true)
    # if unsure just return the input
    @test (work1 = TimeSeriesEcon._dict_to_workspace("a" => 1); work1 == "a" => 1; true)
    # Create a new workspace
    let work1 = Workspace()
        work1.a = 1
        work1.ts = TSeries(2020Q1,randn(10))
        work1.mvts = MVTSeries(2020Q1,(:a,:b),randn(10,2))
        # propertynames
        @test (isa(propertynames(work1),Tuple))
        # getproperty
        @test (work1.a == 1)
        @test (work1[:a] == 1)
        # setproperty
        @test (work1.a = 2; work1.a == 2)
        # isempty
        @test (isempty(work1) == false)
        @test (isempty(Workspace()))
        # in
        @test (in(:b,work1) == false)
        @test (in(:ts,work1))
        # keys
        @test (collect(keys(work1)) == [:a, :ts, :mvts])
        # values
        @test (isa(values(work1),Base.ValueIterator))
        # subset
        @test (typeof(work1[:a, :ts]) == Workspace) 
        @test (length(work1[:a, :ts]) == 2) 
        @test (typeof(work1[[:a, :ts]]) == Workspace) 
        @test (length(work1[[:a, :ts]]) == 2) 
        @test (typeof(work1[(:a, :ts)]) == Workspace) 
        @test (length(work1[(:a, :ts)]) == 2) 
        
        # range
        @test rangeof(work1) == 2020Q1:2022Q2
        # iterate
        #
        # show
        let io = IOBuffer()
            @test (show(io, work1); true)
            @test (show(io, MIME("text/plain"), work1); true)
        end

        # filter
        @test length(filter(tuple -> last(tuple) isa TSeries, work1)) == 1
        @test length(filter(tuple -> last(tuple) == 2, work1)) == 1

        # destructive filter
        filter!(tuple -> last(tuple) == 2, work1)
        @test length(work1) == 1
    end

    # stripping workspaces
    let work1 = Workspace()
        work1.a = 1
        work1.ts = TSeries(2020Q1,randn(10))
        work1.ts[2020Q1:2020Q3] .= NaN
        work2 = Workspace()
        work2.ts = TSeries(2020Q1,randn(10))
        work2.ts[2021Q4:2022Q2] .= NaN
        work2.mvts = MVTSeries(2020Q1,(:a,:b),randn(10,2))
        work2.mvts[2021Q4:2022Q2, [:a, :b]] .= NaN
        work1.w2 = work2

        strip!(work1)

        @test rangeof(work1.ts) == 2020Q4:2022Q2
        @test rangeof(work1.w2.ts) == 2020Q1:2021Q3
        @test rangeof(work1.w2.mvts) == 2020Q1:2022Q2 #mvts unaffected
    end

    # overlay
    let work1 = Workspace()
        work1.A = TSeries(87Y, [1, 2, NaN, 4])
        work2 = Workspace()
        work2.A = TSeries(87Y, [NaN, 6, 7, 8])
        work3 = Workspace()
        work3.A = TSeries(86Y:92Y, [NaN, NaN, NaN, NaN, NaN, NaN, NaN])

        @test overlay(work1, work2).A == TSeries(87Y, [1,2,7,4])
        @test overlay(work2, work1).A == TSeries(87Y, [1,6,7,8])
    
        @test overlay(work3, work1, work2).A ≈ TSeries(86Y, [NaN, 1, 2, 7, 4, NaN, NaN]) nans = true
        @test (C = overlay(work1,work2); overlay(C,work1).A.values == C.A.values)

    end

    # compare
    let work1 = Workspace()
        work1.A = TSeries(87Y, ones(4))
        work2 = Workspace()
        work2.A = TSeries(87Y, ones(4))
        work3 = Workspace()
        work3.A = TSeries(86Y, zeros(4))

        @test TimeSeriesEcon.compare_equal(work1, work2) == true
        @test TimeSeriesEcon.compare_equal(work1, work3) == false
        @test TimeSeriesEcon.compare(work1, work2) == true
        @test TimeSeriesEcon.compare(work1, work3) == false
    end

    # reindexing
    let work1 = Workspace()
        work1.mvts1 = MVTSeries(2020Q1,(:y1,:y2),randn(10,2))
        work1.mvts2 = MVTSeries(2021Q1,(:y1,:y2),randn(10,2))
        work1.ts1 = ts = TSeries(2020Q1,randn(10))
        work1.ts2 = ts = TSeries(2021Q1,randn(10))
        work1.ts3 = ts = TSeries(2020Y,randn(10))
        
        work2 = reindex(work1,2021Q1 => 1U; copy = true)
        @test rangeof(work2.mvts1) == -3U:6U 
        @test rangeof(work2.mvts2) == 1U:10U 
        @test rangeof(work2.ts1) == -3U:6U 
        @test rangeof(work2.ts2) == 1U:10U 
        @test rangeof(work2.ts3) == 2020Y:2029Y #unchanged

        @test work2.mvts1.y1[end] == work1.mvts1.y1[end]
        @test work2.mvts1.y1[begin] == work1.mvts1.y1[begin]
        @test work2.mvts1.y2[end] == work1.mvts1.y2[end]
        @test work2.mvts1.y2[begin] == work1.mvts1.y2[begin]
        @test work2.mvts2.y1[end] == work1.mvts2.y1[end]
        @test work2.mvts2.y1[begin] == work1.mvts2.y1[begin]
        @test work2.mvts2.y2[end] == work1.mvts2.y2[end]
        @test work2.mvts2.y2[begin] == work1.mvts2.y2[begin]
        @test work2.ts1[end] == work1.ts1[end]
        @test work2.ts1[begin] == work1.ts1[begin]
        @test work2.ts2[end] == work1.ts2[end]
        @test work2.ts2[begin] == work1.ts2[begin]

    end
end
