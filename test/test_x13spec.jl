using Test
using TimeSeriesEcon


@testset "building a spec" begin
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

    @test spec isa X13.X13spec
    @test spec.arima isa X13.X13arima
    @test spec.estimate isa X13.X13estimate
    @test spec.transform isa X13.X13transform
    @test spec.regression isa X13.X13regression
    @test spec.automdl isa X13.X13automdl
    @test spec.x11 isa X13.X13x11
    @test spec.x11regression isa X13.X13x11regression
    @test spec.check isa X13.X13check
    @test spec.forecast isa X13.X13forecast
    @test spec.force isa X13.X13force
    @test spec.pickmdl isa X13.X13pickmdl
    @test spec.history isa X13.X13history
    @test spec.identify isa X13.X13identify
    @test spec.outlier isa X13.X13outlier
    @test spec.seats isa X13.X13seats
    @test spec.slidingspans isa X13.X13slidingspans
    @test spec.spectrum isa X13.X13spectrum
    @test spec.series isa X13.X13series
end


@testset "ArimaSpec" begin
    x1 = X13.ArimaSpec(1,0,2)
    @test x1.p == 1
    @test x1.d == 0
    @test x1.q == 2
    @test x1.period == 0

    x2 = X13.ArimaSpec(1,0,3)
    @test x2.p == 1
    @test x2.d == 0
    @test x2.q == 3
    @test x2.period == 0

    x3 = X13.ArimaSpec(1,0,2,1,0,3)
    @test x3 isa Tuple{X13.ArimaSpec,X13.ArimaSpec}
    @test x3[1].p == 1
    @test x3[1].d == 0
    @test x3[1].q == 2
    @test x3[1].period == 0
    @test x3[2].p == 1
    @test x3[2].d == 0
    @test x3[2].q == 3
    @test x3[2].period == 0

    arima1 = X13.arima(x3...)
    @test arima1 isa X13.X13arima
    @test arima1.model isa X13.ArimaModel
    @test arima1.model.specs[1] == x3[1]
    @test arima1.model.specs[2] == x3[2]

    arima1 = X13.arima(x1, x2)
    @test arima1 isa X13.X13arima
    @test arima1.model isa X13.ArimaModel
    @test arima1.model.specs[1] == x1
    @test arima1.model.specs[2] == x2
end

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
    ts = TSeries(1964M1, collect(1:150))
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
    ts = TSeries(1964M1, collect(1:500))
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
    ts = TSeries(1964M1, collect(1:500))
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
    ts = TSeries(1978M12, collect(1:350))
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
    ts = TSeries(1978M12, collect(1:300))
    xts = X13.series(ts, title="Monthly Inventory")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.estimate!(spec, file="Inven.mdl", fix=:all)
    X13.outlier!(spec, span=X13.Span(2000M1))
    s = X13.x13write(spec, test=true)
    @test contains(s, "estimate {\n\tfile = \"Inven.mdl\"\n\tfix = all\n}")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "outlier {\n\tspan = (2000.jan, )\n}")
   
   
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
    ts = TSeries(1976M1, collect(1:250))
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
    ts = TSeries(1969M7, collect(1:150))
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
    ts = TSeries(1969M7, collect(1:150))
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
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Housing Starts in the Midwest", comptype=:add, modelspan=X13.Span(missing,M12))
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
    @test contains(s, "series {\n\tcomptype = add\n\tdata = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50)\n\tmodelspan = (, 0.dec)\n\tstart = 1967.jan\n\ttitle = \"Housing Starts in the Midwest\"\n}")
    
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

@testset "Outlier" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.arima!(spec, X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.outlier!(spec, lsrun=5, types=[:ao, :ls])
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "outlier {\n\tlsrun = 5\n\ttypes = (ao ls)\n}")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:250))
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[X13.ls(1981M6), X13.ls(1990M11)])
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec)
    X13.outlier!(spec, types=:ao, method=:addall, critical=4.0)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (ls1981.jun ls1990.nov)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier {\n\tcritical = 4.0\n\tmethod = addall\n\ttypes = ao\n}")

    # Manual example 3
    ts = TSeries(1976M1, collect(1:250))
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.X13spec(xts)
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec)
    X13.outlier!(spec, types=:ls, critical=3.0, lsrun=2, span=1987M1:1988M12)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier {\n\tcritical = 3.0\n\tlsrun = 2\n\tspan = (1987.jan, 1988.dec)\n\ttypes = ls\n}")

    # Manual example 4
    ts = TSeries(1976M1, collect(1:250))
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.X13spec(xts)
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec)
    X13.outlier!(spec, critical=[3.0, 4.5, 4.0], types=:all)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier {\n\tcritical = (3.0, 4.5, 4.0)\n\ttypes = all\n}")

end

@testset "Pickmdl" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:td, :seasonal])
    X13.pickmdl!(spec, mode=:fcst, file="nosdiff.mdl")
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (td seasonal)\n}")
    @test contains(s, "pickmdl {\n\tfile = \"nosdiff.mdl\"\n\tmode = fcst\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "x11 { }")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=:td)
    X13.pickmdl!(spec, mode=:fcst, file="nosdiff.mdl", method=:first, fcstlim=20, qlim=10, overdiff=0.99, identify=:all)
    X13.estimate!(spec)
    X13.outlier!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "pickmdl {\n\tfcstlim = 20\n\tfile = \"nosdiff.mdl\"\n\tidentify = all\n\tmethod = first\n\tmode = fcst\n\toverdiff = 0.99\n\tqlim = 10\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier { }")
    @test contains(s, "x11 { }")

    # Manual example 3
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=:td)
    X13.pickmdl!(spec, mode=:fcst, file="nosdiff.mdl", outofsample=true)
    X13.estimate!(spec)
    X13.outlier!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "pickmdl {\n\tfile = \"nosdiff.mdl\"\n\tmode = fcst\n\toutofsample = yes\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "x11 { }")

end


