
function toString(b::SymbolicType, str_type=:basic_str_julia)
    b = Basic(b)
    if b.ptr == C_NULL
       error("Trying to print an uninitialized SymEngine Basic variable.")
    end
    a = ccall((str_type, libsymengine), Cstring, (Ref{Basic}, ), b)
    string = unsafe_string(a)
    ccall((:basic_str_free, libsymengine), Nothing, (Cstring, ), a)
    return string
end

Base.show(io::IO, b::SymbolicType) = print(io, toString(b))
Base.show(io::IO, ::MIME"tex/latex", b::SymbolicType) = print(io, toString(b,:basic_str_latex))


" show symengine logo "
mutable struct AsciiArt x end
function ascii_art()
    out = ccall((:ascii_art_str, libsymengine),  Ptr{UInt8},  ())
    AsciiArt(unsafe_string(out))
end

Base.show(io::IO, x::AsciiArt) = print(io, x.x)
