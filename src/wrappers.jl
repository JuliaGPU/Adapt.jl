# adaptors and type aliases for working with array wrappers

using LinearAlgebra

permutation(::PermutedDimsArray{T,N,perm}) where {T,N,perm} = perm


export WrappedArray

adapt_structure(to, A::SubArray) =
      SubArray(adapt(to, Base.parent(A)), adapt(to, parentindices(A)))
function adapt_structure(to, A::PermutedDimsArray)
      perm = permutation(A)
      iperm = invperm(perm)
      A′ = adapt(to, Base.parent(A))
      PermutedDimsArray{Base.eltype(A′),Base.ndims(A′),perm,iperm,typeof(A′)}(A′)
end
adapt_structure(to, A::Base.ReshapedArray) =
      Base.reshape(adapt(to, Base.parent(A)), size(A))
@static if isdefined(Base, :NonReshapedReinterpretArray)
    adapt_structure(to, A::Base.NonReshapedReinterpretArray) =
          Base.reinterpret(Base.eltype(A), adapt(to, Base.parent(A)))
    adapt_structure(to, A::Base.ReshapedReinterpretArray) =
          Base.reinterpret(reshape, Base.eltype(A), adapt(to, Base.parent(A)))
else
    adapt_structure(to, A::Base.ReinterpretArray) =
          Base.reinterpret(Base.eltype(A), adapt(to, Base.parent(A)))
end
@eval function adapt_structure(to, A::Base.LogicalIndex{T}) where T
      # prevent re-calculating the count of booleans during LogicalIndex construction
      mask = adapt(to, A.mask)
      $(Expr(:new, :(Base.LogicalIndex{T, typeof(mask)}), :mask, :(A.sum)))
end

adapt_structure(to, A::LinearAlgebra.Adjoint) =
      LinearAlgebra.adjoint(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.Transpose) =
      LinearAlgebra.transpose(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.LowerTriangular) =
      LinearAlgebra.LowerTriangular(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.UnitLowerTriangular) =
      LinearAlgebra.UnitLowerTriangular(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.UpperTriangular) =
      LinearAlgebra.UpperTriangular(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.UnitUpperTriangular) =
      LinearAlgebra.UnitUpperTriangular(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.Diagonal) =
      LinearAlgebra.Diagonal(adapt(to, Base.parent(A)))
adapt_structure(to, A::LinearAlgebra.Tridiagonal) =
      LinearAlgebra.Tridiagonal(adapt(to, A.dl), adapt(to, A.d), adapt(to, A.du))
adapt_structure(to, A::LinearAlgebra.Symmetric) =
      LinearAlgebra.Symmetric(adapt(to, Base.parent(A)))


# we generally don't support multiple layers of wrappers, but some occur often
# and are supported by Base aliases like StridedArray.

const WrappedReinterpretArray{T,N,Src} =
      Base.ReinterpretArray{T,N,<:Any,<:Union{Src,SubArray{<:Any,<:Any,Src}}}

const WrappedReshapedArray{T,N,Src} =
      Base.ReshapedArray{T,N,<:Union{Src,
                                     SubArray{<:Any,<:Any,Src},
                                     WrappedReinterpretArray{<:Any,<:Any,Src}}}

const WrappedSubArray{T,N,Src} =
      SubArray{T,N,<:Union{Src,
                           WrappedReshapedArray{<:Any,<:Any,Src},
                           WrappedReinterpretArray{<:Any,<:Any,Src}}}


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
const WrappedArray{T,N,Src,Dst} = Union{
      #SubArray{T,N,<:Src},
      Base.LogicalIndex{T,<:Src},
      PermutedDimsArray{T,N,<:Any,<:Any,<:Src},
      #Base.ReshapedArray{T,N,<:Src},
      #Base.ReinterpretArray{T,N,<:Any,<:Src},

      LinearAlgebra.Adjoint{T,<:Dst},
      LinearAlgebra.Transpose{T,<:Dst},
      LinearAlgebra.LowerTriangular{T,<:Dst},
      LinearAlgebra.UnitLowerTriangular{T,<:Dst},
      LinearAlgebra.UpperTriangular{T,<:Dst},
      LinearAlgebra.UnitUpperTriangular{T,<:Dst},
      LinearAlgebra.Diagonal{T,<:Dst},
      LinearAlgebra.Tridiagonal{T,<:Dst},
      LinearAlgebra.Symmetric{T,<:Dst},

      WrappedReinterpretArray{T,N,<:Src},
      WrappedReshapedArray{T,N,<:Src},
      WrappedSubArray{T,N,<:Src},
}

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
ndims(::Type{<:Base.LogicalIndex}) = 1
ndims(::Type{<:LinearAlgebra.Adjoint}) = 2
ndims(::Type{<:LinearAlgebra.Transpose}) = 2
ndims(::Type{<:LinearAlgebra.LowerTriangular}) = 2
ndims(::Type{<:LinearAlgebra.UnitLowerTriangular}) = 2
ndims(::Type{<:LinearAlgebra.UpperTriangular}) = 2
ndims(::Type{<:LinearAlgebra.UnitUpperTriangular}) = 2
ndims(::Type{<:LinearAlgebra.Diagonal}) = 2
ndims(::Type{<:LinearAlgebra.Tridiagonal}) = 2
ndims(::Type{<:WrappedArray{<:Any,N}}) where {N} = N

eltype(::Type{<:WrappedArray{T}}) where {T} = T  # every wrapper has a T typevar

for T in [:(Base.LogicalIndex{<:Any,<:Src}),
          :(PermutedDimsArray{<:Any,<:Any,<:Any,<:Any,<:Src}),
          :(WrappedReinterpretArray{<:Any,<:Any,<:Src}),
          :(WrappedReshapedArray{<:Any,<:Any,<:Src}),
          :(WrappedSubArray{<:Any,<:Any,<:Src})]
    @eval begin
        parent(::Type{<:$T}) where {Src} = Src.name.wrapper
    end
end
parent(::Type{<:WrappedArray{<:Any,<:Any,<:Any,Dst}}) where {Dst} = Dst.name.wrapper
