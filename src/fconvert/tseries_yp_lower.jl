"""
    _get_shift_to_lower(F_to, F_from; method) where {F_to <: YPFrequency, F_from <: YPFrequency}

    This helper function returns the number of periods by which the input of a conversion
    must be shifted up in order to account for reference-month effects of the input and output 
    frequencies when these are different from the defaults (12 for Yearly and 3 for Quarterly). 

    The optional `errors` argument determines whether to verify if the requested conversion is a valid one.
"""
function _get_shift_to_lower(F_to::Type{<:YPFrequency{N1}}, F_from::Type{<:YPFrequency{N2}}; errors=true) where {N1,N2}
    errors && _validate_fconvert_yp(F_to, F_from)
    
    shift_length = 0
    if hasproperty(F_to, :parameters) && length(F_to.parameters) > 0
        # in this case we need to shift the index ranges
        shift_length += Int((12/N1) - F_to.parameters[1])
    end
    return shift_length
end


function fconvert(F_to::Type{<:Union{<:Weekly,Weekly{N1}}}, t::TSeries{<:Union{<:Weekly,Weekly{N2}}}; method=:end, interpolation=:none) where {N1, N2}
    return fconvert(F_to, fconvert(Daily, t, method= interpolation==:linear ? :linear : :const ), method=method)
end

"""only interpolation=:none available"""
function fconvert(F_to::Type{<:Union{<:Yearly,Yearly{N1}}}, t::TSeries{<:Union{<:Yearly,Yearly{N2}}}; method=:end, interpolation=:none) where {N1, N2}
    np = 12
    N_to_effective = @isdefined(N1) ? N1 : np
    N_from_effective = @isdefined(N2) ? N2 : np
    return _fconvert_similar_frequency(F_to, t, N_to_effective, N_from_effective, np; method=method, interpolation=interpolation)
end

function fconvert(F_to::Type{<:Union{Quarterly,Quarterly{N1}}}, t::TSeries{<:Union{Quarterly,Quarterly{N2}}}; method=:end, interpolation=:none) where {N1, N2}
    np = 3
    N_to_effective = @isdefined(N1) ? N1 : np
    N_from_effective = @isdefined(N2) ? N2 : np
    return _fconvert_similar_frequency(F_to, t, N_to_effective, N_from_effective, np; method=method, interpolation=interpolation)
end

function _fconvert_similar_frequency(F_to::Type{<:Frequency}, t::TSeries, N_to_effective::Integer, N_from_effective::Integer, np::Integer; method=:end, interpolation=:none)
    N_shift = N_to_effective - N_from_effective
    if N_shift == 0
        return TSeries(MIT{F_to}(Int(t.firstdate)), t.values)
    end
    
    if interpolation == :none
        if method == :end
            # example: December to June = -6, in this case we want the same Int
            # example: June to December = 6, in this case we want the previous year, as there is no December value for the last year in the from series
            fi = N_shift < 0 ? MIT{F_to}(Int(t.firstdate)) : MIT{F_to}(Int(t.firstdate) - 1)
            return TSeries(fi, t.values)
        elseif method == :begin
            # example: December to August = -4, in this case we want the next year, since the value at the beginning of the June year is the December value
            # example: August to December = 4, in this case we want the same Int
            fi = N_shift < 0 ? MIT{F_to}(Int(t.firstdate + 1)) : MIT{F_to}(Int(t.firstdate))
            return TSeries(fi, t.values)
        elseif method == :mean
            if N_shift < 0
                # December to August (4/12 last year, 8/12 this year) => - 4
                weights = [(abs(N_shift))/np, (np + N_shift) / np]
                fi = MIT{F_to}(Int(t.firstdate + 1))
                values = [weights[1]*t.values[i-1] + weights[2]*t.values[i] for i in 2:length(t.values)]
                return TSeries(fi, values)  
            elseif N_shift > 0
                # August to December (8/12 this year, 4/12 next year) => 4
                weights = [(np - N_shift)/np, N_shift/np]
                fi = MIT{F_to}(Int(t.firstdate))
                values = [weights[1]*t.values[i] + weights[2]*t.values[i+1] for i in 1:length(t.values)-1 ]
                return TSeries(fi, values)  
            end
        else
            throw(ArgumentError("Conversion method not available: $(method)."))
        end
    else
        throw(ArgumentError("Conversion interpolation not available: $(interpolation)."))
    end
end
