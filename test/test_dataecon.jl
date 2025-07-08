# Copyright (c) 2020-2025, Bank of Canada
# All rights reserved.

using Dates
using Random
using LinearAlgebra

using TimeSeriesEcon.DataEcon
DE = TimeSeriesEcon.DataEcon

test_file = "test.daec"
rm(test_file, force=true)
rm(test_file * "-journal", force=true)

@testset "DE file" begin
    global de
    @test_throws DEError opendaec(test_file, readonly=true)
    de = opendaec(test_file, write=true)
    @test isopen(de)
    @test (closedaec!(de); true)
    @test !isopen(de)
    @test (de = opendaec(test_file, readonly=true); isopen(de))
    @test (closedaec!(de); !isopen(de))
    de = opendaec(test_file, write=true)

    # test find_object throws exception or returns missing
    @test_throws DEError find_object(de, root_id, "nosuchobject")
    @test ismissing(find_object(de, root_id, "nosuchobject", false))

    dm = nothing
    @test (dm = opendaecmem(); isopen(dm))
    @test (closedaec!(dm); !isopen(dm))

    # test get_fullpath works
    @test get_fullpath(de, root_id) == "/"

    # test writing an un-supported type shows a message, but doesn't throw.
    let UnsupportedType = Val{0}
        @test_logs (:error, r".*Failed to write.*of type.*\..*"i) writedb(de, Workspace(a=UnsupportedType()))
        @test isempty(readdb(de))
    end

    @test begin
        id = new_catalog(de, "scalars")
        id == find_fullpath(de, "/scalars")
    end
    @test isempty(readdb(de, :scalars))

end

@testset "DE errors" begin
    @test_throws ArgumentError store_scalar(de, :err, Val(0))
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

    pid = find_fullpath(de, cata, false)
    if ismissing(pid)
        pid = new_catalog(de, cata)
    end

    # we can write them 
    for (name, value) in pairs(db)
        id = -1
        @test (id = store_scalar(de, pid, name, value); true)
        @test id == find_fullpath(de, "/$cata/$name")
        attr = get_all_attributes(de, "/$cata/$name")
        _check_attributes(name, value, attr, has_jtype, has_jeltype)
    end

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => load_scalar(de, pid, name)); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => load_scalar(de, "/$cata/$name")); true)
    end

    # list_catalog returns what we expect
    begin
        @test isempty(list_catalog(de; quiet=true, recursive=false))
        @test length(db) == catalog_size(de, cata)
        lst = list_catalog(de, "/$cata"; quiet=true)
        @test length(lst) == length(db)
        for k in keys(db)
            @test "/$cata/$k" in lst
        end
        lst = list_catalog(de; quiet=true)
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
    @test (delete_object(de, "scalars"); true)
    @test ismissing(find_fullpath(de, "scalars", false))

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

    pid = find_fullpath(de, "/$cata", false)
    if ismissing(pid)
        pid = new_catalog(de, cata)
    end

    # we can write them 
    for (name, value) in pairs(db)
        id = -1
        @test (id = store_tseries(de, pid, name, value); true)
        @test id == find_fullpath(de, "/$cata/$name")
        attr = get_all_attributes(de, "/$cata/$name")
        _check_attributes(name, value, attr, has_jtype, has_jeltype)
    end

    ldb = Workspace()
    # we can read them from (pid,name)
    for name in keys(db)
        @test (push!(ldb, name => load_tseries(de, pid, name)); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

    ldb = Workspace()
    # we can read them from full path
    for name in keys(db)
        @test (push!(ldb, name => load_tseries(de, "/$cata/$name")); true)
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
        # special matrices
        diag=Diagonal(rand(17)),
        tran=transpose(rand(22, 11)),
        adj=adjoint(rand(ComplexF64, 13, 34)),
        symu=Symmetric(rand(14, 14), :U),
        syml=Symmetric(rand(14, 14), :L),
        heru=Hermitian(rand(ComplexF32, 8, 8), :U),
        herl=Hermitian(rand(ComplexF32, 8, 8), :L),
    )

    pid = find_fullpath(de, "/2d", false)
    if ismissing(pid)
        pid = new_catalog(de, "2d")
    end

    # excluding special matrices from these two 
    has_jtype = []
    has_jeltype = [:sm2, :mv2]

    # we can write them 
    for (name, value) in pairs(db)
        id = -1
        @test (id = store_mvtseries(de, pid, name, value); true)
        @test id == find_fullpath(de, "/2d/$name")
        attr = get_all_attributes(de, "/2d/$name")
        if value isa LinearAlgebra.AdjOrTrans
            # special check for special matrices
            @test ismissing(get_attribute(de, "/2d/$name", "jtype"))
        elseif value isa Union{Diagonal,LinearAlgebra.HermOrSym}
            # special check for special matrices
            @test get_attribute(de, "/2d/$name", "jtype") == string(nameof(typeof(value)))
        else
            # standard check for "non-special" matrices
            _check_attributes(name, value, attr, has_jtype, has_jeltype)
        end
    end

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => load_mvtseries(de, pid, name)); true)
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

