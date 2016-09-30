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
## Where are exp? log?, sqrt?
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
Base.exp(a::SymbolicType) = E^a
function Base.log(a::SymbolicType) # super hacky
    u = symbols(gensym())
    v = a^u
    diff(v, u) / v
end
Base.sqrt(a::SymbolicType) = a^(1//2)
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
                      ]
    eval(Expr(:import, :Base, meth))
    IMPLEMENT_TWO_ARG_FUNC(meth, libnm, lib=:ntheory_)    
end

## SymEngine mod can have different sign than Julia. Here we ensure that p > 0 ans \in [0, p) and p < 0 ans in (p, 0]
IMPLEMENT_TWO_ARG_FUNC(:ntheory_mod, :mod, lib=:ntheory_)
function Base.mod(k::SymbolicType, p::Number)
    m =  ntheory_mod(k, p)
    (m < 0 && p > 0) && return p + m
    (m > 0 && p < 0) && return p + m
    m
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
