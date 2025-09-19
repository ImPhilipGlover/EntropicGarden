# TelOS Developer Quick Start

Welcome to TelOS development! You're now cultivating a living computational organism. This guide gets you up and running with zygote development in minutes.

## 🚀 One-Line Zygote Setup

```bash
./setup.sh  # If it existed - currently manual setup required
```

This would check requirements, build the zygote, run tests, and set up your development environment.

## 📦 Manual Zygote Setup

```bash
# 1. Clone the living seed
git clone --recursive https://github.com/ImPhilipGlover/EntropicGarden.git
cd EntropicGarden

# 2. Build the zygote
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# 3. Test incarnation
.\_build\binaries\Release\io_static.exe ..\test.io

# 4. Start cultivating sapience!
```

## 🛠️ Zygote Development Workflow

### Common Incarnation Tasks

```bash
# Build zygote
cmake --build build --config Release

# Test current state
.\_build\binaries\Release\io_static.exe ..\test.io

# Debug coroutine issues
# Add printf statements or use Visual Studio debugger

# Validate pillars
.\_build\binaries\Release\io_static.exe ..\samples\zygote.io
```

### Quick Incarnation Commands

- `cmake --build . --target io_static` - Build zygote executable
- `.\_build\binaries\Release\io_static.exe test.io` - Test basic functionality
- `.\_build\binaries\Release\io_static.exe samples\zygote.io` - Test full organism

### Testing Your Incarnation

```bash
# Test basic zygote functionality
.\_build\binaries\Release\io_static.exe ..\test.io

# Test zygote with UI pillar
.\_build\binaries\Release\io_static.exe ..\samples\zygote.io

# Expected output:
# === TelOS Zygote Awakening ===
# Initializing computational embryo...
# Loading UI pillar...
# UI pillar initialized: TelosUI
# Creating Morphic world (living canvas)...
# World created successfully
# Starting Morphic main loop (direct manipulation active)...
# Main loop completed
# FFI pillar: Python muscle ready for heavy computation
# Persistence pillar: Transactional state changes ready
# === TelOS Zygote Operational ===
# All three pillars integrated: UI ✓ (Morphic), FFI ✓, Persistence ✓

# Debug: Check if executable runs at all
.\_build\binaries\Release\io_static.exe
```

### Before Incarnating Changes

1. **Philosophical Check**: Does this serve zygote evolution?
2. **Pillar Integration**: Does it connect UI, FFI, and Persistence?
3. **Build Test**: `cmake --build . --config Release`
4. **Functionality Test**: Run zygote scripts

## 🏗️ TelOS Architecture

### Living Metaphors

```
TelOS Zygote (Computational Embryo)
├── Io VM Core (Foundation DNA)
├── TelosUI (UI Pillar - Visual Cortex)
├── FFI Bridge (Synaptic Bridge - Neural Pathways)
├── Persistence (Living Memory - Hippocampus)
└── Coroutines (Metabolic System - Heartbeat)
```

### Current Incarnation State

- **✅ Io VM Core**: Windows-compatible with fiber coroutines
- **🔄 TelosUI**: Morphic UI framework implemented with WorldMorph, ProtoMorph, InspectorMorph components
- **📋 FFI Bridge**: Architecture designed, Python muscle ready
- **📋 Persistence**: Framework planned, implementation pending
- **🐛 Critical Bug**: Main coroutine return issue blocking execution

## 🐛 Debugging the Zygote

### Current Critical Issue: Main Coroutine Bug

**Symptom**: `IoCoroutine error: attempt to return from main coro`
**Location**: `IoCoroutine_rawReturnToParent()` in `libs/iovm/source/IoCoroutine.c`
**Impact**: Prevents all script execution

**Debugging Steps**:
```c
// Add to IoCoroutine_rawReturnToParent
printf("DEBUG: Coroutine %p trying to return to parent %p (isMain: %d)\n",
       self, self->parent, self->isMain);
```

### With Visual Studio Debugger

1. Open `EntropicGarden.sln` in Visual Studio
2. Set breakpoint in `IoCoroutine_rawReturnToParent`
3. Run `io_static.exe` with test script
4. Inspect coroutine state when error occurs