# TODO: Regime change documentation
@testset "Regression" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:const, :seasonal])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const seasonal)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Irregular Component of Monthly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:const, X13.sincos([4,5])])
    X13.estimate!(spec)
    X13.spectrum!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const sincos[4 5])\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "spectrum { }")

    # Manual example 3
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.labor(10), X13.thank(3)])
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td easter[8] labor[10] thank[3])\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n\tsdiff = (0, 1)\n}")

    # Manual example 4
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:tdnolpyear, :lom, X13.easter(8), X13.labor(10), X13.thank(3)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (tdnolpyear lom easter[8] labor[10] thank[3])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 5
    ts = TSeries(1990M1, collect(1:50))
    xts = X13.series(ts, title="Retail inventory of food products")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[X13.tdstock1coef(31), X13.easterstock(8)], aictest = [:td, :easter])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\taictest = (td easter)\n\tvariables = (tdstock1coef[31] easterstock[8])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "x11 { }")


    # Manual example 6
    ts = TSeries(1990Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.rp(2005Q2,2005Q4), X13.ao(1998Q1), :td])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao2007.1 rp2005.2-2005.4 ao1998.1 td)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")
 
    # Manual example 7
    ts = TSeries(1990Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.qi(2005Q2,2005Q4), X13.ao(1998Q1), :td])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao2007.1 qi2005.2-2005.4 ao1998.1 td)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 8
    ts = TSeries(1990Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.qi(2005Q2,2005Q4), X13.ao(1998Q1), :td], user=:tls, data=MVTSeries(1990Q1, [:tls], collect(51:200)))
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200)\n\tstart = 1990.1\n\tuser = tls\n\tvariables = (ao2007.1 qi2005.2-2005.4 ao1998.1 td)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 9
    ts = TSeries(1981Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=X13.tl(1985Q3,1987Q1))
    X13.identify!(spec, diff=[0,1], sdiff=[0,1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = tl1985.3-1987.1\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n\tsdiff = (0, 1)\n}")

    # Manual example 10
    ts = TSeries(1970M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Riverflow")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:seasonal, :const], data=MVTSeries(1960M1, [:temp, :precip], hcat(collect(1.0:0.1:18),collect(0.0:0.2:34))))
    X13.arima!(spec, X13.ArimaModel(3, 0, 0, 0, 0, 0))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tdata = (1.0 0.0 1.1 0.2 1.2 0.4 1.3 0.6 1.4 0.8 1.5 1.0 1.6 1.2 1.7 1.4 1.8 1.6 1.9 1.8 2.0 2.0 2.1 2.2 2.2 2.4 2.3 2.6 2.4 2.8 2.5 3.0 2.6 3.2 2.7 3.4 2.8 3.6 2.9 3.8 3.0 4.0 3.1 4.2 3.2 4.4 3.3 4.6 3.4 4.8 3.5 5.0 3.6 5.2 3.7 5.4 3.8 5.6 3.9 5.8 4.0 6.0 4.1 6.2 4.2 6.4 4.3 6.6 4.4 6.8 4.5 7.0 4.6 7.2 4.7 7.4 4.8 7.6 4.9 7.8 5.0 8.0 5.1 8.2 5.2 8.4 5.3 8.6 5.4 8.8 5.5 9.0 5.6 9.2 5.7 9.4 5.8 9.6 5.9 9.8 6.0 10.0 6.1 10.2 6.2 10.4 6.3 10.6 6.4 10.8 6.5 11.0 6.6 11.2 6.7 11.4 6.8 11.6 6.9 11.8 7.0 12.0 7.1 12.2 7.2 12.4 7.3 12.6 7.4 12.8 7.5 13.0 7.6 13.2 7.7 13.4 7.8 13.6 7.9 13.8 8.0 14.0 8.1 14.2 8.2 14.4 8.3 14.6 8.4 14.8 8.5 15.0 8.6 15.2 8.7 15.4 8.8 15.6 8.9 15.8 9.0 16.0 9.1 16.2 9.2 16.4 9.3 16.6 9.4 16.8 9.5 17.0 9.6 17.2 9.7 17.4 9.8 17.6 9.9 17.8 10.0 18.0 10.1 18.2 10.2 18.4 10.3 18.6 10.4 18.8 10.5 19.0 10.6 19.2 10.7 19.4 10.8 19.6 10.9 19.8 11.0 20.0 11.1 20.2 11.2 20.4 11.3 20.6 11.4 20.8 11.5 21.0 11.6 21.2 11.7 21.4 11.8 21.6 11.9 21.8 12.0 22.0 12.1 22.2 12.2 22.4 12.3 22.6 12.4 22.8 12.5 23.0 12.6 23.2 12.7 23.4 12.8 23.6 12.9 23.8 13.0 24.0 13.1 24.2 13.2 24.4 13.3 24.6 13.4 24.8 13.5 25.0 13.6 25.2 13.7 25.4 13.8 25.6 13.9 25.8 14.0 26.0 14.1 26.2 14.2 26.4 14.3 26.6 14.4 26.8 14.5 27.0 14.6 27.2 14.7 27.4 14.8 27.6 14.9 27.8 15.0 28.0 15.1 28.2 15.2 28.4 15.3 28.6 15.4 28.8 15.5 29.0 15.6 29.2 15.7 29.4 15.8 29.6 15.9 29.8 16.0 30.0 16.1 30.2 16.2 30.4 16.3 30.6 16.4 30.8 16.5 31.0 16.6 31.2 16.7 31.4 16.8 31.6 16.9 31.8 17.0 32.0 17.1 32.2 17.2 32.4 17.3 32.6 17.4 32.8 17.5 33.0 17.6 33.2 17.7 33.4 17.8 33.6 17.9 33.8 18.0 34.0)\n\tstart = 1960.jan\n\tuser = (temp precip)\n\tvariables = (seasonal const)\n}")
    @test contains(s, "arima {\n\tmodel = (3 0 0)(0 0 0)\n}")
    @test contains(s, "estimate { }")

    # Manual example 11
    ts = TSeries(1967M1, collect(1:250))
    xts = X13.series(ts, title="Retail Inventory - Family Apparel", type=:stock)
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.tdstock(31), X13.ao(1980M7)], aictest=:tdstock)
    X13.arima!(spec, X13.ArimaModel(0, 1, 0, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\taictest = tdstock\n\tvariables = (tdstock[31] ao1980.jul)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 0)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 12
    ts = TSeries(1976M1, collect(1:150))
    xts = X13.series(ts, title="Retail Sales - Televisions", type=:flow)
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.td(1985M12), X13.seasonal(1985M12)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td/1985.dec/ seasonal/1985.dec/)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 13
    ts = TSeries(1976M1, collect(1:150))
    xts = X13.series(ts, title="Retail Sales - Televisions", type=:flow)
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.td(1985M12, :zerobefore), :seasonal, X13.seasonal(1985M12, :zerobefore)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td td//1985.dec/ seasonal seasonal//1985.dec/)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 14
    ts = TSeries(1993Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2001Q3), X13.ls(2007Q1), X13.ls(2007Q3), X13.ao(2008Q4)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao2001.3 ls2007.1 ls2007.3 ao2008.4)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 15
    ts = TSeries(1993Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2001Q3), X13.tl(2007Q1,2007Q2), X13.ao(2008Q4)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao2001.3 tl2007.1-2007.2 ao2008.4)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 16
    ts = TSeries(1993Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2001Q3), X13.lss(2007Q1,2007Q3), X13.ao(2008Q4)])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao2001.3 lss2007.1-2007.3 ao2008.4)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 17
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Exports of pasta products")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables=[:const, :td])
    X13.automdl!(spec)
    X13.x11!(spec, mode=:add)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const td)\n}")
    @test contains(s, "automdl { }")
    @test contains(s, "x11 {\n\tmode = add\n}")

    # Manual example 18
    ts = TSeries(1975M1, collect(1:250))
    xts = X13.series(ts, title="Retail sales of children's apparel")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:const, :td, X13.ao(1976M1), X13.ls(1991M12), X13.easter(8), :seasonal],
        data=MVTSeries(1975M1, [:sale88, :sale89, :sale90], hcat(collect(1.0:0.1:28.3),collect(0.0:0.2:54.6),collect(3.0:0.3:84.9)))
    )
    X13.arima!(spec, X13.ArimaModel(2,1,0))
    X13.forecast!(spec, maxlead=24)
    X13.x11!(spec, appendfcst=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (1.0 0.0 3.0 1.1 0.2 3.3 1.2 0.4 3.6 1.3 0.6 3.9 1.4 0.8 4.2 1.5 1.0 4.5 1.6 1.2 4.8 1.7 1.4 5.1 1.8 1.6 5.4 1.9 1.8 5.7 2.0 2.0 6.0 2.1 2.2 6.3 2.2 2.4 6.6 2.3 2.6 6.9 2.4 2.8 7.2 2.5 3.0 7.5 2.6 3.2 7.8 2.7 3.4 8.1 2.8 3.6 8.4 2.9 3.8 8.7 3.0 4.0 9.0 3.1 4.2 9.3 3.2 4.4 9.6 3.3 4.6 9.9 3.4 4.8 10.2 3.5 5.0 10.5 3.6 5.2 10.8 3.7 5.4 11.1 3.8 5.6 11.4 3.9 5.8 11.7 4.0 6.0 12.0 4.1 6.2 12.3 4.2 6.4 12.6 4.3 6.6 12.9 4.4 6.8 13.2 4.5 7.0 13.5 4.6 7.2 13.8 4.7 7.4 14.1 4.8 7.6 14.4 4.9 7.8 14.7 5.0 8.0 15.0 5.1 8.2 15.3 5.2 8.4 15.6 5.3 8.6 15.9 5.4 8.8 16.2 5.5 9.0 16.5 5.6 9.2 16.8 5.7 9.4 17.1 5.8 9.6 17.4 5.9 9.8 17.7 6.0 10.0 18.0 6.1 10.2 18.3 6.2 10.4 18.6 6.3 10.6 18.9 6.4 10.8 19.2 6.5 11.0 19.5 6.6 11.2 19.8 6.7 11.4 20.1 6.8 11.6 20.4 6.9 11.8 20.7 7.0 12.0 21.0 7.1 12.2 21.3 7.2 12.4 21.6 7.3 12.6 21.9 7.4 12.8 22.2 7.5 13.0 22.5 7.6 13.2 22.8 7.7 13.4 23.1 7.8 13.6 23.4 7.9 13.8 23.7 8.0 14.0 24.0 8.1 14.2 24.3 8.2 14.4 24.6 8.3 14.6 24.9 8.4 14.8 25.2 8.5 15.0 25.5 8.6 15.2 25.8 8.7 15.4 26.1 8.8 15.6 26.4 8.9 15.8 26.7 9.0 16.0 27.0 9.1 16.2 27.3 9.2 16.4 27.6 9.3 16.6 27.9 9.4 16.8 28.2 9.5 17.0 28.5 9.6 17.2 28.8 9.7 17.4 29.1 9.8 17.6 29.4 9.9 17.8 29.7 10.0 18.0 30.0 10.1 18.2 30.3 10.2 18.4 30.6 10.3 18.6 30.9 10.4 18.8 31.2 10.5 19.0 31.5 10.6 19.2 31.8 10.7 19.4 32.1 10.8 19.6 32.4 10.9 19.8 32.7 11.0 20.0 33.0 11.1 20.2 33.3 11.2 20.4 33.6 11.3 20.6 33.9 11.4 20.8 34.2 11.5 21.0 34.5 11.6 21.2 34.8 11.7 21.4 35.1 11.8 21.6 35.4 11.9 21.8 35.7 12.0 22.0 36.0 12.1 22.2 36.3 12.2 22.4 36.6 12.3 22.6 36.9 12.4 22.8 37.2 12.5 23.0 37.5 12.6 23.2 37.8 12.7 23.4 38.1 12.8 23.6 38.4 12.9 23.8 38.7 13.0 24.0 39.0 13.1 24.2 39.3 13.2 24.4 39.6 13.3 24.6 39.9 13.4 24.8 40.2 13.5 25.0 40.5 13.6 25.2 40.8 13.7 25.4 41.1 13.8 25.6 41.4 13.9 25.8 41.7 14.0 26.0 42.0 14.1 26.2 42.3 14.2 26.4 42.6 14.3 26.6 42.9 14.4 26.8 43.2 14.5 27.0 43.5 14.6 27.2 43.8 14.7 27.4 44.1 14.8 27.6 44.4 14.9 27.8 44.7 15.0 28.0 45.0 15.1 28.2 45.3 15.2 28.4 45.6 15.3 28.6 45.9 15.4 28.8 46.2 15.5 29.0 46.5 15.6 29.2 46.8 15.7 29.4 47.1 15.8 29.6 47.4 15.9 29.8 47.7 16.0 30.0 48.0 16.1 30.2 48.3 16.2 30.4 48.6 16.3 30.6 48.9 16.4 30.8 49.2 16.5 31.0 49.5 16.6 31.2 49.8 16.7 31.4 50.1 16.8 31.6 50.4 16.9 31.8 50.7 17.0 32.0 51.0 17.1 32.2 51.3 17.2 32.4 51.6 17.3 32.6 51.9 17.4 32.8 52.2 17.5 33.0 52.5 17.6 33.2 52.8 17.7 33.4 53.1 17.8 33.6 53.4 17.9 33.8 53.7 18.0 34.0 54.0 18.1 34.2 54.3 18.2 34.4 54.6 18.3 34.6 54.9 18.4 34.8 55.2 18.5 35.0 55.5 18.6 35.2 55.8 18.7 35.4 56.1 18.8 35.6 56.4 18.9 35.8 56.7 19.0 36.0 57.0 19.1 36.2 57.3 19.2 36.4 57.6 19.3 36.6 57.9 19.4 36.8 58.2 19.5 37.0 58.5 19.6 37.2 58.8 19.7 37.4 59.1 19.8 37.6 59.4 19.9 37.8 59.7 20.0 38.0 60.0 20.1 38.2 60.3 20.2 38.4 60.6 20.3 38.6 60.9 20.4 38.8 61.2 20.5 39.0 61.5 20.6 39.2 61.8 20.7 39.4 62.1 20.8 39.6 62.4 20.9 39.8 62.7 21.0 40.0 63.0 21.1 40.2 63.3 21.2 40.4 63.6 21.3 40.6 63.9 21.4 40.8 64.2 21.5 41.0 64.5 21.6 41.2 64.8 21.7 41.4 65.1 21.8 41.6 65.4 21.9 41.8 65.7 22.0 42.0 66.0 22.1 42.2 66.3 22.2 42.4 66.6 22.3 42.6 66.9 22.4 42.8 67.2 22.5 43.0 67.5 22.6 43.2 67.8 22.7 43.4 68.1 22.8 43.6 68.4 22.9 43.8 68.7 23.0 44.0 69.0 23.1 44.2 69.3 23.2 44.4 69.6 23.3 44.6 69.9 23.4 44.8 70.2 23.5 45.0 70.5 23.6 45.2 70.8 23.7 45.4 71.1 23.8 45.6 71.4 23.9 45.8 71.7 24.0 46.0 72.0 24.1 46.2 72.3 24.2 46.4 72.6 24.3 46.6 72.9 24.4 46.8 73.2 24.5 47.0 73.5 24.6 47.2 73.8 24.7 47.4 74.1 24.8 47.6 74.4 24.9 47.8 74.7 25.0 48.0 75.0 25.1 48.2 75.3 25.2 48.4 75.6 25.3 48.6 75.9 25.4 48.8 76.2 25.5 49.0 76.5 25.6 49.2 76.8 25.7 49.4 77.1 25.8 49.6 77.4 25.9 49.8 77.7 26.0 50.0 78.0 26.1 50.2 78.3 26.2 50.4 78.6 26.3 50.6 78.9 26.4 50.8 79.2 26.5 51.0 79.5 26.6 51.2 79.8 26.7 51.4 80.1 26.8 51.6 80.4 26.9 51.8 80.7 27.0 52.0 81.0 27.1 52.2 81.3 27.2 52.4 81.6 27.3 52.6 81.9 27.4 52.8 82.2 27.5 53.0 82.5 27.6 53.2 82.8 27.7 53.4 83.1 27.8 53.6 83.4 27.9 53.8 83.7 28.0 54.0 84.0 28.1 54.2 84.3 28.2 54.4 84.6 28.3 54.6 84.9)\n\tstart = 1975.jan\n\tuser = (sale88 sale89 sale90)\n\tvariables = (const td ao1976.jan ls1991.dec easter[8] seasonal)\n}")
    @test contains(s, "arima {\n\tmodel = (2 1 0)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n}")

    # Manual example 19
    ts = TSeries(1975M1, collect(1:250))
    xts = X13.series(ts, title="Retail sales of children's apparel")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:const, :td, X13.ao(1976M1), X13.ls(1991M12), X13.easter(8), :seasonal],
        data=MVTSeries(1975M1, [:sale88, :sale89, :sale90], hcat(collect(1.0:0.1:28.3),collect(0.0:0.2:54.6),collect(3.0:0.3:84.9))),
        usertype=:ao
    )
    X13.arima!(spec, X13.ArimaModel(2,1,0))
    X13.forecast!(spec, maxlead=24)
    X13.x11!(spec, appendfcst=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (1.0 0.0 3.0 1.1 0.2 3.3 1.2 0.4 3.6 1.3 0.6 3.9 1.4 0.8 4.2 1.5 1.0 4.5 1.6 1.2 4.8 1.7 1.4 5.1 1.8 1.6 5.4 1.9 1.8 5.7 2.0 2.0 6.0 2.1 2.2 6.3 2.2 2.4 6.6 2.3 2.6 6.9 2.4 2.8 7.2 2.5 3.0 7.5 2.6 3.2 7.8 2.7 3.4 8.1 2.8 3.6 8.4 2.9 3.8 8.7 3.0 4.0 9.0 3.1 4.2 9.3 3.2 4.4 9.6 3.3 4.6 9.9 3.4 4.8 10.2 3.5 5.0 10.5 3.6 5.2 10.8 3.7 5.4 11.1 3.8 5.6 11.4 3.9 5.8 11.7 4.0 6.0 12.0 4.1 6.2 12.3 4.2 6.4 12.6 4.3 6.6 12.9 4.4 6.8 13.2 4.5 7.0 13.5 4.6 7.2 13.8 4.7 7.4 14.1 4.8 7.6 14.4 4.9 7.8 14.7 5.0 8.0 15.0 5.1 8.2 15.3 5.2 8.4 15.6 5.3 8.6 15.9 5.4 8.8 16.2 5.5 9.0 16.5 5.6 9.2 16.8 5.7 9.4 17.1 5.8 9.6 17.4 5.9 9.8 17.7 6.0 10.0 18.0 6.1 10.2 18.3 6.2 10.4 18.6 6.3 10.6 18.9 6.4 10.8 19.2 6.5 11.0 19.5 6.6 11.2 19.8 6.7 11.4 20.1 6.8 11.6 20.4 6.9 11.8 20.7 7.0 12.0 21.0 7.1 12.2 21.3 7.2 12.4 21.6 7.3 12.6 21.9 7.4 12.8 22.2 7.5 13.0 22.5 7.6 13.2 22.8 7.7 13.4 23.1 7.8 13.6 23.4 7.9 13.8 23.7 8.0 14.0 24.0 8.1 14.2 24.3 8.2 14.4 24.6 8.3 14.6 24.9 8.4 14.8 25.2 8.5 15.0 25.5 8.6 15.2 25.8 8.7 15.4 26.1 8.8 15.6 26.4 8.9 15.8 26.7 9.0 16.0 27.0 9.1 16.2 27.3 9.2 16.4 27.6 9.3 16.6 27.9 9.4 16.8 28.2 9.5 17.0 28.5 9.6 17.2 28.8 9.7 17.4 29.1 9.8 17.6 29.4 9.9 17.8 29.7 10.0 18.0 30.0 10.1 18.2 30.3 10.2 18.4 30.6 10.3 18.6 30.9 10.4 18.8 31.2 10.5 19.0 31.5 10.6 19.2 31.8 10.7 19.4 32.1 10.8 19.6 32.4 10.9 19.8 32.7 11.0 20.0 33.0 11.1 20.2 33.3 11.2 20.4 33.6 11.3 20.6 33.9 11.4 20.8 34.2 11.5 21.0 34.5 11.6 21.2 34.8 11.7 21.4 35.1 11.8 21.6 35.4 11.9 21.8 35.7 12.0 22.0 36.0 12.1 22.2 36.3 12.2 22.4 36.6 12.3 22.6 36.9 12.4 22.8 37.2 12.5 23.0 37.5 12.6 23.2 37.8 12.7 23.4 38.1 12.8 23.6 38.4 12.9 23.8 38.7 13.0 24.0 39.0 13.1 24.2 39.3 13.2 24.4 39.6 13.3 24.6 39.9 13.4 24.8 40.2 13.5 25.0 40.5 13.6 25.2 40.8 13.7 25.4 41.1 13.8 25.6 41.4 13.9 25.8 41.7 14.0 26.0 42.0 14.1 26.2 42.3 14.2 26.4 42.6 14.3 26.6 42.9 14.4 26.8 43.2 14.5 27.0 43.5 14.6 27.2 43.8 14.7 27.4 44.1 14.8 27.6 44.4 14.9 27.8 44.7 15.0 28.0 45.0 15.1 28.2 45.3 15.2 28.4 45.6 15.3 28.6 45.9 15.4 28.8 46.2 15.5 29.0 46.5 15.6 29.2 46.8 15.7 29.4 47.1 15.8 29.6 47.4 15.9 29.8 47.7 16.0 30.0 48.0 16.1 30.2 48.3 16.2 30.4 48.6 16.3 30.6 48.9 16.4 30.8 49.2 16.5 31.0 49.5 16.6 31.2 49.8 16.7 31.4 50.1 16.8 31.6 50.4 16.9 31.8 50.7 17.0 32.0 51.0 17.1 32.2 51.3 17.2 32.4 51.6 17.3 32.6 51.9 17.4 32.8 52.2 17.5 33.0 52.5 17.6 33.2 52.8 17.7 33.4 53.1 17.8 33.6 53.4 17.9 33.8 53.7 18.0 34.0 54.0 18.1 34.2 54.3 18.2 34.4 54.6 18.3 34.6 54.9 18.4 34.8 55.2 18.5 35.0 55.5 18.6 35.2 55.8 18.7 35.4 56.1 18.8 35.6 56.4 18.9 35.8 56.7 19.0 36.0 57.0 19.1 36.2 57.3 19.2 36.4 57.6 19.3 36.6 57.9 19.4 36.8 58.2 19.5 37.0 58.5 19.6 37.2 58.8 19.7 37.4 59.1 19.8 37.6 59.4 19.9 37.8 59.7 20.0 38.0 60.0 20.1 38.2 60.3 20.2 38.4 60.6 20.3 38.6 60.9 20.4 38.8 61.2 20.5 39.0 61.5 20.6 39.2 61.8 20.7 39.4 62.1 20.8 39.6 62.4 20.9 39.8 62.7 21.0 40.0 63.0 21.1 40.2 63.3 21.2 40.4 63.6 21.3 40.6 63.9 21.4 40.8 64.2 21.5 41.0 64.5 21.6 41.2 64.8 21.7 41.4 65.1 21.8 41.6 65.4 21.9 41.8 65.7 22.0 42.0 66.0 22.1 42.2 66.3 22.2 42.4 66.6 22.3 42.6 66.9 22.4 42.8 67.2 22.5 43.0 67.5 22.6 43.2 67.8 22.7 43.4 68.1 22.8 43.6 68.4 22.9 43.8 68.7 23.0 44.0 69.0 23.1 44.2 69.3 23.2 44.4 69.6 23.3 44.6 69.9 23.4 44.8 70.2 23.5 45.0 70.5 23.6 45.2 70.8 23.7 45.4 71.1 23.8 45.6 71.4 23.9 45.8 71.7 24.0 46.0 72.0 24.1 46.2 72.3 24.2 46.4 72.6 24.3 46.6 72.9 24.4 46.8 73.2 24.5 47.0 73.5 24.6 47.2 73.8 24.7 47.4 74.1 24.8 47.6 74.4 24.9 47.8 74.7 25.0 48.0 75.0 25.1 48.2 75.3 25.2 48.4 75.6 25.3 48.6 75.9 25.4 48.8 76.2 25.5 49.0 76.5 25.6 49.2 76.8 25.7 49.4 77.1 25.8 49.6 77.4 25.9 49.8 77.7 26.0 50.0 78.0 26.1 50.2 78.3 26.2 50.4 78.6 26.3 50.6 78.9 26.4 50.8 79.2 26.5 51.0 79.5 26.6 51.2 79.8 26.7 51.4 80.1 26.8 51.6 80.4 26.9 51.8 80.7 27.0 52.0 81.0 27.1 52.2 81.3 27.2 52.4 81.6 27.3 52.6 81.9 27.4 52.8 82.2 27.5 53.0 82.5 27.6 53.2 82.8 27.7 53.4 83.1 27.8 53.6 83.4 27.9 53.8 83.7 28.0 54.0 84.0 28.1 54.2 84.3 28.2 54.4 84.6 28.3 54.6 84.9)\n\tstart = 1975.jan\n\tuser = (sale88 sale89 sale90)\n\tusertype = ao\n\tvariables = (const td ao1976.jan ls1991.dec easter[8] seasonal)\n}")
    @test contains(s, "arima {\n\tmodel = (2 1 0)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n}")

    # Manual example 20
    ts = TSeries(1975M1, collect(1:150))
    xts = X13.series(ts, title="Midwest total starts")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(1977M1), X13.ls(1979M1), X13.ls(1979M3), X13.ls(1980M1), :td],
        b = [-0.7946, -0.8739, 0.6773, -0.6850, 0.0209, 0.0107, -0.0022, 0.0018, 0.0088, -0.0075],
        fixb = [true, true, true, true, false, false, false, false, false, false]
    )
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao1977.jan ls1979.jan ls1979.mar ls1980.jan td)\n\tb = (-0.7946f,-0.8739f,0.6773f,-0.685f,0.0209,0.0107,-0.0022,0.0018,0.0088,-0.0075)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(0 1 1)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "x11 { }")

    # Manual example 21
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Department store sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.easter(8)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec)
    X13.estimate!(spec)
    X13.check!(spec)
    X13.forecast!(spec)
    X13.x11!(spec, mode=:mult, seasonalma=:s3x3, title=["Department Store Retail Sales Adjusted For", "Outlier, Trading Day, and Holiday Effects"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td easter[8])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    @test contains(s, "forecast { }")
    @test contains(s, "x11 {\n\tmode = mult\n\tseasonalma = s3x3\n\ttitle = (\"Department Store Retail Sales Adjusted For\"\n\t\"Outlier, Trading Day, and Holiday Effects\")\n}")

    # Manual example 22
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Department store sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.easter(0)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec)
    X13.estimate!(spec)
    X13.check!(spec)
    X13.forecast!(spec)
    X13.x11!(spec, mode=:mult, seasonalma=:s3x3, title=["Department Store Retail Sales Adjusted For", "Outlier, Trading Day, and Holiday Effects"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td easter[8] easter[0])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    @test contains(s, "forecast { }")
    @test contains(s, "x11 {\n\tmode = mult\n\tseasonalma = s3x3\n\ttitle = (\"Department Store Retail Sales Adjusted For\"\n\t\"Outlier, Trading Day, and Holiday Effects\")\n}")

    # Manual example 23
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Department store sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.easter(0)], aictest=[:td, :easter], testalleaster=true)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec)
    X13.estimate!(spec)
    X13.check!(spec)
    X13.forecast!(spec)
    X13.x11!(spec, mode=:mult, seasonalma=:s3x3, title=["Department Store Retail Sales Adjusted For", "Outlier, Trading Day, and Holiday Effects"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\taictest = (td easter)\n\ttestalleaster = yes\n\tvariables = (td easter[8] easter[0])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    @test contains(s, "forecast { }")
    @test contains(s, "x11 {\n\tmode = mult\n\tseasonalma = s3x3\n\ttitle = (\"Department Store Retail Sales Adjusted For\"\n\t\"Outlier, Trading Day, and Holiday Effects\")\n}")

    # Manual example 24
    ts = TSeries(1990Q1, collect(1:50))
    xts = X13.series(ts, title="US Total Housing Starts")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec;
        data=MVTSeries(1985Q1, [:s1, :s2, :s3], hcat(collect(1.0:0.1:10.3),collect(0.0:0.2:18.6),collect(3.0:0.3:30.9))),
        usertype=:seasonal,
    ),
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.outlier!(spec)
    X13.forecast!(spec, maxlead=24)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (1.0 0.0 3.0 1.1 0.2 3.3 1.2 0.4 3.6 1.3 0.6 3.9 1.4 0.8 4.2 1.5 1.0 4.5 1.6 1.2 4.8 1.7 1.4 5.1 1.8 1.6 5.4 1.9 1.8 5.7 2.0 2.0 6.0 2.1 2.2 6.3 2.2 2.4 6.6 2.3 2.6 6.9 2.4 2.8 7.2 2.5 3.0 7.5 2.6 3.2 7.8 2.7 3.4 8.1 2.8 3.6 8.4 2.9 3.8 8.7 3.0 4.0 9.0 3.1 4.2 9.3 3.2 4.4 9.6 3.3 4.6 9.9 3.4 4.8 10.2 3.5 5.0 10.5 3.6 5.2 10.8 3.7 5.4 11.1 3.8 5.6 11.4 3.9 5.8 11.7 4.0 6.0 12.0 4.1 6.2 12.3 4.2 6.4 12.6 4.3 6.6 12.9 4.4 6.8 13.2 4.5 7.0 13.5 4.6 7.2 13.8 4.7 7.4 14.1 4.8 7.6 14.4 4.9 7.8 14.7 5.0 8.0 15.0 5.1 8.2 15.3 5.2 8.4 15.6 5.3 8.6 15.9 5.4 8.8 16.2 5.5 9.0 16.5 5.6 9.2 16.8 5.7 9.4 17.1 5.8 9.6 17.4 5.9 9.8 17.7 6.0 10.0 18.0 6.1 10.2 18.3 6.2 10.4 18.6 6.3 10.6 18.9 6.4 10.8 19.2 6.5 11.0 19.5 6.6 11.2 19.8 6.7 11.4 20.1 6.8 11.6 20.4 6.9 11.8 20.7 7.0 12.0 21.0 7.1 12.2 21.3 7.2 12.4 21.6 7.3 12.6 21.9 7.4 12.8 22.2 7.5 13.0 22.5 7.6 13.2 22.8 7.7 13.4 23.1 7.8 13.6 23.4 7.9 13.8 23.7 8.0 14.0 24.0 8.1 14.2 24.3 8.2 14.4 24.6 8.3 14.6 24.9 8.4 14.8 25.2 8.5 15.0 25.5 8.6 15.2 25.8 8.7 15.4 26.1 8.8 15.6 26.4 8.9 15.8 26.7 9.0 16.0 27.0 9.1 16.2 27.3 9.2 16.4 27.6 9.3 16.6 27.9 9.4 16.8 28.2 9.5 17.0 28.5 9.6 17.2 28.8 9.7 17.4 29.1 9.8 17.6 29.4 9.9 17.8 29.7 10.0 18.0 30.0 10.1 18.2 30.3 10.2 18.4 30.6 10.3 18.6 30.9)\n\tstart = 1985.1\n\tuser = (s1 s2 s3)\n\tusertype = seasonal\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")

    # Manual example 25
    ts = TSeries(1991M1, collect(1:150))
    xts = X13.series(ts, title="Payment to family nanny, taiwan", span=X13.Span(1993M1))
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec;
        variables=[X13.ao(1995M9), X13.ao(1997M1), X13.ao(1997M2)],
        data=MVTSeries(1991M1, [:beforecny, :betweencny, :aftercny, :beforemoon, :betweenmoon, :aftermoon, :beforemidfall, :betweenmidfall, :aftermidfall], hcat(collect(1.0:0.1:17.1),collect(0.0:0.2:32.2),collect(3.0:0.3:51.3),collect(1.0:0.1:17.1),collect(0.0:0.2:32.2),collect(3.0:0.3:51.3),collect(1.0:0.1:17.1),collect(0.0:0.2:32.2),collect(3.0:0.3:51.3))),
        usertype=[:holiday, :holiday, :holiday, :holiday2, :holiday2, :holiday2, :holiday3, :holiday3, :holiday3],
        chi2test = true
    )
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,0))
    X13.check!(spec)
    X13.forecast!(spec, maxlead=12)
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tchi2test = yes\n\tdata = (1.0 0.0 3.0 1.0 0.0 3.0 1.0 0.0 3.0 1.1 0.2 3.3 1.1 0.2 3.3 1.1 0.2 3.3 1.2 0.4 3.6 1.2 0.4 3.6 1.2 0.4 3.6 1.3 0.6 3.9 1.3 0.6 3.9 1.3 0.6 3.9 1.4 0.8 4.2 1.4 0.8 4.2 1.4 0.8 4.2 1.5 1.0 4.5 1.5 1.0 4.5 1.5 1.0 4.5 1.6 1.2 4.8 1.6 1.2 4.8 1.6 1.2 4.8 1.7 1.4 5.1 1.7 1.4 5.1 1.7 1.4 5.1 1.8 1.6 5.4 1.8 1.6 5.4 1.8 1.6 5.4 1.9 1.8 5.7 1.9 1.8 5.7 1.9 1.8 5.7 2.0 2.0 6.0 2.0 2.0 6.0 2.0 2.0 6.0 2.1 2.2 6.3 2.1 2.2 6.3 2.1 2.2 6.3 2.2 2.4 6.6 2.2 2.4 6.6 2.2 2.4 6.6 2.3 2.6 6.9 2.3 2.6 6.9 2.3 2.6 6.9 2.4 2.8 7.2 2.4 2.8 7.2 2.4 2.8 7.2 2.5 3.0 7.5 2.5 3.0 7.5 2.5 3.0 7.5 2.6 3.2 7.8 2.6 3.2 7.8 2.6 3.2 7.8 2.7 3.4 8.1 2.7 3.4 8.1 2.7 3.4 8.1 2.8 3.6 8.4 2.8 3.6 8.4 2.8 3.6 8.4 2.9 3.8 8.7 2.9 3.8 8.7 2.9 3.8 8.7 3.0 4.0 9.0 3.0 4.0 9.0 3.0 4.0 9.0 3.1 4.2 9.3 3.1 4.2 9.3 3.1 4.2 9.3 3.2 4.4 9.6 3.2 4.4 9.6 3.2 4.4 9.6 3.3 4.6 9.9 3.3 4.6 9.9 3.3 4.6 9.9 3.4 4.8 10.2 3.4 4.8 10.2 3.4 4.8 10.2 3.5 5.0 10.5 3.5 5.0 10.5 3.5 5.0 10.5 3.6 5.2 10.8 3.6 5.2 10.8 3.6 5.2 10.8 3.7 5.4 11.1 3.7 5.4 11.1 3.7 5.4 11.1 3.8 5.6 11.4 3.8 5.6 11.4 3.8 5.6 11.4 3.9 5.8 11.7 3.9 5.8 11.7 3.9 5.8 11.7 4.0 6.0 12.0 4.0 6.0 12.0 4.0 6.0 12.0 4.1 6.2 12.3 4.1 6.2 12.3 4.1 6.2 12.3 4.2 6.4 12.6 4.2 6.4 12.6 4.2 6.4 12.6 4.3 6.6 12.9 4.3 6.6 12.9 4.3 6.6 12.9 4.4 6.8 13.2 4.4 6.8 13.2 4.4 6.8 13.2 4.5 7.0 13.5 4.5 7.0 13.5 4.5 7.0 13.5 4.6 7.2 13.8 4.6 7.2 13.8 4.6 7.2 13.8 4.7 7.4 14.1 4.7 7.4 14.1 4.7 7.4 14.1 4.8 7.6 14.4 4.8 7.6 14.4 4.8 7.6 14.4 4.9 7.8 14.7 4.9 7.8 14.7 4.9 7.8 14.7 5.0 8.0 15.0 5.0 8.0 15.0 5.0 8.0 15.0 5.1 8.2 15.3 5.1 8.2 15.3 5.1 8.2 15.3 5.2 8.4 15.6 5.2 8.4 15.6 5.2 8.4 15.6 5.3 8.6 15.9 5.3 8.6 15.9 5.3 8.6 15.9 5.4 8.8 16.2 5.4 8.8 16.2 5.4 8.8 16.2 5.5 9.0 16.5 5.5 9.0 16.5 5.5 9.0 16.5 5.6 9.2 16.8 5.6 9.2 16.8 5.6 9.2 16.8 5.7 9.4 17.1 5.7 9.4 17.1 5.7 9.4 17.1 5.8 9.6 17.4 5.8 9.6 17.4 5.8 9.6 17.4 5.9 9.8 17.7 5.9 9.8 17.7 5.9 9.8 17.7 6.0 10.0 18.0 6.0 10.0 18.0 6.0 10.0 18.0 6.1 10.2 18.3 6.1 10.2 18.3 6.1 10.2 18.3 6.2 10.4 18.6 6.2 10.4 18.6 6.2 10.4 18.6 6.3 10.6 18.9 6.3 10.6 18.9 6.3 10.6 18.9 6.4 10.8 19.2 6.4 10.8 19.2 6.4 10.8 19.2 6.5 11.0 19.5 6.5 11.0 19.5 6.5 11.0 19.5 6.6 11.2 19.8 6.6 11.2 19.8 6.6 11.2 19.8 6.7 11.4 20.1 6.7 11.4 20.1 6.7 11.4 20.1 6.8 11.6 20.4 6.8 11.6 20.4 6.8 11.6 20.4 6.9 11.8 20.7 6.9 11.8 20.7 6.9 11.8 20.7 7.0 12.0 21.0 7.0 12.0 21.0 7.0 12.0 21.0 7.1 12.2 21.3 7.1 12.2 21.3 7.1 12.2 21.3 7.2 12.4 21.6 7.2 12.4 21.6 7.2 12.4 21.6 7.3 12.6 21.9 7.3 12.6 21.9 7.3 12.6 21.9 7.4 12.8 22.2 7.4 12.8 22.2 7.4 12.8 22.2 7.5 13.0 22.5 7.5 13.0 22.5 7.5 13.0 22.5 7.6 13.2 22.8 7.6 13.2 22.8 7.6 13.2 22.8 7.7 13.4 23.1 7.7 13.4 23.1 7.7 13.4 23.1 7.8 13.6 23.4 7.8 13.6 23.4 7.8 13.6 23.4 7.9 13.8 23.7 7.9 13.8 23.7 7.9 13.8 23.7 8.0 14.0 24.0 8.0 14.0 24.0 8.0 14.0 24.0 8.1 14.2 24.3 8.1 14.2 24.3 8.1 14.2 24.3 8.2 14.4 24.6 8.2 14.4 24.6 8.2 14.4 24.6 8.3 14.6 24.9 8.3 14.6 24.9 8.3 14.6 24.9 8.4 14.8 25.2 8.4 14.8 25.2 8.4 14.8 25.2 8.5 15.0 25.5 8.5 15.0 25.5 8.5 15.0 25.5 8.6 15.2 25.8 8.6 15.2 25.8 8.6 15.2 25.8 8.7 15.4 26.1 8.7 15.4 26.1 8.7 15.4 26.1 8.8 15.6 26.4 8.8 15.6 26.4 8.8 15.6 26.4 8.9 15.8 26.7 8.9 15.8 26.7 8.9 15.8 26.7 9.0 16.0 27.0 9.0 16.0 27.0 9.0 16.0 27.0 9.1 16.2 27.3 9.1 16.2 27.3 9.1 16.2 27.3 9.2 16.4 27.6 9.2 16.4 27.6 9.2 16.4 27.6 9.3 16.6 27.9 9.3 16.6 27.9 9.3 16.6 27.9 9.4 16.8 28.2 9.4 16.8 28.2 9.4 16.8 28.2 9.5 17.0 28.5 9.5 17.0 28.5 9.5 17.0 28.5 9.6 17.2 28.8 9.6 17.2 28.8 9.6 17.2 28.8 9.7 17.4 29.1 9.7 17.4 29.1 9.7 17.4 29.1 9.8 17.6 29.4 9.8 17.6 29.4 9.8 17.6 29.4 9.9 17.8 29.7 9.9 17.8 29.7 9.9 17.8 29.7 10.0 18.0 30.0 10.0 18.0 30.0 10.0 18.0 30.0 10.1 18.2 30.3 10.1 18.2 30.3 10.1 18.2 30.3 10.2 18.4 30.6 10.2 18.4 30.6 10.2 18.4 30.6 10.3 18.6 30.9 10.3 18.6 30.9 10.3 18.6 30.9 10.4 18.8 31.2 10.4 18.8 31.2 10.4 18.8 31.2 10.5 19.0 31.5 10.5 19.0 31.5 10.5 19.0 31.5 10.6 19.2 31.8 10.6 19.2 31.8 10.6 19.2 31.8 10.7 19.4 32.1 10.7 19.4 32.1 10.7 19.4 32.1 10.8 19.6 32.4 10.8 19.6 32.4 10.8 19.6 32.4 10.9 19.8 32.7 10.9 19.8 32.7 10.9 19.8 32.7 11.0 20.0 33.0 11.0 20.0 33.0 11.0 20.0 33.0 11.1 20.2 33.3 11.1 20.2 33.3 11.1 20.2 33.3 11.2 20.4 33.6 11.2 20.4 33.6 11.2 20.4 33.6 11.3 20.6 33.9 11.3 20.6 33.9 11.3 20.6 33.9 11.4 20.8 34.2 11.4 20.8 34.2 11.4 20.8 34.2 11.5 21.0 34.5 11.5 21.0 34.5 11.5 21.0 34.5 11.6 21.2 34.8 11.6 21.2 34.8 11.6 21.2 34.8 11.7 21.4 35.1 11.7 21.4 35.1 11.7 21.4 35.1 11.8 21.6 35.4 11.8 21.6 35.4 11.8 21.6 35.4 11.9 21.8 35.7 11.9 21.8 35.7 11.9 21.8 35.7 12.0 22.0 36.0 12.0 22.0 36.0 12.0 22.0 36.0 12.1 22.2 36.3 12.1 22.2 36.3 12.1 22.2 36.3 12.2 22.4 36.6 12.2 22.4 36.6 12.2 22.4 36.6 12.3 22.6 36.9 12.3 22.6 36.9 12.3 22.6 36.9 12.4 22.8 37.2 12.4 22.8 37.2 12.4 22.8 37.2 12.5 23.0 37.5 12.5 23.0 37.5 12.5 23.0 37.5 12.6 23.2 37.8 12.6 23.2 37.8 12.6 23.2 37.8 12.7 23.4 38.1 12.7 23.4 38.1 12.7 23.4 38.1 12.8 23.6 38.4 12.8 23.6 38.4 12.8 23.6 38.4 12.9 23.8 38.7 12.9 23.8 38.7 12.9 23.8 38.7 13.0 24.0 39.0 13.0 24.0 39.0 13.0 24.0 39.0 13.1 24.2 39.3 13.1 24.2 39.3 13.1 24.2 39.3 13.2 24.4 39.6 13.2 24.4 39.6 13.2 24.4 39.6 13.3 24.6 39.9 13.3 24.6 39.9 13.3 24.6 39.9 13.4 24.8 40.2 13.4 24.8 40.2 13.4 24.8 40.2 13.5 25.0 40.5 13.5 25.0 40.5 13.5 25.0 40.5 13.6 25.2 40.8 13.6 25.2 40.8 13.6 25.2 40.8 13.7 25.4 41.1 13.7 25.4 41.1 13.7 25.4 41.1 13.8 25.6 41.4 13.8 25.6 41.4 13.8 25.6 41.4 13.9 25.8 41.7 13.9 25.8 41.7 13.9 25.8 41.7 14.0 26.0 42.0 14.0 26.0 42.0 14.0 26.0 42.0 14.1 26.2 42.3 14.1 26.2 42.3 14.1 26.2 42.3 14.2 26.4 42.6 14.2 26.4 42.6 14.2 26.4 42.6 14.3 26.6 42.9 14.3 26.6 42.9 14.3 26.6 42.9 14.4 26.8 43.2 14.4 26.8 43.2 14.4 26.8 43.2 14.5 27.0 43.5 14.5 27.0 43.5 14.5 27.0 43.5 14.6 27.2 43.8 14.6 27.2 43.8 14.6 27.2 43.8 14.7 27.4 44.1 14.7 27.4 44.1 14.7 27.4 44.1 14.8 27.6 44.4 14.8 27.6 44.4 14.8 27.6 44.4 14.9 27.8 44.7 14.9 27.8 44.7 14.9 27.8 44.7 15.0 28.0 45.0 15.0 28.0 45.0 15.0 28.0 45.0 15.1 28.2 45.3 15.1 28.2 45.3 15.1 28.2 45.3 15.2 28.4 45.6 15.2 28.4 45.6 15.2 28.4 45.6 15.3 28.6 45.9 15.3 28.6 45.9 15.3 28.6 45.9 15.4 28.8 46.2 15.4 28.8 46.2 15.4 28.8 46.2 15.5 29.0 46.5 15.5 29.0 46.5 15.5 29.0 46.5 15.6 29.2 46.8 15.6 29.2 46.8 15.6 29.2 46.8 15.7 29.4 47.1 15.7 29.4 47.1 15.7 29.4 47.1 15.8 29.6 47.4 15.8 29.6 47.4 15.8 29.6 47.4 15.9 29.8 47.7 15.9 29.8 47.7 15.9 29.8 47.7 16.0 30.0 48.0 16.0 30.0 48.0 16.0 30.0 48.0 16.1 30.2 48.3 16.1 30.2 48.3 16.1 30.2 48.3 16.2 30.4 48.6 16.2 30.4 48.6 16.2 30.4 48.6 16.3 30.6 48.9 16.3 30.6 48.9 16.3 30.6 48.9 16.4 30.8 49.2 16.4 30.8 49.2 16.4 30.8 49.2 16.5 31.0 49.5 16.5 31.0 49.5 16.5 31.0 49.5 16.6 31.2 49.8 16.6 31.2 49.8 16.6 31.2 49.8 16.7 31.4 50.1 16.7 31.4 50.1 16.7 31.4 50.1 16.8 31.6 50.4 16.8 31.6 50.4 16.8 31.6 50.4 16.9 31.8 50.7 16.9 31.8 50.7 16.9 31.8 50.7 17.0 32.0 51.0 17.0 32.0 51.0 17.0 32.0 51.0 17.1 32.2 51.3 17.1 32.2 51.3 17.1 32.2 51.3)\n\tstart = 1991.jan\n\tuser = (beforecny betweencny aftercny beforemoon betweenmoon aftermoon beforemidfall betweenmidfall aftermidfall)\n\tusertype = (holiday holiday holiday holiday2 holiday2 holiday2 holiday3 holiday3 holiday3)\n\tvariables = (ao1995.sep ao1997.jan ao1997.feb)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 0)\n}")
    @test contains(s, "check { }")
    @test contains(s, "forecast {\n\tmaxlead = 12\n}")
    @test contains(s, "estimate { }")
    
