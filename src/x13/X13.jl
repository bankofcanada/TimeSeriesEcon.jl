module X13

using TimeSeriesEcon
using MacroTools
using OrderedCollections

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

include("x13consts.jl")
include("x13spec.jl")
include("x13print.jl")
include("x13result.jl")

end # module end