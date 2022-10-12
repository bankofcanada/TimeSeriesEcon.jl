# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

import Statistics: mean

"""
    fconvert(F_to, t)

Convert the time series `t` to the desired frequency `F`.
"""
fconvert(F_to::Type{<:Frequency}, t::TSeries; args...) = error("""
Conversion of TSeries from $(frequencyof(t)) to $F_to not implemented.
""")
fconvert(F_to::Type{<:Frequency}, t::UnitRange{MIT}; args...) = error("""
Conversion of MIT range from $(frequencyof(t)) to $F_to not implemented.
""")
fconvert(F_to::Type{<:Frequency}, t::MIT; args...) = error("""
Conversion of MIT from $(frequencyof(t)) to $F_to not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(::Type{F}, t::TSeries{F}) where {F<:Frequency} = t

include("fconvert_helpers.jl")
include("fconvert_mit.jl")
include("fconvert_tseries_yp.jl")
include("fconvert_tseries_calendar.jl")

