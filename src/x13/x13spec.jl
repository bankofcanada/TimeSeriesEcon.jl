# https://www2.census.gov/software/x-13arima-seats/x-13-data/documentation/docx13as.pdf
# pg 175



struct X13default end
_X13default = X13default()

abstract type X13var end

struct ao <: X13var
    mit::MIT
end
struct aos <: X13var
    mit1::MIT
    mit2::MIT
end
struct ls <: X13var
    mit::MIT
end
struct lss <: X13var
    mit1::MIT
    mit2::MIT
end

struct tc <: X13var
    mit::MIT
end

struct so <: X13var
    mit::MIT
end

struct rp <: X13var
    mit1::MIT
    mit2::MIT
end

struct qd <: X13var
    mit1::MIT
    mit2::MIT
end
struct qi <: X13var
    mit1::MIT
    mit2::MIT
end

struct tl <: X13var
    mit1::MIT
    mit2::MIT
end

struct tdstock <: X13var
    n::Int64
end
struct tdstock1coef <: X13var
    n::Int64
end
struct easter <: X13var
    n::Int64
end
struct labor <: X13var
    n::Int64
end
struct thank <: X13var
    n::Int64
end

struct sceaster <: X13var
    n::Int64
end
struct easterstock <: X13var
    n::Int64
end
struct sincos <: X13var
    n::Vector{Int64}
end

struct td <: X13var
    mit::MIT
    regimechange::Symbol

    td(mit::MIT, rc::Symbol) = new(mit, rc)
    td(mit::MIT) = new(mit, :both)
    td() = new(1M1, :neither)
end
struct tdnolpyear <: X13var
    mit::MIT
    regimechange::Symbol

    tdnolpyear(mit::MIT, rc::Symbol) = new(mit, rc)
    tdnolpyear(mit::MIT) = new(mit, :both)
    tdnolpyear() = new(1M1, :neither)
end
struct td1coef <: X13var
    mit::MIT
    regimechange::Symbol

    td1coef(mit::MIT, rc::Symbol) = new(mit, rc)
    td1coef(mit::MIT) = new(mit, :both)
    td1coef() = new(1M1, :neither)
end
struct td1nolpyear <: X13var
    mit::MIT
    regimechange::Symbol

    td1nolpyear(mit::MIT, rc::Symbol) = new(mit, rc)
    td1nolpyear(mit::MIT) = new(mit, :both)
    td1nolpyear() = new(1M1, :neither)
end

struct lpyear <: X13var
    mit::MIT
    regimechange::Symbol

    lpyear(mit::MIT, rc::Symbol) = new(mit, rc)
    lpyear(mit::MIT) = new(mit, :both)
    lpyear() = new(1M1, :neither)
end
struct lom <: X13var
    mit::MIT
    regimechange::Symbol

    lom(mit::MIT, rc::Symbol) = new(mit, rc)
    lom(mit::MIT) = new(mit, :both)
    lom() = new(1M1, :neither)
end

struct loq <: X13var
    mit::MIT
    regimechange::Symbol

    loq(mit::MIT, rc::Symbol) = new(mit, rc)
    loq(mit::MIT) = new(mit, :both)
    loq() = new(1M1, :neither)
end
struct seasonal <: X13var
    mit::MIT
    regimechange::Symbol

    seasonal(mit::MIT, rc::Symbol) = new(mit, rc)
    seasonal(mit::MIT) = new(mit, :both)
    seasonal() = new(1M1, :neither)
end

struct Span
    b::Union{MIT, Missing}
    e::Union{MIT,Missing,TimeSeriesEcon._FPConst,UnionAll}

    Span(x::UnitRange{<:MIT}) = new(first(x), last(x))
    Span(b,e) = new(b,e)
    Span(b) = new(b,missing)
    Span(b::Nothing, e) = new(missing,e)
end



struct X13series{F<:Frequency}
    appendbcst::Union{Bool,X13default}
    appendfcst::Union{Bool,X13default}
    comptype::Union{Symbol,X13default}
    compwt::Union{Float64,X13default}
    data::TSeries{F}
    decimals::Union{Int64,X13default}
    file::Union{String,X13default}
    format::Union{String,X13default}
    modelspan::Union{UnitRange{MIT{F}},Span, X13default}
    name::Union{String,X13default}
    period::Union{Int64,X13default}
    precision::Union{Int64,X13default}
    print::Union{Symbol,Vector{Symbol},X13default} #This should just be everything
    save::Union{Symbol,Vector{Symbol},X13default}
    span::Union{UnitRange{MIT{F}},Span,X13default}
    start::Union{MIT{F},X13default}
    title::Union{String,X13default}
    type::Union{Symbol, X13default}
    divpower::Union{Int64,X13default}
    missingcode::Union{Float64,X13default}
    missingval::Union{Float64,X13default}
    saveprecision::Union{Int64,X13default}
    trimzero::Union{Bool,Symbol,X13default}
end


"""
ArimaSpec

A structure holding the autoregressive order (`p`), the number of differences (`d`), the moving
average order (`q`), and the period for an autoregressive model specification.

Operators with missing lags are specified by providing a vector of Integers for the argument.  
For example `ArimaSpec([2,3],0,0)` specifies the model (1-Φ_2*B^2 - Φ_3*B^3)*z_t = a_t.

The default period length is 0, in which case the ordering of the ArimaSpec instances will be used
to infer the correct period lengths. 

Initializing the structure with six arguments will return a tuple of two ArimaSpec structures.
"""
mutable struct ArimaSpec
    p::Union{Int64,Vector{Int64},X13default} # nonseasonal AR order
    d::Union{Int64,Vector{Int64},X13default} # number of nonseasonal differences
    q::Union{Int64,Vector{Int64},X13default} # nonseasonal MA order
    period::Union{Int64,X13default}

    ArimaSpec() = new(0,0,0,0)
    ArimaSpec(p::Union{Int64,Vector{Int64}}) = new(p,0,0,0) # could write these in one line iwth dfaults
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}}) = new(p,d,0,0)
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}}, q::Union{Int64,Vector{Int64}}) = new(p,d,q,0)
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}}, q::Union{Int64,Vector{Int64}}, period::Int64) = new(p,d,q,period)
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}},q::Union{Int64,Vector{Int64}},P::Union{Int64,Vector{Int64}},D::Union{Int64,Vector{Int64}},Q::Union{Int64,Vector{Int64}}) = (new(p,d,q,0), new(P,D,Q,0))
end

export ArimaSpec

struct ArimaModel
    specs::Vector{ArimaSpec}
    default::Bool

    ArimaModel(p::Union{Int64,Vector{Int64}},d::Union{Int64,Vector{Int64}},q::Union{Int64,Vector{Int64}}; default=false) = new([ArimaSpec(p,d,q)], default)
    ArimaModel(p::Union{Int64,Vector{Int64}},d::Union{Int64,Vector{Int64}},q::Union{Int64,Vector{Int64}},period::Int64; default=false) = new([ArimaSpec(p,d,q,period)], default)
    ArimaModel(p::Union{Int64,Vector{Int64}},d::Union{Int64,Vector{Int64}},q::Union{Int64,Vector{Int64}},P::Union{Int64,Vector{Int64}},D::Union{Int64,Vector{Int64}},Q::Union{Int64,Vector{Int64}}; default=false) = new([ArimaSpec(p,d,q),ArimaSpec(P,D,Q)], default)
    ArimaModel(spec::ArimaSpec; default=false) = new([spec], default)
    ArimaModel(specs::ArimaSpec...; default=false) = new([specs...], default)
    ArimaModel(specs::Vector{ArimaSpec}; default=false) = new(specs, default)
end
export ArimaModel

mutable struct X13arima
    model::ArimaModel
    title::Union{String,X13default}
    ar::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default} #default values are 0.1, must be length of AR component
    ma::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default} #default values are 0.1, must be length of MA component
    fixar::Union{Vector{Bool},X13default} 
    fixma::Union{Vector{Bool},X13default} 
end

mutable struct X13automdl
    diff::Union{Vector{Int64},X13default}
    acceptdefault::Union{Bool,X13default}
    checkmu::Union{Bool,X13default}
    ljungboxlimit::Union{Float64,X13default}
    maxorder::Union{Vector{Union{Int64,Missing}},X13default}
    maxdiff::Union{Vector{Union{Int64,Missing}},X13default}
    mixed::Union{Bool,X13default}
    print::Union{Symbol,Vector{Symbol},X13default} #This should just be everything
    savelog::Union{Symbol,Vector{Symbol},X13default}
    armalimit::Union{Float64,X13default}
    balanced::Union{Bool,X13default}
    exactdiff::Union{Bool,Symbol,X13default} #:yes, :no, :first
    fcstlim::Union{Int64,X13default}
    hrinitial::Union{Bool,X13default}
    reducecv::Union{Float64,X13default}
    rejectfcst::Union{Bool,X13default}
    urfinal::Union{Float64,X13default}
end

mutable struct X13check
    maxlag::Union{Int64,X13default}
    qtype::Union{Symbol,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default}
    savelog::Union{Symbol,Vector{Symbol},X13default}
    acflimit::Union{Float64,X13default}
    qlimit::Union{Float64,X13default}
end

mutable struct X13estimate
    exact::Union{Symbol,X13default}
    maxiter::Union{Int64,X13default}
    outofsample::Union{Bool,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default}
    savelog::Union{Symbol,Vector{Symbol},X13default}
    tol::Union{Float64,X13default}
    file::Union{String,X13default}
    fix::Union{Symbol,X13default}
end

mutable struct X13force
    lambda::Union{Float64,X13default}
    mode::Union{Symbol,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default}
    rho::Union{Float64,X13default}
    round::Union{Bool,X13default}
    start::Union{Symbol, TimeSeriesEcon._FPConst, UnionAll, X13default} #q3
    target::Union{Symbol,X13default}
    type::Union{Symbol,X13default}
    usefcst::Union{Bool,X13default}
    indforce::Union{Bool,X13default}
end

mutable struct X13forecast
    exclude::Union{Int64,X13default}
    lognormal::Union{Bool,X13default}
    maxback::Union{Int64,X13default}
    maxlead::Union{Int64,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default}
    probability::Union{Float64,X13default}
end


