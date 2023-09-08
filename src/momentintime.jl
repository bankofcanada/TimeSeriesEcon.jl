# Copyright (c) 2020-2023, Bank of Canada
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
    struct BDaily <: CalendarFrequency end

Represents a business daily frequency (excludes weekends).

See also: [`Frequency`](@ref)
"""
struct BDaily <: CalendarFrequency end

"""
    struct Weekly{end_day} <: Frequency end

Represents a weekly frequency. The default weekly series ends on a Sunday (end_day = 7).

See also: [`Frequency`](@ref)
"""
struct Weekly{end_day} <: CalendarFrequency end

"""
    abstract type YPFrequency{N} <: Frequency end

Represents a calendar frequency defined by a number of periods in a year. The
type parameter `N` is the number of periods and must be a positive integer. 

See also: [`Frequency`](@ref), [`Yearly`](@ref), [`HalfYearly`](@ref), [`Quarterly`](@ref), [`Monthly`](@ref)
"""
abstract type YPFrequency{N} <: CalendarFrequency end


"""
    struct Yearly{end_month} <: YPFrequency{1} end

A concrete frequency defined as 1 period per year. The default end_month is 12.
"""
struct Yearly{end_month} <: YPFrequency{1} end
abstract type Y{end_month} end;
function Base.:*(y::Int, ::Type{Y{end_month}}) where {end_month}
    if !(typeof(end_month) <: Integer)
        throw(ArgumentError("The end_month for a Yearly frequency must be and integer. Received: $end_month"))
    end
    if end_month > 12 || end_month < 1
        throw(ArgumentError("The end_month for a Yearly frequency must be between 1 and 12. Received: $end_month"))
    end
    return MIT{Yearly{end_month}}(y)
end
Base.:*(y::Int, ::Type{Y}) = MIT{Yearly{12}}(y)

"""
    struct HalfYearly{end_month} <: YPFrequency{2} end

A concrete frequency defined as 2 periods per year.
"""
struct HalfYearly{end_month} <: YPFrequency{2} end
abstract type H1{end_month} end;
abstract type H2{end_month} end;
function validate_halfyearly(end_month)
    if !(typeof(end_month) <: Integer)
        throw(ArgumentError("The end_month for a HalfYearly frequency must be and integer. Received: $end_month"))
    end
    if end_month > 6 || end_month < 1
        throw(ArgumentError("The end_month for a HalfYearly frequency must be between 1 and 6. Received: $end_month"))
    end
end
function Base.:*(y::Int, ::Type{H1{end_month}}) where {end_month}
    validate_halfyearly(end_month)
    return MIT{HalfYearly{end_month}}(y, 1)
end
Base.:*(y::Int, ::Type{H1}) = MIT{HalfYearly{6}}(y, 1)
function Base.:*(y::Int, ::Type{H2{end_month}}) where {end_month}
    validate_halfyearly(end_month)
    return MIT{HalfYearly{end_month}}(y, 2)
end
Base.:*(y::Int, ::Type{H2}) = MIT{HalfYearly{6}}(y, 2)

"""
    struct Quarterly{end_month} <: YPFrequency{4} end  

