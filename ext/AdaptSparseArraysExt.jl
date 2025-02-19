module AdaptSparseArraysExt

using Adapt
isdefined(Base, :get_extension) ? (using SparseArrays) : (using ..SparseArrays)

Adapt.adapt_storage(::Type{Array}, xs::SparseVector) = xs
Adapt.adapt_storage(::Type{Array}, xs::SparseMatrixCSC) = xs
Adapt.adapt_storage(::Type{Array{T}}, xs::SparseVector) where {T} = SparseVector{T}(xs)
Adapt.adapt_storage(::Type{Array{T}}, xs::SparseMatrixCSC) where {T} = SparseMatrixCSC{T}(xs)

end
