using Test
using TimeSeriesEcon


@testset "X13 building a spec" begin
    ts = TSeries(2022Q1, collect(1:50))
    spec = X13.newspec(ts)
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
    X13.pickmdl!(spec, [
        X13.ArimaModel(0,1,1,0,1,1; default=true)
        X13.ArimaModel(0,1,2,0,1,1;)
    ])
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


@testset "X13 ArimaSpec construction" begin
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

@testset "X13 Arima writing" begin
    # Manual example 1
    ts = TSeries(1950Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly Grape Harvest")
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaModel(0,1,1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "estimate { }")
    
    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log)
    X13.arima!(spec, X13.ArimaModel(2,1,0,0,1,1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (2 1 0)(0 1 1)\n}")
    @test contains(s, "estimate { }\n")
    @test contains(s, "transform {\n\tfunction = log\n}")
    
    # Manual example 3
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaModel([2],1,0))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = ([2] 1 0)\n}")
    @test contains(s, "estimate { }")
    
    # Manual example 5
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log)
    X13.arima!(spec, X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12); ma = [missing, 1.0], fixma = [false, true])
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n\tma = (,1.0f)\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "transform {\n\tfunction = log\n}")
    
end

@testset "X13 Automdl writing" begin
    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.regression!(spec; aictest=:td)
    X13.automdl!(spec) #savelog argument here...
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "automdl { }")
    @test contains(s, "regression {\n\taictest = td\n}")
    @test contains(s, "x11 { }")
    
end

@testset "X13 Check writing" begin
    # Manual example 1
    ts = TSeries(1964M1, collect(1:150))
    xts = X13.series(ts, title="Monthly Retail Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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

@testset "X13 Estimate writing" begin
    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.estimate!(spec, file="Inven.mdl", fix=:all)
    X13.outlier!(spec, span=X13.Span(2000M1))
    s = X13.x13write(spec, test=true)
    @test contains(s, "estimate {\n\tfile = \"Inven.mdl\"\n\tfix = all\n}")
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "outlier {\n\tspan = (2000.jan, )\n}")
   
   
end

@testset "X13 Force writing" begin
    # Manual example 1
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9)
    X13.force!(spec, start=M10)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "force {\n\tstart = oct\n}")
    
    # Manual example 2
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9)
    X13.force!(spec, start=M10, type=:regress, rho=0.8)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "force {\n\trho = 0.8\n\tstart = oct\n\ttype = regress\n}")
    
    # Manual example 3
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x5)
    X13.force!(spec, type=:none, round=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x5\n}")
    @test contains(s, "force {\n\tround = yes\n\ttype = none\n}")
end

@testset "X13 Forecast writing" begin
    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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

@testset "X13 History writing" begin

    # Manual example 2
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Sales of livestock")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9)
    X13.history!(spec, sadjlags=2)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "history {\n\tsadjlags = 2\n}")
    

    # Manual example 2
    ts = TSeries(1969M7, collect(1:150))
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=:td)
    X13.arima!(spec, X13.ArimaModel(0, 1, 2, 0, 1, 1))
    X13.x11!(spec, seasonalma=:s3x3)
    X13.history!(spec, estimates=[:sadj, :trend])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 2)(0 1 1)\n}")
    @test contains(s, "x11 {\n\tseasonalma = s3x3\n}")
    @test contains(s, "history {\n\testimates = (sadj trend)\n}")
    @test contains(s, "series {\n\tcomptype = add\n\tdata = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 \n\t\t45 46 47 48 49 50)\n\tmodelspan = (, 0.dec)\n\tstart = 1967.jan\n\ttitle = \"Housing Starts in the Midwest\"\n}")
    
end

@testset "X13 Identify writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.identify!(spec, diff=[0, 1], sdiff=[0, 1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n\tsdiff = (0, 1)\n}")
    

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:const, :seasonal])
    X13.identify!(spec, diff=[0, 1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (const seasonal)\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n}")
    
      
    # Manual example 3
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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

@testset "X13 Metadata writing" begin

    # Manual example 1
    ts = TSeries(1964M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Retail Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=:td, aictest=[:td, :easter])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.check!(spec)
    X13.outlier!(spec; types = :all)
    X13.metadata!(spec, "analyst"=>"John J. J. Smith")
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n\taictest = (td easter)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "check { }")
    @test contains(s, "outlier {\n\ttypes = all\n}")
    @test contains(s, "metadata {\n\tkey = \"analyst\"\n\tvalue = \"John J. J. Smith\"\n}")

    # Manual example 2
    ts = TSeries(1964M1, collect(1:150))
    xts = X13.series(ts, title="Monthly Retail Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:td, X13.ao(1967M6), X13.ls(1971M6), X13.easter(8)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.check!(spec)
    X13.metadata!(spec, ["analyst"=>"John J. J. Smith", "spec.updated"=>"October 31, 2006"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (td ao1967.jun ls1971.jun easter[8])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "check { }")
    @test contains(s, "metadata {\n\tkey = (\n\t\t\"analyst\"\n\t\t\"spec.updated\"\n\t)\n\tvalue = (\n\t\t\"John J. J. Smith\"\n\t\t\"October 31, 2006\"\n\t)\n}")

    # Manual example 3
    ts = TSeries(1964M1, collect(1:150))
    xts = X13.series(ts, title="Monthly Retail Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:td, X13.ao(1967M6), X13.ls(1971M6), X13.easter(15)])
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.check!(spec)
    X13.x11!(spec)
    X13.metadata!(spec, ["analyst"=>"John J. J. Smith", "spec.final"=>"November 10, 2006", "key3"=>"AO caused by strike, LS caused by survey change"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (td ao1967.jun ls1971.jun easter[15])\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "check { }")
    @test contains(s, "x11 { }")
    @test contains(s, "metadata {\n\tkey = (\n\t\t\"analyst\"\n\t\t\"spec.final\"\n\t\t\"key3\"\n\t)\n\tvalue = (\n\t\t\"John J. J. Smith\"\n\t\t\"November 10, 2006\"\n\t\t\"AO caused by strike, LS caused by survey change\"\n\t)\n}")
end

@testset "X13 Outlier writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.arima!(spec, X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.outlier!(spec, lsrun=5, types=[:ao, :ls])
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "outlier {\n\tlsrun = 5\n\ttypes = (ao ls)\n}")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:250))
    xts = X13.series(ts, title="Monthly Sales", span=1980M1:1992M12)
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.arima!(spec,  X13.ArimaSpec(0,1,1),X13.ArimaSpec(0,1,1,12))
    X13.estimate!(spec)
    X13.outlier!(spec, critical=[3.0, 4.5, 4.0], types=:all)
    s = X13.x13write(spec, test=true)
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier {\n\tcritical = (3.0, 4.5, 4.0)\n\ttypes = all\n}")

end

@testset "X13 Pickmdl writing" begin

    models = [
        X13.ArimaModel(0,1,1,0,1,1; default=true)
        X13.ArimaModel(0,1,2,0,1,1;)
        X13.ArimaModel(2,1,0,0,1,1;)
        X13.ArimaModel(0,2,2,0,1,1;)
        X13.ArimaModel(2,1,2,0,1,1;)
    ]

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:td, :seasonal])
    X13.pickmdl!(spec, models, mode=:fcst)
    X13.estimate!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (td seasonal)\n}")
    @test contains(s, "pickmdl {\n\tmodels = (0 1 1)(0 1 1) *\n(0 1 2)(0 1 1) X\n(2 1 0)(0 1 1) X\n(0 2 2)(0 1 1) X\n(2 1 2)(0 1 1)\n\tmode = fcst\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "x11 { }")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=:td)
    X13.pickmdl!(spec, models, mode=:fcst, method=:first, fcstlim=20, qlim=10, overdiff=0.99, identify=:all)
    X13.estimate!(spec)
    X13.outlier!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "pickmdl {\n\tfcstlim = 20\n\tmodels = (0 1 1)(0 1 1) *\n(0 1 2)(0 1 1) X\n(2 1 0)(0 1 1) X\n(0 2 2)(0 1 1) X\n(2 1 2)(0 1 1)\n\tidentify = all\n\tmethod = first\n\tmode = fcst\n\toverdiff = 0.99\n\tqlim = 10\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "outlier { }")
    @test contains(s, "x11 { }")

    # Manual example 3
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=:td)
    X13.pickmdl!(spec, models, mode=:fcst, outofsample=true)
    X13.estimate!(spec)
    X13.outlier!(spec)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = td\n}")
    @test contains(s, "pickmdl {\n\tmodels = (0 1 1)(0 1 1) *\n(0 1 2)(0 1 1) X\n(2 1 0)(0 1 1) X\n(0 2 2)(0 1 1) X\n(2 1 2)(0 1 1)\n\tmode = fcst\n\toutofsample = yes\n}")
    @test contains(s, "estimate { }")
    @test contains(s, "x11 { }")

end


