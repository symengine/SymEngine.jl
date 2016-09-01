using BinDeps
using Compat
using Conda
@BinDeps.setup

libsymengine = library_dependency("libsymengine", aliases=["libsymengine", "symengine"])

Conda.add_channel("conda-forge")
Conda.add_channel("symengine")
if is_windows()
    # SymEngine can only be installed to a python 3.5 environment
    Conda.add("python=3.5")
end
provides(Conda.Manager, "symengine==0.2.0", [libsymengine])

@BinDeps.install Dict([(:libsymengine, :libsymengine)])

