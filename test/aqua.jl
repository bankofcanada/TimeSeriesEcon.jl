# Copyright (c) 2020-2025, Bank of Canada
# All rights reserved.

# Package quality checks, https://github.com/JuliaTesting/Aqua.jl
using Aqua

@testset "Aqua" begin
    Aqua.test_all(TimeSeriesEcon;
        # TODO: 113 ambiguities on Julia 1.13 (145 on 1.10), mostly against Base and LinearAlgebra
        ambiguities=(broken=true,),
        # TODO: type parameters in the fconvert signatures that are unbound for some frequencies
        unbound_args=(broken=true,),
    )
end
