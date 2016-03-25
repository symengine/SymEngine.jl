

function diff(b1::BasicType, b2::BasicType)
    a = Basic()
    b1, b2 = map(Basic, (b1, b2))
    ret = ccall((:basic_diff, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    if (ret == 0)
        error("Second argument must be a symbol.")
    end
    return Sym(a)
end
