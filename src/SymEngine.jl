using SymEngine_jll

module SymEngine

import Base: show, convert, real, imag
import Compat: String, unsafe_string, @compat, denominator, numerator, invokelatest, Cvoid, Nothing, MathConstants.γ, MathConstants.e, MathConstants.φ, MathConstants.catalan, LinearAlgebra, finalizer, Libdl, reduce, mapreduce

export Basic, symbols, @vars, @funs, SymFunction
export free_symbols, function_symbols, get_name, get_args
export coeff
export ascii_art
export subs, lambdify, N, cse
export series
export expand

check_deps()

include("utils.jl")
const have_mpfr = have_component("mpfr")
const have_mpc = have_component("mpc")
const libversion = get_libversion()

finalizer(f, o) = finalizer(f, o)

include("exceptions.jl")
include("types.jl")
include("ctypes.jl")
include("display.jl")
include("mathops.jl")
include("mathfuns.jl")
include("simplify.jl")
include("subs.jl")
include("numerics.jl")
include("calculus.jl")
include("recipes.jl")
include("dense-matrix.jl")

function __init__()
    check_deps()
    init_constants()
end

end
