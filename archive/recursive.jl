function wrapper(e)
    holder  = Array{Any, 1}()
    index   = Array{Any, 1}()
    max_lag = Array{Any, 1}()
    ts_name = Array{Any, 1}()

    function extract_head(e::Expr)
        return e.head
    end

    function extract_args(e::Expr)
        if e.head == :call && e.args[1] == :- && typeof(e.args[2]) != Expr
            push!(index, e.args[2])
            push!(max_lag, e.args[3])
        end

        if e.head == :ref
            push!(ts_name, e.args[1])
        end

        return extract_args(e.args)
    end

    function extract_args(e::Array)
        return extract_args.(e)
    end

    function extract_args(e::Symbol)
        push!(holder, e)
        return e
    end

    function extract_args(e::Number)
        push!(holder, e)
        return e
    end

    extract_args(e)

    return Dict("max_lag" => maximum(max_lag), "all" => holder, "index" => index, "ts_name" => ts_name)
end


wrapper(:(ts[t] = ts[t - 1] + ts[t - 2] - ts[t - 1000] + ts[a - 55]))

using Pkg; Pkg.activate(".");
using TSeries
ts = Series(mm(2000, 1), collect(1:12))
ts2 = Series(mm(1999, 1), collect(-4:7))

# macro recursive(eqn)
#     w = wrapper(:($eqn))
#
#     esc(:( map($(w["index"][1]) -> $eqn, $(w["max_lag"] + 1):length($(w["ts_name"][1]))) ))
#
#     # :( map($(w["index"][1]) -> $eqn, $(w["max_lag"] + 1):length($(w["ts_name"][1]))) )
#     # :(map($w["index"][1] -> $eqn, $w["max_lag"] + 1:length($w["ts_name"][1])))
# end

macro recursive(eqn, range)
    w = wrapper(:($eqn))

    esc(:( map($(w["index"][1]) -> $eqn, $range )))

    # :( map($(w["index"][1]) -> $eqn, $(w["max_lag"] + 1):length($(w["ts_name"][1]))) )
    # :(map($w["index"][1] -> $eqn, $w["max_lag"] + 1:length($w["ts_name"][1])))
end

ts

[ts ts2 ts]

ts = Series(mm(2000, 1), collect(1:12))
ts2 = Series(mm(2000, 1), collect(1:12))

@recursive(ts[t] = ts[t-1] + ts2[t], 2:5 );ts

@macroexpand(@recursive ts[t] = ts[t-1] + 10)


# Test Timing
ts1 = Series(mm(2000, 1), ones(10))
ts2 = Series(mm(2000, 6), collect(1:12))
ts3 = deepcopy(ts1)
@recursive ts1[t] = ts1[t-1] + ts2[t]
[ts1 ts2 ts3]

wrapper(:(ts1[t] = ts1[t-1] + ts2[t]))
