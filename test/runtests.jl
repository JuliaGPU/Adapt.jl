using Adapt
using Test

# trivial test

struct Matrix
    mat::AbstractArray
end

struct MatrixAdaptor end

Adapt.adapt_structure(::MatrixAdaptor, xs::AbstractArray) = Matrix(xs)

testmat = [12;34;56;78]

testresult = Matrix(testmat)

@test adapt(MatrixAdaptor(), testmat) == testresult
