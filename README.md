# SymEngine.jl

[![Build Status](https://github.com/symengine/SymEngine.jl/workflows/CI/badge.svg)](https://github.com/symengine/SymEngine.jl/actions)
[![Build status](https://ci.appveyor.com/api/projects/status/github/symengine/symengine.rb?branch=master&svg=true)](https://ci.appveyor.com/project/isuruf/symengine-jl-pj80f/branch/master)
[![Codecov](http://codecov.io/github/symengine/SymEngine.jl/coverage.svg?branch=master)](http://codecov.io/github/symengine/SymEngine.jl?branch=master)
[![Coveralls](https://coveralls.io/repos/symengine/SymEngine.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/symengine/SymEngine.jl?branch=master)

Julia Wrappers for [SymEngine](https://github.com/symengine/symengine), a fast symbolic manipulation library, written in C++.

## Installation

You can install `SymEngine.jl` by giving the following command.

```julia
julia> Pkg.add("SymEngine")
```

## Quick Start

### Working with scalar variables

#### Defining variables

One can define variables in a few ways. The following three examples are equivalent.

Defining two symbolic variables with the names `a` and `b`, and assigning them to julia variables with the same name.

``` julia
julia> a=symbols(:a); b=symbols(:b)
b

julia> a,b = symbols("a b")
(a, b)

julia> @vars a b
(a, b)
```

### Simple expressions

We are going to define an expression using the variables from earlier:

``` julia
julia> ex1 = a + 2(b+2)^2 + 2a + 3(a+1)
3*a + 3*(1 + a) + 2*(2 + b)^2
```

One can see that values are grouped, but no expansion is done.

### Working with vector and matrix variables

### Defining vectors of variables

A vector of variables can be defined using list comprehension and string interpolation.

```julia
julia> [symbols("α_$i") for i in 1:3]
3-element Vector{Basic}:
 α_1
 α_2
 α_3
```

#### Defining matrices of variables

Some times one might want to define a matrix of variables.
One can use a matrix comprehension, and string interpolation to create a matrix of variables.

```julia
julia> W = [symbols("W_$i$j") for i in 1:3, j in 1:4]
3×4 Matrix{Basic}:
 W_11  W_12  W_13  W_14
 W_21  W_22  W_23  W_24
 W_31  W_32  W_33  W_34
```

#### Matrix-vector multiplication

Now using the matrix we can perform matrix operations:

```julia
julia> W*[1.0, 2.0, 3.0, 4.0]
3-element Vector{Basic}:
 1.0*W_11 + 2.0*W_12 + 3.0*W_13 + 4.0*W_14
 1.0*W_21 + 2.0*W_22 + 3.0*W_23 + 4.0*W_24
 1.0*W_31 + 2.0*W_32 + 3.0*W_33 + 4.0*W_34
```

### Operations

#### `expand`

```julia
julia> expand(a + 2(b+2)^2 + 2a + 3(a+1))
11 + 6*a + 8*b + 2*b^2
```

#### `subs`

Performs substitution.

```julia
julia> subs(a^2+(b-2)^2, b=>a)
a^2 + (-2 + a)^2

julia> subs(a^2+(b-2)^2, b=>2)
a^2

julia> subs(a^2+(b-2)^2, a=>2)
4 + (-2 + b)^2

julia> subs(a^2+(b-2)^2, a^2=>2)
2 + (-2 + b)^2

julia> subs(a^2+(b-2)^2, a=>2, b=>3)
5
```

#### `diff`

Peforms differentiation

```julia
julia> diff(a + 2(b+2)^2 + 2a + 3(a+1), b)
4*(2 + b)
```

## License

`SymEngine.jl` is licensed under MIT open source license.
