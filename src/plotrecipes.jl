

using RecipesBase

@recipe plot(::Type{TS <: TSeries}, ts::TS) where TS = (Float64[mitrange(ts)...], ts.values)

