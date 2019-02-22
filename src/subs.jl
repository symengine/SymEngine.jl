

"""
    subs

Substitute values into a symbolic expression.

Examples
```
@vars x y
ex = x^2 + y^2
subs(ex, x, 1) # 1 + y^2
subs(ex, (x, 1)) # 1 + y^2
subs(ex, (x, 1), (y,x)) # 1 + x^2, values are substituted left to right.
subs(ex, x=>1)  # alternate to subs(x, (x,1))
subs(ex, x=>1, y=>1) # ditto
```
"""
function subs(ex::T, var::S, val) where {T<:SymbolicType, S<:SymbolicType}
    s = Basic()
    ccall((:basic_subs2, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}, Ref{Basic}, Ref{Basic}), s, ex, var, val)
    return s
end
function subs(ex::T, d::CMapBasicBasic) where T<:SymbolicType
    s = Basic()
    ccall((:basic_subs, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}, Ptr{Cvoid}), s, ex, d.ptr)
    return s
end

subs(ex::T, d::Dict) where {T<:SymbolicType} = subs(ex, CMapBasicBasic(d))
subs(ex::T, y::Tuple{S, Any}) where {T <: SymbolicType, S<:SymbolicType} = subs(ex, y[1], y[2])
subs(ex::T, y::Tuple{S, Any}, args...) where {T <: SymbolicType, S<:SymbolicType} = subs(subs(ex, y), args...)
subs(ex::T, d::Pair...) where {T <: SymbolicType} = subs(ex, [(p.first, p.second) for p in d]...)


## Allow an expression to be called, as with ex(2). When there is more than one symbol, one can rely on order of `free_symbols` or
## be explicit by passing in pairs : `ex(x=>1, y=>2)` or a dict `ex(Dict(x=>1, y=>2))`.
function (ex::Basic)(args...)
  xs = free_symbols(ex)
  subs(ex, collect(zip(xs, args))...)
end
(ex::Basic)(x::Dict) = subs(ex, x)
(ex::Basic)(x::Pair...) = subs(ex, x...)


## Lambdify

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

map_fn(key, fn_map) = haskey(fn_map, key) ? fn_map[key] : Symbol(lowercase(string(key)))

function _convert(::Type{Expr}, ex::Basic)
    fn = get_symengine_class(ex)

    if fn == :Symbol
        return Symbol(toString(ex))
    elseif (fn in number_types) || (fn == :Constant)
        return N(ex)
    end

    as = get_args(ex)

    Expr(:call, map_fn(fn, fn_map), [_convert(Expr,a) for a in as]...)
end


function convert(::Type{Expr}, ex::Basic)
    fn = get_symengine_class(ex)

    if fn == :Symbol
        return Expr(:call, :*, Symbol(toString(ex)), 1)
    elseif (fn in number_types) || (fn == :Constant)
        return Expr(:call, :*, N(ex), 1)
    end

    return _convert(Expr, ex)
end

function convert(::Type{Expr}, m::AbstractArray{Basic, 2})
    col_args = []
    for i = 1:size(m, 1)
        row_args = []
        for j = 1:size(m, 2)
            push!(row_args, convert(Expr, m[i, j]))
        end
        row = Expr(:hcat, row_args...)
        push!(col_args, row)
    end
    Expr(:vcat, col_args...)
end

function convert(::Type{Expr}, m::AbstractArray{Basic, 1})
    row_args = []
    for j = 1:size(m, 1)
        push!(row_args, convert(Expr, m[j]))
    end
    Expr(:vcat, row_args...)
end

walk_expression(b) = convert(Expr, b)

"""
    lambdify
evaluates a symbolless expression or returns a function
"""
function lambdify(ex, vars=[])
    if length(vars) == 0
        vars = free_symbols(ex)
    end
    body = convert(Expr, ex)
    lambdify(body, vars)
end

function lambdify(ex::Basic, vars=[]; cse=false)
    if length(vars) == 0
        vars = free_symbols(ex)
    end
    if !cse
        body = convert(Expr, ex)
        return lambdify(body, vars)
    end
    replace_syms, replace_exprs, new_exprs = SymEngine.cse(ex)
    body_args = []
    for (i, j) in zip(replace_syms, replace_exprs)
        append!(body_args, [Expr(:(=), Symbol(toString(i)), convert(Expr, j))])
    end
    append!(body_args, [convert(Expr, new_exprs[0])])
    body = Expr(:block, body_args...)
    lambdify(body, vars)
end

lambdify(ex::BasicType, vars=[]) = lambdify(Basic(ex), vars)

function lambdify(ex::Expr, vars)
    if length(vars) == 0
        # return a number
        eval(ex)
    else
        # return a function
        _lambdify(ex, vars)
    end
end

function _lambdify(ex::Expr, vars)
    try
        fn = eval(Expr(:function,
                  Expr(:call, gensym(), map(Symbol,vars)...),
                       ex))
        (args...) -> invokelatest(fn, args...) # https://github.com/JuliaLang/julia/pull/19784
    catch err
        throw(ArgumentError("Expression does not lambdify"))
    end
end
