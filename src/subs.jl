

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
function subs{T<:SymbolicType, S<:SymbolicType}(ex::T, var::S, val)
    s = Basic()
    ccall((:basic_subs2, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &s, &ex, &var, &val)
    return s
end
function subs{T<:SymbolicType}(ex::T, d::CMapBasicBasic)
    s = Basic()
    ccall((:basic_subs, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Void}), &s, &ex, d.ptr)
    return s
end

subs{T<:SymbolicType}(ex::T, d::Dict) = subs(ex, CMapBasicBasic(d))
subs{T <: SymbolicType, S<:SymbolicType}(ex::T, y::Tuple{S, Any}) = subs(ex, y[1], y[2])
subs{T <: SymbolicType, S<:SymbolicType}(ex::T, y::Tuple{S, Any}, args...) = subs(subs(ex, y), args...)
subs{T <: SymbolicType}(ex::T, d::Pair...) = subs(ex, [(p.first, p.second) for p in d]...)


## Allow an expression to be called, as with ex(2). When there is more than one symbol, one can rely on order of `free_symbols` or
## be explicit by passing in pairs : `ex(x=>1, y=>2)` or a dict `ex(Dict(x=>1, y=>2))`.
## This uses `eval` to avoid having to work around different styles in v0.5 and v0.4
call_v0_4 = quote
  function Base.call{T <: Basic}(ex::T, args...)
      xs = free_symbols(ex)
      subs(ex, collect(zip(xs, args))...)
  end
  Base.call(ex::Basic, x::Dict) = subs(ex, x)
  Base.call(ex::Basic, x::Pair...) = subs(ex, x...)
end

call_v0_5 = quote
  function (ex::Basic)(args...)
      xs = free_symbols(ex)
      subs(ex, collect(zip(xs, args))...)
  end
  (ex::Basic)(x::Dict) = subs(ex, x)
  (ex::Basic)(x::Pair...) = subs(ex, x...)
end
VERSION < v"0.5.0" ? eval(call_v0_4) : eval(call_v0_5)


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

function walk_expression(ex)
    fn = get_symengine_class(ex)
    
    if fn == :Symbol
        return Symbol(toString(ex))
    elseif (fn in number_types) || (fn == :Constant)
        return N(ex)
    end

    as = get_args(ex)

    Expr(:call, map_fn(fn, fn_map), [walk_expression(a) for a in as]...)
end

"""
    lambdify

evaluates a symbolless expression or returns a function
"""
function lambdify(ex::Basic, vars=[])
    if length(vars) == 0
        vars = free_symbols(ex)
    end
    body = walk_expression(ex)
    _lambdify(body, vars)
end
lambdify(ex::BasicType, vars=[]) = lambdify(Basic(ex), vars)

function lambdify(m::AbstractArray{Basic, 2}, vars=[])
    col_args = []
    for i = 1:size(m, 1)
        row_args = []
        for j = 1:size(m, 2)
            push!(row_args, walk_expression(m[i, j]))
        end
        row = Expr(:hcat, row_args...)
        push!(col_args, row)
    end
    body = Expr(:vcat, col_args...)
    _lambdify(body, vars)
end


function lambdify(m::AbstractArray{Basic, 1}, vars=[])
    row_args = []
    for j = 1:size(m, 1)
        push!(row_args, walk_expression(m[j]))
    end
    body = Expr(:vcat, row_args...)
    _lambdify(body, vars)
end

function _lambdify(ex::Expr, vars)
    if length(vars) == 0
        # return a number
        eval(body)
    else
        # return a function
        _lambdify(body, vars)
    end
end

function lambdify(ex::Expr, vars)
    try
        fn = eval(Expr(:function,
                  Expr(:call, gensym(), map(Symbol,vars)...),
                       ex))
        (args...) -> invokelatest(fn, args...) # https://github.com/JuliaLang/julia/pull/19784
    catch err
        throw(ArgumentError("Expression does not lambdify"))
    end
end

