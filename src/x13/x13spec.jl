# https://www2.census.gov/software/x-13arima-seats/x-13-data/documentation/docx13as.pdf
# pg 175

# Make a default type,
# Make all types unions of default and the actual type...

struct X13default end
_X13default = X13default()

struct X13series{F<:Frequency}
    appendbcst::Union{Bool,X13default}
    appendfcst::Union{Bool,X13default}
    comptype::Union{Symbol,X13default}
    compwt::Union{Float64,X13default}
    data::TSeries{F}
    decimals::Union{Int64,X13default}
    file::Union{String,X13default}
    format::Union{String,X13default}
    modelspan::Union{UnitRange{MIT{F}},X13default}
    name::Union{String,X13default}
    period::Union{Int64,X13default}
    precision::Union{Int64,X13default}
    print::Union{Vector{Symbol},X13default} #This should just be everything
    save::Union{Vector{Symbol},X13default}
    span::Union{UnitRange{MIT{F}},X13default}
    start::Union{MIT{F},X13default}
    title::Union{String,X13default}
    type::Union{Symbol, X13default}
    divpower::Union{Int64,X13default}
    missingcode::Union{Float64,X13default}
    missingval::Union{Float64,X13default}
    saveprecision::Union{Int64,X13default}
    trimzero::Union{Symbol,X13default}

    # X13series(t::TSeries{F}) where F = new{F}(
    #     _X13default, # appendbcst::Union{Bool,X13default}
    #     _X13default, # appendfcst::Union{Bool,X13default}
    #     _X13default, # comptype::Union{Symbol,X13default}
    #     _X13default, # compwt::Union{Float64,X13default}
    #     deepcopy(t), # data::TSeries{F}
    #     _X13default, # decimals::Union{Int64,X13default}
    #     _X13default, # file::Union{String,X13default}
    #     _X13default, # format::Union{String,X13default}
    #     _X13default, # modelspan::Union{UnitRange{MIT{F}},X13default}
    #     _X13default, # name::Union{String,X13default}
    #     _X13default, # period::Union{Int64,X13default}
    #     _X13default, # precision::Union{Int64,X13default}
    #     [:header, :span, :seriesplot, :specfile, :savefile, :specorig, :missingvaladj, :calendaradjorig, :outlieradjorig, :adjoriginal, :adjorigplot], # print::Union{Vector{Symbol},X13default} #This should just be everything
    #     [:span, :specorig, :missingvaladj, :calendaradjorig, :outlieradjorig, :adjoriginal], # save::Union{Vector{Symbol},X13default} #This should just be everything
    #     _X13default, # span::Union{UnitRange{MIT{F}},X13default}
    #     _X13default, # start::Union{MIT{F},X13default}
    #     _X13default, # title::Union{String,X13default}
    #     _X13default, # type::Union{Symbol, X13default}
    #     _X13default, # divpower::Union{Int64,X13default}
    #     _X13default, # missingcode::Union{Float64,X13default}
    #     _X13default, # missingval::Union{Float64,X13default}
    #     _X13default, # saveprecision::Union{Int64,X13default}
    #     _X13default, # trimzero::Union{Symbol,X13default}
    #     )
end


# TODO: The X13 spec should be either Monthly or Quarterly to determine some defaults

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
    ArimaSpec(p::Union{Int64,Vector{Int64}}) = new(p,0,0,0)
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}}) = new(p,d,0,0)
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}}, q::Union{Int64,Vector{Int64}}) = new(p,d,q,0)
    ArimaSpec(p::Union{Int64,Vector{Int64}}, d::Union{Int64,Vector{Int64}}, q::Union{Int64,Vector{Int64}}, period::Int64) = new(p,d,q,period)
    ArimaSpec(p::Union{Int64,Vector{Int64}},d::Union{Int64,Vector{Int64}},q::Union{Int64,Vector{Int64}},P::Union{Int64,Vector{Int64}},D::Union{Int64,Vector{Int64}},Q::Union{Int64,Vector{Int64}}) = (new(p,d,q,0), new(P,D,Q,0))
end
# TODO: mixture of integer and vector arguments

export ArimaSpec


mutable struct X13arima
    model::Vector{ArimaSpec}
    title::Union{String,X13default}
    ar::Union{Vector{Union{Float64,Missing}},X13default} #default values are 0.1, must be length of AR component
    ma::Union{Vector{Union{Float64,Missing}},X13default} #default values are 0.1, must be length of MA component
    arfixed::Union{Vector{Bool},X13default} 
    mafixed::Union{Vector{Bool},X13default} 

    # function X13arima(title::Union{String,X13default}, model::ArimaSpec)
    #     ar = Vector{Union{Float64,Missing}}()
    #     for k in model.p
    #         push!(ar, missing)
    #     end
    #     ma = Vector{Union{Float64,Missing}}()
    #     for k in model.P
    #         push!(ma, missing)
    #     end

    #     return new(model,title, ar, ma)
    # end
    # X13arima(title::Union{String,X13default}) = X13arima(title,ArimaSpec())
    # X13arima(model::ArimaSpec) = X13arima("",model)
    # X13arima() = X13arima("",ArimaSpec())
end

mutable struct X13automdl
    diff::Union{Tuple{Int64,Int64},X13default}
    acceptdefault::Union{Bool,X13default}
    checkmu::Union{Bool,X13default}
    ljungboxlimit::Union{Float64,X13default}
    maxorder::Union{Tuple{Int64,Int64},X13default}
    maxdiff::Union{Tuple{Int64,Int64},X13default}
    mixed::Union{Bool,X13default}
    print::Union{Vector{Symbol},X13default} #This should just be everything
    savelog::Union{Vector{Symbol},X13default}
    armalimit::Union{Float64,X13default}
    balanced::Union{Bool,X13default}
    exactdiff::Union{Symbol,X13default} #:yes, :no, :first
    fcstlim::Union{Int64,X13default}
    hrinitial::Union{Bool,X13default}
    reducecv::Union{Float64,X13default}
    rejectfcst::Union{Bool,X13default}
    urfinal::Union{Float64,X13default}

    # X13automdl(p::Union{Int64,X13default},P::Union{Int64,X13default}) = new(
    #     (p,P),
    #     false, #acceptdefault
    #     false, #checkmu
    #     0.95, #ljungboxlimit
    #     (2,1), #maxdiff
    #     (2,1), #maxorder
    #     true, #mixed
    #     [:autochoice, :autochoicemdl, :autodefaulttests, :autofinaltests, :autoljungboxtest, :bestfivemdl, :header, :unitroottest, :unitroottestmdl], # print
    #     [:alldiagnostics], # savelog, check appendix
    #     1.0, #armalimit
    #     false, # balanced::Union{Bool,X13default}
    #     :first, # exactdiff::Union{Symbol,X13default} #:yes, :no, :first
    #     15.0, # fcstlim::Union{Float64,X13default}
    #     false, # hrinitial::Union{Bool,X13default}
    #     0.14268, # reducecv::Union{Float64,X13default}
    #     false, # rejectfcst::Union{Bool,X13default}
    #     1.05, # urfinal::Union{Float64,X13default}
    # )
end

mutable struct X13check
    maxlag::Union{Int64,X13default}
    qtype::Union{Symbol,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}
    acflimit::Union{Float64,X13default}
    qlimit::Union{Float64,X13default}
   

    # X13check() = new(
    #     0, # maxlag::Union{Int64,X13default}, CHECK WHEN WRITING SPEC!!!
    #     :ljungbox, # qtype::Union{Symbol,X13default}, one of :ljungbox, :lb, :boxpierce, :bp
    #     [:afc, afcplot, :pacf, pacfplot, :acfsquared, :acfsquaredplot, :normalitytest, :durbinwatson, :friedmantest, histogram], # print::Union{Vector{Symbol},X13default}
    #     [:acf, :pacf, :acfsquared], # save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     1.6, # acflimit::Union{Float64,X13default}
    #     0.05 # qlimit::Union{Float64,X13default}
    # )
end

mutable struct X13estimate
    exact::Union{Symbol,X13default}
    maxiter::Union{Int64,X13default}
    outofsample::Union{Bool,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}
    tol::Union{Float64,X13default}
    file::Union{String,X13default}
    fix::Union{Symbol,X13default}
   

    # X13estimate() = new(
    #     :arma, # exact::Union{Symbol,X13default}, one of :arma, :ma, :none
    #     1500, # maxiter::Union{Int64,X13default}
    #     false, # outofsample::Union{Bool,X13default},
    #     [:options, :model, :estimates, :averagefcsterr, :lkstats, :iterations, :iterationerrors, :regcmatrix, :armacmatrix, :lformulas, :roots, :regressioneffects, :regressionresiduals, :residuals], # print::Union{Vector{Symbol},X13default}
    #     [:model, :estimates, :lkstats, :iterations, :regcmatrix, :armacmatrix, :roots, :regressioneffects, :regressionresiduals, :residuals], # save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     1.0e-5, # tol::Union{Float64,X13default}
    #     "", # file::Union{String,X13default}
    #     :nochange, # fix::Union{Symbol,X13default}
    # )
end

mutable struct X13force
    lambda::Union{Float64,X13default}
    mode::Union{Symbol,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}
    rho::Union{Float64,X13default}
    round::Union{Bool,X13default}
    start::Union{Int64,X13default} #q3
    target::Union{Symbol,X13default}
    type::Union{Symbol,X13default}
    usefcst::Union{Bool,X13default}
    indforce::Union{Bool,X13default}

    # X13force() = new(
    #     0.0, # lambda::Union{Float64,X13default},
    #     :ratio, # mode::Union{Symbol,X13default}, one of :ratio, :diff
    #     [:seasadjtot, :saround, :revsachanges, :rndsachanges], # print::Union{Vector{Symbol},X13default}
    #     [:seasadjtot, :saround, :revsachanges, :rndsachanges, :revsachangespct, :rndsachangespct], # save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     0.729, #rho::Union{Float64,X13default}, # The default for this argument is 0.9 for monthly series, 0.729 for quarterly series ((0.9) 3 ).
    #     false, # round::Union{Bool,X13default},
    #     1M1, # start::Int # start month or quarter...
    #     :original, # target::Union{Symbol,X13default}, one of :original, :caladjust, :permprioradj, :both
    #     :none, # type::Union{Symbol,X13default}, one of :none, :denton, :regress
    #     true, # usefcst::Union{Bool,X13default}
    #     true, # indforce::Union{Bool,X13default}
    # )
