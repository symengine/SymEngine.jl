using Pkg
Pkg.activate(".")
using SymEngine

struct CustomFunc
    name::String
    cfunc::Base.CFunction
    func1
    func2
end

struct CFunctionWrapperClass
    name::Ptr{Cchar}
    create_ptr::Ptr{Cvoid}
    diff_ptr::Ptr{Cvoid}
end

function create_func(name, f)
    function _create_func(a::Basic, args_ptr::Ptr{Cvoid})::Cint
        args = SymEngine.CVecBasic(args_ptr)
        try
            res = f(convert(Vector, args))
        catch e
            res = nothing
        end
        if res == nothing
            return 1
        else
            res = Basic(res)
            ccall((:basic_assign, SymEngine.libsymengine), Nothing, (Ref{Basic}, Ref{Basic}), a, res)
            return 0
        end
    end
    create_ptr = @cfunction($_create_func, Cint, (Ref{Basic}, Ptr{Cvoid}))
    return CustomFunc(name, create_ptr, f, _create_func)
end

function my_real(x::Vector{Basic})
   return real(N(x[1]))
end

function my_norm(x::Vector{Basic})
   a, b = N(x[1]), N(x[2])
   return sqrt(a^2+b^2)
end

@vars x

function (c::CustomFunc)(args...)
    v = convert(SymEngine.CVecBasic, args...)
    a = Basic()
    ccall((:basic_create_function_wrapper, SymEngine.libsymengine), Nothing, (Ref{Basic}, Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Ptr{Cvoid}), a, v.ptr, pointer(c.name), c.cfunc.ptr, C_NULL)
    return a
end

c = create_func("Re", my_real)
c(x)

d = create_func("Norm", my_norm)
d(2, 3)
