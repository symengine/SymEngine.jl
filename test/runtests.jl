using Base.Test
using SymEngine

include("test-dense-matrix.jl")

x = symbols("x")
y = symbols(:y)
@vars z

# Check Basic conversions
@test eltype([Basic(u) for u in [1, 1/2, 1//2, pi, e]]) == Basic

# make sure @vars defines in a local scope
let
    @vars w
end
@test_throws UndefVarError isdefined(w)

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
for j in [-3, 3], p in [-5,5]
    @test mod(Basic(j), Basic(p)) == mod(j, p)
end
@test mod(Basic(10), 4) == 2               # mod(::Basic, ::Number)
@test_throws MethodError mod(10, Basic(4)) # no mod(::Number, ::Basic)
@test gcd(Basic(10), Basic(4)) == 2
@test lcm(Basic(10), Basic(4)) == 20
@test binomial(Basic(5), 2) == 10


## type information
a = Basic(1)
b = Basic(1//2)
c = Basic(0.125)
@test isa(SymEngine.BasicType(a+a), SymEngine.BasicType{Val{:Integer}})
@test isa(SymEngine.BasicType(a+b), SymEngine.BasicType{Val{:Rational}})
@test isa(SymEngine.BasicType(a+c), SymEngine.BasicType{Val{:RealDouble}})
@test isa(SymEngine.BasicType(b+c), SymEngine.BasicType{Val{:RealDouble}})
@test isa(SymEngine.BasicType(c+c), SymEngine.BasicType{Val{:RealDouble}})

## can we do math with items of BasicType?
a1 = SymEngine.BasicType(a)
tot = a1
for i in 1:100  tot = tot + a1 end
@test tot == 101
sin(a1)

# samples of different types:
# (Int, Rational{Int}, Complex{Int}, Float64, Complex{Float64})
samples = (1, 1//2, (1 + 2im), 1.0, (1.0 + 0im))
## subs - check all different syntaxes and types
ex = x^2 + y^2
for val in samples
    @test subs(ex, x, val) == val^2 + y^2
    @test subs(ex, (x, val)) == val^2 + y^2
    @test subs(ex, x => val) == val^2 + y^2
end
# This probably results in a number of redundant tests (operator order).
for val1 in samples, val2 in samples
    @test subs(ex, (x, val1), (y, val2)) == val1^2 + val2^2
    @test subs(ex, x => val1, y => val2) == val1^2 + val2^2
end

## lambidfy
@test_approx_eq lambdify(sin(Basic(1))) sin(1)
@test_approx_eq lambdify(exp(PI/2*x))(1) exp(pi/2)
for val in samples
    ex = sin(x + val)
    @test_approx_eq lambdify(ex)(val) sin(2*val)
end

## N
for val in samples
    @test N(Basic(val)) == val
end

## generic linear algebra
x = symbols("x")
A = [x 2; x 1]
@test det(A) == -x
@test det(inv(A)) == - 1/x
(A \ [1,2])[1] == 3/x

## check that unique work (hash)
x,y,z = symbols("x y z")
@test length(SymEngine.free_symbols([x*y, y,z])) == 3
