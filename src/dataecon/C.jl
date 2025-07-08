module C

using DataEcon_jll
export DataEcon_jll

using CEnum

function de_version()
    ccall((:de_version, libdaec), Ptr{Cchar}, ())
end

function de_error(msg, len)
    ccall((:de_error, libdaec), Cint, (Ptr{Cchar}, Csize_t), msg, len)
end

function de_error_source(msg, len)
    ccall((:de_error_source, libdaec), Cint, (Ptr{Cchar}, Csize_t), msg, len)
end

function de_clear_error()
    ccall((:de_clear_error, libdaec), Cint, ())
end

@cenum var"##Ctag#241"::Int32 begin
    DE_SUCCESS = 0
    DE_ERR_ALLOC = -1000
    DE_BAD_AXIS_TYPE = -999
    DE_BAD_NUM_AXES = -998
    DE_BAD_CLASS = -997
    DE_BAD_TYPE = -996
    DE_BAD_ELTYPE = -995
    DE_BAD_ELTYPE_NONE = -994
    DE_BAD_ELTYPE_DATE = -993
    DE_BAD_NAME = -992
    DE_BAD_FREQ = -991
    DE_SHORT_BUF = -990
    DE_OBJ_DNE = -989
    DE_AXIS_DNE = -988
    DE_ARG = -987
    DE_NO_OBJ = -986
    DE_EXISTS = -985
    DE_BAD_OBJ = -984
    DE_NULL = -983
    DE_DEL_ROOT = -982
    DE_MIS_ATTR = -981
    DE_INEXACT = -980
    DE_RANGE = -979
    DE_INTERNAL = -978
end

const de_file = Ptr{Cvoid}

function de_open(fname, de)
    ccall((:de_open, libdaec), Cint, (Ptr{Cchar}, Ptr{de_file}), fname, de)
end

function de_open_readonly(fname, de)
    ccall((:de_open_readonly, libdaec), Cint, (Ptr{Cchar}, Ptr{de_file}), fname, de)
end

function de_open_memory(pde)
    ccall((:de_open_memory, libdaec), Cint, (Ptr{de_file},), pde)
end

function de_close(de)
    ccall((:de_close, libdaec), Cint, (de_file,), de)
end

function de_truncate(de)
    ccall((:de_truncate, libdaec), Cint, (de_file,), de)
end

@cenum class_t::Int32 begin
    class_catalog = 0
    class_scalar = 1
    class_vector = 2
    class_tseries = 2
    class_matrix = 3
    class_mvtseries = 3
    class_tensor = 4
    class_ndtseries = 4
    class_any = -1
end

@cenum type_t::Int32 begin
    type_none = 0
    type_integer = 1
    type_signed = 1
    type_unsigned = 2
    type_date = 3
    type_float = 4
    type_complex = 5
    type_string = 6
    type_other_scalar = 7
    type_vector = 10
    type_range = 11
    type_tseries = 12
    type_other_1d = 13
    type_matrix = 20
    type_mvtseries = 21
    type_other_2d = 22
    type_tensor = 30
    type_ndtseries = 31
    type_other_nd = 32
    type_any = -1
end

const obj_id_t = Int64

struct object_t
    id::obj_id_t
    pid::obj_id_t
    obj_class::class_t
    obj_type::type_t
    name::Ptr{Cchar}
end

function de_find_object(de, pid, name, id)
    ccall((:de_find_object, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, Ptr{obj_id_t}), de, pid, name, id)
end

function de_load_object(de, id, object)
    ccall((:de_load_object, libdaec), Cint, (de_file, obj_id_t, Ptr{object_t}), de, id, object)
end

function de_delete_object(de, id)
    ccall((:de_delete_object, libdaec), Cint, (de_file, obj_id_t), de, id)
end

function de_set_attribute(de, id, name, value)
    ccall((:de_set_attribute, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, Ptr{Cchar}), de, id, name, value)
end

function de_get_attribute(de, id, name, value)
    ccall((:de_get_attribute, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, Ptr{Ptr{Cchar}}), de, id, name, value)
end

function de_get_all_attributes(de, id, delim, nattr, names, values)
    ccall((:de_get_all_attributes, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, Ptr{Int64}, Ptr{Ptr{Cchar}}, Ptr{Ptr{Cchar}}), de, id, delim, nattr, names, values)
end

function de_get_object_info(de, id, fullpath, depth, created)
    ccall((:de_get_object_info, libdaec), Cint, (de_file, obj_id_t, Ptr{Ptr{Cchar}}, Ptr{Int64}, Ptr{Int64}), de, id, fullpath, depth, created)
end

