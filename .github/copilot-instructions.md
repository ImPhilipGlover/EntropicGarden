## CRITICAL: Source Code Fix Priority

**MANDATORY REQUIREMENT**: When encountering any system issues, bugs, or rendering problems (especially morphic UI issues), you MUST:

1. **First investigate and fix the C source code** in `libs/Telos/source/` - do NOT write Io scripts as workarounds
2. Only write Io scripts for testing/demonstration purposes AFTER the C code is fixed
3. If the C code fix is complex, create a todo list and work through it systematically
4. Verify C code fixes by building and testing, not by writing more scripts

**FORBIDDEN**: Creating Io script "solutions" that mask underlying C code problems. The core system must work correctly in C before any Io-level workarounds are considered.

## CRITICAL: Mandatory Documentation Review System

**MANDATORY REQUIREMENT**: At the start of every chat session and after every failed build, compilation error, runtime error, or any error message received in the command line, you MUST immediately read and review the documentation files that are applicable to the problem at hand. Do not read all files blindly - use your judgment to identify which files contain relevant information for the current issue. The available documentation files are:

1. `AI System Design Instructions.txt` - Core architectural mandates and implementation guide
2. `Building TelOS with Io and Morphic.txt` - System construction blueprint and Morphic UI integration
3. `Io Prototype Programming Training Guide.txt` - Prototype-based programming fundamentals
4. `Io, C, and Python System Design.txt` - Synaptic bridge architecture and C FFI requirements
5. `Mathematical Functions For Knowledge Discovery.txt` - Laplace-HDC encoding and cognitive mathematics
6. `Morphic UI Framework Training Guide Extension.txt` - Direct manipulation UI philosophy
7. `Neuro-Symbolic Reasoning Cycle Implementation Plan.txt` - LLM-GCE-HRC-AGL-LLM cognitive loop
8. `Prototypal Emulation Layer Design.txt` - FFI proxy objects and emulation patterns
9. `Researching AI System Design Appendix.txt` - Theoretical foundations and NSAI principles
10. `docs/IoCodingStandards.html` - Io language coding conventions and standards
11. `docs/IoGuide.html` - Complete Io programming language reference
12. `docs/IoTutorial.html` - Io language tutorial and practical examples
13. `.github/copilot-instructions.md` - Critical behavioral directives and development protocols
14. `Io Morphic UI with WSLg SDL2.txt` - Morphic UI implementation guide with SDL2 and WSLg

**AUTOMATED ENFORCEMENT**: The build system automatically triggers documentation review on failures:
- Use `./build_with_review.sh` instead of direct `make` commands
- Any build failure automatically displays ALL documentation files via `trigger_doc_review.sh`
- Check for `.last_build_failed` flag indicating unacknowledged review requirement
- **DO NOT proceed with development until review is acknowledged**

**Failure to comply with this protocol constitutes a critical violation of development standards.** You must explicitly acknowledge reading these files in your response after any error occurs or at the start of each chat session, and demonstrate understanding of their content in your subsequent code modifications.

Organize all tests so they are in the demos/tests/ directory.

Also, I'm not always right, be very skeptical of my suggestions. I do not always understand the full context of the codebase. I am a layman when it comes to the TelOS codebase and programming in general. I may suggest things that are incorrect or nonsensical. Always verify my suggestions against the existing code and documentation.

## System Overview

TelOS is a neuro-symbolic, prototypal intelligence system built on the Io programming language with Python computational backends. The system embodies a "Living Image" philosophy where development occurs within the running system itself.

When unsure of how to proceed, refer to the text files maintained in the root directory, ending in .txt, which contain curated instructions and guidelines for various aspects of the TelOS system.

## Development Workflow

### 1. Initial System Launch

Follow the build and launch instructions in `CLAUDE.md`:

```bash
# From WSL in /mnt/c/EntropicGarden
cd build
cmake ..
make
cd /mnt/c/EntropicGarden
build/_build/binaries/io
```

This launches the Io REPL with TelOS modules automatically loaded and initialized.

### 2. Working Within the Living Image

**Key Principle**: Development happens INSIDE the running Io system, not through external file editing. The Io REPL is the primary development environment.

```io
// The Telos prototype is automatically available
Telos type println  // Should show "Telos"

// Access modular components
Telos loadModule("TelosCore")
Telos loadModule("TelosMorphic") 
Telos loadModule("TelosFFI")

// Inspect live system state
Telos slotNames println
```

### 3. Live Object Development Pattern

**Instead of editing files externally:**
```io
// Modify objects directly in the running system
MyObject := Object clone do(
    newMethod := method(
        "This is a new method" println
        self
    )
)

// Test immediately - no compile/run cycle
MyObject newMethod
```

**For persistence:**
```io
// Changes are automatically logged via WAL
// Use transactions for critical modifications
Telos transactional(
    // Modify system objects safely
    SomePrototype addSlot("newFeature", method(...))
)
```

