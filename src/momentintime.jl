# ----------------------------------------
# 1. Frequency abstract types
# ----------------------------------------

"""
    Frequency

`Frequency` is an abstract type. 

`Monthly`, `Quarterly`, `Yearly`, `Unit` abstract types are subtypes of `Frequency`.

### Examples
```julia-repl
julia> Quarterly <: Frequency
true
```
"""
abstract type Frequency end

"""
    Monthly

See also: [`Frequency`](@ref)
```
"""
abstract type Monthly <: Frequency end

"""
    Quarterly

See also: [`Frequency`](@ref)
```
"""
abstract type Quarterly <: Frequency end

"""
    Yearly

See also: [`Frequency`](@ref)
```
"""
abstract type Yearly <: Frequency end

"""
    Unit

See also: [`Frequency`](@ref)
```
"""
abstract type Unit <: Frequency end

"""
    ppy(::Frequency)

Returns the number of periods per year for a given `Frequency`, `MIT`, and `TSeries`


### Examples
```julia-repl
julia> ppy(Quarterly)                   # Frequency
4

julia> ppy(mm(2020, 1))                 # MIT
12

julia> ppy(TSeries(yy(2020), ones(3)))   # TSeries
1
```
"""
ppy(::Type{T}) where T <: Monthly   = 12
ppy(::Type{T}) where T <: Quarterly = 4
ppy(::Type{T}) where T <: Yearly    = 1
ppy(::Type{T}) where T <: Unit      = 1


# ----------------------------------------
# 2. MIT{T} - main workhorse of date declaration in TimeSeriesEcon.jl
# ----------------------------------------
"""
    MIT{Frequency} <: Signed 64

MIT is a primitive type (Signed 64) representing a discrete date.

__Note:__ Please use `yy`, `qq`, 'mm', `ii` to instantiate `MIT`s. 
`MIT`s are mainly used internally for the package development.

### Examples
```julia-repl
julia> MIT{Yearly}(2000)
2000Y
julia> MIT{Monthly}(2020*12 + 3)
2020M4
```
"""
primitive type MIT{T <: Frequency} <: Signed 64 end

function MIT{T}(x::Int64) where T <: Frequency
    reinterpret(MIT{T}, x)
end

# converting to Int is just the internal representation
Int64(x::MIT{T}) where T <: Frequency = reinterpret(Int64, x)
Base.promote_rule(::Type{MIT{S}}, ::Type{T}) where S <: Frequency where T <: Integer = Int64

# converting to Float has whole part equal to the year and fractional part 
# equal to the fraction of the year for the period
(T::Type{<:AbstractFloat})(x::MIT{F}) where F <: Frequency = year(x) + (period(x)-1) / ppy(F)
Base.promote_rule(::Type{MIT{F}}, ::Type{T}) where F <: Frequency where T <:AbstractFloat = T

Base.one(::MIT{F}) where F <: Frequency = Int(1)
Base.one(::Type{MIT{F}}) where F <: Frequency = Int(1)

"""
    year(::MIT)

Returns ::Int64 representing year for a given `MIT`

__Note:__ an internal method for now.

### Examples
```
julia> year(mm(2020, 1))
2020
```
"""
function year(x::MIT{T}) where T <: Frequency
    div(reinterpret(Int64, x), ppy(T))
end

"""
    period(::MIT)

Returns ::Int64 representing period for a given `MIT`

### Examples
```
julia> period(mm(2020, 1))
1
```
"""
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


"""
    ii(::Int64)

Represents an _Integer_ date and return `MIT{Unit}` type instance

### Examples
```julia-repl
julia> ii(123)
ii(123)

julia> ii(123) + 5
ii(128)

julia> typeof(ii(123))
MIT{Unit}
```
"""
ii(x::Int64) = MIT{Unit}(x*ppy(Unit))

"""
    mm(y::Int64, p::Int64)

Represents a `Monthly` date and returns `MIT{Monthly}` type instance.

### Examples
```julia-repl
julia> mm(2020, 1)
2020M1

julia> mm(2020, 1) + 5
2020M6
```
"""
mm(y, p) = begin
    1 <= p <= 12 || error("Monthly period ", p, " must be in 1:12.")
    MIT{Monthly}(y*ppy(Monthly) + p -1)
end

"""
    qq(y::Int64, p::Int64)

Represents a `Quarterly` date and returns `MIT{Quarterly}` type instance.

### Examples
```julia-repl
julia> qq(2020, 1)
2020Q1

julia> qq(2020, 1) + 5
2021Q2
```
"""
qq(y, p) = begin
    1 <= p <= 4 || error("Quarterly period ", p, " must be in 1:4")
    MIT{Quarterly}(y*ppy(Quarterly) + p - 1)
end

"""
    yy(y::Int64)

Represents a `Yearly` date and returns `MIT{Yearly}` type instance.

### Examples
```julia-repl
julia> yy(2020)
2020Y

julia> yy(2020) + 5
2025Y
```
"""
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

# ----------------------------------------
# 3 MIT Exceptions and Errors
# ----------------------------------------

Base.:(+)(x::MIT{T}, y::MIT{S}) where T <: Frequency where S <: Frequency = throw(
    ArgumentError("`MIT` addition is not defined, but you can add `Integer` to `MIT`.")
)