new_catalog(de, "speedtest")
closedaec!(de)

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
    writedb(test_file, "/speedtest", db)
    tm = time() - tm
    @info "write time: $tm"
    if tm > 15
        @warn "write time is larger than expected"
    end

    tm = time()
    ldb = readdb(test_file, "/speedtest")
    tm = time() - tm
    @info "read time: $tm"
    if tm > 15
        @warn "read time is larger than expected"
    end

    @test @compare(db, ldb, ignoremissing, nans = true, quiet)

end

# test emptying the File
@testset "DE empty!" begin
    opendaec(test_file) do de
        @test !isempty(de)
        @test_throws DEError empty!(de)  # cannot truncate when readonly
    end
    @test_throws Exception opendaec(test_file; truncate=true)
    opendaec(test_file, write=true) do de
        @test (empty!(de); true)
        @test isempty(de)
    end
    @test isempty(readdb(test_file))
end

@testset "DE overwrite" begin
    opendaec(test_file, write=true, overwrite=false) do de
        @test (store_scalar(de, :hello, "hello"); true)
        @test_throws DEError store_scalar(de, :hello, "hello")
        @test (new_catalog(de, :newcat); true)
        @test_throws DEError new_catalog(de, :newcat)
        @test (store_tseries(de, :newseries, [1,2,3,4]); true)
        @test_throws DEError store_tseries(de, :newseries, [1,2,3,4])
        @test (store_mvtseries(de, :newdata, [1 2 3; 4 5 6]); true)
        @test_throws DEError store_mvtseries(de, :newdata, [3 4; 8 9])
    end
    opendaec(test_file, write=true, overwrite=true) do de
        @test (store_scalar(de, :hello, "hello"); true)
        @test (new_catalog(de, :newcat); true)
        @test (store_tseries(de, :newseries, [1,2,3,4]); true)
        @test (store_mvtseries(de, :newdata, [1 2 3; 4 5 6]); true)
    end
end

@testset "DE show" begin
    @test_throws DEError opendaec("/this/path/does/not/exist.daec")
    Core.eval(DE.I, :(debug_libdaec = :debug))
    @test_logs (:error, r".*DE\(\d+\) SQLite3: unable to open database file.*"i) begin
        try
            opendaec("/this/path/does/not/exist.daec")
        catch err
            if err isa DEError
                @error "$err"
            else
                rethrow()
            end
        end
    end
    Core.eval(DE.I, :(debug_libdaec = :nodebug))
    @test_logs (:error, r".*DE\(\d+\) SQLite3: unable to open database file.*"i) begin
        try
            opendaec("/this/path/does/not/exist.daec")
        catch err
            if err isa DEError
                @error "$err"
            else
                rethrow()
            end
        end
    end
    closedaec!(de)
    @test_logs (:info, r".*DEFile:.*\(closed\).*"i) @info "$de"
    opendaec(test_file; overwrite=false) do de
        @test_logs (:info, r".*DEFile:.*"i) @info "$de"
    end
    opendaec(test_file; overwrite=true) do de
        @test_logs (:info, r".*DEFile:.*\(overwrite\).*"i) @info "$de"
    end
end

# clean up after ourselves
closedaec!(de)  # should be closed already, but just in case
rm(test_file, force=true)
rm(test_file * "-journal", force=true)

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



