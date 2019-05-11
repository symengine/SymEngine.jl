using SpecialFunctions

function IMPLEMENT_ONE_ARG_FUNC(meth, symnm; lib=:basic_)
     @eval begin
        function ($meth)(b::SymbolicType)
            a = Basic()
            ccall(($(string(lib,symnm)), libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, b)
            return a
        end
    end
end

function IMPLEMENT_TWO_ARG_FUNC(meth, symnm; lib=:basic_)
     @eval begin
        function ($meth)(b1::SymbolicType, b2::Number)
            a = Basic()
            b1, b2 = promote(b1, b2)
            ccall(($(string(lib,symnm)), libsymengine), Nothing, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b1, b2)
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
                      (:gamma,:gamma,:SpecialFunctions),
                      (:log,:log,:Base),
                      (:sqrt,:sqrt,:Base),
                      (:exp,:exp,:Base),
                      (:eta,:dirichlet_eta,:SpecialFunctions),
                      (:zeta,:zeta,:SpecialFunctions),
                      ]
    eval(:(import $modu.$meth))
    IMPLEMENT_ONE_ARG_FUNC(:($modu.$meth), libnm)
end
Base.abs2(x::SymEngine.Basic) = abs(x)^2

if get_symbol(:basic_atan2) != C_NULL
    if VERSION < VersionNumber(0,7)
        import Base.atan2
        IMPLEMENT_TWO_ARG_FUNC(:(Base.atan2), :atan2)
    else
        import Base.atan
        IMPLEMENT_TWO_ARG_FUNC(:(Base.atan), :atan2)
    end
end

# export not import
for  (meth, libnm) in [
                       (:lambertw,:lambertw),   # in add-on packages, not base
                       ]
    IMPLEMENT_ONE_ARG_FUNC(meth, libnm)
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
    IMPLEMENT_TWO_ARG_FUNC(:(Base.$meth), libnm, lib=:ntheory_)
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
