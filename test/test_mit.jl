# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

import TimeSeriesEcon: qq, mm, yy
using Dates

@testset "MIT,Duration" begin
    # mit2yp conversions
    @test mit2yp(MIT{Quarterly}(5)) == (1, 2)
    @test mit2yp(MIT{Quarterly}(4)) == (1, 1)
    @test mit2yp(MIT{Quarterly}(3)) == (0, 4)
    @test mit2yp(MIT{Quarterly}(2)) == (0, 3)
    @test mit2yp(MIT{Quarterly}(1)) == (0, 2)
    @test mit2yp(MIT{Quarterly}(0)) == (0, 1)
    @test mit2yp(MIT{Quarterly}(-1)) == (-1, 4)
    @test mit2yp(MIT{Quarterly}(-2)) == (-1, 3)
    @test mit2yp(MIT{Quarterly}(-3)) == (-1, 2)
    @test mit2yp(MIT{Quarterly}(-4)) == (-1, 1)
    @test mit2yp(MIT{Quarterly}(-5)) == (-2, 4)
    @test mit2yp(MIT{Quarterly}(-6)) == (-2, 3)
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

    # custom frequencies
    customFreq = YPFrequency{5}
    customFreq2 = YPFrequency{11}
    d1 = Duration{customFreq}(10)
    d2 = Duration{customFreq}(4)
    d3 = Duration{customFreq2}(4)
    @test d1 - d2 == 6
    @test div(d1,d2) == 2
    @test rem(d1,d2) == 2
    @test div(d2,d1) == 0
    @test_throws ArgumentError div(d2,d3)
    @test_throws ArgumentError rem(d2,d3)

    #hash
    @test hash(1Q1, UInt(8)) == hash(("Quarterly", 4), UInt(8))
    @test hash(1Q3 - 1Q1, UInt(8)) == hash(("Quarterly", 2), UInt(8))
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

    # step ranges
    sr1 = 1Q1:1Q3-1Q1:4Q4
    @test length(sr1) == 8
    @test step(sr1) == 2
    @test first(sr1) == 1Q1
    @test last(sr1) == 4Q3
    @test collect(sr1) == [1Q1, 1Q3, 2Q1, 2Q3, 3Q1, 3Q3, 4Q1, 4Q3]
    
    sr2 = 1Q1:2:4Q4
    @test length(sr2) == 8
    @test step(sr2) == 2
    @test first(sr2) == 1Q1
    @test last(sr2) == 4Q3
    @test collect(sr2) == [1Q1, 1Q3, 2Q1, 2Q3, 3Q1, 3Q3, 4Q1, 4Q3]

    @test_throws ArgumentError 1Q2:2:5U
    @test_throws ArgumentError 1Q2:1Q1-1Q2:5U
    
    
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
        # show(io, pp(20, 3; N=6))
        show(io, 5U)
        println(io, 2020M1 - 2019M1)
        show(io, 3U - 2U)
        show(io, 2000M12 - 2000M1)
        println(io, Duration{Yearly}(7))
        show(io, Q1)
        show(io, 1U)
        println(io, M1, M12, ".")

        customFreq = YPFrequency{4}
        customMIT = MIT{customFreq}(5)
        show(io, customMIT)

        customFreq2 = YPFrequency{5}
        customMIT2 = MIT{customFreq2}(6)
        println(io, "")
        show(io, customMIT2)

        println(io, "")
        show(io, U)

        foo = readlines(seek(io, 0))
        # @test foo == ["2020Q120P35U12", "1117", "1Q11U1M11M12."]
        @test foo == ["2020Q15U12", "1117", "1Q11U1M11M12.", "1Q2", "1P2", "1U"]
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
    let val = qq(2020, 2)
        @test year(val) == 2020
        @test period(val) == 2
        @test frequencyof(val) <: YPFrequency{4}
    end
    @test year(mm(2020, 12)) == 2020
    @test period(mm(2020, 12)) == 12
end

@testset "daily, business_daily" begin
    # daily
    d1 = MIT{Daily}(738156)
    @test Dates.Date(d1) == Dates.Date("2022-01-01")
    d2 = daily("2022-01-01")
    @test typeof(d2) == MIT{Daily}
    @test d2 == d1
    d3 = d"2022-01-01"
    @test typeof(d3) == MIT{Daily}
    @test d3 == d1

    # range
    d_rng = d"2022-01-01:2022-01-20"
    @test frequencyof(d_rng) == Daily
    @test typeof(d_rng) == UnitRange{MIT{Daily}}
    @test Dates.Date(first(d_rng)) == Dates.Date("2022-01-01")
    @test Dates.Date(last(d_rng)) == Dates.Date("2022-01-20")

    # business daily
    bd1 = MIT{BusinessDaily}(527256)
    @test Dates.Date(bd1) == Dates.Date("2022-01-03")
    bd2 = bdaily("2022-01-03")
    @test typeof(bd2) == MIT{BusinessDaily}
    @test bd2 == bd1
    bd3 = bd"2022-01-03"
    @test typeof(bd3) == MIT{BusinessDaily}
    @test bd3 == bd1
    bd_weekend1 = bdaily("2022-01-02")
    @test Dates.Date(bd_weekend1) == Dates.Date("2021-12-31")
    bd_weekend2 = bdaily("2022-01-02", bias_previous=false)
    @test Dates.Date(bd_weekend2) == Dates.Date("2022-01-03")
    bd_weekend3 = bd"2022-01-02"
    @test Dates.Date(bd_weekend3) == Dates.Date("2021-12-31")
    bd_weekend4 = bd"2022-01-02"n
    @test Dates.Date(bd_weekend4) == Dates.Date("2022-01-03")
    bd_weekend5 = bd"2022-01-02"next
    @test Dates.Date(bd_weekend5) == Dates.Date("2022-01-03")

    # range
    bd_rng = bd"2022-01-01:2022-01-22"
    @test frequencyof(bd_rng) == BusinessDaily
    @test typeof(bd_rng) == UnitRange{MIT{BusinessDaily}}
    @test Dates.Date(first(bd_rng)) == Dates.Date("2022-01-03")
    @test Dates.Date(last(bd_rng)) == Dates.Date("2022-01-21")

end
