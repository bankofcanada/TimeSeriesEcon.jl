using Test
using TimeSeriesEcon

import TimeSeriesEcon.yp

@testset "MIT,Duration" begin
    # yp conversions
    @test yp(MIT{Quarterly}(5)) == (1, 2)
    @test yp(MIT{Quarterly}(4)) == (1, 1)
    @test yp(MIT{Quarterly}(3)) == (0, 4)
    @test yp(MIT{Quarterly}(2)) == (0, 3)
    @test yp(MIT{Quarterly}(1)) == (0, 2)
    @test yp(MIT{Quarterly}(0)) == (0, 1)
    @test yp(MIT{Quarterly}(-1)) == (-1, 4)
    @test yp(MIT{Quarterly}(-2)) == (-1, 3)
    @test yp(MIT{Quarterly}(-3)) == (-1, 2)
    @test yp(MIT{Quarterly}(-4)) == (-1, 1)
    @test yp(MIT{Quarterly}(-5)) == (-2, 4)
    @test yp(MIT{Quarterly}(-6)) == (-2, 3)
    # subtractions
    @test typeof(qq(2020, 1) - qq(2019, 2)) == Duration{Quarterly}
    @test typeof(qq(2020, 1) - 2) == MIT{Quarterly}
    @test typeof(qq(2020, 1) - Duration{Quarterly}(2)) == MIT{Quarterly}
    @test typeof(Duration{Quarterly}(5) - 2) == Duration{Quarterly}
    @test typeof(Duration{Quarterly}(5) - Duration{Quarterly}(2)) == Duration{Quarterly}
    @test_throws ArgumentError qq(2020, 1) - mm(2019, 2)
    @test_throws ArgumentError qq(2020, 1) - Duration{Monthly}(5)
    @test_throws ArgumentError Duration{Quarterly}(8) - Duration{Monthly}(5)
    # equality
    @test qq(2020, 1) == qq(2020, 1)
    @test qq(2020, 1) != qq(2020, 2)
    @test qq(2020, 1) != mm(2020, 1)
    @test 5 == qq(2020, 1) - (qq(2020, 1) - 5)
    @test Duration{Quarterly}(5) == qq(2020, 1) - (qq(2020, 1) - 5)
    @test 5 == qq(2020, 1) - (qq(2020, 1) - 5)
    @test Duration{Monthly}(5) != qq(2020, 1) - (qq(2020, 1) - 5)
    @test Duration{Quarterly}(5) != MIT{Quarterly}(5)
    @test 5 == MIT{Quarterly}(5)
    # order
    @test qq(2000, 1) < qq(2000, 2)
    @test qq(2000, 1) <= qq(2000, 1)
    @test_throws ArgumentError qq(2000, 1) < mm(2000, 1)
    @test qq(0, 1) == 0
    @test mm(0, 1) == 0
    @test qq(0, 1) != mm(0, 1)
    @test_throws ArgumentError qq(0, 1) <= mm(0, 1)
    @test_throws ArgumentError qq(0, 1) < mm(0, 1)
    @test Duration{Quarterly}(5) < Duration{Quarterly}(6)
    @test !(Duration{Quarterly}(5) < Duration{Quarterly}(5))
    @test Duration{Quarterly}(5) <= Duration{Quarterly}(5)
    @test Duration{Quarterly}(5) == 5
    @test Duration{Monthly}(5) == 5
    @test !(Duration{Quarterly}(5) == Duration{Monthly}(5))
    @test_throws ArgumentError Duration{Quarterly}(5) < Duration{Monthly}(5)
    @test_throws ArgumentError Duration{Quarterly}(5) <= Duration{Monthly}(5)
    @test (MIT{Quarterly}(5) == 5) && (Duration{Quarterly}(5) == 5) && (MIT{Quarterly}(5) != Duration{Quarterly}(5))
    @test_throws ArgumentError MIT{Quarterly}(5) < Duration{Quarterly}(5)
    @test_throws ArgumentError MIT{Quarterly}(5) <= Duration{Quarterly}(5)
    @test_throws ArgumentError Duration{Quarterly}(5) < MIT{Quarterly}(5)
    @test_throws ArgumentError Duration{Quarterly}(5) <= MIT{Quarterly}(5)
    # addition
    @test qq(2020, 1) + 4 == qq(2021, 1)
    @test_throws ArgumentError qq(2020, 1) + qq(1, 0)
    @test_throws ArgumentError qq(2020, 1) + mm(1, 0)
    @test qq(2020, 1) + Duration{Quarterly}(4) == qq(2021, 1)
    @test Duration{Quarterly}(5) + Duration{Quarterly}(2) == 7
    @test Duration{Quarterly}(5) + 2 == 7
    @test Duration{Quarterly}(5) + 2 isa Duration{Quarterly}
    @test 2 + Duration{Quarterly}(5) == 7
    @test 2 + Duration{Quarterly}(5) isa Duration{Quarterly}
    @test_throws ArgumentError Duration{Quarterly}(5) + Duration{Monthly}(2)
    @test Duration{Quarterly}(5) + Duration{Quarterly}(2) isa Duration{Quarterly}
    @test_throws ArgumentError 20Q1 + Duration{Monthly}(2)
    # conversions to float (for plotting)
    @test 2000Q1 + 1 == 2000Q2
    @test 2000Q1 + 1.0 == 2001.0
    @test 2000Q1 + 1.2 == 2001.2
    @test 1.2 + 5U == 6.2
    @test 5U + 1.2 == 6.2
    # promotions
    @test_throws ArgumentError promote(1, 1Q1) 
    @test_throws ArgumentError promote(1Q1, 1) 
    @test_throws ArgumentError promote(1Q1 - 1Q1, 1) 
    @test_throws ArgumentError promote(1, 1Q1 - 1Q1) 
    @test promote(1.1, 1Q1) === (1.1, 1.0)
    @test promote(1Q1, 1.2) === (1.0, 1.2)
