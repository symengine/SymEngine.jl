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
export Basic


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

Base.promote_rule{S<:Number}(::Type{Basic}, ::Type{S} ) = Basic


## Construct symbolic objects
## rename? This conflicts with Base.symbol
function _symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return a
end
_symbol(s::Symbol) = _symbol(string(s))

"`symbols(::Symbol)` construct symbolic value"
symbols(s::Symbol) = _symbol(s)
symbols(s::ASCIIString) = [_symbol(symbol(o)) for o in split(replace(s, ",", " "), r"\s+")]
export symbols




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
export @vars


## We also have a wrapper type that can be used to control dispatch
## pros: wrapping adds overhead, so if possible best to use Basic
## cons: have to write methods meth(x::Basic, ...) = meth(BasicType(x),...)


## Wrapper type
## this allows SymEngine.jl to keep track of the class of the C++ object



## Parameterized type allowing or dispatch on Julia side by type of objecton SymEngine side
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

function get_type(s::Basic)
    id = ccall((:basic_get_type, :libsymengine), UInt, (Ptr{Basic},), &s)
    convert(Int, id)
end

function get_class_from_id(id::Int)
    out = ccall((:basic_get_class_from_id, :libsymengine), Ptr{UInt8}, (Int,), id)
    bytestring(out)
end

"
Get SymEngine class of an object (e.g. 1=>:Integer, 1//2 =:Rational, sin(x) => :Sin, ...
"
get_symengine_class(s::Basic) = symbol(get_class_from_id(get_type(s)))

## Convert a Basic value into one of the BasicType values
function Base.convert(::Type{BasicType}, val::Basic)
    nm = get_symengine_class(val)
    BasicType{Val{nm}}(val)
end
Base.convert{T}(::Type{BasicType{T}}, val::Basic) = convert(BasicType, val)



## We have Basic and BasicType{...}. We go back and forth with:
## Basic(b::BasicType) and BasicType(b::Basic)

# for mathops
Base.promote_rule{T<:BasicType, S<:Number}(::Type{T}, ::Type{S} ) = T

# to intersperse BasicType and Basic in math ops
Base.promote_rule{T<:BasicType}(::Type{T}, ::Type{Basic} ) = T
Base.promote_rule{T<:BasicType}( ::Type{Basic}, ::Type{T} ) = T

# is this not needed?
#Base.convert{T<:BasicType}(::Type{Basic}, val::T) = val.x

## needed for mathops
Base.convert{T<:BasicType}(::Type{T}, val::Number) = T(Basic(val))


## some type unions used for dispatch
## Names here match those returned by get_symengine_class()
number_types = [:Integer, :Rational, :Complex]
BasicNumber = Union{[SymEngine.BasicType{Val{i}} for i in number_types]...}

op_types = [:Mul, :Add, :Pow, :Symbol, :Const]
BasicOp = Union{[SymEngine.BasicType{Val{i}} for i in op_types]...}

trig_types = [:Sin, :Cos, :Tan, :Csc, :Sec, :Cot, :ASin, :ACos, :ATan, :ACsc, :ASec, :ACot]
BasicTrigFunction =  Union{[SymEngine.BasicType{Val{i}} for i in trig_types]...}



