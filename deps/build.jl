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
    EnvManagerType = Conda.EnvManager{env}
    # Conda's method will install miniconda to check that a package exists.
    # This will indicate to BinDeps that the packages for this env exists unconditionally.
    BinDeps.package_available(m::EnvManagerType) = true
    # Adding the channel to conda will install miniconda even if conda is not the chosen LibraryProvider
    # Override the command for install in this env so that channels are added.
    function BinDeps.generate_steps(dep::BinDeps.LibraryDependency, manager::EnvManagerType, opts)
        Conda.add_channel("conda-forge", env)
        Conda.add_channel("symengine", env)
        Conda.add("$(manager.packages[1])", env)
    end
    provides(EnvManagerType, "symengine==0.2.0", [libsymengine])
end

@BinDeps.install Dict([(:libsymengine, :libsymengine)])

