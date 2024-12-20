# Copyright (c) 2020-2024, Bank of Canada
# All rights reserved.


@testset "MV construct" begin
    @test size(MVTSeries(20Q1)) == (0, 0)
    @test size(MVTSeries(20Q1, :a)) == (0, 1)
    @test size(MVTSeries(20Q1, (:a, :b))) == (0, 2)
    @test size(MVTSeries(20Q1, (:a, "b"))) == (0, 2)
    @test size(MVTSeries(20Q1:20Q4, :a)) == (4, 1)
    @test size(MVTSeries(20Q1:20Q4, (:a, :b))) == (4, 2)
    @test size(MVTSeries(20Q1:20Q4, ("a", :b))) == (4, 2)
    @test size(MVTSeries(20Q1:20Q4, ["a", :b])) == (4, 2)
    @test size(MVTSeries(20Q1:20Q4, ["a", :b], undef)) == (4, 2)
    @test size(MVTSeries(20Q1:20Q4, ["a", :b], 5)) == (4, 2)
    @test size(MVTSeries(20Q1:20Q4, ["a", :b], zeros)) == (4, 2)
    @test size(MVTSeries(1U:5U)) == (5, 0)
    @test size(MVTSeries(a=TSeries(1U:5U), b=TSeries(3U:8U))) == (8, 2)


    let a = similar(zeros(Int, 0, 0), (20Y:22Y, (:a, :b))),
        b = similar(zeros(Int, 0, 0), Complex, (20Y:22Y, (:a, :b))),
        c = fill(5, 20Q1:20Q4, (:a, :b, :c))

        @test a isa MVTSeries
        @test rangeof(a) == 20Y:22Y
        @test tuple(colnames(a)...) == (:a, :b)
        @test eltype(a) == Int
        @test eltype(b) == Complex
        @test eltype(c) == Int
        @test size(c) == (4, 3)
        @test extrema(c) == (5, 5)
        @test typeof(similar(c)) === typeof(c)
    end

    @test_throws ArgumentError MVTSeries(1U, (:a, :b), zeros(10, 3))
    @test_throws ArgumentError MVTSeries(1U, (:a, :b), zeros(10, 1))

    @test_throws ArgumentError MVTSeries(1U:5U, (:a, :b), zeros(10, 2))
    @test_throws ArgumentError MVTSeries(1U:5U, (:a, :b), zeros(4, 2))
    @test (MVTSeries(1U:5U, (:a, :b), zeros(5, 2)); true)

    @test (MVTSeries(20Q1, ("a",), zeros(5,)); true)
    @test (MVTSeries(20Q1, "a", zeros(5,)); true)
    @test (MVTSeries(1U:5U, ("a",), zeros(5,)); true)

    @test (MVTSeries(20Q1, :a, zeros(5,)); true)
    @test (MVTSeries(1U:5U, :a, zeros(5,)); true)

    # construct with named arguments
    let x = MVTSeries(2020Q1:2021Q1;
            hex=TSeries(2019Q1, collect(Float64, 1:20)),
            why=zeros(5),
            zed=3)
        @test x.hex isa TSeries
        @test x isa MVTSeries
        @test rangeof(x) == 2020Q1:2021Q1
        # provided TSeries is truncated to MVTSeries range
        @test rangeof(x.hex) == 2020Q1:2021Q1
        @test x.hex.values == collect(5.0:9.0)
    end

    # construct from a TSeries - init all columns from given TSeries
    init = TSeries(2020Q1, randn(16))
    @test (MVTSeries(2021Q1:2022Q4, (:a, :b, :c), init); true)
    a = MVTSeries(2021Q1:2022Q4, (:a, :b, :c), init)
    @test axes(a) == (2021Q1:2022Q4, [:a, :b, :c])
    for (_, col) in columns(a)
        @test col ≈ init
    end
    @test (fill(init, colnames(a)) ≈ a)
    b = fill(init, colnames(a))
    @test axes(b) == (rangeof(init), axes(a, 2))

end

@testset "MV Int Ind" begin
    a = MVTSeries(20Q1, (:a, :b), rand(5, 2))
    for i = 1:10
        x = a[i]
        a[i] = i
    end
    @test a[:] == a.values[:]
    @test a[:] == 1:10
    @test a[3:5] == 3:5
    @test a[:, 1] == 1:5
    @test a[1, :] == [1, 6]
    @test a[1:3, :] == [1 6; 2 7; 3 8]
    @test a[:, 1:2] == a.values[:, 1:2]
    @test a[:, :] == a
    for i = 1:5
        for j = 1:2
            x = a[i, j]
            a[i, j] = 10i + j
        end
    end
    @test a[:] == [11, 21, 31, 41, 51, 12, 22, 32, 42, 52]

    b = rand(Bool, size(a))
    @test a[b[:, 1], 1] == a.values[b[:, 1], 1]
    @test a[1, b[1, :]] == a.values[1, b[1, :]]
    @test a[b] == a.values[b]

end

@testset "MV dot" begin
    a = MVTSeries(20Q1, [:a, "b"], rand(10, 2))
    @test a.a isa TSeries
    a.a[20Q1] = 22
    @test a[1, 1] == 22
    @test_throws BoundsError a.c
    @test (a.a = TSeries(20Q1, 1:10); a.values[:, 1] == collect(1:10))
    @test (a.a = 1; a.values[:, 1] == ones(10))
    b = MVTSeries(rangeof(a), (:a,), rand)
    @test (a.a = b; a.values[:, 1] == b.values[:, 1])
    @test (a[:, :] = 6ones(size(a)...); all(a.values .== 6))
    @test (a[:, :] .= 6ones(size(a)...); all(a.values .== 6))
end

@testset "MV" begin
    @test_throws ArgumentError MVTSeries(1M10, (:a, :b, :c), rand(10, 2))
    let nms = (:a, :b), dta = rand(20, 2),
        sd = MVTSeries(2000Q1, nms, copy(dta)),
        dta2 = rand!(similar(dta))

        # if one argument is Colon, fall back on single argument indexing
        # getindex
        @test sd[2000Q1, :] == dta[1, :]
        @test all(sd[2000Q1:2000Q4, :].values == dta[1:4, :])
        @test sd[:, :a].values == dta[:, 1]
        @test sd[:, (:a, :b)].values == dta[:, 1:2]
        @test sd[:, [:a, :b]].values == dta[:, 1:2]

        @test firstdate(sd) == 2000Q1
        @test lastdate(sd) == 2000Q1 + 20 - 1
        @test frequencyof(sd) <: Quarterly
        @test sd isa AbstractMatrix
        @test size(sd) == size(dta)
        # integer indexing must be identical to dta
        for i in axes(dta, 2)
            @test sd[:, i] == dta[:, i]
        end
        for j in axes(dta, 1)
            @test sd[j, :] == dta[j, :]
        end
        for i in eachindex(dta)
            @test sd[i] == dta[i]
        end
        # set indexing with integers
        for i in eachindex(dta2)
            sd[i] = dta2[i]
        end
        @test sd[:] == dta2[:]
        for i in axes(dta, 1)
            sd[i, :] = dta[i, :]
        end
        @test sd[:] == dta[:]
        for i in axes(dta2, 2)
            sd[:, i] = dta2[:, i]
        end
        @test sd[:] == dta2[:]
        # access by dot notation (for the columns)
        @test propertynames(sd) == nms
        @test sd.a isa TSeries
        @test sd.b isa TSeries
        @test_throws BoundsError sd.c
        @test sd.a.values == dta2[:, 1]
        sd.a[:] = dta[:, 1]
        sd.b[:] = dta[:, 2]
        @test sd[:] == dta[:]
        @test sd[:a] isa TSeries && sd[:a].values == dta[:, 1]
        @test sd["b"] isa TSeries && sd["b"].values == dta[:, 2]
        # 
        sd.a = dta[:, 1]
        sd.b = dta[:, 2]
        @test sd[:] == dta[:]
        # 
        sd[:] = dta[:]
        sd.a = sd.b
        @test sd[:, 1] == sd[:, 2]
        sd.a = zeros(size(dta, 1))
        @test sum(abs, sd.a.values) == 0
        @test_throws DimensionMismatch sd.a[:] = ones(length(sd.a) + 5)
        @test_throws DimensionMismatch sd.a = ones(length(sd.a) + 5)
        # access to rows by MIT
        sd[:] = dta[:]
        @test sd[2000Q1] isa Vector{Float64}
        for (i, idx) in enumerate(rangeof(sd))
            @test sd[idx] == dta[i, :]
        end
        sd[2000Q1] = zeros(size(dta, 2))
        @test sum(abs, sd[1, :]) == 0
        @test_throws BoundsError sd[1999Q4]
        @test_throws DimensionMismatch sd[2000Q3] = zeros(size(dta, 2) + 1)
        @test_throws ArgumentError sd[2000Y]
        @test_throws BoundsError sd[1999Q4] = [5.0, 1.1]
        @test_throws BoundsError sd[2010Q4] = rand(2)
        # 
        @test sd[2001Q1:2002Q4] isa MVTSeries
        @test sd[2001Q1:2002Q4].values == sd[5:12, :]
        sd[2001Q1:2002Q4] = 1:16
        @test sd[5:12, :] == reshape(1.0:16.0, :, 2)
        @test_throws BoundsError sd[1111Q4:2002Q1]
        @test_throws BoundsError sd[2002Q1:2200Q2]
        @test_throws DimensionMismatch sd[2001Q1:2002Q4] = 1:17
        # assign new column
        sd1 = hcat(sd, c=sd.a .+ 3.0)
        @test sd1[nms] == sd
        @test sd1[(:a, :c)].values == sd1[:, [1, 3]]
        # access with 2 args MIT and Symbol
        @test sd[2001Q2, (:a, :b)] isa Vector{eltype(sd)}
        let foo = sd[2001Q2:2002Q1, (:a, :b)]
            @test foo isa MVTSeries
            @test size(foo) == (4, 2)
            @test firstdate(foo) == 2001Q2
        end
        # access with an MIT range and a Symbol returns a TSeries
        let foo = sd[2001Q2:2002Q1, :a]
            @test foo isa TSeries
            @test size(foo) == (4,)
            @test firstdate(foo) == 2001Q2
            @test foo.values == sd[2001Q2:2002Q1, :a].values
        end
        @test_throws BoundsError sd[1999Q1, (:a,)]
        @test_throws BoundsError sd[2001Q1:2001Q2, (:a, :c)]
        @test_throws Exception sd.c = 5
        @test similar(sd) isa typeof(sd)
        @test_throws BoundsError sd[1999Q1:2000Q4] = zeros(8, 2)
        @test_throws BoundsError sd[2004Q1:2013Q4, [:a, :b]]
        # setindex with two 
        @test_throws ArgumentError sd[2001Q1, (:b,)] = 3.5
        sd[2001Q1, :b] = 3.5
        @test sd[5, 2] == 3.5
        @test_throws ArgumentError sd[2000Q1:2001Q4, (:b,)] = 3.7
        sd[2000Q1:2001Q4, (:b,)] = fill(3.7, 8)
        @test all(sd[1:8, 2] .== 3.7)
        @test_throws BoundsError sd[1999Q1:2000Q4, (:a, :b)] = 5.7
        @test_throws BoundsError sd[2000Q1:2000Q4, (:a, :c)] = 5.7

        # getindex mixed_freq_error
        @test_throws ArgumentError sd[1U, :a]
        @test_throws ArgumentError sd[1U:5U, :b]

        # setindex mixed_freq_error
        @test_throws ArgumentError sd[1U, :a] = 5
        @test_throws ArgumentError sd[1U:5U, :a] = 5

        # if one argument is Colon, fall back on single argument indexing
        # setindex
        @test (myvar = [2, 2]; sd[2000Q1, :] = myvar; sd[2000Q1, :] == myvar)
        @test (myvar = [1 2; 3 4]; sd[2000Q1:2000Q2, :] = myvar; sd[2000Q1:2000Q2, :].values == myvar)
        @test (sd[:, :a] = dta[:, 1]; sd[:, :a].values == dta[:, 1])
        @test (myvar = rand(size(sd)...); sd[:, (:a, :b)] = myvar; sd[:, (:a, :b)].values == myvar)
        @test (myvar = rand(size(sd)...); sd[:, [:a, :b]] = myvar; sd[:, [:a, :b]].values == myvar)

        # with a range of MIT and a single column, we fall back on TSeries assignment
        @test (myvar = [1, 2, 3, 4]; sd[2000Q1:2000Q4, :a] = myvar; sd[2000Q1:2000Q4, :a].values == myvar)

        # setindex from an MVTSeries to an MVTSeries
        begin
            sd2 = MVTSeries(2001Q1, nms, rand(8, length(nms)))
            sd[2001Q1:2001Q4, [:a, :b]] = sd2
            @test (sd[2001Q1:2001Q4, :].values == sd2[2001Q1:2001Q4, :].values)
            dA = rand(36, 3)
            A = MVTSeries(2020M1, (:a, :b, :c), copy(dA))
            B = MVTSeries(2021M1, (:a, :c), ones(36, 2))
            @test (A[2021M1:2021M12] = B; true)
            @test A[:, :b] ≈ dA[:, 2]
            @test A[2020M1:2020M12, :] ≈ dA[1:12, :]
            @test A[2022M1:2022M12, :] ≈ dA[25:36, :]
            @test A[2021M1:2021M12, :a] ≈ ones(12)
            @test A[2021M1:2021M12, :c] ≈ ones(12)
        end

        # https://github.com/bankofcanada/TimeSeriesEcon.jl/pull/49
        # `sd[var] .= ...` should work the same as `sd[:,var] .= ...`
        rand!(sd)
        @test (sd[nms] = dta; sd.values == dta)
        @test (sd[:a] .= dta2[:, 1]; sd[:b] = dta2[:, 2]; sd.values == dta2)
        @test (sd[nms] .= dta; sd.values == dta)
        @test (sd[nms] = dta2; sd.values == dta2)
        @test (sd[nms] = sd2; sd[rangeof(sd2), :].values == sd2.values)
        rand!(sd)
        @test (sd[nms] .= sd2; sd[rangeof(sd2), :].values == sd2.values)
    end
