
function expand(b::Basic)
    a = Basic()
    ccall((:basic_expand, :libsymengine), Void, (Ptr{Basic}, Ptr{Basic}), &a, &b)
    return a
end
