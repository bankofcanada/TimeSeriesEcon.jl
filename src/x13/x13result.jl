import Dates
mutable struct X13result
    spec::X13spec
    outfolder::String
    stdout::String
    series::Workspace
    other::Workspace
end

function run(spec::X13spec{F}) where F

    x13write(spec)

    gpath = joinpath(spec.folder, "graphics")
    if !ispath(gpath)
        mkdir(gpath)
    end
    println(gpath)

    c = `x13as -I "$(joinpath(spec.folder,"spec"))" -G "$(gpath)" -S`

    stdin_buffer = IOBuffer()
    stdout_buffer = IOBuffer()
    stderr_buffer = IOBuffer()
    cmdout = Base.run(c, stdin_buffer, stdout_buffer, stderr_buffer)
    stdout = String(take!(stdout_buffer))

    res = X13.X13result(spec, spec.folder, stdout, Workspace(), Workspace())

    main_objects = readdir(spec.folder, join=true)
    files = filter(obj -> !isdir(obj), main_objects)
    sub_folders = filter(obj -> isdir(obj), main_objects)
    for folder in sub_folders
         sub_folder_objects = readdir(folder, join=true)
         files = [files..., filter(obj -> !isdir(obj), sub_folder_objects)...]
    end
    @show files

    for file in files
        ext = Symbol(splitext(file)[2][2:end])
        if ext in _series_extensions
            res.series[ext] = x13read_series(file, frequencyof(spec.series.data), spec.series.start)
        elseif ext == :udg
            #TODO: make this meaningful
            res.other[ext] = x13read_udg(file)
        elseif ext in _table_extensions
            res.series[ext] = x13read_table(file)
        elseif ext ∉ (:spc,)
            println("=================================================================================================================")
            println(ext)
            println(read(file, String))
        end
    end

    # TODO: .tbs, .sum, .rog are special SEATS outputs

    return res
    
end

function x13read_udg(file)
    lines = split(read(file, String),"\n")
    ws = Workspace()
    for line in lines[1:end-1]
        split_point = findfirst(": ", line)[begin]
        if line[split_point] !== ':'
            println("OBS! ", line[split_point-1], ", ", line)
        end
        key = Symbol(line[1:split_point-1])
        val = strip(line[split_point+1:end])
        foundval = false
        if key == :date
            val = Dates.Date(val, Dates.DateFormat("u d, y"))
            foundval = true
        end
        if !foundval
            try 
                val = parse(Int64, val)
                foundval = true
            catch ArgumentError
            end
        end

        if !foundval
            try 
                val = parse(Float64, val)
                foundval = true
            catch ArgumentError
            end
        end

        if !foundval
            # could be a vector of numbers
            splitval = split(replace(val, "*******" => "NaN"), r"[\t\s]+")
            if length(splitval) > 1
                try 
                    val = [parse(Float64, strip(v)) for v in splitval]
                    foundval = true
                catch ArgumentError
                end
            end
        end

        if !foundval && val == "no"
            val = false
            foundval = true
        end

        if !foundval && val == "yes"
            val = true
            foundval = true
        end

        # if !foundval
        #     println(key, ": ", val)
        # end

        ws[key] = val

        # sline = split(line, [" ", "\t"])
    end
    # println(ws)
    return ws
end

function _sanitize_colname(s::AbstractString)
    return replace(s, r"[\s\-\.]+" => "_")
end

function x13read_table(file)
    lines = split(read(file, String),"\n")
    headers = _sanitize_colname.(split(lines[1], "\t"))
    vals = Matrix{Float64}(undef, (length(lines)-3, length(headers)))
    for (i,line) in enumerate(lines[3:end-1])
        vals[i,:] = [parse(Float64, v) for v in split(line, "\t")]
    end
    res = MVTSeries(1U, Symbol.(headers), vals)
    return res
end
function x13read_series(file, F::Type{<:Frequency}, start::MIT)
    lines = split(read(file, String),"\n")
    vals = Vector{Float64}(undef, length(lines)-3)
    for (i, line) in enumerate(lines[3:end-1])
        # println(line)
        vals[i] = parse(Float64, split(line, "\t")[2])
    end
    period_string = split(lines[3], "\t")[1]
    if length(period_string) > 2
        p = parse(Int64, period_string[end-1:end])
        y = parse(Int64, period_string[1:end-2])
        return TSeries(MIT{F}(y,p), vals)
    else
        throw(ArgumentError("Period string has an unexpected format: $(period_string)."))
    end

    println(vals)
end
function x13read_mvtseries(file, F::Type{<:Frequency})
    lines = split(read(file, String),"\n")
    headers = split(lines[1], "\t")[2:end]
    headers = _sanitize_colname.(headers)
    vals = Matrix{Float64}(undef, (length(lines)-3, length(headers)))

    for (i, line) in enumerate(lines[3:end-1])
        # println(line)
        vals[i,:] = [parse(Float64, v) for v in split(line, "\t")[2:end]]
    end
    period_string = split(lines[3], "\t")[1]
    if length(period_string) > 2
        p = parse(Int64, period_string[end-1:end])
        y = parse(Int64, period_string[1:end-2])
        if length(headers) > 1
            return MVTSeries(MIT{F}(y,p), headers, vals)
        else
            return TSeries(MIT{F}(y,p), vals[:,1])
        end
    else
        throw(ArgumentError("Period string has an unexpected format: $(period_string)."))
    end

    println(vals)
end

export run

_series_extensions = (:a1, :rrs, :b1, :a3, :rsd, :ref)
# _mvts_extensions = (:ref,)
_table_extensions = (:pcf,:acf,:ac2)
_series_alt_names = Dict{Symbol,Symbol}(
    :a1 => :span, #series
    :b1 => :adjoriginal, #series
    :rrs => :regressionresiduals, #estimate
    :rsd => :residuals, #estimate
    :ref => :regressioneffects, #estimate
    :a3 => :prioradjusted, #transform
)
_series_descriptions = Dict{Symbol,String}(
    :a1 => "Original series (adjusted for span)",
    :b1 => "Original series (adjusted for prior effects and forcast extended)",
    :ref => "x*beta matrix of regression variables multiplied by the vector of estimated regression coefficients",
    :rrs => "Residuals from regression effects",
    :rsd => "Model residuals",
    :a3 => "Prior-adjusted series",
)