end

@testset "Range" begin
    rng = 2020Q1:2020Q4
    @test rng isa UnitRange{MIT{Quarterly}}
    @test isempty(2020Q1:2019Q1)
    @test length(rng) isa Int
    @test length(rng) == 4
    @test step(rng) isa Int
    @test step(rng) == 1
    for (i, m) in enumerate(rng)
    @test m isa MIT{Quarterly}
        @test first(rng) <= m <= last(rng)
        @test rng[i] == m
    end
    @test_throws ArgumentError 2020Q1:2020M12
    @test union(3U:5U, 4U:6U) === 3U:6U
    @test_throws ArgumentError union(3U:5U, 4Q1:6Q1) 
end

@testset "FPConst" begin
    @test 8U === MIT{Unit}(8)
    @test 2000Y === yy(2000)
    @test 1999Q1 === qq(1999, 1)
    @test 1999Q2 === qq(1999, 2)
    @test 1999Q3 === qq(1999, 3)
    @test 1999Q4 === qq(1999, 4)
    @test 1988M12 === mm(1988, 12)
    @test 1988M11 === mm(1988, 11)
    @test 1988M10 === mm(1988, 10)
    @test 1988M9 === mm(1988, 9)
    @test 1988M8 === mm(1988, 8)
    @test 1988M7 === mm(1988, 7)
    @test 1988M6 === mm(1988, 6)
    @test 1988M5 === mm(1988, 5)
    @test 1988M4 === mm(1988, 4)
    @test 1988M3 === mm(1988, 3)
    @test 1988M2 === mm(1988, 2)
    @test 1988M1 === mm(1988, 1)
end


@testset "MITops" begin
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

@testset "MIT.show" begin
    let io = IOBuffer()
        show(io, 2020Q1)
        show(io, pp(20, 3; N=6))
        show(io, 5U)
        println(io, 2020M1 - 2019M1)
        show(io, 3U - 2U)
        show(io, 2000M12 - 2000M1)
        println(io, Duration{Yearly}(7))
        show(io, Q1)
        show(io, 1U)
        println(io, M1, M12, ".")
        foo = readlines(seek(io, 0))
        @test foo == ["2020Q120P35U12", "1117", "1Q11U1M11M12."]
    end
