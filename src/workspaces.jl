# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

# 

export Workspace, AbstractWorkspace

abstract type AbstractWorkspace end

"""
    struct Workspace
        …
    end

A collection of variables. `Workspace`s can store data of any kind, including
numbers, `MIT`s, ranges, strings, `TSeries`, `MVTSeries`, even nested
`Workspace`s.

### Construction
Easiest is to start with and empty `Workspace` and fill it up later. Otherwise,
content can be provided at construction time as a collection of name-value
pairs, where the name must be a `Symbol` and the value can be anything.

### Access
Members of the `Workspace` can be accessed using "dot" notation or using
`[]` indexing, like a dictionary.

"""
struct Workspace <: AbstractWorkspace
    _c::OrderedDict{Symbol,Any}
    # punt construction to container
    Workspace(args...; kwargs...) = new(OrderedDict{Symbol,Any}(args...; kwargs...))
    # Allow construction like this: Workspace(; var1=val1, var2=val2, ...)
    Workspace(; kw...) = new(OrderedDict{Symbol,Any}(kw))
end

_c(w::AbstractWorkspace) = getfield(w, :_c)

_dict_to_workspace(x) = x
_dict_to_workspace(x::AbstractDict) = Workspace(x; recursive=true)
function Workspace(fromdict::AbstractDict; recursive=false)
    w = Workspace()
    if Base.haslength(fromdict)
        Base.sizehint!(_c(w), length(fromdict))
    end
    convert_value = recursive ? _dict_to_workspace : identity
    for (key, value) in fromdict
        w[Symbol(key)] = convert_value(value)
    end
    return w
end

Base.propertynames(w::AbstractWorkspace, private::Bool=false) = tuple(keys(w)...)
Base.getproperty(w::AbstractWorkspace, sym::Symbol) = sym === :_c ? _c(w) : getindex(w, sym)
Base.setproperty!(w::AbstractWorkspace, sym::Symbol, val) = setindex!(w, val, sym)

# MacroTools.@forward Workspace._c (Base.getindex,)
Base.getindex(w::AbstractWorkspace, sym) = getindex(_c(w), convert(Symbol, sym))
Base.getindex(w::AbstractWorkspace, sym, syms...) = getindex(w, (sym, syms...,))
Base.getindex(w::AbstractWorkspace, syms::Vector) = Workspace(convert(Symbol, s) => w[s] for s in syms)
Base.getindex(w::AbstractWorkspace, syms::Tuple) = Workspace(convert(Symbol, s) => w[s] for s in syms)

MacroTools.@forward Workspace._c (Base.setindex!,)
MacroTools.@forward Workspace._c (Base.isempty, Base.keys, Base.haskey, Base.values, Base.length)
MacroTools.@forward Workspace._c (Base.iterate, Base.get, Base.get!,)

function Base.eltype(w::AbstractWorkspace)
    ET = isempty(w) ? Any : try
        Base.promote_typeof(values(w)...)
    catch
        Any
    end
    return Pair{Symbol,ET}
end
function Base.eltype(w::AbstractWorkspace)
    ET = isempty(w) ? Any : reduce(Base.promote_typeof, values(w))
    return Pair{Symbol,ET}
end

Base.push!(w::AbstractWorkspace, args...; kwargs...) = (push!(_c(w), args..., (k => v for (k, v) in kwargs)...); w)
Base.delete!(w::AbstractWorkspace, args...; kwargs...) = (delete!(_c(w), args...; kwargs...); w)

@inline Base.in(name, w::AbstractWorkspace) = convert(Symbol, name) ∈ keys(_c(w))
Base.get(f::Function, w::AbstractWorkspace, key) = get(f, _c(w), key)
Base.get!(f::Function, w::AbstractWorkspace, key) = get!(f, _c(w), key)

"""
    rangeof(w; method=intersect)

Calculate the range of a [`Workspace`](@ref) as the intersection of the ranges
of all [`TSeries`](@ref), [`MVTSeries`](@ref) and [`Workspace`](@ref) members of
`w`. If there are objects of different frequencies there will be a
mixed-frequency error.

Optionally, parameter `method=` can be set to a custom function that combines
two UnitRanges into one UnitRange. If not specified, it defaults to `intersect`.

If you want the range that spans the ranges of all members of `w` it would be
better to call `rangeof_span(values(m)...)`.
"""
rangeof(w::AbstractWorkspace; method=intersect) = (
    iterable = (v for v in values(w) if applicable(rangeof, v));
    mapreduce(rangeof, method, iterable)
)

# _to_unitrange is only used in the implementation of rangeof_span, which requires union of ranges. 
_to_unitrange(x::AbstractWorkspace) = rangeof_span(
    Iterators.map(
        _to_unitrange, values(x)
    )...
)

_has_frequencyof(::Type{<:AbstractWorkspace}) = true
_has_frequencyof(::T) where {T} = _has_frequencyof(T)
_has_frequencyof(::Type{<:MIT}) = true
_has_frequencyof(::Type{<:Duration}) = true
_has_frequencyof(::Type{<:AbstractArray{T}}) where {T} = _has_frequencyof(T)
function _has_frequencyof(::Type{T}) where {T}
    try
        frequencyof(T)
        return true
    catch
        return false
    end