# TODO: Regime change documentation
@testset "X13 Regression writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[X13.tdstock1coef(31), X13.easterstock(8)], aictest = [:td, :easter])
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = (tdstock1coef[31] easterstock[8])\n\taictest = (td easter)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "x11 { }")


    # Manual example 6
    ts = TSeries(1990Q1, collect(1:150))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.ao(2007Q1), X13.qi(2005Q2,2005Q4), X13.ao(1998Q1), :td], user=:tls, data=MVTSeries(1990Q1, [:tls], collect(51:200)))
    X13.arima!(spec, X13.ArimaModel(0, 1, 1, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 \n\t\t92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 \n\t\t126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 \n\t\t158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 \n\t\t190 191 192 193 194 195 196 197 198 199 200)\n\tstart = 1990.1\n\tuser = tls\n\tvariables = (ao2007.1 qi2005.2-2005.4 ao1998.1 td)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 9
    ts = TSeries(1981Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=X13.tl(1985Q3,1987Q1))
    X13.identify!(spec, diff=[0,1], sdiff=[0,1])
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tvariables = tl1985.3-1987.1\n}")
    @test contains(s, "identify {\n\tdiff = (0, 1)\n\tsdiff = (0, 1)\n}")

    # Manual example 10
    ts = TSeries(1970M1, collect(1:50))
    xts = X13.series(ts, title="Monthly Riverflow")
    spec = X13.newspec(xts)
    X13.regression!(spec; variables=[:seasonal, :const], data=MVTSeries(1960M1, [:temp, :precip], hcat(collect(1.0:0.1:18),collect(0.0:0.2:34))))
    X13.arima!(spec, X13.ArimaModel(3, 0, 0, 0, 0, 0))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "regression {\n\tdata = (\t1.0\t0.0\n\t1.1\t0.2\n\t1.2\t0.4\n\t1.3\t0.6\n\t1.4\t0.8\n\t1.5\t1.0\n\t1.6\t1.2\n\t1.7\t1.4\n\t1.8\t1.6\n\t1.9\t1.8\n\t2.0\t2.0\n\t2.1\t2.2\n\t2.2\t2.4\n\t2.3\t2.6\n\t2.4\t2.8\n\t2.5\t3.0\n\t2.6\t3.2\n\t2.7\t3.4\n\t2.8\t3.6\n\t2.9\t3.8\n\t3.0\t4.0\n\t3.1\t4.2\n\t3.2\t4.4\n\t3.3\t4.6\n\t3.4\t4.8\n\t3.5\t5.0\n\t3.6\t5.2\n\t3.7\t5.4\n\t3.8\t5.6\n\t3.9\t5.8\n\t4.0\t6.0\n\t4.1\t6.2\n\t4.2\t6.4\n\t4.3\t6.6\n\t4.4\t6.8\n\t4.5\t7.0\n\t4.6\t7.2\n\t4.7\t7.4\n\t4.8\t7.6\n\t4.9\t7.8\n\t5.0\t8.0\n\t5.1\t8.2\n\t5.2\t8.4\n\t5.3\t8.6\n\t5.4\t8.8\n\t5.5\t9.0\n\t5.6\t9.2\n\t5.7\t9.4\n\t5.8\t9.6\n\t5.9\t9.8\n\t6.0\t10.0\n\t6.1\t10.2\n\t6.2\t10.4\n\t6.3\t10.6\n\t6.4\t10.8\n\t6.5\t11.0\n\t6.6\t11.2\n\t6.7\t11.4\n\t6.8\t11.6\n\t6.9\t11.8\n\t7.0\t12.0\n\t7.1\t12.2\n\t7.2\t12.4\n\t7.3\t12.6\n\t7.4\t12.8\n\t7.5\t13.0\n\t7.6\t13.2\n\t7.7\t13.4\n\t7.8\t13.6\n\t7.9\t13.8\n\t8.0\t14.0\n\t8.1\t14.2\n\t8.2\t14.4\n\t8.3\t14.6\n\t8.4\t14.8\n\t8.5\t15.0\n\t8.6\t15.2\n\t8.7\t15.4\n\t8.8\t15.6\n\t8.9\t15.8\n\t9.0\t16.0\n\t9.1\t16.2\n\t9.2\t16.4\n\t9.3\t16.6\n\t9.4\t16.8\n\t9.5\t17.0\n\t9.6\t17.2\n\t9.7\t17.4\n\t9.8\t17.6\n\t9.9\t17.8\n\t10.0\t18.0\n\t10.1\t18.2\n\t10.2\t18.4\n\t10.3\t18.6\n\t10.4\t18.8\n\t10.5\t19.0\n\t10.6\t19.2\n\t10.7\t19.4\n\t10.8\t19.6\n\t10.9\t19.8\n\t11.0\t20.0\n\t11.1\t20.2\n\t11.2\t20.4\n\t11.3\t20.6\n\t11.4\t20.8\n\t11.5\t21.0\n\t11.6\t21.2\n\t11.7\t21.4\n\t11.8\t21.6\n\t11.9\t21.8\n\t12.0\t22.0\n\t12.1\t22.2\n\t12.2\t22.4\n\t12.3\t22.6\n\t12.4\t22.8\n\t12.5\t23.0\n\t12.6\t23.2\n\t12.7\t23.4\n\t12.8\t23.6\n\t12.9\t23.8\n\t13.0\t24.0\n\t13.1\t24.2\n\t13.2\t24.4\n\t13.3\t24.6\n\t13.4\t24.8\n\t13.5\t25.0\n\t13.6\t25.2\n\t13.7\t25.4\n\t13.8\t25.6\n\t13.9\t25.8\n\t14.0\t26.0\n\t14.1\t26.2\n\t14.2\t26.4\n\t14.3\t26.6\n\t14.4\t26.8\n\t14.5\t27.0\n\t14.6\t27.2\n\t14.7\t27.4\n\t14.8\t27.6\n\t14.9\t27.8\n\t15.0\t28.0\n\t15.1\t28.2\n\t15.2\t28.4\n\t15.3\t28.6\n\t15.4\t28.8\n\t15.5\t29.0\n\t15.6\t29.2\n\t15.7\t29.4\n\t15.8\t29.6\n\t15.9\t29.8\n\t16.0\t30.0\n\t16.1\t30.2\n\t16.2\t30.4\n\t16.3\t30.6\n\t16.4\t30.8\n\t16.5\t31.0\n\t16.6\t31.2\n\t16.7\t31.4\n\t16.8\t31.6\n\t16.9\t31.8\n\t17.0\t32.0\n\t17.1\t32.2\n\t17.2\t32.4\n\t17.3\t32.6\n\t17.4\t32.8\n\t17.5\t33.0\n\t17.6\t33.2\n\t17.7\t33.4\n\t17.8\t33.6\n\t17.9\t33.8\n\t18.0\t34.0\t)\n\tstart = 1960.jan\n\tuser = (temp precip)\n\tvariables = (seasonal const)\n}")
    @test contains(s, "arima {\n\tmodel = (3 0 0)(0 0 0)\n}")
    @test contains(s, "estimate { }")

    # Manual example 11
    ts = TSeries(1967M1, collect(1:250))
    xts = X13.series(ts, title="Retail Inventory - Family Apparel", type=:stock)
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[X13.tdstock(31), X13.ao(1980M7)], aictest=:tdstock)
    X13.arima!(spec, X13.ArimaModel(0, 1, 0, 0, 1, 1))
    X13.estimate!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tvariables = (tdstock[31] ao1980.jul)\n\taictest = tdstock\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 0)(0 1 1)\n}")
    @test contains(s, "estimate { }")

    # Manual example 12
    ts = TSeries(1976M1, collect(1:150))
    xts = X13.series(ts, title="Retail Sales - Televisions", type=:flow)
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; variables=[:const, :td, X13.ao(1976M1), X13.ls(1991M12), X13.easter(8), :seasonal],
        data=MVTSeries(1975M1, [:sale88, :sale89, :sale90], hcat(collect(1.0:0.1:28.3),collect(0.0:0.2:54.6),collect(3.0:0.3:84.9)))
    )
    X13.arima!(spec, X13.ArimaModel(2,1,0))
    X13.forecast!(spec, maxlead=24)
    X13.x11!(spec, appendfcst=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (\t1.0\t0.0\t3.0\n\t1.1\t0.2\t3.3\n\t1.2\t0.4\t3.6\n\t1.3\t0.6\t3.9\n\t1.4\t0.8\t4.2\n\t1.5\t1.0\t4.5\n\t1.6\t1.2\t4.8\n\t1.7\t1.4\t5.1\n\t1.8\t1.6\t5.4\n\t1.9\t1.8\t5.7\n\t2.0\t2.0\t6.0\n\t2.1\t2.2\t6.3\n\t2.2\t2.4\t6.6\n\t2.3\t2.6\t6.9\n\t2.4\t2.8\t7.2\n\t2.5\t3.0\t7.5\n\t2.6\t3.2\t7.8\n\t2.7\t3.4\t8.1\n\t2.8\t3.6\t8.4\n\t2.9\t3.8\t8.7\n\t3.0\t4.0\t9.0\n\t3.1\t4.2\t9.3\n\t3.2\t4.4\t9.6\n\t3.3\t4.6\t9.9\n\t3.4\t4.8\t10.2\n\t3.5\t5.0\t10.5\n\t3.6\t5.2\t10.8\n\t3.7\t5.4\t11.1\n\t3.8\t5.6\t11.4\n\t3.9\t5.8\t11.7\n\t4.0\t6.0\t12.0\n\t4.1\t6.2\t12.3\n\t4.2\t6.4\t12.6\n\t4.3\t6.6\t12.9\n\t4.4\t6.8\t13.2\n\t4.5\t7.0\t13.5\n\t4.6\t7.2\t13.8\n\t4.7\t7.4\t14.1\n\t4.8\t7.6\t14.4\n\t4.9\t7.8\t14.7\n\t5.0\t8.0\t15.0\n\t5.1\t8.2\t15.3\n\t5.2\t8.4\t15.6\n\t5.3\t8.6\t15.9\n\t5.4\t8.8\t16.2\n\t5.5\t9.0\t16.5\n\t5.6\t9.2\t16.8\n\t5.7\t9.4\t17.1\n\t5.8\t9.6\t17.4\n\t5.9\t9.8\t17.7\n\t6.0\t10.0\t18.0\n\t6.1\t10.2\t18.3\n\t6.2\t10.4\t18.6\n\t6.3\t10.6\t18.9\n\t6.4\t10.8\t19.2\n\t6.5\t11.0\t19.5\n\t6.6\t11.2\t19.8\n\t6.7\t11.4\t20.1\n\t6.8\t11.6\t20.4\n\t6.9\t11.8\t20.7\n\t7.0\t12.0\t21.0\n\t7.1\t12.2\t21.3\n\t7.2\t12.4\t21.6\n\t7.3\t12.6\t21.9\n\t7.4\t12.8\t22.2\n\t7.5\t13.0\t22.5\n\t7.6\t13.2\t22.8\n\t7.7\t13.4\t23.1\n\t7.8\t13.6\t23.4\n\t7.9\t13.8\t23.7\n\t8.0\t14.0\t24.0\n\t8.1\t14.2\t24.3\n\t8.2\t14.4\t24.6\n\t8.3\t14.6\t24.9\n\t8.4\t14.8\t25.2\n\t8.5\t15.0\t25.5\n\t8.6\t15.2\t25.8\n\t8.7\t15.4\t26.1\n\t8.8\t15.6\t26.4\n\t8.9\t15.8\t26.7\n\t9.0\t16.0\t27.0\n\t9.1\t16.2\t27.3\n\t9.2\t16.4\t27.6\n\t9.3\t16.6\t27.9\n\t9.4\t16.8\t28.2\n\t9.5\t17.0\t28.5\n\t9.6\t17.2\t28.8\n\t9.7\t17.4\t29.1\n\t9.8\t17.6\t29.4\n\t9.9\t17.8\t29.7\n\t10.0\t18.0\t30.0\n\t10.1\t18.2\t30.3\n\t10.2\t18.4\t30.6\n\t10.3\t18.6\t30.9\n\t10.4\t18.8\t31.2\n\t10.5\t19.0\t31.5\n\t10.6\t19.2\t31.8\n\t10.7\t19.4\t32.1\n\t10.8\t19.6\t32.4\n\t10.9\t19.8\t32.7\n\t11.0\t20.0\t33.0\n\t11.1\t20.2\t33.3\n\t11.2\t20.4\t33.6\n\t11.3\t20.6\t33.9\n\t11.4\t20.8\t34.2\n\t11.5\t21.0\t34.5\n\t11.6\t21.2\t34.8\n\t11.7\t21.4\t35.1\n\t11.8\t21.6\t35.4\n\t11.9\t21.8\t35.7\n\t12.0\t22.0\t36.0\n\t12.1\t22.2\t36.3\n\t12.2\t22.4\t36.6\n\t12.3\t22.6\t36.9\n\t12.4\t22.8\t37.2\n\t12.5\t23.0\t37.5\n\t12.6\t23.2\t37.8\n\t12.7\t23.4\t38.1\n\t12.8\t23.6\t38.4\n\t12.9\t23.8\t38.7\n\t13.0\t24.0\t39.0\n\t13.1\t24.2\t39.3\n\t13.2\t24.4\t39.6\n\t13.3\t24.6\t39.9\n\t13.4\t24.8\t40.2\n\t13.5\t25.0\t40.5\n\t13.6\t25.2\t40.8\n\t13.7\t25.4\t41.1\n\t13.8\t25.6\t41.4\n\t13.9\t25.8\t41.7\n\t14.0\t26.0\t42.0\n\t14.1\t26.2\t42.3\n\t14.2\t26.4\t42.6\n\t14.3\t26.6\t42.9\n\t14.4\t26.8\t43.2\n\t14.5\t27.0\t43.5\n\t14.6\t27.2\t43.8\n\t14.7\t27.4\t44.1\n\t14.8\t27.6\t44.4\n\t14.9\t27.8\t44.7\n\t15.0\t28.0\t45.0\n\t15.1\t28.2\t45.3\n\t15.2\t28.4\t45.6\n\t15.3\t28.6\t45.9\n\t15.4\t28.8\t46.2\n\t15.5\t29.0\t46.5\n\t15.6\t29.2\t46.8\n\t15.7\t29.4\t47.1\n\t15.8\t29.6\t47.4\n\t15.9\t29.8\t47.7\n\t16.0\t30.0\t48.0\n\t16.1\t30.2\t48.3\n\t16.2\t30.4\t48.6\n\t16.3\t30.6\t48.9\n\t16.4\t30.8\t49.2\n\t16.5\t31.0\t49.5\n\t16.6\t31.2\t49.8\n\t16.7\t31.4\t50.1\n\t16.8\t31.6\t50.4\n\t16.9\t31.8\t50.7\n\t17.0\t32.0\t51.0\n\t17.1\t32.2\t51.3\n\t17.2\t32.4\t51.6\n\t17.3\t32.6\t51.9\n\t17.4\t32.8\t52.2\n\t17.5\t33.0\t52.5\n\t17.6\t33.2\t52.8\n\t17.7\t33.4\t53.1\n\t17.8\t33.6\t53.4\n\t17.9\t33.8\t53.7\n\t18.0\t34.0\t54.0\n\t18.1\t34.2\t54.3\n\t18.2\t34.4\t54.6\n\t18.3\t34.6\t54.9\n\t18.4\t34.8\t55.2\n\t18.5\t35.0\t55.5\n\t18.6\t35.2\t55.8\n\t18.7\t35.4\t56.1\n\t18.8\t35.6\t56.4\n\t18.9\t35.8\t56.7\n\t19.0\t36.0\t57.0\n\t19.1\t36.2\t57.3\n\t19.2\t36.4\t57.6\n\t19.3\t36.6\t57.9\n\t19.4\t36.8\t58.2\n\t19.5\t37.0\t58.5\n\t19.6\t37.2\t58.8\n\t19.7\t37.4\t59.1\n\t19.8\t37.6\t59.4\n\t19.9\t37.8\t59.7\n\t20.0\t38.0\t60.0\n\t20.1\t38.2\t60.3\n\t20.2\t38.4\t60.6\n\t20.3\t38.6\t60.9\n\t20.4\t38.8\t61.2\n\t20.5\t39.0\t61.5\n\t20.6\t39.2\t61.8\n\t20.7\t39.4\t62.1\n\t20.8\t39.6\t62.4\n\t20.9\t39.8\t62.7\n\t21.0\t40.0\t63.0\n\t21.1\t40.2\t63.3\n\t21.2\t40.4\t63.6\n\t21.3\t40.6\t63.9\n\t21.4\t40.8\t64.2\n\t21.5\t41.0\t64.5\n\t21.6\t41.2\t64.8\n\t21.7\t41.4\t65.1\n\t21.8\t41.6\t65.4\n\t21.9\t41.8\t65.7\n\t22.0\t42.0\t66.0\n\t22.1\t42.2\t66.3\n\t22.2\t42.4\t66.6\n\t22.3\t42.6\t66.9\n\t22.4\t42.8\t67.2\n\t22.5\t43.0\t67.5\n\t22.6\t43.2\t67.8\n\t22.7\t43.4\t68.1\n\t22.8\t43.6\t68.4\n\t22.9\t43.8\t68.7\n\t23.0\t44.0\t69.0\n\t23.1\t44.2\t69.3\n\t23.2\t44.4\t69.6\n\t23.3\t44.6\t69.9\n\t23.4\t44.8\t70.2\n\t23.5\t45.0\t70.5\n\t23.6\t45.2\t70.8\n\t23.7\t45.4\t71.1\n\t23.8\t45.6\t71.4\n\t23.9\t45.8\t71.7\n\t24.0\t46.0\t72.0\n\t24.1\t46.2\t72.3\n\t24.2\t46.4\t72.6\n\t24.3\t46.6\t72.9\n\t24.4\t46.8\t73.2\n\t24.5\t47.0\t73.5\n\t24.6\t47.2\t73.8\n\t24.7\t47.4\t74.1\n\t24.8\t47.6\t74.4\n\t24.9\t47.8\t74.7\n\t25.0\t48.0\t75.0\n\t25.1\t48.2\t75.3\n\t25.2\t48.4\t75.6\n\t25.3\t48.6\t75.9\n\t25.4\t48.8\t76.2\n\t25.5\t49.0\t76.5\n\t25.6\t49.2\t76.8\n\t25.7\t49.4\t77.1\n\t25.8\t49.6\t77.4\n\t25.9\t49.8\t77.7\n\t26.0\t50.0\t78.0\n\t26.1\t50.2\t78.3\n\t26.2\t50.4\t78.6\n\t26.3\t50.6\t78.9\n\t26.4\t50.8\t79.2\n\t26.5\t51.0\t79.5\n\t26.6\t51.2\t79.8\n\t26.7\t51.4\t80.1\n\t26.8\t51.6\t80.4\n\t26.9\t51.8\t80.7\n\t27.0\t52.0\t81.0\n\t27.1\t52.2\t81.3\n\t27.2\t52.4\t81.6\n\t27.3\t52.6\t81.9\n\t27.4\t52.8\t82.2\n\t27.5\t53.0\t82.5\n\t27.6\t53.2\t82.8\n\t27.7\t53.4\t83.1\n\t27.8\t53.6\t83.4\n\t27.9\t53.8\t83.7\n\t28.0\t54.0\t84.0\n\t28.1\t54.2\t84.3\n\t28.2\t54.4\t84.6\n\t28.3\t54.6\t84.9\t)\n\tstart = 1975.jan\n\tuser = (sale88 sale89 sale90)\n\tvariables = (const td ao1976.jan ls1991.dec easter[8] seasonal)\n}")
    @test contains(s, "arima {\n\tmodel = (2 1 0)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n}")

    # Manual example 19
    ts = TSeries(1975M1, collect(1:250))
    xts = X13.series(ts, title="Retail sales of children's apparel")
    spec = X13.newspec(xts)
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
    @test contains(s, "regression {\n\tdata = (\t1.0\t0.0\t3.0\n\t1.1\t0.2\t3.3\n\t1.2\t0.4\t3.6\n\t1.3\t0.6\t3.9\n\t1.4\t0.8\t4.2\n\t1.5\t1.0\t4.5\n\t1.6\t1.2\t4.8\n\t1.7\t1.4\t5.1\n\t1.8\t1.6\t5.4\n\t1.9\t1.8\t5.7\n\t2.0\t2.0\t6.0\n\t2.1\t2.2\t6.3\n\t2.2\t2.4\t6.6\n\t2.3\t2.6\t6.9\n\t2.4\t2.8\t7.2\n\t2.5\t3.0\t7.5\n\t2.6\t3.2\t7.8\n\t2.7\t3.4\t8.1\n\t2.8\t3.6\t8.4\n\t2.9\t3.8\t8.7\n\t3.0\t4.0\t9.0\n\t3.1\t4.2\t9.3\n\t3.2\t4.4\t9.6\n\t3.3\t4.6\t9.9\n\t3.4\t4.8\t10.2\n\t3.5\t5.0\t10.5\n\t3.6\t5.2\t10.8\n\t3.7\t5.4\t11.1\n\t3.8\t5.6\t11.4\n\t3.9\t5.8\t11.7\n\t4.0\t6.0\t12.0\n\t4.1\t6.2\t12.3\n\t4.2\t6.4\t12.6\n\t4.3\t6.6\t12.9\n\t4.4\t6.8\t13.2\n\t4.5\t7.0\t13.5\n\t4.6\t7.2\t13.8\n\t4.7\t7.4\t14.1\n\t4.8\t7.6\t14.4\n\t4.9\t7.8\t14.7\n\t5.0\t8.0\t15.0\n\t5.1\t8.2\t15.3\n\t5.2\t8.4\t15.6\n\t5.3\t8.6\t15.9\n\t5.4\t8.8\t16.2\n\t5.5\t9.0\t16.5\n\t5.6\t9.2\t16.8\n\t5.7\t9.4\t17.1\n\t5.8\t9.6\t17.4\n\t5.9\t9.8\t17.7\n\t6.0\t10.0\t18.0\n\t6.1\t10.2\t18.3\n\t6.2\t10.4\t18.6\n\t6.3\t10.6\t18.9\n\t6.4\t10.8\t19.2\n\t6.5\t11.0\t19.5\n\t6.6\t11.2\t19.8\n\t6.7\t11.4\t20.1\n\t6.8\t11.6\t20.4\n\t6.9\t11.8\t20.7\n\t7.0\t12.0\t21.0\n\t7.1\t12.2\t21.3\n\t7.2\t12.4\t21.6\n\t7.3\t12.6\t21.9\n\t7.4\t12.8\t22.2\n\t7.5\t13.0\t22.5\n\t7.6\t13.2\t22.8\n\t7.7\t13.4\t23.1\n\t7.8\t13.6\t23.4\n\t7.9\t13.8\t23.7\n\t8.0\t14.0\t24.0\n\t8.1\t14.2\t24.3\n\t8.2\t14.4\t24.6\n\t8.3\t14.6\t24.9\n\t8.4\t14.8\t25.2\n\t8.5\t15.0\t25.5\n\t8.6\t15.2\t25.8\n\t8.7\t15.4\t26.1\n\t8.8\t15.6\t26.4\n\t8.9\t15.8\t26.7\n\t9.0\t16.0\t27.0\n\t9.1\t16.2\t27.3\n\t9.2\t16.4\t27.6\n\t9.3\t16.6\t27.9\n\t9.4\t16.8\t28.2\n\t9.5\t17.0\t28.5\n\t9.6\t17.2\t28.8\n\t9.7\t17.4\t29.1\n\t9.8\t17.6\t29.4\n\t9.9\t17.8\t29.7\n\t10.0\t18.0\t30.0\n\t10.1\t18.2\t30.3\n\t10.2\t18.4\t30.6\n\t10.3\t18.6\t30.9\n\t10.4\t18.8\t31.2\n\t10.5\t19.0\t31.5\n\t10.6\t19.2\t31.8\n\t10.7\t19.4\t32.1\n\t10.8\t19.6\t32.4\n\t10.9\t19.8\t32.7\n\t11.0\t20.0\t33.0\n\t11.1\t20.2\t33.3\n\t11.2\t20.4\t33.6\n\t11.3\t20.6\t33.9\n\t11.4\t20.8\t34.2\n\t11.5\t21.0\t34.5\n\t11.6\t21.2\t34.8\n\t11.7\t21.4\t35.1\n\t11.8\t21.6\t35.4\n\t11.9\t21.8\t35.7\n\t12.0\t22.0\t36.0\n\t12.1\t22.2\t36.3\n\t12.2\t22.4\t36.6\n\t12.3\t22.6\t36.9\n\t12.4\t22.8\t37.2\n\t12.5\t23.0\t37.5\n\t12.6\t23.2\t37.8\n\t12.7\t23.4\t38.1\n\t12.8\t23.6\t38.4\n\t12.9\t23.8\t38.7\n\t13.0\t24.0\t39.0\n\t13.1\t24.2\t39.3\n\t13.2\t24.4\t39.6\n\t13.3\t24.6\t39.9\n\t13.4\t24.8\t40.2\n\t13.5\t25.0\t40.5\n\t13.6\t25.2\t40.8\n\t13.7\t25.4\t41.1\n\t13.8\t25.6\t41.4\n\t13.9\t25.8\t41.7\n\t14.0\t26.0\t42.0\n\t14.1\t26.2\t42.3\n\t14.2\t26.4\t42.6\n\t14.3\t26.6\t42.9\n\t14.4\t26.8\t43.2\n\t14.5\t27.0\t43.5\n\t14.6\t27.2\t43.8\n\t14.7\t27.4\t44.1\n\t14.8\t27.6\t44.4\n\t14.9\t27.8\t44.7\n\t15.0\t28.0\t45.0\n\t15.1\t28.2\t45.3\n\t15.2\t28.4\t45.6\n\t15.3\t28.6\t45.9\n\t15.4\t28.8\t46.2\n\t15.5\t29.0\t46.5\n\t15.6\t29.2\t46.8\n\t15.7\t29.4\t47.1\n\t15.8\t29.6\t47.4\n\t15.9\t29.8\t47.7\n\t16.0\t30.0\t48.0\n\t16.1\t30.2\t48.3\n\t16.2\t30.4\t48.6\n\t16.3\t30.6\t48.9\n\t16.4\t30.8\t49.2\n\t16.5\t31.0\t49.5\n\t16.6\t31.2\t49.8\n\t16.7\t31.4\t50.1\n\t16.8\t31.6\t50.4\n\t16.9\t31.8\t50.7\n\t17.0\t32.0\t51.0\n\t17.1\t32.2\t51.3\n\t17.2\t32.4\t51.6\n\t17.3\t32.6\t51.9\n\t17.4\t32.8\t52.2\n\t17.5\t33.0\t52.5\n\t17.6\t33.2\t52.8\n\t17.7\t33.4\t53.1\n\t17.8\t33.6\t53.4\n\t17.9\t33.8\t53.7\n\t18.0\t34.0\t54.0\n\t18.1\t34.2\t54.3\n\t18.2\t34.4\t54.6\n\t18.3\t34.6\t54.9\n\t18.4\t34.8\t55.2\n\t18.5\t35.0\t55.5\n\t18.6\t35.2\t55.8\n\t18.7\t35.4\t56.1\n\t18.8\t35.6\t56.4\n\t18.9\t35.8\t56.7\n\t19.0\t36.0\t57.0\n\t19.1\t36.2\t57.3\n\t19.2\t36.4\t57.6\n\t19.3\t36.6\t57.9\n\t19.4\t36.8\t58.2\n\t19.5\t37.0\t58.5\n\t19.6\t37.2\t58.8\n\t19.7\t37.4\t59.1\n\t19.8\t37.6\t59.4\n\t19.9\t37.8\t59.7\n\t20.0\t38.0\t60.0\n\t20.1\t38.2\t60.3\n\t20.2\t38.4\t60.6\n\t20.3\t38.6\t60.9\n\t20.4\t38.8\t61.2\n\t20.5\t39.0\t61.5\n\t20.6\t39.2\t61.8\n\t20.7\t39.4\t62.1\n\t20.8\t39.6\t62.4\n\t20.9\t39.8\t62.7\n\t21.0\t40.0\t63.0\n\t21.1\t40.2\t63.3\n\t21.2\t40.4\t63.6\n\t21.3\t40.6\t63.9\n\t21.4\t40.8\t64.2\n\t21.5\t41.0\t64.5\n\t21.6\t41.2\t64.8\n\t21.7\t41.4\t65.1\n\t21.8\t41.6\t65.4\n\t21.9\t41.8\t65.7\n\t22.0\t42.0\t66.0\n\t22.1\t42.2\t66.3\n\t22.2\t42.4\t66.6\n\t22.3\t42.6\t66.9\n\t22.4\t42.8\t67.2\n\t22.5\t43.0\t67.5\n\t22.6\t43.2\t67.8\n\t22.7\t43.4\t68.1\n\t22.8\t43.6\t68.4\n\t22.9\t43.8\t68.7\n\t23.0\t44.0\t69.0\n\t23.1\t44.2\t69.3\n\t23.2\t44.4\t69.6\n\t23.3\t44.6\t69.9\n\t23.4\t44.8\t70.2\n\t23.5\t45.0\t70.5\n\t23.6\t45.2\t70.8\n\t23.7\t45.4\t71.1\n\t23.8\t45.6\t71.4\n\t23.9\t45.8\t71.7\n\t24.0\t46.0\t72.0\n\t24.1\t46.2\t72.3\n\t24.2\t46.4\t72.6\n\t24.3\t46.6\t72.9\n\t24.4\t46.8\t73.2\n\t24.5\t47.0\t73.5\n\t24.6\t47.2\t73.8\n\t24.7\t47.4\t74.1\n\t24.8\t47.6\t74.4\n\t24.9\t47.8\t74.7\n\t25.0\t48.0\t75.0\n\t25.1\t48.2\t75.3\n\t25.2\t48.4\t75.6\n\t25.3\t48.6\t75.9\n\t25.4\t48.8\t76.2\n\t25.5\t49.0\t76.5\n\t25.6\t49.2\t76.8\n\t25.7\t49.4\t77.1\n\t25.8\t49.6\t77.4\n\t25.9\t49.8\t77.7\n\t26.0\t50.0\t78.0\n\t26.1\t50.2\t78.3\n\t26.2\t50.4\t78.6\n\t26.3\t50.6\t78.9\n\t26.4\t50.8\t79.2\n\t26.5\t51.0\t79.5\n\t26.6\t51.2\t79.8\n\t26.7\t51.4\t80.1\n\t26.8\t51.6\t80.4\n\t26.9\t51.8\t80.7\n\t27.0\t52.0\t81.0\n\t27.1\t52.2\t81.3\n\t27.2\t52.4\t81.6\n\t27.3\t52.6\t81.9\n\t27.4\t52.8\t82.2\n\t27.5\t53.0\t82.5\n\t27.6\t53.2\t82.8\n\t27.7\t53.4\t83.1\n\t27.8\t53.6\t83.4\n\t27.9\t53.8\t83.7\n\t28.0\t54.0\t84.0\n\t28.1\t54.2\t84.3\n\t28.2\t54.4\t84.6\n\t28.3\t54.6\t84.9\t)\n\tstart = 1975.jan\n\tuser = (sale88 sale89 sale90)\n\tusertype = ao\n\tvariables = (const td ao1976.jan ls1991.dec easter[8] seasonal)\n}")
    @test contains(s, "arima {\n\tmodel = (2 1 0)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n}")

    # Manual example 20
    ts = TSeries(1975M1, collect(1:150))
    xts = X13.series(ts, title="Midwest total starts")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    @test contains(s, "regression {\n\ttestalleaster = yes\n\tvariables = (td easter[8] easter[0])\n\taictest = (td easter)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "estimate { }")
    @test contains(s, "check { }")
    @test contains(s, "forecast { }")
    @test contains(s, "x11 {\n\tmode = mult\n\tseasonalma = s3x3\n\ttitle = (\"Department Store Retail Sales Adjusted For\"\n\t\"Outlier, Trading Day, and Holiday Effects\")\n}")

    # Manual example 24
    ts = TSeries(1990Q1, collect(1:50))
    xts = X13.series(ts, title="US Total Housing Starts")
    spec = X13.newspec(xts)
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
    @test contains(s, "regression {\n\tdata = (\t1.0\t0.0\t3.0\n\t1.1\t0.2\t3.3\n\t1.2\t0.4\t3.6\n\t1.3\t0.6\t3.9\n\t1.4\t0.8\t4.2\n\t1.5\t1.0\t4.5\n\t1.6\t1.2\t4.8\n\t1.7\t1.4\t5.1\n\t1.8\t1.6\t5.4\n\t1.9\t1.8\t5.7\n\t2.0\t2.0\t6.0\n\t2.1\t2.2\t6.3\n\t2.2\t2.4\t6.6\n\t2.3\t2.6\t6.9\n\t2.4\t2.8\t7.2\n\t2.5\t3.0\t7.5\n\t2.6\t3.2\t7.8\n\t2.7\t3.4\t8.1\n\t2.8\t3.6\t8.4\n\t2.9\t3.8\t8.7\n\t3.0\t4.0\t9.0\n\t3.1\t4.2\t9.3\n\t3.2\t4.4\t9.6\n\t3.3\t4.6\t9.9\n\t3.4\t4.8\t10.2\n\t3.5\t5.0\t10.5\n\t3.6\t5.2\t10.8\n\t3.7\t5.4\t11.1\n\t3.8\t5.6\t11.4\n\t3.9\t5.8\t11.7\n\t4.0\t6.0\t12.0\n\t4.1\t6.2\t12.3\n\t4.2\t6.4\t12.6\n\t4.3\t6.6\t12.9\n\t4.4\t6.8\t13.2\n\t4.5\t7.0\t13.5\n\t4.6\t7.2\t13.8\n\t4.7\t7.4\t14.1\n\t4.8\t7.6\t14.4\n\t4.9\t7.8\t14.7\n\t5.0\t8.0\t15.0\n\t5.1\t8.2\t15.3\n\t5.2\t8.4\t15.6\n\t5.3\t8.6\t15.9\n\t5.4\t8.8\t16.2\n\t5.5\t9.0\t16.5\n\t5.6\t9.2\t16.8\n\t5.7\t9.4\t17.1\n\t5.8\t9.6\t17.4\n\t5.9\t9.8\t17.7\n\t6.0\t10.0\t18.0\n\t6.1\t10.2\t18.3\n\t6.2\t10.4\t18.6\n\t6.3\t10.6\t18.9\n\t6.4\t10.8\t19.2\n\t6.5\t11.0\t19.5\n\t6.6\t11.2\t19.8\n\t6.7\t11.4\t20.1\n\t6.8\t11.6\t20.4\n\t6.9\t11.8\t20.7\n\t7.0\t12.0\t21.0\n\t7.1\t12.2\t21.3\n\t7.2\t12.4\t21.6\n\t7.3\t12.6\t21.9\n\t7.4\t12.8\t22.2\n\t7.5\t13.0\t22.5\n\t7.6\t13.2\t22.8\n\t7.7\t13.4\t23.1\n\t7.8\t13.6\t23.4\n\t7.9\t13.8\t23.7\n\t8.0\t14.0\t24.0\n\t8.1\t14.2\t24.3\n\t8.2\t14.4\t24.6\n\t8.3\t14.6\t24.9\n\t8.4\t14.8\t25.2\n\t8.5\t15.0\t25.5\n\t8.6\t15.2\t25.8\n\t8.7\t15.4\t26.1\n\t8.8\t15.6\t26.4\n\t8.9\t15.8\t26.7\n\t9.0\t16.0\t27.0\n\t9.1\t16.2\t27.3\n\t9.2\t16.4\t27.6\n\t9.3\t16.6\t27.9\n\t9.4\t16.8\t28.2\n\t9.5\t17.0\t28.5\n\t9.6\t17.2\t28.8\n\t9.7\t17.4\t29.1\n\t9.8\t17.6\t29.4\n\t9.9\t17.8\t29.7\n\t10.0\t18.0\t30.0\n\t10.1\t18.2\t30.3\n\t10.2\t18.4\t30.6\n\t10.3\t18.6\t30.9\t)\n\tstart = 1985.1\n\tuser = (s1 s2 s3)\n\tusertype = seasonal\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)\n}")
    @test contains(s, "outlier { }")
    @test contains(s, "forecast {\n\tmaxlead = 24\n}")

    # Manual example 25
    ts = TSeries(1991M1, collect(1:150))
    xts = X13.series(ts, title="Payment to family nanny, taiwan", span=X13.Span(1993M1))
    spec = X13.newspec(xts)
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
    @test contains(s, "regression {\n\tchi2test = yes\n\tdata = (\t1.0\t0.0\t3.0\t1.0\t0.0\t3.0\t1.0\t0.0\t3.0\n\t1.1\t0.2\t3.3\t1.1\t0.2\t3.3\t1.1\t0.2\t3.3\n\t1.2\t0.4\t3.6\t1.2\t0.4\t3.6\t1.2\t0.4\t3.6\n\t1.3\t0.6\t3.9\t1.3\t0.6\t3.9\t1.3\t0.6\t3.9\n\t1.4\t0.8\t4.2\t1.4\t0.8\t4.2\t1.4\t0.8\t4.2\n\t1.5\t1.0\t4.5\t1.5\t1.0\t4.5\t1.5\t1.0\t4.5\n\t1.6\t1.2\t4.8\t1.6\t1.2\t4.8\t1.6\t1.2\t4.8\n\t1.7\t1.4\t5.1\t1.7\t1.4\t5.1\t1.7\t1.4\t5.1\n\t1.8\t1.6\t5.4\t1.8\t1.6\t5.4\t1.8\t1.6\t5.4\n\t1.9\t1.8\t5.7\t1.9\t1.8\t5.7\t1.9\t1.8\t5.7\n\t2.0\t2.0\t6.0\t2.0\t2.0\t6.0\t2.0\t2.0\t6.0\n\t2.1\t2.2\t6.3\t2.1\t2.2\t6.3\t2.1\t2.2\t6.3\n\t2.2\t2.4\t6.6\t2.2\t2.4\t6.6\t2.2\t2.4\t6.6\n\t2.3\t2.6\t6.9\t2.3\t2.6\t6.9\t2.3\t2.6\t6.9\n\t2.4\t2.8\t7.2\t2.4\t2.8\t7.2\t2.4\t2.8\t7.2\n\t2.5\t3.0\t7.5\t2.5\t3.0\t7.5\t2.5\t3.0\t7.5\n\t2.6\t3.2\t7.8\t2.6\t3.2\t7.8\t2.6\t3.2\t7.8\n\t2.7\t3.4\t8.1\t2.7\t3.4\t8.1\t2.7\t3.4\t8.1\n\t2.8\t3.6\t8.4\t2.8\t3.6\t8.4\t2.8\t3.6\t8.4\n\t2.9\t3.8\t8.7\t2.9\t3.8\t8.7\t2.9\t3.8\t8.7\n\t3.0\t4.0\t9.0\t3.0\t4.0\t9.0\t3.0\t4.0\t9.0\n\t3.1\t4.2\t9.3\t3.1\t4.2\t9.3\t3.1\t4.2\t9.3\n\t3.2\t4.4\t9.6\t3.2\t4.4\t9.6\t3.2\t4.4\t9.6\n\t3.3\t4.6\t9.9\t3.3\t4.6\t9.9\t3.3\t4.6\t9.9\n\t3.4\t4.8\t10.2\t3.4\t4.8\t10.2\t3.4\t4.8\t10.2\n\t3.5\t5.0\t10.5\t3.5\t5.0\t10.5\t3.5\t5.0\t10.5\n\t3.6\t5.2\t10.8\t3.6\t5.2\t10.8\t3.6\t5.2\t10.8\n\t3.7\t5.4\t11.1\t3.7\t5.4\t11.1\t3.7\t5.4\t11.1\n\t3.8\t5.6\t11.4\t3.8\t5.6\t11.4\t3.8\t5.6\t11.4\n\t3.9\t5.8\t11.7\t3.9\t5.8\t11.7\t3.9\t5.8\t11.7\n\t4.0\t6.0\t12.0\t4.0\t6.0\t12.0\t4.0\t6.0\t12.0\n\t4.1\t6.2\t12.3\t4.1\t6.2\t12.3\t4.1\t6.2\t12.3\n\t4.2\t6.4\t12.6\t4.2\t6.4\t12.6\t4.2\t6.4\t12.6\n\t4.3\t6.6\t12.9\t4.3\t6.6\t12.9\t4.3\t6.6\t12.9\n\t4.4\t6.8\t13.2\t4.4\t6.8\t13.2\t4.4\t6.8\t13.2\n\t4.5\t7.0\t13.5\t4.5\t7.0\t13.5\t4.5\t7.0\t13.5\n\t4.6\t7.2\t13.8\t4.6\t7.2\t13.8\t4.6\t7.2\t13.8\n\t4.7\t7.4\t14.1\t4.7\t7.4\t14.1\t4.7\t7.4\t14.1\n\t4.8\t7.6\t14.4\t4.8\t7.6\t14.4\t4.8\t7.6\t14.4\n\t4.9\t7.8\t14.7\t4.9\t7.8\t14.7\t4.9\t7.8\t14.7\n\t5.0\t8.0\t15.0\t5.0\t8.0\t15.0\t5.0\t8.0\t15.0\n\t5.1\t8.2\t15.3\t5.1\t8.2\t15.3\t5.1\t8.2\t15.3\n\t5.2\t8.4\t15.6\t5.2\t8.4\t15.6\t5.2\t8.4\t15.6\n\t5.3\t8.6\t15.9\t5.3\t8.6\t15.9\t5.3\t8.6\t15.9\n\t5.4\t8.8\t16.2\t5.4\t8.8\t16.2\t5.4\t8.8\t16.2\n\t5.5\t9.0\t16.5\t5.5\t9.0\t16.5\t5.5\t9.0\t16.5\n\t5.6\t9.2\t16.8\t5.6\t9.2\t16.8\t5.6\t9.2\t16.8\n\t5.7\t9.4\t17.1\t5.7\t9.4\t17.1\t5.7\t9.4\t17.1\n\t5.8\t9.6\t17.4\t5.8\t9.6\t17.4\t5.8\t9.6\t17.4\n\t5.9\t9.8\t17.7\t5.9\t9.8\t17.7\t5.9\t9.8\t17.7\n\t6.0\t10.0\t18.0\t6.0\t10.0\t18.0\t6.0\t10.0\t18.0\n\t6.1\t10.2\t18.3\t6.1\t10.2\t18.3\t6.1\t10.2\t18.3\n\t6.2\t10.4\t18.6\t6.2\t10.4\t18.6\t6.2\t10.4\t18.6\n\t6.3\t10.6\t18.9\t6.3\t10.6\t18.9\t6.3\t10.6\t18.9\n\t6.4\t10.8\t19.2\t6.4\t10.8\t19.2\t6.4\t10.8\t19.2\n\t6.5\t11.0\t19.5\t6.5\t11.0\t19.5\t6.5\t11.0\t19.5\n\t6.6\t11.2\t19.8\t6.6\t11.2\t19.8\t6.6\t11.2\t19.8\n\t6.7\t11.4\t20.1\t6.7\t11.4\t20.1\t6.7\t11.4\t20.1\n\t6.8\t11.6\t20.4\t6.8\t11.6\t20.4\t6.8\t11.6\t20.4\n\t6.9\t11.8\t20.7\t6.9\t11.8\t20.7\t6.9\t11.8\t20.7\n\t7.0\t12.0\t21.0\t7.0\t12.0\t21.0\t7.0\t12.0\t21.0\n\t7.1\t12.2\t21.3\t7.1\t12.2\t21.3\t7.1\t12.2\t21.3\n\t7.2\t12.4\t21.6\t7.2\t12.4\t21.6\t7.2\t12.4\t21.6\n\t7.3\t12.6\t21.9\t7.3\t12.6\t21.9\t7.3\t12.6\t21.9\n\t7.4\t12.8\t22.2\t7.4\t12.8\t22.2\t7.4\t12.8\t22.2\n\t7.5\t13.0\t22.5\t7.5\t13.0\t22.5\t7.5\t13.0\t22.5\n\t7.6\t13.2\t22.8\t7.6\t13.2\t22.8\t7.6\t13.2\t22.8\n\t7.7\t13.4\t23.1\t7.7\t13.4\t23.1\t7.7\t13.4\t23.1\n\t7.8\t13.6\t23.4\t7.8\t13.6\t23.4\t7.8\t13.6\t23.4\n\t7.9\t13.8\t23.7\t7.9\t13.8\t23.7\t7.9\t13.8\t23.7\n\t8.0\t14.0\t24.0\t8.0\t14.0\t24.0\t8.0\t14.0\t24.0\n\t8.1\t14.2\t24.3\t8.1\t14.2\t24.3\t8.1\t14.2\t24.3\n\t8.2\t14.4\t24.6\t8.2\t14.4\t24.6\t8.2\t14.4\t24.6\n\t8.3\t14.6\t24.9\t8.3\t14.6\t24.9\t8.3\t14.6\t24.9\n\t8.4\t14.8\t25.2\t8.4\t14.8\t25.2\t8.4\t14.8\t25.2\n\t8.5\t15.0\t25.5\t8.5\t15.0\t25.5\t8.5\t15.0\t25.5\n\t8.6\t15.2\t25.8\t8.6\t15.2\t25.8\t8.6\t15.2\t25.8\n\t8.7\t15.4\t26.1\t8.7\t15.4\t26.1\t8.7\t15.4\t26.1\n\t8.8\t15.6\t26.4\t8.8\t15.6\t26.4\t8.8\t15.6\t26.4\n\t8.9\t15.8\t26.7\t8.9\t15.8\t26.7\t8.9\t15.8\t26.7\n\t9.0\t16.0\t27.0\t9.0\t16.0\t27.0\t9.0\t16.0\t27.0\n\t9.1\t16.2\t27.3\t9.1\t16.2\t27.3\t9.1\t16.2\t27.3\n\t9.2\t16.4\t27.6\t9.2\t16.4\t27.6\t9.2\t16.4\t27.6\n\t9.3\t16.6\t27.9\t9.3\t16.6\t27.9\t9.3\t16.6\t27.9\n\t9.4\t16.8\t28.2\t9.4\t16.8\t28.2\t9.4\t16.8\t28.2\n\t9.5\t17.0\t28.5\t9.5\t17.0\t28.5\t9.5\t17.0\t28.5\n\t9.6\t17.2\t28.8\t9.6\t17.2\t28.8\t9.6\t17.2\t28.8\n\t9.7\t17.4\t29.1\t9.7\t17.4\t29.1\t9.7\t17.4\t29.1\n\t9.8\t17.6\t29.4\t9.8\t17.6\t29.4\t9.8\t17.6\t29.4\n\t9.9\t17.8\t29.7\t9.9\t17.8\t29.7\t9.9\t17.8\t29.7\n\t10.0\t18.0\t30.0\t10.0\t18.0\t30.0\t10.0\t18.0\t30.0\n\t10.1\t18.2\t30.3\t10.1\t18.2\t30.3\t10.1\t18.2\t30.3\n\t10.2\t18.4\t30.6\t10.2\t18.4\t30.6\t10.2\t18.4\t30.6\n\t10.3\t18.6\t30.9\t10.3\t18.6\t30.9\t10.3\t18.6\t30.9\n\t10.4\t18.8\t31.2\t10.4\t18.8\t31.2\t10.4\t18.8\t31.2\n\t10.5\t19.0\t31.5\t10.5\t19.0\t31.5\t10.5\t19.0\t31.5\n\t10.6\t19.2\t31.8\t10.6\t19.2\t31.8\t10.6\t19.2\t31.8\n\t10.7\t19.4\t32.1\t10.7\t19.4\t32.1\t10.7\t19.4\t32.1\n\t10.8\t19.6\t32.4\t10.8\t19.6\t32.4\t10.8\t19.6\t32.4\n\t10.9\t19.8\t32.7\t10.9\t19.8\t32.7\t10.9\t19.8\t32.7\n\t11.0\t20.0\t33.0\t11.0\t20.0\t33.0\t11.0\t20.0\t33.0\n\t11.1\t20.2\t33.3\t11.1\t20.2\t33.3\t11.1\t20.2\t33.3\n\t11.2\t20.4\t33.6\t11.2\t20.4\t33.6\t11.2\t20.4\t33.6\n\t11.3\t20.6\t33.9\t11.3\t20.6\t33.9\t11.3\t20.6\t33.9\n\t11.4\t20.8\t34.2\t11.4\t20.8\t34.2\t11.4\t20.8\t34.2\n\t11.5\t21.0\t34.5\t11.5\t21.0\t34.5\t11.5\t21.0\t34.5\n\t11.6\t21.2\t34.8\t11.6\t21.2\t34.8\t11.6\t21.2\t34.8\n\t11.7\t21.4\t35.1\t11.7\t21.4\t35.1\t11.7\t21.4\t35.1\n\t11.8\t21.6\t35.4\t11.8\t21.6\t35.4\t11.8\t21.6\t35.4\n\t11.9\t21.8\t35.7\t11.9\t21.8\t35.7\t11.9\t21.8\t35.7\n\t12.0\t22.0\t36.0\t12.0\t22.0\t36.0\t12.0\t22.0\t36.0\n\t12.1\t22.2\t36.3\t12.1\t22.2\t36.3\t12.1\t22.2\t36.3\n\t12.2\t22.4\t36.6\t12.2\t22.4\t36.6\t12.2\t22.4\t36.6\n\t12.3\t22.6\t36.9\t12.3\t22.6\t36.9\t12.3\t22.6\t36.9\n\t12.4\t22.8\t37.2\t12.4\t22.8\t37.2\t12.4\t22.8\t37.2\n\t12.5\t23.0\t37.5\t12.5\t23.0\t37.5\t12.5\t23.0\t37.5\n\t12.6\t23.2\t37.8\t12.6\t23.2\t37.8\t12.6\t23.2\t37.8\n\t12.7\t23.4\t38.1\t12.7\t23.4\t38.1\t12.7\t23.4\t38.1\n\t12.8\t23.6\t38.4\t12.8\t23.6\t38.4\t12.8\t23.6\t38.4\n\t12.9\t23.8\t38.7\t12.9\t23.8\t38.7\t12.9\t23.8\t38.7\n\t13.0\t24.0\t39.0\t13.0\t24.0\t39.0\t13.0\t24.0\t39.0\n\t13.1\t24.2\t39.3\t13.1\t24.2\t39.3\t13.1\t24.2\t39.3\n\t13.2\t24.4\t39.6\t13.2\t24.4\t39.6\t13.2\t24.4\t39.6\n\t13.3\t24.6\t39.9\t13.3\t24.6\t39.9\t13.3\t24.6\t39.9\n\t13.4\t24.8\t40.2\t13.4\t24.8\t40.2\t13.4\t24.8\t40.2\n\t13.5\t25.0\t40.5\t13.5\t25.0\t40.5\t13.5\t25.0\t40.5\n\t13.6\t25.2\t40.8\t13.6\t25.2\t40.8\t13.6\t25.2\t40.8\n\t13.7\t25.4\t41.1\t13.7\t25.4\t41.1\t13.7\t25.4\t41.1\n\t13.8\t25.6\t41.4\t13.8\t25.6\t41.4\t13.8\t25.6\t41.4\n\t13.9\t25.8\t41.7\t13.9\t25.8\t41.7\t13.9\t25.8\t41.7\n\t14.0\t26.0\t42.0\t14.0\t26.0\t42.0\t14.0\t26.0\t42.0\n\t14.1\t26.2\t42.3\t14.1\t26.2\t42.3\t14.1\t26.2\t42.3\n\t14.2\t26.4\t42.6\t14.2\t26.4\t42.6\t14.2\t26.4\t42.6\n\t14.3\t26.6\t42.9\t14.3\t26.6\t42.9\t14.3\t26.6\t42.9\n\t14.4\t26.8\t43.2\t14.4\t26.8\t43.2\t14.4\t26.8\t43.2\n\t14.5\t27.0\t43.5\t14.5\t27.0\t43.5\t14.5\t27.0\t43.5\n\t14.6\t27.2\t43.8\t14.6\t27.2\t43.8\t14.6\t27.2\t43.8\n\t14.7\t27.4\t44.1\t14.7\t27.4\t44.1\t14.7\t27.4\t44.1\n\t14.8\t27.6\t44.4\t14.8\t27.6\t44.4\t14.8\t27.6\t44.4\n\t14.9\t27.8\t44.7\t14.9\t27.8\t44.7\t14.9\t27.8\t44.7\n\t15.0\t28.0\t45.0\t15.0\t28.0\t45.0\t15.0\t28.0\t45.0\n\t15.1\t28.2\t45.3\t15.1\t28.2\t45.3\t15.1\t28.2\t45.3\n\t15.2\t28.4\t45.6\t15.2\t28.4\t45.6\t15.2\t28.4\t45.6\n\t15.3\t28.6\t45.9\t15.3\t28.6\t45.9\t15.3\t28.6\t45.9\n\t15.4\t28.8\t46.2\t15.4\t28.8\t46.2\t15.4\t28.8\t46.2\n\t15.5\t29.0\t46.5\t15.5\t29.0\t46.5\t15.5\t29.0\t46.5\n\t15.6\t29.2\t46.8\t15.6\t29.2\t46.8\t15.6\t29.2\t46.8\n\t15.7\t29.4\t47.1\t15.7\t29.4\t47.1\t15.7\t29.4\t47.1\n\t15.8\t29.6\t47.4\t15.8\t29.6\t47.4\t15.8\t29.6\t47.4\n\t15.9\t29.8\t47.7\t15.9\t29.8\t47.7\t15.9\t29.8\t47.7\n\t16.0\t30.0\t48.0\t16.0\t30.0\t48.0\t16.0\t30.0\t48.0\n\t16.1\t30.2\t48.3\t16.1\t30.2\t48.3\t16.1\t30.2\t48.3\n\t16.2\t30.4\t48.6\t16.2\t30.4\t48.6\t16.2\t30.4\t48.6\n\t16.3\t30.6\t48.9\t16.3\t30.6\t48.9\t16.3\t30.6\t48.9\n\t16.4\t30.8\t49.2\t16.4\t30.8\t49.2\t16.4\t30.8\t49.2\n\t16.5\t31.0\t49.5\t16.5\t31.0\t49.5\t16.5\t31.0\t49.5\n\t16.6\t31.2\t49.8\t16.6\t31.2\t49.8\t16.6\t31.2\t49.8\n\t16.7\t31.4\t50.1\t16.7\t31.4\t50.1\t16.7\t31.4\t50.1\n\t16.8\t31.6\t50.4\t16.8\t31.6\t50.4\t16.8\t31.6\t50.4\n\t16.9\t31.8\t50.7\t16.9\t31.8\t50.7\t16.9\t31.8\t50.7\n\t17.0\t32.0\t51.0\t17.0\t32.0\t51.0\t17.0\t32.0\t51.0\n\t17.1\t32.2\t51.3\t17.1\t32.2\t51.3\t17.1\t32.2\t51.3\t)\n\tstart = 1991.jan\n\tuser = (beforecny betweencny aftercny beforemoon betweenmoon aftermoon beforemidfall betweenmidfall aftermidfall)\n\tusertype = (holiday holiday holiday holiday2 holiday2 holiday2 holiday3 holiday3 holiday3)\n\tvariables = (ao1995.sep ao1997.jan ao1997.feb)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 0)\n}")
    @test contains(s, "check { }")
    @test contains(s, "forecast {\n\tmaxlead = 12\n}")
    @test contains(s, "estimate { }")
    
end

@testset "X13 Seats writing" begin

    # Manual example 1
    ts = TSeries(1987M1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
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
    @test contains(s, "seats {\n\tout = 0\n}")

    # Manual example 2
    ts = TSeries(1990Q1, collect(1:50))
    xts = X13.series(ts, title="Exports of truck parts")
    spec = X13.newspec(xts)
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
    @test contains(s, "seats {\n\tfinite = yes\n\tout = 0\n}")
    @test contains(s, "history {\n\testimates = (sadj trend)\n}")

    # Manual example 3
    ts = TSeries(MIT{YPFrequency{6}}(1995*6), collect(1:50))
    xts = X13.series(ts, title="Model based adjustment of Bimonthly exports")
    spec = X13.newspec(xts)
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
    @test contains(s, "seats {\n\tout = 0\n}")

    # Example with tabtables
    ts = TSeries(MIT{YPFrequency{6}}(1995*6), collect(1:50))
    xts = X13.series(ts, title="Model based adjustment of Bimonthly exports")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.regression!(spec; aictest=:td)
    X13.arima!(spec, X13.ArimaModel(0,1,1,0,1,1))
    X13.outlier!(spec, types=[:ao, :ls, :tc])
    X13.forecast!(spec, maxlead=18)
    X13.seats!(spec, tabtables=[:xo,:n,:s,:p])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\taictest = td\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)\n}")
    @test contains(s, "outlier {\n\ttypes = (ao ls tc)\n}")
    @test contains(s, "forecast {\n\tmaxlead = 18\n}")
    @test contains(s, "seats {\n\tout = 0\n\ttabtables = \"xo,n,s,p\"\n}")

