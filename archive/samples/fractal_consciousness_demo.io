/*
   fractal_consciousness_demo.io - Demonstration of Fractal AI Communication
   Intrapersona Monologue & Interpersona Dialogue with Ollama Models
*/

writeln("=== TelOS Fractal Consciousness Demo ===")
writeln("Initializing fractal AI communication interface...")

// Load required modules
doFile("libs/Telos/io/TelosCore.io")
doFile("libs/Telos/io/TelosOllama.io")

// Check Ollama availability
writeln("Checking Ollama server availability...")
TelosOllama refreshModels

if(TelosOllama availableModels size > 0,
    writeln("✓ Ollama server detected with " .. TelosOllama availableModels size .. " models")
    TelosOllama availableModels foreach(model,
        writeln("  - " .. model)
    )
,
    writeln("⚠ Ollama server not available - demo will run in fallback mode")
    writeln("To use real AI models, ensure Ollama is running:")
    writeln("  curl -fsSL https://ollama.ai/install.sh | sh")
    writeln("  ollama serve")
    writeln("  ollama pull llama3.2:latest")
)

// Create and initialize the fractal consciousness UI
writeln("\nInitializing Fractal Consciousness UI...")
fractalUI := FractalConsciousnessUI clone
fractalUI initialize

writeln("\n=== Fractal Consciousness Interface Ready ===")
writeln("Available commands:")
writeln("  - fractalUI runFractalSession(3)  # Run 3 cycles of fractal dialogue")
writeln("  - fractalUI startFractalMonologue # Trigger internal contemplation")
writeln("  - fractalUI startFractalDialogue  # Initiate persona interactions")
writeln("  - fractalUI layoutPersonas       # Rearrange visual layout")

// Demonstrate basic functionality
writeln("\n=== Running Basic Fractal Demonstration ===")

// Create a test persona for demonstration
testPersona := FractalPersona clone
testPersona name := "TestThinker" 
testPersona personality := "analytical and curious"
testPersona model := TelosOllama defaultModel

writeln("Created test persona: " .. testPersona name)

// Test monologue generation (will use fallback if Ollama unavailable)
writeln("\nTesting intrapersona monologue...")
result := testPersona generateMonologue("What is the nature of fractal consciousness?")

if(result != nil and result success,
    writeln("✓ Monologue generated successfully")
,
    writeln("ℹ Using fallback mode (Ollama not available)")
    # Fallback thought for demo
    testPersona currentThought := "Consciousness appears to exhibit fractal properties - patterns repeating at different scales of awareness, from neural networks to social cognition to cosmic intelligence."
    writeln("Generated fallback thought: " .. testPersona currentThought)
)

// Test visual display
writeln("\nTesting fractal visualization...")
fractalUI startFractalMonologue
Telos displayFor(2)

writeln("\n=== Interactive Demo Ready ===")
writeln("The fractal consciousness interface is now active!")
writeln("Visual elements:")
writeln("  • Blue rectangles = AI personas with internal monologue")
writeln("  • Green rectangles = Interpersona dialogue connections")  
writeln("  • Text bubbles = Current thoughts and communications")
writeln("")
writeln("To run full fractal consciousness session:")
writeln("  fractalUI runFractalSession(5)  # 5 cycles of deep AI dialogue")
writeln("")
writeln("Window will remain open for interaction...")
writeln("Use Telos closeWindow when finished")

// Keep window open for interaction
writeln("\nFractal consciousness demo active - window responsive to interactions")
writeln("Press Ctrl+C in terminal to exit, or close window with X button")