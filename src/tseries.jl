#-------------------------------------------------------------------------------
# TSeries struct and constructors
#-------------------------------------------------------------------------------

"""
    TSeries

Data structure representing a time-series vector. The following 
operations are allowed:

 - indexing using `MIT` (aka "moment-in-time") and `UnitRange{MIT}`
 - assignment using `MIT` and `UnitRange{MIT}`

In addition, most of the operations available to Julia vectors (+, -, *, etc.)
are supported by `TSeries` as well.

### Examples
 - Create `TSeries`
```julia-repl
julia> x = TSeries(qq(2020, 1), ones(4))
TSeries{Quarterly} of length 4
2020Q1: 1.0
2020Q2: 1.0
2020Q3: 1.0
2020Q4: 1.0
```

 - Index into `TSeries`
```julia-repl
julia> x[2000Q1]
1.0

julia> x[qq(2020, 1):qq(2020, 2)]
TSeries{Quarterly} of length 2
2020Q1: 1.0
2020Q2: 1.0
```

- Assignment using `MIT`
```julia-repl
julia> x[qq(2020, 1)] = 100; x
TSeries{Quarterly} of length 4
2020Q1: 100.0
2020Q2: 1.0
2020Q3: 1.0
2020Q4: 1.0

julia> x[qq(2020, 1):qq(2020, 2)] = 100; x
TSeries{Quarterly} of length 4
2020Q1: 100.0
2020Q2: 100.0
2020Q3: 1.0
2020Q4: 1.0
```

 - Arithmetic Operations on `TSeries`
```julia-repl
julia> x = TSeries(qq(2020, 1), ones(4))
TSeries{Quarterly} of length 4
2020Q1: 1.0
2020Q2: 1.0
2020Q3: 1.0
2020Q4: 1.0

julia> 2*x + 98
TSeries{Quarterly} of length 4
2020Q1: 100.0
2020Q2: 100.0
2020Q3: 100.0
2020Q4: 100.0

julia> log(exp(x))
TSeries{Quarterly} of length 4
2020Q1: 1.0
2020Q2: 1.0
2020Q3: 1.0
2020Q4: 1.0
```
"""
mutable struct TSeries{T <: Frequency, C <: AbstractVector{Float64}} <: AbstractVector{Float64}
    firstdate::MIT{T}
    values::C
end

# We work only with Float64. All other numbers are converted to it.
# Might be inefficient
TSeries(fd::MIT, v::AbstractVector{<:Number}) = TSeries(fd, Vector{Float64}(v))

TSeries(v::AbstractVector{<:Number}) = TSeries(1U, v)

TSeries(I::AbstractUnitRange{<:MIT}) = TSeries(first(I), Vector{Float64}(undef, length(I)))
TSeries(I::AbstractUnitRange{<:MIT}, ::UndefInitializer) = TSeries(I)

# TSeries constructor with a range and data
function TSeries(I::AbstractUnitRange{<:MIT}, V::AbstractVector{<:Number})
    if length(I) ≠ length(V)
        throw(ArgumentError("Range and data lengths don't match."))
    end
    TSeries(first(I), V)
end

# TSeries constructor with a range and a single value
function TSeries(I::AbstractUnitRange{<:MIT}, v::Number)
    # use the inner constructor
    TSeries(first(I), fill(Float64(v), length(I)))
end

#-------------------------------------------------------------------------------
# Base.show
#-------------------------------------------------------------------------------

Base.summary(io::IO, t::TSeries) = isempty(t) ? 
        print(io, "Empty ", frequencyof(t), " TSeries") : 
        print(IOContext(io, :compact=>true), length(t.values), "-element ", frequencyof(t), " TSeries from ", t.firstdate)

