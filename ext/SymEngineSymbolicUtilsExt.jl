module SymEngineSymbolicUtilsExt

using SymEngine
using SymbolicUtils

# Needed for some simplification routines
# a total order <ₑ
import SymbolicUtils: <ₑ, isterm, isadd, ismul, issym, get_degrees, monomial_lt, _arglen

#Base.nameof(x::SymEngine.SymbolicType) = Symbol(x)
#
#function is_number(a::SymEngine.Basic)
#    cls = SymEngine.get_symengine_class(a)
#    any(==(cls), SymEngine.number_types) && return true
#    false
#end


function SymbolicUtils.:<ₑ(a::SymEngine.Basic, b::SymEngine.Basic)
    if !SymbolicUtils.iscall(a) || !SymbolicUtils.iscall(a)
        if !SymbolicUtils.iscall(a) && !SymbolicUtils.iscall(b)
            return <ₑ(Symbol(a), Symbol(b))
        elseif SymbolicUtils.iscall(a) && !SymbolicUtils.iscall(b)
            return false
        elseif !SymbolicUtils.iscall(a) && SymbolicUtils.iscall(b)
            return true
        end
    end

    da, db = get_degrees(a), get_degrees(b)
    fw = monomial_lt(da, db)
    bw = monomial_lt(db, da)
    if fw === bw && !isequal(a, b)
        if _arglen(a) == _arglen(b)
            return (operation(a), arguments(a)...,) <ₑ (operation(b), arguments(b)...,)
        else
            return _arglen(a) < _arglen(b)
        end
    else
        return fw
    end
end

Base.isless(x::Number, y::SymEngine.Basic) = isless(promote(x,y)...)
Base.isless(x::SymEngine.Basic,y::Number) = isless(promote(x,y)...)

end
