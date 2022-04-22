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

        #destructive filter
        filter!(tuple -> last(tuple) == 2, work1)
        @test length(work1) == 1
    end

    #stripping workspaces
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
end
