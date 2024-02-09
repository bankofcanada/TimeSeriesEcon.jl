# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

"""
    @rec [index=]range expression

Compute recursive operations on time series. The first argument is the range
and the second argument is an expression to be evaluated over that range.

The expression is meant to be an assignment, but it doesn't have to be. 

The range specification can include an optional indexing variable name. If not
given, the variable name defaults to `t`.

### Examples
```julia-repl
julia> s = TSeries(1U)
Empty TSeries{Unit} starting 5U

julia> s[1U] = s[2U] = 1; s
2-element TSeries{Unit} with range 1U:2U:
      1U : 1.0
      2U : 1.0

julia> @rec t=3U:10U s[t] = s[t-1] + s[t-2]

julia> s
10-element TSeries{Unit} with range 1U:10U:
      1U : 1.0
      2U : 1.0
      3U : 2.0
      4U : 3.0
      5U : 5.0
      6U : 8.0
      7U : 13.0
      8U : 21.0
      9U : 34.0
     10U : 55.0
```
"""
macro rec(arg_rng, arg_eqn)
    ind = nothing
    rng = nothing
    matched = @capture(arg_rng, ind_ = rng_) || @capture(arg_rng, ind_ in rng_) || @capture(arg_rng, ind_ ∈ rng_)
    if !matched
        rng = arg_rng
        @capture(arg_eqn, var_[ind_] = rhs_)
    end
    if !isa(ind, Symbol)
        ind = :t
    end
    arg_eqn = MacroTools.prewalk(arg_eqn) do e
        if MacroTools.isexpr(e, :macrocall)
            try
                return Core.eval(__module__, e)
            catch
                return e
            end
        end
        return e
    end
    # for loop with empty body
    ret = :(for $(ind) in $(rng) end)  
    # replace body with arg_eqn, keeping the original source line
    ret.args[end] = Expr(:block, __source__, arg_eqn)
    return esc(ret)
end

