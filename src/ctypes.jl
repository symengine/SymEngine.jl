# types from SymEngine to Julia
## CSetBasic
type CSetBasic
    ptr::Ptr{Void}
end

function CSetBasic()
    z = CSetBasic(ccall((:setbasic_new, :libsymengine), Ptr{Void}, ()))
    finalizer(z, CSetBasic_free)
    z
end

function CSetBasic_free(x::CSetBasic)
    if x.ptr != C_NULL
        ccall((:setbasic_free, :libsymengine), Void, (Ptr{Void},), x.ptr)
        x.ptr = C_NULL
    end
end

function Base.length(s::CSetBasic)
    ccall((:setbasic_size, :libsymengine), UInt, (Ptr{Void},), s.ptr)
end

function Base.getindex(s::CSetBasic, n::UInt)
    result = Basic()
    ccall((:setbasic_get, :libsymengine), Void, (Ptr{Void}, UInt, Ptr{Basic}), s.ptr, n, &result)
    result
end

function Base.convert(::Type{Vector}, x::CSetBasic)
    n = Base.length(x)
    [x[i-1] for i in 1:n]
end
Base.convert(::Type{Set}, x::CSetBasic) = Set(convert(Vector, x))

## VecBasic Need this for get_args...

type CVecBasic
    ptr::Ptr{Void}
end

function CVecBasic()
    z = CVecBasic(ccall((:vecbasic_new, :libsymengine), Ptr{Void}, ()))
    finalizer(z, CVecBasic_free)
    z
end

function CVecBasic_free(x::CVecBasic)
    if x.ptr != C_NULL
        ccall((:vecbasic_free, :libsymengine), Void, (Ptr{Void},), x.ptr)
        x.ptr = C_NULL
    end
end

function Base.length(s::CVecBasic)
    ccall((:vecbasic_size, :libsymengine), UInt, (Ptr{Void},), s.ptr)
end

function Base.getindex(s::CVecBasic, n::UInt)
    result = Basic()
    ccall((:vecbasic_get, :libsymengine), Void, (Ptr{Void}, UInt, Ptr{Basic}), s.ptr, n, &result)
    result
end

function Base.convert(::Type{Vector}, x::CVecBasic)
    n = Base.length(x)
    [x[i-1] for i in 1:n]
end
