# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

using Dates
using Random
using LinearAlgebra

DE = TimeSeriesEcon.DataEcon
test_file = "test.daec"
rm(test_file, force=true)
rm(test_file * "-journal", force=true)

@testset "DE file" begin
    global de
    @test_throws DE.DEError DE.opendaec(test_file, readonly=true)
    de = DE.opendaec(test_file, write=true)
    @test isopen(de)
    @test (DE.closedaec!(de); true)
    @test !isopen(de)
    @test (de = DE.opendaec(test_file, readonly=true); isopen(de))
    @test (DE.closedaec!(de); !isopen(de))
    de = DE.opendaec(test_file, write=true)

    # test find_object throws exception or returns missing
    @test_throws DE.DEError DE.find_object(de, DE.root_id, "nosuchobject")
    @test ismissing(DE.find_object(de, DE.root_id, "nosuchobject", false))

    dm = nothing
    @test (dm = DE.opendaecmem(); isopen(dm))
    @test (DE.closedaec!(dm); !isopen(dm))

    # test get_fullpath works
    @test DE.get_fullpath(de, DE.root_id) == "/"

    # test writing an un-supported type shows a message, but doesn't throw.
    let UnsupportedType = Val{0}
        @test_logs (:error, r".*Failed to write.*of type.*\..*"i) DE.writedb(de, Workspace(a=UnsupportedType()))
        @test isempty(DE.readdb(de))
    end

    @test begin
        id = DE.new_catalog(de, "scalars")
        id == DE.find_fullpath(de, "/scalars")
    end
    @test isempty(DE.readdb(de, :scalars))

end

@testset "DE errors" begin
    @test_throws ArgumentError DE.store_scalar(de, :err, Val(0))
end

function _check_attributes(name, value, attr, has_jtype, has_jeltype)
    sz = 0
    if (name in has_jtype)
        @test get(attr, "jtype", nothing) == string(typeof(value))
        sz += 1
    end
    if (name in has_jeltype)
        @test get(attr, "jeltype", nothing) == string(Base.eltype(value))
        sz += 1
    end
    @test length(attr) == sz
end

@testset "DE scalar" begin
    db = Workspace(
        # integers
        a=Int8(1),
        ua=UInt8(1),
        b=Int16(1),
        ub=UInt16(1),
        c=Int32(1),
        uc=UInt32(1),
        d=Int64(1),
        ud=UInt64(1),
        e=Int128(1),
        ue=UInt128(1),
        # MITs
        d1=1U,
        d2=d"2020-01-01",
        d3=bd"2020-01-01",
        d4=w"2020-01-01"3,
        d5=w"2020-01-01",
        d6=2020Y,
        d7=2020Y{6},
        d8=2020M11,
        d9=2020Q2,
        d10=2020Q2{2},
        d11=2020H1,
        d12=2020H2{4},
        # Durations
        du1=2020Y - 2019Y,
        du2=2020Q3 - 2021Q4,
        # strings
        ns1=:hello,
        ns2="hi there",
        # floats
        f1=1.0f0,
        f2=1.0,
        f3=1 // 2,
        # complexes
        c1=8 + 3im,
        c2=8.0f1 + 3im,
        c3=8.0 + 3im,
        # Date and DateTime
        cd1=Dates.now(),
        cd2=Dates.today()
    )

    cata = "scalars"
    # Julia types that are not directly supporded by DataEcon.
    has_jtype = [:ns1, :f3, :c1, :cd1, :cd2]
    has_jeltype = []

    pid = DE.find_fullpath(de, cata, false)
    if ismissing(pid)
        pid = DE.new_catalog(de, cata)
    end

    # we can write them 
    for (name, value) in pairs(db)
        id = DE.store_scalar(de, pid, name, value)
        @test id == DE.find_fullpath(de, "/$cata/$name")
        attr = DE.get_all_attributes(de, id)
        _check_attributes(name, value, attr, has_jtype, has_jeltype)
    end

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => DE.load_scalar(de, pid, name)); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => DE.load_scalar(de, "/$cata/$name")); true)
    end

    # list_catalog returns what we expect
    begin
        @test isempty(DE.list_catalog(de; quiet=true, recursive=false))
        @test length(db) == DE.catalog_size(de, cata)
        lst = DE.list_catalog(de, "/$cata"; quiet=true)
        @test length(lst) == length(db)
        for k in keys(db)
            @test "/$cata/$k" in lst
        end
        lst = DE.list_catalog(de; quiet=true)
        @test length(lst) == length(db)
        for k in keys(db)
            @test "/$cata/$k" in lst
        end
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

    # delete + recursive delete 
    @test (DE.delete_object(de, "scalars"); true)
    @test ismissing(DE.find_fullpath(de, "scalars", false))

end

