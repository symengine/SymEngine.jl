import Base: diff


## diff(ex, x)         f'
## what is the rest of the interface. This does:
## diff(ex, x, n)      f^(n)
## diff(ex, x, y, ...) f_{xy...}  # also diff(ex, (x,y))
## Support for diff(ex, x,n1, y,n2, ...),
## but can also do diff(ex, (x,y), (n1, n2))


function diff!(a::Basic, b1::SymbolicType, b2::Basic)
    is_symbol(b2) || throw(ArgumentError("Must differentiate with respect to a symbol"))
    ret = ccall((:basic_diff, libsymengine), Int, (Ref{Basic}, Ref{Basic}, Ref{Basic}), a, b1, b2)
    return a
end

function diff(b1::SymbolicType, b2::Basic)
    a = Basic()
    diff!(a, b1, b2)
    a
end

function diff(b1::SymbolicType, b2::SymbolicType, n::Integer)
    n < 0 && throw(DomainError("n must be non-negative integer"))
    n == 0 && return b1
    x = Basic(b2)
    out = Basic()
    diff!(out, b1, x)
    for _ in (n-1):-1:1
        diff!(out, out, x)
    end
    out
end

function diff(b1::SymbolicType, b2::SymbolicType, n::Integer, xs...)
    diff(diff(b1,b2,n), xs...)
end

function diff(b1::SymbolicType, b2::SymbolicType, b3::SymbolicType)
    if isinteger(b3)
        n = N(b3)::Int
        diff(b1, b2, n)
    else
        ex = diff(b1, b2)
        diff(ex, b3)
    end
end

function diff(b1::SymbolicType, b2::SymbolicType, b3::SymbolicType, bs...)
    diff(diff(b1,b2,b3), bs...)
end

function diff(b1::SymbolicType)
    xs = free_symbols(b1)
    n = length(xs)
    n == 0 && return zero(b1)
    n > 1 && throw(ArgumentError("More than one variable; one must be specified"))
    diff(b1, only(xs))
end

## deprecate
diff(b1::SymbolicType, b2::BasicType{Val{:Symbol}}) = diff(b1, Basic(b2))
diff(b1::SymbolicType, b2::BasicType) =
    throw(ArgumentError("Second argument must be of Symbol type"))

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
