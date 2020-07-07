using Test
using TSeries

ts_m = Series(mm(2018, 1), collect(1.0:12.0))
ts_q = Series(qq(2018, 1):qq(2020, 4), collect(1:12))
ts_y = Series(yy(2018), collect(1:12))

@testset "Series Construction" begin
    @test ts_m.firstdate == mm(2018, 1)
    @test ts_m.values == collect(1.0:12.0)

    @test ts_q.firstdate == qq(2018, 1)
    @test ts_q.values == collect(1.0:12.0)

    @test ts_y.firstdate == yy(2018)
    @test ts_y.values == collect(1.0:12.0)
end


@testset "Monthly Access" begin
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
    @test ts_m[mm(2017, 1)] == nothing
    @test ts_m[mm(2017, 1):mm(2017, 3)] == nothing
end

@testset "Quarterly Access" begin
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

@testset "Yearly Access" begin
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

# ts_m = Series(mm(2018, 1), collect(1.0:12.0))
@testset "Monthly Setting" begin
    # begin
    #     ts_m = Series(mm(2018, 1), collect(1.0:12.0))
    #     ts_m[mm(2018, 1)] = 100;
    #     @test ts_m[mm(2018, 1)].values == [100]
    # end
    #
    # begin
    #     ts_m = Series(mm(2018, 1), collect(1.0:12.0))
    #     ts_m[mm(2017, 1)] = 100;
    #     @test ts_m[mm(2017, 1)].values == [100]
    #     @test ts_m.firstdate == mm(2017, 1)
    #     @test isequal(ts_m.values, vcat([100], fill(NaN, 11), collect(1.0:12.0)))
    # end

    # begin
    #     ts_m = Series(mm(2018, 1), collect(1.0:12.0))
    #     ts_m[mm(2019, 2)] = 100;
    #     @test ts_m[mm(2019, 2)].values == [100]
    #     @test ts_m.firstdate == mm(2018, 1)
    #     @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [100]))
    # end

    begin
        ts_m = Series(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2019, 2):mm(2019, 4)] = 1;
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [1, 1, 1]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [1, 1, 1]))
    end

    begin
        ts_m = Series(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2017, 10):mm(2017, 11)] = 1;
        @test ts_m[mm(2017, 10):mm(2017, 11)].values == [1, 1]
        @test ts_m.firstdate == mm(2017, 10)
        @test isequal(ts_m.values, vcat([1, 1], [NaN], collect(1.0:12.0)))
    end

    begin
        ts_m = Series(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2019, 2):mm(2019, 4)] = [9, 10, 11];
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [9, 10, 11]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [9, 10, 11]))
    end

    begin
        ts_m = Series(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2017, 10):mm(2017, 11)] = [9, 10];
        @test ts_m[mm(2017, 10):mm(2017, 11)].values == [9, 10]
        @test ts_m.firstdate == mm(2017, 10)
        @test isequal(ts_m.values, vcat([9, 10], [NaN], collect(1.0:12.0)))
    end


end

@testset "Addition" begin
    x = Series(ii(1), [7, 7, 7])
    y = Series(ii(3), [2, 4, 5])
    @test x + y == Series(ii(3), [9])

    x = Series(ii(1), [7, 7, 7])
    y = Series(ii(2), [2, 4, 5])
    @test x + y == Series(ii(2), [9, 11])
end



# @test length(ts) == 12
# @test ts[10] == 10.0
#
# ts[1] = 1000
# @test ts[1] == 1000
#
# @test (mm(2018, 1) < mm(2018, 2)) == true
#
# ts[mm(2017, 8):mm(2017, 11)] = [-1, -1.0, -1, -1]
# @test ts[mm(2017, 8):mm(2017, 11)] == [-1.0, -1.0, -1.0, -1.0]
# @test isequal(ts[mm(2017, 12)], [NaN])
#
# ts[mm(2019, 2):mm(2019, 11)] = -10



#
# ts[mm(2019, 2):mm(2019, 11)]
#
# ts[mm(2018, 1)]
#
# ts[mm(2019, 6)] = -1;ts
#
# ts[mm(2017, 6)] = -1;ts
#
# ts[mm(2017, 8)] = 1000;ts
#
# ts[mm(2017, 1):mm(2050, 1)]
#
#
# mm(2018, 1):mm(2018, 12) |> typeof
