module Adapt

using LinearAlgebra


export WrappedArray

# database of array wrappers
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

"""
    WrappedArray{AT}

Union-type that encodes all array wrappers known by Adapt.jl.

Only use this type for dispatch purposes. To convert instances of an array wrapper, use
[`adapt`](@ref).
"""
const WrappedArray{AT} = @eval Union{$([W for (W,ctor) in Adapt.wrappers]...)} where AT

# XXX: this Unions is a hack, and only works with one level of wrray wrappers. ideally, Base
#      would have `Transpose <: WrappedArray <: AbstractArray` and we could define methods
#      in terms of `Union{SomeArray, WrappedArray{<:Any, <:SomeArray}}`.
#      https://github.com/JuliaLang/julia/pull/31563


export adapt

"""
    adapt(to, x)

Adapt a value `x` according to `to`. If no specific adaptions have been registered for `to`,
this call will be a no-op.

To alter the behavior, implement methods of `adapt_structure` and `adapt_storage` to
respectively define how to adapt structures, and the leaves of those structures.

For example, defining an adaptor for an environment where we can't have integers, and adding
a method to `adapt_storage` to appropriately convert those to floating-point numbers:

    julia> struct IntegerLessAdaptor end

    julia> Adapt.adapt_storage(::IntegerLessAdaptor, x::Int64) = Float64(x)

    julia> adapt(IntegerLessAdaptor(), 42)
    42.0

This will automatically work on known types too:

    julia> adapt(IntegerLessAdaptor(), tuple(1,2,3))
    (1.0, 2.0, 3.0)

If we want this to work with custom structures, we need to extend `adapt_structure`:

    julia> struct MyStructure
             x
           end

    julia> Adapt.adapt_structure(to, obj::MyStructure) = MyStructure(adapt(to, obj.x))

    julia> adapt(IntegerLessAdaptor(), MyStructure(42))
    MyStructure(42.0)
"""
adapt(to, x) = adapt_structure(to, x)

adapt_structure(to, x) = adapt_storage(to, x)
adapt_storage(to, x) = x

include("base.jl")

end # module
