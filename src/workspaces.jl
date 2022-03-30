# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# 

export Workspace

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
struct Workspace
    _c::OrderedDict{Symbol,Any}
    # punt construction to container
    Workspace(args...; kwargs...) = new(OrderedDict{Symbol,Any}(args...; kwargs...))
    # Allow construction like this: Workspace(; var1=val1, var2=val2, ...)
    Workspace(; kw...) = new(OrderedDict{Symbol,Any}(kw))
end

_c(w::Workspace) = getfield(w, :_c)

_dict_to_workspace(x) = x
_dict_to_workspace(x::AbstractDict) = Workspace(x)
function Workspace(fromdict::AbstractDict; recursive=false)
    w = Workspace()
    convert_value = recursive ? _dict_to_workspace : identity
    for (key, value) in fromdict
        w[Symbol(key)] = convert_value(value)
    end
    return w
end

Base.propertynames(w::Workspace, private::Bool=false) = tuple(keys(w)...)
Base.getproperty(w::Workspace, sym::Symbol) = sym === :_c ? _c(w) : getindex(w, sym)
Base.setproperty!(w::Workspace, sym::Symbol, val) = setindex!(w, val, sym)

# MacroTools.@forward Workspace._c (Base.getindex,)
Base.getindex(w::Workspace, sym) = getindex(_c(w), convert(Symbol, sym))
Base.getindex(w::Workspace, sym, syms...) = getindex(w, (sym, syms...,))
Base.getindex(w::Workspace, syms::Vector) = getindex(w, (syms...,))
Base.getindex(w::Workspace, syms::Tuple) = Workspace(convert(Symbol, s) => w[s] for s in syms)

MacroTools.@forward Workspace._c (Base.setindex!,)
MacroTools.@forward Workspace._c (Base.isempty, Base.keys, Base.haskey, Base.values, Base.length)
MacroTools.@forward Workspace._c (Base.iterate, Base.get, Base.get!, Base.push!, Base.delete!)
MacroTools.@forward Workspace._c (Base.eltype,)

@inline Base.in(name, w::Workspace) = convert(Symbol, name) ∈ keys(_c(w))
Base.get(f::Function, w::Workspace, key) = get(f, _c(w), key)
Base.get!(f::Function, w::Workspace, key) = get!(f, _c(w), key)

"""
    rangeof(w)

Calculate the range of a [`Workspace`](@ref) as the intersection of the ranges
of all [`TSeries`](@ref), [`MVTSeries`](@ref) and [`Workspace`](@ref) members of
`w`. If there are objects of different frequencies there will be a
mixed-frequency error.
"""
rangeof(w::Workspace) = (
    iterable = (v for v in values(w) if hasmethod(rangeof, (typeof(v),)));
    mapreduce(rangeof, intersect, iterable)
)


function Base.summary(io::IO, w::Workspace)
    if isempty(w)
        return print(io, "Empty Workspace")
    end
    return print(io, "Workspace with ", length(w), "-variables")
end

function Base.show(io::IO, ::MIME"text/plain", w::Workspace)

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
        if v isa Union{AbstractString,Symbol,AbstractRange}
            # It's a string or a Symbol
            sv = sprint(show, v, context=io, sizehint=0)
        elseif typeof(v) == eltype(v)
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
function strip!(w::Workspace; recursive=true)
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
Base.filter(f,w::Workspace) = Workspace(filter(f,_c(w)))
Base.filter!(f,w::Workspace) = (filter!(f,_c(w)); w)

