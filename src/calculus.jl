import Base: diff


## diff(ex, x)         f'
## what is the rest of the interface. This does:
## diff(ex, x, n)      f^(n)
## diff(ex, x, y, ...) f_{xy...}  # also diff(ex, (x,y))
## no support for diff(ex, x,n1, y,n2, ...), but can do diff(ex, (x,y), (n1, n2))

function diff(b1::SymbolicType, b2::BasicType{Val{:Symbol}})
    a = Basic()
    ret = ccall((:basic_diff, libsymengine), Int, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b1, b2)
    return a
end

diff(b1::SymbolicType, b2::BasicType) =
    throw(ArgumentError("Second argument must be of Symbol type"))

function diff(b1::SymbolicType, b2::SymbolicType, n::Integer=1)
    n < 0 && throw(DomainError("n must be non-negative integer"))
    n==0 && return b1
    n==1 && return diff(b1, BasicType(b2))
    n > 1 && return diff(diff(b1, BasicType(b2)), BasicType(b2), n-1)
end

function diff(b1::SymbolicType, b2::SymbolicType, b3::SymbolicType)
    isa(BasicType(b3), BasicType{Val{:Integer}}) ? diff(b1, b2, N(b3)) : diff(b1, (b2, b3))
end

diff(b1::SymbolicType, b2::SymbolicType, b3::SymbolicType, b4::SymbolicType, b5...) =
    diff(b1, (b2,b3,b4,b5...))

## mixed partials
diff(ex::SymbolicType, bs::Tuple) = reduce((ex, x) -> diff(ex, x), bs, init=ex)
diff(ex::SymbolicType, bs::Tuple, ns::Tuple) =
    reduce((ex, x) -> diff(ex, x[1],x[2]), zip(bs, ns), init=ex)

diff(b1::SymbolicType, x::Union{String,Symbol}) = diff(b1, Basic(x))

"""
Series expansion to order `n` about point `x0`
"""
function series(ex::SymbolicType, x::SymbolicType, x0=0, n::Union{Integer, Basic}=6)
    (!isa(N(n), Integer) || n < 0) && throw(DomainError("n must be non-negative integer"))

    fc = subs(ex, x, x0)
    n==0 && return fc

    fp = ex
    nfact = Basic(1)
    for k in 1:n
        fp = diff(fp, x)
        nfact = k * nfact
        fc = fc + subs(fp, x, x0) * (x-x0)^k / nfact
    end

    fc
end
