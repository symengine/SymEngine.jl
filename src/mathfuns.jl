using SpecialFunctions

function IMPLEMENT_ONE_ARG_FUNC(modu, meth, symnm; lib=:basic_)
    methbang = Symbol(meth, "!")
    if isa(modu, Symbol)
        meth = :($modu.$meth)
    end
     @eval begin
        function ($meth)(b::SymbolicType)
            a = Basic()
            ($methbang)(a,b)
            a
        end
        function ($methbang)(a::Basic, b::SymbolicType)
            err_code = ccall(($(string(lib,symnm)), libsymengine), Cuint, (Ref{Basic}, Ref{Basic}), a, b)
            throw_if_error(err_code, $(string(meth)))
            return a
        end
    end
end

function IMPLEMENT_TWO_ARG_FUNC(modu, meth, symnm; lib=:basic_)
    methbang = Symbol(meth, "!")
    if isa(modu, Symbol)
        meth = :($modu.$meth)
    end

     @eval begin
        function ($meth)(b1::SymbolicType, b2::Number)
            a = Basic()
            ($methbang)(a,b1,b2)
            a
        end
         function ($methbang)(a::Basic, b1::SymbolicType, b2::Number)
            b1, b2 = promote(b1, b2)
            err_code = ccall(($(string(lib,symnm)), libsymengine), Cuint, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b1, b2)
            throw_if_error(err_code, $(string(meth)))
            return a
        end

    end
end

## import from base one argument functions
## these are from cwrapper.cpp, one arg func
for (meth, libnm, modu) in [
                      (:abs,:abs,:Base),
                      (:sin,:sin,:Base),
                      (:cos,:cos,:Base),
                      (:tan,:tan,:Base),
                      (:csc,:csc,:Base),
                      (:sec,:sec,:Base),
                      (:cot,:cot,:Base),
                      (:asin,:asin,:Base),
                      (:acos,:acos,:Base),
                      (:asec,:asec,:Base),
                      (:acsc,:acsc,:Base),
                      (:atan,:atan,:Base),
                      (:acot,:acot,:Base),
                      (:sinh,:sinh,:Base),
                      (:cosh,:cosh,:Base),
                      (:tanh,:tanh,:Base),
                      (:csch,:csch,:Base),
                      (:sech,:sech,:Base),
                      (:coth,:coth,:Base),
                      (:asinh,:asinh,:Base),
                      (:acosh,:acosh,:Base),
                      (:asech,:asech,:Base),
                      (:acsch,:acsch,:Base),
                      (:atanh,:atanh,:Base),
                      (:acoth,:acoth,:Base),
                      (:log,:log,:Base),
                      (:sqrt,:sqrt,:Base),
                      (:exp,:exp,:Base),
                      (:sign, :sign, :Base),
                      (:ceil, :ceiling, :Base),
                      (:floor, :floor, :Base)
                      ]
    eval(:(import $modu.$meth))
    IMPLEMENT_ONE_ARG_FUNC(modu, meth, libnm)
end

for (meth, libnm, modu) in [
    (:gamma,:gamma,:SpecialFunctions),
    (:loggamma,:loggamma,:SpecialFunctions),
    (:eta,:dirichlet_eta,:SpecialFunctions),
    (:zeta,:zeta,:SpecialFunctions),
    (:erf, :erf, :SpecialFunctions),
    (:erfc, :erfc, :SpecialFunctions)
]
    eval(:(import $modu.$meth))
    IMPLEMENT_ONE_ARG_FUNC(modu, meth, libnm)
end

for (meth, libnm, modu) in [
    (:beta, :beta, :SpecialFunctions),
    (:polygamma, :polygamma, :SpecialFunctions),
    (:loggamma,:loggamma,:SpecialFunctions),
    ]
    eval(:(import $modu.$meth))
    IMPLEMENT_TWO_ARG_FUNC(modu, meth, libnm)
end

