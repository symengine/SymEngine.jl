# types from SymEngine to Julia
## CSetBasic
mutable struct CSetBasic
    ptr::Ptr{Cvoid}
end

function CSetBasic()
    z = CSetBasic(ccall((:setbasic_new, libsymengine), Ptr{Cvoid}, ()))
    _finalizer(CSetBasic_free, z)
    z
end

function CSetBasic_free(x::CSetBasic)
    if x.ptr != C_NULL
        ccall((:setbasic_free, libsymengine), Nothing, (Ptr{Cvoid},), x.ptr)
        x.ptr = C_NULL
    end
end

function Base.length(s::CSetBasic)
    ccall((:setbasic_size, libsymengine), UInt, (Ptr{Cvoid},), s.ptr)
end

function Base.getindex(s::CSetBasic, n::UInt)
    result = Basic()
    ccall((:setbasic_get, libsymengine), Nothing, (Ptr{Cvoid}, UInt, Ref{Basic}), s.ptr, n, result)
    result
end

function Base.convert(::Type{Vector}, x::CSetBasic)
    n = Base.length(x)
    [x[i-1] for i in 1:n]
end
Base.convert(::Type{Set}, x::CSetBasic) = Set(convert(Vector, x))

## VecBasic Need this for get_args...

mutable struct CVecBasic
    ptr::Ptr{Cvoid}
end

function CVecBasic()
    z = CVecBasic(ccall((:vecbasic_new, libsymengine), Ptr{Cvoid}, ()))
    _finalizer(CVecBasic_free, z)
    z
end

function CVecBasic_free(x::CVecBasic)
    if x.ptr != C_NULL
        ccall((:vecbasic_free, libsymengine), Nothing, (Ptr{Cvoid},), x.ptr)
        x.ptr = C_NULL
    end
end

function Base.length(s::CVecBasic)
    ccall((:vecbasic_size, libsymengine), UInt, (Ptr{Cvoid},), s.ptr)
end

function Base.getindex(s::CVecBasic, n)
    result = Basic()
    ccall((:vecbasic_get, libsymengine), Nothing, (Ptr{Cvoid}, UInt, Ref{Basic}), s.ptr, UInt(n), result)
    result
end

function Base.convert(::Type{Vector}, x::CVecBasic)
    n = Base.length(x)
    [x[i-1] for i in 1:n]
end

start(s::CVecBasic) = 0
done(s::CVecBasic, i) = (i == Base.length(s))
next(s::CVecBasic, i) = s[i], i+1
if VERSION < v"0.7.0-rc1"
    Base.start(s::CVecBasic) = start(s)
    Base.done(s::CVecBasic, i) = done(s, i)
    Base.next(s::CVecBasic, i) = next(s, i)
else
    function Base.iterate(s::CVecBasic, i=start(s))
        done(s, i) && return nothing
        next(s, i)
    end
end

## CMapBasicBasic
mutable struct CMapBasicBasic
    ptr::Ptr{Cvoid}
end

function CMapBasicBasic()
    z = CMapBasicBasic(ccall((:mapbasicbasic_new, libsymengine), Ptr{Cvoid}, ()))
    _finalizer(CMapBasicBasic_free, z)
    z
end

function CMapBasicBasic(dict::Dict)
    c = CMapBasicBasic()
    for (key, value) in dict
        c[Basic(key)] = Basic(value)
    end
    return c
end

function CMapBasicBasic_free(x::CMapBasicBasic)
    if x.ptr != C_NULL
        ccall((:mapbasicbasic_free, libsymengine), Nothing, (Ptr{Cvoid},), x.ptr)
        x.ptr = C_NULL
    end
end

function Base.length(s::CMapBasicBasic)
    ccall((:mapbasicbasic_size, libsymengine), UInt, (Ptr{Cvoid},), s.ptr)
end

function Base.getindex(s::CMapBasicBasic, k::Basic)
    result = Basic()
    ret = ccall((:mapbasicbasic_get, libsymengine), Cint, (Ptr{Cvoid}, Ref{Basic}, Ref{Basic}), s.ptr, k, result)
    if ret == 0
        throw(KeyError("Key not found"))
    end
    result
end

function Base.setindex!(s::CMapBasicBasic, k::Basic, v::Basic)
    ccall((:mapbasicbasic_insert, libsymengine), Nothing, (Ptr{Cvoid}, Ref{Basic}, Ref{Basic}), s.ptr, k, v)
end

Base.convert(::Type{CMapBasicBasic}, x::Dict{Any, Any}) = CMapBasicBasic(x)

## Dense matrix

mutable struct CDenseMatrix <: DenseArray{Basic, 2}
    ptr::Ptr{Cvoid}
end

Base.promote_rule(::Type{CDenseMatrix}, ::Type{Matrix{T}} ) where {T <: Basic} = CDenseMatrix

function CDenseMatrix_free(x::CDenseMatrix)
    if x.ptr != C_NULL
        ccall((:dense_matrix_free, libsymengine), Nothing, (Ptr{Cvoid},), x.ptr)
        x.ptr = C_NULL
    end
end

function CDenseMatrix()
    z = CDenseMatrix(ccall((:dense_matrix_new, libsymengine), Ptr{Cvoid}, ()))
    _finalizer(CDenseMatrix_free, z)
    z
end

function CDenseMatrix(m::Int, n::Int)
    z = CDenseMatrix(ccall((:dense_matrix_new_rows_cols, libsymengine), Ptr{Cvoid}, (Int, Int), m, n))
    _finalizer(CDenseMatrix_free, z)
    z
end


function CDenseMatrix(x::Array{T, 2}) where T
    r,c = size(x)
    M = CDenseMatrix(r, c)
    for j in 1:c
        for i in 1:r ## fill column by column
            M[i,j] = x[i,j]
        end
    end
    M
end


function Base.convert(::Type{Matrix}, x::CDenseMatrix) 
    m,n = Base.size(x)
    [x[i,j] for i in 1:m, j in 1:n]
end

Base.convert(::Type{CDenseMatrix}, x::Array{T, 2}) where {T} = CDenseMatrix(x)
Base.convert(::Type{CDenseMatrix}, x::Array{T, 1}) where {T} = convert(CDenseMatrix, reshape(x, length(x), 1))


function toString(b::CDenseMatrix)
    a = ccall((:dense_matrix_str, libsymengine), Cstring, (Ptr{Cvoid}, ), b.ptr)
    string = unsafe_string(a)
    ccall((:basic_str_free, libsymengine), Nothing, (Cstring, ), a)
    string = replace(string, "**", "^") # de pythonify
    return string
end

function Base.show(io::IO, m::CDenseMatrix)
    r, c = size(m)
    println(io, "CDenseMatrix: $r x $c")
    println(io, toString(m))
end
