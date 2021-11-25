# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using OrderedCollections

# -------------------------------------------------------------------------------
# MVTSeries -- multivariate TSeries
# -------------------------------------------------------------------------------

mutable struct MVTSeries{
    F<:Frequency,
    T<:Number,
    C<:AbstractMatrix{T}
} <: AbstractMatrix{T}

    firstdate::MIT{F}
    columns::OrderedDict{Symbol,TSeries{F,T}}
    values::C

    # inner constructor enforces constraints
    function MVTSeries(firstdate::MIT{F},
        names::NTuple{N,Symbol},
        values::AbstractMatrix
    ) where {F<:Frequency,N}
        if N != size(values, 2)
            ArgumentError("Number of names and columns don'x match:" *
                          " $N ≠ $(size(values, 2)).") |> throw
        end
        columns = OrderedDict(nm => TSeries(firstdate, view(values, :, ind))
                              for (nm, ind) in zip(names, axes(values, 2)))
        new{F,eltype(values),typeof(values)}(firstdate, columns, values)
    end

end

# standard constructor with default empty values
function MVTSeries(fd::MIT = 1U, vars = (), data::Union{Nothing, AbstractMatrix}=nothing)
    if vars isa Symbol
        vars = (vars,)
    else
        vars = tuple(Symbol.(vars)...)
    end
    if data === nothing
        return MVTSeries(fd, vars, Matrix{Float64}(undef, 0, length(vars)))
    else
        return MVTSeries(fd, vars, data)
    end
end
# see more constructors below

@inline _vals(x::MVTSeries) = getfield(x, :values)
@inline _cols(x::MVTSeries) = getfield(x, :columns)

@inline colnames(x::MVTSeries) = keys(_cols(x))
@inline rawdata(x::MVTSeries) = _vals(x)
@inline Base.pairs(x::MVTSeries) = pairs(_cols(x))

@inline firstdate(x::MVTSeries) = getfield(x, :firstdate)
@inline lastdate(x::MVTSeries) = firstdate(x) + size(_vals(x), 1) - one(firstdate(x))
@inline frequencyof(::MVTSeries{F}) where {F<:Frequency} = F
@inline rangeof(x::MVTSeries) = firstdate(x):lastdate(x)

# -------------------------------------------------------------------------------
# Make MVTSeries work properly as an AbstractArray


@inline Base.size(x::MVTSeries) = size(_vals(x))
@inline Base.axes(x::MVTSeries) = (rangeof(x), colnames(x))
@inline Base.axes1(x::MVTSeries) = rangeof(x)

# the following are needed for copy() and copyto!() (and a bunch of Julia internals that use them)
@inline Base.IndexStyle(x::MVTSeries) = IndexStyle(_vals(x))
@inline Base.dataids(x::MVTSeries) = Base.dataids(_vals(x))

# normally only the first of the following is sufficient.
# we add few other versions of similar below
Base.similar(x::MVTSeries) = MVTSeries(firstdate(x), colnames(x), similar(_vals(x)))

# -------------------------------------------------------------------------------
# Indexing with integers and booleans - same as matrices

# Indexing with integers falls back to AbstractArray
const FallbackType = Union{Integer,Colon,AbstractUnitRange{<:Integer},AbstractArray{<:Integer},CartesianIndex}
Base.getindex(sd::MVTSeries, i1::FallbackType...) = getindex(_vals(sd), i1...)
Base.setindex!(sd::MVTSeries, val, i1::FallbackType...) = setindex!(_vals(sd), val, i1...)

# -------------------------------------------------------------
# Some other constructors
# -------------------------------------------------------------

# Empty (0 variables) from range
@inline MVTSeries(T::Type{<:Number}, rng::AbstractUnitRange{<:MIT}) = MVTSeries(first(rng), (), Matrix{T}(undef, length(rng), 0))
@inline MVTSeries(rng::UnitRange{<:MIT}) = MVTSeries(Float64, rng)

