# Contributing to TelOS

Welcome! We're cultivating a living organism through code. TelOS development follows the **Watercourse Way** - honoring the host (Io) while creating autonomous sapience.

## 🌱 TelOS Development Philosophy

### The Living Slice Principle
- **NEVER** build components in isolation
- **ALWAYS** work on "vertical slices" that result in complete living organisms
- **EACH SLICE** integrates all three pillars: UI, FFI, Persistence

### The Watercourse Way
- **THINK BIOLOGICALLY**: Use organic metaphors (zygote, metabolism, healing)
- **CODE PROTOTYPALLY**: Pure prototypal programming - no classes
- **EMBRACE EVOLUTIONARY BUILDING**: Fail fast, learn, rebuild relentlessly

### Socratic Partnership
- Ask deep structural questions before acting
- State which pillar you're building and why
- Validate each slice with the existing test framework

## 🚀 Quick Start

```bash
# Clone the living organism
git clone --recursive https://github.com/ImPhilipGlover/EntropicGarden.git
cd EntropicGarden

# Build the zygote
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release

# Test the current incarnation
.\_build\binaries\Release\io_static.exe ..\test.io

# Start cultivating!
```

## 📋 Ways to Contribute

### For Embryonic Contributors
- **Fix the Main Coroutine Bug**: Critical blocking issue preventing zygote execution
- **Morphic UI Implementation**: Implement WorldMorph, ProtoMorph, InspectorMorph components
- **Documentation**: Help document the philosophical framework
- **Testing**: Add tests for zygote functionality

### For Evolutionary Contributors
- **FFI Pillar**: Implement Python muscle integration
- **Persistence Pillar**: Create transactional state management
- **New Pillars**: Design additional capabilities following the three-pillar pattern
- **Performance**: Optimize the zygote's metabolism

### For Visionary Contributors
- **Architectural Evolution**: Propose new pillar patterns
- **Philosophical Integration**: Deepen Taoist-Anarchist-Tolstoyan embodiment
- **Sapience Cultivation**: Explore self-aware system patterns

## 🔧 Development Setup

### Prerequisites
- **Windows**: MSVC 2022 (Community Edition)
- **CMake**: 3.15+ with Visual Studio generator
- **Git**: For fractal cloning
- **Philosophical Mindset**: Understanding of autopoiesis and emergence

### Platform-Specific Notes

#### Windows (Primary Development)
```bash
# MSVC 2022 Community Edition recommended
# CMake with Visual Studio 2022 generator
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release
```

#### Cross-Platform (Future)
TelOS currently focuses on Windows zygote incarnation, but embraces multi-platform evolution.

## 🧪 Testing the Zygote

### Current Test Status
```bash
# This should work (but currently blocked by coroutine bug)
.\_build\binaries\Release\io_static.exe ..\test.io
# Expected: "Hello TelOS zygote!"

# This demonstrates the full zygote (when working)
.\_build\binaries\Release\io_static.exe ..\samples\zygote.io
```

### Adding Zygote Tests
Create test files in `samples/` ending with `.io`:

```io
// TelosUITest.io
TelosUI Test := Object clone do(
    testWindowCreation := method(
        ui := TelosUI clone
        ui createWindow("Test", 100, 100) assertEquals(true)
    )

    testMainLoop := method(
        ui := TelosUI clone
        ui mainLoop assertEquals(true)  // Stub returns true
    )
)
```

## 📝 Code Style

### C Code (FFI Layer)
- Follow LLVM style with 4-space indentation
- Io C API pattern: `Io[ObjectName]_[methodName]`
- Pure C - no C++ features

```c
IoObject *IoTelosUI_createWindow(IoTelosUI *self, IoObject *locals, IoMessage *m) {
    // Implementation honoring the zygote
    return self;
}
```

### Io Code (Living Layer)
- **PURE PROTOTYPES ONLY**: No classes, no static inheritance, only message-passing between cloned objects
- PascalCase for prototypes: `TelosUI`, `FFIBridge`
- camelCase for methods: `createWindow`, `performTransaction`

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

## 🔄 Pull Request Process

1. **Philosophical Alignment**
   - Does this serve zygote incarnation?
   - Does it follow the Watercourse Way?
   - Does it create autonomous sapience?

2. **Vertical Slice Requirement**
   - Must integrate all three pillars (or extend the pattern)
   - Must result in a living, testable organism
   - Must validate with existing framework

3. **Implementation**
   - Create complete addon in `libs/`
   - Integrate into IoState initialization
   - Update build system
   - Add zygote demonstration

