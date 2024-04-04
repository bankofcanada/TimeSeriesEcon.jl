# Copyright (c) 2020-2024, Bank of Canada
# All rights reserved.
import TimeSeriesEcon: qq, mm, yy

@testset "TSeries" begin
    # test constructors
    s = TSeries(20Q1, collect(10.0 .+ (1:12)))
    @test typeof(s) === TSeries{Quarterly{3},Float64,Array{Float64,1}}
    @test size(s) == (12,)
    @test axes(s) == (20Q1:22Q4,)
    @test length(s) == 12
    @test values(s) == [11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0]
    @test s.values == [11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0]
    @test rawdata(s) == [11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0]

    t = TSeries(Int, 5)   # from type and number
    @test typeof(t) === TSeries{Unit,Int,Vector{Int}} && t.firstdate == 1U && length(t.values) == 5
    t = TSeries(UInt8, 4 .+ (1:5)) # from type and Int range
    @test typeof(t) === TSeries{Unit,UInt8,Vector{UInt8}} && t.firstdate == 5U && length(t.values) == 5
    t = TSeries(Float32, 1:5, undef) # from type, range and undef
    @test typeof(t) === TSeries{Unit,Float32,Vector{Float32}} && t.firstdate == 1U && length(t.values) == 5

    # constructing with similar()
    t = similar(ones(Float64, 5), (2Q1:4Q4))
    @test typeof(t) === TSeries{Quarterly{3},Float64,Vector{Float64}} && t.firstdate == 2Q1 && length(t.values) == 12

    # indexing
    @test s[1] == 11.0
    @test s[12] == 22.0
    @test s[1:3] == [11.0, 12.0, 13.0]
    @test s[1:2:12] == collect(10.0 .+ (1:2:12))
    @test s[s.<13] == [11.0, 12.0]
    #
    @test s[20Q1] == 11.0
    @test s[begin] == s.values[1]
    @test s[end] == s.values[end]
    @test s[begin:begin+3] isa typeof(s)
    @test s[begin:begin+3].values == s.values[begin:begin+3]
    @test (@. 13 < s < 16) isa TSeries{frequencyof(s),Bool}
    #
    @test_throws ArgumentError s[2:end]  # can't mix Int indexing with begin/end
    @test_throws ArgumentError s[begin:4]
    #
    @test_throws ArgumentError s[1U]  # wrong frequency
    @test_throws ArgumentError s[1Y:3Y]  # wrong frequency
    @test_throws ArgumentError s[2Y] = 5  # wrong frequency

    q = copy(s)
    s[19Q1] = 5  # outside range
    @test s.values ≈ [5, NaN, NaN, NaN, q.values...] nans = true
    s[end+3] = 3  # outside range
    @test s.values ≈ [5, NaN, NaN, NaN, q.values..., NaN, NaN, 3] nans = true

    @test_throws ArgumentError s[20Y:21Y] = [2, 3]  # wrong frequency

    i = TSeries(20Y, ones(Int32, 5))
    i[17Y] = -1
    @test i.values == [-1, typenan(Int32), typenan(Int32), ones(5)...]

    @test_throws ArgumentError resize!(i, 17U:24U)  # wrong frequency
    @test_throws ArgumentError copyto!(i, 17U:24U, i)  # wrong frequency
    @test_throws ArgumentError copyto!(i, s)  # wrong frequency

    # various ways of initializing an empty tseries
    i2 = TSeries(1U)
    @test length(i2) == 0
    i3 = TSeries(Int32, 20Y)
    @test length(i3) == 0
    @test_throws InexactError i3[20Y] = 2.5

    # rangeof with drop
    let myts = TSeries(20Q1:21Q4, 1)
        @test rangeof(myts, drop=2) == 20Q3:21Q4
        @test rangeof(myts, drop=-2) == 20Q1:21Q2
    end

    # similar with an abstract array
    val = Float32(22.3)
    t2 = similar(typeof([val]), (2Q1:4Q4))
    @test typeof(t2) === TSeries{Quarterly{3},Float32,Vector{Float32}} && t2.firstdate == 2Q1 && length(t2.values) == 12
    t3 = similar([val], (2Q1:4Q4))
    @test typeof(t3) === TSeries{Quarterly{3},Float32,Vector{Float32}} && t3.firstdate == 2Q1 && length(t3.values) == 12

    # fill
    t4 = fill(2, (20Y:22Y))
    @test t4 isa TSeries && rangeof(t4) == 20Y:22Y && t4[21Y] == 2
    for (fname, fval) in ((:zeros, 0.0), (:ones, 1.0), (:trues, true), (:falses, false))
        @eval begin
            t1 = $fname(20Y:22Y)
            t2 = $fname((20Y:22Y))
            @test t1 isa TSeries && rangeof(t1) == 20Y:22Y && t1[21Y] == $fval
            @test t2 isa TSeries && rangeof(t2) == 20Y:22Y && t2[21Y] == $fval
        end
        if fname in (:zeros, :ones)
            @eval begin
                @test typeof(t1[21Y]) == Float64
                @test typeof(t2[21Y]) == Float64
                t3 = $fname(Float32, 20Y:22Y)
                t4 = $fname(Float32, (20Y:22Y))
                @test t3 isa TSeries && rangeof(t3) == 20Y:22Y && t3[21Y] == $fval && typeof(t3[21Y]) == Float32
                @test t4 isa TSeries && rangeof(t4) == 20Y:22Y && t4[21Y] == $fval && typeof(t4[21Y]) == Float32
            end
        end
        if fname in (:trues, :falses)
            @eval begin
                @test typeof(t1[21Y]) == Bool
                @test typeof(t2[21Y]) == Bool
            end
        end
    end
