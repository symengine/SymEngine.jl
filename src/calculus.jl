import Base: diff

function diff{T<:SymbolicType}(b1::T, b2::BasicType{Val{:Symbol}})
    a = Basic()
    b1, b2 = map(Basic, (b1, b2))
    ret = ccall((:basic_diff, :libsymengine), Int, (Ptr{Basic}, Ptr{Basic}, Ptr{Basic}), &a, &b1, &b2)
    return a
end
diff{T<:SymbolicType}(b1::T, b2::BasicType) = throw(ArgumentError("Second argument must be of symbol type"))
diff{T<:SymbolicType, S<:SymbolicType}(b1::T, b2::S) = diff(b1, _Sym(b2))

