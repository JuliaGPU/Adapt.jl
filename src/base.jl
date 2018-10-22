# predefined adaptors for working with types from the Julia standard library

## Base

adapt_structure(A::AbstractAdaptor, xs::Tuple) = Tuple(adapt(A, x) for x in xs)
@generated adapt_structure(A::AbstractAdaptor, x::NamedTuple) =
    Expr(:tuple, (:($f=adapt(A, x.$f)) for f in fieldnames(x))...)


## LinearAlgebra

import LinearAlgebra: Adjoint, Transpose
adapt_structure(A::AbstractAdaptor, x::Adjoint)   = Adjoint(adapt(A, parent(x)))
adapt_structure(A::AbstractAdaptor, x::Transpose) = Transpose(adapt(A, parent(x)))