Base.show(io::IO, ::MIME"text/plain", t::TSeries) = show(io, t)
function Base.show(io::IO, t::TSeries)
    summary(io, t)
    isempty(t) && return
    print(io, ":")
    limit = get(io, :limit, true)
    nval = length(t.values)
    from = t.firstdate
    nrow, ncol = displaysize(io)
    if limit && nval > nrow - 5
        top = div(nrow - 5, 2)
        bot = nval - nrow + 6 + top
        for i = 1:top
            print(io, "\n", lpad(from+(i-1), 8), " : ", t.values[i])
        end
        print(io, "\n    ⋮")
        for i = bot:nval
            print(io, "\n", lpad(from+(i-1), 8), " : ", t.values[i])
        end
    else
        for i = 1:nval
            print(io, "\n", lpad(from+(i-1), 8), " : ", t.values[i])
        end
    end
end

#-------------------------------------------------------------------------------
# Base.getindex and Base.setindex
#-------------------------------------------------------------------------------


# """
# Since `TSeries` is a subtype of `AbstractVector`, we have to provide implementations for `size`, `getindex`, and `setindex!`
# """
Base.:(==)(x::TSeries{T}, y::TSeries{T}) where T <: Frequency = (x.firstdate == y.firstdate && isequal(x.values, y.values))
Base.size(ts::TSeries) = size(ts.values)

# Indexing with plain integers simply indexes within the values 
Base.getindex(ts::TSeries, i::Int64) = getindex(ts.values, i)
Base.getindex(ts::TSeries, I::AbstractUnitRange{Int}) = TSeries(firstdate(ts) - 1 .+ I, getindex(ts.values, I))
Base.getindex(ts::TSeries, I::AbstractVector{Int}) = getindex(ts.values, I)
Base.setindex!(ts::TSeries, v::Number, i::Int64) = setindex!(ts.values, v, i)
Base.setindex!(ts::TSeries, v::Number, I::AbstractUnitRange{Int}) = ts.values[I] .= v
Base.setindex!(ts::TSeries, v::Number, I::AbstractVector{Int}) = ts.values[I] .= v
Base.setindex!(ts::TSeries{F}, v::TSeries{F}, I::AbstractUnitRange{Int}) where F <: Frequency = ts.values[I] .= v.values
Base.setindex!(ts::TSeries{F}, v::TSeries{F}, I::AbstractVector{Int}) where F <: Frequency = ts.values[I] .= v.values
Base.setindex!(ts::TSeries, v, I::AbstractUnitRange{Int}) = setindex!(ts.values, v, I)
Base.setindex!(ts::TSeries, v, I::AbstractVector{Int}) = setindex!(ts.values, v, I)



Base.axes(t::TSeries) = (mitrange(t),)
Base.axes1(t::TSeries) = mitrange(t)
Base.axes(r::AbstractUnitRange{<:MIT}) = (r,)
Base.axes1(r::AbstractUnitRange{<:MIT}) = r
Base.getindex(r::AbstractUnitRange{<:MIT}, I::AbstractUnitRange{Int}) = r[first(I)]:r[last(I)]
Base.getindex(r::AbstractUnitRange{<:MIT}, I::AbstractVector{Int}) = [r[i] for i in I]

function Base.view(t::TSeries, I::AbstractUnitRange{<:Integer})
    if !<:(eltype(I), MIT)
        I = firstdate(t) - 1 .+ I
    end
    @boundscheck  checkbounds(t, I)
    TSeries(I, @inbounds view(t.values, I .- t.firstdate .+ 1))
end

Base.similar(t::TSeries) = TSeries(firstdate(t), similar(getfield(t, :values)))
Base.dataids(t::TSeries) = Base.dataids(getfield(t, :values))
Base.IndexStyle(::TSeries) = IndexLinear()

"""
`getindex` using `MIT`
"""
Base.getindex(ts::TSeries{T}, i::MIT{T}) where T <: Frequency = begin
    # return `nothing` if accessing outside of the `ts` range
    if i < ts.firstdate || i > ts.firstdate + length(ts) - 1
        return nothing
    end

    i_int = i - ts.firstdate + 1
    ts[i_int]
