# Quickstart

`TimeSeriesEcon.jl` provides two Julia types:
 - `MIT` aka `moment-in-time` is a discrete date
    - initialized using `mm, qq, yy, ii` constructors.
 - `TSeries` is 1-dimensional array indexed using `MIT`s

## MIT aka "Moment-In-Time"

Let's start by creating a quarterly `MIT`. Every `MIT` is equipped with `Frequency` information.
 
```julia-repl
julia> using TimeSeriesEcon

julia> qq(2020, 3)
2020Q3

julia> typeof(qq(2020, 3))
MIT{Quarterly}

julia> frequencyof(qq(2020, 3))
Quarterly
```

It's possible to access year and period information of an `MIT`. 

```julia-repl
julia> year(qq(2020, 3))
2020

julia> period(qq(2020, 3))
3
```

You can also retrieve the number of periods for an `MIT`. Plus, the function `ppy` returns an integer indicating the number of periods based on the associted `Frequency`.

```julia-repl
julia> ppy(qq(2020, 3))
4

julia> ppy(mm(2020, 1))
12

julia> ppy(yy(2020))
1
```

Finally, you can add/subtract periods.

```julia-repl
julia> mm(2018, 1) + 24
2020M1

julia> qq(2018, 1) + 8
2020Q1

julia> yy(2018) + 2
2020Y
```

## TSeries

`TSeries` behave like regular vectors, but you can access/assign values using `MIT`s.  

```julia-repl
julia> TSeries(qq(2020, 3), ones(5))
5-element Quarterly TSeries from 2020Q3:
  2020Q3 : 1.0
  2020Q4 : 1.0
  2021Q1 : 1.0
  2021Q2 : 1.0
  2021Q3 : 1.0
```

*Access* values using a single `MIT` or range of `MIT`s.

```
julia> myseries = TSeries(qq(2020, 3), ones(5));

julia> myseries[qq(2020, 3)]
1.0

julia> myseries[qq(2020, 3)]
1.0

julia> myseries[qq(2020, 3):qq(2021, 2)]
4-element Quarterly TSeries from 2020Q3:
  2020Q3 : 1.0
  2020Q4 : 1.0
  2021Q1 : 1.0
  2021Q2 : 1.0
```

*Assign* values using a single `MIT` or range of `MIT`s.

```julia-repl
julia> myseries = TSeries(qq(2020, 3), ones(5));

julia> myseries[qq(2020, 3)] = 10;

julia> myseries
5-element Quarterly TSeries from 2020Q3:
  2020Q3 : 10.0
  2020Q4 : 1.0
  2021Q1 : 1.0
  2021Q2 : 1.0
  2021Q3 : 1.0
```

```julia-repl
julia> myseries[qq(2020, 4):qq(2021, 3)] = 100;

julia> myseries
5-element Quarterly TSeries from 2020Q3:
  2020Q3 : 10.0
  2020Q4 : 100.0
  2021Q1 : 100.0
  2021Q2 : 100.0
  2021Q3 : 100.0
```

Finally, you can assign values at arbitrary points.

```julia-repl
julia> myseries = TSeries(qq(2020, 3), ones(5));

julia> myseries[qq(2020, 1)] = 1;

julia> myseries
7-element Quarterly TSeries from 2020Q1:
  2020Q1 : 1.0
  2020Q2 : NaN
  2020Q3 : 1.0
  2020Q4 : 1.0
  2021Q1 : 1.0
  2021Q2 : 1.0
  2021Q3 : 1.0

julia> myseries[qq(2022, 1):qq(2022, 2)] = 1;

julia> myseries
10-element Quarterly TSeries from 2020Q1:
  2020Q1 : 1.0
  2020Q2 : NaN
  2020Q3 : 1.0
  2020Q4 : 1.0
  2021Q1 : 1.0
  2021Q2 : 1.0
  2021Q3 : 1.0
  2021Q4 : NaN
  2022Q1 : 1.0
  2022Q2 : 1.0
```