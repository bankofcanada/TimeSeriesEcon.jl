using Suppressor
using Statistics


@testset "fconvert, general" begin
    t = TSeries(5U, collect(1:10))
    @test fconvert(Unit, t) === t
    @test_throws ErrorException fconvert(Quarterly, t)

    q = TSeries(5Q1, 1.0collect(1:10))
    @test_throws ErrorException fconvert(Unit, q)
    mq = fconvert(Monthly, q)
    @test typeof(mq) === TSeries{Monthly,Float64,Vector{Float64}}
    @test fconvert(Monthly, q, method=:const).values == repeat(1.0:10, inner=3)

    yq = fconvert(Yearly, q)
    @test typeof(yq) === TSeries{Yearly{12},Float64,Vector{Float64}}
    @test fconvert(Yearly, q, method=:mean).values == [2.5, 6.5]
    @test fconvert(Yearly, q, method=:point, values_base=:end).values == [4.0, 8.0]
    @test fconvert(Yearly, q, method=:point, values_base=:begin).values == [1.0, 5.0, 9.0]
    @test fconvert(Yearly, q, method=:sum).values == [10.0, 26.0]

    h = TSeries(5H1, 1.0*collect(1:10))
    yh = fconvert(Yearly, h)
    @test typeof(yh) == TSeries{Yearly{12},Float64,Vector{Float64}}
    @test fconvert(Yearly, h, method=:mean).values == [1.5, 3.5, 5.5, 7.5, 9.5]
    @test fconvert(Yearly, h, method=:point, values_base=:end).values == [2,4,6,8,10]
    @test fconvert(Yearly, h, method=:point, values_base=:begin).values == [1,3,5,7,9]
    @test fconvert(Yearly, h, method=:sum).values == [3,7,11,15,19]

    for i = 1:11
        @test rangeof(fconvert(Yearly, TSeries(1M1 .+ (i:50)), method=:mean)) == 2Y:4Y
        @test rangeof(fconvert(Yearly, TSeries(1M1 .+ (0:47+i)))) == 1Y:4Y
    end
    for i = 1:3
        @test rangeof(fconvert(Yearly, TSeries(1Q1 .+ (i:50)), method=:mean)) == 2Y:12Y
        @test rangeof(fconvert(Yearly, TSeries(1Q1 .+ (0:47+i)))) == 1Y:12Y 
    end
    for i = 1:2
        @test rangeof(fconvert(Yearly, TSeries(1H1 .+ (i:50)), method=:mean)) == 2Y:25Y
    end
    for i = 1:11
        @test rangeof(fconvert(Quarterly, TSeries(1M1 .+ (i:50)), method=:mean)) == 1Q2+div(i - 1, 3):5Q1
        # @test rangeof(fconvert(Quarterly, TSeries(1M1 .+ (0:47+i)))) == 1Q1:4Q4 #current output is 1Q1:4Q4
    end

    #wrong method for conversion direction
    @test_throws ArgumentError fconvert(Monthly, q, method=:mean)
    @test_throws ArgumentError fconvert(Yearly, q, method=:const)


end

@testset "fconvert, YPFrequencies, to higher" begin
    y1 = TSeries(MIT{Yearly}(22), [1, 2])
    q1 = fconvert(Quarterly, y1)
    @test rangeof(q1) == 22Q1:23Q4
    @test q1.values == [1, 1, 1, 1, 2, 2, 2, 2]
    q1_beginning = fconvert(Quarterly, y1, values_base=:begin)
    @test rangeof(q1_beginning) == 22Q1:23Q4
    @test q1_beginning.values == [1, 1, 1, 1, 2, 2, 2, 2]
    r1 = fconvert(Quarterly, rangeof(y1), trim=:end)
    @test r1 == 22Q1:23Q4
    # mit1_start = fconvert(Quarterly, y1.firstdate, values_base=:begin)
    # @test mit1_start == 22Q1
    # @test fconvert(Quarterly, y1.firstdate, values_base=:begin, round_to=:previous) == 22Q1
    # @test fconvert(Quarterly, y1.firstdate, values_base=:begin, round_to=:next) == 22Q1
    # @test fconvert(Quarterly, y1.firstdate, values_base=:begin, round_to=:current) == 22Q1
    # @test fconvert(Quarterly, y1.firstdate, values_base=:end, round_to=:previous) == 22Q4
    # @test fconvert(Quarterly, y1.firstdate, values_base=:end, round_to=:next) == 22Q4
    # @test fconvert(Quarterly, y1.firstdate, values_base=:end, round_to=:current) == 22Q4

    y2 = TSeries(MIT{Yearly{7}}(22), [1, 2])
    q2 = fconvert(Quarterly, y2)
    @test q2.values == [1, 1, 1, 1, 2, 2, 2, 2]
    @test rangeof(q2) == 21Q3:23Q2
    q2_beginning = fconvert(Quarterly, y2; values_base=:begin)
    @test rangeof(q2_beginning) == 21Q4:23Q3
    @test q2_beginning.values == [1, 1, 1, 1, 2, 2, 2, 2]
    r2 = fconvert(Quarterly, rangeof(y2); trim=:end)
    @test r2 == 21Q3:23Q2
    # mit2_start = fconvert(Quarterly, y2.firstdate, values_base=:begin)
    # @test mit2_start == 21Q3
    # @test fconvert(Quarterly, y2.firstdate, values_base=:begin, round_to=:previous) == 21Q3
    # @test fconvert(Quarterly, y2.firstdate, values_base=:begin, round_to=:next) == 21Q4
    # @test fconvert(Quarterly, y2.firstdate, values_base=:begin, round_to=:current) == 21Q3
    # @test fconvert(Quarterly, y2.firstdate, values_base=:end, round_to=:previous) == 22Q2
    # @test fconvert(Quarterly, y2.firstdate, values_base=:end, round_to=:next) == 22Q3
    # @test fconvert(Quarterly, y2.firstdate, values_base=:end, round_to=:current) == 22Q3

    y3 = TSeries(MIT{Yearly{7}}(22), [1, 2])
    q3 = fconvert(Quarterly{1}, y3)
    @test rangeof(q3) == MIT{Quarterly{1}}(21 * 4 + 3):MIT{Quarterly{1}}(23 * 4 + 2) # 21Q4:23Q3;
    @test q3.values == [1, 1, 1, 1, 2, 2, 2, 2]
    r3 = fconvert(Quarterly{1}, rangeof(y3))
    @test r3 == MIT{Quarterly{1}}(21 * 4 + 3):MIT{Quarterly{1}}(23 * 4 + 2) #21Q4:23Q3
    # mit3_start = fconvert(Quarterly{1}, y3.firstdate, values_base=:begin)
    # @test mit3_start == MIT{Quarterly{1}}(21 * 4 + 3) #21Q4
    q3_beginning = fconvert(Quarterly{1}, y3; values_base=:begin)
    @test rangeof(q3_beginning) == MIT{Quarterly{1}}(21 * 4 + 3):MIT{Quarterly{1}}(23 * 4 + 2) # 21Q4:23Q3;
    @test q3_beginning.values == [1, 1, 1, 1, 2, 2, 2, 2]
    r3_beginning = fconvert(Quarterly{1}, rangeof(y3); trim=:end)
    @test r3_beginning == MIT{Quarterly{1}}(21 * 4 + 3):MIT{Quarterly{1}}(23 * 4 + 2) #21Q4:23Q3
    # mit3_start_beginning = fconvert(Quarterly{1}, y3.firstdate, values_base=:begin)
    # @test mit3_start_beginning == MIT{Quarterly{1}}(21 * 4 + 3) #21Q4


    y4 = TSeries(MIT{Yearly}(22), [1, 2])
    m1 = fconvert(Monthly, y4)
    @test rangeof(m1) == 22M1:23M12
    @test m1.values == [repeat([1], 12)..., repeat([2], 12)...]
    r4 = fconvert(Monthly, rangeof(y4))
    @test r4 == 22M1:23M12
    # mit4_start = fconvert(Monthly, y4.firstdate, values_base=:begin, round_to=:next)
    # @test mit4_start == 22M1

    y5 = TSeries(MIT{Yearly{7}}(22), [1, 2])
    m2 = fconvert(Monthly, y5)
    @test rangeof(m2) == 21M8:23M7
    @test m2.values == [repeat([1], 12)..., repeat([2], 12)...]
    r5 = fconvert(Monthly, rangeof(y5))
    @test r5 == 21M8:23M7
    # mit5_start = fconvert(Monthly, y5.firstdate, values_base=:begin, round_to=:next)
    # @test mit5_start == 21M8

    y6 = TSeries(2022Y, collect(1:4))
    m6_begin = fconvert(Monthly, y6, method=:linear, values_base=:begin)
    @test rangeof(m6_begin) == 2022M1:2025M12
    @test values(m6_begin) == [1.0, 1.0833333333333333, 1.1666666666666667, 1.25, 1.3333333333333335, 1.4166666666666665, 1.5, 1.5833333333333335, 1.6666666666666665, 1.75, 1.8333333333333335, 1.9166666666666665, 2.0, 2.083333333333333, 2.166666666666667, 2.25, 2.3333333333333335, 2.4166666666666665, 2.5, 2.583333333333333, 2.666666666666667, 2.75, 2.833333333333333, 2.916666666666667, 3.0, 3.0833333333333335, 3.1666666666666665, 3.25, 3.333333333333333, 3.4166666666666665, 3.5, 3.5833333333333335, 3.6666666666666665, 3.75, 3.8333333333333335, 3.9166666666666665, 4.0, 4.083333333333333, 4.166666666666667, 4.25, 4.333333333333334, 4.416666666666666, 4.5, 4.583333333333334, 4.666666666666666, 4.75, 4.833333333333334, 4.916666666666666]
    m6_end = fconvert(Monthly, y6, method=:linear, values_base=:end)
    @test rangeof(m6_end) == 2022M1:2025M12
    @test values(m6_end) == [0.08333333333333333, 0.16666666666666666, 0.25, 0.3333333333333333, 0.4166666666666667, 0.5, 0.5833333333333334, 0.6666666666666666, 0.75, 0.8333333333333334, 0.9166666666666666, 1.0, 1.0833333333333333, 1.1666666666666667, 1.25, 1.3333333333333335, 1.4166666666666665, 1.5, 1.5833333333333335, 1.6666666666666665, 1.75, 1.8333333333333335, 1.9166666666666665, 2.0, 2.083333333333333, 2.166666666666667, 2.25, 2.3333333333333335, 2.4166666666666665, 2.5, 2.583333333333333, 2.666666666666667, 2.75, 2.833333333333333, 2.916666666666667, 3.0, 3.0833333333333335, 3.1666666666666665, 3.25, 3.333333333333333, 3.4166666666666665, 3.5, 3.5833333333333335, 3.6666666666666665, 3.75, 3.8333333333333335, 3.9166666666666665, 4.0]
    m6_middle = fconvert(Monthly, y6, method=:linear, values_base=:middle)
    @test rangeof(m6_middle) == 2022M1:2025M12
    @test values(m6_middle) == [0.541666666666667, 0.625, 0.7083333333333335, 0.791666666666667, 0.8750000000000002, 0.9583333333333335, 1.0416666666666667, 1.125, 1.2083333333333333, 1.2916666666666665, 1.375, 1.4583333333333335, 1.5416666666666665, 1.625, 1.7083333333333335, 1.7916666666666665, 1.875, 1.9583333333333335, 2.041666666666667, 2.125, 2.208333333333333, 2.2916666666666665, 2.375, 2.4583333333333335, 2.541666666666667, 2.625, 2.708333333333333, 2.791666666666667, 2.875, 2.958333333333333, 3.0416666666666665, 3.125, 3.2083333333333335, 3.291666666666667, 3.375, 3.4583333333333335, 3.5416666666666665, 3.625, 3.7083333333333335, 3.7916666666666665, 3.875, 3.9583333333333335, 4.041666666666667, 4.125, 4.208333333333334, 4.291666666666667, 4.375, 4.458333333333334]

    q7 = TSeries(2022Q1, collect(1:12))
    m7_begin = fconvert(Monthly, q7, method=:linear, values_base=:begin)
    @test rangeof(m7_begin) == 2022M1:2024M12
    @test values(m7_begin) == [1.0, 1.3333333333333335, 1.6666666666666665, 2.0, 2.3333333333333335, 2.666666666666667, 3.0, 3.333333333333333, 3.6666666666666665, 4.0, 4.333333333333334, 4.666666666666666, 5.0, 5.333333333333334, 5.666666666666667, 6.0, 6.333333333333333, 6.666666666666666, 7.0, 7.333333333333334, 7.666666666666666, 8.0, 8.333333333333334, 8.666666666666668, 9.0, 9.333333333333334, 9.666666666666666, 10.0, 10.333333333333334, 10.666666666666668, 11.0, 11.333333333333334, 11.666666666666668, 12.0, 12.333333333333332, 12.666666666666666]
    m7_end = fconvert(Monthly, q7, method=:linear, values_base=:end)
    @test rangeof(m7_end) == 2022M1:2024M12
    @test values(m7_end) == [0.3333333333333333, 0.6666666666666666, 1.0, 1.3333333333333335, 1.6666666666666665, 2.0, 2.3333333333333335, 2.666666666666667, 3.0, 3.333333333333333, 3.6666666666666665, 4.0, 4.333333333333334, 4.666666666666666, 5.0, 5.333333333333334, 5.666666666666667, 6.0, 6.333333333333333, 6.666666666666666, 7.0, 7.333333333333334, 7.666666666666666, 8.0, 8.333333333333334, 8.666666666666668, 9.0, 9.333333333333334, 9.666666666666666, 10.0, 10.333333333333334, 10.666666666666668, 11.0, 11.333333333333334, 11.666666666666668, 12.0]
    m7_middle = fconvert(Monthly, q7, method=:linear, values_base=:middle)
    @test rangeof(m7_middle) == 2022M1:2024M12
    @test values(m7_middle) == [0.6666666666666665, 1.0, 1.3333333333333335, 1.6666666666666665, 2.0, 2.3333333333333335, 2.666666666666667, 3.0, 3.333333333333333, 3.6666666666666665, 4.0, 4.333333333333334, 4.666666666666666, 5.0, 5.333333333333334, 5.666666666666667, 6.0, 6.333333333333333, 6.666666666666666, 7.0, 7.333333333333334, 7.666666666666666, 8.0, 8.333333333333334, 8.666666666666668, 9.0, 9.333333333333334, 9.666666666666666, 10.0, 10.333333333333334, 10.666666666666668, 11.0, 11.333333333333334, 11.666666666666668, 12.0, 12.333333333333332]

    h8 = TSeries(2022H1, collect(1:5))
    m8 = fconvert(Monthly, h8)
    @test rangeof(m8) == 2022M1:2024M6
    @test values(m8) == [1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5]
    m8_begin = fconvert(Monthly, h8, method=:linear, values_base=:begin)
    @test rangeof(m8_begin) == 2022M1:2024M6
    @test values(m8_begin)[1:13] ≈ [1,1+1/6,1+2/6,1+3/6,1+4/6,1+5/6,2,2+1/6,2+2/6,2+3/6,2+4/6,2+5/6,3]
    m8_end = fconvert(Monthly, h8, method=:linear, values_base=:end)
    @test rangeof(m8_end) == 2022M1:2024M6
    @test values(m8_end)[1:13] ≈ [0+1/6,0+2/6,0+3/6,0+4/6,0+5/6,1,1+1/6,1+2/6,1+3/6,1+4/6,1+5/6,2,2+1/6]
    m8_middle = fconvert(Monthly, h8, method=:linear, values_base=:middle)
    @test rangeof(m8_middle) == 2022M1:2024M6
    @test values(m8_middle)[1:13] ≈ [.75-1/6, .75, .75+1/6,1.25-1/6, 1.25, 1.25+1/6, 1.75-1/6, 1.75, 1.75+1/6, 2.25-1/6, 2.25,2.25+1/6,2.75-1/6]
    m8_even = fconvert(Monthly, h8, method=:even)
    @test rangeof(m8_even) == 2022M1:2024M6
    @test values(m8_even) == [1,1,1,1,1,1,2,2,2,2,2,2,3,3,3,3,3,3,4,4,4,4,4,4,5,5,5,5,5,5] ./ 6
    