end

@testset "frequencyof" begin
    @test frequencyof(qq(2000, 1)) == Quarterly
    @test frequencyof(mm(2000, 1)) == Monthly
    @test frequencyof(yy(2000)) == Yearly
    @test frequencyof(1U) == Unit
    @test frequencyof(qq(2001, 1):qq(2002, 1)) == Quarterly
    @test_throws ArgumentError frequencyof(1)
    @test_throws ArgumentError frequencyof(Int)
    @test frequencyof(qq(2000, 1) - qq(2000, 1)) == Quarterly
    @test frequencyof(mm(2000, 1) - mm(2000, 1)) == Monthly
    @test frequencyof(yy(2000, 1) - yy(2000, 1)) == Yearly
    @test frequencyof(5U - 3U) == Unit
    @test frequencyof(TSeries(yy(2000), zeros(5))) == Yearly
end

@testset "mm, qq, yy" begin
    @test mm(2020, 1) == MIT{Monthly}(2020 * 12)
    @test qq(2020, 1) == MIT{Quarterly}(2020 * 4)
    @test yy(2020) == MIT{Yearly}(2020)
end

@testset "year, period" begin
    @test_throws ArgumentError year(1U)
    let val = pp(2020, 2; N=6)
        @test year(val) == 2020
        @test period(val) == 2
        @test frequencyof(val) === YPFrequency{6}
    end
    @test year(mm(2020, 12)) == 2020
    @test period(mm(2020, 12)) == 12
end

@testset "TSeries" begin
    # test constructors
    s = TSeries(20Q1, collect(10.0 .+ (1:12)))
    @test typeof(s) === TSeries{Quarterly,Float64,Array{Float64,1}}
    @test size(s) == (12,)
    @test axes(s) == (20Q1:22Q4,)
    @test length(s) == 12

    t = TSeries(Int, 5)   # from type and number
    @test typeof(t) === TSeries{Unit,Int,Vector{Int}} && t.firstdate == 1U && length(t.values) == 5
    t = TSeries(UInt8, 4 .+ (1:5)) # from type and Int range
    @test typeof(t) === TSeries{Unit,UInt8,Vector{UInt8}} && t.firstdate == 5U && length(t.values) == 5
    t = TSeries(Float32, 1:5, undef) # from type, range and undef
    @test typeof(t) === TSeries{Unit,Float32,Vector{Float32}} && t.firstdate == 1U && length(t.values) == 5

    # constructing with similar()
    t = similar(ones(Float64, 5), (2Q1:4Q4))
    @test typeof(t) === TSeries{Quarterly,Float64,Vector{Float64}} && t.firstdate == 2Q1 && length(t.values) == 12

    # indexing
    @test s[1] == 11.0
    @test s[12] == 22.0
    @test s[1:3] == [11.0, 12.0, 13.0]
    @test s[1:2:12] == collect(10.0 .+ (1:2:12))
    @test s[s .< 13] == [11.0, 12.0]
    #
    @test s[20Q1] == 11.0
    @test s[begin] == s.values[1]
    @test s[end] == s.values[end]
    @test s[begin:begin + 3] isa typeof(s)
    @test s[begin:begin + 3].values == s.values[begin:begin + 3]
    @test (@. 13 < s < 16 ) isa TSeries{frequencyof(s),Bool}
    #
    @test_throws ArgumentError s[2:end]  # can't mix Int indexing with begin/end
    @test_throws ArgumentError s[begin:4]
    #
    @test_throws ArgumentError s[1U]  # wrong frequency
    @test_throws ArgumentError s[1Y:3Y]  # wrong frequency
    @test_throws ArgumentError s[2Y] = 5  # wrong frequency

    q = copy(s)
    s[19Q1] = 5  # outside range
    @test s.values ≈ [5, NaN, NaN, NaN, q.values...] nans=true
    s[end + 3] = 3  # outside range
    @test s.values ≈ [5, NaN, NaN, NaN, q.values..., NaN, NaN, 3] nans=true

    @test_throws ArgumentError s[20Y:21Y] = [2, 3]  # wrong frequency

    i = TSeries(20Y, ones(Int32, 5))
    i[17Y] = -1
    @test i.values == [-1, typenan(Int32), typenan(Int32), ones(5)...]

    @test_throws ArgumentError resize!(i, 17U:24U)  # wrong frequency
    @test_throws ArgumentError copyto!(i, 17U:24U, i)  # wrong frequency
    @test_throws ArgumentError copyto!(i, s)  # wrong frequency