end


@testset "Bcast" begin
    t = TSeries(5U:10U, rand(6))

    # we can broadcast with a singleton
    r = t .+ 5
    @test typeof(r) == typeof(t) && eachindex(r) == eachindex(t) && all(r.values .== t.values .+ 5)

    # we can broadcast with another TSeries of identical range
    r = t .+ TSeries(5U, collect(1:6))
    @test typeof(r) == typeof(t) && eachindex(r) == eachindex(t) && all(r.values .== t.values .+ (1:6)) && rangeof(r) == rangeof(t)

    # we can broadcast with another TSeries of different range
    r = t .+ TSeries(4U, collect(1:6))
    @test typeof(r) == typeof(t) && eachindex(r) == 5U:9U && all(r.values .== t.values[1:end-1] .+ (2:6))

    # we can broadcast with a Vector
    r = t .+ collect(1:6)
    @test typeof(r) == typeof(t) && eachindex(r) == eachindex(t) && all(r.values .== t.values .+ (1:6))

    # broadcast with a vector of the wrong dimension throws a DimensionMismatch
    @test_throws DimensionMismatch t .+ collect(1:4)
    @test_throws DimensionMismatch t .+ collect(1:8)

    # broadcast with a TSeries of another frequency throws a mixed_freq_error
    @test_throws ArgumentError t .+ TSeries(2020Q1 .+ (0:5), 0.75)

    # we can .= correctly
    t .= 1.0
    @test all(t.values .== 1.0)

    t .+= collect(1:6)
    @test eachindex(t) == (5U:10U) && all(t.values .== 1.0 .+ (1:6))

    s = similar(t, 3U:12U)
    fill!(s, 0.0)
    s .= t .- 2
    @test eachindex(s) === (3U:12U) && all(s[5U:10U].values .== (1:6) .- 1.0)
    @test all(s[3U:4U].values .== 0.0) && all(s[11U:end] .== 0.0)

    # we can .^ correctly
    @test isa(s .^ 2, typeof(s))
    @test (s .^ 2).values == s.values .^ 2

    # dot-assign when the rhs is a vector
    @test_throws DimensionMismatch s .= ones(length(s) + 1)
    @test_throws DimensionMismatch s .= ones(length(s) - 1)
    @test (s .= ones(length(s)); rangeof(s) === 3U:12U && all(s.values .== 1.0))

    # dot-assign into a range
    t[begin+2:end-2] .= 2
    @test t.values == [2, 3, 2, 2, 6, 7]

    t[end+2:end+4] .= 8
    @test t.values ≈ [2, 3, 2, 2, 6, 7, NaN, 8, 8, 8] nans = true

    # setindex with BitArray and broadcasting
    t[t.<7] .= 0
    @test t.values ≈ [0, 0, 0, 0, 0, 7, NaN, 8, 8, 8] nans = true

    t[2:4] .= 1
    @test t.values ≈ [0, 1, 1, 1, 0, 7, NaN, 8, 8, 8] nans = true

    #additional tests for code coverage
    @test Base.Broadcast._eachindex((1U:4U,)) == 1:4

    t2 = TSeries(5U:10U, collect(1:6))
    r2 = t2 .+ 5
    t3 = t2 .+ r2
    @test Base.Broadcast.preprocess(t2, r2).x ≈ [6, 7, 8, 9, 10, 11]
    @test Base.Broadcast.preprocess(t2, r2).keeps == (true,)
    @test Base.Broadcast.preprocess(t2, r2).defaults == (1,)

    Base.Broadcast.check_broadcast_shape((1U:10U,), (1,)) == nothing
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape((10,), (1U:10U,))
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape((2U:11U,), (1U:10U,))
    @test Base.Broadcast.preprocess(t2, collect(1:10)).keeps == (true,)
    @test Base.Broadcast.preprocess(t2, collect(1:10)).defaults == (1,)
    @test Base.Broadcast.preprocess(t2, collect(1:10)).x == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    @test Base.Broadcast.BroadcastStyle(TimeSeriesEcon.TSeriesStyle{Monthly}(), TimeSeriesEcon.TSeriesStyle{Monthly}()) == TimeSeriesEcon.TSeriesStyle{Monthly}()
    bcStyle = TimeSeriesEcon.TSeriesStyle{Monthly}()
    bcStyle2 = TimeSeriesEcon.TSeriesStyle{Unit}()

    bcasted = Base.Broadcast.Broadcasted{TimeSeriesEcon.TSeriesStyle{Monthly}}(Monthly, (1,))
    @test_throws DimensionMismatch Base.similar(bcasted, Float64)
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape((1U:10U,), (10,))
    @test Base.Broadcast.check_broadcast_shape((1U:10U,), ()) === nothing
    @test Base.Broadcast.preprocess(t2, 10.0) == 10

