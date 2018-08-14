# Adapt

[![Build Status](https://travis-ci.org/JuliaGPU/Adapt.jl.svg?branch=master)](https://travis-ci.org/JuliaGPU/Adapt.jl)

The `adapt(T, x)` function acts like `convert(T, x)`, but without the restriction of returning a `T`. This allows you to "convert" wrapper types like `Adjoint` to be GPU compatible (for example) without throwing away the wrapper.

e.g.

```julia
adapt(CuArray, ::Adjoint{Array})::Adjoint{CuArray}
```

New data types like `Adjoint` should overload `adapt(T, ::Adjoint)` (usually just to forward the call to `adapt`).

```julia
adapt(T, x::Adjoint) = Adjoint(adapt(T, parent(x)))
```

New adaptor types like `CuArray` should overload `adapt_` for compatible types.

```julia
adapt_(::Type{<:CuArray}, xs::AbstractArray) =
  isbits(xs) ? xs : convert(CuArray, xs)
```
