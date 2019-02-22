using Compat.Test
using SymEngine
import Compat.LinearAlgebra: lu, det, zeros
CDenseMatrix = SymEngine.CDenseMatrix

@vars x

# constructors
A = [x 1 2; 3 x 4; 5 6 x]
M = convert(CDenseMatrix, A)
M = CDenseMatrix(A)

# abstract interface
@test M[1,1] == A[1,1]
for i in eachindex(M)
    @test M[i] == A[i]
end
M[1,1] = x^2
@test M[1,1] == x^2
M[1,1] = x

# inherits from DenseArray
@test all(M .+ 3 .== A .+ 3)
@test all(M * 3 .== A * 3)
@test all(M + M .== A + A)
@test all(M * M .== A * A)
@test all(transpose(M) .== transpose(A))

# generic det
@test prod([subs(det(M) - det(A), x, i) == 0 for i in 2:10]) == true
@test inv(M) - inv(A) == zeros(Basic, 3,3)

# factorizations
L1, U1 = lu(M)
L2, U2, P2 = lu(A)
@test iszero(expand.(L1 - L2))
@test iszero(expand.(U1 - U2))

A = [x 1 2; 0 x 4; 0 0 x]
b = [1, 2, 3]
M = convert(CDenseMatrix, A)
out = M \ b
@test M * out - b == zeros(Basic, 3, 1)