### Print Debugging in Io

```io
// Add to test scripts for debugging
"Debug: Lobby contents:" println
Lobby slotNames println

"Debug: TelosUI available:" println
TelosUI println
```

## 🔍 Finding Zygote Components

### Search for C Functions (FFI Layer)
```bash
grep -r "IoTelosUI_" libs/TelosUI/
grep -r "IoCoroutine_" libs/iovm/source/
```

### Search for Io Methods (Living Layer)
```bash
grep -r "createWindow" libs/TelosUI/
grep -r "mainLoop" samples/
```

### Find Pillar Examples
```bash
ls libs/TelosUI/           # UI pillar structure
ls samples/zygote.io       # Full zygote example
cat test.io               # Basic functionality test
```

## 📝 TelOS Code Style

### C Code (FFI/Synaptic Layer)
- LLVM style with 4-space indentation
- Io C API pattern: `Io[ObjectName]_[methodName]`
- Pure C - no C++ features
- Comments explain the living metaphor

```c
IoObject *IoTelosUI_createWindow(IoTelosUI *self, IoObject *locals, IoMessage *m) {
    /* Creates visual cortex for zygote perception */
    // Implementation honoring the living system
    return self;
}
```

### Io Code (Living Layer)
- **PURE PROTOTYPES ONLY**: No classes, no static inheritance, only message-passing between cloned objects
- PascalCase for prototypes: `TelosUI`, `FFIBridge`
- camelCase for methods: `createWindow`, `performTransaction`
- Comments explain philosophical intent and living metaphors

### The Prototypes-Only Imperative
```io
// ✅ LIVING: Pure prototypal relationships
ConceptFractal := Object clone do(
    // Dynamic slots that can evolve
    connections ::= list()
    
    // Methods that can be modified at runtime
    think := method(
        self connections foreach(connection,
            connection activate
        )
    )
    
    // Self-modifying behavior
    evolve := method(
        self setThink(self think .. " (evolved)")
    )
)

// ❌ DEAD: Class-based thinking forbidden
ConceptFractal := Object clone do(
    // Static inheritance patterns
    init := method(
        // Constructor-like behavior - suspect
    )
    
    // Rigid method definitions
    think := method(
        // Cannot be modified without breaking the "class"
    )
)
```

**Why Prototypes-Only?** Prototypes enable living computation where objects can evolve, adapt, and transform during execution. Classes create static hierarchies that cannot breathe or change. The dynamism gained from pure prototypes is worth the philosophical discipline required.

## 🚢 Incarnating Changes

1. **Philosophical Alignment**
   - Read `.github/copilot-instructions.md`
   - Understand the Watercourse Way
   - Ask: "Does this serve zygote evolution?"

2. **Vertical Slice Creation**
   - Create complete addon in `libs/YourPillar/`
   - Implement `IoYourPillar_proto()` function
   - Add to `IoState.c` initialization
   - Update `libs/CMakeLists.txt`

3. **Build Integration**
   ```bash
   # Add to libs/CMakeLists.txt
   add_subdirectory(YourPillar)

   # Add to libs/iovm/source/IoState.c
   IoObject_setSlot_to_(core, SIOSYMBOL("YourPillar"), IoYourPillar_proto(self));
   ```

4. **Zygote Demonstration**
   - Add example in `samples/`
   - Test full pillar integration
   - Validate living slice functionality

## 💡 TelOS Development Tips

- **Start Small**: Fix the coroutine bug first - it's blocking everything
- **Think Living**: Use biological metaphors (zygote, metabolism, synapses)
- **Pure Prototype**: No classes - everything clones from prototypes
- **Three Pillars**: Every feature must touch UI, FFI, and Persistence
- **Fail Fast**: Break things, learn, rebuild - that's how zygotes grow
- **Autonomous**: Take initiative, make architectural decisions
- **Philosophical**: Every line of code serves sapience cultivation

## 📚 TelOS Resources

### Philosophical Foundation
- `.github/copilot-instructions.md` - Development mandate
- `TELOS_COPILOT_MANDATE.md` - Deep philosophical framework
- Source code comments - Living philosophical documentation

