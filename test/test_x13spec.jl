using Test
using TimeSeriesEcon

ts = TSeries(2022Q1, collect(1:50))

spec = X13.X13spec(ts)
m = X13.ArimaSpec()
X13.arima!(spec,m)
X13.estimate!(spec)
X13.transform!(spec)
X13.regression!(spec)
X13.automdl!(spec)
X13.x11!(spec)
X13.x11regression!(spec)
X13.check!(spec)
X13.forecast!(spec)
X13.force!(spec)
X13.pickmdl!(spec)
X13.history!(spec)
X13.identify!(spec)
X13.outlier!(spec)
X13.seats!(spec)
X13.slidingspans!(spec)
X13.spectrum!(spec)


spec = X13.X13spec(ts)
m = X13.ArimaSpec()
X13.estimate!(spec)
X13.x13write("",spec)

# X13.arima(m, ar=[missing,2.0])

# """
# function arima(model::ArimaSpec; 
#     title::Union{String,X13default}=_X13default,
#     ar::Union{Vector{Union{Float64,Missing}},X13default}=_X13default,
#     ma::Union{Vector{Union{Float64,Missing}},X13default}=_X13default,
# )

# @testset "ArimaSpec" begin
#     x1 = X13.ArimaSpec(1,0,2)
#     @test x1.p == 1
#     @test x1.d == 0
#     @test x1.q == 2
#     @test x1.period == 0

#     x2 = X13.ArimaSpec(1,0,3)
#     @test x2.p == 1
#     @test x2.d == 0
#     @test x2.q == 3
#     @test x2.period == 0

#     x3 = X13.ArimaSpec(1,0,2,1,0,3)
#     @test x3 isa Tuple{X13.ArimaSpec,X13.ArimaSpec}
#     @test x3[1].p == 1
#     @test x3[1].d == 0
#     @test x3[1].q == 2
#     @test x3[1].period == 0
#     @test x3[2].p == 1
#     @test x3[2].d == 0
#     @test x3[2].q == 3
#     @test x3[2].period == 0

#     arima1 = X13.arima(x3...)
#     @test arima1 isa X13.X13arima
#     @test arima1.model isa Vector{X13.ArimaSpec}
#     @test arima1.model[1] == x3[1]
#     @test arima1.model[2] == x3[2]

#     arima1 = X13.arima(x1, x2)
#     @test arima1 isa X13.X13arima
#     @test arima1.model isa Vector{X13.ArimaSpec}
#     @test arima1.model[1] == x1
#     @test arima1.model[2] == x2
# end

@testset "Arima" begin
    # Manual example 1
    ts = TSeries(1950Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly Grape Harvest")
    spec = X13.X13spec(xts)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "estimate { }")
    
    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.arima!(spec, X13.ArimaModel(2,1,0,0,1,1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (2 1 0)(0 1 1)\n}")
    @test contains(s, "estimate { }\n")
    @test contains(s, "transform {\n\tfunction = log\n}")
    
    # Manual example 3
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec; variables=[:seasonal, :const])
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "estimate { }\n")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (seasonal const)\n}")
    
    # Manual example 4
    ts = TSeries(1950Y, collect(1:50))
    xts = X13.series(ts, title="Annual Olive Harvest")
    spec = X13.X13spec(xts)
    X13.arima!(spec, X13.ArimaModel([2],1,0))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = ([2] 1 0)\n}")
    @test contains(s, "estimate { }")
    
    # Manual example 5
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables = :const )
    X13.arima!(spec, X13.ArimaModel(0,1,1,12))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)12\n}")
    @test contains(s, "estimate { }\n")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = const\n}")
    
    
    # Manual example 6
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables = [:const, :seasonal] )
    m = X13.ArimaModel(X13.ArimaSpec(1,1,0),X13.ArimaSpec(1,0,0,3),X13.ArimaSpec(0,0,1))
    X13.arima!(spec, m)
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (1 1 0)(1 0 0)3(0 0 1)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (const seasonal)\n}")
    
    # Manual example 7
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.arima!(spec, X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12); ma = [missing, 1.0], fixma = [false, true])
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n\tma = (,1.0f)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "transform {\n\tfunction = log\n}")
    
end

