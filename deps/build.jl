using BinDeps
using Compat
import BinDeps: lower
import CondaBinDeps

if VERSION > VersionNumber("0.7.0-DEV")
    # TODO: Remove this hack when BinDeps is fixed
    lower(s::Base.Process, c::BinDeps.SynchronousStepCollection) = nothing
end

@BinDeps.setup

# Use x.y.z for downloading binaries, but only check for x.y in shared libraries
# so that patch version increases can be found in system
libsymengine_version = "0.3.0"
libsymengine_soversion = join(split(libsymengine_version, ".")[1:2], ".")

if is_windows()
   libsymengine_soname = "symengine-$(libsymengine_soversion).dll"
elseif is_apple()
   libsymengine_soname = "libsymengine.$(libsymengine_soversion).dylib"
else
   libsymengine_soname = "libsymengine.so.$(libsymengine_soversion)"
end

# Use the dummy name libsymengine-dummy to avoid finding libsymengine.so
# We only want to find the versioned library
libdep = library_dependency("libsymengine_dummy", aliases=[libsymengine_soname])

path = abspath(dirname(@__FILE__), "usr")
if is_windows()
    isdir(path) || mkdir(path)
    if Sys.WORD_SIZE == 64
        suffix = "x86_64"
    else
        suffix = "x86"
    end
    url = "https://github.com/symengine/symengine/releases/download/"
    url *= "v$(libsymengine_version)/symengine-$(libsymengine_version)-binaries-msvc-$(suffix).tar.bz2"
    provides(Binaries, URI(url), libdep, unpacked_dir="symengine-$(libsymengine_version)/bin")
else
    # Conda's method will install miniconda to check that a package exists.
    # This will indicate to BinDeps that the packages for this env exists unconditionally.
    BinDeps.package_available(m::CondaBinDeps.Manager) = true
    # Adding the channel to conda will install miniconda even if conda is not the chosen LibraryProvider
    # Override the command for install in this env so that channels are added.
    function BinDeps.generate_steps(dep::BinDeps.LibraryDependency, manager::CondaBinDeps.Manager, opts)
        CondaBinDeps.Conda.add_channel("conda-forge", env)
        CondaBinDeps.Conda.add("$(manager.packages[1])", env)
    end
    provides(CondaBinDeps.Manager, "symengine=$(libsymengine_version)", [libdep])
end

@BinDeps.install Dict([(:libsymengine_dummy, :libsymengine)])
