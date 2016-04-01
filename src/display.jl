
function toString(b::SymbolicType)
    b = Basic(b)
    a = ccall((:basic_str, :libsymengine), Ptr{Int8}, (Ptr{Basic}, ), &b)
    string = bytestring(a)
    ccall((:basic_str_free, :libsymengine), Void, (Ptr{Int8}, ), a)
    string = replace(string, "**", "^") # de pythonify
    return string
end

Base.show(io::IO, b::SymbolicType) = print(io, toString(b))


" show symengine logo "
type AsciiArt x end
function ascii_art()
    out = ccall((:ascii_art_str, :libsymengine),  Ptr{UInt8},  ())
    AsciiArt(bytestring(out))
end
export ascii_art
Base.show(io::IO, x::AsciiArt) = print(io, x.x)

