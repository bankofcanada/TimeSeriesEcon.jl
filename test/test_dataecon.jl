# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

DE = TimeSeriesEcon.DataEcon
test_file = "test.daec"
rm(test_file, force=true)
rm(test_file*"-journal", force=true)

@testset "DE file" begin
    de = DE.opendaec(test_file)
    @test isopen(de)
    @test (DE.closedaec!(de); true)
    @test !isopen(de)
end

de = DE.opendaec(test_file)

@testset "DE catalog" begin
    @test begin
        id = DE.new_catalog(de, "scalars")
        id == DE.find_fullpath(de, "/scalars")
    end
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
    )

    pid = DE.find_fullpath(de, "/scalars", false)
    if ismissing(pid)
        pid = DE.new_catalog(de, "scalars")
    end

    # we can write them 
    for (name, value) in pairs(db)
        @test begin
            id = DE.store_scalar(de, pid, name, value)
            id == DE.find_fullpath(de, "/scalars/$name")
        end
    end


    pid1 = DE.find_fullpath(de, "/scalars1", false)
    if ismissing(pid1)
        pid1 = DE.new_catalog(de, "scalars1")
    end

    # we can write them 
    for (name, value) in pairs(db)
        @test begin
            id = DE.store_scalar(de, "/scalars1/$name", value)
            id == DE.find_object(de, pid1, name)
        end
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
        @test (push!(ldb, name => DE.load_scalar(de, "/scalars/$name")); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

    # delete + recursive delete 
    @test (DE.delete_object(de, "scalars1"); true)
    @test ismissing(DE.find_fullpath(de, "scalars1", false))

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
        z1 = TSeries(2020Q1, rand(16)),
        z2 = TSeries(2020M7, rand(Int, 27)),
        z3 = TSeries(w"2020-01-01"3, [1.0im .+ (1:11);])
    )

    # we can write them 
    for (name, value) in pairs(db)
        @test (DE.store_tseries(de, name, value); true)
    end

    ldb = Workspace()
    # we can read them 
    for name in keys(db)
        @test (push!(ldb, name => DE.load_tseries(de, name)); true)
    end

    # they are equal
    @test @compare db ldb quiet

    # their types are the same
    @test @compare map(typeof, db) map(typeof, ldb) quiet

end

@testset "DE speed" begin
    id = DE.new_catalog(de, "speedtest")

    ts = TSeries(2000Y{4}, rand(400))
    a = Workspace()
    for i = 1:100_000
        name = Symbol(:x, i)
        ts[mod1(i,length(ts))] = i
        push!(a, name => copy(ts))
    end
    tm = time()
    DE.writedb(de, id, a)
    tm = time() - tm
    @info "write time: $tm"
    @test tm < 15
    
    tm = time()
    b = DE.readdb(de, id)
    tm = time() - tm
    @info "read time: $tm"
    @test tm < 10

    @test @compare(a, b, ignoremissing, nans=true, quiet)

end

# clean up after ourselves
DE.closedaec!(de)
rm(test_file, force=true)