A concrete frequency defined as 4 periods per year. The default end_month is 3.
"""
struct Quarterly{end_month} <: YPFrequency{4} end
abstract type Q1{end_month} end;
abstract type Q2{end_month} end;
abstract type Q3{end_month} end;
abstract type Q4{end_month} end;
function validate_quarterly(end_month)
    if !(typeof(end_month) <: Integer)
        throw(ArgumentError("The end_month for a Quarterly frequency must be and integer. Received: $end_month"))
    end
    if end_month > 3 || end_month < 1
        throw(ArgumentError("The end_month for a Quarterly frequency must be between 1 and 3. Received: $end_month"))
    end
end
function Base.:*(y::Int, ::Type{Q1{end_month}}) where {end_month}
    validate_quarterly(end_month)
    return MIT{Quarterly{end_month}}(y, 1)
end
Base.:*(y::Int, ::Type{Q1}) = MIT{Quarterly{3}}(y, 1)
function Base.:*(y::Int, ::Type{Q2{end_month}}) where {end_month}
    validate_quarterly(end_month)
    return MIT{Quarterly{end_month}}(y, 2)
end
Base.:*(y::Int, ::Type{Q2}) = MIT{Quarterly{3}}(y, 2)
function Base.:*(y::Int, ::Type{Q3{end_month}}) where {end_month}
    validate_quarterly(end_month)
    return MIT{Quarterly{end_month}}(y, 3)
end
Base.:*(y::Int, ::Type{Q3}) = MIT{Quarterly{3}}(y, 3)
function Base.:*(y::Int, ::Type{Q4{end_month}}) where {end_month}
    validate_quarterly(end_month)
    return MIT{Quarterly{end_month}}(y, 4)
end
Base.:*(y::Int, ::Type{Q4}) = MIT{Quarterly{3}}(y, 4)



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
MIT{F}(x::Int) where {F<:Frequency} = reinterpret(MIT{F}, x)
MIT{Yearly}(x::Int) = MIT{Yearly{12}}(x)
MIT{Quarterly}(x::Int) = MIT{Quarterly{3}}(x)
MIT{HalfYearly}(x::Int) = MIT{HalfYearly{6}}(x)
MIT{Weekly}(x::Int) = MIT{Weekly{7}}(x)
MIT{YPFrequency{1}}(x::Int) = MIT{Yearly{12}}(x)
MIT{YPFrequency{2}}(x::Int) = MIT{HalfYearly{6}}(x)
MIT{YPFrequency{4}}(x::Int) = MIT{Quarterly{3}}(x)
MIT{YPFrequency{12}}(x::Int) = MIT{Monthly}(x)
Int(x::MIT) = reinterpret(Int, x)

Duration{F}(x::Int) where {F<:Frequency} = reinterpret(Duration{F}, x)
Duration{Yearly}(x::Int) = Duration{Yearly{12}}(x)
Duration{Quarterly}(x::Int) = Duration{Quarterly{3}}(x)
Duration{HalfYearly}(x::Int) = Duration{HalfYearly{6}}(x)
Duration{Weekly}(x::Int) = Duration{Weekly{7}}(x)
Duration{YPFrequency{1}}(x::Int) = Duration{Yearly{12}}(x)
Duration{YPFrequency{2}}(x::Int) = Duration{HalfYearly{6}}(x)
Duration{YPFrequency{4}}(x::Int) = Duration{Quarterly{3}}(x)
Duration{YPFrequency{12}}(x::Int) = Duration{Monthly}(x)
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
frequencyof(::T) where {T} = frequencyof(T)
frequencyof(F::Type{<:Frequency}) = F
frequencyof(T::Type) = throw(ArgumentError("$(T) does not have a frequency."))
frequencyof(::Type{MIT{F}}) where {F<:Frequency} = F
frequencyof(::Type{Duration{F}}) where {F<:Frequency} = F
# AbstractArray{<:MIT} cover MIT-ranges and vectors of MIT
frequencyof(AT::Type{<:AbstractArray{<:Union{MIT,Duration}}}) = frequencyof(eltype(AT))

# -------------------------
# YP-specific stuff

# construct from year and period
"""
    MIT{F}(year, period) where {F <: YPFrequency}

