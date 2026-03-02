module AdaptStaticArraysExt

using Adapt
isdefined(Base, :get_extension) ? (using StaticArrays) : (using ..StaticArrays)

Adapt.adapt_storage(::Type{<:SArray{S}}, xs::Array) where {S} = SArray{S}(xs)
Adapt.adapt_storage(::Type{SArray}, xs::Array) = SArray{Tuple{size(xs)...}}(xs)

Adapt.adapt_structure(to, x::SArray{S,T,N,L}) where {S,T,N,L} =
    SArray{S}(ntuple(i -> Adapt.adapt(to, x[i]), Val(L)))

end
