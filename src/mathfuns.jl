function IMPLEMENT_ONE_ARG_FUNC(meth, symnm; lib=:basic_)
     @eval begin
        function ($meth)(b::SymbolicType)
            a = Basic()
            ccall(($(string(lib,symnm)), libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
            return a
        end
    end
end

function IMPLEMENT_TWO_ARG_FUNC(meth, symnm; lib=:basic_)
     @eval begin
        function ($meth)(b1::SymbolicType, b2::Number)
            a = Basic()
            b1, b2 = promote(b1, b2)
            ccall(($(string(lib,symnm)), libsymengine), Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
            return a
        end
    end
end

## import from base one argument functions
## these are from cwrapper.cpp, one arg func
for (meth, libnm) in [
                      (:abs,:abs),
                      (:sin,:sin),
                      (:cos,:cos),
                      (:tan,:tan),
                      (:csc,:csc),
                      (:sec,:sec),
                      (:cot,:cot),
                      (:asin,:asin),
                      (:acos,:acos),
                      (:asec,:asec),
                      (:acsc,:acsc),
                      (:atan,:atan),
                      (:acot,:acot),
                      (:sinh,:sinh),
                      (:cosh,:cosh),
                      (:tanh,:tanh),
                      (:csch,:csch),
                      (:sech,:sech),
                      (:coth,:coth),
                      (:asinh,:asinh),
                      (:acosh,:acosh),
                      (:asech,:asech),
                      (:acsch,:acsch),
                      (:atanh,:atanh),
                      (:acoth,:acoth),
                      (:zeta,:zeta),
                      (:gamma,:gamma),
                      (:eta,:dirichlet_eta),
                      (:log,:log),
                      (:sqrt,:sqrt),
                      (:exp,:exp),
                      ]
    eval(Expr(:import, :Base, meth))
    IMPLEMENT_ONE_ARG_FUNC(meth, libnm)
end

# export not import
for  (meth, libnm) in [
                       (:lambertw,:lambertw)   # in add-on packages, not base
                       ]
    IMPLEMENT_ONE_ARG_FUNC(meth, libnm)    
    eval(Expr(:export, meth))
end

## add these in until they are wrapped
Base.cbrt(a::SymbolicType) = a^(1//3)
                  
for (meth, fn) in [(:sind, :sin), (:cosd, :cos), (:tand, :tan), (:secd, :sec), (:cscd, :csc), (:cotd, :cot)]
    eval(Expr(:import, :Base, meth))
    @eval begin
        $(meth)(a::SymbolicType) = $(fn)(a*PI/180)
    end
end


## Number theory module from cppwrapper
for (meth, libnm) in [(:gcd, :gcd),
                      (:lcm, :lcm),
                      (:div, :quotient),
                      (:mod, :mod_f),
                      ]
    eval(Expr(:import, :Base, meth))
    IMPLEMENT_TWO_ARG_FUNC(meth, libnm, lib=:ntheory_)    
end

Base.binomial(n::Basic, k::Number) = binomial(N(n), N(k))  #ntheory_binomial seems wrong
Base.rem(a::SymbolicType, b::SymbolicType) = a - (a ÷ b) * b
Base.factorial(n::SymbolicType, k) = factorial(N(n), N(k))

## but not (:fibonacci,:fibonacci), (:lucas, :lucas) (Basic type is not the signature)
for (meth, libnm) in [(:nextprime,:nextprime)
                      ]
    IMPLEMENT_ONE_ARG_FUNC(meth, libnm, lib=:ntheory_)    
    eval(Expr(:export, meth))
end

function Base.convert{T}(::Type{CVecBasic}, x::Vector{T})
    vec = CVecBasic()
    for i in x
       b::Basic = Basic(i)
       ccall((:vecbasic_push_back, libsymengine), Void, (Ptr{Void}, Ptr{Basic}), vec.ptr, &b)
    end
    return vec
end

function Base.convert(::Type{CVecBasic}, x...)
    vec = CVecBasic()
    for i in x
       b::Basic = Basic(i)
       ccall((:vecbasic_push_back, libsymengine), Void, (Ptr{Void}, Ptr{Basic}), vec.ptr, &b)
    end
    return vec
end

type SymFunction
    name::String
end

function (f::SymFunction)(x::CVecBasic)
    a = Basic()
    ccall((:function_symbol_set, libsymengine), Void, (Ptr{Basic}, Ptr{Int8}, Ptr{Void}), &a, f.name, x.ptr)
    return a
end

(f::SymFunction){T}(x::Vector{T}) = (f::SymFunction)(convert(CVecBasic, x))
(f::SymFunction)(x...) = (f::SymFunction)(convert(CVecBasic, x...))

