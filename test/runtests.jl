using Adapt
using Test


# custom array type

struct CustomArray{T,N} <: AbstractArray{T,N}
    arr::AbstractArray
end

CustomArray(x::AbstractArray{T,N}) where {T,N} = CustomArray{T,N}(x)
Adapt.adapt_storage(::Type{<:CustomArray}, xs::AbstractArray) = CustomArray(xs)

Base.size(x::CustomArray, y...) = size(x.arr, y...)
Base.getindex(x::CustomArray, y...) = getindex(x.arr, y...)


const val = CustomArray{Float64,2}(rand(2,2))

# basic adaption
@test adapt(CustomArray, val.arr) == val
@test adapt(CustomArray, val.arr) isa CustomArray

# idempotency
@test adapt(CustomArray, val) == val
@test adapt(CustomArray, val) isa CustomArray

# custom wrapper
struct Wrapper{T}
    arr::T
end
Wrapper(x::T) where {T} = Wrapper{T}(x)
Adapt.adapt_structure(to, xs::Wrapper) = Wrapper(adapt(to, xs.arr))
@test adapt(CustomArray, Wrapper(val.arr)) == Wrapper(val)
@test adapt(CustomArray, Wrapper(val.arr)) isa Wrapper{<:CustomArray}


## base wrappers

@test adapt(CustomArray, (val.arr,)) == (val,)
@test @allocated(adapt(nothing, ())) == 0
@test @allocated(adapt(nothing, (1,))) == 0
@test @allocated(adapt(nothing, (1,2,3,4,5,6,7,8,9,10))) == 0

@test adapt(CustomArray, (a=val.arr,)) == (a=val,)

@test adapt(CustomArray, view(val.arr,:,:)) == view(val,:,:)
@test adapt(CustomArray, view(val.arr,:,:)) isa SubArray{<:Any,<:Any,<:CustomArray}


using LinearAlgebra

@test adapt(CustomArray, val.arr') == val'
@test adapt(CustomArray, val.arr') isa Adjoint{<:Any,<:CustomArray}