_output_alt_names = Dict{Symbol,Dict{Symbol,Symbol}}(
    :arima => Dict{Symbol,Symbol}(),
    :automdl => Dict{Symbol,Symbol}(
        :ach => :autochoice,
        :amd => :autochoicemdl,
        :adt => :autodefaulttests,
        :aft => :autofinaltests,
        :alb => :autoljungboxtest,
        :b5m => :bestfivemdl,
        :hdr => :header,
        :urt => :unitroottest,
        :urm => :unitroottestmdl,
        :adf => :autodiff,
        :mu => :mean,
    ),
    :check => Dict{Symbol,Symbol}(
        :acf => :acf,
        :acp => :acfplot,
        :pcf => :pacf,
        :pcp => :pacfplot,
        :ac2 => :acfsquared,
        :ap2 => :acfsquaredplot,
        :nrm => :normalitytest,
        :dw => :durbinwatson,
        :frt => :friedmantest,
        :hst => :histogram,
        :nrm => :normalitytest,
        :lbq => :ljungboxq,
        :bpq => :boxpierceq,
        :dw => :durbinwatson,
        :sft => :seasonalftest,
        :tft => :tdftest,
    ),
    :estimate => Dict{Symbol,Symbol}(
        :opt => :options,
        :mdl => :model,
        :est => :estimates,
        :afc => :averagefcsterr,
        :lks => :lkstats,
        :itr => :iterations,
        :ite => :iterationerrors,
        :rcm => :regcmatrix,
        :acm => :armacmatrix,
        :lkf => :lformulas,
        :rts => :roots,
        :ref => :regressioneffects,
        :rrs => :regressionresiduals,
        :rsd => :residuals,
        :aic => :aic,
        :acc => :aicc,
        :bic => :bic,
        :hq => :hannanquinn,
    ),
    :force => Dict{Symbol,Symbol}(
        :saa => :seasadjtot,
        :rnd => :saround,
        :e6a => :revsachanges,
        :e6r => :rndsachanges,
        :p6a => :revsachangespct,
        :p6r => :rndsachangespct,
    ),
    :forecast => Dict{Symbol,Symbol}(
        :ftr => :transformed,
        :fvr => :variances,
        :fct => :forecasts,
        :btr => :transformedbcst,
        :bct => :backcasts,
    ),
    :history => Dict{Symbol,Symbol}(
        :hdr => :header,
        :rot => :outlierhistory,
        :sar => :sarevisions,
        :sas => :sasummary,
        :chr => :chngrevisions,
        :chs => :chngsummary,
        :iar => :indsarevisions,
        :ias => :indsasummary,
        :trr => :trendrevisions,
        :trs => :trendsummary,
        :tcr => :trendchngrevisions,
        :tcs => :trendchngsummary,
        :sfr => :sfrevisions,
        :ssm => :sfsummary,
        :lkh => :lkhdhistory,
        :fce => :fcsterrors,
        :amh => :armahistory,
        :tdh => :tdhistory,
        :sfh => :sfilterhistory,
        :sae => :saestimates,
        :che => :chngestimates,
        :iae => :indsaestimates,
        :tre => :trendestimates,
        :tce => :trendchngestimates,
        :sfe => :sfestimates,
        :fch => :fcsthistory,
        :asa => :aveabsrevsa,
        :ach => :aveabsrevchng,
        :iaa => :aveabsrevindsa,
        :atr => :aveabsrevtrend,
        :atc => :aveabsrevtrendchng,
        :asf => :aveabsrevsf,
        :asp => :aveabsrevsfproj,
        :afe => :avesumsqfcsterr,
    ),
    :metadata => Dict{Symbol,Symbol}(),
    :identify => Dict{Symbol,Symbol}(
        :iac => :acf,
        :acp => :acfplot,
        :ipc => :pacf,
        :pcp => :pacfplot,
        :rgc => :regcoefficients,
    ),
    :outlier => Dict{Symbol,Symbol}(
        :hdr => :header,
        :oit => :iterations,
        :ots => :tests,
        :tls => :temporaryls,
        :fts => :finaltests,
    ),
    :pickmdl => Dict{Symbol,Symbol}(
        :pmc => :pickmdlchoice,
        :hdr => :header,
        :umd => :usermodels,
    ),
    :regression => Dict{Symbol,Symbol}(
        :rmx => :regressionmatrix,
        :ats => :aictest,
        :otl => :outlier,
        :ao => :aoutlier,
        :ls => :levelshift,
        :so => :seasonaloutlier,
        :a13 => :transitory,
        :tc => :temporarychange,
        :td => :tradingday,
        :hol => :holiday,
        :a10 => :regseasonal,
        :usr => :userdef,
        :cts => :chi2test,
        :tdw => :dailyweights,
    ),
    :seats => Dict{Symbol,Symbol}(
        :s10 => :seasonal,
        :s13 => :irregular,
        :s11 => :seasonaladj,
        :s14 => :transitory,
        :s16 => :adjustfac,
        :s18 => :adjustmentratio,
        :tfd => :trendfcstdecomp,
        :sfd => :seasonalfcstdecomp,
        :ofd => :seriesfcstdecomp,
        :afd => :seasonaladjfcstdecomp,
        :yfd => :transitoryfcstdecomp,
        :sec => :seasadjconst,
        :stc => :trendconst,
        :sta => :totaladjustment,
        :dor => :difforiginal,
        :dsa => :diffseasonaladj,
        :dtr => :difftrend,
        :ssm => :seasonalsum,
        :cyc => :cycle,
        :ltt => :longtermtrend,
        :mdc => :componentmodels,
        :fac => :filtersaconc,
        :faf => :filtersasym,
        :ftc => :filtertrendconc,
        :ftf => :filtertrendsym,
        :gac => :squaredgainsaconc,
        :gaf => :squaredgainsasym,
        :gtc => :squaredgaintrendconc,
        :gtf => :squaredgaintrendsym,
        :tac => :timeshiftsaconc,
        :ttc => :timeshifttrendconc,
        :wkf => :wkendfilter,
        :pss => :seasonalpct,
        :psi => :irregularpct,
        :psc => :transitorypct,
        :psa => :adjustfacpct,
        :smd => :seatsmodel,
        :xmd => :x13model,
        :nrm => :normalitytest,
        :oue => :overunderestimation,
        :tse => :totalsquarederror,
        :cvr => :componentvariance,
        :cee => :concurrentesterror,
        :prs => :percentreductionse,
        :aad => :averageabsdiffannual,
        :ssg => :seasonalsignif,

    ),
    :series => Dict{Symbol,Symbol}(
        :hdr => :header,
        :a1 => :span,
        :a1p => :seriesplot,
        :spc => :specfile,
        :sav => :savefile,
        :sp0 => :specorig,
        :mva => :missingvaladj,
        :a18 => :calendaradjorig,
        :a19 => :outlieradjorig,
        :b1 => :adjoriginal,
        :b1p => :adjorigplot,
    ),
    :slidingspans => Dict{Symbol,Symbol}(
        :hdr => :header,
        :ssf => :ssftest,
        :fmn => :factormeans,
        :pct => :percent,
        :sum => :summary,
        :smy => :yysummary,
        :fmi => :indfactormeans,
        :pci => :indpercent,
        :smi => :indsummary,
        :pcy => :yypercent,
        :sfs => :sfspans,
        :chs => :chngspans,
        :sas => :saspans,
        :ycs => :ychngspans,
        :tds => :tdspans,
        :pyi => :indyypercent,
        :syi => :indyysummary,
        :sis => :indsfspans,
        :cis => :indchngspans,
        :ais => :indsaspans,
        :yis => :indychngspans,
    ),
    :spectrum => Dict{Symbol,Symbol}(
        :sp0 => :specorig,
        :sp1 => :specsa,
        :sp2 => :specirr,
        :s1s => :specseatssa,
        :s2s => :specseatsirr,
        :ser => :specextresiduals,
        :spr => :specresidual,
        :is0 => :speccomposite,
        :is2 => :specindirr,
        :is1 => :specindsa,
        :tpk => :tukeypeaks,
        :st0 => :tukeyspecorig,
        :st1 => :tukeyspecsa,
        :st2 => :tukeyspecirr,
        :st1 => :tukeyspecseatssa,
        :st2 => :tukeyspecseatsirr,
        :ter => :tukeyspecextresiduals,
        :str => :tukeyspecresidual,
        :it0 => :tukeyspeccomposite,
        :it2 => :tukeyspecindirr,
        :it1 => :tukeyspecindsa,
        :dpk => :dirpeaks,
        :dqs => :dirqs,
        :dtp => :dirtukeypeaks,
        :ipk => :indpeaks,
        :iqs => :indqs,
        :itp => :indtukeypeaks,
        :spk => :peaks,
        :stp => :tukeypeaks,
        :a1 => :original,
        :a19 => :outlieradjoriginal,
        :b1 => :adjoriginal,
        :e1 => :modoriginal,
    ),
    :transform => Dict{Symbol,Symbol}(
        :tac => :aictransform,
        :a1c => :seriesconstant,
        :acp => :seriesconstantplot,
        :a2 => :prior,
        :a2p => :permprior,
        :a2t => :tempprior,
        :a3 => :prioradjusted,
        :a3p => :permprioradjusted,
        :a4d => :prioradjustedptd,
        :a4p => :permprioradjustedptd,
        :trn => :transformed,
    ),
    :x11 => Dict{Symbol,Symbol}(
        :fad => :adjustdiff,
        :d16 => :adjustfac,
        :e18 => :adjustmentratio,
        :d18 => :calendar,
        :e8 => :calendaradjchanges,
        :chl => :combholiday,
        :d8f => :ftestd8,
        :d13 => :irregular,
        :c17 => :irrwt,
        :d9a => :movseasrat,
        :e5 => :origchanges,
        :f3 => :qstat,
        :d9 => :replacsi,
        :rsf => :residualseasf,
        :e6 => :sachanges,
        :d11 => :seasadj,
        :d10 => :seasonal,
        :fsd => :seasonaldiff,
        :tdy => :tdaytype,
        :tad => :totaladjustment,
        :d12 => :trend,
        :e7 => :trendchanges,
        :d8 => :unmodsi,
        :d8b => :unmodsiox,
        :f2 => :x11diag,
        :e4 => :yrtotals,
        :c1 => :adjoriginalc,
        :d1 => :adjoriginald,
        :asf => :autosf,
        :c20 => :extreme,
        :b20 => :extremeb,
        :b1f => :ftestb1,
        :ira => :irregularadjao,
        :b13 => :irregularb,
        :c13 => :irregularc,
        :b17 => :irrwtb,
        :f1 => :mcdmovavg,
        :e3 => :modirregular,
        :e1 => :modoriginal,
        :e2 => :modseasadj,
        :c4 => :modsic4,
        :d4 => :modsid4,
        :b4 => :replacsib4,
        :b9 => :replacsib9,
        :c9 => :replacsic9,
        :e11 => :robustsa,
        :b11 => :seasadjb11,
        :b6 => :seasadjb6,
        :c11 => :seasadjc11,
        :c6 => :seasadjc6,
        :sac => :seasadjconst,
        :d6 => :seasadjd6,
        :b10 => :seasonalb10,
        :b5 => :seasonalb5,
        :c10 => :seasonalc10,
        :c5 => :seasonalc5,
        :d5 => :seasonald5,
        :b3 => :sib3,
        :b8 => :sib8,
        :c19 => :tdadjorig,
        :b19 => :tdadjorigb,
        :tal => :trendadjls,
        :b2 => :trendb2,
        :b7 => :trendb7,
        :c2 => :trendc2,
        :c7 => :trendc7,
        :tac => :trendconst,
        :d2 => :trendd2,
        :d7 => :trendd7,
        :irregularplot => :irregularplot,
        :origwsaplot => :origwsaplot,
        :ratioplotorig => :ratioplotorig,
        :ratioplotsa => :ratioplotsa,
        :seasadjplot => :seasadjplot,
        :seasonalplot => :seasonalplot,
        :trendplot => :trendplot,
        :paf => :adjustfacpct,
        :pe8 => :calendaradjchangespct,
        :pir => :irregularpct,
        :pe5 => :origchangespct,
        :pe6 => :sachangespct,
        :psf => :seasonalpct,
        :pe7 => :trendchangespct,
        :fb1 => :fstableb1,
        :fd8 => :fstabled8,
        :icr => :icratio,
        :ids => :idseasonal,
        :m1 => :m1,
        :m10 => :m10,
        :m11 => :m11,
        :m2 => :m2,
        :m3 => :m3,
        :m4 => :m4,
        :m5 => :m5,
        :m6 => :m6,
        :m7 => :m7,
        :m8 => :m8,
        :m9 => :m9,
        :msf => :movingseasf,
        :msr => :movingseasratio,
        :q => :q,
        :q2 => :q2,
    ),
    :x11regression => Dict{Symbol,Symbol}(
        :a4 => :priortd,
        :c14 => :extremeval,
        :c15 => :x11reg,
        :c16 => :tradingday,
        :c18 => :combtradingday,
        :xhl => :holiday,
        :xca => :calendar,
        :xcc => :combcalendar,
        :xoh => :outlierhdr,
        :xat => :xaictest,
        :b14 => :extremevalb,
        :b15 => :x11regb,
        :b16 => :tradingdayb,
        :b18 => :combtradingdayb,
        :bxh => :holidayb,
        :bxc => :calendarb,
        :bcc => :combcalendarb,
        :xoi => :outlieriter,
        :xot => :outliertests,
        :xrm => :xregressionmatrix,
        :xrc => :xregressioncmatrix,

    )
)

