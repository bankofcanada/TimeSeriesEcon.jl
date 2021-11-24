# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

using MacroTools

"""
    @rec [index=]range expression

Computes recursive operations on time series. The first argument is the range
and the second argument is an expression to be evaluated over that range.

The expression is meant to be an assignment, but it doesn't have to be. 

The the range can specify an optional indexing variable (as in a for loop). If
not given, the variable is assumed to be `t`.

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
    return esc(quote
        for $(ind) in $(rng)
            $(arg_eqn)
        end
    end)
end

