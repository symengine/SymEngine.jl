using Test
using SymEngine
import LinearAlgebra: lu, det, zeros, dot
CDenseMatrix = SymEngine.CDenseMatrix

@vars x y

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

@test SymEngine.dense_matrix_eye(2,2,0) == Basic[1 0; 0 1]

# dot product
@test dot(x, x) == x^2
@test dot([1, x, 0], [y, -2, 1]) == y - 2x

@testset "dense matrix" begin
    @vars a b c d x y
    A = [a b; c d]
    B = [x, y]
    res = A \ B
    @test res == [(x - b*(y - c*x/a)/(d - b*c/a))/a,
           (y - c*x/a)/(d - b*c/a)]
end