end

"""
`getindex` using `Vector{MIT}`. Note the difference between `Vector{MIT}` and `UnitRange{MIT}`
"""
Base.getindex(s::TSeries{T},v::AbstractVector{MIT{T}}) where T <: Frequency = begin
    [s[i] for i in v]
end

"""
`getindex` using `UnitRange{MIT}`
"""
Base.getindex(ts::TSeries{T}, I::AbstractUnitRange{MIT{T}}) where T <: Frequency = begin

    I_int = I .- ts.firstdate .+ 1

    I_common = intersect(I_int, 1:length(ts))

    if I_common.start > I_common.stop
        println("Warning: $I is outside of TSeries bounds $(mitrange(ts)).")
        return nothing
    end

    firstdate_new = MIT{T}(Int64(ts.firstdate) + I_common.start - 1)

    return TSeries(firstdate_new, ts.values[I_common])
end

"""
`setindex` a value using `MIT`
"""
Base.setindex!(ts::TSeries{T}, v::Number, mit::MIT{T}) where T <: Frequency = begin
    # Step 1: find the `distance` between
    # - mit::MIT{T} and
    # - ts.firstdate::MIT{T}
    distance = mit - ts.firstdate + 1

    # Step 2: vectorize v::IntOrFloat to append in place to ts.values::Vector{Float64}
    # in Case 2 and 3
    v_singleton = Vector{Float64}([v])

    if 1 <= distance <= length(ts)          # Case 1: place v in an array
        ts.values[distance] = Float64(v)
    elseif distance < 1                     # Case 2: extend ts.values on the left side
        val_nan_vector = append!(v_singleton, fill(NaN, abs(distance)))
        prepend!(ts.values, val_nan_vector)
        ts.firstdate = mit
    else # length(ts) < distance            # Case 3: extend ts.values on the right side
        nan_val_vector = append!(fill(NaN, abs(distance) - length(ts) - 1), v_singleton)
        append!(ts.values, nan_val_vector)
    end
end

"""
`setindex` a value using `UnitRange{MIT}`
"""
Base.setindex!(ts::TSeries{T}, v::Number, I::AbstractUnitRange{MIT{T}}) where T <: Frequency = begin
    for i in I
        ts[i] = v
    end
end

"""
`setindex` a vector using `UnitRange{MIT}`
"""
Base.setindex!(ts::TSeries{T}, v::AbstractVector{<:Number}, I::AbstractUnitRange{MIT{T}}) where T <: Frequency = begin
    for (i, val) in zip(I, v)
        ts[i] = val
    end
end

# Base.setindex!(ts::TSeries{T}, v::Vector{Int64}, I::UnitRange{MIT{T}}) where T <: Frequency = begin
#     for (i, val) in zip(I, v)
#         ts[i] = val
#     end
# end



"""
`setindex` values from other `TSeries` using `MIT`
"""
Base.setindex!(ts::TSeries{T}, v::TSeries{T}, mit::MIT{T}) where T <: Frequency = begin
    mit in ts.firstdate:lastdate(ts) || error("Given date:$mit is not in ", ts)
    mit in v.firstdate:lastdate(v) || error("Given date:$mit is not in ", v)

    ts[mit] = v[mit].values[1]
end

"""
`setindex` values from other `TSeries` using `UnitRange{MIT}`
"""
Base.setindex!(ts::TSeries{T}, v::TSeries{T}, I::AbstractUnitRange{MIT{T}}) where T <: Frequency = begin
    commonrange = intersect(I, mitrange(v))
    ts[commonrange] = v[commonrange].values
end

# """
# `setindex` values from other `Vector` using `MIT`
# """
# Base.setindex!(ts::TSeries{T}, v::AbstractVector{<:Number}, mit::MIT{T}) where T <: Frequency = begin
#     length(v) == 1 || error(v, " can contain only one element.")
#     ts[mit] = v[mit][1]
# end