end

@testset "MV views" begin
    x = MVTSeries(2000Q1, (:a, :b, :c), rand(10, 3))

    # first MIT, second list
    @test x[2000Q1, (:a, :b)] == view(x, 2000Q1, (:a, :b))
    @test view(x, 2000Q1, (:a, :b)) isa SubArray
    # first MIT, second :
    @test x[2001Q1, :] == view(x, 2001Q1, :)
    @test view(x, 2001Q1, :) isa SubArray

    # first MIT-range, second name
    @test x[2000Q1:2001Q4, :b] isa TSeries
    @test x[2000Q1:2001Q4, :b].values isa Vector
    @test view(x, 2000Q1:2001Q4, :b) isa TSeries
    @test view(x, 2000Q1:2001Q4, :b).values isa SubArray
    @test x[2000Q1:2001Q4, :b] == view(x, 2000Q1:2001Q4, :b)

    # first :, second name
    @test x[:, :c] isa TSeries
    # @test x[:, :c].values isa Vector
    @test view(x, :, :c) isa TSeries
    @test view(x, :, :c).values isa SubArray
    @test x[:, :c] == view(x, :, :c)

    # first MIT-range, second list
    @test x[2000Q2:2001Q3, (:a, :c)] isa MVTSeries
    @test x[2000Q2:2001Q3, (:a, :c)].values isa Matrix
    @test view(x, 2000Q2:2001Q3, (:a, :c)) isa MVTSeries
    @test view(x, 2000Q2:2001Q3, (:a, :c)).values isa SubArray
    @test x[2000Q2:2001Q3, (:a, :c)] == view(x, 2000Q2:2001Q3, (:a, :c))

    # first MIT-range, second :
    @test x[2000Q1:2001Q3, :] isa MVTSeries
    @test x[2000Q1:2001Q3, :].values isa Matrix
    @test view(x, 2000Q1:2001Q3, :) isa MVTSeries
    @test view(x, 2000Q1:2001Q3, :).values isa SubArray
    @test x[2000Q1:2001Q3, :] == view(x, 2000Q1:2001Q3, :)

    # first :, second list
    @test x[:, (:b, :a)] isa MVTSeries
    @test x[:, (:b, :a)].values isa Matrix
    @test view(x, :, (:b, :a)) isa MVTSeries
    @test view(x, :, (:b, :a)).values isa SubArray
    @test x[:, (:b, :a)] == view(x, :, (:b, :a))

    # first :, second :
    @test x[:, :] isa MVTSeries
    @test x[:, :].values isa Matrix
    @test view(x, :, :) isa MVTSeries
    @test view(x, :, :).values isa SubArray
    @test x[:, :] == view(x, :, :)
end

@testset "MV bool access" begin
    A = MVTSeries(2000Y, collect('a' .+ (0:7)), rand(12, 8))
    B = copy(A.values)
    m, n = size(A)

    # access with a Bool vectors that are the same length as the axes of A    
    tf = rand(Bool, m)  # for the rows
    tf2 = rand(Bool, n) # for the columns
    tstf = TSeries(rangeof(A), tf)
    m1 = sum(tf)
    n1 = sum(tf2)

    # getindex
    @test A[tf] == B[tf, :]
    @test A[tf, :] == B[tf, :]
    @test A[tf, (:a, :c)] == B[tf, [1, 3]]
    @test A[tf, tf2] == B[tf, tf2]
    # setindex
    @test (A[tf] = ones(m1, n); B[tf, :] = ones(m1, n); A.values == B)
    @test (A[tf, :] = 2 * ones(m1, n); B[tf, :] = 2 * ones(m1, n); A.values == B)
    @test (A[tf, (:b, :c)] = 3 * ones(m1, 2); B[tf, [2, 3]] = 3 * ones(m1, 2); A.values == B)
    @test (A[tf, tf2] = 4 * ones(m1, n1); B[tf, tf2] = 4 * ones(m1, n1); A.values == B)
    copyto!(B, copyto!(A, rand(m, n)))
    # view
    @test (v = view(A, tf); v.parent isa Matrix && size(v) == (m1, n) && v == B[tf, :])
    @test (v = view(A, tf, :); v.parent isa Matrix && size(v) == (m1, n) && v == B[tf, :])
    @test (v = view(A, tf, (:a, :d)); v.parent isa Matrix && size(v) == (m1, 2) && v == B[tf, [1, 4]])
    @test (v = view(A, tf, tf2); v.parent isa Matrix && size(v) == (m1, n1) && v == B[tf, tf2])
    # broadcast arithmetic
    tmp = rand(m1, n)
    @test (A[tf] .+ 1 == B[tf, :] .+ 1)
    @test (A[tf] .+ 1tmp == B[tf, :] .+ 1tmp)
    @test (A[tf] .+ 1tmp[1:1, :] == B[tf, :] .+ 1tmp[1:1, :])
    @test (A[tf] .+ 1tmp[:, 1:1] == B[tf, :] .+ 1tmp[:, 1:1])
    @test (A[tf] .+ 1tmp[:, 1] == B[tf, :] .+ 1tmp[:, 1])
    tmp = rand(m1, n)
    @test (A[tf, :] .+ 2 == B[tf, :] .+ 2)
    @test (A[tf, :] .+ 2tmp == B[tf, :] .+ 2tmp)
    @test (A[tf, :] .+ 2tmp[1:1, :] == B[tf, :] .+ 2tmp[1:1, :])
    @test (A[tf, :] .+ 2tmp[:, 1:1] == B[tf, :] .+ 2tmp[:, 1:1])
    @test (A[tf, :] .+ 2tmp[:, 1] == B[tf, :] .+ 2tmp[:, 1])
    tmp = rand(m1, 3)
    @test (A[tf, (:a, :d, :c)] .+ 3 == B[tf, [1, 4, 3]] .+ 3)
    @test (A[tf, (:a, :d, :c)] .+ 3tmp == B[tf, [1, 4, 3]] .+ 3tmp)
    @test (A[tf, (:a, :d, :c)] .+ 3tmp[1:1, :] == B[tf, [1, 4, 3]] .+ 3tmp[1:1, :])
    @test (A[tf, (:a, :d, :c)] .+ 3tmp[:, 1:1] == B[tf, [1, 4, 3]] .+ 3tmp[:, 1:1])
    @test (A[tf, (:a, :d, :c)] .+ 3tmp[:, 1] == B[tf, [1, 4, 3]] .+ 3tmp[:, 1])
    tmp = rand(m1, n1)
    @test (A[tf, tf2] .+ 4 == B[tf, tf2] .+ 4)
    @test (A[tf, tf2] .+ 4tmp == B[tf, tf2] .+ 4tmp)
    @test (A[tf, tf2] .+ 4tmp[1:1, :] == B[tf, tf2] .+ 4tmp[1:1, :])
    @test (A[tf, tf2] .+ 4tmp[:, 1:1] == B[tf, tf2] .+ 4tmp[:, 1:1])
    @test (A[tf, tf2] .+ 4tmp[:, 1] == B[tf, tf2] .+ 4tmp[:, 1])
    # broadcast assignment
    copyto!(B, copyto!(A, rand(m, n)))
    tmp = rand(m1, n)
    @test (A[tf] .+= 1; B[tf, :] .+= 1; A.values == B)
    @test (A[tf] .+= 1tmp; B[tf, :] .+= 1tmp; A.values == B)
    @test (A[tf] .+= 1tmp[1:1, :]; B[tf, :] .+= 1tmp[1:1, :]; A.values == B)
    @test (A[tf] .+= 1tmp[:, 1:1]; B[tf, :] .+= 1tmp[:, 1:1]; A.values == B)
    @test (A[tf] .+= 1tmp[:, 1]; B[tf, :] .+= 1tmp[:, 1]; A.values == B)
    tmp = rand(m1, n)
    @test (A[tf, :] .+= 2; B[tf, :] .+= 2; A.values == B)
    @test (A[tf, :] .+= 2tmp; B[tf, :] .+= 2tmp; A.values == B)
    @test (A[tf, :] .+= 2tmp[1:1, :]; B[tf, :] .+= 2tmp[1:1, :]; A.values == B)
    @test (A[tf, :] .+= 2tmp[:, 1:1]; B[tf, :] .+= 2tmp[:, 1:1]; A.values == B)
    @test (A[tf, :] .+= 2tmp[:, 1]; B[tf, :] .+= 2tmp[:, 1]; A.values == B)
    tmp = rand(m1, 3)
    @test (A[tf, (:d, :a, :c)] .+= 3; B[tf, [4, 1, 3]] .+= 3; A.values == B)
    @test (A[tf, (:d, :a, :c)] .+= 3tmp; B[tf, [4, 1, 3]] .+= 3tmp; A.values == B)
    @test (A[tf, (:d, :a, :c)] .+= 3tmp[1:1, :]; B[tf, [4, 1, 3]] .+= 3tmp[1:1, :]; A.values == B)
    @test (A[tf, (:d, :a, :c)] .+= 3tmp[:, 1:1]; B[tf, [4, 1, 3]] .+= 3tmp[:, 1:1]; A.values == B)
    @test (A[tf, (:d, :a, :c)] .+= 3tmp[:, 1]; B[tf, [4, 1, 3]] .+= 3tmp[:, 1]; A.values == B)
    tmp = rand(m1, n1)
    @test (A[tf, tf2] .+= 4; B[tf, tf2] .+= 4; A.values == B)
    @test (A[tf, tf2] .+= 4tmp; B[tf, tf2] .+= 4tmp; A.values == B)
    @test (A[tf, tf2] .+= 4tmp[1:1, :]; B[tf, tf2] .+= 4tmp[1:1, :]; A.values == B)
    @test (A[tf, tf2] .+= 4tmp[:, 1:1]; B[tf, tf2] .+= 4tmp[:, 1:1]; A.values == B)
    @test (A[tf, tf2] .+= 4tmp[:, 1]; B[tf, tf2] .+= 4tmp[:, 1]; A.values == B)

    # access with a single bool vector that is the same length as all of A
    sg = rand(Bool, length(A))
    k = sum(sg)
    # getindex
    @test A[sg] == B[sg]
    # setindex
    tmp = rand(k)
    @test (A[sg] = 1tmp; B[sg] = 1tmp; A.values == B)
    # view
    @test (q = view(A, sg); q.parent isa Vector && size(q) == (k,) && q == B[sg])
    # broadcast arithmetic
    @test (A[sg] .* 2 ≈ B[sg] .* 2)
    # broadcast assignment
    tmp = rand(k)
    @test (A[sg] .*= 3; B[sg] .*= 3; A.values == B)
    @test (A[sg] .*= 4tmp; B[sg] .*= 4tmp; A.values == B)
