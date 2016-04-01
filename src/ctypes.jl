# types from SymEngine to Julia

## XXX BROKEN!! Not sure why XXX

## CSetBasic
type CSetBasic
    ptr::Ptr{Void}
    function CSetBasic(o)
        z = new(o)
        ccall((:setbasic_new, :libsymengine), Void, (Ptr{CSetBasic},), &z)
        finalizer(z, CSetBasic_free)
        return z
    end
    CSetBasic() = CSetBasic(C_NULL)
end

CSetBasic_free(o::CSetBasic) = ccall((:setbasic_free, :libsymengine), Void, (Ptr{CSetBasic},), &o)

function CSetBasic_size(s::CSetBasic)
    a = ccall((:setbasic_size,:libsymengine), UInt32, (Ptr{CSetBasic},), &s)
    convert(Int, a)
end

function CSetBasic_get(s::CSetBasic, n::Int)
    result = Basic()
    ccall((:setbasic_get, :libsymengine), Void, (Ptr{CSetBasic}, Int, Ptr{Basic}), &s, n, &result)
    result
end


function Base.convert(::Type{Set}, x::CSetBasic)
    n = CSetBasic_size(x)
    Set([CSetBasic_get(x, i-1) for i in 1:n])
end

## VecBasic Need this for get_args...

type CVecBasic
    ptr::Ptr{Void}  
    function CVecBasic(o)
        z = new(o)
        ccall((:vecbasic_new, :libsymengine), Void, (Ptr{CVecBasic},), &z)
        finalizer(z, CVecBasic_free)
        return z
    end
    CVecBasic() = CVecBasic(C_NULL)
end


CVecBasic_free(o::CVecBasic) = ccall((:vecbasic_free, :libsymengine), Void, (Ptr{CVecBasic},), &o)


function CVecBasic_size(s::CVecBasic)
    a = ccall((:vecbasic_size, :libsymengine), UInt32, (Ptr{CVecBasic},), &s)
    convert(Int, a)
end

function CVecBasic_get(s::CVecBasic, n::Int)
    result = Basic()
    ccall((:vecbasic_get, :libsymengine), Void, (Ptr{CVecBasic}, Int, Ptr{Basic}), &s, n, &result)
    result
end

function Base.convert(::Type{Vector}, x::CVecBasic)
    n = CVecBasic_size(x)
    [CVecBasic_get(x, i-1) for i in 1:n]
end
