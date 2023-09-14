module SymEngineSymbolicUtilsExt

using SymEngine
using SymbolicUtils
import SymEngine: SymbolicType

#
function is_number(a::SymEngine.Basic)
    cls = SymEngine.get_symengine_class(a)
    any(==(cls), SymEngine.number_types) && return true
    false
end


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
λ(::Val{:Gamma}) = gamma; λ(::Val{:Zeta}) = zeta; λ(::Val{:LambertW}) = lambertw

#==
Check if x represents an expression tree. If returns true, it will be assumed that operation(::T) and arguments(::T) methods are defined. Definining these three should allow use of SymbolicUtils.simplify on custom types. Optionally symtype(x) can be defined to return the expected type of the symbolic expression.
==#
function SymbolicUtils.istree(x::SymEngine.SymbolicType)
    cls = SymEngine.get_symengine_class(x)
    cls == :Symbol && return false
    any(==(cls), SymEngine.number_types) && return false
    return true
end

SymbolicUtils.issym(x::SymEngine.SymbolicType) = SymEngine.get_symengine_class(x) == :Symbol
Base.nameof(x::SymEngine.SymbolicType) = Symbol(x)

# no metadata(x), metadata(x, data)

#==
Returns the head (a function object) performed by an expression tree. Called only if istree(::T) is true. Part of the API required for simplify to work. Other required methods are arguments and istree
==#
function SymbolicUtils.operation(x::SymEngine.SymbolicType)
    istree(x) || error("$(typeof(x)) doesn't have an operation!")
    return λ(x)
end


#==
Returns the arguments (a Vector) for an expression tree. Called only if istree(x) is true. Part of the API required for simplify to work. Other required methods are operation and istree
==#
function SymbolicUtils.arguments(x::SymEngine.SymbolicType)
    get_args(x)
end

#==
Construct a new term with the operation f and arguments args, the term should be similar to t in type. if t is a SymbolicUtils.Term object a new Term is created with the same symtype as t. If not, the result is computed as f(args...). Defining this method for your term type will reduce any performance loss in performing f(args...) (esp. the splatting, and redundant type computation). T is the symtype of the output term. You can use SymbolicUtils.promote_symtype to infer this type. The exprhead keyword argument is useful when creating Exprs.
==#
function SymbolicUtils.similarterm(t::SymEngine.SymbolicType, f, args, symtype=nothing;
                                   metadata=nothing, exprhead=:call)
    f(args...) # default
end

# Needed for some simplification routines
# a total order <ₑ
import SymbolicUtils: <ₑ, isterm, isadd, ismul, issym, cmp_mul_adds, cmp_term_term
function SymbolicUtils.:<ₑ(a::SymEngine.Basic, b::SymEngine.Basic)
    if isterm(a) && !isterm(b)
        return false
    elseif isterm(b) && !isterm(a)
        return true
    elseif (isadd(a) || ismul(a)) && (isadd(b) || ismul(b))
        return cmp_mul_adds(a, b)
    elseif issym(a) && issym(b)
        nameof(a) < nameof(b)
    elseif !istree(a) && !istree(b)
        T = typeof(a)
        S = typeof(b)
        if T == S
            is_number(a) && is_number(b) && return N(a) < N(b)
            return hash(a) < hash(b)
        else
            return name(T) < nameof(S)
        end
        #return T===S ? (T <: Number ? isless(a, b) : hash(a) < hash(b)) : nameof(T) < nameof(S)
    elseif istree(b) && !istree(a)
        return true
    elseif istree(a) && istree(b)
        return cmp_term_term(a,b)
    else
        return !(b <ₑ a)
    end
end

end
