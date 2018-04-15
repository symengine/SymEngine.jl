"Helper function to lookup a symbol from libsymengine"
function get_symbol(sym::Symbol)
    handle = Libdl.dlopen_e(libsymengine)
    if handle == C_NULL
        C_NULL
    else
        Libdl.dlsym_e(handle, sym)
    end
end

"Get libsymengine version"
function get_libversion()
    func = get_symbol(:symengine_version)
    if func != C_NULL
        a = ccall(func, Ptr{UInt8}, ())
        VersionNumber(unsafe_string(a))
    else
        # Above method is not in 0.2.0 which is the earliest version supported
        VersionNumber("0.2.0")
    end
end

"Check whether libsymengine was compiled with comp"
function have_component(comp::String)
    func = get_symbol(:symengine_have_component)
    if func != C_NULL
        ccall(func, Cint, (Ptr{UInt8},), comp) == 1
    elseif comp == "mpfr"
        get_symbol(:real_mpfr_set_d) != C_NULL
    elseif comp == "mpc"
        get_symbol(:complex_mpc_real_part) != C_NULL
    else
        false
    end
end