_output_save_tables = Dict{Symbol, Vector{Symbol}}(
    :arima => Vector{Symbol}(),
    :automdl => Vector{Symbol}(),
    :check => [:act, :pcf, :ac2],
    :estimate => [:mdl, :est, :lks, :itr, :rcm, :acm, :rts, :ref, :rrs, :rsd],
    :force => [:saa, :rnd, :e6a, :e6r, :p6a, :p6r],
    :forecast => [:ftr, :fvr, :fct, :btr, :bct],
    :history => [:rot, :sar, :chr, :iar, :trr, :tcr, :sfr, :lkh, :fce, :amh, :tdh, :sfh, :sae, :che, :iae, :tre, :tce, :sfe, :fch],
    :metadata => Vector{Symbol}(),
    :identify => [:iac, :ipc],
    :outlier => [:oit, :fts],
    :pickmdl => Vector{Symbol}(),
    :regression => [:rmx, :otl, :ao, :ls, :so, :a13, :tc, :td, :hol, :a10, :usr],
    :seats => [:s11, :dsa, :ttc, :sec, :tac, :ftf, :ofd, :afd, :s10, :s16, :dor, :s18, :yfd, :faf, :gaf, :stc, :wkf, :tfd, :s13, :s14, :sta, :dtr, :gac, :gtc, :gtf, :cyc, :ssm, :mdc, :ftc, :sfd, :ltt, :fac, :pss, :psi, :psc, :psa],
    :series => [:a1, :sp0, :mva, :a18, :a19, :b1],
    :slidingspans => [:smv, :sfs, :chs, :sas, :ycs, :tds, :sis, :cis, :ais, :yis],
    :spectrum => [:is1, :sp2, :sp0, :s1s, :st2, :is2, :it0, :s2s, :it1, :sp1, :str, :ser, :ter, :st0, :is0, :it2, :spr, :st1],
    :transform => [:a2, :a2t, :a4d, :a3, :trn, :a4p, :a2p, :a3p, :a1c],
    :x11 => [:d4, :tad, :d8b, :e1, :d6, :b5, :d9, :d2, :d1, :tac, :c2, :b20, :e7, :c9, :b17, :c7, :c13, :b10, :f1, :c11, :e2, :d12, :c19, :e11, :c6, :b3, :tal, :e5, :b7, :b19, :c4, :ira, :e3, :fsd, :b2, :e18, :d10, :b11, :c1, :c17, :e6, :d11, :c10, :d5, :b8, :d16, :fad, :b6, :d8, :d18, :d13, :sac, :d7, :e8, :chl, :c5, :b13, :c20, :paf, :pe8, :pir, :pe5, :pe6, :psf, :pe7],
    :x11regression => [:a4, :c14, :c16, :c18, :xhl, :xca, :xcc, :b14, :b16, :b18, :bxh, :hxc, :bcc, :xoi, :xrm, :xrc],
)

