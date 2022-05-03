# Copyright (c) 2020-2021, Bank of Canada
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
    @test size(MVTSeries(1U:5U)) == (5,0)
    @test size(MVTSeries(a=TSeries(1U:5U), b=TSeries(3U:8U))) == (8,2)


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
    @test a[:, :] == a.values
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
end

@testset "MV" begin
    @test_throws ArgumentError MVTSeries(1M10, (:a, :b, :c), rand(10, 2))
    let nms = (:a, :b), dta = rand(20, 2),
        sd = MVTSeries(2000Q1, nms, copy(dta)),
        dta2 = rand(size(dta)...)

        # if one argument is Colon, fall back on single argument indexing
        # getindex
        @test sd[2000Q1, :] == dta[1, :]
        @test all(sd[2000Q1:2000Q4, :].values == dta[1:4, :])
        @test sd[:, :a].values == dta[:, 1]
        @test sd[:, (:a, :b)].values == dta[:, 1:2]
        @test sd[:, [:a, :b]].values == dta[:, 1:2]

        @test firstdate(sd) == 2000Q1
        @test lastdate(sd) == 2000Q1 + 20 - 1
        @test frequencyof(sd) == Quarterly
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
        @test_throws BoundsError sd.a = ones(length(sd.a) + 5)
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
        sd1 = hcat(sd, c = sd.a .+ 3.0)
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
        let sd2 = MVTSeries(2001Q1, nms, rand(8, length(nms)))
            sd[2001Q1:2001Q4, [:a, :b]] = sd2
            @test (sd[2001Q1:2001Q4, :].values == sd2[2001Q1:2001Q4, :].values)
        end
    end
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

end