end

@testset "fconvert, YPFrequencies, to lower" begin
    q1 = TSeries(1Q2, [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8])
    y1 = fconvert(Yearly, q1, method=:mean)
    @test rangeof(y1) == 2Y:4Y
    @test y1.values == [3, 5, 7]
    r1 = fconvert(Yearly, rangeof(q1))
    @test r1 == 2Y:4Y
    # mit1_start = fconvert(Yearly, q1.firstdate, values_base=:begin, round_to=:next)
    # @test mit1_start == 2Y
    # mit1_end = fconvert(Yearly, last(rangeof(q1)), values_base=:end, round_to=:previous)
    # @test mit1_end == 4Y


    q2 = TSeries(MIT{Quarterly{2}}(9), [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8])
    y2 = fconvert(Yearly, q2, method=:mean)
    @test rangeof(y2) == 3Y:5Y
    @test y2.values == [3, 5, 7]
    r2 = fconvert(Yearly, rangeof(q2))
    @test r2 == 3Y:5Y
    y2m = fconvert(Yearly, fconvert(Monthly, q2), method=:mean)
    @test y2m.values == [3 + 1 / 6, 5 + 1 / 6, 7 + 1 / 6]
    # mit2_start = fconvert(Yearly, q2.firstdate, values_base=:begin, round_to=:next)
    # @test mit2_start == 3Y
    # mit2_end = fconvert(Yearly, last(rangeof(q2)), values_base=:end, round_to=:previous)
    # @test mit2_end == 5Y

    q3 = TSeries(1Q2, [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8])
    y3 = fconvert(Yearly, q3, method=:mean)
    @test rangeof(y3) == 2Y:4Y
    @test y3.values == [3, 5, 7]
    r3 = fconvert(Yearly, rangeof(q3))
    @test r3 == 2Y:4Y
    # mit3_start = fconvert(Yearly, q3.firstdate, values_base=:begin, round_to=:next)
    # @test mit3_start == 2Y
    # mit3_end = fconvert(Yearly, last(rangeof(q3)), values_base=:end, round_to=:previous)
    # @test mit3_end == 4Y

    q4 = TSeries(MIT{Quarterly{2}}(9), [1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8])
    y4 = fconvert(Yearly, q4, method=:mean)
    @test rangeof(y4) == 3Y:4Y
    @test y4.values == [3, 5]
    r4 = fconvert(Yearly, rangeof(q4))
    @test r4 == 3Y:4Y
    y4m = fconvert(Yearly, fconvert(Monthly, q4), method=:mean)
    @test y4m.values == [3 + 1 / 6, 5 + 1 / 6]
    # mit4_start = fconvert(Yearly, q4.firstdate, values_base=:begin, round_to=:next)


    m5 = TSeries(20M1, collect(1:36))
    y5 = fconvert(Yearly, m5, method=:mean)
    @test rangeof(y5) == 20Y:22Y
    @test y5.values == [6.5, 18.5, 30.5]
    r5 = fconvert(Yearly, rangeof(m5))
    @test r5 == 20Y:22Y
    # mit5_start = fconvert(Yearly, m5.firstdate, values_base=:begin, round_to=:next)
    # @test mit5_start == 20Y
    # mit5_end = fconvert(Yearly, last(rangeof(m5)), values_base=:end, round_to=:previous)
    # @test mit5_end == 22Y

    m6 = TSeries(20M1, collect(1:36))
    y6 = fconvert(Yearly{9}, m6, method=:mean)
    @test rangeof(y6) == MIT{Yearly{9}}(21):MIT{Yearly{9}}(22) #20Y:21Y
    @test y6.values == [15.5, 27.5]
    r6 = fconvert(Yearly{9}, rangeof(m6))
    @test r6 == MIT{Yearly{9}}(21):MIT{Yearly{9}}(22) #20Y:21Y
    # mit6_start = fconvert(Yearly{9}, m6.firstdate, values_base=:begin, round_to=:next)
    # @test mit6_start == MIT{Yearly{9}}(21) #20Y:21Y
    # mit6_end = fconvert(Yearly{9}, last(rangeof(m6)), values_base=:end, round_to=:previous)
    # @test mit6_end == MIT{Yearly{9}}(22) #20Y:21Y

    m7 = TSeries(20M1, collect(1:36))
    q7 = fconvert(Quarterly, m7, method=:mean)
    @test rangeof(q7) == 20Q1:22Q4
    @test q7.values == collect(2:3:35)
    r7 = fconvert(Quarterly, rangeof(m7))
    @test r7 == 20Q1:22Q4
    # mit7_start = fconvert(Quarterly, m7.firstdate, values_base=:begin, round_to=:next)
    # @test mit7_start == 20Q1
    # mit7_end = fconvert(Quarterly, last(rangeof(m7)), values_base=:end, round_to=:previous)
    # @test mit7_end == 22Q4

    m8 = TSeries(20M1, collect(1:36))
    q8 = fconvert(Quarterly{2}, m8, method=:mean)
    @test rangeof(q8) == MIT{Quarterly{2}}(20 * 4 + 1):MIT{Quarterly{2}}(22 * 4 + 3) #20Q2:22Q4
    @test q8.values == collect(4:3:34)
    r8 = fconvert(Quarterly{2}, rangeof(m8))
    @test r8 == MIT{Quarterly{2}}(20 * 4 + 1):MIT{Quarterly{2}}(22 * 4 + 3) #20Q2:22Q4
    # mit8_start = fconvert(Quarterly{2}, m8.firstdate, values_base=:begin, round_to=:next)
    # @test mit8_start == MIT{Quarterly{2}}(20 * 4 + 1) # 20Q2
    # mit8_end = fconvert(Quarterly{2}, last(rangeof(m8)), values_base=:end, round_to=:previous)
    # @test mit8_end == MIT{Quarterly{2}}(22 * 4 + 3) #22Q4

    q9 = TSeries(2022Q1, collect(1:10))
    y9_begin = fconvert(Yearly, q9, method=:point, values_base=:begin)
    @test rangeof(y9_begin) == 2022Y:2024Y
    @test y9_begin.values == [1,5,9]
    y9_end = fconvert(Yearly, q9, method=:point, values_base=:end)
    @test rangeof(y9_end) == 2022Y:2023Y
    @test y9_end.values == [4,8]
    y9_begin_m8 = fconvert(Yearly{8}, q9, method=:point, values_base=:begin)
    @test rangeof(y9_begin_m8) == MIT{Yearly{8}}(2023):MIT{Yearly{8}}(2024)
    @test y9_begin_m8.values == [3,7]
    y9_end_m8 = fconvert(Yearly{8}, q9, method=:point, values_base=:end)
    @test rangeof(y9_end_m8) == MIT{Yearly{8}}(2022):MIT{Yearly{8}}(2024)
    @test y9_end_m8.values == [2,6, 10]

    # @test mit4_start == 3Y

    # bias in single period conversions
    # @test fconvert(Quarterly, 20M2, round_to=:current) == 20Q1
    # @test fconvert(Quarterly, 20M2, round_to=:next) == 20Q1
    # @test fconvert(Quarterly, 20M2, round_to=:previous) == 19Q4
    # @test fconvert(Quarterly, 20M3, round_to=:previous) == 20Q1
    # @test fconvert(Quarterly, 20M3, round_to=:next) == 20Q1
    # @test fconvert(Quarterly, 20M3, round_to=:current) == 20Q1
    # @test fconvert(Quarterly, 20M1, round_to=:next) == 20Q1

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

@testset "fconvert, YPFrequencies, to similar" begin
    qs1 = TSeries(2022Q2{2}, collect(2.0:4.0))
    qs2 = fconvert(Quarterly, qs1, method=:point, values_base=:end)
    @test rangeof(qs2) == 2022Q2:2022Q4
    @test values(qs2) == [2.0, 3.0, 4.0]
    qs3 = fconvert(Quarterly, qs1, method=:point, values_base=:begin)
    @test rangeof(qs3) == 2022Q2:2022Q4
    @test values(qs3) == [2.0, 3.0, 4.0]
end

