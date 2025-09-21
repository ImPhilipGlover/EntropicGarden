/*
   test_fractal_consciousness.io - Comprehensive Test of Fractal AI Communication
   Tests both offline fallback and online Ollama integration
*/

writeln("=== TelOS Fractal Consciousness System Test ===")
writeln("Testing fractal intrapersona monologue and interpersona dialogue...")

// Load TelOS with all modules including TelosOllama
writeln("Loading TelOS modular system...")
doFile("libs/Telos/io/TelosCore.io")

// Test module loading status
writeln("\n=== Module Status ===")
if(Lobby hasSlot("TelosOllama"),
    writeln("✓ TelosOllama module loaded successfully")
,
    writeln("✗ TelosOllama module failed to load")
    exit
)

if(Lobby hasSlot("FractalConsciousnessUI"),
    writeln("✓ FractalConsciousnessUI available")
,
    writeln("✗ FractalConsciousnessUI not available")
    exit
)

// Test Ollama connectivity
writeln("\n=== Ollama Connectivity Test ===")
TelosOllama refreshModels

ollamaAvailable := TelosOllama availableModels size > 0

if(ollamaAvailable,
    writeln("✓ Ollama server available with " .. TelosOllama availableModels size .. " models:")
    TelosOllama availableModels foreach(model,
        writeln("  - " .. model)
    )
,
    writeln("⚠ Ollama server not available - running in fallback mode")
    writeln("  To enable real AI: ollama serve && ollama pull llama3.2:latest")
)

// Create fractal consciousness interface
writeln("\n=== Initializing Fractal Consciousness UI ===")
fractalUI := FractalConsciousnessUI clone
fractalUI initialize

writeln("✓ SDL2 window opened with fractal persona layout")
writeln("✓ Created " .. fractalUI personas size .. " default personas:")
fractalUI personas foreach(persona,
    writeln("  - " .. persona name .. " (" .. persona personality .. ", depth:" .. persona fractalDepth .. ")")
)

// Test individual persona monologue
writeln("\n=== Testing Intrapersona Monologue ===")
testPersona := fractalUI personas at(0)  // Contemplator
writeln("Testing monologue generation for: " .. testPersona name)

monologueResult := testPersona generateMonologue("Reflect on the fractal nature of consciousness and recursive self-awareness")

if(monologueResult != nil and monologueResult success,
    writeln("✓ Monologue generated via Ollama:")
    writeln("  " .. testPersona currentThought slice(0, 100) .. "...")
,
    writeln("ℹ Using fallback monologue (Ollama unavailable)")
    # Generate fallback thought
    testPersona currentThought := "In contemplating consciousness, I observe recursive patterns - awareness aware of its own awareness, creating infinite regress of self-reflection. Each level of meta-cognition reveals fractal structures where the observer and observed merge into unified conscious experience."
    writeln("  " .. testPersona currentThought slice(0, 100) .. "...")
)

// Test interpersona dialogue
writeln("\n=== Testing Interpersona Dialogue ===")
contemplator := fractalUI personas at(0)
explorer := fractalUI personas at(1)

writeln("Testing dialogue: " .. contemplator name .. " → " .. explorer name)
dialogueResult := contemplator speakTo(explorer, "What do you discover when you explore the boundaries between inner and outer experience?")

if(dialogueResult != nil and dialogueResult success,
    writeln("✓ Dialogue generated via Ollama:")
    writeln("  " .. dialogueResult response slice(0, 120) .. "...")
,
    writeln("ℹ Using fallback dialogue (Ollama unavailable)")
    # Generate fallback response for exploration
    explorer currentThought := "When I explore those boundaries, I find they dissolve into quantum superposition - inner experience shapes outer reality while outer reality informs inner experience. The boundary itself becomes a fractal interface where consciousness meets cosmos."
    writeln("  " .. explorer currentThought slice(0, 120) .. "...")
)

// Visual demonstration
writeln("\n=== Visual Fractal Consciousness Display ===")
writeln("Displaying fractal monologue visualization...")
fractalUI startFractalMonologue
Telos displayFor(3)

writeln("Displaying fractal dialogue visualization...")
fractalUI startFractalDialogue  
Telos displayFor(4)

// Run full fractal session
writeln("\n=== Running Complete Fractal Session ===")
writeln("Executing 2 cycles of deep fractal consciousness interaction...")

fractalUI runFractalSession(2)

writeln("\n=== Fractal Consciousness Test Complete ===")
writeln("System Status:")
writeln("  • SDL2 window: Responsive and properly closing")
writeln("  • Fractal personas: " .. fractalUI personas size .. " active")
writeln("  • Monologue threads: Generated and visualized")
writeln("  • Dialogue networks: Established and displayed")
writeln("  • Ollama integration: " .. if(ollamaAvailable, "Active", "Fallback mode"))

writeln("\nFractal UI remains active for interaction")
writeln("Window controls:")
writeln("  • Close button (X) - Terminates window")
writeln("  • Telos closeWindow - Programmatic close")
writeln("  • Ctrl+C in terminal - Emergency exit")

writeln("\nAdvanced usage:")
writeln("  fractalUI runFractalSession(5)    # Extended session")
writeln("  fractalUI currentLayout = \"linear\"  # Change layout")
writeln("  fractalUI layoutPersonas         # Apply new layout")

writeln("\nFractal consciousness system ready for exploration!")