using BinDeps
using Compat
using Conda
@BinDeps.setup

libsymengine = library_dependency("libsymengine", aliases=["libsymengine", "symengine"])

if is_windows()
    path = abspath(dirname(@__FILE__), "usr")
    isdir(path) || mkdir(path)
    if WORD_SIZE == 64
        url = "https://github.com/symengine/symengine/releases/download/v0.2.0/binaries-msvc-x86_64.tar.bz2"
    else
        url = "https://github.com/symengine/symengine/releases/download/v0.2.0/binaries-msvc-x86.tar.bz2"
    end
    provides(Binaries, URI(url), libsymengine, unpacked_dir="$path/bin")
else
    env = Symbol(abspath(dirname(@__FILE__), "usr"))
    Conda.add_channel("conda-forge", env)
    Conda.add_channel("symengine", env)
    provides(Conda.EnvManager{env}, "symengine==0.2.0", [libsymengine])
end

@BinDeps.install Dict([(:libsymengine, :libsymengine)])