end

ts_u = TSeries(5)
ts_v = TSeries(3:5)
ts_m = TSeries(mm(2018, 1), collect(1.0:12.0))
ts_q = TSeries(qq(2018, 1):qq(2020, 4), collect(1:12))
ts_y = TSeries(yy(2018), collect(1:12))

@testset "TSeries 1" begin

    @test ts_u.firstdate == 1U
    # @test ts_u.values == 1:5

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
        @test length(r) == 10 + 12 + 12 + 5
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
        @test t[2:4] isa Vector{Float64} # TSeries{frequencyof(t),Float64,Vector{Float64}}
        @test t[2:4] == t.values[2:4]
        @test t[[1, 3, 4]] isa Vector{Float64}
        @test t[[1, 3, 4]] == t.values[[1, 3, 4]]
        # test assignment
        @test begin
            t[2:4] .= 2.5
            t.values[2:4] == fill(2.5, 3)
        end
        @test 5 == (t[3] = 5)
        @test t.values == [first(t), 2.5, 5.0, 2.5, last(t)]
        @test t[:] === t
        @test nextind(t, 2) == 3
        @test prevind(t, 2) == 1
        @test nextind(t, 5U) == 6U
        @test prevind(t, 5U) == 4U
    end
end

@testset "Bool indexing" begin
    tt = TSeries(2020Q1, falses(5))
    tt[[2, 4]] .= true
    @test tt[tt] == [true, true]
    @test tt[.!tt] == [false, false, false]
    @test_throws ArgumentError (1U:5U)[tt]    # mixed frequencies
    @test_throws BoundsError (1:5)[tt] == [2, 4]
    @test rangeof(tt)[tt] == [2020Q2, 2020Q4]
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
        z[begin.+(2:4)] .+= 0.2
        z[begin.+(3:4)] = [3, 4]
        @test z != t
        z = view(t, 2:5)
        c = view(t, 2010M2:2010M5)
        @test c == z
        @test z == t[begin.+(1:4)]
        z[[1, 3]] += [0.5, 0.5]
        z[[2, 4]] = [1, 1.5]
        @test c == z
        @test z == t[begin.+(1:4)]
        @test view(t, :) isa TSeries
        @test view(t, :).values isa SubArray
        @test view(t, :) == t
    end
