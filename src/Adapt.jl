module Adapt

export adapt

"""
    adapt(to, x)

Adapt a value `x` according to `to`. If no specific adaptions have been registered for `to`,
this call will be a no-op.

To alter the behavior, implement methods of `adapt_structure` and `adapt_storage` to
respectively define how to adapt structures, and the leaves of those structures.

For example, defining an adaptor for an environment where we can't have integers, and adding
a method to `adapt_storage` to appropriately convert those to floating-point numbers:

    julia> struct IntegerLessAdaptor end

    julia> Adapt.adapt_storage(::IntegerLessAdaptor, x::Int64) = Float64(x)

    julia> adapt(IntegerLessAdaptor(), 42)
    42.0

This will automatically work on known types too:

    julia> adapt(IntegerLessAdaptor(), tuple(1,2,3))
    (1.0, 2.0, 3.0)

If we want this to work with custom structures, we need to extend `adapt_structure`:

    julia> struct MyStructure
             x
           end

    julia> Adapt.adapt_structure(to, obj::MyStructure) = MyStructure(adapt(to, obj.x))

    julia> adapt(IntegerLessAdaptor(), MyStructure(42))
    MyStructure(42.0)
"""
adapt(to, x) = adapt_structure(to, x)

adapt_structure(to, x) = adapt_storage(to, x)
adapt_storage(to, x) = x

include("base.jl")
include("macro.jl")
include("wrappers.jl")

end # module
