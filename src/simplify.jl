
function Base.expand(b::SymbolicType)
    a = Basic()
    b = Basic(b)
    ccall((:basic_expand, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
    return a
end

