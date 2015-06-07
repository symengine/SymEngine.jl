module SymEngine
export
    Basic, basic_symbol, basic_diff

import
    Base.show,
    Base.convert

type Basic
    ptr::Ptr{Void}
    function Basic()
        z = new(C_NULL)
        ccall((:basic_init, :libsymengine), Void, (Ptr{Basic}, ), &z)
        finalizer(z, basic_free)
        return z
    end
end

basic_free(b::Basic) = ccall((:basic_free, :libsymengine), Void, (Ptr{Basic}, ), &b)

function basic_symbol(s::ASCIIString)
    a = Basic()
    ccall((:symbol_set, :libsymengine), Void, (Ptr{Basic}, Ptr{Int8}), &a, s)
    return a
end

function basic_str(b::Basic)
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
    convert(::Type{Basic}, x::Union(Int8, Int16, Int32)) = Basic(convert(Clong, x))
    convert(::Type{Basic}, x::Union(Uint8, Uint16, Uint32)) = Basic(convert(Culong, x))
else
    convert(::Type{Basic}, x::Union(Int8, Int16, Int32, Int64)) = Basic(convert(Clong, x))
    convert(::Type{Basic}, x::Union(Uint8, Uint16, Uint32, Uint64)) = Basic(convert(Culong, x))
end
convert(::Type{Basic}, x::Integer) = Basic(BigInt(x))

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

function ==(b1::Basic, b2::Basic)
    ccall((:basic_eq, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}), &b1, &b2) == 1
end

+(b1::Basic, b2::Integer) = b1 + convert(Basic, b2)
+(b1::Integer, b2::Basic) = convert(Basic, b1) + b2
-(b1::Basic, b2::Integer) = b1 - convert(Basic, b2)
-(b1::Integer, b2::Basic) = convert(Basic, b1) - b2
*(b1::Basic, b2::Integer) = b1 * convert(Basic, b2)
*(b1::Integer, b2::Basic) = convert(Basic, b1) * b2
/(b1::Basic, b2::Integer) = b1 / convert(Basic, b2)
/(b1::Integer, b2::Basic) = convert(Basic, b1) / b2
^(b1::Basic, b2::Integer) = b1 ^ convert(Basic, b2)
^(b1::Integer, b2::Basic) = convert(Basic, b1) ^ b2


function basic_diff(b1::Basic, b2::Basic)
    a = Basic()
    ret = ccall((:basic_diff, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    if (ret == 0)
        error("b2 must be a symbol.")
    end
    return a
end

show(io::IO, b::Basic) = print(io, basic_str(b))

end

