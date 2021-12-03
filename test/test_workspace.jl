# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

@testset "workspace" begin
    # Create an empty workspace
    @test (Workspace(); true)
    # Add keys to the workspace
    @test (work1 = Workspace(); work1.a = 1; true)
    # Create a new workspace
    let work1 = Workspace()
        work1.a = 1
        work1.ts = TSeries(2020Q1,randn(10))
        work1.mvts = MVTSeries(2020Q1,(:a,:b),randn(10,2))
        # propertynames
        @test (isa(propertynames(work1),Tuple))
        # getproperty
        @test (work1.a == 1)
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
        # iterate
        #
        # show
        let io = IOBuffer()
            @test (show(io, work1); true)
        end
    end
end
