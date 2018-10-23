module Adapt

export adapt

# external interface
adapt(to, x) = adapt_structure(to, x)

# interface for libraries to implement
adapt_structure(to, x) = adapt_storage(to, x)
adapt_storage(to, x) = x

include("base.jl")

end # module