# Empty from a list of variables and of specified type (first date must also be given, Frequency is not enough)
# @inline MVTSeries(fd::MIT, vars) = MVTSeries(Float64, fd, vars)
MVTSeries(T::Type{<:Number}, fd::MIT, vars) = MVTSeries(fd, vars, Matrix{T}(undef, 0, length(vars)))

# Uninitialized from a range and list of variables
@inline MVTSeries(rng::UnitRange{<:MIT}, vars) = MVTSeries(Float64, rng, vars, undef)
@inline MVTSeries(rng::UnitRange{<:MIT}, vars, ::UndefInitializer) = MVTSeries(Float64, rng, vars, undef)
@inline MVTSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}, vars) = MVTSeries(T, rng, vars, undef)
MVTSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}, vars, ::UndefInitializer) = 
    MVTSeries(first(rng), vars, Matrix{T}(undef, length(rng), length(vars)))
MVTSeries(T::Type{<:Number}, rng::UnitRange{<:MIT}, vars::Symbol, ::UndefInitializer) = 
    MVTSeries(first(rng), (vars,), Matrix{T}(undef, length(rng), 1))

# initialize with a function like zeros, ones, rand.
MVTSeries(rng::UnitRange{<:MIT}, vars, init::Function) = MVTSeries(first(rng), vars, init(length(rng), length(vars)))
# no type-explicit version because the type is determined by the output of init()

#initialize with a constant
MVTSeries(rng::UnitRange{<:MIT}, vars, v::Number) = MVTSeries(first(rng), vars, fill(v, length(rng), length(vars)))

# construct with a given range (rather than only the first date). We must check the range length matches the data size 1
function MVTSeries(rng::UnitRange{<:MIT}, vars, vals::AbstractMatrix{<:Number})
    lrng = length(rng)
    lvrs = length(vars)
    nrow, ncol = size(vals)
    if lrng != nrow || lvrs != ncol
        throw(ArgumentError("Number of periods and variables do not match size of data." *
                        " ($(lrng)×$(lvrs)) ≠ ($(nrow)×$(ncol))"
        ))
    end
    return MVTSeries(first(rng), vars, vals) 
end

# construct if data is given as a vector (it must be exactly 1 variable)
MVTSeries(fd::MIT, vars, data::AbstractVector) = MVTSeries(fd, vars, reshape(data, :, 1))
MVTSeries(fd::MIT, vars::Symbol, data::AbstractVector) = MVTSeries(fd, (vars,), reshape(data, :, 1))
MVTSeries(rng::UnitRange{<:MIT}, vars, data::AbstractVector) = MVTSeries(rng, vars, reshape(data, :, 1))
MVTSeries(rng::UnitRange{<:MIT}, vars::Symbol, data::AbstractVector) = MVTSeries(rng, (vars,), reshape(data, :, 1))

# construct uninitialized by way of calling similar 
Base.similar(::Type{<:AbstractArray}, T::Type{<:Number}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {N} = MVTSeries(T, shape[1], shape[2])
Base.similar(::Type{<:AbstractArray{T}}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {T<:Number,N} = MVTSeries(T, shape[1], shape[2])
Base.similar(::AbstractArray, T::Type{<:Number}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {N} = MVTSeries(T, shape[1], shape[2])
Base.similar(::AbstractArray{T}, shape::Tuple{UnitRange{<:MIT},NTuple{N,Symbol}}) where {T<:Number,N} = MVTSeries(T, shape[1], shape[2])

# construct from range and fill with the given constant or array
Base.fill(v::Number, rng::UnitRange{<:MIT}, vars::NTuple{N, Symbol}) where {N} = MVTSeries(first(rng), vars, fill(v, length(rng),length(vars)))



# -------------------------------------------------------------------------------
# Indexing with MIT 






include("mvtseries/mvts_show.jl")
