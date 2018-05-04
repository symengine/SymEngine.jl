function throw_if_error(error_code::Cuint, str=nothing)
    if error_code == 0
        return
    elseif error_code == 1
        error("Unknown SymEngine Exception")
    elseif error_code == 2
        throw(DivideError())
    elseif error_code == 3
        error("Not implemented SymEngine feature")
    elseif error_code == 4
        throw(DomainError())
    elseif error_code == 5
        throw(ParseError(str))
    end
end
