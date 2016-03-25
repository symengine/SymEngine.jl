

function diff(b1::Basic, b2::Basic)
    a = Basic()
    ret = ccall((:basic_diff, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    if (ret == 0)
        error("Second argument must be a symbol.")
    end
    return a
end
