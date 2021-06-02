# predefined adaptors for working with types from the Julia standard library

adapt_structure(to, xs::Union{Tuple,NamedTuple}) = map(x->adapt(to,x), xs)


## Closures

# two things can be captured: static parameters, and actual values (fields)

@eval function adapt_structure(to, f::F) where {F<:Function}
  isempty(F.parameters) && return f
  nsparams = length(F.parameters) - nfields(f)

  # TODO: we should adapt the static parameters too
  #       (but adapt currently only works with values)
  sparams = ntuple(i->F.parameters[i], nsparams)
  fields = ntuple(i->adapt(to, getfield(f, i)), nfields(f))

  # TODO: this assumes the typevars of the closure matches the sparams + fields.
  #       that may not always be true, and definitely isn't for arbitrary callable objects.
  ftyp = F.name.wrapper{sparams..., map(Core.Typeof, fields)...}
  $(Expr(:splatnew, :ftyp, :fields))
end


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(adapt(to, bc.f), map(arg->adapt(to, arg), bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)
