module Adapt

using LinearAlgebra

adapt_(T, x) = x

adapt(T, x) = adapt_(T, x)

# Base integrations

adapt(T, x::Adjoint) = Adjoint(adapt(T, parent(x)))
adapt(T, x::Transpose) = Transpose(adapt(T, parent(x)))

end # module