end

@testset "show" begin
    for (nrow, fd) = zip([3, 4, 5, 6, 7, 8, 22, 23, 24, 25, 26, 30],
        Iterators.cycle((qq(2010, 1), mm(2010, 1), yy(2010), 1U)))
        let io = IOBuffer()
            t = TSeries(fd, rand(24))
            show(IOContext(io, :displaysize => (nrow, 80)), MIME"text/plain"(), t)
            @test length(readlines(seek(io, 0))) == max(2, min(length(t) + 1, nrow - 3))
        end
    end
    for fd = (2020Q1, 2020M1, 2020Y, 2020U)
        let io = IOBuffer()
            t = TSeries(fd, Float64[])
            show(IOContext(io, :displaysize => (10, 80)), MIME"text/plain"(), t)
            @test startswith(readlines(seek(io, 0))[1], "Empty")
        end
    end
end

@testset "math" begin
    tq = TSeries(2020Q1, rand(12))
    tm = TSeries(2020M1, copy(tq.values))
    tu = TSeries(11U, copy(tq.values))

    tmp = tq .* 5
    @test 5tq isa TSeries{Quarterly{3}}
    @test tq * 5 isa TSeries{Quarterly{3}}
    @test 5tq == tmp
    @test tq * 5 == tmp
    @test (5tm).values == (5tq).values && 5tm ≠ 5tq

    @test (tq + tq) == (tq .+ tq)

    # approx works when ranges don't match 
    sq = resize!(copy(tq), 2020Q3:2022Q2)
    @test sq ≠ tq && sq ≈ tq

    # adding two TSeries of same frequency and range works
    @test tq + 5tq ≈ 6tq
    # adding TSeries and 
    @test_throws MethodError 5 + tq
    @test_throws MethodError tq + 5
    @test 5 .+ tq == tq .+ 5  # broadcasting works
    @test_throws ArgumentError tq + 5tm   # different frequencies not allowed

    # shape errors
    @test_throws ArgumentError TimeSeriesEcon.shape_error(typeof(1), typeof(2))
    @test_throws ArgumentError TimeSeriesEcon.shape_error(1, 2)

    # maximum and minimum
    @test minimum(tq) == minimum(tq.values)
    @test maximum(tq) == maximum(tq.values)
    halve(x) = x / 2
    @test minimum(halve, tq) == minimum(halve, tq.values)
    @test maximum(halve, tq) == maximum(halve, tq.values)
end