end

@testset "MVTSeries show" begin
    # test the case when column labels are longer than the numbers
    let io = IOBuffer(), x = MVTSeries(1U, (:verylongandsuperboringnameitellya, :anothersuperlongnamethisisridiculous, :a), rand(20, 3) .* 100)
        show(io, x)
        lines = readlines(seek(io, 0))
        # labels longer than 10 character are abbreviated with '…' at the end
        @test length(split(lines[2], '…')) == 3
    end
    let io = IOBuffer(), x = MVTSeries(1U, (:alpha, :beta), zeros(24, 2))
        show(io, x)
        lines = readlines(seek(io, 0))
        lens = length.(lines)
        # when labels are longer than the numbers, the entire column stretches to fit the label
        @test lens[2] == lens[3]
    end
    nrow = 24
    letters = Symbol.(['a':'z'...])
    for (nlines, fd) in zip([3, 4, 5, 6, 7, 8, 22, 23, 24, 25, 26, 30], Iterators.cycle((2010Q1, 2010M1, 2010Y, 1U)))
        for ncol in [2, 5, 10, 20]
            # display size if nlines × 80
            # data size is nrow × ncol
            # when printing data there are two header lines - summary and column names
            io = IOBuffer()
            x = MVTSeries(fd, tuple(letters[1:ncol]...), rand(nrow, ncol))
            show(IOContext(io, :displaysize => (nlines, 80)), MIME"text/plain"(), x)
            lines = readlines(seek(io, 0))
            @test length(lines) == max(3, min(nrow + 2, nlines - 3))
            @test maximum(length, lines) <= 80
            io = IOBuffer()
            show(IOContext(io, :limit => false), x)
            lines = readlines(seek(io, 0))
            @test length(lines) == nrow + 2
        end
    end
end

