# Copyright (c) 2020-2024, Bank of Canada
# All rights reserved.

# overload matrix-matrix and matrix-vector operations
# for MVTSeries and TSeries

import Base: *, \, /

for op in (:*, :\, :/)
    for AT in (AbstractMatrix, AbstractVector, Adjoint{<:Any, <:AbstractMatrix{T}} where {T})
        for ST in (MVTSeries, TSeries)
            eval(quote
                $op(A::$AT, B::$ST) = $op(A, _vals(B))
                $op(A::$ST, B::$AT) = $op(_vals(A), B)
            end)
        end
    end
    eval(quote
        $op(A::TSeries, B::TSeries) = $op(_vals(A), _vals(B))
        $op(A::TSeries, B::MVTSeries) = $op(_vals(A), _vals(B))
        $op(A::MVTSeries, B::TSeries) = $op(_vals(A), _vals(B))
        $op(A::MVTSeries, B::MVTSeries) = $op(_vals(A), _vals(B))
    end)
end

Base.adjoint(A::MVTSeries) = adjoint(_vals(A))
Base.adjoint(A::TSeries) = adjoint(_vals(A))

Base.transpose(A::MVTSeries) = transpose(_vals(A))
Base.transpose(A::TSeries) = transpose(_vals(A))