end

@testset "Seats" begin

    # Manual example 1
    ts = TSeries(1987M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:auto)
    X13.regression!(spec; aictest=:td)
    X13.automdl!(spec)
    X13.outlier!(spec, types=[:ao, :ls, :tc])
    X13.forecast!(spec, maxlead=36)
    X13.seats!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = auto\n}")
    @test contains(s, "regression {\n\taictest = td\n}")
    @test contains(s, "automdl { }")
    @test contains(s, "forecast {\n\tmaxlead = 36\n}")
    @test contains(s, "outlier {\n\ttypes = (ao ls tc)\n}")
    @test contains(s, "seats { }")

    # Manual example 2
    ts = TSeries(1990Q1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; aictest=:td)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=12)
    X13.seats!(spec, finite=true)
    X13.history!(spec, estimates=[:sadj, :trend])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\taictest = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 12\n}")
    @test contains(s, "seats {\n\tfinite = yes\n}")
    @test contains(s, "history {\n\testimates = (sadj trend)\n}")

    # Manual example 3
    ts = TSeries(MIT{YPFrequency{6}}(1995*6), collect(1:50))
    xts = X13.series(ts, title="Model based adjustment of Bimonthly exports")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; aictest=:td)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec, types=[:ao, :ls, :tc])
    X13.forecast!(spec, maxlead=18)
    X13.seats!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\taictest = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "outlier {\n\ttypes = (ao ls tc)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 18\n}")
    @test contains(s, "seats { }")

