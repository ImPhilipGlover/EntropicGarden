#!/usr/bin/env io

// Prototypal Linter - C and Python Syntax Checker
// Validates C/C++ and Python code via synaptic bridge

PrototypalLinter := Object clone do(

    checkCSyntax := method(
        "🔍 Checking C/C++ syntax..." println
        // Use gcc/clang to check syntax
        cFiles := Directory with(".") files select(f, f name endsWithSeq(".c") or f name endsWithSeq(".cpp") or f name endsWithSeq(".h") or f name endsWithSeq(".hpp")) recursive
        cFiles foreach(file,
            result := System system("gcc -fsyntax-only -I. " .. file path)
            if(result != 0,
                "❌ C syntax error in: " .. file path println
                return false
            )
        )
        "✅ C/C++ syntax OK" println
        return true
    )

    checkPythonSyntax := method(
        "🔍 Checking Python syntax..." println
        pyFiles := Directory with(".") files select(f, f name endsWithSeq(".py")) recursive
        pyFiles foreach(file,
            result := System system("python -m py_compile " .. file path)
            if(result != 0,
                "❌ Python syntax error in: " .. file path println
                return false
            )
        )
        "✅ Python syntax OK" println
        return true
    )

    run := method(
        if(checkCSyntax and checkPythonSyntax,
            "✅ All C/C++ and Python syntax checks passed!" println
            return true
        ,
            return false
        )
    )
)

if(isLaunchScript,
    linter := PrototypalLinter clone
    if(linter run not, System exit(1))
)