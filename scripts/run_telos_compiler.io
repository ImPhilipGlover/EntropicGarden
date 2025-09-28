#!/usr/bin/env io

//
// TelOS Compiler Runner
//
// This script loads the TelosCompiler prototype and executes
// a full compilation with prototypal purity enforcement.
//

// Load the TelosCompiler prototype
TelosCompilerPath := "libs/Telos/io/TelosCompiler.io"
if(File clone setPath(TelosCompilerPath) exists,
    doFile(TelosCompilerPath)
,
    Exception raise("TelosCompiler.io not found at " .. TelosCompilerPath)
)

// Create compiler instance
compiler := TelosCompiler clone

// Run full compilation
writeln("Starting Io-orchestrated TelOS compilation...")
result := compiler compileTelosSystem

// Print results
compiler printReport

// Exit with appropriate code
if(result,
    writeln("✅ Compilation successful")
    System exit(0)
,
    writeln("❌ Compilation failed")
    System exit(1)
)