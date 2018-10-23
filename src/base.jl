# predefined adaptors for working with types from the Julia standard library

## Base

adapt_structure(to, xs::Tuple) = Tuple(adapt(to, x) for x in xs)
@generated adapt_structure(to, x::NamedTuple) =
    Expr(:tuple, (:($f=adapt(to, x.$f)) for f in fieldnames(x))...)

adapt(to, x::SubArray) = SubArray(adapt(to, parent(x)), parentindices(x))


## LinearAlgebra

import LinearAlgebra: Adjoint, Transpose
adapt_structure(to, x::Adjoint)   = Adjoint(adapt(to, parent(x)))
adapt_structure(to, x::Transpose) = Transpose(adapt(to, parent(x)))


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(bc.f, map(arg->adapt(to, arg), bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)
