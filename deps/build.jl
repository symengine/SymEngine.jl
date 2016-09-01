using BinDeps
using Compat
using Conda
@BinDeps.setup

libsymengine = library_dependency("libsymengine", aliases=["libsymengine", "symengine"])

Conda.add_channel("conda-forge")
Conda.add_channel("symengine")
provides(Conda.Manager, "symengine==0.2.0", [libsymengine])

@BinDeps.install Dict([(:libsymengine, :libsymengine)])

