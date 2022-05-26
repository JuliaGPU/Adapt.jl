# adaptors for converting abstract arrays to Base.Array


"""
    abstract type AbstractComputeUnit

Supertype for arbitrary computing devices (CPU, GPU, etc.).

`adapt(dev::AbstractComputeUnit, x)` adapts `x` for `dev`.

`Sys.total_memory(dev)` and `Sys.free_memory(dev)` return the total and free
memory on the device.
"""
abstract type AbstractComputeUnit end
export AbstractComputeUnit


"""
    struct ComputingDeviceIndependent

`get_compute_unit(x) === ComputingDeviceIndependent()` indicates
that `x` is not tied to a specific computing device. This typically
means that x is a statically allocated object.
"""
struct ComputingDeviceIndependent end
export ComputingDeviceIndependent


"""
    UnknownComputeUnitOf(x)

`get_compute_unit(x) === ComputingDeviceIndependent()` indicates
that the computing device for `x` cannot be determined.
"""
struct UnknownComputeUnitOf{T}
    x::T
end


"""
    struct MixedComputeSystem <: AbstractComputeUnit

A (possibly heterogenous) system of multiple compute units.
"""
struct MixedComputeSystem <: AbstractComputeUnit end
export MixedComputeSystem


"""
    struct CPUDevice <: AbstractComputeUnit

`CPUDevice()` is the default CPU device.
"""
struct CPUDevice <: AbstractComputeUnit end
export CPUDevice

adapt_storage(::CPUDevice, x) = adapt_storage(Array, x)

Sys.total_memory(::CPUDevice) = Sys.total_memory()
Sys.free_memory(::CPUDevice) = Sys.free_memory()


"""
    abstract type AbstractComputeAccelerator <: AbstractComputeUnit

Supertype for GPU computing devices.
"""
abstract type AbstractComputeAccelerator <: AbstractComputeUnit end
export AbstractComputeAccelerator


"""
    abstract type AbstractGPUDevice <: AbstractComputeAccelerator

Supertype for GPU computing devices.
"""
abstract type AbstractGPUDevice <: AbstractComputeAccelerator end
export AbstractGPUDevice


merge_compute_units() = ComputingDeviceIndependent()

@inline function merge_compute_units(a, b, c, ds::Vararg{Any,N}) where N
    a_b = merge_compute_units(a,b)
    return merge_compute_units(a_b, c, ds...)
end

@inline merge_compute_units(a::UnknownComputeUnitOf, b::UnknownComputeUnitOf) = a
@inline merge_compute_units(a::UnknownComputeUnitOf, b::Any) = a
@inline merge_compute_units(a::Any, b::UnknownComputeUnitOf) = b

@inline function merge_compute_units(a, b)
    return (a === b) ? a : compute_unit_mergeresult(
        compute_unit_mergerule(a, b),
        compute_unit_mergerule(b, a),
    )
end

struct NoCUnitMergeRule end

@inline compute_unit_mergerule(a::Any, b::Any) = NoCUnitMergeRule()
@inline compute_unit_mergerule(a::UnknownComputeUnitOf, b::Any) = a
@inline compute_unit_mergerule(a::UnknownComputeUnitOf, b::UnknownComputeUnitOf) = a
@inline compute_unit_mergerule(a::ComputingDeviceIndependent, b::Any) = b

@inline compute_unit_mergeresult(a_b::NoCUnitMergeRule, b_a::NoCUnitMergeRule) = MixedComputeSystem()
@inline compute_unit_mergeresult(a_b, b_a::NoCUnitMergeRule) = a_b
@inline compute_unit_mergeresult(a_b::NoCUnitMergeRule, b_a) = b_a
@inline compute_unit_mergeresult(a_b, b_a) = a_b === b_a ? a_b : MixedComputeSystem()


"""
    get_compute_unit(x)::Union{
        AbstractComputeUnit,
        ComputingDeviceIndependent,
        UnknownComputeUnitOf
    }

Get the computing device backing object `x`.

Don't specialize `get_compute_unit`, specialize
[`Adapt.get_compute_unit_impl`](@ref) instead.
"""
get_compute_unit(x) = get_compute_unit_impl(Union{}, x)
export get_compute_unit


"""
    get_compute_unit_impl(::Type{TypeHistory}, x)::AbstractComputeUnit

See [`get_compute_unit_impl`](@ref).

Specializations that directly resolve the compute unit based on `x` can
ignore `TypeHistory`:

```julia
Adapt.get_compute_unit_impl(@nospecialize(TypeHistory::Type), x::SomeType) = ...
```
"""
function get_compute_unit_impl end


@inline get_compute_unit_impl(@nospecialize(TypeHistory::Type), ::Array) = CPUDevice()

# Guard against object reference loops:
@inline get_compute_unit_impl(::Type{TypeHistory}, x::T) where {TypeHistory,T<:TypeHistory} = begin
    UnknownComputeUnitOf(x) 
end

@generated function get_compute_unit_impl(::Type{TypeHistory}, x) where TypeHistory
    if isbitstype(x)
        :(ComputingDeviceIndependent())
    else
        NewTypeHistory = Union{TypeHistory, x}
        impl = :(begin dev_0 = ComputingDeviceIndependent() end)
        append!(impl.args, [:($(Symbol(:dev_, i)) = merge_compute_units(get_compute_unit_impl($NewTypeHistory, getfield(x, $i)), $(Symbol(:dev_, i-1)))) for i in 1:fieldcount(x)])
        push!(impl.args, :(return $(Symbol(:dev_, fieldcount(x)))))
        impl
    end
end
