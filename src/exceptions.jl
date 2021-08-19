@inline function throw_if_error(error_code::Cuint, str=nothing)
    if error_code == 0
        return
    else
        throw(get_error(error_code, str))
    end
end

function get_error(error_code::Cuint, str=nothing)
    if error_code == 1
        return ErrorException("Unknown SymEngine Exception")
    elseif error_code == 2
        return DivideError()
    elseif error_code == 3
        return ErrorException("Not implemented SymEngine feature")
    elseif error_code == 4
        return DomainError(str)
    elseif error_code == 5
        return Meta.ParseError(str)
    else
        return ErrorException("Unexpected SymEngine error code")
    end
end
