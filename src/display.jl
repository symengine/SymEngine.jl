
function toString(b::SymbolicType)
    b = Basic(b)
    a = ccall((:basic_str, :libsymengine), Ptr{Int8}, (Ptr{Basic}, ), &b)
    string = bytestring(a)
    ccall((:basic_str_free, :libsymengine), Void, (Ptr{Int8}, ), a)
    string = replace(string, "**", "^") # de pythonify
    return string
end

show(io::IO, b::SymbolicType) = print(io, toString(b))