@testset "fconvert, Weekly to lower" begin
    """
    frequency WEEKLY(SUNDAY)
    DATE 1
    Series !ws1 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
    """
    t1 = TSeries(MIT{Weekly}(1), Float64.(collect(1:20)))
    """
    Frequency WEEKLY(THURSDAY)
    Series !ws2 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
    """
    t2 = TSeries(MIT{Weekly{4}}(2), Float64.(collect(1:20)))

    """repo CONVERT(WS1, MONTHLY, LINEAR, AVERAGED)"""
    r1 = fconvert(Monthly, fconvert(Daily, t1, method=:linear), method=:mean)
    r1_mid = fconvert(Monthly, fconvert(Daily, t1, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r1.values, [2.286, 6.5, 10.714, 15.071], atol=1e-2)
    @test isapprox(r1_mid.values, [2.71, 6.93, 11.14, 15.50], atol=1e-2)
    @test rangeof(r1) == 1M1:1M4
    r1_range = fconvert(Monthly, rangeof(t1), trim=:both)
    @test r1_range == 1M1:1M4
    # r1_MIT_start = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Monthly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS1, MONTHLY, LINEAR, END)"""
    r2 = fconvert(Monthly, fconvert(Daily, t1, method=:linear), method=:point, values_base=:end)
    @test isapprox(r2.values, [4.43, 8.43, 12.86, 17.14], atol=1e-2)
    @test rangeof(r2) == 1M1:1M4
    r2_range = fconvert(Monthly, rangeof(t1), trim=:end)
    @test r2_range == 1M1:1M4
    # r2_MIT_start = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Monthly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    """repo CONVERT(WS1, MONTHLY, LINEAR, BEGIN)"""
    r3 = fconvert(Monthly, fconvert(Daily, t1, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r3.values, [1.00, 5.43, 9.43, 13.86, 18.14], atol=1e-2)
    @test rangeof(r3) == 1M1:1M5
    r3_range = fconvert(Monthly, rangeof(t1), trim=:begin)
    @test r3_range == 1M1:1M5
    # r3_MIT_start = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Monthly, last(rangeof(t1)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    """repo CONVERT(WS1, MONTHLY, LINEAR, SUMMED)"""
    #OBS!! Not getting exact results here, low tolerance!!
    # r4 = fconvert(Monthly, t1, method=:sum, interpolation=:linear)
    # @test isapprox(r4.values, [12.02, 27.71, 49.35, 66.43], atol=1e-0)
    # @test rangeof(r4) == 1M1:1M4
    # r4_range = fconvert(Monthly, rangeof(t1), trim=:both)
    # @test r4_range == 1M1:1M4

    """repo CONVERT(WS1, MONTHLY, DISCRETE, AVERAGED)"""
    r5 = fconvert(Monthly, t1, method=:mean)
    @test isapprox(r5.values, [2.50, 6.50, 10.50, 15.00], atol=1e-2)
    @test rangeof(r5) == 1M1:1M4

    """repo CONVERT(WS1, MONTHLY, DISCRETE, BEGIN)"""
    r6 = fconvert(Monthly, t1, method=:point, values_base=:begin)
    @test isapprox(r6.values, [1.00, 5.00, 9.00, 13.00, 18.00], atol=1e-2)
    @test rangeof(r6) == 1M1:1M5

    """repo CONVERT(WS1, MONTHLY, DISCRETE, END)"""
    r7 = fconvert(Monthly, t1, method=:point, values_base=:end)
    @test isapprox(r7.values, [4.00, 8.00, 12.00, 17.00], atol=1e-2)
    @test rangeof(r7) == 1M1:1M4

    """repo CONVERT(WS1, MONTHLY, DISCRETE, SUMMED)"""
    r8 = fconvert(Monthly, t1, method=:sum)
    @test isapprox(r8.values, [10.00, 26.00, 42.00, 75.00], atol=1e-2)
    @test rangeof(r8) == 1M1:1M4

    """repo CONVERT(WS2, MONTHLY, LINEAR, AVERAGED)"""
    r9 = fconvert(Monthly, fconvert(Daily, t2, method=:linear), method=:mean)
    r9_mid = fconvert(Monthly, fconvert(Daily, t2, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r9.values, [5.929, 10.143, 14.5], atol=1e-2)
    @test isapprox(r9_mid.values, [6.36, 10.57, 14.93], atol=1e-2)
    @test rangeof(r9) == 1M2:1M4
    r9_range = fconvert(Monthly, rangeof(t2), trim=:both)
    @test r9_range == 1M2:1M4
    # r9_MIT_start = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Monthly, last(rangeof(t2)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS2, MONTHLY, LINEAR, END)"""
    r10 = fconvert(Monthly, fconvert(Daily, t2, method=:linear), method=:point, values_base=:end)
    @test isapprox(r10.values, [3.86, 7.86, 12.29, 16.57], atol=1e-2)
    @test rangeof(r10) == 1M1:1M4
    r10_range = fconvert(Monthly, rangeof(t2), trim=:end)
    @test r10_range == 1M1:1M4
    # r10_MIT_start = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Monthly, last(rangeof(t2)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS2, MONTHLY, LINEAR, BEGIN)"""
    r11 = fconvert(Monthly, fconvert(Daily, t2, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r11.values, [4.86, 8.86, 13.29, 17.57], atol=1e-2)
    @test rangeof(r11) == 1M2:1M5
    r11_range = fconvert(Monthly, rangeof(t2), trim=:begin)
    @test r11_range == 1M2:1M5
    # r11_MIT_start = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Monthly, last(rangeof(t2)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS2, MONTHLY, LINEAR, SUMMED)"""
    ## OBS! reduced tolerance!
    # r12 = fconvert(Monthly, t2, method=:sum, interpolation=:linear)
    # @test isapprox(r12.values, [25.43, 46.82, 63.98], atol=1e-1)
    # @test rangeof(r12) == 1M2:1M4
    # r12_range = fconvert(Monthly, rangeof(t2), trim=:both)
    # @test r12_range == 1M2:1M4

    """repo CONVERT(WS2, MONTHLY, DISCRETE, AVERAGED)"""
    r13 = fconvert(Monthly, t2, method=:mean)
    @test isapprox(r13.values, [5.50, 10.00, 14.50], atol=1e-2)
    @test rangeof(r13) == 1M2:1M4

    """repo CONVERT(WS2, MONTHLY, DISCRETE, END)"""
    r14 = fconvert(Monthly, t2, method=:point, values_base=:end)
    @test isapprox(r14.values, [3.00, 7.00, 12.00, 16.00], atol=1e-2)
    @test rangeof(r14) == 1M1:1M4

    """repo CONVERT(WS2, MONTHLY, DISCRETE, BEGIN)"""
    r15 = fconvert(Monthly, t2, method=:point, values_base=:begin)
    @test isapprox(r15.values, [4.00, 8.00, 13.00, 17.00], atol=1e-2)
    @test rangeof(r15) == 1M2:1M5

    """repo CONVERT(WS2, MONTHLY, DISCRETE, SUMMED)"""
    r16 = fconvert(Monthly, t2, method=:sum)
    @test isapprox(r16.values, [22.00, 50.00, 58.00], atol=1e-2)
    @test rangeof(r16) == 1M2:1M4


    """
    date 1 to 2
    Frequency WEEKLY(SUNDAY)
    Series !ws3 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,36,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60
    Frequency WEEKLY(THURSDAY)
    Series !ws4 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,36,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60

    """
    t3 = TSeries(MIT{Weekly}(1), Float64.(collect(1:60)))
    t4 = TSeries(MIT{Weekly{4}}(2), Float64.(collect(1:60)))
    """repo CONVERT(WS3, QUARTERLY, DISCRETE, AVERAGED)"""
    r1 = fconvert(Quarterly, t3, method=:mean)
    @test isapprox(r1.values, [6.50, 19.00, 32.43, 46.00], atol=1e-1)
    @test rangeof(r1) == 1Q1:1Q4
    r1_range = fconvert(Quarterly, rangeof(t3), trim=:both)
    @test r1_range == 1Q1:1Q4
    # r1_MIT_start = fconvert(Quarterly, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Quarterly, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS3, QUARTERLY, DISCRETE, END)"""
    r2 = fconvert(Quarterly, t3, method=:point, values_base=:end)
    @test isapprox(r2.values, [12, 25, 39, 52], atol=1e-2)
    @test rangeof(r2) == 1Q1:1Q4
    r2_range = fconvert(Quarterly, rangeof(t3), trim=:end)
    @test r2_range == 1Q1:1Q4
    # r2_MIT_start = fconvert(Quarterly, first(rangeof(t3)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Quarterly, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range


    """repo CONVERT(WS3, QUARTERLY, DISCRETE, BEGIN)"""
    r3 = fconvert(Quarterly, t3, method=:point, values_base=:begin)
    @test isapprox(r3.values, [1, 13, 26, 40, 53], atol=1e-2)
    @test rangeof(r3) == 1Q1:2Q1
    r3_range = fconvert(Quarterly, rangeof(t3), trim=:begin)
    @test r3_range == 1Q1:2Q1
    # r3_MIT_start = fconvert(Quarterly, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Quarterly, last(rangeof(t3)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range


    """repo CONVERT(WS3, QUARTERLY, DISCRETE, SUMMED)"""
    r4 = fconvert(Quarterly, t3, method=:sum)
    @test isapprox(r4.values, [78, 247, 454, 598], atol=1e0)
    @test rangeof(r4) == 1Q1:1Q4
    r4_range = fconvert(Quarterly, rangeof(t3), trim=:both)
    @test r4_range == 1Q1:1Q4


    """repo CONVERT(WS3, QUARTERLY, LINEAR, AVERAGED)"""
    r5 = fconvert(Quarterly, fconvert(Daily, t3, method=:linear), method=:mean)
    r5_mid = fconvert(Quarterly, fconvert(Daily, t3, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r5.values, [6.5, 19.43, 32.5, 45.64], atol=1e-1)
    @test isapprox(r5_mid.values, [6.93, 19.86, 32.85, 46.07], atol=1e-1)
    @test rangeof(r5) == 1Q1:1Q4

    """repo CONVERT(WS3, QUARTERLY, LINEAR, END)"""
    r6 = fconvert(Quarterly, fconvert(Daily, t3, method=:linear), method=:point, values_base=:end)
    @test isapprox(r6.values, [12.86, 25.86, 39.00, 52.15], atol=1e-2)
    @test rangeof(r6) == 1Q1:1Q4

    """repo CONVERT(WS3, QUARTERLY, LINEAR, BEGIN)"""
    r7 = fconvert(Quarterly, fconvert(Daily, t3, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r7.values, [1.00, 13.86, 26.86, 40.00, 53.14], atol=1e-2)
    @test rangeof(r7) == 1Q1:2Q1

    """repo CONVERT(WS3, QUARTERLY, LINEAR, SUMMED)"""
    # r8 = fconvert(Quarterly, t3, method=:sum, interpolation=:linear)
    # @test isapprox(r8.values, [89.08, 258.14, 431.78, 605.51], atol=1e-0)
    # @test rangeof(r8) == 1Q1:1Q4

    """repo CONVERT(WS4, QUARTERLY, DISCRETE, AVERAGED)"""
    r9 = fconvert(Quarterly, t4, method=:mean)
    @test isapprox(r9.values, [19.00, 31.92, 45.00], atol=1e-1)
    @test rangeof(r9) == 1Q2:1Q4
    r9_range = fconvert(Quarterly, rangeof(t4), trim=:both)
    @test r9_range == 1Q2:1Q4
    # r9_MIT_start = fconvert(Quarterly, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Quarterly, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS4, QUARTERLY, DISCRETE, END)"""
    r10 = fconvert(Quarterly, t4, method=:point, values_base=:end)
    @test isapprox(r10.values, [12, 25, 38, 51], atol=1e-2)
    @test rangeof(r10) == 1Q1:1Q4
    r10_range = fconvert(Quarterly, rangeof(t4), trim=:end)
    @test r10_range == 1Q1:1Q4
    # r10_MIT_start = fconvert(Quarterly, first(rangeof(t4)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Quarterly, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS4, QUARTERLY, DISCRETE, BEGIN)"""
    r11 = fconvert(Quarterly, t4, method=:point, values_base=:begin)
    @test isapprox(r11.values, [13, 26, 39, 52], atol=1e-2)
    @test rangeof(r11) == 1Q2:2Q1
    r11_range = fconvert(Quarterly, rangeof(t4), trim=:begin)
    @test r11_range == 1Q2:2Q1
    # r11_MIT_start = fconvert(Quarterly, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Quarterly, last(rangeof(t4)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS4, QUARTERLY, DISCRETE, SUMMED)"""
    r12 = fconvert(Quarterly, t4, method=:sum)
    @test isapprox(r12.values, [247, 415, 585], atol=1e-0)
    @test rangeof(r12) == 1Q2:1Q4
    r12_range = fconvert(Quarterly, rangeof(t4), trim=:both)
    @test r12_range == 1Q2:1Q4

    """repo CONVERT(WS4, QUARTERLY, LINEAR, AVERAGED)"""
    r13 = fconvert(Quarterly, fconvert(Daily, t4, method=:linear), method=:mean)
    r13_mid = fconvert(Quarterly, fconvert(Daily, t4, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r13.values, [18.86, 31.93, 45.07], atol=1e-1)
    @test isapprox(r13_mid.values, [19.29, 32.28, 45.50], atol=1e-1)
    @test rangeof(r13) == 1Q2:1Q4

    """repo CONVERT(WS4, QUARTERLY, LINEAR, END)"""
    r14 = fconvert(Quarterly, fconvert(Daily, t4, method=:linear), method=:point, values_base=:end)
    @test isapprox(r14.values, [12.29, 25.29, 38.43, 51.57], atol=1e-2)
    @test rangeof(r14) == 1Q1:1Q4

    """repo CONVERT(WS4, QUARTERLY, LINEAR, BEGIN)"""
    r15 = fconvert(Quarterly, fconvert(Daily, t4, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r15.values, [13.29, 26.29, 39.43, 52.57], atol=1e-2)
    @test rangeof(r15) == 1Q2:2Q1

    """repo CONVERT(WS4, QUARTERLY, LINEAR, SUMMED)"""
    # r16 = fconvert(Quarterly, t4, method=:sum, interpolation=:linear)
    # @test isapprox(r16.values, [250.71, 424.28, 597.98], atol=2e0)
    # @test rangeof(r16) == 1Q2:1Q4



    """
    date 1 to 4
    Frequency WEEKLY(SUNDAY)
    Series !ws5 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200
    Frequency WEEKLY(THURSDAY)
    Series !ws6 = 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200

    """
    t5 = TSeries(MIT{Weekly}(1), Float64.(collect(1:200)))
    t6 = TSeries(MIT{Weekly{4}}(2), Float64.(collect(1:200)))

    """repo CONVERT(WS5, ANNUAL, DISCRETE, AVERAGED)"""
    r1 = fconvert(Yearly, t5, method=:mean)
    @test isapprox(r1.values, [26.50, 78.50, 130.50], atol=1e-2)
    @test rangeof(r1) == 1Y:3Y
    r1_range = fconvert(Yearly, rangeof(t5), trim=:both)
    @test r1_range == 1Y:3Y
    # r1_MIT_start = fconvert(Yearly, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Yearly, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS5, ANNUAL, DISCRETE, END)"""
    r2 = fconvert(Yearly, t5, method=:point, values_base=:end)
    @test isapprox(r2.values, [52, 104, 156], atol=1e-2)
    @test rangeof(r2) == 1Y:3Y
    r2_range = fconvert(Yearly, rangeof(t5), trim=:end)
    @test r2_range == 1Y:3Y
    # r2_MIT_start = fconvert(Yearly, first(rangeof(t5)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Yearly, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    """repo CONVERT(WS5, ANNUAL, DISCRETE, BEGIN)"""
    r3 = fconvert(Yearly, t5, method=:point, values_base=:begin)
    @test isapprox(r3.values, [1, 53, 105, 157], atol=1e-2)
    @test rangeof(r3) == 1Y:4Y
    r3_range = fconvert(Yearly, rangeof(t5), trim=:begin)
    @test r3_range == 1Y:4Y
    # r3_MIT_start = fconvert(Yearly, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Yearly, last(rangeof(t5)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    """repo CONVERT(WS5, ANNUAL, DISCRETE, SUMMED)"""
    r4 = fconvert(Yearly, t5, method=:sum)
    @test isapprox(r4.values, [1378, 4082, 6786], atol=1e-1)
    @test rangeof(r4) == 1Y:3Y
    r4_range = fconvert(Yearly, rangeof(t5), trim=:both)
    @test r4_range == 1Y:3Y

    """repo CONVERT(WS5, ANNUAL, LINEAR, AVERAGED)"""
    r5 = fconvert(Yearly, fconvert(Daily, t5, method=:linear), method=:mean)
    r5_mid = fconvert(Yearly, fconvert(Daily, t5, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r5.values, [26.14, 78.29, 130.43], atol=1e-2)
    @test isapprox(r5_mid.values, [26.57, 78.71, 130.86], atol=1e-2)
    @test rangeof(r5) == 1Y:3Y

    """repo CONVERT(WS5, ANNUAL, LINEAR, END)"""
    r6 = fconvert(Yearly, fconvert(Daily, t5, method=:linear), method=:point, values_base=:end)
    @test isapprox(r6.values, [52.14, 104.29, 156.43], atol=1e-2)
    @test rangeof(r6) == 1Y:3Y

    """repo CONVERT(WS5, ANNUAL, LINEAR, BEGIN)"""
    r7 = fconvert(Yearly, fconvert(Daily, t5, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r7.values, [1, 53.14, 105.29, 157.43], atol=1e-2)
    @test rangeof(r7) == 1Y:4Y

    """repo CONVERT(WS5, ANNUAL, LINEAR, SUMMED)"""
    # r8 = fconvert(Yearly, t5, method=:sum, interpolation=:linear)
    # @test isapprox(r8.values, [1385.51, 4104.39, 6823.27], atol=1e-1)
    # @test rangeof(r8) == 1Y:3Y

    """repo CONVERT(WS6, ANNUAL, DISCRETE, AVERAGED)"""
    r9 = fconvert(Yearly, t6, method=:mean)
    @test isapprox(r9.values, [77.50, 129.50], atol=1e-2)
    @test rangeof(r9) == 2Y:3Y
    r9_range = fconvert(Yearly, rangeof(t6), trim=:both)
    @test r9_range == 2Y:3Y
    # r9_MIT_start = fconvert(Yearly, first(rangeof(t6)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Yearly, last(rangeof(t6)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS6, ANNUAL, DISCRETE, END)"""
    r10 = fconvert(Yearly, t6, method=:point, values_base=:end)
    @test isapprox(r10.values, [51, 103, 155], atol=1e-2)
    @test rangeof(r10) == 1Y:3Y
    r10_range = fconvert(Yearly, rangeof(t6), trim=:end)
    @test r10_range == 1Y:3Y
    # r10_MIT_start = fconvert(Yearly, first(rangeof(t6)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Yearly, last(rangeof(t6)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS6, ANNUAL, DISCRETE, BEGIN)"""
    r11 = fconvert(Yearly, t6, method=:point, values_base=:begin)
    @test isapprox(r11.values, [52, 104, 156], atol=1e-2)
    @test rangeof(r11) == 2Y:4Y
    r11_range = fconvert(Yearly, rangeof(t6), trim=:begin)
    @test r11_range == 2Y:4Y
    # r11_MIT_start = fconvert(Yearly, first(rangeof(t6)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Yearly, last(rangeof(t6)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS6, ANNUAL, DISCRETE, SUMMED)"""
    r12 = fconvert(Yearly, t6, method=:sum)
    @test isapprox(r12.values, [4030, 6734], atol=1e-2)
    @test rangeof(r12) == 2Y:3Y
    r12_range = fconvert(Yearly, rangeof(t6), trim=:both)
    @test r12_range == 2Y:3Y

    """repo CONVERT(WS6, ANNUAL, LINEAR, AVERAGED)"""
    r13 = fconvert(Yearly, fconvert(Daily, t6, method=:linear), method=:mean)
    r13_mid = fconvert(Yearly, fconvert(Daily, t6, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r13.values, [77.71, 129.86], atol=1e-2)
    @test isapprox(r13_mid.values, [78.14, 130.29], atol=1e-2)
    @test rangeof(r13) == 2Y:3Y

    """repo CONVERT(WS6, ANNUAL, LINEAR, END)"""
    r14 = fconvert(Yearly, fconvert(Daily, t6, method=:linear), method=:point, values_base=:end)
    @test isapprox(r14.values, [51.57, 103.71, 155.86], atol=1e-2)
    @test rangeof(r14) == 1Y:3Y

    """repo CONVERT(WS6, ANNUAL, LINEAR, BEGIN)"""
    r15 = fconvert(Yearly, fconvert(Daily, t6, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r15.values, [52.57, 104.71, 156.86], atol=1e-2)
    @test rangeof(r15) == 2Y:4Y

    """repo CONVERT(WS6, ANNUAL, LINEAR, SUMMED)"""
    # r16 = fconvert(Yearly, t6, method=:sum, interpolation=:linear)
    # @test isapprox(r16.values, [4074.59, 6793.47], atol=1e-1)
    # @test rangeof(r16) == 2Y:3Y


    # ### Quarterly, odd months


    """repo CONVERT(WS3, QUARTERLY(JANUARY), DISCRETE, AVERAGED)"""
    r1 = fconvert(Quarterly{1}, t3, method=:mean)
    @test isapprox(r1.values, [11.00, 24.00, 36.92, 50.00], atol=1e-1)
    @test rangeof(r1) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    r1_range = fconvert(Quarterly{1}, rangeof(t3), trim=:both)
    @test r1_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    # r1_MIT_start = fconvert(Quarterly{1}, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Quarterly{1}, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS3, QUARTERLY(JANUARY), DISCRETE, END)"""
    r2 = fconvert(Quarterly{1}, t3, method=:point, values_base=:end)
    @test isapprox(r2.values, [4, 17, 30, 43, 56], atol=1e-2)
    @test rangeof(r2) == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)
    r2_range = fconvert(Quarterly{1}, rangeof(t3), trim=:end)
    @test r2_range == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)
    # r2_MIT_start = fconvert(Quarterly{1}, first(rangeof(t3)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Quarterly{1}, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    """repo CONVERT(WS3, QUARTERLY(JANUARY), DISCRETE, BEGIN)"""
    r3 = fconvert(Quarterly{1}, t3, method=:point, values_base=:begin)
    @test isapprox(r3.values, [5, 18, 31, 44, 57], atol=1e-2)
    @test rangeof(r3) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)
    r3_range = fconvert(Quarterly{1}, rangeof(t3), trim=:begin)
    @test r3_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)
    # r3_MIT_start = fconvert(Quarterly{1}, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Quarterly{1}, last(rangeof(t3)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    """repo CONVERT(WS3, QUARTERLY(JANUARY), DISCRETE, SUMMED)"""
    r4 = fconvert(Quarterly{1}, t3, method=:sum)
    @test isapprox(r4.values, [143, 312, 480, 650], atol=1e-0)
    @test rangeof(r4) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    r4_range = fconvert(Quarterly{1}, rangeof(t3), trim=:both)
    @test r4_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS3, QUARTERLY(JANUARY), LINEAR, AVERAGED)"""
    r5 = fconvert(Quarterly{1}, fconvert(Daily, t3, method=:linear), method=:mean)
    r5_mid = fconvert(Quarterly{1}, fconvert(Daily, t3, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r5.values, [10.86, 23.79, 36.93, 50.07], atol=1e-1)
    @test isapprox(r5_mid.values, [11.29, 24.21, 37.28, 50.50], atol=1e-1)
    @test rangeof(r5) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS3, QUARTERLY(JANUARY), LINEAR, END)"""
    r6 = fconvert(Quarterly{1}, fconvert(Daily, t3, method=:linear), method=:point, values_base=:end)
    @test isapprox(r6.values, [4.43, 17.14, 30.29, 43.43, 56.57], atol=1e-2)
    @test rangeof(r6) == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS3, QUARTERLY(JANUARY), LINEAR, BEGIN)"""
    r7 = fconvert(Quarterly{1}, fconvert(Daily, t3, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r7.values, [5.43, 18.14, 31.29, 44.43, 57.57], atol=1e-2)
    @test rangeof(r7) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)

    """repo CONVERT(WS3, QUARTERLY(JANUARY), LINEAR, SUMMED)"""
    # r8 = fconvert(Quarterly{1}, t3, method=:sum, interpolation=:linear)
    # @test isapprox(r8.values, [143.49, 318.24, 489.98, 663.71], atol=2e-0)
    # @test rangeof(r8) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS4, QUARTERLY(JANUARY), DISCRETE, AVERAGED)"""
    r9 = fconvert(Quarterly{1}, t4, method=:mean)
    @test isapprox(r9.values, [10.00, 23.00, 35.92, 49.50], atol=1e-1)
    @test rangeof(r9) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    r9_range = fconvert(Quarterly{1}, rangeof(t4), trim=:both)
    @test r9_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    # r9_MIT_start = fconvert(Quarterly{1}, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Quarterly{1}, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS4, QUARTERLY(JANUARY), DISCRETE, END)"""
    r10 = fconvert(Quarterly{1}, t4, method=:point, values_base=:end)
    @test isapprox(r10.values, [3, 16, 29, 42, 56], atol=1e-2)
    @test rangeof(r10) == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)
    r10_range = fconvert(Quarterly{1}, rangeof(t4), trim=:end)
    @test r10_range == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)
    # r10_MIT_start = fconvert(Quarterly{1}, first(rangeof(t4)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Quarterly{1}, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS4, QUARTERLY(JANUARY), DISCRETE, BEGIN)"""
    r11 = fconvert(Quarterly{1}, t4, method=:point, values_base=:begin)
    @test isapprox(r11.values, [4, 17, 30, 43, 57], atol=1e-2)
    @test rangeof(r11) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)
    r11_range = fconvert(Quarterly{1}, rangeof(t4), trim=:begin)
    @test r11_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)
    # r11_MIT_start = fconvert(Quarterly{1}, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Quarterly{1}, last(rangeof(t4)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS4, QUARTERLY(JANUARY), DISCRETE, SUMMED)"""
    r12 = fconvert(Quarterly{1}, t4, method=:sum)
    @test isapprox(r12.values, [130, 299, 467, 693], atol=1e-0)
    @test rangeof(r12) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    r12_range = fconvert(Quarterly{1}, rangeof(t4), trim=:both)
    @test r12_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS4, QUARTERLY(JANUARY), LINEAR, AVERAGED)"""
    r13 = fconvert(Quarterly{1}, fconvert(Daily, t4, method=:linear), method=:mean)
    r13_mid = fconvert(Quarterly{1}, fconvert(Daily, t4, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r13.values, [10.29, 23.21, 36.36, 49.5], atol=1e-1)
    @test isapprox(r13_mid.values, [10.71, 23.64, 36.71, 49.93], atol=1e-1)
    @test rangeof(r13) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS4, QUARTERLY(JANUARY), LINEAR, END)"""
    r14 = fconvert(Quarterly{1}, fconvert(Daily, t4, method=:linear), method=:point, values_base=:end)
    @test isapprox(r14.values, [3.86, 16.57, 29.71, 42.86, 56.00], atol=1e-2)
    @test rangeof(r14) == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)

    """repo CONVERT(WS4, QUARTERLY(JANUARY), LINEAR, BEGIN)"""
    r15 = fconvert(Quarterly{1}, fconvert(Daily, t4, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r15.values, [4.86, 17.57, 30.71, 43.86, 57.00], atol=1e-2)
    @test rangeof(r15) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)

    """repo CONVERT(WS4, QUARTERLY(JANUARY), LINEAR, SUMMED)"""
    # r16 = fconvert(Quarterly{1}, t4, method=:sum, interpolation=:linear)
    # @test isapprox(r16.values, [136.22, 310.73, 482.47, 656.20], atol=1e-0)
    # @test rangeof(r16) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

    #######################################

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), DISCRETE, AVERAGED)"""
    r1 = fconvert(Quarterly{2}, t3, method=:mean)
    @test isapprox(r1.values, [15, 28, 41, 54], atol=1e-1) 
    @test rangeof(r1) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    r1_range = fconvert(Quarterly{2}, rangeof(t3), trim=:both)
    @test r1_range == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    # r1_MIT_start = fconvert(Quarterly{2}, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Quarterly{2}, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), DISCRETE, END)"""
    r2 = fconvert(Quarterly{2}, t3, method=:point, values_base=:end)
    @test isapprox(r2.values, [8, 21, 34, 47, 60], atol=1e-2) 
    @test rangeof(r2) == MIT{Quarterly{2}}(4):MIT{Quarterly{2}}(8)
    r2_range = fconvert(Quarterly{2}, rangeof(t3), trim=:end)
    @test r2_range == MIT{Quarterly{2}}(4):MIT{Quarterly{2}}(8)
    # r2_MIT_start = fconvert(Quarterly{2}, first(rangeof(t3)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Quarterly{2}, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), DISCRETE, BEGIN)"""
    r3 = fconvert(Quarterly{2}, t3, method=:point, values_base=:begin)
    @test isapprox(r3.values, [9, 22, 35, 48], atol=1e-2)
    @test rangeof(r3) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    r3_range = fconvert(Quarterly{2}, rangeof(t3), trim=:begin)
    @test r3_range == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    # r3_MIT_start = fconvert(Quarterly{2}, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Quarterly{2}, last(rangeof(t3)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), DISCRETE, SUMMED)"""
    r4 = fconvert(Quarterly{2}, t3, method=:sum) 
    @test isapprox(r4.values, [195, 364, 532, 702], atol=1e-0)
    @test rangeof(r4) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    r4_range = fconvert(Quarterly{2}, rangeof(t3), trim=:both)
    @test r4_range == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), LINEAR, AVERAGED)"""
    r5 = fconvert(Quarterly{2}, fconvert(Daily, t3, method=:linear), method=:mean)
    r5_mid = fconvert(Quarterly{2}, fconvert(Daily, t3, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r5.values, [15.07, 28.21, 41.29], atol=1e-1)
    @test isapprox(r5_mid.values, [15.50, 28.64, 41.64], atol=1e-1)
    @test rangeof(r5) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(7)

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), LINEAR, END)"""
    r6 = fconvert(Quarterly{2}, fconvert(Daily, t3, method=:linear), method=:point, values_base=:end)
    @test isapprox(r6.values, [8.43, 21.57, 34.71, 47.71], atol=1e-2)
    @test rangeof(r6) == MIT{Quarterly{2}}(4):MIT{Quarterly{2}}(7)

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), LINEAR, BEGIN)"""
    r7 = fconvert(Quarterly{2}, fconvert(Daily, t3, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r7.values, [9.43, 22.57, 35.71, 48.71], atol=1e-2)
    @test rangeof(r7) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)

    """repo CONVERT(WS3, QUARTERLY(FEBRUARY), LINEAR, SUMMED)"""
    # r8 = fconvert(Quarterly{2}, t3, method=:sum, interpolation=:linear)
    # @test isapprox(r8.values, [203.71, 376.43, 542.30], atol=1e-1)
    # @test rangeof(r8) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(7)

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), DISCRETE, AVERAGED)"""
    r9 = fconvert(Quarterly{2}, t4, method=:mean)
    @test isapprox(r9.values, [14.50, 28.00, 41, 54], atol=1e-1) 
    @test rangeof(r1) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    r9_range = fconvert(Quarterly{2}, rangeof(t4), trim=:both)
    @test r9_range == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    # r9_MIT_start = fconvert(Quarterly{2}, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Quarterly{2}, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), DISCRETE, END)"""
    r10 = fconvert(Quarterly{2}, t4, method=:point, values_base=:end)
    @test isapprox(r10.values, [7, 21, 34, 47, 60], atol=1e-2) 
    @test rangeof(r10) == MIT{Quarterly{2}}(4):MIT{Quarterly{2}}(8)
    r10_range = fconvert(Quarterly{2}, rangeof(t4), trim=:end)
    @test r10_range == MIT{Quarterly{2}}(4):MIT{Quarterly{2}}(8)
    # r10_MIT_start = fconvert(Quarterly{2}, first(rangeof(t4)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Quarterly{2}, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), DISCRETE, BEGIN)"""
    r11 = fconvert(Quarterly{2}, t4, method=:point, values_base=:begin)
    @test isapprox(r11.values, [8, 22, 35, 48], atol=1e-2)
    @test rangeof(r11) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    r11_range = fconvert(Quarterly{2}, rangeof(t4), trim=:begin)
    @test r11_range == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    # r11_MIT_start = fconvert(Quarterly{2}, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Quarterly{2}, last(rangeof(t4)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), DISCRETE, SUMMED)"""
    r12 = fconvert(Quarterly{2}, t4, method=:sum)
    @test isapprox(r12.values, [203, 364, 532, 702], atol=1e-0) 
    @test rangeof(r12) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)
    r12_range = fconvert(Quarterly{2}, rangeof(t4), trim=:both)
    @test r12_range == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), LINEAR, AVERAGED)"""
    r13 = fconvert(Quarterly{2}, fconvert(Daily, t4, method=:linear), method=:mean)
    r13_mid = fconvert(Quarterly{2}, fconvert(Daily, t4, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r13.values, [14.5, 27.64, 40.71, 53.64], atol=1e-1)
    @test isapprox(r13_mid.values, [14.93, 28.07, 41.14, 54.07], atol=1e-1) # NOTE: FAME output a value for 2Q1 even though the last observation is Feb 24
    @test rangeof(r13) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), LINEAR, END)"""
    r14 = fconvert(Quarterly{2}, fconvert(Daily, t4, method=:linear), method=:point, values_base=:end)
    @test isapprox(r14.values, [7.86, 21.00, 34.14, 47.14, 60], atol=1e-2) # NOTE: FAME output a value for 2Q1 even though the last observation is Feb 24
    @test rangeof(r14) == MIT{Quarterly{2}}(4):MIT{Quarterly{2}}(8)

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), LINEAR, BEGIN)"""
    r15 = fconvert(Quarterly{2}, fconvert(Daily, t4, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r15.values, [8.86, 22.00, 35.14, 48.14], atol=1e-2)
    @test rangeof(r15) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(8)

    """repo CONVERT(WS4, QUARTERLY(FEBRUARY), LINEAR, SUMMED)"""
    # r16 = fconvert(Quarterly{2}, t4, method=:sum, interpolation=:linear)
    # @test isapprox(r16.values, [196.2, 368.94, 533.86], atol=2e-0) # NOTE: FAME output a value for 2Q1 even though the last observation is Feb 24
    # @test rangeof(r1) == MIT{Quarterly{2}}(5):MIT{Quarterly{2}}(7)

    ### Annual, odd months

    """repo CONVERT(WS5, ANNUAL(AUGUST), DISCRETE, AVERAGED)"""
    r1 = fconvert(Yearly{8}, t5, method=:mean)
    @test isapprox(r1.values, [60.5, 113, 165.5], atol=1e-2)
    @test rangeof(r1) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)
    r1_range = fconvert(Yearly{8}, rangeof(t5), trim=:both)
    @test r1_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)
    # r1_MIT_start = fconvert(Yearly{8}, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Yearly{8}, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS5, ANNUAL(AUGUST), DISCRETE, END)"""
    r2 = fconvert(Yearly{8}, t5, method=:point, values_base=:end)
    @test isapprox(r2.values, [34, 86, 139, 191], atol=1e-2)
    @test rangeof(r2) == MIT{Yearly{8}}(1):MIT{Yearly{8}}(4)
    r2_range = fconvert(Yearly{8}, rangeof(t5), trim=:end)
    @test r2_range == MIT{Yearly{8}}(1):MIT{Yearly{8}}(4)
    # r2_MIT_start = fconvert(Yearly{8}, first(rangeof(t5)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Yearly{8}, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    """repo CONVERT(WS5, ANNUAL(AUGUST), DISCRETE, BEGIN)"""
    r3 = fconvert(Yearly{8}, t5, method=:point, values_base=:begin)
    @test isapprox(r3.values, [35, 87, 140, 192], atol=1e-2)
    @test rangeof(r3) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)
    r3_range = fconvert(Yearly{8}, rangeof(t5), trim=:begin)
    @test r3_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)
    # r3_MIT_start = fconvert(Yearly{8}, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Yearly{8}, last(rangeof(t5)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    """repo CONVERT(WS5, ANNUAL(AUGUST), DISCRETE, SUMMED)"""
    r4 = fconvert(Yearly{8}, t5, method=:sum)
    @test isapprox(r4.values, [3146, 5989, 8606], atol=1e-1)
    @test rangeof(r4) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)
    r4_range = fconvert(Yearly{8}, rangeof(t5), trim=:both)
    @test r4_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)

    """repo CONVERT(WS5, ANNUAL(AUGUST), LINEAR, AVERAGED)"""
    r5 = fconvert(Yearly{8}, fconvert(Daily, t5, method=:linear), method=:mean)
    r5_mid = fconvert(Yearly{8}, fconvert(Daily, t5, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r5.values, [60.86, 113, 165.21], atol=1e-2)
    @test isapprox(r5_mid.values, [61.29, 113.43, 165.64], atol=1e-2)
    @test rangeof(r5) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)

    """repo CONVERT(WS5, ANNUAL(AUGUST), LINEAR, END)"""
    r6 = fconvert(Yearly{8}, fconvert(Daily, t5, method=:linear), method=:point, values_base=:end)
    @test isapprox(r6.values, [34.71, 86.86, 139.00, 191.29], atol=1e-2)
    @test rangeof(r6) == MIT{Yearly{8}}(1):MIT{Yearly{8}}(4)

    """repo CONVERT(WS5, ANNUAL(AUGUST), LINEAR, BEGIN)"""
    r7 = fconvert(Yearly{8}, fconvert(Daily, t5, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r7.values, [35.71, 87.86, 140.00, 192.29], atol=1e-2)
    @test rangeof(r7) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)

    """repo CONVERT(WS5, ANNUAL(AUGUST), LINEAR, SUMMED)"""
    # r8 = fconvert(Yearly{8}, t5, method=:sum, interpolation=:linear)
    # @test isapprox(r8.values, [3195.61, 5914.49, 8660.76], atol=1e-0)
    # @test rangeof(r8) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)

    """repo CONVERT(WS6, ANNUAL(AUGUST), DISCRETE, AVERAGED)"""
    r9 = fconvert(Yearly{8}, t6, method=:mean)
    @test isapprox(r9.values, [60.5, 112.5, 164.5], atol=1e-2)
    @test rangeof(r9) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)
    r9_range = fconvert(Yearly{8}, rangeof(t6), trim=:both)
    @test r9_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)
    # r9_MIT_start = fconvert(Yearly{8}, first(rangeof(t6)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Yearly{8}, last(rangeof(t6)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS6, ANNUAL(AUGUST), DISCRETE, END)"""
    r10 = fconvert(Yearly{8}, t6, method=:point, values_base=:end)
    @test isapprox(r10.values, [34, 86, 138, 190], atol=1e-2)
    @test rangeof(r10) == MIT{Yearly{8}}(1):MIT{Yearly{8}}(4)
    r10_range = fconvert(Yearly{8}, rangeof(t6), trim=:end)
    @test r10_range == MIT{Yearly{8}}(1):MIT{Yearly{8}}(4)
    # r10_MIT_start = fconvert(Yearly{8}, first(rangeof(t6)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Yearly{8}, last(rangeof(t6)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS6, ANNUAL(AUGUST), DISCRETE, BEGIN)"""
    r11 = fconvert(Yearly{8}, t6, method=:point, values_base=:begin)
    @test isapprox(r11.values, [35, 87, 139, 191], atol=1e-2)
    @test rangeof(r11) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)
    r11_range = fconvert(Yearly{8}, rangeof(t6), trim=:begin)
    @test r11_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)
    # r11_MIT_start = fconvert(Yearly{8}, first(rangeof(t6)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Yearly{8}, last(rangeof(t6)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS6, ANNUAL(AUGUST), DISCRETE, SUMMED)"""
    r12 = fconvert(Yearly{8}, t6, method=:sum)
    @test isapprox(r12.values, [3146, 5850, 8554], atol=1e-2)
    @test rangeof(r12) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)
    r12_range = fconvert(Yearly{8}, rangeof(t6), trim=:both)
    @test r12_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)

    """repo CONVERT(WS6, ANNUAL(AUGUST), LINEAR, AVERAGED)"""
    r13 = fconvert(Yearly{8}, fconvert(Daily, t6, method=:linear), method=:mean)
    r13_mid = fconvert(Yearly{8}, fconvert(Daily, t6, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r13.values, [60.29, 112.43, 164.64], atol=1e-2)
    @test isapprox(r13_mid.values, [60.71, 112.86, 165.07], atol=1e-2)
    @test rangeof(r13) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)

    """repo CONVERT(WS6, ANNUAL(AUGUST), LINEAR, END)"""
    r14 = fconvert(Yearly{8}, fconvert(Daily, t6, method=:linear), method=:point, values_base=:end)
    @test isapprox(r14.values, [34.14, 86.29, 138.43, 190.71], atol=1e-2)
    @test rangeof(r14) == MIT{Yearly{8}}(1):MIT{Yearly{8}}(4)

    """repo CONVERT(WS6, ANNUAL(AUGUST), LINEAR, BEGIN)"""
    r15 = fconvert(Yearly{8}, fconvert(Daily, t6, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r15.values, [35.14, 87.29, 139.43, 191.71], atol=1e-2)
    @test rangeof(r15) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)

    """repo CONVERT(WS6, ANNUAL(AUGUST), LINEAR, SUMMED)"""
    # r16 = fconvert(Yearly{8}, t6, method=:sum, interpolation=:linear)
    # @test isapprox(r16.values, [3165.82, 5884.69, 8630.88], atol=1e-1)
    # @test rangeof(r16) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(4)


    ########################################

    """repo CONVERT(WS5, ANNUAL(MARCH), DISCRETE, AVERAGED)"""
    r1 = fconvert(Yearly{3}, t5, method=:mean)
    @test isapprox(r1.values, [39, 91.5, 143.5], atol=1e-2)
    @test rangeof(r1) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)
    r1_range = fconvert(Yearly{3}, rangeof(t5), trim=:both)
    @test r1_range == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)
    # r1_MIT_start = fconvert(Yearly{3}, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Yearly{3}, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    """repo CONVERT(WS5, ANNUAL(MARCH), DISCRETE, END)"""
    r2 = fconvert(Yearly{3}, t5, method=:point, values_base=:end)
    @test isapprox(r2.values, [12, 65, 117, 169], atol=1e-2)
    @test rangeof(r2) == MIT{Yearly{3}}(1):MIT{Yearly{3}}(4)
    r2_range = fconvert(Yearly{3}, rangeof(t5), trim=:end)
    @test r2_range == MIT{Yearly{3}}(1):MIT{Yearly{3}}(4)
    # r2_MIT_start = fconvert(Yearly{3}, first(rangeof(t5)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Yearly{3}, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    """repo CONVERT(WS5, ANNUAL(MARCH), DISCRETE, BEGIN)"""
    r3 = fconvert(Yearly{3}, t5, method=:point, values_base=:begin)
    @test isapprox(r3.values, [13, 66, 118, 170], atol=1e-2)
    @test rangeof(r3) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(5)
    r3_range = fconvert(Yearly{3}, rangeof(t5), trim=:begin)
    @test r3_range == MIT{Yearly{3}}(2):MIT{Yearly{3}}(5)
    # r3_MIT_start = fconvert(Yearly{3}, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Yearly{3}, last(rangeof(t5)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    """repo CONVERT(WS5, ANNUAL(MARCH), DISCRETE, SUMMED)"""
    r4 = fconvert(Yearly{3}, t5, method=:sum)
    @test isapprox(r4.values, [2067, 4758, 7462], atol=1e-1)
    @test rangeof(r4) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)
    r4_range = fconvert(Yearly{3}, rangeof(t5), trim=:both)
    @test r4_range == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)

    """repo CONVERT(WS5, ANNUAL(MARCH), LINEAR, AVERAGED)"""
    r5 = fconvert(Yearly{3}, fconvert(Daily, t5, method=:linear), method=:mean)
    r5_mid = fconvert(Yearly{3}, fconvert(Daily, t5, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r5.values, [39.0, 91.14, 143.36], atol=1e-2)
    @test isapprox(r5_mid.values, [39.43, 91.57, 143.79], atol=1e-2)
    @test rangeof(r5) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)

    """repo CONVERT(WS5, ANNUAL(MARCH), LINEAR, END)"""
    r6 = fconvert(Yearly{3}, fconvert(Daily, t5, method=:linear), method=:point, values_base=:end)
    @test isapprox(r6.values, [12.86, 65.00, 117.14, 169.43], atol=1e-2)
    @test rangeof(r6) == MIT{Yearly{3}}(1):MIT{Yearly{3}}(4)

    """repo CONVERT(WS5, ANNUAL(MARCH), LINEAR, BEGIN)"""
    r7 = fconvert(Yearly{3}, fconvert(Daily, t5, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r7.values, [13.86, 66.00, 118.14, 170.43], atol=1e-2)
    @test rangeof(r7) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(5)

    """repo CONVERT(WS5, ANNUAL(MARCH), LINEAR, SUMMED)"""
    # r8 = fconvert(Yearly{3}, t5, method=:sum, interpolation=:linear)
    # @test isapprox(r8.values, [2055.92, 4774.80, 7517.04], atol=1e-0)
    # @test rangeof(r8) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)

    """repo CONVERT(WS6, ANNUAL(MARCH), DISCRETE, AVERAGED)"""
    r9 = fconvert(Yearly{3}, t6, method=:mean)
    @test isapprox(r9.values, [38.5, 90.5, 142.5], atol=1e-2)
    @test rangeof(r9) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)
    r9_range = fconvert(Yearly{3}, rangeof(t6), trim=:both)
    @test r9_range == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)
    # r9_MIT_start = fconvert(Yearly{3}, first(rangeof(t6)), values_base=:begin, round_to=:next)
    # r9_MIT_end = fconvert(Yearly{3}, last(rangeof(t6)), values_base=:end, round_to=:previous)
    # @test r9_MIT_start:r9_MIT_end == r9_range

    """repo CONVERT(WS6, ANNUAL(MARCH), DISCRETE, END)"""
    r10 = fconvert(Yearly{3}, t6, method=:point, values_base=:end)
    @test isapprox(r10.values, [12, 64, 116, 168], atol=1e-2)
    @test rangeof(r10) == MIT{Yearly{3}}(1):MIT{Yearly{3}}(4)
    r10_range = fconvert(Yearly{3}, rangeof(t6), trim=:end)
    @test r10_range == MIT{Yearly{3}}(1):MIT{Yearly{3}}(4)
    # r10_MIT_start = fconvert(Yearly{3}, first(rangeof(t6)), values_base=:begin, round_to=:current)
    # r10_MIT_end = fconvert(Yearly{3}, last(rangeof(t6)), values_base=:end, round_to=:previous)
    # @test r10_MIT_start:r10_MIT_end == r10_range

    """repo CONVERT(WS6, ANNUAL(MARCH), DISCRETE, BEGIN)"""
    r11 = fconvert(Yearly{3}, t6, method=:point, values_base=:begin)
    @test isapprox(r11.values, [13, 65, 117, 169], atol=1e-2)
    @test rangeof(r11) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(5)
    r11_range = fconvert(Yearly{3}, rangeof(t6), trim=:begin)
    @test r11_range == MIT{Yearly{3}}(2):MIT{Yearly{3}}(5)
    # r11_MIT_start = fconvert(Yearly{3}, first(rangeof(t6)), values_base=:begin, round_to=:next)
    # r11_MIT_end = fconvert(Yearly{3}, last(rangeof(t6)), round_to=:current)
    # @test r11_MIT_start:r11_MIT_end == r11_range

    """repo CONVERT(WS6, ANNUAL(MARCH), DISCRETE, SUMMED)"""
    r12 = fconvert(Yearly{3}, t6, method=:sum)
    @test isapprox(r12.values, [2002, 4706, 7410], atol=1e-2)
    @test rangeof(r12) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)
    r12_range = fconvert(Yearly{3}, rangeof(t6), trim=:both)
    @test r12_range == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)

    """repo CONVERT(WS6, ANNUAL(MARCH), LINEAR, AVERAGED)"""
    r13 = fconvert(Yearly{3}, fconvert(Daily, t6, method=:linear), method=:mean)
    r13_mid = fconvert(Yearly{3}, fconvert(Daily, t6, method=:linear, values_base=:middle), method=:mean)
    @test isapprox(r13.values, [38.43, 90.57, 142.79], atol=1e-2)
    @test isapprox(r13_mid.values, [38.86, 91.00, 143.21], atol=1e-2)
    @test rangeof(r13) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)

    """repo CONVERT(WS6, ANNUAL(MARCH), LINEAR, END)"""
    r14 = fconvert(Yearly{3}, fconvert(Daily, t6, method=:linear), method=:point, values_base=:end)
    @test isapprox(r14.values, [12.29, 64.43, 116.57, 168.86], atol=1e-2)
    @test rangeof(r14) == MIT{Yearly{3}}(1):MIT{Yearly{3}}(4)

    """repo CONVERT(WS6, ANNUAL(MARCH), LINEAR, BEGIN)"""
    r15 = fconvert(Yearly{3}, fconvert(Daily, t6, method=:linear, values_base=:begin), method=:point, values_base=:begin)
    @test isapprox(r15.values, [13.29, 65.43, 117.57, 169.86], atol=1e-2)
    @test rangeof(r15) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(5)

    """repo CONVERT(WS6, ANNUAL(MARCH), LINEAR, SUMMED)"""
    # r16 = fconvert(Yearly{3}, t6, method=:sum, interpolation=:linear)
    # @test isapprox(r16.values, [2026.12, 4745.00, 7488.06], atol=1e-1)
    # @test rangeof(r16) == MIT{Yearly{3}}(2):MIT{Yearly{3}}(4)

    """Unitrange trims"""
    mit_w1 = MIT{Weekly}(4)
    mit_w2 = MIT{Weekly}(10)
    rm1 = fconvert(Monthly, mit_w1:mit_w2, trim=:both)
    @test rm1 == 1M2:1M2
    rm2 = fconvert(Monthly, mit_w1:mit_w2, trim=:begin)
    @test rm2 == 1M2:1M3
    rm3 = fconvert(Monthly, mit_w1:mit_w2, trim=:end)
    @test rm3 == 1M1:1M2

