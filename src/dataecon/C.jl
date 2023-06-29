module C

using DataEcon_jll
export DataEcon_jll

using CEnum

function de_error(msg, len)
    ccall((:de_error, libdaec), Cint, (Ptr{Cchar}, Csize_t), msg, len)
end

function de_error_source(msg, len)
    ccall((:de_error_source, libdaec), Cint, (Ptr{Cchar}, Csize_t), msg, len)
end

function de_clear_error()
    ccall((:de_clear_error, libdaec), Cint, ())
end

@cenum var"##Ctag#328"::Int32 begin
    DE_SUCCESS = 0
    DE_ERR_ALLOC = -1000
    DE_BAD_AXIS_TYPE = -999
    DE_BAD_CLASS = -998
    DE_BAD_TYPE = -997
    DE_BAD_NAME = -996
    DE_SHORT_BUF = -995
    DE_OBJ_DNE = -994
    DE_AXIS_DNE = -993
    DE_ARG = -992
    DE_NO_OBJ = -991
    DE_EXISTS = -990
    DE_BAD_OBJ = -989
    DE_NULL = -988
    DE_DEL_ROOT = -987
    DE_MIS_ATTR = -986
    DE_INTERNAL = -985
end

const de_file = Ptr{Cvoid}

function de_open(fname, de)
    ccall((:de_open, libdaec), Cint, (Ptr{Cchar}, Ptr{de_file}), fname, de)
end

function de_close(de)
    ccall((:de_close, libdaec), Cint, (de_file,), de)
end

@cenum class_t::Int32 begin
    class_catalog = 0
    class_scalar = 1
    class_vector = 2
    class_tseries = 2
    class_matrix = 3
    class_mvtseries = 3
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
    type_any = -1
end

@cenum frequency_t::UInt32 begin
    freq_none = 0
    freq_unit = 1
    freq_daily = 4
    freq_bdaily = 5
    freq_monthly = 8
    freq_weekly = 16
    freq_weekly_sun = 16
    freq_weekly_mon = 17
    freq_weekly_tue = 18
    freq_weekly_wed = 19
    freq_weekly_thu = 20
    freq_weekly_fri = 21
    freq_weekly_sat = 22
    freq_quarterly = 32
    freq_quarterly_jan = 33
    freq_quarterly_feb = 34
    freq_quarterly_mar = 35
    freq_quarterly_apr = 33
    freq_quarterly_may = 34
    freq_quarterly_jun = 35
    freq_quarterly_jul = 33
    freq_quarterly_aug = 34
    freq_quarterly_sep = 35
    freq_quarterly_oct = 33
    freq_quarterly_nov = 34
    freq_quarterly_dec = 35
    freq_halfyearly = 64
    freq_halfyearly_jan = 65
    freq_halfyearly_feb = 66
    freq_halfyearly_mar = 67
    freq_halfyearly_apr = 68
    freq_halfyearly_may = 69
    freq_halfyearly_jun = 70
    freq_halfyearly_jul = 65
    freq_halfyearly_aug = 66
    freq_halfyearly_sep = 67
    freq_halfyearly_oct = 68
    freq_halfyearly_nov = 69
    freq_halfyearly_dec = 70
    freq_yearly = 128
    freq_yearly_jan = 129
    freq_yearly_feb = 130
    freq_yearly_mar = 131
    freq_yearly_apr = 132
    freq_yearly_may = 133
    freq_yearly_jun = 134
    freq_yearly_jul = 135
    freq_yearly_aug = 136
    freq_yearly_sep = 137
    freq_yearly_oct = 138
    freq_yearly_nov = 139
    freq_yearly_dec = 140
end

const obj_id_t = Int64

struct object_t
    id::obj_id_t
    pid::obj_id_t
    class::class_t
    type::type_t
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

function de_new_catalog(de, pid, name, id)
    ccall((:de_new_catalog, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, Ptr{obj_id_t}), de, pid, name, id)
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
    type::axis_type_t
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
    axis::axis_t
    nbytes::Int64
    value::Ptr{Cvoid}
end

const vector_t = tseries_t

function de_store_tseries(de, pid, name, type, eltype, axis_id, nbytes, value, id)
    ccall((:de_store_tseries, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, type_t, axis_id_t, Int64, Ptr{Cvoid}, Ptr{obj_id_t}), de, pid, name, type, eltype, axis_id, nbytes, value, id)
end

function de_load_tseries(de, id, tseries)
    ccall((:de_load_tseries, libdaec), Cint, (de_file, obj_id_t, Ptr{tseries_t}), de, id, tseries)
end

struct mvtseries_t
    object::object_t
    eltype::type_t
    axis1::axis_t
    axis2::axis_t
    nbytes::Int64
    value::Ptr{Cvoid}
end

const matrix_t = mvtseries_t

function de_store_mvtseries(de, pid, name, type, eltype, axis1_id, axis2_id, nbytes, value, id)
    ccall((:de_store_mvtseries, libdaec), Cint, (de_file, obj_id_t, Ptr{Cchar}, type_t, type_t, axis_id_t, axis_id_t, Int64, Ptr{Cvoid}, Ptr{obj_id_t}), de, pid, name, type, eltype, axis1_id, axis2_id, nbytes, value, id)
end

function de_load_mvtseries(de, id, mvtseries)
    ccall((:de_load_mvtseries, libdaec), Cint, (de_file, obj_id_t, Ptr{mvtseries_t}), de, id, mvtseries)
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

end # module
