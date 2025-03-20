module SymEngineTermInterfaceExt

import SymEngine
import TermInterface


λ(x::SymEngine.SymbolicType) = λ(Val(SymEngine.get_symengine_class(x)))
λ(::Val{T}) where {T} = getfield(Main, Symbol(lowercase(string(T))))

λ(::Val{:Add}) = +; λ(::Val{:Sub}) = -
λ(::Val{:Mul}) = *; λ(::Val{:Div}) = /
λ(::Val{:Pow}) = ^
λ(::Val{:re}) = real; λ(::Val{:im}) = imag
λ(::Val{:Abs}) = abs
λ(::Val{:Log}) = log
λ(::Val{:Sin}) = sin; λ(::Val{:Cos}) = cos; λ(::Val{:Tan}) = tan
λ(::Val{:Csc}) = csc; λ(::Val{:Sec}) = sec; λ(::Val{:Cot}) = cot
λ(::Val{:Asin}) = asin; λ(::Val{:Acos}) = acos; λ(::Val{:Atan}) = atan
λ(::Val{:Acsc}) = acsc; λ(::Val{:Asec}) = asec; λ(::Val{:Acot}) = acot
λ(::Val{:Sinh}) = sinh; λ(::Val{:Cosh}) = cosh; λ(::Val{:Tanh}) = tanh
λ(::Val{:Csch}) = csch; λ(::Val{:Sech}) = sech; λ(::Val{:Coth}) = coth
λ(::Val{:Asinh}) = asinh; λ(::Val{:Acosh}) = acosh; λ(::Val{:Atanh}) = atanh
λ(::Val{:Acsch}) = acsch; λ(::Val{:Asech}) = asech; λ(::Val{:Acoth}) = acoth
λ(::Val{:ATan2}) = atan;
λ(::Val{:Beta}) = SymEngine.SpecialFunctions.beta;
λ(::Val{:Gamma}) = SymEngine.SpecialFunctions.gamma;
λ(::Val{:PolyGamma}) = SymEngine.SpecialFunctions.polygamma;
λ(::Val{:LogGamma}) = SymEngine.SpecialFunctions.loggamma;
λ(::Val{:Erf}) = SymEngine.SpecialFunctions.erf;
λ(::Val{:Erfc}) = SymEngine.SpecialFunctions.erfc;
λ(::Val{:Zeta}) = SymEngine.SpecialFunctions.zeta;
λ(::Val{:LambertW}) = SymEngine.SpecialFunctions.lambertw



const julia_operations = Vector{Any}(missing, length(SymEngine.symengine_classes))
for (i,s) ∈ enumerate(SymEngine.symengine_classes)
    val = try
        λ(Val(s))
    catch err
        missing
    end
    julia_operations[i] = val
end

#==
Check if x represents an expression tree. If returns true, it will be assumed that operation(::T) and arguments(::T) methods are defined. Definining these three should allow use of SymbolicUtils.simplify on custom types. Optionally symtype(x) can be defined to return the expected type of the symbolic expression.
==#
function TermInterface.iscall(x::SymEngine.SymbolicType)
    cls = SymEngine.get_symengine_class(x)
    cls == :Symbol && return false
    cls == :Constant && return false
    any(==(cls), SymEngine.number_types) && return false
    return true
end
TermInterface.isexpr(x::SymEngine.SymbolicType) = TermInterface.iscall(x)

##TermInterface.issym(x::SymEngine.SymbolicType) = SymEngine.get_symengine_class(x) == :Symbol

function TermInterface.operation(x::SymEngine.SymbolicType)
    TermInterface.iscall(x) || error("$(typeof(x)) doesn't have an operation!")
    return julia_operations[SymEngine.get_type(x) + 1]
end

function TermInterface.arguments(x::SymEngine.SymbolicType)
    SymEngine.get_args(x)
end

TermInterface.head(x::SymEngine.SymbolicType) = TermInterface.operation(x)
TermInterface.children(x::SymEngine.SymbolicType) = TermInterface.arguments(x)

function TermInterface.maketerm(t::Type{<:SymEngine.SymbolicType}, f, args,
                                metadata=nothing)
    f(args...) # default
end


# no metadata(x), metadata(x, data)

end