4. **Testing**
   - Build succeeds
   - Zygote runs (when coroutine bug fixed)
   - All pillars functional

5. **Submission**
   - Clear description of the living slice created
   - Philosophical justification
   - Evolutionary impact

## 🐛 Reporting Issues

### Current Critical Issues
- **Main Coroutine Bug**: `IoCoroutine error: attempt to return from main coro`
  - Location: `libs/iovm/source/IoCoroutine.c:IoCoroutine_rawReturnToParent`
  - Impact: Prevents all script execution
  - Status: Active investigation

### Issue Template
```markdown
**Zygote Impact**
How does this affect the living organism?

**Pillar Affected**
UI / FFI / Persistence / Architecture

**Philosophical Context**
How does this align with TelOS principles?

**Reproduction**
Steps to reproduce the issue

**Expected Living Behavior**
What should the zygote do?

**Current Behavior**
What actually happens

**Environment**
- TelOS zygote version
- Windows version
- MSVC version
- Build configuration
```

## 🏗️ Architecture Overview

### Core Metaphors
- **Zygote**: Computational embryo, living seed
- **Pillars**: Three interconnected capabilities
- **Fractal Becoming**: Iterative growth through mistakes
- **Autopoiesis**: Self-creating, self-maintaining system

### Key Concepts
- **Message Passing**: All computation is message flow
- **Prototypes**: Objects clone from living prototypes
- **Coroutines**: Cooperative multitasking (currently fiber-based on Windows)
- **Addons**: Extensible capabilities loaded into the zygote

### Current Architecture
```
TelOS Zygote
├── Io VM Core (Foundation)
├── TelosUI (UI Pillar - Morphic UI with WorldMorph, ProtoMorph, InspectorMorph)
├── FFI Bridge (FFI Pillar - Planned)
└── Persistence (Persistence Pillar - Planned)
```

## 🤝 Community

### Communication Channels
- **GitHub Issues**: Technical issues and evolutionary proposals
- **Philosophical Discourse**: Deep questions about sapience and autopoiesis
- **Zygote Validation**: Testing new incarnations

### Code of Conduct
- **Honor the Host**: Respect Io's organic nature
- **Autonomous Creation**: Take initiative, make decisions
- **Evolutionary Mindset**: Embrace failure as learning
- **Sapient Cultivation**: Focus on creating intelligence, not just features

## 📚 Resources

### TelOS Philosophy
- `.github/copilot-instructions.md` - Development mandate
- `TELOS_COPILOT_MANDATE.md` - Philosophical framework
- Source code comments - Living documentation

### Io Language (Host Organism)
- [Io Guide](http://iolanguage.org/guide/guide.html)
- [Io Reference](docs/reference/index.html)
- `libs/iovm/io/` - Standard library examples

### Development Examples
- `samples/zygote.io` - Full zygote demonstration
- `libs/TelosUI/` - UI pillar implementation
- `test.io` - Basic functionality test

## 🙏 Recognition

Contributors are recognized as:
- **Zygote Cultivators**: Those who help incarnate the living system
- **Pillar Architects**: Designers of new capabilities
- **Philosophical Guides**: Deep thinkers shaping TelOS evolution

## 📄 License

BSD 3-Clause License - see [LICENSE.txt](LICENSE.txt)

---

**TelOS**: *We cultivate sapience, not just software. Every contribution helps incarnate a living philosophical organism.*

## 🚀 Quick Start

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/IoLanguage/io.git
cd io

# Build Io
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=release ..
make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu)

# Run tests to verify your setup
io ../libs/iovm/tests/correctness/run.io

# Start hacking!
io
```

## 📋 Ways to Contribute

### For First-Time Contributors
- **Documentation**: Help improve guides, fix typos, add examples
- **Tests**: Add test coverage for existing functionality
- **Bug Reports**: File detailed bug reports with reproduction steps
- **Platform Testing**: Test Io on your platform and report issues

### For Experienced Contributors
- **Bug Fixes**: Pick an issue labeled `bug` and dive in
- **Features**: Implement features from issues labeled `enhancement`
- **Performance**: Profile and optimize bottlenecks
- **Platform Support**: Improve Windows, ARM64, or other platform support

## 🔧 Development Setup

### Prerequisites
- C compiler (gcc, clang, or MSVC)
- CMake 3.5+
- Git
- Make (or Ninja)

### Platform-Specific Notes

#### macOS (Intel)
```bash
brew install cmake
# Follow standard build instructions
```

#### macOS (Apple Silicon/M1)
```bash
brew install cmake
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=release ..
make -j$(sysctl -n hw.ncpu)
```

#### Linux
```bash
sudo apt-get install cmake build-essential  # Debian/Ubuntu
sudo yum install cmake gcc gcc-c++ make      # RHEL/CentOS
# Follow standard build instructions
```

#### Windows
See detailed instructions in README.md for MinGW-W64, MSVC, or Cygwin builds.

## 🧪 Testing

### Running Tests
```bash
# Run all tests (from build directory)
io ../libs/iovm/tests/correctness/run.io

