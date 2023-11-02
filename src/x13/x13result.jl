import Dates


# NEW PLAN: make a type for results with tables, then specify a print type for those... I think

# struct WorkspaceTable <: AbstractWorkspace end



mutable struct X13result
    spec::X13spec
    outfolder::String
    stdout::String
    series::Workspace
    tables::Workspace
    other::Workspace
    errors::Vector{String}
    warnings::Vector{String}
    notes::Vector{String}
    out::Workspace
end

function run(spec::X13spec{F}; verbose=true, errors=false) where F

    x13write(spec)

    gpath = joinpath(spec.folder, "graphics")
    if !ispath(gpath)
        mkdir(gpath)
    end
    # println(gpath)

    c = `x13as -I "$(joinpath(spec.folder,"spec"))" -G "$(gpath)" -S`

    stdin_buffer = IOBuffer()
    stdout_buffer = IOBuffer()
    stderr_buffer = IOBuffer()
    try
        cmdout = Base.run(c, stdin_buffer, stdout_buffer, stderr_buffer)
    catch err
        if err isa ProcessFailedException
        else
            throw(err)
        end
    end
    stdin = String(take!(stdin_buffer))
    stdout = String(take!(stdout_buffer))
    stderr = String(take!(stderr_buffer))

    if length(stderr) > 0
        println(stderr)
        error("running X13 failed. See above. Additional information may be available in $(spec.folder)")
    end
    
    res = X13.X13result(spec, spec.folder, stdout, Workspace(), Workspace(), Workspace(), Vector{String}(), Vector{String}(), Vector{String}(), Workspace())

    main_objects = readdir(spec.folder, join=true)
    files = filter(obj -> !isdir(obj), main_objects)
    sub_folders = filter(obj -> isdir(obj), main_objects)
    for folder in sub_folders
         sub_folder_objects = readdir(folder, join=true)
         files = [files..., filter(obj -> !isdir(obj), sub_folder_objects)...]
    end
    # @show files

    # errors = Vector{String}()
    # warnings = Vector{String}()
    # notes = Vector{String}()

    for file in files
        ext = Symbol(splitext(file)[2][2:end])
        # println(ext)
        if ext in _series_extensions
            res.series[ext] = x13read_series(file, frequencyof(spec.series.data))
        elseif ext in _table_extensions
            lines = split(read(file, String),"\n")
            # println(read(file, String))
            res.tables[ext] = x13read_workspace_table(lines, ext=ext)
        elseif ext == :udg
            #TODO: make this meaningful
            res.other[ext] = x13read_udg(file)
        elseif ext in _kv_list_extensions
            lines = split(read(file, String), "\n")
            res.other[ext] = x13_read_key_values(lines,  r"\s+")
        elseif ext == :est
            res.other[ext] = x13read_estimates(file)
        elseif ext == :mdl
            res.other[ext] = x13read_model(file)
        elseif ext == :err
            x13read_err(file, res.warnings, res.notes, res.errors)
            res.out[ext] = read(file, String)
        elseif ext ∈ (:ipc, :iac)
            res.other[ext] = x13read_identify(file)
        elseif ext == :OUT
            # SEATS output files
            if split(file, "/")[end] == "TABLE-S.OUT"
                lines = split(read(file, String),"\n")
                if length(lines) > 2
                    res.series.s = x13read_seatsseries(lines, frequencyof(spec.series.data))
                end
            end
        elseif ext ∈ _ignored_extensions
            res.out[ext] = read(file, String)
        elseif ext ∉ _ignored_extensions && ext !== :txt && ext !== :log
            println("=================================================================================================================")
            # println(ext)
            # println(read(file, String))
            println(file)
        end
    end



    

    if verbose
        for w in warnings
            @warn w
        end

        for n in notes
            @info n
        end
    end

    if length(res.errors) > 0
        for err in res.errors
            println("ERROR: $err")
        end
        if errors
            @warn "There were errors in the specification file."
        else #if length(res.errors) > 1 || findfirst("span of data end date", res.errors[1]) !== 1:21
            # println(findfirst("span of data end date", res.errors[1]))
            @assert length(res.errors) == 0 "There were errors in the specification file."
        end
    end

    # TODO: .tbs, .sum, .rog are special SEATS outputs

    return res
    
