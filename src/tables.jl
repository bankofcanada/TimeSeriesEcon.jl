
using Tables


Tables.rowaccess(::Type{<:TSeries}) = true

struct TSeriesTable{F<:Frequency,V,T<:TSeries{F,V}} <: Tables.AbstractColumns
    x::T
end

Tables.istable(::Type{<:TSeries}) = true
Tables.istable(::Type{<:TSeriesTable}) = true
Tables.schema(tt::TSeriesTable{F,V}) where {F<:Frequency,V} = Tables.Schema(Tables.columnnames(tt), [MIT{F}, V])

Tables.columnaccess(::Type{TSeries}) = true
Tables.columnaccess(::Type{TSeriesTable}) = true
Tables.columns(tt::TSeries) = TSeriesTable(tt)
Tables.columns(tt::TSeriesTable) = tt
Tables.columnnames(tt::TSeriesTable) = [:date, :value]
Tables.getcolumn(tt::TSeriesTable, ::Type, col::Int, nm::Symbol) = col == 1 ? rangeof(tt.x) : col == 2 ? tt.values : throw(BoundsError(tt, col))
Tables.getcolumn(tt::TSeriesTable, col::Int) = col == 1 ? rangeof(getfield(tt, :x)) : col == 2 ? getfield(tt, :x).values : throw(BoundsError(tt, (col,)))
Tables.getcolumn(tt::TSeriesTable, col::Symbol) = col == :date ? rangeof(getfield(tt, :x)) : col == :value ? getfield(tt, :x).values : throw(BoundsError(tt, (col,)))

Tables.rowaccess(::Type{TSeries}) = true
Tables.rowaccess(::Type{TSeriesTable}) = true
struct TSeriesRow{F<:Frequency,V}
    date::MIT{F}
    value::V
    function TSeriesRow(i::Int,tt::TSeriesTable{F,V}) where {F<:Frequency, V}
        x = getfield(tt,:x)
        new{F,V}(x.firstdate + i - 1, x.values[i])
    end
end
Tables.rows(t::TSeries) = TSeriesTable(t)
Tables.rows(tt::TSeriesTable) = tt
Tables.eltype(::TSeriesTable{F,V}) where {F<:Frequency,V} = TSeriesRow{F,V}
Tables.length(tt::TSeriesTable) = length(getfield(tt,:x))
Base.iterate(tt::TSeriesTable, st=1) = st > length(tt) ? nothing : (TSeriesRow(st,tt), st+1)
Tables.getcolumn(r::TSeriesRow, ::Type, col::Int, nm::Symbol) = col == 1 ? r.date : col == 2 ? r.value : throw(BoundsError(r, (col,)))
Tables.getcolumn(r::TSeriesRow, col::Int) = col == 1 ? r.date : col == 2 ? r.value : throw(BoundsError(r, (col,)))
Tables.getcolumn(r::TSeriesRow, col::Symbol) = getproperty(r,col)
Tables.columnnames(r::TSeriesRow) = [:date, :value]
