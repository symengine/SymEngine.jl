import Base: convert, real, imag, num, den, float
import Base: isfinite, isnan, isinf, isless
import Base: trunc, ceil, floor, round


function evalf(b::Basic, bits::Integer=53, real::Bool=false)
    c = Basic()
    status = ccall((:basic_evalf, libsymengine), Cint, (Ptr{Basic}, Ptr{Basic}, Culong, Cint), &c, &b, Culong(bits), Int(real))
    if status == 0
        return c
    else
        throw(ArgumentError("libsymengine has to be compiled with MPFR and MPC for eval with precision greater than 53."))
    end
end

## Conversions from SymEngine -> Julia at the ccall level
function convert(::Type{BigInt}, b::BasicType{Val{:Integer}})
    a = BigInt()
    c = Basic(b)
    ccall((:integer_get_mpz, libsymengine), Void, (Ptr{BigInt}, Ptr{Basic}), &a, &c)
    return a
end


function convert(::Type{BigFloat}, b::BasicType{Val{:RealMPFR}})
    c = Basic(b)
    a = BigFloat()
    ccall((:real_mpfr_get, libsymengine), Void, (Ptr{BigFloat}, Ptr{Basic}), &a, &c)
    return a
end

function convert(::Type{Cdouble}, b::BasicType{Val{:RealDouble}})
    c = Basic(b)
    return ccall((:real_double_get_d, libsymengine), Cdouble, (Ptr{Basic},), &c)
end

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


##################################################
# N
"""

Convert a SymEngine numeric value into a Julian number

"""
N(a::Integer) = a
N(a::Rational) = a
N(a::Complex) = a
N(b::Basic) = N(BasicType(b))

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

N(b::BasicType{Val{:Rational}}) = Rational(N(num(b)), N(den(b))) # TODO: conditionally wrap rational_get_mpq from cwrapper.h
N(b::BasicType{Val{:RealDouble}}) = convert(Cdouble, b)
N(b::BasicType{Val{:RealMPFR}}) = convert(BigFloat, b)

N(b::BasicComplexNumber) = complex(N(real(b)), N(imag(b)))
function N(b::BasicType)
    b = convert(Basic, b)
    fs = free_symbols(b)
    if length(fs) > 0
        throw(ArgumentError("Object can have no free symbols"))
    end
    out = evalf(b)
    imag(out) == Basic(0.0) ? real(out) : out
end
        

##  Conversions SymEngine -> Julia 

## Rational: TODO: follow symengine/symengine#1143 for support in the cwrapper
den(x::Basic)                     = den(BasicType(x))
den(x::BasicType{Val{:Integer}})  = Basic(1)
den(x::BasicType{Val{:Rational}}) = Basic(String(copy(split(SymEngine.toString(x), "/"))[2]))
den(x::BasicComplexNumber)        = imag(x) == Basic(0) ? den(real(x)) : throw(InexactError())
den(x::BasicType)                 = throw(InexactError())

num(x::Basic)                     = num(BasicType(x))
num(x::BasicType{Val{:Integer}})  = Basic(x)
num(x::BasicType{Val{:Rational}}) = Basic(String(copy(split(SymEngine.toString(x), "/"))[1]))
num(x::BasicComplexNumber)        = imag(x) == Basic(0) ? num(real(x)) : throw(InexactError())
num(x::BasicType)                 = throw(InexactError())


## Complex
real(x::Basic) = real(SymEngine.BasicType(x))
real(x::SymEngine.BasicType) = x

imag(x::Basic) = imag(SymEngine.BasicType(x))
imag(x::BasicType{Val{:Integer}}) = Basic(0)
imag(x::BasicType{Val{:RealDouble}}) = Basic(0)
imag(x::BasicType{Val{:RealMPFR}}) = Basic(0)
imag(x::BasicType{Val{:Rational}}) = Basic(0)
imag(x::SymEngine.BasicType) = throw(InexactError())


convert(::Type{Complex{Float64}}, x::Basic)  = convert(Complex{Float64}, N(evalf(x, 53, false)))
convert(::Type{Complex{BigFloat}}, x::Basic) = convert(Complex{Float64}, N(evalf(x, precision(BigFloat), false)))
convert{T}(::Type{Complex{T}}, x::Basic)     = complex(convert(T, real(x)), convert(T, imag(x)))

## define convert(T, x) methods leveraging N()
convert(::Type{Float64}, x::Basic)      = convert(Float64, N(evalf(x, 53, true)))
convert(::Type{BigFloat}, x::Basic)     = convert(BigFloat, N(evalf(x, precision(BigFloat), true)))
convert{T <: Real}(::Type{T}, x::Basic) = convert(T, N(x))


## For generic programming in Julia
float(x::Basic) = float(N(x))

# trunc, flooor, ceil, round, rem, mod, cld, fld, 
isfinite(x::Basic) = x-x == 0
isnan(x::Basic) = isnan(N(x))
isinf(x::Basic) = !isnan(x) & !isfinite(x)
isless(x::Basic, y::Basic) = isless(N(x), N(y))


## These should have support in symengine-wrapper, but currently don't
trunc(x::Basic, args...) = Basic(trunc(N(x), args...))  
trunc{T <: Integer}(::Type{T},x::Basic, args...) = convert(T, trunc(x,args...))

ceil(x::Basic) = Basic(ceil(N(x)))
ceil{T <: Integer}(::Type{T},x::Basic) = convert(T, ceil(x))

floor(x::Basic) = Basic(floor(N(x)))
floor{T <: Integer}(::Type{T},x::Basic) = convert(T, floor(x))

round(x::Basic) = Basic(round(N(x)))
round{T <: Integer}(::Type{T},x::Basic) = convert(T, round(x))
