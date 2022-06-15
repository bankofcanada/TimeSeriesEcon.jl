
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

    #non-user called functions
    @test_throws ArgumentError TimeSeriesEcon._to_lower(Monthly, q)
    @test_throws ArgumentError TimeSeriesEcon._to_higher(Yearly, q)

    #wrong method for conversion direction
    @test_throws ArgumentError fconvert(Monthly, q, method=:mean)
    @test_throws ArgumentError fconvert(Yearly, q, method=:const)


end



@testset "fconvert, YPFrequencies, to higher" begin
    y1 = TSeries(MIT{Yearly}(22), [1,2])
    q1 = fconvert(Quarterly, y1)
    @test rangeof(q1) == 22Q1:23Q4;
    @test q1.values == [1,1,1,1,2,2,2,2]
    q1_beginning = fconvert(Quarterly, y1, orientation=:beginning)
    @test rangeof(q1_beginning) == 22Q1:23Q4;
    @test q1_beginning.values == [1,1,1,1,2,2,2,2]

    y2 = TSeries(MIT{Yearly{7}}(22), [1,2])
    q2 = fconvert(Quarterly, y2)
    @test rangeof(q2) ==21Q3:23Q2;
    @test q2.values == [1,1,1,1,2,2,2,2]
    q2_beginning = fconvert(Quarterly, y2; orientation=:beginning)
    @test rangeof(q2_beginning) ==  21Q4:23Q3;
    @test q2_beginning.values == [1,1,1,1,2,2,2,2]

    y3 = TSeries(MIT{Yearly{7}}(22), [1,2])
    q3 = fconvert(Quarterly{1}, y3)
    @test rangeof(q3) ==  MIT{Quarterly{1}}(21*4+3):MIT{Quarterly{1}}(23*4+2) # 21Q4:23Q3;
    @test q3.values == [1,1,1,1,2,2,2,2]
    q3_beginning = fconvert(Quarterly{1}, y3; orientation=:beginning)
    @test rangeof(q3_beginning) ==  MIT{Quarterly{1}}(21*4+3):MIT{Quarterly{1}}(23*4+2) # 21Q4:23Q3;
    @test q3_beginning.values == [1,1,1,1,2,2,2,2]

    y4 = TSeries(MIT{Yearly}(22), [1,2])
    m1 = fconvert(Monthly, y4)
    @test rangeof(m1) == 22M1:23M12;
    @test m1.values == [repeat([1], 12)..., repeat([2], 12)...]

    y5 = TSeries(MIT{Yearly{7}}(22), [1,2])
    m2 = fconvert(Monthly, y5)
    @test rangeof(m2) ==21M8:23M7;
    @test m2.values == [repeat([1], 12)..., repeat([2], 12)...]

    

end

@testset "fconvert, YPFrequencies, to lower" begin
    q1 = TSeries(1Q2, [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8])
    y1 = fconvert(Yearly, q1)
    @test rangeof(y1) == 2Y:4Y
    @test y1.values == [3, 5, 7]

    q2 = TSeries(MIT{Quarterly{2}}(5), [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8])
    y2 = fconvert(Yearly, q2)
    @test rangeof(y2) == 2Y:4Y
    @test y2.values == [3 + 1/6, 5 + 1/6, 7 + 1/6]

    q3 = TSeries(1Q2, [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8])
    y3 = fconvert(Yearly, q3)
    @test rangeof(y3) == 2Y:4Y
    @test y3.values == [3, 5, 7]

    q4 = TSeries(MIT{Quarterly{2}}(5), [1,1,2,2,3,3,4,4,5,5,6,6,7,7,8])
    y4 = fconvert(Yearly, q4)
    @test rangeof(y4) == 2Y:3Y
    @test y4.values == [3 + 1/6, 5 + 1/6]

    m5 = TSeries(20M1, collect(1:36))
    y5 = fconvert(Yearly, m5)
    @test rangeof(y5) == 20Y:22Y
    @test y5.values == [6.5, 18.5, 30.5]

    m6 = TSeries(20M1, collect(1:36))
    y6 = fconvert(Yearly{9}, m6)
    @test rangeof(y6) == MIT{Yearly{9}}(21):MIT{Yearly{9}}(22) #20Y:21Y
    @test y6.values == [15.5, 27.5]

    m7 = TSeries(20M1, collect(1:36))
    q7 = fconvert(Quarterly, m7)
    @test rangeof(q7) == 20Q1:22Q4 #20Y:21Y
    @test q7.values == collect(2:3:35)

    m8 = TSeries(20M1, collect(1:36))
    q8 = fconvert(Quarterly{2}, m8)
    @test rangeof(q8) == MIT{Quarterly{2}}(20*4 + 1):MIT{Quarterly{2}}(22*4 + 3) #20Q2:22Q4
    @test q8.values == collect(4:3:34)
    
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

