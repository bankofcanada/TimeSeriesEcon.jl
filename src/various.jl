# Copyright (c) 2020-2023, Bank of Canada
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

"""
    overlay(data::MVTSeries, datan::MVTSeries...)

When all arguments are `MVTSeries` the result is an `MVTSeries` of the overlayed
range and the ordered union of the columns. Each column is an overlay of the
corresponding `TSeries`.
"""
function overlay(args::MVTSeries...)
    isempty(args) && return MVTSeries()
    rng = mapreduce(rangeof, union, args)
    names = collect(mapfoldl(keys, union, args, init=OrderedSet{Symbol}()))
    ET = mapreduce(eltype, promote_type, args)
    ret = MVTSeries(rng, names, typenan(ET))
    for name in names
        ret[:, name] .= overlay(rng, (arg[name] for arg in args if name in keys(arg))...)
    end
    return ret
end


#### merge! and merge

@inline Base.empty!(w::Workspace) = (empty!(w._c); w)
@inline Base.merge!(w::Workspace, others::Union{Workspace,<:AbstractDict}...) = (
    merge!(_c(w), map(_c, others)...);
    w
)
@inline Base.merge(w::Workspace, others::Union{Workspace,<:AbstractDict}...) = merge!(Workspace(), w, others...)

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
@inline compare_equal(x::AbstractArray{<:Number}, y::AbstractArray{<:Number}; atol=0, rtol=atol > 0 ? 0.0 : √eps(), nans::Bool=false, kwargs...) = isapprox(x, y; atol, rtol, nans)
function compare_equal(x::TSeries, y::TSeries; trange::Union{Nothing,AbstractUnitRange{<:MIT}}=nothing, atol=0, rtol=atol > 0 ? 0.0 : √eps(), nans::Bool=false, kwargs...)
    if trange === nothing || !(frequencyof(x) == frequencyof(y) == frequencyof(trange))
        trange = intersect(rangeof(x), rangeof(y))
    end
    isempty(trange) || isapprox(x[trange], y[trange]; atol, rtol, nans)
end

function compare_equal(x::AbstractArray, y::AbstractArray; kwargs...)
    equal = true
    for i in union(eachindex(x), eachindex(y))
        xval = i ∈ eachindex(x) ? x[i] : missing
        yval = i ∈ eachindex(y) ? y[i] : missing
        if !compare(xval, yval, Symbol(i); kwargs...)
            equal = false
        end
    end
    return equal
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
    elseif compare_equal(x, y; showequal, ignoremissing, names, left, right, quiet, kwargs...)
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



####  reindex

"""
    reindex(ts, from => to; copy = false)
    reindex(w, from => to; copy = false)
    reindex(rng, from => to)

The function `reindex` re-indexes the `TSeries` or `MVTSeries` `ts`, 
or those contained in the `Workspace` `w`, 
or the `UnitRange` `rng`, 
so that the `MIT` `from` becomes the `MIT` `to` leaving the data unchanged.
For a `Workspace`, only objects  with the same frequency as the first element of the pair
will be reindexed; also, nested `Workspace`s are reindexed recursively.

By default, the data is not copied.

Example:
With a `TSeries` or an `MVTSeries` 
```
ts = MVTSeries(2020Q1,(:y1,:y2),randn(10,2))
ts2 = reindex(ts,2021Q1 => 1U; copy = true)
ts2.y2[3U] = 9999
ts
ts2
```
With a `Workspace`
```
w = Workspace();
w.a = TSeries(2020Q1,randn(10))
w.b = TSeries(2021Q1,randn(10))
w.c = 1
w.d = "string"
w1 = reindex(w, 2021Q1 => 1U)
w2 = reindex(w, 2021Q1 => 1U; copy = true)
w.a[2020Q1] = 9999
MVTSeries(; w1_a = w1.a, w2_a = w2.a)

reindex(2022Q4, 2022Q1 => 1U) === 4U
```
With a `UnitRange`
```
reindex(2021Q1:2022Q4, 2022Q1 => 1U)
```
"""
function reindex end
export reindex

function reindex(T::MIT{F}, pair::Pair{<:MIT{F},<:MIT}; copy=false) where {F<:Frequency}
    return pair[2] + Int(T - pair[1])
end

function reindex(rng::UnitRange{<:MIT}, pair::Pair{<:MIT,<:MIT}; copy=false)
    T = pair[2] + Int(rng[1] - pair[1])
    return T:T+length(rng)-1
end

function reindex(ts::TSeries, pair::Pair{<:MIT,<:MIT}; copy=false)
    ts_lag = firstdate(ts) - pair[1]
    return TSeries(pair[2] + Int(ts_lag), copy ? Base.copy(ts.values) : ts.values)
end

function reindex(ts::MVTSeries, pair::Pair{<:MIT,<:MIT}; copy=false)
    ts_lag = firstdate(ts) - pair[1]
    return MVTSeries(pair[2] + Int(ts_lag), keys(ts), copy ? Base.copy(ts.values) : ts.values)
