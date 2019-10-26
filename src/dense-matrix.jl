## Dense matrix interface

dense_matrix_rows(s::CDenseMatrix) = ccall((:dense_matrix_rows, libsymengine), Int, (Ptr{Cvoid}, ), s.ptr)
dense_matrix_cols(s::CDenseMatrix) = ccall((:dense_matrix_cols, libsymengine), Int, (Ptr{Cvoid}, ), s.ptr)
function dense_matrix_rows_cols(mat::CDenseMatrix, r::UInt, c::UInt)
    ccall((:dense_matrix_rows_cols, libsymengine), Int, (Ptr{Cvoid}, UInt, UInt), s.ptr, r, c)
end


function dense_matrix_get_basic(s::CDenseMatrix, r::Int, c::Int)
    result = Basic()
    ccall((:dense_matrix_get_basic, libsymengine), Nothing, (Ref{Basic}, Ptr{Cvoid}, UInt, UInt), result, s.ptr, UInt(r), UInt(c))
    result
end


function dense_matrix_set_basic(s::CDenseMatrix, val, r::Int, c::Int)
    value = Basic(val)
    ccall((:dense_matrix_set_basic, libsymengine), Nothing, (Ptr{Cvoid}, UInt, UInt, Ref{Basic}), s.ptr, UInt(r), UInt(c), value)
    value
end



## Basic operations det, inv, transpose
function dense_matrix_det(s::CDenseMatrix)
    result = Basic()
    ccall((:dense_matrix_det, libsymengine), Nothing, (Ref{Basic}, Ptr{Cvoid}), result, s.ptr)
    result
end
function dense_matrix_inv(s::CDenseMatrix)
    result = CDenseMatrix()
    ccall((:dense_matrix_inv, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}), result.ptr, s.ptr)
    result
end


function dense_matrix_transpose(s::CDenseMatrix)
    result = CDenseMatrix()
    ccall((:dense_matrix_transpose, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}), result.ptr, s.ptr)
    result
end

function dense_matrix_submatrix(mat::CDenseMatrix, r1::Int, c1::Int, r2::Int, c2::Int, r::Int, c::Int)
    s = CDenseMatrix()
    ccall((:dense_matrix_inv, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, UInt, UInt, UInt, UInt, UInt, UInt),
          s.ptr, mat.ptr, UInt(r1), UInt(c1), UInt(r2), UInt(c2), UInt(r), UInt(c))
    s
end


## some matrix arithmetic methods
## These are unncecessary, as +,-,*,^ are inhertied by the AbstractArray Interface. Those return Array{Basic,2}. These
## return CDenseMatrix objects.
function dense_matrix_add_matrix(a::CDenseMatrix, b::CDenseMatrix)
    result = CDenseMatrix()
    ccall((:dense_matrix_add_matrix, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), result.ptr, a.ptr, b.ptr)
    result
end


function dense_matrix_mul_matrix(a::CDenseMatrix, b::CDenseMatrix)
    result = CDenseMatrix()
    ccall((:dense_matrix_mul_matrix, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), result.ptr, a.ptr, b.ptr)
    result
end

function dense_matrix_add_scalar(a::CDenseMatrix, b::Basic)
    result = CDenseMatrix()
    ccall((:dense_matrix_add_scalar, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), result.ptr, a.ptr, b.ptr)
    result
end


function dense_matrix_mul_scalar(a::CDenseMatrix, b::Basic)
    result = CDenseMatrix()
    ccall((:dense_matrix_mul_scalar, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), result.ptr, a.ptr, b.ptr)
    result
end


## Factorizations ##################################################
function dense_matrix_LU(mat::CDenseMatrix)
    ## need square?
    L = CDenseMatrix()
    U = CDenseMatrix()
    ccall((:dense_matrix_LU, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), L.ptr, U.ptr,  mat.ptr)
    (L, U)
end

## LDL decomposition
function dense_matrix_LDL(mat::CDenseMatrix)
    L = CDenseMatrix()
    D = CDenseMatrix()
    ccall((:dense_matrix_LDL, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), L.ptr, D.ptr,  mat.ptr)
    (L, D)
end

