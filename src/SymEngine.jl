module SymEngine

import
    Base.show,
    Base.convert,
    Base.abs

import Base.Operators: +, -, ^, /, \, *, ==

include("../deps/deps.jl")

abstract BASIC
abstract NUMBER <: BASIC

type Basic
    ptr::Ptr{Void}
    function Basic()
        z = new(C_NULL)
        ccall((:basic_new_stack, :libsymengine), Void, (Ptr{Basic}, ), &z)
        finalizer(z, basic_free)
        return z
    end
end

type Number <: BASIC
    ptr::Ptr{Void}
    function Number()
        z = new(C_NULL)
        ccall((:basic_new_stack, :libsymengine), Void, (Ptr{Number}, ), &z)
        finalizer(z, basic_free)
        return z
    end
end

type Integer <: NUMBER
    ptr::Ptr{Void}
    function Integer()
        z = new(C_NULL)
        ccall((:basic_new_stack, :libsymengine), Void, (Ptr{Integer}, ), &z)
        finalizer(z, basic_free)
        return z
    end
end


basic_free(b::Basic) = ccall((:basic_free_stack, :libsymengine), Void, (Ptr{Basic}, ), &b)
basic_free(b::Number) = ccall((:basic_free_stack, :libsymengine), Void, (Ptr{Number}, ), &b)
basic_free(b::Integer) = ccall((:basic_free_stack, :libsymengine), Void, (Ptr{Integer}, ), &b)

function symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return a
end

function toString(b::Basic)
    a = ccall((:basic_str, :libsymengine), Ptr{Int8}, (Ptr{Basic}, ), &b)
    string = bytestring(a)
    ccall((:basic_str_free, :libsymengine), Void, (Ptr{Int8}, ), a)
    return string
end

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

function +(b1::Basic, b2::Basic)
    a = Basic()
    ccall((:basic_add, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    return a
end

function /(b1::Basic, b2::Basic)
    a = Basic()
    ccall((:basic_div, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    return a
end

function *(b1::Basic, b2::Basic)
    a = Basic()
    ccall((:basic_mul, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    return a
end

function ^(b1::Basic, b2::Basic)
    a = Basic()
    ccall((:basic_pow, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    return a
end

function -(b1::Basic, b2::Basic)
    a = Basic()
    ccall((:basic_sub, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    return a
end

function -(b::Basic)
    a = Basic()
    ccall((:basic_neg, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
    return a
end

+(b::Basic) = b
\(b1::Basic, b2::Basic) = b2 / b1

function abs(b::Basic)
    a = Basic()
    ccall((:basic_abs, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
    return a
end

function ==(b1::Basic, b2::Basic)
    ccall((:basic_eq, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}), &b1, &b2) == 1
end

types=Union{Integer, Rational}

+(b1::Basic, b2::types) = b1 + convert(Basic, b2)
+(b1::types, b2::Basic) = convert(Basic, b1) + b2
-(b1::Basic, b2::types) = b1 - convert(Basic, b2)
-(b1::types, b2::Basic) = convert(Basic, b1) - b2
*(b1::Basic, b2::types) = b1 * convert(Basic, b2)
*(b1::types, b2::Basic) = convert(Basic, b1) * b2
/(b1::Basic, b2::types) = b1 / convert(Basic, b2)
/(b1::types, b2::Basic) = convert(Basic, b1) / b2
^(b1::Basic, b2::Integer) = b1 ^ convert(Basic, b2)
^(b1::Integer, b2::Basic) = convert(Basic, b1) ^ b2
^(b1::Basic, b2::types) = b1 ^ convert(Basic, b2)
^(b1::types, b2::Basic) = convert(Basic, b1) ^ b2
\(b1::Basic, b2::types) = b1 \ convert(Basic, b2)
\(b1::types, b2::Basic) = convert(Basic, b1) \ b2
==(b1::Basic, b2::types) = b1 == convert(Basic, b2)
==(b1::types, b2::Basic) = convert(Basic, b1) == b2

function diff(b1::Basic, b2::Basic)
    a = Basic()
    ret = ccall((:basic_diff, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    if (ret == 0)
        error("Second argument must be a symbol.")
    end
    return a
end

function expand(b::Basic)
    a = Basic()
    ccall((:basic_expand, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
    return a
end

show(io::IO, b::Basic) = print(io, toString(b))

end