_output_descriptions = Dict{Symbol,Dict{Symbol,String}}(
    :arima => Dict{Symbol,String}(),
    :automdl => Dict{Symbol,String}(
        :ach => "model choice of automatic model procedure",
        :amd => "summary output for models estimated during choice of ARMA model orders",
        :adt => "tests performed on the default model (usually the airline model) of the automatic model identification procedure",
        :aft => "final tests performed on the model identified by automdl",
        :alb => "check of the residual Ljung-Box statistic",
        :b5m => "summary of best five models found during choice of ARMA model orders",
        :hdr => "header for the automatic modeling output",
        :urt => "choice of differencing",
        :urm => "summary output for models estimated during difference order identification",
        :adf => "choice of differencing by automatic model identification procedure", #diagnostic
        :mu => "choice regarding use of constant term with automatically identified model",
    ),
    :check => Dict{Symbol,String}(
        :acf => "autocorrelation function of residuals with standard errors, and Ljung-Box Q-statistics computed through each lag",
        :acp => "plot of residual autocorrelation function with ±2 standard error limits",
        :pcf => "partial autocorrelation function of residuals with standard errors",
        :pcp => "plot of residual partial autocorrelation function with ± 2 standard error limits",
        :ac2 => "autocorrelation function of squared residuals with standard errors, and Ljung-Box Q-statistics computed through each lag",
        :ap2 => "plot of squared residual autocorrelation function with ± 2 standard error limits",
        :nrm => "Geary’s a and Kurtosis statistical tests for the normality of the model residuals, as well as a test for skewness of the residuals.",
        :dw => "Durbin-Watson statistic for model residuals",
        :frt => "Friedman non-parametric test for residual seasonality",
        :hst => "histogram of standardized residuals and the following summary statistics of the residuals: minimum, maximum, median, standard deviation, and robust estimate of residual standard deviation (1.48 × the median absolute deviation)",
        :nrm => "Test results from the normality tests on the regARIMA model residuals (Kurtosis, skewness and Geary’s a statistics)", # diagnostic
        :lbq => "Significant lags for the Ljung-Box Q statistic", # diagnostic
        :bpq => "Significant lags for the Box-Pierce Q statistic", # diagnostic
        :dw => "Durbin-Watson statistic for regARIMA model residuals", # diagnostic
        :sft => "Model-based f-statistic for seasonality from Lytras, Feldpausch, and Bell (2007)", # diagnostic
        :tft => "Model-based f-statistic for trading day from Pang and Monsell (2016)", # diagnostic
    ),
    :estimate => Dict{Symbol,String}(
        :opt => "header for the estimation options",
        :mdl => "if used with the print argument, this controls printing of a short description of the model; if used with the save argument, this creates a file containing regression and arima specs corresponding to the model, with the estimation results used to specify initial values for the ARMA parameters",
        :est => "regression and ARMA parameter estimates, with standard errors",
        :afc => "average magnitude of forecast errors over each of the last three years of data.",
        :lks => "log-likelihood at final parameter estimates and, if exact = arma is used (default option), corresponding model selection criteria (AIC, AICC, Hannan-Quinn, BIC)",
        :itr => "detailed output for estimation iterations, including log-likelihood values and parameters, and counts of function evaluations and iterations",
        :ite => "error messages for estimation iterations, including failure to converge",
        :rcm => "correlation matrix of regression parameter estimates if used with the print argument; covariance matrix of same if used with the save argument",
        :acm => "correlation matrix of ARMA parameter estimates if used with the print argument; covariance matrix of same if used with the save argument",
        :lkf => "formulas for computing the log-likelihood and model selection criteria",
        :rts => "roots of the autoregressive and moving average operators in the estimated model",
        :ref => "Xβˆ, matrix of regression variables multiplied by the vector of estimated regression coefficients",
        :rrs => "residuals from regression effects",
        :rsd => "model residuals with associated dates or observation numbers",
        :aic => "Akaike’s Information Criterion (AIC)", # diagnostic
        :acc => "Akaike’s Information Criterion (AIC) adjusted for the length of the series", # diagnostic
        :bic => "Baysean Information Criterion (BIC)", # diagnostic
        :hq => "Hannan-Quinn Information Criterion", # diagnostic
    ),
    :force => Dict{Symbol,String}(
        :saa => "final seasonally adjusted series with constrained yearly totals (if type = regress or type = denton)",
        :rnd => "rounded final seasonally adjusted series (if round = yes) or the rounded final seasonally adjusted series with constrained yearly totals (if type = regress or type = denton)",
        :e6a => "percent changes (differences) in seasonally adjusted series with revised yearly totals",
        :e6r => "percent changes (differences) in rounded seasonally adjusted series",
        :p6a => "percent changes in seasonally adjusted series with forced yearly totals",
        :p6r => "percent changes in rounded seasonally adjusted series",   
    ),
    :forecast => Dict{Symbol,String}(
        :ftr => "forecasts on the transformed scale, with corresponding forecast standard errors",
        :fvr => "forecast error variances on the transformed scale, showing the contributions of the error assuming the model is completely known (stochastic variance) and the error due to estimating any regression parameters (error in estimating AR and MA parameters is ignored)",
        :fct => "point forecasts on the original scale, along with upper and lower prediction interval limits",
        :btr => "backcasts on the transformed scale, with corresponding forecast standard errors",
        :bct => "point backcasts on the original scale, along with upper and lower prediction interval limits",
    ),
    :history => Dict{Symbol,String}(
        :hdr => "header for history analysis",
        :rot => "record of outliers removed and kept for the revisions history (printed only if automatic outlier identification is used)",
        :sar => "revision from concurrent to most recent estimate of the seasonally adjusted data",
        :sas => "summary statistics for seasonal adjustment revisions",
        :chr => "revision from concurrent to most recent estimate of the month-to-month (or quarter-to-quarter) changes in the seasonally adjusted data",
        :chs => "summary statistics for revisions in the month-to-month (or quarter-to-quarter) changes in the seasonally adjusted data",
        :iar => "revision from concurrent to most recent estimate of the indirect seasonally adjusted series",
        :ias => "summary statistics for indirect seasonal adjustment revisions",
        :trr => "revision from concurrent to most recent estimate of the trend component",
        :trs => "summary statistics for trend component revisions",
        :tcr => "revision from concurrent to most recent estimate of the month-to-month (or quarter-to-quarter) changes in the trend component",
        :tcs => "summary statistics for revisions in the month-to-month (or quarter-to-quarter) changes in the trend component",
        :sfr => "revision from concurrent to most recent estimate of the seasonal factor, as well as projected seasonal factors.",
        :ssm => "summary statistics for seasonal factor revisions",
        :lkh => "history of AICC and likelihood values",
        :fce => "revision history of the accumulated sum of squared forecast errors",
        :amh => "history of estimated AR and MA coefficients from the reg-ARIMA model",
        :tdh => "history of estimated trading day regression coefficients from the regARIMA model",
        :sfh => "record of seasonal filter selection for each observation in the revisions history (printed only if automatic seasonal filter selection is used)",
        :sae => "concurrent and most recent estimate of the seasonally adjusted data",
        :che => "concurrent and most recent estimate of the month-tomonth (or quarter-to-quarter) changes in the seasonally adjusted data",
        :iae => "concurrent and most recent estimate of the indirect seasonally adjusted data",
        :tre => "concurrent and most recent estimate of the trend component",
        :tce => "concurrent and most recent estimate of the month-tomonth (or quarter-to-quarter) changes in the trend component",
        :sfe => "concurrent and most recent estimate of the seasonal factors and projected seasonal factors",
        :fch => "listing of the forecast and forecast errors used to generate accumulated sum of squared forecast errors",
        :asa => "average absolute revision of the seasonally adjusted series", # diagnostic
        :ach => "average absolute revision of the month-to-month (or quarter-to-quarter) changes in the seasonally adjusted data", # diagnostic
        :iaa => "average absolute revision of the indirect seasonally adjusted series", # diagnostic
        :atr => "average absolute revision of the final trend component", # diagnostic
        :atc => "average absolute revision of the month-to-month (or quarter-to-quarter) changes in the trend component", # diagnostic
        :asf => "average absolute revision of the final seasonal factors", # diagnostic
        :asp => "average absolute revision of the projected seasonal factors", # diagnostic
        :afe => "average sum of squared forecast error for each forecast lag", # diagnostic
    ),
    :metadata => Dict{Symbol,String}(),
    :identify => Dict{Symbol,String}(
        :iac => "sample autocorrelation function(s), with standard errors and Ljung-Box Q-statistics for each lag",
        :acp => "line printer plot of sample autocorrelation function(s) with ± 2 standard error limits shown on the plot",
        :ipc => "sample partial autocorrelation function(s) with standard errors for each lag",
        :pcp => "line printer plot of sample partial autocorrelation function(s) with ± 2 standard error limits shown on the plot",
        :rgc => "Regression coefficients removed from the transformed series before ACFs and PACFs were generated.",
    ),
    :outlier => Dict{Symbol,String}(
        :hdr => "options specified for outlier detection including critical value, outlier span, and types of outliers searched for",
        :oit => "detailed results for each iteration of outlier detection including outliers detected, outliers deleted, model parameter estimates, and robust and non-robust estimates of the residual standard deviation",
        :ots => "t-statistics for every time point and outlier type on each outlier detection iteration",
        :tls => "summary of t-statistics for temporary level shift tests",
        :fts => "t-statistics for every time point and outlier type generated during the final outlier detection iteration",
    ),
    :pickmdl => Dict{Symbol,String}(
        :pmc => "model choice of pickmdl automatic model selection procedure", 
        :hdr => "header for the pickmdl output",
        :umd => "output for each model used in the pickmdl automatic model selection procedure",
    ),
    :regression => Dict{Symbol,String}(
        :rmx => "values of regression variables with associated dates",
        :ats => "output from AIC-based test(s) for trading day, Easter, and user-defined regression variables",
        :otl => "combined regARIMA outlier factors (table A8)",
        :ao => "regARIMA additive (or point) outlier factors (table A8.AO)",
        :ls => "regARIMA level change, temporary level change and ramp outlier factors (table A8.LS)",
        :so => "regARIMA seasonal outlier factors (table A8.SO)",
        :a13 => "regARIMA transitory component factors from user-defined regressors (table A13)",
        :tc => "regARIMA temporary change outlier factors (table A8.TC)",
        :td => "regARIMA trading day factors (table A6)",
        :hol => "regARIMA holiday factors (table A7)",
        :a10 => "regARIMA user-defined seasonal factors (table A10)",
        :usr => "factors from user-defined regression variables (table A9)",
        :cts => "output from chi-squared based test for groups of user-defined regression variables",
        :tdw => "Daily weights from trading day regressors, normalized to sum to seven",

    ),
    :seats => Dict{Symbol,String}(
        :s10 => "final SEATS seasonal component",
        :s13 => "final SEATS irregular component",
        :s11 => "final SEATS seasonal adjustment component",
        :s14 => "final SEATS transitory component",
        :s16 => "final SEATS combined adjustment factors",
        :s18 => "final SEATS adjustment ratio",
        :tfd => "forecast of the trend component",
        :sfd => "forecast of the seasonal component",
        :ofd => "forecast of the series component",
        :afd => "forecast of the final SEATS seasonal adjustment",
        :yfd => "forecast of the transitory component",
        :sec => "final SEATS seasonal adjustment with constant term included",
        :stc => "final SEATS trend component with constant term included",
        :sta => "total adjustment factors for SEATS seasonal adjustment",
        :dor => "fully differenced transformed original series",
        :dsa => "fully differenced transformed SEATS seasonal adjustment",
        :dtr => "fully differenced transformed SEATS trend",
        :ssm => "seasonal-period-length sums of final SEATS seasonal component",
        :cyc => "cycle component",
        :ltt => "long term trend",
        :mdc => "models for the components",
        :fac => "concurrent finite seasonal adjustment filter",
        :faf => "symmetric finite seasonal adjustment filter",
        :ftc => "concurrent finite trend filter",
        :ftf => "symmetric finite trend filter",
        :gac => "squared gain for finite concurrent seasonal adjustment filter",
        :gaf => "squared gain for finite symmetric seasonal adjustment filter",
        :gtc => "squared gain for finite concurrent trend filter",
        :gtf => "squared gain for finite symmetric trend filter",
        :tac => "time shift for finite concurrent seasonal adjustment filter",
        :ttc => "time shift for finite concurrent trend filter",
        :wkf => "end filters of the semi-infinite Wiener-Kolmogorov filter",
        :pss => "final seasonal factors, expressed as percentages if appropriate",
        :psi => "final irregular component, expressed as percentages if appropriate",
        :psc => "final transitory component, expressed as percentages if appropriate",
        :psa => "combined adjustment factors, expressed as percentages if appropriate",
        :smd => "Model used by the SEATS module for signal extraction", # diagnostic
        :xmd => "Model submitted to the SEATS module", # diagnostic
        :nrm => "Normality test", # diagnostic
        :oue => "Over-under estimation diagnostics", # diagnostic
        :tse => "Total mean squared error", # diagnostic
        :cvr => "Component variances", # diagnostic
        :cee => "Concurrent estimation error", # diagnostic
        :prs => "Percent reduction standard error", # diagnostic
        :aad => "Annual Average absolute difference", # diagnostic
        :ssg => "Test for seasonal significance", # diagnostic



    ),
    :series => Dict{Symbol,String}(
        :hdr => "summary of options selected for this run of X-13-ARIMA-SEATS",
        :a1 => "time series data, with associated dates (if the span argument is present, data are printed and/or saved only for the specified span)",
        :a1p => "plot of the original series",
        :spc => "contents of input specification file used for this run",
        :sav => "list of files to be produced by the X-13-ARIMA-SEATS run",
        :sp0 => "spectral plot of the first-differenced original series",
        :mva => "original series with missing values replaced by reg-ARIMA estimates",
        :a18 => "original series adjusted for regARIMA calendar effects",
        :a19 => "original series adjusted for regARIMA outliers",
        :b1 => "original series, adjusted for prior effects and forecast extended",
        :b1p => "plot of the prior adjusted original series augmented by prior-adjusted forecasts (if specified); if no prior factors or forecasts are used, the original series is plotted",
    ),
    :slidingspans => Dict{Symbol,String}(
        :hdr => "header text for the sliding spans analysis",
        :ssf => "F-tests for stable and moving seasonality estimated over each of the sliding spans",
        :fmn => "range analysis for each of the sliding spans",
        :pct => "table showing the percent of observations flagged as unstable for the seasonal and/or trading day factors, final seasonally adjusted series (if necessary), and the month-to-month (or quarter-toquarter) changes",
        :sum => "tables, histograms and hinge values summarizing the percentage of observations flagged for unstable seasonal and/or trading day factors, final seasonally adjusted series (if necessary), and month-tomonth (or quarter-to-quarter) changes",
        :smy => "additional tables, histograms and hinge values summarizing the percentage of observations flagged for the year-to-year changes",
        :fmi => "range analysis for the implicit adjustment factors of the indirectly seasonally adjusted series",
        :pci => "tables of the percent of observations flagged as unstable for the seasonal factors and month-tomonth (or quarter-to-quarter) changes of the indirect seasonal adjustment",
        :smi => "tables, histograms and hinge values summarizing the percentage of observations flagged for unstable seasonal factors, month-to-month (or quarter-toquarter) and year-to-year changes for the indirect adjustment",
        :pcy => "additional entry for the percent of observations flagged as unstable for the year-to-year changes",
        :sfs => "seasonal factors from all sliding spans",
        :chs => "month-to-month (or quarter-to-quarter) changes from all sliding spans",
        :sas => "seasonally adjusted series from all sliding spans",
        :ycs => "year-to-year changes from all sliding spans",
        :tds => "trading day factors from all sliding spans",
        :pyi => "additonal entry for the percent of observations flagged as unstable for the year-to-year (or quarter-to-quarter) changes of the indirect seasonal adjustment",
        :syi => "additional tables, histograms and hinge values summarizing the percentage of observations flagged for the year-to-year changes of the indirect seasonal adjustment",
        :sis => "indirect seasonal factors from all sliding spans",
        :cis => "indirect month-to-month (or quarter-to-quarter) changes from all sliding spans",
        :ais => "indirect seasonally adjusted series from all sliding spans",
        :yis => "indirect year-to-year changes from all sliding spans",
    ),
    :spectrum => Dict{Symbol,String}(
        :qch => "QS diagnostic to detect seasonality in quarterly version of a monthly series",
        :qs => "QS diagnostic to detect seasonality",
        :sp0 => "spectral plot of the first-differenced original series",
        :sp1 => "spectral plot of differenced, X-11 seasonally adjusted series (or of the logged seasonally adjusted series if mode = logadd or mode = mult)",
        :sp2 => "spectral plot of outlier-modified X-11 irregular series",
        :s1s => "spectrum of the differenced final SEATS seasonal adjustment",
        :s2s => "spectrum of the final SEATS irregular",
        :ser => "spectrum of the extended residuals",
        :spr => "spectral plot of the regARIMA model residuals",
        :is0 => "spectral plot of first-differenced aggregate series",
        :is2 => "spectral plot of the first-differenced indirect seasonally adjusted series",
        :is1 => "spectral plot of outlier-modified irregular series from the indirect seasonal adjustment",
        :tpk => "Peak probability of Tukey spectrum",
        :st0 => "Tukey spectrum of the first-differenced original series",
        :st1 => "Tukey spectrum of the differenced, X-11 seasonally adjusted series (or of the logged seasonally adjusted series if mode = logadd or mode = mult)",
        :st2 => "Tukey spectrum of the outlier-modified X-11 irregular series",
        :st1 => "Tukey spectrum of the differenced final SEATS seasonal adjustment",
        :st2 => "Tukey spectrum of the final SEATS irregular",
        :ter => "Tukey spectrum of the extended residuals",
        :str => "Tukey spectrum of the regARIMA model residuals",
        :it0 => "Tukey spectrum of the first-differenced aggregate series",
        :it2 => "Tukey spectrum of the first-differenced indirect seasonally adjusted series",
        :it1 => "Tukey spectrum of the outlier-modified irregular series from the indirect seasonal adjustment",
        :dpk => "Visually significant peaks in spectra for direct seasonal adjustment", #diagnostic
        :dqs => "QS diagnostic to detect seasonality, direct seasonal adjustment", #diagnostic
        :dtp => "Peak probabilities for Tukey spectra for direct seasonal adjustment", #diagnostic
        :ipk => "Visually significant peaks in spectra for indirect seasonal adjustment", #diagnostic
        :iqs => "QS diagnostic to detect seasonality, indirect seasonal adjustment", #diagnostic
        :itp => "Peak probabilities for Tukey spectra for inddirect seasonal adjustment", #diagnostic
        :spk => "Visually significant peaks in spectra", #diagnostic
        :stp => "Significant peaks of Tukey spectrum", #diagnostic
        :a1 => "original series", #diagnostic
        :a19 => "original series, adjusted for regARIMA outliers", #diagnostic
        :b1 => "original series, adjusted for user specified and reg-", #diagnostic
        :e1 => "original series modified for extremes", #diagnostic
    ),
    :transform => Dict{Symbol,String}(
        :tac => "output from AIC-based test(s) for transformation",
        :a1c => "original series with value from the constant argument added to the series",
        :acp => "plot of original series with value from the constant argument added to the series",
        :a2 => "prior-adjustment factors, with associated dates",
        :a2p => "permanent prior-adjustment factors, with associated dates",
        :a2t => "temporary prior-adjustment factors, with associated dates",
        :a3 => "prior-adjusted series, with associated dates",
        :a3p => "prior-adjusted series using only permanent prior factors, with associated dates",
        :a4d => "prior-adjusted series (including prior trading day adjustments), with associated dates",
        :a4p => "prior-adjusted series using only permanent prior factors and prior trading day adjustments, with associated dates",
        :trn => "prior-adjusted and transformed data, with associated dates",
    ),
    :x11 => Dict{Symbol,String}(
        :fad => "final adjustment difference (only for pseudo-additive seasonal adjustment)",
        :d16 => "combined seasonal and trading day factors",
        :e18 => "final adjustment ratios (original series / seasonally adjusted series)",
        :d18 => "combined holiday and trading day factors",
        :e8 => "percent changes (differences) in original series adjusted for calendar effects",
        :chl => "combined holiday prior adjustment factors, A16 table",
        :d8f => "F-tests for stable and moving seasonality, D8",
        :d13 => "final irregular component",
        :c17 => "final weights for the irregular component",
        :d9a => "moving seasonality ratios for each period",
        :e5 => "percent changes (differences) in original series",
        :f3 => "quality control statistics",
        :d9 => "final replacement values for extreme SI-ratios (differences), D iteration",
        :rsf => "F-test for residual seasonality",
        :e6 => "percent changes (differences) in seasonally adjusted series",
        :d11 => "final seasonally adjusted series",
        :d10 => "final seasonal factors",
        :fsd => "final seasonal difference (only for pseudo-additive seasonal adjustment)",
        :tdy => "trading day factors printed by type of month",
        :tad => "total adjustment factors (only printed out if the original series contains values that are ≤ 0)",
        :d12 => "final trend-cycle",
        :e7 => "percent changes (differences) in final trend component series",
        :d8 => "final unmodified SI-ratios (differences)",
        :d8b => "final unmodified SI-ratios, with labels for outliers and extreme values",
        :f2 => "summary of seasonal adjustment diagnostics",
        :e4 => "ratio of yearly totals of original and seasonally adjusted series",
        :c1 => "original series modified for outliers, trading day and prior factors, C iteration",
        :d1 => "original series modified for outliers, trading day and prior factors, D iteration",
        :asf => "automatic seasonal factor selection",
        :c20 => "extreme values, C iteration",
        :b20 => "extreme values, B iteration",
        :b1f => "F-test for stable seasonality, B1 table",
        :ira => "final irregular component adjusted for point outliers",
        :b13 => "irregular component, B iteration",
        :c13 => "irregular component, C iteration",
        :b17 => "preliminary weights for the irregular component",
        :f1 => "MCD moving average of the final seasonally adjusted series",
        :e3 => "irregular component modified for zero-weighted extreme values",
        :e1 => "original series modified for zero-weighted extreme values",
        :e2 => "seasonally adjusted series modified for zero-weighted extreme values",
        :c4 => "modified SI-ratios (differences), C iteration",
        :d4 => "modified SI-ratios (differences), D iteration",
        :b4 => "preliminary replacement values for extreme SI-ratios (differences), B iteration",
        :b9 => "replacement values for extreme SI-ratios (differences), B iteration",
        :c9 => "modified SI-ratios (differences), C iteration",
        :e11 => "robust final seasonally adjusted series",
        :b11 => "seasonally adjusted series, B iteration",
        :b6 => "preliminary seasonally adjusted series, B iteration",
        :c11 => "seasonally adjusted series, C iteration",
        :c6 => "preliminary seasonally adjusted series, C iteration",
        :sac => "final seasonally adjusted series with constant from transform spec included",
        :d6 => "preliminary seasonally adjusted series, D iteration",
        :b10 => "seasonal factors, B iteration",
        :b5 => "preliminary seasonal factors, B iteration",
        :c10 => "preliminary seasonal factors, C iteration",
        :c5 => "preliminary seasonal factors, C iteration",
        :d5 => "preliminary seasonal factors, D iteration",
        :b3 => "preliminary unmodified SI-ratios (differences)",
        :b8 => "unmodified SI-ratios (differences)",
        :c19 => "original series adjusted for final trading day",
        :b19 => "original series adjusted for preliminary trading day",
        :tal => "final trend-cycle adjusted for level shift outliers",
        :b2 => "preliminary trend-cycle, B iteration",
        :b7 => "preliminary trend-cycle, B iteration",
        :c2 => "preliminary trend-cycle, C iteration",
        :c7 => "preliminary trend-cycle, C iteration",
        :tac => "final trend component with constant from transform spec included",
        :d2 => "preliminary trend-cycle, D iteration",
        :d7 => "preliminary trend-cycle, D iteration",
        :irregularplot => "plot of the final irregular component",
        :origwsaplot => "plot of the original series with the final seasonally adjusted series",
        :ratioplotorig => "month-to-month (or quarter-to-quarter) ratio plots of the original series",
        :ratioplotsa => "month-to-month (or quarter-to-quarter) ratio plots of the seasonally adjusted series",
        :seasadjplot => "plot of the final seasonally adjusted series",
        :seasonalplot => "seasonal factor plots, grouped by month or quarter",
        :trendplot => "plot of the final trend-cycle",
        :paf => "combined adjustment factors, expressed as percentages if appropriate",
        :pe8 => "percent changes in original series adjusted for calendar factors",
        :pir => "final irregular component, expressed as percentages if appropriate",
        :pe5 => "percent changes in the original series",
        :pe6 => "percent changes in seasonally adjusted series",
        :psf => "final seasonal factors, expressed as percentages if appropriate",
        :pe7 => "percent changes in final trend cycle",
        :fb1 => "F-test for stable seasonality, performed on the original series", # diagnostic
        :fd8 => "F-test for stable seasonality, performed on the final SI-ratios", # diagnostic
        :icr => "I/¯ C¯ ratio", # diagnostic
        :ids => "Identifiable seasonality test result", # diagnostic
        :m1 => "M1 Quality Control Statistic", # diagnostic
        :m10 => "M10 Quality Control Statistic", # diagnostic
        :m11 => "M11 Quality Control Statistic", # diagnostic
        :m2 => "M2 Quality Control Statistic", # diagnostic
        :m3 => "M3 Quality Control Statistic", # diagnostic
        :m4 => "M4 Quality Control Statistic", # diagnostic
        :m5 => "M5 Quality Control Statistic", # diagnostic
        :m6 => "M6 Quality Control Statistic", # diagnostic
        :m7 => "M7 Quality Control Statistic", # diagnostic
        :m8 => "M8 Quality Control Statistic", # diagnostic
        :m9 => "M9 Quality Control Statistic", # diagnostic
        :msf => "F-test for moving seasonality", # diagnostic
        :msr => "Moving seasonality ratio", # diagnostic
        :q => "Overall index of the quality of the seasonal adjustment", # diagnostic
        :q2 => "Q statistic computed without the M2 Quality Control statistic", # diagnostic
    ),
    :x11regression => Dict{Symbol,String}(
        :a4 => "prior trading day weights and factors",
        :c14 => "irregulars excluded from the irregular regression, C iteration",
        :c15 => "final irregular regression coefficients and diagnostics",
        :c16 => "final trading day factors and weights",
        :c18 => "final trading day factors from combined daily weights",
        :xhl => "final holiday factors",
        :xca => "final calendar factors (trading day and holiday)",
        :xcc => "final calendar factors from combined daily weights",
        :xoh => "options specified for outlier detection including critical value and outlier span",
        :xat => "output from AIC-based tests for trading day and holiday",
        :b14 => "irregulars excluded from the irregular regression, B iteration",
        :b15 => "preliminary irregular regression coefficients and diagnostics",
        :b16 => "preliminary trading day factors and weights",
        :b18 => "preliminary trading day factors from combined daily weights",
        :bxh => "preliminary holiday factors",
        :bxc => "preliminary calendar factors",
        :bcc => "preliminary calendar factors from combined daily weights",
        :xoi => "detailed results for each iteration of outlier detection including outliers detected, outliers deleted, model parameter estimates, and robust and non-robust estimates of the residual standard deviation",
        :xot => "t-statistics for every time point of each outlier detection iteration",
        :xrm => "values of irregular regression variables with associated dates",
        :xrc => "correlation matrix of irregular regression parameter estimates if used with the print argument; covariance matrix of same if used with the save argument",

    ),
)