end

@testset "Bcast" begin
    t = TSeries(5U:10U, rand(6))

    # we can broadcast with a singleton
    r = t .+ 5
    @test typeof(r) == typeof(t) && eachindex(r) == eachindex(t) && all(r.values .== t.values .+ 5)

    # we can broadcast with another TSeries of identical range
    r = t .+ TSeries(5U, collect(1:6))
    @test typeof(r) == typeof(t) && eachindex(r) == eachindex(t) && all(r.values .== t.values .+ (1:6))

    # we can broadcast with another TSeries of different range
    r = t .+ TSeries(4U, collect(1:6))
    @test typeof(r) == typeof(t) && eachindex(r) == 5U:9U && all(r.values .== t.values[1:end - 1] .+ (2:6))

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

    # dot-assign into a range
    t[begin + 2:end - 2] .= 2
    @test t.values == [2, 3, 2, 2, 6, 7]
    
    t[end + 2:end + 4] .= 8
    @test t.values ≈ [2, 3, 2, 2, 6, 7, NaN, 8, 8, 8] nans = true

    # setindex with BitArray
    t[t .< 7] .= 0
    @test t.values ≈ [0, 0, 0, 0, 0, 7, NaN, 8, 8, 8] nans = true
    
    t[2:4] .= 1
    @test t.values ≈ [0, 1, 1, 1, 0, 7, NaN, 8, 8, 8] nans = true

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
        @test t[[1,3,4]] isa Vector{Float64}
        @test t[[1,3,4]] == t.values[[1,3,4]]
        # test assignment
        @test begin
            t[2:4] .= 2.5
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
        z[begin .+ (2:4)] .+= 0.2
        z[begin .+ (3:4)] = [3,4]
        @test z != t
        z = view(t, 2:5)
        c = view(t, 2010M2:2010M5)
@test c == z
        @test z == t[begin .+ (1:4)]
        z[[1,3]] += [0.5, 0.5]
        z[[2,4]] = [1,1.5]
        @test c == z
        @test z == t[begin .+ (1:4)]
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
    @test 5tq isa TSeries{Quarterly} 
    @test tq * 5 isa TSeries{Quarterly} 
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
    @test_throws BoundsError ts_q[qq(2017, 1)] == nothing
    @test_throws BoundsError ts_q[qq(2017, 1):qq(2017, 3)] == nothing
end

@testset "Yearly" begin
    @test ts_y[yy(2018):yy(2029)] == ts_y

    # access outside of ts boundaries
    @test_throws BoundsError ts_y[yy(2017):yy(2017) + 100] == ts_y

    # partially out of boundary
    @test_throws BoundsError ts_y[yy(2017):yy(2018)] == ts_y[yy(2018):yy(2018)]
    @test_throws BoundsError ts_y[yy(2017):yy(2021)] == ts_y[1:4]

    @test_throws BoundsError ts_y[yy(2018):yy(2100)] == ts_y[yy(2018):yy(2029)]
    @test_throws BoundsError ts_y[yy(2021):yy(2100)] == ts_y[4:12]

    # fully out of boundary
    @test_throws BoundsError ts_y[yy(2017)] == nothing
    @test_throws BoundsError ts_y[yy(2010):yy(2017)] == nothing
end

