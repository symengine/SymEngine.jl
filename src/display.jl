
function toString(b::SymbolicType)
    b = Basic(b)
    a = ccall((:basic_str_julia, libsymengine), Cstring, (Ptr{Basic}, ), &b)
    string = unsafe_string(a)
    ccall((:basic_str_free, libsymengine), Void, (Cstring, ), a)
    return string
end

Base.show(io::IO, b::SymbolicType) = print(io, toString(b))


" show symengine logo "
mutable struct AsciiArt x end
function ascii_art()
    out = ccall((:ascii_art_str, libsymengine),  Ptr{UInt8},  ())
    AsciiArt(unsafe_string(out))
end

Base.show(io::IO, x::AsciiArt) = print(io, x.x)