end

@testset "X13 Series writing" begin

    # Manual example 1
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="A simple example")
    spec = X13.newspec(xts)
    s = X13.x13write(spec, test=true)
    @test contains(s, "series {\n\tdata = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 \n\t\t45 46 47 48 49 50)\n\tstart = 1967.jan\n\ttitle = \"A simple example\"\n}")
    
    # Manual example 2
    ts = TSeries(1940Q1, collect(1:250))
    xts = X13.series(ts, span=1964Q1:1990Q4)
    spec = X13.newspec(xts)
    s = X13.x13write(spec, test=true)
    @test contains(s, "series {\n\tdata = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 \n\t\t45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 \n\t\t88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 \n\t\t123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 \n\t\t155 156 157 158 159 160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 \n\t\t187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 \n\t\t219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250)\n\tperiod = 4\n\tspan = (1964.1, 1990.4)\n\tstart = 1940.1\n}")
    
    # Manual example 6
    ts = TSeries(1976M1, collect(1.0:0.1:25.0))
    xts = X13.series(ts, span=first(rangeof(ts)):1992M12, comptype=:add, decimals=2)
    spec = X13.newspec(xts)
    s = X13.x13write(spec, test=true)
    @test contains(s, "series {\n\tcomptype = add\n\tdata = (1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 \n\t\t4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 \n\t\t7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9.0 9.1 9.2 9.3 9.4 9.5 9.6 9.7 9.8 9.9 10.0 10.1 10.2 10.3 \n\t\t10.4 10.5 10.6 10.7 10.8 10.9 11.0 11.1 11.2 11.3 11.4 11.5 11.6 11.7 11.8 11.9 12.0 12.1 12.2 12.3 12.4 12.5 12.6 12.7 12.8 12.9 \n\t\t13.0 13.1 13.2 13.3 13.4 13.5 13.6 13.7 13.8 13.9 14.0 14.1 14.2 14.3 14.4 14.5 14.6 14.7 14.8 14.9 15.0 15.1 15.2 15.3 15.4 15.5 \n\t\t15.6 15.7 15.8 15.9 16.0 16.1 16.2 16.3 16.4 16.5 16.6 16.7 16.8 16.9 17.0 17.1 17.2 17.3 17.4 17.5 17.6 17.7 17.8 17.9 18.0 18.1 \n\t\t18.2 18.3 18.4 18.5 18.6 18.7 18.8 18.9 19.0 19.1 19.2 19.3 19.4 19.5 19.6 19.7 19.8 19.9 20.0 20.1 20.2 20.3 20.4 20.5 20.6 20.7 \n\t\t20.8 20.9 21.0 21.1 21.2 21.3 21.4 21.5 21.6 21.7 21.8 21.9 22.0 22.1 22.2 22.3 22.4 22.5 22.6 22.7 22.8 22.9 23.0 23.1 23.2 23.3 \n\t\t23.4 23.5 23.6 23.7 23.8 23.9 24.0 24.1 24.2 24.3 24.4 24.5 24.6 24.7 24.8 24.9 25.0)\n\tdecimals = 2\n\tspan = (1976.jan, 1992.dec)\n\tstart = 1976.jan\n}")
    
