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
mutable struct Basic  <: Number
    ptr::Ptr{Cvoid}
    function Basic()
        z = new(C_NULL)
        ccall((:basic_new_stack, libsymengine), Nothing, (Ref{Basic}, ), z)
        finalizer(basic_free, z)
        return z
    end
    function Basic(v::Ptr{Cvoid})
        z = new(v)
        return z
    end
end

basic_free(b::Basic) = ccall((:basic_free_stack, libsymengine), Nothing, (Ref{Basic}, ), b)

function convert(::Type{Basic}, x::Clong)
    a = Basic()
    ccall((:integer_set_si, libsymengine), Nothing, (Ref{Basic}, Clong), a, x)
    return a
end

function convert(::Type{Basic}, x::Culong)
    a = Basic()
    ccall((:integer_set_ui, libsymengine), Nothing, (Ref{Basic}, Culong), a, x)
    return a
end

function convert(::Type{Basic}, x::BigInt)
    a = Basic()
    ccall((:integer_set_mpz, libsymengine), Nothing, (Ref{Basic}, Ref{BigInt}), a, x)
    return a
end

function convert(::Type{Basic}, s::String)
    a = Basic()
    b = ccall((:basic_parse, libsymengine), Cuint, (Ref{Basic}, Ptr{Int8}), a, s)
    throw_if_error(b, s)
    return a
end

function convert(::Type{Basic}, ex::Expr)
    expr = copy(ex)
    Basic(string(expr))
end

convert(::Type{Basic}, ex::Symbol) = Basic(string(ex))

function convert(::Type{Basic}, x::Cdouble)
    a = Basic()
    ccall((:real_double_set_d, libsymengine), Nothing, (Ref{Basic}, Cdouble), a, x)
    return a
end

function convert(::Type{Basic}, x::BigFloat)
    if (x.prec <= 53)
        return convert(Basic, Cdouble(x))
    elseif have_mpfr
        a = Basic()
        ccall((:real_mpfr_set, libsymengine), Nothing, (Ref{Basic}, Ref{BigFloat}), a, x)
        return a
    else
        warn("SymEngine is not compiled with MPFR support. Converting will lose precision.")
        return convert(Basic, Cdouble(x))
    end
end

if Clong == Int32
    convert(::Type{Basic}, x::Union{Int8, Int16}) = Basic(convert(Clong, x))
    convert(::Type{Basic}, x::Union{UInt8, UInt16}) = Basic(convert(Culong, x))
else
    convert(::Type{Basic}, x::Union{Int8, Int16, Int32}) = Basic(convert(Clong, x))
    convert(::Type{Basic}, x::Union{UInt8, UInt16, UInt32}) = Basic(convert(Culong, x))
end
convert(::Type{Basic}, x::Union{Float16, Float32}) = Basic(convert(Cdouble, x))
convert(::Type{Basic}, x::Integer) = Basic(BigInt(x))
convert(::Type{Basic}, x::Rational) = Basic(numerator(x)) / Basic(denominator(x))
convert(::Type{Basic}, x::Complex) = Basic(real(x)) + Basic(imag(x)) * IM

Basic(x::T) where {T} = convert(Basic, x)
Basic(x::Basic) = x

Base.promote_rule(::Type{Basic}, ::Type{S}) where {S<:Number} = Basic
Base.promote_rule(::Type{S}, ::Type{Basic}) where {S<:Number} = Basic
Base.promote_rule(::Type{S}, ::Type{Basic}) where {S<:AbstractIrrational} = Basic

## Class ID
get_type(s::Basic) = ccall((:basic_get_type, libsymengine), UInt, (Ref{Basic},), s)
function get_class_from_id(id::UInt)
    a = ccall((:basic_get_class_from_id, libsymengine), Ptr{UInt8}, (Int,), id)
    str = unsafe_string(a)
    ccall((:basic_str_free, libsymengine), Nothing, (Ptr{UInt8}, ), a)
    str
end

# use value of `get_type` to index into a vector storing symbols
function _get_symengine_classes()
    d = Vector{Symbol}()
    i = 0
    while true
      s = get_class_from_id(UInt(i))
      if s == ""
          break
    end
      push!(d, Symbol(s))
      i+=1
  end
    return d
end

const symengine_classes = _get_symengine_classes()
const symengine_classes_val = [Val(c) for c in SymEngine.symengine_classes]

