using Base.Test
using SymEngine

x = symbols("x")
y = symbols(:y)
@vars z

a = x^2 + x/2 - x*y*5
b = diff(a, x)
@test b == 2*x + 1//2 - 5*y

c = x + Rational(1, 5)
c = expand(c * 5)
@test c == 5*x + 1

c = x ^ 5
@test diff(c, x) == 5 * x ^ 4

c = x ^ y
@test c != y^x

c = Basic(-5)
@test abs(c) == 5
@test abs(c) != 4

show(a)
println()
show(b)
println()


## mathfuns
@test abs(Basic(-1)) == 1
@test sin(Basic(1)) == subs(sin(x), x, 1)
@test sin(PI) == 0
@test subs(sin(x), x, pi) == 0
@test sind(Basic(30)) == 1 // 2

## subs
ex = x^2 + y^2
@test subs(ex, x, 1) == 1 + y^2
@test subs(ex, (x, 1)) == 1 + y^2
@test subs(ex, x => 1) == 1 + y^2
@test subs(ex, (x,1), (y,2)) == 1 + 2^2
@test subs(ex, x => 1, y => 2) == 1 + 2^2


## type information
a = Basic(1)
b = Basic(1//2)
@test isa(SymEngine.BasicType(a+a), SymEngine.BasicType{Val{:Integer}})
@test isa(SymEngine.BasicType(a+b), SymEngine.BasicType{Val{:Rational}})

## can we do math with items of BasicType?
a1 = SymEngine.BasicType(a)
tot = a1
for i in 1:100  tot = tot + a1 end
@test tot == 101
sin(a1)

## N, not exported. Just a test for now
a = Basic(1)
@test SymEngine.N(a) == 1
@test SymEngine.N(Basic(1//2)) == 1//2
@test SymEngine.N(Basic(12345678901234567890)) == 12345678901234567890


## generic linear algebra
x = symbols("x")
A = [x 2; x 1]
@test det(A) == -x
@test det(inv(A)) == - 1/x
(A \ [1,2])[1] == 3/x
