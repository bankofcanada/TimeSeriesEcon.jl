using Test
using TimeSeriesEcon

@testset "FPConst" begin
    @test 1U == ii(1)
    @test 2000Y == yy(2000)
    @test 1999Q1 == qq(1999, 1)
    @test 1999Q2 == qq(1999, 2)
    @test 1999Q3 == qq(1999, 3)
    @test 1999Q4 == qq(1999, 4)
    @test 1988M12 == mm(1988, 12)
    @test 1988M11 == mm(1988, 11)
    @test 1988M10 == mm(1988, 10)
    @test 1988M9 == mm(1988, 9)
    @test 1988M8 == mm(1988, 8)
    @test 1988M7 == mm(1988, 7)
    @test 1988M6 == mm(1988, 6)
    @test 1988M5 == mm(1988, 5)
    @test 1988M4 == mm(1988, 4)
    @test 1988M3 == mm(1988, 3)
    @test 1988M2 == mm(1988, 2)
    @test 1988M1 == mm(1988, 1)
end


ts_u = TSeries(1:5)
ts_m = TSeries(mm(2018, 1), collect(1.0:12.0))
ts_q = TSeries(qq(2018, 1):qq(2020, 4), collect(1:12))
ts_y = TSeries(yy(2018), collect(1:12))

@testset "TSeries: Construction" begin

    @test ts_u.firstdate == ii(1)
    @test ts_u.values == 1:5

    @test ts_m.firstdate == mm(2018, 1)
    @test ts_m.values == collect(1.0:12.0)

    @test ts_q.firstdate == qq(2018, 1)
    @test ts_q.values == collect(1.0:12.0)

    @test ts_y.firstdate == yy(2018)
    @test ts_y.values == collect(1.0:12.0)

    # Make sure if lengths are different we get an error
    @test_throws ArgumentError TSeries(1U:5U, 1:6)

    let t = TSeries(2U, rand(5))
        @test firstdate(t) == 2U
        @test lastdate(t) == 6U
        @test length(t.values) == 5
        @test length(t) == 5
    end

    let t = TSeries(1991Q1:1992Q4), s = TSeries(2222Y:2225Y, undef), r = TSeries(1006M3:1009M5, 0.3), e = TSeries(2000Y:1995Y, 7)
        @test isempty(e) 
        @test length(r) == 10+12+12+5
        @test length(t) == length(t.values) == 8
        @test firstindex(t) == firstdate(t) == 1991Q1
        @test lastindex(t) == lastdate(t) == 1992Q4
    end

end

@testset "Int indexing" begin
    let t = TSeries(4U:8U, rand(5))
        @test t.firstdate == 4U && lastdate(t) == 8U
        # test access
        @test t[1] isa Number 
        @test t[1] == t.values[1]
        @test t[2:4] isa TSeries{frequencyof(t),Vector{Float64}}
        @test t[2:4].values == t.values[2:4]
        @test t[[1,3,4]] isa Vector{Float64}
        @test t[[1,3,4]] == t.values[[1,3,4]]
        # test assignment
        @test begin
            t[2:4] = 2.5
            t.values[2:4] == fill(2.5, 3)
        end
        @test 5 == (t[3] = 5)
        @test t.values == [first(t), 2.5, 5.0, 2.5, last(t)]
    end
end

@testset "Views" begin
    let t = TSeries(2010M1, rand(20))
        @test axes(t) == (2010M1 - 1 .+ (1:20),)
        @test Base.axes1(t) == 2010M1 - 1 .+ (1:20)
        z = similar(t)
        @test z isa typeof(t)
        @test z.firstdate == t.firstdate
        @test z != t
        z = copy(t)
        @test z == t
        z[3:5] += 0.2
        z[4:5] = [3,4]
        @test z != t
        z = view(t, 2:5)
        c = view(t, 2010M2:2010M5)
        @test c == z
        @test z == t[2:5]
        z[[1,3]] += [0.5, 0.5]
        z[[2,4]] = [1,1.5]
        @test z == t[2:5]
        @test c == z
    end
end