@testset "MV bcast" begin

    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))
    t = TSeries(20Q1, ones(10))
    s = [2.0 3.0]

    # we can do dot operations with scalars
    @test (x .+ 2; true)

    # we can do dot operations with multiple MVTSeries of the same dimension
    @test x .+ 2x ./ 2 == 2x

    # we can do dot operations with multiple MVTSeries of different ranges
    @test begin
        q = x .+ x[begin+1:end-1, :] ./ 2
        q == 1.5x[begin+1:end-1, :]
    end

    # we can do dot operations with matrices of identical size
    @test x .+ 3 .* x.values == 4x

    # with matrixes of wrong size we get a DimensionMismatch
    @test_throws DimensionMismatch x .+ x.values[begin+1:end-1, :]
    @test_throws DimensionMismatch x .+ x.values[:, [1, 1, 1]]

    @test x .+ t.values == (x .+ 1)
    @test x .+ t == (x .+ 1)
    #
    @test x .+ 1 .* 3 == (x .+ 3)
    @test 1 .* 3 .+ x == (x .+ 3)
    @test x .+ t.values .* 3 == (x .+ 3)
    @test t.values .* 3 .+ x == (x .+ 3)
    @test x .+ t .* 3 == (x .+ 3)
    @test t .* 3 .+ x == (x .+ 3)

    # we can .^ correctly
    @test isa(x .^ 2, typeof(x))
    @test (x .^ 2).values == x.values .^ 2

    @test (z = (x .+ s); z isa typeof(x) && axes(z) == axes(x))
    @test (x .+ s).values == (x.values .+ s)

    # test .op= assignments
    let z = copy(x)
        z .= 1
        @test z isa typeof(x) && axes(x) == axes(z)
        @test all(z.values .== 1)

        z .= randn(size(z)...)
        @test z isa typeof(x) && axes(x) == axes(z)
        @test !all(z.values .== 1)
    end

    let z = copy(x)
        z .+= t
        @test z isa typeof(x) && axes(x) == axes(z)
        @test all(z.values .== x.values .+ 1)
    end

    let z = copy(x)
        z .+= t.values
        @test z isa typeof(x) && axes(x) == axes(z)
        @test all(z.values .== x.values .+ 1)
    end

    let z = copy(x)
        z .+= s
        @test z isa typeof(x) && axes(x) == axes(z)
        @test z.values == x.values .+ s
    end

    # test .= within a range
    q = MVTSeries(20Q1, collect("abcd"), randn(12, 4))
    let p = copy(q)
        p .= TSeries(21Q1, ones(4))
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q1:21Q4, :].values == ones(4, 4)
    end

    let p = copy(q)
        p .= MVTSeries(21Q1, :b, ones(4))
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q1:21Q4, (:a, :c, :d)] == q[21Q1:21Q4, (:a, :c, :d)]
        @test p[21Q1:21Q4, :b].values == ones(4)
    end

    let p = copy(q)
        p[:, :b] .= TSeries(21Q1:21Q4, 1.0)
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q1:21Q4, (:a, :c, :d)] == q[21Q1:21Q4, (:a, :c, :d)]
        @test p[21Q1:21Q4, :b].values == ones(4)
    end

    let p = copy(q)
        p[21Q1:21Q4, :b] .= TSeries(20Q1:22Q4, 1.0)
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q1:21Q4, (:a, :c, :d)] == q[21Q1:21Q4, (:a, :c, :d)]
        @test p[21Q1:21Q4, :b].values == ones(4)
    end

    let p = copy(q)
        p[21Q1:21Q4, :b] .+= TSeries(20Q1:22Q4, 1.0)
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q1:21Q4, (:a, :c, :d)] == q[21Q1:21Q4, (:a, :c, :d)]
        @test p[21Q1:21Q4, :b] == q[21Q1:21Q4, :b] .+ 1
    end

    let p = copy(q)
        p[21Q1, (:b, :d)] .+= 1.0
        p[21Q2, (:b, :d)] .+= [1.0, 1.0]
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q3:21Q4, :] == q[21Q3:21Q4, :]
        @test p[21Q1:21Q2, (:a, :c)] == q[21Q1:21Q2, (:a, :c)]
        @test p[21Q1:21Q2, (:b, :d)] == q[21Q1:21Q2, (:b, :d)] .+ 1
    end

    let p = copy(q)
        @test_throws DimensionMismatch p[21Q1:21Q4, (:b, :d)] .= [4, 5]
        p[21Q1:21Q4, (:b, :d)] .= [4 5]
        @test p[20Q1:20Q4, :] == q[20Q1:20Q4, :]
        @test p[22Q1:22Q4, :] == q[22Q1:22Q4, :]
        @test p[21Q1:21Q4, (:a, :c)] == q[21Q1:21Q4, (:a, :c)]
        @test p[21Q1:21Q4, :b].values == 4ones(4)
        @test p[21Q1:21Q4, :d].values == 5ones(4)
    end

    # additional test for code coverage
    x2 = MVTSeries(20Q1, (:a, :b), [collect(1:10) collect(11:20)])
    x2_monthly = MVTSeries(20M1, (:a, :b), [collect(1:10) collect(11:20)])
    x3 = MVTSeries(20Q1, (:a, :b), [collect(21:30) collect(31:40)])
    # x2 = MVTSeries(20Q1, (:a, :b), rand(10, 2))
    t2 = TSeries(20Q1, ones(10))
    t_monthly = TSeries(20M1, ones(10))
    s2 = [2.0 3.0]

    @test (x2 .+ t2).values == x2.values .+ t2.values
    @test (x2.values .+ t2).values == x2.a.values .+ t2.values
    @test (x2 .+ t2.values).values == x2.values .+ t2.values
    @test (t2 .+ x2).values == x2.values .+ t2.values
    @test (t2.values .+ x2).values == x2.values .+ t2.values
    @test (t2 .+ x2.values).values == (t2.values.+x2.values)[:, 1]
    @test (x2 .+ x3).values == x2.values .+ x3.values
    @test_throws ArgumentError x2 .+ t_monthly
    @test_throws ArgumentError x2 .+ x2_monthly

    # when no columns overlap we get an MVTSeries with no variables
    @test x2 .+ MVTSeries(20Q1, (:c, :d), [collect(1:10) collect(11:20)]) isa MVTSeries
    @test collect(keys(x2 .+ MVTSeries(20Q1, (:c, :d), [collect(1:10) collect(11:20)]))) == Symbol[]

    # when some columns overlap we get the intersection
    @test x2 .+ MVTSeries(20Q1, (:b, :d), [collect(1:10) collect(11:20)]) isa MVTSeries
    @test collect(keys(x2 .+ MVTSeries(20Q1, (:b, :d), [collect(1:10) collect(11:20)]))) == [:b]

    # when ranges partially overlap we get the intersection
    @test rangeof(x2 .+ MVTSeries(20Q4, (:a, :b), [collect(1:10) collect(11:20)])) == 20Q4:22Q2
    @test rangeof(MVTSeries(20Q4, (:a, :b), [collect(1:10) collect(11:20)]) .+ x2) == 20Q4:22Q2

    # when ranges don't overlap we get a TSeries with a broken range
    @test rangeof(x2 .+ MVTSeries(30Q1, (:a, :b), [collect(1:10) collect(11:20)])) == 30Q1:29Q4



    bcStyle = TimeSeriesEcon.MVTSeriesStyle{Quarterly{3}}()
    @test Base.Broadcast.BroadcastStyle(bcStyle, TimeSeriesEcon.MVTSeriesStyle{Quarterly{3}}()) == bcStyle

    b_casted = Base.Broadcast.Broadcasted{TimeSeriesEcon.MVTSeriesStyle{Monthly}}(Monthly, (1,))
    @test_throws DimensionMismatch Base.similar(b_casted, Float64)

    @test 1U:4U isa TimeSeriesEcon._MVTSAxes1
    @test (:a,) isa TimeSeriesEcon._MVTSAxes2
    @test (1U:4U, (:a,)) isa TimeSeriesEcon._MVTSAxesType
    @test Base.Broadcast._eachindex((1U:4U, (:a,))) == CartesianIndices((4, 1))

    # check broadcast shape (this seems a little broken)
    axes1 = (1U:4U, (:a,))
    axes2 = (5U:8U, (:b,))
    axes3 = (1U:8U, (:b,))
    x_axes1 = MVTSeries(1U:4U; a=collect(1:4))
    x_axes2 = MVTSeries(5U:8U; a=collect(1:4))
    x_axes3 = MVTSeries(1U:8U; a=collect(1:8))
    x_axes4 = MVTSeries(1U:4U; a=collect(1:4), b=collect(5:8))
    # TODO: should these throw errors?
    @test x_axes1 + x_axes2 isa MVTSeries # should maybe throw an error?
    @test x_axes2 + x_axes3 isa MVTSeries # should maybe throw an error?
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape(axes1, axes2)
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape(axes2, axes3)
    @test Base.Broadcast.check_broadcast_shape(axes3, axes2) === nothing

    @test Base.Broadcast.check_broadcast_shape(axes(x_axes1), axes(TSeries(2U:3U))) === nothing
    @test x_axes1 .+ TSeries(2U:3U, collect(1:2)) isa MVTSeries
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape(axes(x_axes1), axes(TSeries(2U:5U)))
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape(axes(TSeries(2U:5U)), axes(x_axes1))
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape(axes(x_axes4), axes(TSeries(2U:5U, collect(1:4))))
    @test_throws DimensionMismatch Base.Broadcast.check_broadcast_shape(axes(x_axes1), (1U:4U, 1U:4U)) # TSeriesAxesType should have length 1
    @test Base.Broadcast.check_broadcast_shape((1:4,), axes(x_axes1)) === nothing
    # TODO: should these throw errors?
    @test x_axes1 .+ TSeries(2U:5U, collect(1:4)) isa MVTSeries #should maybe throw an error?
    @test TSeries(2U:5U, collect(1:4)) .+ x_axes1 isa MVTSeries #should maybe throw an error?
    @test TSeries(2U:5U, collect(1:4)) .+ x_axes4 isa MVTSeries #should maybe throw an error?
    @test Base.Broadcast.check_broadcast_shape(axes1, ()) === nothing # should maybe throw an error

    # preprocess
    extruded = [21 31
        22 32
        23 33
        24 34
        25 35
        26 36
        27 37
        28 38
        29 39
        30 40]
    Base.Broadcast.preprocess(x2, x3).x == extruded
    Base.Broadcast.preprocess(x2, x3).keeps == (true, true)
    Base.Broadcast.preprocess(x2, x3).defaults == (1, 1)
    @test Base.Broadcast.preprocess(x2, x3.values).x == extruded
    Base.Broadcast.preprocess(x2, x3.values).keeps == (true, true)
    Base.Broadcast.preprocess(x2, x3.values).defaults == (1, 1)
    @test Base.Broadcast.preprocess(x2, t2).x == ones(10)
    @test Base.Broadcast.preprocess(x2, t2).keeps == (true,)
    @test Base.Broadcast.preprocess(x2, t2).defaults == (1,)
    @test Base.Broadcast.preprocess(x2, 2.3) == 2.3

    mat3 = [7.0 7.0; 2.0 12.0; 7.0 7.0; 4.0 14.0; 7.0 7.0; 6.0 16.0; 7.0 7.0; 8.0 18.0; 7.0 7.0; 10.0 20.0]

    ##################################################################################################
    # broadcasting assignment of a Number using StepRange index
    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[20Q1:2:22Q2] .= 7.0
    @test x3.values == mat3
    x3[20Q1:2:22Q2] .+= 0.0
    @test x3.values == mat3

    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[1:2:10, :] .= 7.0
    @test x3.values == mat3
    x3[1:2:10, :] .+= 0.0
    @test x3.values == mat3

    # direct assignment of a Matrix using StepRange index
    mat4 = ones(5, 2) .* 7
    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[20Q1:2:22Q2] = mat4
    @test x3.values == mat3
    x3[20Q1:2:22Q2] += 0.0 * mat4
    @test x3.values == mat3

    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[1:2:10, :] = mat4
    @test x3.values == mat3
    x3[1:2:10, :] += 0.0 * mat4
    @test x3.values == mat3

    # broadcasting assignment of a Matrix using StepRange index
    mat4 = ones(5, 2) .* 7
    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[20Q1:2:22Q2] .= mat4
    @test x3.values == mat3
    x3[20Q1:2:22Q2] .+= 0.0 * mat4
    @test x3.values == mat3

    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[1:2:10, :] .= mat4
    @test x3.values == mat3
    x3[1:2:10, :] .+= 0.0 * mat4
    @test x3.values == mat3

    # direct assignment of a Matrix using Vector index
    ind = collect(20Q1:2:22Q2)

    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[ind] .= 7.0
    @test x3.values == mat3
    x3[ind] .+= 0.0
    @test x3.values == mat3

    mat4 = ones(5, 2) .* 7
    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[ind] = mat4
    @test x3.values == mat3
    x3[ind] += 0.0 * mat4
    @test x3.values == mat3

    x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
    x3[ind] .= mat4
    @test x3.values == mat3
    x3[ind] .+= 0.0 * mat4
    @test x3.values == mat3


    ##################################################################################################
    # repeat, with second index (:)

    for first_index in (20Q1:2:22Q2, collect(20Q1:2:22Q2), TSeries(20Q1, (1:10) .% 2 .== 1), (1:10) .% 2 .== 1),
        second_index in ((:,), ([:a, :b],), ())

        x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
        x3[first_index, second_index...] .= 7.0
        @test x3.values == mat3
        x3[first_index, second_index...] .+= 0.0
        @test x3.values == mat3

        # direct assignment of a Matrix using StepRange index
        mat4 = ones(5, 2) .* 7
        x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
        x3[first_index, second_index...] = mat4
        @test x3.values == mat3
        x3[first_index, second_index...] += 0.0 * mat4
        @test x3.values == mat3

        # broadcasting assignment of a Matrix using StepRange index
        mat4 = ones(5, 2) .* 7
        x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
        x3[first_index, second_index...] .= mat4
        @test x3.values == mat3
        x3[first_index, second_index...] .+= 0.0 * mat4
        @test x3.values == mat3

        first_index! = (eltype(first_index) == Bool) ? (.!first_index) : (first_index .+ 1)

        x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
        x7 = fill!(similar(x3), 7)
        x7[first_index!, second_index...] = x3
        @test x7.values == mat3

        x3 = MVTSeries(20Q1, (:a, :b), [collect(1.0:10) collect(11.0:20)])
        x7 = fill!(similar(x3), 7)
        x7[first_index!, second_index...] .= x3
        @test x7.values == mat3
    end

    ##################################################################################################

    mat5 = [7.0 11.0 7.0; 2.0 12.0 22.0; 7.0 13.0 7.0; 4.0 14.0 24.0; 7.0 15.0 7.0; 6.0 16.0 26.0; 7.0 17.0 7.0; 8.0 18.0 28.0; 7.0 19.0 7.0; 10.0 20.0 30.0]
    for first_index in (20Q1:2:22Q2, collect(20Q1:2:22Q2), TSeries(20Q1, (1:10) .% 2 .== 1), (1:10) .% 2 .== 1),
        second_index in ([:a, :c], (:a, :c))

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x3[first_index, second_index] .= 7.0
        @test x3.values == mat5
        x3[first_index, second_index] .+= 0.0
        @test x3.values == mat5

        rng = rangeof(x3)
        nf = eltype(first_index) <: Bool ? sum(first_index) : length(first_index)
        ns = length(second_index)

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x3[first_index, second_index] = 7.0 * ones(nf, ns)
        @test x3.values == mat5
        x3[first_index, second_index] += zeros(nf, ns)
        @test x3.values == mat5

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x3[first_index, second_index] .= 7.0 * ones(nf, ns)
        @test x3.values == mat5
        x3[first_index, second_index] .+= zeros(nf, ns)
        @test x3.values == mat5

        first_index! = (eltype(first_index) == Bool) ? (.!first_index) : (first_index .+ 1)

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x7 = MVTSeries(rng, colnames(x3), 7.0)
        x8 = copyto!(MVTSeries(first(rng)-4:last(rng)+4, colnames(x3), NaN), x3)
        x7[first_index!, second_index] = x8
        x7[rng, :b] = x8
        @test x7.values == mat5

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x7 = MVTSeries(rng, colnames(x3), 7.0)
        x8 = copyto!(MVTSeries(first(rng)-4:last(rng)+4, colnames(x3), NaN), x3)
        x7[first_index!, second_index] = x8
        x7[rng, :b] = x8.b
        @test x7.values == mat5

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x7 = MVTSeries(rng, colnames(x3), 7.0)
        x8 = copyto!(MVTSeries(first(rng)-4:last(rng)+4, colnames(x3), NaN), x3)
        x7[first_index!, second_index] .= x8
        x7[rng, :b] .= x8
        @test x7.values == mat5

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        x7 = MVTSeries(rng, colnames(x3), 7.0)
        x8 = copyto!(MVTSeries(first(rng)-4:last(rng)+4, colnames(x3), NaN), x3)
        x7[first_index!, second_index] .= x8
        x7[rng, :b] .= x8.b
        @test x7.values == mat5

        x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
        for dims in ((1, ns), (nf, 1), (nf,), (nf, ns))
            r7 = 7.0 * ones(dims)
            x8 = copyto!(MVTSeries(first(rng)-4:last(rng)+4, colnames(x3), NaN), x3)
            if eltype(first_index) == Bool && !isa(first_index, TSeries) && length(first_index) != size(x8, 1)
                @test_throws BoundsError x8[first_index, second_index] .= r7
            else
                x8[first_index, second_index] .= r7
                @test x8[rng, :].values == mat5
                x8[first_index, second_index] .+= zeros(dims)
                @test x8[rng, :].values == mat5
            end
        end

    end

    x3 = MVTSeries(20Q1, (:a, :b, :c), [collect(1.0:10) collect(11.0:20) collect(21.0:30)])
    x3[1:2:10, [1, 3]] .= 7.0
    @test x3.values == mat5

    for F = (Quarterly{3}, Monthly, HalfYearly{2})
        N = ppy(F)
        dA = rand(3N, 3)
        start = MIT{F}(2020, 1)
        A = MVTSeries(start, (:a, :b, :c), copy(dA))
        B = MVTSeries(start, (:a, :c), ones(3N, 2))
        foo = N+1:2N
        sfoo = rangeof(A)[foo]
        _!foo = setdiff(1:size(dA, 1), foo)
        _!sfoo = setdiff(rangeof(A), sfoo)
        @test (A[sfoo] .= B; true)
        @test A[sfoo, :a] ≈ ones(N)
        @test A[sfoo, :b] ≈ dA[foo, 2]
        @test A[sfoo, :c] ≈ ones(N)
        @test A[_!sfoo, :] ≈ dA[_!foo, :]

        C = MVTSeries(sfoo, (:a, :b), 7 .+ rand(length(foo), 2))
        Ctests = (v=[:a, :b], w=setdiff([:a, :b], v)) -> begin
            isempty(v) || @test A[sfoo, v] ≈ C.values[:, indexin(v, [:a, :b])]
            isempty(w) || @test A[sfoo, w] ≈ dA[foo, indexin(w, [:a, :b, :c])]
            @test A[sfoo, :c] ≈ dA[foo, 3]
            @test A[_!sfoo, :] ≈ dA[_!foo, :]
        end

        # explicit variables throw BoundsError if missing from the rhs
        @test_throws BoundsError A[[:a, :b, :c]] .= C

        A .= dA
        A[[:a, :b]] .= C
        Ctests()
        A .= dA
        A .= C
        Ctests()
        A .= dA
        A[:, :] .= C
        Ctests()
        A .= dA
        A[:, [:a, :b]] .= C
        Ctests()
        A .= dA
        A[:, :a] .= C
        Ctests([:a])
        A .= dA
        A[:, [:b]] .= C
        Ctests([:b])

        # explicit ranges throw BoundsError if missing from the rhs
        @test_throws BoundsError A[-2 .+ sfoo, [:a, :c]] .= TSeries(sfoo, 16)
        @test_throws BoundsError A[rangeof(A), [:a, :c]] .= TSeries(sfoo, 16)
        A .= dA
        A[[:a, :c]] .= TSeries(sfoo, 16)
        @test (A[_!sfoo, :] ≈ dA[_!foo,:])
        @test all(A[sfoo, [:a, :c]] .== 16)
        A .= dA
        A[:, [:a, :c]] .= TSeries(sfoo, 16)
        @test (A[_!sfoo, :] ≈ dA[_!foo,:])
        @test all(A[sfoo, [:a, :c]] .== 16)
        A .= dA
        A[sfoo, :] .= TSeries(sfoo, 16)
        @test (A[_!sfoo, :] ≈ dA[_!foo,:])
        @test all(A[sfoo, :] .== 16)
        A .= dA
        A[:, :] .= TSeries(sfoo, 16)
        @test (A[_!sfoo, :] ≈ dA[_!foo,:])
        @test all(A[sfoo, :] .== 16)

    end