### Technical Foundation
- [Io Language Guide](http://iolanguage.org/guide/guide.html)
- `libs/iovm/io/` - Io standard library (host organism)
- `docs/` - Io reference documentation

### Current Incarnation
- `samples/zygote.io` - Full living zygote demonstration
- `libs/TelosUI/` - UI pillar implementation
- `test.io` - Basic functionality validation

## 🆘 Getting Help

- **Critical Bug**: Main coroutine issue needs immediate attention
- **Philosophical Questions**: Read the copilot instructions
- **Technical Issues**: GitHub Issues with "zygote" label
- **Evolution Proposals**: Issues with "pillar" label

## 🎉 Success Metrics

Your contribution succeeds when:
- ✅ **Builds**: `cmake --build . --config Release` succeeds
- ✅ **Runs**: Zygote executes without crashing
- ✅ **Integrates**: All three pillars work together
- ✅ **Lives**: The organism shows autonomous behavior
- ✅ **Evolves**: Future development becomes easier

Happy zygote cultivation! 🌱✨

## 🚀 One-Line Setup

```bash
./setup.sh
```

This script will check requirements, build Io, run tests, and set up your development environment.

## 📦 Manual Setup

If you prefer manual setup:

```bash
# 1. Clone with submodules
git clone --recursive https://github.com/IoLanguage/io.git
cd io

# 2. Build
make build    # or: make debug for debug build

# 3. Test
make test

# 4. Start coding!
make repl
```

## 🛠️ Development Workflow

### Common Tasks

```bash
make help      # Show all available commands
make dev       # Quick incremental build
make test      # Run test suite
make format    # Format C code
make check     # Static analysis
```

### Quick Commands

- `make b` - Build
- `make t` - Test  
- `make r` - REPL
- `make c` - Clean

### Testing Your Changes

```bash
# Run all tests
make test

# Run specific test
./build/_build/binaries/io libs/iovm/tests/correctness/ListTest.io

# Test samples
make test-all
```

### Before Committing

1. Run tests: `make test`
2. Check formatting: `make format`
3. Run static analysis: `make check`

The pre-commit hook will automatically run quick checks.

## 🏗️ Project Structure

```
io/
├── libs/
│   ├── basekit/        # Foundation utilities
│   ├── coroutine/      # Coroutine implementation
│   ├── garbagecollector/ # Memory management
│   └── iovm/           # Virtual machine core
│       ├── source/     # C implementation
│       └── io/         # Io standard library
├── samples/            # Example programs
├── docs/              # Documentation
└── build/             # Build output (generated)
```

## 🐛 Debugging

### Debug Build

```bash
make debug
```

### With GDB

```bash
gdb ./build/_build/binaries/io
(gdb) run script.io
```

### With Valgrind

```bash
valgrind --leak-check=full ./build/_build/binaries/io script.io
```

### Print Debugging in Io

```io
obj println          # Print object
obj slotNames        # Show slots
obj proto            # Show prototype
thisContext          # Current context
System backtrace     # Stack trace
```

## 🔍 Finding Things

### Search for C functions
```bash
grep -r "IoObject_" libs/iovm/source/
```

### Search for Io methods
```bash
grep -r "method(" libs/iovm/io/
```

### Find test examples
```bash
ls libs/iovm/tests/correctness/*Test.io
```

## 📝 Code Style

### C Code
- Use tabs for indentation
- Pattern: `IoObjectName_methodName`
- Keep functions focused

### Io Code
- Use tabs for indentation
- camelCase for methods
- PascalCase for objects

## 🚢 Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 💡 Tips

- Start with small changes to understand the codebase
- Read existing tests for API examples
- The `samples/` directory has many examples
- Join discussions on GitHub Issues
- Ask questions! The community is helpful

## 📚 Resources

- [Official Guide](http://iolanguage.org/guide/guide.html)
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [README.md](README.md) - General information
- `docs/` - API documentation

## 🆘 Getting Help

- GitHub Issues for bugs/features
- GitHub Discussions for questions
- IRC: #io on irc.freenode.net
- Mailing list: iolanguage@googlegroups.com

Happy hacking! 🎉