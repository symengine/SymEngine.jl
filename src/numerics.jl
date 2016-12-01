import Base: convert, real, imag, num, den
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


function convert(::Type{Complex{Cdouble}}, b::BasicType{Val{:ComplexDouble}})
    return complex(convert(Cdouble, real(b)), convert(Cdouble, imag(b)))
end


##  Conversions SymEngine -> Julia being more systematic
##need Int, BigInt,  Float64, BigFloat, Complex{T} Rational{Int}, Rational{BigInt},
##BasicTypes: Integer, Rational, RealDouble, RealMPFR, :Complex, :ComplexDouble, :ComplexMPC

## Int
convert(::Type{Int}, x::Basic) = convert(Int, BasicType(x))
convert(::Type{Int}, x::BasicType{Val{:Integer}}) = convert(Int, convert(BigInt,x))
convert(::Type{Int}, x::BasicType{Val{:Rational}}) = den(x) == 1 ? convert(Int, num(x)) : throw(InexactError())
convert(::Type{Int}, x::BasicType{Val{:RealDouble}}) = convert(Int, convert(Float64, x))
convert(::Type{Int}, x::BasicType{Val{:RealMPFR}}) = convert(Int, convert(BigFloat, x))
convert(::Type{Int}, x::BasicComplexNumber) = imag(x) == 0 ? convert(Int, real(x)) : throw(InexactError())
convert(::Type{Int}, x::BasicType) = convert(Int, convert(Float64, evalf(Basic(x), 53, true)))



## BigInt
convert(::Type{BigInt}, x::Basic) = convert(BigInt, BasicType(x))
#function convert(::Type{BigInt}, x::BasicType{Val{:Integer}})
convert(::Type{BigInt}, x::BasicType{Val{:Rational}}) = den(x) == 1 ? convert(BigInt, num(x)) : throw(InexactError())
convert(::Type{BigInt}, x::BasicType{Val{:RealDouble}}) = convert(BigInt, convert(Float64, x))
convert(::Type{BigInt}, x::BasicType{Val{:RealMPFR}}) = convert(BigInt, convert(BigFloat, x))
convert(::Type{BigInt}, x::BasicComplexNumber) = imag(x) == 0 ? convert(BigInt, real(x)) : throw(InexactError())
convert(::Type{BigInt}, x::BasicType) = throw(InexactError())

## Float64
convert(::Type{Float64}, x::Basic) = convert(Float64, BasicType(x))
convert(::Type{Float64}, x::BasicType{Val{:Integer}}) = convert(Float64, convert(BigInt, x))
##convert(::Type{Float64}, x::BasicType{Val{:RealDouble}}) =
convert(::Type{Float64}, x::BasicType{Val{:RealMPFR}}) = convert(Float64, convert(BigFloat, x))
convert(::Type{Float64}, x::BasicComplexNumber) = imag(x) == 0 ? convert(Float64, real(x)) : throw(InexactError())
convert(::Type{Float64}, x::BasicType) = convert(Float64, evalf(Basic(x), 53, true))


## BigFloat
convert(::Type{BigFloat}, x::Basic) = convert(BigFloat, BasicType(x))
convert(::Type{BigFloat}, x::BasicType{Val{:Integer}}) = BigFloat(convert(BigInt, x))
convert(::Type{BigFloat}, x::BasicType{Val{:Rational}}) = BigFloat(convert(Rational{BigInt}, x))
convert(::Type{BigFloat}, x::BasicType{Val{:RealDouble}}) = convert(BigFloat, convert(Float64, x))
#convert(::Type{Float64}, x::BasicType{Val{:RealMPFR}}) 
convert(::Type{BigFloat}, x::BasicComplexNumber) = imag(x) == 0 ? convert(BigFloat, real(x)) : throw(InexactError())
convert(::Type{BigFloat}, x::BasicType) = throw(InexactError())

## Rational
Base.den(x::Basic) = den(BasicType(x))
Base.den(x::BasicType{Val{:Integer}}) = Basic(1)
Base.den(x::BasicType{Val{:Rational}}) = Basic(String(copy(split(SymEngine.toString(x), "/"))[2]))
Base.den(x::BasicComplexNumber) = imag(x) == 0 ? den(real(x)) : throw(InexactError())
Base.den(x::BasicType) = Basic(1)

Base.num(x::Basic) = num(BasicType(x))
Base.num(x::BasicType{Val{:Integer}}) = Basic(x)
Base.num(x::BasicType{Val{:Rational}}) = Basic(String(copy(split(SymEngine.toString(x), "/"))[1]))
Base.num(x::BasicComplexNumber) = imag(x) == 0 ? num(real(x)) : throw(InexactError())
Base.num(x::BasicType) = throw(InexactError())

convert{T}(::Type{Rational{T}}, x::Basic) = convert(Rational{T}, BasicType(x))
convert{T}(::Type{Rational{T}}, x::BasicType{Val{:RealDouble}}) = convert(Rational, convert(Float64, x))
convert{T}(::Type{Rational{T}}, x::BasicType) = Rational(convert(T, num(x)), convert(T, den(x)))


## Complex
Base.real(x::Basic) = real(SymEngine.BasicType(x))
## BasicComplexNumber elsewhere
Base.real(x::SymEngine.BasicType) = x

Base.imag(x::Basic) = imag(SymEngine.BasicType(x))
Base.imag(x::BasicType{Val{:Integer}}) = 0
Base.imag(x::BasicType{Val{:RealDouble}}) = 0
Base.imag(x::BasicType{Val{:RealMPFR}}) = 0
Base.imag(x::BasicType{Val{:Rational}}) = 0
Base.imag(x::SymEngine.BasicType) = x

convert{T}(::Type{Complex{T}}, x::Basic) = complex(convert(T, real(x)), convert(T, imag(x)))


##################################################
# N
"""

Convert a SymEngine numeric value into a number

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

N(b::BasicType{Val{:Rational}}) = Rational(N(num(b)), N(den(b))) # TODO: Implement rational_get_mpq in cwrapper.h
N(b::BasicType{Val{:RealDouble}}) = convert(Cdouble, b)
N(b::BasicType{Val{:RealMPFR}}) = convert(BigFloat, b)

N(b::BasicComplexNumber) = complex(N(real(b)), N(imag(b)))
function N(b::BasicType)
    b = convert(Basic, b)
    fs = free_symbols(b)
    if length(fs) > 0
        throw(ArgumentError("Object can have no free symbols"))
    end
    eval(lambdify(b))
end
        


## For generic programming in Julia
Base.convert{T <: Real}(::Type{T}, x::Basic) = convert(T, N(x))
Base.float(x::Basic) = float(N(x))

# trunc, flooor, ceil, round, rem, mod, cld, fld, 
isfinite(x::Basic) = x-x == 0
isnan(x::Basic) = isnan(N(x))
isinf(x::Basic) = !isnan(x) & !isfinite(x)
isless(x::Basic, y::Basic) = isless(N(x), N(y))


## These are seriously hacky.
trunc(x::Basic, args...) = Basic(trunc(Float64(x), args...))  
trunc{T <: Integer}(::Type{T},x::Basic, args...) = convert(T, trunc(x,args...))

ceil(x::Basic) = Basic(ceil(Float64(x)))
ceil{T <: Integer}(::Type{T},x::Basic) = convert(T, ceil(x))

floor(x::Basic) = Basic(floor(Float64(x)))
floor{T <: Integer}(::Type{T},x::Basic) = convert(T, floor(x))

round(x::Basic) = Basic(round(Float64(x)))
round{T <: Integer}(::Type{T},x::Basic) = convert(T, round(x))