_output_udm_description = Dict{Symbol,String}(
    :acf => "residual autocorrelations",
    :acf2 => "squared residual autocorrelations",
    :adjcori => "composite series (prior adjusted)",
    :ador => "original series (prior adjusted)",
    :ahst => "concurrent and revised seasonal adjustments and revisions",
    :aichst => "revision history of the likelihood statistics",
    :ao => "regARIMA AO outlier component",
    :arat => "final adjustment ratios",
    :armahst => "ARMA model coefficient history",
    :bct => "point backcasts and prediction intervals on the original scale",
    :btr => "point backcasts and standard errors for the transformed data",
    :cad => "regARIMA calendar adjusted original data",
    :caf => "combined adjustment factors",
    :cal => "combined calendar adjustment factors",
    :ccal => "final combined calendar factors from irregular component regression",
    :cfchst => "forecast and forecast error history",
    :chol => "combined holiday component",
    :chss => "sliding spans of the changes in the seasonally adjusted series",
    :cmpcad => "regARIMA calendar adjusted composite data",
    :cmpoad => "regARIMA outlier adjusted composite data",
    :cmpori => "composite time series data (for the span analyzed)",
    :cmppadj => "prior adjusted composite data",
    :cmpspor => "spectrum of the composite series",
    :cmpsptukor => "Tukey spectrum of the composite series",
    :csahst => "history of the period-to-period changes of the seasonal adjustments",
    :ctd => "final combined trading day factors from irregular component regression",
    :ctrhst => "history of the period-to-period changes of the trend-cycle values",
    :fct => "point forecasts and prediction intervals on the original scale",
    :fcthst => "revision history of the out-of-sample forecasts",
    :fintst => "final outlier test statistics",
    :fltsac => "concurrent seasonal adjustment filter",
    :fltsaf => "symmetric seasonal adjustment filter",
    :flttrnc => "concurrent trend filter",
    :flttrnf => "symmetric trend filter",
    :frfc => "factors applied to get adjusted series with forced yearly totals",
    :ftr => "point forecasts and standard errors for the transformed data",
    :idacf => "residual autocorrelations for different orders of differencing",
    :idpacf => "residual partial autocorrelations for different orders of differencing",
    :indahst => "concurrent and revised indirect seasonal adjustments and revisions",
    :indao => "indirect additive outlier adjustment factors",
    :indarat => "indirect final adjustment ratios",
    :indcaf => "indirect combined adjustment factors",
    :indcal => "indirect calendar component",
    :indchss => "sliding spans of the changes in the indirect seasonally adjusted series",
    :indfrfc => "factors applied to get indirect adjusted series with forced yearly totals",
    :indirr => "indirect irregular component",
    :indls => "indirect level change adjustment factors",
    :indmirr => "irregular component modified for extremes from indirect adjustment",
    :indmori => "original data modified for extremes from indirect adjustment",
    :indmsa => "seasonally adjusted data modified for extremes from indirect adjustment",
    :indrsi => "final replacement values for SI component of indirect adjustment",
    :indsa => "indirect seasonally adjusted data",
    :indsar => "rounded indirect final seasonally adjusted series",
    :indsass => "sliding spans of the indirect seasonally adjusted series",
    :indsat => "final indirect seasonally adjusted series with forced yearly totals",
    :indsf => "indirect seasonal component",
    :indsfss => "sliding spans of the indirect seasonal factors",
    :indsi => "indirect unmodified SI component",
    :indspir => "spectrum of indirect modified irregular component",
    :indspsa => "spectrum of differenced indirect seasonally adjusted series",
    :indsptukir => "Tukey spectrum of indirect modified irregular component",
    :indsptuksa => "Tukey spectrum of differenced indirect seasonally adjusted series",
    :indtadj => "indirect total adjustment factors",
    :indtrn => "indirect trend cycle",
    :indyyss => "sliding spans of the year-to-year changes in the indirect seasonally adjusted series",
    :irr => "final irregular component",
    :irrwt => "final weights for irregular component",
    :ls => "regARIMA level change outlier component",
    :mdlest => "regression and ARMA parameter estimates",
    :mirr => "modified irregular series",
    :mori => "original data modified for extremes",
    :msa => "modified seasonally adjusted series",
    :mvadj => "original series adjusted for missing value regressors",
    :oad => "regARIMA outlier adjusted original data",
    :ori => "time series data (for the span analyzed)",
    :oricnt => "time series data plus constant (for the span analyzed)",
    :orifctd => "series forecast decomposition (SEATS)",
    :otl => "regARIMA combined outlier component",
    :pacf => "residual partial autocorrelation",
    :padj => "prior-adjusted data",
    :padjt => "prior-adjusted data (including prior trading day adjustments)",
    :ppradj => "permanent prior-adjusted data",
    :ppradjt => "permanent prior-adjusted data (including prior trading day adjustments)",
    :pprior => "permanent prior-adjustment factors",
    :prior => "prior-adjustment factors",
    :ptd => "prior trading day factors",
    :regrsd => "residuals from the estimated regression effects",
    :rgseas => "regARIMA user-defined seasonal component",
    :rhol => "regARIMA holiday component",
    :rsi => "final replacement values for SI ratios",
    :rtd => "regARIMA trading day component",
    :sa => "final seasonally adjusted data",
    :sac => "final seasonally adjusted series with constant value added",
    :safctd => "final seasonally adjusted series forecast decomposition (SEATS)",
    :sar => "rounded final seasonally adjusted series",
    :sass => "sliding spans of the seasonally adjusted series",
    :sat => "final seasonally adjusted series with forced yearly totals",
    :seataf => "final combined adjustment factors (SEATS)",
    :seatase => "standard error of final seasonally adjusted series (SEATS)",
    :seatcse => "standard error of final transitory component (SEATS)",
    :seatcyc => "final cycle",
    :seatdori => "differenced original series after transformation, prior adjustment (SEATS)",
    :seatdsa => "differenced final seasonally adjusted series (SEATS)",
    :seatdtr => "differenced final trend (SEATS)",
    :seatirr => "final irregular component (SEATS)",
    :seatltt => "final long term trend",
    :seatsa => "final seasonally adjusted series (SEATS)",
    :seatsf => "final seasonal component (SEATS)",
    :seatsse => "standard error of final seasonal component (SEATS)",
    :seatssm => "sum of final seasonal component (SEATS)",
    :seattrn => "final trend component (SEATS)",
    :seattse => "standard error of final trend component (SEATS)",
    :setarat => "final adjustment ratios (SEATS)",
    :setsac => "final seasonally adjusted series with constant value added (SEATS)",
    :settadj => "total adjustment factors (SEATS)",
    :settrc => "final trend cycle with constant value added (SEATS)",
    :settrns => "final transitory component (SEATS)",
    :sf => "final seasonal factors",
    :sffctd => "final seasonal component forecast decomposition (SEATS)",
    :sfhst => "concurrent and projected seasonal component and their percent revisions",
    :sfr => "seasonal factors, adjusted for user-defined seasonal regARIMA component",
    :sfss => "sliding spans of the seasonal factors",
    :sgsac => "squared gain of the concurrent seasonal adjustment filter",
    :sgsaf => "squared gain of the symmetric seasonal adjustment filter",
    :sgtrnc => "squared gain of the concurrent trend filter",
    :sgtrnf => "squared gain of the symmetric trend filter",
    :si => "final unmodified SI ratios",
    :siox => "final unmodified SI ratios, with labels for outliers and extreme values",
    :so => "regARIMA seasonal outlier component",
    :spcsir => "spectrum of the irregular component (SEATS)",
    :spcssa => "spectrum of the seasonally adjusted series (SEATS)",
    :spctuksir => "Tukey spectrum of the irregular component (SEATS)",
    :spctukssa => "Tukey spectrum of the seasonally adjusted series (SEATS)",
    :spexrsd => "spectrum of the extended residuals (SEATS)",
    :spir => "spectrum of modified irregular series",
    :spor => "spectrum of the original series",
    :sprsd => "spectrum of the regARIMA model residuals",
    :spsa => "spectrum of differenced seasonally adjusted series",
    :sptukexrsd => "Tukey spectrum of the extended residuals (SEATS)",
    :sptukir => "Tukey spectrum of modified irregular series",
    :sptukor => "Tukey spectrum of the original series",
    :sptukrsd => "Tukey spectrum of the regARIMA model residuals",
    :sptuksa => "Tukey spectrum of differenced seasonally adjusted series",
    :tadj => "total adjustment factors",
    :tc => "regARIMA temporary change outlier component",
    :tdhst => "trading day coefficient history",
    :tdss => "sliding spans of the trading day factors",
    :tprior => "temporary prior-adjustment factors",
    :trancmp => "regARIMA transitory component",
    :tranfcd => "final transitory component forecast decomposition (SEATS)",
)