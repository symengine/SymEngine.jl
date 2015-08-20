# SymEngine.jl

[![Build Status](https://travis-ci.org/symengine/SymEngine.jl.svg?branch=master)](https://travis-ci.org/symengine/SymEngine.jl)

Julia Wrappers for SymEngine, a fast symbolic manipulation library, written in C++.

## Installation

You can install `SymEngine.jl` by giving the following commands.

```julia
julia> Pkg.clone("https://github.com/symengine/SymEngine.jl")
julia> Pkg.build("SymEngine")
```

`build.jl` supports only Linux and OS X for now.

For Windows, follow the instructions in the [C++ repo](https://github.com/sympy/symengine) and make sure `SymEngine` shared library is in `LD_LIBRARY_PATH`

## License

`SymEngine.jl` is licensed under MIT open source license. 
