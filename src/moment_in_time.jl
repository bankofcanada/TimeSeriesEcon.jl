# ----------------------------------------
# 1. Frequency abstract types
# ----------------------------------------
abstract type Frequency end

abstract type Monthly <: Frequency end
abstract type Quarterly <: Frequency end
abstract type Yearly <: Frequency end
abstract type Unit <: Frequency end

ppy(::Type{T}) where T <: Monthly   = 12
ppy(::Type{T}) where T <: Quarterly = 4
ppy(::Type{T}) where T <: Yearly    = 1
ppy(::Type{T}) where T <: Unit      = 1

# ----------------------------------------
# 2. MIT{T} - main workhorse of date declaration in TSeries.jl
# ----------------------------------------

primitive type MIT{T <: Frequency} <: Signed 64 end

function MIT{T}(x::Int64) where T <: Frequency
    reinterpret(MIT{T}, x)
end

Int64(x::MIT{T}) where T <: Frequency = reinterpret(Int64, x)

Base.promote_rule(::Type{MIT{S}}, ::Type{T}) where S <: Frequency where T <: Integer = Int64

function year(x::MIT{T}) where T <: Frequency
    div(reinterpret(Int64, x), ppy(T))
end

function period(x::MIT{T}) where T <: Frequency
    1 + rem(reinterpret(Int64, x), ppy(T))
end

Base.show(io::IO, x::MIT{T}) where T <: Frequency = begin
    print(io, year(x), string(T)[1], period(x))
end

Base.show(io::IO, x::MIT{T}) where T <: Yearly = begin
    print(io, year(x), string(T)[1])
end

Base.show(io::IO, x::MIT{T}) where T <: Unit = begin
    print(io, "ii(", Int64(x), ")")
end

Base.string(m::MIT{T}) where T <: Frequency = repr(m)


# ----------------------------------------
# 2.1 MIT{T} constructors
#   - ii, mm, qq, yy
# ----------------------------------------

ii(x::Int64) = MIT{Unit}(x*ppy(Unit))

mm(y, p) = begin
    1 <= p <= 12 || error("Monthly period ", p, " must be in 1:12.")
    MIT{Monthly}(y*ppy(Monthly) + p -1)
end

qq(y, p) = begin
    1 <= p <= 4 || error("Quarterly period ", p, " must be in 1:4")
    MIT{Quarterly}(y*ppy(Quarterly) + p - 1)
end

yy(y; p=1) = MIT{Yearly}(y*ppy(Yearly) + p - 1)

# ----------------------------------------
# 2.2 MIT{T} operations
# ----------------------------------------
Base.isequal(x::MIT{T}, y::MIT{T}) where T <: Frequency = x == y

Base.:(<=)(x::MIT{T}, y::MIT{T}) where T <: Frequency = begin
    reinterpret(Int64, x) <= reinterpret(Int64, y)
end

Base.:(<)(x::MIT{T}, y::MIT{T}) where T <: Frequency = begin
    reinterpret(Int64, x) < reinterpret(Int64, y)
end

Base.:-(m::MIT{T}, x::Integer) where T <: Frequency = begin
    reinterpret(MIT{T}, reinterpret(Int64, m) - x)
end

Base.:+(m::MIT{T}, x::Integer) where T <: Frequency = begin
    reinterpret(MIT{T}, reinterpret(Int64, m) + x)
end

Base.:-(m::MIT{T}, x::MIT{T}) where T <: Frequency = begin
    Int64(m) - Int64(x)
end

# ----------------------------------------
# 2.2 MIT{T} vector and dict support
# ----------------------------------------

# added so MIT can be used as dictionary keys
Base.hash(x::MIT{T}) where T <: Frequency = begin
    reinterpret(Int64, x) |> hash
end

# added for sorting Vector{MIT{T}} where T <: Frequency
Base.sub_with_overflow(x::MIT{T}, y::MIT{T}) where T <: Frequency = begin
    Base.checked_ssub_int(reinterpret(Int64, x), reinterpret(Int64, y))
end