@testset "MIT arithmetic" begin
    @test 5U < 8U
    @test 5U <= 8U
    @test 5U <= 5U
    @test 5U >= 5U
    @test 5U == 5U
    @test 8U >= 5U
    @test 8U > 5U
    @test 2001Q1 >= 2000Q3
    @test_throws ArgumentError 1M1 > 2Q1
    @test_throws ArgumentError 1M1 <= 2Q1
    @test 1M1 != 2Q1

    @test 2001Y + 5 == 2006Y
    @test 6 + 2001Q3 == 2003Q1
    @test 2003Q1 - 2001Q3 == 6
    @test 2003Q1 - 6 == 2001Q3
    @test_throws ArgumentError 6 - 2003Q1
    @test_throws ArgumentError 2003Q1 + 2003Q1
    @test_throws ArgumentError 2003Q1 + 2003Y
end

@testset "show" begin
    for (nrow, fd) = zip([3, 4, 5, 6, 7, 8, 22, 23, 24, 25, 26, 30], Iterators.cycle((qq(2010, 1), mm(2010, 1), yy(2010), ii(1))))
        let io = IOBuffer()
            t = TSeries(fd, rand(24))
            show(IOContext(io, :displaysize => (nrow, 80)), MIME"text/plain"(), t)
            @test length(readlines(seek(io, 0))) == max(2, min(length(t) + 1, nrow - 3))
        end
    end
end

@testset "frequencyof" begin
    @test frequencyof(qq(2000, 1)) == Quarterly
    @test frequencyof(mm(2000, 1)) == Monthly
    @test frequencyof(yy(2000)) == Yearly
    @test frequencyof(ii(1)) == Unit
    @test frequencyof(qq(2001, 1):qq(2002, 1)) == Quarterly
    @test frequencyof(TSeries(yy(2000), zeros(5))) == Yearly
end

@testset "TSeries: Broadcasting" begin

    allones = TSeries(2020Q1, ones(10))
    @test 5 - allones == 5 .- allones

    # -----------------------------------
    tsbc = TSeries(2020M1, ℯ * ones(12))

    @test Base.BroadcastStyle(typeof(tsbc)) ==  Base.Broadcast.ArrayStyle{TSeries}()

    @test TimeSeriesEcon.find_tseries(Broadcast.Broadcasted(-, (5, tsbc))) == tsbc
    @test TimeSeriesEcon.find_tseries(tsbc) == tsbc
    @test TimeSeriesEcon.find_tseries(Any, tsbc) == tsbc
    @test TimeSeriesEcon.find_tseries(tsbc, nothing) == tsbc

    @test firstdate(similar(tsbc)) == 2020M1
    @test size(similar(tsbc)) == size(tsbc)

    @test log.(tsbc) == TSeries(2020M1, ones(12))
    @test tsbc.firstdate == mm(2020, 1)
    @test exp.(log.(tsbc)) == tsbc
    @test tsbc .* 0 .+ 100 == TSeries(mm(2020, 1), 100 * ones(12))
    
    tsbc = log.(tsbc) + 99 # 1 + 99
    @test tsbc == TSeries(2020M1, 100 * ones(12))
end



@testset "TSeries: Index using end" begin
    @test ts_m[end] == 12
    @test ts_m[firstdate(ts_m):end] == ts_m
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
    @test mm(2020, 1) == MIT{Monthly}(2020 * 12)
    @test qq(2020, 1) == MIT{Quarterly}(2020 * 4)
    @test yy(2020) == MIT{Yearly}(2020)
    @test ii(2020) == MIT{Unit}(2020)
end

@testset "MIT: year, period" begin
    @test year(mm(2020, 12)) == 2020
    @test period(mm(2020, 12)) == 12
end

@testset "MIT: mitrange" begin
    @test mitrange(TSeries(qq(2020, 1), ones(4))) == qq(2020, 1):qq(2020, 4)
end

@testset "MIT: ppy" begin
    @test ppy(Quarterly) == 4
    @test ppy(qq(2020, 1)) == 4
    @test ppy(TSeries(qq(2020, 1), ones(1))) == 4

end

@testset "axes of range" begin
    @test axes(1U:5U) == axes(1:5)
    @test Base.axes1(2020Y:2030Y) == Base.OneTo(11)
end

@testset "recursive" begin
    ts = TSeries(1U, zeros(0))
    ts[1U] = ts[2U] = 1.0
    @rec 3U:10U ts[t] = ts[t-1]+ts[t-2]
    @test ts.values == [1.0,1,2,3,5,8,13,21,34,55]
    t = zeros(10,7)
    r = rand(1, 7)
    t[1, :] = r
    @rec 2:10 t[s,:] = t[s-1,:] .* s
    @test t ≈ factorial.(1:10) * r
end
