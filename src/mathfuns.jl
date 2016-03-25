
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
    tup = (Base.symbol("basic_$libnm"), :libsymengine)
    @eval begin
        function ($meth)(b::BasicType)
            a = Basic()
            b = Basic(b)
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
            return Sym(a)
        end
    end
end

# functions not in 
for  (meth, libnm) in [
                       (:lambertw,:lambertw)   # in add-on packages, not base
                       ]
    tup = (Base.symbol("basic_$libnm"), :libsymengine)
    @eval begin
        function ($meth)(b::BasicType)
            a = Basic()
            b = Basic(b)
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
            return Sym(a)
        end
    end
    eval(Expr(:export, meth))
end

## add
Base.sqrt(a::BasicType) = a^(1//2)
Base.cbrt(a::BasicType) = a^(1//3)
for (meth, fn) in [(:sind, :sin), (:cosd, :cos), (:tand, :tan), (:secd, :sec), (:cscd, :csc), (:cotd, :cot)]
    eval(Expr(:import, :Base, meth))
    @eval begin
        $(meth)(a::BasicType) = $(fn)(a*PI/180)
    end
end


## Number theory module from cppwrapper
for (meth, libnm) in [(:gcd, :gcd),
                      (:lcm, :lcm),
                      (:mod, :mod),
                      (:div, :quotient),
                      (:binomial, :binomial)
                      ]
    eval(Expr(:import, :Base, meth))
    tup = (Base.symbol("ntheory_$libnm"), :libsymengine)
    @eval begin
        function ($meth)(a::BasicType, b::BasicType)
            s = Basic()
            a,b = map(Basic, (a, b))
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &s, &a, &b)
            return Sym(s)
        end
    end
end

Base.rem(a::BasicType, b::BasicType) = a - (a ÷ b) * b

## but not (:fibonacci,:fibonacci), (:lucas, :lucas) (Basic type is not the signature)
for (meth, libnm) in [(:nextprime,:nextprime)
                      ]
    tup = (Base.symbol("ntheory_$libnm"), :libsymengine)
    @eval begin
        function ($meth)(a::BasicType)
            s = Basic()
            a = Basic(a)
            ccall($tup, Void, (Ptr{Basic}, Ptr{Basic}), &s, &a)
            return Sym(s)
        end
    end
    eval(Expr(:export, meth))
    
end
