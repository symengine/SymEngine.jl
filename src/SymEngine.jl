module SymEngine

using SymEngine_jll

import Base: show, convert, real, imag, MathConstants.γ, MathConstants.e, MathConstants.φ, MathConstants.catalan, invokelatest
import Compat: String, unsafe_string, @compat, denominator, numerator, Cvoid, Nothing, finalizer, reduce, mapreduce
import Serialization
import LinearAlgebra, Libdl

export Basic, symbols, @vars, @funs, SymFunction
export free_symbols, function_symbols, get_name, get_args
export coeff
export ascii_art
export subs, lambdify, N, cse
export series
export expand

include("utils.jl")
const have_mpfr = have_component("mpfr")
const have_mpc = have_component("mpc")
const libversion = get_libversion()

include("exceptions.jl")
include("types.jl")
include("ctypes.jl")
include("decl.jl")
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
    init_constants()
end

end
