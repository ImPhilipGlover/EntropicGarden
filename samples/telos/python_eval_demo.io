// Python Eval Demo: exercise Telos.pyEval for simple expressions and statements
Telos init
Telos createWorld

writeln("-- Python Eval Demo --")
writeln("version: ", Telos pyEval("import sys; sys.version.split()[0]"))
writeln("sum 1..5: ", Telos pyEval("sum(range(1,6))"))
writeln("exec stmt (no output): ", Telos pyEval("x=41\nx+=1"))
writeln("x value (should be 42 or empty if separate env): ", Telos pyEval("'x=' + str(globals().get('x',''))"))

Telos walBegin("py.demo")
Telos walEnd("py.demo")

"Python eval demo completed" println
