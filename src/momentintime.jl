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
    MIT{Frequency}(x::Int64)

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

MIT{F}(y::Integer, p::Integer) where F <: Frequency = 1 <= p <= ppy(F) ? 
                                                      reinterpret(MIT{F}, y * ppy(F) + p - 1) :
                                                      throw(ArgumentError("$F period must be in 1…$(ppy(F))")) 

export frequencyof
"""
    frequencyof(::MIT)
    frequencyof(::Type{MIT})

Return the Frequency type of the given MIT instance of type.
"""
frequencyof(::Any) = nothing
frequencyof(::MIT{T}) where T <: Frequency = T
frequencyof(::Type{MIT{T}}) where T <: Frequency = T

# converting to Int is just the internal representation
Int64(x::MIT{T}) where T <: Frequency = reinterpret(Int64, x)
Base.promote_rule(::Type{MIT{S}}, ::Type{T}) where S <: Frequency where T <: Integer = Int64

# converting to Float has whole part equal to the year and fractional part 
# equal to the fraction of the year for the period
(T::Type{<:AbstractFloat})(x::MIT{F}) where F <: Frequency = year(x) + (period(x) - 1) / ppy(F)
Base.promote_rule(::Type{MIT{F}}, ::Type{T}) where F <: Frequency where T <: AbstractFloat = T

Base.one(::MIT) = Int(1)
Base.one(::Type{<:MIT}) = Int(1)

"""
    year(x::MIT)

Return `::Int64` representing year for a given `MIT`

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
    period(x::MIT)

Return `::Int64` representing period for a given `MIT`

### Examples
```
julia> period(mm(2020, 1))
1
```
"""
function period(x::MIT{T}) where T <: Frequency
    1 + rem(reinterpret(Int64, x), ppy(T))
end

function Base.show(io::IO, x::MIT)
    F = first("$(frequencyof(x))")
    Y = year(x)
    Y = get(io, :compact, true) ? string(year(x)) : lpad(Y, 4)
    np = ppy(x)
    if np == 1 
        print(io, Y, F)
    else
        n = length(string(np))
        print(io, Y, F, rpad(period(x), n))
    end
end

Base.string(m::MIT{T}) where T <: Frequency = repr(m)

# ----------------------------------------
# 2.1 MIT{T} constructors
#   - ii, mm, qq, yy
# ----------------------------------------


"""
    ii(x::Int64)

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
ii(x::Int64) = MIT{Unit}(x, 1)

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
mm(y, p) = MIT{Monthly}(y, p)

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
qq(y, p) = MIT{Quarterly}(y, p)

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
yy(y, p=1) = MIT{Yearly}(y, p)

# ----------------------------------------
# 2.2 MIT{T} operations
# ----------------------------------------

Base.isequal(x::MIT, y::MIT) = frequencyof(x) == frequencyof(y) && isequal(Int(x), Int(y))
Base.:(==)(x::MIT, y::MIT) = frequencyof(x) == frequencyof(y) && Int(x) == Int(y)

Base.:(<)(x::MIT, y::MIT) = frequencyof(x) == frequencyof(y) ? Int(x) < Int(y) : throw(ArgumentError("Cannot compare MIT of different frequency."))
Base.:(<=)(x::MIT, y::MIT) = (x < y) || (x == y) 

Base.:-(a::MIT, b::MIT) = frequencyof(a) == frequencyof(b) ? Int(a)-Int(b) : throw(ArgumentError("Cannot subtract MIT of different frequencies."))
Base.:-(m::MIT, x::Integer) = reinterpret(typeof(m), Int(m) - x)
Base.:-(::Integer, ::MIT) = throw(ArgumentError("Cannot subtract MIT from an Integer."))

Base.:+(m::MIT, x::Integer) = reinterpret(typeof(m), Int(m) + x)
Base.:+(x::Integer, m::MIT) = reinterpret(typeof(m), Int(m) + x)
Base.:+(::MIT, ::MIT) = throw(ArgumentError("Cannot add two MIT."))

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
# 4 Convenience constants
# ----------------------------------------

struct _FPConst{F <: Frequency,P}
    _FPConst{F,P}() where F <: Frequency where P = 0 < P <= ppy(F) ? new{F,P}() : throw(ArgumentError("Invalid period $P for frequency $F."))
end
_FPConst(F::Type{<:Frequency}, p::Integer=1) = _FPConst{F,p}()
Base.:(*)(y::Integer, fc::_FPConst{F,P}) where F <: Frequency where P = MIT{F}(y, P)


export Y, U, Q1, Q2, Q3, Q4, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12
global const Y = _FPConst(Yearly)
global const U = _FPConst(Unit)
global const Q1 = _FPConst(Quarterly, 1)
global const Q2 = _FPConst(Quarterly, 2)
global const Q3 = _FPConst(Quarterly, 3)
global const Q4 = _FPConst(Quarterly, 4)
global const M1 = _FPConst(Monthly, 1)
global const M2 = _FPConst(Monthly, 2)
global const M3 = _FPConst(Monthly, 3)
global const M4 = _FPConst(Monthly, 4)
global const M5 = _FPConst(Monthly, 5)
global const M6 = _FPConst(Monthly, 6)
global const M7 = _FPConst(Monthly, 7)
global const M8 = _FPConst(Monthly, 8)
global const M9 = _FPConst(Monthly, 9)
global const M10 = _FPConst(Monthly, 10)
global const M11 = _FPConst(Monthly, 11)
global const M12 = _FPConst(Monthly, 12)

