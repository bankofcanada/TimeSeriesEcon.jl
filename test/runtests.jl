using Test
using TimeSeriesEcon

ts_m = TSeries(mm(2018, 1), collect(1.0:12.0))
ts_q = TSeries(qq(2018, 1):qq(2020, 4), collect(1:12))
ts_y = TSeries(yy(2018), collect(1:12))

@testset "TSeries: Construction" begin
    @test ts_m.firstdate == mm(2018, 1)
    @test ts_m.values == collect(1.0:12.0)

    @test ts_q.firstdate == qq(2018, 1)
    @test ts_q.values == collect(1.0:12.0)

    @test ts_y.firstdate == yy(2018)
    @test ts_y.values == collect(1.0:12.0)
end

@testset "show" begin
    for (nrow, fd) = zip([3, 4, 5, 6, 7, 8, 22, 23, 24, 25, 26, 30], Iterators.cycle((qq(2010,1), mm(2010,1), yy(2010), ii(1))))
        let io = IOBuffer()
            t = TSeries(fd, rand(24))
            show(IOContext(io, :displaysize=>(nrow,80)), MIME"text/plain"(), t)
            @test length(readlines(seek(io,0))) == max(2, min(length(t)+1, nrow-3))
        end
    end
end

@testset "frequencyof" begin
    @test frequencyof(qq(2000,1)) == Quarterly
    @test frequencyof(mm(2000,1)) == Monthly
    @test frequencyof(yy(2000)) == Yearly
    @test frequencyof(ii(1)) == Unit
    @test frequencyof(qq(2001,1):qq(2002,1)) == Quarterly
    @test frequencyof(TSeries(yy(2000), zeros(5))) == Yearly
end

@testset "TSeries: Monthly Access" begin
    @test ts_m[mm(2018, 1):mm(2018, 12)] == ts_m
    @test ts_m[mm(2018, 1):mm(2018, 12)].firstdate == mm(2018, 1)

    # access outside of ts boundaries
    @test ts_m[mm(2017, 1):mm(2019, 12)] == ts_m
    @test ts_m[mm(2017, 1):mm(2019, 12)].firstdate == ts_m.firstdate

    # partially out of boundary
    @test ts_m[mm(2017, 1):mm(2018, 6)] == ts_m[mm(2018, 1):mm(2018, 6)]
    @test ts_m[mm(2017, 1):mm(2018, 6)] == ts_m[mm(2018, 1):mm(2018, 6)]

    @test ts_m[mm(2017, 1):mm(2018, 6)] == ts_m[1:6]


    @test ts_m[mm(2018, 6):mm(2019, 12)] == ts_m[mm(2018, 6):mm(2018, 12)]
    @test ts_m[mm(2018, 6):mm(2019, 12)] == ts_m[6:12]

    # fully out of boundary
    @test ts_m[mm(2017, 1)] === nothing
    @test ts_m[mm(2017, 1):mm(2017, 3)] === nothing
end

@testset "TSeries: Quarterly Access" begin
    @test ts_q[qq(2018, 1):qq(2020, 4)] == ts_q

    # access outside of ts boundaries
    @test ts_q[qq(2017, 1):qq(2021, 4)] == ts_q

    # partially out of boundary
    @test ts_q[qq(2017, 1):qq(2018, 4)] == ts_q[qq(2018, 1):qq(2018, 4)]
    @test ts_q[qq(2017, 1):qq(2018, 4)] == ts_q[1:4]

    @test ts_q[qq(2018, 4):qq(2021, 4)] == ts_q[qq(2018, 4):qq(2020, 4)]
    @test ts_q[qq(2018, 4):qq(2021, 4)] == ts_q[4:12]

    # fully out of boundary
    @test ts_q[qq(2017, 1)] == nothing
    @test ts_q[qq(2017, 1):qq(2017, 3)] == nothing
end