end
_series_extensions = ( :rrs, :rmx, :rsd, :ref, :trn, :fct, 
    :a1, :a2, :a3, :a4, :a10, :a18, :a18, :a19, 
    :b1, :b2, :b3, :b5, :b6, :b7, :b8, :b10, :b11, :b13, :b14, :b16, :b17, :b19, :b20,
    :c1, :c2, :c4, :c5, :c6, :c7, :c10, :c11, :c13, :c14, :c16, :c17, :c18, :c19, :c20,
    :d1, :d2, :d4, :d5, :d6, :d7, :d8, :d9, :d12, :d10, :d11, :d13, :d16, :d18,
    :e1, :e2, :e3, :e5, :e6, :e7, :e8, :e11, :e18, 
    :s10, :s11, :s12, :s13, :s14, :s16, :s18, 
    :tad, :psf, :pir, :pe5, :pe6, :pe7, :pe8, :paf, :f1, :otl, :ftr, :ira, :fvr, :p6a, :p6r, :e6a, :e6r, :saa, :ffc, 
    :rnd, :fts, :btr, :bct, :fch, :fce, :amh, :tre, :sae, :trr, :sar, :tal, :ycs, :sfs, :chs, :tds, :ads, 
    :a2p, :a1c, :a2t, :xrm, :a4d, :xhl, :bxh, :xca, :xcc,
    :yfd, :tse, :tfd, :ssm, :sse, :sfd, :se3, :se2, :dtr, :dsa, :dor, :cse, :ase, :afd, 
    :td, :ao, :ls, :hol, :chl, :tc, :usr,) # these have dates
# _table_extensions = (, ) #TODO: maybe make these tables...
_table_extensions = (:pcf,:acf,:ac2,:itr,:spr,:sp0, :sp1, :sp2, :str, :st0, :st1, :st2, :rts, :acm, :rcm, :d8b, :oit, :rot, :xoi,
    :t1s, :t2s, :s1s, :s2s, :ttc, :tac, :gtf, :gtc, :gaf, :gac, :ftf, :ftc, :faf, :fac, 
    )
_kv_list_extensions = (:lks,)
_ignored_extensions = (
    :spc, # the input spec file
    :gmt, # a list of files in the graphics folder
    :out, # TODO: the output of the print command
    # :OUT, # SEATS has a separate out file...
)

# check what we haven't seen:
all_treated_outputs = [_series_extensions..., _table_extensions..., _kv_list_extensions...]
non_treaded_output_keys = Vector{Symbol}()
for spec in keys(_output_save_tables)
    for sym in _output_save_tables[spec]
        if sym ∉ all_treated_outputs
            push!(non_treaded_output_keys, sym)
        end
    end
end
@showall non_treaded_output_keys
# [:iac, :ipc, :smv, :sas, :sis, :cis, :ais, :yis, :so, :a13, :sec, :ofd, :stc, :wkf, :sta, :cyc, :mdc, :ltt, :pss, :psi, :psc, :psa, :is1, :is2, :it0, :it1, :ser, :ter, :is0, :it2, :b18, :hxc, :bcc, :xrc, :a4p, :a3p, :chr, :iar, :tcr, :sfr, :lkh, :tdh, :sfh, :che, :iae, :tce, :sfe, :mva, :c9, :fsd, :fad, :sac, :act, :mdl, :est]


function x13read_udg(file)
    lines = split(read(file, String),"\n")
    return x13_read_key_values(lines, ": ")
