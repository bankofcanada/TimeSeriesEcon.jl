# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

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
        # show(io, pp(20, 3; N=6))
        show(io, 5U)
        println(io, 2020M1 - 2019M1)
        show(io, 3U - 2U)
        show(io, 2000M12 - 2000M1)
        println(io, Duration{Yearly}(7))
        show(io, Q1)
        show(io, 1U)
        println(io, M1, M12, ".")
        foo = readlines(seek(io, 0))
        # @test foo == ["2020Q120P35U12", "1117", "1Q11U1M11M12."]
        @test foo == ["2020Q15U12", "1117", "1Q11U1M11M12."]
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
