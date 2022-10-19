# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

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

See also: [`Frequency`](@ref), [`YPFrequency`](@ref)
"""
struct Unit <: Frequency end

"""
    abstract type CalendarFrequency <: Frequencies  end

Represents frequencies associated with a specific gregorian calendar position.

See also: [`Frequency`](@ref), [`YPFrequency`](@ref)
"""
abstract type CalendarFrequency <: Frequency end

"""
    struct Daily <: CalendarFrequency end

Represents a daily frequency.

See also: [`CalendarFrequency`](@ref)
"""
struct Daily <: CalendarFrequency end

"""
    struct BusinessDaily <: CalendarFrequency end

Represents a business daily frequency (excludes weekends).

See also: [`Frequency`](@ref)
"""
struct BusinessDaily <: CalendarFrequency end

"""
    struct Weekly <: Frequency end

Represents a weekly frequency. The default weekly series ends on a Sunday (N = 7).

See also: [`Frequency`](@ref)
"""
struct Weekly{N} <: CalendarFrequency where N<:Integer  end

"""
    abstract type YPFrequency{N} <: Frequency end

Represents a calendar frequency defined by a number of periods in a year. The
type parameter `N` is the number of periods and must be a positive integer. 

See also: [`Frequency`](@ref), [`Yearly`](@ref), [`Quarterly`](@ref), [`Monthly`](@ref)
"""
abstract type YPFrequency{N} <: Frequency end


"""
    struct Yearly <: YPFrequency{1} end

A concrete frequency defined as 1 period per year.
"""
struct Yearly{N} <: YPFrequency{1} where N<:Integer  end

"""
    struct Quarterly <: YPFrequency{4} end

A concrete frequency defined as 4 periods per year.
"""
struct Quarterly{N} <: YPFrequency{4} where N<:Integer end

"""
    struct Monthly <: YPFrequency{12} end

A concrete frequency defined as 12 periods per year.
"""
struct Monthly <: YPFrequency{12} end

# ----------------------------------------
# 2. MIT (moment in time) and Duration 
# ----------------------------------------

primitive type MIT{F<:Frequency} <: Signed 64 end
primitive type Duration{F<:Frequency} <: Signed 64 end

"""
    MIT{F <: Frequency}, Duration{F <: Frequency}

Two types representing a moment in time (like 2020Q1 or 2020Y) and duration (the
quantity of time between two moments).

Both of these have a Frequency as a type parameter and both internally are
represented by integer values.

If you imagine a time axis of the given `Frequency`, `MIT` values are ordinal
(correspond to points) while `Duration` values are cardinal (correspond to
distances).
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
    frequencyof(x)
    frequencyof(T)

Return the [`Frequency`](@ref) type of the given value `x` or type `T`.
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

Construct an [`MIT`](@ref) instance from `year` and `period`. This is valid only
for frequencies subtyped from [`YPFrequency`](@ref).
""" 
MIT{F}(y::Integer, p::Integer) where F <: YPFrequency{N} where N = MIT{F}(N * Int(y) + Int(p) - 1)
function MIT{F}(y::Integer, p::Integer) where F <: Weekly{N} where N 
    first_day_of_year = Dates.Date("$y-01-01")
    d = first_day_of_year + Day(7*(p - 1))
    return weekly(d, N, true)
end
function MIT{F}(y::Integer, p::Integer) where F <: BusinessDaily 
    first_day_of_year = Dates.Date("$y-01-01")
    first_day = dayofweek(first_day_of_year)
    days_diff = first_day > 5 ? 8 - first_day : 0
    d = first_day_of_year + Day(days_diff)
    return bdaily(d) + p - 1
end
function MIT{F}(y::Integer, p::Integer) where F <: Daily 
    first_day_of_year = Dates.Date("$y-01-01")
    return daily(first_day_of_year) + p - 1
end

"""
    mit2yp(x::MIT)

