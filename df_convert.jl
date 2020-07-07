# Experimental Script:
#

using DataFrames
using TSeries
import TSeries: MIT


ts_q = Series(qq(2018, 1), collect(1:10))
ts_m = Series(mm(2012, 2), collect(10:20))
ts_y = Series(yy(2012), collect(3:5))
ts_i = Series(i(2), collect(-5:-1))


ts_dict = Dict("q" => ts_q, "m" => ts_m, "y" => ts_y, "i" => ts_i)


ts_df = DataFrame(name = String[], type = DataType[], date = MIT{<: Frequency}[], value = Float64[])


df = DataFrame()



names = String[];
for key in keys(ts_dict)
    fill(key, length(ts_dict[key])) |>
        x -> push!(names, x...)
end

df.names = names; df
#
type = Type[];
for key in keys(ts_dict)
    fill(typeof(ts_dict[key]), length(ts_dict[key])) |>
        x -> push!(type, x...)
end

type

df.type = type; df
#
date = MIT{<: Frequency}[];
for key in keys(ts_dict)
    mitrange(ts_dict[key]) |>
        x -> push!(date, x...)
end

date

df.date = date; df

# vals

value = Float64[];
for key in keys(ts_dict)
    ts_dict[key].values |>
        x -> push!(value, x...)
end

value

df.value = value; df


# Plotting

using Query
using Dates

# df_i = df |>
#     @filter(_.names == "i") |>
#     DataFrame
#
# df_i
#
# p = plot(df_i, x = :names, y = :value,  Geom.point)

# Base.promote_rule(::Type{Float64}, ::Type{MIT{T}}) where T <: Frequency = Float64
# Base.promote_rule(::Type{Missing}, ::Type{MIT{T}}) where T <: Frequency = MIT{T}

#

# Base.promote_rule(::Type{MIT{T}}, ::Type{Float64}) where T <: Frequency = Float64
# Float64(x::MIT{T}) where T <: Frequency = Float64(Int64(x))
# Float64(x::MIT{T}) where T <: Frequency = Int64(x) |> Float64

using Pkg; Pkg.activate(".");

using TSeries
import TSeries: MIT, Frequency, Unit, mm
using Fontconfig
using Cairo
using Gadfly

Base.string(x::MIT{T}) where T <: Frequency = string(TSeries.year(x), string(T)[1], TSeries.period(x))
Base.string(x::MIT{Unit}) = string("i(", Int64(x), ")")


function plot_ts(ts::Series{T}, title = "NA") where T <: Frequency

    # x_mit = string.(mitrange(ts))
    string_labels = string.(mitrange(ts));
    # x = 1:length(ts);
    one_based_integer_labels = 1:length(ts);

    step_size = max(2, div(length(one_based_integer_labels), 5))

    p = plot(x=one_based_integer_labels, y=ts.values, Geom.point,
         Guide.title(title),
         Guide.xlabel("Date"),
         Guide.ylabel("Response"),
         Guide.xticks(ticks = one_based_integer_labels[1:step_size:end]),
         Scale.x_continuous(labels = i -> string_labels[i]))
end







holder = Vector{Plot}();

for i in 1:1000
    random_int = rand(20:100);
    tbd = Series(qq(2018, 1), rand( collect(1:100), random_int) );
    p = plot_ts(tbd);
    push!(holder, p)
end

draw(SVG("myplot.svg", 10inch, 6000inch), vstack(holder...))



# forecast_db

using JLD2

@load "forecast_db.jld2"
series_dict = filter(p -> typeof(p.second) <: Series, forecast_db)

holder = Vector{Plot}()
for key in keys(series_dict)
    p = plot_ts(series_dict[key], key);
    push!(holder, p)
end

draw(SVG("forecast_db.html", 7inch, 1500inch), vstack(holder[1:500]...))


# 1 + 1 |> println

#
# plot(x=rand(1:10, 10), y=rand(1:10, 10), Geom.line, Guide.xticks(ticks=[1:9;]))