end
function x13_read_key_values(lines::Vector{<:AbstractString}, separator=r"[\t\:]")
    ws = Workspace()
    for line in lines
        if length(strip(line)) == 0
            continue
        end
        # println(line)
        split_point = findfirst(separator, line)[begin]
        if line[split_point] ∉ (':', '\t', ' ')
            println("OBS! ", line[split_point-1], ", ", line)
        end
        key = Symbol(line[1:split_point-1])
        val = strip(line[split_point+1:end])
        foundval = false
        if key == :date
            val = Dates.Date(replace(val, r"\s+"=>" "), Dates.DateFormat("u d, y"))
            foundval = true
        end
        if !foundval
            try 
                val = parse(Int64, val)
                foundval = true
            catch ArgumentError
            end
        end

        if !foundval
            try 
                val = parse(Float64, val)
                foundval = true
            catch ArgumentError
            end
        end

        if !foundval
            # could be a vector of numbers
            splitval = split(replace(val, "*******" => "NaN"), r"[\t\s]+")
            if length(splitval) > 1
                try 
                    val = [parse(Float64, strip(v)) for v in splitval]
                    foundval = true
                catch ArgumentError
                end
            end
        end

        if !foundval && val == "no"
            val = false
            foundval = true
        end

        if !foundval && val == "yes"
            val = true
            foundval = true
        end

        # if !foundval
        #     println(key, ": ", val)
        # end

        ws[key] = val

        # sline = split(line, [" ", "\t"])
    end

    _add_layers!(ws)

    # println(ws)
    return ws
end

#TODO: deal with thins like k.other.udf.roots.ar.nonseaonal.01 which can't be accessed without Symbol("01")

"""Replaces keys with periods in them with workspaces"""
function _add_layers!(ws::Workspace)
    keys_added = Vector{Symbol}()
    for key in collect(keys(ws))
        dotindex = findfirst('.', string(key))
        if dotindex isa Int64
            trunk = Symbol(string(key)[1:dotindex-1])
            leaf = Symbol(string(key)[dotindex+1:end])
            if trunk ∉ keys(ws)
                ws[trunk] = Workspace()
                push!(keys_added, trunk)
            elseif !(ws[trunk] isa Workspace)
                trunk = Symbol("$(string(trunk))_")
                ws[trunk] = Workspace()
                push!(keys_added, trunk)
            end
            # @show trunk
            # @show leaf
            # @show ws[key]
            # @show ws[trunk]
            ws[trunk][leaf] = ws[key]
            delete!(ws, key)
        end
    end
    for key in keys_added
        _add_layers!(ws[key])
    end
end

function _sanitize_colname(s::AbstractString)
    return replace(s, r"[\s\-\.]+" => "_")
end

function x13read_table(file)
    lines = split(read(file, String),"\n")
    headers = _sanitize_colname.(split(strip(lines[1]), "\t"))
    vals = Matrix{Float64}(undef, (length(lines)-3, length(headers)))
    for (i,line) in enumerate(lines[3:end-1])
        # println("line: ", line)
        vals[i,:] = [parse(Float64, v) for v in split(strip(line), "\t")]
    end
    res = MVTSeries(1U, Symbol.(headers), vals)
    return res
end

function x13read_workspace_table(lines::Vector{<:AbstractString}; ext=:nospecialrules)
    if strip(lines[end]) == ""
        lines=lines[1:end-1]
    end
    # println(lines)
    # println(read(file, String))
    ws = WorkspaceTable()
    headers = _sanitize_colname.(split(strip(lines[1]), "\t"))
    if ext == :acm
        # this table is missing a header...
        insert!(headers, 2, "lag")
    end

    vectors = Vector{Any}()
    numvals =  length(lines)-2
    for h in 1:length(headers)
        push!(vectors, Vector{String}(undef, numvals))
    end
    # vectors = repeat([Vector{String}(undef, length(lines)-2)], length(header))
    # vals = Matrix{Float64}(undef, (length(lines)-3, length(headers)))
    # put values in vectors
    for (i,line) in enumerate(lines[3:end])
        if length(strip(line)) == 0
            continue
        end
        for (j,val) in enumerate(split(line, "\t"))
            j > length(headers) && val == "" && continue
            vectors[j][i] = val
        end
        # # println("line: ", line)
        # vals[i,:] = [parse(Float64, v) for v in split(strip(line), "\t")]
    end
    # attempt to parse the vectors
    for (i,v) in enumerate(vectors)
        foundval = false

        if !foundval
            try
                vectors[i] = parse.(Int64, v)
                foundval = true
            catch ArgumentError
            end
        end
        if !foundval
            try
                vectors[i] = parse.(Float64, v)
                foundval = true
            catch ArgumentError
            end
        end
    end

    for (i,head) in enumerate(headers)
        ws[Symbol(head)] = vectors[i]
    end
    return ws
