# SymEngine.jl

[![Build Status](https://travis-ci.org/symengine/SymEngine.jl.svg?branch=master)](https://travis-ci.org/symengine/SymEngine.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/github/symengine/symengine.rb?branch=master&svg=true)](https://ci.appveyor.com/project/isuruf/symengine-jl-pj80f/branch/master)

[![SymEngine](http://pkg.julialang.org/badges/SymEngine_0.6.svg)](http://pkg.julialang.org/?pkg=SymEngine)
[![SymEngine](http://pkg.julialang.org/badges/SymEngine_0.7.svg)](http://pkg.julialang.org/?pkg=SymEngine)

Julia Wrappers for SymEngine, a fast symbolic manipulation library, written in C++.

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

#### Defining matricies of variables

Some times one might want to define a matrix of variables.
One can use a matrix comprehension, and string interpolation to create a matrix of variables.

```julia
julia> W = [symbols("W_$i$j") for i in 1:3, j in 1:4]
3×4 Array{SymEngine.Basic,2}:
 W_11  W_12  W_13  W_14
 W_21  W_22  W_23  W_24
 W_31  W_32  W_33  W_34
```

#### Matrix-vector multiplication

Now using the matrix we can perform matrix operations:

```julia
julia> W*[1.0, 2.0, 3.0, 4.0]
3-element Array{SymEngine.Basic,1}:
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

Performs subsitution.

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