end

@testset "MVTSeries math" begin
    #promote shape
    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))
    y = MVTSeries(21Q1, (:a, :b), rand(10, 2))
    y2 = MVTSeries(21Q1, (:b, :c), rand(10, 2))

    @test promote_shape(x, y)[1] == 21Q1:22Q2
    @test length(promote_shape(x, y)[1]) == 6
    @test promote_shape(x, y)[2] == [:a, :b]
    @test_throws DimensionMismatch promote_shape(x, y2)

    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))
    y = MVTSeries(21Q1, (:a, :b), rand(10, 2))
    @test promote_shape(x, y.values) == promote_shape(x.values, y.values)
    @test promote_shape(x.values, y) == promote_shape(x.values, y.values)

    @test LinearIndices(x) == LinearIndices(x.values)
    @test LinearIndices(x)[:, 1] == collect(1:10)
    @test LinearIndices(x)[:, 2] == collect(11:20)

    ## multiplication and division
    x2 = MVTSeries(1U:3U, (:a, :b))
    x2.a = collect(1:3)
    x2.b = collect(4:6)

    x3 = 2 * x2
    @test x3.a.values == [2, 4, 6]
    @test x3.b.values == [8, 10, 12]

    x4 = x2 * 2
    @test x4.a.values == [2, 4, 6]
    @test x4.b.values == [8, 10, 12]

    x5 = x2 / 2
    @test x5.a.values == [0.5, 1, 3 / 2]
    @test x5.b.values == [2, 5 / 2, 3]

    x6 = 2 \ x2
    @test x6.a.values == [0.5, 1, 3 / 2]
    @test x6.b.values == [2, 5 / 2, 3]

    y3 = MVTSeries(1U:3U, (:a, :b))
    y3.a = collect(7:9)
    y3.b = collect(10:12)

    x7 = x2 + y3
    @test x7.a.values == [8, 10, 12]
    @test x7.b.values == [14, 16, 18]

    y4 = MVTSeries(2U:4U, (:a, :b))
    y4.a = collect(7:9)
    y4.b = collect(10:12)

    x8 = x2 + y4
    @test rangeof(x8) == 2U:3U
    @test x8.a.values == [9, 11]
    @test x8.b.values == [15, 17]

    x9 = y3 - x2
    @test x9.a.values == [6, 6, 6]
    @test x9.b.values == [6, 6, 6]

    x10 = x2 - y4
    @test rangeof(x10) == 2U:3U
    @test x10.a.values == [-5, -5]
    @test x10.b.values == [-5, -5]


    @test_throws DimensionMismatch x2 + y2
    @test_throws DimensionMismatch x2 - y2

    @test sum(x2) == 21
    @test minimum(x2) == 1
    @test maximum(x2) == 6
    @test prod(x2) == factorial(6)

    addSix = (x) -> x + 6
    @test sum(addSix, x2) == sum(y3)
    @test minimum(addSix, x2) == minimum(y3)
    @test maximum(addSix, x2) == maximum(y3)
    @test prod(addSix, x2) == prod(y3)

    @test size(sum(x2, dims=1)) == (1, 2)
    @test sum(x2, dims=1)[1] == 6
    @test sum(x2, dims=1)[2] == 15
    for func in (:sum, :prod, :minimum, :maximum)
        @eval begin
            @test size($func($x2, dims=1)) == (1, 2)

            @test size($func($x2, dims=2)) == (3,)
            @test $func($x2, dims=2) isa TSeries
            @test rangeof($func($x2, dims=2)) == 1U:3U

            @test size($func($x2, dims=3)) == (3, 2)
            @test $func($x2, dims=3) == $(x2.values)

            # higher dimension go to the highest available
            @test $func($x2, dims=10) == $func($x2, dims=3)

            @test $func($addSix, $x2) == $func($y3)
            for d in (1,2,3)
                @test $func($addSix, $x2, dims=d) == $func($y3, dims=d)
            end
        end
    end

    #reshape
    @test reshape(x2, 6) == collect(1:6) # this also displays an error message
    @test reshape(x2, 3, 2) == x2
    @test_throws DimensionMismatch reshape(x2, 2)

    # shift, lead, lag
    let x2_orig = MVTSeries(1U:3U, (:a, :b))
        x2_orig.a = collect(1:3)
        x2_orig.b = collect(4:6)
        x2 = copy(x2_orig)

        shifted_x2 = shift(x2, 1)
        @test rangeof(shifted_x2) == 0U:2U
        @test shifted_x2.values == x2.values
        @test rangeof(shifted_x2) == rangeof(shifted_x2.a) == rangeof(shifted_x2.b)

        @test lead(x2) == shift(x2, 1)
        @test rangeof(x2) == rangeof(x2.a) == rangeof(x2.b)
        @test lag(x2) == shift(x2, -1)
        @test rangeof(x2) == rangeof(x2.a) == rangeof(x2.b)

        x2 = copy(x2_orig)
        shift!(x2, 1)
        @test rangeof(x2) == 0U:2U
        @test rangeof(x2) == rangeof(x2.a) == rangeof(x2.b)
        @test x2.values == x2_orig.values

        x2 = copy(x2_orig)
        lead!(x2)
        @test rangeof(x2) == rangeof(x2.a) == rangeof(x2.b)
        @test rangeof(x2) == 0U:2U
        @test x2.values == x2_orig.values

        x2 = copy(x2_orig)
        lag!(x2)
        @test rangeof(x2) == rangeof(x2.a) == rangeof(x2.b)
        @test rangeof(x2) == 2U:4U
        @test x2.values == x2_orig.values



    end

    #diff
    let x2_orig = MVTSeries(1U:3U, (:a, :b))
        x2_orig.a = collect(1:3)
        x2_orig.b = collect(4:6)
        x2 = copy(x2_orig)

        x2_diff = diff(x2)
        @test rangeof(x2_diff) == 2U:3U
        @test x2_diff.a.values == [1, 1]
        @test x2_diff.b.values == [1, 1]

        x2_diff2 = diff(x2, -2)
        @test rangeof(x2_diff2) == 3U:3U
        @test x2_diff2.a.values == [2]
        @test x2_diff2.b.values == [2]
    end

    #cumsum
    let x2_orig = MVTSeries(1U:3U, (:a, :b))
        x2_orig.a = collect(1:3)
        x2_orig.b = collect(4:6)
        x2 = copy(x2_orig)

        x2_cumsum = cumsum(x2, dims=1)
        @test rangeof(x2_cumsum) == 1U:3U
        @test x2_cumsum.a.values == [1, 3, 6]
        @test x2_cumsum.b.values == [4, 9, 15]

        x2_cumsum2 = cumsum(x2, dims=2)
        @test rangeof(x2_cumsum2) == 1U:3U
        @test x2_cumsum2.a.values == [1, 2, 3]
        @test x2_cumsum2.b.values == [5, 7, 9]
    end

    #moving average
    let x = MVTSeries(1U:10U, (:a, :b))
        x.a = collect(1:10)
        x.b = collect(11:20)

        @test moving(x, 1) == x
        @test moving(x.a, 1) == x.a
        @test moving(x.b, 1) == x.b

        x_m4 = moving(x, 4)
        @test rangeof(x_m4) == 4U:10U
        @test x_m4.a.values == collect(4:10) .- 1.5
        @test x_m4.b.values == collect(14:20) .- 1.5

        x_m4_forward = moving(x, -4)
        @test rangeof(x_m4_forward) == 1U:7U
        @test x_m4_forward.a.values == collect(1:7) .+ 1.5
        @test x_m4_forward.b.values == collect(11:17) .+ 1.5

        x_m2 = moving(x, 2)
        @test rangeof(x_m2) == 2U:10U
        @test x_m2.a.values == collect(2:10) .- 0.5
        @test x_m2.b.values == collect(12:20) .- 0.5

        x_m2_forward = moving(x, -2)
        @test rangeof(x_m2_forward) == 1U:9U
        @test x_m2_forward.a.values == collect(1:9) .+ 0.5
        @test moving(x.a, -2) == collect(1:9) .+ 0.5
        @test x_m2_forward.b.values == collect(11:19) .+ 0.5
        @test moving(x.b, -2) == collect(11:19) .+ 0.5

        @test moving(x, -4) == moving_average(x, -4)
        @test 4moving(x, -4) == moving_sum(x, -4)
    end

    #undiff
    let x = MVTSeries(1U:10U, (:a, :b))
        x.a = collect(1:10)
        x.b = collect(11:20)
        @test undiff(diff(x.a), 1U => x.a[1]) == x.a
        @test undiff(diff(x.a), 1U => 1.0) == x.a
        @test undiff(diff(x.a), 2U => 2.0) == x.a[2U:10U]
        @test undiff(diff(x.a), 5U => 5.0) == x.a[2U:10U] # not sure why this is the case
        @test undiff(diff(x), 1U => [1, 11]) == x
        @test undiff(diff(x.a)) == collect(0:9) #first item is assumed to be 0

        x2 = copy(x)
        undiff!(x2.a, diff(x.a * 3); fromdate=6U) ##no effect
        @test x2.a == [1, 2, 3, 4, 5, 6, 9, 12, 15, 18]
        @test x2.b == x.b

        ts1 = copy(x.a)
        ts2 = diff(ts1 .* 3)
        @test ts1 != ts2
        # applied growth rate (+3) applies from the period after fromdate
        undiff!(ts1, ts2, fromdate=6U)
        @test ts1.values == [1, 2, 3, 4, 5, 6, 9, 12, 15, 18]
        # adding the growth rate to an earlier date makes it kick in earlier and changes the series
        undiff!(ts1, ts2, fromdate=4U)
        @test ts1.values == [1, 2, 3, 4, 7, 10, 13, 16, 19, 22]
        # adding the same growth rate to a later date leads the series unchanged
        undiff!(ts1, ts2, fromdate=8U)
        @test ts1.values == [1, 2, 3, 4, 7, 10, 13, 16, 19, 22]

        tt = TSeries(2020Q1, randn(20))
        qq = TSeries(2019Q1:2050Q4, ones)
        @test undiff(tt)[begin+1:end] ≈ cumsum(tt)
        @test undiff(tt, 7) ≈ undiff(tt) .+ 7
        @test undiff(tt, 2020Q1 => 7) ≈ undiff(tt, 2020Q1 => 0.0) .+ 7
        @test undiff(tt, 2020Q1 => tt[begin]) ≈ cumsum(tt)
        @test undiff(tt, 2021Q1 => tt) ≈ cumsum(tt) .- cumsum(tt)[2021Q1] .+ tt[2021Q1]
        @test undiff(tt, 2021Q1 => qq) ≈ cumsum(tt) .- cumsum(tt)[2021Q1] .+ 1

        mm = MVTSeries(rangeof(tt), (:a, :b, :c), tt)
        zz = MVTSeries(rangeof(qq), colnames(mm), qq)
        zz.b .+= 8
        zz.c .+= 28

        @test undiff(mm) == MVTSeries(firstdate(mm)-1:lastdate(mm), colnames(mm), undiff(tt))
        @test undiff(mm, 0.0) == MVTSeries(firstdate(mm)-1:lastdate(mm), colnames(mm), undiff(tt))
        @test undiff(mm, 7) == MVTSeries(firstdate(mm)-1:lastdate(mm), colnames(mm), undiff(tt, 7))
        @test undiff(mm, [1, 8, 28]) ≈ MVTSeries(firstdate(mm)-1:lastdate(mm), colnames(mm), undiff(tt)) .+ [1 8 28]
        @test undiff(mm, 2021Q1 => 0.0)[2021Q1] ≈ [0.0, 0.0, 0.0]
        @test undiff(mm, 2021Q1 => 7.0)[2021Q1] ≈ ([0.0, 0.0, 0.0] .+ 7)
        @test undiff(mm, 2021Q1 => [1, 8, 28])[2021Q1] ≈ [1, 8, 28]
        @test undiff(mm, zz)[firstdate(mm)-1] ≈ [1, 9, 29]
        @test undiff(mm, 2021Q1 => zz)[2021Q1] ≈ [1, 9, 29]
        @test undiff(mm, qq)[2019Q4] ≈ [1, 1, 1]
        @test undiff(mm, 2021Q1 => qq)[2021Q1] ≈ [1, 1, 1]
    end
