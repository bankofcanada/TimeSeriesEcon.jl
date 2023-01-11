using Statistics

"""
FAME Reproduction scripts
whats v39055
DATE 2021
HOLIDAY ON
repo v39055, shift(v39055, 1), diff(v39055), shift(v39055, -1), pct(v39055)
"""

@testset "BDaily" begin
    # v39055, Bond, benchmark bonds, Canada, issued by the Government of Canada, 10-year original maturity, average yield

    bonds_data = [NaN, 0.68, 0.7, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86, 0.81, 0.8, 0.8, 0.83, 0.87, 0.84, 0.81, 0.82, 0.8, 0.82, 0.84, 0.88, 0.91, 0.94, 0.96, 1, 1.01, 0.99, 0.99, 0.99, 1.03, NaN, 1.12, 1.11, 1.14, 1.21, 1.23, 1.26, 1.31, 1.46, 1.35, 1.35, 1.33, 1.4, 1.49, 1.5, 1.53, 1.45, 1.41, 1.43, 1.58, 1.54, 1.56, 1.58, 1.61, 1.59, 1.55, 1.49, 1.47, 1.46, 1.49, 1.53, 1.53, 1.55, 1.51, NaN, 1.56, 1.49, 1.5, 1.46, 1.5, 1.51, 1.5, 1.53, 1.45, 1.53, 1.53, 1.5, 1.52, 1.52, 1.51, 1.53, 1.56, 1.53, 1.56, 1.54, 1.52, 1.53, 1.51, 1.51, 1.49, 1.51, 1.54, 1.59, 1.56, 1.55, 1.57, 1.56, 1.58, 1.54, 1.54, NaN, 1.46, 1.45, 1.49, 1.49, 1.49, 1.5, 1.49, 1.52, 1.46, 1.47, 1.45, 1.41, 1.38, 1.38, 1.39, 1.38, 1.44, 1.4, 1.37, 1.41, 1.4, 1.42, 1.41, 1.45, 1.41, 1.42, 1.39, NaN, 1.37, 1.4, 1.32, 1.29, 1.26, 1.32, 1.32, 1.34, 1.29, 1.26, 1.24, 1.14, 1.17, 1.22, 1.19, 1.21, 1.22, 1.16, 1.17, 1.19, 1.2, NaN, 1.12, 1.13, 1.16, 1.24, 1.25, 1.27, 1.26, 1.25, 1.19, 1.16, 1.15, 1.16, 1.13, 1.14, 1.16, 1.18, 1.25, 1.23, 1.2, 1.18, 1.22, 1.18, 1.15, 1.19, NaN, 1.23, 1.2, 1.17, 1.23, 1.22, 1.17, 1.22, 1.23, 1.29, 1.22, 1.22, 1.21, 1.33, 1.38, 1.41, 1.5, 1.51, NaN, 1.47, 1.49, 1.53, 1.5, 1.56, 1.62, NaN, 1.62, 1.61, 1.53, 1.58, 1.58, 1.63, 1.63, 1.68, 1.65, 1.65, 1.63, 1.6, 1.66, 1.72, 1.74, 1.72, 1.71, 1.64, 1.59, 1.63, 1.59, 1.68, NaN, 1.67, 1.72, 1.77, 1.7, 1.69, 1.66, 1.76, 1.81, 1.77, 1.77, 1.59, 1.61, 1.58, 1.5, 1.49, 1.45, 1.51, 1.58, 1.56, 1.5, 1.47, 1.4, 1.43, 1.41, 1.35, 1.32, 1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42,]
    tsbd = TSeries(TimeSeriesEcon.bdaily("2021-01-01"), bonds_data)
    @test length(tsbd) == 261

    # TimeSeriesEcon.setoption(:bdaily_skip_nans, true)
    # TimeSeriesEcon.setoption(:bdaily_skip_holidays, false)
    TimeSeriesEcon.clear_holidays_map()

    @test values(tsbd[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test tsbd[end-9:end].values ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-01"):TimeSeriesEcon.bdaily("2021-01-14")

    tsbd_shifted = shift(tsbd, 1, skip_all_nans=true)
    @test values(tsbd_shifted[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.47, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_shifted[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-17"):TimeSeriesEcon.bdaily("2021-12-30")
    @test rangeof(tsbd_shifted[begin:begin+9]) == TimeSeriesEcon.bdaily("2020-12-31"):TimeSeriesEcon.bdaily("2021-01-13")
    @test values(tsbd_shifted[begin:begin+9]) ≈ [0.68, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true

    tsbd_diffed = diff(tsbd, skip_all_nans=true)
    @test values(tsbd_diffed[end-9:end]) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, NaN, 0.01, -0.02, -0.03] nans = true
    @test rangeof(tsbd_diffed[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_diffed[begin:begin+9]) ≈ [NaN, 0.02, 0.05, 0.04, 0.02, 0.02, 0.01, -0.03, 0.05, -0.05] nans = true
    @test rangeof(tsbd_diffed[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_lagged = lag(tsbd, skip_all_nans=true)
    @test rangeof(tsbd_lagged[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-21"):TimeSeriesEcon.bdaily("2022-01-03")
    @test values(tsbd_lagged[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.46, 1.46, 1.47, 1.45, 1.42] nans = true
    @test values(tsbd_lagged[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true

    tsbd_pct = pct(tsbd, skip_all_nans=true)
    @test values(tsbd_pct[end-9:end]) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, NaN, NaN, 0.68, -1.36, -2.07] nans = true atol = 0.01
    @test rangeof(tsbd_pct[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")
    @test rangeof(tsbd_pct[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_pct[begin:begin+9]) ≈ [NaN, 2.94, 7.14, 5.33, 2.53, 2.47, 1.20, -3.57, 6.17, -5.81] nans = true atol = 0.01
    @test rangeof(tsbd_pct[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    # Holidays OFF
    TimeSeriesEcon.setoption(:bdaily_skip_nans, false)
    tsbd_shifted2 = shift(tsbd, 1)
    @test values(tsbd_shifted2[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_shifted2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-17"):TimeSeriesEcon.bdaily("2021-12-30")
    @test values(tsbd_shifted2[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd_shifted2[begin:begin+9]) == TimeSeriesEcon.bdaily("2020-12-31"):TimeSeriesEcon.bdaily("2021-01-13")

    tsbd_diffed2 = diff(tsbd)
    @test values(tsbd_diffed2[end-9:end]) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, NaN, NaN, -0.02, -0.03] nans = true
    @test rangeof(tsbd_diffed2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_diffed2[begin:begin+9]) ≈ [NaN, 0.02, 0.05, 0.04, 0.02, 0.02, 0.01, -0.03, 0.05, -0.05] nans = true
    @test rangeof(tsbd_diffed2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_lagged2 = lag(tsbd)
    @test values(tsbd_lagged2[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_lagged2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-21"):TimeSeriesEcon.bdaily("2022-01-03")
    @test values(tsbd_lagged2[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd_lagged2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_pct2 = pct(tsbd)
    @test values(tsbd_pct2[end-9:end]) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, NaN, NaN, NaN, -1.36, -2.07] nans = true atol = 0.01
    @test rangeof(tsbd_pct2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_pct2[begin:begin+9]) ≈ [NaN, 2.94, 7.14, 5.33, 2.53, 2.47, 1.20, -3.57, 6.17, -5.81] nans = true atol = 0.01
    @test rangeof(tsbd_pct2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    # reset the option
    TimeSeriesEcon.setoption(:bdaily_skip_nans, false)

    ## Testing holidays map
    covered_range = bdaily("1970-01-01"):bdaily("2049-12-31")
    test_ts = TSeries(first(covered_range), ones(Bool, length(covered_range)))
    test_ts[bdaily("2021-12-27"):bdaily("2021-12-28")] .= false
    TimeSeriesEcon.setoption(:bdaily_holidays_map, test_ts)
    TimeSeriesEcon.setoption(:bdaily_skip_holidays, true)
    # tsmall = TSeries(TimeSeriesEcon.bdaily("2021-12-20"), [1,2,3,4,5,NaN,NaN,8,9,10])
    tsmall = TSeries(TimeSeriesEcon.bdaily("2021-12-20"), [1, 2, 3, 4, 5, NaN, NaN, 8, NaN, 10])
    tsmall_shifted = shift(tsmall, 1, holidays_map=test_ts)
    tsmall_diffed = diff(tsmall, holidays_map=test_ts)
    tsmall_lagged = lag(tsmall, holidays_map=test_ts)
    tsmall_pct = pct(tsmall, holidays_map=test_ts)
    # MVTSeries(orig = tsmall, lagged = shift(tsmall, -1), diffed = diff(tsmall), pct = pct(tsmall))

    # TimeSeriesEcon.set_holidays_map("ON", test_ts);

    # Shifts and lags when business_skip_holidays = true, but business_skip_nans = false
    # NaNs on holidays will be replaced with the appropriate non-holiday, non-nan value
    # NaNs on non-holidays will not be replaced and will be shifted appropriately 
    @test tsmall[end-9:end].values ≈ [1, 2, 3, 4, 5, NaN, NaN, 8, NaN, 10] nans = true
    @test tsmall_shifted[end-9:end].values ≈ [1, 2, 3, 4, 5, 8, 8, 8, NaN, 10] nans = true
    @test tsmall_lagged[end-9:end].values ≈ [1, 2, 3, 4, 5, 5, 5, 8, NaN, 10] nans = true
    @test tsmall_diffed[end-8:end].values ≈ [1, 1, 1, 1, NaN, NaN, 3, NaN, NaN] nans = true
    @test tsmall_pct[end-8:end].values ≈ [100, 50, 100 / 3, 25, NaN, NaN, 60, NaN, NaN] nans = true atol = 0.01

    # When the NaN is up against holidays it shifts to the other side. 
    # The Holiday values will also be replaced with a NaN when this is the latest available non-holiday value
    tsmall2 = TSeries(TimeSeriesEcon.bdaily("2021-12-20"), [1, 2, 3, 4, 5, NaN, NaN, NaN, 9, 10])
    tsmall2_shifted = shift(tsmall2, 1, holidays_map=test_ts)
    tsmall2_diffed = diff(tsmall2, holidays_map=test_ts)
    tsmall2_lagged = lag(tsmall2, holidays_map=test_ts)
    tsmall2_pct = pct(tsmall2, holidays_map=test_ts)
    @test tsmall2[end-9:end].values ≈ [1, 2, 3, 4, 5, NaN, NaN, NaN, 9, 10] nans = true
    @test tsmall2_shifted[end-9:end].values ≈ [1, 2, 3, 4, 5, NaN, NaN, NaN, 9, 10] nans = true
    @test tsmall2_lagged[end-9:end].values ≈ [1, 2, 3, 4, 5, 5, 5, NaN, 9, 10] nans = true
    @test tsmall2_diffed[end-8:end].values ≈ [1, 1, 1, 1, NaN, NaN, NaN, NaN, 1] nans = true
    @test tsmall2_pct[end-8:end].values ≈ [100, 50, 100 / 3, 25, NaN, NaN, NaN, NaN, 100 / 9] nans = true atol = 0.01

    # The cleanedvalues function returns only a subset of values
    @test cleanedvalues(tsbd[end-9:end], holidays_map=test_ts) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_shifted[end-9:end], holidays_map=test_ts) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_lagged[end-9:end], holidays_map=test_ts) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_diffed[end-9:end], holidays_map=test_ts) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02, -0.03] nans = true
    @test cleanedvalues(tsbd_pct[end-9:end], holidays_map=test_ts) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36, -2.07] nans = true atol = 0.01

    @test cleanedvalues(tsbd_shifted2[end-9:end], holidays_map=test_ts) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_lagged2[end-9:end], holidays_map=test_ts) ≈ [1.38, 1.44, 1.42, 1.44, NaN, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_diffed2[end-9:end], holidays_map=test_ts) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, -0.02, -0.03] nans = true
    @test cleanedvalues(tsbd_pct2[end-9:end], holidays_map=test_ts) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, NaN, -1.36, -2.07] nans = true atol = 0.01

    @test cleanedvalues(tsmall[end-9:end], holidays_map=test_ts) ≈ [1, 2, 3, 4, 5, 8, NaN, 10] nans = true
    @test cleanedvalues(tsmall_shifted[end-9:end], holidays_map=test_ts) ≈ [1, 2, 3, 4, 5, 8, NaN, 10] nans = true
    @test cleanedvalues(tsmall_lagged[end-9:end], holidays_map=test_ts) ≈ [1, 2, 3, 4, 5, 8, NaN, 10] nans = true
    @test cleanedvalues(tsmall_diffed[end-8:end], holidays_map=test_ts) ≈ [1, 1, 1, 1, 3, NaN, NaN] nans = true
    @test cleanedvalues(tsmall_pct[end-8:end], holidays_map=test_ts) ≈ [100, 50, 100 / 3, 25, 60, NaN, NaN] nans = true atol = 0.01

    @test cleanedvalues(tsmall2[end-9:end], holidays_map=test_ts) ≈ [1, 2, 3, 4, 5, NaN, 9, 10] nans = true
    @test cleanedvalues(tsmall2_shifted[end-9:end], holidays_map=test_ts) ≈ [1, 2, 3, 4, 5, NaN, 9, 10] nans = true
    @test cleanedvalues(tsmall2_lagged[end-9:end], holidays_map=test_ts) ≈ [1, 2, 3, 4, 5, NaN, 9, 10] nans = true
    @test cleanedvalues(tsmall2_diffed[end-8:end], holidays_map=test_ts) ≈ [1, 1, 1, 1, NaN, NaN, 1] nans = true
    @test cleanedvalues(tsmall2_pct[end-8:end], holidays_map=test_ts) ≈ [100, 50, 100 / 3, 25, NaN, NaN, 100 / 9] nans = true atol = 0.01

    # The cleanedvalues function returns only a subset of values (skip_holidays uses stored map)
    TimeSeriesEcon.setoption(:bdaily_holidays_map, test_ts)
    @test cleanedvalues(tsbd[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_shifted[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_lagged[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_diffed[end-9:end], skip_holidays=true) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02, -0.03] nans = true
    @test cleanedvalues(tsbd_pct[end-9:end], skip_holidays=true) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36, -2.07] nans = true atol = 0.01

    @test cleanedvalues(tsbd_shifted2[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_lagged2[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, NaN, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_diffed2[end-9:end], skip_holidays=true) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, -0.02, -0.03] nans = true
    @test cleanedvalues(tsbd_pct2[end-9:end], skip_holidays=true) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, NaN, -1.36, -2.07] nans = true atol = 0.01

    @test cleanedvalues(tsmall[end-9:end], skip_holidays=true) ≈ [1, 2, 3, 4, 5, 8, NaN, 10] nans = true
    @test cleanedvalues(tsmall_shifted[end-9:end], skip_holidays=true) ≈ [1, 2, 3, 4, 5, 8, NaN, 10] nans = true
    @test cleanedvalues(tsmall_lagged[end-9:end], skip_holidays=true) ≈ [1, 2, 3, 4, 5, 8, NaN, 10] nans = true
    @test cleanedvalues(tsmall_diffed[end-8:end], skip_holidays=true) ≈ [1, 1, 1, 1, 3, NaN, NaN] nans = true
    @test cleanedvalues(tsmall_pct[end-8:end], skip_holidays=true) ≈ [100, 50, 100 / 3, 25, 60, NaN, NaN] nans = true atol = 0.01

    @test cleanedvalues(tsmall2[end-9:end], skip_holidays=true) ≈ [1, 2, 3, 4, 5, NaN, 9, 10] nans = true
    @test cleanedvalues(tsmall2_shifted[end-9:end], skip_holidays=true) ≈ [1, 2, 3, 4, 5, NaN, 9, 10] nans = true
    @test cleanedvalues(tsmall2_lagged[end-9:end], skip_holidays=true) ≈ [1, 2, 3, 4, 5, NaN, 9, 10] nans = true
    @test cleanedvalues(tsmall2_diffed[end-8:end], skip_holidays=true) ≈ [1, 1, 1, 1, NaN, NaN, 1] nans = true
    @test cleanedvalues(tsmall2_pct[end-8:end], skip_holidays=true) ≈ [100, 50, 100 / 3, 25, NaN, NaN, 100 / 9] nans = true atol = 0.01


    TimeSeriesEcon.clear_holidays_map()
    # TimeSeriesEcon.setoption(:bdaily_skip_nans, false)
    # TimeSeriesEcon.setoption(:bdaily_skip_holidays, false)

    ## Testing ON holidays map
    TimeSeriesEcon.set_holidays_map("CA", "ON")
    # TimeSeriesEcon.setoption(:bdaily_skip_nans, false)
    # TimeSeriesEcon.setoption(:bdaily_skip_holidays, true)
    @test cleanedvalues(tsbd[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    # @test cleanedvalues(tsbd_shifted[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    # @test cleanedvalues(tsbd_lagged[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45] nans = true
    # @test cleanedvalues(tsbd_diffed[end-9:end], skip_holidays=true) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02, -0.03] nans = true
    # @test cleanedvalues(tsbd_pct[end-9:end], skip_holidays=true) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36, -2.07] nans = true atol = 0.01

    tsbd_shifted3 = shift(tsbd, 1, skip_holidays=true)
    tsbd_diffed3 = diff(tsbd, skip_holidays=true)
    tsbd_lagged3 = lag(tsbd, skip_holidays=true)
    tsbd_pct3 = pct(tsbd, skip_holidays=true)
    @test cleanedvalues(tsbd[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_shifted3[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_lagged3[end-9:end], skip_holidays=true) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45] nans = true
    @test cleanedvalues(tsbd_diffed3[end-9:end], skip_holidays=true) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, 0.01, -0.02, -0.03] nans = true
    @test cleanedvalues(tsbd_pct3[end-9:end], skip_holidays=true) ≈ [4.55, 4.35, -1.39, 1.41, 1.39, 0.68, -1.36, -2.07] nans = true atol = 0.01

    # passing holidays map directly produces the same results
    ontario_map = copy(TimeSeriesEcon.getoption(:bdaily_holidays_map))
    TimeSeriesEcon.clear_holidays_map()
    # TimeSeriesEcon.setoption(:bdaily_skip_holidays, false)
    # TimeSeriesEcon.setoption(:bdaily_skip_nans, false)

    tsbd_shifted4 = shift(tsbd, 1, holidays_map=ontario_map)
    tsbd_diffed4 = diff(tsbd, holidays_map=ontario_map)
    tsbd_lagged4 = lag(tsbd, holidays_map=ontario_map)
    tsbd_pct4 = pct(tsbd, holidays_map=ontario_map)
    @test cleanedvalues(tsbd[end-9:end], holidays_map=ontario_map) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.45, 1.42] nans = true
    @test cleanedvalues(tsbd_shifted4[end-9:end]) ≈  values(tsbd_shifted3[end-9:end])  nans = true
    @test cleanedvalues(tsbd_lagged4[end-9:end]) ≈  values(tsbd_lagged3[end-9:end])  nans = true
    @test cleanedvalues(tsbd_diffed4[end-9:end]) ≈  values(tsbd_diffed3[end-9:end])  nans = true
    @test cleanedvalues(tsbd_pct4[end-9:end]) ≈  values(tsbd_pct3[end-9:end])  nans = true

    # reset
    TimeSeriesEcon.clear_holidays_map()
    # TimeSeriesEcon.setoption(:bdaily_skip_holidays, false)
    # TimeSeriesEcon.setoption(:bdaily_skip_nans, false)
end

@testset "BDaily statistics" begin
    bonds_data = [NaN, 0.68, 0.7, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86, 0.81, 0.8, 0.8, 0.83, 0.87, 0.84, 0.81, 0.82, 0.8, 0.82, 0.84, 0.88, 0.91, 0.94, 0.96, 1, 1.01, 0.99, 0.99, 0.99, 1.03, NaN, 1.12, 1.11, 1.14, 1.21, 1.23, 1.26, 1.31, 1.46, 1.35, 1.35, 1.33, 1.4, 1.49, 1.5, 1.53, 1.45, 1.41, 1.43, 1.58, 1.54, 1.56, 1.58, 1.61, 1.59, 1.55, 1.49, 1.47, 1.46, 1.49, 1.53, 1.53, 1.55, 1.51, NaN, 1.56, 1.49, 1.5, 1.46, 1.5, 1.51, 1.5, 1.53, 1.45, 1.53, 1.53, 1.5, 1.52, 1.52, 1.51, 1.53, 1.56, 1.53, 1.56, 1.54, 1.52, 1.53, 1.51, 1.51, 1.49, 1.51, 1.54, 1.59, 1.56, 1.55, 1.57, 1.56, 1.58, 1.54, 1.54, NaN, 1.46, 1.45, 1.49, 1.49, 1.49, 1.5, 1.49, 1.52, 1.46, 1.47, 1.45, 1.41, 1.38, 1.38, 1.39, 1.38, 1.44, 1.4, 1.37, 1.41, 1.4, 1.42, 1.41, 1.45, 1.41, 1.42, 1.39, NaN, 1.37, 1.4, 1.32, 1.29, 1.26, 1.32, 1.32, 1.34, 1.29, 1.26, 1.24, 1.14, 1.17, 1.22, 1.19, 1.21, 1.22, 1.16, 1.17, 1.19, 1.2, NaN, 1.12, 1.13, 1.16, 1.24, 1.25, 1.27, 1.26, 1.25, 1.19, 1.16, 1.15, 1.16, 1.13, 1.14, 1.16, 1.18, 1.25, 1.23, 1.2, 1.18, 1.22, 1.18, 1.15, 1.19, NaN, 1.23, 1.2, 1.17, 1.23, 1.22, 1.17, 1.22, 1.23, 1.29, 1.22, 1.22, 1.21, 1.33, 1.38, 1.41, 1.5, 1.51, NaN, 1.47, 1.49, 1.53, 1.5, 1.56, 1.62, NaN, 1.62, 1.61, 1.53, 1.58, 1.58, 1.63, 1.63, 1.68, 1.65, 1.65, 1.63, 1.6, 1.66, 1.72, 1.74, 1.72, 1.71, 1.64, 1.59, 1.63, 1.59, 1.68, NaN, 1.67, 1.72, 1.77, 1.7, 1.69, 1.66, 1.76, 1.81, 1.77, 1.77, 1.59, 1.61, 1.58, 1.5, 1.49, 1.45, 1.51, 1.58, 1.56, 1.5, 1.47, 1.4, 1.43, 1.41, 1.35, 1.32, 1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42,];
    tsbd = TSeries(TimeSeriesEcon.bdaily("2021-01-01"), bonds_data)
    @test length(tsbd) == 261
    noisy_tsbd = copy(tsbd)
    noisy_tsbd .+= rand(length(tsbd))

    @test isnan(mean(tsbd)) == true
    @test mean(tsbd, skip_all_nans=true) ≈ 1.363253012048193
    
    TimeSeriesEcon.set_holidays_map("CA", "ON")
    @test isnan(mean(tsbd, skip_holidays=true)) == true
    @test isnan(mean(tsbd[bd"2021-06-01:2021-07-15"])) == true
    @test mean(tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) ≈ 1.39124999999999
    @test mean(tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) ≈ 1.39124999999999

    @test isnan(std(tsbd, skip_holidays=true)) == true
    @test isnan(std(tsbd[bd"2021-06-01:2021-07-15"])) == true
    @test std(tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) ≈ 0.066174256762464
    @test std(tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) ≈ 0.066174256762464
    
    @test isnan(stdm(tsbd, 1.3912499999999999, skip_holidays=true)) == true
    @test isnan(stdm(tsbd[bd"2021-06-01:2021-07-15"], 1.3912499999999999)) == true
    @test stdm(tsbd[bd"2021-06-01:2021-07-15"], 1.3912499999999999, skip_holidays=true) ≈ 0.066174256762464
    @test stdm(tsbd[bd"2021-06-01:2021-07-15"], 1.3912499999999999, skip_all_nans=true) ≈ 0.066174256762464
    @test stdm(tsbd[bd"2021-06-01:2021-07-15"], 2.3912499999999999, skip_holidays=true) ≈ 1.01815376872758
    @test stdm(tsbd[bd"2021-06-01:2021-07-15"], 2.3912499999999999, skip_all_nans=true) ≈ 1.01815376872758
    
    
    @test isnan(var(tsbd, skip_holidays=true)) == true
    @test isnan(var(tsbd[bd"2021-06-01:2021-07-15"])) == true
    @test var(tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) == 0.004379032258064514
    @test var(tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) == 0.004379032258064514

    @test isnan(varm(tsbd, 1.3912499999999999, skip_holidays=true)) == true
    @test isnan(varm(tsbd[bd"2021-06-01:2021-07-15"], 1.3912499999999999)) == true
    @test varm(tsbd[bd"2021-06-01:2021-07-15"], 1.3912499999999999, skip_holidays=true) ≈ 0.0043790322580645
    @test varm(tsbd[bd"2021-06-01:2021-07-15"], 1.3912499999999999, skip_all_nans=true) ≈ 0.0043790322580645
    @test varm(tsbd[bd"2021-06-01:2021-07-15"], 2.3912499999999999, skip_holidays=true) ≈ 1.03663709677419
    @test varm(tsbd[bd"2021-06-01:2021-07-15"], 2.3912499999999999, skip_all_nans=true) ≈ 1.03663709677419
    
    @test isnan(median(tsbd, skip_holidays=true)) == true
    @test isnan(median(tsbd[bd"2021-06-01:2021-07-15"])) == true
    @test median(tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) == 1.4
    @test median(tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) == 1.4

    @test_throws ArgumentError quantile(tsbd, [.25, .5, .75], skip_holidays=true)
    @test_throws ArgumentError quantile(tsbd[bd"2021-06-01:2021-07-15"], [.25, .5, .75])
    @test quantile(tsbd[bd"2021-06-01:2021-07-15"], [.25, .5, .75], skip_holidays=true) ≈ [1.3625, 1.4, 1.42499999999999]
    @test quantile(tsbd[bd"2021-06-01:2021-07-15"], [.25, .5, .75], skip_all_nans=true) ≈ [1.3625, 1.4, 1.42499999999999]
    @test quantile(tsbd[bd"2021-06-01:2021-07-15"], .98, skip_holidays=true) ≈ 1.5076
    @test quantile(tsbd[bd"2021-06-01:2021-07-15"], .98, skip_all_nans=true) ≈ 1.5076


    @test isnan(cov(tsbd[bd"2021-06-01:2021-07-15"])) == true
    @test cov(tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) ≈ 0.00437903225806
    @test cov(tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) ≈ 0.00437903225806
    @test isnan(cov(tsbd[bd"2021-06-01:2021-07-15"], noisy_tsbd[bd"2021-06-01:2021-07-15"])) == true
    @test cov(tsbd[bd"2021-06-01:2021-07-15"], noisy_tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) < 1.0
    @test cov(tsbd[bd"2021-06-01:2021-07-15"], noisy_tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) < 1.0


    @test cor(tsbd, skip_holidays=true) == 1.0
    @test cor(tsbd[bd"2021-06-01:2021-07-15"]) == 1.0
    @test cor(tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) == 1.0
    @test cor(tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) == 1.0
    @test isnan(cor(tsbd[bd"2021-06-01:2021-07-15"], shift(tsbd, -1)[bd"2021-06-01:2021-07-15"])) == true
    @test cor(tsbd[bd"2021-06-01:2021-07-15"], noisy_tsbd[bd"2021-06-01:2021-07-15"], skip_holidays=true) < 1.0
    @test cor(tsbd[bd"2021-06-01:2021-07-15"], noisy_tsbd[bd"2021-06-01:2021-07-15"], skip_all_nans=true) < 1.0

    # MVTS functions
    mvtsbd = MVTSeries(; clean=tsbd, noisy=noisy_tsbd)
    mvtscorr = cor(tsbd, noisy_tsbd, skip_all_nans = true) 
    mvtscov1 = var(tsbd, skip_all_nans = true) 
    mvtscov2 = var(noisy_tsbd, skip_all_nans = true) 
    mvtscov3 = cov(tsbd, noisy_tsbd, skip_all_nans = true) 

    @test isapprox(cor(mvtsbd), [ 1.0 NaN ; NaN 1.0], nans = true)
    @test isapprox(cor(mvtsbd, skip_all_nans=true), [ 1.0 mvtscorr ; mvtscorr 1.0], nans = true)
    @test isapprox(cov(mvtsbd), [ NaN NaN ; NaN NaN], nans = true)
    @test isapprox(cov(mvtsbd, skip_all_nans=true), [ mvtscov1 mvtscov3 ; mvtscov3 mvtscov2], nans = true)

    @test isapprox(mean(mvtsbd, dims=1), [NaN NaN], nans=true)    
    @test isapprox(mean(mvtsbd, dims=1, skip_all_nans=true), [1.3632530120481 mean(noisy_tsbd, skip_all_nans=true)], nans=true)    
    res_mean_long = [
        mean([tsbd[bd"2021-06-29"], noisy_tsbd[bd"2021-06-29"]]),
        mean([tsbd[bd"2021-06-30"], noisy_tsbd[bd"2021-06-30"]]),
        mean([tsbd[bd"2021-07-02"], noisy_tsbd[bd"2021-07-02"]]),
    ]
    @test isapprox(mean(mvtsbd[bd"2021-06-29:2021-07-03"], dims=2, skip_all_nans=true), res_mean_long, nans=true)    
    @test isapprox(mean(√, mvtsbd, dims=1, skip_all_nans=true), [1.1623302063259 mean(√, noisy_tsbd, skip_all_nans=true)], nans=true)    
    res_mean_long2 = [
        mean(√, [tsbd[bd"2021-06-29"], noisy_tsbd[bd"2021-06-29"]]),
        mean(√, [tsbd[bd"2021-06-30"], noisy_tsbd[bd"2021-06-30"]]),
        mean(√, [tsbd[bd"2021-07-02"], noisy_tsbd[bd"2021-07-02"]]),
    ]
    @test isapprox(mean(√, mvtsbd[bd"2021-06-29:2021-07-03"], dims=2, skip_all_nans=true), res_mean_long2, nans=true)    
    

    @test isapprox(std(mvtsbd, dims=1, skip_all_nans=true), [0.24532947776869 std(noisy_tsbd, skip_all_nans=true)], nans=true) 
    res_std_long = [
        std([tsbd[bd"2021-06-29"], noisy_tsbd[bd"2021-06-29"]]),
        std([tsbd[bd"2021-06-30"], noisy_tsbd[bd"2021-06-30"]]),
        std([tsbd[bd"2021-07-02"], noisy_tsbd[bd"2021-07-02"]]),
    ]
    @test isapprox(std(mvtsbd[bd"2021-06-29:2021-07-03"], dims=2, skip_all_nans=true), res_std_long, nans=true)    
    
    @test isapprox(var(mvtsbd, dims=1, skip_all_nans=true), [0.0601865526622619 var(noisy_tsbd, skip_all_nans=true)], nans=true)    
    res_var_long = [
        var([tsbd[bd"2021-06-29"], noisy_tsbd[bd"2021-06-29"]]),
        var([tsbd[bd"2021-06-30"], noisy_tsbd[bd"2021-06-30"]]),
        var([tsbd[bd"2021-07-02"], noisy_tsbd[bd"2021-07-02"]]),
    ]
    @test isapprox(var(mvtsbd[bd"2021-06-29:2021-07-03"], dims=2, skip_all_nans=true), res_var_long, nans=true)    

    @test isapprox(median(mvtsbd, dims=1, skip_all_nans=true), [1.43 median(noisy_tsbd, skip_all_nans=true)], nans=true)    
    res_median_long = [
        median([tsbd[bd"2021-06-29"], noisy_tsbd[bd"2021-06-29"]]),
        median([tsbd[bd"2021-06-30"], noisy_tsbd[bd"2021-06-30"]]),
        median([tsbd[bd"2021-07-02"], noisy_tsbd[bd"2021-07-02"]]),
    ]
    @test isapprox(median(mvtsbd[bd"2021-06-29:2021-07-03"], dims=2, skip_all_nans=true), res_median_long, nans=true)    

    TimeSeriesEcon.clear_holidays_map()
end