@testset "Monthly" begin
    @test ts_m[mm(2018, 1):mm(2018, 12)] == ts_m
    @test ts_m[mm(2018, 1):mm(2018, 12)].firstdate == mm(2018, 1)

    # access outside of ts boundaries
    @test_throws BoundsError ts_m[mm(2017, 1):mm(2019, 12)] == ts_m
    # @test ts_m[mm(2017, 1):mm(2019, 12)].firstdate == ts_m.firstdate

    # partially out of boundary
    @test_throws BoundsError ts_m[mm(2017, 1):mm(2018, 6)] == ts_m[mm(2018, 1):mm(2018, 6)]
    @test_throws BoundsError ts_m[mm(2017, 1):mm(2018, 6)] == ts_m[mm(2018, 1):mm(2018, 6)]

    @test_throws BoundsError ts_m[mm(2017, 1):mm(2018, 6)] == ts_m[1:6]


    @test_throws BoundsError ts_m[mm(2018, 6):mm(2019, 12)] == ts_m[mm(2018, 6):mm(2018, 12)]
    @test_throws BoundsError ts_m[mm(2018, 6):mm(2019, 12)] == ts_m[6:12]

    # fully out of boundary
    @test_throws BoundsError ts_m[mm(2017, 1)] === nothing
    @test_throws BoundsError ts_m[mm(2017, 1):mm(2017, 3)] === nothing
end

@testset "Quarterly" begin
    @test ts_q[qq(2018, 1):qq(2020, 4)] == ts_q

    # access outside of ts boundaries
    @test_throws BoundsError ts_q[qq(2017, 1):qq(2021, 4)] == ts_q

    # partially out of boundary
    @test_throws BoundsError ts_q[qq(2017, 1):qq(2018, 4)] == ts_q[qq(2018, 1):qq(2018, 4)]
    @test_throws BoundsError ts_q[qq(2017, 1):qq(2018, 4)] == ts_q[1:4]

    @test_throws BoundsError ts_q[qq(2018, 4):qq(2021, 4)] == ts_q[qq(2018, 4):qq(2020, 4)]
    @test_throws BoundsError ts_q[qq(2018, 4):qq(2021, 4)] == ts_q[4:12]

    # fully out of boundary
    @test_throws BoundsError ts_q[qq(2017, 1)] === nothing
    @test_throws BoundsError ts_q[qq(2017, 1):qq(2017, 3)] === nothing
end

@testset "Yearly" begin
    @test ts_y[yy(2018):yy(2029)] == ts_y

    # access outside of ts boundaries
    @test_throws BoundsError ts_y[yy(2017):yy(2017)+100] == ts_y

    # partially out of boundary
    @test_throws BoundsError ts_y[yy(2017):yy(2018)] == ts_y[yy(2018):yy(2018)]
    @test_throws BoundsError ts_y[yy(2017):yy(2021)] == ts_y[1:4]

    @test_throws BoundsError ts_y[yy(2018):yy(2100)] == ts_y[yy(2018):yy(2029)]
    @test_throws BoundsError ts_y[yy(2021):yy(2100)] == ts_y[4:12]

    # fully out of boundary
    @test_throws BoundsError ts_y[yy(2017)] === nothing
    @test_throws BoundsError ts_y[yy(2010):yy(2017)] === nothing
end

