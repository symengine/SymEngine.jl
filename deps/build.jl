using BinDeps
using Compat
@BinDeps.setup

group = library_group("symengine")

deps = [
    libgmp = library_dependency("libgmp", group = group),
    libgmpxx = library_dependency("libgmpxx", group = group),
    libsymengine = library_dependency("libsymengine", depends = [libgmp, libgmpxx])
]

prefix=joinpath(BinDeps.depsdir(libsymengine), "usr")

provides(AptGet,
    @compat Dict(
        "libgmp-dev" => [libgmp, libgmpxx]
    ))

provides(Yum,
    @compat Dict(
        "gmp-devel" => [libgmp, libgmpxx]
    ))

@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        print("Homebrew package not installed, please run Pkg.add(\"Homebrew\") to use it to download dependencies")
    else
        using Homebrew
        provides(Homebrew.HB, "gmp", [libgmp, libgmpxx], os = :Darwin)
    end
end

provides(Sources,
        URI("https://github.com/sympy/symengine/archive/master.zip"), libsymengine, unpacked_dir="symengine-master")

provides(Sources,
        URI("https://ftp.gnu.org/gnu/gmp/gmp-6.0.0a.tar.bz2"), [libgmp, libgmpxx], unpacked_dir="gmp-6.0.0")

provides(BuildProcess,
    @compat Dict(
        Autotools(libtarget = "libgmpxx.la", configure_options=["--enable-cxx"]) => [libgmp, libgmpxx]
    ))

xx(t...) = (OS_NAME == :Windows ? t[1] : (OS_NAME == :Linux || length(t) == 2) ? t[2] : t[3])

symenginesrcdir = joinpath(BinDeps.depsdir(libsymengine),"src","symengine-master")
symenginebuilddir = joinpath(BinDeps.depsdir(libsymengine),"builds","symengine")
provides(BuildProcess,
    (@build_steps begin
        GetSources(libsymengine)
        CreateDirectory(symenginebuilddir)
        @build_steps begin
            ChangeDirectory(symenginebuilddir)
            FileRule(joinpath(prefix, "lib", xx("libsymengine.dll", "libsymengine.so", "libsymengine.dylib")),@build_steps begin
                `cmake -DCMAKE_INSTALL_PREFIX="$prefix" -DCOMMON_DIR="$prefix" -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=yes -DBUILD_SHARED_LIBS=on $symenginesrcdir -DBUILD_TESTS=no -DBUILD_BENCHMARKS=no`
                `make`
                `make install`
            end)
        end
    end), libsymengine)

@BinDeps.install Dict([(:libsymengine, :libsymengine)])