end

function reindex(w::Workspace, pair::Pair{<:MIT,<:MIT}; copy=false)
    freq_from = frequencyof(pair[1])
    wo = Workspace()
    for (k, v) in w
        if v isa Workspace
            wo[k] = reindex(w[k], pair; copy)
        elseif hasmethod(reindex, (typeof(v), Pair{<:MIT,<:MIT})) && frequencyof(v) == freq_from
            wo[k] = reindex(v, pair; copy=copy)
        elseif copy && hasmethod(Base.copy, (typeof(v),))
            wo[k] = Base.copy(w[k])
        else
            wo[k] = w[k]
        end
    end
    return wo
end

###########################
_w(a) = a
_w(w::Workspace) = w._c
TOML.print(w::Workspace; sorted::Bool=false, by=identity) = TOML.print(_w, w._c; sorted, by)
TOML.print(io::IO, w::Workspace; sorted::Bool=false, by=identity) = TOML.print(_w, io, w._c; sorted, by)
TOML.print(f::TOML.Internals.Printer.MbyFunc, io::IO, w::Workspace; sorted::Bool=false, by=identity) = TOML.print(f ∘ _w, io, w._c; sorted, by)
TOML.print(f::TOML.Internals.Printer.MbyFunc, w::Workspace; sorted::Bool=false, by=identity) = TOML.print(f ∘ _w, w._c; sorted, by)


## isyearly, isquarterly, isweekly, ismonthly
isyearly(F::Type{<:Frequency}) = F <: Yearly
ishalfyearly(F::Type{<:Frequency}) = F <: HalfYearly
isquarterly(F::Type{<:Frequency}) = F <: Quarterly
ismonthly(F::Type{<:Frequency}) = F <: Monthly
isweekly(F::Type{<:Frequency}) = F <: Weekly
isdaily(F::Type{<:Frequency}) = F <: Daily
isbdaily(F::Type{<:Frequency}) = F <: BDaily
isyearly(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = isyearly(frequencyof(x))
ishalfyearly(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = ishalfyearly(frequencyof(x))
isquarterly(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = isquarterly(frequencyof(x))
ismonthly(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = ismonthly(frequencyof(x))
isweekly(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = isweekly(frequencyof(x))
isdaily(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = isdaily(frequencyof(x))
isbdaily(x::Union{Duration{F},TSeries{F},MVTSeries{F},MIT{F},UnitRange{MIT{F}}}) where {F<:Frequency} = isbdaily(frequencyof(x))
export isyearly, isquarterly, ismonthly, isweekly, ishalfyearly, isweekly, isdaily, isbdaily


"""
    clean_old_frequencies(m::MIT)
    clean_old_frequencies(ts::TSeries)
    clean_old_frequencies(mvts::MVTSeries)
    clean_old_frequencies(ws::Workspace)
    clean_old_frequencies!(ws::Workspace)

The internal representation for Quarterly and Yearly frequencies has changed
between v0.4 and v0.5 of the TimeSeriesEcon package. Some stored data from old
frequencies may need to be processed after loading to convert the objects to ones
using the new frequencies.

Example:
    using JLD2
    ws = Workspace(load("stored_workspace.jld2"))
    TimeSeriesEcon.clean_old_frequencies!(ws)
"""
clean_old_frequencies(x) = x
function clean_old_frequencies(m::MIT)
    sanitized_frequency = sanitize_frequency(frequencyof(m))
    if sanitized_frequency !== frequencyof(m)
        return MIT{sanitized_frequency}(Int(m))
    end
    return m
end
function clean_old_frequencies(ts::TSeries)
    new_firstdate = clean_old_frequencies(ts.firstdate)
    if frequencyof(new_firstdate) !== frequencyof(ts.firstdate)
        new_lastdate = new_firstdate + length(rangeof(ts)) - 1
        return copyto!(TSeries(eltype(values(ts)), new_firstdate:new_lastdate), values(ts))
    end
    return ts
end
function clean_old_frequencies(mvts::MVTSeries)
    if sanitize_frequency(frequencyof(mvts)) !== frequencyof(mvts)
        new_pairs = Vector{Pair{Symbol,TSeries}}()
        for (key, val) in pairs(mvts)
            push!(new_pairs, key => clean_old_frequencies(val))
        end
        return MVTSeries(; new_pairs...)
    end
    return mvts
end
function clean_old_frequencies(ws::Workspace)
    new_ws = Workspace()
    for (key, val) in ws
        new_ws[key] = clean_old_frequencies(val)
    end
    return new_ws
end
function clean_old_frequencies!(ws::Workspace)
    for (key, val) in ws
        if val isa Workspace
            TimeSeriesEcon.clean_old_frequencies!(val)
        else
            ws[key] = TimeSeriesEcon.clean_old_frequencies(val)
        end
    end
end

"""
    clean_old_frequencies!

Like [`clean_old_frequencies`](@ref), but in place. 
"""
clean_old_frequencies!

export clean_old_frequencies
export clean_old_frequencies!
