using SymEngine

x = basic_symbol("x")
y = basic_symbol("y")

a = x^2 + 2*x -x*y*5
b = basic_diff(a, x)

show(a)
show(b)
