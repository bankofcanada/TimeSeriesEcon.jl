module X13

using TimeSeriesEcon
using MacroTools
using OrderedCollections
using X13as_jll

struct WorkspaceTable <: AbstractWorkspace
    _c::OrderedDict{Symbol,Any}
    # punt construction to container
    WorkspaceTable(args...; kwargs...) = new(OrderedDict{Symbol,Any}(args...; kwargs...))
    # Allow construction like this: Workspace(; var1=val1, var2=val2, ...)
    WorkspaceTable(; kw...) = new(OrderedDict{Symbol,Any}(kw))
end
MacroTools.@forward WorkspaceTable._c (Base.setindex!,)
MacroTools.@forward WorkspaceTable._c (Base.isempty, Base.keys, Base.haskey, Base.values, Base.length)
MacroTools.@forward WorkspaceTable._c (Base.iterate, Base.get, Base.get!,)
export WorkspaceTable

struct X13ResultWorkspace <: AbstractWorkspace
    _c::OrderedDict{Symbol,Any}
    # punt construction to container
    X13ResultWorkspace(args...; kwargs...) = new(OrderedDict{Symbol,Any}(args...; kwargs...))
    # Allow construction like this: Workspace(; var1=val1, var2=val2, ...)
    X13ResultWorkspace(; kw...) = new(OrderedDict{Symbol,Any}(kw))
end
MacroTools.@forward X13ResultWorkspace._c (Base.setindex!,)
MacroTools.@forward X13ResultWorkspace._c (Base.isempty, Base.keys, Base.haskey, Base.values, Base.length)
MacroTools.@forward X13ResultWorkspace._c (Base.iterate, Base.get, Base.get!,)
export WorkspaceTable, X13ResultWorkspace

include("x13consts.jl")
include("x13spec.jl")
include("x13print.jl")
include("x13result.jl")

"""
`deseasonalize!(ts::TSeries; kwargs...)`

Run a default x11 spec on the time series and replace the values in the series with the values from the resulting d11 "final seasonally adjusted series".

The default seasonal adjustment decomposition is multiplicative (`mode=:mult`). The default seasonal filter will be chosen automatically by X13 unless one is
specified with the `seasonalma` keyword argument. Similarly a default trend moving average will be chosen by X13 unless one is specified with the `trendma` keyword argument.

See the documentation for the x11 spec for details on available keyword arguments.
"""
function deseasonalize!(ts::TSeries; kwargs...)
    spec = X13.newspec(ts; x11=X13.x11(; save=:d11, kwargs...))
    res = X13.run(spec, verbose=false)
    ts.values = res.series.d11.values
    ts
end
deseasonalize(ts::TSeries; kwargs...) = deseasonalize!(copy(ts), kwargs...)
export deseasonalize, deseasonalize!

"""
`cleanup()`

By default, the folders created by the x13 runs are automatically removed when the process exits. However, if the julia process was forcefully closed some folders may
remain. This function will remove all folders in the system's temporary directory (the default directory for `mktempdir`) who (1) have names starting with "x13_", 
and (2) are owned by the current user.
"""
function cleanup()
    folder = mktempdir(; prefix="x13_", cleanup=true)
    parent = joinpath(splitpath(folder)[1:end-1])
    all_folders_and_files = readdir(parent, join=false)
    num_removed_folders = 0
    for f in all_folders_and_files
        if findfirst("x13_", f) == 1:4 && isdir(joinpath(parent, f))
            stats = stat(joinpath(parent,f))
            if stats.uid == Libc.getuid()
                path = joinpath(parent,f)
                rm(path; recursive=true)
                num_removed_folders += 1
            end
        end
    end
    println("Removed $(num_removed_folders) temporary x13 folders.")
end

end # module end