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
        work4 = Workspace()
        work4.A = TSeries(86Y, zeros(300))
        work5 = Workspace()
        work5.A = TSeries(86Y, zeros(300))

        @test TimeSeriesEcon.compare_equal(work1, work2; quiet=true) == true
        @test TimeSeriesEcon.compare_equal(work1, work3; quiet=true) == false
        @test TimeSeriesEcon.compare_equal(work4, work5; quiet=true) == true
        @test TimeSeriesEcon.compare(work1, work2; quiet=true) == true
        @test TimeSeriesEcon.compare(work1, work3; quiet=true) == false
        @test TimeSeriesEcon.compare(work4, work5; quiet=true) == true
    end;

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

@testset "clean old workspace" begin
    m1 = reinterpret(MIT{Quarterly}, 8088)
    m2 = reinterpret(MIT{Quarterly}, 8094)
    @test frequencyof(m1) == Quarterly
    # note: these series can't be displayed due to implicit conversion
    # resulting in mixed frequency errors
    t1 = TSeries(m1, collect(1:10));
    t2 = TSeries(m1, collect(11:20));
    t3 = TSeries(m1, collect(21:30));
    t4 = TSeries(m1, collect(31:40));
    t5 = TSeries(m1, collect(41:50));
    t6 = TSeries(m1, collect(51:60));
    t7 = TSeries(m1, collect(61:70));
    t8 = TSeries(m1, collect(71:80));
    t9 = TSeries(m1, collect(81:90));
    t10 = TSeries(m1, collect(91:100));
    @test frequencyof(t1) == Quarterly
    cleaned_m1 = TimeSeriesEcon.clean_old_frequencies(m1)
    @test typeof(cleaned_m1) == MIT{Quarterly{3}}
    cleaned_t1 = TimeSeriesEcon.clean_old_frequencies(t1)
    @test typeof(cleaned_t1) == TSeries{Quarterly{3}, Int64, Vector{Int64}}

    ws = Workspace(:a => t1, :b => t2, :c=> m1, :d => Workspace(:e => t4, :f => t5));
    cleaned_ws = TimeSeriesEcon.clean_old_frequencies(ws)
    @test typeof(cleaned_ws.a) == TSeries{Quarterly{3}, Int64, Vector{Int64}}
    @test typeof(cleaned_ws.b) == TSeries{Quarterly{3}, Int64, Vector{Int64}}
    @test typeof(cleaned_ws.c) == MIT{Quarterly{3}}
    @test typeof(cleaned_ws.d.e) == TSeries{Quarterly{3}, Int64, Vector{Int64}}
    @test typeof(cleaned_ws.d.f) == TSeries{Quarterly{3}, Int64, Vector{Int64}}

    ws2 = Workspace(:a => t1, :b => t2, :c=> m1, :d => Workspace(:e => t4, :f => t5));
    @test typeof(ws2.a) == TSeries{Quarterly, Int64, Vector{Int64}}
    @test typeof(ws2.c) == MIT{Quarterly}
    TimeSeriesEcon.clean_old_frequencies!(ws2)
    @test typeof(ws2.a) == TSeries{Quarterly{3}, Int64, Vector{Int64}}
    @test typeof(ws2.b) == TSeries{Quarterly{3}, Int64, Vector{Int64}}
    @test typeof(ws2.c) == MIT{Quarterly{3}}
    @test typeof(ws2.d.e) == TSeries{Quarterly{3}, Int64, Vector{Int64}}
    @test typeof(ws2.d.f) == TSeries{Quarterly{3}, Int64, Vector{Int64}}

    # Note: no test for MVTSeries
end

@testset "frequencyof Workspaces" begin
    
    w = Workspace()
    @test frequencyof(w) isa Nothing
    @test_throws ArgumentError frequencyof(w; check=true)

    push!(w, :a=>5, :b=>2020Q1)
    push!(w, :c=>TSeries(w.b, rand(5)))
    @test length(w) == 3
    @test frequencyof(w) <: Quarterly
    push!(w, :d => 20M1)
    @test frequencyof(w) isa Nothing
    delete!(w, :d)
    @test frequencyof(w) <: Quarterly
    
    w.w = Workspace(a=20Y, b=20Y-20Y)
    w.b1 = @weval w b + a
    w.α = @weval w  sin(pi) + w[:a] - w.a
    @test frequencyof(w) isa Nothing
    
end
