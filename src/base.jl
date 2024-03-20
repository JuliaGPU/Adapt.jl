# predefined adaptors for working with types from the Julia standard library

# Use recursion to avoid inference bail-out in `map`
#adapt_structure(to, xs::Union{Tuple,NamedTuple}) = map(adapt(to), xs)
adapt_structure(to, xs::NamedTuple) = map(adapt(to), xs)
# Specialize on small Tuples
function adapt_structure(to, xs::Tuple)
  if length(xs) ≤ 20
    _adapt_tuple_structure(to, xs)
  else
    map(adapt(to), xs)
  end
end
_adapt_tuple_structure(to, xs::Tuple) =
  (adapt(to, first(xs)), _adapt_tuple_structure(to, Base.tail(xs))...)
_adapt_tuple_structure(to, xs::Tuple{}) = ()
_adapt_tuple_structure(to, xs::Tuple{<:Any}) = (adapt(to, first(xs)), )

## Closures

# two things can be captured: static parameters, and actual values (fields)

@eval function adapt_structure(to, f::F) where {F<:Function}
  # how many type parameters does this function have?
  # each captured value will have one (with the exception of boxed values)
  num_type_params = length(F.parameters)
  num_type_params <= 0 && return f

  # the remainder of the parameters are static parameters
  num_typed_captures = count(!(==(Core.Box)), fieldtypes(F))
  num_static_params = num_type_params - num_typed_captures
  static_params = ntuple(i->F.parameters[i], num_static_params)
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
  ftyp = F.name.wrapper{static_params..., map(Core.Typeof, typed_captures)...}
  $(Expr(:splatnew, :ftyp, :fields))
end

adapt_structure(to, x::Core.Box) = Core.Box(adapt(to, x.contents))

if VERSION >= v"1.7"
  # we can't rewrite opaque closures
  adapt_structure(to, oc::Core.OpaqueClosure) = oc
end


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(adapt(to, bc.f), adapt(to, bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)