function de_find_fullpath(de, fullpath, id)
    ccall((:de_find_fullpath, libdaec), Cint, (de_file, Ptr{Cchar}, Ptr{obj_id_t}), de, fullpath, id)
end

function de_catalog_size(de, pid, count)
    ccall((:de_catalog_size, libdaec), Cint, (de_file, obj_id_t, Ptr{Int64}), de, pid, count)
end

function de_new_catalog(de, pid, name, id)
    ccall((:de_new_catalog, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, Ptr{obj_id_t}), de, pid, name, id)
end

@cenum frequency_t::UInt32 begin
    freq_none = 0
    freq_unit = 11
    freq_daily = 12
    freq_bdaily = 13
    freq_weekly = 16
    freq_weekly_sun0 = 16
    freq_weekly_mon = 17
    freq_weekly_tue = 18
    freq_weekly_wed = 19
    freq_weekly_thu = 20
    freq_weekly_fri = 21
    freq_weekly_sat = 22
    freq_weekly_sun7 = 23
    freq_weekly_sun = 23
    freq_monthly = 32
    freq_quarterly = 64
    freq_quarterly_jan = 65
    freq_quarterly_feb = 66
    freq_quarterly_mar = 67
    freq_quarterly_apr = 65
    freq_quarterly_may = 66
    freq_quarterly_jun = 67
    freq_quarterly_jul = 65
    freq_quarterly_aug = 66
    freq_quarterly_sep = 67
    freq_quarterly_oct = 65
    freq_quarterly_nov = 66
    freq_quarterly_dec = 67
    freq_halfyearly = 128
    freq_halfyearly_jan = 129
    freq_halfyearly_feb = 130
    freq_halfyearly_mar = 131
    freq_halfyearly_apr = 132
    freq_halfyearly_may = 133
    freq_halfyearly_jun = 134
    freq_halfyearly_jul = 129
    freq_halfyearly_aug = 130
    freq_halfyearly_sep = 131
    freq_halfyearly_oct = 132
    freq_halfyearly_nov = 133
    freq_halfyearly_dec = 134
    freq_yearly = 256
    freq_yearly_jan = 257
    freq_yearly_feb = 258
    freq_yearly_mar = 259
    freq_yearly_apr = 260
    freq_yearly_may = 261
    freq_yearly_jun = 262
    freq_yearly_jul = 263
    freq_yearly_aug = 264
    freq_yearly_sep = 265
    freq_yearly_oct = 266
    freq_yearly_nov = 267
    freq_yearly_dec = 268
end

const date_t = Int64

function de_pack_year_period_date(freq, year, period, date)
    ccall((:de_pack_year_period_date, libdaec), Cint, (frequency_t, Int32, UInt32, Ptr{date_t}), freq, year, period, date)
end

function de_unpack_year_period_date(freq, date, year, period)
    ccall((:de_unpack_year_period_date, libdaec), Cint, (frequency_t, date_t, Ptr{Int32}, Ptr{UInt32}), freq, date, year, period)
end

function de_pack_calendar_date(freq, year, month, day, date)
    ccall((:de_pack_calendar_date, libdaec), Cint, (frequency_t, Int32, UInt32, UInt32, Ptr{date_t}), freq, year, month, day, date)
end

function de_unpack_calendar_date(freq, date, year, month, day)
    ccall((:de_unpack_calendar_date, libdaec), Cint, (frequency_t, date_t, Ptr{Int32}, Ptr{UInt32}, Ptr{UInt32}), freq, date, year, month, day)
end

struct scalar_t
    object::object_t
    frequency::frequency_t
    nbytes::Int64
    value::Ptr{Cvoid}
end

function de_store_scalar(de, pid, name, type, freq, nbytes, value, id)
    ccall((:de_store_scalar, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, frequency_t, Int64, Ptr{Cvoid}, Ptr{obj_id_t}), de, pid, name, type, freq, nbytes, value, id)
end

function de_load_scalar(de, id, scalar)
    ccall((:de_load_scalar, libdaec), Cint, (de_file, obj_id_t, Ptr{scalar_t}), de, id, scalar)
end

const axis_id_t = Int64

@cenum axis_type_t::UInt32 begin
    axis_plain = 0
    axis_range = 1
    axis_names = 2
end

struct axis_t
    id::axis_id_t
    ax_type::axis_type_t
    length::Int64
    frequency::frequency_t
    first::Int64
    names::Ptr{Cchar}
end

function de_axis_plain(de, length, id)
    ccall((:de_axis_plain, libdaec), Cint, (de_file, Int64, Ptr{axis_id_t}), de, length, id)
end

