module Adapt

adapt_(T, x) = x

adapt(T, x) = adapt_(T, x)

# Base integrations

adapt(T, x::RowVector) = RowVector(adapt(T, x.vec))

adapt(T, xs::Tuple) = map(x -> adapt(T, x), xs)

end # module
