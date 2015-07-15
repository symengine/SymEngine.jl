using Base.Test
import SymEngine

x = SymEngine.symbol("x")
y = SymEngine.symbol("y")

a = x^2 + x/2 - x*y*5
b = SymEngine.diff(a, x)
@test b == 2*x + Rational(1, 2) - 5*y

c = x + Rational(1, 5)
c = SymEngine.expand(c * 5)
@test c == 5*x + 1

c = x ^ 5
@test SymEngine.diff(c, x) == 5 * x ^ 4

c = x ^ y
@test c != y^x

c = SymEngine.Basic(-5)
@test abs(c) == 5
@test abs(c) != 4

show(a)
println()
show(b)
println()
