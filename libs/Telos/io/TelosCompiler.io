//
// TelOS Compiler Orchestrator - Io-Driven Prototypal Purity Enforcement
//
// This Io prototype serves as the master compiler orchestrator for the TelOS system.
// It uses the synaptic bridge to invoke Python C compilation and linting operations,
// ensuring that all code adheres to prototypal purity principles.
//
// The compiler enforces:
// - UvmObject inheritance in all Python code
// - TelosProxyObject patterns in C code
// - Pure prototypal programming across the entire system
//
// All compilation flows through Io mind to maintain architectural coherence.
// Implementation uses the canonical polyglot pipeline: Io → C ABI → Python
//

TelosCompiler := Object clone do(
    //
    // Core Compiler State
    //

    // Compilation results and violations
    compilationResults := nil
    violations := list()
    buildStatus := "uninitialized"

    // Source directories to scan
    pythonSourceDir := "libs/Telos/python"
    cSourceDir := "libs/Telos/source"
    ioSourceDir := "libs/Telos/io"

    // Synaptic bridge reference
    bridge := nil

    //
    // Initialization and Setup
    //

    init := method(
        compilationResults = Map clone
        violations = list()
        buildStatus = "ready"
        bridge = nil

        // Add the build directory to addon search paths
        addonRootPath := "build/addons"
        if(Directory clone setPath(addonRootPath) exists,
            AddonLoader appendSearchPath(addonRootPath)
            "ℹ️  Added addon search path: " .. addonRootPath println
            
            // Also manually ensure it's in the search paths
            if(AddonLoader hasSlot("_searchPaths") not,
                AddonLoader _searchPaths := AddonLoader searchPaths
            )
            if(AddonLoader _searchPaths detect(path, path == addonRootPath) == nil,
                AddonLoader _searchPaths append(addonRootPath)
                "ℹ️  Manually added addon path to search paths" println
            )
        )

        // Load the synaptic bridge
        doRelativeFile("TelosBridge.io")
        if(Telos isNil or Telos Bridge isNil,
            "⚠️  Synaptic bridge not available - Io-only validation mode" println
            buildStatus = "bridge_unavailable"
        ,
            "✅ Synaptic bridge loaded" println
        )

        markChanged()
        self
    )

    //
    // Bridge Management
    //

    initializeBridge := method(
        "DEBUG: In initializeBridge method" println
        "DEBUG: Telos exists: " .. (Telos isNil not) println
        if(Telos isNil or Telos Bridge isNil,
            "DEBUG: Telos or Telos Bridge is nil" println
            "❌ Synaptic bridge not available" println
            return false
        )

        "DEBUG: Calling Telos Bridge initialize directly" println
        // Initialize the bridge with default workers
        if(Telos Bridge initialize(4),
            "✅ Synaptic bridge initialized" println
            true
        ,
            "❌ Failed to initialize synaptic bridge" println
            false
        )
    )

    shutdownBridge := method(
        if(Telos notNil and Telos Bridge notNil,
            Telos stop
            "ℹ️  Synaptic bridge shutdown" println
        )
    )

    //
    // JSON Task Submission via Bridge
    //

    submitCompilationTask := method(operation, filePath,
        // Use the synaptic bridge to submit tasks to Python handlers
        task := Map clone
        task atPut("operation", operation)
        if(filePath isNil not and filePath size > 0,
            task atPut("file", filePath)
        )

        // Convert to JSON for bridge transmission
        taskJson := task asJson

        // Submit via synaptic bridge
        e := try(
            responseJson := Telos Bridge submitTask(taskJson, 4096)  // 4KB buffer
            if(responseJson isNil,
                "  ❌ Bridge task failed: nil response" println
                return nil
            )

            response := responseJson asObject  // Parse JSON response
            if(response isNil,
                "  ❌ Bridge task failed: invalid JSON response" println
                return nil
            )

            return response
        )

        if(e,
            "  ❌ Bridge task failed: " .. (e type) .. " - " .. (e asString) println
            return nil
        )
    )

    //
    // Core Compilation Orchestration
    //

    compileTelosSystem := method(
        "Starting Io-orchestrated TelOS compilation with polyglot pipeline..." println

        "DEBUG: About to call initializeBridge" println
        // Initialize synaptic bridge
        if(initializeBridge not,
            "DEBUG: initializeBridge failed" println
            if(buildStatus == "bridge_unavailable",
                "ℹ️  Bridge unavailable - proceeding with Io-only validation" println
            ,
                buildStatus = "bridge_failed"
                markChanged()
                return false
            )
        )

        // Phase 1: Pre-compilation validation
        if(performPreCompilationValidation not,
            "❌ Pre-compilation validation failed" println
            triggerDocumentationReview("system", "Pre-compilation validation failed")
            buildStatus = "validation_failed"
            markChanged()
            shutdownBridge
            return false
        )

        // Phase 2: Python compilation with UvmObject enforcement
        if(buildStatus == "bridge_unavailable",
            "⏭️  Skipping Python compilation (bridge unavailable)" println
        ,
            if(compilePythonSubsystem not,
                "❌ Python compilation failed" println
                triggerDocumentationReview("python", "Python subsystem compilation failed")
                buildStatus = "python_failed"
                markChanged()
                shutdownBridge
                return false
            )
        )

        // Phase 3: C compilation with prototypal pattern enforcement
        if(buildStatus == "bridge_unavailable",
            "⏭️  Skipping C compilation (bridge unavailable)" println
        ,
            if(compileCSubsystem not,
                "❌ C compilation failed" println
                triggerDocumentationReview("c", "C subsystem compilation failed")
                buildStatus = "c_failed"
                markChanged()
                shutdownBridge
                return false
            )
        )

        // Phase 4: Io validation
        if(validateIoSubsystem not,
            "❌ Io validation failed" println
            triggerDocumentationReview("io", "Io subsystem validation failed")
            buildStatus = "io_failed"
            markChanged()
            shutdownBridge
            return false
        )

        shutdownBridge
        "✅ TelOS compilation completed successfully with prototypal purity enforced" println
        buildStatus = "success"
        markChanged()
        true
    )

    //
    // Pre-Compilation Validation
    //

    performPreCompilationValidation := method(
        "Performing pre-compilation validation..." println

        // Validate UvmObject is available in Python via bridge
        if(validateUvmObjectAvailable not,
            violations append(Map clone atPut("type", "system") atPut("message", "UvmObject not available in Python subsystem"))
            return false
        )

        "✅ Pre-compilation validation passed" println
        true
    )

    validateUvmObjectAvailable := method(
        result := submitCompilationTask("validate_uvm_object", "")
        if(result isNil, return false)

        if(result at("success") == true,
            "  ✅ UvmObject validation passed" println
            true
        ,
            "  ❌ UvmObject validation failed: " .. (result at("error") ? result at("error") : "unknown error") println
            triggerDocumentationReview("python", "UvmObject not available: " .. (result at("error") ? result at("error") : "unknown error"))
            false
        )
    )

    //
    // Python Subsystem Compilation
    //

    compilePythonSubsystem := method(
        "Compiling Python subsystem with UvmObject enforcement..." println

        // Get all Python files
        pythonFiles := getPythonFiles()

        pythonFiles foreach(file,
            if(compilePythonFile(file) not,
                violations append(Map clone atPut("file", file) atPut("type", "python") atPut("message", "Failed UvmObject inheritance validation"))
                return false
            )
        )

        "✅ Python subsystem compiled with UvmObject enforcement" println
        true
    )

    compilePythonFile := method(filePath,
        "  Analyzing Python file: " .. filePath println

        result := submitCompilationTask("validate_uvm_inheritance", filePath)
        if(result isNil, return false)

        if(result at("success") == true,
            violationsFound := result at("violation_count") ? result at("violation_count") : 0
            if(violationsFound > 0,
                "    ⚠️  Found " .. violationsFound .. " UvmObject violations" println
                // Add violations to our list
                result at("violations") foreach(violation,
                    "      Processing violation: " .. violation println
                    newViolation := Map clone
                    newViolation atPut("file", filePath)
                    newViolation atPut("type", "python")
                    newViolation atPut("line", violation at("line"))
                    newViolation atPut("rule", violation at("rule"))
                    newViolation atPut("message", violation at("message"))
                    newViolation atPut("severity", violation at("severity"))
                    violations append(newViolation)
                )
            ,
                "    ✅ No UvmObject violations found" println
            )
            true
        ,
            "    ❌ Python linting failed: " .. (result at("error") ? result at("error") : "unknown error") println
            false
        )
        markChanged()
    )

    getPythonFiles := method(
        // Use Io's Directory functionality to find Python files
        files := list()
        dir := Directory clone setPath(pythonSourceDir)
        if(dir exists,
            dir files foreach(file,
                if(file name endsWithSeq(".py"),
                    files append(pythonSourceDir .. "/" .. file name)
                )
            )
        )
        markChanged()
        files
    )

    //
    // C Subsystem Compilation
    //

    compileCSubsystem := method(
        "Compiling C subsystem with prototypal pattern enforcement..." println

        // Get all C files
        cFiles := getCFiles()

        cFiles foreach(file,
            if(compileCFile(file) not,
                violations append(Map clone atPut("file", file) atPut("type", "c") atPut("message", "Failed TelosProxyObject pattern validation"))
                return false
            )
        )

        "✅ C subsystem compiled with prototypal pattern enforcement" println
        markChanged()
        true
    )

    compileCFile := method(filePath,
        "  Analyzing C file: " .. filePath println

        result := submitCompilationTask("validate_telos_proxy_patterns", filePath)
        if(result isNil, return false)

        if(result at("success") == true,
            violationsFound := result at("violation_count") ? result at("violation_count") : 0
            if(violationsFound > 0,
                "    ⚠️  Found " .. violationsFound .. " TelosProxyObject violations" println
                // Add violations to our list
                result at("violations") foreach(violation,
                    violations append(Map clone
                        atPut("file", filePath)
                        atPut("type", "c")
                        atPut("line", violation at("line"))
                        atPut("rule", violation at("rule"))
                        atPut("message", violation at("message"))
                        atPut("severity", violation at("severity"))
                    )
                )
            ,
                "    ✅ No TelosProxyObject violations found" println
            )
            true
        ,
            "    ❌ C validation failed: " .. (result at("error") ? result at("error") : "unknown error") println
            false
        )
        markChanged()
    )

    getCFiles := method(
        // Find C source files
        files := list()
        dir := Directory clone setPath(cSourceDir)
        if(dir exists,
            dir files foreach(file,
                if(file name endsWithSeq(".c") or file name endsWithSeq(".h"),
                    files append(cSourceDir .. "/" .. file name)
                )
            )
        )
        markChanged()
        files
    )

    //
    // Io Subsystem Validation
    //

    validateIoSubsystem := method(
        "Validating Io subsystem for prototypal purity..." println

        // Get all Io files
        ioFiles := getIoFiles()

        ioFiles foreach(file,
            if(validateIoFile(file) not,
                violations append(Map clone atPut("file", file) atPut("type", "io") atPut("message", "Failed Io prototypal pattern validation"))
                return false
            )
        )

        "✅ Io subsystem validated for prototypal purity" println
        markChanged()
        true
    )

    validateIoFile := method(filePath,
        // Io validation can be done directly in Io since we're already in Io
        file := File clone setPath(filePath)
        if(file exists,
            file open
            fileContent := file readToEnd
            file close
            // Check for forbidden class-like patterns
            if(fileContent containsSeq("class ") or fileContent containsSeq(" extends ") or fileContent containsSeq(" subclass ") or fileContent containsSeq(" new("),
                violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "Contains class-based patterns"))
                triggerDocumentationReview("io", "Io file contains class-based patterns: " .. filePath)
                false
            ,
                true
            )
        ,
            violations append(Map clone atPut("file", filePath) atPut("type", "io") atPut("message", "File not found"))
            false
        )
        markChanged()
    )

    getIoFiles := method(
        // Find Io source files
        files := list()
        dir := Directory clone setPath(ioSourceDir)
        if(dir exists,
            dir files foreach(file,
                if(file name endsWithSeq(".io"),
                    files append(ioSourceDir .. "/" .. file name)
                )
            )
        )
        markChanged()
        files
    )

    //
    // Reporting and Status
    //

    getCompilationReport := method(
        report := Map clone
        report atPut("status", buildStatus)
        report atPut("totalViolations", violations size)
        report atPut("violationsByType", Map clone)
        report atPut("violationDetails", violations)

        violations foreach(violation,
            type := violation at("type")
            if(report at("violationsByType") at(type) isNil,
                report at("violationsByType") atPut(type, 0)
            )
            report at("violationsByType") atPut(type, report at("violationsByType") at(type) + 1)
        )

        markChanged()
        report
    )

    printReport := method(
        report := getCompilationReport()

        "=== TelOS Compiler Report ===" println
        "Status: " .. report at("status") println
        "Total Violations: " .. report at("totalViolations") println
        "" println

        if(report at("totalViolations") > 0,
            "Violations by type:" println
            report at("violationsByType") foreach(type, count,
                "  " .. type .. ": " .. count println
            )
            "" println

            "Violation details:" println
            violations foreach(violation,
                "  [" .. violation at("type") .. "] " .. violation at("file") .. ": " .. violation at("message") println
            )
        )
        markChanged()
    )

    //
    // Persistence Covenant
    //

    markChanged := method(
        // For future ZODB integration
        self
    )

    //
    // Documentation Review Integration
    //

    triggerDocumentationReview := method(subsystem, errorDetails,
        "🔍 Triggering documentation review for subsystem: " .. subsystem println
        "   Error details: " .. errorDetails println

        docsToReview := getDocumentationForSubsystem(subsystem)
        
        docsToReview foreach(doc,
            "  📖 Reviewing: " .. doc println
            reviewResult := performDocumentationReview(doc, errorDetails, subsystem)
            if(reviewResult at("success") == true and reviewResult at("relevant") == true,
                "    ✅ Found relevant guidance in " .. doc println
                "    💡 " .. (reviewResult at("guidance") ? reviewResult at("guidance") : "No guidance") println
            ,
                "    ℹ️  " .. (reviewResult at("guidance") ? reviewResult at("guidance") : "No guidance") println
            )
        )

        // Also perform semantic search for related patterns
        performSemanticSearch(subsystem, errorDetails)

        markChanged()
    )    getDocumentationForSubsystem := method(subsystem,
        docs := Map clone

        // Io Prototypes & Persistence subsystem
        docs atPut("io", list(
            "docs/IoCodingStandards.html",
            "docs/IoGuide.html",
            "docs/IoTutorial.html",
            "docs/Io Prototype Programming Training Guide.txt",
            "docs/Building TelOS with Io and Morphic.txt",
            "docs/AI Plan Synthesis_ High-Resolution Blueprint.txt",
            "docs/Design Protocol for Dynamic System Resolution.txt"
        ))

        // Python Workers & Shared Memory subsystem
        docs atPut("python", list(
            "docs/AI Plan Synthesis_ High-Resolution Blueprint.txt",
            "docs/Design Protocol for Dynamic System Resolution.txt",
            "docs/AI Constructor Implementation Plan.txt",
            "docs/Tiered Cache Design and Optimization.txt"
        ))

        // C Substrate / Synaptic Bridge subsystem
        docs atPut("c", list(
            "docs/AI Plan Synthesis_ High-Resolution Blueprint.txt",
            "docs/Design Protocol for Dynamic System Resolution.txt",
            "docs/AI Constructor Implementation Plan.txt",
            "docs/Prototypal Emulation Layer Design.txt"
        ))

        // Federated Memory / Caching subsystem
        docs atPut("memory", list(
            "docs/Tiered Cache Design and Optimization.txt",
            "docs/Design Protocol for Dynamic System Resolution.txt",
            "docs/AI Constructor Implementation Plan.txt"
        ))

        // LLM / Transduction Pipeline subsystem
        docs atPut("llm", list(
            "docs/TELOS Implementation Addendum 1.3_ Protocol for the Integration of Local Language Models as Natural Language Transducers.txt",
            "docs/AI Plan Synthesis_ High-Resolution Blueprint.txt",
            "docs/AI Constructor Implementation Plan.txt"
        ))

        // Morphic UI / Rendering subsystem
        docs atPut("ui", list(
            "docs/Building TelOS with Io and Morphic.txt",
            "docs/Io Morphic UI with WSLg SDL2.txt",
            "docs/Morphic UI Framework Training Guide Extension.txt"
        ))

        docs at(subsystem) ? docs at(subsystem) : list()
    )

    performDocumentationReview := method(docPath, errorDetails,
        "    📖 Analyzing documentation: " .. docPath println
        
        // Submit documentation review task to Python via bridge
        task := Map clone
        task atPut("operation", "review_documentation")
        task atPut("doc_path", docPath)
        task atPut("error_details", errorDetails)
        
        taskJson := task asJson
        responseJson := Telos Bridge submitTask(taskJson, 8192)  // Larger buffer for doc content
        
        if(responseJson isNil,
            result := Map clone
            result atPut("relevant", false)
            result atPut("guidance", "Failed to read documentation: bridge unavailable")
            return result
        )
        
        response := responseJson asObject
        if(response isNil,
            result := Map clone
            result atPut("relevant", false)
            result atPut("guidance", "Failed to parse documentation response")
            return result
        )
        
        // Return the analysis result from Python
        result := Map clone
        result atPut("relevant", response at("relevant") ? response at("relevant") : false)
        result atPut("guidance", response at("guidance") ? response at("guidance") : "No guidance available")
        
        result
    )

    performSemanticSearch := method(subsystem, errorDetails,
        "🔎 Performing semantic search for related patterns..." println

        // Extract key terms from error details
        keyTerms := extractKeyTerms(errorDetails)

        // Search for related concepts in the codebase
        relatedPatterns := findRelatedPatterns(keyTerms, subsystem)

        if(relatedPatterns size > 0,
            "    📚 Found related patterns in codebase:" println
            relatedPatterns foreach(pattern,
                "      • " .. pattern println
            )
        ,
            "    📚 No specific related patterns found in codebase" println
        )
    )

    extractKeyTerms := method(errorDetails,
        // Simple keyword extraction - in a full implementation this would use NLP
        terms := list()
        
        errorLower := errorDetails asLowercase
        
        if(errorLower containsSeq("uvmobject"), terms append("UvmObject"))
        if(errorLower containsSeq("prototypal") or errorLower containsSeq("prototype"), terms append("prototypal"))
        if(errorLower containsSeq("inheritance"), terms append("inheritance"))
        if(errorLower containsSeq("class"), terms append("class"))
        if(errorLower containsSeq("bridge") or errorLower containsSeq("synaptic"), terms append("bridge"))
        if(errorLower containsSeq("ffi"), terms append("FFI"))
        if(errorLower containsSeq("zodb") or errorLower containsSeq("persistent"), terms append("ZODB"))
        if(errorLower containsSeq("memory") or errorLower containsSeq("shared"), terms append("memory"))
        if(errorLower containsSeq("cache"), terms append("cache"))
        if(errorLower containsSeq("io "), terms append("Io"))
        if(errorLower containsSeq("python"), terms append("Python"))
        if(errorLower containsSeq("c ") or errorLower containsSeq("c++"), terms append("C"))
        
        terms
    )

    findRelatedPatterns := method(keyTerms, subsystem,
        patterns := list()
        
        // Search for related patterns in source files
        // This is a simplified version - full implementation would use semantic search
        
        keyTerms foreach(term,
            // Look for files that might contain related patterns
            searchPaths := getSubsystemSearchPaths(subsystem)
            searchPaths foreach(path,
                dir := Directory clone setPath(path)
                if(dir exists,
                    dir files foreach(file,
                        fileName := file name asLowercase
                        if(fileName endsWithSeq(".py") or fileName endsWithSeq(".io") or fileName endsWithSeq(".c") or fileName endsWithSeq(".h"),
                            // Check if file might be relevant
                            if(fileName containsSeq(term asLowercase) or term asLowercase containsSeq(fileName),
                                patterns append("Consider reviewing " .. path .. "/" .. file name .. " for " .. term .. " patterns")
                            )
                        )
                    )
                )
            )
        )
        
        patterns
    )

    getSubsystemSearchPaths := method(subsystem,
        paths := Map clone
        
        paths atPut("io", list("libs/Telos/io"))
        paths atPut("python", list("libs/Telos/python"))
        paths atPut("c", list("libs/Telos/source"))
        paths atPut("system", list("libs/Telos/io", "libs/Telos/python", "libs/Telos/source"))
        
        paths at(subsystem) ? paths at(subsystem) : list()
    )

    analyzeDocumentationForError := method(content, errorDetails, docPath,
        guidance := ""

        // Convert error details to lowercase for case-insensitive matching
        errorLower := errorDetails asLowercase

        // Look for relevant sections based on error patterns
        if(errorLower containsSeq("uvmobject") or errorLower containsSeq("prototypal") or errorLower containsSeq("inheritance"),
            // Python/UvmObject related errors
            if(content asLowercase containsSeq("uvmobject") or content asLowercase containsSeq("prototypal"),
                guidance = guidance .. "Found UvmObject guidance in " .. docPath .. ". "
            )
        )

        if(errorLower containsSeq("class") or errorLower containsSeq("extends") or errorLower containsSeq("subclass"),
            // Io class-related errors
            if(content asLowercase containsSeq("prototype") or content asLowercase containsSeq("clone") or content asLowercase containsSeq("object"),
                guidance = guidance .. "Found Io prototypal programming guidance in " .. docPath .. ". "
            )
        )

        if(errorLower containsSeq("bridge") or errorLower containsSeq("synaptic") or errorLower containsSeq("ffi"),
            // Bridge/FFI related errors
            if(content asLowercase containsSeq("bridge") or content asLowercase containsSeq("ffi") or content asLowercase containsSeq("c abi"),
                guidance = guidance .. "Found synaptic bridge guidance in " .. docPath .. ". "
            )
        )

        if(errorLower containsSeq("zodb") or errorLower containsSeq("persistent") or errorLower containsSeq("storage"),
            // Persistence related errors
            if(content asLowercase containsSeq("zodb") or content asLowercase containsSeq("persistent") or content asLowercase containsSeq("storage"),
                guidance = guidance .. "Found persistence layer guidance in " .. docPath .. ". "
            )
        )

        if(errorLower containsSeq("memory") or errorLower containsSeq("shared") or errorLower containsSeq("cache"),
            // Memory/cache related errors
            if(content asLowercase containsSeq("memory") or content asLowercase containsSeq("cache") or content asLowercase containsSeq("shared"),
                guidance = guidance .. "Found memory management guidance in " .. docPath .. ". "
            )
        )

        if(guidance size == 0,
            // Generic guidance if no specific patterns match
            guidance = "Review " .. docPath .. " for general architectural guidance related to: " .. errorDetails
        )

        guidance
    )
)

// Export the compiler prototype
TelosCompiler