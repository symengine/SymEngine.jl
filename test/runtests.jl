using Base.Test
using SymEngine

x = Sym("x")
y = Sym(:y)
@syms z

a = x^2 + x/2 - x*y*5
b = SymEngine.diff(a, x)
@test b == 2*x + 1//2 - 5*y

c = x + Rational(1, 5)
c = SymEngine.expand(c * 5)
@test c == 5*x + 1

c = x ^ 5
@test SymEngine.diff(c, x) == 5 * x ^ 4

c = x ^ y
@test c != y^x

c = Sym(-5)
@test abs(c) == 5
@test abs(c) != 4

show(a)
println()
show(b)
println()


## mathfuns
@test abs(Sym(-1)) == 1
@test sin(Sym(1)) == subs(sin(x), x, 1)
@test sin(PI) == 0
@test subs(sin(x), x, pi) == 0
@test sind(Sym(30)) == 1 // 2

## subs
ex = x^2 + y^2
@test subs(ex, x, 1) == 1 + y^2
@test subs(ex, (x, 1)) == 1 + y^2
@test subs(ex, x => 1) == 1 + y^2
@test subs(ex, (x,1), (y,2)) == 1 + 2^2
@test subs(ex, x => 1, y => 2) == 1 + 2^2


## type information
a = Sym(1)
b = Sym(1//2)
@test isa(a+a, SymEngine.BasicInteger)
@test isa(a+b, SymEngine.BasicRational)
