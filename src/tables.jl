
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
    function TSeriesRow(i::Int, tt::TSeriesTable{F,V}) where {F<:Frequency,V}
        x = getfield(tt, :x)
        new{F,V}(x.firstdate + i - 1, x.values[i])
    end
end
Tables.rowaccess(t::TSeries) = true
Tables.rowaccess(tt::TSeriesTable) = true
Tables.rows(t::TSeries) = TSeriesTable(t)
Tables.rows(tt::TSeriesTable) = tt
Tables.eltype(::TSeriesTable{F,V}) where {F<:Frequency,V} = TSeriesRow{F,V}
Tables.length(tt::TSeriesTable) = length(getfield(tt, :x))
Base.iterate(tt::TSeriesTable, st=1) = st > length(tt) ? nothing : (TSeriesRow(st, tt), st + 1)
Tables.getcolumn(r::TSeriesRow, ::Type, col::Int, nm::Symbol) = col == 1 ? r.date : col == 2 ? r.value : throw(BoundsError(r, (col,)))
Tables.getcolumn(r::TSeriesRow, col::Int) = col == 1 ? r.date : col == 2 ? r.value : throw(BoundsError(r, (col,)))
Tables.getcolumn(r::TSeriesRow, col::Symbol) = getproperty(r, col)
Tables.columnnames(r::TSeriesRow) = [:date, :value]


## TSeries as a Tables.jl sink

function _tbl_fd(::Type{F}, dt::Dates.Date)::MIT{<:F} where {F<:Frequency}
    return MIT{F}(dt)
end

_tbl_fd(::Type{F}, dt::MIT) where {F<:Frequency} = mixed_freq_error(F, typeof(dt))
function _tbl_fd(::Type{F}, dt::MIT{Q})::MIT{Q} where {N,F<:YPFrequency{N},Q<:YPFrequency{N}}
    if isconcretetype(F) && F != frequencyof(dt)
        mixed_freq_error(F, frequencyof(dt))
    end
    return dt
end
function _tbl_fd(::Type{F}, dt::MIT{F})::MIT{F} where {F<:Frequency}
    dt
end

function _tbl_fd(::Type{F}, dt::AbstractString)::MIT{F} where {F<:YPFrequency}
    return eval(Meta.parse(dt))
end

function _tbl_fd(::Type{F}, dt::AbstractString)::MIT{F} where {F<:Frequency}
    return MIT{F}(Dates.Date(dt))
end

function TSeries{F}(tt::Tables.AbstractColumns) where {F<:Frequency}
    # if tt isa TSeriesTable
    #     return getfield(tt, 1)
    # end
    if Tables.rowaccess(tt)
        rows = Tables.rows(tt)
        iter = iterate(rows)
        isnothing(iter) && return TSeries(1U)
        (r, st) = iter
        vals = Vector{typeof(r.value)}(undef, length(tt))
        ret = TSeries(_tbl_fd(F, r.date), vals)
        vals[1] = r.value
        for i = 2:length(tt)
            (r, st) = iterate(rows, st)
            vals[i] = r.value
        end
        return ret
    elseif Tables.columnaccess(tt)
        dates, values = Tables.columns(tt)
        return TSeries(_tbl_fd(F, dates[1]), copy(values))
    else
        throw(ArgumentError("Neither row- nor column- access defined for $(typeof(tt))"))
    end
end
