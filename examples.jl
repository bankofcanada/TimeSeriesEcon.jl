using Pkg; Pkg.activate(".");

using TSeries


mitrange(ts2)

ts  = Series(i(1), fill(0, 10))
ts2 = Series(i(5), fill(1, 10))


ts[i(1)] = [1000];ts

m[mm(2000, 1):mm(2000, 5)]


ts[i(1):i(5)]

ts[i(5)] = ts2;ts

ts[i(6):i(10)]=ts2;ts

ts2

ts2[i(1):i(3)]

ts2[i(2):i(5)]

# ts = Series(yy(2012), collect(1:10))
# ts_q = Series(qq(2012, 1), collect(1.0:10.0))
ts_m = Series(mm(2012, 1), collect(1:10))
ts_m1 = Series(mm(2011, 1), collect(1:10))

# TSeries.DataFrames.showall([ts_m ts_m1])

ts_m[mm(2012, 10):mm(2012, 12)]
ts_m[mm(2011, 1):mm(2012, 4)]
ts_m[mm(2011, 4):mm(2012, 7)]

ts_m[mm(2011, 1):mm(2012, 8)]
ts_m[mm(2010, 1):mm(2012, 1) + 2] = 1; ts_m

ts_m[mm(2018, 1) + 4] == ts_m[mm(2019, 1)]

mm(2010, 1):mm(2010, 2) |> collect

mm(2010, 1):mm(2010, 2) |> x -> Int64(x.stop) - Int64(x.start) + 1

I = mm(2010, 1):mm(2010, 2)
#-----------------------------------------------------

ts_m = Series(mm(2020, 1):mm(2020, 12), collect(1:12))

#-----------------------------------------------------
# Getter
#-----------------------------------------------------
date = mm(2020, 6)
date_rng1 = mm(2019, 1):mm(2019, 3) # out of bound -> left side
date_rng2 = mm(2019, 4):mm(2020, 3) # partially out of bounds -> left side
date_rng3 = mm(2020, 4):mm(2020, 7) # fully in bounds
date_rng4 = mm(2020, 8):mm(2021, 3) # partially out of bounds -> right side
date_rng5 = mm(2021, 4):mm(2020, 9) # out of bound -> right side

ts_m[date]

ts_m[date_rng1] == nothing
ts_m[date_rng2]
ts_m[date_rng3]
ts_m[date_rng4]
ts_m[date_rng5] == nothing

#-----------------------------------------------------
# Setter
#-----------------------------------------------------
ts_m = Series(mm(2020, 1):mm(2020, 12), collect(1:12))


date = mm(2020, 6)
date_left = mm(2019, 7)
date_right = mm(2021, 6)

date_rng1 = mm(2019, 1):mm(2019, 3) # out of bound -> left side
date_rng2 = mm(2019, 4):mm(2020, 3) # partially out of bounds -> left side
date_rng3 = mm(2020, 4):mm(2020, 7) # fully in bounds
date_rng4 = mm(2020, 8):mm(2021, 3) # partially out of bounds -> right side
date_rng5 = mm(2021, 4):mm(2021, 9) # out of bound -> right side

ts_m[date] = 60;ts_m

ts_m[date_left] = 100;ts_m
ts_m[date_right] = 100;ts_m

ts_m = Series(mm(2020, 1):mm(2020, 12), collect(1:12))
ts_m[date_rng1] = -5; ts_m
ts_m[date_rng2] = -6; ts_m
ts_m[date_rng3] = -7; ts_m
ts_m[date_rng4] = -8; ts_m
ts_m[date_rng5] = -9; ts_m


ts_m = Series(mm(2020, 1):mm(2020, 12), collect(1:12))
ts_m2 = Series(mm(2020, 7):mm(2021, 6), collect(1:12))
ts_m[mm(2021, 3)] = 45;ts_m



ts_m |> TSeries.lastdate

ts_m + ts_m2

ts_m2[mm(2019, 1)] = 100

ts_m + ts_m2

# function Base.hcat(tuple_of_ts::Vararg{Series{T}, N}) where T <: Frequency where N
#     firstdate = [i.firstdate for i in tuple_of_ts] |> minimum
#     lastdate  = [TSeries.lastdate(i) for i in tuple_of_ts] |> maximum
#
#     holder = Array{Float64, 1}()
#
#     for ts in tuple_of_ts
#         for date in firstdate:lastdate
#             if ts[date] == nothing
#                 v = [NaN]
#             else
#                 v = ts[date].values[1]
#             end
#
#             append!(holder, v)
#         end
#     end
#
#     reshaped_array = reshape(holder, (length(firstdate:lastdate), length(tuple_of_ts)))
#
#     df = DataFrame(reshaped_array)
#     df.date = firstdate:lastdate
#
#     return  df
# end


println("------")
showall([ts_m ts_m2])
df.date =

df = DataFrame()

df.date = mm(2012, 1):mm(2012, 12) |> collect |> x -> convert(String, x)
df.: = collect(1:12)

ts_m3 = Series(mm(2012, 4), [4, 5, 6, 7, 8])


showall(df)

# ts = Series(mm(2000, 1), collect(1:12))
#
# function equation(eqn::String)
#     map(t -> (ts[t] = ts[t - 1] + 25), 2:length(ts))
# end
#
# function max_lag(eqn::String)
#     pattern = r"\[[a-z]\s*[+-]\s*(\d+)\]"
#     eachmatch(pattern, eqn) |> collect
# end
#
# m = max_lag("ts[t] = ts[t-4] + ts[t-100]")
#
# m.match
# m.captures


e = :(ts[t] = ts[t - 1] + 25)

typeof(e)

macro solve_recursive(eqn, ts_name, max_lag, letter)
    :(map($letter -> $eqn, $max_lag + 1:length($ts_name)))
end

ts = Series(mm(2000, 1), collect(1:12))
@solve_recursive((ts[t] = ts[t - 1] + 25), ts, 1, t)

:(ts[t] = ts[t - 1] + 25)

dump(e)






















# function flatten(v::Vector)
#     reducer(x) = reduce(vcat, x)
#
#     while length(v) != 8
#         v = reducer(v)
#     end
#
#     return v
# end

flatten(extract_args(e))
e

extract_head(e)
reduce(reduce(vcat, reduce(vcat, extract_args(e))))

extract_args(e)





eltype.([1, 2, 3, 4, [1,23.0]])






extract_args.(extract_args.(extract_args(e)))

e_q = e |> QuoteNode

e_q.value

fieldnames(Expr)



end


tbd = [1, 2, 3]
