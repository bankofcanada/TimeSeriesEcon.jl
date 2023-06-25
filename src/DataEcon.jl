# Copyright (c) 2020-2023, Bank of Canada
# All rights reserved.

module DataEcon

using Clang.Generators
using DataEcon_jll
using Scratch
using TOML


DE_version = ""
C_module_path = ""
function _do_init(C_module_path)
    headers = DataEcon_jll.daec_header_path
    args = get_default_args()
    options = Dict{String,Any}("general" => Dict{String,Any}(
        "library_name" => "libdaec",
        "module_name" => "C",
        "jll_pkg_name" => "DataEcon_jll",
        "output_file_path" => C_module_path
    ))
    ctx = create_context(headers, args, options)
    build!(ctx)
end

function __init__()
    global DE_version = TOML.parsefile(joinpath(dirname(pathof(DataEcon_jll)), "..", "Project.toml"))["version"]
    DE_version = split(DE_version, "+")[1]
    scratch_dir = @get_scratch!("clang-" * DE_version)
    global C_module_path = joinpath(scratch_dir, "C.jl")
    if mtime(C_module_path) < mtime(DataEcon_jll.daec_header_path)
        @info "Building C interface to DataEcon_jll version " * DE_version
        _do_init(C_module_path)
    end
    Core.include(@__MODULE__, C_module_path)
end

end
