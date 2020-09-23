# adaptors and type aliases for working with array wrappers

using LinearAlgebra

permutation(::PermutedDimsArray{T,N,perm}) where {T,N,perm} = perm


export WrappedArray

# database of array wrappers
const _wrappers = (
  :(SubArray{T,N,<:Src})                          => (A,mut)->SubArray(mut(parent(A)), mut(parentindices(A))),
  :(Base.LogicalIndex{T,<:Src})                   => (A,mut)->Base.LogicalIndex(mut(A.mask)),
  :(PermutedDimsArray{T,N,<:Any,<:Any,<:Src})     => (A,mut)->PermutedDimsArray(mut(parent(A)), permutation(A)),
  :(Base.ReshapedArray{T,N,<:Src})                => (A,mut)->Base.reshape(mut(parent(A)), size(A)),
  :(Base.ReinterpretArray{T,N,<:Any,<:Src})       => (A,mut)->Base.reinterpret(eltype(A), mut(parent(A))),
  :(LinearAlgebra.Adjoint{T,<:Dst})               => (A,mut)->LinearAlgebra.adjoint(mut(parent(A))),
  :(LinearAlgebra.Transpose{T,<:Dst})             => (A,mut)->LinearAlgebra.transpose(mut(parent(A))),
  :(LinearAlgebra.LowerTriangular{T,<:Dst})       => (A,mut)->LinearAlgebra.LowerTriangular(mut(parent(A))),
  :(LinearAlgebra.UnitLowerTriangular{T,<:Dst})   => (A,mut)->LinearAlgebra.UnitLowerTriangular(mut(parent(A))),
  :(LinearAlgebra.UpperTriangular{T,<:Dst})       => (A,mut)->LinearAlgebra.UpperTriangular(mut(parent(A))),
  :(LinearAlgebra.UnitUpperTriangular{T,<:Dst})   => (A,mut)->LinearAlgebra.UnitUpperTriangular(mut(parent(A))),
  :(LinearAlgebra.Diagonal{T,<:Dst})              => (A,mut)->LinearAlgebra.Diagonal(mut(parent(A))),
  :(LinearAlgebra.Tridiagonal{T,<:Dst})           => (A,mut)->LinearAlgebra.Tridiagonal(mut(A.dl), mut(A.d), mut(A.du)),
)

for (W, ctor) in _wrappers
    mut = :(A -> adapt(to, A))
    @eval adapt_structure(to, wrapper::$W where {T,N,Src,Dst}) = $ctor(wrapper, $mut)
end

"""
    WrappedArray{T,N,Src,Dst}

Union-type that encodes all array wrappers known by Adapt.jl. Typevars `T` and `N` encode
the type and dimensionality of the resulting container.

Two additional typevars are used to encode the parent array type: `Src` when the wrapper
uses the parent array as a source, but changes its properties (e.g.
`SubArray{T,1,Array{T,2}` changes `N`), and `Dst` when those properties are copied and thus
are identical to the destination wrapper's properties (e.g. `Transpose{T,Array{T,N}}` has
the same dimensionality as the inner array). When creating an alias for this type, e.g.
`WrappedSomeArray{T,N} = WrappedArray{T,N,...}` the `Dst` typevar should typically be set to
`SomeArray{T,N}` while `Src` should be more lenient, e.g., `SomeArray`.

Only use this type for dispatch purposes. To convert instances of an array wrapper, use
[`adapt`](@ref).
"""
const WrappedArray{T,N,Src,Dst} = @eval Union{$([W for (W,ctor) in Adapt._wrappers]...)} where {T,N,Src,Dst}

# XXX: this Union is a hack:
# - only works with one level of wrapping
# - duplication of Src and Dst typevars (without it, we get `WrappedGPUArray{T,N,AT{T,N}}`
#   not matching `SubArray{T,1,AT{T,2}}`, and leaving out `{T,N}` makes it impossible to
#   match e.g. `Diagonal{T,AT}` and get `N` out of that). alternatively, computed types
#   would make it possible to do `SubArray{T,N,<:AT.name.wrapper}` or `Diagonal{T,AT{T,N}}`.
#
# ideally, Base would have, e.g., `Transpose <: WrappedArray`, and we could use
# `Union{SomeArray, WrappedArray{<:Any, <:SomeArray}}` for dispatch.
# https://github.com/JuliaLang/julia/pull/31563

# accessors for extracting information about the wrapper type
Base.ndims(W::Type{<:WrappedArray{<:Any,N}}) where {N} = @isdefined(N) ? N : specialized_ndims(W)
Base.eltype(::Type{<:WrappedArray{T}}) where {T} = T  # every wrapper has a T typevar
Base.parent(::Type{<:WrappedArray{<:Any,<:Any,Src,Dst}}) where {Src,Dst} = @isdefined(Dst) ? Dst.name.wrapper : Src.name.wrapper

# some wrappers don't have a N typevar because it is constant, but we can't extract that from <:WrappedArray
specialized_ndims(::Type{<:LinearAlgebra.Adjoint}) = 2
specialized_ndims(::Type{<:LinearAlgebra.Transpose}) = 2
specialized_ndims(::Type{<:LinearAlgebra.LowerTriangular}) = 2
specialized_ndims(::Type{<:LinearAlgebra.UnitLowerTriangular}) = 2
specialized_ndims(::Type{<:LinearAlgebra.UpperTriangular}) = 2
specialized_ndims(::Type{<:LinearAlgebra.UnitUpperTriangular}) = 2
specialized_ndims(::Type{<:LinearAlgebra.Diagonal}) = 2
specialized_ndims(::Type{<:LinearAlgebra.Tridiagonal}) = 2
