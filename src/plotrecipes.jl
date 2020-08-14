

using RecipesBase

@recipe plot(ts::TSeries...) = begin
    for t in ts
        @series begin
            (Float64[mitrange(t)...], t.values)
        end
    end
end
