#!/usr/bin/env io

//
// Io-Only Validation Script
//
// This script validates Io files for prototypal purity without requiring
// the synaptic bridge to be loaded.
//

writeln("Starting Io-only validation...")

// Create a mock TelosCompiler that doesn't require the bridge
TelosCompiler := Object clone do(
    setSlot("violations", list())
    setSlot("buildStatus", "ready")

    validateIoSubsystem := method(
        "Validating Io subsystem for prototypal purity..." println

        // Get all Io files
        ioFiles := getIoFiles()

        ioFiles foreach(file,
            "Checking " .. file println
            if(validateIoFile(file) not,
                violations append(Map clone atPut("file", file) atPut("type", "io") atPut("message", "Failed Io prototypal pattern validation"))
                "  ❌ Failed" println
                // Don't return false - continue checking other files
            ,
                "  ✅ Passed" println
            )
        )

        "✅ Io subsystem validated for prototypal purity" println
        violations size == 0  // Return true only if no violations
    )

    validateIoFile := method(filePath,
        // Io validation can be done directly in Io since we're already in Io
        file := File clone setPath(filePath)
        if(file exists,
            file open
            fileContent := file readToEnd
            file close

            if(fileContent isNil,
                violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Could not read file content"))
                return false
            )

            // Check for forbidden class-like patterns
            if(fileContent containsSeq("class ") or fileContent containsSeq(" extends ") or fileContent containsSeq(" subclass ") or fileContent containsSeq(" new("),
                violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Contains class-based patterns"))
                return false
            )

            // Simple check for missing markChanged - look for methods that contain state-modifying operations
            // but don't contain markChanged
            if((fileContent containsSeq("append(") or fileContent containsSeq("atPut(") or
                fileContent containsSeq("setSlot(") or fileContent containsSeq("set ") or
                fileContent containsSeq("add") or fileContent containsSeq("remove")) and
               fileContent containsSeq("markChanged") not,
                violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "File contains state-modifying operations but no markChanged calls"))
                return false
            )

            true
        ,
            violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "File not found"))
            false
        )
    )

    getIoFiles := method(
        // Find Io source files
        files := list()
        dir := Directory clone setPath("libs/Telos/io")
        if(dir exists,
            dir files foreach(file,
                if(file name endsWithSeq(".io"),
                    files append("libs/Telos/io/" .. file name)
                )
            )
        )
        files
    )

    printReport := method(
        "=== Io Validation Report ===" println
        "Total Violations: " .. violations size println
        "" println

        if(violations size > 0,
            violations foreach(violation,
                "  [" .. violation at("type") .. "] " .. violation at("file") .. ": " .. violation at("message") println
            )
        )
    )
)

// Run validation
compiler := TelosCompiler clone
result := compiler validateIoSubsystem

// Print results
compiler printReport

// Exit with appropriate code
if(result,
    writeln("✅ Io validation successful")
    System exit(0)
,
    writeln("❌ Io validation failed")
    System exit(1)
)