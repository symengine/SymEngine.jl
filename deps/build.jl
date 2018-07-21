using BinaryProvider

dependencies = Dict(
    "https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2/build.jl" =>
        "7674924b83e090d2490f7dbc103045142e083c92bb7d7baea5d779f10afae910",

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

# dlopen the libraries in order so that latter libraries can be dlopened
for product in all_products
    Libdl.dlopen_e(locate(product))
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), all_products)
