# predefined adaptors for working with types from the Julia standard library

## Base

#adapt_structure(to, xs::Tuple) = Tuple(adapt(to, x) for x in xs)
#
# non-allocating version
#@generated adapt_structure(to, x::Tuple) =
#    Expr(:tuple, (:(adapt(to, x[$i])) for i in 1:fieldcount(x))...)
#
# non-allocating, non-@generated version
adapt_structure(to, xs::Tuple) = _adapt_structure(to, xs)
_adapt_structure(to, xs::Tuple{}) = ()
_adapt_structure(to, xs::Tuple) =
    tuple(adapt(to, xs[1]), _adapt_structure(to, Base.tail(xs))...)

@generated adapt_structure(to, x::NamedTuple) =
    Expr(:tuple, (:($f=adapt(to, x.$f)) for f in fieldnames(x))...)


## Array wrappers

using LinearAlgebra

# database of array wrappers, for use throughout the package
#
# LHS entries are a symbolic type with AT for the array type
#
# RHS entries consist of a closure to reconstruct the wrapper, with as arguments
# a wrapper instance and mutator function to apply to the inner array
const wrappers = (
  :(SubArray{<:Any,<:Any,AT})                     => (A,mut)->SubArray(mut(parent(A)), mut(parentindices(A))),
  :(PermutedDimsArray{<:Any,<:Any,<:Any,<:Any,AT})=> (A,mut)->PermutedDimsArray(mut(parent(A)), permutation(A)),
  :(Base.ReshapedArray{<:Any,<:Any,AT,<:Any})     => (A,mut)->Base.reshape(mut(parent(A)), size(A)),
  :(LinearAlgebra.Adjoint{<:Any,AT})              => (A,mut)->LinearAlgebra.adjoint(mut(parent(A))),
  :(LinearAlgebra.Transpose{<:Any,AT})            => (A,mut)->LinearAlgebra.transpose(mut(parent(A))),
  :(LinearAlgebra.LowerTriangular{<:Any,AT})      => (A,mut)->LinearAlgebra.LowerTriangular(mut(parent(A))),
  :(LinearAlgebra.UnitLowerTriangular{<:Any,AT})  => (A,mut)->LinearAlgebra.UnitLowerTriangular(mut(parent(A))),
  :(LinearAlgebra.UpperTriangular{<:Any,AT})      => (A,mut)->LinearAlgebra.UpperTriangular(mut(parent(A))),
  :(LinearAlgebra.UnitUpperTriangular{<:Any,AT})  => (A,mut)->LinearAlgebra.UnitUpperTriangular(mut(parent(A))),
  :(LinearAlgebra.Diagonal{<:Any,AT})             => (A,mut)->LinearAlgebra.Diagonal(mut(parent(A))),
  :(LinearAlgebra.Tridiagonal{<:Any,AT})          => (A,mut)->LinearAlgebra.Tridiagonal(mut(A.dl), mut(A.d), mut(A.du)),
)

permutation(::PermutedDimsArray{T,N,perm}) where {T,N,perm} = perm

for (W, ctor) in wrappers
    mut = :(A -> adapt(to, A))
    @eval adapt_structure(to, wrapper::$W where {AT <: Any}) = $ctor(wrapper, $mut)
end


## Broadcast

import Base.Broadcast: Broadcasted, Extruded

adapt_structure(to, bc::Broadcasted{Style}) where Style =
  Broadcasted{Style}(bc.f, map(arg->adapt(to, arg), bc.args), bc.axes)

adapt_structure(to, ex::Extruded) =
    Extruded(adapt(to, ex.x), ex.keeps, ex.defaults)
