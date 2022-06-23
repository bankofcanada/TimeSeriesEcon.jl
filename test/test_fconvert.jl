using Suppressor


@testset "fconvert, general" begin
    t = TSeries(5U, collect(1:10))
    @test fconvert(Unit, t) === t
    @test_throws ErrorException fconvert(Quarterly, t) 
    
    q = TSeries(5Q1, 1.0collect(1:10))
    @test_throws ErrorException  fconvert(Unit, q)
    mq = fconvert(Monthly, q)
    @test typeof(mq) === TSeries{Monthly, Float64, Vector{Float64}}
    @test fconvert(Monthly, q, method=:const).values == repeat(1.0:10, inner=3)

    yq = fconvert(Yearly, q)
    @test typeof(yq) === TSeries{Yearly, Float64, Vector{Float64}}
    @test fconvert(Yearly, q, method=:mean).values == [2.5, 6.5]
    @test fconvert(Yearly, q, method=:end).values == [4.0, 8.0]
    @test fconvert(Yearly, q, method=:begin).values == [1.0, 5.0]
    @test fconvert(Yearly, q, method=:sum).values == [10.0, 26.0]


    for i = 1:11
        @test rangeof(fconvert(Yearly, TSeries(1M1 .+ (i:50)))) == 2Y:4Y
        @test rangeof(fconvert(Yearly, TSeries(1M1 .+ (0:47+i)))) == 1Y:4Y
    end
    for i = 1:3
        @test rangeof(fconvert(Yearly, TSeries(1Q1 .+ (i:50)))) == 2Y:12Y
        # @test rangeof(fconvert(Yearly, TSeries(1Q1 .+ (0:47+i)))) == 1Y:12Y 
    end
    for i = 1:11
        @test rangeof(fconvert(Quarterly, TSeries(1M1 .+ (i:50)))) == 1Q2+div(i-1,3):5Q1
        # @test rangeof(fconvert(Quarterly, TSeries(1M1 .+ (0:47+i)))) == 1Y:4Y #current output is 1Q1:4Q4
    end

    #wrong method for conversion direction
    @test_throws ArgumentError fconvert(Monthly, q, method=:mean)
    @test_throws ArgumentError fconvert(Yearly, q, method=:const)


end



@testset "fconvert, YPFrequencies, to higher" begin
    y1 = TSeries(MIT{Yearly}(22), [1,2])
    q1 = fconvert(Quarterly, y1)
    @test rangeof(q1) == 22Q1:23Q4;
    @test q1.values == [1,1,1,1,2,2,2,2]
    q1_beginning = fconvert(Quarterly, y1, values_base=:beginning)
    @test rangeof(q1_beginning) == 22Q1:23Q4;
    @test q1_beginning.values == [1,1,1,1,2,2,2,2]
    r1 = fconvert(Quarterly, rangeof(y1), values_base=:beginning)
    @test r1 == 22Q1:23Q4;
    mit1_start = fconvert(Quarterly, y1.firstdate, values_base=:beginning)
    @test mit1_start == 22Q1;
    
    y2 = TSeries(MIT{Yearly{7}}(22), [1,2])
    q2 = fconvert(Quarterly, y2)
    @test rangeof(q2) ==21Q3:23Q2;
    @test q2.values == [1,1,1,1,2,2,2,2]
    q2_beginning = fconvert(Quarterly, y2; values_base=:beginning)
    @test rangeof(q2_beginning) ==  21Q4:23Q3;
    @test q2_beginning.values == [1,1,1,1,2,2,2,2]
    r2 = fconvert(Quarterly, rangeof(y2); values_base=:beginning)
    @test r2 == 21Q4:23Q3
    mit2_start = fconvert(Quarterly, y2.firstdate, values_base=:beginning)
    @test mit2_start == 21Q4;

    y3 = TSeries(MIT{Yearly{7}}(22), [1,2])
    q3 = fconvert(Quarterly{1}, y3)
    @test rangeof(q3) ==  MIT{Quarterly{1}}(21*4+3):MIT{Quarterly{1}}(23*4+2) # 21Q4:23Q3;
    @test q3.values == [1,1,1,1,2,2,2,2]
    r3 = fconvert(Quarterly{1}, rangeof(y3))
    @test r3 == MIT{Quarterly{1}}(21*4+3):MIT{Quarterly{1}}(23*4+2) #21Q4:23Q3
    mit3_start = fconvert(Quarterly{1}, y3.firstdate)
    @test mit3_start == MIT{Quarterly{1}}(21*4+3); #21Q4
    q3_beginning = fconvert(Quarterly{1}, y3; values_base=:beginning)
    @test rangeof(q3_beginning) ==  MIT{Quarterly{1}}(21*4+3):MIT{Quarterly{1}}(23*4+2) # 21Q4:23Q3;
    @test q3_beginning.values == [1,1,1,1,2,2,2,2]
    r3_beginning = fconvert(Quarterly{1}, rangeof(y3); values_base=:beginning)
    @test r3_beginning == MIT{Quarterly{1}}(21*4+3):MIT{Quarterly{1}}(23*4+2) #21Q4:23Q3
    mit3_start_beginning = fconvert(Quarterly{1}, y3.firstdate, values_base=:beginning)
    @test mit3_start_beginning == MIT{Quarterly{1}}(21*4+3); #21Q4

    y4 = TSeries(MIT{Yearly}(22), [1,2])
    m1 = fconvert(Monthly, y4)
    @test rangeof(m1) == 22M1:23M12;
    @test m1.values == [repeat([1], 12)..., repeat([2], 12)...]
    r4 = fconvert(Monthly, rangeof(y4))
    @test r4 == 22M1:23M12;
    mit4_start = fconvert(Monthly, y4.firstdate)
    @test mit4_start == 22M1;

    y5 = TSeries(MIT{Yearly{7}}(22), [1,2])
    m2 = fconvert(Monthly, y5)
    @test rangeof(m2) ==21M8:23M7;
    @test m2.values == [repeat([1], 12)..., repeat([2], 12)...]
    r5 = fconvert(Monthly, rangeof(y5))
    @test r5 == 21M8:23M7;
    mit5_start = fconvert(Monthly, y5.firstdate)
    @test mit5_start == 21M8;


    # need one with orientation = :end != orientation = :end

    