end

@testset "Series" begin

    # Manual example 1
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="A simple example")
    spec = X13.X13spec(xts)
    s = X13.x13write(spec, test=true)
    @test contains(s, "series {\n\tdata = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50)\n\tstart = 1967.jan\n\ttitle = \"A simple example\"\n}")
    
    # Manual example 2
    ts = TSeries(1940Q1, collect(1:250))
    xts = X13.series(ts, span=1964Q1:1990Q4)
    spec = X13.X13spec(xts)
    s = X13.x13write(spec, test=true)
    @test contains(s, "series {\n\tdata = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250)\n\tperiod = 4\n\tspan = (1964.1, 1990.4)\n\tstart = 1940.1\n}")
    
    # Manual example 6
    ts = TSeries(1976M1, collect(1.0:0.1:25.0))
    xts = X13.series(ts, span=first(rangeof(ts)):1992M12, comptype=:add, decimals=2)
    spec = X13.X13spec(xts)
    s = X13.x13write(spec, test=true)
    @test contains(s, "series {\n\tcomptype = add\n\tdata = (1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9.0 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 11.0 11.1 11.2 11.3 11.4 11.5 11.6 11.7 11.8 11.9 12.0 12.1 12.2 12.3 12.4 12.5 12.6 12.7 12.8 12.9 13.0 13.1 13.2 13.3 13.4 13.5 13.6 13.7 13.8 13.9 14.0 14.1 14.2 14.3 14.4 14.5 14.6 14.7 14.8 14.9 15.0 15.1 15.2 15.3 15.4 15.5 15.6 15.7 15.8 15.9 16.0 16.1 16.2 16.3 16.4 16.5 16.6 16.7 16.8 16.9 17.0 17.1 17.2 17.3 17.4 17.5 17.6 17.7 17.8 17.9 18.0 18.1 18.2 18.3 18.4 18.5 18.6 18.7 18.8 18.9 19.0 19.1 19.2 19.3 19.4 19.5 19.6 19.7 19.8 19.9 20.0 20.1 20.2 20.3 20.4 20.5 20.6 20.7 20.8 20.9 21.0 21.1 21.2 21.3 21.4 21.5 21.6 21.7 21.8 21.9 22.0 22.1 22.2 22.3 22.4 22.5 22.6 22.7 22.8 22.9 23.0 23.1 23.2 23.3 23.4 23.5 23.6 23.7 23.8 23.9 24.0 24.1 24.2 24.3 24.4 24.5 24.6 24.7 24.8 24.9 25.0)\n\tdecimals = 2\n\tspan = (1976.jan, 1992.dec)\n\tstart = 1976.jan\n}")
    