end

@testset "X13 Slidingspans writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Tourist")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9)
    X13.slidingspans!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "slidingspans { }")

    # Manual example 2
    ts = TSeries(1967Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly stock prices on NASDAQ")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=[:s3x9, :s3x9, :s3x5, :s3x5], trendma=7, mode=:logadd)
    X13.slidingspans!(spec, cutseas = 5.0, cutchng = 5.0)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tmode = logadd\n\tseasonalma = (s3x9 s3x9 s3x5 s3x5)\n\ttrendma = 7\n}")
    @test contains(s, "slidingspans {\n\tcutchng = 5.0\n\tcutseas = 5.0\n}")

    # Manual example 3
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Number of employed machinists - X-11")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    @test contains(s, "seats {\n\tout = 0\n}")
    @test contains(s, "slidingspans {\n\tlength = 144\n\toutlier = keep\n}")

    # Manual example 5
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Cheese sales in Wisconsin")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9)
    X13.slidingspans!(spec, length=40, numspans=3)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n}")
    @test contains(s, "slidingspans {\n\tlength = 40\n\tnumspans = 3\n}")
   
end

@testset "X13 Spectrum writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Klaatu")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=:s3x9, trendma=23)
    X13.spectrum!(spec, logqs=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n\ttrendma = 23\n}")
    @test contains(s, "spectrum {\n\tlogqs = yes\n}")

    # Manual example 2
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Spectrum analysis of Building Permits Series")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log)
    X13.spectrum!(spec, start=1987M1)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "spectrum {\n\tstart = 1987.jan\n}")

    # Manual example 3
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="TOTAL ONE-FAMILY Housing Starts")
    spec = X13.newspec(xts)
    X13.x11!(spec; seasonalma=[:s3x9], title="Composite adj. of 1-Family housing starts")
    X13.spectrum!(spec, type=:periodgram)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = (s3x9)\n\ttitle = \"Composite adj. of 1-Family housing starts\"\n}")
    @test contains(s, "spectrum {\n\ttype = periodgram\n}")

    # Manual example 4
    ts = TSeries(1988M1, collect(1:50))
    xts = X13.series(ts, title="Total U.S. Retail Sales")
    spec = X13.newspec(xts)
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

