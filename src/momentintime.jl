# ----------------------------------------
# 1. Frequency types
# ----------------------------------------

"""
    abstract type Frequency end

The abstract supertype for all frequencies.
See also: [`Unit`](@ref) and [`YPFrequency`](@ref)
"""
abstract type Frequency end

"""
    struct Unit <: Frequency end

Represents a non-dimensional frequency (not associated with the calendar).
See also: [`YPFrequency`](@ref)
"""
struct Unit <: Frequency end

"""
    abstract type YPFrequency{N} <: Frequency end;

Represents a calendar frequency based on a number of periods in a year. 
The type parameter `N` is the number of periods and must be a positive integer.
"""
abstract type YPFrequency{N} <: Frequency end;

struct Yearly <: YPFrequency{1} end
struct Quarterly <: YPFrequency{4} end
struct Monthly <: YPFrequency{12} end

"""
    Yearly, Quarterly, Monthly

Frequencies corresponding to 1, 4, and 12 periods per year.
"""
Yearly, Quarterly, Monthly


# """
#     ppy(::Frequency)

# Returns the number of periods per year for a given `Frequency`, `MIT`, and `TSeries`


# ### Examples
# ```julia-repl
# julia> ppy(Quarterly)                   # Frequency
# 4

# julia> ppy(mm(2020, 1))                 # MIT
# 12

# julia> ppy(TSeries(yy(2020), ones(3)))   # TSeries
# 1
# ```
# """
# ppy(::Type{T}) where T <: Monthly   = 12
# ppy(::Type{T}) where T <: Quarterly = 4
# ppy(::Type{T}) where T <: Yearly    = 1
# ppy(::Type{T}) where T <: Unit      = 1


# ----------------------------------------
# 2. MIT (moment in time) and Duration 
# ----------------------------------------

primitive type MIT{F <: Frequency} <: Signed 64 end
primitive type Duration{F <: Frequency} <: Signed 64 end

"""
    MIT{F <: Frequency}, Duration{F <: Frequency}

Two types representing a 
moment in time (like 2020Q1 or 2020-01-01) and
duration (the quantity of time between two moments).

Both of these have a Frequency as a type parameter and both 
internally are represented by integer values.

If you imagine a time axis of the given `Frequency`, `MIT` values are
ordinal (correspond to points) while `Duration` values are cardinal 
(correspond to distances). 
"""
MIT, Duration

# --------------------------
# conversions with Int
MIT{F}(x::Int) where F <: Frequency = reinterpret(MIT{F}, x)
Int(x::MIT) = reinterpret(Int, x)

Duration{F}(x::Int) where F <: Frequency = reinterpret(Duration{F}, x)
Int(x::Duration) = reinterpret(Int, x)


# -------------------------
# frequencyof()

"""
frequencyof(x), frequencyof(T)

Return the Frequency type of the given value `x` or type `T`.
"""
function frequencyof end

# throw an error, except for values and types that have a frequency
# Q: should we return `nothing` instead? 
# A: No. We assume that `frequencyof` returns a subtype of `Frequency`. 
frequencyof(::T) where T = frequencyof(T)
frequencyof(T::Type) = throw(ArgumentError("$(T) does not have a frequency."))
frequencyof(::Type{MIT{F}}) where F <: Frequency = F
frequencyof(::Type{Duration{F}}) where F <: Frequency = F
# AbstractArray{<:MIT} cover MIT-ranges and vectors of MIT
frequencyof(::Type{<:AbstractArray{MIT{F}}}) where F <: Frequency = F
frequencyof(::Type{<:AbstractArray{Duration{F}}}) where F <: Frequency = F

# -------------------------
# YP-specific stuff

# construct from year and period
"""
    MIT{F}(year, period) where {F <: YPFrequency}

Construct an [`MIT`](@ref) instance from year and period. This is valid only for
frequencies subtyped from [`YPFrequency`](@ref).
""" 
MIT{F}(y::Integer, p::Integer) where F <: YPFrequency{N} where N = MIT{F}(N * Int(y) + Int(p) - 1)

