```
julia> primitive type MIT{T} <: Signed64 end
ERROR: syntax: unexpected "end"

julia> primitive type MIT{T} <: Signed 64 end

julia> a = MIT{Quarterly}
MIT{Quarterly}

julia> a = MIT{Quarterly}(20)
ERROR: MethodError: no method matching MIT{Quarterly}(::Int64)
Closest candidates are:
  MIT{Quarterly}(::T<:Number) where T<:Number at boot.jl:725
  MIT{Quarterly}(::Float16) where T<:Integer at float.jl:71
  MIT{Quarterly}(::Complex) where T<:Real at complex.jl:37
  ...
Stacktrace:
 [1] top-level scope at none:0

julia> ppy(::type{T}) where T <: Quarterly = 4
ERROR: UndefVarError: type not defined
Stacktrace:
 [1] top-level scope at none:0

julia> ppy(::Type{T}) where T <: Quarterly = 4
ppy (generic function with 1 method)

julia> ppy(::Type{T}) where T <: Monthly = 12
ppy (generic function with 2 methods)

julia> ppy(::Type{T}) where T <: Yearly = 1
ppy (generic function with 3 methods)

julia> ppy(Quarterly)
4

julia> M
MIME             Matrix            Method            Module
MIME"            Media             MethodError       MomentInTime
MIT              MergeSort         Missing           Monthly
MathConstants    Meta              MissingException
julia> history()
ERROR: UndefVarError: history not defined
Stacktrace:
 [1] top-level scope at none:0

julia> MIT{T}(x::Int64) = reinterpret(
reinterpret(::Type{Unsigned}, x::Float16) in Base at essentials.jl:382
reinterpret(::Type{Signed}, x::Float16) in Base at essentials.jl:383
reinterpret(::Type{Unsigned}, x::Float64) in Base at float.jl:848
reinterpret(::Type{Unsigned}, x::Float32) in Base at float.jl:849
reinterpret(::Type{Signed}, x::Float64) in Base at float.jl:850
reinterpret(::Type{Signed}, x::Float32) in Base at float.jl:851
reinterpret(::Type{T}, A::Base.ReshapedArray, dims::Tuple{Vararg{Int64e T in Base at reshapedarray.jl:191
reinterpret(::Type{Bool}, B::BitArray, dims::Tuple{Vararg{Int64,N}}) w
bitarray.jl:502
reinterpret(::Type, A::SparseArrays.AbstractSparseArray) in SparseArrame\Administrator\buildbot\worker\package_win64\build\usr\share\julia\srrays\src\abstractsparse.jl:40
reinterpret(::Type{T}, a::A) where {T, N, S, A<:AbstractArray{S,N}} inetarray.jl:14
reinterpret(::Type{T}, x) where T in Base at essentials.jl:381
reinterpret(B::BitArray, dims::Tuple{Vararg{Int64,N}}) where N in Base3
julia> MIT{T}(x::Int64) = reinterpret(MIT{T}, x)
ERROR: UndefVarError: T not defined
Stacktrace:
 [1] top-level scope at none:0

julia> MIT{T}(x::Int64) where T <: Frequency = reinterpret(MIT{T}, x)

julia> MIT{Quarterly}(123)
Error showing value of type MIT{Quarterly}:
ERROR: flipsign not defined for MIT{Quarterly}
julia> Base.show(io::IO, x::MIT{T}) where T <: Frequency = print(io, r
x))

julia> MIT{Quarterly}(123)
123

julia> Base.show(io::IO, x::MIT{T}) where T <: Frequency = print(io, serpret(Int64, x))

julia> MIT{Quarterly}(123)
Q123

julia> MIT{Monthly}(123)
M123

julia> qq(y, p) = MIT{Quarterly}(y*4+p)
qq (generic function with 2 methods)

julia> qq(2000,2)
MomentInTime{Quarterly_Jan}(8002)

julia> qq1(y, p) = MIT{Quarterly}(y*4+p)
qq1 (generic function with 1 method)

julia>

julia> qq1(2000,2)
Q8002

julia> qq1(2000,2):qq1(2000,4)
ERROR: <= not defined for MIT{Quarterly}
Stacktrace:
 [1] no_op_err(::String, ::Type) at .\promotion.jl:410
 [2] <=(::MIT{Quarterly}, ::MIT{Quarterly}) at .\promotion.jl:427
 [3] >=(::MIT{Quarterly}, ::MIT{Quarterly}) at .\operators.jl:333
 [4] unitrange_last(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:
 [5] UnitRange{MIT{Quarterly}}(::MIT{Quarterly}, ::MIT{Quarterly}) at
 [6] (::Colon)(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:5
 [7] top-level scope at none:0

julia> qq1(2000,2) + 1
ERROR: promotion of types MIT{Quarterly} and Int64 failed to change an
Stacktrace:
 [1] sametype_error(::Tuple{MIT{Quarterly},Int64}) at .\promotion.jl:3
 [2] not_sametype(::Tuple{MIT{Quarterly},Int64}, ::Tuple{MIT{Quarterlymotion.jl:302
 [3] +(::MIT{Quarterly}, ::Int64) at .\int.jl:802
 [4] top-level scope at none:0

julia> year(x::MIT{T}) where T <: Frequency = div(reinterpret(Int64, x
year (generic function with 1 method)

julia> year(qq1(2000,2))
2000

julia> period(x::MIT{T}) where T <: Frequency = rem(reinterpret(Int64,
period (generic function with 1 method)

julia> Base.show(io::IO, x::MIT{T}) where T <: Frequency = print(io, y1], period(x))

julia> qq1(2000,2)
2000Q2
julia> Base.:+(m::MIT{T}, x::Integer) where T <: Frequency = reinterprpret(Int64, m) + x))
ERROR: syntax: extra token ")" after end of expression

julia> Base.:+(m::MIT{T}, x::Integer) where T <: Frequency = reinterprpret(Int64, m) + x)

julia> qq1(2000,2) = 3
ERROR: syntax: "2000" is not a valid function argument name

julia> qq1(2000,2) + 3
2001Q1

julia> qq1(2000,2):qq1(2001,4)
ERROR: <= not defined for MIT{Quarterly}
Stacktrace:
 [1] no_op_err(::String, ::Type) at .\promotion.jl:410
 [2] <=(::MIT{Quarterly}, ::MIT{Quarterly}) at .\promotion.jl:427
 [3] >=(::MIT{Quarterly}, ::MIT{Quarterly}) at .\operators.jl:333
 [4] unitrange_last(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:
 [5] UnitRange{MIT{Quarterly}}(::MIT{Quarterly}, ::MIT{Quarterly}) at
 [6] (::Colon)(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:5
 [7] top-level scope at none:0
julia> Base.:(<=)(x::MIT{T}, y::MIT{T}) where T = reinterpret(Int64, xnt64, y)

julia> qq1(2000,2):qq1(2001,4)
ERROR: promotion of types MIT{Quarterly} and MIT{Quarterly} failed to ts
Stacktrace:
 [1] sametype_error(::Tuple{MIT{Quarterly},MIT{Quarterly}}) at .\promo
 [2] not_sametype(::Tuple{MIT{Quarterly},MIT{Quarterly}}, ::Tuple{MIT{rterly}}) at .\promotion.jl:302
 [3] -(::MIT{Quarterly}, ::MIT{Quarterly}) at .\int.jl:802
 [4] unitrange_last(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:
 [5] UnitRange{MIT{Quarterly}}(::MIT{Quarterly}, ::MIT{Quarterly}) at
 [6] (::Colon)(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:5
 [7] top-level scope at none:0
julia> Base.promote_rule(::Type{MIT{S}}, ::Type{T}) where T <: Integercy = Int64

julia> Int64(x::MIT{T}) where T <: Frequency = reinterpret(Int64, x)
Int64

julia> qq1(2000,2):qq1(2001,4)
ERROR: promotion of types MIT{Quarterly} and MIT{Quarterly} failed to ts
Stacktrace:
 [1] sametype_error(::Tuple{MIT{Quarterly},MIT{Quarterly}}) at .\promo
 [2] not_sametype(::Tuple{MIT{Quarterly},MIT{Quarterly}}, ::Tuple{MIT{rterly}}) at .\promotion.jl:302
 [3] -(::MIT{Quarterly}, ::MIT{Quarterly}) at .\int.jl:802
 [4] unitrange_last(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:
 [5] UnitRange{MIT{Quarterly}}(::MIT{Quarterly}, ::MIT{Quarterly}) at
 [6] (::Colon)(::MIT{Quarterly}, ::MIT{Quarterly}) at .\range.jl:5
 [7] top-level scope at none:0

julia> Base.:-(m::MIT{T}, x::Integer) where T <: Frequency = reinterprpret(Int64, m) - x)

julia> qq1(2000,2):qq1(2001,4)
2000Q2:2002Q0

julia> for z in qq1(2000,2):qq1(2001,4) display(z) end
ERROR: < not defined for MIT{Quarterly}
Stacktrace:
 [1] no_op_err(::String, ::Type) at .\promotion.jl:410
 [2] <(::MIT{Quarterly}, ::MIT{Quarterly}) at .\promotion.jl:426
 [3] >(::MIT{Quarterly}, ::MIT{Quarterly}) at .\operators.jl:286
 [4] isempty(::UnitRange{MIT{Quarterly}}) at .\range.jl:455
 [5] iterate(::UnitRange{MIT{Quarterly}}) at .\range.jl:571
 [6] top-level scope at .\none:0

julia> Base.:(<)(x::MIT{T}, y::MIT{T}) where T = reinterpret(Int64, x)64, y)
2000Q2
2000Q3
2001Q0
2001Q1
2001Q2
2001Q3
2002Q0

julia>
julia> MIT{[CQuarterly}(123)
ERROR: syntax: unexpected "}"

julia> qq1(y, p) = MIT{Quarterly}(y*4+p-1)
qq1 (generic function with 1 method)

julia> period(x::MIT{T}) where T <: Frequency = 1+rem(reinterpret(Int6
period (generic function with 1 method)

julia> qq1(2000,2)
2000Q2

julia> qq1(2000,3)
2000Q3

julia> qq1(2000,4)
2000Q4

julia> qq1(2000,5)
2001Q1
ay(z) end
2000Q2
2000Q3
2000Q4
2001Q1
2001Q2
2001Q3
2001Q4

julia>

```
