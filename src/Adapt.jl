module Adapt

export adapt, AbstractAdaptor

abstract type AbstractAdaptor end

# external interface
adapt(A::AbstractAdaptor, x) = adapt_structure(A, x)

# interface for libraries to implement
adapt_structure(A::AbstractAdaptor, x) = adapt_storage(A, x)
adapt_storage(::AbstractAdaptor, x) = x

include("base.jl")

end # module
