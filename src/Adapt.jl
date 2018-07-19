module Adapt

using LinearAlgebra

adapt_(T, x) = convert(T, x)

adapt(T, x) = adapt_(T, x)

# Base integrations

adapt(T, x::RowVector) = RowVector(adapt(T, x.vec))

end # module
