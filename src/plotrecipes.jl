# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.


using RecipesBase

#
# We add an argument `range`. if not given, the full range of the series will be
# plotted. It is useful when plotting multiple series with different stored ranges.
#
# We add an argument `mit_loc` specifying the x-coordinate where the point will
# be located within the period
#    For example
#                           /  2020.0    with mit_loc=:left
#                2020Q1 --> |  2020.125  with mit_loc=:middle
#                           \  2020.25   with mit_loc=:right
#

mit_offset(::Val{:left}, ::Type{<:Frequency}) = 0.0
mit_offset(::Val{:middle}, ::Type{<:Frequency}) = 0.5
mit_offset(::Val{:middle}, ::Type{<:YPFrequency{N}}) where {N} = 0.5 / N
mit_offset(::Val{:right}, ::Type{<:Frequency}) = 1.0
mit_offset(::Val{:right}, ::Type{<:YPFrequency{N}}) where {N} = 1.0 / N

function mit_formatter(V::Val, F::Type{<:YPFrequency{N}}) where {N}
    offset = mit_offset(V, F)
    warned = false
    return function (x)
        yr = floor(Int, x - offset)
        per = 1 + floor(Int, N * (x - yr - offset))
        xmit = MIT{F}(yr, per)
        if (N * abs(x - xmit) > 0.1) 
            # x is more than one tenth of a period away from xmit
            warned || @warn "xticks marked with (+) are not aligned with $(nameof(F)) MITs."
            warned = true
            return string(xmit) * "⁺"
        end
        string(xmit)
    end
end

# This "series"-type recipe is for plotting a single TSeries. 
# It is activated when plot(..., seriestype=:tseries, ...)
# We recognize the mit_loc kw-argument - sets the x-location of the point within the period interval. One of :left, :middle, or :right
@recipe function one_tseries(::Type{Val{:tseries}}, x, y, z)
    @assert y isa TSeries
    @assert z isa Nothing
    @assert frequencyof(x) == frequencyof(y)
    mit_loc = get(plotattributes, :mit_loc, :left)
    rng = get(plotattributes, :trange, x)
    rng = intersect(rng, rangeof(y))
    y := values(y[rng])
    x := float.(rng) .+ mit_offset(Val(mit_loc), frequencyof(rng))
    if frequencyof(x) <: YPFrequency
        xformatter --> mit_formatter(Val(mit_loc), frequencyof(rng))
    elseif frequencyof(x) <: Union{BDaily,Daily,<:Weekly}
        x := [Date(MIT{frequencyof(x)}(Int64(i))) for i in rng]
    end
    # xt, xl, xh = Plots.optimize_ticks(first(x), last(x); k_min=4, k_max=8)
    # xticks := xt
    # xlim := (xl, xh)
    # restore the original seriestype
    st = plotattributes[:_org_st]
    seriestype := st
end

# This "user"-type recipe is for plotting multiple TSeries.
# It calls the one_tseries recipe in a loop
@recipe function many_tseries(ts::TSeries...)
    # populate x with the range and y with t itself.
    # divert to seriestype=:tseries (done in one_tseries() above), but
    # keep track of the original seriestype, so we can restore it
    _org_st = get(plotattributes, :seriestype, :path)
    for t = ts
        @series begin
            seriestype := :tseries
            _org_st := _org_st
            (rangeof(t), t)
        end
    end
end

# This "user"-type recipe is for plotting multiple MVTSeries datasets.
# It calls the one_tseries recipe in a loop
@recipe function many_mvtseries(datasets::MVTSeries...)
    # trange 
    # trng = get(plotattributes, :trange, nothing)
    # label applies to the datasets 
    lbls = get(plotattributes, :label, nothing)
    if lbls === nothing
        lbls = ["data$i" for i = 1:length(datasets)]
    elseif lbls isa AbstractString
        lbls = [lbls]
    end
    if length(lbls) != length(datasets)
        error(ArgumentError("Number of labels and data don't match"))
    end
    # vars is a selection of variables to plot from each dataset
    vars = get(plotattributes, :vars, nothing)
    if vars === nothing
        vars = mapreduce(colnames, union, datasets)
    end
    nvars = length(vars)
    if nvars > 10
        error("Too many variables. Try splitting into pages.")
    end

    # default layout - one subplot for each variable
    layout --> nvars

    # common attributes for all subplots
    titlefont --> ("computer modern", 11)

    for (ind, var) in enumerate(vars)
        # subplot attributes
        subplot := ind

        if var isa Pair{Symbol,<:AbstractString}
            vname = var[1]
            title := var[2]
        else
            vname = Symbol(var)
            title := string(vname)
        end

        # create a series for variable vname for each dataset
        for (jnd, data) in enumerate(datasets)
            # series specific properties
            label := lbls[jnd]
            if hasproperty(data, vname)
                series = getproperty(data, vname)
                @series begin
                    # the series itself (done by one_tseries() above)
                    series
                end
            else
                # variable missing from dataset
                @series begin
                    # empty :path series
                    seriestype := :path
                    (Float64[], Float64[])
                end
            end
        end
    end
end

