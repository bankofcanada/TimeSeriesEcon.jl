# Copyright (c) 2020-2025, Bank of Canada
# All rights reserved.

# Tables.jl integration, so that TSeries and MVTSeries can be consumed by
# DataFrames, CSV, the VSCode table viewer, and anything else that speaks
# Tables.jl. See https://tables.juliadata.org/
#
# Only the column interface is implemented. Tables.jl derives row access from
# column access, so there is no second representation to keep in step.

"""
    TimeSeriesEcon.DATE_COLUMN_NAME

Name given to the column holding the [`MIT`](@ref) of each observation when a
[`TSeries`](@ref) or [`MVTSeries`](@ref) is read as a Tables.jl table.
"""
const DATE_COLUMN_NAME = :date

#############################################################################
# TSeries

Tables.istable(::Type{<:TSeries}) = true
Tables.columnaccess(::Type{<:TSeries}) = true

"""
    Tables.columns(t::TSeries)

Read `t` as a two column table: `date` holds the [`MIT`](@ref) of each
observation and `value` holds the observation itself.

Both columns are views onto `t`, so this does not copy the data. Materialize it
if you need the table to outlive mutations of `t`, for example with
`DataFrame(t)`.
"""
Tables.columns(t::TSeries) = NamedTuple{(DATE_COLUMN_NAME, :value)}((rangeof(t), _vals(t)))

#############################################################################
# MVTSeries

Tables.istable(::Type{<:MVTSeries}) = true
Tables.columnaccess(::Type{<:MVTSeries}) = true

"""
    Tables.columns(x::MVTSeries)

Read `x` as a table with one `date` column holding the [`MIT`](@ref) of each
observation followed by one column per variable, in the order they appear in
`x`.

Throws an `ArgumentError` if `x` already has a variable named `date`, since the
two would collide.

The columns are views onto `x`, so this does not copy the data. Materialize it
if you need the table to outlive mutations of `x`, for example with
`DataFrame(x)`.
"""
function Tables.columns(x::MVTSeries)
    names = colnames(x)
    if DATE_COLUMN_NAME in names
        throw(ArgumentError(
            "MVTSeries has a variable named `$(DATE_COLUMN_NAME)`, which collides with the " *
            "date column used by the Tables.jl interface. Rename the variable to read it as a table."
        ))
    end
    columns = (rangeof(x), (_vals(x[nm]) for nm in names)...)
    return NamedTuple{(DATE_COLUMN_NAME, names...)}(columns)
end
