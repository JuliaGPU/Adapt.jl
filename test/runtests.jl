using Adapt
using Test


# custom array type

struct CustomArray{T,N} <: AbstractArray{T,N}
    arr::Array{T,N}
end

Adapt.adapt_storage(::Type{<:CustomArray}, xs::Array) = CustomArray(xs)

Base.size(x::CustomArray, y...) = size(x.arr, y...)
Base.getindex(x::CustomArray, y...) = getindex(x.arr, y...)
Base.count(x::CustomArray) = count(x.arr)

const mat = CustomArray{Float64,2}(rand(2,2))
const vec = CustomArray{Float64,1}(rand(2))

const mat_bools = CustomArray{Bool,2}(rand(Bool,2,2))

# test that adaption of `src_expr` to `to` matches `dst_expr`:
# - using ==
# - comparing the types
#
# if `typ` is set, assert that `src` (or `dst`, as they have been asserted to be identical)
# is a subtype of `typ`. this is useful to check that complex unions cover what's needed.
macro test_adapt(to, src_expr, dst_expr, typ=nothing)
    quote
        src = $(esc(src_expr))
        dst = $(esc(dst_expr))

        res = @inferred(adapt($(esc(to)), src))
        @test res == dst
        @test typeof(res) == typeof(dst)

        if $(esc(typ)) !== nothing
            @test typeof(dst) <: $(esc(typ))
        end
    end
end

AnyCustomArray{T,N} = Union{CustomArray,WrappedArray{T,N,CustomArray,CustomArray{T,N}}}


# basic adaption
@test_adapt CustomArray mat.arr mat

# idempotency
@test_adapt CustomArray mat mat

# to array
@test_adapt Array mat mat.arr
@test_adapt Array{Float32} mat Float32.(mat.arr)

# custom wrapper
struct Wrapper{T}
    arr::T
end
Adapt.adapt_structure(to, xs::Wrapper) = Wrapper(adapt(to, xs.arr))
@test_adapt CustomArray Wrapper(mat.arr) Wrapper(mat)


@testset "base structures" begin

@test @inferred(adapt(nothing, NamedTuple())) == NamedTuple()
@test_adapt CustomArray (mat.arr,) (mat,)
@test @allocated(adapt(nothing, ())) == 0
@test @allocated(adapt(nothing, (1,))) == 0
@test @allocated(adapt(nothing, (1,2,3,4,5,6,7,8,9,10))) == 0

@test_adapt CustomArray (a=mat.arr,) (a=mat,)

end

# NOTE: if we put this in the preceding testset, unrelated tests start to allocate
@testset "closures" begin

# basic capture of a variable
function closure1(x)
    function foobar()
        x
    end
    foobar
end

f = closure1(mat.arr)
@test f() === mat.arr
f′ = adapt(CustomArray, f)
@test f′() === mat
@test @inferred(adapt(nothing, f)()) === f()

# closure with sparams
function closure2(A::AbstractArray{T}=zeros(1), b::Number=0) where {T}
    function f()
        convert(T, 0)
        A, A[1] == b
    end
    f
end

f = closure2(mat.arr)
@test f() === (mat.arr, false)
f′ = adapt(CustomArray, f)
@test f′() === (mat, false)

# closure with box
x1 = CustomArray{Int,1}([1])
x2 = CustomArray{Int,1}([2])
x3 = CustomArray{Int,1}([3])
function closure3(a)
    b = "whatever"
    f(c) = (a, b, c)
    b = x2.arr
    return f
end

f = closure3(x1.arr)
@test f(x3.arr) === (x1.arr, x2.arr, x3.arr)
f′ = adapt(CustomArray, f)
@test f′(x3.arr) === (x1, x2, x3.arr)
# NOTE: actual arguments should be adapted by the caller

end


@testset "array wrappers" begin

@test_adapt CustomArray view(mat.arr,:,:) view(mat,:,:) AnyCustomArray
inds = CustomArray{Int,1}([1,2])
@test_adapt CustomArray view(mat.arr,inds.arr,:) view(mat,inds,:) AnyCustomArray

# NOTE: manual creation of PermutedDimsArray because permutedims collects
@test_adapt CustomArray PermutedDimsArray(mat.arr,(2,1)) PermutedDimsArray(mat,(2,1)) AnyCustomArray

# NOTE: manual creation of ReshapedArray because Base.Array has an optimized `reshape`
@test_adapt CustomArray Base.ReshapedArray(mat.arr,(2,2),()) reshape(mat,(2,2)) AnyCustomArray

@test_adapt CustomArray Base.LogicalIndex(mat_bools.arr) Base.LogicalIndex(mat_bools) AnyCustomArray

@test_adapt CustomArray reinterpret(Int64,mat.arr) reinterpret(Int64,mat) AnyCustomArray

@static if isdefined(Base, :NonReshapedReinterpretArray)
    @test_adapt CustomArray reinterpret(reshape,Int64,mat.arr) reinterpret(reshape,Int64,mat) AnyCustomArray
end


## doubly-wrapped

@test_adapt CustomArray reinterpret(Int64,view(mat.arr,:,:)) reinterpret(Int64,view(mat,:,:)) AnyCustomArray