end

@testset "fconvert, YPFrequencies, to lower" begin
    q1 = TSeries(1Q2, [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8])
    y1 = fconvert(Yearly, q1)
    @test rangeof(y1) == 2Y:4Y
    @test y1.values == [3, 5, 7]
    @suppress begin
        r1 = fconvert(Yearly, rangeof(q1))
        @test r1 == 2Y:4Y
    end
    mit1_start = fconvert(Yearly, q1.firstdate, round_to=:next)
    @test mit1_start == 2Y;
    mit1_end = fconvert(Yearly, last(rangeof(q1)), round_to=:previous)
    @test mit1_end == 4Y;
    

    q2 = TSeries(MIT{Quarterly{2}}(5), [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8])
    y2 = fconvert(Yearly, q2)
    @test rangeof(y2) == 2Y:4Y
    @test y2.values == [3 + 1/6, 5 + 1/6, 7 + 1/6]
    @suppress begin
        r2 = fconvert(Yearly, rangeof(q2))
        @test r2 == 2Y:4Y
    end
    mit2_start = fconvert(Yearly, q2.firstdate, round_to=:next)
    @test mit2_start == 2Y;
    mit2_end = fconvert(Yearly, last(rangeof(q2)), round_to=:previous)
    @test mit2_end == 4Y;

    q3 = TSeries(1Q2, [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8])
    y3 = fconvert(Yearly, q3)
    @test rangeof(y3) == 2Y:4Y
    @test y3.values == [3, 5, 7]
    @suppress begin
        r3 = fconvert(Yearly, rangeof(q3))
        @test r3 == 2Y:4Y
    end
    mit3_start = fconvert(Yearly, q3.firstdate, round_to=:next)
    @test mit3_start == 2Y;
    mit3_end = fconvert(Yearly, last(rangeof(q3)), round_to=:previous)
    @test mit3_end == 4Y;

    q4 = TSeries(MIT{Quarterly{2}}(5), [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8])
    y4 = fconvert(Yearly, q4)
    @test rangeof(y4) == 2Y:3Y
    @test y4.values == [3 + 1/6, 5 + 1/6]
    @suppress begin
        r4 = fconvert(Yearly, rangeof(q4))
        @test r4 == 2Y:3Y
    end
    mit4_start = fconvert(Yearly, q4.firstdate, round_to=:next)
    @test mit4_start == 2Y;

    m5 = TSeries(20M1, collect(1:36))
    y5 = fconvert(Yearly, m5)
    @test rangeof(y5) == 20Y:22Y
    @test y5.values == [6.5, 18.5, 30.5]
    @suppress begin
        r5 = fconvert(Yearly, rangeof(m5))
        @test r5 == 20Y:22Y
    end
    mit5_start = fconvert(Yearly, m5.firstdate, round_to=:next)
    @test mit5_start == 20Y;
    mit5_end = fconvert(Yearly, last(rangeof(m5)), round_to=:previous)
    @test mit5_end == 22Y;

    m6 = TSeries(20M1, collect(1:36))
    y6 = fconvert(Yearly{9}, m6)
    @test rangeof(y6) == MIT{Yearly{9}}(21):MIT{Yearly{9}}(22) #20Y:21Y
    @test y6.values == [15.5, 27.5]
    @suppress begin
        r6 = fconvert(Yearly{9}, rangeof(m6))
        @test r6 == MIT{Yearly{9}}(21):MIT{Yearly{9}}(22) #20Y:21Y
    end
    mit6_start = fconvert(Yearly{9}, m6.firstdate, round_to=:next)
    @test mit6_start == MIT{Yearly{9}}(21); #20Y:21Y
    mit6_end = fconvert(Yearly{9}, last(rangeof(m6)), round_to=:previous)
    @test mit6_end == MIT{Yearly{9}}(22); #20Y:21Y

    m7 = TSeries(20M1, collect(1:36))
    q7 = fconvert(Quarterly, m7)
    @test rangeof(q7) == 20Q1:22Q4
    @test q7.values == collect(2:3:35)
    @suppress begin
        r7 = fconvert(Quarterly, rangeof(m7))
        @test r7 == 20Q1:22Q4
    end
    mit7_start = fconvert(Quarterly, m7.firstdate, round_to=:next)
    @test mit7_start == 20Q1;
    mit7_end = fconvert(Quarterly, last(rangeof(m7)), round_to=:previous)
    @test mit7_end == 22Q4;

    m8 = TSeries(20M1, collect(1:36))
    q8 = fconvert(Quarterly{2}, m8)
    @test rangeof(q8) == MIT{Quarterly{2}}(20*4 + 1):MIT{Quarterly{2}}(22*4 + 3) #20Q2:22Q4
    @test q8.values == collect(4:3:34)
    @suppress begin
        r8 = fconvert(Quarterly{2}, rangeof(m8))
        @test r8 == MIT{Quarterly{2}}(20*4 + 1):MIT{Quarterly{2}}(22*4 + 3) #20Q2:22Q4
    end
    mit8_start = fconvert(Quarterly{2}, m8.firstdate, round_to=:next)
    @test mit8_start == MIT{Quarterly{2}}(20*4 + 1) # 20Q2
    mit8_end = fconvert(Quarterly{2}, last(rangeof(m8)), round_to=:previous)
    @test mit8_end == MIT{Quarterly{2}}(22*4 + 3) #22Q4

    # bias in single period conversions
    @test TimeSeriesEcon._to_lower(Quarterly, 20M2, round_to=:current) == 20Q1
    @test TimeSeriesEcon._to_lower(Quarterly, 20M2, round_to=:next) == 20Q2
    @test TimeSeriesEcon._to_lower(Quarterly, 20M2, round_to=:previous) == 19Q4
    @test TimeSeriesEcon._to_lower(Quarterly, 20M3, round_to=:previous) == 20Q1
    @test TimeSeriesEcon._to_lower(Quarterly, 20M1, round_to=:next) == 20Q1
    
    """
    FAME reproduction scripts
    =================================
    frequency ANNUAL
    DATE 2022 to 2023
    OVERWRITE ON
    SERIES !ts1 = 1,2
    report ts1
    report convert(ts1, QUARTERLY, CONSTANT,END)
    FREQUENCY ANNUAL(JULY)
    DATE 2022 to 2024
    SERIES !ts2 = 1,2
    FREQUENCY QUARTERLY(FEBRUARY)
    DATE 2020 to 2025
    SERIES !qs1 = 1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8
    DATE 2020 to 2025
    qs2 = shift(qs1, 1)
    CONVERT(QS1, ANNUAL, CONSTANT, AVERAGED)
    FREQUENCY MONTHLY
    DATE 2020 to 2023
    SERIES !m1 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36
    DATE 2019 to 2024
    report convert(m1, QUARTERLY, CONSTANT, AVERAGED)
    report convert(m1, QUARTERLY(FEBRUARY), CONSTANT, AVERAGED)
    report convert(m1, ANNUAL(SEPTEMBER), CONSTANT, AVERAGED)
    """

end