end

@testset "Slidingspans" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Tourist")
    spec = X13.X13spec(xts)
    X13.x11!(spec; seasonalma=:s3x9)
    X13.slidingspans!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "slidingspans { }")

    # Manual example 2
    ts = TSeries(1967Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly stock prices on NASDAQ")
    spec = X13.X13spec(xts)
    X13.x11!(spec; seasonalma=[:s3x9, :s3x9, :s3x5, :s3x5], trendma=7, mode=:logadd)
    X13.slidingspans!(spec, cutseas = 5.0, cutchng = 5.0)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tmode = logadd\n\tseasonalma = (s3x9 s3x9 s3x5 s3x5)\n\ttrendma = 7\n}")
    @test contains(s, "slidingspans {\n\tcutchng = 5.0\n\tcutseas = 5.0\n}")

    # Manual example 3
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Number of employed machinists - X-11")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables = [:const, :td, X13.rp(1982M5,1982M10)])
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.outlier!(spec)
    X13.estimate!(spec)
    X13.check!(spec)
    X13.forecast!(spec)
    X13.x11!(spec, mode=:add)
    X13.slidingspans!(spec, outlier=:keep, length=144)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const td rp1982.may-1982.oct)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    @test contains(s, "forecast { }")
    @test contains(s, "x11 {\n\tmode = add\n}")
    @test contains(s, "slidingspans {\n\tlength = 144\n\toutlier = keep\n}")

    # Manual example 4
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Number of employed machinists - Seats")
    spec = X13.X13spec(xts)
    X13.regression!(spec; variables = [:const, :td, X13.rp(1982M5,1982M10)])
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.outlier!(spec)
    X13.estimate!(spec)
    X13.check!(spec)
    X13.forecast!(spec)
    X13.seats!(spec)
    X13.slidingspans!(spec, outlier=:keep, length=144)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const td rp1982.may-1982.oct)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    @test contains(s, "forecast { }")
    @test contains(s, "seats { }")
    @test contains(s, "slidingspans {\n\tlength = 144\n\toutlier = keep\n}")

    # Manual example 5
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Cheese sales in Wisconsin")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec; variables = [:const, :seasonal, :tdnolpyear])
    X13.arima!(spec, X13.ArimaModel(3,1,0))
    X13.forecast!(spec, maxlead=60)
    X13.x11!(spec, appendfcst=true)
    X13.slidingspans!(spec, fixmdl=false)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (const seasonal tdnolpyear)\n}")
    @test contains(s, "arima {\n\tmodel = (3 1 0)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 60\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n}")
    @test contains(s, "slidingspans {\n\tfixmdl = no\n}")

    # Manual example 6
    ts = TSeries(1967Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly stock prices on NASDAQ")
    spec = X13.X13spec(xts)
    X13.x11!(spec; seasonalma=:s3x9)
    X13.slidingspans!(spec, length=40, numspans=3)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "slidingspans {\n\tlength = 40\n\tnumspans = 3\n}")
   