function de_axis_range(de, length, frequency, first, id)
    ccall((:de_axis_range, libdaec), Cint, (de_file, Int64, frequency_t, Int64, Ptr{axis_id_t}), de, length, frequency, first, id)
end

function de_axis_names(de, length, names, id)
    ccall((:de_axis_names, libdaec), Cint, (de_file, Int64, Ptr{Cchar}, Ptr{axis_id_t}), de, length, names, id)
end

function de_load_axis(de, id, axis)
    ccall((:de_load_axis, libdaec), Cint, (de_file, axis_id_t, Ptr{axis_t}), de, id, axis)
end

struct tseries_t
    object::object_t
    eltype::type_t
    elfreq::frequency_t
    axis::axis_t
    nbytes::Int64
    value::Ptr{Cvoid}
end

const vector_t = tseries_t

function de_store_tseries(de, pid, name, obj_type, eltype, elfreq, axis_id, nbytes, value, id)
    ccall((:de_store_tseries, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, type_t, frequency_t, axis_id_t, Int64, Ptr{Cvoid}, Ptr{obj_id_t}), de, pid, name, obj_type, eltype, elfreq, axis_id, nbytes, value, id)
end

function de_load_tseries(de, id, tseries)
    ccall((:de_load_tseries, libdaec), Cint, (de_file, obj_id_t, Ptr{tseries_t}), de, id, tseries)
end

struct mvtseries_t
    object::object_t
    eltype::type_t
    elfreq::frequency_t
    axis1::axis_t
    axis2::axis_t
    nbytes::Int64
    value::Ptr{Cvoid}
end

const matrix_t = mvtseries_t

function de_store_mvtseries(de, pid, name, obj_type, eltype, elfreq, axis1_id, axis2_id, nbytes, value, id)
    ccall((:de_store_mvtseries, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, type_t, frequency_t, axis_id_t, axis_id_t, Int64, Ptr{Cvoid}, Ptr{obj_id_t}), de, pid, name, obj_type, eltype, elfreq, axis1_id, axis2_id, nbytes, value, id)
end

function de_load_mvtseries(de, id, mvtseries)
    ccall((:de_load_mvtseries, libdaec), Cint, (de_file, obj_id_t, Ptr{mvtseries_t}), de, id, mvtseries)
end

struct ndtseries_t
    object::object_t
    eltype::type_t
    elfreq::frequency_t
    naxes::Int64
    axis::NTuple{5, axis_t}
    nbytes::Int64
    value::Ptr{Cvoid}
end

const tensor_t = ndtseries_t

function de_store_ndtseries(de, pid, name, obj_type, eltype, elfreq, naxes, axis_ids, nbytes, value, id)
    ccall((:de_store_ndtseries, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, type_t, frequency_t, Int64, Ptr{axis_id_t}, Int64, Ptr{Cvoid}, Ptr{obj_id_t}), de, pid, name, obj_type, eltype, elfreq, naxes, axis_ids, nbytes, value, id)
end

function de_load_ndtseries(de, id, ndtseries)
    ccall((:de_load_ndtseries, libdaec), Cint, (de_file, obj_id_t, Ptr{ndtseries_t}), de, id, ndtseries)
end

function de_pack_strings(strvec, length, buffer, bufsize)
    ccall((:de_pack_strings, libdaec), Cint, (Ptr{Ptr{Cchar}}, Int64, Ptr{Cchar}, Ptr{Int64}), strvec, length, buffer, bufsize)
end

function de_unpack_strings(buffer, bufsize, strvec, length)
    ccall((:de_unpack_strings, libdaec), Cint, (Ptr{Cchar}, Int64, Ptr{Ptr{Cchar}}, Int64), buffer, bufsize, strvec, length)
end

const de_search = Ptr{Cvoid}

function de_list_catalog(de, pid, search)
    ccall((:de_list_catalog, libdaec), Cint, (de_file, obj_id_t, Ptr{de_search}), de, pid, search)
end

function de_search_catalog(de, pid, wc, type, cls, search)
    ccall((:de_search_catalog, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, class_t, Ptr{de_search}), de, pid, wc, type, cls, search)
end

function de_next_object(search, object)
    ccall((:de_next_object, libdaec), Cint, (de_search, Ptr{object_t}), search, object)
end

function de_finalize_search(search)
    ccall((:de_finalize_search, libdaec), Cint, (de_search,), search)
end

const DE_VERSION = "0.3.2"

const DE_VERNUM = 0x0320

const DE_VER_MAJOR = 0

const DE_VER_MINOR = 3

const DE_VER_REVISION = 2

const DE_VER_SUBREVISION = 0

const DE_MAX_AXES = 5

end # module
