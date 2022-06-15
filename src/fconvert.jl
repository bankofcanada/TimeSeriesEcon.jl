# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

import Statistics: mean

#### strip and strip!

function _valid_range(t::TSeries)
    fd = firstdate(t)
    ld = lastdate(t)
    while fd <= ld && istypenan(t[ld])
        ld -= 1
    end
    while fd <= ld && istypenan(t[fd])
        fd += 1
    end
    return fd:ld
end

"""
    strip(t:TSeries)

Remove leading and trailing `NaN` from the given time series. This version
creates a new [`TSeries`](@ref) instance.
"""
Base.strip(t::TSeries) = getindex(t, _valid_range(t))
"""
    strip!(t::TSeries)

Remove leading and training `NaN` from the given time series. This is
done in-place.
"""
strip!(t::TSeries) = resize!(t, _valid_range(t))
export strip!

"""
    fconvert(F, t)

Convert the time series `t` to the desired frequency `F`.
"""
fconvert(F::Type{<:Frequency}, t::TSeries; args...) = error("""
Conversion from $(frequencyof(t)) to $F not implemented.
""")

# do nothing when the source and target frequencies are the same.
fconvert(::Type{F}, t::TSeries{F}) where {F<:Frequency} = t

"""
    fconvert(F1, x::TSeries{F2}; method) where {F1 <: YPFrequency, F2 <: YPFrequency}

Convert between frequencies derived from [`YPFrequency`](@ref).

Currently this works only when the periods per year of the higher frequency is
an exact multiple of the periods per year of the lower frequency.

### Converting to Higher Frequency
The only method available is `method=:const`, where the value at each period of
the higher frequency is the value of the period of the lower frequency it
belongs to.
```
x = TSeries(2000Q1:2000Q3, collect(Float64, 1:3))
fconvert(Monthly, x)
```

### Converting to Lower Frequency
The range of the result includes periods that are fully included in the range of
the input. For each period of the lower frequency we aggregate all periods of
the higher frequency within it. We have 4 methods currently available: `:mean`,
`:sum`, `:begin`, and `:end`.  The default is `:mean`.
```
x = TSeries(2000M1:2000M7, collect(Float64, 1:7))
fconvert(Quarterly, x; method = :sum)
```
"""
function fconvert(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=nothing, orientation=nothing) where {N1,N2}
    args = Dict()
    if method !== nothing
        args[:method] = method
    end
    if orientation !== nothing
        args[:orientation] = orientation
    end
    N1 > N2 ? _to_higher(F, t; args...) : _to_lower(F, t; args...)
end

function _to_higher(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:const, orientation=:end) where {N1,N2}
    """
    NOTE: current const method assumes we are interested in matching end-of-period values.
    FAME has other approaches (BEGINNING, AVERAGED, SUMMED, ANNUALIZED, FORMULA, HIGH, LOW)
    These are passed in an "observed" argument to the convert function.
    """
    (np, r) = divrem(N1, N2)
    if r != 0
        throw(ArgumentError("Cannot convert to higher frequency with $N1 ppy from $N2 ppy - not an exact multiple."))
    end
    # check if series has an odd anchor
    shift_length = 0
    if hasproperty(F, :parameters) && length(F.parameters) > 0
        # error handling
        if N1 == 1 && F.parameters[1] ∉ (1,2,3,4,5,6,7,8,9,10,11,12)
            throw(ArgumentError("Target yearly frequency has an unsuppported end month: $(F.parameters[1]). Must be 1-12."))
        end
        if N1 == 4 && F.parameters[1] ∉ (1,2,3)
            throw(ArgumentError("Target quarterly frequency has an unsuppported end month: $(F.parameters[1]). Must be 1-3."))
        end
    end
    if hasproperty(frequencyof(t), :parameters) && length(frequencyof(t).parameters) > 0
        
        # error handling
        if N2 == 1 && frequencyof(t).parameters[1] ∉ (1,2,3,4,5,6,7,8,9,10,11,12)
            throw(ArgumentError("Yearly frequency has an unsuppported end month: $(frequencyof(t).parameters[1]). Must be 1-12."))
        end
        if N2 == 4 && frequencyof(t).parameters[1] ∉ (1,2,3)
            throw(ArgumentError("Quarterly frequency has an unsuppported end month: $(frequencyof(t).parameters[1]). Must be 1-3."))
        end

        """ N1/N2 is ratio between the frequencies, one of  12, 4, or 3
        monthly from yearly: 12/1 = 12
        monthly from quarterly: 12/4 = 3
        quarterly from yearly: 4/1 = 4

        the numerator of the ceil argument is the end month for the frequency
        1-12 for yearly frequencies, 1-3 for quarterly frequencies

        the denominator of the ceil argument the number of months in each period of the input TSeries
        it is either 12 (for conversion from yearly) or 3 (for conversion from quarterly)

        together, these determine whether a shift in the base month of the input translates into
        a shift in the period of the output.

        Example 1:
          Yearly{8} to monthly -> 12/1 - floor(8 / (12/12)) -> 12 - ceil(8/1) = 12 - 8 = 4
          Since the yearly period ends in the eigth month of the year (i.e. August)
          This is fourt months earlier than the baseline assumption (end of period in twelfth month, i.e. December)
          so we need to shift the output to an earlier time by 4 months.

        Example 2:
          Quarterly{1} to monthly -> 12/4 - floor(1 / (12/12)) -> 3 - ceil(1/1) = 3 - 1 = 2
          Since the quarterly period ends in the first month of the quarter (i.e. January, April, July, October)
          This is two months earlier than the baseline assumption (end of period in third month, i.e. March)
          so we need to shift the output to an earlier time by 2 months.

        Example 3:
            Yearly{10} to quarterly ->  4/1 - floor(10 / (12/4))  = 4 - ceil(10/3) = 4 - 3 = 1
            Since October is before the end of 4th quarter, the end period for each data point is one quarter earlier.

        Example 4:
            Yearly{7} to quarterly ->  4/1 - floor(7 / (12/4))  = 4 - ceil(7/3) = 4 - 2 = 2
            Since July is before the end of the third quarter, the last quarter for which we have data at the end is Q2
            This is two quarter earlier than the baseline assumption (data for end of Q4) so we need to shift
            the output to an earlier time by 2 quarters.

        Example 5:
            Yearly{7} to quarterly{1} 
            effective_end_month = 7 + (12 / 4) - 1 = 7 + 3 - 1 = 7 + 2 = 9
            Yearly{7} to quarterly{1} ->  4/1 - floor(9 / (12/4))  = 4 - ceil(9/3) = 4 - 1 = 1
            Since July is the end of a the third quarter in a Quarterly{1} framework
            This is the same as if we were working with a Yearly{9} data and a regular Quarterly{3} target.
            We thus need to shift the results by only one Quarter.
        
        """
        rounder = floor
        if (orientation == :beginning)
            rounder = ceil
        end

        effective_end_month = frequencyof(t).parameters[1]
        if hasproperty(F, :parameters) && length(F.parameters) > 0
            effective_end_month +=  (12/N1) - F.parameters[1]
        end
        shift_length = Int(N1/N2 - rounder(effective_end_month / (12 / N1) ))
    end
    
    # np = number of periods of the destination frequency for each period of the source frequency
    (y1, p1) = mit2yp(firstindex(t))
    # (y2, p2) = yp(lastindex(t))
    fi = MIT{F}(y1, (p1 - 1) * np + 1)
    # lastindex_s = pp(y2, p2*np; N=N1))
    if method == :const
        if shift_length != 0
            shift!(TSeries(fi, repeat(t.values, inner=np)), shift_length)
        else
        return TSeries(fi, repeat(t.values, inner=np))
        end
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
end