@testset "MVTSeries math" begin
    

    #promote shape
    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))
    y = MVTSeries(21Q1, (:a, :b), rand(10, 2))
    y2 =  MVTSeries(21Q1, (:b, :c), rand(10, 2))

    @test promote_shape(x, y)[1] == 21Q1:22Q2
    @test length(promote_shape(x, y)[1]) == 6
    @test promote_shape(x, y)[2] == (:a, :b)
    @test_throws DimensionMismatch promote_shape(x, y2)

    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))
    y = MVTSeries(21Q1, (:a, :b), rand(10, 2))
    @test promote_shape(x, y.values) == promote_shape(x.values, y.values)
    @test promote_shape(x.values, y) == promote_shape(x.values, y.values)
    
    @test LinearIndices(x) == LinearIndices(x.values)
    @test LinearIndices(x)[:,1] == collect(1:10)
    @test LinearIndices(x)[:,2] == collect(11:20)

    ## multiplication and devision
    x2 = MVTSeries(1U:3U, (:a, :b))
    x2.a = collect(1:3)
    x2.b = collect(4:6)

    x3 = 2 * x2
    @test x3.a.values == [2,4,6]
    @test x3.b.values == [8, 10, 12]

    x4 = x2 * 2
    @test x4.a.values == [2,4,6]
    @test x4.b.values == [8, 10, 12]

    x5 = x2 / 2
    @test x5.a.values == [0.5,1,3/2]
    @test x5.b.values == [2, 5/2, 3]

    x6 = 2 \ x2
    @test x6.a.values == [0.5,1,3/2]
    @test x6.b.values == [2, 5/2, 3]

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
    @test x8.a.values == [9,11]
    @test x8.b.values == [15, 17]

    x9 = y3 - x2
    @test x9.a.values == [6, 6, 6]
    @test x9.b.values == [6, 6, 6]

    x10 = x2 - y4
    @test rangeof(x10) == 2U:3U
    @test x10.a.values == [-5,-5]
    @test x10.b.values == [-5,-5]


    @test_throws DimensionMismatch x2 + y2
    @test_throws DimensionMismatch x2 - y2

    @test sum(x2) == 21
    @test minimum(x2) == 1
    @test maximum(x2) == 6
    @test prod(x2) == factorial(6)

    addSix(x) = x + 6;
    @test sum(addSix, x2) == sum(y3)
    @test minimum(addSix, x2) == minimum(y3)
    @test maximum(addSix, x2) == maximum(y3)
    @test prod(addSix, x2) == prod(y3)

    @test size(sum(x2, dims=1)) == (1,2)
    @test sum(x2, dims=1)[1] == 6
    @test sum(x2, dims=1)[2] == 15
    for func in (:sum, :prod, :minimum, :maximum)
        @eval  begin
            x2 = MVTSeries(1U:3U, (:a, :b))
            x2.a = collect(1:3)
            x2.b = collect(4:6)

            y3 = MVTSeries(1U:3U, (:a, :b))
            y3.a = collect(7:9)
            y3.b = collect(10:12)

            @test size($func(x2, dims=1)) == (1,2)
            
            @test size($func(x2, dims=2)) == (3,)
            @test $func(x2, dims=2) isa TSeries
            @test rangeof($func(x2, dims=2)) == 1U:3U
            
            @test size($func(x2, dims=3)) == (3,2)
            @test $func(x2, dims=3) == x2.values

            # higher dimension go to the highest available
            @test $func(x2, dims=10) == $func(x2, dims=3)

            addSix(x) = x + 6;
            @test $func(addSix, x2) == $func(y3)
            @test $func(addSix, x2, dims=1) == $func(y3, dims=1)
            @test $func(addSix, x2, dims=2) == $func(y3, dims=2)
            @test $func(addSix, x2, dims=3) == $func(y3, dims=3)

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

        @test lead(x2) == shift(x2,1)
        @test lag(x2) == shift(x2,-1)

        x2 = copy(x2_orig)
        shift!(x2, 1)
        @test rangeof(x2) == 0U:2U
        @test x2.values == x2_orig.values

        x2 = copy(x2_orig)
        lead!(x2)
        @test rangeof(x2) == 0U:2U
        @test x2.values == x2_orig.values

        x2 = copy(x2_orig)
        lag!(x2)
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
        @test x2_diff.a.values == [1,1]
        @test x2_diff.b.values == [1,1]

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
        @test x2_cumsum.a.values == [1,3,6]
        @test x2_cumsum.b.values == [4,9,15]

        x2_cumsum2 = cumsum(x2, dims=2)
        @test rangeof(x2_cumsum2) == 1U:3U
        @test x2_cumsum2.a.values == [1,2,3]
        @test x2_cumsum2.b.values == [5,7,9]
    end

    #moving average
    let x = MVTSeries(1U:10U, (:a, :b))
        x.a = collect(1:10)
        x.b = collect(11:20)

        @test moving(x,1) == x
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
        @test x_m2_forward.b.values == collect(11:19) .+ 0.5 


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
        #@test undiff(diff(x.a)) == x.a #should not fail 

        x2 = copy(x)
        undiff!(x2.a, diff(x.a); fromdate=3U)
        @test x2.a == x.a
        @test x2.b == x.b

        # ts1 = copy(x.a)
        # ts2 = diff(ts1)
        # ts3 = diff(ts1 .* 3)
        # @test ts1 != ts2
        # undiff!(ts1, ts3)
        # @test ts1[1U] == x.a[1U]
        # the calculus is a bit off. The diff is multiplied in
        # but not for the first period, which is just taken from ts2
        # Then the value of the second period is equal to
        # ts1[2U] + ts3[2U] = 2.0 * 3.0 = 6.0, but then we also subtract 2... 
        # these tests should be revisited.
        # @test ts1[2U:10U] == x.a[2U:10U] .* 3 .- (1.0 * 3 - 1)

        # @test undiff(diff(x.a), x.a) == x.a
    end

    
end



using OrderedCollections

@testset "MVTSeries various" begin
    x = MVTSeries(20Q1, (:a, :b), rand(10, 2))

    @test TimeSeriesEcon._c(x) isa OrderedDict
    @test length(TimeSeriesEcon._c(x)) == 2
    @test TimeSeriesEcon._c(x)[:a] isa TSeries

    #reindexing
    ts = MVTSeries(2020Q1,(:y1,:y2),randn(10,2))
    ts2 = reindex(ts,2021Q1 => 1U; copy = true)
    @test ts2.y2[3U] == ts.y2[2021Q3]
    @test length(ts2.y2) == 10
    @test ts2.y1[-3U] == ts.y1[2020Q1]  
    
end