Recover the year and period from the given [`MIT`](@ref) value. This is valid
only for frequencies subtyped from [`YPFrequency`](@ref).
"""
function mit2yp end

# Careful with values near 0 and negative values
# the remainder `p` returned by divrem() has the same sign 
# as the argument being divided. We need 0 <= p <= N-1, so
# in this case we add N to p and subtract 1 from y 
# (since 1y = N*p we preserve the property that x = N*y+p)
@inline function mit2yp(x::MIT{<:YPFrequency{N}}) where {N} 
    (y, p) = divrem(Int(x), N); 
    p < 0 ? (y - 1, p + N + 1) : (y, p + 1)
end
@inline function mit2yp(x::MIT{<:Weekly})
    date = Dates.Date(x);
    year = Dates.year(date);
    week = ceil(Int, dayofyear(date) / 7)
    return (year, week);
end
@inline function mit2yp(x::MIT{Daily})
    date = Dates.Date(x);
    return (Dates.year(date), Dates.dayofyear(date));
end
@inline function mit2yp(x::MIT{BusinessDaily})
    # This function needs to return the year and the number of business days between
    # the start of the year and provided MIT
    y = Dates.year(Dates.Date(x));
    first_day_of_year = Dates.Date(y,1,1);
    first_day = dayofweek(first_day_of_year);
    days_diff = first_day > 5 ? 8 - first_day : 0;
    d = first_day_of_year + Day(days_diff);
    return (y, Int(x - bdaily(d) + 1));
end
mit2yp(x) = throw(ArgumentError("Value of type $(typeof(x)) cannot be represented as (year, period) pair. "))

"""
    year(mit)

Return the year of an [`MIT`](@ref). This is valid only for frequencies subtyped
from [`YPFrequency`](@ref).
"""
year(x) = mit2yp(x)[1]

"""
    period(mit)

Return the period of an [`MIT`](@ref). This is valid only for frequencies
subtyped from [`YPFrequency`](@ref).
"""
period(x) = mit2yp(x)[2]

"""
    mm(year, period)

Construct an `MIT{Monthly}` from an year and a period.
"""
mm(y::Integer, p::Integer) = MIT{Monthly}(y, p)

"""
    qq(year, period)

Construct an `MIT{Quarterly}` from an year and a period.
"""
qq(y::Integer, p::Integer) = MIT{Quarterly}(y, p)

"""
    yy(year, period)

Construct an `MIT{Yearly}` from an year and a period.
"""
yy(y::Integer, p::Integer=1) = MIT{Yearly}(y, p)

"""
    yy(year, period)

Construct an `MIT{Yearly}` from an year and a period.
"""
_d0 = Date("0001-01-01") - Day(1) 
daily(d::Date; args...) = MIT{Daily}(Dates.value(d - _d0))
daily(d::String, args...) = MIT{Daily}(Dates.value(Date(d) - _d0))
macro d_str(d); daily(d); end

function bdaily(d::Date; bias_previous=true) 
    num_weekends, rem = divrem(Dates.value(d - _d0), 7)
    adjustment = 0
    if bias_previous && rem == 6 
        adjustment = 1
    elseif !bias_previous && rem == 0
        adjustment = -1
    end
    return MIT{BusinessDaily}(Dates.value(d - _d0 - Day(num_weekends*2 + adjustment)))
end
bdaily(d::String; bias_previous::Bool=true) = bdaily(Dates.Date(d), bias_previous=bias_previous)
macro bd_str(d); bdaily(d); end

weekly(d::Date) = MIT{Weekly}(Int(ceil(Dates.value(d) / 7)))
weekly(d::String) = MIT{Weekly}(Int(ceil(Dates.value(Date(d)) / 7)))
weekly(d::Date, N::Integer) = MIT{Weekly{N}}(Int(ceil((Dates.value(d)) / 7)) + max(0, min(1, dayofweek(d) - N)))
weekly(d::String, N::Integer) = MIT{Weekly{N}}(Int(ceil((Dates.value(Date(d))) / 7)) + max(0, min(1, dayofweek(Date(d)) - N)))
function weekly(d::Date, N::Integer, normalize::Bool)
    if normalize && N == 7
        return MIT{Weekly}(Int(ceil((Dates.value(d)) / 7)) + max(0, min(1, dayofweek(d) - N)))
    else
        return weekly(d, N)
    end    
end
weekly(d::String, N::Integer, normalize::Bool) = weekly(Dates.Date(d), N, normalize)


# -------------------------
# ppy: period per year
"""
    ppy(x)
    ppy(T)

Return the periods per year for the frequency associated with the given value
`x` or type `T`.

It returns approximations for CalendarFrequencies. Used in part for comparing frequencies.