@testset "X13 Transform writing" begin

    # Manual example 1
    ts = TSeries(1967M1, collect(1:50))
    xts = X13.series(ts, title="Transform example")
    spec = X13.newspec(xts)
    X13.transform!(spec; data=TSeries(1967M1,collect(0.1:0.1:5.0)), mode=:ratio, adjust=:lom)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tadjust = lom\n\tdata = (0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 \n\t\t3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0)\n\tmode = ratio\n\tstart = 1967.jan\n}")
    
    # Manual example 2
    ts = TSeries(1997Q1, collect(1:50))
    xts = X13.series(ts, title="Transform example")
    spec = X13.newspec(xts)
    X13.transform!(spec; constant=45.0, func=:auto)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = auto\n\tconstant = 45.0\n}")

    # Manual example 3
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Total U.S. Retail Sales --- Current Dollars")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, data=TSeries(1970M1,collect(0.1:0.1:17.0)), title="Consumer Price Index" )
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tdata = (0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 \n\t\t3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 \n\t\t6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9.0 9.1 9.2 9.3 9.4 9.5 \n\t\t9.6 9.7 9.8 9.9 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 11.0 11.1 11.2 11.3 11.4 11.5 11.6 11.7 11.8 11.9 12.0 12.1 12.2 \n\t\t12.3 12.4 12.5 12.6 12.7 12.8 12.9 13.0 13.1 13.2 13.3 13.4 13.5 13.6 13.7 13.8 13.9 14.0 14.1 14.2 14.3 14.4 14.5 14.6 14.7 14.8 \n\t\t14.9 15.0 15.1 15.2 15.3 15.4 15.5 15.6 15.7 15.8 15.9 16.0 16.1 16.2 16.3 16.4 16.5 16.6 16.7 16.8 16.9 17.0)\n\tfunction = log\n\tstart = 1970.jan\n\ttitle = \"Consumer Price Index\"\n}")

    # Manual example 4
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Total U.S. Retail Sales --- Current Dollars")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, data=TSeries(1970M1,collect(0.1:0.1:17.0)), title="Consumer Price Index", type=:temporary)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tdata = (0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 \n\t\t3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 5.0 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9 6.0 6.1 6.2 6.3 \n\t\t6.4 6.5 6.6 6.7 6.8 6.9 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 9.0 9.1 9.2 9.3 9.4 9.5 \n\t\t9.6 9.7 9.8 9.9 10.0 10.1 10.2 10.3 10.4 10.5 10.6 10.7 10.8 10.9 11.0 11.1 11.2 11.3 11.4 11.5 11.6 11.7 11.8 11.9 12.0 12.1 12.2 \n\t\t12.3 12.4 12.5 12.6 12.7 12.8 12.9 13.0 13.1 13.2 13.3 13.4 13.5 13.6 13.7 13.8 13.9 14.0 14.1 14.2 14.3 14.4 14.5 14.6 14.7 14.8 \n\t\t14.9 15.0 15.1 15.2 15.3 15.4 15.5 15.6 15.7 15.8 15.9 16.0 16.1 16.2 16.3 16.4 16.5 16.6 16.7 16.8 16.9 17.0)\n\tfunction = log\n\tstart = 1970.jan\n\ttitle = \"Consumer Price Index\"\n\ttype = temporary\n}")
    
    # Manual example 5
    ts = TSeries(1901Q1, collect(1:50))
    xts = X13.series(ts, title="Annual Rainfall")
    spec = X13.newspec(xts)
    X13.transform!(spec; power=.3333)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tpower = 0.3333\n}")

    # Manual example 6
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="Annual Rainfall")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:log, 
        data=MVTSeries(1970M1,[:cpi, :strike], hcat(collect(0.1:0.1:17.0), collect(17.0:-0.1:0.1))), 
        title="Consumer Price Index & Strike Effect"
    )
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tdata = (\t0.1\t17.0\n\t0.2\t16.9\n\t0.3\t16.8\n\t0.4\t16.7\n\t0.5\t16.6\n\t0.6\t16.5\n\t0.7\t16.4\n\t0.8\t16.3\n\t0.9\t16.2\n\t1.0\t16.1\n\t1.1\t16.0\n\t1.2\t15.9\n\t1.3\t15.8\n\t1.4\t15.7\n\t1.5\t15.6\n\t1.6\t15.5\n\t1.7\t15.4\n\t1.8\t15.3\n\t1.9\t15.2\n\t2.0\t15.1\n\t2.1\t15.0\n\t2.2\t14.9\n\t2.3\t14.8\n\t2.4\t14.7\n\t2.5\t14.6\n\t2.6\t14.5\n\t2.7\t14.4\n\t2.8\t14.3\n\t2.9\t14.2\n\t3.0\t14.1\n\t3.1\t14.0\n\t3.2\t13.9\n\t3.3\t13.8\n\t3.4\t13.7\n\t3.5\t13.6\n\t3.6\t13.5\n\t3.7\t13.4\n\t3.8\t13.3\n\t3.9\t13.2\n\t4.0\t13.1\n\t4.1\t13.0\n\t4.2\t12.9\n\t4.3\t12.8\n\t4.4\t12.7\n\t4.5\t12.6\n\t4.6\t12.5\n\t4.7\t12.4\n\t4.8\t12.3\n\t4.9\t12.2\n\t5.0\t12.1\n\t5.1\t12.0\n\t5.2\t11.9\n\t5.3\t11.8\n\t5.4\t11.7\n\t5.5\t11.6\n\t5.6\t11.5\n\t5.7\t11.4\n\t5.8\t11.3\n\t5.9\t11.2\n\t6.0\t11.1\n\t6.1\t11.0\n\t6.2\t10.9\n\t6.3\t10.8\n\t6.4\t10.7\n\t6.5\t10.6\n\t6.6\t10.5\n\t6.7\t10.4\n\t6.8\t10.3\n\t6.9\t10.2\n\t7.0\t10.1\n\t7.1\t10.0\n\t7.2\t9.9\n\t7.3\t9.8\n\t7.4\t9.7\n\t7.5\t9.6\n\t7.6\t9.5\n\t7.7\t9.4\n\t7.8\t9.3\n\t7.9\t9.2\n\t8.0\t9.1\n\t8.1\t9.0\n\t8.2\t8.9\n\t8.3\t8.8\n\t8.4\t8.7\n\t8.5\t8.6\n\t8.6\t8.5\n\t8.7\t8.4\n\t8.8\t8.3\n\t8.9\t8.2\n\t9.0\t8.1\n\t9.1\t8.0\n\t9.2\t7.9\n\t9.3\t7.8\n\t9.4\t7.7\n\t9.5\t7.6\n\t9.6\t7.5\n\t9.7\t7.4\n\t9.8\t7.3\n\t9.9\t7.2\n\t10.0\t7.1\n\t10.1\t7.0\n\t10.2\t6.9\n\t10.3\t6.8\n\t10.4\t6.7\n\t10.5\t6.6\n\t10.6\t6.5\n\t10.7\t6.4\n\t10.8\t6.3\n\t10.9\t6.2\n\t11.0\t6.1\n\t11.1\t6.0\n\t11.2\t5.9\n\t11.3\t5.8\n\t11.4\t5.7\n\t11.5\t5.6\n\t11.6\t5.5\n\t11.7\t5.4\n\t11.8\t5.3\n\t11.9\t5.2\n\t12.0\t5.1\n\t12.1\t5.0\n\t12.2\t4.9\n\t12.3\t4.8\n\t12.4\t4.7\n\t12.5\t4.6\n\t12.6\t4.5\n\t12.7\t4.4\n\t12.8\t4.3\n\t12.9\t4.2\n\t13.0\t4.1\n\t13.1\t4.0\n\t13.2\t3.9\n\t13.3\t3.8\n\t13.4\t3.7\n\t13.5\t3.6\n\t13.6\t3.5\n\t13.7\t3.4\n\t13.8\t3.3\n\t13.9\t3.2\n\t14.0\t3.1\n\t14.1\t3.0\n\t14.2\t2.9\n\t14.3\t2.8\n\t14.4\t2.7\n\t14.5\t2.6\n\t14.6\t2.5\n\t14.7\t2.4\n\t14.8\t2.3\n\t14.9\t2.2\n\t15.0\t2.1\n\t15.1\t2.0\n\t15.2\t1.9\n\t15.3\t1.8\n\t15.4\t1.7\n\t15.5\t1.6\n\t15.6\t1.5\n\t15.7\t1.4\n\t15.8\t1.3\n\t15.9\t1.2\n\t16.0\t1.1\n\t16.1\t1.0\n\t16.2\t0.9\n\t16.3\t0.8\n\t16.4\t0.7\n\t16.5\t0.6\n\t16.6\t0.5\n\t16.7\t0.4\n\t16.8\t0.3\n\t16.9\t0.2\n\t17.0\t0.1\t)\n\tfunction = log\n\tname = (cpi strike)\n\tstart = 1970.jan\n\ttitle = \"Consumer Price Index & Strike Effect\"\n}")
    
    # Manual example 7
    ts = TSeries(1978M1, collect(1:50))
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec; func=:auto, aicdiff=0.0)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\taicdiff = 0.0\n\tfunction = auto\n}")

