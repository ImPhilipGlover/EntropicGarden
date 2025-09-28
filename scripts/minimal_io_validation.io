#!/usr/bin/env io

//
// Minimal Io Validation Script
//
// This script loads Io files and checks for basic prototypal purity violations
// without requiring the full TelOS compiler bridge.
//

writeln("Starting minimal Io validation...")

// Load Io files
ioFiles := list(
    "libs/Telos/io/TelosBridge.io",
    "libs/Telos/io/TelosCompiler.io",
    "libs/Telos/io/TelosConceptRepository.io",
    "libs/Telos/io/TelosFederatedMemory.io",
    "libs/Telos/io/TelosGauntlet.io",
    "libs/Telos/io/TelosHRC.io",
    "libs/Telos/io/TelosTelemetry.io",
    "libs/Telos/io/TelosTelemetryDashboard.io",
    "libs/Telos/io/TelosZODBManager.io"
)

violations := list()

ioFiles foreach(filePath,
    file := File clone setPath(filePath)
    if(file exists,
        file open
        content := file readToEnd
        file close

        writeln("Checking " .. filePath .. "...")

        // Check for class patterns
        if(content containsSeq("class "),
            violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Contains 'class' keyword"))
        )
        if(content containsSeq(" extends "),
            violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Contains 'extends' keyword"))
        )
        if(content containsSeq(" new("),
            violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Contains 'new(' constructor pattern"))
        )

        // Check for missing markChanged calls (basic check)
        lines := content split("\n")
        methodLines := list()
        lines foreach(i, line,
            if(line containsSeq(":=") and line containsSeq("method("),
                methodLines append(i + 1)  // 1-indexed line number
            )
        )

        // Look for methods that modify state but don't call markChanged
        lines foreach(i, line,
            if(line containsSeq("append(") or line containsSeq("atPut(") or line containsSeq("set") or line containsSeq("add"),
                // Check if this method has markChanged
                methodStart := 0
                for(j, i, 0, -1,
                    if(lines at(j) containsSeq(":=") and lines at(j) containsSeq("method("),
                        methodStart := j
                        break
                    )
                )

                hasMarkChanged := false
                for(j, methodStart, lines size,
                    if(lines at(j) containsSeq("markChanged"),
                        hasMarkChanged := true
                        break
                    )
                    if(lines at(j) containsSeq(")"),
                        break
                    )
                )

                if(hasMarkChanged not,
                    violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Method modifies state but missing markChanged() call") atPut("line", i + 1))
                )
            )
        )

        "  ✅ Checked" println
    ,
        violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "File not found"))
    )
)

// Report results
writeln("\n=== Io Validation Results ===")
writeln("Total violations: " .. violations size)

if(violations size > 0,
    violations foreach(violation,
        "[" .. violation at("type") .. "] " .. violation at("file") .. ": " .. violation at("message") println
    )
    writeln("\n❌ Io validation failed")
    System exit(1)
,
    writeln("✅ Io validation passed")
    System exit(0)
)