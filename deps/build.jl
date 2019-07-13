using BinaryProvider

dependencies = [
    ("gmp", "6.1.2", "https://github.com/JuliaPackaging/Yggdrasil/releases/download/GMP-v6.1.2-1/build_GMP.v6.1.2.jl",
        "49205602a6121affc12e2c8039f21fd7fe079f328abaa9294d7cd804ac1769cb"),

    ("mpfr", "4.0.1", "https://github.com/JuliaPackaging/Yggdrasil/releases/download/MPFR-v4.0.2-0/build_MPFR.v4.0.2.jl",
        "385b33639b808395e776832ab37708046f9fed2748ab283880371047768cb1d3"),

    ("mpc", "1.1.0", "https://github.com/isuruf/MPCBuilder/releases/download/v1.1.0-3/build_MPC.v1.1.0.jl",
        "c4ab6da81bf9a54e44aa5b8d372979a14af81bde06589c1fcb90521af3a29d2f"),

    ("symengine", "0.4.0", "https://github.com/symengine/SymEngineBuilder/releases/download/v0.4.0-3/build_SymEngine.v0.4.0.jl",
        "97348aaf042e3c81b938ac665a0c81e02b5f4e5125d76cedcd2fc3c9dcb182df"),
]

libdir = "lib"

if Sys.iswindows()
    libdir = "bin"
end

prefix = joinpath(@__DIR__, "libsymengine-0.4")
downloads_dir = joinpath(@__DIR__, "downloads")

all_products = LibraryProduct[]

if !isdir(joinpath(prefix, libdir))
    mkpath(joinpath(prefix, libdir))
end

for (name, version, url, hash) in dependencies
    product = LibraryProduct(joinpath(prefix, libdir), String[string("lib", name)], Symbol(string("lib", name)))
    push!(all_products, product)

    if !satisfied(product)
        tmp_file = joinpath(downloads_dir, "build_$hash.jl")
        download_verify(url, hash, tmp_file)
        contents = read(tmp_file, String)
        tmp_prefix = joinpath(downloads_dir, string(name, "-", version))
        m = Module(:__anon__)
        Core.eval(m, quote
            using BinaryProvider
            function write_deps_file(path, products; verbose=true) end
            ARGS = [$tmp_prefix]
        end)
        Base.include_string(m, contents)
        for file in readdir(joinpath(tmp_prefix, libdir))
            cp(joinpath(tmp_prefix, libdir, file), joinpath(prefix, libdir, file), force=true)
        end
    end
    @info(locate(product))
end

for product in all_products
    locate(product, verbose=true)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), all_products)