end


@testset "X13 x11 writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Klaatu")
    spec = X13.newspec(xts)
    X13.x11!(spec)
    X13.spectrum!(spec, logqs=true)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Klaatu")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:s3x9, trendma=23)
    X13.x11regression!(spec, variables=:td, aictest=:td)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11regression {\n\tvariables = td\n\taictest = td\n}")
    @test contains(s, "x11 {\n\tseasonalma = s3x9\n\ttrendma = 23\n}")

    # Manual example 3
    ts = TSeries(1967Q1, collect(1:50))
    xts = X13.series(ts, title="Quarterly housing starts")
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=[:s3x3, :s3x3, :s3x5, :s3x5], trendma=7)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tseasonalma = (s3x3 s3x3 s3x5 s3x5)\n\ttrendma = 7\n}")

    # Manual example 4
    ts = TSeries(1969M7, collect(1:150))
    xts = X13.series(ts, title="Exports of leather goods")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[:const, :td], 
        data=MVTSeries(1975M1, [:sale88, :sale90], hcat(collect(1.0:0.1:19.1),collect(3.0:0.3:57.3)))
    )
    X13.arima!(spec, X13.ArimaSpec(3,1,0), X13.ArimaSpec(0,1,1,12))
    X13.forecast!(spec, maxlead=12, maxback=12)
    X13.x11!(spec, title=["Unit Auto Sales", "Adjusted for special sales in 1988, 1990"])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (\t1.0\t3.0\n\t1.1\t3.3\n\t1.2\t3.6\n\t1.3\t3.9\n\t1.4\t4.2\n\t1.5\t4.5\n\t1.6\t4.8\n\t1.7\t5.1\n\t1.8\t5.4\n\t1.9\t5.7\n\t2.0\t6.0\n\t2.1\t6.3\n\t2.2\t6.6\n\t2.3\t6.9\n\t2.4\t7.2\n\t2.5\t7.5\n\t2.6\t7.8\n\t2.7\t8.1\n\t2.8\t8.4\n\t2.9\t8.7\n\t3.0\t9.0\n\t3.1\t9.3\n\t3.2\t9.6\n\t3.3\t9.9\n\t3.4\t10.2\n\t3.5\t10.5\n\t3.6\t10.8\n\t3.7\t11.1\n\t3.8\t11.4\n\t3.9\t11.7\n\t4.0\t12.0\n\t4.1\t12.3\n\t4.2\t12.6\n\t4.3\t12.9\n\t4.4\t13.2\n\t4.5\t13.5\n\t4.6\t13.8\n\t4.7\t14.1\n\t4.8\t14.4\n\t4.9\t14.7\n\t5.0\t15.0\n\t5.1\t15.3\n\t5.2\t15.6\n\t5.3\t15.9\n\t5.4\t16.2\n\t5.5\t16.5\n\t5.6\t16.8\n\t5.7\t17.1\n\t5.8\t17.4\n\t5.9\t17.7\n\t6.0\t18.0\n\t6.1\t18.3\n\t6.2\t18.6\n\t6.3\t18.9\n\t6.4\t19.2\n\t6.5\t19.5\n\t6.6\t19.8\n\t6.7\t20.1\n\t6.8\t20.4\n\t6.9\t20.7\n\t7.0\t21.0\n\t7.1\t21.3\n\t7.2\t21.6\n\t7.3\t21.9\n\t7.4\t22.2\n\t7.5\t22.5\n\t7.6\t22.8\n\t7.7\t23.1\n\t7.8\t23.4\n\t7.9\t23.7\n\t8.0\t24.0\n\t8.1\t24.3\n\t8.2\t24.6\n\t8.3\t24.9\n\t8.4\t25.2\n\t8.5\t25.5\n\t8.6\t25.8\n\t8.7\t26.1\n\t8.8\t26.4\n\t8.9\t26.7\n\t9.0\t27.0\n\t9.1\t27.3\n\t9.2\t27.6\n\t9.3\t27.9\n\t9.4\t28.2\n\t9.5\t28.5\n\t9.6\t28.8\n\t9.7\t29.1\n\t9.8\t29.4\n\t9.9\t29.7\n\t10.0\t30.0\n\t10.1\t30.3\n\t10.2\t30.6\n\t10.3\t30.9\n\t10.4\t31.2\n\t10.5\t31.5\n\t10.6\t31.8\n\t10.7\t32.1\n\t10.8\t32.4\n\t10.9\t32.7\n\t11.0\t33.0\n\t11.1\t33.3\n\t11.2\t33.6\n\t11.3\t33.9\n\t11.4\t34.2\n\t11.5\t34.5\n\t11.6\t34.8\n\t11.7\t35.1\n\t11.8\t35.4\n\t11.9\t35.7\n\t12.0\t36.0\n\t12.1\t36.3\n\t12.2\t36.6\n\t12.3\t36.9\n\t12.4\t37.2\n\t12.5\t37.5\n\t12.6\t37.8\n\t12.7\t38.1\n\t12.8\t38.4\n\t12.9\t38.7\n\t13.0\t39.0\n\t13.1\t39.3\n\t13.2\t39.6\n\t13.3\t39.9\n\t13.4\t40.2\n\t13.5\t40.5\n\t13.6\t40.8\n\t13.7\t41.1\n\t13.8\t41.4\n\t13.9\t41.7\n\t14.0\t42.0\n\t14.1\t42.3\n\t14.2\t42.6\n\t14.3\t42.9\n\t14.4\t43.2\n\t14.5\t43.5\n\t14.6\t43.8\n\t14.7\t44.1\n\t14.8\t44.4\n\t14.9\t44.7\n\t15.0\t45.0\n\t15.1\t45.3\n\t15.2\t45.6\n\t15.3\t45.9\n\t15.4\t46.2\n\t15.5\t46.5\n\t15.6\t46.8\n\t15.7\t47.1\n\t15.8\t47.4\n\t15.9\t47.7\n\t16.0\t48.0\n\t16.1\t48.3\n\t16.2\t48.6\n\t16.3\t48.9\n\t16.4\t49.2\n\t16.5\t49.5\n\t16.6\t49.8\n\t16.7\t50.1\n\t16.8\t50.4\n\t16.9\t50.7\n\t17.0\t51.0\n\t17.1\t51.3\n\t17.2\t51.6\n\t17.3\t51.9\n\t17.4\t52.2\n\t17.5\t52.5\n\t17.6\t52.8\n\t17.7\t53.1\n\t17.8\t53.4\n\t17.9\t53.7\n\t18.0\t54.0\n\t18.1\t54.3\n\t18.2\t54.6\n\t18.3\t54.9\n\t18.4\t55.2\n\t18.5\t55.5\n\t18.6\t55.8\n\t18.7\t56.1\n\t18.8\t56.4\n\t18.9\t56.7\n\t19.0\t57.0\n\t19.1\t57.3\t)\n\tstart = 1975.jan\n\tuser = (sale88 sale90)\n\tvariables = (const td)\n}")
    @test contains(s, "arima {\n\tmodel = (3 1 0)(0 1 1)12\n}")
    @test contains(s, "forecast {\n\tmaxback = 12\n\tmaxlead = 12\n}")
    @test contains(s, "x11 {\n\ttitle = (\"Unit Auto Sales\"\n\t\"Adjusted for special sales in 1988, 1990\")\n}")

    # Manual example 6
    ts = TSeries(1976M1, collect(1:150))
    xts = X13.series(ts, title="NORTHEAST ONE FAMILY Housing Starts")
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[:const], 
        data=MVTSeries(1975M1, [:strike80, :strike85, :strike90], hcat(collect(1.0:0.1:8.3),collect(0.0:0.2:14.6),collect(3.0:0.3:24.9)))
    )
    X13.arima!(spec, X13.ArimaSpec(0,1,1), X13.ArimaSpec(0,1,1,12))
    X13.x11!(spec, appendfcst=true, title="Car Sales in the US - Adjust for strikes in 80, 85, 90")
    X13.x11regression!(spec, variables=:td)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (\t1.0\t0.0\t3.0\n\t1.1\t0.2\t3.3\n\t1.2\t0.4\t3.6\n\t1.3\t0.6\t3.9\n\t1.4\t0.8\t4.2\n\t1.5\t1.0\t4.5\n\t1.6\t1.2\t4.8\n\t1.7\t1.4\t5.1\n\t1.8\t1.6\t5.4\n\t1.9\t1.8\t5.7\n\t2.0\t2.0\t6.0\n\t2.1\t2.2\t6.3\n\t2.2\t2.4\t6.6\n\t2.3\t2.6\t6.9\n\t2.4\t2.8\t7.2\n\t2.5\t3.0\t7.5\n\t2.6\t3.2\t7.8\n\t2.7\t3.4\t8.1\n\t2.8\t3.6\t8.4\n\t2.9\t3.8\t8.7\n\t3.0\t4.0\t9.0\n\t3.1\t4.2\t9.3\n\t3.2\t4.4\t9.6\n\t3.3\t4.6\t9.9\n\t3.4\t4.8\t10.2\n\t3.5\t5.0\t10.5\n\t3.6\t5.2\t10.8\n\t3.7\t5.4\t11.1\n\t3.8\t5.6\t11.4\n\t3.9\t5.8\t11.7\n\t4.0\t6.0\t12.0\n\t4.1\t6.2\t12.3\n\t4.2\t6.4\t12.6\n\t4.3\t6.6\t12.9\n\t4.4\t6.8\t13.2\n\t4.5\t7.0\t13.5\n\t4.6\t7.2\t13.8\n\t4.7\t7.4\t14.1\n\t4.8\t7.6\t14.4\n\t4.9\t7.8\t14.7\n\t5.0\t8.0\t15.0\n\t5.1\t8.2\t15.3\n\t5.2\t8.4\t15.6\n\t5.3\t8.6\t15.9\n\t5.4\t8.8\t16.2\n\t5.5\t9.0\t16.5\n\t5.6\t9.2\t16.8\n\t5.7\t9.4\t17.1\n\t5.8\t9.6\t17.4\n\t5.9\t9.8\t17.7\n\t6.0\t10.0\t18.0\n\t6.1\t10.2\t18.3\n\t6.2\t10.4\t18.6\n\t6.3\t10.6\t18.9\n\t6.4\t10.8\t19.2\n\t6.5\t11.0\t19.5\n\t6.6\t11.2\t19.8\n\t6.7\t11.4\t20.1\n\t6.8\t11.6\t20.4\n\t6.9\t11.8\t20.7\n\t7.0\t12.0\t21.0\n\t7.1\t12.2\t21.3\n\t7.2\t12.4\t21.6\n\t7.3\t12.6\t21.9\n\t7.4\t12.8\t22.2\n\t7.5\t13.0\t22.5\n\t7.6\t13.2\t22.8\n\t7.7\t13.4\t23.1\n\t7.8\t13.6\t23.4\n\t7.9\t13.8\t23.7\n\t8.0\t14.0\t24.0\n\t8.1\t14.2\t24.3\n\t8.2\t14.4\t24.6\n\t8.3\t14.6\t24.9\t)\n\tstart = 1975.jan\n\tuser = (strike80 strike85 strike90)\n\tvariables = (const)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "x11 {\n\tappendfcst = yes\n\ttitle = \"Car Sales in the US - Adjust for strikes in 80, 85, 90\"\n}")
    @test contains(s, "x11regression {\n\tvariables = td\n}")

    # Manual example 9
    ts = TSeries(1978M1, collect(1:50))
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:auto, aicdiff=0.0)
    X13.x11!(spec)
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\taicdiff = 0.0\n\tfunction = auto\n}")
    @test contains(s, "x11 { }")

    # Example with sigmavec
    ts = TSeries(1978M1, collect(1:50))
    xts = X13.series(ts, title="Total U.K. Retail Sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:auto, aicdiff=0.0)
    X13.x11!(spec, calendarsigma=:select, sigmavec=[M1, M2, M12])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\taicdiff = 0.0\n\tfunction = auto\n}")
    @test contains(s, "x11 {\n\tcalendarsigma = select\n\tsigmavec = (jan, feb, dec)\n}")
    