[`YPFrequency`](@ref).
"""
function ppy end
ppy(x) = ppy(frequencyof(x))
ppy(::Type{<:YPFrequency{N}}) where {N} = N
ppy(::Type{<:Daily}) = 365 # approximately
ppy(::Type{<:BusinessDaily}) = 260 # approximately
ppy(::Type{<:Weekly}) = 52 # approximately
ppy(x::Type{<:Frequency}) = error("Frequency $(x) does not have periods per year") 

#-------------------------
# date conversion
Dates.Date(m::MIT{Daily}, values_base::Symbol=:end) = _d0 + Day(Int(m))
Dates.Date(m::MIT{BusinessDaily}, values_base::Symbol=:end) =  _d0 + Day(Int(m) + 2*floor((Int(m)-1)/5))
function Dates.Date(m::MIT{Weekly}, values_base::Symbol=:end) 
    if values_base == :begin
        return _d0 + Day(Int(m)*7 - 6) 
    end
    return _d0 + Day(Int(m)*7)
end
function Dates.Date(m::MIT{Weekly{N}}, values_base::Symbol = :end) where N 
    if values_base == :begin
        return _d0 + Day(Int(m)*7 - 6) - Day(7-N)
    end
    return _d0 + Day(Int(m)*7) - Day(7-N)
end
function Dates.Date(m::MIT{Monthly}, values_base::Symbol=:end)
    year, month = divrem(Int(m), 12)
    if values_base == :begin
        return Dates.Date("$year-01-01") + Month(month)    
    end
    return Dates.Date("$year-01-01") + Month(month+1) - Day(1)
end
function Dates.Date(m::MIT{Quarterly}, values_base::Symbol=:end)
    year, quarter = divrem(Int(m), 4)
    if values_base == :begin
        return Dates.Date("$year-01-01") + Month(quarter*3)
    end
    return Dates.Date("$year-01-01") + Month((quarter+1)*3) - Day(1)
end
function Dates.Date(m::MIT{Quarterly{N}}, values_base::Symbol=:end) where N 
    year, quarter = divrem(Int(m), 4)
    if values_base == :begin
        return Dates.Date("$year-01-01") + Month(quarter*3 - (3-N))    
    end
    return Dates.Date("$year-01-01") + Month((quarter+1) * 3 - (3-N)) - Day(1)
end
function Dates.Date(m::MIT{Yearly}, values_base::Symbol=:end) 
    if values_base == :begin
        return Dates.Date("$(Int(m))-01-01")
    end
    return Dates.Date("$(Int(m) + 1)-01-01") - Day(1)
end
function Dates.Date(m::MIT{Yearly{N}}, values_base::Symbol=:end) where N 
    if values_base == :begin
        return Dates.Date("$(Int(m))-01-01") - Month(12-N)
    end
    return Dates.Date("$(Int(m) + 1)-01-01") - Month(12-N) - Day(1)
end

#-------------------------
# pretty printing

Base.show(io::IO, m::MIT{Unit}) = print(io, Int(m), 'U')
Base.show(io::IO, m::MIT{Daily}) = print(io, Dates.Date(m))
Base.show(io::IO, m::MIT{BusinessDaily}) = print(io, Dates.Date(m))
function Base.show(io::IO, m::Union{MIT{Weekly{N}},MIT{Weekly}}) where N
    date = Dates.Date(m)
    week = Dates.week(date)
    year = Dates.year(date)
    month = Dates.month(date)
    if week > 51 && month != 12
        year -= 1
    end
    print(io, "$(year)W$(week)")
end

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

mixed_freq_error(T1::Type, T2::Type) = throw(ArgumentError("Mixing frequencies not allowed: $(frequencyof(T1)) and $(frequencyof(T2))."))
mixed_freq_error(::T1, ::T2) where {T1,T2} = mixed_freq_error(T1, T2) 
mixed_freq_error(T1::Type, T2::Type, T3::Type) = throw(ArgumentError("Mixing frequencies not allowed: $(frequencyof(T1)), $(frequencyof(T2)) and $(frequencyof(T3))."))
mixed_freq_error(::T1, ::T2, ::T3) where {T1,T2,T3} = mixed_freq_error(T1, T2, T3) 

Base.promote_rule(T1::Type{<:MIT}, T2::Type{<:MIT}) = mixed_freq_error(T1, T2)
Base.promote_rule(T1::Type{MIT{F}}, T2::Type{MIT{F}}) where {F<:Frequency} = T1

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
Base.:(-)(l::Duration{F}) where F <: Frequency = Duration{F}(-Int(l))
Base.:(-)(l::Duration{F}, r::Duration{F}) where F <: Frequency = Duration{F}(Int(l) - Int(r))
# difference of Duration and Integer is a Duration -- the Integer value is interpreted as a Duration of the same frequency
Base.:(-)(l::Duration{F}, r::Integer) where F <: Frequency = Duration{F}(Int(l) - Int(r))

Base.rem(x::Duration, y::Duration) = mixed_freq_error(x,y)
Base.rem(x::Duration{F}, y::Duration{F}) where {F<:Frequency} = Duration{F}(rem(Int(x),Int(y)))
Base.div(x::Duration, y::Duration, args...) = mixed_freq_error(x,y)
Base.div(x::Duration{F}, y::Duration{F}, args...) where {F<:Frequency} = Duration{F}(div(Int(x),Int(y),args...))

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
(T::Type{<:AbstractFloat})(x::MIT{<:YPFrequency{N}}) where N = convert(T, ((y, p) = mit2yp(x); y + (p - 1) / N))
Base.promote_rule(::Type{<:MIT}, ::Type{T}) where T <: AbstractFloat = T

# frequency comparisons
Base.isless(x::Type{<:Frequency}, y::Type{<:Frequency}) where {N1,N2} = isless(ppy(x),ppy(y))

# needed for comparisons
Base.flipsign(x::Duration{F}, y::Duration{F}) where F = flipsign(Int(x),Int(y))
Base.flipsign(x::MIT{F}, y::MIT{F}) where F = flipsign(Int(x),Int(y))

# ----------------------------------------
# 2.2 MIT{T} vector and dict support
# ----------------------------------------

# added so MIT can be used as dictionary keys
Base.hash(x::MIT{T}, h::UInt) where T <: Frequency = hash(("$T", Int(x)), h)
Base.hash(x::Duration{T}, h::UInt) where T <: Frequency = hash(("$T", Int(x)), h)

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

""" 

