import Base: convert, real, imag, float, eps
import Base: isfinite, isnan, isinf, isless
import Base: trunc, ceil, floor, round


function evalf(b::Basic, bits::Integer=53, real::Bool=false)
    c = Basic()
    bits > 53 && real && (have_mpfr || throw(ArgumentError("libsymengine has to be compiled with MPFR for this feature")))
    bits > 53 && !real && (have_mpc || throw(ArgumentError("libsymengine has to be compiled with MPC for this feature")))
    status = ccall((:basic_evalf, libsymengine), Cint, (Ref{Basic}, Ref{Basic}, Culong, Cint), c, b, Culong(bits), Int(real))
    if status == 0
        return c
    else
        throw(ArgumentError("symbolic value cannot be evaluated to a numeric value"))
    end
end

## Conversions from SymEngine -> Julia at the ccall level
function convert(::Type{BigInt}, b::BasicType{Val{:Integer}})
    a = BigInt()
    c = Basic(b)
    ccall((:integer_get_mpz, libsymengine), Nothing, (Ref{BigInt}, Ref{Basic}), a, c)
    return a
end


function convert(::Type{BigFloat}, b::BasicType{Val{:RealMPFR}})
    c = Basic(b)
    a = BigFloat()
    ccall((:real_mpfr_get, libsymengine), Nothing, (Ref{BigFloat}, Ref{Basic}), a, c)
    return a
end

function convert(::Type{Cdouble}, b::BasicType{Val{:RealDouble}})
    c = Basic(b)
    return ccall((:real_double_get_d, libsymengine), Cdouble, (Ref{Basic},), c)
end