mutable struct X13history
    endtable::Union{MIT,X13default}
    estimates::Union{Symbol,Vector{Symbol},X13default}
    fixmdl::Union{Bool,X13default}
    fixreg::Union{Bool,X13default}
    fstep::Union{Int64,Vector{Int64},X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    sadjlags::Union{Int64,Vector{Int64},X13default}
    start::Union{MIT,X13default}
    target::Union{Symbol,X13default}
    trendlags::Union{Int64,Vector{Int64},X13default}
    fixx11reg::Union{Bool,X13default}
    outlier::Union{Symbol,X13default}
    outlierwin::Union{Int64,X13default}
    refresh::Union{Bool,X13default}
    transformfcst::Union{Bool,X13default}
    x11outlier::Union{Bool,X13default}
end

mutable struct X13identify
    diff::Union{Vector{Int64},X13default}
    sdiff::Union{Vector{Int64},X13default}
    maxlag::Union{Int64,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
end

mutable struct X13metadata
    entries::Union{Pair{String,String},Vector{Pair{String,String}}}
end

mutable struct X13outlier
    critical::Union{Float64,Vector{Union{Missing,Float64}},Vector{Float64},X13default}
    lsrun::Union{Int64,X13default}
    method::Union{Symbol,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    span::Union{UnitRange{<:MIT},Span,X13default}
    types::Union{Symbol,Vector{Symbol},X13default}
    almost::Union{Float64,X13default}
    tcrate::Union{Float64,X13default}
end

mutable struct X13pickmdl
    bcstlim::Union{Int64,X13default}
    fcstlim::Union{Int64,X13default}
    models::Union{Vector{ArimaModel}, X13default}
    identify::Union{Symbol,X13default}
    method::Union{Symbol,X13default}
    mode::Union{Symbol,X13default}
    outofsample::Union{Bool,X13default}
    overdiff::Union{Float64,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    savelog::Union{Symbol,Vector{Symbol},X13default}
    qlim::Union{Int64,X13default}
    file::Union{String,X13default}
end


mutable struct X13regression
    aicdiff::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default}
    aictest::Union{Symbol,Vector{Symbol},X13default}
    chi2test::Union{Bool,X13default}
    chi2testcv::Union{Float64,X13default}
    data::Union{TSeries,MVTSeries, X13default}
    file::Union{String,X13default}
    format::Union{String,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    pvaictest::Union{Float64,X13default}
    start::Union{MIT,X13default}
    testalleaster::Union{Bool,X13default}
    tlimit::Union{Float64,X13default}
    user::Union{Symbol,Vector{Symbol},X13default}
    usertype::Union{Symbol,Vector{Symbol},X13default}
    variables::Union{Symbol,X13var,Vector{Union{Symbol,X13var}},X13default}
    b::Union{Vector{Float64},X13default}
    fixb::Union{Vector{Bool},X13default}
    centeruser::Union{Symbol,X13default}
    eastermeans::Union{Bool,X13default}
    noapply::Union{Symbol,X13default}
    tcrate::Union{Float64,X13default}
end

mutable struct X13seats
    appendfcst::Union{Bool,X13default}
    finite::Union{Bool,X13default}
    hpcycle::Union{Bool,X13default}
    noadmiss::Union{Bool,X13default}
    out::Union{Int64,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    printphtrf::Union{Bool,X13default}
    qmax::Union{Int64,X13default}
    statseas::Union{Bool,X13default}
    tabtables::Union{Vector{Symbol},X13default}
    bias::Union{Int64,X13default}
    epsiv::Union{Float64,X13default}
    epsphi::Union{Int64,X13default}
    hplan::Union{Int64,X13default}
    imean::Union{Bool,X13default}
    maxit::Union{Int64,X13default}
    rmod::Union{Float64,X13default}
    xl::Union{Float64,X13default}
end

mutable struct X13slidingspans
    cutchng::Union{Float64,X13default}
    cutseas::Union{Float64,X13default}
    cuttd::Union{Float64,X13default}
    fixmdl::Union{Bool,Symbol,X13default}
    fixreg::Union{Vector{Symbol},X13default}
    length::Union{Int64,X13default}
    numspans::Union{Int64,X13default}
    outlier::Union{Symbol,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    start::Union{MIT,X13default}
    additivesa::Union{Symbol,X13default}
    fixx11reg::Union{Bool,X13default}
    x11outlier::Union{Bool,X13default}
end

mutable struct X13spectrum
    logqs::Union{Bool,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    qcheck::Union{Bool,X13default}
    start::Union{MIT,X13default}
    tukey120::Union{Bool,X13default}
    decibel::Union{Bool,X13default}
    difference::Union{Bool,Symbol,X13default}
    maxar::Union{Int64,X13default}
    peakwidth::Union{Int64,X13default}
    series::Union{Symbol,X13default}
    siglevel::Union{Int64,X13default}
    type::Union{Symbol,X13default}
end

mutable struct X13transform
    adjust::Union{Symbol,X13default}
    aicdiff::Union{Float64,X13default}
    data::Any
    file::Union{String,X13default}
    format::Union{String,X13default}
    func::Union{Symbol,X13default} #TODO should be function
    mode::Union{Symbol,Vector{Symbol},X13default}
    name::Union{Symbol,Vector{Symbol},X13default}
    power::Union{Float64,X13default}
    precision::Union{Int64,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default}     
    start::Union{MIT,Vector{MIT},X13default}
    title::Union{String,X13default}
    type::Union{Symbol,Vector{Symbol},X13default}
    constant::Union{Float64,X13default}
    trimzero::Union{Bool,Symbol,X13default}
end


mutable struct X13x11
    appendbcst::Union{Bool,X13default}
    appendfcst::Union{Bool,X13default}
    final::Union{Symbol,Vector{Symbol},X13default}
    mode::Union{Symbol,X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default}     
    seasonalma::Union{Symbol,Vector{Symbol},X13default}
    sigmalim::Union{Vector{Float64},X13default}
    title::Union{String,Vector{String},X13default}
    trendma::Union{Int64,X13default}
    type::Union{Symbol,X13default}
    calendarsigma::Union{Symbol,X13default}
    centerseasonal::Union{Bool,X13default}
    keepholiday::Union{Bool,X13default}
    print1stpass::Union{Bool,X13default}
    sfshort::Union{Bool,X13default}
    sigmavec::Union{Vector{<:TimeSeriesEcon._FPConst},Vector{UnionAll},X13default}
    trendic::Union{Float64,X13default}
    true7term::Union{Bool,X13default}
end

mutable struct X13x11regression
    aicdiff::Union{Float64,X13default}
    aictest::Union{Symbol,Vector{Symbol},X13default}
    critical::Union{Float64,X13default}
    data::Any
    file::Union{String,X13default}
    format::Union{String,X13default}
    outliermethod::Union{Symbol,X13default}
    outlierspan::Union{UnitRange{<:MIT}, Span, X13default}
    print::Union{Symbol,Vector{Symbol},X13default}
    save::Union{Symbol,Vector{Symbol},X13default} 
    savelog::Union{Symbol,Vector{Symbol},X13default} 
    prior::Union{Bool,X13default}
    sigma::Union{Float64,X13default}
    span::Union{UnitRange{<:MIT}, Span, X13default}
    start::Union{MIT,X13default}
    tdprior::Union{Vector{Float64},X13default}
    user::Union{Symbol,Vector{Symbol},X13default}
    usertype::Union{Symbol,Vector{Symbol},X13default}
    variables::Union{Symbol,X13var,Vector{Union{Symbol,X13var}},X13default}
    almost::Union{Float64,X13default}
    b::Union{Vector{Float64},X13default}
    fixb::Union{Vector{Bool},X13default}
    centeruser::Union{Symbol,X13default}
    eastermeans::Union{Bool,X13default}
    forcecal::Union{Bool,X13default}
    noapply::Union{Vector{Symbol},X13default}
    reweight::Union{Bool,X13default}
    umdata::Any
    umfile::Union{String,X13default}
    umformat::Union{String,X13default}
    umname::Union{String,X13default}
    umprecision::Union{Int64,X13default}
    umstart::Union{MIT,X13default}
    umtrimzero::Union{Symbol,X13default}
end




mutable struct X13spec{F<:Frequency}
    series::Union{X13series{F},X13default}
    arima::Union{X13arima,X13default}
    estimate::Union{X13estimate,X13default}
    transform::Union{X13transform,X13default}
    regression::Union{X13regression,X13default}
    automdl::Union{X13automdl,X13default} #or its own type
    x11::Union{X13x11,X13default}
    x11regression::Union{X13x11regression,X13default}
    check::Union{X13check,X13default}
    forecast::Union{X13forecast,X13default}
    # composite::X13composite # not supported
    force::Union{X13force,X13default}
    pickmdl::Union{X13pickmdl,X13default}
    history::Union{X13history,X13default}
    metadata::Union{X13metadata,X13default}
    identify::Union{X13identify,X13default}
    outlier::Union{X13outlier,X13default}
    seats::Union{X13seats,X13default} # not supported
    slidingspans::Union{X13slidingspans,X13default}
    spectrum::Union{X13spectrum,X13default}
    folder::Union{String,X13default}
    string::Union{String,X13default}

end

function newspec(series::Union{X13series,X13default}; 
    arima::Union{X13arima,X13default} = _X13default,
    estimate::Union{X13estimate,X13default} = _X13default,
    transform::Union{X13transform,X13default} = _X13default,
    regression::Union{X13regression,X13default} = _X13default,
    automdl::Union{X13automdl,X13default} = _X13default,
    x11::Union{X13x11,X13default} = _X13default,
    x11regression::Union{X13x11regression,X13default} = _X13default,
    check::Union{X13check,X13default} = _X13default,
    forecast::Union{X13forecast,X13default} = _X13default,
    # composite::X13composite # not supported
    force::Union{X13force,X13default} = _X13default,
    pickmdl::Union{X13pickmdl,X13default} = _X13default,
    history::Union{X13history,X13default} = _X13default,
    metadata::Union{X13metadata,X13default} = _X13default,
    identify::Union{X13identify,X13default} = _X13default,
    outlier::Union{X13outlier,X13default} = _X13default,
    seats::Union{X13seats,X13default} = _X13default,
    slidingspans::Union{X13slidingspans,X13default} = _X13default,
    spectrum::Union{X13spectrum,X13default} = _X13default,
    folder::Union{String,X13default} = _X13default,
    string::Union{String,X13default} = _X13default
    )
    return X13spec{frequencyof(series.data)}(series, arima, estimate,transform,regression,automdl,x11,x11regression,check,forecast,force,pickmdl,history,metadata,identify,outlier,seats,slidingspans,spectrum,folder,string)
end
function newspec(F::Frequency; 
    series::Union{X13series,X13default} = _X13default,
    arima::Union{X13arima,X13default} = _X13default,
    estimate::Union{X13estimate,X13default} = _X13default,
    transform::Union{X13transform,X13default} = _X13default,
    regression::Union{X13regression,X13default} = _X13default,
    automdl::Union{X13automdl,X13default} = _X13default,
    x11::Union{X13x11,X13default} = _X13default,
    x11regression::Union{X13x11regression,X13default} = _X13default,
    check::Union{X13check,X13default} = _X13default,
    forecast::Union{X13forecast,X13default} = _X13default,
    # composite::X13composite # not supported
    force::Union{X13force,X13default} = _X13default,
    pickmdl::Union{X13pickmdl,X13default} = _X13default,
    history::Union{X13history,X13default} = _X13default,
    metadata::Union{X13metadata,X13default} = _X13default,
    identify::Union{X13identify,X13default} = _X13default,
    outlier::Union{X13outlier,X13default} = _X13default,
    seats::Union{X13seats,X13default} = _X13default,
    slidingspans::Union{X13slidingspans,X13default} = _X13default,
    spectrum::Union{X13spectrum,X13default} = _X13default,
    folder::Union{String,X13default} = _X13default,
    string::Union{String,X13default} = _X13default
    )
    return X13spec{F}(series, arima, estimate,transform,regression,automdl,x11,x11regression,check,forecast,force,pickmdl,history,metadata,identify,outlier,seats,slidingspans,spectrum,folder,string)
end
newspec(ts::TSeries; kwargs...) = newspec(X13.series(ts); kwargs...)




"""
`series(model::ArimaSpec; kwargs...)`

`series!(spec::X13spec{F}, model::ArimaSpec; kwargs...)`

### Main keyword arguments:

* **appendbcst**  (Bool)  - Determines if backcasts will be included in certain tables selected for storage with the
    save option. If `appendbcst=true`, then backcasted values will be stored with tables a16,
    b1, d10, and d16 of the x11 spec, table s10 of the seats spec, tables a6, a7, a8, a8.tc,
    a9, and a10 of the regression spec, and tables c16 and c18 of the x11regression spec.
    If `appendbcst=false`, no backcasts will be stored. The default is `false`.

* **appendfcst** (Bool) - Determines if forecasts will be included in certain tables selected for storage with the save
    option. If `appendfcst=true`, then forecasted values will be stored with tables a16, b1,
    d10, d16, and h1 of the x11 spec, tables a6, a7, a8, a8.tc, a9, and a10 of the regression
    spec, and tables c16 and c18 of the x11regression spec. If `appendfcst=false`, no forecasts
    will be stored. The default is `false`.

* **comptype9** (Symbol) - Indicates how a component series of a composite (also called aggregate) series is incorporated into the composite. 
    These component series can be added into the (partially formed)
    composite series (`comptype=:add`), subtracted from the composite series (`comptype=:sub`),
    multiplied by the composite series (`comptype=:mult`), or divided into the composite series
    (`comptype=:div`). The default is no aggregation (`comptype=:none`).

    Note that the composite series is initialized to zero, and each component is incorporated
    into the composite series sequentially. So when the desired composition is something like
    comp = comp1 × comp2, the comptype argument for the first component should be set
    to comptype=add, so that the composite series is set to 0 + comp1, and the comptype
    argument for the second component should be set to `comptype=:mult`.

* **compwt** (Float64) - Specifies that the series is to be multiplied by a constant before aggregation. This constant 
    must be greater than zero (for example, `compwt=0.5`). This argument can only be
    used in conjunction with comptype. The default composite weight is 1.0.

* **decimals** (Int64) - Specifies the number of decimals that will appear in the seasonal adjustment tables of the
    main output file. This value must be an integer between 0 and 5, inclusive (for example,
    `decimals=5`). The default number of decimals is 0.

* **modelspan** (UnitRange{MIT} or X13.span) - Specifies the span (data interval) of the data to be used to determine all regARIMA
    model coefficients. This argument can be utilized when, for example, the user does not
    want data early in the series to affect the forecasts, or, alternatively, data late in the
    series to affect regression estimates used for preadjustment before seasonal adjustment.
    The default span corresponds to the span of the series being analyzed. 
    
    For example, for monthly data,
    the statement `modelspan=1968M1:last(dateof(ts))`` causes whatever regARIMA model is specified in
    other specs to be estimated from the time series data starting in January, 1968 and
    ending at the end date of the TSeries `ts`.

    An X13.Span can also be used in this field, this is specified with two values with a value of missing,
    substituting for the beginning or ending of the provided series. Example: `X13.Span(1968M1,missing)`.
    The second value can also be a monthly or a quarterly indicator, such as `M11` or `Q2`. If this is th ecase,
    the ending tdate of the modelspan will be the most recent occurence in the data of the specified month or quarter.

* **name** (String) - The name of the time series. The name must be enclosed in quotes and may contain up
    to 64 characters. Up to the first 16 characters will be printed as a label on every page.

* **span** (UnitRange{MIT} or Span) - Limits the data utilized for the calculations and analysis to a span (data interval) of
    the available time series. The default span corresponds to the span of the series being analyzed. The start and end 
    dates of the span must both lie within the series, and the start date must precede the end date.

    For example, for monthly data,
    the statement `modelspan=1968M1:last(dateof(ts))`` causes whatever regARIMA model is specified in
    other specs to be estimated from the time series data starting in January, 1968 and
    ending at the end date of the TSeries `ts`. 

    An X13.Span can also be used in this field, this is specified with two values with a value of missing,
    substituting for the beginning or ending of the provided series. Example: `X13.Span(1968M1,missing)`.

* **title** (String) - A title describing the time series. The title may contain
    up to 79 characters. It will be printed on each page of the output (unless the -p option
    is evoked; see Section 2.7).
    
* **type** (Symbol) - Indicates the type of series being input. If `type = :flow`, the series is assumed to be a
    flow series; if `type = :stock`, the series is assumed to be a stock series. The default is to
    not assign a type to the series.

### Rarely used keyword arguments:
* **divpower** (Int64) - An integer value used to re-scale the input time series prior to analysis. The program
    divides the series by ten raised to the specified value. For example, setting `divpower = 2` will divide the 
    original time series by 10^2, while divpower = -4 will divide the seriesby 10^(-4). 
    Integers from -9 to 9 are acceptable values for divpower. If this option is not
    specified, the time series will not be re-scaled.

* **missingcode** (Float64) - A numeric value in the input time series that the program will interpret as a missing
    value. This option can only be used in input specification files requiring a regARIMA
    model to be estimated or identified automatically. The default value is -99999.0. Example:
    `missingcode=0.0`.

* **missingval** (Float64) - The initial replacement value for observations that have the value of missingcode. The
    subsequent replacement procedure is described in DETAILS. The default value of missingval is 1000000000. 
    Example: `missingval=1e10`.

* **saveprecision** (Int64) - The number of decimals stored when saving a table to a separate file with the save
    argument. The default value of saveprecision is 15. Example: `saveprecision=10`.
"""
function series(t::TSeries{F}; 
    appendbcst::Union{Bool,X13default}=_X13default,
    appendfcst::Union{Bool,X13default}=_X13default,
    comptype::Union{Symbol,X13default}=_X13default,
    compwt::Union{Float64,X13default}=_X13default,
    decimals::Union{Int64,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    modelspan::Union{UnitRange{MIT{F}},Span,X13default}=_X13default,
    name::Union{String,X13default}=_X13default,
    period::Union{Int64,X13default}=_X13default,
    precision::Union{Int64,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    span::Union{UnitRange{MIT{F}},Span,X13default}=_X13default,
    start::Union{MIT{F},X13default}=_X13default,
    title::Union{String,X13default}=_X13default,
    type::Union{Symbol, X13default}=_X13default,
    divpower::Union{Int64,X13default}=_X13default,
    missingcode::Union{Float64,X13default}=_X13default,
    missingval::Union{Float64,X13default}=_X13default,
    saveprecision::Union{Int64,X13default}=_X13default,
    trimzero::Union{Bool,Symbol,X13default}=_X13default
) where F<:Frequency
    data=copy(t)
    if start isa MIT
        data=copy(t[start:end])
    else
        start = first(rangeof(data))
    end
    # logic and checks here...
    if name isa String && length(name) > 64
        @warn "Series name trunctated to 64 characters. Full name: $name"
        name = name[1:64]
    end

    if title isa String && length(title) > 79
        @warn "Series title trunctated to 79 characters. Full title: $title"
        title = title[1:79]
    end

    if divpower isa Int64 && (divpower < -9 || divpower > 9)
        Throw(ArgumentError("Series divpower must be between -9 and 9. $(divpower) provided"))
    end

    if F !== Monthly && !(F <: Yearly)
        period = ppy(t)
    end

    if span isa UnitRange
        if first(span) < first(rangeof(t)) || last(span) > last(rangeof(t))
            throw(ArgumentError("span ($span) must be contained within the range of the provided series ($(rangeof(data)))."))
        end
    elseif span isa Span
        if span.b isa MIT && span.b < first(rangeof(t))
            throw(ArgumentError("the start of the specified span must be on or after the start of the provided series ($(first(rangeof(data)))). Received: $(span.b)"))
        end
        if span.e isa MIT && span.e > last(rangeof(t))
            throw(ArgumentError("the end of the specified spanmust be on or after the end of the provided series ($(last(rangeof(data)))). Received: $(span.b)"))
        end
    end

    if !(divpower isa X13default)
        if divpower < -9 || divpower > 9
            throw(ArgumentError("divpower values must be between -9 and 9 (inclusive). Received: $(divpower)."))
        end
    end

    if span isa X13.Span
        if span.e isa TimeSeriesEcon._FPConst || span.e isa UnionAll
            throw(ArgumentError("Spans with an fuzzy ending time, such as M11 or Q2, are not allowed in the span argument of the series spec. Please pass an MIT or `missing`. Received: $(span.e)."))
        end
    end

    _print_all = [:default, :adjoriginal, :adjorigplot, :calendaradjorig, :outlieradjorig, :seriesplot]
    _save_all = [:span, :specfile, :adjoriginal, :calendaradjorig, :outlieradjorig, :seriesmvadj]

    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13series{F}(appendbcst, appendfcst, comptype, compwt, data, decimals, file, format, modelspan,name, period, precision, print, save, span,start,title,type,divpower,missingcode,missingval,saveprecision,trimzero)
end
series!(spec::X13spec{F}, t::TSeries{F}; kwargs...) where F = (spec.series = series(t; kwargs...); spec)

"""
`arima(model::ArimaSpecs...; kwargs...)`

`arima!(spec::X13spec{F}, model::ArimaSpec...; kwargs...)`

Specifies the ARIMA part of the regARIMA model. This defines a pure ARIMA model if the regression spec
is absent. The ARIMA part of the model may include multiplicative seasonal factors and operators with missing
lags. Using the `ar` and `ma` arguments, initial values for the individual AR and MA parameters can be specified
for the iterative estimation. Also, individual parameters can be held fixed at these initial values while the rest
of the parameters are estimated

### Main positional arguments:
* **model** (ArimaSpec) - Specifies the ARIMA part of the model. It is a vector
    of X13.ArimaSpec objects. The default period for these specs is 0. Specs with this default
    will have their period determined by their ordering. For example 
    `arima(X13.ArimaSpec(p,d,q),X13.ArimaSpec(P,D,Q)) assumes that the first spec has a period of 1
    and the second spec has a period of the frequency of the series (i.e. 4 for a Quarterly series).

    More than two
    ARIMA factors can be specified, and ARIMA factors can explicitly be given seasonal
    periods that differ from the default choices.

### Main keyword arguments:

* **ar** (Vector{Union{Float64,Missing}) - Specifies initial values for nonseasonal and seasonal autoregressive parameters in the
    order that they appear in the model argument. If present, the `ar` argument must assign
    initial values to all AR parameters in the model. Initial values are assigned to parameters
    either by specifying the value in the argument list or by explicitly indicating that it is
    missing. Missing values take on their default value of `0.1`. For example, for a model
    with two AR parameters, `ar=[0.7,missing]` is equivalent to `ar=`0.7,0.1]`, but `ar=[0.7]` is
    not allowed. For a model with three AR parameters, `ar=[0.8,missing,-0.4]` is equivalent to
    `ar=[0.8,0.1,-0.4]`. To hold a parameter fixed during estimation at its initial value,
    use the `arfixed` keyword argument.

* **ma** (Vector{Union{Float64,Missing}) - Specifies initial values for all moving average parameters 
    in the same way `ar` does so for autoregressive parameters.

* **fixar** (Vector{Bool}) - Specifies for each element in the `ar` argument whether to hold the
    value fixed. Must be the same length as the `ar` argument.

* **fixma** (Vector{Bool}) - Specifies for each element in the `ma` argument whether to hold the
    value fixed. Must be the same length as the `ma` argument.

* **title** (String) - Specifies a title for the ARIMA model, in quotes. It must be less than 80 characters.
    The title appears above the ARIMA model description and the table of estimates. The
    default is to print ARIMA Model.

"""
function arima(model::ArimaModel; 
    title::Union{String,X13default}=_X13default,
    ar::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default}=_X13default,
    ma::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default}=_X13default,
    fixar::Union{Vector{Bool},X13default}=_X13default,
    fixma::Union{Vector{Bool},X13default}=_X13default,
)
    # checks and logic

    # ar arguments have correct length
    # if !(ar isa X13default)
    #     @assert length(ar) == length(model[1].p) 
    # end
    # if !(ma isa X13default)
    #     @assert length(ma) == length(model[1].q) 
    # end

    # fixed arguments have correct length
    if !(fixar isa X13default)
        @assert length(fixar) == length(ar) 
    end
    if !(fixma isa X13default)
        @assert length(fixma) == length(ma) 
    end

    if title isa String && length(title) > 79
        @warn "Series title trunctated to 79 characters. Full title: $title"
        title = title[1:79]
    end

    return X13arima(model, title, ar, ma, fixar, fixma)
end
# arima(model::ArimaModel; kwargs...) = arima(model; kwargs...)
arima(model::ArimaSpec; kwargs...) = arima(ArimaModel(model); kwargs...)
arima(models::ArimaSpec...; kwargs...) = arima(ArimaModel(models...); kwargs...)

arima!(spec::X13spec{F}, model::ArimaModel; kwargs...) where F = (spec.arima = arima(model; kwargs...); spec)
arima!(spec::X13spec{F}, model::ArimaSpec; kwargs...) where F = (spec.arima = arima(ArimaModel(model); kwargs...); spec)
arima!(spec::X13spec{F}, models::ArimaSpec...; kwargs...) where F = (spec.arima = arima(ArimaModel(models...); kwargs...); spec)


# arima!(spec::X13spec{F}, model::ArimaSpec; kwargs...) where F = (spec.arima = arima((model,)...; kwargs...))
# arima!(spec::X13spec{F}, model::ArimaSpec...; kwargs...) where F = (spec.arima = arima(model...; kwargs...))


"""
`automdl(; kwargs...)`

`automdl!(spec::X13spec{F}; kwargs...)`

Specifies that the ARIMA part of the regARIMA model will be sought using an automatic model selection
procedure derived from the one used by TRAMO (see G´omez and Maravall (2001a)). The user can specify the
maximum ARMA and differencing orders to use in the model search, and can adjust thresholds for several of
the selection criteria.

### Main keyword arguments:

* **acceptdefault** (Bool) - Controls whether the default model is chosen if the Ljung-Box Q 
    statistic for its model
    residuals (checked at lag 24 if the series is monthly, 16 if the series is quarterly) is
    acceptable (`acceptdefault = true`). If the default model is found to be acceptable, no
    further attempt will be made to identify a model or differencing order. The default for
    acceptdefault is `acceptdefault = false`.

* **checkmu** (Bool) - Controls whether the automatic model selection procedure will check for the significance
    of a constant term (`checkmu = true`), or will maintain the choice of the user made by the
    user in the regression spec (`checkmu = false`). The default for checkmu is `checkmu = true`.

* **diff** (Vector{Int64}) - Fixes the orders of differencing to be used in the automatic ARIMA model identification
    procedure. The diff argument has two input values, the regular differencing order and
    the seasonal differencing order. Both values must be specified; there is no default value.
    Acceptable values for the regular differencing orders are 0, 1 and 2; acceptable values
    for the seasonal differencing orders are 0 and 1. If specified in the same spec file as
    the maxdiff argument, the values for the diff argument are ignored and the program
    performs automatic identification of nonseasonal and seasonal differencing with the limits
    specified in maxdiff.

* **ljungboxlimit** (Float64) - Acceptance criterion for confidence coefficient of the Ljung-Box Q statistic. If the Ljung
    Box Q for the residuals of a final model (checked at lag 24 if the series is Monthly,
    16 if the series is Quarterly) is greater than ljungboxlimit, the model is rejected, the
    outlier critical value is reduced, and model and outlier identification (if specified) is
    redone with a reduced value (see reducecv argument). The default for ljungboxlimit
    is `ljungboxlimit = 0.95`.

* **maxdiff** (Vector{Union{Int64,Missing}}) - Specifies the maximum orders of regular and seasonal differencing 
    for the automatic
    identification of differencing orders. The maxdiff argument has two input values, the
    maximum regular differencing order and the maximum seasonal differencing order. Acceptable 
    values for the maximum order of regular differencing are 1 or 2, and the acceptable value 
    for the maximum order of seasonal differencing is 1. If specified in the same
    spec file as the maxdiff argument, the values for the diff argument are ignored and the
    program performs automatic identification of nonseasonal and seasonal differencing with
    the limits specified in maxdiff. The default is `maxdiff = [2, 1]`.

* **maxorder** (Vector{Union{Int64,Missing}}) - Specifies the maximum orders of the regular and seasonal ARMA polynomials 
    to be examined during the automatic ARIMA model identification procedure. The maxorder
    argument has two input values, the maximum order of regular ARMA model to be tested
    and the maximum order of seasonal ARMA model to be tested. The maximum order for
    the regular ARMA model must be greater than zero, and can be at most 4; the maximum
    order for the seasonal ARMA model can be either 1 or 2. The default is `maxorder = [2, 1]`.

* **mixed** (Bool) - Controls whether ARIMA models with nonseasonal AR and MA terms or seasonal AR
    and MA terms will be considered in the automatic model identification procedure (`mixed = true`). 
    If `mixed = false`, mixed models would not be considered. Note that a model with
    AR and MA terms in both the seasonal and nonseasonal parts of the model can be acceptable, 
    provided there are not AR and MA terms in either the seasonal or nonseasonal.
    For example, when `mixed = false` an ARIMA (0 1 1)(1 1 0) model would be considered,
    while an ARIMA (1 1 1)(0 1 1) model would not, since there are AR and MA terms in
    the nonseasonal part of the model. The default for mixed is `mixed = true`.

### Rarely used keyword arguments:

* **armalimit** (Float64) - Threshold value for t-statistics of ARMA coefficients used for final test of model 
    parsimony. If the highest order ARMA coefficient has a t-value less than this value in magnitude, 
    the program will reduce the order of the model. The value given for armalimit is
    also used for the final check of the constant term; if the constant term has a t-value less
    than armalimit in magnitude, the program will remove the constant term from the set
    of regressors. This value should be greater than zero. The default is `armalimit = 1.0`.

* **balanced** (Bool) - Controls whether the automatic model procedure will have a preference for balanced
    models (where the order of the combined AR and differencing operator is equal to the
    order of the combined MA operator). Setting `balanced = true` yields the same preference
    as the TRAMO program. The default is `balanced = false`.

* **exactdiff** (Bool or Symbol) - Controls if exact likelihood estimation is used when Hannen-Rissanen fails in automatic
    difference identification procedure (`exactdiff = true`), or if conditional likelihood estimation is used 
    (`exactdiff = false`). The default is to start with exact likelihood estimation, and switch to conditional if 
    the number of iterations for the exact likelihood procedure exceeds 200 iterations (`exactdiff = :first`).

* **fcstlim** (Int64) - The acceptance threshold for the within-sample forecast error test of the final identified
    model. The absolute average percentage error of the extrapolated values within the last
    three years of data must be less than this value for forecasts to be generated with the final
    model. For example, fcstlim=20 sets this threshold to 20 percent. The value entered
    for this argument must not be less than zero, or greater than 100. This option is only
    active when rejectfcst = yes. The default is  `fcstlim=15` percent.

* **hrinitial** (Bool) - Controls whether Hannan-Rissanen estimation is done before exact maximum likelihood
    estimation to provide initial values when generating likelihood statistics for identifying
    the ARMA orders (`hrinitial = true`). If `hrinitial = true`, then models for which
    the Hannan-Rissanen estimation yields coefficients that are unacceptable initial values
    to the exact maximum likelihood estimation procedure will be rejected. The default is
    `hrinitial = false`.

* **reducecv** (Float64) - The percentage by which the outlier critical value will be reduced when an identified
    model is found to have a Ljung-Box Q statistic with an unacceptable confidence coefficient. This value should 
    be between 0 and 1, and will only be active when automatic outlier identification is selected. The reduced 
    critical value will be set to `(1-reducecv)*CV` ), where CV is the original critical value. 
    The default is `reducecv = 0.14268`.

* **rejectfcst** (Bool) - If `rejectfcst = true`, then a test of the out-of-sample forecast error of the final three
    years of data will be generated with the identified model to determine if forecast extension
    will be applied. If the forecast error exceeds the value of fcstlimit, forecasts will not
    be generated with the final identified model, but the model will be used to generate
    preadjustment factors for calendar and outlier effects. The default is `rejectfcst=false`.

* **urfinal** (Float64) - Threshold value for the final unit root test. If the magnitude of an AR root for the final
    model is less than this number, a unit root is assumed, the order of the AR polynomial
    is reduced by one, and the appropriate order of differencing (nonseasonal, seasonal) is
    increased. This value should be greater than one. The default is `urfinal = 1.05`.

"""
function automdl(;
    diff::Union{Vector{Int64},X13default}=_X13default,
    acceptdefault::Union{Bool,X13default}=_X13default,
    checkmu::Union{Bool,X13default}=_X13default,
    ljungboxlimit::Union{Float64,X13default}=_X13default,
    maxorder::Union{Vector{Union{Int64,Missing}},X13default}=_X13default,
    maxdiff::Union{Vector{Union{Int64,Missing}},X13default}=_X13default,
    mixed::Union{Bool,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=[:autochoice, :autochoicemdl, :autodefaulttests, :autofinaltests, :autoljungboxtest, :bestfivemdl, :header, :unitroottest, :unitroottestmdl],
    savelog::Union{Symbol,Vector{Symbol},X13default}=:alldiagnostics,
    armalimit::Union{Float64,X13default}=_X13default,
    balanced::Union{Bool,X13default}=_X13default,
    exactdiff::Union{Bool,Symbol,X13default}=_X13default,
    fcstlim::Union{Int64,X13default}=_X13default,
    hrinitial::Union{Bool,X13default}=_X13default,
    reducecv::Union{Float64,X13default}=_X13default,
    rejectfcst::Union{Bool,X13default}=_X13default,
    urfinal::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    if !(diff isa X13default) 
        if length(diff) !== 2
            throw(ArgumentError("The diff argument of the automdl spec must contain exactly two values."))
        end
        if diff[1] ∉ (0,1,2)
            throw(ArgumentError("Acceptable values for the regular differencing orders of the automdl spec are 0, 1, and 2. Received: $(diff[1])."))
        end
        if diff[2] ∉ (0,1)
            throw(ArgumentError("Acceptable values for the seasonal differencing orders of the automdl spec are 0 and 2. Received: $(diff[2])."))
        end
        if !(maxdiff isa X13default)
            @warn "The diff argument of the automdl spec will be ignored because a maxdiff argument is specified."
        end
    end

    if !(maxdiff isa X13default) 
        if length(maxdiff) !== 2
            throw(ArgumentError("The maxdiff argument of the automdl spec must contain exactly two values."))
        end
        if !(maxdiff[1] isa Missing) && maxdiff[1] ∉ (0,1,2)
            throw(ArgumentError("Acceptable values for the regular maximum differencing orders of the automdl spec are 1, and 2. Received: $(maxdiff[1])."))
        end
        if !(maxdiff[1] isa Missing) && maxdiff[2] ∉ (0,1)
            throw(ArgumentError("The only acceptable value for the seasonal maximum differencing orders of the automdl spec is 1. Received: $(maxdiff[2])."))
        end
    end

    if !(maxorder isa X13default) 
        if length(maxorder) !== 2
            throw(ArgumentError("The maxorder argument of the automdl spec must contain exactly two values."))
        end
        if !(maxorder[1] isa Missing) && maxorder[1] ∉ (1,2,3,4)
            throw(ArgumentError("The maximum order for the regular ARMA model must be greater than zero and can be at most 4. Received: $(maxorder[1])."))
        end
        if !(maxorder[2] isa Missing) && maxorder[2] ∉ (1,2)
            throw(ArgumentError("The maximum order for the seasonal ARMA model can be either 1 or 2. Received: $(maxorder[2])."))
        end
    end

    if !(armalimit isa X13default) && armalimit <= 0.0
        throw(ArgumentError("armalimit should have a value geater than zero. Received: $(armalimit)."))
    end

    if !(fcstlim isa X13default) && (fcstlim < 0 || fctslim > 100)
        throw(ArgumentError("fcstlim must not be less than zero or greater than 100. Received: $(fcstlim)."))
    end

    if !(reducecv isa X13default) && (reducecv < 0.0 || reducecv > 1.0)
        throw(ArgumentError("reducecv should be between 0 and 1. Received: $(reducecv)."))
    end

    if !(urfinal isa X13default) && urfinal < 1.0 
        throw(ArgumentError("urfinal should be greater than 1. Received: $(urfinal)."))
    end

    _print_all = [:autochoice, :autochoicemdl, :autodefaulttests, :autofinaltests, :autoljungboxtest, :bestfivemdl, :header, :unitroottest, :unitroottestmdl]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end

    return X13automdl(diff,acceptdefault,checkmu,ljungboxlimit,maxorder,maxdiff,mixed,print,savelog,armalimit,balanced,exactdiff,fcstlim,hrinitial,reducecv,rejectfcst,urfinal)
end
automdl!(spec::X13spec{F}; kwargs...) where F = (spec.automdl = automdl(; kwargs...); spec)


"""
`check(; kwargs...)`

`check!(spec::X13spec{F}; kwargs...)`

Specification to produce statistics for diagnostic checking of residuals from the estimated model. Statistics
    available for diagnostic checking include the sample ACF and PACF of the residuals with associated standard
    errors, Ljung-Box Q-statistics and their p-values, summary statistics of the residuals, normality test statistics
    for the residuals, a spectral plot of the model residuals, and a histogram of the standardized residuals.

### Main keyword arguments:

* **maxlag** (Int64) - The number of lags requested for the residual sample ACF and PACF for both tables
    and plots. The default is 24 for monthly series, 8 for quarterly series.

* **qtype** (Symbol) - The type of residual diagnostic to be displayed with the sample autocorrelation plots. If
    `qtype = :ljungbox` or `qtype = :lb`, the Ljung-Box Q-statistic will be the one produced. If
    `qtype = :boxpierce` or `qtype = :bp`, the Box-Pierce Q-statistic will be the one produced.
    The Ljung-Box statistic will be produced by default.

### Rarely used keyword arguments:

* **acflimit** (Float64) - Limit for the t-statistic used to determine if residual sample ACFs and PACFs are flagged
    as significant in the diagnostic summary file (with the file extension .udg). The default
    is 1.6.

* **qlimit** (Float64) - Limit for the p-value of the Q statistic used to determine if residual sample ACFs and
    PACFs are flagged as significant in the diagnostic summary file (with the file extension
    .udg) or the log output file (which ends with the text .log). The default is 0.05.
"""
function check(; 
    maxlag::Union{Int64,X13default}=_X13default,
    qtype::Union{Symbol,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:alldiagnostics,
    acflimit::Union{Float64,X13default}=_X13default,
    qlimit::Union{Float64,X13default}=_X13default
)
    # checks and logic
    _print_all = [:acf, :acfplot, :pacf, :pacfplot, :acfsquared, :acfsquaredplot, :normalitytest, :durbinwatson, :friedmantest, :histogram]
    _save_all = [:acf, :pacf, :acfsquared]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13check(maxlag,qtype,print,save,savelog,acflimit,qlimit)
end
check!(spec::X13spec{F}; kwargs...) where F = (spec.check = check(; kwargs...); spec)

"""
`estimate(; kwargs...)`

`estimate!(spec::X13spec{F}; kwargs...)`

Estimates the regARIMA model specified by the regression and arima specs. Allows the setting of various
estimation options. Estimation output includes point estimates and standard errors for all estimated AR,
MA, and regression parameters; the maximum likelihood estimate of the variance σ^2; t-statistics for individual
regression parameters; χ^2-statistics for assessing the joint significance of the parameters associated with certain
regression effects (if included in the model); and likelihood based model selection statistics (if the exact likelihood
function is used). The regression effects for which χ^2-statistics are produced include stable seasonal effects,
trading-day effects, and the set of user-defined regression effects.

### Main keyword arguments:

* **exact** (Symbol) - Specifies use of exact or conditional likelihood for estimation, likelihood evaluation, and
    forecasting. The default is `exact = :arma`, which uses the likelihood function that is exact
    for both AR and MA parameters. Other options are: `exact = :ma`, use the likelihood
    function that is exact for MA, but conditional for AR parameters; and `exact = :none`,
    use the likelihood function that is conditional for both AR and MA parameters.

* **maxiter** (Int64) - The maximum number allowed of ARMA iterations (nonlinear iterations for estimating
    the AR and MA parameters). For models with regression variables, this limit applies
    to the total number of ARMA iterations over all IGLS iterations. For models without
    regression variables, this is the maximum number of iterations allowed for the single set
    of ARMA iterations. The default is `maxiter = 1500`.

* **outofsample** (Bool) - Determines the kind of forecast error used in calculating the average magnitude of forecast
    errors over the last three years, a diagnostic statistic. If `outofsample=true`, out-of-sample
    forecasts errors are used; these are obtained by removing the data in the forecast period
    from the data set used to estimate the model and produce one year of forecasts (for each
    of the last three years of data). If `outofsample=false`, within-sample forecasts errors are
    used. That is, the model parameter estimates for the full series are used to generate
    forecasts for each of the last three years of data. The default is `outofsample=false`.

* **tol** (Float64) - Convergence tolerance for the nonlinear estimation. Absolute changes in the log-likelihood 
    are compared to tol to check convergence of the estimation iterations. For models
    with regression variables, tol is used to check convergence of the IGLS iterations (where
    the regression parameters are re-estimated for each new set of AR and MA parameters),
    see Otto, Bell, and Burman (1987). For models without regression variables there are
    no IGLS iterations, and tol is then used to check convergence of the nonlinear iterations
    used to estimate the AR and MA parameters. The default value is `tol = 1.0e-5`.

### Rarely used keyword arguments:

* **file** (String) - The full path to a file containing the `.mdl` output from another estimation.

* **fix** (Symbol) - Specifies whether certain coefficients found in the model file specified in the file argument
    are to be held fixed instead of being used as initializing values for further estimation. If
    `fix = :all`, both the regression and ARMA parameter estimates will be held fixed at
    their values in the model file. If `fix = :arma`, only ARMA parameter estimates will be
    held fixed at their model file values. If `fix = :none`, none of the parameter estimates
    will be held fixed. The default is fix = nochange, which will preserve coefficient values
    specified as fixed in the model file and allow re-estimation of all other coefficients.

"""
function estimate(; 
    exact::Union{Symbol,X13default}=_X13default,
    maxiter::Union{Int64,X13default}=_X13default,
    outofsample::Union{Bool,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:alldiagnostics,
    tol::Union{Float64,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    fix::Union{Symbol,X13default}=_X13default,
)
    # checks and logic

    _print_all = [:options, :model, :estimates, :averagefcsterr, :lkstats, :iterations, :iterationerrors, :regcmatrix, :armacmatrix, :lformulas, :roots, :regressioneffects, :regressionresiduals, :residuals]
    _save_all = [:model, :estimates, :lkstats, :iterations, :regcmatrix, :armacmatrix, :roots, :regressioneffects, :regressionresiduals, :residuals]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end
    return X13estimate(exact,maxiter,outofsample,print,save,savelog,tol,file,fix)
end
estimate!(spec::X13spec{F}; kwargs...) where F = (spec.estimate = estimate(; kwargs...); spec)
#TODO: Support for file argument (previous model)

"""
`force(; kwargs...)`

`force!(spec::X13spec{F}; kwargs...)`

An optional spec for invoking options that allow users to force yearly totals of the seasonally adjusted series
    to equal those of the original series for convenience. Two forcing methods are available, the original modified
    Denton method of X-11-ARIMA and earlier version of X-13ARIMA-SEATS described in Huot (1975) and Cholette
    (1978), and a newer method based on the regression benchmarking method of Cholette and Dagum (1994) as
    adapted by Quenneville, Cholette, Huot, Chiu, and DiFonzo (2004). See also Dagum and Cholette (2006).

    
### Main keyword arguments:

* **lambda** (Float64) - Value of the parameter λ used to determine the weight matrix C for the regression method
    of forcing the totals of the seasonally adjusted series. For more details, see Section 2 of
    Quenneville et al. (2004). Permissable values of lambda range from -3.0 to 3.0. The
    most commonly used values are 1.0, 0.5 and 0.0, while cases could also be made for
    using either -2, -1, or 2; other values of lambda are extremely unlikely. The default is
    `lambda = 0.0`.

* **mode** (Symbol) - Determines whether the ratios (`mode=:ratio`) or differences (`mode=:diff`) in the annual
    totals of the series specified in the argument target and the seasonally adjusted series
    are stored, and on what basis the forcing adjustment factors are generated. The default
    is `mode=:ratio`.

* **rho** (Float64) - Determines whether the ratios (`mode=:ratio`) or differences (`mode=:diff`) in the annual
    totals of the series specified in the argument target and the seasonally adjusted series
    are stored, and on what basis the forcing adjustment factors are generated. The default
    is `mode=:ratio`.

* **round** (Bool) - When `round=true`, the program will adjust the seasonally adjusted values for each calendar 
    year so that the sum of the rounded seasonally adjusted series for any year will equal
    the rounded annual total; otherwise, the seasonally adjusted values will not be rounded.

* **start** (Symbol or Month/Quarter indicator) - This option sets the beginning of the yearly benchmark period over which the seasonally
    adjusted series will be forced to sum to the total. Unless start is used, the year is
    assumed to be the calendar year for the procedure invoked by setting `type=:denton` or
    `type=:regress`, but an alternate starting period can be specified for the year (such as the
    start of a fiscal year) by assigning to forcestart the month i.e. (`:october` or `M10`) or quarter (i.e. `:q3` or `Q3`)
    of the beginning of the desired yearly benchmarking period.
    For example, to specify a fiscal year which starts in October and ends in September, set
    `start=M10`. To specify a fiscal year which starts in the third quarter
    of one year and ends in the second quarter of the next, set `start=Q3` (for a Quarterly series).

* **target** (Symbol) - Specifies which series is used as the target for forcing the totals of the seasonally adjusted
    series.

    Entry for the target argument | series                                                                       
    :-----------------------------| :----------------------------------------------------------------------------
    `:original`                   | Original Series                                                              
    `:caladjust`                  | Calendar Adjusted Series                                                     
    `:permprioradj`               | Original Series adjusted for permanent prior adjustment factors              
    `:both`                       | Original Series adjusted for calendar and permanent prior adjustment factors 
    
    The default for this argument is target=original.


* **type** (Symbol) - Specifies options that allow the seasonally adjusted series be modified to force the yearly
    totals of the seasonally adjusted series and the series specified in the target argument
    to be the same. By default (`type=:none`), the program will not modify the seasonally
    adjusted values.

    When `type=:denton`, the differences between the annual totals is distributed over the
    seasonally adjusted values in a way that approximately preserves the month-to-month (or
    quarter-to-quarter) movements of the original series for an additive seasonal adjustment,
    and tries to keep the ratio of the forced and unforced values constant for multiplicative
    adjustments. For more details see Huot (1975) and Cholette (1978).

    When `type=:regress`, a regression-based solution of Cholette and Dagum (1994) to the
    problem of benchmarking seasonally adjusted series is used. For more details see Quenneville et al. (2004).

    These forcing procedures are not recommended if the seasonal pattern is changing or if
    trading day adjustment is performed.

* **usefcst** (Bool) - Determines if forecasts are appended to the series processed by the benchmarking routines
    used to force the yearly totals of the seasonally adjusted series. If `usefcst = true`, then
    forecasts are used to extend the series in the forcing procedure; if `usefcst = false`, then
    forecasts are not used. The default is` usefcst = true`.

### Rarely used keyword arguments:

* **indforce** (Bool) - Determines how the indirect seasonally adjusted series with forced yearly total is generated. 
    If `indforce = true`, the indirect seasonally adjusted series will be modified so that
    their yearly totals match those of the target series. If `indforce = false`, the seasonally
    adjusted series with forced yearly totals will be combined for each of the component series
    to form the indirect seasonally adjusted series with forced yearly totals. The default for
    this option is `indforce = true`.

"""
function force(;
    lambda::Union{Float64,X13default}=_X13default,
    mode::Union{Symbol,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    rho::Union{Float64,X13default}=_X13default,
    round::Union{Bool,X13default}=_X13default,
    start::Union{Symbol, TimeSeriesEcon._FPConst, UnionAll, X13default}=_X13default,
    target::Union{Symbol,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
    usefcst::Union{Bool,X13default}=_X13default,
    indforce::Union{Bool,X13default}=_X13default,
)
    # checks and logic
    if !(rho isa X13default) && (rho < 0.0 || rho > 1.0)
        throw(ArgumentError("rho must be between 0 and 1. Received: $(rho)."))
    end

    _print_all = [:seasadjtot, :saround, :revsachanges, :rndsachanges]
    _save_all = [:seasadjtot, :saround, :revsachanges, :rndsachanges, :revsachangespct, :rndsachangespct]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13force(lambda,mode,print,save,rho,round,start,target,type,usefcst,indforce)
end
force!(spec::X13spec{F}; kwargs...) where F = (spec.force = force(; kwargs...); spec)


"""
`forecast(; kwargs...)`

`forecast!(spec::X13spec{F}; kwargs...)`

Specification to forecast and/or backcast the time series given in the series spec using the estimated model.
The output contains point forecasts and forecast standard errors for the transformed series, and point forecasts
and prediction intervals for the original series.

### Main keyword arguments:

* **exclude** (Int64) - Number of observations excluded from the end of the series (or from the end of the span
    specified by the span argument of the series spec, if present) before forecasting. The
    default is to start forecasting from the end of the series (or span), i.e., `exclude = 0`.

* **lognormal** (Bool) - Determines if an adjustment is made to the forecasts when a log transformation is specified 
    by the user to reflect that the forecasts age generated from a log-normal distribution
    (`lognormal = true`). The default is not to make such an adjustment (`lognormal = false`).

* **maxback** (Int64) - Number of backcasts produced. The default is 0 and 120 is the maximum. (The limit of
    120 can be changed—see Section 2.8 of the manual.) Note: Backcasts are not produced when SEATS
    seasonal adjustments are specified, or if the starting date specified in the modelspan
    argument of the series spec is not the same as the starting date of the analysis span
    specified in the span argument of the series spec.

* **maxlead** (Int64) - Number of forecasts produced. The default is one year of forecasts (unless a SEATS
    seasonal adjustment is requested - then the default is three years of forecasts) and 120 is
    the maximum. (The limit of 120 can be changed—see Section 2.8 of the manual.)

* **probability** (Float64) - Coverage probability for prediction intervals, assuming normality. The default is 
    `probability=.95`, in which case prediction intervals on the transformed scale are point forecast
    ± 1.96 × _forecast standard error_.

"""
function forecast(; 
    exclude::Union{Int64,X13default}=_X13default,
    lognormal::Union{Bool,X13default}=_X13default,
    maxback::Union{Int64,X13default}=_X13default,
    maxlead::Union{Int64,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    probability::Union{Float64,X13default}=_X13default,
)
    # checks and logic

    _print_all = [:transformed, :variances, :forecasts, :transformedbcst, :backcasts]
    _save_all = [:transformed, :variances, :forecasts, :transformedbcst, :backcasts]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end
    return X13forecast(exclude,lognormal,maxback,maxlead,print,save,probability)
end
forecast!(spec::X13spec{F}; kwargs...) where F = (spec.forecast = forecast(; kwargs...); spec)

"""
`history(; kwargs...)`

`history!(spec::X13spec{F}; kwargs...)`

Optional spec for requesting a sequence of runs from a sequence of truncated versions of the time series for the
    purpose of creating historical records of (i) revisions from initial (concurrent or projected) seasonal adjustments,
    (ii) out-of-sample forecast errors, and (iii) likelihood statistics. The user can specify the beginning date of the
    historical record and the choice of records (i) - (iii). If forecast errors are chosen, the user can specify a vector
    of forecast leads. *Warning:* Generating the history analysis can substantially increase the program’s run time.

### Main keyword arguments:

* **endtable** (MIT) - Specifies the final date of the output tables of the revisions history analysis of seasonal
    adjustment and trend estimates and their period-to-period changes. This can be used
    to ensure that the revisions history analysis summary statistics are based only on final
    (or nearly final) seasonal adjustments or trends. If endtable is not assigned a value,
    it is set to the date of the observation immediately before the end of the series or to a
    value one greater than the largest lag specified in sadjlags or trendlags. This option
    has no effect on the historical analysis of forecasts and likelihood estimates. Example:
    `endtable=1990M6`.

* **estimates** (Symbol or Vector{Symbol}) - Determines which estimates from the regARIMA modeling and/or the X-11 seasonal
    adjustment will be analyzed in the history analysis. Example: `estimates=[:sadj, :aic]`.
    The default is the seasonally adjusted series (`:sadj`). The following estimates are available:

    Option       | Description                                                                                                                                                                                                   
    :------------| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    `:sadj`      | Final seasonally adjusted series (and indirect seasonally adjusted series, if composite seasonal adjustment is performed.                                                                                     
    `:sadjchng`  | Month-to-month (or quarter-to-quarter) changes in the final seasonally adjusted series.                                                                                                                     
    `:trend`     | Final Henderson trend component.                                                                                                                                                                              
    `:trendchng` | Month-to-month (or quarter-to-quarter) changes in the final Henderson trend component.                                                                                                                        
    `:seasonal`  | Final and projected seasonal factors.                                                                                                                                                                         
    `:aic`       | AICCs and maximum log likelihoods for the regARIMA model.                                                                                                                                                     
    `:fcst`      | Forecasts and evolving mean square forecast errors generated from the regARIMA model. Warning: This option can be used only when forecasts are produced, see the forecast spec in Section 7.7 of the manual.  
    `:arma`      | Estimated AR and MA coefficients from the regARIMA model.                                                                                                                                                     
    `:td`        | Trading day regression coefficients from the regARIMA model. *Warning:* This option can be used only when trading day regressors are specified, see the regression spec in Section 7.13 of the manual.        

* **fixmdl** (Bool) - Specifies whether the regARIMA model will be re-estimated during the history analysis.
    If `fixmdl=true`, the ARIMA parameters and regression coefficients of the regARIMA
    model will be fixed throughout the analysis at the values estimated from the entire series
    (or model span, if one is specified via the modelspan argument). If `fixmdl=false`, the
    regARIMA model parameters will be re-estimated each time the end point of the data is
    changed. The default is `fixmdl=false`. This argument is ignored if no regARIMA model is
    fit to the series.

* **fixreg** (Bool) - Specifies the fixing of the coefficients of a regressor group, either within a regARIMA
    model or an irregular component regression. These coefficients will be fixed at the values
    obtained from the model span (implicit or explicitly) indicated in the series or composite
    spec. All other coefficients will be re-estimated for each history span. Trading day
    (`:td`), holiday (`:holiday`), outlier (`:outlier`), or other user-defined (`:user`) regression effects
    can be fixed. This argument is ignored if neither a regARIMA model nor an irregular
    component regression model is fit to the series, or if` fixmdl=:true`.

* **fstep** (Int64 or Vector{Int64}) - Specifies a vector of up to four (4) forecast leads that will be analyzed in the history
    analysis of forecast errors. Example: `fstep=[1, 2, 12]` will produce an error analysis for
    the 1-step, 2-step, and 12-step ahead forecasts. The default is `fstep=[1, 12]` for monthly series
    or `fstep=[1, 4]` for quarterly series. *Warning:* The values given in this vector cannot exceed
    the specified value of the maxlead argument of the forecast spec, or be less than one.

* **sadjlags** (Int64 or Vector{Int64}) - Specifies a vector of up to 5 revision lags (each greater than zero) that will be analyzed
    in the revisions analysis of lagged seasonal adjustments. The calculated revisions for
    these revision lags will be those of the seasonal adjustments obtained using this many
    observations beyond the time point of the adjustment. That is, for each value revisionlag[i]
    given in `sadjlags`, series values through time t + revisionlag[i] will be used to obtain
    the adjustment for time t whose revision will be calculated. For more information, see
    the manual.

    This option is meaningful only if the revisions history of the seasonally adjusted series or
    month-to-month (quarter-to-quarter) changes in the seasonally adjusted series is specified
    in the estimates argument. The default is no analysis of revisions of lagged seasonal
    adjustments.

* **start** (MIT) - Specifies the starting date of the revisions history analysis. If this argument is not used,
    its default setting depends on the length of the longest seasonal filter used, provided that
    a seasonal adjustment is being performed (if there is no conflict with the requirement that
    60 earlier observations be available when a regARIMA model is estimated and `fixmdl=false`,
    the default for `fixmdl`). The default starting date is six (6) years after the start of the
    series, if the longest filter is either a 3x3 or stable filter, eight (8) years for a 3x5 filter,
    and twelve (12) years for a 3x9 filter. If no seasonal adjustment is done, the default is 8
    years after the start of the series. Example: `start=1990M6`.

* **target** (Symbol) - Specifies whether the deviation from the concurrent estimate or the deviation from the
    final estimate defines the revisions of the seasonal adjustments and trends calculated at
    the lags specified in sadjlags or trendlags. The default is `target=:final`; the alternative
    is `target=:concurrent`.

* **trendlags** (Int64 or Vector{Int64}) - Similar to `sadjlags`, this argument prescribes which lags will be used in the revisions
    history of the lagged trend components. Up to 5 integer lags greater than zero can be
    specified.

    This option is meaningful only if the revisions history of the final trend component or
    month-to-month (quarter-to-quarter) changes in the final trend component is specified in
    the estimates argument. The default is no analysis of revisions lagged trend estimates.



### Rarely used keyword arguments:

* **fixx11reg** (Bool) - Specifies whether the irregular component regression model specified in the x11regression
    spec will be re-estimated during the history analysis. If `fixx11reg=true`, the regression
    coefficients for the irregular component regression model are fixed throughout the analysis
    at the values estimated from the entire series. If `fixx11reg=false`, the irregular component
    regression model parameters will be re-estimated each time the end point of the history
    interval is advanced.

    The default is `fixx11reg=false`. This argument is ignored if no irregular component regression model is specified.

* **outlier** (Symbol) - Specifies whether automatic outlier detection is to be performed whenever the regARIMA
    model is re-estimated during the revisions history analysis. This argument has no effect
    if the outlier spec is not used.

    If `outlier=:keep`, all outliers automatically identified using the full series are kept in the
    regARIMA model during the revisions history analysis. The coefficients estimating the
    effects of these outliers are re-estimated whenever the other regARIMA model parameters
    are re-estimated. No additional outliers are automatically identified and estimated. This
    is the default setting.

    If `outlier=:remove`, those outlier regressors that were added to the regression part of
    the regARIMA model when automatic outlier identification was performed on the full
    series are removed from the regARIMA model during the revisions history analysis.
    Consequently, their effects are not estimated and removed from the series. This option
    gives the user a way to investigate the consequences of not doing automatic outlier
    identification.

    If `outlier=:auto`, among outliers automatically identified for the full series, only those
    that fall in the time period up to `outlierwin` observations before the starting date of the
    revisions history analysis are automatically included in the regARIMA model. In each
    run of the estimation procedure with a truncated version of the original series, automatic
    outlier identification is performed only for the last `outlierwin`+1 observations. An outlier
    that is identified is used for the current run, but is only retained for the subsequent runs
    of the historical analysis if it is at least `outlierwin` observations from the end of the
    subsequent span of data being analyzed.

* **outlierwin** (Int64) - Specifies how many observations before the end of each span will be used for outlier
    identification during the revisions history analysis. The default is 12 for monthly series
    and 4 for quarterly series. This argument has an effect only if the `outlier` spec is used,
    and if `outlier=:auto` in the `history` spec.

* **refresh** (Bool) - Specifies which of two sets of initializing values is used for the regARIMA model 
    parameter estimation. If `refresh=true`, the parameter estimates from the last model evaluation
    are used as starting values for the current regARIMA model estimation done during
    the revisions history. If `refresh=false`, then the initial values of the regARIMA model
    parameters will be set to the estimates derived from the entire series. The default is
    `refresh=false`.

* **transformfcst** (Bool) - Specifies whether the forecast error output of the history analysis is for forecasts of
    the original data (`transformfcst = false`) or for the forecasts of the transformed data
    specified by the transform spec (`transformfcst = true`). See Details. The default is
    `transformfcst = false`.

* **x11outlier** (Bool) - Specifies whether the AO outlier identification will be performed during the history analysis
    for all irregular component regressions that result from the x11regression spec. If
    `x11outlier=true`, AO outlier identification will be performed for each of the history runs.
    Those AO outlier regressors that were added to the irregular component regression model
    when automatic AO outlier identification was done for the full series are removed from the
    irregular component regression model prior to the history runs. If `x11outlier=false`, then
    the AO outlier regressors automatically identified are kept for each of the history runs. If
    the date of an outlier detected for the complete span of data does not occur in the data
    span of one of the history runs, the outlier will be dropped from the model for that run.
    The coefficients estimating the effects of these AO outliers are re-estimated whenever the
    other irregular component regression model parameters are re-estimated. However, no
    additional AO outliers are automatically identified and estimated. This option is ignored
    if the x11regression spec is not used, if the selection of the aictest argument results
    in the program not estimating an irregular component regression model, or if the sigma
    argument is used in the x11regression spec. The default is `x11outlier=true`.
    


"""
function history(; 
    endtable::Union{MIT,X13default}=_X13default,
    estimates::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    fixmdl::Union{Bool,X13default}=_X13default,
    fixreg::Union{Bool,X13default}=_X13default,
    fstep::Union{Int64,Vector{Int64},X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default} =_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default} =[:alldiagnostics],
    sadjlags::Union{Int64,Vector{Int64},X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    target::Union{Symbol,X13default}=_X13default,
    trendlags::Union{Int64,Vector{Int64},X13default}=_X13default,
    fixx11reg::Union{Bool,X13default}=_X13default,
    outlier::Union{Symbol,X13default}=_X13default,
    outlierwin::Union{Int64,X13default}=_X13default,
    refresh::Union{Bool,X13default}=_X13default,
    transformfcst::Union{Bool,X13default}=_X13default,
    x11outlier::Union{Bool,X13default}=_X13default,
) 
    # checks and logic
    if fstep isa Vector{Int64}
        if length(fstep) > 4
            throw(ArgumentError("fstep can contain up to four forecast leads. Received: $(fstep)."))
        end
        if any(fstep .< 1)
            throw(ArgumentError("fstep values cannot be less than one. Received: $(fstep)."))
        end
    elseif fstep isa Int64 && fstep < 1
        throw(ArgumentError("fstep cannot be less than one. Received: $(fstep)."))
    end

    if sadjlags isa Vector{Int64}
        if length(sadjlags) > 5
            throw(ArgumentError("sadjlags can contain up to five revision lags. Received: $(sadjlags)."))
        end
        if any(sadjlags .< 1)
            throw(ArgumentError("sadjlags values cannot be less than one. Received: $(sadjlags)."))
        end
    elseif fstep isa Int64 && fstep < 1
        throw(ArgumentError("sadjlags cannot be less than one. Received: $(sadjlags)."))
    end

    _print_all = [:header, :outlierhistory, :sarevisions, :sasummary, :chngrevisions, :chngsummary, :indsarevisions, :indsasummary, :trendrevisions, :trendsummary, :trendchngrevisions, :trendchngsummary, :sfrevisions, :sfsummary, :lkhdhistory, :fcsterrors, :armahistory, :tdhistory, :sfilterhistory, :saestimates, :chngestimates, :indsaestimates, :trendestimates, :trendchngestimates, :sfestimates, :fcsthistory]
    _save_all = [:outlierhistory, :sarevisions, :chngrevisions, :indsarevisions, :trendrevisions, :trendchngrevisions, :sfrevisions, :lkhdhistory, :fcsterrors, :armahistory, :tdhistory, :sfilterhistory, :saestimates, :chngestimates, :indsaestimates, :trendestimates, :trendchngestimates, :sfestimates, :fcsthistory]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13history(endtable,estimates,fixmdl,fixreg,fstep,print,save,savelog,sadjlags,start,target,trendlags,fixx11reg,outlier,outlierwin,refresh,transformfcst,x11outlier)
end
history!(spec::X13spec{F}; kwargs...) where F = (spec.history = history(; kwargs...); spec)

"""
`identify(; kwargs...)`

`identify!(spec::X13spec{F}; kwargs...)`

Specification to produce tables and line printer plots of sample ACFs and PACFs for identifying the ARIMA
    part of a regARIMA model. Sample ACFs and PACFs are produced for all combinations of the nonseasonal and
    seasonal differences of the data specified by the `diff` and `sdiff` arguments. If the `regression` spec is present, the
    ACFs and PACFs are calculated for the specified differences of a series of regression residuals. If the `regression`
    spec is not present, the ACFs and PACFs are calculated for the specified differences of the original data.
    
### Main keyword arguments:

* **diff** (Vector{Int64}) - Orders of nonseasonal differencing specified. The value 0 specifies no differencing, the
    value 1 specifies one nonseasonal difference (1 − B), the value 2 specifies two nonseasonal differences (1−B)^2, 
    etc. The specified ACFs and PACFs will be produced for all orders of
    nonseasonal differencing specified, in combination with all orders of seasonal differencing
    specified in `sdiff`. The default is `diff=[0]`.

* **maxlag** (Int64) - The number of lags specified for the ACFs and PACFs for both tables and plots. The
    default is 36 for monthly series, 12 for quarterly series.

* **sdiff** (Vector{Int64}) - Orders of seasonal differencing specified. The value 0 specifies no seasonal differencing,
    the value 1 specifies one seasonal difference (1−B_s)), etc. The specified ACFs and PACFs
    will be produced for all orders of seasonal differencing specified, in combination with all
    orders of nonseasonal differencing specified in diff. The default is `sdiff=[0]`.

"""
function identify(; 
    diff::Union{Vector{Int64},X13default}=_X13default,
    sdiff::Union{Vector{Int64},X13default}=_X13default,
    maxlag::Union{Int64,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
)
    # checks and logic

    _print_all = [:acf, :acfplot, :pacf, :pacfplot, :regcoefficients]
    _save_all = [:acf, :pacf]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13identify(diff,sdiff,maxlag,print,save)
end
identify!(spec::X13spec{F}; kwargs...) where F = (spec.identify = identify(; kwargs...); spec)

"""
`metadata(entries::Union{Pair{String,String}, Vector{Pair{String,String}}})`

`metadata!(spec::X13spec{F}, entries::Union{Pair{String,String}, Vector{Pair{String,String}}})`

Specification that allows users to insert metadata into the diagnostic summary file. Users can specify keys and
corresponding values for those keys to insert additional information into the diagnostic summary file stored by
X-13ARIMA-SEATS. The only argument is entries:
    
* **entries** (Pair{String,String} or Vector{Pair{String,String}}) - A Pair{String,String} or vector of such pairs.
    Up to 20 key-value paris can can be specified - no single key or value can be more than 132 characters
    long, and all the keys taken together, or all values taken together, cannot be exceed 2000 characters.
"""
function metadata(entries::Union{Pair{String,String}, Vector{Pair{String,String}}}
)
    if entries isa Pair{String,String}
        entries = [entries]
    end
    # checks and logic
    
    if length(entries) > 20
        throw(ArgumentError("A maximum of 20 metadata entries can be specified. Received: $(length(entries)) entries."))
    end
    keys_vector = [p[1] for p in entries]
    values_vector = [p[2] for p in entries]
    if any([length(k) > 132 for k in keys_vector])
        throw(ArgumentError("Keys in the metadata spec can have a maximum length of 132 characters."))
    end
    if length(join(keys_vector,"")) > 2000
        throw(ArgumentError("Keys in the metadata spec can have a maximum combined length of 2000 characters. Received: $(length(join(keys_vector,""))) characters."))
    end

    if any([length(k) > 132 for k in values_vector])
        throw(ArgumentError("Values in the metadata spec can have a maximum length of 132 characters."))
    end
    if length(join(values_vector,"")) > 2000
        throw(ArgumentError("Values in the metadata spec can have a maximum combined length of 2000 characters. Received: $(length(join(keys_vector,""))) characters."))
    end

    return X13metadata(entries)
end
metadata!(spec::X13spec{F}, entries::Union{Pair{String,String}, Vector{Pair{String,String}}}) where F = (spec.metadata = metadata(entries); spec)

"""
`outlier(; kwargs...)`

`outlier!(spec::X13spec{F}; kwargs...)`

Specification to perform automatic detection of additive (point) outliers, temporary change outliers, level shifts,
or any combination of the three using the specified model. After outliers (referring to any of the outlier types
mentioned above) have been identified, the appropriate regression variables are incorporated into the model
as “Automatically Identified Outliers”, and the model is re-estimated. This procedure is repeated until no
additional outliers are found. If two or more level shifts are detected (or are present in the model due to the
specification of level shift(s) in the `regression` spec), t-statistics can be computed to test null hypotheses that
each run of two or more successive level shifts cancels to form a temporary level shift.

### Main keyword arguments:

* **critical** (Float64 or Vector{Union{Float64,Missing}}) - Sets the value to which the absolute values of the outlier t-statistics are compared to
    detect outliers. The default critical value is determined by the number of observations
    in the interval searched for outliers (see the `span` argument below). It is obtained by a
    modification of the asymptotic formula of Ljung (1993) that interpolates critical values
    for numbers of observations between 3 and 99. Table 7.22 gives default critical values for
    various outlier span lengths.

    If only one value is given for this argument (`critical = [3.5]`), then this critical value is
    used for all types of outliers. If a vector of up to three values is given (`critical = [3.5,
    4.0, 4.0]`), then the critical value for additive outliers is set to the first entry (3.5
    in this case), the critical value for level shift outliers is set to the second entry
    (4.0), and the critical value for temporary change outliers is set to the third  entry
    (4.0). A missing value, as in `critical = [3.25,missing,3.25]`, is set to the default critical
    value. Raising the critical value decreases the sensitivity of the outlier detection routine,
    possibly decreasing the number of observations treated as outliers

* **lsrun** (Int64) - Compute t-statistics to test null hypotheses that each run of 2, . . . , lsrun successive level
    shifts cancels to form a temporary level shift. The t-statistics are computed as the sum
    of the estimated parameters for the level shifts in each run divided by the appropriate
    standard error. (See Otto and Bell 1993). Both automatically identified level shifts and
    level shifts specified in the `regression` spec are used in the tests. `lsrun` may be given
    values from 0 to 5; 0 and 1 request no computation of temporary level shift t-statistics.
    If the value specified for `lsrun` exceeds the total number of level shifts in the model
    following outlier detection, then lsrun is reset to this total. The default value for `lsrun`
    is 0, i.e., no temporary level shift t-statistics are computed. For details on handling temporary level shifts, see the manual.

* **method** (Symbol) - Determines how the program successively adds detected outliers to the model. The
    choices are `method = :addone` or `method = :addall`. See DETAILS for a description of
    these two methods. The default is `method = :addone`.

* **span** (UnitRange{MIT} or Span) - Specifies start and end dates of a span of the time series to be searched for outliers. The
    start and end dates of the span must both lie within the series and within the model
    span if one is specified by the modelspan argument of the series spec, and the start
    date must precede the end date. (If there is a span argument
    in the series spec, then, in the above remarks, replace the start and end dates of the
    series by the start and end dates of the span given in the series spec.)

    An X13.Span can also be used in this field, this is specified with two values with a value of missing,
    substituting for the beginning or ending of the provided series. Example: `X13.Span(1968M1,missing)`.

* **types** (Vector{Symbol}) - Specifies the types of outliers to detect. The choices are: `types = [:ao]`, detect additive
    outliers only; `types = [:ls]`, detect level shifts only; `types = [:tc]`, detect temporary change
    outliers only; `types = [:all]`, detect additive outliers, temporary change outliers, and level
    shifts simultaneously; or `types = [:none]`, turn off outlier detection (but not t-statistics for
    temporary level shifts). The default is `types = [:ao, :ls]`.


### Rarely used keyword arguments:

* **almost** (Float64) - Differential used to determine the critical value used for a set of ”almost” outliers -
    outliers with t-statistics near the outlier critical value that are not incorporated into the
    regARIMA model. After outlier identification, any outlier with a t-statistic larger than
    Critical - almost is considered an "almost outlier," and is included in a separate table.
    The default is `almost = 0.5`; values for this argument must always be greater than zero.

* **tcrate** (Float64) - Defines the rate of decay for the temporary change outlier regressor. This value must
    be a number greater than zero and less than one. The default value is `tcrate=0.7** (12/period)`, 
    where period is the number of observations in one year (12 for monthly
    time series, 4 for quarterly time series). This formula for the default value of tcrate
    ensures the same rate of decay over an entire year for series of different periodicity. If
    the frequency of the time series is less than 4 (ie, period < 4), then there is no default
    value, and the user will have to enter a value of tcrate if a temporary change outlier
    was specified in the variables argument of the regression spec, or if temporary change
    outliers are specified in the types argument of this spec. If this argument is specified in
    the regression spec, it is not necessary to include it in this spec.

"""
function outlier(; 
    critical::Union{Float64,Vector{Union{Float64,Missing}},Vector{Float64},X13default}=_X13default,
    lsrun::Union{Int64,X13default}=_X13default,
    method::Union{Symbol,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:identified,
    span::Union{UnitRange{<:MIT},Span,X13default}=_X13default,
    types::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    almost::Union{Float64,X13default}=_X13default,
    tcrate::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    if critical isa Vector
        if length(critical) > 3
            throw(ArgumentError("critical can contain up to three values. Received: $(critical)."))
        end
    end

    if !(lsrun isa X13default) && (lsrun < 0 || lsrun > 5)
        throw(ArgumentError("lsrun can take values from 0 to 5. Received: $(lsrun)."))
    end

    if !(almost isa X13default) && (almost  < 0.0)
        throw(ArgumentError("almost must have a value greater than zero. Received: $(almost)."))
    end

    if !(tcrate isa X13default) && (tcrate  <= 0.0 || tcrate >= 1.0)
        throw(ArgumentError("tcrate must be a number greater than zero and less than one. Received: $(tcrate)."))
    end

    if span isa X13.Span
        if span.e isa TimeSeriesEcon._FPConst || span.e isa UnionAll
            throw(ArgumentError("Spans with an fuzzy ending time, such as M11 or Q2, are not allowed in the span argument of the outlier spec. Please pass an MIT or `missing`. Received: $(span.e)."))
        end
    end

    _print_all = [:header, :iterations, :tests, :temporaryls, :finaltests]
    _save_all = [:iterations, :finaltests]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13outlier(critical,lsrun,method,print,save,savelog,span,types,almost,tcrate)
end
outlier!(spec::X13spec{F}; kwargs...) where F = (spec.outlier = outlier(; kwargs...); spec)

"""
`pickmdl(; kwargs...)`

`pickmdl!(spec::X13spec{F}; kwargs...)`
`pickmdl!(spec::X13spec{F}, models::Vector{ArimaModel}; kwargs...)`
`pickmdl!(spec::X13spec{F}, model::ArimaModel... ; kwargs...)`

Specifies that the ARIMA part of the regARIMA model will be sought using an automatic model selection
procedure similar to the one used by X-11-ARIMA/88 (see Dagum 1988). The user can specify which types
of models are to be fitted to the time series in the procedure and can change the thresholds for the selection
criteria.

### Positional arguments:

A vector or series of ArimaModel instances can be passed to the `pickmdl!` function. If present, these will be used in 
place of the "file" argument. Note that only one of the passed ArimaModels can have its `default` field set to `true`.

### Main keyword arguments:

* **bcstlim** (Int64) - Sets the acceptance threshold for the within-sample backcast error test when backcasts
    are specified by setting `mode=:both`. The absolute average percentage error of the backcasted values is then tested against the threshold. 
    For example, `bcstlim=25` sets this
    threshold to 25 percent. The value entered for this argument must not be less than zero,
    or greater than 100. The default is `bcstlim=20` percent.

* **fcstlim** (Int64) - Sets the acceptance threshold for the within-sample forecast error test. The absolute
    average percentage error of the extrapolated values within the last three years of data
    must be less than this value if a model is to be accepted by the pickmdl automatic
    modeling selection procedure. For example, `fcstlim=20` sets this threshold to 20 percent.
    The value entered for this argument must not be less than zero, or greater than 100. The
    default is `fcstlim=15` percent.

* **file** (String) - The full path to a file containing a series of Arima specifications. Please see the manual for details.

* **identify** (Symbol) - Determines how automatic identification of outliers (via the `outlier` spec) and/or 
    automatic trading day regressor identification (via the `aictest` argument of the `regression`
    spec) are done within the pickmdl automatic model selection procedure. If `identify = :all`, 
    automatic trading day regressor and/or automatic outlier identification (done in
    that order if both are specified) are done for each model specified in the automatic model
    file. If `identify = :first`, automatic trading day regressor and/or automatic outlier
    identification are done the first model specified in the automatic model file. 
    The decisions made for the first model specified are then used for the remaining models. The
    identification procedures are redone for the selected model, if the model selected is not
    the first. The default is `identify = :first`.

* **method** (Symbol) - Specifies whether the pickmdl automatic model selection procedure will select the first
    model which satisfies the model selection criteria (`method = :first`) or the estimated
    model with the lowest within-sample forecast error of all the model which satisfies the
    model selection criteria (`method = :best`). The default is `method = :first`.

* **mode** (Symbol) - Specifies that the program will attempt to find a satisfactory model within the set of
    candidate model types specified by the user, using the criteria developed by Statistics
    Canada for the X-11-ARIMA program and documented in Dagum (1988); see DETAILS.
    The fitted model chosen will be used to produce a year of forecasts if `mode = :fcst`, or
    will produce a year of forecasts and backcasts if `mode = :both`. The default is `mode = :fcst`. 
    
    The `forecast` spec can be used to override the number of forecasts and backcasts
    used to extend the series. The model will be chosen from the types read in from a file
    named in the file argument (specified above). Do not use both `arima` and `pickmdl` in
    the same specification file.

* **outofsample** (Bool) - Determines which kind of forecast error is used for pickmdl automatic model evaluation
    and selection. If `outofsample=true`, out-of-sample forecasts errors are used; these are
    obtained by removing the data in the forecast period from the data set used to estimate
    the model and to produce one year of forecasts (for each of the last three years of data). If
    `outofsample=false`, within-sample forecasts errors are used. That is, the model parameter
    estimates for the full series are used to generate forecasts for each of the last three years
    of data. For conformity with X-11-ARIMA, outlier adjustments are made to the forecasted
    data that have been identified as outliers. The default is `outofsample=false`.

* **overdiff** (Float64) - Sets the threshold for the sum of the MA parameter estimates in the overdifferencing test.
    The program computes the sum of the seasonal (for models with at least one seasonal
    difference) or non-seasonal (for models with at least one non-seasonal difference) MA
    parameter estimates. If the sum of the non-seasonal MA parameter estimates is greater
    than the limit set here, the pickmdl automatic model selection procedure will reject the
    model because of overdifferencing. If the sum of the seasonal MA parameter estimates
    is greater than the limit set here, the pickmdl automatic model selection procedure will
    print out a warning message suggesting the use of fixed seasonal effects in the regression
    spec, but will not reject the model. The default for this argument is` overdiff=0.9`; values entered
    for this argument should not be any lower than 0.9, and must not be greater than 1.

* **qlim** (Int64) - Sets the acceptance threshold for the p-value of the Ljung-Box Q-statistic for model
    adequacy. The p-value associated with the fitted model’s Q must be greater than this
    value for a model to be accepted by the pickmdl automatic model selection procedure.
    For example, `qlim = 10` sets this threshold to 10 percent. The value entered for this
    argument must not be less than zero, or greater than 100. The default is `qlim = 5`
    percent.

"""
function pickmdl(models::Union{Vector{ArimaModel},X13default}; 
    bcstlim::Union{Int64,X13default}=_X13default,
    fcstlim::Union{Int64,X13default}=_X13default,
    identify::Union{Symbol,X13default}=_X13default,
    method::Union{Symbol,X13default}=_X13default,
    mode::Union{Symbol,X13default}=_X13default,
    outofsample::Union{Bool,X13default}=_X13default,
    overdiff::Union{Float64,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:automodel,
    qlim::Union{Int64,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
)
    # TODO: file argument MUST BE SPECIFIED
    # checks and logic
    if !(bcstlim isa X13default) && (bcstlim < 0 || bcstlim > 100)
        throw(ArgumentError("bcstlim must be a value between 0 and 100 (inclusive). Received: $(bcstlim)."))
    end
    if !(fcstlim isa X13default) && (fcstlim < 0 || fcstlim > 100)
        throw(ArgumentError("fcstlim must be a value between 0 and 100 (inclusive). Received: $(fcstlim)."))
    end
    if !(qlim isa X13default) && (qlim < 0 || qlim > 100)
        throw(ArgumentError("qlim must be a value between 0 and 100 (inclusive). Received: $(qlim)."))
    end
    if !(overdiff isa X13default) 
        if overdiff > 1.0
            throw(ArgumentError("overdiff must not be greater than 1. Received: $(overdiff)."))
        end
        if overdiff < 0.9
            throw(ArgumentError("overdiff should not be less than 0.9. Received: $(overdiff)."))
        end
    end

    if !(models isa X13default)
        if length(models) < 2
            throw(ArgumentError("pickmdl spec must be provided with at least two candidate models. Received: $(length(models)). $(models)"))
        end
        num_defaults = 0
        for m in models
            if m.default == true
                num_defaults += 1
            end
        end
        if num_defaults > 1
            throw(ArgumentError("pickmdl can only have one model specified as a default, but $(num_defaults) of the provided models are flagged as defaults."))
        end
    end

    _print_all = [:pickmdlchoice, :header, :usermodels]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (models isa X13default) && (file isa X13default)
        throw(ArgumentError("pickmdl spec must either be constructed with a vector of ArimaModels or with the file keyword argument specified."))
    end
    
    return X13pickmdl(bcstlim,fcstlim,models,identify,method,mode,outofsample,overdiff,print,savelog,qlim,file)
end
pickmdl(models::ArimaModel...; kwargs...) = pickmdl([models...]; kwargs...)
pickmdl(; kwargs...) = pickmdl(_X13default; kwargs...)

pickmdl!(spec::X13spec{F}, models::Vector{ArimaModel}; kwargs...) where F = (spec.pickmdl = pickmdl(models; kwargs...); spec)
pickmdl!(spec::X13spec{F}, models::ArimaModel...; kwargs...) where F = (spec.pickmdl = pickmdl([models...]; kwargs...); spec)
pickmdl!(spec::X13spec{F}; kwargs...) where F = (spec.pickmdl = pickmdl(; kwargs...); spec)


# pickmdl!(spec::X13spec{F}; kwargs...) where F = (spec.pickmdl = pickmdl(; kwargs...))

"""
`regression(; kwargs...)`

`regression!(spec::X13spec{F}; kwargs...)`

Specification for including regression variables in a regARIMA model, or for specifying regression variables
    whose effects are to be removed by the `identify` spec to aid ARIMA model identification. Predefined regression
    variables are selected with the `variables` argument. The available predefined variables provide regressors
    modeling a constant effect, fixed seasonality, trading-day and holiday variation, additive outliers, level shifts,
    and temporary changes or ramps. Change-of-regime regression variables can be specified for seasonal and
    trading-day regressors. User-defined regression variables can be added to the model with the `user` argument.
    Data for any user-defined variables must be supplied, either in the `data` argument. The `regression` spec can contain both predefined and user-defined regression
    variables.

### Main keyword arguments:

* **aicdiff** (Vector{Union{Float64,Missing}) - Defines the amount by which the AIC value (corrected for the length of the series, or
    AICC) of the model with the regressor(s) specified in the aictest argument must fall
    below the AICC of the model without these regressor(s) in order for the model with the
    regressors to be chosen. The default value is `aicdiff=[0.0]`.

    If only one value is given for this argument (`aicdiff = [3.5]`), then this critical value is
    used for all types of regressors. If a vector of up to four values is given (`aicdiff = [3.5,
    4.0, 4.0, 5.5]`), then the AIC difference for trading day regressors is set to the first
    entry (3.5 in this case), the AIC difference for length of month regressors is set to
    the second entry (4.0), the AIC difference for Easter regressors is set to the third
    entry (4.0), and the AIC difference for user-defined regressors is set to the fourth
    entry (5.5). A missing value, as in `aicdiff = [3.25,missing,3.25,missing]`, is set to the default
    critical value.

    For more information on how this option is used in conjunction with the aictest argument, see the manual.

* **aictest** (Symbol or Vector{Symbol}) - Specifies that an AIC-based selection will be used to determine if a given set of regression
    variables will be included with the regARIMA model specified. The only entries allowed
    for this variable are `:td`, `:tdnolpyear`, `:tdstock`, `:td1coef`, `:td1nolpyear`, `:tdstock1coef`,
    `:lom`, `:loq`, `:lpyear`, `:easter`, `:easterstock`, and `:user`. If a trading day model selection is
    specified, for example, then AIC values (with a correction for the length of the series,
    henceforth referred to as AICC) are derived for models with and without the specified
    trading day variable. By default, the model with smaller AICC is used to generate
    forecasts, identify outliers, etc. If more than one type of regressor is specified, the AIC-tests 
    are performed sequentially in this order: (a) trading day regressors, (b) length of
    month / length of quarter / leap year regressors, (c) Easter regressors, (d) user-defined
    regressors. If there are several variables of the same type (for example, several trading
    day regressors), then the aictest procedure is applied to them as a group. That is, either
    all variables of this type will be included in the final model or none. See DETAILS for
    more information on the testing procedure. If this option is not specified, no automatic
    AIC-based selection is performed.

* **chi2test** (Bool) - Specifies that Chi-squared statistics will be be used to determine if groups of user-defined
    holiday regressors will be kept in the regARIMA model. When `chi2test = true`, 
    Chi-squared statistics will be generated for all user-defined holiday regression groups, and
    those who which are not significant (at the level of the argument `chi2testcv`) are removed
    from the regARIMA model. The default is `chi2test = false`, where no testing is done.

* **chi2testcv** (Bool) - Sets the probability for the critical value used for the selection procedure in `chi2test`.
    The default is 0.01.

* **pvaictest** (Float64) - Probability for generating a critical value for any AIC tests specified in this spec. This
    probablity must be > 0.0 and < 1.0. Table 7.26 in the manual shows the critical value generated for
    different values of pvaictest and different values of ν, the difference in the number of
    parameters between two models.

    If this argument is not specified, the aicdiff argument is used to set the critical value
    for AIC testing.

* **testalleaster** (Bool) - Specifies if an extra regression model is evaluated when more than one Easter regressor
    is specified in the variables argument. When `testalleaster = true`, an additional
    regARIMA model is estimated which contains all the Easter regressors specified by the
    user in the variables argument. An AICC diagnostic is generated from this model,
    and used in the AIC-based testing procedure as well as the AICCs for model with and
    without the individual Easter regressors. The default is `testalleaster = false`, only the
    individual Easter regressors specified by the user are used in the AIC testing procedure.

* **tlimit** (Float64) - Sets the value to which the absolute values of the t-statistics of AO and LS sequence
    regressors are compared to retain those outliers in the regARIMA model. If this argument
    is not specified, AO and LS sequence regressors are not checked for significance.

* **usertype** (Symbol or Vector{Symbol}) - Assigns a type of model-estimated regression effect to each user-defined regression variable. 
    It causes the variable and its estimated effects to be used and be output in the
    same way as a predefined regressor of the same type. This option is useful when trying
    out alternatives to the regression effects provided by the program.
    The type of the user-defined regression effects can be defined as a constant (`:constant`),
    seasonal (`:seasonal`), trading day (`:td`), length-of-month (`:lom`), length-of-quarter (`:loq`),
    leap year (`:lpyear`), outlier (`:ao`, `:ls`, or `:so`), a user-defined transitory component for SEATS
    (`:transitory`) or other user-defined (`:user`) regression effects. In addition to these types,
    users can specify up to 5 different user-defined holidays (`:holiday`, `:holiday2`, `:holiday3`,
    `:holiday4`, and `:holiday5`). This gives the user flexibility in specifying more than one
    holiday, and the chi-squared statistic is generated separately for these user-defined holidays.
    One effect type can be specified for all the user-defined regression variables defined in the
    regression spec (`usertype=:td`), or each user-defined regression variable can be given its
    own type (`usertype=[:td, :td, :td, :td, :td, :td, :holiday, :user]`). Once a type other than
    user has been assigned to a user-defined variable, further specifications for the variable
    in other arguments, such as `aictest` or `noapply`, must use this type designation, not
    `user`. If this option is not specified, all user-defined variables have the type `:user`. See
    the manual for more information on assigning types to user-defined regressors.

* **variables** (Symbol, X13Var or Vector{Symbol,X13Var}) - List of predefined regression variables to be included in the model. Data values for
    these variables are calculated by the program, mostly as functions of the calendar. See the table below for the list 
    of pre-defined variables and the manual for additional details.
  

    variable          | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
    :-----------------| :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    `:const`          | Trend constant regression variable to allow for a nonzero overall mean for the differenced data.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    `:seasonal`       | Fixed seasonal effects parameterized via s−1 seasonal contrast variables (s = seasonal period). The resulting variables allow for month-to-month (or quarter-to-quarter, etc.) differences in level, but have no net effect on overall level. `:seasonal` cannot be used with `sincos()` and also not in models with seasonal differencing except as a partial change of regime variable (see DETAILS where additional change of regime options are described, as in Table 7.29 in the manual). Can be used as a regime change variable, example: `X13.seasonal(1983M1)`, `X13.seasonal(1983M1, :zerobefore)`, `X13.seasonal(1983M1, :zeroafter)`. See the manual for more details.                                                                                                          
    `sincos()`        | Fixed seasonal effects (for s = seasonal period) parameterized via trigonometric regression variables of the form sin(ωj t) and cos(ωj t) at seasonal frequencies ωj = (2πj/s) for 1 ≤ j ≤ s/2 (dropping sin(ωj t) ≡ 0 for j = s/2 for s even). Each frequency to be included must be specified, i.e., for monthly series `X13.sincos([1, 2, 3, 4, 5, 6])` includes all seasonal frequencies while `X13.sincos([1, 2, 3])` includes only the first three. `sincos()` cannot be used with seasonal or in models with seasonal differencing.                                                                                                                                                                                                                                                          
    `:td`             | Estimate monthly (or quarterly) flow trading-day effects by including the `:tdnolpyear` variables (see below) in the model, and by handling leap-year effects either by re-scaling (for transformed series) or by including the `:lpyear` regression variable (for untransformed series). `:td` can only be used for monthly or quarterly series, and cannot be used with `:tdnolpyear`, `:td1coef`, `:td1nolpyear`, `:lpyear`, `:lom`, `:loq`, `:tdstock`, or `:tdstock1coef`. If `:td` is specified, do not specify `adjust = :lpyear` or `adjust = :lom` (\`adjust = :loq\`) in the transform spec. Can be used as a regime change variable, example: `X13.td(1983M1)`, `X13.td(1983M1, :zerobefore)`, `X13.td(1983M1, :zeroafter)`. See the manual for more details.                     
    `:tdnoleapyear`   | Include the six day-of-week contrast variables (monthly and quarterly flow series only): (no. of Mondays) − (no. of Sundays), . . . , (no. of Saturdays) − (no. of Sundays). `:tdnolpyear` cannot be used with `:td`, `:td1coef`, `:td1nolpyear`, `:tdstock`, or `:tdstock1coef`. Can be used as a regime change variable, example: `X13.tdnolpyear(1983M1)`, `X13.tdnolpyear(1983M1, :zerobefore)`, `X13.tdnolpyear(1983M1, :zeroafter)`. See the manual for more details.                                                                                                                                                                                                                                                                                                                  
    `:td1coef`        | Estimate monthly (or quarterly) flow trading-day effects by including the `:td1nolpyear` variable (see below) in the model, and by handling leap-year effects either by re-scaling (for transformed series) or by including the `:lpyear` regression variable (for untransformed series). `:td1coef` can only be used for monthly or quarterly series, and cannot be used with `:td`, `:tdnolpyear`, `:td1nolpyear`, `:lpyear`, `:lom`, `:loq`, `:tdstock`, or `:tdstock1coef`. If `:td1coef` is specified, do not specify `adjust = :lpyear` or `adjust = :lom` (\`adjust = :loq\`) in the transform spec. Can be used as a regime change variable, example: `X13.td1coef(1983M1)`, `X13.td1coef(1983M1, :zerobefore)`, `X13.td1coef(1983M1, :zeroafter)`. See the manual for more details. 
    `:td1nolpyear`    | Include the weekday-weekend contrast variable (monthly and quarterly flow series only): (no. of weekdays) − 5 2 (no. of Saturdays and Sundays). `:td1nolpyear` cannot be used with `:td`, `:tdnolpyear`, `:td1coef`, `:tdstock`, or `:tdstock1coef`. Can be used as a regime change variable. Example: `X13.td1nolpyear(1983M1)`, `X13.td1nolpyear(1983M1, :zerobefore)`, `X13.td1nolpyear(1983M1, :zeroafter)`. See the manual for more details.                                                                                                                                                                                                                                                                                                                                            
    `:lpyear`         | Include a contrast variable for leap-year (monthly and quarterly flow series only): 0.75 for leap-year Februaries (first quarters), -0.25 for non-leap year Februaries (first quarters), 0.0 otherwise. `:lpyear` cannot be used with `:td`, `:td1coef`, `:tdstock`, or `:tdstock1coef`. Can be used as a regime change variable. Example: `X13.lpyear(1983M1)`, `X13.lpyear(1983M1, :zerobefore)`, `X13.lpyear(1983M1, :zeroafter)`. See the manual for more details.                                                                                                                                                                                                                                                                                                                       
    `:lom`            | Include length-of-month as a regression variable. If `:lom` is requested for a quarterly series, X-13ARIMA-SEATS uses `:loq` instead. Requesting `:lom` when s 6= 12 or 4 results in an error. `:lom` cannot be used with `:td`, `:td1coef`, `:tdstock`, or `:tdstock1coef`. Can be used as a regime change variable. Example: `X13.lom(1983M1)`, `X13.lom(1983M1, :zerobefore)`, `X13.lom(1983M1, :zeroafter)`. See the manual for more details.                                                                                                                                                                                                                                                                                                                                            
    `:loq`            | Include length-of-quarter as a regression variable. If `:loq` is requested for a monthly series, X-13ARIMA-SEATS uses `:lom` instead. The same restrictions that apply to `:lom` apply to `:loq`. Can be used as a regime change variable. Example: `X13.loq(1983M1)`, `X13.loq(1983M1, :zerobefore)`, `X13.loq(1983M1, :zeroafter)`. See the manual for more details.                                                                                                                                                                                                                                                                                                                                                                                                                      
    `tdstock(w)`      | Estimate day-of-week effects for inventories or other stocks reported for the w-th day of each month. The value w must be supplied and can range from 1 to 31. For any month of length less than the specified w, the tdstock variables are measured as of the end of the month. Use `X13.tdstock(31)` for end-of-month stock series. `tdstock` can be used only with monthly series and cannot be used with `tdstock1coef`, `:td`, `:tdnolpyear`, `:td1coef`, `:td1nolpyear`, `:lom`, or `:loq`.                                                                                                                                                                                                                                                                                                   
    `tdstock1coef(w)` | Estimate a constrained stock trading day effect for inventories or other stocks reported for the w-th day of each month. The value w must be supplied and can range from 1 to 31. For any month of length less than the specified w, the tdstock1coef variables are measured as of the end of the month. Use `X13.tdstock1coef(31)` for end-of-month stock series. `tdstock1coef` can be used only with monthly series and cannot be used with `tdstock1coef`, `:td`, `:tdnolpyear`, `:td1coef`, `:td1nolpyear`, `:lom`, or `:loq`.                                                                                                                                                                                                                                                                 
    `easter(w)`       | Easter holiday regression variable for monthly or quarterly flow data which assumes the level of daily activity changes on the w−th day before Easter and remains at the new level through the day before Easter. This value w must be supplied and can range from 1 to 25. A user can also specify an `X13.easter(0)` regression variable, that assumes the daily activity level changes on Easter Sunday only. To estimate complex effects, several of these variables, differing in their choices of w, can be specified.                                                                                                                                                                                                                                                                        
    `labor(w)`        | Labor Day holiday regression variable (monthly flow data only) that assumes the level of daily activity changes on the w−th day before Labor Day and remains at the new level until the day before Labor Day. The value w must be supplied and can range from 1 to 25. Example: `X13.labor(10).`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    `thanks(w)`       | Thanksgiving holiday regression variable (monthly flow data only) that assumes the level of daily activity changes on the w−th day before or after Thanksgiving and remains at the new level until December 24. The value w must be supplied and can range from −8 to 17. Values of w < 0 indicate a number of days after Thanksgiving; values of w > 0 indicate a number of days before Thanksgiving. Example: `X13.thanks(-5)`.                                                                                                                                                                                                                                                                                                                                                                   
    `sceaster(w)`     | Statistics Canada Easter holiday regression variable (monthly or quarterly flow data only) assumes that the level of daily activity changes on the (w − 1)−th day and remains at the new level through Easter day. The value w must be supplied and can range from 1 to 24. To estimate complex effects, several of these variables, differing in their choices of w, can be specified. Example: `X13.sceaster(5)`.                                                                                                                                                                                                                                                                                                                                                                                 
    `easterstock(w)`  | End of month stock Easter holiday regression variable for monthly or quarterly stock data. This regressor is generated from the `easter(w)` regressors. The value w must be supplied and can range from 1 to 25. To estimate complex effects, several of these variables, differing in their choices of w, can be specified. Example: `X13.easterstock(10)`.                                                                                                                                                                                                                                                                                                                                                                                                                                        
    `ao(mit)`         | Additive (point) outlier variable, AO, for the given date. More than one AO may be specified. All specified outlier dates must occur within the series. (AOs with dates within the series but outside the span specified by the `span` argument of the `series` spec are ignored). Example: `X13.ao(1983M1)`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
    `aos(mit1,mit2)`  | Specifies a sequence of additive (point) outlier variable, AO, for the given range of dates or observation numbers. Sequence AO outliers begin and end on a given date, e.g., `X13.aos(2008M4,2008M10)`. More than one AOS may be specified, though the spans should not overlap. All specified outlier dates must occur within the series. (AOSs with dates within the series but outside the span specified by the `span` argument of the `series` spec are ignored.)                                                                                                                                                                                                                                                                                                                             
    `ls(mit)`         | Regression variable for a constant level shift (in the transformed series) beginning on the given date, e.g., `X13.ls(1990M10)`for a level shift beginning in October 1990. More than one level shift may be specified. Dates are specified as for AOs and the same restrictions apply with one addition: level shifts cannot be specified to occur on the start date of the series (or of the span specified by the `span` argument of the `series` spec).                                                                                                                                                                                                                                                                                                                                         
    `lss(mit1,mit2)`  | Specifies a sequence of level shift outlier variable, AO, for the given range of dates or observation numbers. Sequence LS outlers begin and end on a given date, e.g., `X13.ss(2008M6,2008M11)`. More than one LSS may be specified, though the spans should not overlap. All specified outlier dates must occur within the series. (LSSs with dates within the series but outside the span specified by the `span` argument of the `series` spec are ignored.)                                                                                                                                                                                                                                                                                                                                    
    `tc(mit)`         | Regression variable for a temporary level change (in the transformed series) beginning on the given date, e.g., `X13.tc(1990M10)` for a temporary change beginning in October 1990. More than one temporary change may be specified. Dates are specified as for AOs, and the same restrictions apply.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
    `so(mit)`         | Regression variable for a seasonal outlier (in the transformed series) beginning on the given date, e.g., `X13.so(1990M10)` for a seasonal outlier beginning in October 1990. More than one seasonal outlier may be specified. Dates are specified as for AOs, and the same restrictions apply with one addition: seasonal level shifts cannot be specified to occur on the start date of the series (or of the span specified by the `span` argument of the `series` spec).                                                                                                                                                                                                                                                                                                                        
    `rp(mit1,mit2)`   | Ramp effect which begins and ends on the given dates, e.g., `X13.rp(1988M4,1990M10)`. More than one ramp effect may be specified. All dates of the ramps must occur within the series. (Ramps specified within the series but with both start and end dates outside the span specified by the `span` argument of the `series` spec are ignored.) Ramps can overlap other ramps, TLs, AOs, and level shifts.                                                                                                                                                                                                                                                                                                                                                                                         
    `qd(mit1,mit2)`   | Quadratic ramp effect which begins and ends on the given dates, e.g., `X13.qd(1998M4,2000M10)`. More than one ramp effect may be specified. All dates of the ramps must occur within the series. (Ramps specified within the series but with both start and end dates outside the span specified by the `span` argument of the `series` spec are ignored.) Quadratic ramps can overlap other ramps, TLs, AOs, and level shifts.                                                                                                                                                                                                                                                                                                                                                                     
    `qi(mit1,mit2)`   | Quadratic ramp effect which begins and ends on the given dates, e.g., `X13.qi(2010M4,2011M10)`. More than one ramp effect may be specified. All dates of the ramps must occur within the series. (Ramps specified within the series but with both start and end dates outside the span specified by the `span` argument of the `series` spec are ignored.) Quadratic ramps can overlap other ramps, TLs, AOs, and level shifts.                                                                                                                                                                                                                                                                                                                                                                     
    `tl(mit1,mit2)`   | Temporary level change effect which begins and ends on the given dates, e.g., `X13.tl(1988M4,1990M10)`. More than one temporary level shift effect may be specified. All dates of the temporary level shift regressor must occur within the series. (Temporary level shifts specified within the series but with start or end dates outside the span specified by the `span` argument of the `series` spec are ignored.) Temporary level shifts can overlap other TLs, ramps, AOs, and level shifts.                                                                                                                                                                                                                                                                                                
    

        
### Rarely used keyword arguments:

* **b** (Vector{Float64}) - Specifies initial values for regression parameters in the order that they appear in the
    `variables` and `user` arguments. If present, the `b` argument must assign initial values
    to _all_ regression coefficients in the regARIMA model, and must appear in the spec file
    after the `variables` and `user` arguments. Initial values are assigned to parameters
    either by specifying the value in the argument list or by explicitly indicating that it is
    missing as in the example below. Missing values take on their default value of 0.1. For
    example, for a model with two regressors, `b=[0.7, missing]` is equivalent to `b=[0.7,0.1]`, but
    `b=[0.7]` is not allowed. For a model with three regressors, `b=[0.8,missing,-0.4]` is equivalent
    to `b=[0.8,0.1,-0.4]`. To hold a parameter fixed at a specified value, use the `fixb` argument.

* **centeruser** (Symbol) - Specifies the removal of the (sample) mean or the seasonal means from the user-defined
    regression variables. If `centeruser=:mean`, the mean of each user-defined regressor is
    subtracted from the regressor. If `centeruser=:seasonal`, means for each calendar month
    (or quarter) are subtracted from each of the user-defined regressors. If this option is
    not specified, the user-defined regressors are assumed to already be in an appropriately
    centered form and are not modified.

* **eastermeans** (Bool) - Specifies whether long term (500 year) monthly means are used to remove seasonality from
    the Easter regressor associated with the variable `Symbol("easter[w]")`, as described in footnote 5
    of Table 4.1 (`eastermeans=true`), or, instead, monthly means calculated from the span of
    data used for the calculation of the coefficients of the Easter regressors (`eastermeans=false`).
    The default is `eastermeans=true`. This argument is ignored if no built-in Easter regressor
    is included in the regression model, or if the only Easter regressor is `Symbol("sceaster[w]").

* **fixb** (Vector{Bool}) - A vector of `true`/`false` entries corresponding to the entries in the `b` vector.
    `true` entries will be held fixed.

* **noapply** (Symbol) - List of the types of regression effects defined in the regression spec whose 
    model-estimated values are *not* to be removed from the original series before the seasonal
    adjustment calculations specified by the `x11` spec are performed.
    Applicable types are all modelled trading day effects (`td`), Easter, Labor Day, and
    Thanksgiving-Christmas holiday effects (`:holiday`), point outliers (`:ao`), level changes and
    ramps (`:ls`), temporary changes (`:tc`), seasonal outliers (`:so`), user-defined seasonal regression 
    effects (`:userseasonal`), and the set of user-defined regression effects (`:user`).

* **tcrate** (Float64) - Defines the rate of decay for the temporary change outlier regressor. This value must be
    a number greater than zero and less than one. The default value is `tcrate=0.7^(12 / period)`, 
    where period is the number of observations in one year (for monthly time
    series, 4 for quarterly time series. This formula for the default value of tcrate ensures the
    same rate of decay over an entire year for series of different periodicity. If the frequency
    of the time series is less than 4 (ie, period < 4), then there is no default value, and the
    user will have to enter a value of tcrate if a temporary change outlier was specified in
    the variables argument

"""
function regression(; 
    aicdiff::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default}=_X13default,
    aictest::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    chi2test::Union{Bool,X13default}=_X13default,
    chi2testcv::Union{Float64,X13default}=_X13default,
    data::Union{MVTSeries, X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=[:aictest, :chi2test],
    pvaictest::Union{Float64,X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    testalleaster::Union{Bool,X13default}=_X13default,
    tlimit::Union{Float64,X13default}=_X13default,
    user::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    usertype::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    variables::Union{Symbol,X13var,Vector{<:Union{Symbol,X13var,Any}},X13default}=_X13default,
    b::Union{Vector{Float64},X13default}=_X13default,
    fixb::Union{Vector{Bool},X13default}=_X13default,
    centeruser::Union{Symbol,X13default}=_X13default,
    eastermeans::Union{Bool,X13default}=_X13default,
    noapply::Union{Symbol,X13default}=_X13default,
    tcrate::Union{Float64,X13default}=_X13default,
)
   
    # derivations
    start = _X13default
    user = _X13default
    if !(data isa X13default)
        start = first(rangeof(data))
        user = collect(colnames(data))
        if length(user) == 1
            user = user[1]
        end
    end

    # ensure correct type of variables
    _variables = X13default()
    if !(variables isa X13default)
        if variables isa Vector
            _variables = Vector{Union{Symbol,X13var}}()
            for var in variables
                push!(_variables, var)
            end
        else
            _variables = variables
        end
    end

    # checks and logic
    if !(aicdiff isa X13default) && !(pvaictest isa X13default)
        throw(ArgumentError("The aicdiff argument cannot be used in the same regression spec as the pvaictest argument."))
    end

    if !(usertype isa X13default)
        if !(user isa X13default) && usertype isa Vector{Symbol} && user isa Vector{Symbol}
            if length(usertype) > 1 && (length(usertype) != length(user))
                throw(ArgumentError("The usertype argument must have the same length as the number of user series provided ($(length(user))) when more than a single type is specified. Received: $(usertype)"))
            end
        end
        usertype_allowed_values = (:constant, :seasonal, :td, :lom, :loq, :lpyear, :ao, :ls, :so, :transitory, :user, :holiday, :holiday2, :holiday3, :holiday4, :holiday5)
        if usertype isa Vector{Symbol} && length(filter(x -> x  ∉ usertype_allowed_values, usertype)) > 0
            throw(ArgumentError("The usertype argument can only have the following values: $(usertype_allowed_values). \n\nReceived: $(usertype)"))
        elseif usertype isa Symbol && usertype ∉ usertype_allowed_values
            throw(ArgumentError("The usertype argument can only have the following values: $(usertype_allowed_values). \n\nReceived: $(usertype)"))
        end
    end

    #TODO: enforce correct length of b?
    if !(variables isa X13default)
        vars = variables isa Vector ? variables : [variables]
        all_aos = Vector{UnitRange{<:MIT}}()
        all_lss = Vector{UnitRange{<:MIT}}()
        for v in vars
            if v isa tdstock && (v.n < 1 || v.n > 31)
                throw(ArgumentError("tdstock variables must have a value between 1 and 31 (inclusive). Received: $(v.n)."))
            end
            if v isa easter && (v.n < 0 || v.n > 25)
                throw(ArgumentError("easter variables must have a value between 1 and 25 (inclusive). Received: $(v.n)."))
            end
            if v isa labor && (v.n < 1 || v.n > 25)
                throw(ArgumentError("labor variables must have a value between 1 and 25 (inclusive). Received: $(v.n)."))
            end
            if v isa thank && (v.n < -8 || v.n > 17)
                throw(ArgumentError("labor variables must have a value between -8 and 17 (inclusive). Received: $(v.n)."))
            end
            if v isa sceaster && (v.n < 1 || v.n > 24)
                throw(ArgumentError("sceaster variables must have a value between 1 and 24 (inclusive). Received: $(v.n)."))
            end
            if v isa easterstock && (v.n < 1 || v.n > 25)
                throw(ArgumentError("easterstock variables must have a value between 1 and 25 (inclusive). Received: $(v.n)."))
            end
            if v isa aos
                push!(all_aos, v.mit1:v.mit2)
            end
            if v isa lss
                push!(all_lss, v.mit1:v.mit2)
            end
        end
        for n1 in 1:length(all_aos)
            for n2 in 1:length(all_aos)
                if n1 !== n2 && length(intersect(all_aos[n1], all_aos[n2])) > 0
                    @warn "The variables spec has overlapping aos specifications: $(all_aos[n1]) and $(all_aos[n2])."
                end
            end
        end
        for n1 in 1:length(all_lss)
            for n2 in 1:length(all_lss)
                if n1 !== n2 &&length(intersect(all_lss[n1], all_lss[n2])) > 0
                    @warn "The variables spec has overlapping lss specifications: $(all_lss[n1]) and $(all_lss[n2])."
                end
            end
        end
    end

    allowed_aictest_values =  (:td, :tdnolpyear, :tdstock, :td1coef, :td1nolpyear, :tdstock1coef, :lom, :loq, :lpyear, :easter, :easterstock, :user)
    if aictest isa Symbol && aictest ∉ allowed_aictest_values
        throw(ArgumentError("aictest can only contain these entries: $(allowed_aictest_values). Received: $(aictest)."))
    elseif aictest isa Vector{Symbol} 
        if length(filter(a -> a ∈ allowed_aictest_values, aictest)) < length(aictest)
            throw(ArgumentError("aictest can only contain these entries: $(allowed_aictest_values). Received: $(aictest)."))
        end
    end

    _print_all = [:regressionmatrix, :aictest, :outlier, :aoutlier, :levelshift, :seasonaloutlier, :transitory, :temporarychange, :tradingday, :holiday, :regseasonal, :userdef, :chi2test, :dailyweights]
    _save_all = [:regressionmatrix, :outlier, :aoutlier, :levelshift, :seasonaloutlier, :transitory, :temporarychange, :tradingday, :holiday, :regseasonal, :userdef]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13regression(aicdiff,aictest,chi2test,chi2testcv,data,file,format,print,save,savelog,pvaictest,start,testalleaster,tlimit,user,usertype,_variables,b,fixb,centeruser,eastermeans,noapply,tcrate)
end
regression!(spec::X13spec{F}; kwargs...) where F = (spec.regression = regression(; kwargs...); spec)

"""
`seats(; kwargs...)`

`seats!(spec::X13spec{F}; kwargs...)`


An optional spec invoking the production of model based signal extraction using SEATS, a seasonal adjustment
program developed by Victor Gómez and Agustin Maravall at the Bank of Spain.

The user can set options which control ARIMA model estimation if done within the SEATS module (`epsiv`
and `maxit`), perform checks on the model submitted to the SEATS modules (`qmax`, `rmod` and `xl`). The user
can also choose options to decompose the trend-cycle into a long-term trend and a cycle component using the
modified Hodrick-Prescott filter (`hpcycle` and `hplan`)

### Main keyword arguments:

* **appendfcst** (Bool) - Determines if forecasts will be included in certain SEATS tables selected for storage with
    the save option. If `appendfcst=true`, then forecasted values will be stored with table s10.
    If `appendfcst=false`, no forecasts will be stored. The default is to not include forecasts.

* **finite** (Bool) - Sets level of seasonal decomposition diagnostic output. The default (`finite = false`) 
    produces filter and diagnostic output that are obtained from infinite (Wiener-Kolmogorov)
    filters and signal extraction error and revisions statistics are associated with semi-infinite
    or bi-infinite data. With `filter = true`, all of the filter output and most of the signal
    extraction error and revisions statistics are finite-sample quantities for the available data.

* **hpcycle** (Bool) - If `hpcycle = true`, then the program will decompose the trend-cycle into a long-term
    trend and a cycle component using the modified Hodrick-Prescott filter. The default
    is not to perform this decomposition (`hpcycle = false`). For more information on the
    Hodrick-Prescott filter, see Kaiser and Maravall (2001), Wikipedia Contributers (2015),
    and McElroy (2008a).

* **noadmiss** (Bool) - When `noadmiss=true`, if the model submitted to SEATS does not lead to an 
    admissible decomposition, it will be replaced with a decomposable model. Otherwise when
    `noadmiss=false`, no approximation is done in this case. The default is `noadmiss=false`.

* **printphtrf** (Bool) - When `printphtrf=true`, the program will produce output related to the transfer function
    and phase delay of the seasonal adjustment filter. Otherwise when `printphtrf=false`, no
    such output is produced. The default is `printphtrf=false`.

* **qmax** (Int64) - Sets a limit for the Ljung-Box Q statistic, which is used to determine if the model provided
    to the SEATS module is of acceptable quality. Default is `qmax=50`.

    When model coefficients are fixed in the arima or regression specs, it is often necessary
    to choose a larger value of qmax to keep SEATS from changing the model.


* **statseas** (Bool) - If `statseas=false`, the program will not accept a stationary seasonal model, and will change
    the seasonal part of the model to (0 1 1). If `statseas=true`, the program will accept a
    stationary seasonal model. The default is `statsea = true`.

* **tabtables** (Vector{Symbol}) - A list of seasonal adjustment components and series to be stored in a separate file with
    the extension .tbs. The list is entered as a text string with codes listed in the table below. 
    An example entry is `tabtables=[:xo,:n,:s,:p]`. Note that components can only be added - they cannot be
    removed as in the print argument. The default is tabtables=[:all].

    symbol  | Description of table                               
    :-------| :--------------------------------------------------
    `:all`  | all series                                         
    `:xo`   | original series                                    
    `:n`    | seasonally adjusted series                         
    `:s`    | seasonal factors                                   
    `:p`    | trend-cycle                                        
    `:u`    | irregular                                          
    `:c`    | transitory                                         
    `:cal`  | calendar                                           
    `:pa`   | preadjustment factor                               
    `:cy`   | cycle                                              
    `:ltp`  | long term trend                                    
    `:er`   | residuals                                          
    `:rg0`  | separate regression component                      
    `:rgsa` | regression component in seasonally adjusted series 
    `:stp`  | stochastic trend cycle                             
    `:stn`  | stochastic seasonally adjusted series              
    `:rtp`  | real time trend cycle                              
    `:rtsa` | real time seasonally adjusted series               


### Rarely used keyword arguments:

* **bias** (Int64) - Corrects for the bias that may occur in multiplicative decomposition when the period-to-period 
    changes are relatively large when compared to the overall mean. This argument
    should only be set when a log transformation is used.

    If `bias = 1`, a correction is made for the overall bias for the full length of the series and
    for the forecasting period. This is the default value.

    If `bias = -1`, a correction is made so that, for every year (including the forecasting period), 
    the annual average of the original series equals the annual average of the seasonally
    adjusted series, and also (very approximately) equals the annual average of the trend.

    If `bias = 0`, no bias correction is done. No other values are allowed.

* **epsiv** (Float64) - Convergence criteria for ARIMA estimation within the SEATS module; this is used when
    the SEATS module determines that a model should be changed or re-estimated. This
    should be a small positive number; the default is `epsiv=0.001`.

* **epsphi** (Int64) - When Phi(B) contains a complex root, it is allocated to the seasonal if its frequency
    differes from the seasonal fequencies by less than epsphi degrees. Otherwise, it goes to
    the cycle. The default is `epsphi=2`.

* **hplan** (Int64) - A parameter that is used to determine the modified Hodrick-Prescott filter. By default,
    the program will set this parameter automatically according to the seasonal period of
    the series. For more information on the Hodrick-Prescott filter, see Kaiser and Maravall
    (2001). Example `hplan = 1000`.

* **imean** (Bool) - Indicates if the series is to be mean-corrected (`imean = true`). The default is not to remove
    the mean from the series before signal extraction (`imean = false`)

* **maxit** (Int64) - Number of iterations allowed for ARIMA estimation within the SEATS module; should
    be a positive integer. Default is `maxit=20`.

* **rmod** (Float64) - Limit for the modulus of an AR root. If the modulus of an AR root is larger than rmod,
    the root is assigned to the trend; if the modulus of an AR root is smaller than rmod,
    the root is assigned to the cycle. The default value is `rmod=0.80`.

* **xl** (Float64) - When the modulus of an estimated root falls in the range (XL, 1), it is set to 1.00 if the
    root is in the AR polynomial. If the root is in the MA polynomial, it is set to `xl`. The
    default is `xl=0.99`.

"""
function seats(; 
    appendfcst::Union{Bool,X13default}=_X13default,
    finite::Union{Bool,X13default}=_X13default,
    hpcycle::Union{Bool,X13default}=_X13default,
    noadmiss::Union{Bool,X13default}=_X13default,
    out::Union{Int64,X13default}=0, #set an actual default here as we want to save the tables
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default, #set to nothing here because we want to save the tables...
    save::Union{Symbol,Vector{Symbol},X13default} =_X13default, # [:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:seriesfcstdecomp,:seasonaladjfcstdecomp,:transitoryfcstdecomp,:seasadjconst, :trendconst,:totaladjustment,:difforiginal,:diffseasonaladj,:difftrend,:seasonalsum, :cycle, :longtermtrend, :componentmodels,:filtersaconc,:filtersasym,:filtertrendconc,:filtertrendsym,:squaredgainsaconc,:squaredgainsasym,:squaredgaintrendconc,:squaredgaintrendsym,:timeshiftsaconc,:timeshifttrendconc,:wkendfilter,:seasonalpct,:irregularpct,:transitorypct,:adjustfacpct],
    savelog::Union{Symbol,Vector{Symbol},X13default} = [:seatsmodel,:x13model,:normalitytest,:overunderestimation,:totalssquarederror,:componentvariance,:concurrentesterror,:percentreductionse,:averageabsdiffannual,:seasonalsignif],
    printphtrf::Union{Bool,X13default}=_X13default,
    qmax::Union{Int64,X13default}=_X13default,
    statseas::Union{Bool,X13default}=_X13default,
    tabtables::Union{Vector{Symbol},X13default}=_X13default,
    bias::Union{Int64,X13default}=_X13default,
    epsiv::Union{Float64,X13default}=_X13default,
    epsphi::Union{Int64,X13default}=_X13default,
    hplan::Union{Int64,X13default}=_X13default,
    imean::Union{Bool,X13default}=_X13default,
    maxit::Union{Int64,X13default}=_X13default,
    rmod::Union{Float64,X13default}=_X13default,
    xl::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    if !(epsiv isa X13default) && epsiv <= 0.0
        throw(ArgumentError("epsiv should be a small positive number. Received: $(epsiv)."))
    end
    if !(hpcycle isa X13default) && !(hplan isa X13default) && hpcycle == false
        @warn "Hodrick-Prescott filters will be used even though hpcycle is $hpcycle because an hplan value has been specified."
    end
    # print = _X13default
    # save = _X13default # most likely there is a spec error here...: transitoryfcstdecomp
    # doesn't work: :seriesfcstdecomp, :seasonaladjfcstdecomp, :transitoryfcstdecomp, :trendconst, :totaladjustment
    # save = [:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:seasadjconst, :difforiginal,:diffseasonaladj,:difftrend,:seasonalsum, :cycle, :longtermtrend, :componentmodels,:filtersaconc,:filtersasym,:filtertrendconc,:filtertrendsym,:squaredgainsaconc,:squaredgainsasym,:squaredgaintrendconc,:squaredgaintrendsym,:timeshiftsaconc,:timeshifttrendconc,:wkendfilter,:seasonalpct,:irregularpct,:transitorypct,:adjustfacpct],
    # save = [:seasonalfcstdecomp,:seasadjconst, :difforiginal]#,:diffseasonaladj,:difftrend,:seasonalsum, :cycle, :longtermtrend, :componentmodels,:filtersaconc,:filtersasym,:filtertrendconc,:filtertrendsym,:squaredgainsaconc,:squaredgainsasym,:squaredgaintrendconc,:squaredgaintrendsym,:timeshiftsaconc,:timeshifttrendconc,:wkendfilter,:seasonalpct,:irregularpct,:transitorypct,:adjustfacpct]
    # out = _X13default #this one can be safely left at zero
    savelog = _X13default # setting all four to X13default makes it work...

    _save_all = [:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:ofd,:seasonaladjfcstdecomp,:transitoryfcstdecomp,:seasadjconst, :trendconst,:totaladjustment,:difforiginal,:diffseasonaladj,:difftrend,:seasonalsum, :cycle, :longtermtrend, :componentmodels,:filtersaconc,:filtersasym,:filtertrendconc,:filtertrendsym,:squaredgainsaconc,:squaredgainsasym,:squaredgaintrendconc,:squaredgaintrendsym,:timeshiftsaconc,:timeshifttrendconc,:wkendfilter,:seasonalpct,:irregularpct,:transitorypct,:adjustfacpct]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        @warn "The print=:all option is not available for the Seats spec."
        print = _X13default
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
        out = 0
    end

    return X13seats(appendfcst,finite,hpcycle,noadmiss,out,print,save,savelog,printphtrf,qmax,statseas,tabtables,bias,epsiv,epsphi,hplan,imean,maxit,rmod,xl)
end
seats!(spec::X13spec{F}; kwargs...) where F = (spec.seats = seats(; kwargs...); spec)

"""
`slidingspans(; kwargs...)`

`slidingspans!(spec::X13spec{F}; kwargs...)`


Optional spec providing sliding spans stability analysis. These compare different features of seasonal adjustment
output from overlapping subspans of the time series data. The user can specify options to control the starting
date for sliding spans comparisons (`start`), the length of the sliding spans (`length`), the threshold values determining 
sliding spans statistics (`cutseas`, `cuttd`, `cutchng`), how the values of the regARIMA model parameter
estimates will be obtained during the sliding spans seasonal adjustment runs (`fixmdl`), and whether regARIMA
automatic outlier identification is performed (`outlier`).

### Main keyword arguments:

* **cutchng** (Float64) - Threshold value for the month-to-month, quarter-to-quarter, or year-to-year percent
    changes in seasonally adjusted series. For a month (quarter) common to more than
    one span, if the maximum absolute difference of its period-to-period percent changes
    from the different spans exceeds the threshold value, then the month (quarter) is flagged
    as having an unreliable estimate for this period-to-period change. This value must be
    greater than 0; the default value is 3.0. Example: `cutchng=5.0`.

* **cutseas** (Float64) - Threshold value for the seasonal factors and seasonally adjusted series. For a month
    (quarter) common to more than one span, if the maximum absolute percent change of its
    estimated seasonal factors or adjustments from the different spans exceeds the threshold
    value, then this month’s (quarter’s) seasonal factor or adjustment is flagged as unreliable.
    This value must be greater than 0; the default value is 3.0. Example: `cutseas=5.0`.

* **cuttd** (Float64) - Threshold value for the trading day factors. For a month (quarter) common to more than
    one span, if the maximum absolute percent change of its estimated trading day factors
    from the different spans exceeds the threshold value, then this month's (quarter's) trading
    day factor is flagged as unreliable. This value must be greater than 0; the default value
    is 2.0. Example: `cuttd=1.0`.

* **fixmdl** (Bool or Symbol) - Specifies how the initial values for parameters estimated in regARIMA models are to be
    reset before seasonally adjusting a sliding span. This argument is ignored if a regARIMA
    model is not fit to the series.

    If `fixmdl=true`, the values for the regARIMA model parameters for each span will be set
    to the parameter estimates taken from the original regARIMA model estimation. These
    parameters will be taken as fixed and not re-estimated. This is the default for fixmdl.
    
    If `fixmdl=false`, the program will restore the initial values to what they were when the
    regARIMA model estimation was done for the complete series. If they were fixed in the
    estimate spec, they remain fixed at the same values.
    
    If `fixmdl=:clear`, initial values for each span will be set to be the defaults, namely 0.1
    for all coefficients, and all model parameters will be re-estimated.

* **fixreg** (Vector{Symbol}) - Specifies the fixing of the coefficients of a regressor group in either a regARIMA model or
    an irregular component regression. These coefficients will be fixed at the values obtained
    from the model span (implicit or explicitly) indicated in the series or composite spec.
    All other regression coefficients will be re-estimated for each sliding span. Trading day
    (`:td`), holiday (`:holiday`), outlier (`:outlier`), or other user-defined (`:user`) regression effects
    can be fixed. This argument is ignored if neither a regARIMA model nor an irregular
    component regression is fit to the series, or if `fixmdl=true`.

* **length** (Int64) - The length of each span, in months or quarters (in accordance with the sampling interval)
    of time series data used to generate output for comparisons. A length selected by the
    user must yield a span greater than 3 years long and less or equal to 19 years long. If
    the length of the span is not specified by the user, the program will choose a span length
    based on the length of the seasonal filter selected by the user (or by the program if a
    seasonal filter was not specified by the user) when the seasonal adjustment is performed
    by the `x11` spec, or by the level of the seasonal MA parameter coefficient (Theta), when
    the seasonal adjustment is performed by the `seats` spec. For more information, see
    DETAILS. Monthly data example: `length=96`.

* **numspans** (Int64) - Number of sliding spans used to generate output for comparisons. The number of spans
    selected by the user must be between 2 and 4, inclusive. If this argument is not specified
    by the user, the program will choose the maximum number of spans (up to 4) that can
    be formed based on the length of the sliding spans given by the user (or selected by the
    program if the length argument is not used). Example: `numspans=4`.

* **outlier** (Symbol) - Specifies whether automatic outlier detection is to be performed whenever the regARIMA
    model is re-estimated during the processing of each span. This argument has no effect if
    the outlier spec is not used.

    If `outlier=:keep`, the program carries over any outliers automatically identified in the
    original estimation of the regARIMA model for the complete time series, and does not
    perform automatic outlier identification when a regARIMA model is estimated for one
    of the sliding spans. If the date of an outlier detected for the complete span of data does
    not occur in one of the sliding spans, the outlier will be dropped from the model for that
    span. This is the default setting.

    If `outlier=remove`, those outlier regressors that were added to the regression part of the
    regARIMA model when automatic outlier identification was performed on the full series
    are removed from the regARIMA model during the sliding spans analysis. Consequently,
    their effects are not estimated and removed from the series. If outlier terms are included
    in the regression spec, these will included in the model estimated for the spans. This
    option gives the user a way to investigate the consequences of not doing automatic outlier
    identification.

    If `outlier=yes`, the program performs automatic outlier identification whenever a regARIMA 
    model is estimated for a span of data.

* **start** (MIT) - The starting date for sliding spans comparisons. The default is the beginning month of
    the second span. Example: `start=1990M1`.


### Rarely used keyword arguments:

* **additivesa** (Symbol) - Specifies whether the sliding spans analysis of an additive seasonal adjustment will be
    calculated from the maximum differences of the seasonally adjusted series (`additivesa = difference`) 
    or from the maximum of an implied adjustment ratio of the original series
    to the final seasonally adjusted series (`additivesa = percent`). This option will also
    determine if differences (`additivesa = difference`) or percent changes (`additivesa = percent`) 
    are generated in the analysis of the month-to-month, quarter-to-quarter,
    or year-to-year changes in seasonally adjusted series. The default is `additivesa = difference`. 
    If the seasonally adjusted series for any of the spans contains values that are
    less than or equal to zero, the sliding spans analysis will be performed on the differences.

* **fixx11reg** (Bool) - Specifies whether the irregular component regression model will be re-estimated during
    the sliding spans analysis, if one is specified in the x11regression spec. If `fixx11reg=true`,
    the regression coefficients of the irregular component regression model are fixed throughout 
    the analysis at the values estimated from the entire series. If `fixx11reg=false`, the
    irregular component regression model parameters will be re-estimated for each span.
    The default is `fixx11reg=true`.

* **x11outlier** (Bool) - Specifies whether the AO outlier identification will be performed during the sliding spans
    analysis for the irregular component regression specified in the x11regression spec. If
    `x11outlier=true`, AO outlier identification will be done for each span. Those AO outlier
    regressors that were added to the irregular component regression model when automatic
    AO outlier identification was done for the full series are removed from the irregular
    component regression model prior to the sliding spans run. If `x11outlier=false`, then the
    automatically identified AO outlier regressors for the full series are kept for each sliding
    spans run. If the date of an AO outlier detected for the complete span of data does not
    occur in one of the sliding spans, the outlier will be dropped from the model for that span.
    The coefficients estimating the effects of these AO outliers are re-estimated whenever the
    other irregular component regression model parameters are re-estimated. However, no
    additional AO outliers are automatically identified and estimated. This option is ignored
    if the x11regression spec is not used, if the selection of the aictest argument results
    in the program not estimating an irregular component regression model, or if the sigma
    argument is used in the x11regression spec. The default is `x11outlier=true`.
        


"""
function slidingspans(; 
    cutchng::Union{Float64,X13default}=_X13default,
    cutseas::Union{Float64,X13default}=_X13default,
    cuttd::Union{Float64,X13default}=_X13default,
    fixmdl::Union{Bool,Symbol,X13default}=_X13default,
    fixreg::Union{Vector{Symbol},X13default}=_X13default,
    length::Union{Int64,X13default}=_X13default,
    numspans::Union{Int64,X13default}=_X13default,
    outlier::Union{Symbol,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:percents,
    start::Union{MIT,X13default}=_X13default,
    additivesa::Union{Symbol,X13default}=_X13default,
    fixx11reg::Union{Bool,X13default}=_X13default,
    x11outlier::Union{Bool,X13default}=_X13default,
)
    
    # checks and logic
    if !(fixmdl isa X13default) && !(fixreg isa X13default) && fixmdl == true
        @warn "fixreg will be ignored because fixmdl is set to true."
    end

    #TODO: yysummary in save arg
    _print_all = [:header, :ssftest, :factormeans, :percent, :summary, :yysummary, :indfactormeans, :indpercent, :indsummary,:yypercent, :sfspans, :chngspans, :saspans, :ychngspans, :tdspans,:indyypercent,:indyysummary,:indsfspans,:indchngspans,:indsaspans,:indychngspans]
    _save_all = [:sfspans, :chngspans, :saspans, :ychngspans, :tdspans,:indsfspans,:indchngspans,:indsaspans,:indychngspans]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13slidingspans(cutchng,cutseas,cuttd,fixmdl,fixreg,length,numspans,outlier,print,save,savelog,start,additivesa,fixx11reg,x11outlier)
end
slidingspans!(spec::X13spec{F}; kwargs...) where F = (spec.slidingspans = slidingspans(; kwargs...); spec)

"""
`spectrum(; kwargs...)`

`spectrum!(spec::X13spec{F}; kwargs...)`

Optional spec that provides a choice between two spectrum diagnostics to detect seasonality or trading day
effects in monthly series. Users can set the starting date of the span of data to be used to estimate the spectra
(`start`) and the type of spectrum estimate to be generated (`type`). For more information on the spectrum
diagnostic, see Section 6.1 of the manual.

In addition, the alternative QS statistic for detecting seasonality, applicable also to quarterly series, is
described here and its output is illustrated. There is also an option for generating the QS statistic for the
quarterly version of a monthly series

### Main keyword arguments:

* **logqs** (Bool) - Determines whether the log of the original series or seasonally adjusted series will be
    taken before the QS statistic is computed `logqs = true`. The default is `logqs = false`.

* **qcheck** (Bool) - Determines if the QS diagnostic will be generated for the quarertly version of a monthly
    series `qcheck = true` to check for quarterly seasonality. The default is `qcheck = false`.
    This argument only produced output for monthly time series.

* **start** (MIT) - The starting date of the span of data to be used to estimate the spectra the original,
    seasonally adjusted, and modified irregular series. This can be used to determine if there are residual trading
    day or seasonal effects in the adjusted data from, say, the last seven years. Residual effects
    can occur when seasonal or trading day patterns are evolving. The default starting date
    for the spectral plots is set to be 96 observations (8 years of monthly data) from the end
    of the series. If the span of data to be analyzed is less than 96 observations long, it is set
    to the starting date of this span of data. Example: `start=1987M1`.

* **tukey120** (Bool) - Determines whether the value of m used to generate the Tukey spectrum will be set to 120
    if the length of the series is greater than or equal to 120 (`tukey120 = true`). If `tukey120 = false`, 
    the length of the series is used to determine if the value of m will be 112 or 79. The
    default is `tukey120 = true`.


### Rarely used keyword arguments:

* **decibel** (Bool) - Determines whether spectral estimates will be expressed in terms of decibel units `decibel = true`, 
    as shown in equation (6.1) in the manual. The estimates are plotted on the untransformed scale
    if `decibel = false`. The default is `decibel = true`.

* **difference** (Bool or Symbol) - If `difference=false`, the spectrum of the (transformed) original series or seasonally 
    adjusted series is calculated; if `difference=:first`, the spectrum of the month-to-month
    differences of these series is calculated. The default (`difference=true`) will apply a
    max(d + D - 1, 1) difference to the (transformed) original series and seasonally adjusted
    series before computing the spectrum, where d is the order of regular differencing and D
    is the order of seasonal differencing in the regARIMA model specified for the series. If
    no regARIMA model is specified, the default order of differencing is 1.

* **maxar** (Int64) - An integer value used to set the maximum order of the AR spectrum used as the default
    type of spectrum plot. Integers from 1 to 30 are acceptable values for maxar. If this
    option is not specified, the maximum order will be set to 30.

* **peakwidth** (Int64) - Allows the user to set the width of the band used to determine spectral peaks. The
    default value is `peakwidth = 1`.

* **series** (Symbol) - Allows the user to select the series used in the spectrum of the original (or composite)
    series (Table G.0). The table below shows the series that can be specified with this argument. The default is `series = :adjoriginal`.

    Symbol                | Alternate symbol | Description of table                                                    
    :---------------------| :--------------- | :----------------------------------------------------------------------- 
    `:original`           | `:a1`            | original series                                                         
    `:outlieradjoriginal` | `:a19`           | original series, adjusted for regARIMA outliers                         
    `:adjoriginal`        | `:b1`            | original series, adjusted for user specified and regARIMA prior effects 
    `:modoriginal`        | `:e1`            | original series modified for extremes                                   

    Note that if the `x11` spec is not specified, the original series modified for extremes will
    not be generated; the setting series = modoriginal will be ignored, and the default
    setting will be used instead.

* **siglevel** (Int64) - Sets the significance level for detecting a peak in the spectral plots. The default is
    `siglevel = 6`.

* **type** (Symbol) - The type of spectral estimate used in the spectral plots output by the program. 
    If `type=:periodogram`, the periodogram of the series is calculated and plotted. The default
    (`type=:arspec`) produces an autoregressive model spectrum of the series.
        
        

"""
function spectrum(; 
    logqs::Union{Bool,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:alldiagnostics,
    qcheck::Union{Bool,X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    tukey120::Union{Bool,X13default}=_X13default,
    decibel::Union{Bool,X13default}=_X13default,
    difference::Union{Bool,Symbol,X13default}=_X13default,
    maxar::Union{Int64,X13default}=_X13default,
    peakwidth::Union{Int64,X13default}=_X13default,
    series::Union{Symbol,X13default}=_X13default,
    siglevel::Union{Int64,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
)
    # checks and logic
    # TODO: for some reason :tukeyspecorig, :tukeyspecsa,  :tukeyspecirr,:tukeyspecseatssa,:tukeyspecseatsirr,:tukeyspecextresiduals,:tukeyspecresidual,:tukeyspeccomposite,:tukeyspecindirr,:tukeyspecindsa are not available in save spec
    # save = [:specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa]# save::Union{Symbol,Vector{Symbol},X13default}
    # tukey120=true

    _print_all = [:qcheck, :qs, :specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa,:tukeypeaks]
    _save_all = [:specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13spectrum(logqs,print,save,savelog,qcheck,start,tukey120,decibel,difference,maxar,peakwidth,series,siglevel,type)
end
spectrum!(spec::X13spec{F}; kwargs...) where F = (spec.spectrum = spectrum(; kwargs...); spec)

"""
`transform(; kwargs...)`

`transform!(spec::X13spec{F}; kwargs...)`

Specification used to transform or adjust the series prior to estimating a regARIMA model. With this spec
the series can be Box-Cox (power) or logistically transformed, length-of-month adjusted, and divided by 
user-defined prior-adjustment factors. Data for any user-defined prior-adjustment factors must be supplied
in the `data` argument. For seasonal adjustment, a set of
permanently removed factors can be specified and also a set of factors that are temporarily removed until the
seasonal factors are calculated.

### Main keyword arguments:

* **adjust** (Symbol) - Perform length-of-month adjustment on monthly data (`adjust = :lom`), length-of-quarter 
    adjustment on quarterly data (`adjust = :loq`), or leap year adjustment of monthly
    or quarterly data (`adjust = :lpyear`). (See the manual.)

    Do not use the adjust argument if `:td` or `:td1coef` is specified in the `variables` argument
    of the `regression` or `x11regression` specs, or if additive or pseudo-additive seasonal
    adjustment is specified in the mode argument of the `x11` spec. Leap year adjustment
    (`adjust = :lpyear`) is only allowed when a log transformation is specified in either the
    `power` or `func` arguments.

* **aicdiff** (Float64) - Defines the difference in AICC needed to accept no transformation when the 
    automatic transformation selection option is invoked (`func=:auto`). The default value
    is `aicdiff = -2.0` for monthly and quarterly series, `aicdiff = 0.0` otherwise. For
    more information on how this option is used to select a transformation see the manual.

* **data** (TSeries or MVTSeries) - A TSeries or an MVTSeries containing two series of preadjustment factors which, 
    unless` mode=:diff` (see below), must have positive values intended for division into the corresponding values
    of the input time series. The default value is a vector of ones (no prior adjustment). When
    data is used, an adjustment factor must be supplied for every observation in
    the series (or for the span specified by the span argument of the series spec, if present).
    Generally, an adjustment factor must also be supplied for each forecast (and backcast)
    desired. (See the manual.)  When `mode = :diff`, the values in data are subtracted from the series, and they need not be positive.
    
    An MVTSeries with two series can supplied when both permanent and temporary
    prior-adjustment factors are specified in the type set - see the manual for more information.

* **func** (Symbol) - Transform the series Yt input in the series spec using a log, square root, inverse, or
    logistic transformation. Alternatively, perform an AIC-based selection to decide between
    a log transformation and no transformation (function=auto) using either the regARIMA
    model specified in the regression and arima specs or the airline model (0 1 1)(0 1 1) (see
    the manual). The default is no transformation (`func = :none`). Do not include both
    the function and power arguments. Note: there are restrictions on the values used in
    these arguments when preadjustment factors for seasonal adjustment are generated from
    a regARIMA model; see the manual.  
     
    Symbol      | Transformation            | Range for Yₜ            | Equivalent power argument 
    :-----------| :-------------------------| :----------------------| :-------------------------
    `:none`     | Yₜ                         | all values             | `power = 1`               
    `:log`      | log(Yₜ)                    | Yₜ > 0 for all t        | `power = 0`               
    `:sqrt`     | 1/4 + 2*(sqrt(Yₜ) - 1)     | Yₜ ≥ 0 for all t        | `power = 0.5`             
    `:inverse`  | 2 - 1/Yₜ                   | Yₜ ≠ 0 for all t        | `power = -1`              
    `:logistic` | log(Yₜ / (1 - Yₜ)           | 0 < Yₜ < 1 for all t   | no equivalent        

* **mode** (Symbol or Vector{Symbol}) - Specifies the way in which the user-defined prior adjustment factors will be applied to
    the time series. If prior adjustment factors to be divided into the series are not given
    as percents (e.g., [100, 100, 50, ...]), but rather as ratios (e.g., [1.0, 1.0, .5, ...]), set
    `mode=:ratio`. If the prior adjustments are to be subtracted from the original series, set
    `mode=:diff`. If `mode=:diff` is used when the mode of the seasonal adjustment is set to be
    multiplicative or log additive in the `x11` spec, the factors are assumed to be on the log
    scale. The factors will be exponentiated to put them on the same basis as the original
    series. If this argument is not specified, then the prior adjustment factors are assumed
    to be percents (`mode=:percent`). 

    If both permanent and temporary prior-adjustment factors are specified in the type
    argument, then up to two values can be specified for this argument, provided they are
    compatible (e.g., `diff` cannot be specified along with ratio or percent). See DETAILS
    for more information

* **power** (Float64) - Transform the input series Yₜ using a Box-Cox power transformation.
        
        Yₜ = λ^2 + (Yₜ^λ 0 1)/λ for λ ≠ 0
        Yₜ = log(Yₜ)  for λ = 0

    This formula for the Box-Cox power transformation is constructed so that its values will
    be close to Yₜ when λ is near 1 and close to log(Yₜ) when λ is near zero. It also has the
    property that the transformed value is positive when Yₜ is greater than 1.
    The power λ must be given (e.g., `power = .33`). The default is no transformation (λ =1), 
    i.e., `power = 1`. The log transformation (`power = 0`), square root transformation
    (`power = .5`), and the inverse transformation (`power = -1`) can alternatively be given
    using the `func` argument. Do not use both the `power` and the `func` arguments
    in the same spec file. 
    
    **Note:** there are restrictions on the values used in these arguments
    when preadjustment factors for seasonal adjustment are generated from a regARIMA
    model; see the manual.   
    
* **title** (String) - A title for the set of user-defined prior-adjustment factors. 
    The title must be enclosed in quotes and may contain up to 79 characters.

* **type** (Symbol or Vector{Symbol}) - Specifies whether the user-defined prior-adjustment factors are permanent 
    factors (removed from the final seasonally adjusted series as well as the original series) or temporary
    factors (removed from the original series for the purposes of generating seasonal factors
    but not from the final seasonally adjusted series). If only one value is given for this argument (`type = :temporary`), 
    then only one set of user-defined prior-adjustment factors
    will be expected. If both types of user-defined prior-adjustment factors are given (`type = [:temporary, :permanent]`), 
    then two sets of prior adjustment factors will be expected,
    for more information see the manual. The default is `type = :permanent`.

### Rarely used keyword arguments:

* **constant** (Float64) - Positive constant value that is added to the original series before the program models
    or seasonally adjusts the series. Once the program finishes modeling and/or seasonally
    adjusting the series with the constant value added, this constant is removed from the
    seasonally adjusted series as well as the trend component.

"""
function transform(; 
    adjust::Union{Symbol,X13default}=_X13default,
    aicdiff::Union{Float64,X13default}=_X13default,
    data::Union{TSeries,MVTSeries,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    func::Union{Symbol,X13default}=_X13default,
    mode::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    name::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    power::Union{Float64,X13default}=_X13default,
    precision::Union{Int64,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:autotransform,
    start::Union{MIT,Vector{MIT},X13default}=_X13default,
    title::Union{String,X13default}=_X13default,
    type::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    constant::Union{Float64,X13default}=_X13default,
    trimzero::Union{Bool,Symbol,X13default}=_X13default,
)
    # checks and logic
    start = _X13default
    name = _X13default
    if !(data isa X13default)
        start = first(rangeof(data))
        if data isa MVTSeries
            name = collect(colnames(data))
            if length(name) == 1
                name = name[1]
            end
        end
    end

    if !(func isa X13default) && !(power isa X13default)
        throw(ArgumentError("Either power or func can be specified, but not both."))
    end

    if !(adjust isa X13default) && adjust == :lpyear
        if !(power isa X13default) && power !== 0.0
            throw(ArgumentError("adjust can only be :lpyear when a log-transform (power=0.0) is specified."))
        elseif !(func isa X13default) && func !== :log
            throw(ArgumentError("adjust can only be :lpyear when a log-transform (func=:log) is specified."))
        end
    end

    if mode isa Vector{Symbol}
        if length(mode) > 2
            throw(ArgumentError("Only up to two values can be included in the mode argument. Received: $(length(mode))."))
        end
        if :diff ∈ mode && (:ratio ∈ mode || :percent ∈ mode)
            throw(ArgumentError("The :diff mode is not compatible with the :ratio or :percent modes. Received: $(mode)."))
        end
    end

    if title isa String && length(title) > 79
        @warn "Series title trunctated to 79 characters. Full title: $title"
        title = title[1:79]
    end

    if !(type isa X13default) 
        if data isa X13default
            throw(ArgumentError("A user-defined prior-adjustment type is specified, but not data has been provided."))
        end
        if data isa TSeries && type isa Vector{Symbol} && length(type) > 1
            throw(ArgumentError("The number of user-defined prior adjustment types provided ($(length(type))) must match the number of data series provided (1)."))
        elseif data isa MVTSeries && type isa Vector{Symbol} && length(type) !== length(columns(data))
            throw(ArgumentError("The number of user-defined prior adjustment types provided ($(length(type))) must match the number of data series provided ($(length(columns(data))))."))
        end
    end

    _print_all = [:aictransform, :seriesconstant, :seriesconstantplot, :prior, :permprior, :tempprior, :prioradjusted, :permprioradjusted, :prioradjustedptd, :permprioradjustedptd, :transformed]
    _save_all = [:seriesconstant, :prior, :permprior, :tempprior, :prioradjusted, :permprioradjusted, :prioradjustedptd, :permprioradjustedptd, :transformed]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13transform(adjust,aicdiff,data,file,format,func,mode,name,power,precision,print,save,savelog,start,title,type,constant,trimzero)
end
transform!(spec::X13spec{F}; kwargs...) where F = (spec.transform = transform(; kwargs...); spec)

"""
`x11(; kwargs...)`

`x11!(spec::X13spec{F}; kwargs...)`

An optional spec for invoking seasonal adjustment by an enhanced version of the methodology of the Census
Bureau X-11 and X-11Q programs. The user can control the type of seasonal adjustment decomposition 
calculated (`mode`), the seasonal and trend moving averages used (`seasonalma` and `trendma`), and the type of
extreme value adjustment performed during seasonal adjustment (`sigmalim`). The output options, specified
by print and save, include final tables and diagnostics for the X-11 seasonal adjustment method. In X-13-
ARIMA-SEATS, additional specs can be used to diagnose data and adjustment problems, to develop compensating
prior regression adjustments, and to extend the series by forecasts and backcasts. Such operations can result in
a modified series from which the X-11 procedures obtain better seasonal adjustment factors. For more details
on the X-11 seasonal adjustment diagnostics, see Shiskin, Young, and Musgrave (1967), Lothian and Morry
(1978), and Ladiray and Quenneville (2001). Trading day effect adjustments and other holiday adjustments can
be obtained from the `x11regression` spec.

### Main keyword arguments:

* **appendbcst** (Bool) - Determines if backcasts will be included in certain X-11 tables selected for storage with
    the save option. If `appendbcst=true`, then backcasted values will be stored with tables
    tables a16, b1, d10, d16, and h1. If `appendbcst=false`, no backcasts will be stored. The
    default is to not include backcasts.

* **appendfcst** (Bool) - Determines if forecasts will be included in certain X-11 tables selected for storage with
    the save option. If `appendfcst=true`, then forecasted values will be stored with tables
    a16, b1, d10, and d16. If `appendfcst=false`, no forecasts will be stored. The default is to
    not include forecasts.

* **final** (Symbol or Vector{Symbol}) - List of the types of prior adjustment factors, obtained from the regression and outlier
    specs, that are to be removed from the final seasonally adjusted series. Additive outliers
    (`final=:ao`), level change and ramp outliers (`final=:ls`), temporary change (`final=:tc`),
    and factors derived from user-defined regressors (`final=:user`) can be removed. If this
    option is not specified, the final seasonally adjusted series will contain these effects.

* **mode** (Symbol) - Determines the mode of the seasonal adjustment decomposition to be performed. There
    are four choices: (a) multiplicative (`mode=:mult`), (b) additive (`mode=:add`), (c) pseudo-additive 
    (`mode=:pseudoadd`), and (d) log-additive (`mode=:logadd`) decomposition. The
    default mode is `:mult`, unless the automatic transformation selection procedure is invoked
    in the transform spec; in the latter case, the mode will match the transformation selected
    for the series (`:mult` for the log transformation and `:add` for no transformation).

* **seasonalma** (Symbol or Vector{Symbol}) - Specifies which seasonal moving average (also called seasonal ”filter”) will be used to
    estimate the seasonal factors. These seasonal moving averages are n×m moving averages, meaning that 
    an n-term simple average is taken of a sequence of consecutive m-term simple averages.

    The seasonal filters shown in the table below can be selected for the entire series, or for
    a particular month or quarter. If the same moving average is used for all calendar
    months or quarters, only a single value need be entered. If different seasonal moving
    averages are desired for some calendar months or quarters, a list of these must be entered,
    specifying the desired seasonal moving average for each month or quarter. An example
    for a quarterly series is the following: `seasonalma=[:s3x3, :s3x9, :s3x9, :s3x9]`.
        
    If no seasonal moving average is specified, the program will choose the final seasonal filter
    automatically; this option can also be invoked by setting `seasonalma=:msr`. This is done
    using the moving seasonality ratio procedure of X-11-ARIMA/88, see the manual. This is a
    change from previous versions of X-11 and X-11-ARIMA where, when no seasonal moving
    average was specified, a 3×3 moving average was used to calculate the initial seasonal
    factors in each iteration, and a 3×5 moving average to calculate the final seasonal factors.
    This seasonal filtering sequence can be specified by entering `seasonalma=:x11default`.

    Symbol        | Description of option                                                                                                                                                                                                           |
    :-------------| :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
    `:s3x1`       | A 3×1 moving average.                                                                                                                                                                                                           
    `:s3x3`       | A 3×3 moving average.                                                                                                                                                                                                           
    `:s3x5`       | A 3×5 moving average.                                                                                                                                                                                                           
    `:s3x9`       | A 3×9 moving average.                                                                                                                                                                                                           
    `:s3x15`      | A 3×15 moving average.                                                                                                                                                                                                          
    `:stable`     | Stable seasonal filter. A single seasonal factor for each calendar month or quarter is generated by calculating the simple average of all the values for each month or quarter (taken after detrending and outlier adjustment). 
    `:x11default` | A 3×3 moving average is used to calculate the initial seasonal factors in each iteration, and a 3×5 moving average to calculate the final seasonal factors.                                                                     

* **sigmalim** (Vector{Union{Float64,Missing}}) - Specifies the lower and upper sigma limits used to downweigh extreme irregular values
    in the internal seasonal adjustment iterations. The sigmalim argument has two input values, 
    the lower and upper sigma limits. Valid list values are any real numbers
    greater than zero with the lower sigma limit less than the upper sigma limit (example:
    `sigmalim=[1.8, 2.8]`). A missing value defaults to 1.5 for the lower sigma limit and 2.5
    for the upper sigma limit. For example, the statement `sigmalim=[missing,3.0]` specifies that
    the upper sigma limit will be set to 3.0, while the lower sigma limit will remain at the
    1.5 default. For an explanation of
    how X-13ARIMA-SEATS uses these sigma limits to derive adjustments for extreme values,
    see the manual.

* **title** (String,Vector{String}) - Title of the seasonal adjustment, in quotes, for the convenience of the user. This can be
    a single title or a list of up to 8 titles. This list will be
    printed on the title page below the series title. There is no default seasonal adjustment
    title.

* **trendma** (Int64) - Specifies which Henderson moving average will be used to estimate the final trend-cycle.
    Any odd number greater than one and less than or equal to 101 can be specified. Example:
    `trendma=23`. If no selection is made, the program will select a trend moving average based
    on statistical characteristics of the data. For monthly series, either a 9-, 13- or 23-term
    Henderson moving average will be selected. For quarterly series, the program will choose
    either a 5- or a 7-term Henderson moving average.

* **type** (Symbol) - When `type=:summary`, the program develops estimates of the trend-cycle, irregular, and
    related diagnostics, along with residual seasonal factors and, optionally, also residual
    trading day and holiday factors from an input series which is assumed to be either already
    seasonally adjusted or nonseasonal. These residual factors are not removed. The output
    series in the final seasonally adjusted series (table D11) is the same as the original series
    (table A1). When `type=:trend`, the program develops estimates for the final trend-cycle
    and irregular components without attempting to estimate a seasonal component. The
    input series is assumed to be either already seasonally adjusted or nonseasonal. With this
    option, estimated trading day and holiday effects as well as permanent prior adjustment
    factors are removed to form the adjusted series (table D11) as well as for the calculation
    of the trend (table D12). When a metafile with a composite spec is used to obtain
    an indirect adjustment of an aggregate, these options are used for components of the
    aggregate that are not seasonally adjusted. In the default setting, `type=:sa`, the program
    calculates a seasonal decomposition of the series. With all three values of type, the final
    seasonally adjusted series (printed in the D11 table of the main output file) is used to
    form the indirect seasonal adjustment of the composite.

### Rarely used keyword arguments:

* **calendarsigma** (Symbol) - Specifies if the standard errors used for extreme value detection and adjustment 
    are computed separately for each calendar month (quarter), or separately for two complementary
    sets of calendar months (quarters). If `calendarsigma=:all`, the standard errors will be
    computed separately for each month (quarter). If `calendarsigma=:signif`, the standard
    errors will be computed separately for each month only if Cochran's hypothesis test determines that the 
    irregular component is heteroskedastic by calendar month (quarter).

    If `calendarsigma=:select`, the months (quarters) will be divided into two groups, and
    the standard error of each group will be computed. For the select option, the argument
    sigmavec must be used to define one of the two groups of months (quarters). If calendarsigma 
    is not specified, the standard errors will be computed from 5 year spans of
    irregulars, in the manner described in Dagum (1988).

* **centerseasonal** (Bool) - If `centerseasonal = true`, the program will center the seasonal factors combined with
    user-defined seasonal regression effects. The default is `centerseasonal = false`.

* **keepholiday** (Bool) - Determines if holiday effects estimated by the program are to be kept in the 
    final seasonally adjusted series. In the default setting, `keepholiday=false`, holiday adjustment
    factors derived from the program are removed from the final seasonally adjusted series.
    If `keepholiday=true`, holiday adjustment factors derived from the program are kept in
    the final seasonally adjusted series. The default is used to produce a series adjusted for
    both seasonal and holiday effects.

* **print1stpass** (Bool) - If `print1stpass=true`, output from the seasonal adjustment needed to generate the
    irregular components used for the irregular regression adjustment procedures will be
    printed out. If `print1stpass=false`, this output will be suppressed, and only the tables associated 
    with the irregular regression procedures are printed out. The default
    is `print1stpass=false`. When `print1stpass=true`, the `print` argument controls which tables are actually printed.

* **sfshort** (Bool) - Controls what seasonal filters are used to obtain the seasonal factors if the series is at
    most 5 years long. For the default case, `sfshort=false`, a stable seasonal filter will be
    used to calculate the seasonal factors, regardless of what is entered for the seasonalma
    argument. If `sfshort=true`, X-13ARIMA-SEATS will use the central and one sided seasonal
    filters associated with the choice given in the seasonalma argument wherever possible.

* **sigmavec** (Vector{TimeSeriesEcon._FPConst}) - Specifies one of the two groups of months (quarters) for whose irregulars a group standard 
    error will be calculated under the `calendarsigma=:select` option. The user enters the endings of 
    monthly or quarterly MITs, i.e. M1, M1, or Q1, Q2. Example: `sigmavec=[M1, M2, M12]`). 
    Warning: This argument can only be specified when `calendarsigma=:select`.

* **trendic** (Float64) - Specifies the irregular-to-trend variance ratio that will be used to generate the end weights
    for the Henderson moving average. The procedure is taken from Doherty (2001). If
    this variable is not specified, the value of `trendic` will depend on the length of the
    Henderson trend filter. These default values closely reproduce the end weights for the
    set of Henderson trend filters which originally appeared in X-11 and X-11-ARIMA.

* **true7term** (Bool) - Specifies the end weights used for the seven term Henderson filter. If 
    `true7term = true`, then the asymmetric ends weights for the 7 term Henderson filter are applied for
    observations at the end of the series where a central Henderson filter cannot be applied.
    If `true7term = false`, then central and asymmetric weights from a 5 term Henderson filter
    are applied, as in previous versions of the X-11-ARIMA program released by Statistics
    Canada. The default is `true7term = false`.

"""
function x11(; 
    appendbcst::Union{Bool,X13default}=_X13default,
    appendfcst::Union{Bool,X13default}=_X13default,
    final::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    mode::Union{Symbol,X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:alldiagnostics,
    seasonalma::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    sigmalim::Union{Vector{Union{Float64,Missing}},Vector{Float64},X13default}=_X13default,
    title::Union{String,Vector{String},X13default}=_X13default,
    trendma::Union{Int64,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
    calendarsigma::Union{Symbol,X13default}=_X13default,
    centerseasonal::Union{Bool,X13default}=_X13default,
    keepholiday::Union{Bool,X13default}=_X13default,
    print1stpass::Union{Bool,X13default}=_X13default,
    sfshort::Union{Bool,X13default}=_X13default,
    sigmavec::Union{Vector{<:TimeSeriesEcon._FPConst},Vector{UnionAll},X13default}=_X13default,
    trendic::Union{Float64,X13default}=_X13default,
    true7term::Union{Bool,X13default}=_X13default,
)
    # checks and logic
    if !(trendma isa X13default)
        if trendma % 2 !== 1 || trendma < 3 || trendma > 101
            throw(ArgumentError("trendma must be an unequal number between 3 and 101. Received: $(trendma)."))
        end
    end

    if !(sigmavec isa X13default)
        if calendarsigma isa X13default || (calendarsigma isa Symbol && calendarsigma !== :select)
            throw(ArgumentError("The sigmavec argument can only be specified when calendarsigma=:select."))
        end
    end
    # not in save: :residualseasf

    # TODO: add :totaladjustment to print if series contains values <= 0
    
    # save = [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:irregular,:irrwt,:origchanges,:replacsi,:sachanges,:seasadj,:seasonal,:seasonaldiff,:totaladjustment,:trend,:trendchanges,:unmodsi,:unmodsiox,:adjoriginalc,:adjoriginald,:extreme,:extremeb,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:adjustfacpct,:calendaradjchangespct,:irregularpct,:origchangespct,:sachangespct,:seasonalpct,:trendchangespct]# print::Union{Symbol,Vector{Symbol},X13default}

    # print = [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:ftestd8,:irregular,:irrwt,:movseasrat,:origchanges,:qstat,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:tdaytype,:trend,:tendchanges,:unmodsi,:unmodsiox,:x11diag,:yrtotals,:adjoriginalc,:adjoriginald,:autosf,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsib4,:replacsib9,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:irregularplot,:origwsaplot,:ratioplotorig,:ratioplotsa,:seasadjplot,:seasonalplot,:trendplot]# print::Union{Symbol,Vector{Symbol},X13default}
    # print = [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:ftestd8,:irregular,:irrwt]#,:moveseasrat]#,:origchanges,:qstat,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:tdaytype,:totaladjustment,:trend,:tendchanges,:unmodsi,:unmodsiox,:x11diag,:yrtotals,:adjoriginalc,:adjoriginald,:autosf,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsib4,:replacsib9,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:irregularplot,:origwsaplot,:ratioplotorig,:ratioplotsa,:seasadjplot,:seasonalplot,:trendplot]
    # save = [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:irregular,:irrwt,:origchanges,:replacsi]#,:sachanges,:seasadj,:seasonal,:seasonaldiff,:totaladjustment,:trend,:tendchanges,:unmodsi,:unmodsiox,:adjoriginalc,:adjoriginald,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:adjustfacpct,:calendaradjchangespct,:irregularpct,:origchangespct,:sachangespct,:seasonalpct,:trendchangespct]
    _print_all = [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:ftestd8,:irregular,:irrwt,:movseasrat,:origchanges,:qstat,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:tdaytype,:trend,:trendchanges,:unmodsi,:unmodsiox,:x11diag,:yrtotals,:adjoriginalc,:adjoriginald,:autosf,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsib4,:replacsib9,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:irregularplot,:origwsaplot,:ratioplotorig,:ratioplotsa,:seasadjplot,:seasonalplot,:trendplot]
    _save_all = [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:irregular,:irrwt,:origchanges,:replacsi,:sachanges,:seasadj,:seasonal,:seasonaldiff,:totaladjustment,:trend,:trendchanges,:unmodsi,:unmodsiox,:adjoriginalc,:adjoriginald,:extreme,:extremeb,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:adjustfacpct,:calendaradjchangespct,:irregularpct,:origchangespct,:sachangespct,:seasonalpct,:trendchangespct]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end

    return X13x11(appendbcst,appendfcst,final,mode,print,save,savelog,seasonalma,sigmalim,title,trendma,type,calendarsigma,centerseasonal,keepholiday,print1stpass,sfshort,sigmavec,trendic,true7term)
end
x11!(spec::X13spec{F}; kwargs...) where F = (spec.x11 = x11(; kwargs...); spec)



"""
`x11regression(; kwargs...)`

`x11regression!(spec::X13spec{F}; kwargs...)`

`x11(; kwargs...)`

`x11!(spec::X13spec{F}; kwargs...)`

An optional spec for use in conjunction with the x11 spec for series without missing observations. This spec
estimates calendar effects by regression modeling of the irregular component with predefined or user-defined
regressors. The user can select predefined regression variables with the `variables` argument. The predefined
variables are for calendar (trading-day and holiday) variation and additive outliers. A change-of-regime option
is available with trading-day regressors. User-defined calendar effect regression variables can be included in
the model via the user argument. Data for any user-defined variables must be supplied in the data
argument. The regression model specified can contain both predefined and user-defined regression variables.

### Main keyword arguments:

* **aicdiff** (Float64) - Defines the difference in AICC needed to accept a regressor specified in the aictest
    argument. The default value is `aicdiff=0.0`. For more information on how this option
    is used in conjunction with the aictest argument, see the manual.

* **aictest** (Symbol or Vector{Symbol}) - Specifies that an AIC-based comparison will be used to determine if a specified regression
    variable should be included in the user's irregular component regression model. The only
    entries allowed for this variable are `:td`, `:tdstock`, `:td1coef`, `:tdstock1coef`, `:easter`, and
    `:user`. If a trading day model selection is specified, for example, then AIC values (with
    a correction for the length of the series, henceforth referred to as AICC) are derived
    for models with and without the specified trading day variable. By default, the model
    with smaller AICC is used to generate forecasts, identify outliers, etc. If more than
    one type of regressor is specified, the AIC-tests are performed sequentially in this order:
    (a) trading day regressors, (b) easter regressors, (c) user-defined regressors. If there are
    several variables of the same type (for example, several td regressors), then the aictest
    procedure is applied to them as a group. That is, either all variables of this type will
    be included in the final model or none. See the manual for more information on the
    testing procedure. If this option is not specified, no automatic AIC-based selection will
    be performed.

* **critical** (Float64) - Sets the critical value (threshold) against which the absolute values of the outlier 
    t-statistics are compared to detect additive outliers (meaning extreme irregular values). This
    argument applies unless the sigma argument is used, or the only regressor(s) estimated
    is flow trading day. The assigned value must be a real number greater than 0. Example:
    `critical=4.0`. The default critical value is determined by the number of observations
    in the interval searched for outliers (see the outlierspan argument below). Table 7.22
    gives default critical values for a number of outlier span lengths. Larger (smaller) critical
    values predispose x11regression to treat fewer (more) irregulars as outliers. A large
    value of critical should be used if no protection is wanted against extreme irregular
    values.

* **data** (MVTSeries) - Assigns values to the user-defined regression variables. The time frame of the values
    must cover the time frame of the series (or of the span specified by the span argument of
    the series spec, if present). It must also cover the time frame of forecasts and backcasts
    requested in the forecast spec.

* **outliermethod** (Symbol) - Determines how the program successively adds detected outliers to the model. The
    choices are `outliermethod = :addone` or `outliermethod = :addall`. See the DETAILS section of the
    outlier spec for a description of these two methods. The default is `outliermethod = :addone`.
    This argument cannot be used if the `sigma` argument is used.

* **outlierspan** (UnitRange{MIT} or Span) - Specifies start and end dates of the span of the irregular component to be searched for
    outliers. The start and end dates of the span must both lie within the series. Example: `outlierspan = 1976M1:2022M3`.
    This argument cannot be used with the `sigma` argument.

    An X13.Span can also be used in this field, this is specified with two values with a value of missing,
    substituting for the beginning or ending of the provided series. Example: `X13.Span(1968M1,missing)`.

* **prior** (Bool) - Specifies whether calendar factors from the irregular component regression are computed
    in a preliminary run and applied as prior factors (`prior=true`), or as a part of the seasonal
    adjustment process (`prior=false`). The default is `prior=false`. The prior argument has
    no effect when a regARIMA model is specified; in this case, the irregular component
    regression is always computed before seasonal adjustment.

* **sigma** (Float64) - The sigma limit for excluding extreme values of the irregular components before trading
    day (only) regression is performed. Irregular values larger than this number of standard
    deviations from the mean (1.0 for multiplicative adjustments, 0.0 for additive adjustments) are 
    excluded as extreme. Each irregular has a standard error determined by its
    month (or quarter) type. The month types are determined by the month length, by
    the day of the week on which the month starts. This argument cannot be used when
    regressors other than flow trading day are present in the model, or when the `critical`
    argument is used. The assigned value must be a real number greater than 0; the default
    is 2.5 (which is invoked only when the flow trading day variable(s) are the only regressor
    estimated). Example: `sigma=3.0`.

* **span** (UnitRange{MIT} or Span) - Specifies the span (data interval) of irregular component values to be used to estimate
    the regression model's coefficients. This argument can be utilized when, for example,
    the user does not want data early in the series to affect regression estimates used for
    preadjustment before seasonal adjustment. As with the `modelspan` spec detailed in the
    `series` spec, the span argument has two values, the start and end date of the desired
    span. The start and end dates of the
    model span must both lie within the time span of data specified for analysis in the `series`
    spec, and the start date must precede the end date.

    An X13.Span can also be used in this field, this is specified with two values with a value of missing,
    substituting for the beginning or ending of the provided series. Example: `X13.Span(1968M1,missing)`.
    The second value can also be a monthly or a quarterly indicator, such as `M11` or `Q2`. If this is th ecase,
    the ending tdate of the modelspan will be the most recent occurence in the data of the specified month or quarter.

* **tdprior** (Vector{Float64}) - User-input list of seven daily weights, starting with Monday's weight, which specify a
    desired X-11 trading day adjustment prior to seasonal adjustment. These weights are
    adjusted to sum to 7.0 by the program. This option can be used only with multiplicative
    and log-additive seasonal adjustments. The values must be real numbers greater than or
    equal to zero. Example: `tdprior=[0.7, 0.7, 0.7, 1.05, 1.4, 1.4, 1.05]`.

* **usertype** (Symbol or Vector{Symbol}) - Assigns a type to the user-defined regression variables. 
    The user-defined regression effects can be defined as a trading day (td), holiday (holiday, or other user-defined (user)
    regression effects. A single effect type can be specified for all the user-defined regression
    variables defined in the x11regression spec (`usertype=:td`), or each user-defined regression variable can be 
    given its own type (`usertype=[:td, :td, :td, :td, :td, :td, :holiday, :user]`). 
    See the manual for more information on assigning types to user-defined regressors.

* **variables** (Vector{Symbol}) - List of predefined regression variables to be included in the model. The values of these
    variables are calculated by the program, as functions of the calendar in most cases. See the table below for the list 
    of pre-defined variables and the manual for additional details.
  
    Variable          | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
    :-----------------| :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    `:td`             | Estimates monthly (or quarterly) flow trading-day effects by adding the `:tdnolpyear` variables (see the `variables` argument in the `regression` spec) to the model. The derivations of February from the average length of 28.25 are handled either by rescaling (for multiplicative adjustments) or by including the `:lpyear` regression variable (for additive and log-additive adjustments). `:td` cannot be used with `tdstock()`, `tdstock1coef()` or `:td1coef`.                                      
    `:td1coef`        | Estimate monthly (or quarterly) flow trading-day effects by including the `:td1nolpyear` variable (see below) in the model, and by handling leap-year effects either by rescaling (for transformed series) or by including the `:lpyear` regression variable (for untransformed series). `:td1coef` can only be used for monthly or quarterly series, and cannot be used with `:td`, `tdstock1coef()` or `tdstock()`.                                                                                          
    `tdstock(w)`      | Adds 6 stock trading-day variables to model the effect of the day of the week on a stock series estimated for the w-th day of each month. The value w must be supplied and can range from 1 to 31. For any month of length less than the specified w, the `tdstock` variables are measured as of the end of the month. Use `X13.tdstock(31)` for end-of-month stock series. `tdstock` can be used only with monthly series and cannot be used with `:td`, `tdstock1coef()` or `:td1coef`.                      
    `tdstock1coef(w)` | Adds a constrained stock trading-day variable to model the effect of the day of the week on a stock series estimated for the w-th day of each month. The value w must be supplied and can range from 1 to 31. For any month of length less than the specified w, the `tdstock1coef` variables are measured as of the end of the month. Use `X13.tdstock1coef(31)` for end-of-month stock series. `tdstock1coef` can be used only with monthly series and cannot be used with `:td`, `tdstock()` or `:td1coef`. 
    `easter(w)`       | Easter holiday regression variable (monthly or quarterly flow data only) which assumes the level of daily activity changes on the w−th day before Easter and remains at the new level until the day before Easter. The value w must be supplied and can range from 1 to 25. To estimate complex effects, several of these variables, differing in their choices of w, can be specified. Example: `X13.easter(10)`.                                                                                             
    `labor(w)`        | Labor Day holiday regression variable (monthly flow data only) that assumes the level of daily activity changes on the w−th day before Labor Day and remains at the new level until the day before Labor Day. The value w must be supplied and can range from 1 to 25. Example: `X13.labor(8)`.                                                                                                                                                                                                                
    `thank(w)`        | Thanksgiving holiday regression variable (monthly flow data only) that assumes the level of daily activity changes on the w−th day before or after Thanksgiving and remains at the new level until December 24. The value w must be supplied and can range from −8 to 17. Values of w < 0 indicate a number of days after Thanksgiving; values of w > 0 indicate a number of days before Thanksgiving. Example: `X13.thank(-4)`.                                                                               
    `sceaster(w)`     | Statistics Canada Easter holiday regression variable (monthly or quarterly flow data only) assumes that the level of daily activity changes on the (w−1)−th day and remains at the new level through Easter day. The value w must be supplied and can range from 1 to 24. To estimate complex effects, several of these variables, differing in their choices of w, can be specified. Example: `X13.sceaster(8)`.                                                                                              
    `ao(mit)`         | Additive (point) outlier variable, AO, for the given date. More than one AO may be specified. All specified outlier dates must occur within the series. (AOs with dates within the series but outside the span specified by the `span` argument of the `series` spec are ignored). Example: `X13.ao(1983M1)`.                                                                                                                                                                                                  
   
### Rarely used keyword arguments:

* **almost** (Float64) - Differential used to determine the critical value used for a set of ”almost” outliers -
    outliers with t-statistics near the outlier critical value that are not incorporated into the
    regARIMA model. After outlier identification, any outlier with a t-statistic larger than
    Critical − almost is considered an ”almost outlier,” and is included in a separate table.
    The default is `almost = 0.5`; values for this argument must always be greater than zero.

* **b** (Vector{Float64}) - Specifies initial values for regression parameters in the order that they appear in the
    `variables` and `user` arguments. If present, the `b` argument must assign initial values
    to _all_ regression coefficients in the regARIMA model. Initial values are assigned to parameters
    either by specifying the value in the argument list or by explicitly indicating that it is
    missing as in the example below. Missing values take on their default value of 0.1. For
    example, for a model with two regressors, `b=[0.7, missing]` is equivalent to `b=[0.7,0.1]`, but
    `b=[0.7]` is not allowed. For a model with three regressors, `b=[0.8,missing,-0.4]` is equivalent
    to `b=[0.8,0.1,-0.4]`. To hold a parameter fixed at a specified value, use the `fixb` argument.

* **fixb** (Vector{Bool}) - A vector of `true`/`false` entries corresponding to the entries in the `b` vector.
        `true` entries will be held fixed.

* **centeruser** (Symbol) - Specifies the removal of the (sample) mean or the seasonal means from the user-defined
    regression variables. If `centeruser=:mean`, the mean of each user-defined regressor is
    subtracted from the regressor. If `centeruser=:seasonal`, means for each calendar month
    (or quarter) are subtracted from each of the user-defined regressors. If this option is
    not specified, the user-defined regressors are assumed to already be in an appropriately
    centered form and are not modified.

* **eastermeans** (Bool) - Specifies whether long term (500 year) monthly means are used to deseasonalize the
    Easter regressor associated with the variable `easter[w]`, as described in footnote 5 of
    Table 4.1 of the manual (`eastermeans=true`), or, instead, monthly means calculated from the span of
    data used for the calculation of the coefficients of the Easter regressors (`eastermeans=false`).
    The default is `eastermeans=true`. This argument is ignored if no built-in Easter regressor
    is included in the regression model, or if the only Easter regressor is `sceaster[w]` (see
    the manual for details).

* **forcecal** (Bool) - Specifies whether the calendar adjustment factors are to be constrained to have the same
    value as the product (or sum, if additive seasonal adjustment is used) of the holiday and
    trading day factors (`forcecal=true`), or not (`forcecal=false`). The default is `forcecal=false`.
    This argument is functional only when both holiday and trading day regressors are specified in the `variables` argument of this spec.

* **noapply** (Vector{Symbol}) - List of the types of regression effects defined in the `x11regression` spec whose 
    model-estimated values are not to be adjusted out of the original series or final seasonally
    adjusted series. Available effects include modelled trading day effects (`:td`) and Easter,
    Labor Day, and Thanksgiving-Christmas holiday effects (`:holiday`).

* **reweight** (Bool) - Specifies whether the daily trading day weights are to be re-weighted when at least one
    of the daily weights in the C16 output table is less than zero (`reweight=true`), or not
    (`reweight=false`). The default is `reweight=false`. This argument is functional only when
    trading day regressors are specified in the variables argument of this spec. Note: the
    default for previous versions of X-11 and X-11-ARIMA corresponds to `reweight=true`.

* **umdata** (MVTSeries) - An MVTSeries of mean-adjustment values, to be subtracted from the irregular series
    Iₜ (or Log(Iₜ)) before the coefficients of a model with a user-defined regressor are estimated. 
    This argument is used when the mean function for predefined
    regressors described in the manual is incorrect for the model with user-defined regressors.
    The mean-adjustment function depends on the mode of adjustment. See the manual for
    more information.

    The time frame of these values must cover the time frame of the series (or of the span
    specified by the span argument of the `series` spec, if present). It must also cover the
    time frame of forecasts and backcasts requested in the `forecast` spec.
"""
function x11regression(; 
    aicdiff::Union{Float64,X13default}=_X13default,
    aictest::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    critical::Union{Float64,X13default}=_X13default,
    data::Any=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    outliermethod::Union{Symbol,X13default}=_X13default,
    outlierspan::Union{UnitRange{<:MIT}, Span, X13default}=_X13default,
    print::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    save::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    savelog::Union{Symbol,Vector{Symbol},X13default}=:aictest, # savelog::Union{Symbol,Vector{Symbol},X13default}     
    prior::Union{Bool,X13default}=_X13default,
    sigma::Union{Float64,X13default}=_X13default,
    span::Union{UnitRange{<:MIT},Span,X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    tdprior::Union{Vector{Float64},X13default}=_X13default,
    user::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    usertype::Union{Symbol,Vector{Symbol},X13default}=_X13default,
    variables::Union{Symbol,X13var,Vector{<:Union{Symbol,X13var,Any}},X13default}=_X13default,
    almost::Union{Float64,X13default}=_X13default,
    b::Union{Vector{Float64},X13default}=_X13default,
    fixb::Union{Vector{Bool},X13default}=_X13default,
    centeruser::Union{Symbol,X13default}=_X13default,
    eastermeans::Union{Bool,X13default}=_X13default,
    forcecal::Union{Bool,X13default}=_X13default,
    noapply::Union{Vector{Symbol},X13default}=_X13default,
    reweight::Union{Bool,X13default}=_X13default,
    umdata::Any=_X13default,
    umfile::Union{String,X13default}=_X13default,
    umformat::Union{String,X13default}=_X13default,
    umname::Union{String,X13default}=_X13default,
    umprecision::Union{Int64,X13default}=_X13default,
    umstart::Union{MIT,X13default}=_X13default,
    umtrimzero::Union{Bool,Symbol,X13default}=_X13default,
)
    # checks and logic
    start = _X13default
    user = _X13default
    if !(data isa X13default)
        start = first(rangeof(data))
        user = collect(colnames(data))
        if length(user) == 1
            user = user[1]
        end
    end

    umstart = _X13default
    umname = _X13default
    if !(umdata isa X13default)
        umstart = first(rangeof(umdata))
        umname = collect(colnames(umdata))
        if length(umname) == 1
            umname = umname[1]
        end
    end

    # ensure correct type of variables
    _variables = X13default()
    if !(variables isa X13default)
        if variables isa Vector
            _variables = Vector{Union{Symbol,X13var}}()
            for var in variables
                push!(_variables, var)
            end
        else
            _variables = variables
        end

        if !(aictest isa X13default)
            aics = aictest isa Vector ? aictest : [aictest]
            vars =_variables isa Vector ? _variables : [_variables]
            types_used = Set(collect_regvar_types(vars))
            if length(filter(a -> a ∈ (:td, :tdstock, :td1coef, :tdstock1coef), aics)) > 1 && length(filter(a -> a  ∈ (:td, :tdstock, :td1coef, :tdstock1coef), types_used)) > 1
                for aic in aics
                    if aic  ∈ (:td, :tdstock, :td1coef, :tdstock1coef) && aic ∉ types_used
                        throw(ArgumentError("Trading day regressors specified in the aictest must correspond with trading day regressors provided in the variables argument. $(aic) was specified in the aictest argument, but the variables argument uses $(filter(x -> x ∈ (:td, :tdstock, :td1coef, :tdstock1coef), types_used))."))
                    end
                end
            end
        end
    end

    allowed_aictest_values =  (:td, :tdstock, :td1coef, :tdstock1coef, :easter, :user)
    if aictest isa Symbol && aictest ∉ allowed_aictest_values
        throw(ArgumentError("aictest can only contain these entries: $(allowed_aictest_values). Received: $(aictest)."))
    elseif aictest isa Vector{Symbol} && length(filter(a -> a ∈ allowed_aictest_values, aictest)) < length(aictest)
        throw(ArgumentError("aictest can only contain these entries: $(allowed_aictest_values). Received: $(aictest)."))
    end

    if !(sigma isa X13default) && sigma <= 0.0
        throw(ArgumentError("sigma must be a number greater than 0. Received: $(sigma)."))
    end
    
    if !(tdprior isa X13default)
        if length(tdprior) !== 7
            throw(ArgumentError("tdprior must have a length of exactly 7. Received: $(tdprior)."))
        end
        if any(tdprior .< 0.0)
            throw(ArgumentError("tdprior values must all be greater than or equal to 0. Received: $(tdprior)."))
        end
    end

    if !(usertype isa X13default)
        if !(user isa X13default) && usertype isa Vector{Symbol} && user isa Vector{Symbol}
            if length(usertype) > 1 && (length(usertype) != length(user))
                throw(ArgumentError("The usertype argument must have the same length as the number of user series provided ($(length(user))) when more than a single type is specified. Received: $(usertype)"))
            end
        end
        usertype_allowed_values = (:td, :holiday, :user)
        if usertype isa Vector{Symbol} && length(filter(x -> x  ∉ usertype_allowed_values, usertype)) > 0
            throw(ArgumentError("The usertype argument can only have the following values: $(usertype_allowed_values). \n\nReceived: $(usertype)"))
        elseif usertype isa Symbol && usertype ∉ usertype_allowed_values
            throw(ArgumentError("The usertype argument can only have the following values: $(usertype_allowed_values). \n\nReceived: $(usertype)"))
        end
    end

    if outlierspan isa X13.Span
        if span.e isa TimeSeriesEcon._FPConst || span.e isa UnionAll
            throw(ArgumentError("Spans with a fuzzy ending time, such as M11 or Q2, are not allowed in the span argument of the series spec. Please pass an MIT or `missing`. Received: $(span.e)."))
        end
    end

    # print = _X13default
    # save = _X13default
    # savelog = _X13default
    # aictest = _X13default
    # aictest = [:td]
    _print_all = [:priortd, :extremeval, :x11reg, :tradingday, :combtradingday, :holiday, :calendar, :combcalendar, :outlierhdr, :xaictest, :extremevalb, :x11regb, :tradingdayb, :combtradingdayb, :holidayb, :calendarb, :combcalendarb, :outlieriter, :outliertests, :xregressionmatrix, :xregressioncmatrix]
    _save_all = [:priortd, :extremeval, :tradingday, :combtradingday, :holiday, :calendar, :combcalendar, :extremevalb, :tradingdayb, :combtradingdayb, :holidayb, :calendarb, :combcalendarb, :outlieriter, :xregressionmatrix, :xregressioncmatrix]
    if (print isa Symbol && print == :all) || (print isa Vector{Symbol} && print == [:all])
        print = _print_all
    end
    if (save isa Symbol && save == :all) || (save isa Vector{Symbol} && save == [:all])
        save = _save_all
    end


    return X13x11regression(aicdiff,aictest,critical,data,file,format,outliermethod,outlierspan,print,save,savelog,prior,sigma,span,start,tdprior,user,usertype,_variables,almost,b,fixb,centeruser,eastermeans,forcecal,noapply,reweight,umdata,umfile,umformat,umname,umprecision,umstart,umtrimzero)
end
x11regression!(spec::X13spec{F}; kwargs...) where F = (spec.x11regression = x11regression(; kwargs...); spec)


function validateX13spec(spec::X13spec)

    # The arima spec cannot be used in the same spec file as the pickmdl or automdl specs;
    if !(spec.arima isa X13default)
        if !(spec.automdl isa X13default)
            throw(ArgumentError("The arima spec cannot be used in the same spec file as the pickmdl or automdl specs."))
        end
        if !(spec.pickmdl isa X13default)
            throw(ArgumentError("The arima spec cannot be used in the same spec file as the pickmdl or automdl specs."))
        end

        #  the model, ma, andar arguments of the arima spec cannot be used when the file argument is specified in the estimate spec
        if !(spec.estimate isa X13default) && !(spec.estimate.file isa X13default) && (!(spec.arima.ar isa X13default) || !(spec.arima.ar isa X13default) || !(spec.arima.model isa X13default))
            throw(ArgumentError("The model, ma, and ar arguments of the arima spec cannot be used when the file argument is specified in the estimate spec"))
        end


    end

    if !(spec.automdl isa X13default)
        if !(spec.pickmdl isa X13default)
            throw(ArgumentError("The automdl spec cannot be used in the same spec file as the pickmdl or arima specs."))
        end

         if !(spec.estimate isa X13default) && !(spec.estimate.file isa X13default)
            throw(ArgumentError("The automdl spec cannot be used in the same spec file as an estimate spec employing the file argument."))
        end

    end

    if !(spec.estimate isa X13default) && !(spec.estimate.file isa X13default)
        if !(spec.regression isa X13default)
            if !(spec.regression.variables isa X13default) || !(spec.regression.user isa X13default) || !(spec.regression.b isa X13default)
                throw(ArgumentError("The variables, user, and b arguments of the regression spec cannot be used when the estimate spec contains the file argument."))
            end
        end
    end

    if !(spec.forecast isa X13default)
        if !(spec.forecast.exclude isa X13default) && !(spec.x11 isa X13default)
            #TODO: warning: exclude cannot be used if seasonal adjustment is specified by the x11 spec...
        end

        if !(spec.forecast.maxlead isa X13default) && !(spec.history isa X13default) && !(spec.history.fstep isa X13default)
            if spec.history.fstep isa Vector{Int64} && any(spec.history.fstep .> spec.forecast.maxlead)
                throw(ArgumentError("The values of fstep in the history spec cannot be greater than the maxlead specified in the history spec ($(spec.forecast.maxlead)). Recieved: $(spec.history.fstep)."))
            end
        end
    end

    if !(spec.history isa X13default)
        if !(spec.history.outlier isa X13default) && (spec.outlier isa X13default)
            @warn "The outlier argument of the history spec has no effect when no outlier spec is specified."
        end
    end

    # regression variable type exceptions
    if !(spec.regression isa X13default) && !(spec.regression.variables isa X13default)
        vars = spec.regression.variables isa Vector ? spec.regression.variables : [spec.regression.variables]
        if !(spec.transform isa X13default) && !(spec.transform.adjust isa X13default) && spec.transform.adjust == :lom
            for v in vars
                if v == :td || v == :lom || v isa td || v isa lom
                    throw(ArgumentError("When adjust=:lom is specified in the transform spec, the inclusion of either td or lom variables in the variables list of the regression spec leads to conflicts."))
                end
            end
        end

        types_used = Set(collect_regvar_types(vars))
        series_range = rangeof(spec.series.data)
        span_range = rangeof(spec.series.data)
        if spec.series.span isa UnitRange
            span_range = spec.series.span
        elseif spec.series.span isa Span
            if spec.series.span.b isa MIT
                span_range = spec.series.span.b:last(span_range)
            end
            if spec.series.span.e isa MIT
                span_range = first(span_range):spec.series.span.e
            end
            ## TODO: treatment of 0.per ranges here
        end
        for v in vars
            vtypesymbol = v
            if !(vtypesymbol isa Symbol)
                vtypesymbol = var_types_map[typeof(v)]
            end
            if !(spec.series.type isa X13default)
                if spec.series.type != :flow
                    if vtypesymbol ∈ (:td, :tdnolpyear, :td1coef, :td1nolpyear, :lpyear, :easter, :labor, :thank, :sceaster)
                        throw(ArgumentError("$vtype regressors can only be used with flow-type data. The provided series has the type: $(spec.series.type)."))
                    end
                elseif spec.series.type != :stock
                    if vtypesymbol ∈ (:tdstock, :td1stock, :easterstock)
                        throw(ArgumentError("$vtype regressors can only be used with stock-type data. The provided series has the type: $(spec.series.type)."))
                    end
                end
            end
            if vtypesymbol == :td
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("td regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:tdnolpyear, :td1coef, :td1nolpyear, :lpyear, :lom, :loq, :tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("td cannot be used with tdnolpyear, td1coef, td1nolpyear, lpyear, lom, loq, tdstock, or tdstock1coef regressors."))
                end
                if !(spec.transform isa X13default) && !(spec.transform.adjust isa X13default)
                    throw(ArgumentError("The adjust argument of the transform spec cannot be used when td or td1coef is specified in the regression spec."))
                end
            end
            if vtypesymbol == :tdnolpyear
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("tdnolpyear regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:td, :td1coef, :td1nolpyear, :tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("tdnolpyear cannot be used with td, td1coef, td1nolpyear, tdstock, or tdstock1coef regressors."))
                end
            end
            if vtypesymbol == :td1coef
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("td1coef regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:td, :tdnolpyear, :td1nolpyear, :lpyear, :lom, :loq, :tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("td1coef cannot be used with td, tdnolpyear, td1nolpyear, lpyear, lom, loq, tdstock, or tdstock1coef regressors."))
                end
                if !(spec.transform isa X13default) && !(spec.transform.adjust isa X13default)
                    throw(ArgumentError("The adjust argument of the transform spec cannot be used when td or td1coef is specified in the regression spec."))
                end
            end
            if vtypesymbol == :td1nolpyear
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("td1nolpyear regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:td, :tdnolpyear, :td1coef, :tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("td1nolpyear cannot be used with td, tdnolpyear, td1coef, tdstock, or tdstock1coef regressors."))
                end
            end
            if vtypesymbol == :lpyear
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("lpyear regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:td, :td1coef, :tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("lpyear cannot be used with td, td1coef, tdstock, or tdstock1coef regressors."))
                end
            end
            if vtypesymbol == :lom
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("lom regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:td,:td1coef,:tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("lom cannot be used with td, td1coef, tdstock, or tdstock1coef regressors."))
                end
            end
            if vtypesymbol == :loq
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("loq regressors can only be used with Monthly or Quarterly data."))
                end
                if length(intersect(types_used, Set([:td, :td1coef, :tdstock, :tdstock1coef]))) > 0
                    throw(ArgumentError("loq cannot be used with td, td1coef, tdstock, or tdstock1coef regressors."))
                end
            end
            if vtypesymbol == :tdstock
                if !(ismonthly(spec.series.data))
                    throw(ArgumentError("tdstock regressors can only be used with Monthly data."))
                end
                if length(intersect(types_used, Set([:tdstock1coef, :td, :tdnolpyear, :td1coef, :td1nolpyear, :lom, :loq]))) > 0
                    throw(ArgumentError("tdstock cannot be used with tdstock1coef, td, tdnolpyear, td1coed, td1nolpyear, lom or loq regressors."))
                end
            end
            if vtypesymbol == :tdstock1coef
                if !(ismonthly(spec.series.data))
                    throw(ArgumentError("tdstock1coef regressors can only be used with Monthly data."))
                end
                if length(intersect(types_used, Set([:tdstock, :td, :tdnolpyear, :td1coef, :td1nolpyear, :lom, :loq]))) > 0
                    throw(ArgumentError("tdstock1coef cannot be used with tdstock, td, tdnolpyear, td1coed, td1nolpyear, lom or loq regressors."))
                end
            end
            if vtypesymbol == :labor
                if !(ismonthly(spec.series.data))
                    throw(ArgumentError("labor regressors can only be used with Monthly data."))
                end
            end
            if vtypesymbol == :sceaster
                if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                    throw(ArgumentError("sceaster regressors can only be used with Monthly data."))
                end
            end
            if v isa ao && !(v.mit ∈ series_range)
                throw(ArgumentError("ao regressors must have a date within the series range ($(series_range)). Received: ao($(v.mit))"))
            end
            if v isa tc && !(v.mit ∈ series_range)
                throw(ArgumentError("tc regressors must have a date within the series range ($(series_range)). Received: tc($(v.mit))"))
            end
            if v isa ls 
                if !(v.mit ∈ series_range)
                    throw(ArgumentError("ls regressors must have a date within the series range ($(series_range)). Received: ls($(v.mit))"))
                elseif v.mit == first(span_range)
                    throw(ArgumentError("ls regressors cannot be at the start of the series range or the span range ($(span_range)). Received: ls($(v.mit))"))
                end
            end
            if v isa so 
                if !(v.mit ∈ series_range)
                    throw(ArgumentError("so regressors must have a date within the series range ($(series_range)). Received: so($(v.mit))"))
                elseif v.mit == first(span_range)
                    throw(ArgumentError("so regressors cannot be at the start of the series range or the span range ($(span_range)). Received: so($(v.mit))"))
                end
            end
            if v isa aos && (!(v.mit1 ∈ series_range) || !(v.mit2 ∈ series_range))
                throw(ArgumentError("aos regressors must have a date within the series range ($(series_range)). Received: aos($(v.mit1),$(v.mit2))"))
            end
            if v isa lss && (!(v.mit1 ∈ series_range) || !(v.mit2 ∈ series_range))
                throw(ArgumentError("lss regressors must have a date within the series range ($(series_range)). Received: aos($(v.mit1),$(v.mit2))"))
            end
            if v isa rp && (!(v.mit1 ∈ series_range) || !(v.mit2 ∈ series_range))
                throw(ArgumentError("rp regressors must have a date within the series range ($(series_range)). Received: rp($(v.mit1),$(v.mit2))"))
            end
            if v isa qd && (!(v.mit1 ∈ series_range) || !(v.mit2 ∈ series_range))
                throw(ArgumentError("qd regressors must have a date within the series range ($(series_range)). Received: qd($(v.mit1),$(v.mit2))"))
            end
            if v isa qi && (!(v.mit1 ∈ series_range) || !(v.mit2 ∈ series_range))
                throw(ArgumentError("qi regressors must have a date within the series range ($(series_range)). Received: qi($(v.mit1),$(v.mit2))"))
            end
            if v isa tl && (!(v.mit1 ∈ series_range) || !(v.mit2 ∈ series_range))
                throw(ArgumentError("tl regressors must have a date within the series range ($(series_range)). Received: tl($(v.mit1),$(v.mit2))"))
            end
        end

        if !(spec.regression.aictest isa X13default)
            ## type restrictions for AIC test
            aictests = spec.regression.aictest isa Vector ? spec.regression.aictest : [spec.regression.aictest]
            for aic in aictests
                if !(spec.series.type isa X13default)
                    if spec.series.type != :flow
                        if aic ∈ (:tdnolpyear, :td1coef, :td1nolpyear, :lpyear, :easter, :labor, :thank, :sceaster)
                            throw(ArgumentError("aictest: $aic regressors can only be tested for with flow-type data. The provided series has the type: $(spec.series.type)."))
                        end
                    elseif spec.series.type != :stock
                        if aic ∈ (:tdstock, :td1stock, :easterstock)
                            throw(ArgumentError("aictest: $aic regressors can only be tested for with stock-type data. The provided series has the type: $(spec.series.type)."))
                        end
                    end
                end

                if aic == :td
                    if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: td regressors can only be used with Monthly or Quarterly data."))
                    end
                    if length(intersect(types_used, Set([:lpyear, :lom, :loq]))) > 0
                        throw(ArgumentError("aictest: td cannot be used with lpyear, lom, loq, regressors."))
                    end
                end
                if aic == :tdnolpyear
                    if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: tdnolpyear regressors can only be used with Monthly or Quarterly data."))
                    end
                    if length(intersect(types_used, Set([:td, :td1coef, :td1nolpyear, :tdstock, :tdstock1coef]))) > 0
                        throw(ArgumentError("aictest: tdnolpyear cannot be used with td, td1coef, td1nolpyear, tdstock, or tdstock1coef regressors."))
                    end
                end
                if aic == :td1coef
                    if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: td1coef regressors can only be used with Monthly or Quarterly data."))
                    end
                    if length(intersect(types_used, Set([:td, :tdnolpyear, :td1nolpyear, :lpyear, :lom, :loq, :tdstock, :tdstock1coef]))) > 0
                        throw(ArgumentError("aictest: td1coef cannot be used with td, tdnolpyear, td1nolpyear, lpyear, lom, loq, tdstock, or tdstock1coef regressors."))
                    end
                end
                if aic == :td1nolpyear
                    if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: td1nolpyear regressors can only be used with Monthly or Quarterly data."))
                    end
                    if length(intersect(types_used, Set([:td, :tdnolpyear, :td1coef, :tdstock, :tdstock1coef]))) > 0
                        throw(ArgumentError("aictest: td1nolpyear cannot be used with td, tdnolpyear, td1coef, tdstock, or tdstock1coef regressors."))
                    end
                end
                if aic == :lpyear
                    if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: lpyear regressors can only be used with Monthly or Quarterly data."))
                    end
                    if length(intersect(types_used, Set([:td, :td1coef, :tdstock, :tdstock1coef]))) > 0
                        throw(ArgumentError("aictest: lpyear cannot be used with td, td1coef, tdstock, or tdstock1coef regressors."))
                    end
                end
                if aic == :lom
                    if !(ismonthly(spec.series.data))
                        throw(ArgumentError("aictest: lom regressors can only tested for with Monthly data."))
                    end
                    if length(intersect(types_used, Set([:td,:td1coef,:tdstock, :tdstock1coef]))) > 0
                        throw(ArgumentError("aictest: lom cannot be used with td, td1coef, tdstock, or tdstock1coef regressors."))
                    end
                end
                if aic == :loq
                    if !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: loq regressors can only be tested for with Quarterly data."))
                    end
                    if length(intersect(types_used, Set([:td, :td1coef, :tdstock, :tdstock1coef]))) > 0
                        throw(ArgumentError("aictest: loq cannot be used with td, td1coef, tdstock, or tdstock1coef regressors."))
                    end
                end
                if aic == :tdstock
                    if !(ismonthly(spec.series.data))
                        throw(ArgumentError("aictest: tdstock regressors can only be used with Monthly data."))
                    end
                    if length(intersect(types_used, Set([:tdstock1coef, :td, :tdnolpyear, :td1coef, :td1nolpyear, :lom, :loq]))) > 0
                        throw(ArgumentError("aictest: tdstock cannot be used with tdstock1coef, td, tdnolpyear, td1coed, td1nolpyear, lom or loq regressors."))
                    end
                end
                if aic == :tdstock1coef
                    if !(ismonthly(spec.series.data))
                        throw(ArgumentError("aictest: tdstock1coef regressors can only be used with Monthly data."))
                    end
                    if length(intersect(types_used, Set([:tdstock, :td, :tdnolpyear, :td1coef, :td1nolpyear, :lom, :loq]))) > 0
                        throw(ArgumentError("aictest: tdstock1coef cannot be used with tdstock, td, tdnolpyear, td1coed, td1nolpyear, lom or loq regressors."))
                    end
                end
                if aic == :labor
                    if !(ismonthly(spec.series.data))
                        throw(ArgumentError("aictest: labor regressors can only be used with Monthly data."))
                    end
                end
                if aic == :sceaster
                    if !(ismonthly(spec.series.data)) && !(isquarterly(spec.series.data))
                        throw(ArgumentError("aictest: sceaster regressors can only be used with Monthly data."))
                    end
                end
            end
        end
    end

    if !(spec.regression isa X13default) && !(spec.regression.data isa X13default)
        if !(spec.regression.data isa X13default)
            datarange = rangeof(spec.regression.data)
            series_range = rangeof(spec.series.data)
            required_range = rangeof(spec.series.data)
            if spec.series.span isa UnitRange
                required_range = spec.series.span
            elseif spec.series.span isa Span
                if spec.series.span.b isa MIT
                    required_range = spec.series.span.b:last(required_range)
                end
                if spec.series.span.e isa MIT
                    required_range = first(required_range):spec.series.span.e
                end
                ## TODO: treatment of 0.per ranges here
            end
            if !(spec.forecast isa X13default)
                if !(spec.forecast.maxback isa X13default)
                    required_range = first(required_range)-spec.forecast.maxback:last(required_range)
                end
                if !(spec.forecast.maxlead isa X13default)
                    required_range = first(required_range):last(required_range)+spec.forecast.maxlead
                end
            end
            
            if intersect(required_range, datarange) !== required_range
                throw(ArgumentError("The data provided in the regression spec must cover the range of the supplied data (or the span specified by the span argument of the series spec), as well as any forecasts and backcasts requested by the forecast spec. The required range is $(required_range), but the provided range was only $(datarange)."))
            end
        end
    end

   

    if !(spec.history isa X13default) 
        if !(spec.history.outlier isa X13default) && (spec.outlier isa X13default)
            @warn "The outlier argument of the history spec has no effect when no outlier spec is specified."
        end
    end

    if !(spec.seats isa X13default)
        if !(spec.seats.hpcycle isa X13default) && spec.seats.hplan isa X13default && spec.seats.hpcycle == true
            if ismonthly(spec.series.data) && length(spec.series.data) < 120
                @warn "Hodrick-Prescott filters will not be used as the default hplan requires at least 120 monthly observations. The provided series has $(length(spec.series.data)) observations."
            elseif isquarterly(spec.series.data) && length(spec.series.data) < 48
                @warn "Hodrick-Prescott filters will not be used as the default hplan requires at least 48 quarterly observations. The provided series has $(length(spec.series.data)) observations."
            end
        end
    end

    # If the beginning date specified in the modelspan argument is not the same as the starting date in the span argument, backcasts cannot be generated
    if !(spec.series.modelspan isa X13default) && !(spec.forecast isa X13default) && !(spec.forecast.maxback isa X13default)
        if !(spec.series.span isa X13default) && first(spec.series.modelspan) !== first(spec.series.span)
            @warn "Backcasts will not be generated as the start of the modelspan specified ($(spec.series.modelspan)) does not coincide with the start of the series span specified ($(spec.series.span))."
        end
    end
    
    if !(spec.slidingspans isa X13default)
        if !(spec.slidingspans.length isa X13default)
            if isquarterly(spec.series.data) && spec.slidingspans.length < 12
                throw(ArgumentError("The length argument of the slidingspans spec must cover at least 3 years. Current length is ≈$(spec.slidingspan.length / 4) years."))
            end
            if isquarterly(spec.series.data) && spec.slidingspans.length > 4*19
                throw(ArgumentError("The length argument of the slidingspans spec can cover at most 19 years. Current length is ≈$(spec.slidingspan.length / 4) years."))
            end

            if ismonthly(spec.series.data) && spec.slidingspans.length < 36
                throw(ArgumentError("The length argument of the slidingspans spec must cover at least 3 years. Current length is ≈$(spec.slidingspans.length / 12) years."))
            end
            if ismonthly(spec.series.data) && spec.slidingspans.length > 12*19
                throw(ArgumentError("The length argument of the slidingspans spec can cover at most 19 years. Current length is ≈$(spec.slidingspan.length / 12) years."))
            end
        end
        if !(spec.slidingspans.outlier isa X13default) && spec.outlier isa X13default
            @warn "The outlier argument of the slidingspans spec will be ignored as there is no outlier spec specified."
        end
    end

    if !(spec.spectrum isa X13default)
        if !(spec.spectrum.qcheck isa X13default) && spec.spectrum.qcheck == true && !ismonthly(spec.series.data)
            @warn "The qcheck argument of the spectrum spec only produces output for a monthly TSeries."
        end
    end

    if !(spec.transform isa X13default)
        if !(spec.transform.adjust isa X13default) && !(spec.x11 isa X13default) && !(spec.x11.mode isa X13default)
            if spec.x11.mode == :add || spec.x11.mode == :pseudoadd
                throw(ArgumentError("The adjust argument of the transform spec cannot be used when the mode argument of the x11 spec is :add or :pseudoadd."))
            end
        end
        if !(spec.x11 isa X13default)
            if spec.x11.mode isa X13default && spec.transform.power isa X13default && spec.transform.func isa X13default 
                throw(ArgumentError("The default value for the mode argument of the x11 spec (multiplicative) conflicts with the default for the function and power arguments of the transform spec (no transformation)."))
            end
        end
    end

    if !(spec.x11regression isa X13default)
        #TODO:
        if !(spec.transform isa X13default) && !(spec.transform.adjust isa X13default)
            throw(ArgumentError("The adjust argument of the transform spec cannot be used when td or td1coef is specified in the x11regression spec."))
        end

        if !(spec.x11regression.data isa X13default)
            data_range = rangeof(spec.x11regression.data)
            required_range = rangeof(spec.series.data)
            if spec.series.span isa UnitRange
                required_range = spec.series.span
            elseif spec.series.span isa Span
                if spec.series.span.b isa MIT
                    required_range = spec.series.span.b:last(required_range)
                end
                if spec.series.span.e isa MIT
                    required_range = first(required_range):spec.series.span.e
                end
                ## TODO: treatment of 0.per ranges here
            end
            if !(spec.forecast isa X13default)
                if !(spec.forecast.maxback isa X13default)
                    required_range = first(required_range)-spec.forecast.maxback:last(required_range)
                end
                if !(spec.forecast.maxlead isa X13default)
                    required_range = first(required_range):last(required_range)+spec.forecast.maxlead
                end
            end
            if intersect(required_range, data_range) !== required_range
                throw(ArgumentError("The data provided in the x11regression spec must cover the range of the supplied data (or the span specified by the span argument of the series spec), as well as any forecasts and backcasts requested by the forecast spec. The required range is $(required_range), but the provided range was only $(data_range)."))
            end
        end
        if !(spec.x11regression.umdata isa X13default)
            data_range = rangeof(spec.x11regression.umdata)
            required_range = rangeof(spec.series.data)
            if spec.series.span isa UnitRange
                required_range = spec.series.span
            elseif spec.series.span isa Span
                if spec.series.span.b isa MIT
                    required_range = spec.series.span.b:last(required_range)
                end
                if spec.series.span.e isa MIT
                    required_range = first(required_range):spec.series.span.e
                end
                ## TODO: treatment of 0.per ranges here
            end
            if !(spec.forecast isa X13default)
                if !(spec.forecast.maxback isa X13default)
                    required_range = first(required_range)-spec.forecast.maxback:last(required_range)
                end
                if !(spec.forecast.maxlead isa X13default)
                    required_range = first(required_range):last(required_range)+spec.forecast.maxlead
                end
            end
            if intersect(required_range, data_range) !== required_range
                throw(ArgumentError("The umdata provided in the x11regression spec must cover the range of the supplied data (or the span specified by the span argument of the series spec), as well as any forecasts and backcasts requested by the forecast spec. The required range is $(required_range), but the provided range was only $(data_range)."))
            end
        end

        if !(spec.x11regression.outlierspan isa X13default)
            if intersect(spec.x11regression.outlierspan, rangeof(spec.series.data)) !== spec.x11regression.outlierspan
                throw(ArgumentError("The outlierspan argument of the x11regression spec must lie within the range of the provided data ($(rangeof(spec.series.data)))). Received: $(spec.x11regression.outlierspan)."))
            end
        end
        if !(spec.x11regression.span isa X13default)
            required_range = rangeof(spec.series.data)
            if spec.series.span isa UnitRange
                required_range = spec.series.span
            elseif spec.series.span isa Span
                if spec.series.span.b isa MIT
                    required_range = spec.series.span.b:last(required_range)
                end
                if spec.series.span.e isa MIT
                    required_range = first(required_range):spec.series.span.e
                end
                ## TODO: treatment of 0.per ranges here
            end
            if intersect(spec.x11regression.span, required_range) !== spec.x11regression.span
                throw(ArgumentError("The span argument of the x11regression spec must lie within the range of the provided data ($(required_range))). Received: $(spec.x11regression.span)."))
            end
        end

        if !(spec.x11regression.variables isa X13default)
            vars = spec.x11regression.variables isa Vector ? spec.x11regression.variables : [spec.x11regression.variables]
            types_used = Set(collect_regvar_types(vars))
            if !(spec.x11regression.usertype isa X13default)
                if spec.x11regression.usertype isa Symbol
                    push!(types_used, spec.x11regression.usertype)
                else
                    for ut in spec.x11regresison.usertype
                        push!(types_used, ut)
                    end
                end
            end

            if !(spec.x11regression.forcecal isa X13default)
                if !(any([:td, :td1coef, :tdstock, :tdstock1coef] .∈ types_used ) && any([:easter, :labor, :thank, :sceaster] .∈ types_used ))
                    @warn "The forcecal argument of the x11regression will not have any effect as the variables argument does not contain both td and holiday regressors."
                end
            end
        end
    end

    if !(spec.x11regression isa X13default) && !(spec.regression isa X13default)
        # TODO: When trading day and/or holiday adjustments are estimated from both the regression and x11regression specs, then the noapply option must be used to ensure that only one set of factors is used in the adjustment...
    end
    
end

var_types_map = Dict{Type,Symbol}(
    ao => :ao,
    aos => :aos,
    ls => :ls,
    lss => :lss,
    tc => :tc,
    so => :so,
    rp => :rp,
    qd => :qd,
    qi => :qi,
    tl => :tl,
    tdstock => :tdstock,
    tdstock1coef => :tdstock1coef,
    easter => :easter,
    labor => :labor,
    thank => :thank,
    sceaster => :sceaster,
    easterstock => :easterstock,
    sincos => :sincos,
    td => :td,
    tdnolpyear => :tdnolpyear,
    td1coef => :td1coef,
    td1nolpyear => :td1nolpyear,
    lpyear => :lpyear,
    lom => :lom,
    loq => :loq,
    seasonal => :seasonal,
)
function collect_regvar_types(vars)
    types_used = Vector{Symbol}()
    for v in vars
        if v isa Symbol
            push!(types_used, v)
        else
            push!(types_used, var_types_map[typeof(v)])
        end
    end
    return types_used
end

export X13spec

function Base.show(io::IO, ::MIME"text/plain", ws::X13spec)
    print(io, "X13 spec\n")

end