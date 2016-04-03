import Base.Operators: +, -, ^, /, //, \, *, ==

## equality
function ==(b1::SymbolicType, b2::SymbolicType)
    b1,b2 = map(Basic, (b1, b2))
    ccall((:basic_eq, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}), &b1, &b2) == 1
end


## main ops
for (op, libnm) in ((:+, :add), (:-, :sub), (:*, :mul), (:/, :div), (://, :div), (:^, :pow))
    tup = (Base.symbol("basic_$libnm"), :libsymengine)
    @eval begin
        function ($op)(b1::Basic, b2::Basic)
            a = Basic()
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
            return a
        end
        ($op)(b1::BasicType, b2::BasicType) = ($op)(Basic(b1), Basic(b2))
    end
end

^{T<:SymbolicType, S <: Integer}(a::T, b::S) = Basic(a)^Basic(b)
^{T<:SymbolicType, S <: Rational}(a::T, b::S) = Basic(a)^Basic(b)
+(b::SymbolicType) = b
-(b::SymbolicType) = 0 - b
\(b1::SymbolicType, b2::SymbolicType) = b2 / b1


## ## constants
Base.zero(x::Basic) = Basic(0)
Base.zero{T<:Basic}(::Type{T}) = Basic(0)
Base.one(x::Basic) = Basic(1)
Base.one{T<:Basic}(::Type{T}) = Basic(1)

Base.zero(x::BasicType) = BasicType(Basic(0))
Base.zero{T<:BasicType}(::Type{T}) = BasicType(Basic(0))
Base.one(x::BasicType) = BasicType(Basic(1))
Base.one{T<:BasicType}(::Type{T}) = BasicType(Basic(1))


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
    
## ## Conversions
Base.convert(::Type{Basic}, x::Irrational{:π}) = PI
Base.convert(::Type{Basic}, x::Irrational{:e}) = E
Base.convert(::Type{Basic}, x::Irrational{:γ}) = EulerGamma
#Base.convert(::Type{Basic}, x::Irrational{:catalan}) = ???
Base.convert(::Type{Basic}, x::Irrational{:φ}) = (1 + Basic(5)^Basic(1//2))/2
Base.convert(::Type{BasicType}, x::Irrational) = BasicType(convert(Basic, x))



## Logical operators
Base.(:<)(x::SymbolicType, y::SymbolicType) = N(x) < N(y)
Base.(:<)(x::SymbolicType, y) = <(promote(x,y)...)
Base.(:<)(x, y::SymbolicType) = <(promote(x,y)...)