"Get SymEngine class of an object (e.g. 1=>:Integer, 1//2 =:Rational, sin(x) => :Sin, ..."
get_symengine_class(s::Basic) = symengine_classes[get_type(s) + 1]
get_symengine_class_val(s::Basic) = symengine_classes_val[get_type(s) + 1]


## Construct symbolic objects
## renamed, as `Symbol` conflicts with Base.Symbol
function _symbol(s::String)
    a = Basic()
    ccall((:symbol_set, libsymengine), Nothing, (Ref{Basic}, Ptr{Int8}), a, s)
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
function symbols(s::String)
    ## handle space or comma sparation
    s = replace(s, ","=> " ")
    by_space = split(s, r"\s+")
    Base.length(by_space) == 1 && return symbols(Symbol(s))
    tuple([_symbol(Symbol(o)) for o in by_space]...)
end

## Follow, somewhat, the python names: symbols to construct symbols, @vars

"""
    @vars x y[1:5] z()

Macro to define 1 or more variables or symbolic function

Example
```
@vars x y z
@vars x[1:4]
@vars u(), x
```

"""
macro vars(xs...)
    # If the user separates declaration with commas, the top-level expression is a tuple
    if length(xs) == 1 && isa(xs[1], Expr) && xs[1].head == :tuple
        _gensyms(xs[1].args...)
    elseif length(xs) > 0
        _gensyms(xs...)
    end
end

function _gensyms(xs...)
    asstokw(a) = Expr(:kw, esc(a), true)

    # Each declaration is parsed and generates a declaration using `symbols`
    symdefs = map(xs) do expr
        decl = parsedecl(expr)
        symname = sym(decl)
        symname, gendecl(decl)
    end
    syms, defs = collect(zip(symdefs...))

    # The macro returns a tuple of Symbols that were declared
    Expr(:block, defs..., :(tuple($(map(esc,syms)...))))
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
struct BasicType{T} <: Number
    x::Basic
end

convert(::Type{Basic}, x::Basic) = x

SymbolicType = Union{Basic, BasicType}
convert(::Type{Basic}, x::BasicType) = x.x
Basic(x::BasicType) = x.x

BasicType(val::Basic) =  BasicType{get_symengine_class_val(val)}(val)
convert(::Type{BasicType{T}}, val::Basic) where {T} = BasicType{Val{get_symengine_class(val)}}(val)
# Needed for julia v0.4.7
convert(::Type{T}, x::Basic) where {T<:BasicType} = BasicType(x)


## We have Basic and BasicType{...}. We go back and forth with:
## Basic(b::BasicType) and BasicType(b::Basic)

# for mathops
Base.promote_rule(::Type{T}, ::Type{S} ) where {T<:BasicType, S<:Number} = T
Base.promote_rule(::Type{S}, ::Type{T} ) where {T<:BasicType, S<:Number} = T

# to intersperse BasicType and Basic in math ops
Base.promote_rule(::Type{T}, ::Type{Basic} ) where {T<:BasicType} = T
Base.promote_rule( ::Type{Basic}, ::Type{T} ) where {T<:BasicType} = T
Base.promote_rule(::Type{S}, ::Type{T}) where {S<:AbstractIrrational, T<:BasicType} = T

## needed for mathops
convert(::Type{T}, val::Number) where {T<:BasicType} = T(Basic(val))
## Julia v0.6 errors with ambiguous error if this method is not defined.
convert(::Type{T}, val::T) where {T<:BasicType} = val


## some type unions possibly useful for dispatch
## Names here match those returned by get_symengine_class()
real_number_types = [:Integer, :RealDouble, :Rational, :RealMPFR]
complex_number_types = [:Complex, :ComplexDouble, :ComplexMPC]
number_types = vcat(real_number_types, complex_number_types)
BasicNumber = Union{[SymEngine.BasicType{Val{i}} for i in number_types]...}
BasicRealNumber = Union{[SymEngine.BasicType{Val{i}} for i in real_number_types]...}
BasicComplexNumber = Union{[SymEngine.BasicType{Val{i}} for i in complex_number_types]...}

op_types = [:Mul, :Add, :Pow, :Symbol, :Const]
BasicOp = Union{[SymEngine.BasicType{Val{i}} for i in op_types]...}

trig_types = [:Sin, :Cos, :Tan, :Csc, :Sec, :Cot, :ASin, :ACos, :ATan, :ACsc, :ASec, :ACot]
BasicTrigFunction =  Union{[SymEngine.BasicType{Val{i}} for i in trig_types]...}



