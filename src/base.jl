# predefined adaptors for working with types from the Julia standard library

## Base

adapt_structure(A::AbstractAdaptor, xs::Tuple) = Tuple(adapt(A, x) for x in xs)
@generated adapt_structure(A::AbstractAdaptor, x::NamedTuple) =
    Expr(:tuple, (:($f=adapt(A, x.$f)) for f in fieldnames(x))...)

adapt(A::AbstractAdaptor, x::SubArray) = SubArray(adapt(A, parent(x)), parentindices(x))


## LinearAlgebra

import LinearAlgebra: Adjoint, Transpose
adapt_structure(A::AbstractAdaptor, x::Adjoint)   = Adjoint(adapt(A, parent(x)))
adapt_structure(A::AbstractAdaptor, x::Transpose) = Transpose(adapt(A, parent(x)))


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(A::AbstractAdaptor, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(bc.f, map(arg->adapt(A, arg), bc.args), bc.axes)

adapt_structure(A::AbstractAdaptor, ex::Extruded) =
    Extruded(adapt(A, ex.x), ex.keeps, ex.defaults)
