"""
This file contains functions for writing a X13spec object into a String 
    in the format expected by X13-ARIMA-Seats.
"""

function impose_line_length!(s::Vector{<:AbstractString}, limit=133-8, delve=true) #132
    #TODO: how do you count tabs
    counter = 1
    while counter <= length(s)
        line = s[counter]
        # check data lines
        if delve && occursin("\n", line)
            sub_lines = split(line,"\n")
            impose_line_length!(sub_lines, limit, false)
            s[counter] = join(sub_lines, "\n")
            counter += 1
            continue
        end
        if length(line) > limit
            splitchar = " "
            if occursin(" + ", line)
                splitchar = " + "
            end
            splitstring = split(line,splitchar)
            best_split_index = 2
            cum_length = 0
            for (i, _s) in enumerate(splitstring)
                cum_length = cum_length + length(_s) + length(splitchar)
                if cum_length > limit
                    best_split_index = i - 1
                    break
                end
            end
            s1 = "$(join(splitstring[1:best_split_index], splitchar))$(splitchar)"
            s2 = "        $(join(splitstring[best_split_index+1:end], splitchar))"
            s[counter] = s1
            insert!(s,counter+1,s2)
        end
        counter += 1
    end
end

function x13write(spec::X13spec; test=false, outfolder::Union{String,X13default}=spec.folder)
    if !test && outfolder isa X13default
        spec.folder = mktempdir(; prefix="x13_", cleanup=true) # will be deleted when process exits
        outfolder = spec.folder
    end
    
    s = Vector{String}()

    # check spec consistency
    validateX13spec(spec)

    # print series or composite first, currently we only support series
    push!(s, x13write(getfield(spec, :series); test, outfolder))
    for key in fieldnames(typeof(spec))
        if key ∈ (:series,:folder,:string)
            continue
        end
        val = getfield(spec,key)
        if !(val isa X13default)
            push!(s, x13write(val; test, outfolder))
        end
    end
    spec.string = join(s, "\n")
    
    if test
        return spec.string
    end
    open(joinpath(spec.folder, "spec.spc"), "w") do f
        println(f, spec.string)
    end
end

_spec_name_dict = Dict{Type,String}(
    X13arima => "arima",
    X13automdl => "automdl",
    X13check => "check",
    X13estimate => "estimate",
    X13force => "force",
    X13forecast => "forecast",
    X13history => "history",
    X13identify => "identify",
    X13outlier => "outlier",
    X13pickmdl => "pickmdl",
    X13regression => "regression",
    X13seats => "seats",
    X13series => "series",
    X13slidingspans => "slidingspans",
    X13spectrum => "spectrum",
    X13transform => "transform",
    X13x11 => "x11",
    X13x11regression => "x11regression"
)
_regime_change_dict_start = Dict{Symbol, String}(
    :both => "/",
    :zerobefore => "//",
    :zeroafter => "/",
)
_regime_change_dict_end = Dict{Symbol, String}(
    :both => "/",
    :zerobefore => "/",
    :zeroafter => "//",
)

_per_quarterly_strings_dict = Dict{UnionAll, String}(
    Q1 =>  "q1",
    Q2 =>  "q2",
    Q3 =>  "q3",
    Q4 =>  "q4" #TODO: check if these work.
)

