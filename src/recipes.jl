using RecipesBase

## Plug into RecipesBase so plots of expressions treated like plots of functions
@recipe f(::Type{T}, v::T) where {T<:Basic} = lambdify(v)
@recipe f(::Type{S}, ss::S) where {S<:AbstractVector{Basic}} = Function[lambdify(s) for s in ss]