# ts_m = TSeries(mm(2018, 1), collect(1.0:12.0))
@testset "Setting" begin
    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        @test_throws BoundsError ts_m[mm(2019, 2):mm(2019, 4)] = 1
        ts_m[mm(2019, 2):mm(2019, 4)] .= 1
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [1, 1, 1]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [1, 1, 1]))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        @test_throws BoundsError ts_m[mm(2017, 10):mm(2017, 11)] = 1
        ts_m[mm(2017, 10):mm(2017, 11)] .= 1
        @test ts_m[mm(2017, 10):mm(2017, 11)].values == [1, 1]
        @test ts_m.firstdate == mm(2017, 10)
        @test isequal(ts_m.values, vcat([1, 1], [NaN], collect(1.0:12.0)))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2019, 2):mm(2019, 4)] = [9, 10, 11]
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [9, 10, 11]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [9, 10, 11]))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        ts_m[mm(2017, 10):mm(2017, 11)] = [9, 10]
        @test ts_m[mm(2017, 10):mm(2017, 11)].values == [9, 10]
        @test ts_m.firstdate == mm(2017, 10)
        @test isequal(ts_m.values, vcat([9, 10], [NaN], collect(1.0:12.0)))
    end

    begin
        ts_m1 = TSeries(2018Q1:2018Q4, collect(1.0:4.0))
        ts_m2 = TSeries(2018Q1:2018Q4, zeros(4))
        setindex!(ts_m1, ts_m2, 2018Q3)
        @test ts_m1.values == [1.0, 2.0, 0.0, 4.0]
    end

    begin
        ts_m1 = TSeries(2018Q1:2019Q4, collect(1.0:8.0))
        setindex!(ts_m1, [0.0, 1.0, 2.0, 3.0], 2018Q3:2019Q2)
        @test ts_m1.values == [1.0, 2.0, 0.0, 1.0, 2.0, 3.0, 7.0, 8.0]
    end

    begin
        ts_m1 = TSeries(2018Q1:2019Q4, collect(1.0:8.0))
        setindex!(ts_m1, [0.0, 1.0, 2.0, 3.0], StepRange(2018Q1, 1Q3 - 1Q1, 2019Q4))
        @test ts_m1.values == [0.0, 2.0, 1.0, 4.0, 2.0, 6.0, 3.0, 8.0]
    end

    begin
        ts_m1 = TSeries(2018Q1:2019Q4, collect(1.0:8.0))
        setindex!(ts_m1, [0.0, 1.0, 2.0, 3.0], 2:5)
        @test ts_m1.values == [1.0, 0.0, 1.0, 2.0, 3.0, 6.0, 7.0, 8.0]
    end
end

@testset "Addition" begin
    x = TSeries(1U, [7, 7, 7])
    y = TSeries(3U, [2, 4, 5])
    @test x + y == TSeries(3U, [9])

    x = TSeries(1U, [7, 7, 7])
    y = TSeries(2U, [2, 4, 5])
    @test x + y == TSeries(2U, [9, 11])
end

@testset "Iris" begin
    # IRIS based assignment of values from other TSeries
    x = TSeries(qq(2020, 1), zeros(3))
    y = TSeries(qq(2020, 1), ones(3))
    x[qq(2020, 1):qq(2020, 2)] = y
    @test x == TSeries(qq(2020, 1), [1, 1, 0])


    let t = TSeries(5U:10U, ones)
        s = t[6U:8U]
        @test rangeof(s) === 6U:8U
        s .= 0.7
        t[6U:8U] = s
        @test t.values == [1, 0.7, 0.7, 0.7, 1, 1]

        s .= 0.8
        t[6U:7U] = s
        @test t.values == [1, 0.8, 0.8, 0.7, 1, 1]

        t[6U:7U] = [2, 3]
        @test t.values == [1, 2, 3, 0.7, 1, 1]

        @test_throws ArgumentError t[6Y:7Y] = s  # mixed frequency in indexing range
        @test_throws ArgumentError t[6U:7U] = TSeries(6Y, s.values)  # mixed frequency of src and dest
    end

    # IRIS related: shift
    x = TSeries(qq(2020, 1), zeros(3))
    @test shift(x, 1) == TSeries(qq(2019, 4), zeros(3))

    shift!(x, 1)
    @test x == TSeries(qq(2019, 4), zeros(3))

    # # IRIS related: nanrm!
    # x = TSeries(qq(2020, 1), [NaN, 123, NaN]);
    # nanrm!(x)
    # @test x == TSeries(qq(2020, 2), [123])


    # TODO
    # - pct
    # - apct



end

