import Statistics: mean


function getstart(s::TSeries{T}) where T <: Monthly
    if period(s.firstdate) in [1, 4, 7, 10]
        return s.firstdate
    elseif 1 < period(s.firstdate) < 4
        y = year(s.firstdate)
        p = 4
    elseif 4 < period(s.firstdate) < 7
        y = year(s.firstdate)
        p = 7
    elseif 7 < period(s.firstdate) < 10
        y = year(s.firstdate)
        p = 10
    else 7 < period(s.firstdate) < 10
        y = year(s.firstdate) + 1
        p = 1
    end

    return MIT{T}(y*ppy(T) + p - 1)
        # return qq(year(s.firstdate) + 1, 1)
end

function getend(s::TSeries{T}) where T <: Monthly
    if period(lastdate(s)) in [12, 3, 6, 9]
        return lastdate(s)
    elseif 1 <= period(lastdate(s)) < 3
        y = year(lastdate(s)) - 1
        p = 12
    elseif 4 <= period(lastdate(s)) < 6
        y = year(lastdate(s))
        p = 3
    elseif 7 <= period(lastdate(s)) < 9
        y = year(lastdate(s))
        p = 6
    else 10 <= period(lastdate(s)) < 12
        y = year(lastdate(s))
        p = 9
    end

    return MIT{T}(y*ppy(T) + p - 1)
        # return qq(year(s.firstdate) + 1, 1)
end

function getstart(s::TSeries{T}) where T <: Quarterly
    if period(s.firstdate) == 1
        return s.firstdate
    else
        y = year(s.firstdate) + 1
        p = 1

        return MIT{T}(y*ppy(T) + p - 1)
        # return qq(year(s.firstdate) + 1, 1)
    end
end

function getend(s::TSeries{T}) where T <: Quarterly
    if TimeSeriesEcon.period(lastdate(s)) == ppy(s)
        return lastdate(s)
    else
        y = year(lastdate(s)) - 1
        p = ppy(s)
        return MIT{T}(y*ppy(T) + p - 1)
        # return qq(year(lastdate(s)) - 1, ppy(s))
    end
end


function crop(s::TSeries{T}) where T <: Union{Quarterly, Monthly}
    getstart(s) <= getend(s) || error("TSeries can't be cropped. start:$(getstart(s)) > end:$(getend(s))")

    return s[getstart(s):getend(s)]
end

function Base.convert(::Type{TSeries{Yearly}}, s::TSeries{Quarterly})
    values = Vector{Float64}()

    for i in 1:4:length(crop(s))
        push!(values, mean(crop(s)[i:i+3]))
    end

    firstdate = year(crop(s).firstdate) |> yy

    return TSeries(firstdate, values)
end

function Base.convert(::Type{TSeries{Quarterly}}, s::TSeries{Monthly})
    values = Vector{Float64}()

    for i in 1:3:length(crop(s))
        push!(values, mean(crop(s)[i:i+2]))
    end

    y = year(crop(s).firstdate) |> yy
    p = period(crop(s).firstdate) |>
        x -> div(x - 1, 3) + 1

    return TSeries(qq(y, p), values)
end

function Base.convert(::Type{TSeries{Yearly}}, s::TSeries{Monthly})
    convert(TSeries{Quarterly}, s) |>
        x -> convert(TSeries{Yearly}, x)
end

# Arbitrary function

function Base.convert(::Type{TSeries{Yearly}}, s::TSeries{Quarterly}, f::Symbol)
    values = Vector{Float64}()
    for i in 1:4:length(crop(s))
        push!(values, eval(f)(crop(s)[i:i+3]))
    end
    firstdate = year(crop(s).firstdate) |> yy
    return TSeries(firstdate, values)
end


# convert(TSeries{Yearly}, s)
# convert(TSeries{Yearly}, p)

# function mode(a)
#     isempty(a) && throw(ArgumentError("mode is not defined for empty collections"))
#     cnts = Dict{eltype(a),Int}()
#     # first element
#     mc = 1
#     mv, st = iterate(a)
#     cnts[mv] = 1
#     # find the mode along with table construction
#     y = iterate(a, st)
#     while y !== nothing
#         x, st = y
#         if haskey(cnts, x)
#             c = (cnts[x] += 1)
#             if c > mc
#                 mc = c
#                 mv = x
#             end
#         else
#             cnts[x] = 1
#             # in this case: c = 1, and thus c > mc won't happen
#         end
#         y = iterate(a, st)
#     end
#     return mv
# end

# mode([1, 2, 33, 33, 33])