@testset "TSeries: Yearly Access" begin
    @test ts_y[yy(2018):yy(2029)] == ts_y

    # access outside of ts boundaries
    @test ts_y[yy(2017):yy(2017) + 100] == ts_y

    # partially out of boundary
    @test ts_y[yy(2017):yy(2018)] == ts_y[yy(2018):yy(2018)]
    @test ts_y[yy(2017):yy(2021)] == ts_y[1:4]

    @test ts_y[yy(2018):yy(2100)] == ts_y[yy(2018):yy(2029)]
    @test ts_y[yy(2021):yy(2100)] == ts_y[4:12]

    # fully out of boundary
    @test ts_y[yy(2017)] == nothing
    @test ts_y[yy(2010):yy(2017)] == nothing
end

# ts_m = TSeries(mm(2018, 1), collect(1.0:12.0))
@testset "TSeries: Monthly Setting" begin
    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2019, 2):mm(2019, 4)] = 1;
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [1, 1, 1]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [1, 1, 1]))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2017, 10):mm(2017, 11)] = 1;
        @test ts_m[mm(2017, 10):mm(2017, 11)].values == [1, 1]
        @test ts_m.firstdate == mm(2017, 10)
        @test isequal(ts_m.values, vcat([1, 1], [NaN], collect(1.0:12.0)))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2019, 2):mm(2019, 4)] = [9, 10, 11];
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [9, 10, 11]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [9, 10, 11]))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2017, 10):mm(2017, 11)] = [9, 10];
        @test ts_m[mm(2017, 10):mm(2017, 11)].values == [9, 10]
        @test ts_m.firstdate == mm(2017, 10)
        @test isequal(ts_m.values, vcat([9, 10], [NaN], collect(1.0:12.0)))
    end
end

@testset "TSeries: Addition" begin
    x = TSeries(ii(1), [7, 7, 7])
    y = TSeries(ii(3), [2, 4, 5])
    @test x + y == TSeries(ii(3), [9])

    x = TSeries(ii(1), [7, 7, 7])
    y = TSeries(ii(2), [2, 4, 5])
    @test x + y == TSeries(ii(2), [9, 11])
end

@testset "TSeries: Iris related" begin
    # IRIS based assignment of values from other TSeries
    x = TSeries(qq(2020, 1), zeros(3));
    y = TSeries(qq(2020, 1), ones(3));
    x[qq(2020, 1):qq(2020, 2)] = y;
    @test x == TSeries(qq(2020, 1), [1, 1, 0])

    # IRIS related: shift
    x = TSeries(qq(2020, 1), zeros(3));
    @test shift(x, 1) == TSeries(qq(2019, 4), zeros(3))

    shift!(x, 1)
    @test x == TSeries(qq(2019, 4), zeros(3))

    # IRIS related: nanrm!
    x = TSeries(qq(2020, 1), [NaN, 123, NaN]);
    nanrm!(x)
    @test x == TSeries(qq(2020, 2), [123])


    # TODO
    # - pct
    # - apct



end

@testset "TSeries: firstdate & lastdate" begin
    x = TSeries(qq(2020, 1), zeros(4));
    @test firstdate(x) == qq(2020, 1)
    @test lastdate(x) == qq(2020, 4)
end

@testset "MIT constructors: mm, qq, yy, ii" begin
    @test mm(2020, 1) == MIT{Monthly}(2020*12)
    @test qq(2020, 1) == MIT{Quarterly}(2020*4)
    @test yy(2020) == MIT{Yearly}(2020)
    @test ii(2020) == MIT{Unit}(2020)
end

@testset "MIT: year, period" begin
    @test year(mm(2020, 12)) == 2020
    @test period(mm(2020, 12)) == 12
end

@testset "MIT: mitrange" begin
    @test mitrange( TSeries(qq(2020, 1), ones(4)) ) == qq(2020, 1):qq(2020, 4)
end

@testset "MIT: ppy" begin
    @test ppy(Quarterly) == 4
    @test ppy(qq(2020, 1)) == 4
    @test ppy( TSeries(qq(2020, 1), ones(1)) ) == 4

end
