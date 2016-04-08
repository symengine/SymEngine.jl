

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
    ccall((:basic_subs2, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &s, &ex, &var, &val)
    return s
end
subs{T <: SymbolicType, S<:SymbolicType}(ex::T, y::Tuple{S, Any}) = subs(ex, y[1], y[2])
subs{T <: SymbolicType, S<:SymbolicType}(ex::T, y::Tuple{S, Any}, args...) = subs(subs(ex, y), args...)
subs{T <: SymbolicType}(ex::T, d::Pair...) = subs(ex, [(p.first, p.second) for p in d]...)

## Lambdify

## Mapping of SymEngine Constants into julia values
constant_map = Dict("pi" => :pi, "E" => :e, "EulerGamma" => :γ)

## Map symengine classes to function names
fn_map = Dict(
              :Add => :+,
              :Sub => :-,
              :Mul => :*,
              :Div => :/,
              :Pow => :^,
              :re  => :real,
              :im  => :imag,
              :Abs => :abs # not really needed as default in map_fn covers this
              )

map_fn(key, fn_map) = haskey(fn_map, key) ? fn_map[key] : symbol(lowercase(string(key)))

function walk_expression(ex)
    fn = get_symengine_class(ex)
    
    if fn == :Symbol
        return symbol(toString(ex))
    elseif fn in [:Integer , :Rational]
        return N(ex)
    elseif fn == :Complex
        ## hacky
        x = eval(parse(replace(toString(ex), "I", "im")))
        return Expr(:call, :complex, real(x), imag(x))
    elseif fn == :Constant
        return constant_map[toString(ex)]
                            
    end

    as = get_args(ex)

    Expr(:call, map_fn(fn, fn_map), [walk_expression(a) for a in as]...)
end

## evaluate symbolless expression or return afunction
function lambdify(ex::Basic)
    vars = free_symbols(ex)
    if length(vars) == 0
        _lambdify(ex)
    else
        _lambdify(ex, vars)
    end
end
lambdify(ex::BasicType) = lambdify(Basic(ex))

## return a number
function _lambdify(ex)
    body = walk_expression(ex)
    eval(body)
end

## return a function
function _lambdify(ex::Basic, vars)
    body = walk_expression(ex)

    try
        eval(Expr(:function,
                  Expr(:call, gensym(), map(symbol,vars)...),
                  body))
    catch err
        throw(ArgumentError("Expression does not lambdify"))
    end
end


# N
"""

Convert a SymEngine numeric value into a number

"""
N(b::Basic) = N(BasicType(b))
N(b::BasicType{Val{:Integer}}) = eval(parse(toString(b)))  ## HACKY
N(b::BasicType{Val{:Rational}}) = eval(parse(replace(toString(b), "/", "//")))
N(b::BasicType{Val{:Complex}}) =  eval(parse(replace(toString(b), "I", "im")))

## function N(b::BasicType{Val{:Rational}})
##     println("XXX")
## end
## need to test for free_symbols, if none then we need to evaluate
function N(b::BasicType)
    b = convert(Basic, b)
    fs = free_symbols(b)
    if length(fs) > 0
        throw(ArgumentError("Object can have no free symbols"))
    end
    eval(lambdify(b))
end
        

N(a::Integer) = a
N(a::Rational) = a
N(a::Complex) = a