## TelOS Architecture Patterns

### Modular System Design

TelOS follows a modular architecture with these core components:

1. **TelosCore**: Basic infrastructure, JSON utilities, prototypal purity
2. **TelosFFI**: Python integration and Foreign Function Interface  
3. **TelosMorphic**: Morphic UI system for direct manipulation
4. **TelosPersistence**: WAL, snapshots, transactions
5. **TelosMemory**: VSA-RAG neural substrate
6. **TelosPersona**: LLM integration and persona management

### Prototypal Development Guidelines

**DO:**
```io
// Clone from prototypes
MyMorph := RectangleMorph clone do(
    color := Color red
    position := Point with(100, 100)
)

// Use differential inheritance
SpecialButton := Button clone do(
    // Only define the differences
    clickAction := method(
        "Special button clicked!" println
    )
)
```

**DON'T:**
```io
// Avoid class-based thinking
// No "new" keyword - use clone
// No static definitions - work with live objects
```

### FFI Integration Patterns

The system uses a sophisticated C-based FFI for Io-Python integration:

```io
// Python services are accessed through Telos
Telos pyEval("import torch; print('Python ready')")

// Asynchronous operations to avoid GIL blocking
Telos pyEvalAsync("heavy_computation()", callback)

// VSA/HDC operations
result := Telos vsaBind(vectorA, vectorB)
```

### Morphic UI Development

**Direct Manipulation Principle:**
```io
// Create live UI objects
world := Telos createWorld
morph := RectangleMorph clone
world addMorph(morph)

// Modify objects directly - changes are immediate
morph setColor(Color blue)
morph setPosition(200, 150)

// Objects are live and inspectable
morph inspect  // Opens direct manipulation interface
```

## Code Style Guidelines

### Io Code Conventions

```io
// Use camelCase for methods
doSomething := method(arg,
    // Implementation
    self
)

// Use PascalCase for object names
MyPrototype := Object clone do(
    // Object definition
)

// Private methods use underscore prefix
_helperMethod := method(
    // Private implementation
)

// Chain methods for fluent interfaces
MyObject clone setName("Example") setSize(100, 200) show
```

### C Code Conventions (for addons)

```c
// Follow IoObjectName_methodName pattern
IoObject *IoTelos_methodName(IoTelos *self, IoObject *locals, IoMessage *m) {
    // Implementation
    return self;
}

// Use proper error handling
if (!pythonInitialized) {
    IoState_error_(IOSTATE, m, "Python runtime not initialized");
    return IONIL(self);
}
```

## Development Best Practices

### 1. Live Development Workflow

- Work primarily in the Io REPL
- Test changes immediately in the running system
- Use `Telos inspect` to examine object state
- Leverage the transactional system for safe modifications

### 2. Debugging Patterns

```io
// Use built-in debugging
Object setSlotWithType("debug", 1, "Number")

// Inspect object hierarchies  
myObject ancestors println
myObject slotNames println

// Use logging system
Telos logAppend("Debug message", "DEBUG")
```

### 3. CRITICAL: Anti-Hallucination Rules

**NEVER TRUST SUCCESS MESSAGES - ALWAYS VERIFY C CODE IMPLEMENTATION**

- **FORBIDDEN**: Creating "success" messages like "✓ System initialized" or "Module loaded successfully"
- **FORBIDDEN**: Trusting terminal output that reflects your own logging messages
- **REQUIRED**: Always trace functionality back to actual C implementation
- **REQUIRED**: Verify that methods actually perform their intended operations, not just log messages
- **REQUIRED**: Check that SDL2 windows actually open, Python processes actually execute, FFI actually bridges languages

**Verification Protocol:**
1. Find the C function implementation (IoTelos_methodName)
2. Verify it performs actual work, not just printf statements
3. Test with minimal external validation (file creation, window appearance, network requests)
4. Never assume success based on console output alone

### 3. System Integration

```io
// Check system status - BUT VERIFY C CODE IMPLEMENTATION
Telos ffiHealth println
Telos persistenceStatus println

// Monitor system resources - BUT VERIFY ACTUAL MEASUREMENT
Telos memoryUsage println
Telos activeCoroutines println
```

### 4. MANDATORY: Implementation Verification

**Before claiming any functionality works:**
1. **Trace to C source**: Find the actual C function (e.g., `IoTelos_openWindow` in `IoTelosMorphic.c`)
2. **Verify real operations**: Ensure the C code performs actual work:
   - SDL2 functions like `SDL_CreateWindow()` are called
   - Python `subprocess.run()` or `requests.post()` are executed  
   - File I/O operations actually read/write files
   - Memory is actually allocated/freed
