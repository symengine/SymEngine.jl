import Base.Operators: +, -, ^, /, \, *, ==

## equality
function ==(b1::Basic, b2::Basic)
    ccall((:basic_eq, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}), &b1, &b2) == 1
end


## main ops
for (op, libnm) in ((:+, :add), (:-, :sub), (:*, :mul), (:/, :div), (:^, :pow))
    tup = (Base.symbol("basic_$libnm"), :libsymengine)
    @eval begin
        function ($op)(b1::Basic, b2::Basic)
            a = Basic()
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
            return a
        end
    end
end
    
^{T <: Integer}(a::Basic, b::T) = a^Basic(b)
^{T <: Rational}(a::Basic, b::T) = a^Basic(b)
+(b::Basic) = b
-(b::Basic) = 0 - b
\(b1::Basic, b2::Basic) = b2 / b1


## constants
Base.zero(x::Basic) = Basic(0)
Base.zero(::Type{Basic}) = Basic(0)
Base.one(x::Basic) = Basic(1)
Base.one(::Type{Basic}) = Basic(1)


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
            a
        end
    end
    eval(Expr(:export, op)) 
end
    
## Conversions
Base.convert(::Type{Basic}, x::Irrational{:π}) = PI
Base.convert(::Type{Basic}, x::Irrational{:e}) = E
Base.convert(::Type{Basic}, x::Irrational{:γ}) = EulerGamma
Base.convert(::Type{Basic}, x::Irrational{:catalan}) = sympy[:Catalan]
Base.convert(::Type{Basic}, x::Irrational{:φ}) = (1 + Basic(5)^Basic(1//2))/2

