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

## calculus
x,y = symbols("x y")
n = Basic(2)
ex = sin(x*y)
@test diff(log(x),x) == 1/x
@test diff(ex, x) == y * cos(x*y)
@test diff(ex, x, 2) == diff(diff(ex,x), x)
@test diff(ex, x, n) == diff(diff(ex,x), x)
@test diff(ex, x, y) == diff(diff(ex,x), y)
@test diff(ex, x, y,x) == diff(diff(diff(ex,x), y), x)
@test series(sin(x), x, 0, 2) == x
@test series(sin(x), x, 0, 3) == x - x^3/6
   


## ntheory
@test mod(Basic(10), Basic(4)) == 2
@test mod(Basic(10), 4) == 2               # mod(::Basic, ::Number)
@test_throws MethodError mod(10, Basic(4)) # no mod(::Number, ::Basic)
@test gcd(Basic(10), Basic(4)) == 2
@test lcm(Basic(10), Basic(4)) == 20
@test binomial(Basic(5), 2) == 10


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

## subs
ex = x^2 + y^2
@test subs(ex, x, 1) == 1 + y^2
@test subs(ex, (x, 1)) == 1 + y^2
@test subs(ex, x => 1) == 1 + y^2
@test subs(ex, (x,1), (y,2)) == 1 + 2^2
@test subs(ex, x => 1, y => 2) == 1 + 2^2

## lambidfy
@test_approx_eq lambdify(sin(Basic(1))) sin(1)
ex = sin(x)
@test_approx_eq lambdify(ex)(1) sin(1)

## N
a = Basic(1)
@test N(a) == 1
@test N(Basic(1//2)) == 1//2
@test N(Basic(12345678901234567890)) == 12345678901234567890


## generic linear algebra
x = symbols("x")
A = [x 2; x 1]
@test det(A) == -x
@test det(inv(A)) == - 1/x
(A \ [1,2])[1] == 3/x

## check that unique work (hash)
x,y,z = symbols("x y z")
@test length(SymEngine.free_symbols([x*y, y,z])) == 3
