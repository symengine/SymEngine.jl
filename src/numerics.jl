import Base: convert, real, imag, float, eps, conj
import Base: isfinite, isnan, isinf, isless
import Base: trunc, ceil, floor, round


function evalf(b::Basic, bits::Integer=53, real::Bool=false)
    (b == oo || b == zoo || b == NAN) && return b
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

## Conversions from SymEngine.Basic -> Julia at the ccall level
function _convert(::Type{BigInt}, b::Basic)
    a = BigInt()
    _convert_bigint!(a, b)
    return a
end

function _convert_bigint!(a::BigInt, b::Basic) # non-allocating (sometimes)
    is_a_Integer(b) || throw(ArgumentError("Not an integer"))
    ccall((:integer_get_mpz, libsymengine), Nothing, (Ref{BigInt}, Ref{Basic}), a, b)
    a
end

function _convert(::Type{Int}, b::Basic)
    is_a_Integer(b) || throw(ArgumentError("Not an integer"))
    ccall((:integer_get_si, libsymengine), Int, (Ref{Basic},), b)
end

function _convert(::Type{BigFloat}, b::Basic)
    a = BigFloat()
    _convert_bigfloat!(a, b)
    return a
end

function _convert_bigfloat!(a::BigFloat, b::Basic) # non-allocating
    is_a_RealMPFR(b) || throw("Not a big value")
    ccall((:real_mpfr_get, libsymengine), Nothing, (Ref{BigFloat}, Ref{Basic}), a, b)
    a
end

function _convert(::Type{Cdouble}, b::Basic)
    is_a_RealDouble(b) || throw(ArgumentError("Not a real double"))
    return ccall((:real_double_get_d, libsymengine), Cdouble, (Ref{Basic},), b)
end


##################################################
# N
"""

Convert a SymEngine numeric value into a Julian number

"""
N(a::Integer) = a
N(a::Rational) = a
N(a::Complex) = a

N(b::Basic) = N(Val(get_symengine_class(b)), b)

function N(::Val{:Integer}, b::Basic)
    a = _convert(BigInt, b)
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

# TODO: conditionally wrap rational_get_mpq from cwrapper.h
N(::Val{:Rational},   b::Basic) = Rational(N(numerator(b)), N(denominator(b)))
N(::Val{:RealDouble}, b::Basic) = _convert(Cdouble, b)
N(::Val{:RealMPFR},   b::Basic) = _convert(BigFloat, b)
N(::Val{:Complex},    b::Basic) = complex(N(real(b)), N(imag(b)))
N(::Val{:ComplexMPC}, b::Basic) = complex(N(real(b)), N(imag(b)))
N(::Val{:ComplexDouble}, b::Basic) = complex(N(real(b)), N(imag(b)))

N(::Val{:NaN},        b::Basic) = NaN
function N(::Val{:Infty}, b::Basic)
    if b == oo
        return Inf
    elseif b == zoo
        return Complex(Inf,Inf)
    elseif b == -oo
        return -Inf
    else
        throw(ArgumentError("Unknown infinity symbol"))
    end
end

function N(::Val{:Constant}, b::Basic)
    if b == PI
        return π
    elseif b == EulerGamma
        return γ
    elseif b == E
        return ℯ
    elseif b == Catalan
        return catalan
    elseif b == GoldenRatio
        return φ
    else
        throw(ArgumentError("Unknown constant"))
    end
end

function N(::Val{<:Any}, b::Basic)
    is_constant(b) ||
        throw(ArgumentError("Object can have no free symbols"))
    out = evalf(b)
    imag(out) == Basic(0.0) ? N(real(out)) : N(out)
end

## deprecate N(::BasicType)
N(b::BasicType{T}) where {T} = N(convert(Basic, b), T)

## define convert(T, x) methods leveraging N() when needed
function convert(::Type{Float64}, x::Basic)
    is_a_RealDouble(x) && return _convert(Cdouble, x)
    convert(Float64, N(evalf(x, 53, true)))
end

function convert(::Type{BigFloat}, x::Basic)
    is_a_RealMPFR(x) && return _convert(BigFloat, x)
    convert(BigFloat, N(evalf(x, precision(BigFloat), true)))
end

function convert(::Type{Complex{Float64}}, x::Basic)
    z = is_a_ComplexDouble(x) ? x : evalf(x, 53, false)
    a,b = _real(z), _imag(z)
    u,v = _convert(Cdouble, a), _convert(Cdouble, b)
    return complex(u,v)
end

function convert(::Type{Complex{BigFloat}}, x::Basic)
    z =  is_a_ComplexMPC(x) ? x : evalf(x, precision(BigFloat), false)
    a,b = _real(z), _imag(z)
    u,v = _convert(BigFloat, a), _convert(BigFloat, b)
    return complex(u,v)
end

convert(::Type{Number}, x::Basic)            = x
convert(::Type{T}, x::Basic) where {T <: Real}      = convert(T, N(x))
convert(::Type{Complex{T}}, x::Basic) where {T <: Real}    = convert(Complex{T}, N(x))

# Constructors no longer fall back to `convert` methods
Base.Int64(x::Basic)   = convert(Int64, x)
Base.Int32(x::Basic)   = convert(Int32, x)
Base.Float32(x::Basic) = convert(Float32, x)
Base.Float64(x::Basic) = convert(Float64, x)
Base.BigInt(x::Basic)  = convert(BigInt, x)
Base.Real(x::Basic)    = convert(Real, x)


