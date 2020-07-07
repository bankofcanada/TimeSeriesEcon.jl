const IntOrFloat = Union{Int64, Float64}

#-------------------------------------------------------------------------------
# Series struct and constructors
#-------------------------------------------------------------------------------

"""
`Series{T <: Frequency}(firstdate::MIT{T}, values::Vector{Float64})`
Initialize a time-series structure by providing first date and vector

"""
mutable struct Series{T <: Frequency} <: AbstractVector{Float64}
    firstdate::MIT{T}
    values::Vector{Float64}
end

# Important to provide == , AbstractArrays's own equality only depends on the array values
# However, in our case, ts1.values & ts2.values might be similar, but firstdates different
function Base.:(==)(x::Series{T}, y::Series{T}) where T <: Frequency
    return x.firstdate == y.firstdate && isequal(x.values, y.values)
end

# Series constructor for values == Vector{Int64}
function Series(fd::MIT{T}, v::Vector{Int64}) where T <: Frequency
    Series{T}(fd, Vector{Float64}(v))
end

# Series constructor with a range
function Series(I::UnitRange{MIT{T}}, V::Vector{S}) where T <: Frequency where S <: IntOrFloat
    # check that I and v have the same length
    Int64(I.stop - I.start) + 1 == length(V) || error("Date range and vector length don't match.")
    # use the inner constructor
    Series{T}(I.start, V)
end

# Series constructor with a range and a single value
function Series(I::UnitRange{MIT{T}}, v::Number) where T <: Frequency 
    # use the inner constructor
    Series{T}(I.start, fill(Float64(v), length(I)))
end

#-------------------------------------------------------------------------------
# Base.show
#-------------------------------------------------------------------------------

# printing inline
Base.show(io::IO, ::MIME"text/plain", ts::Series{T}) where T <: Frequency = begin
    println(io, "Series{", T, "} of length ", length(ts))

    for (i, v) in zip(ts.firstdate:ts.firstdate + length(ts) - 1, ts.values)
        println(io, i, ": ", v)
    end
end

#printing in repl
Base.show(io::IO, ts::Series{T}) where T <: Frequency = begin
    println(io, "Series{", T, "} of length ", length(ts))

    for (i, v) in zip(ts.firstdate:ts.firstdate + length(ts) - 1, ts.values)
        println(io, i, ": ", v)
    end
end

#-------------------------------------------------------------------------------
# Base.getindex and Base.setindex
#-------------------------------------------------------------------------------


"""
    Since `Series` struct is a subtype of `AbstractVector{Float64}`, the
    following methods must be defined:
        - size (automatically gives us the definition of `length`)
        - getindex
        - setindex!

"""
Base.size(ts::Series{T}) where T <: Frequency = (length(ts.values), )
Base.getindex(ts::Series{T}, i::Int64) where T <: Frequency = ts.values[i]
Base.setindex!(ts::Series{T}, v::IntOrFloat, i::Int64) where T <: Frequency = begin
    ts.values[i] = v
end

Base.getindex(ts::Series{T}, i::MIT{T}) where T <: Frequency = begin
    # Return empty series if `i` outside of ts index bounds
    if i < ts.firstdate || i > ts.firstdate + length(ts) - 1
        # println("warning: $i is outside range")
        return nothing
    end

    i_int = i - ts.firstdate + 1
    # return Series(i, [ts.values[i_int]])
    ts[i_int]
end

Base.getindex(s::Series{T},v::Vector{TSeries.MIT{T}}) where T <: Frequency = begin
    [s[i] for i in v]
end

