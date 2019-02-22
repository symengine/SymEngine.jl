using BinaryProvider

dependencies = [
    ("gmp", "6.1.2", "https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl",
        "91b2197c4d2209985b2c156e04f3fc11e4beff633cd86bb0053bfefe71cdfba6"),

    ("mpfr", "4.0.1", "https://github.com/JuliaMath/MPFRBuilder/releases/download/v4.0.1-3/build_MPFR.v4.0.1.jl",
        "40f3d06abf45b571b23135a079d66827282e587be15d540874bb45dac163e2c7"),

    ("mpc", "1.1.0", "https://github.com/isuruf/MPCBuilder/releases/download/v1.1.0-2/build_MPC.v1.1.0.jl",
        "85cac0057832da9c9d965531e9a1bada7150032aea4dbead59ff76e95bbdc47f"),

    ("symengine", "0.3.0", "https://github.com/symengine/SymEngineBuilder/releases/download/v0.3.0-3/build_SymEngine.v0.3.0.jl",
        "c6122fbb9ef8198f413c645e66a251593d50a19414528d21f14d4a53ca5e299d"),
]

libdir = "lib"

if Sys.iswindows()
    libdir = "bin"
    dependencies[4]= ("symengine", "0.3.0", "https://github.com/symengine/SymEngineBuilder/releases/download/v0.3.0-2/build_SymEngine.v0.3.0.jl",
        "664b7df2b2e173625fa5742aa194e63392692489b73e6ba4005dcbf661093c9d")
end

prefix = joinpath(@__DIR__, "libsymengine-0.3")
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