@testset "TS.math" begin
    let x = TSeries(2000Y:2010Y, ones)
        # lags and leads
        y = cumsum(x)
        @test rangeof(y) === rangeof(x)
        z = y
        @test z === y
        y1 = lag(y)
        @test rangeof(y1) === 1 .+ (rangeof(y)) && y1.values == y.values
        lag!(y)
        @test y1 == y && y1 !== y
        @test z === y
        y2 = lead(y, 2)
        @test rangeof(y2) === -2 .+ (rangeof(y)) && y2.values == y.values
        lead!(y, 3)
        @test lead(y2) == y && lead(y2) !== y
        @test z === y
        # opeartions
        @test x + x + 3x == 5x
        @test x + x.values == 2x
        @test x.values + x == 2x
    end
end

@testset "axes.range" begin
    @test axes(1U:5U) == axes(1:5)
    @test Base.axes1(2020Y:2030Y) == Base.OneTo(11)
end

@testset "overlay" begin
    # from FAME manual
    A, B = (TSeries(87Y, [1, 2, NaN, 4]), TSeries(87Y, [NaN, 6, 7, 8]))
    @test overlay(A, B) == TSeries(87Y, [1, 2, 7, 4])
    @test overlay(B, A) == TSeries(87Y, [1, 6, 7, 8])
    @test overlay(86Y:92Y, A, B) ≈ TSeries(86Y, [NaN, 1, 2, 7, 4, NaN, NaN]) nans = true
    @test (C = overlay(A, B); overlay(C, A).values == C.values)
end

@testset "strip" begin
    let rng_x = 2000Y:2010Y, x = TSeries(rng_x, ones)
        x[2011Y:2015Y] .= NaN
        x[1995Y:1999Y] .= NaN
        @test (rangeof(strip(x)) == rng_x)
        @test (TimeSeriesEcon.strip!(x); rangeof(x) == rng_x)
    end
end

macro _addone(expr)
    return QuoteNode(Expr(:call, :+, 1, expr))
end
@testset "recursive" begin
    ts = TSeries(1U, zeros(0))
    ts[1U] = ts[2U] = 1.0
    @rec 3U:10U ts[t] = ts[t-1] + ts[t-2]
    @test ts.values == [1.0, 1, 2, 3, 5, 8, 13, 21, 34, 55]
    t = zeros(10, 7)
    r = rand(1, 7)
    t[1, :] = r
    @rec s = 2:10 t[s, :] = t[s-1, :] .* s
    @test t ≈ factorial.(1:10) * r
    #
    s = ones(15)
    @rec i = 3:15 s[i] = s[i-1] + s[i-2]
    @test s == Float64[1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]
    s = TSeries(2020Q1:2021Q4)
    s[begin] = 0
    @test_throws UndefVarError @rec 2020Q1:2021Q2 s[i+1] = 1.0 + s[i]
    @rec i = firstdate(s):2023Q2 s[i+1] = 1.0 + s[i]
    @test rangeof(s) == 2020Q1:2023Q3
    @test values(s) == Float64[0:14...]
    resize!(s, 2020Q1:2020Q2)
    @rec firstdate(s)+1:2022Q3 s[t+1] = 2.0 * s[t] + s[t-1]
    @test rangeof(s) == 2020Q1:2022Q4
    @test values(s) == Float64[0, 1, 2, 5, 12, 29, 70, 169, 408, 985, 2378, 5741]

    tt = TSeries(0U, ones(4))
    @rec 1U:10U tt[t] = @_addone tt[t-1]
    @test tt == TSeries(0U, 1:11)
end

