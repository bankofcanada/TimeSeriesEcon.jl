# Copyright (c) 2020-2021, Bank of Canada
# All rights reserved.

#### Pretty printing for MVTSeries

function Base.summary(io::IO, x::MVTSeries)
    et = eltype(x) === Float64 ? "" : ",$(eltype(x))"
    typestr = "MVTSeries{$(prettyprint_frequency(frequencyof(x)))$(et)}"

    cols = axes(x,2)
    ncols = length(cols)
    if ncols == 0
        vstr = "no variables"
    else
        vstr="variables ($(cols[1])"
        for i = 2:ncols
            cstr = ",$(cols[i])"
            if length(vstr) + length(cstr) > 20 
                vstr *= ",…"
                break
            else
                vstr *= cstr
            end
        end
        vstr *= ")"
    end

    print(io, size(x,1), "×", size(x, 2), " ", typestr, " with range ", rangeof(x), " and ", vstr)
    nothing
end

Base.show(io::IO, ::MIME"text/plain", x::MVTSeries) = show(io, x)
function Base.show(io::IO, x::MVTSeries)
    summary(io, x)
    isempty(x) && return
    print(io, ":")
    limit = get(io, :limit, true)
    nval, nsym = size(x)

    mitpad = 2 + maximum(rangeof(x)) do mit
        length(string(mit))
    end

    from = firstdate(x)
    dheight, dwidth = displaysize(io)
    if get(io, :compact, nothing) === nothing
        io = IOContext(io, :compact => true)
    end
    dwidth -= (mitpad + 3)

    names = collect(colnames(x))
    vals = _vals(x)

    names_str = String[]
    for n in names
        sn = string(n)
        push!(names_str, length(sn) < 10 ? sn : sn[1:10])
    end
    sd_with_names = [reshape(names_str, 1, :); x.values]
    A = Base.alignment(io, sd_with_names, axes(sd_with_names, 1), 1:nsym, dwidth, dwidth, 2)

    all_cols = true
    if length(A) ≠ nsym
        dwidth = div(dwidth - 1, 2)
        AL = Base.alignment(io, sd_with_names, axes(sd_with_names, 1), 1:nsym, dwidth, dwidth, 2)
        AR = reverse(Base.alignment(io, sd_with_names, axes(sd_with_names, 1), reverse(1:nsym), dwidth, dwidth, 2))
        Linds = [1:length(AL)...]
        Rinds = [nsym - length(AR) + 1:nsym...]
        all_cols = false
    end

    local vdots = "\u22ee"
    local hdots = " \u2026 "
    local ddots = " \u22f1 "

    print_aligned_val(io, v, (al, ar), showsep=true; sep=showsep ? "  " : "") = begin
        sv = sprint(print, v, context=io, sizehint=0)
        if v isa Number
            vl, vr = Base.alignment(io, v)
        else
            if length(sv) > al + ar
                sv = sv[1:al + ar - 1] * '…'
            end
            vl, vr = al, length(sv) - al
        end
        print(io, repeat(" ", al - vl), sv, repeat(" ", ar - vr), sep)
    end

    print_colnames(io, Lcols, LAligns, Rcols=[], RAligns=[]) = begin
        local nLcols = length(Lcols)
        local nRcols = length(Rcols)
        for (i, (col, align)) in enumerate(zip(Lcols, LAligns))
            print_aligned_val(io, names[col], align, i < nLcols)
        end
        nRcols == 0 && return
        print(io, hdots)
        for (i, (col, align)) in enumerate(zip(Rcols, RAligns))
            print_aligned_val(io, names[col], align, i < nRcols)
        end
    end

    print_rows(io, rows, Lcols, LAligns, Rcols=[], RAligns=[]) = begin
        local nLcols = length(Lcols)
        local nRcols = length(Rcols)
        for row in rows
            mit = from + (row - 1)
            print(io, '\n', lpad(mit, mitpad), " : ")
            for (i, (val, align)) in enumerate(zip(vals[row, Lcols], LAligns))
                print_aligned_val(io, val, align, i < nLcols)
            end
            nRcols == 0 && continue
            print(io, hdots)
            for (i, (val, align)) in enumerate(zip(vals[row, Rcols], RAligns))
                print_aligned_val(io, val, align, i < nRcols)
            end
        end
    end

    print_vdots(io, Lcols, LAligns, Rcols=[], RAligns=[]) = begin
        print(io, '\n', repeat(" ", mitpad + 3))
        local nLcols = length(Lcols)
        local nRcols = length(Rcols)
        for (i, (col, align)) in enumerate(zip(Lcols, LAligns))
            print_aligned_val(io, vdots, align, i < nLcols)
        end
        nRcols == 0 && return
        print(io, ddots)
        for (i, (col, align)) in enumerate(zip(Rcols, RAligns))
            print_aligned_val(io, vdots, align, i < nRcols)
        end
    end

    if !limit
        print(io, "\n", repeat(" ", mitpad + 3))
        print_colnames(io, 1:nsym, A)
        print_rows(io, 1:nval, 1:nsym, A)
    elseif nval > dheight - 6 # all rows don't fit
                # unable to show all rows
        if all_cols
            print(io, "\n", repeat(" ", mitpad + 3))
            print_colnames(io, 1:nsym, A)
            top = div(dheight - 6, 2)
            print_rows(io, 1:top, 1:nsym, A)
            print_vdots(io, 1:nsym, A)
            bot = nval - dheight + 7 + top
            print_rows(io, bot:nval, 1:nsym, A)
        else # not all_cols
            print(io, "\n", repeat(" ", mitpad + 3))
            print_colnames(io, Linds, AL, Rinds, AR)
            top = div(dheight - 6, 2)
            print_rows(io, 1:top, Linds, AL, Rinds, AR)
            print_vdots(io, Linds, AL, Rinds, AR)
            bot = nval - dheight + 7 + top
            print_rows(io, bot:nval, Linds, AL, Rinds, AR)
        end # all_cols
    else # all rows fit
        if all_cols
            print(io, '\n', repeat(" ", mitpad + 3))
            print_colnames(io, 1:nsym, A)
            print_rows(io, 1:nval, 1:nsym, A)
        else
            print(io, '\n', repeat(" ", mitpad + 3))
            print_colnames(io, Linds, AL, Rinds, AR)
            print_rows(io, 1:nval, Linds, AL, Rinds, AR)
        end
    end
end