end


@testset "fconvert, Weekly to daily" begin
    t1 = TSeries(MIT{Weekly}(1), Float64.(collect(1:20)))
    t2 = TSeries(MIT{Weekly{4}}(2), Float64.(collect(1:20)))

    r1 = fconvert(Daily, t1, method=:const)
    @test r1.values == reduce(vcat, collect([repeat([x], 7) for x in 1:20]))
    @test rangeof(r1) == 1:140

    r2 = fconvert(Daily, t1, method=:linear, values_base=:middle)
    @test r2.values ≈ collect(LinRange(0.5714285714285716, 20.428571428571427, 140))
    @test rangeof(r2) == 1:140

    r3 = fconvert(Daily, t2, method=:const)
    @test r3.values == reduce(vcat, collect([repeat([x], 7) for x in 1:20]))
    @test rangeof(r3) == 5:144

    r4 = fconvert(Daily, t2, method=:linear, values_base=:middle)
    @test r4.values ≈ collect(LinRange(0.5714285714285716, 20.428571428571427, 140))
    @test rangeof(r4) == 5:144

end

@testset "fconvert, Weekly to BDaily" begin

    t1 = TSeries(MIT{Weekly}(1), Float64.(collect(1:20)))
    t2 = TSeries(MIT{Weekly{4}}(2), Float64.(collect(1:20)))
    t3 = TSeries(MIT{Weekly{6}}(2), Float64.(collect(1:20)))

    """repo CONVERT(WS1, BUSINESS, DISCRETE, AVERAGED)"""
    r1 = fconvert(BDaily, t1)
    @test r1.values == reduce(vcat, collect([repeat([x], 5) for x in 1:20]))
    @test rangeof(r1) == 1:100

    r2 = fconvert(BDaily, t1, method=:linear, values_base=:middle)
    @test r2.values ≈ collect(LinRange(0.4, 20.2, 100))
    @test rangeof(r2) == 1:100

    r2_alt = fconvert(BDaily, fconvert(Daily, t1, method=:linear, values_base=:middle))
    linears_r2 = collect(LinRange(0.5714285714285716, 20.428571428571427, 140))
    mask_r2 = repeat([true, true, true, true, true, false, false], 20)
    @test r2_alt.values ≈ linears_r2[mask_r2]
    @test rangeof(r2_alt) == 1:100

    r3 = fconvert(BDaily, t2)
    @test r3.values == reduce(vcat, collect([repeat([x], 5) for x in 1:20]))
    @test rangeof(r3) == 5:104

    r4 = fconvert(BDaily, t2, method=:linear, values_base=:middle)
    @test r4.values ≈ collect(LinRange(0.8, 20.6, 100))
    @test rangeof(r4) == 5:104

    r4_alt = fconvert(BDaily, fconvert(Daily, t2, method=:linear, values_base=:middle))
    linears_r4 = collect(LinRange(0.5714285714285716, 20.428571428571427, 140))
    mask_r4 = repeat([true, false, false, true, true, true, true], 20)
    @test r4_alt.values ≈ linears_r4[mask_r4]
    @test rangeof(r4_alt) == 5:104

    r5_alt = fconvert(BDaily, fconvert(Daily, t3, method=:linear, values_base=:middle))
    linears_r5 = collect(LinRange(0.5714285714285716, 20.428571428571427, 140))
    mask_r5 = repeat([false, true, true, true, true, true, false], 20)
    @test r5_alt.values ≈ linears_r5[mask_r5]
    @test rangeof(r5_alt) == 5:104