end






function x13read_series(file, F::Type{<:Frequency}, start::MIT)
    lines = split(read(file, String),"\n")
    vals = Vector{Float64}(undef, length(lines)-3)
    for (i, line) in enumerate(lines[3:end-1])
        # println(line)
        vals[i] = parse(Float64, split(line, "\t")[2])
    end
    period_string = split(lines[3], "\t")[1]
    if length(period_string) > 2
        p = parse(Int64, period_string[end-1:end])
        y = parse(Int64, period_string[1:end-2])
        return TSeries(MIT{F}(y,p), vals)
    else
        throw(ArgumentError("Period string has an unexpected format: $(period_string)."))
    end

    println(vals)
end
function _tryparse(t::Type, s::AbstractString, default) 
    v = tryparse(t, s)
    v === nothing && return default
    return v
end
function x13read_series(file, F::Type{<:Frequency})
    # println(read(file, String))
    lines = split(read(file, String),"\n")
    headers = split(lines[1], "\t")[2:end]
    headers = _sanitize_colname.(headers)
    vals = Matrix{Float64}(undef, (length(lines)-3, length(headers)))
    

    # check first line
    _s = split(lines[3], "\t")
    lastcol = length(_s)
    if lastcol > length(headers) + 1 && _s[end] == ""
        lastcol = lastcol - 1
    end
    for (i, line) in enumerate(lines[3:end-1])
        # # println(line)
        # _vals =
        # println(_vals)
        # println((length(lines)-3, length(headers)))
        # # pad with NaNs
        # for val in 1:(size(vals)[2] - length(_vals))
        #     push!(_vals, NaN)
        # end
        # println(line)
        vals[i,:] =  [_tryparse(Float64, v, NaN) for v in split(line, "\t")[2:lastcol]]
        # vals[i, vals[i,:] .== undef] .= NaN
    end
    
    period_string = split(lines[3], "\t")[1]
    # @show lines[3]
    if length(period_string) > 2
        # @show period_string
        if lowercase(period_string[1:3]) in keys(_months_and_quarters)
            p = _months_and_quarters[lowercase(period_string[1:3])]
            y = 1
        else
            p = parse(Int64, period_string[end-1:end])
            y = parse(Int64, period_string[1:end-2])
        end
        # println(vals)
        if length(headers) > 1
            return MVTSeries(MIT{F}(y,p), headers, vals)
        elseif length(headers) == 0
            return TSeries(MIT{F}(y,p):(MIT{F}(y,p)+size(vals)[1] - 1))
        else
            return TSeries(MIT{F}(y,p), vals[:,1])
        end
    else
        throw(ArgumentError("Period string has an unexpected format: $(period_string)."))
    end
end

