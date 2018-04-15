__precompile__()

module SymEngine

import Base: show, convert, real, imag
import Compat: String, unsafe_string, @compat, denominator, numerator, invokelatest, Cvoid, Nothing, MathConstants.γ, MathConstants.e, MathConstants.φ, MathConstants.catalan

export Basic, symbols, @vars, @funs, SymFunction
export free_symbols, get_args
export ascii_art
export subs, lambdify, N
export series

const deps_file = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
const deps_in_file = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl.in")

noinit = false

if !isfile(deps_file)
    cp(deps_in_file, deps_file)
end

include(deps_file)
include("utils.jl")
const have_mpfr = have_component("mpfr")
const have_mpc = have_component("mpc")
const libversion = get_libversion()

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

if !noinit
    __init__() = init_constants()
end

end