const TWO = Basic(2)
function abs2!(a::Basic, x::Basic)
    a = abs!(a, x)
    a = pow!(a, x, TWO)
    a
end
function Base.abs2(x::Basic)
    a = Basic()
    abs2!(a, x)
    a
end


if get_symbol(:basic_atan2) != C_NULL
    import Base.atan
    IMPLEMENT_TWO_ARG_FUNC(:Base, :atan, :atan2)
end

# export not import
for  (meth, libnm) in [
                       (:lambertw,:lambertw),   # in add-on packages, not base
                       ]
    IMPLEMENT_ONE_ARG_FUNC(nothing, meth, libnm)
    eval(Expr(:export, meth))
end

## add these in until they are wrapped
Base.cbrt(a::SymbolicType) = a^(1//3)

for (meth, fn) in [(:sind, :sin), (:cosd, :cos), (:tand, :tan), (:secd, :sec), (:cscd, :csc), (:cotd, :cot)]
    eval(:(import Base.$meth))
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
    eval(:(import Base.$meth))
    IMPLEMENT_TWO_ARG_FUNC(:Base, meth, libnm; lib=:ntheory_)
end

Base.binomial(n::Basic, k::Number) = binomial(N(n), N(k))  #ntheory_binomial seems wrong
Base.binomial(n::Basic, k::Integer) = binomial(N(n), N(k))  #Fix dispatch ambiguity / MethodError
Base.rem(a::SymbolicType, b::SymbolicType) = a - (a ÷ b) * b
Base.factorial(n::SymbolicType, k) = factorial(N(n), N(k))

## but not (:fibonacci,:fibonacci), (:lucas, :lucas) (Basic type is not the signature)
for (meth, libnm) in [(:nextprime,:nextprime)
                      ]
    IMPLEMENT_ONE_ARG_FUNC(nothing, meth, libnm, lib=:ntheory_)
    eval(Expr(:export, meth))
end

"Return coefficient of `x^n` term, `x` a symbol"
function coeff!(a::Basic, b::Basic, x, n)
    out = ccall((:basic_coeff, libsymengine), Nothing,
                (Ref{Basic},Ref{Basic},Ref{Basic},Ref{Basic}),
                a,b,Basic(x), Basic(n))
    a
end
coeff(b::Basic, x, n) = coeff!(Basic(), b, x, n)

function Base.convert(::Type{CVecBasic}, x::Vector{T}) where T
    vec = CVecBasic()
    for i in x
       b::Basic = Basic(i)
       ccall((:vecbasic_push_back, libsymengine), Nothing, (Ptr{Cvoid}, Ref{Basic}), vec.ptr, b)
    end
    return vec
end

Base.convert(::Type{CVecBasic}, x...) = Base.convert(CVecBasic, collect(promote(x...)))
Base.convert(::Type{CVecBasic}, x::CVecBasic) = x

mutable struct SymFunction
    name::String
end

SymFunction(s::Symbol) = SymFunction(string(s))

function (f::SymFunction)(x::CVecBasic)
    a = Basic()
    ccall((:function_symbol_set, libsymengine), Nothing, (Ref{Basic}, Ptr{Int8}, Ptr{Cvoid}), a, f.name, x.ptr)
    return a
end

(f::SymFunction)(x::Vector{T}) where {T} = (f::SymFunction)(convert(CVecBasic, x))
(f::SymFunction)(x...) = (f::SymFunction)(convert(CVecBasic, x...))

macro funs(x...)
    q=Expr(:block)
    if length(x) == 1 && isa(x[1],Expr)
        @assert x[1].head === :tuple "@funs expected a list of symbols"
        x = x[1].args
    end
    for s in x
        @assert isa(s,Symbol) "@funs expected a list of symbols"
        push!(q.args, Expr(:(=), esc(s), Expr(:call, :(SymEngine.SymFunction), Expr(:quote, s))))
    end
    push!(q.args, Expr(:tuple, map(esc, x)...))
    q
end
