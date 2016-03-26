
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
convert(::Type{Basic}, x::Rational) = Basic(BasicInteger(num(x)) / BasicInteger(den(x)))



## Wrapper type
## this allows SymEngine.jl to keep track of the class of the C++ object
## XXX This needs to be generated from symengine on startup
## XXX This might be tedious with precompilation!
abstract BasicType <: Number
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
                                         19 => :Constant)

_basic_types = Dict()

## for (k,v) in SYMENGINE_ENUM
##     tname = symbol("Basic$v")
##     fname = symbol("basic_free_$v")
##     @eval begin
##         type $tname <: BasicType
##             x::Basic
##         end
##         _basic_types[$k] = $tname
##     end
## end
##
type BasicValue <: BasicType
    x::Basic
end

Basic(x::BasicType) = x.x

function get_type(s::Basic)
    ccall((:basic_get_type, :libsymengine), Int, (Ptr{Basic},), &s)
end

function get_class_id(id)
    id = string(id)
    ccall((:basic_get_class_id, :libsymengine), AbstractString, (Ptr{AbstractString},), &s)
end

function Base.convert(::Type{BasicType}, val::Basic)
    id = get_type(val)
    if !haskey(_basic_types, id)
        ## need to create a new type
        # nm = get_class_id(id)
        nm = haskey(SYMENGINE_ENUM, id) ? "Basic" * string(SYMENGINE_ENUM[id]) : "BasicValue"
        # create new type
        if nm == "BasicValue"
            return BasicValue(val)
        else
            nm = symbol(nm)
            @eval begin
                type $nm <: BasicType
                    x::Basic
                end
                _basic_types[$id] = $nm
            end
        end
    end
    _basic_types[id](val)
end



Base.promote_rule{T<:SymbolicNumber, S<:Number}(::Type{T}, ::Type{S} ) = T
Base.promote_rule{T<:BasicType, S<:Number}(::Type{T}, ::Type{S} ) = T

Base.convert{T<:BasicType}(::Type{Basic}, val::T) = val.x
Base.convert{T<:BasicType}(::Type{T}, val::Integer) = T(Basic(val))
Base.convert{T<:BasicType}(::Type{T}, val::Rational) = T(Basic(val))








## Construct symbolic objects
## rename? This conflicts with Base.symbol
function _symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return BasicValue(a)
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


## We have a bit of a mess with Basic and BasicType
## Basic is not what we want to use externally. Create a Sym function for that
"""

Create a symbolic object

"""
Sym(x::AbstractString) = _symbol(x)
Sym(x::Symbol) = _symbol(x)
Sym(x::Any) = convert(BasicType, Basic(x))
export Sym



