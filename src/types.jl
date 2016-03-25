
abstract SymbolicNumber <: Number

type Basic <: SymbolicNumber
    ptr::Ptr{Void}
    function Basic()
        z = new(C_NULL)
        ccall((:basic_new_stack, :libsymengine), Void, (Ptr{Basic}, ), &z)
        finalizer(z, basic_free)
        return z
    end
end
export Basic

Base.promote_rule{T<:SymbolicNumber, S<:Number}(::Type{T}, ::Type{S} ) = T

basic_free(b::Basic) = ccall((:basic_free_stack, :libsymengine), Void, (Ptr{Basic}, ), &b)


function Basic(x::Clong)
    a = Basic()
    ccall((:integer_set_si, :libsymengine), Void, (Ptr{Basic}, Clong), &a, x)
    return a
end

function Basic(x::Culong)
    a = Basic()
    ccall((:integer_set_ui, :libsymengine), Void, (Ptr{Basic}, Culong), &a, x)
    return a
end

function Basic(x::BigInt)
    a = Basic()
    ccall((:integer_set_mpz, :libsymengine), Void, (Ptr{Basic}, Ptr{BigInt}), &a, &x)
    return a
end


if Clong == Int32
    convert(::Type{Basic}, x::Union{Int8, Int16, Int32}) = Basic(convert(Clong, x))
    convert(::Type{Basic}, x::Union{UInt8, UInt16, UInt32}) = Basic(convert(Culong, x))
else
    convert(::Type{Basic}, x::Union{Int8, Int16, Int32, Int64}) = Basic(convert(Clong, x))
    convert(::Type{Basic}, x::Union{UInt8, UInt16, UInt32, UInt64}) = Basic(convert(Culong, x))
end
convert(::Type{Basic}, x::Integer) = Basic(BigInt(x))
convert(::Type{Basic}, x::Rational) = Basic(num(x)) / Basic(den(x))


## Construct symbolic objects
## rename? This conflicts with Base.symbol
function _symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return a
end
_symbol(s::Symbol) = _symbol(string(s))

"""

Macro to define 1 or more variables in the main workspace.

Symbolic values are defined with `_symbol`. This is a convenience

Example
```
@syms x y z
```
"""
macro syms(x...)
    q=Expr(:block)
    if length(x) == 1 && isa(x[1],Expr)
        @assert x[1].head === :tuple "@syms expected a list of symbols"
        x = x[1].args
    end
    for s in x
        @assert isa(s,Symbol) "@syms expected a list of symbols"
        push!(q.args, Expr(:(=), s, Expr(:call, :(SymEngine._symbol), Expr(:quote, s))))
    end
    push!(q.args, Expr(:tuple, x...))
    eval(Main, q)
end
export @syms


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
function subs(ex::Basic, var::Basic, val)
    s = Basic()
    val = Basic(val)
    ccall((:basic_subs2, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &s, &ex, &var, &val)
    return s
end
subs{T <: Basic}(ex::T, y::Tuple{Basic, Any}) = subs(ex, y[1], y[2])
subs{T <: Basic}(ex::T, y::Tuple{Basic, Any}, args...) = subs(subs(ex, y), args...)
subs{T <: Basic}(ex::T, d::Pair...) = subs(ex, [(p.first, p.second) for p in d]...)
export subs
