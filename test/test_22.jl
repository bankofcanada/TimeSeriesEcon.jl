# test for issue 22
# https://github.com/bankofcanada/TimeSeriesEcon.jl/issues/22


@testset "issue #22" begin
    d1 = Workspace()
    d1.a = TSeries(2000Q1,randn(10))
    d1.b = TSeries(2000Q1,randn(10))
    d2 = deepcopy(d1)
    d2.a = d1.a[2001Q1:2001Q1]
    d1.a = TSeries(1960Q1,randn(10))
    @test !compare(d1,d2; atol = 1e-8, quiet=true)
    @test compare(d1,d2; atol = 1e-8, quiet=true, ignoremissing=true)
end
