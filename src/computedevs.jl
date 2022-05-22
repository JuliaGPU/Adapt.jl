# adaptors for converting abstract arrays to Base.Array


"""
    abstract type AbstractComputingDevice

Supertype for CPU and GPU computing devices.

`adapt(dev::AbstractComputingDevice, x)` adapts `x` for `dev`.
"""
abstract type AbstractComputingDevice end
export AbstractComputingDevice


"""
    struct ComputingDeviceIndependent <: AbstractComputingDevice

`get_computing_device(x) === ComputingDeviceIndependent()` indicates
that `x` is not tied to a specific computing device. This typically
means that x is a statically allocated object.
"""
struct ComputingDeviceIndependent <: AbstractComputingDevice end
export ComputingDeviceIndependent


"""
    struct CPUDevice <: AbstractComputingDevice

`CPUDevice()` is the default CPU device.
"""
struct CPUDevice <: AbstractComputingDevice end
export CPUDevice



"""
    abstract type AbstractGPUDevice <: AbstractComputingDevice

Supertype for GPU computing devices.
"""
abstract type AbstractGPUDevice <: AbstractComputingDevice end
export AbstractGPUDevice



const _incompatible_devs = ArgumentError("Incompatible computing devices")

select_computing_device(a::ComputingDeviceIndependent, ::ComputingDeviceIndependent) = a
select_computing_device(a::ComputingDeviceIndependent, b::AbstractComputingDevice) = b
select_computing_device(a::AbstractComputingDevice, b::ComputingDeviceIndependent) = a

select_computing_device(a::CPUDevice, ::CPUDevice) = a
select_computing_device(a::CPUDevice, b::AbstractGPUDevice) = a
select_computing_device(a::AbstractGPUDevice, b::CPUDevice) = b
select_computing_device(a::AbstractGPUDevice, b::AbstractGPUDevice) = (a === b) ? a : throw(_incompatible_devs)


"""
    get_computing_device(x)::AbstractComputingDevice

Get the computing device backing object `x`.
"""
function get_computing_device end
export get_computing_device


@inline get_computing_device(::Array) = CPUDevice()

# ToDo: Utilize `ArrayInterfaceCore.buffer(A)`? Would require Adapt to depend
# on ArrayInterfaceCore.

@generated function get_computing_device(x)
    impl = :(begin dev_0 = ComputingDeviceIndependent() end)
    append!(impl.args, [:($(Symbol(:dev_, i)) = select_computing_device(get_computing_device(getfield(x, $i)), $(Symbol(:dev_, i-1)))) for i in 1:fieldcount(x)])
    push!(impl.args, :(return $(Symbol(:dev_, fieldcount(x)))))
    impl
end


adapt_storage(::CPUDevice, x) = adapt_storage(Array, x)
