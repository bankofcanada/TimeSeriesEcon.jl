## Note: this file will not run as part of the standard tests as it relies on other packages

using Revise
using FAME
using TimeSeriesEcon
using Test
using ProgressMeter
using Suppressor

to_fame_frequencies_map = Dict{Type, String}(
    Unit            => "case",
    Yearly          => "annual(december)",
    Yearly{1}       => "annual(january)",
    Yearly{2}       => "annual(february)",
    Yearly{3}       => "annual(march)",
    Yearly{4}       => "annual(april)",
    Yearly{5}       => "annual(may)",
    Yearly{6}       => "annual(june)",
    Yearly{7}       => "annual(july)",
    Yearly{8}       => "annual(august)",
    Yearly{9}       => "annual(september)",
    Yearly{10}      => "annual(october)",
    Yearly{11}      => "annual(november)",
    Yearly{12}      => "annual(december)",
    HalfYearly      => "semiannual(december)",
    HalfYearly{1}   => "semiannual(july)",
    HalfYearly{2}   => "semiannual(august)",
    HalfYearly{3}   => "semiannual(september)",
    HalfYearly{4}   => "semiannual(october)",
    HalfYearly{5}   => "semiannual(november)",
    HalfYearly{6}   => "semiannual(december)",
    Quarterly       => "quarterly(december)",
    Quarterly{1}    => "quarterly(october)",
    Quarterly{2}    => "quarterly(november)",
    Quarterly{3}    => "quarterly(december)",
    Quarterly       => "quarterly(december)",
    Monthly         => "monthly",
    Weekly{1}       => "weekly(monday)",
    Weekly{2}       => "weekly(tuesday)",
    Weekly{3}       => "weekly(wednesday)",
    Weekly{4}       => "weekly(thursday)",
    Weekly{5}       => "weekly(friday)",
    Weekly{6}       => "weekly(saturday)",
    Weekly{7}       => "weekly(sunday)",
    Weekly          => "weekly(sunday)",
    Daily           => "daily",
    BDaily          => "business",
)

function get_fame_conversion_string(F_to, F_from, method, values_base)
    # q, disc, ave
    s = "$(to_fame_frequencies_map[F_to]), "
    if method == :mean
        s = s*"discrete, averaged"
    elseif method == :point
        if values_base == :end
            s = s*"discrete, end"
        end
        if values_base == :begin
            s = s*"discrete, beginning"
        end
    elseif method == :max
        s = s*"discrete, high"
    elseif method == :min
        s = s*"discrete, low"
    elseif method == :sum
        s = s*"discrete, summed"
    elseif method == :const 
        if values_base == :end
            s = s*"constant, end"
        end
        if values_base == :begin
            s = s*"discrete, beginning"
        end
    elseif method == :even 
        s = s*"discrete, summed"
    elseif method == :linear
        s = s*"linear,"
        if values_base == :end
            s = s*"end"
        end
        if values_base == :begin
            s = s*"beginning"
        end
        # if values_base == :middle
        #     s = s*"averaged"
        # end
    end
    # println(s)
    return s
end

function get_fame_convert(F_to, ts; method=:mean, values_base=:end)
    F_from = frequencyof(ts)
    if ppy(F_from) < ppy(F_to) && method == :mean
        method = :const
    end
    # FAME.init_chli()
    writefame(FAME.workdb(),Workspace(:ts => ts))
    fame_string = """work'ts_fame = convert(work'ts, $(get_fame_conversion_string(F_to, F_from, method, values_base)))"""
    if values_base == :begin && method ∉ (:point, :const, :even, :linear)
        fame_string = """
            ignore on
            work'ts_intermediate = convert(work'ts, daily, discrete, beginning)
            work'ts_fame = convert(work'ts_intermediate, $(get_fame_conversion_string(F_to, F_from, method, values_base)))
            ignore off
        """
    elseif values_base == :begin && method ∈ (:const,)
        fame_string = """
            ignore on
            work'ts_intermediate = convert(work'ts, daily, const, beginning)
            work'ts_fame = convert(work'ts_intermediate, $(get_fame_conversion_string(F_to, F_from, method, values_base)))
            ignore off
        """
    end
    fame(fame_string)
    ts_fame = readfame(FAME.workdb()).ts_fame
    # FAME.init_chli()
    # sleep(0.1)
    return ts_fame
end