end

@testset "X13 x11regression writing" begin

    # Manual example 1
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Westus")
    spec = X13.newspec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td)
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\tvariables = td\n}")

    # Manual example 2
    ts = TSeries(1976M1, collect(1:50))
    xts = X13.series(ts, title="Westus")
    spec = X13.newspec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td, aictest=[:td, :easter])
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\tvariables = td\n\taictest = (td easter)\n}")

    # Manual example 3
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Ukclothes")
    spec = X13.newspec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td, usertype=:holiday, critical=4.0,
        data=MVTSeries(1980M1, [:easter1, :easter2], hcat(collect(0.1:0.1:11),collect(11:-0.1:0.1)))
    )
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\tcritical = 4.0\n\tdata = (\t0.1\t11.0\n\t0.2\t10.9\n\t0.3\t10.8\n\t0.4\t10.7\n\t0.5\t10.6\n\t0.6\t10.5\n\t0.7\t10.4\n\t0.8\t10.3\n\t0.9\t10.2\n\t1.0\t10.1\n\t1.1\t10.0\n\t1.2\t9.9\n\t1.3\t9.8\n\t1.4\t9.7\n\t1.5\t9.6\n\t1.6\t9.5\n\t1.7\t9.4\n\t1.8\t9.3\n\t1.9\t9.2\n\t2.0\t9.1\n\t2.1\t9.0\n\t2.2\t8.9\n\t2.3\t8.8\n\t2.4\t8.7\n\t2.5\t8.6\n\t2.6\t8.5\n\t2.7\t8.4\n\t2.8\t8.3\n\t2.9\t8.2\n\t3.0\t8.1\n\t3.1\t8.0\n\t3.2\t7.9\n\t3.3\t7.8\n\t3.4\t7.7\n\t3.5\t7.6\n\t3.6\t7.5\n\t3.7\t7.4\n\t3.8\t7.3\n\t3.9\t7.2\n\t4.0\t7.1\n\t4.1\t7.0\n\t4.2\t6.9\n\t4.3\t6.8\n\t4.4\t6.7\n\t4.5\t6.6\n\t4.6\t6.5\n\t4.7\t6.4\n\t4.8\t6.3\n\t4.9\t6.2\n\t5.0\t6.1\n\t5.1\t6.0\n\t5.2\t5.9\n\t5.3\t5.8\n\t5.4\t5.7\n\t5.5\t5.6\n\t5.6\t5.5\n\t5.7\t5.4\n\t5.8\t5.3\n\t5.9\t5.2\n\t6.0\t5.1\n\t6.1\t5.0\n\t6.2\t4.9\n\t6.3\t4.8\n\t6.4\t4.7\n\t6.5\t4.6\n\t6.6\t4.5\n\t6.7\t4.4\n\t6.8\t4.3\n\t6.9\t4.2\n\t7.0\t4.1\n\t7.1\t4.0\n\t7.2\t3.9\n\t7.3\t3.8\n\t7.4\t3.7\n\t7.5\t3.6\n\t7.6\t3.5\n\t7.7\t3.4\n\t7.8\t3.3\n\t7.9\t3.2\n\t8.0\t3.1\n\t8.1\t3.0\n\t8.2\t2.9\n\t8.3\t2.8\n\t8.4\t2.7\n\t8.5\t2.6\n\t8.6\t2.5\n\t8.7\t2.4\n\t8.8\t2.3\n\t8.9\t2.2\n\t9.0\t2.1\n\t9.1\t2.0\n\t9.2\t1.9\n\t9.3\t1.8\n\t9.4\t1.7\n\t9.5\t1.6\n\t9.6\t1.5\n\t9.7\t1.4\n\t9.8\t1.3\n\t9.9\t1.2\n\t10.0\t1.1\n\t10.1\t1.0\n\t10.2\t0.9\n\t10.3\t0.8\n\t10.4\t0.7\n\t10.5\t0.6\n\t10.6\t0.5\n\t10.7\t0.4\n\t10.8\t0.3\n\t10.9\t0.2\n\t11.0\t0.1\t)\n\tstart = 1980.jan\n\tuser = (easter1 easter2)\n\tusertype = holiday\n\tvariables = td\n}")

    # Manual example 4
    ts = TSeries(1980M1, collect(1:50))
    xts = X13.series(ts, title="nzstarts")
    spec = X13.newspec(xts)
    X13.x11!(spec)
    X13.x11regression!(spec, variables=:td, tdprior=[1.4, 1.4, 1.4, 1.4, 1.4, 0.0, 0.0])
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 { }")
    @test contains(s, "x11regression {\n\ttdprior = (1.4, 1.4, 1.4, 1.4, 1.4, 0.0, 0.0)\n\tvariables = td\n}")

    # Manual example 5
    ts = TSeries(1964Q1, collect(1:150))
    xts = X13.series(ts, title="MIDWEST ONE FAMILY Housing Starts", span=1964Q1:1989Q3)
    spec = X13.newspec(xts)
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
    spec = X13.newspec(xts)
    X13.x11!(spec, seasonalma=:x11default, sigmalim = [1.8, 2.8], appendfcst=true)
    X13.x11regression!(spec, variables=[X13.td(1990M1), X13.easter(8), X13.labor(10), X13.thank(10)])
    s = X13.x13write(spec, test=true)
    @test contains(s, "x11 {\n\tappendfcst = yes\n\tseasonalma = x11default\n\tsigmalim = (1.8, 2.8)\n}")
    @test contains(s, "x11regression {\n\tvariables = (td/1990.jan/ easter[8] labor[10] thank[10])\n}")

    # Manual example 7
    ts = TSeries(1975M1, collect(1:50))
    xts = X13.series(ts, title="Automobile sales")
    spec = X13.newspec(xts)
    X13.transform!(spec, func=:log)
    X13.regression!(spec, variables=[:const], 
        data=MVTSeries(1975M1, [:strike80, :strike85, :strike90], hcat(collect(1.0:0.1:8.3),collect(0.0:0.2:14.6),collect(3.0:0.3:24.9)))
    )
    X13.arima!(spec, X13.ArimaSpec(0,1,1), X13.ArimaSpec(0,1,1,12))
    X13.x11!(spec, title = ["Car Sales in US", "Adjusted for strikes in 80, 85, 90"])
    X13.x11regression!(spec, variables=[:td, X13.easter(8)])
    s = X13.x13write(spec, test=true)
    @test contains(s, "transform {\n\tfunction = log\n}")
    @test contains(s, "regression {\n\tdata = (\t1.0\t0.0\t3.0\n\t1.1\t0.2\t3.3\n\t1.2\t0.4\t3.6\n\t1.3\t0.6\t3.9\n\t1.4\t0.8\t4.2\n\t1.5\t1.0\t4.5\n\t1.6\t1.2\t4.8\n\t1.7\t1.4\t5.1\n\t1.8\t1.6\t5.4\n\t1.9\t1.8\t5.7\n\t2.0\t2.0\t6.0\n\t2.1\t2.2\t6.3\n\t2.2\t2.4\t6.6\n\t2.3\t2.6\t6.9\n\t2.4\t2.8\t7.2\n\t2.5\t3.0\t7.5\n\t2.6\t3.2\t7.8\n\t2.7\t3.4\t8.1\n\t2.8\t3.6\t8.4\n\t2.9\t3.8\t8.7\n\t3.0\t4.0\t9.0\n\t3.1\t4.2\t9.3\n\t3.2\t4.4\t9.6\n\t3.3\t4.6\t9.9\n\t3.4\t4.8\t10.2\n\t3.5\t5.0\t10.5\n\t3.6\t5.2\t10.8\n\t3.7\t5.4\t11.1\n\t3.8\t5.6\t11.4\n\t3.9\t5.8\t11.7\n\t4.0\t6.0\t12.0\n\t4.1\t6.2\t12.3\n\t4.2\t6.4\t12.6\n\t4.3\t6.6\t12.9\n\t4.4\t6.8\t13.2\n\t4.5\t7.0\t13.5\n\t4.6\t7.2\t13.8\n\t4.7\t7.4\t14.1\n\t4.8\t7.6\t14.4\n\t4.9\t7.8\t14.7\n\t5.0\t8.0\t15.0\n\t5.1\t8.2\t15.3\n\t5.2\t8.4\t15.6\n\t5.3\t8.6\t15.9\n\t5.4\t8.8\t16.2\n\t5.5\t9.0\t16.5\n\t5.6\t9.2\t16.8\n\t5.7\t9.4\t17.1\n\t5.8\t9.6\t17.4\n\t5.9\t9.8\t17.7\n\t6.0\t10.0\t18.0\n\t6.1\t10.2\t18.3\n\t6.2\t10.4\t18.6\n\t6.3\t10.6\t18.9\n\t6.4\t10.8\t19.2\n\t6.5\t11.0\t19.5\n\t6.6\t11.2\t19.8\n\t6.7\t11.4\t20.1\n\t6.8\t11.6\t20.4\n\t6.9\t11.8\t20.7\n\t7.0\t12.0\t21.0\n\t7.1\t12.2\t21.3\n\t7.2\t12.4\t21.6\n\t7.3\t12.6\t21.9\n\t7.4\t12.8\t22.2\n\t7.5\t13.0\t22.5\n\t7.6\t13.2\t22.8\n\t7.7\t13.4\t23.1\n\t7.8\t13.6\t23.4\n\t7.9\t13.8\t23.7\n\t8.0\t14.0\t24.0\n\t8.1\t14.2\t24.3\n\t8.2\t14.4\t24.6\n\t8.3\t14.6\t24.9\t)\n\tstart = 1975.jan\n\tuser = (strike80 strike85 strike90)\n\tvariables = (const)\n}")
    @test contains(s, "arima {\n\tmodel = (0 1 1)(0 1 1)12\n}")
    @test contains(s, "x11 {\n\ttitle = (\"Car Sales in US\"\n\t\"Adjusted for strikes in 80, 85, 90\")\n}")
    @test contains(s, "x11regression {\n\tvariables = (td easter[8])\n}")
 
end

@testset "X13  Specification errors writing" begin
    # invalid aictest when using :td variable
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Unit Auto Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec, variables=[:const, :td], aictest=:lom)
    @test_throws ArgumentError X13.x13write(spec, test=true)

    # invalid mixing of td and tdstock regressors
    ts = TSeries(1985M1, collect(1:50))
    xts = X13.series(ts, title="Unit Auto Sales")
    spec = X13.newspec(xts)
    X13.regression!(spec, variables=[:const, :td, :tdstock])
    @test_throws ArgumentError X13.x13write(spec, test=true)
    
end



