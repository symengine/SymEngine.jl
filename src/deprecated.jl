function real(::Val{<:Any}, x)
    if is_constant(x)
        real(evalf(x)) # keep this after removing deprecation
    else
        Base.depwarn(
            """The `real` method for a symbol is deprecated. Its use is for
    numeric values only.""",
            :real; force=true
        )
        x
    end
end

function imag(::Val{<:Any},x)
    if is_constant(x)
        imag(evalf(x)) # keep this after removing deprecation
    else
        Base.depwarn(
            """The `imag` method for a symbol is deprecated. Its use is for
    numeric values only.""",
            :imag; force=true
        )
         throw(InexactError()) # wrong as it was; seems like it should have been Basic(0)
    end
end