end

@testset "fconvert, Daily to Weekly" begin
    t1 = TSeries(MIT{Daily}(1), collect(1:100))

    r1 = fconvert(Weekly, t1, method=:mean)
    @test r1.values == collect(4:7:95)
    @test rangeof(r1) == 1:14
    r1_range = fconvert(Weekly, rangeof(t1), trim=:both)
    @test r1_range == 1:14
    # r1_MIT_start = fconvert(Weekly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Weekly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range


    r2 = fconvert(Weekly, t1, method=:point, values_base=:end)
    @test r2.values == collect(7:7:98)
    @test rangeof(r2) == 1:14
    r2_range = fconvert(Weekly, rangeof(t1), trim=:end)
    @test r2_range == 1:14
    # r2_MIT_start = fconvert(Weekly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r2_MIT_end = fconvert(Weekly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    r3 = fconvert(Weekly, t1, method=:point, values_base=:begin)
    @test r3.values == collect(1:7:100)
    @test rangeof(r3) == 1:15
    r3_range = fconvert(Weekly, rangeof(t1), trim=:begin)
    @test r3_range == 1:15
    # r3_MIT_start = fconvert(Weekly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Weekly, last(rangeof(t1)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    r4 = fconvert(Weekly, t1, method=:sum)
    @test r4.values == collect(28:49:665)
    @test rangeof(r4) == 1:14

    r5 = fconvert(Weekly{4}, t1, method=:mean)
    @test r5.values == collect(8:7:92)
    @test rangeof(r5) == 2:14
    r5_range = fconvert(Weekly{4}, rangeof(t1), trim=:both)
    @test r5_range == 2:14
    # r5_MIT_start = fconvert(Weekly{4}, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r5_MIT_end = fconvert(Weekly{4}, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r5_MIT_start:r5_MIT_end == r5_range

    r6 = fconvert(Weekly{4}, t1, method=:point, values_base=:end)
    @test r6.values == collect(4:7:95)
    @test rangeof(r6) == 1:14
    r6_range = fconvert(Weekly{4}, rangeof(t1), trim=:end)
    @test r6_range == 1:14
    # r6_MIT_start = fconvert(Weekly{4}, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r6_MIT_end = fconvert(Weekly{4}, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r6_MIT_start:r6_MIT_end == r6_range

    r7 = fconvert(Weekly{4}, t1, method=:point, values_base=:begin)
    @test r7.values == collect(5:7:96)
    @test rangeof(r7) == 2:15
    r7_range = fconvert(Weekly{4}, rangeof(t1), trim=:begin)
    @test r7_range == 2:15
    # r7_MIT_start = fconvert(Weekly{4}, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r7_MIT_end = fconvert(Weekly{4}, last(rangeof(t1)), round_to=:current)
    # @test r7_MIT_start:r7_MIT_end == r7_range

    r8 = fconvert(Weekly{4}, t1, method=:sum)
    @test r8.values == collect(56:49:644)
    @test rangeof(r8) == 2:14