function x13write(spec::Union{X13arima,X13automdl,X13check,X13estimate,X13force,X13forecast,X13history,X13identify,X13outlier,X13pickmdl,X13regression,X13seats,X13slidingspans,X13spectrum,X13transform,X13x11,X13x11regression}; test=false, outfolder::Union{String,X13default}=X13default())
    s = Vector{String}()
    spectype = typeof(spec)
    keys_at_end = Vector{Symbol}()
    for key in fieldnames(spectype)
        if test && key ∈ (:print,:save,:savelog)
            continue
        end
        if key ∈ (:fixar, :fixma, :fixb)
            continue
        end
        val = getfield(spec,key)
        if !(val isa X13default)
            if key == :func
                key = :function
            elseif key ∈ (:printphtrf, :tabtables,)
                push!(s, "$key = $(x13write_alt(val))")
                continue
            elseif key ∈ (:print,)
                push!(s, "$key = $(x13write_plus(val))")
                continue
            elseif spec isa X13pickmdl && key ∈ (:models,)
                if !(outfolder isa X13default) && length(outfolder) > 0
                    mdl_string = x13write(val)*"\n"
                    open(joinpath(outfolder, "pickmdl.mdl"), "w") do f
                        print(f, mdl_string);
                    end
                    push!(s, "file = \"$(joinpath(outfolder, "pickmdl.mdl"))\"")
                else
                    push!(s, "$key = $(x13write(val))")
                end
                continue
            elseif key ∈ (:ma, :ar, :b, :aictest)
                # Write these at the end of the spec file
                push!(keys_at_end, key)
                continue
            end

            push!(s, "$key = $(x13write(val))")
        end
    end
    for key in keys_at_end
        val = getfield(spec,key)
        if key ∈ (:ma, :ar, :b)
            push!(s, "$key = $(x12write_fixed_values(spec, key, val))")
            continue
        end
        push!(s, "$key = $(x13write(val))")
    end
    impose_line_length!(s)
    if length(s) > 0
        return "$(_spec_name_dict[spectype]) {\n        $(join(s,"\n        "))\n}"
    else
        return "$(_spec_name_dict[spectype]) { }"
    end
end

function x13write(spec::X13series; test=false, outfolder::Union{String,X13default}=X13default())
    s = Vector{String}()
    for key in fieldnames(typeof(spec))
        if test && key ∈ (:print,:save,:savelog)
            continue
        end
        val = getfield(spec,key)
        if !(val isa X13default)
            if key ∈ (:print,)
                push!(s, "$key = $(x13write_plus(val))")
                continue
            end
            push!(s, "$key = $(x13write(val))")
        end
    end
    impose_line_length!(s)
    return "series {\n        $(join(s,"\n        "))\n}"
end

function x13write(spec::X13metadata; test=false, outfolder::Union{String,X13default}=X13default())
    s = Vector{String}()
    keys_vector = [p[1] for p in spec.entries]
    values_vector = [p[2] for p in spec.entries]
    if length(keys_vector) == 1
        push!(s, "key = $(x13write(keys_vector[1]))")
        push!(s, "value = $(x13write(values_vector[1]))")
    else
        push!(s, "key = (")
        for key in keys_vector
            push!(s, "        \"$key\"")
        end
        push!(s, ")")
        push!(s, "value = (")
        for val in values_vector
            push!(s, "        \"$val\"")
        end
        push!(s, ")")

    end
    impose_line_length!(s)
    return "metadata {\n        $(join(s,"\n        "))\n}"
end

_fixed_val_dict = Dict{Bool,String}(
    true => "f",
    false => ""
)
function x12write_fixed_values(spec, key, val)
    fixedval = getfield(spec, Symbol("fix$(key)"))
    if fixedval isa X13default
        return x13write(val)
    else
        vals = ["$(x13write(v))$(_fixed_val_dict[f])" for (v,f) in zip(val, fixedval)]
        return "($(join(vals,",")))"
    end
end


x13write(val::String) = "\"$val\""
x13write(val::Vector{Symbol}) = "($(join(val, " ")))"
x13write_alt(val::Vector{Symbol}) = "\"$(join(val, ","))\""
x13write_plus(val::Vector{Symbol}) = "($(join(val, " + ")))"
x13write(val::Bool) = val ? "yes" : "no"
x13write_alt(val::Bool) = val ? 1 : 0

x13write(val::ArimaModel) = x13write(val.specs)
x13write(val::ArimaSpec) = val.period != 0 ? "($(val.p) $(val.d) $(val.q))$(val.period)" : "($(val.p) $(val.d) $(val.q))"
x13write(val::Vector{ArimaSpec}) = join(x13write.(val), "")
function x13write(val::Vector{ArimaModel})
    s = Vector{String}()
    for m in val[1:end-1]
        ending = m.default ? " *" : " X"
        push!(s, "$(x13write(m))$ending")
    end
    push!(s, x13write(val[end]))
    return join(s, "\n")