"""
    yp(x::MIT)

Recover the year and period from a given [`MIT`](@ref) value. This is valid only
if the frequency is subtyped from [`YPFrequency`](@ref).
"""
function yp end
yp(x) = throw(ArgumentError("Value of type $(typeof(x)) cannot be represented as (year, period) pair. "))

# Careful with values near 0 and negative values
# the remainder `p` returned by divrem() has the same sign 
# as the argument being divided. We need 0 <= p <= N-1, so
# in this case we add N to p and subtract 1 from y 
# (since 1y = N*p we preserve the property that x = N*y+p)
@inline function yp(x::MIT{<:YPFrequency{N}}) where {N} 
    (y, p) = divrem(Int(x), N); 
    p < 0 ? (y - 1, p + N + 1) : (y, p + 1)
end

@inline year(x) = yp(x)[1]
@inline period(x) = yp(x)[2]

""" 
    year(x::MIT), period(x::MIT)

Return the year and period of an [`MIT`](@ref) value `x`. This only makes
sense if the frequency of `x` is subtyped from [`YPFrequency`](@ref).
"""
year, period

@inline mm(y::Integer, p::Integer) = MIT{Monthly}(y, p)
@inline qq(y::Integer, p::Integer) = MIT{Quarterly}(y, p)
@inline yy(y::Integer, p::Integer=1) = MIT{Yearly}(y, p)

"""
    mm(year, period), qq(year, period), yy(year, period=1)

IRIS type constructors for [`MIT`](@ref) values with frequencies that have
year and period. 
"""
mm, qq, yy

"""
    pp(year, period; N)

Construct an [`MIT`](@ref) with frequency [`YPFrequency{N}`](@ref). For
[`Quarterly`](@ref), [`Monthly`](@ref), [`Yearly`](@ref), use [`qq`](@ref),
[`mm`](@ref), [`yy`](@ref) instead of this.

"""
@inline pp(y::Integer, p::Integer; N::Integer) = MIT{YPFrequency{N}}(y, p)

# -------------------------
# pretty printing

Base.show(io::IO, m::MIT{Unit}) = print(io, Int(m), 'U')
function Base.show(io::IO, m::MIT{F}) where F <: YPFrequency{N} where N
    if isconcretetype(F)
    periodletter = first("$(F)")
    else
        periodletter =  N == 1 ? 'Y' :
                        N == 4 ? 'Q' :
                        N == 12 ? 'M' : 'P';
    end
    print(io, year(m), periodletter)
    if N > 1
        # print(io, rpad(period(m), length(string(N))))
        print(io, period(m))
    end
end

Base.string(m::MIT{<:Frequency}) = repr(m)
Base.print(io::IO, m::MIT{<:Frequency}) = print(io, string(m))

Base.show(io::IO, d::Duration) = print(io, Int(d))
Base.string(d::Duration) = repr(d)
Base.print(io::IO, d::Duration) = print(io, string(d))

# -------------------------
# Arithmetic operations with MIT and Duration

# Arithmetic with MIT and Duration are limited to adding/subtracting and 
# comparisons and even these are valid only with matching frequencies. 
# We want to tightly control what works and what doesn't and also 
# we want to provide meaningful error messages why operations 
# that don't work are disabled.

Base.promote_rule(IT::Type{<:Integer}, MT::Type{<:MIT}) = throw(ArgumentError("Invalid arithmetic operation with $IT and $MT"))
Base.promote_rule(IT::Type{<:Integer}, DT::Type{<:Duration}) = throw(ArgumentError("Invalid arithmetic operation with $IT and $DT"))

mixed_freq_error(::T1, ::T2) where {T1,T2} = throw(ArgumentError("Mixing frequencies not allowed: $(frequencyof(T1)) and $(frequencyof(T2))."))

# -------------------
# subtraction

