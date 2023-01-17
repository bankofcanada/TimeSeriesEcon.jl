using TOML
options = Dict{Symbol,Any}(
    :bdaily_holidays_map => nothing,
    :bdaily_creation_bias => :strict,
    # :bdaily_skip_nans => false, 
    # :bdaily_skip_holidays => false
)

"""
    setoption(option::Symbol, value)

Sets the provided option to the provided values.

Current available options are:
* `:bdaily_holidays_map`: This option holds a tseries of boolean values spanning from 1970-01-01 to 2049-12-31. Values on dates
    with a `false` entry will not be returned when calling the `values` function on a BDaily TSeries 
    with the holidays=true option.
* `:bdaily_skip_nans`: This option controls the treatment of NaN values in BDaily arrays when performing
    `shift`, `lag`,`diff`, and `pct` functions on them. When true, NaNs are replaced with the most relevant non-NaN value when available.
* `:bdaily_skip_holidays`: When true, the values function will always be called with holidays=true for BDaily series. 
    This also controls the behavior of the `shift`, `lag`, `diff`, and `pct` functions, but only NaNs falling on holidays are replaced.
    
"""
function setoption(option::Symbol, value)
    if option==:bdaily_creation_bias && value ∉ (:strict, :previous, :next, :nearest)
        throw(ArgumentError(":bdaily_creation_bias must be :strict, :previous, :next or :nearest. Received: $value"))
    end
    options[option] = value;
    nothing #don't return anything
end

"""
    getoption(option::Symbol)

Returns the current value of the provided option.

See also [`setoption`](@ref)
"""
function getoption(option::Symbol)
    options[option];
end


"""
    get_holidays_options(country::Union{String,Nothing}=nothing)

Returns a dictionary of country codes for supported countries and their subdivisions (where applicable)

Holiday calendars are produced using the [python-holidays](https://github.com/dr-prodigy/python-holidays) libary. See their site for more.
"""
function get_holidays_options(country::Union{String,Nothing}=nothing)
    countries = TOML.parsefile(joinpath(@__DIR__, "..", "data", "holidays.toml"))
    
    if country !== nothing && country ∉ keys(countries)
        throw(ArgumentError("$country is not a supported country. Run without an argument to see supported countries."))
    end

    d = Dict{String,Any}()
    for c in keys(countries)
        if c ∈ ("Metadata",)
            continue
        end
        val = countries[c]
        if val isa Integer
            d[c] = c
        else
            d2 = Array{String}(undef, length(keys(val)))
            for (i, sub) in enumerate(keys(val))
                d2[i] = replace(sub, " " => "_")
            end
            d[c] = d2
        end
    end
    if country !== nothing
        return d[country]
    end
    return d
end

"""
    set_holidays_map(country::String, subdivision::Union{String,Nothing}=nothing)

Sets the current holidays map to the given country and subdivision. Holiday maps span from 1970-01-01 to 2049-12-31.

See also: [`get_holidays_options`](@ref), [`clear_holidays_map`](@ref)
"""
function set_holidays_map(country::String, subdivision::Union{String,Nothing}=nothing)
    countries = TOML.parsefile(joinpath(@__DIR__, "..", "data", "holidays.toml"))
    covered_range = bdaily("1970-01-01"):bdaily("2049-12-31");
    holiday_maps = Array{UInt8}(undef, (Int(length(covered_range)/8), countries["Metadata"]["output_height"]))
    read!(joinpath(@__DIR__, "..", "data", "holidays.bin"), holiday_maps)
    
    col = 0
    if country in keys(countries)
        if country == "IN"
            @warn "Diwali and Holi holidays available from 2010 to 2030 only."
        end
        if subdivision !== nothing
            if !(countries[country] isa Dict)
                throw(ArgumentError("Country $country has no supported subdivisions."))
            end
            if subdivision in keys(countries[country])
                col = countries[country][subdivision]
            else
                throw(ArgumentError("Unsupported subdivision: $subdivision for country: $country. Unsupported country: $country. Run `TimeSeriesEcon.get_holidays_options(\"$country\")` to see list of supported subdivisions."))
            end
        elseif countries[country] isa Dict
            if country in keys(countries["Metadata"]["Defaults"])
                default = countries["Metadata"]["Defaults"][country]
                @warn "Defaulting to subdivision $(default) of $(country)."
                col = countries[country][default]
            else
                throw(ArgumentError("Country $country has subdivisions. Please supply one of: $(keys(countries[country]))."))
            end
            
        else
            col = countries[country]
        end
    else
        throw(ArgumentError("Unsupported country: $country. Run `TimeSeriesEcon.get_holidays_options()` to see list of supported countries."))
    end

    # The bits are packed in a UInt8 array
    # each UInt8 corresponds to one ordering of 8 bits
    ts = TSeries(first(covered_range), reduce(vcat, map(x -> digits(Bool, x, base=2, pad=8), holiday_maps[:,col])));
    setoption(:bdaily_holidays_map, ts);
end


"""
    clear_holidays_map()

Clears the current holidays map.

See also: [`get_holidays_options`](@ref), [`set_holidays_map`](@ref)
"""
function clear_holidays_map()
    setoption(:bdaily_holidays_map, nothing);
end