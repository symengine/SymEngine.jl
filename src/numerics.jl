# N
"""

Convert a SymEngine numeric value into a number

"""
function convert(::Type{BigInt}, b::BasicType{Val{:Integer}})
    a = BigInt()
    c = Basic(b)
    ccall((:integer_get_mpz, libsymengine), Void, (Ptr{BigInt}, Ptr{Basic}), &a, &c)
    return a
end

function convert(::Type{Cdouble}, b::BasicType{Val{:RealDouble}})
    c = Basic(b)
    return ccall((:real_double_get_d, libsymengine), Cdouble, (Ptr{Basic},), &c)
end

real(b::BasicRealNumber) = b
imag(b::BasicRealNumber) = b

function real(b::BasicType{Val{:ComplexDouble}})
    c = Basic(b)
    a = Basic()
    ccall((:complex_double_real_part, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &c)
    return a
end

function imag(b::BasicType{Val{:ComplexDouble}})
    c = Basic(b)
    a = Basic()
    ccall((:complex_double_imaginary_part, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &c)
    return a
end

function real(b::BasicType{Val{:Complex}})
    c = Basic(b)
    a = Basic()
    ccall((:complex_real_part, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &c)
    return a
end

function imag(b::BasicType{Val{:Complex}})
    c = Basic(b)
    a = Basic()
    ccall((:complex_imaginary_part, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &c)
    return a
end

function real(b::BasicType{Val{:ComplexMPC}})
    c = Basic(b)
    a = Basic()
    ccall((:complex_mpc_real_part, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &c)
    return a
end

function imag(b::BasicType{Val{:ComplexMPC}})
    c = Basic(b)
    a = Basic()
    ccall((:complex_mpc_imaginary_part, libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &c)
    return a
end

function convert(::Type{Complex{Cdouble}}, b::BasicType{Val{:ComplexDouble}})
    return complex(convert(Cdouble, real(b)), convert(Cdouble, imag(b)))
end

function convert(::Type{BigFloat}, b::BasicType{Val{:RealMPFR}})
    c = Basic(b)
    a = BigFloat()
    ccall((:real_mpfr_get, libsymengine), Void, (Ptr{BigFloat}, Ptr{Basic}), &a, &c)
    return a
end

function N(b::BasicType{Val{:Integer}})
    a = convert(BigInt, b)
    if (a.size > 1 || a.size < -1)
        return a
    elseif (a.size == 0)
        return 0
    else
        u = unsafe_load(a.d, 1)
        if u <= typemax(Int64)
            return Int64(u) * sign(a)
        elseif sign(a) == 1
            return u
        else
            return a
        end
    end
end

N(b::Basic) = N(BasicType(b))
N(b::BasicType{Val{:RealDouble}}) = convert(Cdouble, b)
# TODO: Implement rational_get_mpq in cwrapper.h
N(b::BasicType{Val{:Rational}}) = eval(parse(replace(toString(b), "/", "//")))
N(b::BasicType{Val{:RealMPFR}}) = convert(BigFloat, b)
N(b::BasicComplexNumber) = complex(N(real(b)), N(imag(b)))

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

function evalf(b::Basic, bits::Integer=53, real::Bool=false)
    c = Basic()
    status = ccall((:basic_evalf, libsymengine), Cint, (Ptr{Basic}, Ptr{Basic}, Culong, Cint), &c, &b, Culong(bits), Int(real))
    if status == 0
        return c
    else
        throw(ArgumentError("libsymengine has to be compiled with MPFR and MPC for eval with precision greater than 53."))
    end
end
