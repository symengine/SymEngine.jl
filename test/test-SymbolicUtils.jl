using Test
using SymEngine
import SymbolicUtils: simplify, @rule, @acrule, Chain, Fixpoint


@testset "SymbolicUtils" begin
    # from SymbolicUtils.jl docs
    # https://symbolicutils.juliasymbolics.org/rewrite/#rule-based_rewriting
    @vars w x y z
    @vars α β
    @vars a b c d

    @test simplify(cos(x)^2 + sin(x)^2) == 1

    r1 = @rule sin(2(~x)) => 2sin(~x)*cos(~x)
    @test r1(sin(2z)) == 2*cos(z)*sin(z)
    @test r1(sin(3z)) === nothing
    @test r1(sin(2*(w-z))) == 2cos(w - z)*sin(w - z)
    @test r1(sin(2*(w+z)*(α+β))) === nothing

    r2 = @rule sin(~x + ~y) => sin(~x)*cos(~y) + cos(~x)*sin(~y);
    @test r2(sin(α+β)) == sin(α)*cos(β) + cos(α)*sin(β)

    xs = @rule(+(~~xs) => ~~xs)(x + y + z) # segment variable
    @test Set(xs) == Set([x,y,z])

    r3 = @rule ~x * +(~~ys) => sum(map(y-> ~x * y, ~~ys));
    @test r3(2 * (w+w+α+β)) == 4w + 2α + 2β

    r4 = @rule ~x + ~~y::(ys->iseven(length(ys))) => "odd terms"; # Predicates for matching

    @test r4(a + b + c + d) == nothing
    @test r4(b + c + d) == "odd terms"
    @test r4(b + c + b) == nothing
    @test r4(a + b) == nothing

    sqexpand = @rule (~x + ~y)^2 => (~x)^2 + (~y)^2 + 2 * ~x * ~y
    @test sqexpand((cos(x) + sin(x))^2) == cos(x)^2 + sin(x)^2 + 2cos(x)*sin(x)

    pyid = @rule  sin(~x)^2 + cos(~x)^2  => 1
    @test_broken pyid(cos(x)^2 + sin(x)^2) === nothing  # order should matter, but this works

    acpyid = @acrule sin(~x)^2 + cos(~x)^2 => 1 # acrule is commutative
    @test acpyid(cos(x)^2 + sin(x)^2 + 2cos(x)*sin(x)) == 1 + 2cos(x)*sin(x)

    csa = Chain([sqexpand, acpyid]) # chain composes rules
    @test csa((cos(x) + sin(x))^2)  == 1 + 2cos(x)*sin(x)

    cas = Chain([acpyid, sqexpand]) # order matters
    @test cas((cos(x) + sin(x))^2) == cos(x)^2 + sin(x)^2 + 2cos(x)*sin(x)

    @test Fixpoint(cas)((cos(x) + sin(x))^2) == 1 + 2cos(x)*sin(x)

end
