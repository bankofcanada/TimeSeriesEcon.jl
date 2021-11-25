# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.


@testset "MV construct" begin
    @test size(MVTSeries(20Q1)) == (0,0)
    @test size(MVTSeries(20Q1, :a)) == (0,1)
    @test size(MVTSeries(20Q1, (:a, :b))) == (0,2)
    @test size(MVTSeries(20Q1, (:a,"b"))) == (0,2)
    @test size(MVTSeries(20Q1:20Q4, :a)) == (4,1)
    @test size(MVTSeries(20Q1:20Q4, (:a,:b))) == (4,2)
    @test size(MVTSeries(20Q1:20Q4, ("a",:b))) == (4,2)
    @test size(MVTSeries(20Q1:20Q4, ["a",:b])) == (4,2)
    @test size(MVTSeries(20Q1:20Q4, ["a",:b], undef)) == (4,2)
    @test size(MVTSeries(20Q1:20Q4, ["a",:b], 5)) == (4,2)
    @test size(MVTSeries(20Q1:20Q4, ["a",:b], zeros)) == (4,2)

    let a = similar(zeros(Int, 0,0), (20Y:22Y, (:a,:b))),
        b = similar(zeros(Int, 0,0), Complex, (20Y:22Y, (:a,:b))),
        c = fill(5, 20Q1:20Q4, (:a,:b,:c))
        @test a isa MVTSeries
        @test rangeof(a) == 20Y:22Y
        @test tuple(colnames(a)...) == (:a, :b)
        @test eltype(a) == Int
        @test eltype(b) == Complex
        @test eltype(c) == Int
        @test size(c) == (4, 3)
        @test extrema(c) == (5, 5)
    end

    @test_throws ArgumentError MVTSeries(1U, (:a, :b), zeros(10,3))
    @test_throws ArgumentError MVTSeries(1U, (:a, :b), zeros(10,1))

    @test_throws ArgumentError MVTSeries(1U:5U, (:a, :b), zeros(10,2))
    @test_throws ArgumentError MVTSeries(1U:5U, (:a, :b), zeros(4,2))
    @test (MVTSeries(1U:5U, (:a, :b), zeros(5,2)); true)

end





@testset "MVTSeries show" begin
    # test the case when column labels are longer than the numbers
    let io = IOBuffer(), x = MVTSeries(1U, (:verylongandsuperboringnameitellya, :anothersuperlongnamethisisridiculous, :a), rand(20, 3) .* 100)
        show(io, x)
        lines = readlines(seek(io, 0))
        # labels longer than 10 character are abbreviated with '…' at the end
        @test length(split(lines[2], '…')) == 3
    end
    let io = IOBuffer() , x = MVTSeries(1U, (:alpha, :beta), zeros(24, 2))
        show(io, x)
        lines = readlines(seek(io, 0))
        lens = length.(lines)
        # when labels are longer than the numbers, the entire column stretches to fit the label
        @test lens[2] == lens[3]
    end
    nrow = 24
    letters = Symbol.(['a':'z'...])
    for (nlines, fd) = zip([3, 4, 5, 6, 7, 8, 22, 23, 24, 25, 26, 30], Iterators.cycle((2010Q1, 2010M1, 2010Y, 1U)))
        for ncol = [2,5,10,20]
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
