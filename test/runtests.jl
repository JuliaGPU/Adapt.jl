using Adapt
using Test


# custom array type

struct CustomArray{T,N} <: AbstractArray{T,N}
    arr::Array
end

CustomArray(x::Array{T,N}) where {T,N} = CustomArray{T,N}(x)
Adapt.adapt_storage(::Type{<:CustomArray}, xs::Array) = CustomArray(xs)

Base.size(x::CustomArray, y...) = size(x.arr, y...)
Base.getindex(x::CustomArray, y...) = getindex(x.arr, y...)


const mat = CustomArray{Float64,2}(rand(2,2))
const vec = CustomArray{Float64,1}(rand(2))

macro test_adapt(to, src, dst)
    quote
        @test adapt($to, $src) == $dst
        @test typeof(adapt($to, $src)) == typeof($dst)
    end
end


# basic adaption
@test_adapt CustomArray mat.arr mat

# idempotency
@test_adapt CustomArray mat mat

# custom wrapper
struct Wrapper{T}
    arr::T
end
Wrapper(x::T) where T = Wrapper{T}(x)
Adapt.adapt_structure(to, xs::Wrapper) = Wrapper(adapt(to, xs.arr))
@test_adapt CustomArray Wrapper(mat.arr) Wrapper(mat)


## base wrappers

@test @inferred(adapt(nothing, NamedTuple())) == NamedTuple()
@test_adapt CustomArray (mat.arr,) (mat,)
@test @allocated(adapt(nothing, ())) == 0
@test @allocated(adapt(nothing, (1,))) == 0
@test @allocated(adapt(nothing, (1,2,3,4,5,6,7,8,9,10))) == 0

@test_adapt CustomArray (a=mat.arr,) (a=mat,)

@test_adapt CustomArray view(mat.arr,:,:) view(mat,:,:)
const inds = CustomArray{Int,1}([1,2])
@test_adapt CustomArray view(mat.arr,inds.arr,:) view(mat,inds,:)

# NOTE: manual creation of PermutedDimsArray because permutedims collects
@test_adapt CustomArray PermutedDimsArray(mat.arr,(2,1)) PermutedDimsArray(mat,(2,1))

# NOTE: manual creation of ReshapedArray because Base.Array has an optimized `reshape`
@test_adapt CustomArray Base.ReshapedArray(mat.arr,(2,2),()) reshape(mat,(2,2))


using LinearAlgebra

@test_adapt CustomArray mat.arr' mat'

@test_adapt CustomArray transpose(mat.arr) transpose(mat)

@test_adapt CustomArray LowerTriangular(mat.arr) LowerTriangular(mat)
@test_adapt CustomArray UnitLowerTriangular(mat.arr) UnitLowerTriangular(mat)
@test_adapt CustomArray UpperTriangular(mat.arr) UpperTriangular(mat)
@test_adapt CustomArray UnitUpperTriangular(mat.arr) UnitUpperTriangular(mat)

@test_adapt CustomArray Diagonal(vec.arr) Diagonal(vec)

const dl = CustomArray{Float64,1}(rand(2))
const du = CustomArray{Float64,1}(rand(2))
const d = CustomArray{Float64,1}(rand(3))
@test_adapt CustomArray Tridiagonal(dl.arr, d.arr, du.arr) Tridiagonal(dl, d, du)
