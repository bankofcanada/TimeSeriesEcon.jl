# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# 

export Workspace

"""
    struct Workspace … end

A collection of variables.
"""
struct Workspace
    _c::OrderedDict{Symbol,Any}
    # punt construction to container
    Workspace(args...; kwargs...) = new(OrderedDict{Symbol,Any}(args...; kwargs...))
    # Allow construction like this: Workspace(; var1=val1, var2=val2, ...)
    Workspace(; kw...) = new(OrderedDict{Symbol,Any}(kw))
end

@inline _c(w::Workspace) = getfield(w, :_c)

Base.propertynames(w::Workspace, private::Bool = false) = tuple(keys(w)...)
Base.getproperty(w::Workspace, sym::Symbol) = sym == :_c ? _c(w) : getindex(w, sym)
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
        push!(w, Symbol(key) => convert_value(value))
    end
    return w
end

const LikeWorkspace = Union{Workspace,MVTSeries,AbstractDict{Symbol,<:Any}}

@inline _c(x::MVTSeries) = _cols(x)
@inline _c(x::AbstractDict) = x

overlay(stuff...) = stuff[1]
overlay(stuff::Vararg{LikeWorkspace}) = Workspace(mergewith(overlay, (_c(w) for w in stuff)...))

###########################

"""
    @compare x y [options] 
    compare(x, y [; options])

Compare two `Workspace` recursively and print out the differences. `MVTSeries`
and `Dict` with keys of type `Symbol` are treated like `Workspace`. `TSeries` and
other `Vector` are compared using `isapprox`, so feel free to supply `rtol` or
`atol`.

Optional argument `name` can be used for the top name. Default is `"!"`.

Parameter `showequal=true` causes the report to include objects that are the
same. Default behaviour, with `showequal=false`, is to report only the
differences.

"""
function compare end, macro compare end
export compare, @compare


@inline compare_equal(x, y; kwargs...) = isequal(x, y)
@inline compare_equal(x::AbstractVector, y::AbstractVector; atol = 0, rtol = atol > 0 ? 0.0 : √eps(), kwargs...) = isapprox(x, y; atol, rtol)
function compare_equal(x::TSeries, y::TSeries; trange=nothing, atol = 0, rtol = atol > 0 ? 0.0 : √eps(), kwargs...) 
    if trange === nothing || !(frequencyof(x) == frequencyof(y) == frequencyof(trange))
        trange = intersect(rangeof(x), rangeof(y))
    end
    isapprox(x[trange], y[trange]; atol, rtol)
end

function compare_equal(x::LikeWorkspace, y::LikeWorkspace; kwargs...)
    equal = true
    for name in union(keys(x), keys(y))
        xval = get(x, name, missing)
        yval = get(y, name, missing)
        if !compare(xval, yval, name; kwargs...)
            equal = false
        end
    end
    return equal
end

@inline compare_print(names, message, quiet) = quiet ? nothing : println(join(names, "."), ": ", message)

function compare(x, y, name = Symbol("_");
    showequal = false, ignoremissing = false, quiet = false,
    left = :left, right = :right,
    names = Symbol[], 
    kwargs...)
    push!(names, name)
    if ismissing(x)
        equal = ignoremissing
        ignoremissing || compare_print(names, "missing in $left", quiet)
    elseif ismissing(y)
        equal = ignoremissing
        ignoremissing || compare_print(names, "missing in $right", quiet)
    elseif compare_equal(x, y; showequal, ignoremissing, names, left, right, kwargs...)
        (showequal || length(names) == 1) && compare_print(names, "same", quiet)
        equal = true
    else
        compare_print(names, "different", quiet)
        equal = false
    end
    pop!(names)
    return equal
end

macro compare(x, y, kwargs...)
    # build the basic compare call
    ret = MacroTools.unblock(quote
        compare($x, $y; left = $(QuoteNode(x)), right = $(QuoteNode(y)))
    end)
    # find the array of kw-parameters in ret
    params = (()->for a in ret.args
        if MacroTools.isexpr(a, :parameters)
            return a.args
        end
    end)()
    # convert arguments to this macro to kw-parameters to the compare() call
    for arg in kwargs
        if arg isa Symbol
            kw = Expr(:kw, arg, true)
        elseif MacroTools.isexpr(arg, :(=))
            kw = Expr(:kw, arg.args...)
        else
            kw = arg
        end
        push!(params, kw)
    end
    # done
    return esc(ret)
end

###########################

"""
    strip!(w::Workspace; recursive=true)

Apply [`strip!`](@ref) to all TSeries members of the given workspace. This
includes nested workspaces, unless `recursive=false`.

"""
function strip!(w::Workspace; recursive = true)
    for (key, value) in w._c
        if value isa TSeries
            strip!(value)
        elseif recursive && value isa Workspace
            strip!(value; recursive)
        end
    end
    return w
end