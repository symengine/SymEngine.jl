using SymEngine
using Compat
using Test
using Serialization
import Base: MathConstants.γ, MathConstants.e, MathConstants.φ, MathConstants.catalan

VERSION >= v"1.9" && include("test-SymbolicUtils.jl")
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
@test repr(Basic()) == "<Unitialized Basic value>"

# test @vars constructions
@vars a, b[0:4], c(), d=>"D"
@test length(b) == 5
@test isa(c, SymFunction)
@test repr(d) == "D"

a = x^2 + x/2 - x*y*5
b = diff(a, x)
@test b == 2*x + 1//2 - 5*y

c = x + Rational(1, 5)
c = expand(c * 5)
@test c == 5*x + 1

c = sum(convert(SymEngine.CVecBasic, [x, x, 1]))
@test c == 2*x + 1
@test x + x + 1 == 2*x + 1
@test x + 1 + 1 == x + 2
@test 1 + x + 1 == x + 2

c = prod(convert(SymEngine.CVecBasic, [x, x, 2]))
@test c == 2*x^2
@test x * x * 2 == 2*x^2
@test x * 2 * 3 == 6 * x
@test 2 * 3 * x == 6 * x
@test 2 * x * 3 == 6 * x
@test 3 * 2 * x == 6 * x

# https://github.com/symengine/SymEngine.jl/issues/259
@testset "Issue #259" begin
    let (a, b, c) = symbols("a b c")
        @test a * [b, c] == [a * b, a * c]
        @test a * 1//3 * [b, c] == [a * b / 3, a * c / 3]
        @test a * 1//3 * 3//4 * [b, c] == [a * b / 4, a * c / 4]
        @test a * 1//3 * 3//4 * 4//5 * [b, c] == [a * b / 5, a * c / 5]
    end
end

c = x ^ 5
@test diff(c, x) == 5 * x ^ 4

c = x ^ y
@test c != y^x

c = Basic(-5)
@test abs(c) == 5
@test abs(c) != 4

repr("text/plain", a) == (1/2)*x - 5*x*y + x^2
repr("text/plain", b) == 1/2 + 2*x - 5*y

@test 1 // x == 1 / x
@test x // 2 == (1//2) * x
@test x // y == x / y


## mathfuns
@test abs(Basic(-1)) == 1
@test sin(Basic(1)) == subs(sin(x), x, 1)
@test sin(PI) == 0
@test subs(sin(x), x, pi) == 0
@test sind(Basic(30)) == 1 // 2

## predicates
@vars x
u,v,w = x(2.1), x(1), x(0)
@test isreal(u)
@test !isinteger(u)
@test isinteger(v)
@test isone(v)
@test iszero(w)
@test (@allocated isreal(u)) == 0
@test (@allocated isinteger(v)) == 0
@test (@allocated isone(x)) == 0
@test (@allocated iszero(x)) == 0
@test (@allocated isone(v)) > 0 # checking v==zero(v) value allocates
@test (@allocated iszero(w)) > 0

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
for i in 1:100
    global tot
    tot = tot + a1
end
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
    @test subs(ex, SymEngine.CMapBasicBasic(Dict(x=>val))) == val^2 + y^2
    @test subs(ex, Dict(x=>val)) == val^2 + y^2
    @test subs(ex) == ex
end
# This probably results in a number of redundant tests (operator order).
for val1 in samples, val2 in samples
    @test subs(ex, (x, val1), (y, val2)) == val1^2 + val2^2
    @test subs(ex, x => val1, y => val2) == val1^2 + val2^2
end

## lambidfy
@test abs(lambdify(sin(Basic(1))) - sin(1)) <= 1e-14
fn = lambdify(exp(PI/2*x))
@test abs(fn(1) - exp(pi/2)) <= 1e-14
for val in samples
    ex2 = sin(x + val)
    fn2 = lambdify(ex2)
    @test abs(fn2(val) - sin(2*val)) <= 1e-14
end
@test lambdify(x^2)(3) == 9

A = [x 2; x 1]
@test lambdify(A, [x])(0) == [0 2; 0 1]
@test lambdify(A)(0) == [0 2; 0 1]
A = [x 2]
@test lambdify(A, [x])(1) == [1 2]
@test lambdify(A)(1) == [1 2]
@test isa(convert.(Expr, [0 x x+1]), Array{Expr})

## N
for val in samples
    @test N(Basic(val)) == val
end

for val in [π, γ, e, φ, catalan]
    @test N(Basic(val)) == val
end

@test !isnan(x)
@test isnan(Basic(0)/0)

## generic linear algebra
x = symbols("x")
A = [x 2; x 1]
#@test det(A) == -x
#@test det(inv(A)) == - 1/x
#(A \ [1,2])[1] == 3/x

## check that unique work (hash)
x,y,z = symbols("x y z")
@test length(SymEngine.free_symbols([x*y, y,z])) == 3

# is/has/free symbol(s)
@vars x y z
@test SymEngine.is_symbol(x)
@test (@allocated SymEngine.is_symbol(x)) == 0
@test !SymEngine.is_symbol(x(2))
@test !SymEngine.is_symbol(x^2)
@test SymEngine.has_symbol(x^2, x)
@test SymEngine.has_symbol(x, x)
@test @allocated(SymEngine.has_symbol(x, x)) == 0
@test SymEngine.has_symbol(sin(sin(sin(x))), x)
@test !SymEngine.has_symbol(x^2, y)
@test Set(free_symbols(x*y)) == Set([x,y])
@test Set(free_symbols(x*y^z)) != Set([x,y])