@testset "various" begin
    # compares
    a = TSeries(89Y, ones(7))
    b = TSeries(89Y, ones(7))
    @test TimeSeriesEcon.compare_equal(a, b) == true
    @test TimeSeriesEcon.compare_equal(a.values, b.values) == true
    @test TimeSeriesEcon.compare_equal(a.values[1], b.values[2]) == true

    c = TSeries(89Y, ones(7) * 1.1)
    @test TimeSeriesEcon.compare_equal(a, c) == false
    @test TimeSeriesEcon.compare_equal(a, c, atol=0.3) == true

    # test with nans
    d = TSeries(89Y, [1.5, 1.6, NaN, 1.8])
    e = TSeries(89Y, [1.5, 1.6, NaN, 1.8])
    @test TimeSeriesEcon.compare(d, e, nans=true, quiet=true) == true

    # compare with different ranges
    A = TSeries(2020Q1, rand(20))
    B = A[begin+4:end-4]
    @test false == @compare A B quiet
    @test true == @compare A B quiet ignoremissing
    @test false == @compare A B quiet trange = 2019Q1:2025Q4
    @test true == @compare A B quiet trange = 2019Q1:2025Q4 ignoremissing
    @test true == @compare A B quiet trange = 2000Q1:2000Q4
    @test true == @compare A B quiet trange = 2000Q1:2000Q4 ignoremissing

    #reindexing
    ts = TSeries(2020Q1, randn(10))
    ts2 = reindex(ts, 2021Q1 => 1U; copy=true)
    @test ts2[3U] == ts[2021Q3]
    @test length(ts2) == 10
    @test ts2[-3U] == ts[2020Q1]
    @test reindex(2022Q4, 2022Q1 => 1U) === 4U
end

@testset "pct" begin
    t1 = TSeries(2000Y, [1, 2, 4, 8])
    @test diff(t1).values == [1, 2, 4]
    @test rangeof(diff(t1)) == 2001Y:2003Y

    @test pct(t1).values == [100, 100, 100]
    @test rangeof(diff(t1)) == 2001Y:2003Y

    @test pct(t1, -2).values == [300, 300]
    @test rangeof(pct(t1, -2)) == 2002Y:2003Y

    t2 = TSeries(2000Y, log.([1, 2, 4, 8]))
    @test pct(t2; islog=true).values ≈ [100, 100, 100]
    @test rangeof(pct(t2; islog=true)) == 2001Y:2003Y

    #annualized
    t3 = TSeries(2000Q1, 2 .^ collect(1:20))
    @test pct(t3).values[1:3] == [100, 100, 100]
    @test apct(t3).values[1:3] == [1500, 1500, 1500]
    @test rangeof(apct(t3)) == 2000Q2:2004Q4
    t4 = TSeries(2000M1, 2 .^ collect(1:20))
    @test pct(t4).values[1:3] == [100, 100, 100]
    @test apct(t4).values[1:3] == [409500, 409500, 409500]
    @test rangeof(apct(t4)) == 2000M2:2001M8
    t5 = TSeries(2000Q1, log.(2 .^ collect(1:20)))
    @test pct(t5; islog=true).values[1:3] ≈ [100, 100, 100]
    @test apct(t5, true).values[1:3] ≈ [1500, 1500, 1500]
    @test rangeof(apct(t5, true)) == 2000Q2:2004Q4

    #year-to-year
    @test ytypct(t1).values[1:3] == [100, 100, 100]
    @test rangeof(ytypct(t1)) == 2001Y:2003Y
    @test ytypct(t3).values[1:3] == [1500, 1500, 1500]
    @test rangeof(ytypct(t3)) == 2001Q1:2004Q4
    @test ytypct(t4).values[1:3] == [409500, 409500, 409500]
    @test rangeof(ytypct(t4)) == 2001M1:2001M8


    ## supplemental nan tests
    x = TSeries(2000Y:2010Y, ones(Int32, 11))
    x2 = TSeries(2012Y:2020Y, ones(Int32, 9))
    x = overlay(x, x2)
    # x[2011Y:2015Y] .= NaN
    @test istypenan(x[2011Y]) == true
    @test istypenan(x[2000Y]) == false
    @test istypenan(nothing) == true
    @test istypenan(missing) == true
    @test istypenan(2) == false
end
