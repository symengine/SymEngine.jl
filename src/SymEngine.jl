__precompile__()

module SymEngine

import Base: show, convert, real, imag
import Compat: String, unsafe_string, @compat, denominator, numerator, invokelatest, Cvoid, Nothing, MathConstants.γ, MathConstants.e, MathConstants.φ, MathConstants.catalan, LinearAlgebra, finalizer, Libdl, reduce, mapreduce

export Basic, symbols, @vars, @funs, SymFunction
export free_symbols, get_args
export ascii_art
export subs, lambdify, N, cse
export series
if VERSION >= v"1.0.0-rc1"
    export expand
end

const deps_file = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
const deps_in_file = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl.in")

noinit = false

if !isfile(deps_file)
    cp(deps_in_file, deps_file)
end

include(deps_file)

if !noinit
    check_deps()
end

include("utils.jl")
const have_mpfr = have_component("mpfr")
const have_mpc = have_component("mpc")
const libversion = get_libversion()

if VERSION > VersionNumber("0.7.0-DEV")
    _finalizer(f, o) = finalizer(f, o)
else
    _finalizer(f, o) = finalizer(o, f)
end

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

if !noinit
    function __init__()
        check_deps()
        init_constants()
    end
end

end
