#!/usr/bin/env io
/*
   Demo Launcher - Easy access to all TelOS Morphic demonstrations
   
   This provides a simple interface to run any of the morphic demos
   with proper sequencing and error handling.
*/

writeln("=== TelOS Morphic Demo Launcher ===")
writeln()

DemoLauncher := Object clone do(
    
    demoPath := "demos/morphic/"
    
    // Check if we're in the right directory
    checkEnvironment := method(
        currentDir := Directory currentWorkingDirectory
        if(File exists(self demoPath .. "basic_window_demo.io") == false,
            writeln("❌ Demo files not found!")
            writeln("   Please ensure you're running from the EntropicGarden root directory.")
            writeln("   Current directory: " .. currentDir)
            return false
        )
        true
    )
    
    // Run basic window demo
    runBasicDemo := method(
        if(self checkEnvironment == false, return)
        
        writeln("🚀 Launching Basic Morphic Window Demo...")
        doFile(self demoPath .. "basic_window_demo.io")
    )
    
    // Run interactive demo
    runInteractiveDemo := method(
        if(self checkEnvironment == false, return)
        
        writeln("🎮 Launching Interactive Morphic Demo...")
        
        // Check if basic demo has been run
        if(Telos world == nil,
            writeln("⚠️  Basic demo not detected. Running it first...")
            self runBasicDemo
            writeln()
        )
        
        doFile(self demoPath .. "interactive_demo.io")
        writeln("✨ Interactive demo loaded. Run: InteractiveMorphicDemo runDemo")
    )
    
    // Run evolution demo
    runEvolutionDemo := method(
        if(self checkEnvironment == false, return)
        
        writeln("🧬 Launching Living Image Evolution Demo...")
        
        // Check if basic demo has been run  
        if(Telos world == nil,
            writeln("⚠️  Basic demo not detected. Running it first...")
            self runBasicDemo
            writeln()
        )
        
        doFile(self demoPath .. "living_image_evolution.io")
        writeln("🌟 Evolution demo loaded. Run: LivingImageEvolution runEvolutionDemo")
    )
    
    // Run all demos in sequence
    runAllDemos := method(
        if(self checkEnvironment == false, return)
        
        writeln("🎪 Running Complete Demo Suite...")
        writeln("=" repeated(50))
        writeln()
        
        // 1. Basic demo
        self runBasicDemo
        writeln()
        
        // 2. Interactive demo
        writeln("Continuing with interactive demo...")
        doFile(self demoPath .. "interactive_demo.io")
        writeln("Running interactive demonstrations...")
        InteractiveMorphicDemo runDemo
        writeln()
        
        // 3. Evolution demo
        writeln("Continuing with evolution demo...")
        doFile(self demoPath .. "living_image_evolution.io")
        writeln("Running evolution demonstrations...")
        LivingImageEvolution runEvolutionDemo
        writeln()
        
        writeln("🎉 Complete demo suite finished!")
        writeln("All objects remain live for further interaction.")
    )
    
    // Show help
    showHelp := method(
        writeln("Available Demo Commands:")
        writeln("  DemoLauncher runBasicDemo        - Basic window with morphs")
        writeln("  DemoLauncher runInteractiveDemo  - Interactive manipulation") 
        writeln("  DemoLauncher runEvolutionDemo    - Living Image evolution")
        writeln("  DemoLauncher runAllDemos         - Complete demo suite")
        writeln("  DemoLauncher showHelp            - Show this help")
        writeln()
        writeln("Quick Start: DemoLauncher runAllDemos")
    )
)

// Show available commands
writeln("TelOS Morphic Demo Suite loaded!")
writeln()
DemoLauncher showHelp

// Return launcher for use
DemoLauncher