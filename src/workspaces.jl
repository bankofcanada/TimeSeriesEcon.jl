# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# 

export Workspace

"""
    struct Workspace … end

A collection of variables.
"""
struct Workspace
    contents::OrderedDict{Symbol,Any}
    # punt construction to container
    Workspace(args...; kwargs...) = new(OrderedDict{Symbol,Any}(args...; kwargs...))
    # Allow construction like this: Workspace(; var1=val1, var2=val2, ...)
    Workspace(; kw...) = new(OrderedDict{Symbol,Any}(kw))
end

@inline _c(w::Workspace) = getfield(w, :contents)

Base.propertynames(w::Workspace) = tuple(keys(_c(w))...)
Base.getproperty(w::Workspace, sym::Symbol) = getindex(_c(w), sym)
Base.setproperty!(w::Workspace, sym::Symbol, val) = setindex!(_c(w), val, sym)

Base.getindex(w::Workspace, Args...) = getindex(_c(w), Args...)
Base.setindex!(w::Workspace, Args...) = setindex!(_c(w), Args...)

@inline Base.isempty(w::Workspace) = isempty(_c(w))
@inline Base.in(name, w::Workspace) = Symbol(name) ∈ keys(_c(w))

Base.keys(w::Workspace) = keys(_c(w))
Base.haskey(w::Workspace, k::Symbol) = haskey(_c(w), k)
Base.values(w::Workspace) = values(_c(w))
Base.length(w::Workspace) = length(_c(w))
Base.iterate(w::Workspace, args...) = iterate(_c(w), args...)
Base.get(w::Workspace, key, default) = get(_c(w), key, default)
Base.get(f::Function, w::Workspace, key) = get(f, _c(w), key)
Base.get!(w::Workspace, key, default) = get!(_c(w), key, default)
Base.get!(f::Function, w::Workspace, key) = get!(f, _c(w), key)
Base.push!(w::Workspace, args...; kwargs...) = (push!(_c(w), args...; kwargs...); w)

function Base.summary(io::IO, w::Workspace)
    if isempty(w)
        return print(io, "Empty Workspace")
    end

    nvars = length(_c(w))
    return print(io, "Workspace with ", nvars, "-variables")
end

function Base.show(io::IO, ::MIME"text/plain", w::Workspace)

    summary(io, w)

    nvars = length(_c(w))
    nvars == 0 && return

    limit = get(io, :limit, true)
    io = IOContext(io, :SHOWN_SET => _c(w),
        :typeinfo => eltype(_c(w)),
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
    for (i, (k, v)) ∈ enumerate(_c(w))
        top < i < bot && continue

        sk = sprint(print, k, context = io, sizehint = 0)
        if typeof(v) == eltype(v) # is it a scalar value?
            sv = sprint(print, v, context = io, sizehint = 0)
        else
            sv = sprint(summary, v, context = io, sizehint = 0)
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

_dict_to_workspace(x) = x
_dict_to_workspace(x::AbstractDict) = Workspace(x)
function Workspace(fromdict::AbstractDict; recursive = false)
    w = Workspace()
    convert_value = ifelse(recursive, _dict_to_workspace, identity)
    for (key, value) in fromdict
        push!(_c(w), Symbol(key) => convert_value(value))
    end
    return w
end

@inline _c(x::MVTSeries) = _cols(x)

function Base.mergewith(combine, stuff::Union{Workspace,MVTSeries}...)
    return Workspace(mergewith(combine, (_c(w) for w in stuff)...))
end

overlay(stuff...) = stuff[1]
overlay(w::Vararg{Union{Workspace,MVTSeries}}) = mergewith(overlay, w...)
