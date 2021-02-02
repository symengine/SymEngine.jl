# Quick Start

Derived from the project `README` [on GitHub](https://github.com/symengine/SymEngine.jl).

## Scalar Variables
### Definitions

Multiple equivalent methods of variable declaration are supported.

```jldoctest
julia> using SymEngine

julia> a=symbols(:a); b=symbols(:b)
b

julia> a,b = symbols("a b")
(a, b)

julia> @vars a b
(a, b)
```

### Simple Expressions
Note that by default, values are grouped but no expansion takes place.

```jldoctest
julia> using SymEngine

julia> @vars a b
(a, b)

julia> ex1 = a + 2(b+2)^2 + 2a + 3(a+1)
3*a + 3*(1 + a) + 2*(2 + b)^2
```


## Vectors and Matrices
### Definitions
#### Vectors
Vectors can be defined through list comprehension and string interpolation.

```jldoctest
julia> using SymEngine

julia> [symbols("α_$i") for i in 1:3]
3-element Array{Basic,1}:
 α_1
 α_2
 α_3
```

#### Matrices
In an analogous manner, matrices are declared with a combination of string interpolation and matrix comprehension.

```jldoctest
julia> using SymEngine

julia> W = [symbols("W_$i$j") for i in 1:3, j in 1:4]
3×4 Array{Basic,2}:
 W_11  W_12  W_13  W_14
 W_21  W_22  W_23  W_24
 W_31  W_32  W_33  W_34
```

### Matrix Vector Operations

Consider the canonical example of **matrix vector multiplication**.

```jldoctest
julia> using SymEngine

julia> W = [symbols("W_$i$j") for i in 1:3, j in 1:4]
3×4 Array{Basic,2}:
 W_11  W_12  W_13  W_14
 W_21  W_22  W_23  W_24
 W_31  W_32  W_33  W_34
 
julia> W*[1.0, 2.0, 3.0, 4.0]
3-element Array{Basic,1}:
 1.0*W_11 + 2.0*W_12 + 3.0*W_13 + 4.0*W_14
 1.0*W_21 + 2.0*W_22 + 3.0*W_23 + 4.0*W_24
 1.0*W_31 + 2.0*W_32 + 3.0*W_33 + 4.0*W_34
```

## Operations
We will demonstrate the most common operations as follows.
### Expansion
```jldoctest
julia> using SymEngine

julia> @vars a b
(a, b)

julia> expand(a + 2(b+2)^2 + 2a + 3(a+1))
11 + 6*a + 8*b + 2*b^2
```
### Substitution
```jldoctest
julia> using SymEngine

julia> @vars a b
(a, b)

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
### Differentiation
```jldoctest
julia> using SymEngine

julia> @vars a b
(a, b)

julia> diff(a + 2(b+2)^2 + 2a + 3(a+1), b)
4*(2 + b)
```