function x13read_seatsseries(lines::Vector{<:AbstractString}, F::Type{<:Frequency})
    # println(read(file, String))
    delim = r"\s\s+"
    headers_line = 2
    if !occursin(delim, lines[headers_line]) #&& headers_line < length(lines)
        headers_line = headers_line + 1
    end
    headers = split(lines[headers_line], delim)[3:end]
    # println(headers)
    # if headers[1] == ""
    #     headers = headers[2:end]
    # end
    # println(headers)
    headers = _sanitize_colname.(headers)
    vals = Matrix{Float64}(undef, (length(lines)-headers_line-2, length(headers)))

    # check first line
    _s = split(lines[headers_line+1], delim) 
    lastcol = length(_s)
    if lastcol > length(headers) + 1 && _s[end] == ""
        lastcol = lastcol - 1
    end
    for (i, line) in enumerate(lines[headers_line+1:end-2])
        vals[i,:] =  [_tryparse(Float64, v, NaN) for v in split(line, delim)[2:lastcol]]
    end
    # for i in 1:5
    #     println("-"*lines[i]*"-")
    # end
    # println(lines[1:3])
    
    # println(split(lines[headers_line+1], delim))
    date = split(split(lines[headers_line+1], delim)[1], "-")
    if length(date) > 1
        # @show period_string
        p = parse(Int64, strip(date[1]))
        y = parse(Int64, strip(date[2]))
    
        # println(vals)
        if length(headers) > 1
            return MVTSeries(MIT{F}(y,p), headers, vals)
        elseif length(headers) == 0
            return TSeries(MIT{F}(y,p):(MIT{F}(y,p)+size(vals)[1] - 1))
        else
            return TSeries(MIT{F}(y,p), vals[:,1])
        end
    else
        throw(ArgumentError("Period string has an unexpected format: $(period_string)."))
    end
end



export run


function x13read_err(file::AbstractString, warnings::Vector{String}, notes::Vector{String}, errors::Vector{String})
    # println(read(file, String))

    lines = split(read(file, String), r"\n")
    collected_lines = Vector{String}()
    for line in lines[1:end]
        if length(line) >= 11
            if line[1:9] == " WARNING:" || line[1:7] == " ERROR:" || line[1:6] == " NOTE:"
                push!(collected_lines, line)
            elseif length(collected_lines) > 0
                collected_lines[end] = collected_lines[end]*"\n$line"
            end
        elseif length(collected_lines) > 0
            collected_lines[end] = collected_lines[end]*"\n$line"
        end
    end

    for line in collected_lines
        if line[1:9] == " WARNING:"
            push!(warnings, line[11:end])
        elseif line[1:7] == " ERROR:"
            push!(errors, line[9:end])
        elseif line[1:6] == " NOTE:"
            push!(notes, line[8:end])
        end
    end
    # println(lines)
    
    # for i in 2:length(lines)
    #     line = strip(lines[i])
    #     # println(line)
    #     if length(strip(line)) <= 1
    #         continue
    #     end
    #     if line[1:8] == "WARNING:"
    #         push!(warnings, line[9:end])
    #     elseif line[1:5] == "NOTE:"
    #        push!(notes, line[6:end])
    #     elseif line[1:6] == "ERROR:"
    #         push!(errors, line[7:end])
    #     elseif line[1:6] == "*-*-*-"
    #         # log file splitter
    #         #TODO: maybe store this information...
    #         continue
    #     elseif i + 1 <= length(lines) && length(strip(lines[i+1])) !== 1 # looking for an arrow on th enext line
    #         println("OBS! unknown entry in error file: $line")
    #         # println(read(file, String))
    #     end
    #     # i = i + 1
    # end

    # return warnings, notes
end
function find_next_empty_line(v::Vector{<:AbstractString})
    for i in 1:length(v)
        if length(strip(v[i])) == 0
            return i
        end
    end
    return length(v)
end

function x13read_estimates(file)
    lines = split(read(file, String),"\n")
    # println(join(lines, '\n'))
    indices = Workspace()
    for (i,line) in enumerate(lines)
        if line == "\$arima:"
            indices.arima = i
        elseif line == "\$regression:"
                indices.regression = i
        elseif line == "\$arima\$estimates:"
            indices.arimaestimates = i
        elseif line == "\$regression\$estimates:"
            indices.regressionestimates = i
        elseif line == "\$variance:"
            indices.variance = i
        end
    end
    res = Workspace()
    if :arima ∈ keys(indices)
        # res.arima = Workspace()
        res.arima = x13read_workspace_table(lines[indices.arimaestimates+1:indices.variance-1])
        res.variance = x13_read_key_values(lines[indices.variance+1:end])
    elseif :regression ∈ keys(indices)
        # res.regression = Workspace()
        res.regression = x13read_workspace_table(lines[indices.regressionestimates+1:indices.variance-1])
        res.variance = x13_read_key_values(lines[indices.variance+1:end])
    end
    return res