end

mutable struct X13forecast
    exclude::Union{Int64,X13default}
    lognormal::Union{Bool,X13default}
    maxback::Union{Int64,X13default}
    maxlead::Union{Int64,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}
    probability::Union{Float64,X13default}
   

    # X13forecast() = new(
    #     0, # exclude::Union{Int64,X13default}
    #     false, # lognormal::Union{Bool,X13default}
    #     0, # maxback::Union{Int64,X13default}
    #     36, # maxlead::Union{Int64,X13default}, #TODO: depends on Q/M 
    #     [:transformed, :variances, :forecasts, :transformedbcst, :backcasts], # print::Union{Vector{Symbol},X13default}
    #     [:transformed, :variances, :forecasts, :transformedbcst, :backcasts], # save::Union{Vector{Symbol},X13default}
    #     0.95, # probability::Union{Float64,X13default}
    # )
end


mutable struct X13history
    endtable::Union{MIT,X13default}
    estimates::Union{Vector{Symbol},X13default}
    fixmdl::Union{Bool,X13default}
    fixreg::Union{Bool,X13default}
    fstep::Union{Vector{Int64},X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    sadjlags::Union{Vector{Int64},X13default}
    start::Union{MIT,X13default}
    target::Union{Symbol,X13default}
    trendlags::Union{Vector{Int64},X13default}
    fixx11reg::Union{Bool,X13default}
    outlier::Union{Symbol,X13default}
    outlierwin::Union{Int64,X13default}
    refresh::Union{Bool,X13default}
    transformfcst::Union{Bool,X13default}
    x11outlier::Union{Bool,X13default}
   

    # X13history() = new(
    #     1990M1, # endtable::MIT #TODO: defaults to end of series...
    #     [:sadj], # estimates::Union{Vector{Symbol},X13default}, can include: [:sadj, :sadjchng, :trend, :tendchng, :seasonal, :aic, :fcst, :arma, :td]
    #     false, # fixmdl::Union{Bool,X13default},
    #     false, # fixreg::Union{Bool,X13default}, #TODO: value makes no sence here
    #     [1,12], # fstep::Union{Vector{Int64},X13default}, #TODO [1,4] for Quarterly
    #     [:header, :outlierhistory, :sarevisions, :sasummary, :chngrevisions, :chngsummary, :indsarevisions, :indsasummary, :trendrevisions, :trendsummary, :trenchchngrevisions, :trendchngsummary, :sfrevisions, :sfsummary, :lkhdhistory, :fcsterrors, :armahistory, :tdhistory, :sfilterhistory, :saestimates, :chngestimates, :indsaestimates, :trendestimates, :trendchngestimates, :sfestimates, :fcsthistory],# print::Union{Vector{Symbol},X13default}
    #     [:outlierhistory, :sarevisions, :chngrevisions, :indsarevisions, :trendrevisions, :trenchchngrevisions, :sfrevisions, :sfsummary, :lkhdhistory, :fcsterrors, :armahistory, :tdhistory, :sfilterhistory, :saestimates, :chngestimates, :indsaestimates, :trendestimates, :trendchngestimates, :sfestimates, :fcsthistory],# save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     Vector{Int64}(), # sadjlags::Union{Vector{Int64},X13default}
    #     nothing, # start::Union{Int64,X13default}
    #     :final, # target::Union{Symbol,X13default}, one of :final, :concurrent
    #     Vector{Int64}(), # trendlags::Union{Vector{Int64},X13default}
    #     false, # fixx11reg::Union{Bool,X13default}
    #     :keep, # outlier::Union{Symbol,X13default}, one of :keep, :remove, :auto
    #     12, # outlierwin::Union{Int64,X13default}, #TODO: 4 for quarterly
    #     false, # refresh::Union{Bool,X13default}
    #     false, # transformfcst::Union{Bool,X13default}
    #     true, # x11outlier::Union{Bool,X13default}
    # )
end

# TODO: May need metadata spec to enforce character limits...

mutable struct X13identify
    diff::Union{Vector{Int64},X13default}
    sdiff::Union{Vector{Int64},X13default}
    maxlag::Union{Int64,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    

    # X13identify() = new(
    #     [0], # diff::Union{Vector{Int64},X13default}
    #     [0], # sdiff::Union{Vector{Int64},X13default}
    #     36, # maxlag::Union{Int64,X13default}, #TODO: 12 for quarterly series
    #     [:afc, :afcplot, :pacf, :pacfplot, :regcoefficients], # print::Union{Vector{Symbol},X13default}
    #     [:afc, :pacf], # save::Union{Vector{Symbol},X13default}
    # )
end

mutable struct X13outlier
    critical::Union{Vector{Float64},X13default}
    lsrun::Union{Int64,X13default}
    method::Union{Symbol,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    span::Union{UnitRange{MIT},X13default}
    types::Union{Vector{Symbol},X13default}
    almost::Union{Float64,X13default}
    tcrate::Union{Float64,X13default}
    
    # X13outlier() = new(
    #     nothing, # critical::Union{Float64,X13default}
    #     0, # lsrun::Union{Int64,X13default}
    #     :addone, # method::Union{Symbol,X13default}, one of :addone, :addall
    #     [:header, :iterations, :tests, :temporaryls, :finaltests], # print::Union{Vector{Symbol},X13default}
    #     [:iterations, :finaltests], # save::Union{Vector{Symbol},X13default} 
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     [1990M1, 1990M1], # span::Vector{MIT} #TODO: make dependent on series...
    #     [:ao, :ls], # types::Union{Vector{Symbol},X13default}, can include :ao, :ls, :tc, :all, :none
    #     0.5, # almost::Union{Float64,X13default}
    #     nothing, # tcrate::Union{Float64,X13default}
    # )
end

mutable struct X13pickmdl
    bcstlim::Union{Int64,X13default}
    fcstlim::Union{Int64,X13default}
    file::Union{String,X13default}
    identify::Union{Symbol,X13default}
    method::Union{Symbol,X13default}
    mode::Union{Symbol,X13default}
    outofsample::Union{Bool,X13default}
    overdiff::Union{Float64,X13default}
    print::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}
    qlim::Union{Int64,X13default}

    
    # X13pickmdl() = new(
    #     20, # bcstlim::Union{Int64,X13default}
    #     15, # fcstlim::Union{Int64,X13default}
    #     "", # file::Union{String,X13default}
    #     :first, # identify::Union{Symbol,X13default}, one of :all, :first
    #     :first, # method::Union{Symbol,X13default}, one of :best, :first
    #     :fcst, # mode::Union{Symbol,X13default}, one of :fcst, :both
    #     false, # outofsample::Union{Bool,X13default}
    #     0.9, # overdiff::Union{Float64,X13default}
    #     [:pickmdlchoice, :header, :usermodels],# print::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     5, # qlim::Union{Int64,X13default}
    # )
end


mutable struct X13regression
    aicdiff::Union{Vector{Union{Float64,Missing}},X13default}
    aictest::Union{Vector{Symbol},X13default}
    chi2test::Union{Bool,X13default}
    chi2testcv::Union{Float64,X13default}
    data::Union{TSeries,MVTSeries, X13default}
    file::Union{String,X13default}
    format::Union{String,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    pvaictest::Union{Float64,X13default}
    start::Union{MIT,X13default}
    testalleaster::Union{Bool,X13default}
    tlimit::Union{Float64,X13default}
    user::Union{Vector{Symbol},X13default}
    usertype::Union{Vector{Symbol},X13default}
    variables::Union{Vector{Symbol},X13default}
    b::Union{Vector{Float64},X13default}
    bfixed::Union{Vector{Bool},X13default}
    centeruser::Union{Symbol,X13default}
    eastermeans::Union{Bool,X13default}
    noapply::Union{Symbol,X13default}
    tcrate::Union{Float64,X13default}


    
    # X13regression() = new(
    #     [0.0], # aicdiff::Vector{Union{Float64,Missing}}
    #     :none, # aictest::Union{Symbol,X13default}, one of :none, :td, :tdnolpyear, :tdstock, :td1coef, :td1nolpyear, :tdstock1coef, :lom, :loq, :lpyear, :easter, :easterstock, :user
    #     false, # chi2test::Union{Bool,X13default}
    #     0.01, # chi2testcv::Union{Float64,X13default}
    #     nothing, # data::MVTSeries
    #     "", # file::Union{String,X13default}
    #     "", # format::Union{String,X13default} #todo: align with printed values
    #     [:regressionmatrix, :aictest, :outlier, :aoutlier, :levelshift, :seasonaloutlier, :transitory, :temporarychange, :tradingday, :holiday, :regseasonal, :userdef, :chi2test, :dailyweights],# print::Union{Vector{Symbol},X13default}
    #     [:regressionmatrix, :outlier, :aoutlier, :levelshift, :seasonaloutlier, :transitory, :temporarychange, :tradingday, :holiday, :regseasonal, :userdef],# save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     nothing, # pvaictest::Union{Float64,X13default}
    #     nothing, # start::Union{MIT,Nothing}
    #     false, # testalleaster::Union{Bool,X13default}
    #     nothing,# tlimit::Union{Float64,X13default}
    #     Vector{Symbol}(), # user::Union{Vector{Symbol},X13default}
    #     Vector{Symbol}(), # usertype::Union{Vector{Symbol},X13default}, can include :constant, :seasonal, :td, :lom, :loq, :lpyear, :ao, :ls, :so, :transitory, :user, :holiday, :holiday2, :holiday3, :holiday4, :holiday5
    #     Vector{Symbol}(), # variables::Union{Vector{Symbol},X13default}
    #     Vector{Float64}(), # b::Union{Vector{Float64},X13default} #todo: enable fixing of values...
    #     :none, # centeruser::Union{Symbol,X13default}, one of :none, :mean, :seasonal
    #     true, # eastermeans::Union{Bool,X13default}
    #     Vector{Symbol}(), # noapply::Union{Symbol,X13default}, can include :td, :holiday, :ao, :ls, :tc, :so, :userseasonal, :user
    #     nothing, # tcrate::Union{Float64,Nothing}
    # )
end

mutable struct X13seats
    appendfcst::Union{Bool,X13default}
    finite::Union{Bool,X13default}
    hpcycle::Union{Bool,X13default}
    noadmiss::Union{Bool,X13default}
    out::Union{Int64,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    printphtrf::Union{Bool,X13default}
    qmax::Union{Int64,X13default}
    statseas::Union{Bool,X13default}
    tabtables::Union{Vector{Symbol},X13default}
    bias::Union{Int64,X13default}
    epsiv::Union{Float64,X13default}
    epsphi::Union{Int64,X13default}
    hplan::Union{Float64,X13default}
    imean::Union{Bool,X13default}
    maxit::Union{Int64,X13default}
    rmod::Union{Float64,X13default}
    xl::Union{Float64,X13default}
    
    # X13seats() = new(
    #     false, # appendfcst::Union{Bool,X13default}
    #     false, # finite::Union{Bool,X13default}
    #     false, # hpcycle::Union{Bool,X13default}
    #     false, # noadmiss::Union{Bool,X13default}
    #     1, # out::Union{Int64,X13default}
    #     [:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:seriesfcstdecomp,:seasonaladjfcstdecomp,:transitoryfcstdecomp,:seasadjconst, :trendconst,:totaladjustment,:difforiginal,:diffseasonaladj,:difftrend,:seasonalsum],# print::Union{Vector{Symbol},X13default}
    #     [:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:seriesfcstdecomp,:seasonaladjfcstdecomp,:transitoryfcstdecomp,:seasadjconst, :trendconst,:totaladjustment,:difforiginal,:diffseasonaladj,:difftrend,:seasonalsum,:componentmodels,:filtersaconc,:filtersasym,:filtertrendconc,:filterdrendsym,:squaredgainsaconc,:squaredgainsasym,:squaredfaintrendconc,:squaredgaintrendsym,:timeshiftsaconc,:timeshifttrendconc,:wkendfilter,:seasonalpct,:irregularpct,:transitorypct,:adjustfacpct],# print::Union{Vector{Symbol},X13default}
    #     [:seatsmodel,:x13model,:normalitytest,:overunderestimation,:totalssquarederror,:componentvariance,:concurrentesterror,:percentreductionse,:averageabsdiffannual,:seasonalsignif],# save::Union{Vector{Symbol},X13default} 
    #     false, # printphtrf::Union{Bool,X13default}
    #     50, # qmax::Union{Int64,X13default}
    #     true, # statseas::Union{Bool,X13default}
    #     [:all], # tabtables::Union{Vector{Symbol},X13default}, can include :all, :xo, :n, :s, :p, :u, :c, :cal, :pa, :cy, :ltp, :er, :rg0, :rgsa, :stp, :stn, :rtp, rtsa
    #     1, # bias::Union{Int64,X13default}
    #     0.001, # epsiv::Union{Float64,X13default}
    #     2, # epsphi::Union{Int64,X13default}
    #     nothing, # hplan::Union{Float64,X13default}
    #     false, # imean::Union{Bool,X13default}
    #     20, # maxit::Union{Int64,X13default}
    #     0.80, # rmod::Union{Float64,X13default}
    #     0.99, # xl::Union{Float64,X13default}
    # )
end

mutable struct X13slidingspans
    cutchng::Union{Float64,X13default}
    cutseas::Union{Float64,X13default}
    cuttd::Union{Float64,X13default}
    fixmdl::Union{Symbol,X13default}
    fixreg::Union{Vector{Symbol},X13default}
    length::Union{Int64,X13default}
    numspans::Union{Int64,X13default}
    outlier::Union{Symbol,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    start::Union{MIT,X13default}
    additivesa::Union{Symbol,X13default}
    fixx11reg::Union{Bool,X13default}
    x11outlier::Union{Bool,X13default}
    
    
    # X13slidingspans() = new(
    #     5.0, # cutchng::Union{Float64,X13default}
    #     5.0, # cutseas::Union{Float64,X13default}
    #     1.0, # cuttd::Union{Float64,X13default}
    #     :yes, # fixmdl::Union{Bool,X13default}, one of :yes, :no, :clear
    #     Vector{Symbol}(), # fixreg::Union{Bool,X13default}, can include :td, :holiday, :outlier, :user
    #     nothing, # length::Union{Int64,X13default}
    #     2, # numspans::Union{Int64,X13default} #TODO: should be explicitly selected
    #     :keep, # outlier::Union{Symbol,X13default}, one of :keep, :remove, :yes
    #     [:header, :ssftest, :factormeans, :percent, :summary, :yysummary, :indfactormeans, :indpercent, :indsummary,:yypercent, :sfspans, :chngspans, :saspans, :ychngspans, :tdspans,:indyypercent,:indyysummary,:indsfspans,:indchngspans,:indsaspans,:indychngspans],# print::Union{Vector{Symbol},X13default}
    #     [:yysummary,:sfspans, :chngspans, :saspans, :ychngspans, :tdspans,:indsfspans,:indchngspans,:indsaspans,:indychngspans],# save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     nothing, # start::Union{MIT,Nothing}
    #     :difference, # additivesa::Union{Symbol,X13default}, one of :difference, :percent
    #     true, # fixx11reg::Union{Bool,X13default}
    #     true, # x11outlier::Union{Bool,X13default}
    # )
end

mutable struct X13spectrum
    logqs::Union{Bool,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    qcheck::Union{Bool,X13default}
    start::Union{MIT,X13default}
    tukey120::Union{Bool,X13default}
    decibel::Union{Bool,X13default}
    difference::Union{Symbol,X13default}
    maxar::Union{Int64,X13default}
    peakwidth::Union{Int64,X13default}
    series::Union{Symbol,X13default}
    siglevel::Union{Int64,X13default}
    type::Union{Symbol,X13default}
    
    
    # X13spectrum() = new(
    #     false, # logqs::Union{Bool,X13default}
    #     [:qcheck, :qs, :specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa,:tukeypeaks],# print::Union{Vector{Symbol},X13default}
    #     [:specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa,:tukeyspecorig, :tukeyspecsa, :tukeyspecirr,:tukeyspecseatssa,:tukeyspecseatsirr,:tukeyspecextresiduals,:tukeyspecresidual,:tukeyspeccomposite,:tukeyspecindirr,:tukeyspecindsa],# save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}
    #     false, # qcheck::Union{Bool,X13default}
    #     nothing, # start::Union{MIT,Nothing}
    #     true, # tukey120::Union{Bool,X13default}
    #     true, # decibel::Union{Bool,X13default}
    #     :yes, # difference::Union{Symbol,X13default}, one of :yes, :no, :first
    #     30, # maxar::Union{Int64,X13default}
    #     1, # peakwidth::Union{Int64,X13default}
    #     :adjoriginal, # series::Union{Symbol,X13default}, one of :original, :outlieradjoriginal, :adjoriginal, :modoriginal
    #     6, # siglevel::Union{Int64,X13default}
    #     :arspec, # type::Union{Symbol,X13default}, one of :arspec, :peridogram
    # )
end

mutable struct X13transform
    adjust::Union{Symbol,X13default}
    aicdiff::Union{Float64,X13default}
    data::Any
    file::Union{String,X13default}
    format::Union{String,X13default}
    func::Union{Symbol,X13default} #TODO should be function
    mode::Union{Vector{Symbol},X13default}
    name::Union{String,X13default}
    power::Union{Float64,X13default}
    precision::Union{Int64,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default}     
    start::Union{MIT,X13default}
    title::Union{String,X13default}
    type::Union{Symbol,X13default}
    constant::Union{Float64,X13default}
    trimzero::Union{Symbol,X13default}
    
    # X13transform() = new(
    #     :none, # adjust::Union{Symbol,X13default}, one of :none, :lom, :loq, :lpyear
    #     -2.0, # aicdiff::Union{Float64,X13default} #TODO: different default for quarterly series
    #     [], # data::Any
    #     "", # file::Union{String,X13default}
    #     "", # format::Union{String,X13default}
    #     :none, # func::Union{Symbol,X13default}, one of :none, :log, :sqrt, :inverse, :logistic
    #     Vector{Symbol}(), # mode::Union{Symbol,X13default}, can include :ratio, :diff, :percent
    #     "", # name::Union{String,X13default}
    #     1.0, # power::Union{Float64,X13default}
    #     0, # precision::Union{Int64,X13default}
    #     [:aictransform, :seriesconstant, :seriesconstantplot, :prior, :permprior, :tempprior, :prioradjusted, :permprioradjusted, :prioradjustedptd, :permprioradjustedptd, :transformed],# print::Union{Vector{Symbol},X13default}
    #     [:seriesconstant, :prior, :permprior, :tempprior, :prioradjusted, :permprioradjusted, :prioradjustedptd, :permprioradjustedptd, :transformed],# save::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}     
    #     nothing, # start::Union{MIT,Nothing}
    #     "", # title::Union{String,X13default}
    #     :permanent, # type::Union{Symbol,X13default}, one of :permanent, :temporary
    #     0.0, # constant::Union{Float64,X13default}
    #     :yes, # trimzero::Union{Symbol,X13default}, one of :span, :yes, :no
        
    # )
end


mutable struct X13x11
    appendbcst::Union{Bool,X13default}
    appendfcst::Union{Bool,X13default}
    final::Union{Vector{Symbol},X13default}
    mode::Union{Symbol,X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default}     
    seasonalma::Union{Vector{Symbol},X13default}
    sigmalim::Union{Vector{Float64},X13default}
    title::Union{Vector{String},X13default}
    trendma::Union{Int64,X13default}
    type::Union{Symbol,X13default}
    calendarsigma::Union{Symbol,X13default}
    centerseasonal::Union{Bool,X13default}
    keepholiday::Union{Bool,X13default}
    print1stpass::Union{Bool,X13default}
    sfshort::Union{Bool,X13default}
    sigmavec::Union{Vector{Symbol},X13default}
    trendic::Union{Float64,X13default}
    true7term::Union{Bool,X13default}

    # X13x11() = new(
    #     false, # appendbcst::Union{Bool,X13default}
    #     false, # appendfcst::Union{Bool,X13default}
    #     Vector{Symbol}(), # final::Union{Vector{Symbol},X13default}, can include :ao, :ls, :tc, :user
    #     :mult, # mode::Union{Symbol,X13default}, one of :mult, :add, :logadd #TODO: default depends on transform spec
    #     [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:ftestd8,:irregular,:irrwt,:moveseasrat,:origchanges,:qstat,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:tdaytype,:totaladjustment,:trend,:tendchanges,:unmodsi,:unmodsiox,:x11diag,:yrtotals,:adjoriginalc,:adjoriginald,:autosf,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsib4,:replacsib9,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:irregularplot,:origwsaplot,:ratioplotorig,:ratioplotsa,:seasadjplot,:seasonalplot,:trendplot],# print::Union{Vector{Symbol},X13default}
    #     [:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:irregular,:irrwt,:origchanges,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:totaladjustment,:trend,:tendchanges,:unmodsi,:unmodsiox,:adjoriginalc,:adjoriginald,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:adjustfacpct,:calendaradjchangespct,:irregularpct,:origchangespct,:sachangespct,:seasonalpct,:trendchangespct],# print::Union{Vector{Symbol},X13default}
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}     
    #     Vector{Symbol}(), # seasonalma::Union{Vector{Symbol},X13default}, can include :s3x1, :s3x3, :s3x5, :s3x9, :s3x15, :stable, x11default
    #     Vector{Float64}(), # sigmalim::Union{Vector{Float64},X13default}
    #     Vector{String}(), # title::Vector{String}
    #     nothing,# trendma::Union{Int64,X13default}
    #     :sa, # type::Union{Symbol,X13default}, one of :summary, :trend, :sa
    #     :none, # calendarsigma::Union{Symbol,X13default}, one of :none, :select
    #     false, # centerseasonal::Union{Bool,X13default}
    #     false, # keepholiday::Union{Bool,X13default}
    #     false, # print1stpass::Union{Bool,X13default}
    #     false, # sfshort::Union{Bool,X13default}
    #     Vector{Symbol}(), # sigmavec::Union{Vector{Symbol},X13default},
    #     nothing, # trendic::Union{Nothing,Float64}
    #     false, # true7term::Union{Bool,X13default}
        
    # )
end

mutable struct X13x11regression
    aicdiff::Union{Float64,X13default}
    aictest::Union{Symbol,X13default}
    critical::Union{Float64,X13default}
    data::Any
    file::Union{String,X13default}
    format::Union{String,X13default}
    outliermethod::Union{Symbol,X13default}
    outlierspan::Union{UnitRange{MIT}, X13default}
    print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} 
    savelog::Union{Vector{Symbol},X13default} 
    prior::Union{Bool,X13default}
    sigma::Union{Float64,X13default}
    span::Union{UnitRange{MIT},X13default}
    start::Union{MIT,X13default}
    tdprior::Union{Vector{Float64},X13default}
    user::Union{Vector{Symbol},X13default}
    usertype::Union{Vector{Symbol},X13default}
    variables::Union{Vector{Any},X13default}
    almost::Union{Float64,X13default}
    b::Union{Vector{Float64},X13default}
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
    

    # X13x11regression() = new(
    #     0.0, # aicdiff::Union{Float64,X13default}
    #     :none, # aictest::Union{Symbol,X13default}, one of :none, :td, :tdstock, :td1coef, :tdstock1coef, :easter, :user
    #     nothing, # critical::Union{Float64,X13default},
    #     nothing, # data::Any
    #     "", # file::Union{String,X13default}
    #     "", # format::Union{String,X13default}
    #     :addone, # outliermethod::Union{Symbol,X13default}, one of :addone, :addall
    #     Vector{MIT}(), # outlierspan::Vector{MIT}
    #     [:priortd, :extremeval, :x11reg, :tradingday, :combtradingday, :holiday, :calendar, :combcalendar, :outlierhdr, :xaictest, :extremevalb, :x11regb, :tradingdayb, :combtradingdayb, :holidayb, calendarb, :combcalendarb, :outlieriter, :outliertests, :xregressionmatrix, :xregressioncmatrix],# print::Union{Vector{Symbol},X13default}
    #     [:priortd, :extremeval, :tradingday, :combtradingday, :holiday, :calendar, :combcalendar, :extremevalb, :tradingdayb, :combtradingdayb, :holidayb, calendarb, :combcalendarb, :outlieriter, :xregressionmatrix, :xregressioncmatrix],# save::Union{Vector{Symbol},X13default},
    #     [:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}     
    #     false, # prior::Union{Bool,X13default}
    #     2.5, # sigma::Union{Float64,X13default}
    #     Vector{MIT}(), # span::Vector{MIT}
    #     nothing, # start::Union{Nothing,MIT}
    #     Vector{Float64}(), # tdprior::Union{Vector{Float64},X13default}
    #     Vector{Symbol}(),# user::Union{Vector{Symbol},X13default}
    #     Vector{Symbol}(),# usertype::Union{Vector{Symbol},X13default}, can include :td, :holiday, :user
    #     Vector{Any}(), # variables::Vector{Any}
    #     0.5, # almost::Union{Float64,X13default}
    #     Vector{Float64}(), # b::Union{Vector{Float64},X13default}
    #     :none, # centeruser::Union{Symbol,X13default}, one of :none, :mean, :seasonal
    #     true, # eastrmeans::Union{Bool,X13default}
    #     false, # forcecal::Union{Bool,X13default}
    #     Vector{Symbol}(),# noapply::Union{Symbol,X13default}, can include :td, :holiday
    #     false, # reweight::Union{Bool,X13default}
    #     nothing, # umdata::Any
    #     "", # umfile::Union{String,X13default}
    #     "", # umformat::Union{String,X13default}
    #     "", # umname::Union{String,X13default}
    #     0, # umprecision::Union{Int64,X13default}
    #     nothing, # umstart::Union{Nothing,MIT}
    #     true, # umtrimzero::Union{Symbol,X13default}
        
    # )
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
    metadata::Union{Dict{String,String},X13default}
    identify::Union{X13identify,X13default}
    outlier::Union{X13outlier,X13default}
    seats::Union{X13seats,X13default} # not supported
    slidingspans::Union{X13slidingspans,X13default}
    spectrum::Union{X13spectrum,X13default}

    X13spec(F::Frequency) = new{F}(
        _X13default, # series::Union{X13series,X13default}
        _X13default, # arima::Union{X13arima,X13default}
        _X13default, # estimate::Union{X13estimate,X13default}
        _X13default, # transform::Union{X13transform,X13default}
        _X13default, # regression::Union{X13regression,X13default}
        _X13default, # automdl::Union{X13automdl,X13default} #or its own type
        _X13default, # x11::Union{X13x11,X13default}
        _X13default, # x11regression::Union{X13x11regression,X13default}
        _X13default, # check::Union{X13check,X13default}
        _X13default, # forecast::Union{X13forecast,X13default}
        # # composite::X13composite # not supported
        _X13default, # force::Union{X13force,X13default}
        _X13default, # pickmdl::Union{X13pickmdl,X13default}
        _X13default, # history::Union{X13history,X13default}
        _X13default, # metadata::Dict{String,String}
        _X13default, # identify::Union{X13identify,X13default}
        _X13default, # outlier::Union{X13outlier,X13default}
        _X13default, # seats::Union{X13seats,X13default} # not supported
        _X13default, # slidingspans::Union{X13slidingspans,X13default}
        _X13default, # spectrum::Union{X13spectrum,X13default}
    )
    X13spec(t::TSeries{F}; kwargs...) where F = new{F}(
        series(t; kwargs...), # series::Union{X13series,X13default}
        _X13default, # arima::Union{X13arima,X13default}
        _X13default, # estimate::Union{X13estimate,X13default}
        _X13default, # transform::Union{X13transform,X13default}
        _X13default, # regression::Union{X13regression,X13default}
        _X13default, # automdl::Union{X13automdl,X13default} #or its own type
        _X13default, # x11::Union{X13x11,X13default}
        _X13default, # x11regression::Union{X13x11regression,X13default}
        _X13default, # check::Union{X13check,X13default}
        _X13default, # forecast::Union{X13forecast,X13default}
        # # composite::X13composite # not supported
        _X13default, # force::Union{X13force,X13default}
        _X13default, # pickmdl::Union{X13pickmdl,X13default}
        _X13default, # history::Union{X13history,X13default}
        _X13default, # metadata::Dict{String,String}
        _X13default, # identify::Union{X13identify,X13default}
        _X13default, # outlier::Union{X13outlier,X13default}
        _X13default, # seats::Union{X13seats,X13default} # not supported
        _X13default, # slidingspans::Union{X13slidingspans,X13default}
        _X13default, # spectrum::Union{X13spectrum,X13default}
    )
end



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

* **file** (String) - See the X13ArimaSeats manual.

* **format** (String) - See the X13ArimaSeats manual.

* **modelspan** (UnitRange{MIT}) - Specifies the span (data interval) of the data to be used to determine all regARIMA
    model coefficients. This argument can be utilized when, for example, the user does not
    want data early in the series to affect the forecasts, or, alternatively, data late in the
    series to affect regression estimates used for preadjustment before seasonal adjustment.
    The default span corresponds to the span of the series being analyzed. 
    
    For example, for monthly data,
    the statement `modelspan=1968M1:last(dateof(ts))`` causes whatever regARIMA model is specified in
    other specs to be estimated from the time series data starting in January, 1968 and
    ending at the end date of the TSeries `ts`.

* **name** (String) - The name of the time series. The name must be enclosed in quotes and may contain up
    to 64 characters. Up to the first 16 characters will be printed as a label on every page.
    When specified with the predefined formats of the format argument, the first six (or
    eight, if format="cs") characters of this name are also used to check if the program is
    reading the correct series, or to find a particular series in a file where many series are
    stored.

* **period** (Int64) - Seasonal period of the series. If X-11 seasonal adjustments are generated, the only values
    currently accepted by the program are 12 for Monthly series and 4 for Quarterly series.
    If SEATS adjustments are generated, the values currently accepted by the program are
    12 for Monthly series, 6 for bimonthly series, 4 for Quarterly series, 2 for HalfYearly series.
    and 1 for Yearly series (primarily for trends). Otherwise, any seasonal period up to 12
    can be specified. (This limit can be changed—see Section 2.8 of the manual.) The default value for
    period is 12.

* **precision** (Int64) - The number of decimal digits to be read from the time series. This option can only be
    used with the predefined formats of the format argument. This value must be an integer
    between 0 and 5, inclusive (for example, `precision=5`). The default is 0. If precision
    is used in a series spec that does not use one of the predefined formats, the argument is
    ignored.

* **span** (UnitRange{MIT}) - Limits the data utilized for the calculations and analysis to a span (data interval) of
    the available time series. The default span corresponds to the span of the series being analyzed. The start and end 
    dates of the span must both lie within the series, and the start date must precede the end date.

    For example, for monthly data,
    the statement `modelspan=1968M1:last(dateof(ts))`` causes whatever regARIMA model is specified in
    other specs to be estimated from the time series data starting in January, 1968 and
    ending at the end date of the TSeries `ts`. 

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

* **trimzero** (Symbol) - If `trimzero=:no`, zeroes at the beginning or end of a time series entered via the file
    argument are treated as series values. If `trimzero=:span`, causes leading and trailing
    zeros to be ignored outside the span of data being analyzed (the span argument must
    be specified with both a starting date and an ending date). The default (`trimzero=:yes`)
    causes leading and trailing zeros to be ignored. Note that when the format argument is
    set to either free, datevalue, x13save, or tramo, all values input are treated as series
    values, regardless of the value of trimzero.

"""
function series(t::TSeries{F}; 
    appendbcst::Union{Bool,X13default}=_X13default,
    appendfcst::Union{Bool,X13default}=_X13default,
    comptype::Union{Symbol,X13default}=_X13default,
    compwt::Union{Float64,X13default}=_X13default,
    decimals::Union{Int64,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    modelspan::Union{UnitRange{MIT{F}},X13default}=_X13default,
    name::Union{String,X13default}=_X13default,
    period::Union{Int64,X13default}=_X13default,
    precision::Union{Int64,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:header, :span, :seriesplot, :specfile, :savefile, :specorig, :missingvaladj, :calendaradjorig, :outlieradjorig, :adjoriginal, :adjorigplot],
    save::Union{Vector{Symbol},X13default}=[:span, :specorig, :missingvaladj, :calendaradjorig, :outlieradjorig, :adjoriginal],
    span::Union{UnitRange{MIT{F}},X13default}=_X13default,
    start::Union{MIT{F},X13default}=_X13default,
    title::Union{String,X13default}=_X13default,
    type::Union{Symbol, X13default}=_X13default,
    divpower::Union{Int64,X13default}=_X13default,
    missingcode::Union{Float64,X13default}=_X13default,
    missingval::Union{Float64,X13default}=_X13default,
    saveprecision::Union{Int64,X13default}=_X13default,
    trimzero::Union{Symbol,X13default}=_X13default
) where F<:Frequency
    data=copy(t)
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

    return X13series(appendbcst, appendfcst, comptype, compwt, data, decimals, file, format, modelspan,name, period, precision, print, save, span,start,title,type,divpower,missingcode,missingval,saveprecision,trimzero)
end
series!(spec::X13spec{F}, t::TSeries{F}; kwargs...) where F = (spec.series = series(t; kwargs...))
#TODO: Another end date specification, with the form 0.per, is available to set the ending date
    # of modelspan to always be the most recent occurrence of a specific calendar month
    # (quarter for quarterly data) in the span of data analyzed, where per denotes the calendar
    # month (quarter). Thus, if the span of data considered ends in a month other than
    # December, modelspan=(,0.dec) will cause the model parameters to stay fixed at the
    # values obtained from data ending in the next-to-final calendar year of the span.
# TODO The start date of the time series in the format start=year.seasonal period. (See Section
    # 3.3 and the examples in the Manual.) The default value of start is 1.1. (See DETAILS.)

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

* **arfixed** (Vector{Bool}) - Specifies for each element in the `ar` argument whether to hold the
    value fixed. Must be the same length as the `ar` argument.

* **mafixed** (Vector{Bool}) - Specifies for each element in the `ma` argument whether to hold the
    value fixed. Must be the same length as the `ma` argument.

* **title** (String) - Specifies a title for the ARIMA model, in quotes. It must be less than 80 characters.
    The title appears above the ARIMA model description and the table of estimates. The
    default is to print ARIMA Model.

"""
function arima(model::ArimaSpec...; 
    title::Union{String,X13default}=_X13default,
    ar::Union{Vector{Union{Float64,Missing}},X13default}=_X13default,
    ma::Union{Vector{Union{Float64,Missing}},X13default}=_X13default,
    arfixed::Union{Vector{Bool},X13default}=_X13default,
    mafixed::Union{Vector{Bool},X13default}=_X13default,
)
    # checks and logic
    
    #place specs in a vector
    model = [model...]

    # ar arguments have correct length
    if !(ar isa X13default)
        @assert length(ar) == length(model[1].p) 
    end
    if !(ma isa X13default)
        @assert length(ma) == length(model[1].q) 
    end

    # fixed arguments have correct length
    if !(arfixed isa X13default)
        @assert length(arfixed) == length(ar) 
    end
    if !(mafixed isa X13default)
        @assert length(mafixed) == length(ma) 
    end

    if title isa String && length(title) > 79
        @warn "Series title trunctated to 79 characters. Full title: $title"
        title = title[1:79]
    end

    return X13arima(model, title, ar, ma, arfixed, mafixed)
end
arima!(spec::X13spec{F}, model::ArimaSpec...; kwargs...) where F = (spec.arima = arima(model; kwargs...))


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

* **diff** (Tuple{Int64,Int64}) - Fixes the orders of differencing to be used in the automatic ARIMA model identification
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

* **maxdiff** (Tuple{Int64,Int64}) - Specifies the maximum orders of regular and seasonal differencing 
    for the automatic
    identification of differencing orders. The maxdiff argument has two input values, the
    maximum regular differencing order and the maximum seasonal differencing order. Acceptable 
    values for the maximum order of regular differencing are 1 or 2, and the acceptable value 
    for the maximum order of seasonal differencing is 1. If specified in the same
    spec file as the maxdiff argument, the values for the diff argument are ignored and the
    program performs automatic identification of nonseasonal and seasonal differencing with
    the limits specified in maxdiff. The default is `maxdiff = (2, 1)`.

* **maxorder** (Tuple{Int64,Int64}) - Specifies the maximum orders of the regular and seasonal ARMA polynomials 
    to be examined during the automatic ARIMA model identification procedure. The maxorder
    argument has two input values, the maximum order of regular ARMA model to be tested
    and the maximum order of seasonal ARMA model to be tested. The maximum order for
    the regular ARMA model must be greater than zero, and can be at most 4; the maximum
    order for the seasonal ARMA model can be either 1 or 2. The default is `maxorder = (2, 1)`.

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

* **exactdiff** (Symbol) - Controls if exact likelihood estimation is used when Hannen-Rissanen fails in automatic
    difference identification procedure (`exactdiff = :yes`), or if conditional likelihood estimation is used 
    (`exactdiff = :no`). The default is to start with exact likelihood estimation, and switch to conditional if 
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
    diff::Union{Tuple{Int64,Int64},X13default}=_X13default,
    acceptdefault::Union{Bool,X13default}=_X13default,
    checkmu::Union{Bool,X13default}=_X13default,
    ljungboxlimit::Union{Float64,X13default}=_X13default,
    maxorder::Union{Tuple{Int64,Int64},X13default}=_X13default,
    maxdiff::Union{Tuple{Int64,Int64},X13default}=_X13default,
    mixed::Union{Bool,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:autochoice, :autochoicemdl, :autodefaulttests, :autofinaltests, :autoljungboxtest, :bestfivemdl, :header, :unitroottest, :unitroottestmdl],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    armalimit::Union{Float64,X13default}=_X13default,
    balanced::Union{Bool,X13default}=_X13default,
    exactdiff::Union{Symbol,X13default}=_X13default,
    fcstlim::Union{Int64,X13default}=_X13default,
    hrinitial::Union{Bool,X13default}=_X13default,
    reducecv::Union{Float64,X13default}=_X13default,
    rejectfcst::Union{Bool,X13default}=_X13default,
    urfinal::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    #TODO: Acceptable values for the regular differencing orders are 0, 1 and 2; 
    # acceptable values for the seasonal differencing orders are 0 and 1.
    #TODO Acceptable 
    # values for the maximum order of regular differencing are 1 or 2, and the acceptable value 
    #     for the maximum order of seasonal differencing is 1

    # TODO: The maximum order for
    # the regular ARMA model must be greater than zero, and can be at most 4; the maximum
    # order for the seasonal ARMA model can be either 1 or 2.

    #TODO: reducecv should be between 0 and 1

    #TODO: urfinal value should be greater than one.

    return X13automdl(diff,acceptdefault,checkmu,ljungboxlimit,maxorder,maxdiff,mixed,print,savelog,armalimit,balanced,exactdiff,fcstlim,hrinitial,reducecv,rejectfcst,urfinal)
end
automdl!(spec::X13spec{F}; kwargs...) where F = (spec.automdl = automdl(; kwargs...))


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
    print::Union{Vector{Symbol},X13default}=[:afc, :afcplot, :pacf, :pacfplot, :acfsquared, :acfsquaredplot, :normalitytest, :durbinwatson, :friedmantest, :histogram],
    save::Union{Vector{Symbol},X13default}=[:acf, :pacf, :acfsquared],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    acflimit::Union{Float64,X13default}=_X13default,
    qlimit::Union{Float64,X13default}=_X13default
)
    # checks and logic
    return X13check(maxlag,qtype,print,save,savelog,acflimit,qlimit)
end
check!(spec::X13spec{F}; kwargs...) where F = (spec.check = check(; kwargs...))

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

* **file** (String) - See the manual.

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
    print::Union{Vector{Symbol},X13default}=[:options, :model, :estimates, :averagefcsterr, :lkstats, :iterations, :iterationerrors, :regcmatrix, :armacmatrix, :lformulas, :roots, :regressioneffects, :regressionresiduals, :residuals],
    save::Union{Vector{Symbol},X13default}=[:model, :estimates, :lkstats, :iterations, :regcmatrix, :armacmatrix, :roots, :regressioneffects, :regressionresiduals, :residuals],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    tol::Union{Float64,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    fix::Union{Symbol,X13default}=_X13default,
)
    # checks and logic
    return X13estimate(exact,maxiter,outofsample,print,save,savelog,tol,file,fix)
end
estimate!(spec::X13spec{F}; kwargs...) where F = (spec.estimate = estimate(; kwargs...))
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

* **start** (Int64) - This option sets the beginning of the yearly benchmark period over which the seasonally
    adjusted series will be forced to sum to the total. Unless start is used, the year is
    assumed to be the calendar year for the procedure invoked by setting `type=:denton` or
    `type=:regress`, but an alternate starting period can be specified for the year (such as the
    start of a fiscal year) by assigning to forcestart the month (1-12) or quarter (1-4)
    of the beginning of the desired yearly benchmarking period.
    For example, to specify a fiscal year which starts in October and ends in September, set
    `start=10`. To specify a fiscal year which starts in the third quarter
    of one year and ends in the second quarter of the next, set `start=3` (for a Quarterly series).

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
    print::Union{Vector{Symbol},X13default}=[:seasadjtot, :saround, :revsachanges, :rndsachanges],
    save::Union{Vector{Symbol},X13default}=[:seasadjtot, :saround, :revsachanges, :rndsachanges, :revsachangespct, :rndsachangespct],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    rho::Union{Float64,X13default}=_X13default,
    round::Union{Bool,X13default}=_X13default,
    start::Union{Int64,X13default}=_X13default,
    target::Union{Symbol,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
    usefcst::Union{Bool,X13default}=_X13default,
    indforce::Union{Bool,X13default}=_X13default,
)
    # checks and logic
    # TODO: printing start will be difficult

    return X13force(lambda,mode,print,save,savelog,rho,round,start,target,type,usefcst,indforce)
end
force!(spec::X13spec{F}; kwargs...) where F = (spec.force = force(; kwargs...))


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
    print::Union{Vector{Symbol},X13default}=[:transformed, :variances, :forecasts, :transformedbcst, :backcasts],
    save::Union{Vector{Symbol},X13default}=[:transformed, :variances, :forecasts, :transformedbcst, :backcasts],
    probability::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    return X13forecast(exclude,lognormal,maxback,maxlead,print,save,probability)
end
forecast!(spec::X13spec{F}; kwargs...) where F = (spec.forecast = forecast(; kwargs...))

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

* **estimates** (Vector{Symbol}) - Determines which estimates from the regARIMA modeling and/or the X-11 seasonal
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

* **fstep** (Vector{Int64}) - Specifies a vector of up to four (4) forecast leads that will be analyzed in the history
    analysis of forecast errors. Example: `fstep=[1, 2, 12]` will produce an error analysis for
    the 1-step, 2-step, and 12-step ahead forecasts. The default is `fstep=[1, 12]` for monthly series
    or `fstep=[1, 4]` for quarterly series. *Warning:* The values given in this vector cannot exceed
    the specified value of the maxlead argument of the forecast spec, or be less than one.

* **sadjlags** (Vector{Int64}) - Specifies a vector of up to 5 revision lags (each greater than zero) that will be analyzed
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

* **trendlags** (Vector{Int64}) - Similar to `sadjlags`, this argument prescribes which lags will be used in the revisions
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
    estimates::Union{Vector{Symbol},X13default}=_X13default,
    fixmdl::Union{Bool,X13default}=_X13default,
    fixreg::Union{Bool,X13default}=_X13default,
    fstep::Union{Vector{Int64},X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:header, :outlierhistory, :sarevisions, :sasummary, :chngrevisions, :chngsummary, :indsarevisions, :indsasummary, :trendrevisions, :trendsummary, :trenchchngrevisions, :trendchngsummary, :sfrevisions, :sfsummary, :lkhdhistory, :fcsterrors, :armahistory, :tdhistory, :sfilterhistory, :saestimates, :chngestimates, :indsaestimates, :trendestimates, :trendchngestimates, :sfestimates, :fcsthistory],
    save::Union{Vector{Symbol},X13default} =[:outlierhistory, :sarevisions, :chngrevisions, :indsarevisions, :trendrevisions, :trenchchngrevisions, :sfrevisions, :sfsummary, :lkhdhistory, :fcsterrors, :armahistory, :tdhistory, :sfilterhistory, :saestimates, :chngestimates, :indsaestimates, :trendestimates, :trendchngestimates, :sfestimates, :fcsthistory],
    savelog::Union{Vector{Symbol},X13default} =[:alldiagnostics],
    sadjlags::Union{Vector{Int64},X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    target::Union{Symbol,X13default}=_X13default,
    trendlags::Union{Vector{Int64},X13default}=_X13default,
    fixx11reg::Union{Bool,X13default}=_X13default,
    outlier::Union{Symbol,X13default}=_X13default,
    outlierwin::Union{Int64,X13default}=_X13default,
    refresh::Union{Bool,X13default}=_X13default,
    transformfcst::Union{Bool,X13default}=_X13default,
    x11outlier::Union{Bool,X13default}=_X13default,
) 
    # checks and logic
    return X13history(endtable,estimates,fixmdl,fixreg,fstep,print,save,savelog,sadjlags,start,target,trendlags,fixx11reg,outlier,outlierwin,refresh,transformfcst,x11outlier)
end
history!(spec::X13spec{F}; kwargs...) where F = (spec.history = history(; kwargs...))

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
    print::Union{Vector{Symbol},X13default}=[:afc, :afcplot, :pacf, :pacfplot, :regcoefficients],
    save::Union{Vector{Symbol},X13default}=[:afc, :pacf],
)
    # checks and logic
    return X13identify(diff,sdiff,maxlag,print,save)
end
identify!(spec::X13spec{F}; kwargs...) where F = (spec.identify = identify(; kwargs...))

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

* **critical** (Vector{Union{Float64,Missing}}) - Sets the value to which the absolute values of the outlier t-statistics are compared to
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

* **span** (UnitRange{MIT}) - Specifies start and end dates of a span of the time series to be searched for outliers. The
    start and end dates of the span must both lie within the series and within the model
    span if one is specified by the modelspan argument of the series spec, and the start
    date must precede the end date. (If there is a span argument
    in the series spec, then, in the above remarks, replace the start and end dates of the
    series by the start and end dates of the span given in the series spec.)

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
    critical::Union{Vector{Union{Float64,Missing}},X13default}=_X13default,
    lsrun::Union{Int64,X13default}=_X13default,
    method::Union{Symbol,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:header, :iterations, :tests, :temporaryls, :finaltests],
    save::Union{Vector{Symbol},X13default}= [:iterations, :finaltests],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    span::Union{UnitRange{MIT},X13default}=_X13default,
    types::Union{Vector{Symbol},X13default}=_X13default,
    almost::Union{Float64,X13default}=_X13default,
    tcrate::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    #TODO: `lsrun` may be given values from 0 to 5

    #TODO: values for `almost` argument must always be greater than zero

    #todo: tcrate must be a number greater than zero and less than one

    return X13outlier(critical,lsrun,method,print,save,savelog,span,types,almost,tcrate)
end
outlier!(spec::X13spec{F}; kwargs...) where F = (spec.outlier = outlier(; kwargs...))

"""
`pickmdl(; kwargs...)`

`pickmdl!(spec::X13spec{F}; kwargs...)`

Specifies that the ARIMA part of the regARIMA model will be sought using an automatic model selection
procedure similar to the one used by X-11-ARIMA/88 (see Dagum 1988). The user can specify which types
of models are to be fitted to the time series in the procedure and can change the thresholds for the selection
criteria.

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

* **file** (String) - See the manual.

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
function pickmdl(; 
    bcstlim::Union{Int64,X13default}=_X13default,
    fcstlim::Union{Int64,X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    identify::Union{Symbol,X13default}=_X13default,
    method::Union{Symbol,X13default}=_X13default,
    mode::Union{Symbol,X13default}=_X13default,
    outofsample::Union{Bool,X13default}=_X13default,
    overdiff::Union{Float64,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:pickmdlchoice, :header, :usermodels],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    qlim::Union{Int64,X13default}=_X13default,
)
    # checks and logic
    return X13pickmdl(bcstlim,fcstlim,file,identify,method,mode,outofsample,overdiff,print,savelog,qlim)
end
pickmdl!(spec::X13spec{F}; kwargs...) where F = (spec.pickmdl = pickmdl(; kwargs...))

"""
`regression(; kwargs...)`

`regression!(spec::X13spec{F}; kwargs...)`

Specification for including regression variables in a regARIMA model, or for specifying regression variables
    whose effects are to be removed by the `identify` spec to aid ARIMA model identification. Predefined regression
    variables are selected with the `variables` argument. The available predefined variables provide regressors
    modeling a constant effect, fixed seasonality, trading-day and holiday variation, additive outliers, level shifts,
    and temporary changes or ramps. Change-of-regime regression variables can be specified for seasonal and
    trading-day regressors. User-defined regression variables can be added to the model with the `user` argument.
    Data for any user-defined variables must be supplied, either in the `data` argument, or in a file specified by
    the `file` argument (not both). The `regression` spec can contain both predefined and user-defined regression
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

* **aictest** (Vector{Symbol}) - Specifies that an AIC-based selection will be used to determine if a given set of regression
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

* **file** (String) - See the manual.

* **format** (String) - See the manual.

* **pvaictest** (Float64) - Probability for generating a critical value for any AIC tests specified in this spec. This
    probablity must be > 0.0 and < 1.0. Table 7.26 in the manual shows the critical value generated for
    different values of pvaictest and different values of ν, the difference in the number of
    parameters between two models.

    If this argument is not specified, the aicdiff argument is used to set the critical value
    for AIC testing.

* **start** (MIT) - The start date for the data values for the user-defined regression variables. The default
    is the start date of the series. Valid values are any date up to the start date of the series
    (or up to the start date of the `span` specified by the `span` argument of the `series` spec,
    if present).

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

* **user** (Vector{Symbol}) - Specifies names for any user-defined regression variables. Names are required for all 
    user-defined variables to be included in the model. The names given are used to label estimated
    coefficients in the program's output. Data values for the user-defined variables must be
    supplied, using either the `data` or `file` argument (not both). The maximum number of
    user-defined regression variables is 52. (This limit can be changed—see Section 2.8 of the manual.)

* **usertype** (Vector{Symbol}) - Assigns a type of model-estimated regression effect to each user-defined regression variable. 
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
    regression spec (`usertype=[:td]`), or each user-defined regression variable can be given its
    own type (`usertype=[:td, :td, :td, :td, :td, :td, :holiday, :user]`). Once a type other than
    user has been assigned to a user-defined variable, further specifications for the variable
    in other arguments, such as `aictest` or `noapply`, must use this type designation, not
    `user`. If this option is not specified, all user-defined variables have the type `:user`. See
    the manual for more information on assigning types to user-defined regressors.

* **variables** (Vector{Symbol}) - List of predefined regression variables to be included in the model. Data values for
    these variables are calculated by the program, mostly as functions of the calendar. See
    the manual for a discussion and a table of the available predefined variables. Also see
    Section 4.3 of the manual for additional information and a table defining the actual regression variables
    used.
    
### Rarely used keyword arguments:

* **b** (Vector{Float64}) - Specifies initial values for regression parameters in the order that they appear in the
    `variables` and `user` arguments. If present, the `b` argument must assign initial values
    to _all_ regression coefficients in the regARIMA model, and must appear in the spec file
    after the `variables` and `user` arguments. Initial values are assigned to parameters
    either by specifying the value in the argument list or by explicitly indicating that it is
    missing as in the example below. Missing values take on their default value of 0.1. For
    example, for a model with two regressors, `b=[0.7, missing]` is equivalent to `b=[0.7,0.1]`, but
    `b=[0.7]` is not allowed. For a model with three regressors, `b=[0.8,missing,-0.4]` is equivalent
    to `b=[0.8,0.1,-0.4]`. To hold a parameter fixed at a specified value, use the `bfixed` argument.

* **bfixed** (Vector{Bool}) - A vector of `true`/`false` entries corresponding to the entries in the `b` vector.
        `true` entries will be held fixed.

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
    aicdiff::Union{Vector{Union{Float64,Missing}},X13default}=_X13default,
    aictest::Union{Vector{Symbol},X13default}=_X13default,
    chi2test::Union{Bool,X13default}=_X13default,
    chi2testcv::Union{Float64,X13default}=_X13default,
    data::Union{TSeries,MVTSeries, X13default}=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:regressionmatrix, :aictest, :outlier, :aoutlier, :levelshift, :seasonaloutlier, :transitory, :temporarychange, :tradingday, :holiday, :regseasonal, :userdef, :chi2test, :dailyweights],
    save::Union{Vector{Symbol},X13default}=[:regressionmatrix, :outlier, :aoutlier, :levelshift, :seasonaloutlier, :transitory, :temporarychange, :tradingday, :holiday, :regseasonal, :userdef],
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    pvaictest::Union{Float64,X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    testalleaster::Union{Bool,X13default}=_X13default,
    tlimit::Union{Float64,X13default}=_X13default,
    user::Union{Vector{Symbol},X13default}=_X13default,
    usertype::Union{Vector{Symbol},X13default}=_X13default,
    variables::Union{Vector{Symbol},X13default}=_X13default,
    b::Union{Vector{Float64},X13default}=_X13default,
    bfixed::Union{Vector{Bool},X13default}=_X13default,
    centeruser::Union{Symbol,X13default}=_X13default,
    eastermeans::Union{Bool,X13default}=_X13default,
    noapply::Union{Symbol,X13default}=_X13default,
    tcrate::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    return X13regression(aicdiff,aictest,chi2test,chi2testcv,data,file,format,print,save,savelog,pvaictest,start,testalleaster,tlimit,user,usertype,variables,b,bfixed,centeruser,eastermeans,noapply,tcrate)
end
regression!(spec::X13spec{F}; kwargs...) where F = (spec.regression = regression(; kwargs...))

"""
seats(; kwargs...)
seats!(spec::X13spec{F}; kwargs...)
"""
function seats(; 
    appendfcst::Union{Bool,X13default}=_X13default,
    finite::Union{Bool,X13default}=_X13default,
    hpcycle::Union{Bool,X13default}=_X13default,
    noadmiss::Union{Bool,X13default}=_X13default,
    out::Union{Int64,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:seriesfcstdecomp,:seasonaladjfcstdecomp,:transitoryfcstdecomp,:seasadjconst, :trendconst,:totaladjustment,:difforiginal,:diffseasonaladj,:difftrend,:seasonalsum],# print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default} =[:trend, :seasonal, :irregular, :seasonaladj, :transitory, :adjustfac, :adjustmentratio,:trendfcstdecomp,:seasonalfcstdecomp,:seriesfcstdecomp,:seasonaladjfcstdecomp,:transitoryfcstdecomp,:seasadjconst, :trendconst,:totaladjustment,:difforiginal,:diffseasonaladj,:difftrend,:seasonalsum,:componentmodels,:filtersaconc,:filtersasym,:filtertrendconc,:filterdrendsym,:squaredgainsaconc,:squaredgainsasym,:squaredfaintrendconc,:squaredgaintrendsym,:timeshiftsaconc,:timeshifttrendconc,:wkendfilter,:seasonalpct,:irregularpct,:transitorypct,:adjustfacpct],
    savelog::Union{Vector{Symbol},X13default} =[:seatsmodel,:x13model,:normalitytest,:overunderestimation,:totalssquarederror,:componentvariance,:concurrentesterror,:percentreductionse,:averageabsdiffannual,:seasonalsignif],
    printphtrf::Union{Bool,X13default}=_X13default,
    qmax::Union{Int64,X13default}=_X13default,
    statseas::Union{Bool,X13default}=_X13default,
    tabtables::Union{Vector{Symbol},X13default}=_X13default,
    bias::Union{Int64,X13default}=_X13default,
    epsiv::Union{Float64,X13default}=_X13default,
    epsphi::Union{Int64,X13default}=_X13default,
    hplan::Union{Float64,X13default}=_X13default,
    imean::Union{Bool,X13default}=_X13default,
    maxit::Union{Int64,X13default}=_X13default,
    rmod::Union{Float64,X13default}=_X13default,
    xl::Union{Float64,X13default}=_X13default,
)
    # checks and logic
    return X13seats(appendfcst,finite,hpcycle,noadmiss,out,print,save,savelog,printphtrf,qmax,statseas,tabtables,bias,epsiv,epsphi,hplan,imean,maxit,rmod,xl)
end
seats!(spec::X13spec{F}; kwargs...) where F = (spec.seats = seats(; kwargs...))

"""
slidingspans(; kwargs...)
slidingspans!(spec::X13spec{F}; kwargs...)
"""
function slidingspans(; 
    cutchng::Union{Float64,X13default}=_X13default,
    cutseas::Union{Float64,X13default}=_X13default,
    cuttd::Union{Float64,X13default}=_X13default,
    fixmdl::Union{Symbol,X13default}=_X13default,
    fixreg::Union{Vector{Symbol},X13default}=_X13default,
    length::Union{Int64,X13default}=_X13default,
    numspans::Union{Int64,X13default}=_X13default,
    outlier::Union{Symbol,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:header, :ssftest, :factormeans, :percent, :summary, :yysummary, :indfactormeans, :indpercent, :indsummary,:yypercent, :sfspans, :chngspans, :saspans, :ychngspans, :tdspans,:indyypercent,:indyysummary,:indsfspans,:indchngspans,:indsaspans,:indychngspans],# print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}=[:yysummary,:sfspans, :chngspans, :saspans, :ychngspans, :tdspans,:indsfspans,:indchngspans,:indsaspans,:indychngspans],# save::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    start::Union{MIT,X13default}=_X13default,
    additivesa::Union{Symbol,X13default}=_X13default,
    fixx11reg::Union{Bool,X13default}=_X13default,
    x11outlier::Union{Bool,X13default}=_X13default,
)
    # checks and logic
    return X13slidingspans(cutchng,cutseas,cuttd,fixmdl,fixreg,length,numspans,outlier,print,save,savelog,start,additivesa,fixx11reg,x11outlier)
end
slidingspans!(spec::X13spec{F}; kwargs...) where F = (spec.slidingspans = slidingspans(; kwargs...))

"""
spectrum(; kwargs...)
spectrum!(spec::X13spec{F}; kwargs...)
"""
function spectrum(; 
    logqs::Union{Bool,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:qcheck, :qs, :specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa,:tukeypeaks],# print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}=[:specorig, :specsa, :specirr, :specseatssa, :specseatsirr,:specextresiduals,:specresidual,:speccomposite,:specindirr,:specindsa,:tukeyspecorig, :tukeyspecsa, :tukeyspecirr,:tukeyspecseatssa,:tukeyspecseatsirr,:tukeyspecextresiduals,:tukeyspecresidual,:tukeyspeccomposite,:tukeyspecindirr,:tukeyspecindsa],# save::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    qcheck::Union{Bool,X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    tukey120::Union{Bool,X13default}=_X13default,
    decibel::Union{Bool,X13default}=_X13default,
    difference::Union{Symbol,X13default}=_X13default,
    maxar::Union{Int64,X13default}=_X13default,
    peakwidth::Union{Int64,X13default}=_X13default,
    series::Union{Symbol,X13default}=_X13default,
    siglevel::Union{Int64,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
)
    # checks and logic
    return X13spectrum(logqs,print,save,savelog,qcheck,start,tukey120,decibel,difference,maxar,peakwidth,series,siglevel,type)
end
spectrum!(spec::X13spec{F}; kwargs...) where F = (spec.spectrum = spectrum(; kwargs...))

"""
transform(; kwargs...)
transform!(spec::X13spec{F}; kwargs...)
"""
function transform(; 
    adjust::Union{Symbol,X13default}=_X13default,
    aicdiff::Union{Float64,X13default}=_X13default,
    data::Any=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    func::Union{Symbol,X13default}=_X13default,
    mode::Union{Vector{Symbol},X13default}=_X13default,
    name::Union{String,X13default}=_X13default,
    power::Union{Float64,X13default}=_X13default,
    precision::Union{Int64,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:aictransform, :seriesconstant, :seriesconstantplot, :prior, :permprior, :tempprior, :prioradjusted, :permprioradjusted, :prioradjustedptd, :permprioradjustedptd, :transformed],# print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}=[:seriesconstant, :prior, :permprior, :tempprior, :prioradjusted, :permprioradjusted, :prioradjustedptd, :permprioradjustedptd, :transformed],# save::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    start::Union{MIT,X13default}=_X13default,
    title::Union{String,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
    constant::Union{Float64,X13default}=_X13default,
    trimzero::Union{Symbol,X13default}=_X13default,
)
    # checks and logic
    return X13transform(adjust,aicdiff,data,file,format,func,mode,name,power,precision,print,save,savelog,start,title,type,constant,trimzero)
end
transform!(spec::X13spec{F}; kwargs...) where F = (spec.transform = transform(; kwargs...))

"""
x11(; kwargs...)
x11!(spec::X13spec{F}; kwargs...)
"""
function x11(; 
    appendbcst::Union{Bool,X13default}=_X13default,
    appendfcst::Union{Bool,X13default}=_X13default,
    final::Union{Vector{Symbol},X13default}=_X13default,
    mode::Union{Symbol,X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:ftestd8,:irregular,:irrwt,:moveseasrat,:origchanges,:qstat,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:tdaytype,:totaladjustment,:trend,:tendchanges,:unmodsi,:unmodsiox,:x11diag,:yrtotals,:adjoriginalc,:adjoriginald,:autosf,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsib4,:replacsib9,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:irregularplot,:origwsaplot,:ratioplotorig,:ratioplotsa,:seasadjplot,:seasonalplot,:trendplot],# print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}=[:adjustdiff, :adjustfac,:adjustmentratio,:calendar,:calendaradjchanges,:combholiday,:irregular,:irrwt,:origchanges,:replacsi,:residualseasf,:sachanges,:seasadj,:seasonal,:seasonaldiff,:totaladjustment,:trend,:tendchanges,:unmodsi,:unmodsiox,:adjoriginalc,:adjoriginald,:extreme,:extremeb,:ftestb1,:irregularadjao,:irregularb,:irregularc,:irrwtb,:mcdmovavg,:modirregular,:modoriginal,:modseasadj,:modsic4,:modsid4,:replacsic9,:robustsa,:seasadjb11,:seasadjb6,:seasadjc11,:seasadjc6,:seasadjconst,:seasadjd6,:seasonalb10,:seasonalb5,:seasonalc10,:seasonalc5,:seasonald5,:sib3,:sib8,:tdadjorig,:tdadjorigb,:trendadjls,:trendb2,:trendb7,:trendc2,:trendc7,:trendconst,:trendd2,:trendd7,:adjustfacpct,:calendaradjchangespct,:irregularpct,:origchangespct,:sachangespct,:seasonalpct,:trendchangespct],# print::Union{Vector{Symbol},X13default}
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics],
    seasonalma::Union{Vector{Symbol},X13default}=_X13default,
    sigmalim::Union{Vector{Float64},X13default}=_X13default,
    title::Union{Vector{String},X13default}=_X13default,
    trendma::Union{Int64,X13default}=_X13default,
    type::Union{Symbol,X13default}=_X13default,
    calendarsigma::Union{Symbol,X13default}=_X13default,
    centerseasonal::Union{Bool,X13default}=_X13default,
    keepholiday::Union{Bool,X13default}=_X13default,
    print1stpass::Union{Bool,X13default}=_X13default,
    sfshort::Union{Bool,X13default}=_X13default,
    sigmavec::Union{Vector{Symbol},X13default}=_X13default,
    trendic::Union{Float64,X13default}=_X13default,
    true7term::Union{Bool,X13default}=_X13default,
)
    # checks and logic
    return X13x11(appendbcst,appendfcst,final,mode,print,save,savelog,seasonalma,sigmalim,title,trendma,type,calendarsigma,centerseasonal,keepholiday,print1stpass,sfshort,sigmavec,trendic,true7term)
end
x11!(spec::X13spec{F}; kwargs...) where F = (spec.x11 = x11(; kwargs...))



"""
x11regression(; kwargs...)
x11regression!(spec::X13spec{F}; kwargs...)
"""
function x11regression(; 
    aicdiff::Union{Float64,X13default}=_X13default,
    aictest::Union{Symbol,X13default}=_X13default,
    critical::Union{Float64,X13default}=_X13default,
    data::Any=_X13default,
    file::Union{String,X13default}=_X13default,
    format::Union{String,X13default}=_X13default,
    outliermethod::Union{Symbol,X13default}=_X13default,
    outlierspan::Union{UnitRange{MIT}, X13default}=_X13default,
    print::Union{Vector{Symbol},X13default}=[:priortd, :extremeval, :x11reg, :tradingday, :combtradingday, :holiday, :calendar, :combcalendar, :outlierhdr, :xaictest, :extremevalb, :x11regb, :tradingdayb, :combtradingdayb, :holidayb, :calendarb, :combcalendarb, :outlieriter, :outliertests, :xregressionmatrix, :xregressioncmatrix],# print::Union{Vector{Symbol},X13default}
    save::Union{Vector{Symbol},X13default}=[:priortd, :extremeval, :tradingday, :combtradingday, :holiday, :calendar, :combcalendar, :extremevalb, :tradingdayb, :combtradingdayb, :holidayb, :calendarb, :combcalendarb, :outlieriter, :xregressionmatrix, :xregressioncmatrix],# save::Union{Vector{Symbol},X13default},
    savelog::Union{Vector{Symbol},X13default}=[:alldiagnostics], # savelog::Union{Vector{Symbol},X13default}     
    prior::Union{Bool,X13default}=_X13default,
    sigma::Union{Float64,X13default}=_X13default,
    span::Union{UnitRange{MIT},X13default}=_X13default,
    start::Union{MIT,X13default}=_X13default,
    tdprior::Union{Vector{Float64},X13default}=_X13default,
    user::Union{Vector{Symbol},X13default}=_X13default,
    usertype::Union{Vector{Symbol},X13default}=_X13default,
    variables::Union{Vector{Any},X13default}=_X13default,
    almost::Union{Float64,X13default}=_X13default,
    b::Union{Vector{Float64},X13default}=_X13default,
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
    umtrimzero::Union{Symbol,X13default}=_X13default,
)
    # checks and logic
    return X13x11regression(aicdiff,aictest,critical,data,file,format,outliermethod,outlierspan,print,save,savelog,prior,sigma,span,start,tdprior,user,usertype,variables,almost,b,centeruser,eastermeans,forcecal,noapply,reweight,umdata,umfile,umformat,umname,umprecision,umstart,umtrimzero)
end
x11regression!(spec::X13spec{F}; kwargs...) where F = (spec.x11regression = x11regression(; kwargs...))


function validateX13spec(spec::X13spec)

    # The arima spec cannot be used in the same spec file as the pickmdl or automdl specs;
    if !(spec.arima isa X13default)
        if !(spec.automdl isa X13default)
            throw(ArgumentError("The arima spec cannot be used in the same spec file as the pickmdl or automdl specs."))
        end
        if !(spec.pickmdl isa X13default)
            throw(ArgumentError("The arima spec cannot be used in the same spec file as the pickmdl or automdl specs."))
        end
    end

    #TODO: the model, ma, andar arguments of the arima spec cannot be used when the file argument is specified in the estimate spec
end

export X13spec