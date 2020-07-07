# mode: julia
	primitive type MIT{T} <: Signed64 end
# time: 2020-02-21 14:58:19 EST
# mode: julia
	primitive type MIT{T} <: Signed 64 end
# time: 2020-02-21 14:58:29 EST
# mode: julia
	a = MIT{Quarterly}
# time: 2020-02-21 14:58:37 EST
# mode: julia
	a = MIT{Quarterly}(20)
# time: 2020-02-21 14:59:33 EST
# mode: julia
	ppy(::type{T}) where T <: Quarterly = 4
# time: 2020-02-21 14:59:42 EST
# mode: julia
	ppy(::Type{T}) where T <: Quarterly = 4
# time: 2020-02-21 14:59:54 EST
# mode: julia
	ppy(::Type{T}) where T <: Monthly = 12
# time: 2020-02-21 15:00:02 EST
# mode: julia
	ppy(::Type{T}) where T <: Yearly = 1
# time: 2020-02-21 15:00:08 EST
# mode: julia
	ppy(Quarterly)
# time: 2020-02-21 15:00:26 EST
# mode: julia
	history()
# time: 2020-02-21 15:01:32 EST
# mode: julia
	MIT{T}(x::Int64) = reinterpret(MIT{T}, x)
# time: 2020-02-21 15:01:44 EST
# mode: julia
	MIT{T}(x::Int64) where T <: Frequency = reinterpret(MIT{T}, x)
# time: 2020-02-21 15:01:53 EST
# mode: julia
	MIT{Quarterly}(123)
# time: 2020-02-21 15:03:04 EST
# mode: julia
	Base.show(io::IO, x::MIT{T}) where T <: Frequency = print(io, reinterpret(Int64, x))
# time: 2020-02-21 15:03:07 EST
# mode: julia
	MIT{Quarterly}(123)
# time: 2020-02-21 15:03:22 EST
# mode: julia

# time: 2020-02-21 15:03:24 EST
# mode: julia
	MIT{Quarterly}(123)
# time: 2020-02-21 15:03:32 EST
# mode: julia
	MIT{Monthly}(123)
# time: 2020-02-21 15:04:14 EST
# mode: julia
	qq(y, p) = MIT{Quarterly}(y*4+p)
# time: 2020-02-21 15:04:23 EST
# mode: julia
	qq(2000,2)
# time: 2020-02-21 15:04:40 EST
# mode: julia
	qq1(y, p) = MIT{Quarterly}(y*4+p)
# time: 2020-02-21 15:04:50 EST
# mode: julia
	qq1(2000,2)
# time: 2020-02-21 15:05:02 EST
# mode: julia
	qq1(2000,2):qq1(2000,4)
# time: 2020-02-21 15:06:08 EST
# mode: julia
	qq1(2000,2) + 1
# time: 2020-02-21 15:07:51 EST
# mode: julia
	year(x::MIT{T}) where T <: Frequency = div(reinterpret(Int64, x), ppy(T))
# time: 2020-02-21 15:08:00 EST
# mode: julia
	year(qq1(2000,2))
# time: 2020-02-21 15:08:16 EST
# mode: julia
	period(x::MIT{T}) where T <: Frequency = rem(reinterpret(Int64, x), ppy(T))
# time: 2020-02-21 15:08:42 EST
# mode: julia
	Base.show(io::IO, x::MIT{T}) where T <: Frequency = print(io, year(x), string(T)[1], period(x))
# time: 2020-02-21 15:08:47 EST
# mode: julia
	qq1(2000,2)
# time: 2020-02-21 15:11:04 EST
# mode: julia
	Base.:+(m::MIT{T}, x::Integer) where T <: Frequency = reinterpret(MIT{T}, reinterpret(Int64, m) + x))
# time: 2020-02-21 15:11:06 EST
# mode: julia
	Base.:+(m::MIT{T}, x::Integer) where T <: Frequency = reinterpret(MIT{T}, reinterpret(Int64, m) + x)
# time: 2020-02-21 15:11:13 EST
# mode: julia
	qq1(2000,2) = 3
# time: 2020-02-21 15:11:17 EST
# mode: julia
	qq1(2000,2) + 3
# time: 2020-02-21 15:11:29 EST
# mode: julia
	qq1(2000,2):qq1(2001,4)
# time: 2020-02-21 15:12:34 EST
# mode: julia
	Base.:(<=)(x::MIT{T}, y::MIT{T}) where T = reinterpret(Int64, x) <= reinterpret(Int64, y)
# time: 2020-02-21 15:12:36 EST
# mode: julia
	qq1(2000,2):qq1(2001,4)
# time: 2020-02-21 15:15:30 EST
# mode: julia
	Base.promote_rule(::Type{MIT{S}}, ::Type{T}) where T <: Integer where S <:Frequency = Int64
# time: 2020-02-21 15:15:59 EST
# mode: julia
	Int64(x::MIT{T}) where T <: Frequency = reinterpret(Int64, x)
# time: 2020-02-21 15:16:04 EST
# mode: julia
	qq1(2000,2):qq1(2001,4)
# time: 2020-02-21 15:16:28 EST
# mode: julia
	Base.:-(m::MIT{T}, x::Integer) where T <: Frequency = reinterpret(MIT{T}, reinterpret(Int64, m) - x)
# time: 2020-02-21 15:16:29 EST
# mode: julia
	qq1(2000,2):qq1(2001,4)
# time: 2020-02-21 15:17:22 EST
# mode: julia
	for z in qq1(2000,2):qq1(2001,4) display(z) end
# time: 2020-02-21 15:17:49 EST
# mode: julia
	Base.:(<)(x::MIT{T}, y::MIT{T}) where T = reinterpret(Int64, x) < reinterpret(Int64, y)
# time: 2020-02-21 15:17:50 EST
# mode: julia
	for z in qq1(2000,2):qq1(2001,4) display(z) end
# time: 2020-02-21 15:19:29 EST
# mode: julia
	MIT{[CQuarterly}(123)
# time: 2020-02-21 15:19:57 EST
# mode: julia
	qq1(y, p) = MIT{Quarterly}(y*4+p-1)
# time: 2020-02-21 15:20:12 EST
# mode: julia
	period(x::MIT{T}) where T <: Frequency = 1+rem(reinterpret(Int64, x), ppy(T))
# time: 2020-02-21 15:20:21 EST
# mode: julia
	qq1(2000,2)
# time: 2020-02-21 15:20:24 EST
# mode: julia
	qq1(2000,3)
# time: 2020-02-21 15:20:26 EST
# mode: julia
	qq1(2000,4)
# time: 2020-02-21 15:20:28 EST
# mode: julia
	qq1(2000,5)
# time: 2020-02-21 15:20:44 EST
# mode: julia
	for z in qq1(2000,2):qq1(2001,4) display(z) end
