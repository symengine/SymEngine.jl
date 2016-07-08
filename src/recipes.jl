using RecipesBase

## Plug into RecipesBase so plots of expressions treated like plots of functions
@recipe f{T<:Basic}(::Type{T}, v::T) = lambdify(v)
@recipe f{T<:Basic}(::Type{T}, v::T) = lambdify(v)