@testset "fconvert, all combinations" begin
    frequencies = [
        Daily,
        BDaily, 
        Weekly,
        Weekly{1},
        Weekly{2},
        Weekly{3},
        Weekly{4},
        Weekly{5},
        Weekly{6},
        Weekly{7},
        Monthly,
        Quarterly,
        Quarterly{1},
        Quarterly{2},
        Quarterly{3},
        HalfYearly,
        HalfYearly{1},
        HalfYearly{2},
        HalfYearly{3},
        HalfYearly{4},
        HalfYearly{5},
        HalfYearly{6},
        Yearly,
        Yearly{1},
        Yearly{2},
        Yearly{3},
        Yearly{4},
        Yearly{5},
        Yearly{6},
        Yearly{7},
        Yearly{8},
        Yearly{9},
        Yearly{10},
        Yearly{11},
        Yearly{12}
    ]
    # combinations = [(F_from, l, F_to,) for F_from in frequencies for l in -5:5 for F_to in frequencies ]
    combinations = [(F_from, l, F_to,) for F_from in frequencies for l in 0:0 for F_to in frequencies ]
    # println(combinations[1:100])
    counter = 1
    t_from = nothing
    last_F_from = nothing
    last_l = nothing
    FAME.init_chli()
    fame("""
        overwrite on
        ignore off
    """)
    @showprogress "combinations" for (F_from, l, F_to,) in combinations
    # for (F_from, F_to) in combinations
        if F_from != last_F_from || last_l !== l
            last_l = l
            last_F_from = F_from
            first_mit = MIT{F_from}(100)
            first_mit += ppy(F_from)*1930
            t_from = TSeries(first_mit, collect(1:800-l))
        end
        if F_to !== F_from
            # println(counter, ", from:", F_from, ", to:", F_to)

            # TSeries
            t_to = @suppress fconvert(F_to, t_from)
            
            # println(F_from, ", ", F_to)
            if F_to <= F_from
                for method in (:mean, :point, :min, :max, :sum) # :sum, :point, :min, :max)
                    for values_base in (:end, :begin) #:begin)
                        # println(rangeof(t_from))
                        # println(F_from, ", ", F_to, ", ", method, ", ", values_base)
                        if method == :point
                            t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                            t_to_sub_fame = get_fame_convert(F_to, t_from, method=method, values_base=values_base)
                            @test rangeof(t_to_sub) == rangeof(t_to_sub_fame)
                            @test values(t_to_sub) ≈ values(t_to_sub_fame) nans=true
                        else
                            # values_base = :end
                            t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                            t_to_sub_fame = get_fame_convert(F_to, t_from, method=method, values_base=values_base)
                            @test rangeof(t_to_sub) ⊆ rangeof(t_to_sub_fame)
                            @test values(t_to_sub) ≈ values(t_to_sub_fame[rangeof(t_to_sub)]) nans=true
                        end
                       
                    end
                end
            elseif F_to > F_from
                for method in (:const, :even)
                    for values_base in (:end, :begin)
                        if values_base == :begin && method == :even
                            # no FAME equivalent for this combination
                            continue
                        end
                        # println(rangeof(t_from), ", ", F_to)
                        # println(method, ", ", values_base)
                        t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                        t_to_sub_fame = get_fame_convert(F_to, t_from, method=method, values_base=values_base)
                        @test rangeof(t_to_sub) ⊆ rangeof(t_to_sub_fame)
                        if F_from == BDaily && F_to == Daily && method == :const 
                            # in this conversion TimeSeriesEcon provides values on weekdays but FAME does not
                            days = [fconvert(Daily, mit) for mit in collect(rangeof(t_from))]
                            @test t_to_sub[days] == t_to_sub_fame[days]
                            continue
                        end
                        @test values(t_to_sub) ≈ values(t_to_sub_fame[rangeof(t_to_sub)]) nans=true
                    end
                end
                if F_to ∈ (Daily, BDaily, Monthly) #Daily,BDaily, Monthly)
                    for method in (:linear, )
                        for values_base in (:end, :begin) # :begin, :middle)
                            t_to_sub = @suppress fconvert(F_to, t_from, method=method, values_base=values_base)
                            t_to_sub_fame = get_fame_convert(F_to, t_from, method=method, values_base=values_base)
                            if values_base == :end
                                fame_range = fconvert(F_to, firstdate(t_from), values_base=:end):rangeof(t_to_sub)[end]
                            elseif values_base ==:begin
                                fame_range = rangeof(t_to_sub)[begin]:fconvert(F_to, rangeof(t_from)[end], values_base=:begin, round_to=:next)
                            end
                            @test fame_range == rangeof(t_to_sub_fame)
                            if F_from == BDaily && F_to == Daily && method == :linear 
                                days = [fconvert(Daily, mit) for mit in collect(rangeof(t_from))]
                                @test t_to_sub[days] ≈ t_to_sub_fame[days] nans=true rtol=1e-3
                                continue
                            end
                            @test values(t_to_sub[fame_range]) ≈ values(t_to_sub_fame) nans=true rtol=1e-3
                        end
                    end
                end
            end
            
            counter += 1
        end
    end
end