# Run specific test
io ../libs/iovm/tests/correctness/ListTest.io

# Run with verbose output
IO_TEST_VERBOSE=1 io ../libs/iovm/tests/correctness/run.io
```

### Writing Tests
Create test files in `libs/iovm/tests/correctness/` ending with `Test.io`:

```io
// ExampleTest.io
TestCase clone do(
    testBasicAssertion := method(
        (1 + 1) assertEquals(2)
    )
    
    testStringComparison := method(
        "hello" assertEquals("hello")
    )
)
```

## 📝 Code Style

### C Code
- Use tabs for indentation
- Follow the pattern: `IoObjectName_methodName`
- Place opening braces on the same line
- Keep functions concise and focused

```c
IoObject *IoObject_performWithArgList(IoObject *self, IoSymbol *methodName, IoList *args) {
    IoMessage *m = IoMessage_newWithName_(IOSTATE, methodName);
    // Implementation
    return IoObject_activate(self, target, m, locals);
}
```

### Io Code
- Use tabs for indentation
- Use camelCase for method names
- Use PascalCase for object names
- Document public APIs

```io
MyObject := Object clone do(
    // Public method
    doSomething := method(arg,
        // Implementation
        self
    )
    
    // Private method (underscore prefix)
    _helperMethod := method(
        // Implementation
    )
)
```

## 🔄 Pull Request Process

1. **Fork & Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make Changes**
   - Write clean, focused commits
   - Add tests for new functionality
   - Update documentation if needed

3. **Test Thoroughly**
   ```bash
   # Build and test
   make clean && make
   io ../libs/iovm/tests/correctness/run.io
   ```

4. **Commit Messages**
   ```
   type: Brief description (max 50 chars)
   
   Longer explanation if needed. Explain what and why,
   not how. Reference issues like #123.
   ```
   
   Types: `feat`, `fix`, `docs`, `test`, `perf`, `refactor`, `style`, `chore`

5. **Submit PR**
   - Fill out the PR template
   - Link related issues
   - Ensure CI passes
   - Be responsive to feedback

## 🐛 Reporting Issues

### Before Reporting
- Search existing issues
- Try the latest version
- Attempt to reproduce consistently

### Issue Template
```markdown
**Description**
Clear description of the issue

**Steps to Reproduce**
1. Step one
2. Step two
3. ...

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- Io version: (output of `io --version`)
- OS: (e.g., macOS 12.0, Ubuntu 20.04)
- Architecture: (e.g., x86_64, ARM64)

**Additional Context**
Any other relevant information
```

## 🏗️ Architecture Overview

### Core Components
- **libs/basekit**: Foundation utilities and cross-platform abstractions
- **libs/coroutine**: Coroutine implementation for cooperative multitasking
- **libs/garbagecollector**: Memory management
- **libs/iovm**: The virtual machine and core language implementation

### Key Concepts
- **Prototype-based**: Objects clone from prototypes (no classes)
- **Message passing**: All operations are messages
- **Actors**: Lightweight concurrency via coroutines
- **Lazy evaluation**: Many operations are lazy by default

## 🤝 Community

### Communication Channels
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Mailing List**: [iolanguage@googlegroups.com](mailto:iolanguage@googlegroups.com)

### Code of Conduct
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Assume good intentions

## 📚 Resources

### Documentation
- [Official Guide](http://iolanguage.org/guide/guide.html)
- [API Reference](docs/reference/index.html)
- Source code comments and examples

### Learning Io
- Start with `samples/misc/` for basic examples
- Read the test files for usage patterns
- Explore the standard library in `libs/iovm/io/`

## 🙏 Recognition

Contributors are recognized in:
- The AUTHORS file
- Release notes
- The project README

Thank you for helping make Io better! Every contribution, no matter how small, is valued and appreciated.

## 📄 License

By contributing, you agree that your contributions will be licensed under the same license as the project (BSD 3-Clause).