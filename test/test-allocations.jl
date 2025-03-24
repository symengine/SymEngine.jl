# test for allocations
@vars x y
a = Basic()
@testset "non-allocating(ish) methods" begin
    sin(x), cos(x), abs(x)
    x^x, x + x, x*x, x-x, x/x # warm up

    @test (@allocations SymEngine.sin!(a,x)) == 0
    @test (@allocations SymEngine.cos!(a,x)) == 0
    @test (@allocations SymEngine.pow!(a,x,x)) == 0

    # still allocates 1 (or 2)
    @test (@allocations SymEngine.add!(a,x,y)) < (@allocations x+y)
    @test (@allocations SymEngine.sub!(a,x,y)) < (@allocations x-y)
    @test (@allocations SymEngine.mul!(a,x,y)) < (@allocations x*y)
    @test (@allocations SymEngine.div!(a,x,y)) < (@allocations x/y)
    @test (@allocations SymEngine.abs2!(a,x)) < (@allocations abs2(x))
end
