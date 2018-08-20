using BinaryProvider

dependencies = Dict(
    "https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl" =>
        "91b2197c4d2209985b2c156e04f3fc11e4beff633cd86bb0053bfefe71cdfba6",

    "https://github.com/JuliaMath/MPFRBuilder/releases/download/v4.0.1-3/build_MPFR.v4.0.1.jl" =>
        "40f3d06abf45b571b23135a079d66827282e587be15d540874bb45dac163e2c7",

    "https://github.com/isuruf/MPCBuilder/releases/download/v1.1.0-2/build_MPC.v1.1.0.jl" =>
        "85cac0057832da9c9d965531e9a1bada7150032aea4dbead59ff76e95bbdc47f",

    "https://github.com/symengine/SymEngineBuilder/releases/download/v0.3.0-2/build_SymEngine.v0.3.0.jl" =>
        "664b7df2b2e173625fa5742aa194e63392692489b73e6ba4005dcbf661093c9d",
)

prefix = joinpath(@__DIR__, "symengine-0.3")
downloads_dir = joinpath(prefix, "downloads")
all_products = LibraryProduct[]

for (url, hash) in dependencies
    tmp_file = joinpath(downloads_dir, "build_$hash.jl")
    download_verify(url, hash, tmp_file)
    contents = read(tmp_file, String)
    m = Module(:__anon__)
    Core.eval(m, quote
        using BinaryProvider
        function write_deps_file(path, products) end
        ARGS = [$prefix]
    end)
    Base.include_string(m, contents)
    products = Core.eval(m, :(products))
    append!(all_products, products)
end

for product in all_products
    locate(product, verbose=true)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), all_products)
