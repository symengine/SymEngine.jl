# Basic usage

Julia wrappers for [SymEngine](https://github.com/symengine/symengine), a fast symbolic manipulation library, written in C++.

To begin, we load the package, as any other:

```@example symengine
using SymEngine
```

## Working with scalar variables

### Defining variables

One can define variables in a few ways. For interactive use, the `@vars` macro proves useful, creating the variable(s) in the local scope:

```@example symengine
@vars a b
```

The `@vars` macro can also be used to define collections of variables and symbolic functions.

The `symbols` constructor can be used as well, it takes a symbol or string and returns a symbolic variable with the expected name. A string with spaces is split to allow the specification of multiple variables.

```@example symengine
a = symbols(:a)
b = symbols(:b)
nothing # hide
```

```@example symengine
a,b = symbols("a b")
```


### Symbolic expressions

Symbolic expressions are built up from symbolic variables and numbers by calling many generic Julia functions.

This command defines an expression using the variables from earlier:

```@example symengine
ex1 = a + 2(b+2)^2 + 2a + 3(a+1)
```

One can see that like values are grouped, but no expansion is done.



#### Mathematical operations

The last example shows that the basic math operations have methods to work with symbolic expressions. The same is the case for many of Julia's generic [mathematical operations](https://docs.julialang.org/en/v1/manual/mathematical-operations/).

```@example symengine
@vars x
ex = sin(x)^2 - x*tanh(exp(x))
```

#### The `Basic` type

The `Basic` type is a wrapper that holds a pointer to the underlying symengine object. In the examples above, both `x`, a variable, and `ex`, an expression, are of type `Basic`, though `x` has an internal type `:Symbol` and `ex` an internal type `:Add`. The `Basic` type constructor can also be used for the construction of numeric symbols, numeric expressions, and numeric numbers. For example,

```@example symengine
n = Basic(10)
```


## Working with vector and matrix variables

### The `@vars` macro

The `@vars` macro allows indexing notation to define vectors or more general arrays:

```@example symengine
@vars x[1:2] A[1:2, 1:2]
```

Indices may have offsets

```@example symengine
@vars y[-2:2]
```

The indices passed to `@vars` must be numeric literals.

### Using `symbols`

A vector of variables can also be defined using list comprehension and string interpolation. This allows for runtime-determination of size:

```@example symengine
n = 4
[symbols("α_$i") for i in 1:n]
```

One can also use a matrix comprehension and string interpolation to create matrices:

```@example symengine
W = [symbols("W_$(i)_$(j)") for i in 1:3, j in 1:4]
```

### Matrix-vector multiplication

The above create Julia vectors and  matrices with symbolic components. The usual generic matrix operations can be employed. For example:


```@example symengine
@vars x[1:2] A[1:3,1:2]
A * x
```

### The `CDenseMatrix` class

The `symengine` library provides a method for LU decomposition. It can be called on a matrix of `Basic` values, which is converted to an internal `CDenseMatrix` type that can be passed to the underlying symengine function.

```@example symengine
@vars a x
A = [x (1 + a*x); x (1+a^2*x)]
using LinearAlgebra
lu(A)
```

Linear symbolic equations can be solved using `\`:

```@example symengine
@vars A[1:2, 1:2] x[1:2]
A \ x
```

Again, this dispatches to a symengine call.

An inverse can be found

```@example symengine
@vars x
A = [1 x; 2 x^2]
inv(A)
```

as can determinants, transposes, and adjoints

```@example symengine
det(A)
```

```@example symengine
A = [im x; 2im x^2]
transpose(A)
```

```@example symengine
A'
```

## Symbolic operations

### `as_numer_denom`, `coeff`

The function `as_numer_denom` takes a fractional expression and returns the numerator and denominator:

```@example symengine
@vars x y
ex = (exp(x) - 1) / x
SymEngine.as_numer_denom(ex)
```

The `coeff` function returns the coefficient of specific power of a symbolic variable:

```@example symengine
@vars a b c x
p = a + b*x + c*x^2
[SymEngine.coeff(p, x, i) for i in 0:2]
```

### `expand`

The `expand` method is used to multiply out terms in a product:

```@example symengine
expand(a + 2(b+2)^2 + 2a + 3(a+1))
```

The `expand`ed expression collects like terms, so may lead to a simplification:

```@example symengine
expand((x + 1)*(x - 2) - (x - 1)*x)
```

The `expand` function is much more performant than that in `Symbolics` -- this function, returning 8436 summands, runs about five times faster:

```@example symengine
function expand_test(a,b,c)
    x = expand(((a+b+c+1)^20))
    y = expand(((a+b+c+1)^15))
    z = expand(x*y)
end
nothing # hide
```


### `subs`

The `subs` methods allows for substitution of parts of the expression tree with other expressions:

```@example symengine
subs(a^2 + (b-2)^2, b=>a)
```

```@example symengine
subs(a^2 + (b-2)^2, b=>2)
```

```@example symengine
subs(a^2 + (b-2)^2, a=>2)
```

```@example symengine
subs(a^2 + (b-2)^2, a^2=>2)
```

```@example symengine
subs(a^2 + (b-2)^2, a=>2, b=>3)
```

The `k=>v` pair notation is used to specify what is to be substituted (`k`) and with what (`v`). As seen, both can be expressions and not just variables.

The `call` method for symbolic expressions dispatches to `subs` and can be called with pairs, as above, or just values. When just values are passed, they are paired with the values returned by `free_symbols`:

```@example symengine
@vars x y z
ex = x * y^2 * z^3
ex(2,3,4) == ex(x=>2, y=>3, z=>4) == ex(Pair.(free_symbols(ex), (2,3,4))...)
```

### `diff`

The `diff` function performs symbolic differentiation.

```@example symengine
diff(a + 2(b+2)^2 + 2a + 3(a+1), b)
```

Higher-order derivatives can be specified with a number

```@example symengine
@vars x
ex = sin(sin(x))
diff(ex, x, 3)
```

Mixed derivatives can be found:

```@example symengine
@vars a b x y
ex = a*x*y^2 + b*x^2*y
diff(ex, x, x, y) # also diff(ex, x, 2, y 1) does 2 in x one in y
```


Symbolic functions can be defined and differentiated

```@example symengine
@vars x f()
diff(f(x), x)
```

The derivative operation in `SymEngine` is more performant than that from `Symbolics` -- this function, which returns 744 summands, for `D=diff` is orders of magnitude faster than for `D=Symbolics.derivative`:

```@example symengine
function diff_test(D, x)
    expr = sin(sin(sin(sin(x))));
    for i = 1:10
        expr = D(expr, x)
    end
    expr
end
nothing # hide
```




## Numeric values

There are a number of built-in constants holding symbolic values including: `PI`, `E`, `IM`, `oo`, `zoo`, `NAN`.

As well, symbolic numbers may be produced through substitution or directly through the `Basic` constructor:

```@example symengine
x = Basic(1)
x/2
```

To convert a symbolic value to a value in `julia` can be done through the `N` function, which attempts to identify a matching type:

```@example symengine
N(x), N(x/2), N(PI)
```

The `float` method will convert the symbolic value to a floating point number:

```@example symengine
float(x), float(x/2), float(PI)
```

The `SymEngine.evalf` function does this conversion within symengine, whereas `float` first attempts to identify an appropriate Julia type through a call to `N` before then calling `float`.

To create a Julia function from an expression it is possible to use something like `x -> float(ex)`, but more idiomatically, `lambdify` would be used:

```@example symengine
@vars x
ex = x * tanh(exp(x))
l = lambdify(ex)
typeof(ex(1)), typeof(l(1))
```

The recipe for `Plots` just wraps an expression with `lambdify`.


Other generic methods in Julia work on symbolic numbers, but not expressions, including: `real`, `imag`, `trunc`, and `round`. For some numeric expressions, first calling `N` then calling one of these functions is needed.


## Introspection

There are various methods allowing the introspection of symbolic values

* `SymEngine.is_constant(ex)` checks if the expression contains any free symbol; return `false` if so.

* `SymEngine.has_symbol(ex,x)` checks if symbolic expression contains the specific symbol.

* `free_symbols(ex)` returns all the symbols in an expression. The `SymEngine.function_symbols` returns symbolic functions, such as defined by `@vars f()`.

* `SymEngine.get_args(ex)` returns the arguments of a given expression; returning an empty vector if the expression has no arguments.

* There are several predicate functions for checking the storage type of a symbolic number: `SymEngine.is_a_Number`, `SymEngine.is_a_Integer`,  `SymEngine.is_a_Rational`, `SymEngine.is_a_RealDouble`, `SymEngine.is_a_RealMPFR`, `SymEngine.is_a_Complex`, `SymEngine.is_a_ComplexDouble`, `SymEngine.is_a_ComplexMPC`. Importantly, these do not apply to a constant symbolic expression. That is, a test like `SymEngine.is_a_Number(1 + exp(Basic(1)))` will be `false`.

* Several generic predicate functions, `iszero`, `isone`, `isinteger`, `isreal`, `isfinite`, `isinf`, and `isnan`.

These are imperfect; it may be better to use `N` to return a numeric value in Julia and call their counterpart. Even then, symbolic numeric expressions may be subject to floating point roundoff that masks the true mathematical nature.

There are also methods to inspect the type that symengine uses to store an expression.

* `SymEngine.get_type` returns an unsigned integer uniquely identifying the type

* `SymEngine.get_symengine_class` returns a symbol representing the top-most operation or storage type of the object in symengine.

* `SymEngine.get_julia_class` returns a symbol representing the Julia type of the top-most operation or storage type of the object in symengine.

If `TermInterface` is loaded (below), the `operation` method returns the outermost function for a given expression.


##  Basic variables are mutable

The `Basic` type is a Julia type wrapping an underlying symengine object. When a Julia method is called on symbolic objects, the method almost always resolves to some call (via `ccall`) into the `libsymengine` C++ library. The design typically involves mutating a newly constructed `Basic` variable. Some allocations can be saved by calling the mutating version of the operations:

```julia
@vars x
a = Basic()
SymEngine.sin!(a, x)
a
```

Other types that may be useful to minimize allocations are `SymEngine.CSetBasic` and `SymEngine.CVecBasic`.

## Use with `TermInterface`

There is an extension for `TermInterface`. The `TermInterface` package allows general symbolic expression manipulation. This example shows how some of the functionality of `subs` can be programmed using the package's interface.

```@example symengine
using TermInterface

function map_matched(x, is_match, f)
    if SymEngine.is_symbol(x)
        return is_match(x) ? f(x) : x
    end

    is_match(x) && return f(x)
    iscall(x) || return x
    children = map_matched.(arguments(x), is_match, f)
    maketerm(Basic, operation(x), children, nothing)
end

replace_exact(ex, p, q) = map_matched(ex, ==(p), _ -> q)

function replace_head(ex, u, v)
    !iscall(ex) && return ex
    args′ = (replace_head(a, u, v) for a ∈ arguments(ex))
    op = operation(ex)
    λ = op == u ? v : op
    ex = maketerm(Basic, λ, args′, nothing)
end
nothing # hide
```

```@example symengine
@vars x u
replace_exact(sin(x^2)*cos(x^2), x^2, u) # subs(ex, p => q)
```

```@example symengine
replace_head(tan(sin(tan(x))), tan, cos)
```

## `SymEngine.jl` and symengine

This package only wraps those parts of symengine that are exposed through its [C wrapper](https://github.com/symengine/symengine/blob/master/symengine/cwrapper.cpp). The underlying C++ library has more functionality.