Convenience constants that make MIT literal constants possible. For example, the
constant `Q1` makes it possible to write `2020Q1` instead of
`MIT{Quarterly}(2020, 1)`. Use `U` for `MIT{Unit}`, `Y` for `MIT{Yearly}`, `Q1`
to `Q4` for `MIT{Quarterly}` and `M1` to `M12` for `MIT{Monthly}`

"""
Y, U, Q1, Q2, Q3, Q4, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12
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
Base.:(:)(start::MIT{F}, stop::MIT{F}) where F <: Frequency = UnitRange{MIT{F}}(start, stop)

Base.:(:)(::Int, ::MIT) = my_range_error()
Base.:(:)(::MIT, ::Int) = my_range_error()
my_range_error() = throw(ArgumentError("""Cannot mix Int and MIT in the same range. 
    If you're using `begin` or `end` to index a TSeries make sure to use them at both ends.
    For example, instead of s[2:end] use s[begin+1:end].
"""))

Base.:(:)(start::MIT, step::Int, stop::MIT) = mixed_freq_error(start, stop)
Base.:(:)(start::MIT, step::Duration, stop::MIT) = mixed_freq_error(start, step, stop)
Base.:(:)(start::MIT{F}, step::Int, stop::MIT{F}) where {F<:Frequency} = start:Duration{F}(step):stop
Base.:(:)(start::MIT{F}, step::Duration{F}, stop::MIT{F}) where {F<:Frequency} = StepRange(start, step, stop)

Base.length(rng::UnitRange{<:MIT}) = convert(Int, last(rng) - first(rng) + 1)
Base.step(rng::UnitRange{<:MIT}) = convert(Int, 1)

Base.union(l::UnitRange{<:MIT}, r::UnitRange{<:MIT}) = mixed_freq_error(l, r)
Base.union(l::UnitRange{MIT{F}}, r::UnitRange{MIT{F}}) where F <: Frequency = min(first(l), first(r)):max(last(l), last(r))

# Base.issubset(l::UnitRange{<:MIT}, r::UnitRange{<:MIT}) = false
# Base.issubset(l::UnitRange{MIT{F}}, r::UnitRange{MIT{F}}) where F <: Frequency = first(r) <= first(l) && last(l) <= last(r)

#------------------------------
# sort!() a list of MITs
Base.sort!(a::AbstractVector{<:MIT}, args...; kwargs...) = (sort!(reinterpret(Int, a), args...; kwargs...); a)
