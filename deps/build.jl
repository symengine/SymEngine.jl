using BinDeps
using Compat
using Conda
@BinDeps.setup

libsymengine = library_dependency("libsymengine", aliases=["libsymengine", "symengine"])
env = Symbol(abspath(dirname(@__FILE__), "usr"))

Conda.add_channel("conda-forge", env)
Conda.add_channel("symengine", env)
provides(Conda.EnvManager{env}, "symengine==0.2.0", [libsymengine])

@BinDeps.install Dict([(:libsymengine, :libsymengine)])

