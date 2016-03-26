import Base.Operators: +, -, ^, /, //, \, *, ==

## equality
function ==(b1::BasicType, b2::BasicType)
    b1 = b1.x; b2 = b2.x
    ccall((:basic_eq, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}), &b1, &b2) == 1
end


## main ops
for (op, libnm) in ((:+, :add), (:-, :sub), (:*, :mul), (:/, :div), (://, :div), (:^, :pow))
    tup = (Base.symbol("basic_$libnm"), :libsymengine)
    @eval begin
        function ($op)(b1::BasicType, b2::BasicType)
            a = Basic()
            b1,b2 = b1.x, b2.x
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
            return Sym(a)
        end
    end
end
    
^{T <: Integer}(a::BasicType, b::T) = a^BasicType(b)
^{T <: Rational}(a::BasicType, b::T) = a^BasicType(b)
+(b::BasicType) = b
-(b::BasicType) = 0 - b
\(b1::BasicType, b2::BasicType) = b2 / b1


## ## constants
Base.zero(x::BasicType) = BasicInteger(Basic(0))
Base.zero{T<:BasicType}(::Type{T}) = BasicInteger(Basic(0))
Base.one(x::Basic) = BasicInteger(Basic(1))
Base.one{T<:BasicType}(::Type{T}) = BasicInteger(Basic(1))


## Math constants 
## no oo!
for (op, libnm) in [(:IM, :I),
                 (:PI, :pi),
                 (:E, :E),
                 (:EulerGamma, :EulerGamma)
                 ]
    tup = (Base.symbol("basic_const_$libnm"), :libsymengine)
    @eval begin
        ($op) = begin
            a = Basic()
            ccall($tup, Void, (Ptr{Basic}, ), &a)
            Sym(a)
        end
    end
    eval(Expr(:export, op)) 
end
    
## ## Conversions
Base.convert{T<:BasicType}(::Type{T}, x::Irrational{:π}) = PI
Base.convert{T<:BasicType}(::Type{T}, x::Irrational{:e}) = E
Base.convert{T<:BasicType}(::Type{T}, x::Irrational{:γ}) = EulerGamma
Base.convert{T<:BasicType}(::Type{T}, x::Irrational{:catalan}) = sympy[:Catalan]
Base.convert{T<:BasicType}(::Type{T}, x::Irrational{:φ}) = (1 + Sym(5)^Sym(1//2))/2
Base.convert(::Type{Basic}, x::Irrational) = Basic(convert(BasicType, x))
