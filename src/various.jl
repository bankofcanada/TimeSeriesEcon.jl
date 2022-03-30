# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.


"""
    @showall X

Print all data in `X` without truncating the output to fit the size of the  
screen.
"""
macro showall(a)
    return esc(:(show(IOContext(stdout, :limit => false), $a)))
end
export @showall

#### overlay

"""
    overlay(arg1, args...)

Return the first argument, from left to right, that is valid. At least one
argument must be given. Validity is determined by calling [`istypenan`](@ref).
If it returns `true`, the observation is not valid; `false` means it is.
"""
function overlay end
export overlay

overlay(onething) = onething
overlay(head, tail...) = istypenan(head) ? overlay(tail...) : head

"""
    overlay([rng,] t1, t2, ...)

Construct a [`TSeries`](@ref) in which each observation is taken from the first
valid observation in the list of arguments. A valid observation is one
for which [`istypenan`](@ref) returns `false`.

All [`TSeries`](@ref) in the arguments list must be of the same frequency. The
data type of the resulting [`TSeries`](@ref) is decided by the standard
promotion of numerical types in Julia. Its range is the union of the ranges of
the arguments, unless the optional `rng` is ginven in which case it becomes the
range.
"""
overlay(tseries::TSeries...) = overlay(mapreduce(rangeof, union, tseries), tseries...)
function overlay(rng::AbstractRange{<:MIT}, tseries::TSeries...)
    T = mapreduce(eltype, promote_type, tseries)
    ret = TSeries(rng, typenan(T))
    # todo = contains `true` for locations that don't yet contain valid values.
    todo = trues(rng)
    for ts in tseries
        # quit if nothing left to do
        any(todo) || break
        for (mit, val) in zip(rangeof(ts), ts.values)
            # skip if outside overlay range
            mit ∈ rng || continue
            # skip if already done
            todo[mit] || continue
            # skip if not valid
            istypenan(val) && continue
            # still here? assign and mark done
            ret[mit] = val
            todo[mit] = false
        end
    end
    return ret
end

const LikeWorkspace = Union{Workspace,MVTSeries,AbstractDict{Symbol,<:Any}}

_c(x::MVTSeries) = _cols(x)
_c(x::AbstractDict) = x

"""
    overlay(data1, data2, ...)

When overlaying `Workspace`s and `MVTSeries` the result is a `Workspace` and
each member is overlaid recursively.
"""
function overlay(workspaces::LikeWorkspace...)
    ret = Workspace()
    names = mapreduce(keys, union, workspaces)
    for name in names
        things = [w[name] for w in workspaces if haskey(w, name)]
        ret[name] = overlay(things...)
    end
    return ret
end

# overlay(stuff::Vararg{LikeWorkspace}) =
#     Workspace(mergewith(overlay, (_c(w) for w in stuff)...))


#### compare and @compare 

"""
@compare x y [options] 
compare(x, y [; options])

Compare two `Workspace` recursively and print out the differences. `MVTSeries`
and `Dict` with keys of type `Symbol` are treated like `Workspace`. `TSeries` and
other `Vector` are compared using `isapprox`, so feel free to supply `rtol` or
`atol`.

Optional argument `name` can be used for the top name. Default is `"_"`.

Parameter `showequal=true` causes the report to include objects that are the
same. Default behaviour, with `showequal=false`, is to report only the
differences. 

Parameter `ignoremissing=true` causes objects that appear in one but not the
other workspace to be ignored. That is, they are not printed and do not affect
the return value `true` or `false`. Default is `ignoremissing=false` meaning
they will be printed and return value will be `false`.

"""
function compare end, macro compare end
export compare, @compare


@inline compare_equal(x, y; kwargs...) = isequal(x, y)
@inline compare_equal(x::Number, y::Number; atol=0, rtol=atol > 0 ? 0.0 : √eps(), nans::Bool=false, kwargs...) = isapprox(x, y; atol, rtol, nans)
@inline compare_equal(x::AbstractVector, y::AbstractVector; atol=0, rtol=atol > 0 ? 0.0 : √eps(), nans::Bool=false, kwargs...) = isapprox(x, y; atol, rtol, nans)
function compare_equal(x::TSeries, y::TSeries; trange=nothing, atol=0, rtol=atol > 0 ? 0.0 : √eps(), nans::Bool=false, kwargs...)
    if trange === nothing || !(frequencyof(x) == frequencyof(y) == frequencyof(trange))
        trange = intersect(rangeof(x), rangeof(y))
    end
    isapprox(x[trange], y[trange]; atol, rtol, nans)
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

function compare(x, y, name=Symbol("_");
    showequal=false, ignoremissing=false, quiet=false,
    left=:left, right=:right,
    names=Symbol[],
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
        compare($x, $y; left=$(QuoteNode(x)), right=$(QuoteNode(y)))
    end)
    # find the array of kw-parameters in ret
    params = []
    for a in ret.args
        if MacroTools.isexpr(a, :parameters)
            params = a.args
            break
        end
    end
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
