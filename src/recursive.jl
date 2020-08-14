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
macro rec(rng, eqn)
    eqn isa Expr && eqn.head == :(=) || error("Expression must be an assignment.")
    lhs, rhs = eqn.args
    lhs isa Expr && lhs.head == :ref || error("Left hand side of assignment must be an indexing expression.")
    vn, inds = lhs.args[1], lhs.args[2:end]
    tn = let # try to find the indexing variable
        tn = Symbol[]
        for i in 1:length(inds)
            isa(inds[i], Symbol) || continue
            inds[i] == :(:) && continue
            if inds[i] == :t # prefer :t if it's in there
                tn = [:t]
                break
            else
                push!(tn, inds[i])
            end
        end
        isempty(tn) && error("Time index not found.")
        # :t not there and multiple other symbols.
        length(tn) > 1 && error("Ambiguous time index. Use `t`.")
        tn[1]
    end
    return quote
        for $(tn) in $(rng)
            $(eqn)
        end
    end |> esc
end

export @rec
