
using Clang.Generators
using DataEcon_jll

headers = DataEcon_jll.daec_header_path

args = get_default_args()
options = Dict{String,Any}("general" => Dict{String,Any}(
    "library_name" => "libdaec",
    "module_name" => "C",
    "jll_pkg_name" => "DataEcon_jll",
    "output_file_path" => "./C.jl"
))
ctx = create_context(headers, args, options)
build!(ctx)