end

@testset "fconvert, Daily to Monthly" begin
    t1 = TSeries(MIT{Daily}(1), collect(1:100))

    r1 = fconvert(Monthly, t1, method=:mean)
    @test r1.values == [16, 45.5, 75]
    @test rangeof(r1) == 1M1:1M3
    r1_range = fconvert(Monthly, rangeof(t1), trim=:both)
    @test r1_range == 1M1:1M3
    # r1_MIT_start = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Monthly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    r2 = fconvert(Monthly, t1, method=:point, values_base=:end)
    @test r2.values == [31, 31 + 28, 31 + 28 + 31]
    @test rangeof(r2) == 1M1:1M3
    r2_range = fconvert(Monthly, rangeof(t1), trim=:end)
    @test r2_range == 1M1:1M3
    # r2_MIT_start = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Monthly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    r3 = fconvert(Monthly, t1, method=:point, values_base=:begin)
    @test r3.values == [1, 1 + 31, 1 + 31 + 28, 1 + 31 + 28 + 31]
    @test rangeof(r3) == 1M1:1M4
    r3_range = fconvert(Monthly, rangeof(t1), trim=:begin)
    @test r3_range == 1M1:1M4
    # r3_MIT_start = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Monthly, last(rangeof(t1)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    r4 = fconvert(Monthly, t1, method=:sum)
    @test r4.values == [sum(1:31), sum((31+1):(31+28)), sum((31+28+1):(31+28+31))]
    @test rangeof(r4) == 1M1:1M3

    t2 = TSeries(MIT{Daily}(100), collect(1:100))

    r5 = fconvert(Monthly, t2, method=:mean)
    @test r5.values == [mean(22:(22+31-1)), mean(53:(53+30-1))]   #[37, 67.5]
    @test rangeof(r5) == 1M5:1M6
    r5_range = fconvert(Monthly, rangeof(t2), trim=:both)
    @test r5_range == 1M5:1M6
    # r5_MIT_start = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:next)
    # r5_MIT_end = fconvert(Monthly, last(rangeof(t2)), values_base=:end, round_to=:previous)
    # @test r5_MIT_start:r5_MIT_end == r5_range

    r6 = fconvert(Monthly, t2, method=:point, values_base=:end)
    @test r6.values == [21, 21 + 31, 21 + 31 + 30]
    @test rangeof(r6) == 1M4:1M6
    r6_range = fconvert(Monthly, rangeof(t2), trim=:end)
    @test r6_range == 1M4:1M6
    # r6_MIT_start = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:current)
    # r6_MIT_end = fconvert(Monthly, last(rangeof(t2)), values_base=:end, round_to=:previous)
    # @test r6_MIT_start:r6_MIT_end == r6_range

    r7 = fconvert(Monthly, t2, method=:point, values_base=:begin)
    @test r7.values == [22, 22 + 31, 22 + 31 + 30]
    @test rangeof(r7) == 1M5:1M7
    r7_range = fconvert(Monthly, rangeof(t2), trim=:begin)
    @test r7_range == 1M5:1M7
    # r7_MIT_start = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:next)
    # r7_MIT_end = fconvert(Monthly, last(rangeof(t2)), round_to=:current)
    # @test r7_MIT_start:r7_MIT_end == r7_range

    r8 = fconvert(Monthly, t2, method=:sum)
    @test r8.values == [sum(22:(22+31-1)), sum(53:(53+30-1))]
    @test rangeof(r8) == 1M5:1M6

end

@testset "fconvert, Daily to Quarterly" begin
    t1 = TSeries(MIT{Daily}(1), collect(1:400))

    r1 = fconvert(Quarterly, t1, method=:mean)
    @test r1.values == [mean(1:(31+28+31)), mean(91:(91+30+31+30-1)), mean(182:(182+31+31+30-1)), mean(274:(274+31+30+31-1))]
    @test rangeof(r1) == 1Q1:1Q4
    r1_range = fconvert(Quarterly, rangeof(t1), trim=:both)
    @test r1_range == 1Q1:1Q4
    # r1_MIT_start = fconvert(Quarterly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Quarterly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    r2 = fconvert(Quarterly, t1, method=:point, values_base=:end)
    @test r2.values == [90, 181, 273, 365]
    @test rangeof(r2) == 1Q1:1Q4
    r2_range = fconvert(Quarterly, rangeof(t1), trim=:end)
    @test r2_range == 1Q1:1Q4
    # r2_MIT_start = fconvert(Quarterly, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Quarterly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range

    r3 = fconvert(Quarterly, t1, method=:point, values_base=:begin)
    @test r3.values == [1, 91, 182, 274, 366]
    @test rangeof(r3) == 1Q1:2Q1
    r3_range = fconvert(Quarterly, rangeof(t1), trim=:begin)
    @test r3_range == 1Q1:2Q1
    # r3_MIT_start = fconvert(Quarterly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Quarterly, last(rangeof(t1)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    r4 = fconvert(Quarterly, t1, method=:sum)
    @test r4.values == [sum(1:(31+28+31)), sum(91:(91+30+31+30-1)), sum(182:(182+31+31+30-1)), sum(274:(274+31+30+31-1))]
    @test rangeof(r4) == 1Q1:1Q4

    r5 = fconvert(Quarterly{1}, t1, method=:mean)
    @test r5.values == [mean(32:(32+28+31+30-1)), mean(121:(121+31+30+31-1)), mean(213:(213+31+30+31-1)), mean(305:(305+30+31+31-1))]
    @test rangeof(r5) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    r5_range = fconvert(Quarterly{1}, rangeof(t1), trim=:both)
    @test r5_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)
    # r5_MIT_start = fconvert(Quarterly{1}, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r5_MIT_end = fconvert(Quarterly{1}, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r5_MIT_start:r5_MIT_end == r5_range

    r6 = fconvert(Quarterly{1}, t1, method=:point, values_base=:end)
    @test r6.values == [31, 120, 212, 304, 396]
    @test rangeof(r6) == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)
    r6_range = fconvert(Quarterly{1}, rangeof(t1), trim=:end)
    @test r6_range == MIT{Quarterly{1}}(4):MIT{Quarterly{1}}(8)
    # r6_MIT_start = fconvert(Quarterly{1}, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r6_MIT_end = fconvert(Quarterly{1}, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r6_MIT_start:r6_MIT_end == r6_range

    r7 = fconvert(Quarterly{1}, t1, method=:point, values_base=:begin)
    @test r7.values == [32, 121, 213, 305, 397]
    @test rangeof(r7) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)
    r7_range = fconvert(Quarterly{1}, rangeof(t1), trim=:begin)
    @test r7_range == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(9)
    # r7_MIT_start = fconvert(Quarterly{1}, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r7_MIT_end = fconvert(Quarterly{1}, last(rangeof(t1)), round_to=:current)
    # @test r7_MIT_start:r7_MIT_end == r7_range

    r8 = fconvert(Quarterly{1}, t1, method=:sum)
    @test r8.values == [sum(32:(32+28+31+30-1)), sum(121:(121+31+30+31-1)), sum(213:(213+31+30+31-1)), sum(305:(305+30+31+31-1))]
    @test rangeof(r8) == MIT{Quarterly{1}}(5):MIT{Quarterly{1}}(8)

