"""

    @rec(eqn, rng)

Computes recursive calculations for the given `eqn` and `rng`.

### Examples
```julia-repl
julia> s = TSeries(ii(1), zeros(1));

julia> # Initial values

julia> s[ii(1)] = 0;

julia> s[ii(2)] = 1;

julia> @rec s[t] = s[t-1] + s[t-2] ii(3):ii(10)

julia> s
TSeries{Unit} of length 10
ii(1): 0.0
ii(2): 1.0
ii(3): 1.0
ii(4): 2.0
ii(5): 3.0
ii(6): 5.0
ii(7): 8.0
ii(8): 13.0
ii(9): 21.0
ii(10): 34.0
```


"""
macro rec(eqn, rng)
    vn = eqn.args[1].args[1]
    tn = eqn.args[1].args[2]
    return quote
        $(vn)[$(rng)] = NaN
        for $(tn) in $(rng)
            $(eqn)
        end
    end |> esc
end

export @rec