#-------------------------------------------------------------------------------
# Operations
#-------------------------------------------------------------------------------

"""
    firstdate(x::TSeries)

Return an `MIT` indicating the first date in the TSeries.

### Examples
```julia-repl
julia> firstdate(TSeries(qq(2020, 1), ones(10)))
2020Q1
```
"""
firstdate(s::TSeries) = s.firstdate

"""
    lastdate(x::TSeries)

Return an `MIT` indicating the last date in the TSeries.

### Examples
```julia-repl
julia> lastdate(TSeries(qq(2020, 1), ones(10)))
2022Q2
```
"""
lastdate(s::TSeries) = (s.firstdate + length(s) - 1)

# 
# Base.range(t::TSeries) = firstdate(t):lastdate(t)

"""
    Horizonatal Concatenation of `TSeries`

### Examples
```julia-repl
julia> a = TSeries(ii(1), ones(3));
julia> b = TSeries(ii(2), ones(3));
julia> [a b]
4×2 Array{Float64,2}:
   1.0  NaN
   1.0    1.0
   1.0    1.0
 NaN      1.0

```
"""
function Base.hcat(tuple_of_ts::Vararg{TSeries{T}, N}) where T <: Frequency where N
    firstdate = [i.firstdate for i in tuple_of_ts] |> minimum
    lastdate  = [TimeSeriesEcon.lastdate(i) for i in tuple_of_ts] |> maximum

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

    return  reshaped_array
end

"""
    mitrange(x::TSeries)

Return an `UnitRange{MIT{<:Frequency}}` associated with `x`.

### Examples
```julia-repl
julia> mitrange(TSeries(qq(2020, 1), ones(4)))
2020Q1:2020Q4
```
"""
mitrange(ts::TSeries) = firstdate(ts):lastdate(ts)

function Base.:(+)(x::TSeries{T}, y::TSeries{T}) where T <: Frequency
    # I = intersect(x.firstdate:lastdate(x), y.firstdate:lastdate(y))
    I = intersect(mitrange(x), mitrange(y))

    I.start <= I.stop || error("There are no dates in common, operation can't be performed.")
    TSeries(I.start, x[I].values + y[I].values)
end

function Base.:(-)(x::TSeries{T}, y::TSeries{T}) where T <: Frequency
    # I = intersect(x.firstdate:lastdate(x), y.firstdate:lastdate(y))
    I = intersect(mitrange(x), mitrange(y))
    I.start <= I.stop || error("There are no dates in common, operation can't be performed.")
    TSeries(I.start, x[I].values - y[I].values)
end

function Base.:(-)(x::Number, y::TSeries)
    TSeries(y.firstdate, Float64(x) .- y)
end

Base.:(-)(s::TSeries{T}) where T <: Frequency = TSeries(s.firstdate, -s.values)


Base.log(ts::TSeries{T}) where T <: Frequency = TSeries(ts.firstdate, log.(ts.values))
Base.exp(ts::TSeries{T}) where T <: Frequency = TSeries(ts.firstdate, exp.(ts.values))
Base.:(+)(ts::TSeries{T}, a::Number) where T <: Frequency = TSeries(ts.firstdate, ts.values .+ a)
Base.:(+)(a::Number, ts::TSeries{T}) where T <: Frequency = TSeries(ts.firstdate, ts.values .+ a)

Base.:(-)(ts::TSeries{T}, a::Number) where T <: Frequency = TSeries(ts.firstdate, ts.values .- a)

"""
    diff(x::TSeries, k::Int64 = -1)

Same as Iris implementation of diff
"""
function Base.diff(ts::TSeries{T}, k::Int64 = -1) where T <: Frequency
    y = deepcopy(ts);

    y.firstdate = y.firstdate - k

    return ts - y
end

"""
    3 * ts
    ts * 3 returns timeseries with every element multiplied by 3
"""
function Base.:(*)(ts::TSeries{T}, s::Number) where T <: Frequency
    TSeries(ts.firstdate, ts.values .* Float64(s))