Construct an [`MIT`](@ref) instance from `year` and `period`. This is valid only
for frequencies subtyped from [`YPFrequency`](@ref).
"""
MIT{F}(y::Integer, p::Integer) where {F<:YPFrequency{N}} where {N} = MIT{F}(N * Int(y) + Int(p) - 1)
MIT{Yearly}(y::Integer, p::Integer) = MIT{Yearly{12}}(y, p)
MIT{Quarterly}(y::Integer, p::Integer) = MIT{Quarterly{3}}(y, p)
MIT{HalfYearly}(y::Integer, p::Integer) = MIT{HalfYearly{6}}(y, p)
function _weekly_from_yp(F::Type{<:Weekly{end_day}}, y, p) where {end_day}
    first_day_of_year = Dates.Date("$y-01-01")
    d = first_day_of_year + Day(7 * (p - 1))
    return weekly(d, end_day)
end
function MIT{F}(y::Integer, p::Integer) where {F<:BDaily}
    first_day_of_year = Dates.Date("$y-01-01")
    first_day = dayofweek(first_day_of_year)
    days_diff = first_day > 5 ? 8 - first_day : 0
    d = first_day_of_year + Day(days_diff)
    return bdaily(d) + p - 1
end
function MIT{F}(y::Integer, p::Integer) where {F<:Daily}
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
    (y, p) = divrem(Int(x), N)
    p < 0 ? (y - 1, p + N + 1) : (y, p + 1)
end
@inline function mit2yp(x::MIT{Daily})
    date = Dates.Date(x)
    return (Dates.year(date), Dates.dayofyear(date))
end
@inline function mit2yp(x::MIT{BDaily})
    # This function needs to return the year and the number of business days between
    # the start of the year and provided MIT
    y = Dates.year(Dates.Date(x))
    first_day_of_year = Dates.Date(y, 1, 1)
    first_day = dayofweek(first_day_of_year)
    days_diff = first_day > 5 ? 8 - first_day : 0
    d = first_day_of_year + Day(days_diff)
    return (y, Int(x - bdaily(d) + 1))
end
mit2yp(x) = throw(ArgumentError("Value of type $(typeof(x)) cannot be represented as (year, period) pair. "))
# this function is not exposed to the public
@inline function _mit2yp(x::MIT{<:Weekly})
    date = Dates.Date(x)
    year = Dates.year(date)
    week = ceil(Int, dayofyear(date) / 7)
    return (year, week)
end

"""
    year(mit)

Return the year of an [`MIT`](@ref). This is valid only for frequencies subtyped
from [`YPFrequency`](@ref).
"""
year(x::MIT) = mit2yp(x)[1]

"""
    period(mit)

Return the period of an [`MIT`](@ref). This is valid only for frequencies
subtyped from [`YPFrequency`](@ref).
"""
period(x::MIT) = mit2yp(x)[2]

"""
    mm(year, period)

Construct an `MIT{Monthly}` from an year and a period.
"""
mm(y::Integer, p::Integer) = MIT{Monthly}(y, p)

"""
    qq(year, period)

Construct an `MIT{Quarterly}` from an year and a period.
"""
qq(y::Integer, p::Integer) = MIT{Quarterly{3}}(y, p)

"""
    yy(year, period)

Construct an `MIT{Yearly}` from an year and a period.
"""
yy(y::Integer, p::Integer=1) = MIT{Yearly{12}}(y, p)


_d0 = Date("0001-01-01") - Day(1)
"""
    daily(d::Date)

Convert a Date object to an MIT{Daily}.
"""
daily(d::Date; args...) = MIT{Daily}(Dates.value(d - _d0))

"""
    daily(d::String)

Convert a String object to an MIT{Daily}. The string must be convertible to a Date via the `Dates.Date(d::String)` method.
"""
daily(d::String, args...) = MIT{Daily}(Dates.value(Date(d) - _d0))

"""
    d_str(d)

A macro which converts a string to an MIT{Daily} or a UnitRange{MIT{Daily}}.

To return a UnitRange, provide a single string with two dates separated by `:`.

Example:
    christmas = d"2022-12-25"
    days_of_february = d"2022-02-01:2022-02-28"
"""
macro d_str(d)
    if findfirst(":", d) !== nothing
        dsplit = split(d, ":")
        return daily(Dates.Date(dsplit[1])):daily(Dates.Date(dsplit[2]))
    end
    return daily(d)
end

"""
    bdaily(d::Date; bias_previous::Bool=true) 

Construct an `MIT{BDaily}` from a Date object. 

The optional `bias_previous` argument determines which side of a weekend
to land on when the provided date is Saturday or Sunday. The default
is `true`, meaning that the preceding Friday is returned.

