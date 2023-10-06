


function x13write(outfile::String, spec::X13spec; test=false)
    s = x13write(spec; test)
    # println(join(s, "\n"))
end

function x13write(spec::X13spec; test=false)
    s = Vector{String}()

    # print series or composite first, currently we only support series
    push!(s, x13write(getfield(spec, :series); test))

    for key in fieldnames(typeof(spec))
        if key ∈ (:series,)
            continue
        end
        val = getfield(spec,key)
        if !(val isa X13default)
            push!(s, x13write(val; test))
        end
    end
    return join(s, "\n")
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

function x13write(spec::Union{X13arima,X13automdl,X13check,X13estimate,X13force,X13forecast,X13history,X13identify,X13outlier,X13pickmdl,X13regression,X13seats,X13slidingspans,X13spectrum,X13transform,X13x11,X13x11regression}, ; test=false)
    s = Vector{String}()
    spectype = typeof(spec)
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
            elseif key ∈ (:ma, )
                push!(s, "$key = $(x12write_fixed_values(spec, key, val))")
                continue
            end

            push!(s, "$key = $(x13write(val))")
        end
    end
    if length(s) > 0
        return "$(_spec_name_dict[spectype]) {\n\t$(join(s,"\n\t"))\n}"
    else
        return "$(_spec_name_dict[spectype]) { }"
    end
end

function x13write(spec::X13series; test=false)
    s = Vector{String}()
    for key in fieldnames(typeof(spec))
        if test && key ∈ (:print,:save,:savelog)
            continue
        end
        val = getfield(spec,key)
        if !(val isa X13default)
            push!(s, "$key = $(x13write(val))")
        elseif key == :start
            push!(s, "$key = $(x13write(first(rangeof(spec.data))))")
        end
    end
    return "series {\n\t$(join(s,"\n\t"))\n}"
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
x13write(val::Bool) = val ? "yes" : "no"

x13write(val::ArimaModel) = x13write(val.specs)
x13write(val::ArimaSpec) = val.period != 0 ? "($(val.p) $(val.d) $(val.q))$(val.period)" : "($(val.p) $(val.d) $(val.q))"
x13write(val::Vector{ArimaSpec}) = join(x13write.(val), "")
x13write(val::TSeries) = "($(join(values(val), " ")))"
x13write(val::Number) = val
x13write(val::Symbol) = val
x13write(val::Missing) = ""
x13write(val::Vector{Union{Int64,Missing}}) = "($(join(x13write.(val), ", ")))"
x13write(val::Vector{<:Any}) = "($(join(x13write.(val), ", ")))"
x13write(val::Vector{<:Union{Symbol,X13var}}) = "($(join(x13write.(val), " ")))"
x13write(val::X13.ao) = "ao$(x13write(val.mit))"
x13write(val::X13.ls) = "ls$(x13write(val.mit))"
x13write(val::X13.tc) = "tc$(x13write(val.mit))"
x13write(val::X13.so) = "so$(x13write(val.mit))"
x13write(val::X13.aos) = "aos$(x13write(val.mit1))-$(x13write(val.mi2))"
x13write(val::X13.lss) = "lss$(x13write(val.mit1))-$(x13write(val.mi2))"
x13write(val::X13.rp) = "rp$(x13write(val.mit1))-$(x13write(val.mi2))"
x13write(val::X13.qd) = "qd$(x13write(val.mit1))-$(x13write(val.mi2))"
x13write(val::X13.qi) = "qi$(x13write(val.mit1))-$(x13write(val.mi2))"
x13write(val::X13.tl) = "tl$(x13write(val.mit1))-$(x13write(val.mi2))"
x13write(val::tdstock) = "tdstock[$(val.n)]"
x13write(val::tdstock1coef) = "tdstock1coef[$(val.n)]"
x13write(val::easter) = "easter[$(val.n)]"
x13write(val::labour) = "labour[$(val.n)]"
x13write(val::thank) = "thank[$(val.n)]"
x13write(val::sceaster) = "sceaster[$(val.n)]"
x13write(val::easterstock) = "easterstock[$(val.n)]"
x13write(val::sincos) = "sincos[$(join(val.n, " "))]"



function x13write(val::MIT)
    y,p = mit2yp(val)
    return "$y.$p"
end
_months = ["jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"]
function x13write(val::MIT{Monthly})
    y,p = mit2yp(val)
    return "$y.$(_months[p])"
end
x13write(val::UnitRange{<:MIT}) = "($(x13write(first(val))), $(x13write(last(val))))"
x13write(val::MIT{<:Yearly}) = year(val)