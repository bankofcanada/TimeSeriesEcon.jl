# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

# 

export Workspace

"""
    struct Workspace … end

A collection of variables.
"""
struct Workspace
    contents::OrderedDict{Symbol,Any}
    Workspace() = new(OrderedDict{Symbol,Any}())
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
Base.values(w::Workspace) = values(_c(w))
Base.iterate(w::Workspace, args...) = iterate(_c(w), args...)


function Base.show(io::IO, ::MIME"text/plain", w::Workspace)

    if isempty(w)
        return print(io, "Empty Workspace")
    end

    nvars = length(_c(w))
    println(io, "Workspace with ", nvars, "-variables")

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
        sv = sprint(summary, v, context = io, sizehint = 0)
        max_align = max(max_align, length(sk))

        push!(prows, [sk, sv])
        i == top && push!(prows, ["⋮", "⋮"])
    end

    cutoff = dwidth - 5 - max_align

    for (sk, sv) ∈ prows
        lv = length(sv)
        sv = lv <= cutoff ? sv : sv[1:cutoff-1] * "…"
        println(io, "  ", lpad(sk, max_align), " ⇒ ", sv)
    end

end