end

@testset "reducers" begin
    x = MVTSeries(MIT{Monthly}(rand(1:10_000)), collect("abcd"), rand(20, 4))
    for func = (sum, prod, minimum, maximum, mean, median, std, var)
        @test func(x) isa Number
        @test func(x) ≈ func(x.values)
        @test func(x; dims=1) isa Array
        @test func(x; dims=1) ≈ func(x.values; dims=1)
        @test func(x; dims=2) isa TSeries
        @test func(x; dims=2) ≈ let x = func(x.values; dims=2)
            size(x, 2) == 1 ? vec(x) : x
        end
    end
    oper = x -> x + 6
    for func = (sum, prod, minimum, maximum, mean)
        @test func(oper, x) isa Number
        @test func(oper, x) ≈ func(oper, x.values)
        @test func(oper, x; dims=1) isa Array
        @test func(oper, x; dims=1) ≈ func(oper, x.values; dims=1)
        @test func(oper, x; dims=2) isa TSeries
        @test func(oper, x; dims=2) ≈ vec(func(oper, x.values; dims=2))
    end
    pred = x -> x < 0.6
    for func = (any, all)
        @test func(pred, x) isa Number
        @test func(pred, x) ≈ func(pred, x.values)
        @test func(pred, x; dims=1) isa Array
        @test func(pred, x; dims=1) ≈ func(pred, x.values; dims=1)
        @test func(pred, x; dims=2) isa TSeries
        @test func(pred, x; dims=2) ≈ vec(func(pred, x.values; dims=2))
    end

    o1 = fill(NaN, 1)
    o2 = fill(NaN, 1, 1)
    v = fill(NaN, size(x, 1))
    m1 = fill(NaN, size(x, 1), 1)
    m2 = fill(NaN, 1, size(x, 2))
    m12 = fill(NaN, size(x))
    rng = rangeof(x)
    z = TSeries(rng, NaN)
    rng1 = first(rng)-2:last(rng)-2
    z1 = TSeries(rng1, NaN)
    rng2 = first(rng)+3:last(rng)+1
    z2 = TSeries(rng2, NaN)
    rng3 = first(rng)+3:last(rng)-4
    z3 = TSeries(rng3, NaN)
    rng4 = first(rng)-4:last(rng)+3
    z4 = TSeries(rng4, NaN)
    for (func, func!) = ((sum, sum!), (prod, prod!), (maximum, maximum!), (minimum, minimum!))
        for (q, d) = ((o1, (1, 2)), (o2, (1, 2)), (v, 2), (m1, 2), (m2, 1), (m12, ()))
            if q isa AbstractVector
                fill!(q, NaN)
                @test (func!(q, x); q == vec(func(x.values, dims=d)))
                # NOTE: there is a bug in Julia 1.7 in `minimum!(oper, z, x)`, so we skip those tests
                func! isa typeof(minimum!) && (v"1.7" <= VERSION < v"1.8") && continue
                fill!(q, NaN)
                @test (func!(oper, q, x); q == vec(func(oper, x.values, dims=d)))
            else
                fill!(q, NaN)
                @test (func!(q, x); q == func(x.values, dims=d))
                # NOTE: there is a bug in Julia 1.7 in `minimum!(oper, z, x)`, so we skip those tests
                func! isa typeof(minimum!) && (v"1.7" <= VERSION < v"1.8") && continue
                fill!(q, NaN)
                @test (func!(oper, q, x); q == func(oper, x.values, dims=d))
            end
        end
        fill!(z, NaN)
        fill!(z1, NaN)
        fill!(z2, NaN)
        fill!(z3, NaN)
        fill!(z4, NaN)
        @test (func!(z, x); z == func(x, dims=2))
        @test (func!(z1, x); all(isnan, z1.values[1:2]) && z1.values[3:end] == z.values[1:end-2])
        @test (func!(z2, x); all(isnan, z2.values[end:end]) && z2.values[1:end-1] == z.values[4:end])
        @test (func!(z3, x); z3.values == z.values[4:end-4])
        @test (func!(z4, x); all(isnan, z4.values[1:4]) && all(isnan, z4.values[end-2:end]) && z4.values[5:end-3] == z.values)
        # NOTE: there is a bug in Julia 1.7 in `minimum!(oper, z, x)`, so we skip those tests
        func! isa typeof(minimum!) && (v"1.7" <= VERSION < v"1.8") && continue
        fill!(z, NaN)
        fill!(z1, NaN)
        fill!(z2, NaN)
        fill!(z3, NaN)
        fill!(z4, NaN)
        @test (func!(oper, z, x); z == func(oper, x, dims=2))
        @test (func!(oper, z1, x); all(isnan, z1.values[1:2]) && z1.values[3:end] == z.values[1:end-2])
        @test (func!(oper, z2, x); all(isnan, z2.values[end:end]) && z2.values[1:end-1] == z.values[4:end])
        @test (func!(oper, z3, x); z3.values == z.values[4:end-4])
        @test (func!(oper, z4, x); all(isnan, z4.values[1:4]) && all(isnan, z4.values[end-2:end]) && z4.values[5:end-3] == z.values)
    end

    o1 = fill(false, 1)
    o2 = fill(false, 1, 1)
    v = fill(false, size(x, 1))
    m1 = fill(false, size(x, 1), 1)
    m2 = fill(false, 1, size(x, 2))
    m12 = fill(false, size(x))
    rng = rangeof(x)
    z = TSeries(rng, false)
    rng1 = first(rng)-2:last(rng)-2
    z1 = TSeries(rng1, false)
    rng2 = first(rng)+3:last(rng)+1
    z2 = TSeries(rng2, false)
    rng3 = first(rng)+3:last(rng)-4
    z3 = TSeries(rng3, false)
    rng4 = first(rng)-4:last(rng)+3
    z4 = TSeries(rng4, false)
    for (func, func!) = ((any, any!), (all, all!))
        for (q, d) = ((o1, (1, 2)), (o2, (1, 2)), (v, 2), (m1, 2), (m2, 1), (m12, ()))
            if q isa AbstractVector
                fill!(q, false)
                @test (func!(q, pred.(x)); q == vec(func(pred.(x.values), dims=d)))
                fill!(q, false)
                @test (func!(pred, q, x); q == vec(func(pred, x.values, dims=d)))
            else
                fill!(q, false)
                @test (func!(q, pred.(x)); q == func(pred.(x.values), dims=d))
                # NOTE: there is a bug in Julia 1.7 in `minimum!(pred, z, x)`, so we skip those tests
                func! isa typeof(minimum!) && (v"1.7" <= VERSION < v"1.8") && continue
                fill!(q, false)
                @test (func!(pred, q, x); q == func(pred, x.values, dims=d))
            end
        end
        fill!(z, false)
        fill!(z1, false)
        fill!(z2, false)
        fill!(z3, false)
        fill!(z4, false)
        @test (func!(z, pred.(x)); z == func(pred.(x), dims=2))
        @test (func!(z1, pred.(x)); all(!, z1.values[1:2]) && z1.values[3:end] == z.values[1:end-2])
        @test (func!(z2, pred.(x)); all(!, z2.values[end:end]) && z2.values[1:end-1] == z.values[4:end])
        @test (func!(z3, pred.(x)); z3.values == z.values[4:end-4])
        @test (func!(z4, pred.(x)); all(!, z4.values[1:4]) && all(!, z4.values[end-2:end]) && z4.values[5:end-3] == z.values)
        fill!(z, false)
        fill!(z1, false)
        fill!(z2, false)
        fill!(z3, false)
        fill!(z4, false)
        @test (func!(pred, z, x); z == func(pred, x, dims=2))
        @test (func!(pred, z1, x); all(!, z1.values[1:2]) && z1.values[3:end] == z.values[1:end-2])
        @test (func!(pred, z2, x); all(!, z2.values[end:end]) && z2.values[1:end-1] == z.values[4:end])
        @test (func!(pred, z3, x); z3.values == z.values[4:end-4])
        @test (func!(pred, z4, x); all(!, z4.values[1:4]) && all(!, z4.values[end-2:end]) && z4.values[5:end-3] == z.values)
    end
