# predefined adaptors for working with types from the Julia standard library

# Recurse instead of calling `map`, whose NamedTuple method is not specialized
# on the mapped function
adapt_structure(to, xs::NamedTuple{names}) where {names} =
  NamedTuple{names}(adapt_structure(to, Tuple(xs)))
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

# The rule is generated so that the type bookkeeping happens when generating, not during
# inference: when this method recurses (a closure capturing a closure or a `ComposedFunction`),
# inference stops constant-folding the reflection and the result type is lost.
@generated function adapt_structure(to, f::F) where {F<:Function}
  # how many type parameters does this function have?
  # each captured value will have one (with the exception of boxed values)
  num_type_params = length(F.parameters)
  num_type_params <= 0 && return :f

  # the remainder of the parameters are static parameters
  num_typed_captures = count(!(==(Core.Box)), fieldtypes(F))
  num_static_params = num_type_params - num_typed_captures
  # quoted, since a static parameter can be a value that does not evaluate to itself
  static_params = map(QuoteNode, F.parameters[1:num_static_params])
  # TODO: we should adapt the static parameters too
  #       (but adapt currently only works with values)

  # adapt the captured values
  fields = [:(adapt(to, getfield(f, $i))) for i in 1:fieldcount(F)]
  # TODO: this assumes the typevars of the closure matches the sparams + fields.
  #       that may not always be true, and definitely isn't for arbitrary callable objects.
  typed_captures = [:(Core.Typeof($(Symbol(:field, i)))) for i in 1:fieldcount(F)
                    if fieldtype(F, i) !== Core.Box]

  # create a new function
  quote
    $((:($(Symbol(:field, i)) = $(fields[i])) for i in 1:fieldcount(F))...)
    ftyp = $(F.name.wrapper){$(static_params...), $(typed_captures...)}
    $(Expr(:new, :ftyp, (Symbol(:field, i) for i in 1:fieldcount(F))...))
  end
end

adapt_structure(to, x::Core.Box) = Core.Box(adapt(to, x.contents))

# we can't rewrite opaque closures
adapt_structure(to, oc::Core.OpaqueClosure) = oc

# `Fix1` and `Fix2` are functions too, but the closure rule above is not inferable when it
# recurses into them from a closure that captures one
adapt_structure(to, f::Base.Fix1) = Base.Fix1(adapt(to, f.f), adapt(to, f.x))
adapt_structure(to, f::Base.Fix2) = Base.Fix2(adapt(to, f.f), adapt(to, f.x))


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(adapt(to, bc.f), adapt(to, bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)


## Ranges

adapt_structure(to, r::UnitRange) =
  UnitRange(adapt(to, r.start), adapt(to, r.stop))

adapt_structure(to, r::Base.OneTo) = Base.OneTo(adapt(to, r.stop))

adapt_structure(to, r::StepRange) =
  StepRange(adapt(to, r.start), adapt(to, r.step), adapt(to, r.stop))

adapt_structure(to, r::StepRangeLen{T}) where T =
  StepRangeLen{T}(adapt(to, r.ref), adapt(to, r.step), r.len, r.offset)

adapt_structure(to, r::Base.Slice) = Base.Slice(adapt(to, r.indices))

adapt_structure(to, r::LinRange) =
  LinRange(adapt(to, r.start), adapt(to, r.stop), r.len)

## CartesianIndices

adapt_structure(to, ci::CartesianIndices) = ci