end

@testset "fconvert, Daily to Yearly" begin
    t1 = TSeries(MIT{Daily}(1), collect(1:2000))

    r1 = fconvert(Yearly, t1, method=:mean)
    @test r1.values == [mean(1:(365+0)), mean((1*365+1):(2*365)), mean((2*365+1):(3*365)), mean((3*365+1):(4*365+1)), mean((4*365+2):(5*365+1))]
    @test rangeof(r1) == 1Y:5Y
    r1_range = fconvert(Yearly, rangeof(t1), trim=:both)
    @test r1_range == 1Y:5Y
    # r1_MIT_start = fconvert(Yearly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r1_MIT_end = fconvert(Yearly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r1_MIT_start:r1_MIT_end == r1_range

    r2 = fconvert(Yearly, t1, method=:point, values_base=:end)
    @test r2.values == [365, 2 * 365, 3 * 365, 4 * 365 + 1, 5 * 365 + 1]
    @test rangeof(r2) == 1Y:5Y
    r2_range = fconvert(Yearly, rangeof(t1), trim=:end)
    @test r2_range == 1Y:5Y
    # r2_MIT_start = fconvert(Yearly, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r2_MIT_end = fconvert(Yearly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r2_MIT_start:r2_MIT_end == r2_range


    r3 = fconvert(Yearly, t1, method=:point, values_base=:begin)
    @test r3.values == [1, 365 + 1, 2 * 365 + 1, 3 * 365 + 1, 4 * 365 + 2, 5 * 365 + 2]
    @test rangeof(r3) == 1Y:6Y
    r3_range = fconvert(Yearly, rangeof(t1), trim=:begin)
    @test r3_range == 1Y:6Y
    # r3_MIT_start = fconvert(Yearly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r3_MIT_end = fconvert(Yearly, last(rangeof(t1)), round_to=:current)
    # @test r3_MIT_start:r3_MIT_end == r3_range

    r4 = fconvert(Yearly, t1, method=:sum)
    @test r4.values == [sum(1:(365+0)), sum((1*365+1):(2*365)), sum((2*365+1):(3*365)), sum((3*365+1):(4*365+1)), sum((4*365+2):(5*365+1))]
    @test rangeof(r4) == 1Y:5Y

    r5 = fconvert(Yearly{8}, t1, method=:mean)
    @test r5.values == [mean(244:(365+243)), mean((1*365+244):(2*365+243)), mean((2*365+244):(3*365+243+1)), mean((3*365+244+1):(4*365+243+1))]
    @test rangeof(r5) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)
    r5_range = fconvert(Yearly{8}, rangeof(t1), trim=:both)
    @test r5_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)
    # r5_MIT_start = fconvert(Yearly{8}, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r5_MIT_end = fconvert(Yearly{8}, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r5_MIT_start:r5_MIT_end == r5_range

    r6 = fconvert(Yearly{8}, t1, method=:point, values_base=:end)
    @test r6.values == [243, 1 * 365 + 243, 2 * 365 + 243, 3 * 365 + 243 + 1, 4 * 365 + 243 + 1]
    @test rangeof(r6) == MIT{Yearly{8}}(1):MIT{Yearly{8}}(5)
    r6_range = fconvert(Yearly{8}, rangeof(t1), trim=:end)
    @test r6_range == MIT{Yearly{8}}(1):MIT{Yearly{8}}(5)
    # r6_MIT_start = fconvert(Yearly{8}, first(rangeof(t1)), values_base=:begin, round_to=:current)
    # r6_MIT_end = fconvert(Yearly{8}, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test r6_MIT_start:r6_MIT_end == r6_range

    r7 = fconvert(Yearly{8}, t1, method=:point, values_base=:begin)
    @test r7.values == [244, 1 * 365 + 244, 2 * 365 + 244, 3 * 365 + 244 + 1, 4 * 365 + 244 + 1]
    @test rangeof(r7) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(6)
    r7_range = fconvert(Yearly{8}, rangeof(t1), trim=:begin)
    @test r7_range == MIT{Yearly{8}}(2):MIT{Yearly{8}}(6)
    # r7_MIT_start = fconvert(Yearly{8}, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # r7_MIT_end = fconvert(Yearly{8}, last(rangeof(t1)), round_to=:current)
    # @test r7_MIT_start:r7_MIT_end == r7_range

    r8 = fconvert(Yearly{8}, t1, method=:sum)
    @test r8.values == [sum(244:(365+243)), sum((1*365+244):(2*365+243)), sum((2*365+244):(3*365+243+1)), sum((3*365+244+1):(4*365+243+1))]
    @test rangeof(r8) == MIT{Yearly{8}}(2):MIT{Yearly{8}}(5)

end

@testset "fconvert, BDaily to Monthly" begin
    # First BD (Monday) in May to late June
    t1 = TSeries(bdaily("2022-05-02"), collect(1:42))
    r1 = fconvert(Monthly, t1)
    @test rangeof(r1) == 2022M5:2022M5
    @test values(r1) == [11.5]
    dates1 = fconvert(Monthly, rangeof(t1))
    @test dates1 == 2022M5:2022M5
    # mit1_1 = fconvert(Monthly, first(rangeof(t1)), values_base=:begin, round_to=:next)
    # mit1_2 = fconvert(Monthly, last(rangeof(t1)), values_base=:end, round_to=:previous)
    # @test mit1_1 == 2022M5
    # @test mit1_2 == 2022M5

    # Early July to late July
    t2 = TSeries(bdaily("2022-07-06"), collect(1:13))
    r2 = fconvert(Monthly, t2)
    @test rangeof(r2) == 2022M8:2022M7 #hmmm
    @test values(r2) == []
    dates2 = fconvert(Monthly, rangeof(t2))
    @test dates2 == 2022M8:2022M7
    # mit2_1 = fconvert(Monthly, first(rangeof(t2)), values_base=:begin, round_to=:next)
    # @test mit2_1 == 2022M8


    # Early august (Tuesday) to last day in September (Friday)
    t3 = TSeries(bdaily("2022-08-02"), collect(1:44))
    r3 = fconvert(Monthly, t3)
    @test rangeof(r3) == 2022M9:2022M9
    @test values(r3) == [33.5]
    dates3 = fconvert(Monthly, rangeof(t3))
    @test dates3 == 2022M9:2022M9
    # mit3_1 = fconvert(Monthly, first(rangeof(t3)), values_base=:begin, round_to=:next)
    # mit3_2 = fconvert(Monthly, last(rangeof(t3)), values_base=:end, round_to=:previous)
    # @test mit3_1 == 2022M9
    # @test mit3_2 == 2022M9

    # First day in November (Tuesday) to last BD in December (Friday)
    t4 = TSeries(bdaily("2022-11-01"), collect(1:44))
    r4 = fconvert(Monthly, t4)
    @test rangeof(r4) == 2022M11:2022M12
    @test values(r4) == [11.5, 33.5]
    dates4 = fconvert(Monthly, rangeof(t4))
    @test dates4 == 2022M11:2022M12
    # mit4_1 = fconvert(Monthly, first(rangeof(t4)), values_base=:begin, round_to=:next)
    # mit4_2 = fconvert(Monthly, last(rangeof(t4)), values_base=:end, round_to=:previous)
    # @test mit4_1 == 2022M11
    # @test mit4_2 == 2022M12

    # First BD in October (Monday) to late November (Tuesday)
    t5 = TSeries(bdaily("2022-10-03"), collect(1:42))
    r5 = fconvert(Monthly, t5)
    @test rangeof(r5) == 2022M10:2022M10
    @test values(r5) == [11.0]
    dates5 = fconvert(Monthly, rangeof(t5))
    @test dates5 == 2022M10:2022M10
    # mit5_1 = fconvert(Monthly, first(rangeof(t5)), values_base=:begin, round_to=:next)
    # mit5_2 = fconvert(Monthly, last(rangeof(t5)), values_base=:end, round_to=:previous)
    # @test mit5_1 == 2022M10
    # @test mit5_2 == 2022M10
end

@testset "fconvert, BDaily to Weekly" begin
    t1 = TSeries(bdaily("2000-01-03"), collect(1:10)) # Monday the third to Friday the 14th, two whole weeks
    r1 = fconvert(Weekly, t1)
    @test r1.values == [3, 8]
    @test rangeof(r1) == MIT{Weekly}(104304):MIT{Weekly}(104305)
    @test rangeof(r1) == fconvert(Weekly, rangeof(t1))
    # @test rangeof(r1)[begin] == fconvert(Weekly, rangeof(t1)[begin], values_base=:begin, round_to=:next)
    # @test rangeof(r1)[end] == fconvert(Weekly, rangeof(t1)[end], values_base=:end, round_to=:previous)

    t2 = TSeries(bdaily("2000-01-06"), collect(1:10))
    r2 = fconvert(Weekly{3}, t2)
    @test r2.values == [3, 8]
    @test rangeof(r2) == MIT{Weekly{3}}(104305):MIT{Weekly{3}}(104306)
    @test rangeof(r2) == fconvert(Weekly{3}, rangeof(t2))
    # @test rangeof(r2)[begin] == fconvert(Weekly{3}, rangeof(t2)[begin], values_base=:begin, round_to=:next)
    # @test rangeof(r2)[end] == fconvert(Weekly{3}, rangeof(t2)[end], values_base=:end, round_to=:previous)

    r3 = fconvert(Weekly{3}, t1)
    @test r2.values == [3, 8]

    r4 = fconvert(Weekly{6}, t1)
    @test r4.values == [3, 8]

    r5 = fconvert(Weekly{5}, t1)
    @test r5.values == [3, 8]

    r6 = fconvert(Weekly{7}, t1)
    @test r6.values == [3, 8]

end

@testset "fconvert, BDaily to Daily" begin

    t1 = TSeries(bdaily("2022-07-06"), collect(1:13))
    @test rangeof(t1) == bdaily("2022-07-06"):bdaily("2022-07-22")
    r1 = fconvert(Daily, t1)
    @test values(r1) ≈ [1, 2, 3, 4, 4, 4, 5, 6, 7, 8, 9, 9, 9, 10, 11, 12, 13] nans = true
    @test rangeof(r1) == daily("2022-07-06"):daily("2022-07-22")
    r2 = fconvert(Daily, t1, method=:even)
    @test values(r2) ≈ [1, 2, 3, NaN, NaN, 4, 5, 6, 7, 8, NaN, NaN, 9, 10, 11, 12, 13] nans = true
    dates1 = fconvert(Daily, rangeof(t1))
    @test dates1 == daily("2022-07-06"):daily("2022-07-22")
    mit1 = fconvert(Daily, first(rangeof(t1)))
    mit2 = fconvert(Daily, last(rangeof(t1)))
    @test mit1 == daily("2022-07-06")
    @test mit2 == daily("2022-07-22")

    r2 = fconvert(Daily, t1, values_base=:begin)
    @test values(r2) ≈ [1, 2, 3, 3, 3, 4, 5, 6, 7, 8, 8, 8, 9, 10, 11, 12, 13]
    @test rangeof(r2) == daily("2022-07-06"):daily("2022-07-22")

    r3 = fconvert(Daily, t1, values_base=:end)
    @test values(r3) ≈ [1, 2, 3, 4, 4, 4, 5, 6, 7, 8, 9, 9, 9, 10, 11, 12, 13]
    @test rangeof(r3) == daily("2022-07-06"):daily("2022-07-22")

    r4 = fconvert(Daily, t1, method=:linear)
    @test values(r4) ≈ [1, 2, 3, 3 + 1 / 3, 3 + 2 / 3, 4, 5, 6, 7, 8, 8 + 1 / 3, 8 + 2 / 3, 9, 10, 11, 12, 13]
    @test rangeof(r4) == daily("2022-07-06"):daily("2022-07-22")


end

