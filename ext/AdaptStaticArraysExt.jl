module AdaptStaticArraysExt

using Adapt
using StaticArrays

Adapt.adapt_storage(::Type{<:SArray{S}}, xs::Array) where {S} = SArray{S}(xs)
Adapt.adapt_storage(::Type{SArray}, xs::Array) = SArray{Tuple{size(xs)...}}(xs)

end
