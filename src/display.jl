
function toString(b::SymbolicType)
    b = Basic(b)
    a = ccall((:basic_str, :libsymengine), Cstring, (Ptr{Basic}, ), &b)
    string = unsafe_string(a)
    ccall((:basic_str_free, :libsymengine), Void, (Cstring, ), a)
    string = replace(string, "**", "^") # de pythonify
    return string
end

Base.show(io::IO, b::SymbolicType) = print(io, toString(b))


" show symengine logo "
type AsciiArt x end
function ascii_art()
    out = ccall((:ascii_art_str, :libsymengine),  Ptr{UInt8},  ())
    AsciiArt(unsafe_string(out))
end

Base.show(io::IO, x::AsciiArt) = print(io, x.x)