@test_adapt CustomArray reshape(view(mat.arr,:,:), (2,2)) reshape(view(mat,:,:), (2,2)) AnyCustomArray
@test_adapt CustomArray reshape(reinterpret(Int64,mat.arr), (2,2)) reshape(reinterpret(Int64,mat), (2,2)) AnyCustomArray
@test_adapt CustomArray reshape(reinterpret(Int64,view(mat.arr,:,:)), (2,2)) reshape(reinterpret(Int64,view(mat,:,:)), (2,2)) AnyCustomArray

@test_adapt CustomArray view(reinterpret(Int64,mat.arr), :, :) view(reinterpret(Int64,mat), :, :) AnyCustomArray
@test_adapt CustomArray view(reinterpret(Int64,view(mat.arr,:,:)), :, :) view(reinterpret(Int64,view(mat,:,:)), :, :) AnyCustomArray
@test_adapt CustomArray view(Base.ReshapedArray(mat.arr,(2,2),()), :, :) view(reshape(mat, (2,2)), :, :) AnyCustomArray
@test_adapt CustomArray view(reshape(view(mat.arr,:,:), (2,2)), :, :) view(reshape(view(mat,:,:), (2,2)), :, :) AnyCustomArray
@test_adapt CustomArray view(reshape(reinterpret(Int64,mat.arr), (2,2)), :, :) view(reshape(reinterpret(Int64,mat), (2,2)), :, :) AnyCustomArray
@test_adapt CustomArray view(reshape(reinterpret(Int64,view(mat.arr,:,:)), (2,2)), :, :) view(reshape(reinterpret(Int64,view(mat,:,:)), (2,2)), :, :) AnyCustomArray

@static if isdefined(Base, :NonReshapedReinterpretArray)
    @test_adapt CustomArray reinterpret(reshape,Int64,view(mat.arr,:,:)) reinterpret(reshape,Int64,view(mat,:,:)) AnyCustomArray
    @test_adapt CustomArray view(reinterpret(reshape,Int64,mat.arr), :, :) view(reinterpret(reshape,Int64,mat), :, :) AnyCustomArray
    @test_adapt CustomArray view(reinterpret(reshape,Int64,view(mat.arr,:,:)), :, :) view(reinterpret(reshape,Int64,view(mat,:,:)), :, :) AnyCustomArray
end


using LinearAlgebra

@test_adapt CustomArray mat.arr' mat' AnyCustomArray

@test_adapt CustomArray transpose(mat.arr) transpose(mat) AnyCustomArray

@test_adapt CustomArray LowerTriangular(mat.arr) LowerTriangular(mat) AnyCustomArray
@test_adapt CustomArray UnitLowerTriangular(mat.arr) UnitLowerTriangular(mat) AnyCustomArray
@test_adapt CustomArray UpperTriangular(mat.arr) UpperTriangular(mat) AnyCustomArray
@test_adapt CustomArray UnitUpperTriangular(mat.arr) UnitUpperTriangular(mat) AnyCustomArray
@test_adapt CustomArray Symmetric(mat.arr) Symmetric(mat) AnyCustomArray

@test_adapt CustomArray Diagonal(vec.arr) Diagonal(vec) AnyCustomArray

dl = CustomArray{Float64,1}(rand(2))
du = CustomArray{Float64,1}(rand(2))
d = CustomArray{Float64,1}(rand(3))
@test_adapt CustomArray Tridiagonal(dl.arr, d.arr, du.arr) Tridiagonal(dl, d, du) AnyCustomArray

end


@testset "type information" begin
    # single wrapping
    @test parent_type(Transpose{Int,Array{Int,1}}) == Array{Int,1}
    @test parent_type(Transpose{Int,Transpose{Int,Array{Int,1}}}) == Transpose{Int,Array{Int,1}}

    # double wrapping
    @test unwrap_type(Transpose{Int,Array{Int,1}}) == Array{Int,1}
    @test unwrap_type(Transpose{Int,Transpose{Int,Array{Int,1}}}) == Array{Int,1}
end


struct MyStruct{A,B}
    a::A
    b::B
end

@testset "@adapt_structure" begin
    Adapt.@adapt_structure MyStruct

    u = ones(3)
    v = zeros(5)

    @test_adapt CustomArray MyStruct(u,v) MyStruct(CustomArray(u), CustomArray(v))
    @test_adapt CustomArray MyStruct(u,1.0) MyStruct(CustomArray(u), 1.0)
end


@testset "Broadcast" begin
    @test_adapt CustomArray Base.broadcasted(identity, mat.arr) Base.broadcasted(identity, mat)

    f = (x)->((y)->(y,x))
    bc = Base.broadcasted(f(mat.arr), (mat.arr,))
    @test typeof(copy(adapt(CustomArray, bc))) == typeof(broadcast(f(mat), (mat,)))
end

@testset "StaticArrays" begin
    using StaticArrays
    @test_adapt SArray{Tuple{3}} [1,2,3] SArray{Tuple{3}}([1,2,3])

    # can't possibly infer this one, so not using @test_adapt
    #@test_adapt SArray           [1,2,3] SArray{Tuple{3}}([1,2,3])
    @test adapt(SArray, [1,2,3]) === SArray{Tuple{3}}([1,2,3])
end
