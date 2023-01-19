# predefined adaptors for working with types from the Julia standard library

adapt_structure(to, xs::Union{Tuple,NamedTuple}) = map(adapt(to), xs)


## Closures

# two things can be captured: static parameters, and actual values (fields)

@eval function adapt_structure(to, f::F) where {F<:Function}
  # how many type parameters does this function have?
  # each captured value will have one (with the exception of boxed values)
  npar = length(F.parameters)
  npar <= 0 && return f

  # the remainder of the parameters are static parameters
  typed_captures = filter(!(==(Core.Box)), fieldtypes(F))
  nsparams = npar - length(typed_captures)
  sparams = ntuple(i->F.parameters[i], nsparams)
  # TODO: we should adapt the static parameters too
  #       (but adapt currently only works with values)

  # adapt the captured values
  fields = adapt(to, ntuple(i->getfield(f, i), fieldcount(F)))
  # TODO: this assumes the typevars of the closure matches the sparams + fields.
  #       that may not always be true, and definitely isn't for arbitrary callable objects.
  typed_captures = filter(fields) do field
    !isa(field, Core.Box)
  end

  # create a new function
  ftyp = F.name.wrapper{sparams..., map(Core.Typeof, typed_captures)...}
  $(Expr(:splatnew, :ftyp, :fields))
end

adapt_structure(to, x::Core.Box) = Core.Box(adapt(to, x.contents))


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(adapt(to, bc.f), adapt(to, bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)
