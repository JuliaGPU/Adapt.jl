# adaptors for converting abstract arrays to Base.Array


## arrays

Adapt.adapt_storage(::Type{Array}, xs::AT) where {AT<:AbstractArray} =
  convert(Array, xs)

# if an element type is specified, convert to it
Adapt.adapt_storage(::Type{<:Array{T}}, xs::AT) where {T, AT<:AbstractArray} =
  convert(Array{T}, xs)

# NOTE: this flattens all <:AbstractArray leaves, e.g., Base.Slice(1:2) -> [1,2].
