# Adapt

[![Build Status](https://travis-ci.org/JuliaGPU/Adapt.jl.svg?branch=master)](https://travis-ci.org/JuliaGPU/Adapt.jl)

The `adapt(T, x)` function acts like `convert(T, x)`, but without the
restriction of returning a `T`. This allows you to "convert" wrapper types like
`Adjoint` to be GPU compatible (for example) without throwing away the wrapper.

For example:

```julia
adapt(CuArray, ::Adjoint{Array})::Adjoint{CuArray}
```

New wrapper types like `Adjoint` should overload `adapt_structure(T, ::Adjoint)`
(usually just to forward the call to `adapt`):

```julia
Adapt.adapt_structure(to, x::Adjoint) = Adjoint(adapt(to, parent(x)))
```

A similar function, `adapt_storage`, can be used to define the conversion
behavior for the innermost storage types:

```julia
adapt_storage(::Type{<:CuArray}, xs::AbstractArray) = convert(CuArray, xs)
```

Implementations of `adapt_storage` will typically be part of libraries that use
Adapt. For example, CuArrays.jl defines methods of
`adapt_storage(::Type{<:CuArray}, ...)` and uses that to convert different kinds
of arrays, while CUDAnative.jl provides implementations of
`adapt_storage(::CUDAnative.Adaptor, ...)` to convert various values to
GPU-compatible alternatives.

Packages that define new wrapper types and want to be compatible with packages
that use Adapt.jl should provide implementations of `adapt_structure` that
preserve the wrapper type. Adapt.jl already provides such methods for array
wrappers that are part of the Julia standard library.