@testset "DE 1d arrays" begin
    db = Workspace(
        r1=1:5,
        r2=1U:5U,
        r3=2020Q1:2025Q4,
        vs1=["What", "is", "this"],
        vs2=[:this, :is, :What],
        nv1=Int32[],
        nv2=rand(Int8, 7),
        nv3=rand(Complex{Float32}, 7),
        nv4=MIT{Quarterly{3}}[rand(Int64, 12);],
        nv5=UInt8[],
        nv6=Float16[],
        nv7=ComplexF16[],
        z1=TSeries(2020Q1, rand(16)),
        z2=TSeries(2020M7, rand(Int, 27)),
        z3=TSeries(w"2020-01-01"3, [1.0im .+ (1:11);]),
        z4=TSeries(bd"2020-01-01", MIT{HalfYearly{1}}[rand(Int16, 20);]),
        b1=((1:100) .< 71)
    )

    cata = "series"
    has_jtype = [:b1]
    has_jeltype = [:vs2, :nv1, :nv5, :nv6, :nv7, :b1]

    pid = DE.find_fullpath(de, "/$cata", false)
    if ismissing(pid)
        pid = DE.new_catalog(de, cata)
    end

    # we can write them 
    for (name, value) in pairs(db)
        id = DE.store_tseries(de, pid, name, value)
        @test id == DE.find_fullpath(de, "/$cata/$name")
        attr = DE.get_all_attributes(de, id)
        _check_attributes(name, value, attr, has_jtype, has_jeltype)
    end

    ldb = Workspace()
    # we can read them from (pid,name)
    for name in keys(db)
        @test (push!(ldb, name => DE.load_tseries(de, pid, name)); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

    ldb = Workspace()
    # we can read them from full path
    for name in keys(db)
        @test (push!(ldb, name => DE.load_tseries(de, "/$cata/$name")); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

end

@testset "DE 2d arrays" begin
    types_map = Dict(Transpose => Matrix, Adjoint => Matrix)
    db = Workspace(
        mt1=zeros(3, 5),
        mt2=rand(Int32, 6, 8),
        sm1=["What" "is"; "this" "thing?"],
        sm2=[:this :is :What; :I :always :said],
        mv1=MVTSeries(2020Q1, (:a, :b, :c), rand(Float32, 8, 3)),
        mv2=MVTSeries(w"2020-01-17"5, (:a, :b), rand(Bool, 18, 2)),
        diag=Diagonal(rand(17)),
        tran=transpose(rand(22, 11)),
        adj=adjoint(rand(ComplexF64, 13, 34)),
        symu=Symmetric(rand(14, 14), :U),
        syml=Symmetric(rand(14, 14), :L),
        heru=Hermitian(rand(ComplexF32, 8, 8), :U),
        herl=Hermitian(rand(ComplexF32, 8, 8), :L),
    )

    pid = DE.find_fullpath(de, "/2d", false)
    if ismissing(pid)
        pid = DE.new_catalog(de, "2d")
    end

    # we can write them 
    for (name, value) in pairs(db)
        @test (DE.store_mvtseries(de, pid, name, value); true)
    end

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => DE.load_mvtseries(de, pid, name)); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    for (var, db_val) in pairs(db)
        db_type = typeof(db_val)
        db_base_type = eval(nameof(db_type))
        ldb_base_type = get(types_map, db_base_type, db_type)
        @test ldb[var] isa ldb_base_type
    end
end

DE.new_catalog(de, "speedtest")
DE.closedaec!(de)

@testset "DE speed" begin

    ts = TSeries(2000Y{4}, rand(400))
    db = Workspace()
    a = get!(db, :a, Workspace())
    for i = 1:100_000
        name = Symbol(:x, i)
        ts[mod1(i, length(ts))] = i
        push!(a, name => copy(ts))
    end
    b = get!(db, :b, Workspace())
    names = Set{Symbol}()
    while length(names) < 400
        push!(names, Symbol(rand('A':'Z', 5)...))
    end
    names = collect(names)
    mvts = MVTSeries(2000Y{4}, names, rand(400, length(names)))
    for i = 1:100  # like writing 40_000 TSeries of length 400
        name = Symbol(:v, i)
        mvts[mod1(i, length(mvts))] = i
        push!(b, name => copy(mvts))
    end
    scalar_types = Base.BitInteger_types ∪ (Float16, Float32, Float64, ComplexF16, ComplexF32, ComplexF64)
    c = get!(db, :c, Workspace())
    for i = 1:100_000
        name = Symbol(:c, i)
        push!(c, name => rand(rand(scalar_types)))
    end

    tm = time()
    DE.writedb(test_file, "/speedtest", db)
    tm = time() - tm
    @info "write time: $tm"
    if tm > 15
        @warn "write time is larger than expected"
    end

    tm = time()
    ldb = DE.readdb(test_file, "/speedtest")
    tm = time() - tm
    @info "read time: $tm"
    if tm > 15
        @warn "read time is larger than expected"
    end

    @test @compare(db, ldb, ignoremissing, nans = true, quiet)

end

# test emptying the File
@testset "DE empty!" begin
    DE.opendaec(test_file) do de
        @test !isempty(DE.readdb(de))
    end
    DE.opendaec(test_file, write=true) do de
        @test (empty!(de); true)
        @test isempty(DE.readdb(de))
    end
    @test isempty(DE.readdb(test_file))
end

# clean up after ourselves
DE.closedaec!(de)  # should be closed already, but just in case
rm(test_file, force=true)

@testset "DE show" begin
    @test_throws DE.DEError DE.opendaec("/this/path/does/not/exist.daec")
    Core.eval(DE.I, :(debug_libdaec = :debug))
    @test_logs (:error, r".*DE\(\d+\) SQLite3: unable to open database file.*"i) begin
        try
            DE.opendaec("/this/path/does/not/exist.daec")
        catch err
            if err isa DE.DEError
                @error "$err"
            else
                rethrow()
            end
        end
    end
    Core.eval(DE.I, :(debug_libdaec = :nodebug))
    @test_logs (:error, r".*DE\(\d+\) SQLite3: unable to open database file.*"i) begin
        try
            DE.opendaec("/this/path/does/not/exist.daec")
        catch err
            if err isa DE.DEError
                @error "$err"
            else
                rethrow()
            end
        end
    end
    @test_logs (:info, r".*DEFile:.*\(closed\).*"i) @info "$de"

end

##################################################################################################

# Compare the TimeSeriesEcon internal encoding of MITs to the
# encodings produced by de_pack_xyz and de_unpack_xyz.

# Known bug: in TimeSeriesEcon, MIT{BDaily} misbehave when the year is 0 or negative.

# Frequency \ pack/unpack ||   year+period   |   year+month+day 
# ===============================================================
#     YP Date             ||     works       |   works as of DataEcon v0.3.1
#     Cal Date            ||     works       |       works

@testset "pack/unpack year_period" begin
    # here we test the first column of the table - that is packing and unpacking 
    # MITs given year-period
    Random.seed!(0x007)
    fc = Dict{Type{<:Frequency},Base.RefValue{Int}}()
    all_freqs = [Daily, BDaily, (Weekly{i} for i = 1:7)...,
        Monthly, (Quarterly{i} for i = 1:3)...,
        (HalfYearly{i} for i = 1:6)..., (Yearly{i} for i = 1:12)...]
    for i = 1:1000
        fr = rand(all_freqs)
        d1 = convert(Int, rand(Int16))
        if fr == BDaily && d1 < 1
            # make sure it's non-negative to work around known bug
            d1 = 1 - d1
        end
        d = MIT{fr}(d1)
        y, p = isweekly(fr) ? TimeSeriesEcon._mit2yp(d) : TimeSeriesEcon.mit2yp(d)
        d2 = Ref{Int64}(0)
        f = DE.I._to_de_scalar_freq(fr)
        @test DE.C.DE_SUCCESS == DE.C.de_pack_year_period_date(f, y, p, d2)
        if d1 != d2[]
            @info "Not equal" fr d1 d y p d2
            continue
        end
        @test d1 == d2[]
        yr = Ref{Int32}(0)
        pr = Ref{UInt32}(0)
        @test DE.C.DE_SUCCESS == DE.C.de_unpack_year_period_date(f, d2[], yr, pr)
        @test y == yr[] && p == pr[]
        if !(y == yr[] && p == pr[])
            @info "Not equal" fr d1 d y p d2 yr pr
        end

        get!(fc, fr, Ref(0))[] += 1
    end
    # make sure we tested all frequencies
    foreach(all_freqs) do fr
        @test get!(fc, fr, Ref(0))[] > 10
    end
end;


@testset "pack/unpack year_month_day" begin
    # here we test the second column of the table - that is packing and unpacking 
    # MITs given year-month-day. 
    Random.seed!(0x007)
    fc = Dict{Type{<:Frequency},Base.RefValue{Int}}()
    # all_freqs = [Daily, BDaily, (Weekly{i} for i = 1:7)...,]
    all_freqs = [Daily, BDaily, (Weekly{i} for i = 1:7)...,
        Monthly, (Quarterly{i} for i = 1:3)...,
        (HalfYearly{i} for i = 1:6)..., (Yearly{i} for i = 1:12)...]
    for i = 1:1000
        fr = rand(all_freqs)
        d1 = convert(Int, rand(Int16))
        d = MIT{fr}(d1)
        date = Date(d)
        yr = Dates.year(date)
        mn = Dates.month(date)
        dy = Dates.day(date)

        f = DE.I._to_de_scalar_freq(fr)

        d2 = Ref{Int64}(0)
        @test DE.C.DE_SUCCESS == DE.C.de_pack_calendar_date(f, yr, mn, dy, d2)
        if d1 != d2[]
            @info "Not equal" fr d1 d y p d2
            continue
        end
        @test d1 == d2[]

        Y = Ref{Int32}()
        M = Ref{UInt32}()
        D = Ref{UInt32}()
        @test DE.C.DE_SUCCESS == DE.C.de_unpack_calendar_date(f, d1, Y, M, D)
        if !(yr == Y[] && mn == M[] && dy == D[])
            @info "Not equal" fr d1 d y p d2 yr pr
        end
        @test yr == Y[] && mn == M[] && dy == D[]

        get!(fc, fr, Ref(0))[] += 1
    end
    # make sure we tested all supported frequencies
    foreach(all_freqs) do fr
        @test get!(fc, fr, Ref(0))[] > 10
    end
end;



