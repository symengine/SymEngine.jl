module SymEngine

import Base: show, convert, real, imag

using Compat: String, unsafe_string, @compat

export Basic, symbols, @vars
export free_symbols, get_args
export ascii_art
export subs, lambdify, N
export series


const deps_file = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")

if isfile(deps_file)
    include(deps_file)
else
    error("SymEngine is not properly configured. Run Pkg.build(\"SymEngine\") before importing the SymEngine module.")
end

include("types.jl")
include("ctypes.jl")
include("display.jl")
include("mathops.jl")
include("mathfuns.jl")
include("subs.jl")
include("numerics.jl")
include("simplify.jl")
include("calculus.jl")
include("recipes.jl")
include("dense-matrix.jl")
end