end

function _x13read_model(lines::Vector{<:AbstractString})
    res = Workspace()
    indices = Workspace()
    for (i,l) in enumerate(lines)
        line = strip(l)
        if line == "arima{model=" || line == "model="
            indices.model = i
        elseif line == "ar  =("
            indices.ar = i
        elseif line == "ma  =("
            indices.ma = i
        elseif line == "regression{"
            indices.regression = i
        elseif line == "variables=(" || line == "regression{variables=("
            indices.variables = i
        elseif line == "b=("
            indices.b = i
        end
    end

    ordered_keys = Vector{Symbol}()
    for key in keys(indices)
        if length(ordered_keys) == 0
            push!(ordered_keys, key)
        else
            did_add = false
            for i in 1:length(ordered_keys)
                if indices[key] < indices[ordered_keys[i]]
                    insert!(ordered_keys, key, i)
                    did_add = true
                end
            end
            if !did_add
                push!(ordered_keys, key)
            end
        end
    end

    for (i, key) in enumerate(ordered_keys)
        if key == :model 
            model_string = lines[indices[key]+1]
            split_string = split(model_string, "(")
            arima_specs = Vector{ArimaSpec}()
            for s in split_string
                if length(strip(s)) == 0
                    continue
                end
                _s = split(strip(replace(s, ")" => " ", "," => " ")), " ")
                if !occursin("[", s)
                    push!(arima_specs, ArimaSpec(parse.(Int64, _s)...))
                else
                    specvals = Vector{Union{Int64,Vector{Int64}}}()
                    for __s in _s
                        if __s[1] == '['
                            push!(specvals, parse(Int64, __s[begin+1:end-1]))
                        else
                            push!(specvals, parse(Int64, __s))
                        end
                    end
                    push!(arima_specs, ArimaSpec(specvals...))
                end
            end
            res.model = ArimaModel(arima_specs)
        elseif key ∈ (:ar, :ma, :b, :variables)
            if key !== ordered_keys[end]
                val_lines = lines[indices[key]+1:indices[ordered_keys[i+1]]-2]
            else
                val_lines = lines[indices[key]+1:end-3]
            end
            values = strip.(val_lines)
            values = string.(filter(v -> v ∉ ("", ")", "}"), values))
            if key ∈ (:ar, :ma, :b) # numbers
                fixed = repeat([false], length(values))
                parsed_vals = Vector{Float64}(undef, length(values))
                for (i,v) in enumerate(values)
                    if v[end] == 'f'
                        parsed_vals[i] = parse(Float64, v[1:end-1])
                        fixed[i] = true
                    else
                        parsed_vals[i] = parse(Float64, v)
                    end
                    values = parsed_vals
                end
                res[Symbol("fix$(key)")] = fixed
            end
            res[key] = values
        end
    end
    return res
end

function x13read_identify(file)
    res = Workspace()
    lines = split(read(file, String),"\n")
    
    # first two lines are diff/sdiff
    page_switches = findall(s -> length(s) > 4 && s[1:5] == "\$diff", lines)
    
    for (i, loc) in enumerate(page_switches)
        # loc2 = i < length(page_switches)
        sym = Symbol("$(replace(lines[loc], "\$" => "", "= " => ""))$(replace(lines[loc+1], "\$" => "", "= " => ""))")
        table_lines_end = i < length(page_switches) ? page_switches[i+1] - 1 : length(lines)
        res[sym] = x13read_workspace_table(lines[loc+2:table_lines_end])
    end
    
    return res
end

