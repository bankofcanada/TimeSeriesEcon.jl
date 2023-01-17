# Not necessarily tests for various.jl

@testset "linalg" begin
    s = TSeries(20Q1, collect(10.0 .+ (1:12)))
    s2 = TSeries(20Q1, [2])
    s3 = TSeries(20Q1, collect(10.0 .+ (1:10)))
    x = MVTSeries(1U:10U, (:a, :b))
    a = collect(1:10)
    b = collect(11:20)
    x.a = a
    x.b = b

    x2 = MVTSeries(1U:10U, (:a, :b))
    x2.a = a
    x2.b = b

    x3 = MVTSeries(1U:2U, (:a, :b, :c, :d, :e, :f, :g, :h, :i, :j))
    x3.a = collect(1:2)
    x3.b = collect(1:2)
    x3.c = collect(1:2)
    x3.d = collect(1:2)
    x3.e = collect(1:2)
    x3.f = collect(1:2)
    x3.g = collect(1:2)
    x3.h = collect(1:2)
    x3.i = collect(1:2)
    x3.j = collect(1:2)

    x4 = MVTSeries(1U:1U, (:a, :b, :c, :d, :e, :f, :g, :h, :i, :j))
    x4.a = collect(2:2)
    x4.b = collect(2:2)
    x4.c = collect(2:2)
    x4.d = collect(2:2)
    x4.e = collect(2:2)
    x4.f = collect(2:2)
    x4.g = collect(2:2)
    x4.h = collect(2:2)
    x4.i = collect(2:2)
    x4.j = collect(2:2)


    @test adjoint(s) ≈ reshape(collect(10.0 .+ (1:12)), (1,12))
    @test adjoint(x) ≈  [a'; b']

    @test x / x2 == TimeSeriesEcon._vals(x) / TimeSeriesEcon._vals(x2)
    @test x / TimeSeriesEcon._vals(x2) == TimeSeriesEcon._vals(x) / TimeSeriesEcon._vals(x2)
    @test TimeSeriesEcon._vals(x) / x2 == TimeSeriesEcon._vals(x) / TimeSeriesEcon._vals(x2)
    @test x * x3 == TimeSeriesEcon._vals(x) * TimeSeriesEcon._vals(x3)
    @test x \ x2 == TimeSeriesEcon._vals(x) \ TimeSeriesEcon._vals(x2)

    @test s * x4 == TimeSeriesEcon._vals(s) * TimeSeriesEcon._vals(x4)
    @test x4 * s3 == TimeSeriesEcon._vals(x4) * TimeSeriesEcon._vals(s3)
    @test s / s2 == TimeSeriesEcon._vals(s) / TimeSeriesEcon._vals(s2)
end
