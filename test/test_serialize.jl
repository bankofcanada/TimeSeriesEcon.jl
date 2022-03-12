
using Distributed

@testset "serialize" begin

    addprocs(1)
    # @everywhere workers() begin
    #     using Pkg
    #     Pkg.activate(".")
    # end

    @everywhere workers() using TimeSeriesEcon

    p = 2020Q1
    z = fetch(@spawnat :any (p; p + 1))
    @test typeof(p) == typeof(z)
    @test z == 2020Q2
    #
    @test fetch(@spawnat :any (1 .+ (2020Q1:2022Q4))) == 2020Q2:2023Q1
    #
    t = TSeries(2020Q1, rand(5))
    z = fetch(@spawnat :any log.(t))
    @test typeof(t) == typeof(z)
    @test firstdate(t) == firstdate(z)
    @test length(t) == length(z)
    @test z == log.(t)
    #
    sd = MVTSeries(2000Y, (:A, :Beta, :C), rand(5, 3))
    @everywhere foo_1234(s::MVTSeries) = hcat(s; Foo = s.A + s.Beta - 2s.C)
    z = fetch(@spawnat :any foo_1234(sd))
    @test typeof(sd) == typeof(z)
    @test rangeof(sd) == rangeof(z)
    @test (colnames(z)...,) == (:A, :Beta, :C, :Foo)
    @test rawdata(z)[:, 1:3] == rawdata(sd)
    @test rawdata(z)[:, 4] == (rawdata(sd)[:, 1] .+
                               rawdata(sd)[:, 2] .- 2 .* rawdata(sd)[:, 3])
    #
    z = fetch(@spawnat :any MVTSeries(20Q1:22Q4, (:a, :b, :c), rand))
    z[20Q2, :a] = 100
    @test z.a[20Q2] == z[20Q2, :a]
    @test all(z.a .== z[:, :a])
    @test all(z[20Q2] .== z[20Q2, :])
    z.b[21Q1] = 200
    @test z.b[21Q1] == z[21Q1, :b]
    @test all(z.b .== z[:, :b])
    @test all(z[21Q1] .== z[21Q1, :])

    rmprocs(workers())

end