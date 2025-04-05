using SymEngine
using LinearAlgebra
using Test

@testset "real/imag/conj deprecation" begin
    @vars x y
    # dot product
    @test dot(x, x) == x^2
    @test dot([1, x, 0], [y, -2, 1]) == y - 2x


    @vars x
    for ex = (x, x^2)
        @test real(ex) == ex
        @test_throws MethodError imag(ex)
        @test conj(ex) == ex
    end
end