"""
function bdaily(d::Date; bias::Symbol=getoption(:bdaily_creation_bias))
    num_weekends, rem = divrem(Dates.value(d - _d0), 7)
    adjustment = 0
    if rem == 0 # Sunday
        if bias ∈ (:next, :nearest)
            adjustment = -1
        elseif bias == :strict
            throw(ArgumentError("$d is not a valid business day, it is a $(dayname(d))."))
        end
    elseif rem == 6 # Saturday
        if bias ∈ (:previous, :nearest)
            adjustment = 1
        elseif bias == :strict
            throw(ArgumentError("$d is not a valid business day, it is a $(dayname(d))."))
        end
    end
    return MIT{BDaily}(Dates.value(d - _d0 - Day(num_weekends * 2 + adjustment)))
end

"""
    bdaily(d::String; bias_previous::Bool=true)

Construct an `MIT{BDaily}` from a String. The string must be convertible to a Date via the `Dates.Date(d::String)` method.

The optional `bias_previous` argument determines which side of a weekend
to land on when the provided date is Saturday or Sunday. The default
is `true`, meaning that the preceding Friday is returned.

"""
bdaily(d::String; bias::Symbol=getoption(:bdaily_creation_bias)) = bdaily(Dates.Date(d), bias=bias)
macro bd_str(d)
    if findfirst(":", d) !== nothing
        dsplit = split(d, ":")
        rng = bdaily(string(dsplit[1]), bias=:next):bdaily(string(dsplit[2]), bias=:previous)
        if last(rng) < first(rng)
            throw(ArgumentError("The provided range, $d, does not include any business days."))
        end
        return rng
    end
    return bdaily(d)
end;

"""
    bd_str(d, bias)

A macro which converts a string to an MIT{BDaily} or a UnitRange{MIT{BDaily}}.