# call without specifying variables
@vars x y
z = x(2)
@test x(2) == 2
@test (x*y^2)(1,2) == subs(x*y^2, x=>1, y=>2) == (x*y^2)(x=>1, y=>2)
@test z() == 2
@test z(1) == 2

## check that callable symengine expressions can be used as functions for duck-typed functions
@vars x
function simple_newton(f, fp, x0)
    x = float(x0)
    while abs(f(x)) >= 1e-14
        x = x - f(x)/fp(x)
    end
    x
end
@test abs(simple_newton(sin(x), diff(sin(x), x), 3) - pi) <= 1e-14

## Check conversions SymEngine -> Julia
z,flt, rat, ima, cplx = btypes = [Basic(1), Basic(1.23), Basic(3//5), Basic(2im), Basic(1 + 2im)]

@test Int(z) == 1
@test BigInt(z) == 1
@test Float64(flt) ≈ 1.23
@test Real(flt) ≈ 1.23
@test convert(Rational{Int}, rat) == 3//5
@test convert(Complex{Int}, ima) == 2im
@test convert(Complex{Int}, cplx) == 1 + 2im
@test isinf(convert(Float64, oo))
@test isnan(convert(Float64, NAN))

@test_throws InexactError convert(Int, flt)
@test_throws InexactError convert(Int, rat)

x = symbols("x")
Number[1 2 3 x]
@test_throws ArgumentError Int[1 2 3 x]

t = BigFloat(1.23)
@test !SymEngine.have_component("mpfr") || t == convert(BigFloat, convert(Basic, t))

@test typeof(N(Basic(-1))) != BigInt

# Check that libversion works. VersionNumber should always be >= 0.2.0
# since 0.2.0 is the first public release
@test SymEngine.libversion >= VersionNumber("0.2.0")

# Check that constructing Basic from Expr works
@vars x y
@test Basic(:(-2*x)) == -2*x
@test Basic(:(-3*x*y)) == -3*x*y
@test Basic(:((x-y)*-3)) == (x-y)*(-3)
@test Basic(:(-y)) == -y
@test Basic(:(-2*(x-2*y))) == -2*(x-2*y)

@test Basic(0)/0 == NAN
@test subs(1/x, x, 0) == Basic(1)/0

d = Dict(x=>y, y=>x)
@test subs(x + 2*y, d) == y + 2*x

@test sin(x+PI/4) != sin(x)
@test sin(PI/2-x) == cos(x)

f = SymFunction("f")
@test string(f(x, y)) == "f(x, y)"
@test string(f([x, y])) == "f(x, y)"
@test string(f(2*x)) == "f(2*x)"

@funs g, h
@test string(g(x, y)) == "g(x, y)"
@test string(h(x, y)) == "h(x, y)"

# Function symbols
@funs f, g, h, s
@vars n, m
expr = Basic("f(n) + f(n+1) + g(m)^2 - 3*h(n)*s(n)^3")
@test function_symbols(expr) == [h(n), f(n), s(n), g(m), f(n+1)]
@test get_name(f(n+1)) == "f"
@test get_args(f(n+1)) == [n+1]
@test get_args(f(n, m^2)) == [n, m^2]

# Coefficients
@vars x y
expr = x^3 + 3*x^2*y + 3*x*y^2 + y^3 + 1
@test coeff(expr, x, Basic(3)) == 1
@test coeff(expr, x, Basic(2)) == 3*y
@test coeff(expr, x, Basic(1)) == 3*y^2
@test coeff(expr, x, Basic(0)) == y^3 + 1

# Check that infinities are handled correctly
@test_throws DomainError exp(zoo)
@test_throws DomainError sin(zoo)
@test_throws DomainError sin(oo)
@test_throws DomainError subs(sin(log(y - y/x)), x => 1)
@test_throws DomainError exp(zoo+x)/exp(x)

# Some basic checks for complex numbers
@testset "Complex numbers" begin
    for T in (Int, Float64, BigFloat)
        j = one(T) * IM
        @test j == imag(j) * IM
        @test conj(j) == -j
    end
end

@test round(Basic(3.14)) == 3.0
@test round(Basic(3.14); digits=1) == 3.1

function is_serialization_correct(expr :: Basic)
	iobuf = IOBuffer()
	serialize(iobuf, expr)
	seek(iobuf, 0)
	deserialized = deserialize(iobuf)
	close(iobuf)
	return expr == deserialized
end

@vars x y
@testset "Serialization and deserialization" begin
	@test is_serialization_correct(Basic(1.0))
	@test is_serialization_correct(Basic(pi))
	@test is_serialization_correct(Basic(x + y))
	@test is_serialization_correct(Basic(sin(cos(pi*x + y)) + y^2))

	# Complex type test
	iobuf = IOBuffer()
	data = [x+y, x+y]
	serialize(iobuf, data)
	seek(iobuf, 0)
	deserialized = deserialize(iobuf)
	close(iobuf)
	@test deserialized == data
end

VERSION >= v"1.9.0" && include("test-allocations.jl")
