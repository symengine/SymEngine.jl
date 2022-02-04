import Base: +, -, ^, /, //, \, *, ==, sum, prod

## equality
function ==(b1::SymbolicType, b2::SymbolicType)
    b1,b2 = map(Basic, (b1, b2))
    ccall((:basic_eq, libsymengine), Int, (Ref{Basic}, Ref{Basic}), b1, b2) == 1
end


## main ops
for (op, libnm) in ((:+, :add), (:-, :sub), (:*, :mul), (:/, :div), (://, :div), (:^, :pow))
    tup = (Base.Symbol("basic_$libnm"), libsymengine)
    @eval begin
        function ($op)(b1::Basic, b2::Basic)
            a = Basic()
            err_code = ccall($tup, Cuint, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b1, b2)
            throw_if_error(err_code, $(string(libnm)))
            return a
        end
        ($op)(b1::BasicType, b2::BasicType) = ($op)(Basic(b1), Basic(b2))
    end
end

^(a::T, b::S) where {T<:SymbolicType, S <: Integer} = Basic(a)^Basic(b)
^(a::T, b::S) where {T<:SymbolicType, S <: Rational} = Basic(a)^Basic(b)
+(b::SymbolicType) = b
-(b::SymbolicType) = 0 - b
\(b1::SymbolicType, b2::SymbolicType) = b2 / b1

# In contrast to other standard operations such as `+`, `*`, `-`, and `/`,
# Julia doesn't implement a general fallback of `//` for `Number`s promoting
# the input arguments. Thus, we implement this here explicitly.
Base.:(//)(b1::SymbolicType, b2::Number) = //(promote(b1, b2)...)
Base.:(//)(b1::Number, b2::SymbolicType) = //(promote(b1, b2)...)


function sum(v::CVecBasic)
    a = Basic()
    err_code = ccall((:basic_add_vec, libsymengine), Cuint, (Ref{Basic}, Ptr{Cvoid}), a, v.ptr)
    throw_if_error(err_code, "add_vec")
    return a
end

+(b1::Basic, b2::Basic, b3::Basic, bs...) = sum(convert(CVecBasic, [b1, b2, b3, bs...]))
+(b1::Basic, b2::Basic, b3, bs...) = +(Basic(b1), Basic(b2), Basic(b3), bs...)
+(b1, b2::Basic, b3::Basic, bs...) = +(Basic(b1), Basic(b2), Basic(b3), bs...)
+(b1::Basic, b2, b3::Basic, bs...) = +(Basic(b1), Basic(b2), Basic(b3), bs...)

+(b1::Basic, b2, b3, bs...) = +(Basic(b1), Basic(b2), Basic(b3), bs...)
+(b1, b2::Basic, b3, bs...) = +(Basic(b1), Basic(b2), Basic(b3), bs...)
+(b1, b2, b3::Basic, bs...) = +(Basic(b1), Basic(b2), Basic(b3), bs...)


function prod(v::CVecBasic)
    a = Basic()
    err_code = ccall((:basic_mul_vec, libsymengine), Cuint, (Ref{Basic}, Ptr{Cvoid}), a, v.ptr)
    throw_if_error(err_code, "add_mul")
    return a
end

*(b1::Basic, b2::Basic, b3::Basic, bs...) = prod(convert(CVecBasic, [b1, b2, b3, bs...]))
*(b1::Basic, b2::Basic, b3, bs...) = *(Basic(b1), Basic(b2), Basic(b3), bs...)
*(b1, b2::Basic, b3::Basic, bs...) = *(Basic(b1), Basic(b2), Basic(b3), bs...)
*(b1::Basic, b2, b3::Basic, bs...) = *(Basic(b1), Basic(b2), Basic(b3), bs...)

*(b1::Basic, b2, b3, bs...) = *(Basic(b1), Basic(b2), Basic(b3), bs...)
*(b1, b2::Basic, b3, bs...) = *(Basic(b1), Basic(b2), Basic(b3), bs...)
*(b1, b2, b3::Basic, bs...) = *(Basic(b1), Basic(b2), Basic(b3), bs...)

## ## constants
Base.zero(x::Basic) = Basic(0)
Base.zero(::Type{T}) where {T<:Basic} = Basic(0)
Base.one(x::Basic) = Basic(1)
Base.one(::Type{T}) where {T<:Basic} = Basic(1)

Base.zero(x::BasicType) = BasicType(Basic(0))
Base.zero(::Type{T}) where {T<:BasicType} = BasicType(Basic(0))
Base.one(x::BasicType) = BasicType(Basic(1))
Base.one(::Type{T}) where {T<:BasicType} = BasicType(Basic(1))


## Math constants
## no oo!

for op in [:IM, :PI, :E, :EulerGamma, :Catalan, :oo, :zoo, :NAN]
    @eval begin
        const $op = Basic(C_NULL)
    end
    eval(Expr(:export, op))
end

macro init_constant(op, libnm)
    tup = (Base.Symbol("basic_const_$libnm"), libsymengine)
    alloc_tup = (:basic_new_stack, libsymengine)
    :(
        begin
            ccall($alloc_tup, Nothing, (Ref{Basic}, ), $op)
            ccall($tup, Nothing, (Ref{Basic}, ), $op)
            finalizer(basic_free, $op)
        end
    )
end

function init_constants()
    @init_constant IM I
    @init_constant PI pi
    @init_constant E E
    @init_constant EulerGamma EulerGamma
    @init_constant Catalan Catalan
    @init_constant oo infinity
    @init_constant zoo complex_infinity
    @init_constant NAN nan
end

## ## Conversions
Base.convert(::Type{Basic}, x::Irrational{:π}) = PI
Base.convert(::Type{Basic}, x::Irrational{:e}) = E
Base.convert(::Type{Basic}, x::Irrational{:γ}) = EulerGamma
Base.convert(::Type{Basic}, x::Irrational{:catalan}) = Catalan
Base.convert(::Type{Basic}, x::Irrational{:φ}) = (1 + Basic(5)^Basic(1//2))/2
Base.convert(::Type{BasicType}, x::Irrational) = BasicType(convert(Basic, x))

## Logical operators
Base.:<(x::SymbolicType, y::SymbolicType) = N(x) < N(y)
Base.:<(x::SymbolicType, y) = <(promote(x,y)...)
Base.:<(x, y::SymbolicType) = <(promote(x,y)...)

## Other Basic Operations
Base.copysign(x::SymEngine.Basic,y::SymEngine.BasicType) = sign(y)*abs(x)