function x13read_model(file)
    # TODO: make sure we can read all model specs.
    # println(read(file, String))
    lines = split(read(file, String),"\n")
    res = Workspace()
    indices = Workspace()
    
    # find arima and regression
    for (i,l) in enumerate(lines)
        line = strip(l)
        if line == "arima{model=" || line =="arima{"
            indices.arima = i
        elseif line == "regression{"
            indices.regression = i
        end
    end

    if :arima in keys(indices)
        end_line = length(lines)
        if :regression in keys(indices)
            end_line = indices.arima > indices.regression ? length(lines) : indices.regression - 1
        end
        res.arima = _x13read_model(lines[indices.arima:end_line])
    end

    if :regression in keys(indices)
        end_line = length(lines)
        if :arima in keys(indices)
            end_line = indices.regression > indices.arima ? length(lines) : indices.arima - 1
        end
        res.regression = _x13read_model(lines[indices.regression:end_line])
    end

    return res
end

function Base.show(io::IO, ::MIME"text/plain", ws::WorkspaceTable)
    # we are going to print everything...
    colwidths = [length(string(k)) + 1 for k in keys(ws)]
    numrows = maximum(length.(values(ws)))
    types = [typeof(v) for v in values(ws)]

    stringvals = Vector{Vector{String}}()
    for (i,v) in enumerate(values(ws))
        vec = Vector{String}()
        for val in v
            push!(vec, sprint(print, val; context=:compact=>true))
        end
        push!(stringvals, vec)
    end
    for (i,v) in enumerate(stringvals)
        colwidths[i] = max(colwidths[i], maximum(length.(v)))
    end
    
    # now print the thing
    for (i,h) in enumerate(keys(ws))
        print(io, rpad(h,colwidths[i]+1, " "))
    end
    print(io, "\n")
    for c in colwidths
        print(io, "-"^c)
        print(io, " ")
    end
    print(io, "\n")
    for i in 1:numrows
        for (j,vec) in enumerate(stringvals)
            if length(vec) >= i
                if types[j] == Vector{String}
                    print(io, rpad(vec[i], colwidths[j], " "))
                else
                    print(io, lpad(vec[i], colwidths[j], " "))
                end
                print(io, " ")
            else
                print(io, lpad(" ", colwidths[j], " "))
                print(io, " ")
            end
        end
        print(io, "\n")
    end


    
    # summary(io, w)

    # nvars = length(w)
    # nvars == 0 && return

    # limit = get(io, :limit, true)
    # io = IOContext(io, :SHOWN_SET => _c(w),
    #     :typeinfo => eltype(w),
    #     :compact => get(io, :compact, true),
    #     :limit => limit)


    # dheight, dwidth = displaysize(io)

    # if limit && nvars + 5 > dheight
    #     # we're printing some but not all rows (no room on the screen)
    #     top = div(dheight - 5, 2)
    #     bot = nvars - dheight + 7 + top
    # else
    #     top, bot = nvars + 1, nvars + 1
    # end

    # max_align = 0
    # prows = Vector{String}[]
    # for (i, (k, v)) ∈ enumerate(w)
    #     top < i < bot && continue

    #     sk = sprint(print, k, context=io, sizehint=0)
    #     if v isa Union{AbstractString,Symbol,AbstractRange,Dates.Date,Dates.DateTime}
    #         # It's a string or a Symbol
    #         sv = sprint(show, v, context=io, sizehint=0)
    #     elseif typeof(v) == eltype(v) || typeof(v) isa Type{<:DataType}
    #         #  it's a scalar value
    #         sv = sprint(print, v, context=io, sizehint=0)
    #     else
    #         sv = sprint(summary, v, context=io, sizehint=0)
    #     end
    #     max_align = max(max_align, length(sk))

    #     push!(prows, [sk, sv])
    #     i == top && push!(prows, ["⋮", "⋮"])
    # end

    # cutoff = dwidth - 5 - max_align

    # for (sk, sv) ∈ prows
    #     lv = length(sv)
    #     sv = lv <= cutoff ? sv : sv[1:cutoff-1] * "…"
    #     print(io, "\n  ", lpad(sk, max_align), " ⇒ ", sv)
    # end

end