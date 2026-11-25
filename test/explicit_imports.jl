# Copyright (c) 2020-2025, Bank of Canada
# All rights reserved.

# Import hygiene checks, https://github.com/JuliaTesting/ExplicitImports.jl
using ExplicitImports

@testset "ExplicitImports" begin
    test_explicit_imports(TimeSeriesEcon;
        # written X13.name inside X13 on purpose (e.g. X13.run is not Base.run)
        no_self_qualified_accesses=(ignore=(
            :Span, :X13result, :ao, :aos, :easter, :easterstock, :labor, :loadresult, :lom, :loq, :lpyear, :ls,
            :lss, :newspec, :qd, :qi, :rp, :run, :sceaster, :seasonal, :series, :so, :tc, :td, :td1coef,
            :td1nolpyear, :tdnolpyear, :tdstock, :tdstock1coef, :thank, :tl, :x11),),
        # use of non-public names is checked later
        all_explicit_imports_are_public=false,
        all_qualified_accesses_are_public=false,
    )
end