##  Rational --  p/q parts
function as_numer_denom(x::Basic)
    a, b = Basic(), Basic()
    ccall((:basic_as_numer_denom, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b, x)
    return a, b
end

as_numer_denom(x::BasicType) = as_numer_denom(Basic(x))
denominator(x::SymbolicType) = as_numer_denom(x)[2]
numerator(x::SymbolicType)   = as_numer_denom(x)[1]

## Complex
# b::Basic -> a::Basic
function _real(b::Basic)
    if is_a_RealDouble(b) || is_a_RealMPFR(b) || is_a_Integer(b) || is_a_Rational(b)
        return b
    end
    if !(is_a_Complex(b) || is_a_ComplexDouble(b) || is_a_ComplexMPC(b))
        throw(ArgumentError("Not a complex number"))
    end
    a = Basic()
    ccall((:complex_base_real_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, b)
    return a
end

function _imag(b::Basic)
    if !(is_a_Complex(b) || is_a_ComplexDouble(b) || is_a_ComplexMPC(b))
        throw(ArgumentError("Not a complex number"))
    end
    a = Basic()
    ccall((:complex_base_imaginary_part, libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, b)
    return a
end

real(x::Basic) = Basic(real(SymEngine.BasicType(x)))
real(x::SymEngine.BasicType) = x

imag(x::Basic) = Basic(imag(SymEngine.BasicType(x)))
imag(x::BasicType{Val{:Integer}}) = Basic(0)
imag(x::BasicType{Val{:RealDouble}}) = Basic(0)
imag(x::BasicType{Val{:RealMPFR}}) = Basic(0)
imag(x::BasicType{Val{:Rational}}) = Basic(0)
imag(x::SymEngine.BasicType) = throw(InexactError())

# Because of the definitions above, `real(x) == x` for `x::Basic`
# such as `x = symbols("x")`. Thus, it is consistent to define the
conj(x::Basic) = Basic(conj(SymEngine.BasicType(x)))
# To allow future extension, we define the fallback on `BasicType``.
conj(x::BasicType) = 2 * real(x.x) - x.x


## For generic programming in Julia
float(x::Basic) = float(N(x))

# trunc, flooor, ceil, round, rem, mod, cld, fld,
isfinite(x::Basic) = x-x == 0
isnan(x::Basic) = ( x == NAN )
isinf(x::Basic) = !isnan(x) & !isfinite(x)
isless(x::Basic, y::Basic) = isless(N(x), N(y))

# is_a_functions
# could use metaprogramming here
is_a_Number(x::Basic) =
    Bool(convert(Int, ccall((:is_a_Number, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_Integer(x::Basic) =
    Bool(convert(Int, ccall((:is_a_Integer, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_Rational(x::Basic) =
    Bool(convert(Int, ccall((:is_a_Rational, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_RealDouble(x::Basic) =
    Bool(convert(Int, ccall((:is_a_RealDouble, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_RealMPFR(x::Basic) =
    Bool(convert(Int, ccall((:is_a_RealMPFR, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_Complex(x::Basic) =
    Bool(convert(Int, ccall((:is_a_Complex, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_ComplexDouble(x::Basic) =
    Bool(convert(Int, ccall((:is_a_ComplexDouble, libsymengine),
                            Cuint, (Ref{Basic},), x)))
is_a_ComplexMPC(x::Basic) =
    Bool(convert(Int, ccall((:is_a_ComplexMPC, libsymengine),
                            Cuint, (Ref{Basic},), x)))

Base.isinteger(x::Basic) = is_a_Integer(x)
function Base.isreal(x::Basic)
    is_a_Number(x) || return false
    is_a_Integer(x) || is_a_Rational(x) || is_a_RealDouble(x) || is_a_RealMPFR(x)
end

# may not allocate; seems more idiomatic than default x == zero(x)
function Base.iszero(x::Basic)
    is_a_Number(x) || return false
    x == zero(x)
end

function Base.isone(x::Basic)
    is_a_Number(x) || return false
    x == one(x)
end



## These should have support in symengine-wrapper, but currently don't
trunc(x::Basic, args...) = Basic(trunc(N(x), args...))
trunc(::Type{T},x::Basic, args...) where {T <: Integer} = convert(T, trunc(x,args...))

round(x::Basic; kwargs...) = Basic(round(N(x); kwargs...))
round(::Type{T},x::Basic; kwargs...) where {T <: Integer} = convert(T, round(x; kwargs...))

prec(x::Basic) = prec(BasicType(x))
prec(x::BasicType{Val{:RealMPFR}}) = ccall((:real_mpfr_get_prec, libsymengine), Clong, (Ref{Basic},), x)
prec(::BasicType) = throw(ArgumentError("Method not applicable"))

# eps
eps(x::Basic) = eps(BasicType(x))
eps(x::BasicType{T}) where {T} = eps(typeof(x))
eps(::Type{T}) where {T <: BasicType} = 0
eps(::Type{T}) where {T <: Basic} = 0
eps(::Type{BasicType{Val{:RealDouble}}}) = 2^-52
eps(::Type{BasicType{Val{:ComplexDouble}}}) = 2^-52
eps(x::BasicType{Val{:RealMPFR}}) = evalf(Basic(2), prec(x), true) ^ (-prec(x)+1)
eps(x::BasicType{Val{:ComplexMPFR}}) = eps(real(x))

## convert from BasicType
function convert(::Type{BigInt}, b::BasicType{Val{:Integer}})
    _convert(BigInt, Basic(b))
end

function convert(::Type{BigFloat}, b::BasicType{Val{:RealMPFR}})
    _convert(BigInt, Basic(b))
end

function convert(::Type{Cdouble}, b::BasicType{Val{:RealDouble}})
    _convert(Cdouble, Basic(b))
end

## real/imag for BasicType
function real(b::BasicComplexNumber)
    _real(Basic(b))
end

function imag(b::BasicComplexNumber)
    _imag(Basic(b))
end
## end deprecate
