module TSeries

include("moment_in_time.jl")
include("series.jl")
include("recursive.jl")
include("convert.jl")

export mm, qq, yy, ii
# necessary for printing l#: 38 in moment_in_time.jl
export Monthly, Quarterly, Yearly, Frequency, Unit
export Series, mitrange
export shift, shift!



end
