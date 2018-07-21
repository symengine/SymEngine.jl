using BinaryProvider

dependencies = Dict(
    "https://github.com/isuruf/GMPBuilder/releases/download/v6.1.2-1/build_GMP.v6.1.2.jl" =>
        "9bd8d9078c2a9c9a6451f6850ec45c925727afc395b5e4740153707826cd7439",

    "https://github.com/JuliaMath/MPFRBuilder/releases/download/v4.0.1/build.jl" =>
        "36ed4f47426eea41a2576f1c57b4dbbef552c42eea819f8e6c590d394fef049b",

    "https://github.com/isuruf/MPCBuilder/releases/download/v1.1.0/build_mpc.v1.1.0.jl" =>
        "d800a46181c40fe046dfd51bf0357393bb58e2475b6082065ad0756971ad82eb",

    "https://github.com/symengine/SymEngineBuilder/releases/download/v0.3.0/build_SymEngine.v0.3.0.jl" =>
        "cd98583c98c386bc8273ae24efb0ab537f365a115d03342b17623d1ebfde5e6a",
)

prefix = joinpath(@__DIR__, "symengine-0.3")
downloads_dir = joinpath(prefix, "downloads")
all_products = LibraryProduct[]

for (url, hash) in dependencies
    tmp_file = joinpath(downloads_dir, "build_$hash.jl")
    download_verify(url, hash, tmp_file)
    contents = read(tmp_file, String)
    m = Module(:__anon__)
    products = eval(m, quote
        using BinaryProvider
        function write_deps_file(path, products) end
        ARGS = [$prefix]
        include_string($(contents))
        products
    end)
    append!(all_products, products)
end

for product in all_products
    locate(product, verbose=true)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), all_products)