end

function Base.:(*)(s::Number, ts::TSeries{T}) where T <: Frequency
    TSeries(ts.firstdate, ts.values .* Float64(s))
end

"""
    ts / 3 returns timeseries with every element divided by 3
"""
function Base.:(/)(ts::TSeries{T}, s::Number) where T <: Frequency
    TSeries(ts.firstdate, ts.values ./ Float64(s))
end

function Base.:(/)(s::Number, ts::TSeries{T}) where T <: Frequency
    TSeries(ts.firstdate, Float64(s) ./ ts.values)
end

function Base.:(^)(ts::TSeries{T}, s::Number) where T <: Frequency
    TSeries(ts.firstdate, ts.values .^ s)
end



"""
    shift(x::TSeries, n::Int64)

Shift dates of `x` back by `k` periods. 
__Note:__ The implementation of is similar to IRIS `ts{1}`.

Examples
```julia-repl
julia> shift(TSeries(qq(2020, 1), ones(4)), 1)
TSeries{Quarterly} of length 4
2019Q4: 1.0
2020Q1: 1.0
2020Q2: 1.0
2020Q3: 1.0


julia> shift(TSeries(qq(2020, 1), ones(4)), -1)
TSeries{Quarterly} of length 4
2020Q2: 1.0
2020Q3: 1.0
2020Q4: 1.0
2021Q1: 1.0
```

See also: [`shift!`](@ref)
"""
function shift(ts::TSeries{T}, k::Int64) where T <: Frequency
    return TSeries(ts.firstdate - k, ts.values)
end

"""
    shift!(x::TSeries, n::Int64)

Shift dates of `x` back by `k` periods, in-place. 
__Note:__ The implementation of is similar to IRIS `ts{1}`.

Examples
```julia-repl
julia> x = TSeries(qq(2020, 1), ones(4));

julia> shift!(x, 1);

julia> x
TSeries{Quarterly} of length 4
2019Q4: 1.0
2020Q1: 1.0
2020Q2: 1.0
2020Q3: 1.0
```

See also: [`shift`](@ref)
"""
function shift!(ts::TSeries{T}, k::Int64) where T <: Frequency
    ts.firstdate = ts.firstdate - k
    return ts
end

"""
    ppy(::MIT)
    ppy(::Type{MIT})

When applied to an [`MIT`](@ref) instance or type, return the `ppy` of its frequency.
"""
ppy(::MIT{F}) where F <: Frequency = ppy(F)
ppy(::Type{MIT{F}}) where F <: Frequency = ppy(F)

"""
    ppy(::TSeries)
    ppy(::Type{TSeries})

When applied to a [`TSeries`](@ref) instance or type, return the `ppy` of its frequency.
"""
ppy(::TSeries{T}) where T <: Frequency = ppy(T)
ppy(::Type{TSeries{T}}) where T <: Frequency = ppy(T)


function Base.:(/)(x::TSeries{T}, y::TSeries{T}) where T <: Frequency
    I = intersect(mitrange(x), mitrange(y))

    firstdate = I.start;
    values = x[I].values./y[I].values;

    TSeries(firstdate, values)
end

function Base.:(*)(x::TSeries{T}, y::TSeries{T}) where T <: Frequency
    I = intersect(mitrange(x), mitrange(y))

    firstdate = I.start;
    values = x[I].values.*y[I].values;

    TSeries(firstdate, values)
end

"""
    pct(x::TSeries, shift_value::Int64, islog::Bool)

Calculate percentage growth in `x` given a `shift_value`.

__Note:__ The implementation is similar to IRIS.

Examples
```julia-repl
julia> x = TSeries(yy(2000), Vector(1:4));

julia> pct(x, -1)
TSeries{Yearly} of length 3
2001Y: 100.0
2002Y: 50.0
2003Y: 33.33333333333333
```
See also: [`apct`](@ref)
"""
function pct(ts::TSeries, shift_value::Int64; islog::Bool = false)
    if islog
        a = exp(ts);
        b = shift(exp(ts), shift_value);
    else
        a = ts;
        b = shift(ts, shift_value);
    end

    result = ( (a - b)/b ) * 100

    TSeries(result.firstdate, result.values)