# difference of two MIT is a Duration
Base.:(-)(l::MIT, r::MIT) = mixed_freq_error(l, r)
Base.:(-)(l::MIT{F}, r::MIT{F}) where F <: Frequency = Duration{F}(Int(l) - Int(r))
# difference of MIT and Duration is an MIT
Base.:(-)(l::MIT, r::Duration) = mixed_freq_error(l, r)
Base.:(-)(l::MIT{F}, r::Duration{F}) where F <: Frequency = MIT{F}(Int(l) - Int(r))
# difference of MIT and Integer is an MIT -- the Integer value is interpreted as a Duration of the appropriate frequency
Base.:(-)(l::MIT{F}, r::Integer) where F <: Frequency = MIT{F}(Int(l) - Int(r))
# Difference of two Duration is a Duration
Base.:(-)(l::Duration, r::Duration) = mixed_freq_error(l, r)
Base.:(-)(l::Duration{F}, r::Duration{F}) where F <: Frequency = Duration{F}(Int(l) - Int(r))
# difference of Duration and Integer is a Duration -- the Integer value is interpreted as a Duration of the same frequency
Base.:(-)(l::Duration{F}, r::Integer) where F <: Frequency = Duration{F}(Int(l) - Int(r))

# -------------------
# Comparison for equality

# we can always compare two values of MIT and Duration for equality. But they are only equal if they are of the exact same type
Base.:(==)(l::Union{MIT,Duration}, r::Union{MIT,Duration}) = typeof(l) == typeof(r) && Int(l) == Int(r)
# Base.:(==)(l::Duration, r::Duration) = frequencyof(l) == frequencyof(r) && Int(l) == Int(r)
# Base.:(==)(::Duration, ::MIT) = false
# Base.:(==)(::MIT, ::Duration) = false
# when comparing to other Integer types, we compare the numerical values
Base.:(==)(l::Union{MIT,Duration}, r::Integer) = Int(l) == r
Base.:(==)(l::Integer, r::Union{MIT,Duration}) = l == Int(r)
# Base.:(==)(l::Duration, r::Integer) = Int(l) == r
# Base.:(==)(l::Integer, r::Duration) = l == Int(r)

# -------------------
# Comparison for order

# For MIT and Duration values, they can be ordered only if they are of the exact same type, otherwise we throw an ArgumentError.
Base.:(<)(l::MIT, r::MIT) = mixed_freq_error(l, r)
Base.:(<)(l::MIT{F}, r::MIT{F}) where F <: Frequency = Int(l) < Int(r)
Base.:(<)(l::Duration{F}, r::Duration{F}) where F <: Frequency = Int(l) < Int(r)
Base.:(<)(l::Duration, r::Duration) = mixed_freq_error(l, r)
Base.:(<)(l::MIT, r::Duration) = throw(ArgumentError("Illegal comparison of $(typeof(l)) and $(typeof(r))."))
Base.:(<)(l::Duration, r::MIT) = throw(ArgumentError("Illegal comparison of $(typeof(l)) and $(typeof(r))."))

# Comparison of Duration with Int is needed for indexing and iterating time series.
# Base.:(<)(l::Int, r::Duration) = l < Int(r)
# Base.:(<)(l::Duration, r::Int) = Int(l) < r

# <= is expressed as < or == 
Base.:(<=)(l::Union{MIT,Duration}, r::Union{MIT,Duration}) = (l < r) || (l == r)
# Base.:(<=)(l::Duration, r::Int) = (l < r) || (l == r)
# Base.:(<=)(l::Int, r::Duration) = (l < r) || (l == r)


# -------------------
# addition

# addition of two MIT is not allowed
Base.:(+)(::MIT, ::MIT) = throw(ArgumentError("Illegal addition of two `MIT` values."))
# addition of two Duration is valid only if they are of the same frequency
Base.:(+)(l::Duration, r::Duration) = mixed_freq_error(l, r)
Base.:(+)(l::Duration{F}, r::Duration{F}) where F <: Frequency = Duration{F}(Int(l) + Int(r))
# addition of MIT and Duration gives an MIT
Base.:(+)(l::MIT, r::Duration) = mixed_freq_error(l, r)
Base.:(+)(l::MIT{F}, r::Duration{F}) where F <: Frequency = MIT{F}(Int(l) + Int(r))
# addition of MIT or Duration with an Integer yields the same type as the MIT/Duration argument
Base.:(+)(l::Union{MIT,Duration}, r::Integer) = oftype(l, Int(l) + r)
Base.:(+)(l::Integer, r::Union{MIT,Duration}) = oftype(r, l + Int(r))