@testset "Automdl" begin
    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:seasonal, :const])
    X13.automdl!(spec)
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "automdl { }")
    @test contains(s, "regression {\n\tvariables = (seasonal const)\n}")
    @test contains(s, "x11 { }")
    
    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=:td)
    X13.automdl!(spec; diff=[1,1], maxorder=[3,missing])
    X13.outlier!(spec)
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "automdl {\n\tdiff = (1, 1)\n\tmaxorder = (3, )\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "x11 { }")
    @test contains(s, "outlier { }")
    
    # Manual example 3 
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; aictest=:td)
    X13.automdl!(spec) #savelog argument here...
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "automdl { }")
    @test contains(s, "regression {\n\taictest = td\n}")
    @test contains(s, "x11 { }")
    
end

@testset "Check" begin
    # Manual example 1
    ts = TSeries(1964M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Retail Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:td, X13.ao(1967M6), X13.ls(1971M6), X13.easter(14)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.check!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "check { }")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "regression {\n\tvariables = (td ao1967.jun ls1971.jun easter[14])\n}")
    
    # Manual example 2
    ts = TSeries(1964M1, collect(1:50))
    xts = X13.series(ts, title="Warehouse clubs and supercenters")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.ao(2000M3), X13.tc(2001M2)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=24)
    X13.estimate!(spec)
    X13.check!(spec, acflimit=2.0, qlimit=0.05)
    s = X13.x13write(spec, test=true)
    @test contains(s, "check {\n\tacflimit = 2.0\n\tqlimit = 0.05\n}")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "regression {\n\tvariables = (td ao2000.mar tc2001.feb)\n}")
    
    # Manual example 3
    ts = TSeries(1964M1, collect(1:50))
    xts = X13.series(ts, title="Warehouse clubs and supercenters")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, :seasonal, X13.ao(2000M3), X13.tc(2001M2)])
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.forecast!(spec, maxlead=24)
    X13.estimate!(spec)
    X13.check!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "check { }")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "regression {\n\tvariables = (td seasonal ao2000.mar tc2001.feb)\n}")
    
end

@testset "Estimate" begin
    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=:seasonal)
    X13.arima!(spec, X13.ArimaModel(0,1,1); ma=[0.25], fixma=[true])
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "estimate { }")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n\tma = (0.25f)\n}")
    @test contains(s, "regression {\n\tvariables = seasonal\n}")
    
    # Manual example 2
    ts = TSeries(1978M12, collect(1:50))
    xts = X13.series(ts, title="Monthly Inventory")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.ao(1999M1)])
    X13.arima!(spec, X13.ArimaModel(1, 1, 0, 0, 1, 1))
    X13.estimate!(spec, tol=1e-4, maxiter=100, exact=:ma)
    s = X13.x13write(spec, test=true)
    @test contains(s, "estimate {\n\texact = ma\n\tmaxiter = 100\n\ttol = 0.0001\n}")
    @test contains(s, "arima {\n\tmodel = (1 1 0)(0 1 1)\n}")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td ao1999.jan)\n}")
    
    # Manual example 4
    #TODO: alternative to file argument
    ts = TSeries(1978M12, collect(1:50))
    xts = X13.series(ts, title="Monthly Inventory")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.ao(1999M1)])
    X13.arima!(spec, X13.ArimaModel(1, 1, 0, 0, 1, 1))
    X13.estimate!(spec, file="Inven.mdl", fix=:all)
    X13.outlier!(spec, span=2000M1:last(rangeof(ts)))
    s = X13.x13write(spec, test=true)
    @test contains(s, "estimate {\n\tfile = \"Inven.mdl\"\n\tfix = all\n}")
    @test contains(s, "arima {\n\tmodel = (1 1 0)(0 1 1)\n}")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td ao1999.jan)\n}")
    @test contains(s, "outlier {\n\tspan = (2000.jan, 1999.dec)\n}")
   
   
end

