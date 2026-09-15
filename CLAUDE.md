# CLAUDE.md

Guidance for Claude Code and other AI assistants working in this repository.

## What this is

`TimeSeriesEcon.jl` is the time series foundation of the Bank of Canada's Julia stack. It
defines a small set of types that everything else builds on:

- `MIT{F}` — a *moment in time* at frequency `F`, e.g. `2020Q1`, `2021M3`, `d"2020-01-01"`.
- `Duration{F}` — the difference between two `MIT`s of the same frequency.
- `TSeries{F,T,C}` — a vector of observations that knows its start date and frequency.
- `MVTSeries{F,T,C}` — a matrix whose rows are dates and whose named columns are variables.
- `Workspace` — a dictionary-like container for mixed data.

The whole design rests on making illegal operations fail loudly rather than silently produce
a wrong date, so read the frequency rules before touching arithmetic.

## `MIT` is a `Signed` that refuses integer arithmetic

```julia
primitive type MIT{F<:Frequency} <: Signed 64 end
```

`MIT` subtypes `Signed`, but `momentintime.jl` deliberately defines

```julia
Base.promote_rule(IT::Type{<:Integer}, MT::Type{<:MIT}) =
    throw(ArgumentError("Invalid arithmetic operation with $IT and $MT"))
```

so `2020Q1 < 0` throws rather than returning a nonsense answer. Mixing frequencies throws
too, via `mixed_freq_error`. This is intentional and load-bearing — don't "fix" it to make a
downstream package happy.

It does have a consequence worth knowing when you expose `MIT` to generic code: anything that
sees `<: Signed` and assumes arithmetic works will hit that error. `CSV.write` is the one you
will meet first — it calls `x < 0` on every cell, so a table with an `MIT` column cannot be
written directly. Convert the column first (`Date.(col)` or `string.(col)`).

## Layout

| Path | Contents |
| :--- | :--- |
| `src/momentintime.jl` | `MIT`, `Duration`, the frequency types, and all the date arithmetic. The foundation; read it first. |
| `src/tseries.jl`, `src/mvtseries.jl` | The two series types. `_vals(x)` reaches the underlying array, `rangeof(x)` the date range as a `UnitRange{MIT}`, `colnames(x)` an `MVTSeries`' variables. |
| `src/fconvert/` | Frequency conversion — the most subtle code here, and where most bugs live. |
| `src/tables.jl` | The Tables.jl interface, so the series can be read by DataFrames, CSV and the VSCode viewer. |
| `src/x13/`, `src/dataecon/` | Wrappers around the X-13ARIMA-SEATS binary and the DataEcon C library. Both need external artifacts. |
| `test/` | One `test_*.jl` per area, all included from `test/runtests.jl`. |

`MVTSeries` columns are `TSeries` whose storage is a *view* into the parent matrix, so writing
through a column writes through to the matrix. Anything that hands out columns inherits that,
which is usually what you want but is worth stating in a docstring.

## Checks

CI (`.github/workflows/main.yml`) runs the test suite on Julia `1.9`, `lts` and `1`, across
Linux, macOS and Windows, and uploads coverage to Codecov. Locally:

```sh
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.test()'
```

To iterate on one area without paying for the whole suite:

```sh
julia --project=. -e 'using Test, TimeSeriesEcon; include("test/test_tseries.jl")'
```

`Project.toml` declares `julia = "1.7"` while CI starts at `1.9`, so avoid syntax newer than
1.7 unless you also raise the floor. `Manifest.toml` is gitignored — don't commit one.

Coverage is reported per pull request, and new files with no tests show up immediately as a
coverage drop. Ship tests in the same change.

## Conventions

- Nearly every file under `src/` and `test/` opens with the two-line Bank of Canada copyright
  header, and new files should. The year range tracks when the file was last worked on — the
  tree currently spans `2020-2021` to `2020-2025` — so use `2020-2025` on anything new.
- Public functions carry docstrings with a signature line; many are referenced from the docs
  site via `[`name`](@ref)`, so keep the cross-references valid.
- Exports live in `src/TimeSeriesEcon.jl` next to the `include` of the file that defines them,
  not in one block at the top.
- Third-party `using`/`import` go in the first group at the top of the module, standard library
  in the second. The comments marking those groups are there on purpose.
- Frequency-generic code dispatches on `F<:Frequency`; write `::Type{<:TSeries}` rather than
  `::Type{TSeries}` in trait definitions, or the method will not match concrete parameterized
  types like `TSeries{Quarterly{3},Float64,Vector{Float64}}`.
