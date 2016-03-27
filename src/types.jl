## We have different types:
## Basic: holds a ptr to a symengine object. Faster, so is default type
## BasicType{Val{:XXX}}: types that can be use to control dispatch
## SymbolicType: a type union of the two
## Basic(x::BasicType) gives a basic object; _Sym(x::Basic) gives a BasicType object. (This name needs change)
## To control dispatch, one might have `N(b::Basic) = N(_Sym(b))` and then define `N` for types of interest

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



## Construct symbolic objects
## rename? This conflicts with Base.symbol
function _symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return a
end
_symbol(s::Symbol) = _symbol(string(s))

"""

Convenience for construction symbolic values

"""
Sym(s::ASCIIString) = _symbol(s)
Sym(s::Symbol) = Sym(string(s))
Sym(s::Any) = Basic(s)
export Sym


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


## We also have a wrapper type that can be used to control dispatch
## pros: wrapping adds overhead, so if possible best to use Basic
## cons: have to write methods meth(x::Basic, ...) = meth(Sym(x),...)


## Wrapper type
## this allows SymEngine.jl to keep track of the class of the C++ object


## XXX Temporarary, to be replaced by get_class_from_id
const SYMENGINE_ENUM = Dict{Int, Symbol}(0 => :Integer,
                                         1 => :Rational,
                                         2 => :Complex,
                                         3 => :ComplexDouble,
                                         11 => :Symbol,
                                         12 => :EmptySet,
                                         13 => :Interval,
                                         14 => :Mul,
                                         15 => :Add,
                                         16 => :Pow,
                                         19 => :Constant,
                                         20 => :Sin,
                                         21 => :Cos
                                         )

## Parameterized type allowing or dispatch on Julia side by type of objecton SymEngine side
## Use as BasicType{Val{:Integer}}(...)
## To take advantage of this, define
## meth(x::Basic) = meth(_Sym(x))
## and then
## meth(x::BasicType{Val{:Integer}}) = ... or
## meth(x::BasicNumber) = ...
type BasicType{T} <: Number
    x::Basic
end

SymbolicType = Union{Basic, BasicType}

Basic(x::BasicType) = x.x

function get_type(s::Basic)
    ccall((:basic_get_type, :libsymengine), UInt, (Ptr{Basic},), &s)
end

function get_class_from_id(id)
    id = string(id)
    ccall((:basic_get_class_from_id, :libsymengine), AbstractString, (Ptr{AbstractString},), &id)
end

## Convert a Basic value into one of the BasicType values
## XXX this needs hooking up with get_class_from_id XXX
function Base.convert(::Type{BasicType}, val::Basic)
    id = get_type(val)
    # nm = get_class_from_id(id)
    nm = haskey(SYMENGINE_ENUM, id) ? SYMENGINE_ENUM[id] : :Value  # work around until get_class_id is exposed
    BasicType{Val{nm}}(val)
end
Base.convert{T}(::Type{BasicType{T}}, val::Basic) = convert(BasicType, val)

## some type unions used for dispatch
number_types = [:Integer, :Rational, :Complex]
BasicNumber = Union{[SymEngine.BasicType{Val{i}} for i in number_types]...}

op_types = [:Mul, :Add, :Pow, :Symbol, :Const]
BasicOp = Union{[SymEngine.BasicType{Val{i}} for i in op_types]...}

trig_types = [:Sin, :Cos, :Tan, :Csc, :Sec, :Cot, :ASin, :ACos, :ATan, :ACsc, :ASec, :ACot]
BasicTrigFunction =  Union{[SymEngine.BasicType{Val{i}} for i in trig_types]...}





Base.promote_rule{S<:Number}(::Type{Basic}, ::Type{S} ) = Basic
Base.promote_rule{T<:BasicType, S<:Number}(::Type{T}, ::Type{S} ) = T

Base.promote_type{T}(::Type{BasicType{Val{T}}}, ::Type{Basic}) = BasicType{Val{T}}
Base.promote_type{T}(::Type{Basic}, ::Type{BasicType{Val{T}}}) = BasicType{Val{T}}



Base.convert{T<:BasicType}(::Type{Basic}, val::T) = val.x
Base.convert{T<:BasicType}(::Type{T}, val::Integer) = T(Basic(val))
Base.convert{T<:BasicType}(::Type{T}, val::Rational) = T(Basic(val))



## We have Basic and BasicType{...}. We go back and forth with:
## Basic(b::BasicType) and Sym(b::Basic)
_Sym(x::Any) = convert(BasicType, Basic(x))