# ts_m = TSeries(mm(2018, 1), collect(1.0:12.0))
@testset "Setting" begin
    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        @test_throws BoundsError ts_m[mm(2019, 2):mm(2019, 4)] = 1;
        ts_m[mm(2019, 2):mm(2019, 4)] .= 1;
        @test ts_m[mm(2019, 2):mm(2019, 4)].values == [1, 1, 1]
        @test ts_m.firstdate == mm(2018, 1)
        @test isequal(ts_m.values, vcat(collect(1.0:12.0), [NaN], [1, 1, 1]))
    end

    begin
        ts_m = TSeries(mm(2018, 1):mm(2018, 12), collect(1.0:12.0))
        @test_throws BoundsError ts_m[mm(2017, 10):mm(2017, 11)] = 1;
        ts_m[mm(2017, 10):mm(2017, 11)] .= 1;
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
    x = TSeries(qq(2020, 1), zeros(3));
    y = TSeries(qq(2020, 1), ones(3));
    x[qq(2020, 1):qq(2020, 2)] = y;
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

        t[6U:7U] = [2,3]
        @test t.values == [1, 2, 3, 0.7, 1, 1]

        @test_throws ArgumentError t[6Y:7Y] = s  # mixed frequency in indexing range
        @test_throws ArgumentError t[6U:7U] = TSeries(6Y, s.values)  # mixed frequency of src and dest
    end

        # IRIS related: shift
    x = TSeries(qq(2020, 1), zeros(3));
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
        @test rangeof(y1) === 1 .+ (rangeof(y))  && y1.values == y.values
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
        @test_throws ArgumentError x + x.values 
        @test_throws ArgumentError x.values + x
    end
end

@testset "axes.range" begin
    @test axes(1U:5U) == axes(1:5)
    @test Base.axes1(2020Y:2030Y) == Base.OneTo(11)
end

@testset "overlay" begin
    # from FAME manual
    A, B = (TSeries(87Y, [1, 2, NaN, 4]), TSeries(87Y, [NaN, 6, 7, 8]))
    @test overlay(A, B) == TSeries(87Y, [1,2,7,4])
    @test overlay(B, A) == TSeries(87Y, [1,6,7,8])
    @test overlay(86Y:92Y, A, B) ≈ TSeries(86Y, [NaN, 1, 2, 7, 4, NaN, NaN]) nans = true
end

@testset "fconvert" begin
    t = TSeries(5U, collect(1:10))
    @test fconvert(Unit, t) === t
    @test_throws ErrorException fconvert(Quarterly, t) 
    
    q = TSeries(5Q1, 1.0collect(1:10))
    @test_throws ErrorException  fconvert(Unit, q)
    mq = fconvert(Monthly, q)
    @test typeof(mq) === TSeries{Monthly, Float64, Vector{Float64}}
    yq = fconvert(Yearly, q)
    @test typeof(yq) === TSeries{Yearly, Float64, Vector{Float64}}

    for i = 1:11
        @test rangeof(fconvert(Yearly, TSeries(1M1 .+ (i:50)))) == 2Y:4Y
        @test rangeof(fconvert(Yearly, TSeries(1M1 .+ (0:47+i)))) == 1Y:4Y
    end
    for i = 1:3
        @test rangeof(fconvert(Yearly, TSeries(1Q1 .+ (i:50)))) == 2Y:12Y
        @test rangeof(fconvert(Yearly, TSeries(1Q1 .+ (0:47+i)))) == 1Y:12Y
    end
    for i = 1:11
        @test rangeof(fconvert(Quarterly, TSeries(1M1 .+ (i:50)))) == 1Q2+div(i-1,3):5Q1
        # @test rangeof(fconvert(Quarterly, TSeries(1M1 .+ (0:47+i)))) == 1Y:4Y
    end

end

# @testset "recursive" begin
#     ts = TSeries(1U, zeros(0))
#     ts[1U] = ts[2U] = 1.0
#     @rec 3U:10U ts[t] = ts[t-1]+ts[t-2]
        #     @test ts.values == [1.0,1,2,3,5,8,13,21,34,55]
#     t = zeros(10,7)
#     r = rand(1, 7)
#     t[1, :] = r
#     @rec 2:10 t[s,:] = t[s-1,:] .* s
#     @test t ≈ factorial.(1:10) * r
# end