end

@testset "Spectrum" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Klaatu")
    spec = X13.X13spec(xts)
    X13.x11!(spec; seasonalma=:s3x9, trendma=23)
    X13.spectrum!(spec, logqs=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n\ttrendma = 23\n}")
    @test contains(s, "spectrum {\n\tlogqs = yes\n}")

    # Manual example 2
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Spectrum analysis of Building Permits Series")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.spectrum!(spec, start=1987M1)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "spectrum {\n\tstart = 1987.jan\n}")

    # Manual example 3
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="TOTAL ONE-FAMILY Housing Starts")
    spec = X13.X13spec(xts)
    X13.x11!(spec; seasonalma=[:s3x9], title="Composite adj. of 1-Family housing starts")
    X13.spectrum!(spec, type=:periodgram)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = (s3x9)\n\ttitle = \"Composite adj. of 1-Family housing starts\"\n}")
    @test contains(s, "spectrum {\n\ttype = periodgram\n}")

    # Manual example 4
    ts = TSeries(1988M1, collect(1:50))
    xts = X13.series(ts, title="Total U.S. Retail Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:td, X13.easter(8), X13.labor(8)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.forecast!(spec, maxlead=60)
    X13.spectrum!(spec, logqs=true, qcheck=true)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (td easter[8] labor[8])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 60\n}")
    @test contains(s, "spectrum {\n\tlogqs = yes\n\tqcheck = yes\n}")
    @test contains(s, "x11 { }")

end

@testset "Transform" begin

    # Manual example 1
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Transform example")
    spec = X13.X13spec(xts)
    X13.transform!(spec; data=TSeries(1967M1,collect(0.1:0.1:5.0)), mode=:ratio, adjust=:lom)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tadjust = lom\n\tdata = (0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0)\n\tmode = ratio\n\tstart = 1967.jan\n}")
    
    # Manual example 2
    ts = TSeries(1997Q1, collect(1:50))
    xts = X13.series(ts, title="Transform example")
    spec = X13.X13spec(xts)
    X13.transform!(spec; constant=45.0, func=:auto)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = auto\n\tconstant = 45.0\n}")

    # Manual example 3
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Total U.S. Retail Sales --- Current Dollars")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log, data=TSeries(1970M1,collect(0.1:0.1:17.0)), title="Consumer Price Index" )
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tdata = (0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9.0 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 11.0 11.1 11.2 11.3 11.4 11.5 11.6 11.7 11.8 11.9 12.0 12.1 12.2 12.3 12.4 12.5 12.6 12.7 12.8 12.9 13.0 13.1 13.2 13.3 13.4 13.5 13.6 13.7 13.8 13.9 14.0 14.1 14.2 14.3 14.4 14.5 14.6 14.7 14.8 14.9 15.0 15.1 15.2 15.3 15.4 15.5 15.6 15.7 15.8 15.9 16.0 16.1 16.2 16.3 16.4 16.5 16.6 16.7 16.8 16.9 17.0)\n\tfunction = log\n\tstart = 1970.jan\n\ttitle = \"Consumer Price Index\"\n}")

    # Manual example 4
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Total U.S. Retail Sales --- Current Dollars")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log, data=TSeries(1970M1,collect(0.1:0.1:17.0)), title="Consumer Price Index", type=:temporary)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tdata = (0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9.0 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 11.0 11.1 11.2 11.3 11.4 11.5 11.6 11.7 11.8 11.9 12.0 12.1 12.2 12.3 12.4 12.5 12.6 12.7 12.8 12.9 13.0 13.1 13.2 13.3 13.4 13.5 13.6 13.7 13.8 13.9 14.0 14.1 14.2 14.3 14.4 14.5 14.6 14.7 14.8 14.9 15.0 15.1 15.2 15.3 15.4 15.5 15.6 15.7 15.8 15.9 16.0 16.1 16.2 16.3 16.4 16.5 16.6 16.7 16.8 16.9 17.0)\n\tfunction = log\n\tstart = 1970.jan\n\ttitle = \"Consumer Price Index\"\n\ttype = temporary\n}")
    
    # Manual example 5
    ts = TSeries(1901Q1, collect(1:50))
    xts = X13.series(ts, title="Annual Rainfall")
    spec = X13.X13spec(xts)
    X13.transform!(spec; power=.3333)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tpower = 0.3333\n}")

    # Manual example 6
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Annual Rainfall")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:log, 
        data=MVTSeries(1970M1,[:cpi, :strike], hcat(collect(0.1:0.1:17.0), collect(17.0:-0.1:0.1))), 
        title="Consumer Price Index & Strike Effect"
    )
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tdata = (0.1 17.0 0.2 16.9 0.3 16.8 0.4 16.7 0.5 16.6 0.6 16.5 0.7 16.4 0.8 16.3 0.9 16.2 1.0 16.1 1.1 16.0 1.2 15.9 1.3 15.8 1.4 15.7 1.5 15.6 1.6 15.5 1.7 15.4 1.8 15.3 1.9 15.2 2.0 15.1 2.1 15.0 2.2 14.9 2.3 14.8 2.4 14.7 2.5 14.6 2.6 14.5 2.7 14.4 2.8 14.3 2.9 14.2 3.0 14.1 3.1 14.0 3.2 13.9 3.3 13.8 3.4 13.7 3.5 13.6 3.6 13.5 3.7 13.4 3.8 13.3 3.9 13.2 4.0 13.1 4.1 13.0 4.2 12.9 4.3 12.8 4.4 12.7 4.5 12.6 4.6 12.5 4.7 12.4 4.8 12.3 4.9 12.2 5.0 12.1 5.1 12.0 5.2 11.9 5.3 11.8 5.4 11.7 5.5 11.6 5.6 11.5 5.7 11.4 5.8 11.3 5.9 11.2 6.0 11.1 6.1 11.0 6.2 10.9 6.3 10.8 6.4 10.7 6.5 10.6 6.6 10.5 6.7 10.4 6.8 10.3 6.9 10.2 7.0 10.1 7.1 10.0 7.2 9.9 7.3 9.8 7.4 9.7 7.5 9.6 7.6 9.5 7.7 9.4 7.8 9.3 7.9 9.2 8.0 9.1 8.1 9.0 8.2 8.9 8.3 8.8 8.4 8.7 8.5 8.6 8.6 8.5 8.7 8.4 8.8 8.3 8.9 8.2 9.0 8.1 9.1 8.0 9.2 7.9 9.3 7.8 9.4 7.7 9.5 7.6 9.6 7.5 9.7 7.4 9.8 7.3 9.9 7.2 10.0 7.1 10.1 7.0 10.2 6.9 10.3 6.8 10.4 6.7 10.5 6.6 10.6 6.5 10.7 6.4 10.8 6.3 10.9 6.2 11.0 6.1 11.1 6.0 11.2 5.9 11.3 5.8 11.4 5.7 11.5 5.6 11.6 5.5 11.7 5.4 11.8 5.3 11.9 5.2 12.0 5.1 12.1 5.0 12.2 4.9 12.3 4.8 12.4 4.7 12.5 4.6 12.6 4.5 12.7 4.4 12.8 4.3 12.9 4.2 13.0 4.1 13.1 4.0 13.2 3.9 13.3 3.8 13.4 3.7 13.5 3.6 13.6 3.5 13.7 3.4 13.8 3.3 13.9 3.2 14.0 3.1 14.1 3.0 14.2 2.9 14.3 2.8 14.4 2.7 14.5 2.6 14.6 2.5 14.7 2.4 14.8 2.3 14.9 2.2 15.0 2.1 15.1 2.0 15.2 1.9 15.3 1.8 15.4 1.7 15.5 1.6 15.6 1.5 15.7 1.4 15.8 1.3 15.9 1.2 16.0 1.1 16.1 1.0 16.2 0.9 16.3 0.8 16.4 0.7 16.5 0.6 16.6 0.5 16.7 0.4 16.8 0.3 16.9 0.2 17.0 0.1)\n\tfunction = log\n\tname = (cpi strike)\n\tstart = 1970.jan\n\ttitle = \"Consumer Price Index & Strike Effect\"\n}")
    
    # Manual example 7
    ts = TSeries(1978M1, collect(1:50))
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec; func=:auto, aicdiff=0.0)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\taicdiff = 0.0\n\tfunction = auto\n}")