@testset "fconvert, YPFrequency to Daily and BDaily" begin
    t1 = TSeries(2022M1, collect(1:12))
    t2 = TSeries(2022Q1, collect(1:4))
    t3 = TSeries(2022Y, collect(1:2))

    d1 = fconvert(Daily, t1)
    @test d1[daily("2022-01-31")] == 1.0
    @test d1[daily("2022-02-01")] == 2.0
    @test d1[daily("2022-04-01")] == 4.0
    @test length(d1) == 365

    d2 = fconvert(Daily, t2)
    @test d2[daily("2022-01-31")] == 1.0
    @test d2[daily("2022-02-01")] == 1.0
    @test d2[daily("2022-04-01")] == 2.0
    @test length(d1) == 365

    d3 = fconvert(Daily, t3)
    @test d3.values == [ones(365)..., (2 * ones(365))...]

    bd1 = fconvert(BDaily, t1)
    @test bd1[bdaily("2022-01-31")] == 1.0
    @test bd1[bdaily("2022-02-01")] == 2.0
    @test bd1[bdaily("2022-04-01")] == 4.0
    @test length(bd1) == 260

    bd2 = fconvert(BDaily, t2)
    @test bd2[bdaily("2022-01-31")] == 1.0
    @test bd2[bdaily("2022-02-01")] == 1.0
    @test bd2[bdaily("2022-04-01")] == 2.0
    @test length(bd2) == 260

    bd3 = fconvert(BDaily, t3)
    @test bd3.values == [ones(260)..., (2 * ones(260))...]

    d1_lin = fconvert(Daily, t1, method=:linear)
    @test d1_lin[daily("2022-01-01"):daily("2022-01-31")].values == collect(LinRange(0, 1, 32))[2:32]
    @test d1_lin[daily("2022-02-01"):daily("2022-02-28")].values == collect(LinRange(1, 2, 29))[2:29]
    @test d1_lin[daily("2022-04-01"):daily("2022-04-30")].values == collect(LinRange(3, 4, 31))[2:31]
    @test length(d1_lin) == 365

    d1_lin2 = fconvert(Daily, t1, method=:linear, values_base=:begin)
    @test d1_lin2[daily("2022-01-01"):daily("2022-01-31")].values == collect(LinRange(1, 2, 32))[1:31]
    @test d1_lin2[daily("2022-02-01"):daily("2022-02-28")].values == collect(LinRange(2, 3, 29))[1:28]
    @test d1_lin2[daily("2022-04-01"):daily("2022-04-30")].values == collect(LinRange(4, 5, 31))[1:30]
    @test length(d1_lin2) == 365

    d1_lin3 = fconvert(Daily, t1, method=:linear, values_base=:middle)
    @test d1_lin2[daily("2022-01-01"):daily("2022-01-31")].values == collect(LinRange(1, 2, 32))[1:31]
    @test d1_lin2[daily("2022-02-01"):daily("2022-02-28")].values == collect(LinRange(2, 3, 29))[1:28]
    @test d1_lin2[daily("2022-04-01"):daily("2022-04-30")].values == collect(LinRange(4, 5, 31))[1:30]
    @test length(d1_lin2) == 365

    d2_lin = fconvert(Daily, t2, method=:linear)
    @test d2_lin[daily("2022-01-01"):daily("2022-03-31")].values == collect(LinRange(0, 1, 31 + 28 + 31 + 1))[2:31+28+31+1]
    @test d2_lin[daily("2022-04-01"):daily("2022-06-30")].values == collect(LinRange(1, 2, 30 + 31 + 30 + 1))[2:30+31+30+1]
    @test d2_lin[daily("2022-07-01"):daily("2022-09-30")].values == collect(LinRange(2, 3, 31 + 31 + 30 + 1))[2:31+31+30+1]
    @test length(d2_lin) == 365

    d2_lin2 = fconvert(Daily, t2, method=:linear, values_base=:begin)
    @test d2_lin2[daily("2022-01-01"):daily("2022-03-31")].values == collect(LinRange(1, 2, 31 + 28 + 31 + 1))[1:31+28+31]
    @test d2_lin2[daily("2022-04-01"):daily("2022-06-30")].values == collect(LinRange(2, 3, 30 + 31 + 30 + 1))[1:30+31+30]
    @test d2_lin2[daily("2022-07-01"):daily("2022-09-30")].values == collect(LinRange(3, 4, 31 + 31 + 30 + 1))[1:31+31+30]
    @test length(d2_lin2) == 365

    d3_lin = fconvert(Daily, t3, method=:linear)
    @test d3_lin[daily("2022-01-01"):daily("2022-12-31")].values == collect(LinRange(0, 1, 366))[2:366]
    @test length(d3_lin) == 365 * 2

    d3_lin2 = fconvert(Daily, t3, method=:linear, values_base=:begin)
    @test d3_lin2[daily("2022-01-01"):daily("2022-12-31")].values == collect(LinRange(1, 2, 366))[1:365]
    @test length(d3_lin2) == 365 * 2

    bd1_lin = fconvert(BDaily, t1, method=:linear)
    @test bd1_lin[bdaily("2022-01-01", bias=:next):bdaily("2022-01-31", bias=:previous)].values == collect(LinRange(0, 1, 22))[2:22]
    @test bd1_lin[bdaily("2022-02-01", bias=:next):bdaily("2022-02-28", bias=:previous)].values == collect(LinRange(1, 2, 21))[2:21]
    @test bd1_lin[bdaily("2022-04-01", bias=:next):bdaily("2022-04-30", bias=:previous)].values == collect(LinRange(3, 4, 22))[2:22]
    @test length(bd1_lin) == 260

    bd1_lin2 = fconvert(BDaily, t1, method=:linear, values_base=:begin)
    @test bd1_lin2[bdaily("2022-01-01", bias=:next):bdaily("2022-01-31", bias=:previous)].values == collect(LinRange(1, 2, 22))[1:21]
    @test bd1_lin2[bdaily("2022-02-01", bias=:next):bdaily("2022-02-28", bias=:previous)].values == collect(LinRange(2, 3, 21))[1:20]
    @test bd1_lin2[bdaily("2022-04-01", bias=:next):bdaily("2022-04-30", bias=:previous)].values == collect(LinRange(4, 5, 22))[1:21]
    @test length(bd1_lin2) == 260

    bd2_lin = fconvert(BDaily, t2, method=:linear)
    @test bd2_lin[bdaily("2022-01-01", bias=:next):bdaily("2022-03-31", bias=:previous)].values == collect(LinRange(0, 1, 65))[2:65]
    @test length(bd2_lin) == 260

    bd2_lin2 = fconvert(BDaily, t2, method=:linear, values_base=:begin)
    @test bd2_lin2[bdaily("2022-01-01", bias=:next):bdaily("2022-03-31", bias=:previous)].values == collect(LinRange(1, 2, 65))[1:64]
    @test length(bd2_lin2) == 260

    bd3_lin = fconvert(BDaily, t3, method=:linear)
    @test bd3_lin[bdaily("2022-01-01", bias=:next):bdaily("2022-12-31", bias=:previous)].values == collect(LinRange(0, 1, 261))[2:261]
    @test length(bd3_lin) == 260 * 2

    bd3_lin2 = fconvert(BDaily, t3, method=:linear, values_base=:begin)
    @test bd3_lin2[bdaily("2022-01-01", bias=:next):bdaily("2022-12-31", bias=:previous)].values == collect(LinRange(1, 2, 261))[1:260]
    @test length(bd3_lin2) == 260 * 2


end

@testset "fconvert, YPFrequency to Weekly" begin
    t1 = TSeries(2022M1, collect(1:12))
    t2 = TSeries(2022Q1, collect(1:4))
    t3 = TSeries(2022Y, collect(1:2))
    t1_2001 = TSeries(2001M1, collect(1:12))
    t1_2017 = TSeries(2017M1, collect(1:12))
    t1_2021 = TSeries(2021M1, collect(1:12))

    w1 = fconvert(Weekly, t1)
    @test w1[1:35] == [1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5,5,5,6,6,6,6,7,7,7,7,7,8,8,8,8]
    @test length(w1) == 52
    @test rangeof(w1) == weekly("2022-01-01"):weekly("2022-12-25") 
    w1_2001 = fconvert(Weekly, t1_2001)
    @test w1_2001[1:35] == [1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,7,8,8,8,8,9]
    @test rangeof(w1_2001) == weekly("2001-01-01"):weekly("2001-12-30")
    w1_2017 = fconvert(Weekly, t1_2017)
    @test w1_2017[1:35] == [1,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,4,5,5,5,5,6,6,6,6,7,7,7,7,7,8,8,8,8]
    @test rangeof(w1_2017) == weekly("2017-01-01"):weekly("2017-12-31") 
    w1_2021 = fconvert(Weekly{5}, t1_2021)
    @test rangeof(w1_2021) == weekly("2021-01-01", 5):weekly("2021-12-31", 5)

    w2 = fconvert(Weekly, t2)
    @test w2[1:20] == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2]
    @test length(w2) == 52
    @test rangeof(w2) == weekly("2022-01-01"):weekly("2022-12-25") 

    w3 = fconvert(Weekly, t3)
    @test w3[1:52] == ones(52)
    @test w3[53:105] == [(2 * ones(53))...]
    @test length(w3) == 105
    @test rangeof(w3) == weekly("2022-01-01"):weekly("2023-12-31")


    w1_beg = fconvert(Weekly, t1, values_base=:begin)
    @test w1_beg[1:36] == [1, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 8, 9]
    @test length(w1_beg) == 52
    @test rangeof(w1_beg) == weekly("2022-01-08"):weekly("2022-12-31")

    w2_beg = fconvert(Weekly, t2, values_base=:begin)
    @test w2_beg[1:20] == [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2]
    @test length(w2_beg) == 52
    @test rangeof(w2_beg) == weekly("2022-01-08"):weekly("2022-12-31")

    w3_beg = fconvert(Weekly, t3, values_base=:begin)
    @test w3_beg[1:52] == ones(52)
    @test w3_beg[53:104] == [(2 * ones(52))...]
    @test length(w3_beg) == 104
    @test rangeof(w3_beg) == weekly("2022-01-08"):weekly("2023-12-31")

    # w1_lin = fconvert(Weekly, t1, method=:linear)
    # @test w1_lin[1:20] == [
    #     collect(LinRange(0, 1, 6))[2:6]...,
    #     collect(LinRange(1, 2, 5))[2:5]...,
    #     collect(LinRange(2, 3, 5))[2:5]...,
    #     collect(LinRange(3, 4, 5))[2:5]...,
    #     collect(LinRange(4, 5, 6))[2:4]...,
    # ]
    # @test length(w1_lin) == 53

    # w1_lin2 = fconvert(Weekly, t1, method=:linear, values_base=:begin)
    # @test w1_lin2[1:20] == [
    #     collect(LinRange(1, 2, 6))[1:5]...,
    #     collect(LinRange(2, 3, 5))[1:4]...,
    #     collect(LinRange(3, 4, 5))[1:4]...,
    #     collect(LinRange(4, 5, 5))[1:4]...,
    #     collect(LinRange(5, 6, 6))[1:3]...,
    # ]
    # @test length(w1_lin2) == 53

    # w2_lin = fconvert(Weekly, t2, method=:linear)
    # @test w2_lin[1:20] == [
    #     collect(LinRange(0, 1, 14))[2:14]...,
    #     collect(LinRange(1, 2, 14))[2:8]...,
    # ]
    # @test length(w2_lin) == 53

    # w2_lin2 = fconvert(Weekly, t2, method=:linear, values_base=:begin)
    # @test w2_lin2[1:20] == [
    #     collect(LinRange(1, 2, 14))[1:13]...,
    #     collect(LinRange(2, 3, 14))[1:7]...,
    # ]
    # @test length(w2_lin2) == 53


    # w3_lin = fconvert(Weekly, t3, method=:linear)
    # @test w3_lin[1:20] == [
    #     collect(LinRange(0, 1, 53))[2:21]...
    # ]
    # @test length(w3_lin) == 105

    # w3_lin2 = fconvert(Weekly, t3, method=:linear, values_base=:begin)
    # @test w3_lin2[1:20] == [
    #     collect(LinRange(1, 2, 53))[1:20]...
    # ]
    # @test length(w3_lin2) == 105
end

@testset "fconvert, all combinations" begin
    frequencies = [
        Daily,
        BDaily,
        Weekly,
        Weekly{1},
        Weekly{2},
        Weekly{3},
        Weekly{4},
        Weekly{5},
        Weekly{6},
        Weekly{7},
        Monthly,
        Quarterly,
        Quarterly{1},
        Quarterly{2},
        Quarterly{3},
        HalfYearly,
        HalfYearly{1},
        HalfYearly{2},
        HalfYearly{3},
        HalfYearly{4},
        HalfYearly{5},
        HalfYearly{6},
        Yearly,
        Yearly{1},
        Yearly{2},
        Yearly{3},
        Yearly{4},
        Yearly{5},
        Yearly{6},
        Yearly{7},
        Yearly{8},
        Yearly{9},
        Yearly{10},
        Yearly{11},
        Yearly{12}
    ]
    # freq_short = 
    combinations = [(F_from, F_to) for F_from in frequencies for F_to in frequencies]
    counter = 1
    t_from = nothing
    last_F_from = nothing
    # @showprogress "combinations" for (F_from, F_to) in combinations
    for (F_from, F_to) in combinations
        if F_from != last_F_from
            last_F_from = F_from
            t_from = TSeries(MIT{F_from}(100), collect(1:800))
        end
        if F_to !== F_from
            # println(counter, ", from:", F_from, ", to:", F_to)

            # TSeries
            t_to = @suppress fconvert(F_to, t_from)
            @test frequencyof(t_to) == TimeSeriesEcon.sanitize_frequency(F_to)
            @test length(t_to.values) > 0
            # println(F_from, ", ", F_to)
            if F_to <= F_from
                for method in (:mean, :sum, :point, :min, :max)
                    for values_base in (:begin, :end)
                        # @show method, values_base
                        t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                        @test frequencyof(t_to_sub) == TimeSeriesEcon.sanitize_frequency(F_to)
                        @test length(t_to_sub.values) > 0
                        @test maximum(values(t_to_sub)) < 1000000 #check for undefineds
                        @test minimum(values(t_to_sub)) > -1000000 #check for undefineds
                    end
                end
            elseif F_to > F_from
                for method in (:const, :even)
                    for values_base in (:begin, :end)
                        t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                        @test frequencyof(t_to_sub) == TimeSeriesEcon.sanitize_frequency(F_to)
                        @test length(t_to_sub.values) > 0
                        @test maximum(TimeSeriesEcon.skip_if_warranted(values(t_to_sub), F_from == BDaily && F_to == Daily)) < 1000000
                        @test minimum(TimeSeriesEcon.skip_if_warranted(values(t_to_sub), F_from == BDaily && F_to == Daily)) > -1000000
                    end
                end
                if F_to ∈ (Daily, BDaily, Monthly)
                    for method in (:linear, )
                        for values_base in (:begin, :end, :middle)
                            t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                            @test frequencyof(t_to_sub) == TimeSeriesEcon.sanitize_frequency(F_to)
                            @test length(t_to_sub.values) > 0
                            @test maximum(TimeSeriesEcon.skip_if_warranted(values(t_to_sub), F_from == BDaily && F_to == Daily)) < 1000000
                            @test minimum(TimeSeriesEcon.skip_if_warranted(values(t_to_sub), F_from == BDaily && F_to == Daily)) > -1000000
                        end
                    end
                end
            end
            
            # unit ranges
            range_to = @suppress fconvert(F_to, rangeof(t_from))
            @test frequencyof(range_to) == TimeSeriesEcon.sanitize_frequency(F_to)
            @test length(range_to) > 0
            if F_to ∉ (Daily, BDaily)
                range_to_begin = @suppress fconvert(F_to, rangeof(t_from), trim=:begin)
                @test frequencyof(range_to_begin) == TimeSeriesEcon.sanitize_frequency(F_to)
                @test length(range_to_begin) > 0
                range_to_end = @suppress fconvert(F_to, rangeof(t_from), trim=:end)
                @test frequencyof(range_to_end) == TimeSeriesEcon.sanitize_frequency(F_to)
                @test length(range_to_end) > 0
            end

            # MITs
            if F_to == BDaily
                mit_to_previous = @suppress fconvert(F_to, t_from.firstdate, round_to=:previous)
                @test frequencyof(mit_to_previous) == sanitize_frequency(F_to)
                mit_to_next = @suppress fconvert(F_to, t_from.firstdate, round_to=:next)
                @test frequencyof(mit_to_next) == sanitize_frequency(F_to)
            else
                mit_to_end = @suppress fconvert(F_to, t_from.firstdate, values_base=:end)
                @test frequencyof(mit_to_end) == sanitize_frequency(F_to)
                mit_to_begin = @suppress fconvert(F_to, t_from.firstdate, values_base=:begin)
                @test frequencyof(mit_to_begin) == sanitize_frequency(F_to)
            end
            counter += 1
        end
    end
end