The optional `bias`` determines which business day is returned when the provided 
date is on a Saturday or Sunday. Available options are `"n"` or `"next"` for 
biasing the next business day, and "p", or "previous" for the next business day,
`"near"` or `"nearest"` for biasing the nearest business day, and `"s"` or `"strict"`
in which case passing a day on a weekend will return an error.

To return a UnitRange, provide a single string with two dates separated by `:`. 
In this case the first date will be biased to the following business day and the
second date will be biased to the previous business day. The `bias` argument cannot 
be provided when converting a range of dates.

Example:
    april_first = bd"2022-04-01"
    second_week_of_april = bd"2022-04-04:2022-04-08"
"""
macro bd_str(d, bias)
    if findfirst(":", d) !== nothing
        throw(ArgumentError("Additional arguments are not supported when passing a range to bd\"\"."))
    end
    if bias ∉ ("n", "next", "p", "previous", "s", "strict", "near", "nearest")
        throw(ArgumentError("""A  bd\"\" string literal must terminate in one of ("", "n", "next", "p", "previous", "s", "strict", "near", "nearest")."""))
    end
    if bias == ""
        return bdaily(d)
    elseif bias == "n" || bias == "next"
        return bdaily(d, bias=:next)
    elseif bias == "p" || bias == "p"
        return bdaily(d, bias=:previous)
    elseif bias == "s" || bias == "strict"
        return bdaily(d, bias=:strict)
    elseif bias == "near" || bias == "nearest"
        return bdaily(d, bias=:nearest)
    end

end;

"""
    weekly(d::Date) 
    weekly(d::String)
    weekly(d::Date, end_day::Integer)
    weekly(d::String, end_day::Integer)

These functions return an MIT{Weekly} from a provided Date object or String.
The String must be convertible to a Date object via the `Dates.Date(d::String)` method.

Returns an object of type MIT{Weekly{end_day}} when the end_day argument is provided.

"""
weekly(d::Date) = MIT{Weekly{7}}(Int(ceil(Dates.value(d) / 7)))
weekly(d::String) = MIT{Weekly{7}}(Int(ceil(Dates.value(Date(d)) / 7)))
weekly(d::Date, end_day::Integer) = MIT{Weekly{end_day}}(Int(ceil((Dates.value(d)) / 7)) + max(0, min(1, dayofweek(d) - end_day)))
weekly(d::String, end_day::Integer) = MIT{Weekly{end_day}}(Int(ceil((Dates.value(Date(d))) / 7)) + max(0, min(1, dayofweek(Date(d)) - end_day)))
function weekly_from_iso(y::Int, p::Int)
    if p > 53 || p < 1
        throw(ArgumentError("The provided period must be between 1 and 53 (inclusive)."))
    end
    first_day_of_year = Dates.Date("$(y)-01-01")
    week_of_first_day = week(first_day_of_year)
    year_end_padding = week_of_first_day !== 1 ? 1 : 0
    d2 = first_day_of_year + Day(((p - 1) + year_end_padding) * 7)
    w = weekly(first_day_of_year + Day(((p - 1) + year_end_padding) * 7))
    proposed_mit = weekly(first_day_of_year + Day(((p - 1) + year_end_padding) * 7))
    # sanity checks
    d = Dates.Date(proposed_mit)
    if Dates.year(d) !== y && week(d) < 52
        throw(ArgumentError("The year $(y) does not have a week $(p)."))
    end
    return proposed_mit
end
export weekly, weekly_from_iso

"""
    w_str(d)

A macro which converts a string to an MIT{Weekly{7}} or a UnitRange{MIT{Weekly{7}}}.

To return a UnitRange, provide a single string with two dates separated by `:`.

The resulting week(s) will be the week(s) containing the provided date(s).

Example:
    week_of_christmas = w"2022-12-25"
    week_overlapping_with_february = w"2022-02-01:2022-02-28"
"""
macro w_str(d::String, ed::Integer=7)
    if findfirst(":", d) !== nothing
        dsplit = split(d, ":")
        return weekly(Dates.Date(dsplit[1]), ed):weekly(Dates.Date(dsplit[2]), ed)
    end
    return weekly(d, ed)
end
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
ppy(::Type{<:BDaily}) = 260 # approximately
ppy(::Type{<:Weekly}) = 52 # approximately
ppy(x::Type{<:Frequency}) = error("Frequency $(x) does not have periods per year")

#-------------------------
# date conversion
"""
Dates.Date(m::MIT, ref::Symbol=:end)
    
Returns a Date object representing the last day in the provided MIT.
Returns the first day in the provided MIT when `ref == true`.
"""
Dates.Date(m::MIT{Daily}, values_base::Symbol=:end) = _d0 + Day(Int(m))
Dates.Date(m::MIT{BDaily}, values_base::Symbol=:end) = _d0 + Day(Int(m) + 2 * floor((Int(m) - 1) / 5))
function Dates.Date(m::MIT{Weekly{end_day}}, values_base::Symbol=:end) where {end_day}
    if values_base == :begin
        return _d0 + Day(Int(m) * 7 - 6) - Day(7 - end_day)
    end
    return _d0 + Day(Int(m) * 7) - Day(7 - end_day)
end
function Dates.Date(m::MIT{Monthly}, ref::Symbol=:end)
    year, month = divrem(Int(m), 12)
    if ref == :begin
        return Dates.Date("$year-01-01") + Month(month)
    end
    return Dates.Date("$year-01-01") + Month(month + 1) - Day(1)
end
function Dates.Date(m::MIT{Quarterly{end_month}}, ref::Symbol=:end) where {end_month}
    year, quarter = divrem(Int(m), 4)
    if ref == :begin
        return Dates.Date("$year-01-01") + Month(quarter * 3 - (3 - end_month))
    end
    return Dates.Date("$year-01-01") + Month((quarter + 1) * 3 - (3 - end_month)) - Day(1)
end
function Dates.Date(m::MIT{HalfYearly{end_month}}, ref::Symbol=:end) where {end_month}
    year, half = divrem(Int(m), 2)
    if ref == :begin
        return Dates.Date("$year-01-01") + Month(half * 6 - (6 - end_month))
    end
    return Dates.Date("$year-01-01") + Month((half + 1) * 6 - (6 - end_month)) - Day(1)
end
function Dates.Date(m::MIT{Yearly{end_month}}, ref::Symbol=:end) where {end_month}
    if ref == :begin
        return Dates.Date("$(Int(m))-01-01") - Month(12 - end_month)
    end
    return Dates.Date("$(Int(m) + 1)-01-01") - Month(12 - end_month) - Day(1)
end

MIT{Daily}(d::Dates.Date) = daily(d)
MIT{BDaily}(d::Dates.Date) = bdaily(d)
MIT{BDaily}(d::Dates.Date; bias) = bdaily(d; bias)
MIT{Weekly}(d::Dates.Date) = weekly(d)
MIT{Weekly{end_day}}(d::Dates.Date) where {end_day} = weekly(d, end_day)

#-------------------------
# pretty printing

# Note: We previously overloaded Base.show for the types Quarterly{3},
# HalYearly{6}, Yearly{12}, and Weekly{7}. However, this leads to many
# invalidations which makes code run/compile slowly. We use these
# prettyprint functions instead.
prettyprint_frequency(F::Type{<:Frequency}) = "$F"
prettyprint_frequency(F::Type{Quarterly{3}}) = "Quarterly"
prettyprint_frequency(F::Type{Yearly{12}}) = "Yearly"
prettyprint_frequency(F::Type{HalfYearly{6}}) = "HalfYearly"
prettyprint_frequency(F::Type{Weekly{7}}) = "Weekly"

Base.show(io::IO, m::MIT{Unit}) = print(io, Int(m), 'U')
Base.show(io::IO, m::MIT{Daily}) = print(io, Dates.Date(m))
Base.show(io::IO, m::MIT{BDaily}) = print(io, Dates.Date(m))
function Base.show(io::IO, m::MIT{Weekly{end_day}}) where {end_day}
    print(io, "$(Dates.Date(m))")
end

function Base.show(io::IO, m::MIT{F}) where {F<:YPFrequency{N}} where {N}
    periodletter = N == 1 ? 'Y' :
                   N == 2 ? 'H' :
                   N == 4 ? 'Q' :
                   N == 12 ? 'M' : 'P'
    print(io, year(m), periodletter)
    if N > 1
        # print(io, rpad(period(m), length(string(N))))
        print(io, period(m))
    end
    end_month = endperiod(F)
    if N == 4 && end_month !== 3
        print(io, "{$end_month}")
    end
    if N == 1 && end_month !== 12
        print(io, "{$end_month}")
    end
    if N == 2 && end_month !== 6
        print(io, "{$end_month}")
    end
end

Base.string(m::MIT{<:Frequency}) = repr(m)
Base.print(io::IO, m::MIT{<:Frequency}) = print(io, string(m))

function Base.show(io::IO, r::UnitRange{MIT{F}}, args...) where {F<:Union{<:Weekly,<:Daily,<:BDaily}}
    if !get(io, :compact, false)
        print(io, "$(prettyprint_frequency(F)) ")
    end
    print(io, "$(first(r)):$(last(r))")
end

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
Base.promote_rule(T1::Type{MIT{F}}, ::Type{MIT{F}}) where {F<:Frequency} = T1

# -------------------
# subtraction

# difference of two MIT is a Duration
Base.:(-)(l::MIT, r::MIT) = mixed_freq_error(l, r)
Base.:(-)(l::MIT{F}, r::MIT{F}) where {F<:Frequency} = Duration{F}(Int(l) - Int(r))
# difference of MIT and Duration is an MIT
Base.:(-)(l::MIT, r::Duration) = mixed_freq_error(l, r)
Base.:(-)(l::MIT{F}, r::Duration{F}) where {F<:Frequency} = MIT{F}(Int(l) - Int(r))
# difference of MIT and Integer is an MIT -- the Integer value is interpreted as a Duration of the appropriate frequency
Base.:(-)(l::MIT{F}, r::Integer) where {F<:Frequency} = MIT{F}(Int(l) - Int(r))
# Difference of two Duration is a Duration
Base.:(-)(l::Duration, r::Duration) = mixed_freq_error(l, r)
Base.:(-)(l::Duration{F}) where {F<:Frequency} = Duration{F}(-Int(l))
Base.:(-)(l::Duration{F}, r::Duration{F}) where {F<:Frequency} = Duration{F}(Int(l) - Int(r))
# difference of Duration and Integer is a Duration -- the Integer value is interpreted as a Duration of the same frequency
Base.:(-)(l::Duration{F}, r::Integer) where {F<:Frequency} = Duration{F}(Int(l) - Int(r))

Base.rem(x::Duration, y::Duration) = mixed_freq_error(x, y)
Base.rem(x::Duration{F}, y::Duration{F}) where {F<:Frequency} = Duration{F}(rem(Int(x), Int(y)))
Base.div(x::Duration, y::Duration, args...) = mixed_freq_error(x, y)
Base.div(x::Duration{F}, y::Duration{F}, args...) where {F<:Frequency} = Duration{F}(div(Int(x), Int(y), args...))

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
Base.:(<)(l::MIT{F}, r::MIT{F}) where {F<:Frequency} = Int(l) < Int(r)
Base.:(<)(l::Duration{F}, r::Duration{F}) where {F<:Frequency} = Int(l) < Int(r)
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
Base.:(+)(::Duration, ::MIT) = throw(ArgumentError("Illegal addition of `Duration` and `MIT`. Try `MIT` + `Duration`"))
# addition of two Duration is valid only if they are of the same frequency
Base.:(+)(l::Duration, r::Duration) = mixed_freq_error(l, r)
Base.:(+)(l::Duration{F}, r::Duration{F}) where {F<:Frequency} = Duration{F}(Int(l) + Int(r))
# addition of MIT and Duration gives an MIT
Base.:(+)(l::MIT, r::Duration) = mixed_freq_error(l, r)
Base.:(+)(l::MIT{F}, r::Duration{F}) where {F<:Frequency} = MIT{F}(Int(l) + Int(r))
# addition of MIT or Duration with an Integer yields the same type as the MIT/Duration argument
Base.:(+)(l::Union{MIT,Duration}, r::Integer) = oftype(l, Int(l) + r)
Base.:(+)(l::Integer, r::Union{MIT,Duration}) = oftype(r, l + Int(r))

# NOTE: the rules above are meant to catch illegal arithmetic (where the units don't make sense).
# For indexing and iterating TSeries it's more convenient to return Int rather than Duration, however
# we choose to have the checks in place.

# checkindex, however, needs to work with an Int
Base.checkindex(::Type{Bool}, inds::AbstractUnitRange{<:MIT}, i::Int) = 1 <= i <= length(inds)

# -------------------
# one(x) is meant to be a dimensionless 1, so that's what we do
Base.one(::Union{MIT,Duration,Type{<:MIT},Type{<:Duration}}) = Int(1)

# -------------------
# Conversion to Float64 - that's needed for plotting
(T::Type{<:AbstractFloat})(x::MIT) = convert(T, Int(x))
# In the special case of YPFrequency we want the year to be the whole part and the period to be the fractional part. 
(T::Type{<:AbstractFloat})(x::MIT{<:YPFrequency{N}}) where {N} = convert(T, ((y, p) = mit2yp(x); y + (p - 1) / N))
Base.promote_rule(::Type{<:MIT}, ::Type{T}) where {T<:AbstractFloat} = T

# frequency comparisons
Base.isless(x::Type{<:Frequency}, y::Type{<:Frequency}) = isless(ppy(x), ppy(y))

# needed for comparisons
Base.flipsign(x::Duration{F}, y::Duration{F}) where {F} = flipsign(Int(x), Int(y))
Base.flipsign(x::MIT{F}, y::MIT{F}) where {F} = flipsign(Int(x), Int(y))

# needed for plot math
Base.:(/)(a::Duration, b::Duration) = TimeSeriesEcon.mixed_freq_error(a, b)
Base.:(/)(a::MIT, b::Duration) = TimeSeriesEcon.mixed_freq_error(a, b)
Base.:(/)(a::Duration{F}, b::Duration{F}) where {F<:Frequency} = Int(a) / Int(b)
Base.:(/)(a::MIT{F}, b::Duration{F}) where {F<:Frequency} = (a - MIT{F}(0)) / b
Base.promote_rule(::Type{<:Duration}, ::Type{T}) where {T<:AbstractFloat} = T
(T::Type{<:AbstractFloat})(x::Duration) = convert(T, Int(x))

# ----------------------------------------
# 2.2 MIT{T} vector and dict support
# ----------------------------------------

# added so MIT can be used as dictionary keys
Base.hash(x::Union{MIT,Duration}, h::UInt) = hash((typeof(x), Int(x)), h)

# # added for sorting Vector{MIT{T}} where T <: Frequency
# Base.sub_with_overflow(x::MIT{T}, y::MIT{T}) where T <: Frequency = begin
#     Base.checked_ssub_int(reinterpret(Int, x), reinterpret(Int, y))
# end

# ----------------------------------------
# 4 Convenience constants
# ----------------------------------------

struct _FConst{F<:Frequency} end
struct _FPConst{F<:Frequency,P} end
Base.:(*)(y::Integer, ::_FConst{F}) where {F<:Frequency} = MIT{F}(y)
Base.:(*)(y::Integer, ::_FPConst{F,P}) where {F<:Frequency,P} = MIT{F}(y, P)

Base.show(io::IO, C::_FConst) = print(io, 1C)
Base.show(io::IO, C::_FPConst) = print(io, 1C)

""" 

Convenience constants that make MIT literal constants possible. For example, the
constant `Q1` makes it possible to write `2020Q1` instead of
`MIT{Quarterly}(2020, 1)`. Use `U` for `MIT{Unit}`, `Y` for `MIT{Yearly}`, `Q1`
to `Q4` for `MIT{Quarterly}` and `M1` to `M12` for `MIT{Monthly}`

"""
Y, U, Q1, Q2, Q3, Q4, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12
export Y, U, H1, H2, Q1, Q2, Q3, Q4, M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12


const global U = _FConst{Unit}()
const global M1 = _FPConst{Monthly,1}()
const global M2 = _FPConst{Monthly,2}()
const global M3 = _FPConst{Monthly,3}()
const global M4 = _FPConst{Monthly,4}()
const global M5 = _FPConst{Monthly,5}()
const global M6 = _FPConst{Monthly,6}()
const global M7 = _FPConst{Monthly,7}()
const global M8 = _FPConst{Monthly,8}()
const global M9 = _FPConst{Monthly,9}()
const global M10 = _FPConst{Monthly,10}()
const global M11 = _FPConst{Monthly,11}()
const global M12 = _FPConst{Monthly,12}()


# ----------------------------------------
# 5 Ranges of MIT
# ----------------------------------------

Base.:(:)(start::MIT, stop::MIT) = mixed_freq_error(start, stop)
Base.:(:)(start::MIT{F}, stop::MIT{F}) where {F<:Frequency} = UnitRange{MIT{F}}(start, stop)

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
Base.union(l::UnitRange{MIT{F}}, r::UnitRange{MIT{F}}) where {F<:Frequency} = min(first(l), first(r)):max(last(l), last(r))

# Base.issubset(l::UnitRange{<:MIT}, r::UnitRange{<:MIT}) = false
# Base.issubset(l::UnitRange{MIT{F}}, r::UnitRange{MIT{F}}) where F <: Frequency = first(r) <= first(l) && last(l) <= last(r)

#------------------------------
# sort!() a list of MITs
Base.sort!(a::AbstractVector{<:MIT}, args...; kwargs...) = (sort!(reinterpret(Int, a), args...; kwargs...); a)

## endperiod
endperiod(F::Type{<:Frequency}) = 1
endperiod(::Type{Weekly{end_day}}) where {end_day} = end_day
endperiod(::Type{Quarterly{end_month}}) where {end_month} = end_month
endperiod(::Type{HalfYearly{end_month}}) where {end_month} = end_month
endperiod(::Type{Yearly{end_month}}) where {end_month} = end_month

## default_frequency
"""
    sanitize_frequency(F::Frequency)

Return a concrete frequency type corresponding to the given, possibly abstract,
frequency type. If `F` is already a concrete type, return `F` itself. Otherwise,
if a default concrete frequency exists for the given abstract type, return that.

For example, the default `Quarterly` frequency is `Quarterly{3}`.
"""
sanitize_frequency(F::Type{<:Frequency}) = F
sanitize_frequency(::Type{Weekly}) = Weekly{7}
sanitize_frequency(::Type{Quarterly}) = Quarterly{3}
sanitize_frequency(::Type{HalfYearly}) = HalfYearly{6}
sanitize_frequency(::Type{Yearly}) = Yearly{12}
export sanitize_frequency, prettyprint_frequency
