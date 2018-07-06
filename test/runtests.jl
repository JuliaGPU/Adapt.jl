import Adapt: adapt, adapt_
using Test

# trivial test

struct Matrix
    mat::AbstractArray
end

adapt_(::Type{<:Matrix}, xs::AbstractArray) =
  Matrix(xs)

testmat = [12;34;56;78]

testresult = Matrix(testmat)

@test adapt(Matrix, testmat) == testresult