end

using OrderedCollections

@testset "MVTSeries various" begin
    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))

    @test TimeSeriesEcon._c(x) isa OrderedDict
    @test length(TimeSeriesEcon._c(x)) == 2
    @test TimeSeriesEcon._c(x)[:a] isa TSeries

    #reindexing
    ts = MVTSeries(2020Q1, (:y1, :y2), randn(10, 2))
    ts2 = reindex(ts, 2021Q1 => 1U; copy=true)
    @test ts2.y2[3U] == ts.y2[2021Q3]
    @test length(ts2.y2) == 10
    @test ts2.y1[-3U] == ts.y1[2020Q1]


    # make sure copyto! works correctly for MVTSeries 
    a = MVTSeries(firstdate(x)-3:lastdate(x), colnames(x))
    a[begin:begin+2, :] .= TSeries(firstdate(a), Float64[1:3;])
    @test (copyto!(a, x); true)
    for c in colnames(a)
        @test a[c].values == [1, 2, 3, x[c]...]
    end

    # pct, apct, ytypct
    ts = MVTSeries(2020Q1, (:y1, :y2), randn(10, 2))
    @test apct(ts).values ≈ ((ts.values[2:10, :] ./ ts.values[1:9, :]) .^ 4 .- 1) * 100
    @test pct(ts).values ≈ ((ts.values[2:10, :] ./ ts.values[1:9, :]) .- 1) * 100
    @test ytypct(ts).values ≈ ((ts.values[5:10, :] ./ ts.values[1:6, :]) .- 1) * 100

    # mapslices
    ts = MVTSeries(2020Q1, (:y1, :y2), randn(10, 2))
    res1 = mapslices(x -> x .+ 1, ts, dims=1)
    @test res1 isa MVTSeries && axes(res1) == axes(ts)
    @test res1.y1.values == res1.values[:, 1]
    res_matrix = copy(ts.values) .+ 1
    res_mvts = MVTSeries(rangeof(ts), colnames(ts), res_matrix)
    @test mapslices(x -> x .+ 1, ts, dims=1) == res_mvts
    @test mapslices(x -> x .+ 1, ts, dims=2) == res_mvts

    # one-column returns of the same length as ts return a TSeries
    row_means = (ts.values[:, 1] .+ ts.values[:, 2]) ./ 2
    res_tseries = TSeries(rangeof(ts), row_means)
    res2 = mapslices(mean, ts, dims=[2])
    @test res2 isa TSeries && axes(res2) == (rangeof(ts),)
    @test res2 ≈ res_tseries

    # returns that don't fit just return a matrix
    res3 = mapslices(mean, ts, dims=1)
    @test res3 isa Matrix
    @test res3 ≈ mean(ts.values, dims=1)


end

@testset "hcat" begin
    xx = MVTSeries(1U, (:a, :b), rand(15, 2))
    yy = MVTSeries(3U, (:c,), rand(8))
    # make sure hcat works with only one argument
    @test hcat(xx) isa MVTSeries
    @test axes(hcat(xx)) == axes(xx)
    @test hcat(xx) ≈ xx
    @test hcat(xx) !== xx
    # make sure we can pass multiple MVTSeries positional
    @test hcat(xx, yy) isa MVTSeries
    @test axes(hcat(xx, yy)) == (axes(xx, 1), [axes(xx, 2)..., axes(yy, 2)...])
    @test hcat(xx, yy)[axes(xx, 2)] ≈ xx
    # make sure the column order is correct with mix of positions and keyword arguments
    @test hcat(xx, yy; d=rand(15)) isa MVTSeries
    @test axes(hcat(xx, yy; d=rand(15))) == (axes(xx, 1), [axes(xx, 2)..., axes(yy, 2)..., :d])
    @test hcat(xx, yy; d=rand(15))[axes(xx, 2)] ≈ xx
end

@testset "hcat 2" begin
    A = MVTSeries(2000Y, (:a, :b, :c), rand(8, 3))
    B = MVTSeries(1998Y, (:x, :y,), rand(6, 2))
    C = MVTSeries(2002Y, (:m, :n,), rand(11, 2))
    # test for bug that makes the rangeof the result equal to the first, rather than the span of all
    @test rangeof(hcat(A, B)) == rangeof(hcat(B, A))
    # make sure keyword arguments are taken into account when computing the range
    @test rangeof(hcat(A, B; pairs(C)...)) == rangeof(hcat(A, B, C))
end

