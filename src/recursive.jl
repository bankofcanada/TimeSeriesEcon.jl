"""
    @rec(rng, eqn)

Computes recursive calculations for the given range `rng` and equation `eqn`.

### Examples
```julia-repl
julia> s = TSeries(1U, zeros(1))
1-element Unit TSeries from 1U:
      1U : 0.0

julia> s[1U] = 0
0

julia> s[2U] = 1
1

julia> s 
2-element Unit TSeries from 1U:
      1U : 0.0
      2U : 1.0

julia> @rec(3U:10U, s[t] = s[t-1] + s[t-2])

julia> s
10-element Unit TSeries from 1U:
      1U : 0.0
      2U : 1.0
      3U : 1.0
      4U : 2.0
      5U : 3.0
      6U : 5.0
      7U : 8.0
      8U : 13.0
      9U : 21.0
     10U : 34.0
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