end


@testset "x11" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Klaatu")
    spec = X13.X13spec(xts)
    X13.x11!(spec)
    X13.spectrum!(spec, logqs=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Klaatu")
    spec = X13.X13spec(xts)
    X13.x11!(spec, seasonalma=:s3x9, trendma=23)
    X13.x11regression!(spec, variables=:td, aictest=:td)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11regression {\n\taictest = td\n\tvariables = td\n}")
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n\ttrendma = 23\n}")

    # Manual example 3
    ts = TSeries(1967Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly housing starts")
    spec = X13.X13spec(xts)
    X13.x11!(spec, seasonalma=[:s3x3, :s3x3, :s3x5, :s3x5], trendma=7)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = (s3x3 s3x3 s3x5 s3x5)\n\ttrendma = 7\n}")

    # Manual example 4
    ts = TSeries(1969M7, collect(1:150))
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.X13spec(xts)
    X13.regression!(spec, variables=[:const, :td, X13.ls(1972M5), X13.ls(1976M10)])
    X13.arima!(spec, X13.ArimaModel(0,1,2,1,1,0))
    X13.estimate!(spec)
    X13.forecast!(spec, maxlead=0)
    X13.x11!(spec, mode=:add, sigmalim=[2.0, 3.5])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const td ls1972.may ls1976.oct)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(1 1 0)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "forecast {\n\tmaxlead = 0\n}")
    @test contains(s, "x11 {\n\tmode = add\n\tsigmalim = (2.0, 3.5)\n}")

    # Manual example 5
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Unit Auto Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[:const, :td], 
        data=MVTSeries(1975M1, [:sale88, :sale90], hcat(collect(1.0:0.1:19.1),collect(3.0:0.3:57.3)))
    )
    X13.arima!(spec, X13.ArimaSpec(3,1,0), X13.ArimaSpec(0,1,1,12))
    X13.forecast!(spec, maxlead=12, maxback=12)
    X13.x11!(spec, title=["Unit Auto Sales", "Adjusted for special sales in 1988, 1990"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (1.0 3.0 1.1 3.3 1.2 3.6 1.3 3.9 1.4 4.2 1.5 4.5 1.6 4.8 1.7 5.1 1.8 5.4 1.9 5.7 2.0 6.0 2.1 6.3 2.2 6.6 2.3 6.9 2.4 7.2 2.5 7.5 2.6 7.8 2.7 8.1 2.8 8.4 2.9 8.7 3.0 9.0 3.1 9.3 3.2 9.6 3.3 9.9 3.4 10.2 3.5 10.5 3.6 10.8 3.7 11.1 3.8 11.4 3.9 11.7 4.0 12.0 4.1 12.3 4.2 12.6 4.3 12.9 4.4 13.2 4.5 13.5 4.6 13.8 4.7 14.1 4.8 14.4 4.9 14.7 5.0 15.0 5.1 15.3 5.2 15.6 5.3 15.9 5.4 16.2 5.5 16.5 5.6 16.8 5.7 17.1 5.8 17.4 5.9 17.7 6.0 18.0 6.1 18.3 6.2 18.6 6.3 18.9 6.4 19.2 6.5 19.5 6.6 19.8 6.7 20.1 6.8 20.4 6.9 20.7 7.0 21.0 7.1 21.3 7.2 21.6 7.3 21.9 7.4 22.2 7.5 22.5 7.6 22.8 7.7 23.1 7.8 23.4 7.9 23.7 8.0 24.0 8.1 24.3 8.2 24.6 8.3 24.9 8.4 25.2 8.5 25.5 8.6 25.8 8.7 26.1 8.8 26.4 8.9 26.7 9.0 27.0 9.1 27.3 9.2 27.6 9.3 27.9 9.4 28.2 9.5 28.5 9.6 28.8 9.7 29.1 9.8 29.4 9.9 29.7 10.0 30.0 10.1 30.3 10.2 30.6 10.3 30.9 10.4 31.2 10.5 31.5 10.6 31.8 10.7 32.1 10.8 32.4 10.9 32.7 11.0 33.0 11.1 33.3 11.2 33.6 11.3 33.9 11.4 34.2 11.5 34.5 11.6 34.8 11.7 35.1 11.8 35.4 11.9 35.7 12.0 36.0 12.1 36.3 12.2 36.6 12.3 36.9 12.4 37.2 12.5 37.5 12.6 37.8 12.7 38.1 12.8 38.4 12.9 38.7 13.0 39.0 13.1 39.3 13.2 39.6 13.3 39.9 13.4 40.2 13.5 40.5 13.6 40.8 13.7 41.1 13.8 41.4 13.9 41.7 14.0 42.0 14.1 42.3 14.2 42.6 14.3 42.9 14.4 43.2 14.5 43.5 14.6 43.8 14.7 44.1 14.8 44.4 14.9 44.7 15.0 45.0 15.1 45.3 15.2 45.6 15.3 45.9 15.4 46.2 15.5 46.5 15.6 46.8 15.7 47.1 15.8 47.4 15.9 47.7 16.0 48.0 16.1 48.3 16.2 48.6 16.3 48.9 16.4 49.2 16.5 49.5 16.6 49.8 16.7 50.1 16.8 50.4 16.9 50.7 17.0 51.0 17.1 51.3 17.2 51.6 17.3 51.9 17.4 52.2 17.5 52.5 17.6 52.8 17.7 53.1 17.8 53.4 17.9 53.7 18.0 54.0 18.1 54.3 18.2 54.6 18.3 54.9 18.4 55.2 18.5 55.5 18.6 55.8 18.7 56.1 18.8 56.4 18.9 56.7 19.0 57.0 19.1 57.3)\n\tstart = 1975.jan\n\tuser = (sale88 sale90)\n\tvariables = (const td)\n}")
    @test contains(s, "arima {\n\tmodel = (3 1 0)(0 1 1)12\n}")
    @test contains(s, "forecast {\n\tmaxback = 12\n\tmaxlead = 12\n}")
    @test contains(s, "x11 {\n\ttitle = (\"Unit Auto Sales\"\n\t\"Adjusted for special sales in 1988, 1990\")\n}")

    # Manual example 6
    ts = TSeries(1976M1, collect(1:150))
    xts = X13.series(ts, title="NORTHEAST ONE FAMILY Housing Starts")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[X13.ao(1976M2), X13.ao(1978M2), X13.ls(1980M2), X13.ls(1982M11), X13.ao(1984M2)])
    X13.arima!(spec, X13.ArimaModel(0,1,2,0,1,1))
    X13.forecast!(spec, maxlead=60)
    X13.x11!(spec, seasonalma=:s3x9, title="Adjustment of 1 family housing starts")
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (ao1976.feb ao1978.feb ls1980.feb ls1982.nov ao1984.feb)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(0 1 1)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 60\n}")
    @test contains(s, "seasonalma = s3x9\n\ttitle = \"Adjustment of 1 family housing starts\"\n}")

    # Manual example 7
    ts = TSeries(1976M1, collect(1:150))
    xts = X13.series(ts, title="Trend for NORTHEAST ONE FAMILY Housing Starts")
    spec = X13.X13spec(xts)
    X13.regression!(spec, variables=[X13.ls(1980M2), X13.ls(1982M11),])
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.forecast!(spec)
    X13.x11!(spec, type=:trend, trendma=13, sigmalim=[0.7, 1.0], title="Updated Dagum (1996) trend of 1 family housing starts")
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (ls1980.feb ls1982.nov)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "forecast { }")
    @test contains(s, "x11 {\n\tsigmalim = (0.7, 1.0)\n\ttitle = \"Updated Dagum (1996) trend of 1 family housing starts\"\n\ttrendma = 13\n\ttype = trend\n}")

    # Manual example 8
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Automobile sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[:const], 
        data=MVTSeries(1975M1, [:strike80, :strike85, :strike90], hcat(collect(1.0:0.1:8.3),collect(0.0:0.2:14.6),collect(3.0:0.3:24.9)))
    )
    X13.arima!(spec, X13.ArimaSpec(0,1,1), X13.ArimaSpec(0,1,1,12))
    X13.x11!(spec, appendfcst=true, title="Car Sales in the US - Adjust for strikes in 80, 85, 90")
    X13.x11regression!(spec, variables=:td)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (1.0 0.0 3.0 1.1 0.2 3.3 1.2 0.4 3.6 1.3 0.6 3.9 1.4 0.8 4.2 1.5 1.0 4.5 1.6 1.2 4.8 1.7 1.4 5.1 1.8 1.6 5.4 1.9 1.8 5.7 2.0 2.0 6.0 2.1 2.2 6.3 2.2 2.4 6.6 2.3 2.6 6.9 2.4 2.8 7.2 2.5 3.0 7.5 2.6 3.2 7.8 2.7 3.4 8.1 2.8 3.6 8.4 2.9 3.8 8.7 3.0 4.0 9.0 3.1 4.2 9.3 3.2 4.4 9.6 3.3 4.6 9.9 3.4 4.8 10.2 3.5 5.0 10.5 3.6 5.2 10.8 3.7 5.4 11.1 3.8 5.6 11.4 3.9 5.8 11.7 4.0 6.0 12.0 4.1 6.2 12.3 4.2 6.4 12.6 4.3 6.6 12.9 4.4 6.8 13.2 4.5 7.0 13.5 4.6 7.2 13.8 4.7 7.4 14.1 4.8 7.6 14.4 4.9 7.8 14.7 5.0 8.0 15.0 5.1 8.2 15.3 5.2 8.4 15.6 5.3 8.6 15.9 5.4 8.8 16.2 5.5 9.0 16.5 5.6 9.2 16.8 5.7 9.4 17.1 5.8 9.6 17.4 5.9 9.8 17.7 6.0 10.0 18.0 6.1 10.2 18.3 6.2 10.4 18.6 6.3 10.6 18.9 6.4 10.8 19.2 6.5 11.0 19.5 6.6 11.2 19.8 6.7 11.4 20.1 6.8 11.6 20.4 6.9 11.8 20.7 7.0 12.0 21.0 7.1 12.2 21.3 7.2 12.4 21.6 7.3 12.6 21.9 7.4 12.8 22.2 7.5 13.0 22.5 7.6 13.2 22.8 7.7 13.4 23.1 7.8 13.6 23.4 7.9 13.8 23.7 8.0 14.0 24.0 8.1 14.2 24.3 8.2 14.4 24.6 8.3 14.6 24.9)\n\tstart = 1975.jan\n\tuser = (strike80 strike85 strike90)\n\tvariables = (const)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n\ttitle = \"Car Sales in the US - Adjust for strikes in 80, 85, 90\"\n}")
    @test contains(s, "x11regression {\n\tvariables = td\n}")

    # Manual example 9
    ts = TSeries(1978M1, collect(1:50))
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:auto, aicdiff=0.0)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\taicdiff = 0.0\n\tfunction = auto\n}")
    @test contains(s, "x11 { }")
    