# NOTE: the rules above are meant to catch illegal arithmetic (where the units don't make sense).
# For indexing and iterating TSeries it's more convenient to return Int rather than Duration, however
# we choose to have the checks in place.

# -------------------
# one(x) is meant to be a dimensionless 1, so that's what we do
Base.one(::Union{MIT,Duration,Type{<:MIT},Type{<:Duration}}) = Int(1)

# -------------------
# Conversion to Float64 - that's needed for plotting
(T::Type{<:AbstractFloat})(x::MIT) = convert(T, Int(x))
# In the special case of YPFrequency we want the year to be the whole part and the period to be the fractional part. 
(T::Type{<:AbstractFloat})(x::MIT{<:YPFrequency{N}}) where N = convert(T, ((y, p) = yp(x); y + (p - 1) / N))
Base.promote_rule(::Type{<:MIT}, ::Type{T}) where T <: AbstractFloat = T

# ----------------------------------------
# 2.2 MIT{T} vector and dict support
# ----------------------------------------

# added so MIT can be used as dictionary keys
Base.hash(x::MIT{T}) where T <: Frequency = hash(("$T", Int(x)))

# # added for sorting Vector{MIT{T}} where T <: Frequency
# Base.sub_with_overflow(x::MIT{T}, y::MIT{T}) where T <: Frequency = begin
#     Base.checked_ssub_int(reinterpret(Int, x), reinterpret(Int, y))
# end

# ----------------------------------------
# 4 Convenience constants
# ----------------------------------------

struct _FConst{F <: Frequency} end
    struct _FPConst{F <: Frequency,P} end
Base.:(*)(y::Integer, ::_FConst{F}) where F <: Frequency = MIT{F}(y)
Base.:(*)(y::Integer, ::_FPConst{F,P}) where {F <: Frequency,P} = MIT{F}(y, P)

Base.show(io::IO, C::_FConst) = print(io, 1C)
Base.show(io::IO, C::_FPConst) = print(io, 1C)


export Y, U, Q1, Q2, Q3, Q4, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12
global const U = _FConst{Unit}()
global const Y = _FPConst{Yearly,1}()
global const Q1 = _FPConst{Quarterly,1}()
global const Q2 = _FPConst{Quarterly,2}()
global const Q3 = _FPConst{Quarterly,3}()
global const Q4 = _FPConst{Quarterly,4}()
global const M1 = _FPConst{Monthly,1}()
global const M2 = _FPConst{Monthly,2}()
global const M3 = _FPConst{Monthly,3}()
global const M4 = _FPConst{Monthly,4}()
global const M5 = _FPConst{Monthly,5}()
global const M6 = _FPConst{Monthly,6}()
global const M7 = _FPConst{Monthly,7}()
global const M8 = _FPConst{Monthly,8}()
global const M9 = _FPConst{Monthly,9}()
global const M10 = _FPConst{Monthly,10}()
global const M11 = _FPConst{Monthly,11}()
global const M12 = _FPConst{Monthly,12}()


# ----------------------------------------
# 5 Ranges of MIT
# ----------------------------------------

Base.:(:)(start::MIT, stop::MIT) = mixed_freq_error(start, stop)
Base.:(:)(start::MIT{F}, stop::MIT{F}) where F <: Frequency = 
    UnitRange{MIT{F}}(start, stop)

Base.length(rng::UnitRange{<:MIT}) = convert(Int, last(rng) - first(rng) + 1)
Base.step(rng::UnitRange{<:MIT}) = convert(Int, 1)

