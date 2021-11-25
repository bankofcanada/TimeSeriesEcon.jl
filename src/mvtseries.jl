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

# -------------------------------------------------------------------------------
# Indexing with MIT 






include("mvtseries/mvts_show.jl")
