# Copyright (c) 2020-2025, Bank of Canada
# All rights reserved.

using Tables

@testset "Tables TSeries" begin
    t = TSeries(2020Q1, [1.0, 2.0, 3.0, 4.0])

    @test Tables.istable(t)
    @test Tables.istable(typeof(t))
    @test Tables.columnaccess(typeof(t))

    cols = Tables.columns(t)
    @test Tables.columnnames(cols) == (:date, :value)
    @test Tables.getcolumn(cols, :date) == 2020Q1:2020Q4
    @test Tables.getcolumn(cols, :value) == [1.0, 2.0, 3.0, 4.0]
    @test Tables.getcolumn(cols, 1) == 2020Q1:2020Q4
    @test Tables.getcolumn(cols, 2) == [1.0, 2.0, 3.0, 4.0]

    sch = Tables.schema(cols)
    @test sch.names == (:date, :value)
    @test sch.types == (MIT{Quarterly{3}}, Float64)

    # row access is derived from column access by Tables.jl
    rows = collect(Tables.rows(t))
    @test length(rows) == 4
    @test rows[1].date == 2020Q1
    @test rows[1].value == 1.0
    @test rows[end].date == 2020Q4
    @test rows[end].value == 4.0
    @test [r.value for r in Tables.rows(t)] == values(t)

    # the generic Tables.jl round trips, which is what consumers use
    @test Tables.rowtable(t) == [(date=2020Q1, value=1.0), (date=2020Q2, value=2.0),
        (date=2020Q3, value=3.0), (date=2020Q4, value=4.0)]
    ct = Tables.columntable(t)
    @test ct.date == 2020Q1:2020Q4
    @test ct.value == [1.0, 2.0, 3.0, 4.0]
end

@testset "Tables TSeries types" begin
    # frequency and element type are carried through to the schema
    for (ts, DT, VT) in (
        (TSeries(2020M1, [1.0, 2.0]), MIT{Monthly}, Float64),
        (TSeries(2020Y, Int[1, 2]), MIT{Yearly{12}}, Int),
        (TSeries(d"2020-01-01", [1.5, 2.5]), MIT{Daily}, Float64),
    )
        sch = Tables.schema(Tables.columns(ts))
        @test sch.names == (:date, :value)
        @test sch.types == (DT, VT)
        @test length(Tables.rowtable(ts)) == 2
    end

    # an empty series is still a valid, empty table
    e = TSeries(2020Q1, Float64[])
    @test Tables.istable(e)
    @test isempty(Tables.rowtable(e))
    @test Tables.columnnames(Tables.columns(e)) == (:date, :value)
end

@testset "Tables MVTSeries" begin
    x = MVTSeries(2020Q1, (:gdp, :cpi), [1.0 2.0; 3.0 4.0; 5.0 6.0; 7.0 8.0])

    @test Tables.istable(x)
    @test Tables.istable(typeof(x))
    @test Tables.columnaccess(typeof(x))

    cols = Tables.columns(x)
    @test Tables.columnnames(cols) == (:date, :gdp, :cpi)
    @test Tables.getcolumn(cols, :date) == 2020Q1:2020Q4
    @test Tables.getcolumn(cols, :gdp) == [1.0, 3.0, 5.0, 7.0]
    @test Tables.getcolumn(cols, :cpi) == [2.0, 4.0, 6.0, 8.0]

    sch = Tables.schema(cols)
    @test sch.names == (:date, :gdp, :cpi)
    @test sch.types == (MIT{Quarterly{3}}, Float64, Float64)

    rows = Tables.rowtable(x)
    @test length(rows) == 4
    @test rows[1] == (date=2020Q1, gdp=1.0, cpi=2.0)
    @test rows[end] == (date=2020Q4, gdp=7.0, cpi=8.0)

    # variable order is the order of the MVTSeries, not sorted
    y = MVTSeries(2020Q1, (:zeta, :alpha), [1.0 2.0; 3.0 4.0])
    @test Tables.columnnames(Tables.columns(y)) == (:date, :zeta, :alpha)

    # single variable, and a non-Float element type
    z = MVTSeries(2021M1, (:n,), reshape(Int[10, 20, 30], 3, 1))
    @test Tables.columnnames(Tables.columns(z)) == (:date, :n)
    @test Tables.schema(Tables.columns(z)).types == (MIT{Monthly}, Int)
    @test Tables.rowtable(z) == [(date=2021M1, n=10), (date=2021M2, n=20), (date=2021M3, n=30)]
end

@testset "Tables MVTSeries date clash" begin
    # a variable literally named `date` would collide with the date column
    x = MVTSeries(2020Q1, (:date, :gdp), [1.0 2.0; 3.0 4.0])
    @test_throws ArgumentError Tables.columns(x)
    try
        Tables.columns(x)
    catch err
        @test occursin("date", sprint(showerror, err))
    end
end

@testset "Tables columns are views" begin
    # Tables.columns does not copy, so it tracks later writes to the series.
    t = TSeries(2020Q1, [1.0, 2.0])
    vals = Tables.getcolumn(Tables.columns(t), :value)
    t[2020Q2] = 99.0
    @test vals[2] == 99.0

    x = MVTSeries(2020Q1, (:a,), reshape([1.0, 2.0], 2, 1))
    xvals = Tables.getcolumn(Tables.columns(x), :a)
    x.a[2020Q2] = 42.0
    @test xvals[2] == 42.0
end
