# https://juliadocs.github.io/Documenter.jl/stable/man/guide/#Package-Guide
push!(LOAD_PATH,"../src/") 

using Documenter, TimeSeriesEcon

makedocs(sitename = "TimeSeriesEcon.jl",
         format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
         modules = [TimeSeriesEcon],
         pages = [
        "Home" => "index.md",
        "Quickstart" => "quickstart.md",
        "MIT" => "mit.md",
        "TSeries" => "tseries.md",
        "Frequency" => "frequency.md"
    ]
)

deploydocs(
    repo = "github.com/bankofcanada/TimeSeriesEcon.jl.git",
)