@testset "Force" begin
    # Manual example 1
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.X13spec(xts)
    X13.pickmdl!(spec)
    X13.x11!(spec, seasonalma=:s3x9)
    X13.force!(spec, start=10)
    s = X13.x13write(spec, test=true)
    @test contains(s, "pickmdl { }")
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "force {\n\tstart = 10\n}")
    
    # Manual example 2
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.X13spec(xts)
    X13.pickmdl!(spec)
    X13.x11!(spec, seasonalma=:s3x9)
    X13.force!(spec, start=10, type=:regress, rho=0.8)
    s = X13.x13write(spec, test=true)
    @test contains(s, "pickmdl { }")
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "force {\n\trho = 0.8\n\tstart = 10\n\ttype = regress\n}")
    
    # Manual example 3
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.X13spec(xts)
    X13.pickmdl!(spec)
    X13.x11!(spec, seasonalma=:s3x5)
    X13.force!(spec, type=:none, round=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "pickmdl { }")
    @test contains(s, "x11 {\n\tseasonalma = s3x5\n}")
    @test contains(s, "force {\n\tround = yes\n\ttype = none\n}")
end

@testset "Forecast" begin
    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.forecast!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "forecast { }")
    
    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec)
    X13.outlier!(spec)
    X13.forecast!(spec, maxlead=24)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier { }")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    

    # Manual example 3
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec)
    X13.forecast!(spec, maxlead=15, probability=0.90, exclude=10)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "forecast {\n\texclude = 10\n\tmaxlead = 15\n\tprobability = 0.9\n}")
    
    # Manual example 4
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales", span=first(rangeof(ts)):1990M3)
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec)
    X13.forecast!(spec, maxlead=24)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    
    # Manual example 5
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.forecast!(spec, maxback=12)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "forecast {\n\tmaxback = 12\n}")
    @test contains(s, "x11 { }")
    
    # Manual example 6
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaSpec(0, 1, 1), X13.ArimaSpec(0, 1, 1, 12))
    X13.estimate!(spec)
    X13.outlier!(spec)
    X13.forecast!(spec, maxlead=24, lognormal=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier { }")
    @test contains(s, "forecast {\n\tlognormal = yes\n\tmaxlead = 24\n}")
    
end

@testset "History" begin

    # Manual example 2
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Sales of livestock")
    spec = X13.X13spec(xts)
    X13.x11!(spec, seasonalma=:s3x9)
    X13.history!(spec, sadjlags=2)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "history {\n\tsadjlags = 2\n}")
    

    # Manual example 2
    ts = TSeries(1969M7, collect(1:50))
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:const, :td, X13.ls(1972M5), X13.ls(1976M10)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 1, 1, 0))
    X13.estimate!(spec)
    X13.history!(spec, estimates=:fcst, fstep=1, start=1975M1)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const td ls1972.may ls1976.oct)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(1 1 0)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "history {\n\testimates = fcst\n\tfstep = 1\n\tstart = 1975.jan\n}")
    
    # Manual example 3
    ts = TSeries(1969M7, collect(1:50))
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:const, :td, X13.ls(1972M5), X13.ls(1976M10)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 1, 1, 0))
    X13.estimate!(spec)
    X13.history!(spec, estimates=[:arma, :fcst], start=1975M1)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const td ls1972.may ls1976.oct)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(1 1 0)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "history {\n\testimates = (arma fcst)\n\tstart = 1975.jan\n}")
    
    # Manual example 4
    # TODO: fancy modelspan argument here
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Housing Starts in the Midwest", comptype=:add)
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 0, 1, 1))
    X13.x11!(spec, seasonalma=:s3x3)
    X13.history!(spec, estimates=[:sadj, :trend])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(0 1 1)\n}")
    @test contains(s, "x11 {\n\tseasonalma = s3x3\n}")
    @test contains(s, "history {\n\testimates = (sadj trend)\n}")
    
end

@testset "Identify" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n\tsdiff = (0, 1)\n}")
    

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:const, :seasonal])
    X13.identify!(spec, diff=[0, 1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const seasonal)\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n}")
    
      
    # Manual example 3
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.easter(14)])
    X13.identify!(spec, diff=[1], sdiff=[1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td easter[14])\n}")
    @test contains(s, "identify {\n\tdiff = (1)\n\tsdiff = (1)\n}")
    

    # Manual example 4
    ts = TSeries(1963Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[X13.ls(1971Q1)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1], maxlag=16)
    X13.estimate!(spec)
    X13.check!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (ls1971.1)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n\tsdiff = (0, 1)\n\tmaxlag = 16\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    
    
end