###

"Is expression constant"
function is_constant(ex::Basic)
    syms = CSetBasic()
    ccall((:basic_free_symbols, libsymengine), Nothing, (Ref{Basic}, Ptr{Cvoid}), ex, syms.ptr)
    Base.length(syms) == 0
end

"Is expression a symbol"
function is_symbol(x::SymbolicType)
    res = ccall((:is_a_Symbol, libsymengine), Cuint, (Ref{Basic},), x)
    Bool(convert(Int,res))
end

"Does expression contain the symbol"
function has_symbol(ex::SymbolicType, x::SymbolicType)
    is_symbol(x) || throw(ArgumentError("Not a symbol"))
    res = ccall((:basic_has_symbol, libsymengine), Cuint, (Ref{Basic},Ref{Basic}),  ex, x)
    Bool(convert(Int, res))
end


" Return free symbols in an expression as a `Set`"
function free_symbols(ex::Basic)
    syms = CSetBasic()
    ccall((:basic_free_symbols, libsymengine), Nothing, (Ref{Basic}, Ptr{Cvoid}), ex, syms.ptr)
    convert(Vector, syms)
end
free_symbols(ex::BasicType) = free_symbols(Basic(ex))
_flat(A) = mapreduce(x->isa(x,Array) ? _flat(x) : x, vcat, A, init=Basic[])  # from rosetta code example
free_symbols(exs::Array{T}) where {T<:SymbolicType}  = unique(_flat([free_symbols(ex) for ex in exs]))
free_symbols(exs::Tuple) =  unique(_flat([free_symbols(ex) for ex in exs]))

"Return function symbols in an expression as a `Set`"
function function_symbols(ex::Basic)
    syms = CSetBasic()
    ccall((:basic_function_symbols, libsymengine), Nothing, (Ptr{Cvoid}, Ref{Basic}), syms.ptr, ex)
    convert(Vector, syms)
end
function_symbols(ex::BasicType) = function_symbols(Basic(ex))
function_symbols(exs::Array{T}) where {T<:SymbolicType} = unique(_flat([function_symbols(ex) for ex in exs]))
function_symbols(exs::Tuple) = unique(_flat([function_symbols(ex) for ex in exs]))

"Return name of function symbol"
function get_name(ex::Basic)
    a = ccall((:function_symbol_get_name, libsymengine), Cstring, (Ref{Basic}, ), ex)
    string = unsafe_string(a)
    ccall((:basic_str_free, libsymengine), Nothing, (Cstring, ), a)
    return string
end

"Return arguments of a function call as a vector of `Basic` objects"
function get_args(ex::Basic)
    args = CVecBasic()
    ccall((:basic_get_args, libsymengine), Nothing, (Ref{Basic}, Ptr{Cvoid}), ex, args.ptr)
    convert(Vector, args)
end

## so that Dicts will work
basic_hash(ex::Basic) = ccall((:basic_hash, libsymengine), UInt, (Ref{Basic}, ), ex)
# similar definition as in Base for general objects
Base.hash(ex::Basic, h::UInt) = Base.hash_uint(3h - basic_hash(ex))
Base.hash(ex::BasicType, h::UInt) = hash(Basic(ex), h)

function coeff(b::Basic, x::Basic, n::Basic)
    c = Basic()
    ccall((:basic_coeff, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}, Ref{Basic}, Ref{Basic}), c, b, x, n)
    return c
end

coeff(b::Basic, x::Basic) = coeff(b, x, one(Basic))

function Serialization.serialize(s::Serialization.AbstractSerializer, m::Basic)
	Serialization.serialize_type(s, typeof(m))

	size = Ref{UInt64}(0)
	serialized = ccall((:basic_dumps, libsymengine),
		Ptr{Int8}, (Ref{Basic}, Ptr{UInt64}), m, size)

	write(s.io, size[])
	unsafe_write(s.io, serialized, size[])
end

function Serialization.deserialize(s::Serialization.AbstractSerializer, ::Type{Basic})
    size = read(s.io, UInt64)
    serialized_data = read(s.io, size)

	a = Basic()
	res = ccall((:basic_loads, libsymengine),
		Cuint, (Ref{Basic}, Ptr{Int8}, UInt64), a, serialized_data, size)
	throw_if_error(res)
	return a
end
