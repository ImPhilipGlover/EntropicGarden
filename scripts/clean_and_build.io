#!/usr/bin/env io

// TelOS Clean and Build Orchestrator
// Io-orchestrated build process with integrated tool validation

CleanAndBuild := Object clone do(

    runPreBuildChecks := method(
        "🚀 TelOS Clean and Build - Pre-build validation..." println

        // 1. Eradicate mocks directly
        "Running eradicate mocks..." println
        result := System system("io scripts/eradicate_mocks.io .")
        "Eradicate mocks result: " .. (result == 0) println
        if(result != 0, Exception raise("Pre-build failed: eradicate mocks"))

        // 2. Compliance enforcer directly
        "Running compliance enforcer..." println
        result := System system("python3 scripts/compliance_enforcer.py --dry-run")
        "Compliance enforcer result: " .. (result == 0) println
        if(result != 0, Exception raise("Pre-build failed: compliance enforcer"))

        // 3. Io syntax checker directly
        "Running Io syntax checker..." println
        result := System system("bash scripts/io_syntax_checker.sh .")
        "Io syntax checker result: " .. (result == 0) println
        if(result != 0, Exception raise("Pre-build failed: Io syntax checker"))

        "✅ Pre-build checks passed" println
    )

    runBuild := method(
        "🔨 Building TelOS system..." println

        // Clean build directory
        "Cleaning build directory..." println
        result := System system("rm -rf build && mkdir build")
        if(result != 0, Exception raise("Build failed: clean"))

        // Configure with CMake
        "Configuring with CMake..." println
        result := System system("cd build && cmake .. -DCMAKE_BUILD_TYPE=Release")
        if(result != 0, Exception raise("Build failed: configure"))

        // Build
        "Building..." println
        result := System system("cd build && cmake --build . --config Release")
        if(result != 0, Exception raise("Build failed: build"))

        "✅ Build completed successfully" println
    )

    runPostBuildChecks := method(
        "🔍 TelOS Clean and Build - Post-build validation..." println

        // Load TelosBridge after build
        "Loading TelosBridge..." println
        doFile("libs/Telos/io/TelosBridge.io")
        bridge := Lobby Telos Bridge

        // Initialize bridge
        config := Map clone
        config atPut("max_workers", 2)
        config atPut("log_level", "INFO")
        result := bridge initialize(config)
        if(result isNil, Exception raise("Post-build failed: bridge initialization"))

        // 1. C syntax checker via bridge
        "Running C syntax checker..." println
        result := bridge checkCSyntax(".")
        if(result isNil, Exception raise("Post-build failed: C syntax checker"))

        // 2. Python syntax checker via bridge
        "Running Python syntax checker..." println
        result := bridge checkPythonSyntax(".")
        if(result isNil, Exception raise("Post-build failed: Python syntax checker"))

        // 3. Addon checker via bridge
        "Running addon checker..." println
        result := bridge checkAddons(".")
        if(result isNil, Exception raise("Post-build failed: addon checker"))

        // 4. Cognitive evolution monitor
        "Running cognitive evolution monitor..." println
        result := bridge monitorCognitiveEvolution
        if(result isNil, Exception raise("Post-build failed: cognitive evolution monitor"))

        "✅ Post-build checks passed" println
    )

    runFullBuild := method(
        try(
            runPreBuildChecks
            runBuild
            runPostBuildChecks
            "🎉 TelOS build completed successfully with all validations!" println
        ) catch(Exception, block(|e|
            "💥 Build failed: " .. e println
            System exit(1)
        ))
    )
)

if(isLaunchScript,
    builder := CleanAndBuild clone
    builder runFullBuild
)