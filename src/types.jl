## We have different types:
##
## Basic: holds a ptr to a symengine object. Faster, so is default type
##
## BasicType{Val{:XXX}}: types that can be use to control dispatch
##
## SymbolicType: is a type union of the two
##
## Basic(x::BasicType) gives a basic object; BasicType(x::Basic) gives a BasicType object. (This name needs change)
##
## To control dispatch, one might have `N(b::Basic) = N(BasicType(b))` and then define `N` for types of interest

## Hold a reference to a SymEngine object
type Basic  <: Number
    ptr::Ptr{Void}
    function Basic()
        z = new(C_NULL)
        ccall((:basic_new_stack, :libsymengine), Void, (Ptr{Basic}, ), &z)
        finalizer(z, basic_free)
        return z
    end
end


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
convert(::Type{Basic}, x::Complex) = Basic(real(x)) + Basic(imag(x)) * IM

Base.promote_rule{S<:Number}(::Type{Basic}, ::Type{S} ) = Basic

## Class ID
get_type(s::Basic) = ccall((:basic_get_type, :libsymengine), UInt, (Ptr{Basic},), &s)
function get_class_from_id(id::UInt)
    a = ccall((:basic_get_class_from_id, :libsymengine), Ptr{UInt8}, (Int,), id)
    str = bytestring(a)
    ccall((:basic_str_free, :libsymengine), Void, (Ptr{UInt8}, ), a)
    str
end

"Get SymEngine class of an object (e.g. 1=>:Integer, 1//2 =:Rational, sin(x) => :Sin, ..."
get_symengine_class(s::Basic) = symbol(get_class_from_id(get_type(s)))


## Construct symbolic objects
## renamed, as `symbol` conflicts with Base.symbol
function _symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return a
end
_symbol(s::Symbol) = _symbol(string(s))

## use SymPy name here, but no assumptions
"""

`symbols(::Symbol)` construct symbolic value

Examples:
```
a = symbols(:a)
x = symbols("x")
x,y = symbols("x y")
x,y,z = symbols("x,y,z")
```

"""

symbols(s::Symbol) = _symbol(s)
function symbols(s::ASCIIString)
    ## handle space or comma sparation
    s = replace(s, ",", " ")
    by_space = split(s, r"\s+")
    Base.length(by_space) == 1 && return symbols(symbol(s))
    tuple([_symbol(symbol(o)) for o in by_space]...)
end




## Follow, somewhat, the python names: symbols to construct symbols, @vars


"""
Macro to define 1 or more variables in the main workspace.

Symbolic values are defined with `_symbol`. This is a convenience

Example
```
@vars x y z
```
"""
macro vars(x...)
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


## We also have a wrapper type that can be used to control dispatch
## pros: wrapping adds overhead, so if possible best to use Basic
## cons: have to write methods meth(x::Basic, ...) = meth(BasicType(x),...)




## Parameterized type allowing for dispatch on Julia side by type of objecton SymEngine side
## Use as BasicType{Val{:Integer}}(...)
## To take advantage of this, define
## meth(x::Basic) = meth(BasicType(x))
## and then
## meth(x::BasicType{Val{:Integer}}) = ... or
## meth(x::BasicNumber) = ...
type BasicType{T} <: Number
    x::Basic
end

SymbolicType = Union{Basic, BasicType}
convert(::Type{Basic}, x::BasicType) = x.x
Basic(x::BasicType) = x.x

BasicType(val::Basic) =  BasicType{Val{get_symengine_class(val)}}(val)
Base.convert{T}(::Type{BasicType{T}}, val::Basic) = BasicType{Val{get_symengine_class(val)}}(val)



## We have Basic and BasicType{...}. We go back and forth with:
## Basic(b::BasicType) and BasicType(b::Basic)

# for mathops
Base.promote_rule{T<:BasicType, S<:Number}(::Type{T}, ::Type{S} ) = T

# to intersperse BasicType and Basic in math ops
Base.promote_rule{T<:BasicType}(::Type{T}, ::Type{Basic} ) = T
Base.promote_rule{T<:BasicType}( ::Type{Basic}, ::Type{T} ) = T

## needed for mathops
Base.convert{T<:BasicType}(::Type{T}, val::Number) = T(Basic(val))


## some type unions possibly useful for dispatch
## Names here match those returned by get_symengine_class()
number_types = [:Integer, :Rational, :Complex]
BasicNumber = Union{[SymEngine.BasicType{Val{i}} for i in number_types]...}

op_types = [:Mul, :Add, :Pow, :Symbol, :Const]
BasicOp = Union{[SymEngine.BasicType{Val{i}} for i in op_types]...}

trig_types = [:Sin, :Cos, :Tan, :Csc, :Sec, :Cot, :ASin, :ACos, :ATan, :ACsc, :ASec, :ACot]
BasicTrigFunction =  Union{[SymEngine.BasicType{Val{i}} for i in trig_types]...}



###


" Return free symbols in an expression as a `Set`"
function free_symbols(ex::Basic)
    syms = CSetBasic()
    ccall((:basic_free_symbols, :libsymengine), Void, (Ptr{Basic}, Ptr{Void}), &ex, syms.ptr)
    convert(Vector, syms)
end
free_symbols(ex::BasicType) = free_symbols(Basic(ex))
_flat(A) = mapreduce(x->isa(x,Array)? _flat(x): x, vcat, Basic[], A)  # from rosetta code example
free_symbols{T<:SymbolicType}(exs::Array{T})  = unique(_flat([free_symbols(ex) for ex in exs]))
free_symbols(exs::Tuple) =  unique(_flat([free_symbols(ex) for ex in exs]))


"Return arguments of a function call as a vector of `Basic` objects"
function get_args(ex::Basic)
    args = CVecBasic()
    ccall((:basic_get_args, :libsymengine), Void, (Ptr{Basic}, Ptr{Void}), &ex, args.ptr)
    convert(Vector, args)
end

## so that Dicts will work
Base.hash(ex::Basic) = ccall((:basic_hash, :libsymengine), UInt, (Ptr{Basic}, ), &ex)
