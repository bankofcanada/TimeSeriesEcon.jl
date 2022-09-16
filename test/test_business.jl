"""
FAME Reproduction scripts
whats v39055
DATE 2021
HOLIDAY ON
repo v39055, shift(v39055, 1), diff(v39055), shift(v39055, -1), pct(v39055)
"""

@testset "BusinessDaily" begin
    # v39055, Bond, benchmark bonds, Canada, issued by the Government of Canada, 10-year original maturity, average yield
    
    bonds_data = [NaN,0.68,0.7,0.75,0.79,0.81,0.83,0.84,0.81,0.86,0.81,0.8,0.8,0.83,0.87,0.84,0.81,0.82,0.8,0.82,0.84,0.88,0.91,0.94,0.96,1,1.01,0.99,0.99,0.99,1.03,NaN,1.12,1.11,1.14,1.21,1.23,1.26,1.31,1.46,1.35,1.35,1.33,1.4,1.49,1.5,1.53,1.45,1.41,1.43,1.58,1.54,1.56,1.58,1.61,1.59,1.55,1.49,1.47,1.46,1.49,1.53,1.53,1.55,1.51,NaN,1.56,1.49,1.5,1.46,1.5,1.51,1.5,1.53,1.45,1.53,1.53,1.5,1.52,1.52,1.51,1.53,1.56,1.53,1.56,1.54,1.52,1.53,1.51,1.51,1.49,1.51,1.54,1.59,1.56,1.55,1.57,1.56,1.58,1.54,1.54,NaN,1.46,1.45,1.49,1.49,1.49,1.5,1.49,1.52,1.46,1.47,1.45,1.41,1.38,1.38,1.39,1.38,1.44,1.4,1.37,1.41,1.4,1.42,1.41,1.45,1.41,1.42,1.39,NaN,1.37,1.4,1.32,1.29,1.26,1.32,1.32,1.34,1.29,1.26,1.24,1.14,1.17,1.22,1.19,1.21,1.22,1.16,1.17,1.19,1.2,NaN,1.12,1.13,1.16,1.24,1.25,1.27,1.26,1.25,1.19,1.16,1.15,1.16,1.13,1.14,1.16,1.18,1.25,1.23,1.2,1.18,1.22,1.18,1.15,1.19,NaN,1.23,1.2,1.17,1.23,1.22,1.17,1.22,1.23,1.29,1.22,1.22,1.21,1.33,1.38,1.41,1.5,1.51,NaN,1.47,1.49,1.53,1.5,1.56,1.62,NaN,1.62,1.61,1.53,1.58,1.58,1.63,1.63,1.68,1.65,1.65,1.63,1.6,1.66,1.72,1.74,1.72,1.71,1.64,1.59,1.63,1.59,1.68,NaN,1.67,1.72,1.77,1.7,1.69,1.66,1.76,1.81,1.77,1.77,1.59,1.61,1.58,1.5,1.49,1.45,1.51,1.58,1.56,1.5,1.47,1.4,1.43,1.41,1.35,1.32,1.38,1.44,1.42,1.44,1.46,NaN,NaN,1.47,1.45,1.42,]
    tsbd = TSeries(TimeSeriesEcon.bdaily("2021-01-01"), bonds_data)
    @test length(tsbd) == 261

    TimeSeriesEcon.set_option(:business_skip_nans, true)
    TimeSeriesEcon.set_option(:business_skip_holidays, false)
    TimeSeriesEcon.clear_holidays_map();

    @test values(tsbd[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test tsbd[end-9:end].values ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-01"):TimeSeriesEcon.bdaily("2021-01-14")

    tsbd_shifted = shift(tsbd,1)
    @test values(tsbd_shifted[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.47, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_shifted[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-17"):TimeSeriesEcon.bdaily("2021-12-30")
    @test rangeof(tsbd_shifted[begin:begin+9]) == TimeSeriesEcon.bdaily("2020-12-31"):TimeSeriesEcon.bdaily("2021-01-13")
    @test values(tsbd_shifted[begin:begin+9]) ≈ [0.68, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true

    tsbd_diffed = diff(tsbd)
    @test values(tsbd_diffed[end-9:end]) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, NaN, 0.01, -0.02, -0.03] nans = true
    @test rangeof(tsbd_diffed[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_diffed[begin:begin+9]) ≈ [NaN,0.02, 0.05, 0.04, 0.02, 0.02, 0.01,-0.03, 0.05,-0.05] nans = true
    @test rangeof(tsbd_diffed[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_lagged = lag(tsbd)
    @test rangeof(tsbd_lagged[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-21"):TimeSeriesEcon.bdaily("2022-01-03")
    @test values(tsbd_lagged[end-9:end]) ≈[1.38, 1.44, 1.42, 1.44, 1.46, 1.46, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_lagged[begin:begin+9]) ≈ [NaN,0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    
    tsbd_pct = pct(tsbd)
    @test values(tsbd_pct[end-9:end]) ≈[4.55, 4.35, -1.39, 1.41, 1.39, NaN, NaN, 0.68, -1.36, -2.07] nans = true atol=0.01
    @test rangeof(tsbd_pct[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")
    @test rangeof(tsbd_pct[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_pct[begin:begin+9]) ≈ [NaN, 2.94, 7.14, 5.33, 2.53, 2.47, 1.20, -3.57, 6.17, -5.81] nans = true atol=0.01
    @test rangeof(tsbd_pct[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    # Holidays OFF
    TimeSeriesEcon.set_option(:business_skip_nans, false)
    tsbd_shifted2 = shift(tsbd,1)
    @test values(tsbd_shifted2[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_shifted2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-17"):TimeSeriesEcon.bdaily("2021-12-30")
    @test values(tsbd_shifted2[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd_shifted2[begin:begin+9]) == TimeSeriesEcon.bdaily("2020-12-31"):TimeSeriesEcon.bdaily("2021-01-13")

    tsbd_diffed2 = diff(tsbd)
    @test values(tsbd_diffed2[end-9:end]) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, NaN, NaN, -0.02, -0.03] nans = true
    @test rangeof(tsbd_diffed2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_diffed2[begin:begin+9]) ≈ [NaN,0.02, 0.05, 0.04, 0.02, 0.02, 0.01,-0.03, 0.05,-0.05] nans = true
    @test rangeof(tsbd_diffed2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_lagged2 = lag(tsbd)
    @test values(tsbd_lagged2[end-9:end]) ≈[1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_lagged2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-21"):TimeSeriesEcon.bdaily("2022-01-03")
    @test values(tsbd_lagged2[begin:begin+9]) ≈ [NaN,0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd_lagged2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_pct2 = pct(tsbd)
    @test values(tsbd_pct2[end-9:end]) ≈[4.55, 4.35, -1.39, 1.41, 1.39, NaN, NaN, NaN, -1.36, -2.07] nans = true atol=0.01
    @test rangeof(tsbd_pct2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_pct2[begin:begin+9]) ≈ [NaN, 2.94, 7.14, 5.33, 2.53, 2.47, 1.20, -3.57, 6.17, -5.81] nans = true atol=0.01
    @test rangeof(tsbd_pct2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")
    
    # reset the option
    TimeSeriesEcon.set_option(:business_skip_nans, false)

    ## Testing holidays map
    covered_range = bdaily("1970-01-01"):bdaily("2049-12-31");
    test_ts = TSeries(first(covered_range), ones(Bool, length(covered_range)));
    test_ts[bdaily("2021-12-27"):bdaily("2021-12-28")] .= false;
    TimeSeriesEcon.set_option(:business_holidays_map, test_ts);
    TimeSeriesEcon.set_option(:business_skip_holidays, true);
    # tsmall = TSeries(TimeSeriesEcon.bdaily("2021-12-20"), [1,2,3,4,5,NaN,NaN,8,9,10])
    tsmall = TSeries(TimeSeriesEcon.bdaily("2021-12-20"), [1,2,3,4,5,NaN,NaN,8,NaN,10])
    tsmall_shifted = shift(tsmall,1)
    tsmall_diffed = diff(tsmall)
    tsmall_lagged = lag(tsmall)
    tsmall_pct = pct(tsmall)
    # MVTSeries(orig = tsmall, lagged = shift(tsmall, -1), diffed = diff(tsmall), pct = pct(tsmall))
    
    # TimeSeriesEcon.set_holidays_map("ON", test_ts);

    # Shifts and lags when business_skip_holidays = true, but business_skip_nans = false
    # NaNs on holidays will be replaced with the appropriate non-holiday, non-nan value
    # NaNs on non-holidays will not be replaced and will be shifted appropriately 
    @test tsmall[end-9:end].values ≈         [1,2,3,4,5,NaN,NaN,8,NaN,10] nans = true
    @test tsmall_shifted[end-9:end].values ≈ [1,2,3,4,5,8,8,8,NaN,10] nans = true
    @test tsmall_lagged[end-9:end].values ≈  [1,2,3,4,5,5,5,8,NaN,10] nans = true
    @test tsmall_diffed[end-8:end].values ≈  [1,1,1,1,NaN,NaN,3,NaN,NaN] nans = true
    @test tsmall_pct[end-8:end].values ≈     [100,50,100/3,25,NaN,NaN,60,NaN,NaN] nans = true atol=0.01

    # When the NaN is up against holidays it shifts to the other side. 
    # The Holiday values will also be replaced with a NaN when this is the latest available non-holiday value
    tsmall2 = TSeries(TimeSeriesEcon.bdaily("2021-12-20"), [1,2,3,4,5,NaN,NaN,NaN,9,10])
    tsmall2_shifted = shift(tsmall2,1)
    tsmall2_diffed = diff(tsmall2)
    tsmall2_lagged = lag(tsmall2)
    tsmall2_pct = pct(tsmall2)
    @test tsmall2[end-9:end].values ≈         [1,2,3,4,5,NaN,NaN,NaN,9,10] nans = true
    @test tsmall2_shifted[end-9:end].values ≈ [1,2,3,4,5,NaN,NaN,NaN,9,10] nans = true
    @test tsmall2_lagged[end-9:end].values ≈  [1,2,3,4,5,5,5,NaN,9,10] nans = true
    @test tsmall2_diffed[end-8:end].values ≈  [1,1,1,1,NaN,NaN,NaN,NaN,1] nans = true
    @test tsmall2_pct[end-8:end].values ≈     [100,50,100/3,25,NaN,NaN,NaN,NaN,100/9] nans = true atol=0.01

    # The values function returns only a subset of values
    @test values(tsbd[end-9:end]) ≈         [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_shifted[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_lagged[end-9:end]) ≈  [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_diffed[end-9:end]) ≈  [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02, -0.03] nans = true
    @test values(tsbd_pct[end-9:end]) ≈     [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36, -2.07] nans = true atol=0.01

    @test values(tsbd_shifted2[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46,  NaN, 1.45, 1.42] nans = true
    @test values(tsbd_lagged2[end-9:end]) ≈  [1.38, 1.44, 1.42, 1.44,  NaN, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_diffed2[end-9:end]) ≈  [0.06, 0.06, -0.02, 0.02, 0.02, NaN, -0.02, -0.03] nans = true
    @test values(tsbd_pct2[end-9:end]) ≈     [4.55, 4.35, -1.39, 1.41, 1.39, NaN, -1.36, -2.07] nans = true atol=0.01

    @test values(tsmall[end-9:end]) ≈         [1,2,3,4,5,8,NaN,10] nans = true
    @test values(tsmall_shifted[end-9:end]) ≈ [1,2,3,4,5,8,NaN,10] nans = true
    @test values(tsmall_lagged[end-9:end]) ≈  [1,2,3,4,5,8,NaN,10] nans = true
    @test values(tsmall_diffed[end-8:end]) ≈  [1,1,1,1,3,NaN,NaN] nans = true
    @test values(tsmall_pct[end-8:end]) ≈     [100,50,100/3,25,60,NaN,NaN] nans = true atol=0.01

    @test values(tsmall2[end-9:end]) ≈         [1,2,3,4,5,NaN,9,10] nans = true
    @test values(tsmall2_shifted[end-9:end]) ≈ [1,2,3,4,5,NaN,9,10] nans = true
    @test values(tsmall2_lagged[end-9:end]) ≈  [1,2,3,4,5,NaN,9,10] nans = true
    @test values(tsmall2_diffed[end-8:end]) ≈  [1,1,1,1,NaN,NaN,1] nans = true
    @test values(tsmall2_pct[end-8:end]) ≈     [100,50,100/3,25,NaN,NaN,100/9] nans = true atol=0.01
   
    TimeSeriesEcon.clear_holidays_map()
    TimeSeriesEcon.set_option(:business_skip_nans, false)
    TimeSeriesEcon.set_option(:business_skip_holidays, false);

    ## Testing ON holidays map
    ## Note that the Canadian holidays maps are currently wrong! It sets, Dec 24, 27 and 31 as holidays. 
    # The real values are 27 and 28 (except for Quebec)
    TimeSeriesEcon.set_holidays_map("CA", "ON");
    TimeSeriesEcon.set_option(:business_skip_nans, false)
    TimeSeriesEcon.set_option(:business_skip_holidays, true);
    @test values(tsbd[end-9:end]) ≈         [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45] nans = true
    @test values(tsbd_shifted[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_lagged[end-9:end]) ≈  [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.42] nans = true
    @test values(tsbd_diffed[end-9:end]) ≈  [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02] nans = true
    @test values(tsbd_pct[end-9:end]) ≈     [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36] nans = true atol=0.01

    tsbd_shifted3 = shift(tsbd,1)
    tsbd_diffed3 = diff(tsbd)
    tsbd_lagged3 = lag(tsbd)
    tsbd_pct3 = pct(tsbd)
    @test values(tsbd[end-9:end]) ≈         [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45] nans = true
    @test values(tsbd_shifted3[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_lagged3[end-9:end]) ≈  [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.42] nans = true
    @test values(tsbd_diffed3[end-9:end]) ≈  [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02] nans = true
    @test values(tsbd_pct3[end-9:end]) ≈     [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36] nans = true atol=0.01
    

    TimeSeriesEcon.clear_holidays_map()
    TimeSeriesEcon.set_option(:business_skip_holidays, false)
    TimeSeriesEcon.set_option(:business_skip_nans, false)
end

@testset "BusinessDaily, convert" begin
    bonds_data = [NaN,0.68,0.7,0.75,0.79,0.81,0.83,0.84,0.81,0.86,0.81,0.8,0.8,0.83,0.87,0.84,0.81,0.82,0.8,0.82,0.84,0.88,0.91,0.94,0.96,1,1.01,0.99,0.99,0.99,1.03,NaN,1.12,1.11,1.14,1.21,1.23,1.26,1.31,1.46,1.35,1.35,1.33,1.4,1.49,1.5,1.53,1.45,1.41,1.43,1.58,1.54,1.56,1.58,1.61,1.59,1.55,1.49,1.47,1.46,1.49,1.53,1.53,1.55,1.51,NaN,1.56,1.49,1.5,1.46,1.5,1.51,1.5,1.53,1.45,1.53,1.53,1.5,1.52,1.52,1.51,1.53,1.56,1.53,1.56,1.54,1.52,1.53,1.51,1.51,1.49,1.51,1.54,1.59,1.56,1.55,1.57,1.56,1.58,1.54,1.54,NaN,1.46,1.45,1.49,1.49,1.49,1.5,1.49,1.52,1.46,1.47,1.45,1.41,1.38,1.38,1.39,1.38,1.44,1.4,1.37,1.41,1.4,1.42,1.41,1.45,1.41,1.42,1.39,NaN,1.37,1.4,1.32,1.29,1.26,1.32,1.32,1.34,1.29,1.26,1.24,1.14,1.17,1.22,1.19,1.21,1.22,1.16,1.17,1.19,1.2,NaN,1.12,1.13,1.16,1.24,1.25,1.27,1.26,1.25,1.19,1.16,1.15,1.16,1.13,1.14,1.16,1.18,1.25,1.23,1.2,1.18,1.22,1.18,1.15,1.19,NaN,1.23,1.2,1.17,1.23,1.22,1.17,1.22,1.23,1.29,1.22,1.22,1.21,1.33,1.38,1.41,1.5,1.51,NaN,1.47,1.49,1.53,1.5,1.56,1.62,NaN,1.62,1.61,1.53,1.58,1.58,1.63,1.63,1.68,1.65,1.65,1.63,1.6,1.66,1.72,1.74,1.72,1.71,1.64,1.59,1.63,1.59,1.68,NaN,1.67,1.72,1.77,1.7,1.69,1.66,1.76,1.81,1.77,1.77,1.59,1.61,1.58,1.5,1.49,1.45,1.51,1.58,1.56,1.5,1.47,1.4,1.43,1.41,1.35,1.32,1.38,1.44,1.42,1.44,1.46,NaN,NaN,1.47,1.45,1.42,]
    tsbd = TSeries(TimeSeriesEcon.bdaily("2021-01-01"), bonds_data)

    TimeSeriesEcon.clear_holidays_map()
    TimeSeriesEcon.set_option(:business_skip_holidays, false)
    TimeSeriesEcon.set_option(:business_skip_nans, false)

    q1 = fconvert(Quarterly, tsbd)
    @test q1.values ≈ [NaN, NaN, NaN, NaN] nans=true

    TimeSeriesEcon.set_holidays_map("CA", "ON");
    TimeSeriesEcon.set_option(:business_skip_holidays, true)
    TimeSeriesEcon.set_option(:business_skip_nans, false)

    q2 = fconvert(Quarterly, tsbd)
    @test q2.values ≈ [1.152, 1.486, NaN, NaN] nans=true atol=1e-3

    q3 = fconvert(Quarterly, tsbd, nans=true)
    @test q3.values ≈ [1.152, 1.486, 1.235, 1.580] nans=true atol=1e-3

    TimeSeriesEcon.set_holidays_map("CA", "ON");
    TimeSeriesEcon.set_option(:business_skip_holidays, true)
    TimeSeriesEcon.set_option(:business_skip_nans, true)

    q4 = fconvert(Quarterly, tsbd)
    @test q4.values ≈ [1.152, 1.486, 1.235, 1.580] nans=true atol=1e-3

    q5 = fconvert(Quarterly, tsbd, nans=false)
    @test q5.values ≈ [1.152, 1.486, NaN, NaN] nans=true atol=1e-3

    TimeSeriesEcon.clear_holidays_map()
    TimeSeriesEcon.set_option(:business_skip_holidays, false)
    TimeSeriesEcon.set_option(:business_skip_nans, true)
    
    q6 = fconvert(Quarterly, tsbd)
    @test q6.values ≈[1.152, 1.487, 1.235, 1.577] nans=true atol=1e-3
    q7 = fconvert(Quarterly, tsbd, nans=true)
    @test q7.values ≈ [1.152, 1.487, 1.235, 1.577] nans=true atol=1e-3
    q8 = fconvert(Quarterly, tsbd, nans=false)
    @test q8.values ≈ [NaN, NaN, NaN, NaN] nans=true atol=1e-3

    TimeSeriesEcon.clear_holidays_map()
    TimeSeriesEcon.set_option(:business_skip_holidays, false)
    TimeSeriesEcon.set_option(:business_skip_nans, false)

end

"""
FAME functions affected by holiday optional 

DIFF
MMEDIAN
MVAR
EMA
MMIN
PCT
MAVE
MPROD
SHIFT
MAVEC
MSTDDEV
SHIFTMTH
MCORR
MSUM
SHIFTYR
"""