Base.getindex(ts::Series{T}, I::UnitRange{MIT{T}}) where T <: Frequency = begin

    I_int = I .- ts.firstdate |>
        x -> Int64(x.start):Int64(x.stop) |>
        x -> x .+ 1

    I_common = intersect(I_int, 1:length(ts))

    if !(I_common.start <= I_common.stop)
        println("Warning: $I is

         or fully outside of Series bounds $(mitrange(ts)).")
        return nothing
    end

    new_firstdate = MIT{T}(Int64(ts.firstdate) + I_common.start - 1)

    return Series(new_firstdate, ts.values[I_common])
end

Base.setindex!(ts::Series{T}, v::IntOrFloat, mit::MIT{T}) where T <: Frequency = begin
    # Step 1.1: find the `distance` between
    #        - mit::MIT{T} and
    #        - ts.firstdate::MIT{T}
    # Step 1.2: convert `distance::MIT{T}` into `distance::Int64`
    distance = mit - ts.firstdate + 1

    # Step 2: 'vectorify' v::IntOrFloat to append in place to ts.values::Vector{Float64}
    #         in Case 2 and 3
    v_singleton = Vector{Float64}([v])

    if 1 <= distance <= length(ts) # Case 1: place v in an array
        ts.values[distance] = Float64(v)
    elseif distance < 1            # Case 2: extend ts.values on the left side
        val_nan_vector = append!(v_singleton, fill(NaN, abs(distance)))
        prepend!(ts.values, val_nan_vector)
        ts.firstdate = mit
    else # length(ts) < distance   # Case 3: extend ts.values on the right side
        nan_val_vector = append!(fill(NaN, abs(distance) - length(ts) - 1), v_singleton)
        append!(ts.values, nan_val_vector)
    end
end

Base.setindex!(ts::Series{T}, v::IntOrFloat, I::UnitRange{MIT{T}}) where T <: Frequency = begin
    for i in I
        ts[i] = v
    end
end


Base.setindex!(ts::Series{T}, v::Vector{Float64}, I::UnitRange{MIT{T}}) where T <: Frequency = begin
    for (i, val) in zip(I, v)
        ts[i] = val
    end
end

Base.setindex!(ts::Series{T}, v::Vector{Int64}, I::UnitRange{MIT{T}}) where T <: Frequency = begin
    for (i, val) in zip(I, v)
        ts[i] = val
    end
end



# assign TSeries to another Tseries over mit and unit range of mit
Base.setindex!(ts::Series{T}, v::Series{T}, mit::MIT{T}) where T <: Frequency = begin
    mit in ts.firstdate:lastdate(ts) || error("Given date:$mit is not in ", ts)
    mit in v.firstdate:lastdate(v) || error("Given date:$mit is not in ", v)

    ts[mit] = v[mit].values[1]
end

Base.setindex!(ts::Series{T}, v::Vector{S}, mit::MIT{T}) where T <: Frequency where S <: Union{Int64, Float64}= begin
    length(v) == 1 || error(v, " can contain only one element.")

    ts[mit] = v[mit][1]
end


Base.setindex!(ts::Series{T}, v::Series{T}, I::UnitRange{MIT{T}}) where T <: Frequency = begin

    commonrange = intersect(I, mitrange(v))

    ts[commonrange] = v[commonrange].values
end

#-------------------------------------------------------------------------------
# Operations
#-------------------------------------------------------------------------------
firstdate(s::Series{T}) where T <: Frequency = s.firstdate

function lastdate(x::Series{T}) where T <: Frequency
    return x.firstdate + length(x) - 1
end

export firstdate, lastdate

# [ts1 ts2] -> returns a DataFrame
# double for loop might need to be modified in the future
function Base.hcat(tuple_of_ts::Vararg{Series{T}, N}) where T <: Frequency where N
    firstdate = [i.firstdate for i in tuple_of_ts] |> minimum
    lastdate  = [TSeries.lastdate(i) for i in tuple_of_ts] |> maximum

    holder = Array{Float64, 1}()

    for ts in tuple_of_ts
        for date in firstdate:lastdate
            if ts[date] == nothing
                v = [NaN]
            else
                v = ts[date]
            end

            append!(holder, v)
        end
    end

    reshaped_array = reshape(holder, (length(firstdate:lastdate), length(tuple_of_ts)))

    # removed DataFrames dependency
    df = reshaped_array

    return  df
end

function mitrange(ts::Series{T}) where T <: Frequency
    return ts.firstdate:lastdate(ts)
end

function Base.:(+)(x::Series{T}, y::Series{T}) where T <: Frequency
    # I = intersect(x.firstdate:lastdate(x), y.firstdate:lastdate(y))
    I = intersect(mitrange(x), mitrange(y))

    I.start <= I.stop || error("There are no dates in common, operation can't be performed.")
    Series{T}(I.start, x[I].values + y[I].values)
end

function Base.:(-)(x::Series{T}, y::Series{T}) where T <: Frequency
    # I = intersect(x.firstdate:lastdate(x), y.firstdate:lastdate(y))
    I = intersect(mitrange(x), mitrange(y))
    I.start <= I.stop || error("There are no dates in common, operation can't be performed.")
    Series{T}(I.start, x[I].values - y[I].values)
end

function Base.:(-)(x::IntOrFloat, y::Series{T}) where T <: Frequency

    Series{T}(y.firstdate, x .- y)
end

Base.:(-)(s::Series{T}) where T <: Frequency = Series(s.firstdate, -s.values)


Base.log(ts::Series{T}) where T <: Frequency = Series(ts.firstdate, log.(ts.values))
Base.exp(ts::Series{T}) where T <: Frequency = Series(ts.firstdate, exp.(ts.values))
Base.:(+)(ts::Series{T}, a::Number) where T <: Frequency = Series(ts.firstdate, ts.values .+ a)
Base.:(+)(a::Number, ts::Series{T}) where T <: Frequency = Series(ts.firstdate, ts.values .+ a)

Base.:(-)(ts::Series{T}, a::Number) where T <: Frequency = Series(ts.firstdate, ts.values .- a)

"""
Same as Iris implementation of diff
"""
function Base.diff(ts::Series{T}, k::Int64 = -1) where T <: Frequency
    y = deepcopy(ts);

    y.firstdate = y.firstdate - k

    return ts - y
end

"""
    3 * ts
    ts * 3 returns timeseries with every element multiplied by 3
"""
function Base.:(*)(ts::Series{T}, s::IntOrFloat) where T <: Frequency
    Series(ts.firstdate, ts.values .* s)
end

function Base.:(*)(s::IntOrFloat, ts::Series{T}) where T <: Frequency
    Series(ts.firstdate, ts.values .* s)
end

"""
    ts / 3 returns timeseries with every element divided by 3
"""
function Base.:(/)(ts::Series{T}, s::IntOrFloat) where T <: Frequency
    Series(ts.firstdate, ts.values ./ s)
end

function Base.:(/)(s::IntOrFloat, ts::Series{T}) where T <: Frequency
    Series(ts.firstdate, s ./ ts.values)
end

function Base.:(^)(ts::Series{T}, s::IntOrFloat) where T <: Frequency
    Series(ts.firstdate, ts.values .^ s)
end

# function pct(ts::Series{T}) where T <: Frequency
#
# end


"""
    shift/shift! firstdate by k::Int64 periods
"""
function shift(ts::Series{T}, k::Int64) where T <: Frequency
    return Series(ts.firstdate - k, ts.values)
end

function shift!(ts::Series{T}, k::Int64) where T <: Frequency
    ts.firstdate = ts.firstdate - k
    return ts
end

"""
pct, apct, round, ppy
"""
ppy(m::MIT{T}) where T <: Frequency = ppy(T)

function ppy(ts::Series{T}) where T <: Frequency
    ppy(T)
end
export ppy

function Base.:(/)(x::Series{T}, y::Series{T}) where T <: Frequency
    I = intersect(mitrange(x), mitrange(y))

    firstdate = I.start;
    values = x[I].values./y[I].values;

    Series(firstdate, values)
end

function Base.:(*)(x::Series{T}, y::Series{T}) where T <: Frequency
    I = intersect(mitrange(x), mitrange(y))

    firstdate = I.start;
    values = x[I].values.*y[I].values;

    Series(firstdate, values)
end

function pct(ts::Series{T}, shift_value::Int64; islog::Bool = false) where T <: Frequency
    if islog
        a = exp(ts);
        b = shift(exp(ts), shift_value);
    else
        a = ts;
        b = shift(ts, shift_value);
    end

    # firstdate = mitrange(a - b)
    result = ( (a - b)/b ) * 100

    Series(result.firstdate, result.values)
end

export pct

Base.round(ts::Series{T}; digits = 2) where T <: Frequency = begin
    values = (x -> round(x, digits=digits)).(ts.values)
    Series(ts.firstdate, values)
end

function apct(ts::Series{T}, islog::Bool = false) where T <: Frequency
    if islog
        a = exp(ts);
        b = shift(exp(ts), - 1);
    else
        a = ts;
        b = shift(ts, -1);
    end

    values_change = a/b
    firstdate = values_change.firstdate

    values = (values_change.^ppy(ts) .- 1) * 100

    Series( (a/b).firstdate, values)
end
export apct

function Base.cumsum(s::Series{T}) where T <: Frequency
    Series(s.firstdate, cumsum(s.values))
end

function Base.cumsum!(s::Series{T}) where T <: Frequency
    s.values = cumsum(s.values)
    return s
end


"""
rm nans
"""

function leftcropnan!(s::Series{T}) where T <: Frequency
    while isequal(s[firstdate(s)], NaN)
        popfirst!(s.values)
        s.firstdate = s.firstdate + 1
    end
    return s
end


function rightcropnan!(s::Series{T}) where T <: Frequency
    while isequal(s[lastdate(s)], NaN)
        pop!(s.values)
    end
    return s
end

function nanrm!(s::Series{T}, type::Symbol=:both) where T <: Frequency
    if type == :left
        leftcropnan!(s)
    elseif type == :right
        rightcropnan!(s)
    elseif type == :both
        leftcropnan!(s)
        rightcropnan!(s)
    else
        error("Please select between :left, :right, or :both.")
    end
    return s
end


export nanrm!