end
x13write(val::TSeries) = "($(join(values(val), " ")))"
function x13write(val::MVTSeries) 
    cols = columns(val)
    colnames = collect(keys(cols))
    if length(cols) == 1
        return x13write(cols[first(keys(cols))])
    else
        # loop though all columns for time period 1, then for time period 2, etc.
        vals = Vector{String}()
        for t in rangeof(val)
            push!(vals, join(val[t], "        "))
        end
        return "(        $(join(vals, "\n        "))        )"
    end
end
x13write(val::Number) = val
x13write(val::Symbol) = val
x13write(val::Missing) = ""
x13write(val::Vector{Union{Int64,Missing}}) = "($(join(x13write.(val), ", ")))"
x13write(val::Vector{<:Any}) = "($(join(x13write.(val), ", ")))"
x13write(val::Vector{String}) = "($(join(x13write.(val), "\n        ")))"
x13write(val::Vector{<:Union{Symbol,X13var}}) = "($(join(x13write.(val), " ")))"
x13write(val::X13.ao) = "ao$(x13write(val.mit))"
x13write(val::X13.ls) = "ls$(x13write(val.mit))"
x13write(val::X13.tc) = "tc$(x13write(val.mit))"
x13write(val::X13.so) = "so$(x13write(val.mit))"
x13write(val::X13.aos) = "aos$(x13write(val.mit1))-$(x13write(val.mit2))"
x13write(val::X13.lss) = "lss$(x13write(val.mit1))-$(x13write(val.mit2))"
x13write(val::X13.rp) = "rp$(x13write(val.mit1))-$(x13write(val.mit2))"
x13write(val::X13.qd) = "qd$(x13write(val.mit1))-$(x13write(val.mit2))"
x13write(val::X13.qi) = "qi$(x13write(val.mit1))-$(x13write(val.mit2))"
x13write(val::X13.tl) = "tl$(x13write(val.mit1))-$(x13write(val.mit2))"
x13write(val::tdstock) = "tdstock[$(val.n)]"
x13write(val::tdstock1coef) = "tdstock1coef[$(val.n)]"
x13write(val::easter) = "easter[$(val.n)]"
x13write(val::labor) = "labor[$(val.n)]"
x13write(val::thank) = "thank[$(val.n)]"
x13write(val::sceaster) = "sceaster[$(val.n)]"
x13write(val::easterstock) = "easterstock[$(val.n)]"
x13write(val::sincos) = "sincos[$(join(val.n, " "))]"
x13write(val::td)           = val.regimechange == :neither ? "td" : "td$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::tdnolpyear)   = val.regimechange == :neither ? "tdnolpyear" : "tdnolpyear$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::td1coef)      = val.regimechange == :neither ? "td1coef" : "td1coef$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::td1nolpyear)  = val.regimechange == :neither ? "td1nolpyear" : "td1nolpyear$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::lpyear)       = val.regimechange == :neither ? "lpyear" : "lpyear$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::lom)          = val.regimechange == :neither ? "lom" : "lom$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::loq)          = val.regimechange == :neither ? "loq" : "loq$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::seasonal)     = val.regimechange == :neither ? "seasonal" : "seasonal$(_regime_change_dict_start[val.regimechange])$(x13write(val.mit))$(_regime_change_dict_end[val.regimechange])"
x13write(val::Span)         = val.e isa TimeSeriesEcon._FPConst || val.e isa UnionAll ? "($(x13write(val.b)), 0.$(x13write(val.e)))" : "($(x13write(val.b)), $(x13write(val.e)))"
x13write(val::UnionAll) = _quarterly_strings_dict[val]
x13write(val::TimeSeriesEcon._FPConst{Monthly, N}) where N = _ordered_month_names[N]


function x13write(val::MIT)
    y,p = mit2yp(val)
    return "$y.$p"
end
function x13write(val::MIT{Monthly})
    y,p = mit2yp(val)
    return "$y.$(_ordered_month_names[p])"
end
x13write(val::UnitRange{<:MIT}) = "($(x13write(first(val))), $(x13write(last(val))))"
x13write(val::MIT{<:Yearly}) = year(val)