end

@testset "x11regression" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Westus")
    spec = X13.X13spec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\tvariables = td\n}")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Westus")
    spec = X13.X13spec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td, aictest=[:td, :easter])
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\taictest = (td easter)\n\tvariables = td\n}")

    # Manual example 3
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Ukclothes")
    spec = X13.X13spec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td, usertype=:holiday, critical=4.0,
        data=MVTSeries(1980M1, [:easter1, :easter2], hcat(collect(0.1:0.1:11),collect(11:-0.1:0.1)))
    )
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\tcritical = 4.0\n\tdata = (0.1 11.0 0.2 10.9 0.3 10.8 0.4 10.7 0.5 10.6 0.6 10.5 0.7 10.4 0.8 10.3 0.9 10.2 1.0 10.1 1.1 10.0 1.2 9.9 1.3 9.8 1.4 9.7 1.5 9.6 1.6 9.5 1.7 9.4 1.8 9.3 1.9 9.2 2.0 9.1 2.1 9.0 2.2 8.9 2.3 8.8 2.4 8.7 2.5 8.6 2.6 8.5 2.7 8.4 2.8 8.3 2.9 8.2 3.0 8.1 3.1 8.0 3.2 7.9 3.3 7.8 3.4 7.7 3.5 7.6 3.6 7.5 3.7 7.4 3.8 7.3 3.9 7.2 4.0 7.1 4.1 7.0 4.2 6.9 4.3 6.8 4.4 6.7 4.5 6.6 4.6 6.5 4.7 6.4 4.8 6.3 4.9 6.2 5.0 6.1 5.1 6.0 5.2 5.9 5.3 5.8 5.4 5.7 5.5 5.6 5.6 5.5 5.7 5.4 5.8 5.3 5.9 5.2 6.0 5.1 6.1 5.0 6.2 4.9 6.3 4.8 6.4 4.7 6.5 4.6 6.6 4.5 6.7 4.4 6.8 4.3 6.9 4.2 7.0 4.1 7.1 4.0 7.2 3.9 7.3 3.8 7.4 3.7 7.5 3.6 7.6 3.5 7.7 3.4 7.8 3.3 7.9 3.2 8.0 3.1 8.1 3.0 8.2 2.9 8.3 2.8 8.4 2.7 8.5 2.6 8.6 2.5 8.7 2.4 8.8 2.3 8.9 2.2 9.0 2.1 9.1 2.0 9.2 1.9 9.3 1.8 9.4 1.7 9.5 1.6 9.6 1.5 9.7 1.4 9.8 1.3 9.9 1.2 10.0 1.1 10.1 1.0 10.2 0.9 10.3 0.8 10.4 0.7 10.5 0.6 10.6 0.5 10.7 0.4 10.8 0.3 10.9 0.2 11.0 0.1)\n\tstart = 1980.jan\n\tuser = (easter1 easter2)\n\tusertype = holiday\n\tvariables = td\n}")

    # Manual example 4
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="nzstarts")
    spec = X13.X13spec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td, tdprior=[1.4, 1.4, 1.4, 1.4, 1.4, 0.0, 0.0])
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\ttdprior = (1.4, 1.4, 1.4, 1.4, 1.4, 0.0, 0.0)\n\tvariables = td\n}")

    # Manual example 5
    ts = TSeries(1964Q1, collect(1:150))
    xts = X13.series(ts, title="MIDWEST ONE FAMILY Housing Starts", span=1964Q1:1989Q3)
    spec = X13.X13spec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=[:td, X13.easter(8)],
        b=[0.4453, 0.8550, -0.3012, 0.2717, -0.1705, 0.0983, -0.0082],
        fixb=[true, true, true, true, true, true, false]
    )
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\tvariables = (td easter[8])\n\tb = (0.4453f,0.855f,-0.3012f,0.2717f,-0.1705f,0.0983f,-0.0082)\n}")

    # Manual example 6
    ts = TSeries(1967M1, collect(1:150))
    xts = X13.series(ts, title="Motor Home Sales", span=X13.Span(1972M1))
    spec = X13.X13spec(xts)
    X13.x11!(spec, seasonalma=:x11default, sigmalim = [1.8, 2.8], appendfcst=true)
    X13.x11regression!(spec, variables=[X13.td(1990M1), X13.easter(8), X13.labor(10), X13.thank(10)])
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tappendfcst = yes\n\tseasonalma = x11default\n\tsigmalim = (1.8, 2.8)\n}")
    @test contains(s, "x11regression {\n\tvariables = (td/1990.jan/ easter[8] labor[10] thank[10])\n}")

    # Manual example 7
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Automobile sales")
    spec = X13.X13spec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[:const], 
        data=MVTSeries(1975M1, [:strike80, :strike85, :strike90], hcat(collect(1.0:0.1:8.3),collect(0.0:0.2:14.6),collect(3.0:0.3:24.9)))
    )
    X13.arima!(spec, X13.ArimaSpec(0,1,1), X13.ArimaSpec(0,1,1,12))
    X13.x11!(spec, title = ["Car Sales in US", "Adjusted for strikes in 80, 85, 90"])
    X13.x11regression!(spec, variables=[:td, X13.easter(8)])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (1.0 0.0 3.0 1.1 0.2 3.3 1.2 0.4 3.6 1.3 0.6 3.9 1.4 0.8 4.2 1.5 1.0 4.5 1.6 1.2 4.8 1.7 1.4 5.1 1.8 1.6 5.4 1.9 1.8 5.7 2.0 2.0 6.0 2.1 2.2 6.3 2.2 2.4 6.6 2.3 2.6 6.9 2.4 2.8 7.2 2.5 3.0 7.5 2.6 3.2 7.8 2.7 3.4 8.1 2.8 3.6 8.4 2.9 3.8 8.7 3.0 4.0 9.0 3.1 4.2 9.3 3.2 4.4 9.6 3.3 4.6 9.9 3.4 4.8 10.2 3.5 5.0 10.5 3.6 5.2 10.8 3.7 5.4 11.1 3.8 5.6 11.4 3.9 5.8 11.7 4.0 6.0 12.0 4.1 6.2 12.3 4.2 6.4 12.6 4.3 6.6 12.9 4.4 6.8 13.2 4.5 7.0 13.5 4.6 7.2 13.8 4.7 7.4 14.1 4.8 7.6 14.4 4.9 7.8 14.7 5.0 8.0 15.0 5.1 8.2 15.3 5.2 8.4 15.6 5.3 8.6 15.9 5.4 8.8 16.2 5.5 9.0 16.5 5.6 9.2 16.8 5.7 9.4 17.1 5.8 9.6 17.4 5.9 9.8 17.7 6.0 10.0 18.0 6.1 10.2 18.3 6.2 10.4 18.6 6.3 10.6 18.9 6.4 10.8 19.2 6.5 11.0 19.5 6.6 11.2 19.8 6.7 11.4 20.1 6.8 11.6 20.4 6.9 11.8 20.7 7.0 12.0 21.0 7.1 12.2 21.3 7.2 12.4 21.6 7.3 12.6 21.9 7.4 12.8 22.2 7.5 13.0 22.5 7.6 13.2 22.8 7.7 13.4 23.1 7.8 13.6 23.4 7.9 13.8 23.7 8.0 14.0 24.0 8.1 14.2 24.3 8.2 14.4 24.6 8.3 14.6 24.9)\n\tstart = 1975.jan\n\tuser = (strike80 strike85 strike90)\n\tvariables = (const)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "x11 {\n\ttitle = (\"Car Sales in US\"\n\t\"Adjusted for strikes in 80, 85, 90\")\n}")
    @test contains(s, "x11regression {\n\tvariables = (td easter[8])\n}")
 
end

@testset "Specification errors" begin
    # invalid aictest when using :td variable
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Unit Auto Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec, variables=[:const, :td], aictest=:lom)
    @test_throws ArgumentError X13.x13write(spec, test=true)

    # invalid mixing of td and tdstock regressors
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Unit Auto Sales")
    spec = X13.X13spec(xts)
    X13.regression!(spec, variables=[:const, :td, :tdstock])
    @test_throws ArgumentError X13.x13write(spec, test=true)
    
end

# TODO: printing of simavec in x11 spec