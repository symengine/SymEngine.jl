

## subs
"""
Substitute values into a symbolic expression.

Examples
```
@syms x y
ex = x^2 + y^2
subs(ex, x, 1) # 1 + y^2
subs(ex, (x, 1)) # 1 + y^2
subs(ex, (x, 1), (y,x)) # 1 + x^2, values are substituted left to right.
subs(ex, x=>1)  # alternate to subs(x, (x,1))
subs(ex, x=>1, y=>1) # ditto
```
"""
function subs{T<:SymbolicType, S<:SymbolicType}(ex::T, var::S, val)
    s = Basic()
    var, val = map(Basic, (var, val))
    ccall((:basic_subs2, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &s, &ex, &var, &val)
    return s
end
subs{T <: SymbolicType, S<:SymbolicType}(ex::T, y::Tuple{S, Any}) = subs(ex, y[1], y[2])
subs{T <: SymbolicType, S<:SymbolicType}(ex::T, y::Tuple{S, Any}, args...) = subs(subs(ex, y), args...)
subs{T <: SymbolicType}(ex::T, d::Pair...) = subs(ex, [(p.first, p.second) for p in d]...)
export subs


# N
"""

Convert a SymEngine numeric value into a number

"""
N(b::Basic) = N(_Sym(b))
N(b::BasicType{Val{:Integer}}) = parse(BigInt, toString(b))
N(b::BasicType{Val{:Rational}}) = parse(Float64, toString(b))