@testset "Statistics" begin
    # Test MVTS Daily
    bonds_data = [NaN, 0.68, 0.7, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86, 0.81, 0.8, 0.8, 0.83, 0.87, 0.84, 0.81, 0.82, 0.8, 0.82, 0.84, 0.88, 0.91, 0.94, 0.96, 1, 1.01, 0.99, 0.99, 0.99, 1.03, NaN, 1.12, 1.11, 1.14, 1.21, 1.23, 1.26, 1.31, 1.46, 1.35, 1.35, 1.33, 1.4, 1.49, 1.5, 1.53, 1.45, 1.41, 1.43, 1.58, 1.54, 1.56, 1.58, 1.61, 1.59, 1.55, 1.49, 1.47, 1.46, 1.49, 1.53, 1.53, 1.55, 1.51, NaN, 1.56, 1.49, 1.5, 1.46, 1.5, 1.51, 1.5, 1.53, 1.45, 1.53, 1.53, 1.5, 1.52, 1.52, 1.51, 1.53, 1.56, 1.53, 1.56, 1.54, 1.52, 1.53, 1.51, 1.51, 1.49, 1.51, 1.54, 1.59, 1.56, 1.55, 1.57, 1.56, 1.58, 1.54, 1.54, NaN, 1.46, 1.45, 1.49, 1.49, 1.49, 1.5, 1.49, 1.52, 1.46, 1.47, 1.45, 1.41, 1.38, 1.38, 1.39, 1.38, 1.44, 1.4, 1.37, 1.41, 1.4, 1.42, 1.41, 1.45, 1.41, 1.42, 1.39, NaN, 1.37, 1.4, 1.32, 1.29, 1.26, 1.32, 1.32, 1.34, 1.29, 1.26, 1.24, 1.14, 1.17, 1.22, 1.19, 1.21, 1.22, 1.16, 1.17, 1.19, 1.2, NaN, 1.12, 1.13, 1.16, 1.24, 1.25, 1.27, 1.26, 1.25, 1.19, 1.16, 1.15, 1.16, 1.13, 1.14, 1.16, 1.18, 1.25, 1.23, 1.2, 1.18, 1.22, 1.18, 1.15, 1.19, NaN, 1.23, 1.2, 1.17, 1.23, 1.22, 1.17, 1.22, 1.23, 1.29, 1.22, 1.22, 1.21, 1.33, 1.38, 1.41, 1.5, 1.51, NaN, 1.47, 1.49, 1.53, 1.5, 1.56, 1.62, NaN, 1.62, 1.61, 1.53, 1.58, 1.58, 1.63, 1.63, 1.68, 1.65, 1.65, 1.63, 1.6, 1.66, 1.72, 1.74, 1.72, 1.71, 1.64, 1.59, 1.63, 1.59, 1.68, NaN, 1.67, 1.72, 1.77, 1.7, 1.69, 1.66, 1.76, 1.81, 1.77, 1.77, 1.59, 1.61, 1.58, 1.5, 1.49, 1.45, 1.51, 1.58, 1.56, 1.5, 1.47, 1.4, 1.43, 1.41, 1.35, 1.32, 1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42,]

    tsd = TSeries(d"2021-01-01", filter(x -> !isnan(x), bonds_data))
    noisy_tsd = copy(tsd)
    noisy_tsd .+= rand(length(tsd))
    mvtsd = MVTSeries(; clean=tsd, noisy=noisy_tsd)
    mvtsdcorr = cor(tsd, noisy_tsd)
    mvtsdcov = cov(tsd, noisy_tsd)
    @test isapprox(mean(mvtsd, dims=1), [1.3632530120481 mean(noisy_tsd)], nans=true)
    res_mean_long = [
        mean([tsd[d"2021-06-29"], noisy_tsd[d"2021-06-29"]]),
        mean([tsd[d"2021-06-30"], noisy_tsd[d"2021-06-30"]]),
        mean([tsd[d"2021-07-01"], noisy_tsd[d"2021-07-01"]]),
        mean([tsd[d"2021-07-02"], noisy_tsd[d"2021-07-02"]]),
        mean([tsd[d"2021-07-03"], noisy_tsd[d"2021-07-03"]]),
    ]
    @test isapprox(mean(mvtsd[d"2021-06-29:2021-07-03"], dims=2), res_mean_long, nans=true)
    @test isapprox(mean(√, mvtsd, dims=1), [1.1623302063259 mean(√, noisy_tsd)], nans=true)
    res_mean_long2 = [
        mean(√, [tsd[d"2021-06-29"], noisy_tsd[d"2021-06-29"]]),
        mean(√, [tsd[d"2021-06-30"], noisy_tsd[d"2021-06-30"]]),
        mean(√, [tsd[d"2021-07-01"], noisy_tsd[d"2021-07-01"]]),
        mean(√, [tsd[d"2021-07-02"], noisy_tsd[d"2021-07-02"]]),
        mean(√, [tsd[d"2021-07-03"], noisy_tsd[d"2021-07-03"]]),
    ]
    @test isapprox(mean(√, mvtsd[d"2021-06-29:2021-07-03"], dims=2), res_mean_long2, nans=true)

    @test isapprox(std(mvtsd, dims=1), [0.24532947776869 std(noisy_tsd)], nans=true)
    res_std_long = [
        std([tsd[d"2021-06-29"], noisy_tsd[d"2021-06-29"]]),
        std([tsd[d"2021-06-30"], noisy_tsd[d"2021-06-30"]]),
        std([tsd[d"2021-07-01"], noisy_tsd[d"2021-07-01"]]),
        std([tsd[d"2021-07-02"], noisy_tsd[d"2021-07-02"]]),
        std([tsd[d"2021-07-03"], noisy_tsd[d"2021-07-03"]]),
    ]
    @test isapprox(std(mvtsd[d"2021-06-29:2021-07-03"], dims=2), res_std_long, nans=true)
    @test isapprox(var(mvtsd, dims=1), [0.0601865526622619 var(noisy_tsd)], nans=true)
    res_var_long = [
        var([tsd[d"2021-06-29"], noisy_tsd[d"2021-06-29"]]),
        var([tsd[d"2021-06-30"], noisy_tsd[d"2021-06-30"]]),
        var([tsd[d"2021-07-01"], noisy_tsd[d"2021-07-01"]]),
        var([tsd[d"2021-07-02"], noisy_tsd[d"2021-07-02"]]),
        var([tsd[d"2021-07-03"], noisy_tsd[d"2021-07-03"]]),
    ]
    @test isapprox(var(mvtsd[d"2021-06-29:2021-07-03"], dims=2), res_var_long, nans=true)
    @test isapprox(median(mvtsd, dims=1), [1.43 median(noisy_tsd)], nans=true)
    res_median_long = [
        median([tsd[d"2021-06-29"], noisy_tsd[d"2021-06-29"]]),
        median([tsd[d"2021-06-30"], noisy_tsd[d"2021-06-30"]]),
        median([tsd[d"2021-07-01"], noisy_tsd[d"2021-07-01"]]),
        median([tsd[d"2021-07-02"], noisy_tsd[d"2021-07-02"]]),
        median([tsd[d"2021-07-03"], noisy_tsd[d"2021-07-03"]]),
    ]
    @test isapprox(median(mvtsd[d"2021-06-29:2021-07-03"], dims=2), res_median_long, nans=true)

    @test isapprox(cor(mvtsd), [1.0 mvtsdcorr; mvtsdcorr 1.0])
    @test isapprox(cov(mvtsd), [var(tsd) mvtsdcov; mvtsdcov var(noisy_tsd)])

end

@testset "MV rename" begin
    A = MVTSeries(2001Y, collect('A' .+ (0:7)), rand(Float32, 20, 8))

    @test A === rename_columns!(A, (; A=:a, C=:c))
    @test axes(A, 2) == [:a, :B, :c, :D, :E, :F, :G, :H]

    @test A === rename_columns!(A) do x
        Symbol(x, :_1)
    end
    @test axes(A, 2) == [:a_1, :B_1, :c_1, :D_1, :E_1, :F_1, :G_1, :H_1]

    @test_throws ArgumentError rename_columns!(A; replace=nothing)

    @test A === rename_columns!(A; replace=("_1" => "_2"))
    @test axes(A, 2) == [:a_2, :B_2, :c_2, :D_2, :E_2, :F_2, :G_2, :H_2]

    @test A === rename_columns!(A; replace=("_2" => "_1"), suffix=:_2)
    @test axes(A, 2) == [:a_1_2, :B_1_2, :c_1_2, :D_1_2, :E_1_2, :F_1_2, :G_1_2, :H_1_2]

    @test A === rename_columns!(A; replace=("_1" => ""), prefix=:Q__)
    @test axes(A, 2) == [:Q__a_2, :Q__B_2, :Q__c_2, :Q__D_2, :Q__E_2, :Q__F_2, :Q__G_2, :Q__H_2]

    @test A === rename_columns!(A; prefix="O_", replace=("Q__" => "", "_2" => ""), suffix=:_x)
    @test axes(A, 2) == [:O_a_x, :O_B_x, :O_c_x, :O_D_x, :O_E_x, :O_F_x, :O_G_x, :O_H_x]

    @test A === rename_columns!(A; prefix="O_")
    @test axes(A, 2) == [:O_O_a_x, :O_O_B_x, :O_O_c_x, :O_O_D_x, :O_O_E_x, :O_O_F_x, :O_O_G_x, :O_O_H_x]

    @test A === rename_columns!(A; suffix="_x")
    @test axes(A, 2) == [:O_O_a_x_x, :O_O_B_x_x, :O_O_c_x_x, :O_O_D_x_x, :O_O_E_x_x, :O_O_F_x_x, :O_O_G_x_x, :O_O_H_x_x]

    @test A === rename_columns!(A; prefix=:O, suffix="x")
    @test axes(A, 2) == [:OO_O_a_x_xx, :OO_O_B_x_xx, :OO_O_c_x_xx, :OO_O_D_x_xx, :OO_O_E_x_xx, :OO_O_F_x_xx, :OO_O_G_x_xx, :OO_O_H_x_xx]

    Random.seed!(0x007)
    random_colnames = Symbol.([join(rand('A':'Z', 15)) for i = 1:size(A, 2)])
    @test A === rename_columns!(A, random_colnames)
    @test axes(A, 2) == random_colnames

    @test_throws ArgumentError rename_columns!(A, Symbol[])

end

@testset "isassigned" begin
    a = rand(4,2)
    b = MVTSeries(2020Q1, (:A, :B), a)
    for i = -1:6, j = -1:4
        @test isassigned(b, i, j) == isassigned(b.values, i, j)  # there is a bug in Julia 1.9, but that's not for us to fix. 
        @test isassigned(b, 2020Q1 + i - 1, :A) == isassigned(b.A, i)
        @test isassigned(b, 2020Q1 + i - 1, :B) == isassigned(b.B, i)
        @test isassigned(b, 2020Q1 + i - 1, :C) == false
    end
    @test_throws ArgumentError isassigned(b, 2020M2, :A)
end