end

function frequencyof(w::AbstractWorkspace; check=false)
    # recursively collect all frequencies in w.
    freqs = []
    for v in values(w)
        if _has_frequencyof(v)
            fr = frequencyof(v)
            if !isnothing(fr)
                push!(freqs, fr)
            end
        end
    end
    # return something or throw error based of number f frequencies found.
    if length(freqs) == 1
        return freqs[1]
    elseif check
        if isempty(freqs)
            throw(ArgumentError("The given workspace doesn't have a frequency."))
        else
            throw(ArgumentError("The given workspace has multiple frequencies: $((freqs...,))."))
        end
    else
        return nothing
    end
end

function Base.summary(io::IO, w::Workspace)
    if isempty(w)
        return print(io, "Empty Workspace")
    end
    nvar = length(w)
    return print(io, "Workspace with ", nvar, " variable", nvar == 1 ? "" : "s")
end

Base.show(io::IO, x::AbstractWorkspace) = show(io, MIME"text/plain"(), x)
function Base.show(io::IO, ::MIME"text/plain", w::AbstractWorkspace)

    summary(io, w)

    nvars = length(w)
    nvars == 0 && return

    limit = get(io, :limit, true)
    io = IOContext(io, :SHOWN_SET => _c(w),
        :typeinfo => eltype(w),
        :compact => get(io, :compact, true),
        :limit => limit)


    dheight, dwidth = displaysize(io)

    if limit && nvars + 5 > dheight
        # we're printing some but not all rows (no room on the screen)
        top = div(dheight - 5, 2)
        bot = nvars - dheight + 7 + top
    else
        top, bot = nvars + 1, nvars + 1
    end

    max_align = 0
    prows = Vector{String}[]
    for (i, (k, v)) ∈ enumerate(w)
        top < i < bot && continue

        sk = sprint(print, k, context=io, sizehint=0)
        if v isa Union{AbstractString,Symbol,AbstractRange,Dates.Date,Dates.DateTime}
            # It's a string or a Symbol
            sv = sprint(show, v, context=io, sizehint=0)
        elseif typeof(v) == eltype(v) || typeof(v) isa Type{<:DataType}
            #  it's a scalar value
            sv = sprint(print, v, context=io, sizehint=0)
        else
            sv = sprint(summary, v, context=io, sizehint=0)
        end
        max_align = max(max_align, length(sk))

        push!(prows, [sk, sv])
        i == top && push!(prows, ["⋮", "⋮"])
    end

    cutoff = dwidth - 5 - max_align

    for (sk, sv) ∈ prows
        lv = length(sv)
        sv = lv <= cutoff ? sv : sv[1:cutoff-1] * "…"
        print(io, "\n  ", lpad(sk, max_align), " ⇒ ", sv)
    end

end


###########################

"""
    strip!(w::Workspace; recursive=true)

Apply [`strip!`](@ref) to all TSeries members of the given workspace. This
includes nested workspaces, unless `recursive=false`.

"""
function strip!(w::AbstractWorkspace; recursive=true)
    for (key, value) in w._c
        if value isa TSeries
            strip!(value)
        elseif recursive && value isa Workspace
            strip!(value; recursive)
        end
    end
    return w
end

###########################
Base.filter(f, w::AbstractWorkspace) = typeof(w)(filter(f, _c(w)))
Base.filter!(f, w::AbstractWorkspace) = (filter!(f, _c(w)); w)


###########################
_weval_impl(W, sym::Symbol) = :(haskey($W, $(Meta.quot(sym))) ? $W.$sym : $sym)
_weval_impl(_, any::Any) = any
_weval_impl(W, EXPR::Expr) = begin
    if MacroTools.@capture(EXPR, func_(args__))
        return Expr(:call, func, (_weval_impl(W, a) for a in args)...)
    elseif MacroTools.@capture(EXPR, $W)
        return EXPR
    elseif MacroTools.@capture(EXPR, $W.sym_)
        return EXPR
    elseif MacroTools.@capture(EXPR, $W[:sym_])
        return EXPR
    else
        return Expr(EXPR.head, MacroTools.postwalk.(x -> _weval_impl(W, x), EXPR.args)...)
    end
end

"""
    @weval W expression

Evaluate an expression using the members of `Workspace` W as if they were
variables.
"""
macro weval(W, EXPR)
    return esc(_weval_impl(W, EXPR))
end
export @weval


Base.copyto!(x::MVTSeries, w::AbstractWorkspace; verbose=false, trange=rangeof(x)) = copyto!(x, trange, w; verbose)
function Base.copyto!(x::MVTSeries, range::AbstractUnitRange{<:MIT}, w::AbstractWorkspace; verbose=false)
    missing = []
    for (key, value) in pairs(x)
        w_val = get(w, key, nothing)
        if !isnothing(w_val)
            copyto!(value, range, w_val)
        else
            verbose && push!(missing, key)
        end
    end
    if verbose
        @warn "Variables not copied (missing from Workspace): $(join(missing, ", "))"
    end
    return x
end

function Base.map(f::Function, w::AbstractWorkspace)
    ret = typeof(w)()
    for (k, v) in w
        ret[k] = f(v)
    end
    return ret
end

