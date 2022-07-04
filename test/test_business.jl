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

    TimeSeriesEcon.set_option(:holidays, true)

    @test values(tsbd[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, NaN, NaN, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd[begin:begin+9]) ≈ [NaN, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-01"):TimeSeriesEcon.bdaily("2021-01-14")

    tsbd_shifted = shift(tsbd,1)
    @test values(tsbd_shifted[end-9:end]) ≈ [1.38, 1.44, 1.42, 1.44, 1.46, 1.47, 1.47, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_shifted[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-17"):TimeSeriesEcon.bdaily("2021-12-30")
    @test values(tsbd_shifted[begin:begin+9]) ≈ [0.68, 0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd_shifted[begin:begin+9]) == TimeSeriesEcon.bdaily("2020-12-31"):TimeSeriesEcon.bdaily("2021-01-13")

    tsbd_diffed = diff(tsbd)
    @test values(tsbd_diffed[end-9:end]) ≈ [0.06, 0.06, -0.02, 0.02, 0.02, NaN, NaN, 0.01, -0.02, -0.03] nans = true
    @test rangeof(tsbd_diffed[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_diffed[begin:begin+9]) ≈ [NaN,0.02, 0.05, 0.04, 0.02, 0.02, 0.01,-0.03, 0.05,-0.05] nans = true
    @test rangeof(tsbd_diffed[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_lagged = lag(tsbd)
    @test values(tsbd_lagged[end-9:end]) ≈[1.38, 1.44, 1.42, 1.44, 1.46, 1.46, 1.46, 1.47, 1.45, 1.42] nans = true
    @test rangeof(tsbd_lagged[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-21"):TimeSeriesEcon.bdaily("2022-01-03")
    @test values(tsbd_lagged[begin:begin+9]) ≈ [NaN,0.68, 0.70, 0.75, 0.79, 0.81, 0.83, 0.84, 0.81, 0.86] nans = true
    @test rangeof(tsbd_lagged[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    tsbd_pct = pct(tsbd)
    @test values(tsbd_pct[end-9:end]) ≈[4.55, 4.35, -1.39, 1.41, 1.39, NaN, NaN, 0.68, -1.36, -2.07] nans = true atol=0.01
    @test rangeof(tsbd_pct[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_pct[begin:begin+9]) ≈ [NaN, 2.94, 7.14, 5.33, 2.53, 2.47, 1.20, -3.57, 6.17, -5.81] nans = true atol=0.01
    @test rangeof(tsbd_pct[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")

    # Holdiays OFF
    TimeSeriesEcon.set_option(:holidays, false)
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
    @test values(tsbd_pct2[end-9:end]) ≈[4.55, 4.35, -1.39, 1.41, 1.39, NaN, NaN, 0.68, -1.36, -2.07] nans = true atol=0.01
    @test rangeof(tsbd_pct2[end-9:end]) == TimeSeriesEcon.bdaily("2021-12-20"):TimeSeriesEcon.bdaily("2021-12-31")
    @test values(tsbd_pct2[begin:begin+9]) ≈ [NaN, 2.94, 7.14, 5.33, 2.53, 2.47, 1.20, -3.57, 6.17, -5.81] nans = true atol=0.01
    @test rangeof(tsbd_pct2[begin:begin+9]) == TimeSeriesEcon.bdaily("2021-01-04"):TimeSeriesEcon.bdaily("2021-01-15")
end

