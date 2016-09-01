using BinDeps
using Compat
@BinDeps.setup

group = library_group("symengine")

deps = [
    gmp = library_dependency("gmp", aliases=["libgmp", "gmp", "mpir", "libmpir"], group = group),
    mpfr = library_dependency("mpfr", aliases=["libmpfr", "mpfr"], group=group, depends=[gmp]),
    mpc = library_dependency("mpc", aliases=["libmpc", "mpc"], group=group, depends=[mpfr]),
    symengine = library_dependency("symengine", aliases=["libsymengine", "symengine"], depends = [mpc])
]

prefix=joinpath(BinDeps.depsdir(symengine), "usr")

xx(t...) = (OS_NAME == :Windows ? t[1] : (OS_NAME == :Linux || length(t) == 2) ? t[2] : t[3])

if is_unix()
    using Conda
    Conda.add_channel("conda-forge")
    Conda.add_channel("symengine")

    provides(Conda.Manager, "gmp", [gmp])
    provides(Conda.Manager, "mpfr", [mpfr])
    provides(Conda.Manager, "mpc", [mpc])
    # TODO: Make this work for OS X
    provides(Conda.Manager, "symengine==0.2.0", [symengine], os = :Linux)
end

if is_windows()
    using WinRPM
    provides(WinRPM.RPM, "gmp-devel", [gmp])
    provides(WinRPM.RPM, "mpfr-devel", [mpfr])
    provides(WinRPM.RPM, "mpc-devel", [mpc])
end

symengine_version = "v0.2.0"
symengine_dir = (symengine_version[1] == 'v' ? symengine_version[2:end] : symengine_version)

provides(Sources,
        URI("https://github.com/symengine/symengine/archive/$symengine_version.zip"),
            symengine, unpacked_dir="symengine-$symengine_dir")


generator = (is_windows() ? "MSYS Makefiles" : "Unix Makefiles")

symenginesrcdir = joinpath(BinDeps.depsdir(symengine),"src","symengine-$symengine_dir")
symenginebuilddir = joinpath(BinDeps.depsdir(symengine),"builds","symengine")
provides(BuildProcess,
    (@build_steps begin
        GetSources(symengine)
        CreateDirectory(symenginebuilddir)
        @build_steps begin
            ChangeDirectory(symenginebuilddir)
            FileRule(joinpath(prefix, "lib", xx("libsymengine.dll.a", "libsymengine.so", "libsymengine.dylib")),@build_steps begin
                `cmake -G"$generator" -DCMAKE_INSTALL_PREFIX="$prefix" -DCMAKE_PREFIX_PATH="$prefix" -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=yes -DBUILD_SHARED_LIBS=on -DBUILD_TESTS=no -DBUILD_BENCHMARKS=no -DINTEGER_CLASS=gmp -DWITH_MPC=yes $symenginesrcdir`
                `cmake --build .`
                `cmake --build . --target install`
            end)
        end
    end), symengine)

@BinDeps.install Dict([(:symengine, :symengine)])