function _to_lower(F::Type{<:YPFrequency{N1}}, t::TSeries{<:YPFrequency{N2}}; method=:mean) where {N1,N2}
    (np, r) = divrem(N2, N1)
    # println("np = $np, r = $r")
    if r != 0
        throw(ArgumentError("Cannot convert to lower frequency with $N1 from $N2 - not an exact multiple."))
    end
    if hasproperty(frequencyof(t), :parameters) && length(frequencyof(t).parameters) > 0
        # error handling
        if N2 == 4 && frequencyof(t).parameters[1] ∉ (1,2,3)
            throw(ArgumentError("Quarterly input frequency has an unsuppported end month: $(frequencyof(t).parameters[1]). Must be 1-3."))
        end

        #quarterly{1} to yearly
        """
        All the specialized YPFrequencies (Yearly{N}, Quarterly{N}) are based on some monthly shift.
        We therefore convert the series to monthly, before recalling fconvert on the output.
        """
        return fconvert(F, fconvert(Monthly, t), method=method)
    end
    shift_length = 0
    if hasproperty(F, :parameters) && length(F.parameters) > 0
        # error handling
        if N1 == 1 && F.parameters[1] ∉ (1,2,3,4,5,6,7,8,9,10,11,12)
            throw(ArgumentError("Target yearly frequency has an unsuppported end month: $(F.parameters[1]). Must be 1-12."))
        end
        if N1 == 4 && F.parameters[1] ∉ (1,2,3)
            throw(ArgumentError("Target quarterly frequency has an unsuppported end month: $(F.parameters[1]). Must be 1-3."))
        end

        # in this case we need to shift the index ranges
        shift_length += Int((12/N1) - F.parameters[1])

    end

    (y1, p1) = mit2yp(firstindex(t) + shift_length)
    (d1, r1) = divrem(p1 - 1, np)
    fi = MIT{F}(y1, d1 + 1) + (r1 > 0)
    # println("y1 = $y1, p1 = $p1, d1 = $d1, r1 = $r1, fi = $fi")
    (y2, p2) = mit2yp(lastindex(t) + shift_length)
    (d2, r2) = divrem(p2 - 1, np)
    li = MIT{F}(y2, d2 + 1) - (r2 < np - 1)
    # println("y2 = $y2, p2 = $p2, d2 = $d2, r2 = $r2, li = $li")
    vals = t[begin+(r1>0)*(np-r1):end-(r2<np-1)*(1+r2)].values
    # println("vals = $vals")
    if method == :mean
        ret = mean(reshape(vals, np, :); dims=1)
    elseif method == :sum
        ret = sum(reshape(vals, np, :); dims=1)
    elseif method == :begin
        ret = reshape(vals, np, :)[begin, :]
    elseif method == :end
        ret = reshape(vals, np, :)[end, :]
    else
        throw(ArgumentError("Conversion method not available: $(method)."))
    end
    return copyto!(TSeries(eltype(ret), fi:li), ret)
end