if SymEngine.libversion >= VersionNumber("0.4.0")

    function real(b::BasicComplexNumber)
        c = Basic(b)
        a = Basic()
        ccall((:complex_base_real_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

    function imag(b::BasicComplexNumber)
        c = Basic(b)
        a = Basic()
        ccall((:complex_base_imaginary_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

else

    function real(b::BasicType{Val{:ComplexDouble}})
        c = Basic(b)
        a = Basic()
        ccall((:complex_double_real_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

    function imag(b::BasicType{Val{:ComplexDouble}})
        c = Basic(b)
        a = Basic()
        ccall((:complex_double_imaginary_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

    function real(b::BasicType{Val{:Complex}})
        c = Basic(b)
        a = Basic()
        ccall((:complex_real_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

    function imag(b::BasicType{Val{:Complex}})
        c = Basic(b)
        a = Basic()
        ccall((:complex_imaginary_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

    function real(b::BasicType{Val{:ComplexMPC}})
        c = Basic(b)
        a = Basic()
        ccall((:complex_mpc_real_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

    function imag(b::BasicType{Val{:ComplexMPC}})
        c = Basic(b)
        a = Basic()
        ccall((:complex_mpc_imaginary_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, c)
        return a
    end

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
        w = signed(u)
        if w > 0
            return w * a.size
        elseif a.size == 1
            return u
        else
            return a
        end
    end
end

N(b::BasicType{Val{:Rational}}) = Rational(N(numerator(b)), N(denominator(b))) # TODO: conditionally wrap rational_get_mpq from cwrapper.h
N(b::BasicType{Val{:RealDouble}}) = convert(Cdouble, b)
N(b::BasicType{Val{:RealMPFR}}) = convert(BigFloat, b)
N(b::BasicType{Val{:NaN}}) = NaN
N(b::BasicType{Val{:Infty}}) = (string(b) == "-inf") ? -Inf : Inf

## Mapping of SymEngine Constants into julia values
constant_map = Dict("pi" => π, "eulergamma" => γ, "exp(1)" => e, "catalan" => catalan,
                    "goldenratio" => φ)

N(b::BasicType{Val{:Constant}}) = constant_map[toString(b)]

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
function as_numer_denom(x::Basic)
    a, b = Basic(), Basic()
    ccall((:basic_as_numer_denom, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b, x)
    return a, b
end

as_numer_denom(x::BasicType) = as_numer_denom(Basic(x))
denominator(x::SymbolicType) = as_numer_denom(x)[2]
numerator(x::SymbolicType)   = as_numer_denom(x)[1]

## Complex
real(x::Basic) = Basic(real(SymEngine.BasicType(x)))
real(x::SymEngine.BasicType) = x

imag(x::Basic) = Basic(imag(SymEngine.BasicType(x)))
imag(x::BasicType{Val{:Integer}}) = Basic(0)
imag(x::BasicType{Val{:RealDouble}}) = Basic(0)
imag(x::BasicType{Val{:RealMPFR}}) = Basic(0)
imag(x::BasicType{Val{:Rational}}) = Basic(0)
imag(x::SymEngine.BasicType) = throw(InexactError())

## define convert(T, x) methods leveraging N()
convert(::Type{Float64}, x::Basic)           = convert(Float64, N(evalf(x, 53, true)))
convert(::Type{BigFloat}, x::Basic)          = convert(BigFloat, N(evalf(x, precision(BigFloat), true)))
convert(::Type{Complex{Float64}}, x::Basic)  = convert(Complex{Float64}, N(evalf(x, 53, false)))
convert(::Type{Complex{BigFloat}}, x::Basic) = convert(Complex{BigFloat}, N(evalf(x, precision(BigFloat), false)))
convert(::Type{Number}, x::Basic)            = x
convert(::Type{T}, x::Basic) where {T <: Real}      = convert(T, N(x))
convert(::Type{Complex{T}}, x::Basic) where {T <: Real}    = convert(Complex{T}, N(x))

# Constructors no longer fall back to `convert` methods
Base.Int64(x::Basic) = convert(Int64, x)
Base.Int32(x::Basic) = convert(Int32, x)
Base.Float32(x::Basic) = convert(Float32, x)
Base.Float64(x::Basic) = convert(Float64, x)
Base.BigInt(x::Basic) = convert(BigInt, x)
Base.Real(x::Basic) = convert(Real, x)

## For generic programming in Julia
float(x::Basic) = float(N(x))

# trunc, flooor, ceil, round, rem, mod, cld, fld,
isfinite(x::Basic) = x-x == 0
isnan(x::Basic) = ( x == NAN )
isinf(x::Basic) = !isnan(x) & !isfinite(x)
isless(x::Basic, y::Basic) = isless(N(x), N(y))


## These should have support in symengine-wrapper, but currently don't
trunc(x::Basic, args...) = Basic(trunc(N(x), args...))  
trunc(::Type{T},x::Basic, args...) where {T <: Integer} = convert(T, trunc(x,args...))

ceil(x::Basic) = Basic(ceil(N(x)))
ceil(::Type{T},x::Basic) where {T <: Integer} = convert(T, ceil(x))

floor(x::Basic) = Basic(floor(N(x)))
floor(::Type{T},x::Basic) where {T <: Integer} = convert(T, floor(x))

round(x::Basic) = Basic(round(N(x)))
round(::Type{T},x::Basic) where {T <: Integer} = convert(T, round(x))

prec(x::BasicType{Val{:RealMPFR}}) = ccall((:real_mpfr_get_prec, libsymengine), Clong, (Ref{Basic},), x)

# eps
eps(x::Basic) = eps(BasicType(x))
eps(x::BasicType{T}) where {T} = eps(typeof(x))
eps(::Type{T}) where {T <: BasicType} = 0
eps(::Type{T}) where {T <: Basic} = 0
eps(::Type{BasicType{Val{:RealDouble}}}) = 2^-52
eps(::Type{BasicType{Val{:ComplexDouble}}}) = 2^-52
eps(x::BasicType{Val{:RealMPFR}}) = evalf(Basic(2), prec(x), true) ^ (-prec(x)+1)
eps(x::BasicType{Val{:ComplexMPFR}}) = eps(real(x))