end

Base.round(ts::TSeries; digits = 2) = begin
    values = (x -> round(x, digits=digits)).(ts.values)
    TSeries(ts.firstdate, values)
end

"""
    apct(x::TSeries, islog::Bool)

Calculate annualised percent rate of change in `x`.

__Note:__ The implementation is similar to IRIS.

Examples
```julia-repl
julia> x = TSeries(qq(2018, 1), Vector(1:8));

julia> apct(x)
TSeries{Quarterly} of length 7
2018Q2: 1500.0
2018Q3: 406.25
2018Q4: 216.04938271604937
2019Q1: 144.140625
2019Q2: 107.35999999999999
2019Q3: 85.26234567901243
2019Q4: 70.59558517284461
```

See also: [`pct`](@ref)
"""
function apct(ts::TSeries, islog::Bool = false)
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

    TSeries( (a/b).firstdate, values)
end


function Base.cumsum(s::TSeries)
    TSeries(s.firstdate, cumsum(s.values))
end

function Base.cumsum!(s::TSeries)
    s.values = cumsum(s.values)
    return s
end


"""
    leftcropnan!(x::TSeries)

Remove `NaN` values from starting at the beginning of `x`, in-place.

__Note__: an internal function.
"""
function leftcropnan!(s::TSeries)
    while isequal(s[firstdate(s)], NaN)
        popfirst!(s.values)
        s.firstdate = s.firstdate + 1
    end
    return s
end

"""
rightcropnan!(x::TSeries)

Remove `NaN` values from the end of `x`

__Note__: an internal function.
"""
function rightcropnan!(s::TSeries)
    while isequal(s[lastdate(s)], NaN)
        pop!(s.values)
    end
    return s
end


"""
    nanrm!(s::TSeries, type::Symbol)

Remove `NaN` values that are either at the beginning of the `s` and/or end of `x`.

Examples
```
julia> s = TSeries(yy(2018), [NaN, NaN, 1, 2, NaN]);

julia> nanrm!(s);

julia> s
TSeries{Yearly} of length 2
2020Y: 1.0
2021Y: 2.0
```
"""
function nanrm!(s::TSeries, type::Symbol=:both)
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


"""
Can be applied to a [`TSeries`](@ref) instance or a range of MIT to return its [`Frequency`](@ref).
"""
frequencyof(::TSeries{T}) where T <: Frequency = T
frequencyof(::Type{TSeries{T}}) where T <: Frequency = T
frequencyof(::AbstractUnitRange{MIT{T}}) where T <: Frequency = T
frequencyof(::Type{<:AbstractUnitRange{MIT{T}}}) where T <: Frequency = T

# -----------------------------------------------------
# Broadcasting Interface: `BroadcastStyle` and `similar`
# https://docs.julialang.org/en/v1.0.5/manual/interfaces/#man-interfaces-broadcasting-1
# -----------------------------------------------------
Base.BroadcastStyle(::Type{<:TSeries}) = Broadcast.ArrayStyle{TSeries}()

function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{TSeries}}, ::Type{ElType}) where ElType
    # Scan the inputs for the TSeries:
    ts = find_tseries(bc)
    
    similar(ts)
end

"""
    find_tseries

Return the first TSeries among the arguments.

__Note:__ An internal function used for broadcasting support.
"""
find_tseries(bc::Base.Broadcast.Broadcasted) = find_tseries(bc.args)
find_tseries(args::Tuple) = find_tseries(find_tseries(args[1]), Base.tail(args))
find_tseries(x) = x
find_tseries(a::TSeries, rest) = a
find_tseries(::Any, rest) = find_tseries(rest)
