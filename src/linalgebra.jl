import LinearAlgebra: dot

"""Provide proper method for recursive call in LinearAlgebra.jl
""" dot(x::Basic,y::Basic) = x * y :: Basic;
