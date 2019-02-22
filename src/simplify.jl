if VERSION < v"1.0.0-rc1"
    import Base.expand
end
IMPLEMENT_ONE_ARG_FUNC(:expand, :expand)

if get_symbol(:basic_cse) != C_NULL
    function cse(exprs...)
        vec = convert(CVecBasic, exprs...)
        replacement_syms = CVecBasic()
        replacement_exprs = CVecBasic()
        reduced_exprs = CVecBasic()
        ccall((:basic_cse, libsymengine), Nothing, (Ptr{Cvoid},Ptr{Cvoid},Ptr{Cvoid},Ptr{Cvoid}),
            replacement_syms.ptr, replacement_exprs.ptr, reduced_exprs.ptr,vec.ptr)
        return replacement_syms, replacement_exprs, reduced_exprs
    end
else
    function cse(exprs...)
        error("libsymengine is too old")
    end
end