##  Fraction free LU factorization
function dense_matrix_FFLU(mat::CDenseMatrix)
    LU = CDenseMatrix()
    ccall((:dense_matrix_FFLU, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}), LU.ptr, mat.ptr)
    LU
end

## Fraction free LDU factorization
function dense_matrix_FFLDU(mat::CDenseMatrix)
    L = CDenseMatrix()
    D = CDenseMatrix()
    U = CDenseMatrix()
    
    ccall((:dense_matrix_FFLDU, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), L.ptr, D.ptr, U.ptr, mat.ptr)
    (L, D, U)
end

function dense_matrix_LU_solve(A::CDenseMatrix, b::CDenseMatrix)
    x = CDenseMatrix()
    ccall((:dense_matrix_LU_solve, libsymengine), Nothing, (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}), x.ptr, A.ptr, b.ptr)
    x
end


function dense_matrix_zeros(::Type{CDenseMatrix}, r::Int, c::Int)
    result = CDenseMatrix()
    ccall((:dense_matrix_zeros, libsymengine), Nothing, (Ptr{Cvoid}, UInt, UInt), result.ptr, UInt(r), UInt(c))
    result
end


function dense_matrix_ones(r::Int, c::Int)
    result = CDenseMatrix()
    ccall((:dense_matrix_ones, libsymengine), Nothing, (Ptr{Cvoid}, UInt, UInt), result.ptr, UInt(r), UInt(c))
    result
end

## dense_matrix_diag XXX don't have CVecBasic constructor

function dense_matrix_eye(N::Int, M::Int, k::Int=0)
    s = CDenseMatrix()
    ccall((:dense_matrix_eye, libsymengine), Nothing, (Ptr{Cvoid}, UInt, UInt, Int), s.ptr, UInt(N), UInt(M), k)
    s
end

dense_matrix_eq(a::CDenseMatrix, b::CDenseMatrix) = ccall((:dense_matrix_eq, libsymengine), Int, (Ptr{Cvoid},Ptr{Cvoid}), a.ptr, b.ptr)

## Plug into Julia's interface ##################################################

import Base: ==
==(a::CDenseMatrix, b::CDenseMatrix)  = dense_matrix_eq(a, b) == 1

## Abstract Array Interface
Base.size(s::CDenseMatrix) = (dense_matrix_rows(s), dense_matrix_cols(s))
Base.getindex(s::CDenseMatrix, r::Int, c::Int) = dense_matrix_get_basic(s, r-1, c-1)
Base.setindex!(s::CDenseMatrix, val, r::Int, c::Int) = dense_matrix_set_basic(s, val, r-1, c-1)

## special matrices
Base.zeros(::Type{CDenseMatrix}, r::Int, c::Int) = dense_matrix_zeros(s, r-1, c-1)
Base.ones(::Type{CDenseMatrix}, r::Int, c::Int) = dense_matrix_ones(r-1, c-1)


## basic functions
LinearAlgebra.det(s::CDenseMatrix) = dense_matrix_det(s)
Base.inv(s::CDenseMatrix) = dense_matrix_inv(s)
Base.transpose(s::CDenseMatrix) = dense_matrix_transpose(s)

LinearAlgebra.factorize(M::CDenseMatrix) = factorize(convert(Matrix, M))

"""
LU decomposition for CDenseMatrix, dense matrices of symbolic values

Also: lufact(a, val{:false}) for non-pivoting lu factorization
"""
function LinearAlgebra.lu(a::CDenseMatrix)
    l, u = dense_matrix_LU(a)
    convert(Matrix, l), convert(Matrix, u), Matrix{Basic}(LinearAlgebra.I, size(l)[1], size(l)[1])
end

if VERSION < VersionNumber("0.7.0-DEV")
    LinearAlgebra.lu(a::Array{T,2}) where {T <: Basic} = LinearAlgebra.lu(convert(CDenseMatrix, a))
end


# solve using LU_solve
import Base: \
\(A::CDenseMatrix, b::CDenseMatrix) = dense_matrix_LU_solve(A, b)
\(A::CDenseMatrix, b::Vector) = A \ convert(CDenseMatrix, [convert(Basic,u) for u in b])
    
