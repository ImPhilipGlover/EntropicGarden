#!/usr/bin/env io

// Eradicate Mocks Tool
// Scans codebase for mock implementations and ensures 0 violations

EradicateMocks := Object clone do(

    scanForMocks := method(path,
        "🔍 Scanning for mock implementations..." println

        // Ensure path is a valid string
        if(path isNil, path = ".")

        // Scan Io files for mock patterns - look for specific mock indicators
        ioFiles := Directory with("libs/Telos/io") files select(f, f name endsWithSeq(".io"))
        mockCount := 0

        ioFiles foreach(file,
            content := File with(file path) contents
            // Look for specific mock patterns that indicate placeholder implementations
            if(content containsSeq("TODO.*mock") or
               content containsSeq("mock.*implementation") or
               content containsSeq("placeholder") or
               content containsSeq("stub") or
               content containsSeq("fake.*method"),
                "⚠️  Mock implementation found in: " .. file name println
                mockCount = mockCount + 1
            )
        )

        // Scan Python files for mock patterns
        pyFiles := Directory with(path) files select(f, f name endsWithSeq(".py"))
        pyFiles foreach(file,
            content := File with(file path) contents
            // Look for specific mock patterns that indicate placeholder implementations
            if(content containsSeq("TODO.*mock") or
               content containsSeq("mock.*implementation") or
               content containsSeq("placeholder") or
               content containsSeq("stub") or
               content containsSeq("fake.*method") or
               content containsSeq("NotImplementedError") or
               content containsSeq("pass.*#.*mock"),
                "⚠️  Mock implementation found in: " .. file path println
                mockCount = mockCount + 1
            )
        )

        if(mockCount == 0,
            "✅ No mock implementations found - system is production-ready!" println
            return true
        ,
            "❌ Found " .. mockCount .. " mock implementation violations" println
            return false
        )
    )

    run := method(
        if(scanForMocks not,
            System exit(1)
        )
    )
)

if(isLaunchScript,
    tool := EradicateMocks clone
    tool run
)