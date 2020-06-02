# predefined adaptors for working with types from the Julia standard library

adapt_structure(to, xs::Union{Tuple,NamedTuple}) = map(x->adapt(to,x), xs)


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(bc.f, map(arg->adapt(to, arg), bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)
