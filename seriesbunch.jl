using TSeries
import TSeries: MIT

using Printf

mutable struct SeriesBunch{T <: Frequency} <: AbstractMatrix{Float64}
    firstdate::MIT{T}
    values::Matrix{Float64}
    colnames::Vector{String}
end

function SeriesBunch(fd::MIT{T}, V::Array{Int64, 2}, colnames::Vector{String}) where T <: Frequency
    SeriesBunch{T}(fd, V, colnames)
end

function SeriesBunch(fd::MIT{T}, V::Array{Float64, 2}, colnames::Vector{String}) where T <: Frequency
    SeriesBunch{T}(fd, V, colnames)
end

# -------
# AbstractMatrix Interface
# https://docs.julialang.org/en/v1/manual/interfaces/#man-interface-array-1
# -------
Base.size(sb::SeriesBunch{T}) where T <: Frequency = size(sb.values)
Base.getindex(sb::SeriesBunch, I::Vararg{Int64, 2}) = sb.values[I...]
Base.setindex!(sb::SeriesBunch, v::Union{Int64, Float64}, I::Vararg{Int, 2}) = (sb.values[I...] = v)


# -------
# Base.show - setup proper display
# -------
import Base: show


eachrow(A::AbstractVecOrMat) = (view(A, i, :) for i in axes(A, 1))

function show(io::IO, sb::SeriesBunch{T}) where T <: Frequency

    println(io, "SeriesBunch{", T, "} with dimensions ", size(sb))
    println(io, "")
    println(io, "Column Names: "*join(sb.colnames, ", "))
    nrows = size(sb)[2]

    values_generator = eachrow(sb.values) |> collect
    for i = 1:nrows
        print(io, string(sb.firstdate - 1 + i)*": ")
        println(io, join(values_generator[i], "  "))
    end
end

function show(io::IO, ::MIME"text/plain", sb::SeriesBunch{T}) where T <: Frequency
    println(io, "SeriesBunch{", T, "} with dimensions ", size(sb))
    println(io, "")
    println(io, "Column Names: "*join(sb.colnames, ", "))
    nrows = size(sb)[2]

    values_generator = eachrow(sb.values) |> collect
    for i = 1:nrows
        print(io, string(sb.firstdate - 1 + i)*": ")
        println(io, join(values_generator[i], "  "))
    end
end



sb = SeriesBunch(i(1), hcat([1, 2], [3, 4]), ["a", "b"])

sb |> println

function SeriesBunch(tuple_of_ts::Vararg{Series{T}, N}; colnames::Vector{String}) where T <: Frequency where N

    firstdate = [i.firstdate for i in tuple_of_ts] |> minimum
    values = hcat(tuple_of_ts...)

    length(sb.colnames) == length(tuple_of_ts) || println("Warning: The number of column names and actual columns don't match.")

    SeriesBunch{T}(firstdate, values, colnames)
end


a = Series(i(1), [1, 2, 3, 4, 5]);
b = Series(i(1), [1, 2, 3, 4, 5]);
c = Series(i(1), [1, 2, 3, 4, 5]);

sb = SeriesBunch(a, b, c, colnames=["a", "b", "c"])
