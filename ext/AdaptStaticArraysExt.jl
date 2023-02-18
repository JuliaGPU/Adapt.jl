module AdaptStaticArraysCoreExt

using Adapt
isdefined(Base, :get_extension) ? (using StaticArrays) : (using ..StaticArrays)

Adapt.adapt_storage(::Type{<:SArray{S}}, xs::Array) where {S} = SArray{S}(xs)

end