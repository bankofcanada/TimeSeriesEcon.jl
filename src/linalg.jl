# Copyright (c) 2020-2022, Bank of Canada
# All rights reserved.

# overload matrix-matrix and matrix-vector operations
# for MVTSeries and TSeries

import Base: *, \, /

for op in (:*, :\, :/)
    eval(quote
        $op(A::AbstractVecOrMat, B::TSeries) = $op(A, _vals(B))
        $op(A::AbstractVecOrMat, B::MVTSeries) = $op(A, _vals(B))
        $op(A::TSeries, B::AbstractVecOrMat) = $op(_vals(A), B)
        $op(A::MVTSeries, B::AbstractVecOrMat) = $op(_vals(A), B)
        $op(A::TSeries, B::TSeries) = $op(_vals(A), _vals(B))
        $op(A::TSeries, B::MVTSeries) = $op(_vals(A), _vals(B))
        $op(A::MVTSeries, B::TSeries) = $op(_vals(A), _vals(B))
        $op(A::MVTSeries, B::MVTSeries) = $op(_vals(A), _vals(B))
    end)

end

