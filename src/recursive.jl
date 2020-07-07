
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