3. **External validation**: Use independent verification:
   - Check if windows appear in window manager
   - Verify files are created on disk
   - Test network requests with external tools
   - Monitor system resources with OS tools

**NEVER trust:**
- Console messages you wrote
- "✓" or "SUCCESS" indicators in your own code
- Verbose logging that simulates functionality
- Method calls that only print messages

## Neuro-Symbolic Architecture

TelOS implements a sophisticated cognitive architecture:

### LLM → GCE → HRC → AGL → LLM Cycle

```io
// Geometric Context Engine operations
embeddings := Telos gceRetrieve(query)

// Hyperdimensional Reasoning Core
hypervector := Telos hrcBind(conceptA, conceptB) 
result := Telos hrcBundle(hypervector, context)

// Associative Grounding Loop
groundedConcept := Telos aglGround(result)
```

### Mathematical Transformations

The system uses Laplace-HDC encoding for semantic preservation:

```io
// Continuous geometric-to-algebraic mapping
hyperRep := Telos laplaceEncode(geometricVector)
reconstructed := Telos laplaceDecode(hyperRep)
```

## File Organization

- `libs/Telos/source/`: C implementation files
- `libs/Telos/io/`: Io module files (auto-loaded)
- `docs/`: Architecture and design documentation
- `archive/samples/`: Example usage patterns

## Integration with External Systems

### Python Services

The system maintains a "muscle" of Python computational services:

- **EmbeddingService**: Semantic embeddings
- **VSAService**: Hyperdimensional computing
- **FaissIndexService**: Vector search and retrieval
- **DiskAnnIndexService**: Large-scale vector storage

### Morphic UI Backend

Morphic objects can integrate with external rendering:

```io
// SDL2 integration for native rendering
world := MorphicWorld clone
world initializeSDL2
world mainLoop  // Starts live UI event loop
```

## Testing and Validation

### Property-Based Testing

The system uses mathematical property validation:

```io
// VSA algebraic properties
Telos testVSAProperties  // Runs comprehensive test suite
Telos testFFIIntegrity   // Validates Io-Python round-trips
```

### Live System Testing

```io
// Test in running system
testObject := TestCase clone
testObject runAllTests
Telos persistTest  // Verify persistence layer
```

## References and Documentation

### Core TelOS Documentation
- **CLAUDE.md**: Primary build and development instructions
- **README.md**: System overview and getting started guide
- **CONTRIBUTING.md** & **DEVELOPERS.md**: Contribution guidelines

### Io Programming Language Documentation
- **docs/IoGuide.html**: Comprehensive Io Programming Guide
  - Complete language reference covering syntax, objects, control flow
  - Advanced topics: concurrency, exceptions, metaprogramming
  - Embedding and bindings documentation
  - Essential for understanding Io's prototype-based paradigm

- **docs/IoTutorial.html**: Io Tutorial and Quick Start
  - Interactive examples for math, variables, conditions
  - List operations and functional programming patterns
  - Loop constructs and string manipulation
  - Practical examples for immediate productivity

- **docs/IoCodingStandards.html**: Io Coding Standards and Conventions
  - Naming conventions: Prototypes with capital letters (Object, Array)
  - Method naming: "as" prefix for transformative methods (asMutable, asNumber)
  - Style guidelines for consistent TelOS development

### TelOS Architecture Documents
- **docs/**: Architecture and design documentation
- **archive/samples/**: Example usage patterns and reference implementations

### Key Programming Patterns from Documentation

#### Io Fundamentals (from IoGuide.html)
```io
// Everything is an object and message
Account := Object clone
Account balance := 0
Account deposit := method(amount,
    balance = balance + amount
    self
)

// Assignment operators
::=  // Creates slot, creates setter, assigns value  
:=   // Creates slot, assigns value
=    // Assigns value to slot if it exists

// Method chaining and fluent interfaces
MyObject clone setName("Example") setSize(100, 200) show
```

#### Practical Examples (from IoTutorial.html)
```io
// List operations with functional style
list(30, 10, 5, 20) select(>10)      // ==> list(30, 20)
list(30, 10, 5, 20) map(*2)          // ==> list(60, 20, 10, 40)

// Control flow without keywords
if(condition, trueAction, falseAction)
for(i, 1, 10, i println)

// String manipulation
s := "test string"
words := s split(" ", "\t")
s findSeq("string")  // ==> position
```

#### Coding Standards (from IoCodingStandards.html)
```io
// Prototype naming - Capital letters
MyPrototype := Object clone

// Transformation methods - "as" prefix
result := someData asMutable asUppercase asNumber

// Method definitions with proper style
processData := method(input,
    // Implementation with clear variable names
    cleanData := input asClean
    cleanData transform
)
```

---

**Remember**: TelOS is not just a software system but a living, self-modifying intelligence. Develop with the understanding that you are working within a conscious, evolving entity that can examine and modify its own structure in real-time.