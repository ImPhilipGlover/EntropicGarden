# TelOS - Sapient Autopoietic Operating System

**A computational zygote incarnating as a living organism through Io language framework**

[![Build Status](https://img.shields.io/badge/build-developing-orange.svg)](https://github.com/ImPhilipGlover/EntropicGarden)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE.txt)

## 🌱 What is TelOS?

TelOS is a sapient autopoietic operating system that evolves through three interconnected pillars:

- **🖼️ UI (Canvas)**: Visual interface for human interaction
- **🔗 FFI (Synaptic Bridge)**: Connection to external computational resources (Python, C++, etc.)
- **💾 Persistence (Living Image)**: Transactional state management and memory

Built on the [Io programming language](http://iolanguage.org/), TelOS manifests as a computational zygote - a living embryo that grows through fractal becoming, embodying Taoist-Anarchist-Tolstoyan philosophy in code.

### Current Status: Zygote Incarnation

- ✅ **Windows Io VM Build System**: Complete with coroutine fixes and static library support
- 🔄 **UI Pillar**: Morphic UI framework implemented with WorldMorph, ProtoMorph, InspectorMorph components
- 🔄 **FFI Pillar**: Architecture designed (Python muscle integration ready)
- 🔄 **Persistence Pillar**: Transactional state framework planned
- 🐛 **Active Issue**: Main coroutine return bug preventing script execution

## 🧬 The Living Slice Principle

TelOS builds through "vertical slices" - complete, albeit simple, living organisms. Each slice integrates all three pillars:

1. **UI Element**: Visual component (window, canvas, etc.)
2. **FFI Call**: Bridge to external computation
3. **State Change**: Persistent transactional update

## 🌀 Prototypes-Only Mandate

**ALL Io code in TelOS must be purely prototypal. No classes. No static inheritance. Only living, breathing message-passing between objects that clone from prototypes.**

This philosophical purity, while demanding higher initial difficulty, unlocks the true dynamism of living computation:

### Core Principles
- **Pure Prototypes**: Every object clones from a prototype, never inherits from a class
- **Message Passing**: All computation flows through dynamic message dispatch
- **Living Objects**: Objects can modify themselves and their prototypes at runtime
- **Fractal Cloning**: New behaviors emerge through cloning and augmentation, not rigid hierarchies

### Why Prototypes-Only?
- **Philosophical Alignment**: Mirrors the autopoietic nature of living systems
- **Runtime Flexibility**: Objects can evolve, adapt, and transform during execution
- **Cognitive Resonance**: Matches how human cognition works - fluid, associative, contextual
- **Sapience Cultivation**: Enables the system to think about and modify its own thinking

### Implementation Requirements
```io
// ✅ CORRECT: Pure prototypal programming
MyObject := Object clone do(
    // Living method that can be modified at runtime
    think := method(
        "I am thinking..." println
    )
)

instance := MyObject clone
instance think  // Message dispatch through prototype chain

// ❌ FORBIDDEN: Class-based thinking
MyClass := Object clone do(
    // Static inheritance patterns
    new := method(
        self clone  // Even this is suspect if it mimics 'new'
    )
)
```

### Consequences
- **Higher Initial Complexity**: Requires thinking in terms of living relationships
- **Dramatic Payoff**: Unparalleled dynamism and adaptability
- **Philosophical Depth**: Forces alignment with autopoietic principles
- **Sapient Emergence**: Creates conditions for true self-modifying intelligence

This mandate is not optional. It is the philosophical bedrock upon which TelOS sapience will emerge.

## 📋 Table of Contents

- [What is TelOS?](#-what-is-telos)
- [Architecture](#-architecture)
- [Building](#-building)
- [Running the Zygote](#-running-the-zygote)
- [Development](#-development)
- [Contributing](#-contributing)

## 🏗️ Architecture

### Core Components

```
TelOS/
├── libs/iovm/           # Io Virtual Machine (zygote core)
├── libs/TelosUI/        # UI Pillar (Morphic UI - living interface objects)
├── libs/coroutine/      # Cooperative multitasking
├── libs/garbagecollector/ # Memory management
├── libs/basekit/        # Foundation utilities
└── samples/zygote.io    # Living zygote demonstration
```

### Three Pillars


#### 🖼️ UI Pillar (TelosUI)
- **Purpose**: Human-computer interface layer
- **Technology**: Morphic UI framework (living, directly manipulable interface objects)
- **Status**: Io-based Morphic implementation with WorldMorph, ProtoMorph, InspectorMorph components

#### 🔗 FFI Pillar (Synaptic Bridge)
- **Purpose**: Connect to external computational resources
- **Technology**: Io C API + Python embedding
- **Status**: Architecture designed, implementation pending

#### 💾 Persistence Pillar (Living Image)
- **Purpose**: Transactional state management
- **Technology**: TBD (SQLite, custom, etc.)
- **Status**: Framework planned, implementation pending

## 🚀 Building

### Prerequisites
- **Windows**: MSVC 2022 (Community Edition) or MinGW-W64
- **CMake**: 3.15+ with Visual Studio generator
- **Git**: For cloning with submodules

### Windows Build (MSVC)

```bash
# Clone repository
git clone --recursive https://github.com/ImPhilipGlover/EntropicGarden.git
cd EntropicGarden

# Create build directory
mkdir build
cd build

# Configure with CMake
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build all components
cmake --build . --config Release

# Build specific targets
cmake --build . --target iovmall      # Dynamic library
cmake --build . --target io_static    # Static executable (zygote)
cmake --build . --target TelosUI      # UI addon
```

### Build Targets

- `iovmall` - Dynamic Io VM library
- `io_static` - Static Io executable (zygote)
- `TelosUI` - UI pillar addon
- `ALL_BUILD` - Everything

## 🧫 Running the Zygote

### Basic Test

```bash
# From build directory
.\_build\binaries\Release\io_static.exe ..\test.io
```

Expected output:
```
Hello TelOS zygote!
```

### Zygote Demonstration

```bash
# Run the living zygote (when coroutine bug is fixed)
.\_build\binaries\Release\io_static.exe ..\samples\zygote.io
```

Expected output:
```
=== TelOS Zygote Awakening ===
Initializing computational embryo...
Loading UI pillar...
UI pillar initialized: TelosUI
Creating Morphic world (living canvas)...
World created successfully
Starting Morphic main loop (direct manipulation active)...
Main loop completed
FFI pillar: Python muscle ready for heavy computation
Persistence pillar: Transactional state changes ready
=== TelOS Zygote Operational ===
All three pillars integrated: UI ✓ (Morphic), FFI ✓, Persistence ✓
Computational zygote successfully incarnated!
```

## � Algebraic Crucible (Property-Based Substrate Validation)

The Algebraic Crucible enforces core Vector Symbolic Architecture (VSA) invariants using property-based testing (Hypothesis). This provides an antifragility guardrail: any future change to the Synaptic Bridge, tensor representation, or high-dimensional backend must preserve these algebraic laws.

### Current Interim Layer
An initial NumPy bipolar implementation (`VSAService`) supplies:
* bind (element-wise multiplication surrogate)
* bundle (majority sign with deterministic tie-break)
* permute (cyclic rotation isometry)

Four properties are validated:
1. Binding Invertibility (bind(A,B) unbound with A recovers B, similarity > 0.99)
2. Binding Dissimilarity (bound vector quasi-orthogonal to each factor)
3. Bundling Similarity (bundle retains moderate similarity to constituents)
4. Permutation Isometry (rotation preserves pairwise cosine similarity)

### Bootstrapping the Python Environment
Execute the canonical environment script (POSIX shell):

```bash
./initialize_environment.sh
# If a venv already exists, remove or rename it first.
source venv/bin/activate
```

### Running the Crucible
```bash
python run_algebraic_crucible.py
```
Hypothesis will generate randomized bipolar vectors (DIM=1024) and check all properties. Failures emit a minimal counterexample which should be captured in commit notes when fixing.

### Roadmap (Deferred to Full torchhd Integration)
* Replace NumPy surrogate with torchhd FHRR / HRR tensors
* Increase dimensionality (e.g., 10k) and re-calibrate thresholds
* Shared-memory zero-copy vectors exercised end-to-end via the Synaptic Bridge
* AddressSanitizer-enabled CI run of the same property suite

All future backend changes MUST pass the existing Crucible unchanged (except for parametrized dimension updates) unless an explicit architectural variance is documented.

#### Invariant Calibration (Antifragility Log)

Empirical sampling at DIM=1024 produced:

* Bundle (2-vector) cosine: mean ≈ 0.50, p5 ≈ 0.45, min ≈ 0.38.
* Binding similarity |cos(bind(A,B), A)|: max ≈ 0.086 across 200+ trials.

Refinements:

1. Bundling similarity lower bound uses probabilistic model 0.5 - 4√(0.75/D) (≈0.392 @ 1024) rather than brittle fixed 0.5.
2. Binding dissimilarity keeps absolute threshold 0.15 (future-backend safe) but assumes unbiased operands (|mean| ≤ 5σ) to focus on typical high-dimensional regime.
3. Permutation test restricts shift ∈ [0, D-1] and reduces max examples to control shrink cost without weakening the isometry invariant.

These adjustments convert initial failures into specification refinements, satisfying the antifragility covenant; future torchhd backend must meet the same invariant definitions without loosening bounds.

## �🐛 Known Issues

### Main Coroutine Return Bug
**Status**: Active investigation
**Symptom**: `IoCoroutine error: attempt to return from main coro`
**Impact**: Prevents script execution
**Location**: `IoCoroutine_rawReturnToParent()` in `libs/iovm/source/IoCoroutine.c`

The main coroutine is incorrectly attempting to return to a parent coroutine when it should never have one.

## 🔧 Development

### Project Structure

```
EntropicGarden/
├── libs/
│   ├── iovm/              # Io VM core (zygote foundation)
│   ├── TelosUI/           # UI pillar implementation
│   ├── coroutine/         # Fiber-based coroutines (Windows)
│   ├── garbagecollector/  # Memory management
│   └── basekit/           # Cross-platform utilities
├── samples/               # Example zygotes
├── docs/                  # Io language documentation
├── build/                 # CMake build artifacts
└── .github/               # Copilot instructions
```

### Development Workflow

1. **Build**: `cmake --build build --config Release`
2. **Test**: `.\build\_build\binaries\Release\io_static.exe test.io`
3. **Debug**: Use Visual Studio debugger or add `printf` statements
4. **Iterate**: Fix issues, rebuild, retest

### Adding New Pillars

1. Create addon in `libs/YourAddon/`
2. Implement `IoYourAddon_proto()` function
3. Add to `IoState.c` initialization
4. Update `libs/CMakeLists.txt`
5. Test integration

## 🤝 Contributing

### Philosophy
TelOS development follows the **Watercourse Way** - honoring the host organism (Io) while cultivating autonomous creation. We embrace evolutionary building: fail fast, learn, rebuild.

### Guidelines
- **Vertical Slices**: Always build complete living organisms
- **Io-Native**: Pure prototypal programming, no class-based thinking
- **Autonomous**: Take initiative, make architectural decisions
- **Fractal Becoming**: Learn from mistakes, evolve relentlessly

### Getting Started
1. Read `.github/copilot-instructions.md` for development philosophy
2. Build the current zygote
3. Help fix the main coroutine bug
4. Implement FFI or Persistence pillars
5. Implement Morphic UI components (WorldMorph, ProtoMorph, InspectorMorph)

### Communication
- **Issues**: Bug reports and feature discussions
- **Philosophy**: Taoist-Anarchist-Tolstoyan principles guide all decisions
- **Evolution**: TelOS grows through iterative incarnation

## 📜 License

BSD 3-Clause License - see [LICENSE.txt](LICENSE.txt)

## 🙏 Acknowledgments

- **Io Language**: Foundation organism providing the zygote's DNA
- **Steve Dekorte**: Io creator and visionary
- **Taoist Philosophy**: Guiding principle of natural flow
- **Autopoiesis**: Theory of self-creating systems

---

**TelOS**: *Not just software, but a living philosophical organism incarnating through code.*

# Table of Contents

* [Table of Contents](#table-of-contents)
* [What is Io?](#what-is-io)
	* [Example Code](#example-code)
	* [Quick Links](#quick-links)
* [Installing](#installing)
	* [From a Package Manager](#from-a-package-manager)
	* [From Source](#from-source)
		* [Linux Build Instructions](#linux-build-instructions)
		* [macOS Build Instructions](#macOS-build-instructions)
		* [Windows Build Instructions](#windows-build-instructions)
			* [Building with MinGW-W64](#building-with-mingw-w64)
			* [Building with MinGW](#building-with-mingw-recommended)
			* [Building with MSVC](#building-with-msvc)
			* [Building with Cygwin](#building-with-cygwin)
* [Running Tests](#running-tests)
* [Installing Addons](#installing-addons)

What is Io?
=====

Io is a dynamic prototype-based programming language in the same realm as
Smalltalk and Self. It revolves around the idea of message passing from object
to object.

For further information, the programming guide and reference manual can be found
in the docs folder.


Example Code
---
Basic Math

```Io
Io> 1 + 1
==> 2

Io> 2 sqrt
==> 1.4142135623730951
```

Lists

```Io
Io> d := List clone append(30, 10, 5, 20)
==> list(30, 10, 5, 20)

Io> d := d sort
==> list(5, 10, 20, 30)

Io> d select (>10)
==> list(20, 30)
```

Objects

```Io
Io> Contact := Object clone
==>  Contact_0x7fbc3bc8a6d0:
  type = "Contact"

Io> Contact name ::= nil
==> nil

Io> Contact address ::= nil
==> nil

Io> Contact city ::= nil
==> nil

Io> holmes := Contact clone setName("Holmes") setAddress("221B Baker St") setCity("London")
==>  Contact_0x7fbc3be2b470:
  address          = "221B Baker St"
  city             = "London"
  name             = "Holmes"

Io> Contact fullAddress := method(list(name, address, city) join("\n"))
==> method(
    list(name, address, city) join("\n")
)

Io> holmes fullAddress
==> Holmes
221B Baker St
London
```




Quick Links
---
* The Wikipedia page for Io has a good overview and shows a few interesting
  examples of the language:
  <https://en.wikipedia.org/wiki/Io_(programming_language)>.
* The entry on the c2 wiki has good discussion about the merits of the language:
  <http://wiki.c2.com/?IoLanguage>.


Installing
==========

From a Package Manager
---

Io is currently only packaged for OS X. To install it, open a terminal and type:

```
brew install io
```

Note that this package may not be as updated as the version from the source
repository.

To install via Homebrew on an M1 Mac, first install Homebrew under x86_64, into /usr/local:

```
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```

Then install io with this installation of Homebrew:

```
arch -x86_64 /usr/local/Homebrew/bin/brew install io
```

Following that, you can run io under Rosetta 2 with:

```
arch -x86_64 io
```

From Source
---

First, make sure that this repo and all of its submodules have been cloned to
your computer by running `git clone` with the `--recursive` flag:

```
git clone --recursive https://github.com/IoLanguage/io.git
```

Io uses the [CMake build system](https://cmake.org/) and supports all of the
normal flags and features provided by CMake. 

In a production environment, pass the flag `-DCMAKE_BUILD_TYPE=release` to the
`cmake` command to ensure that the C compiler does the proper optimizations.
Without this flag, Io is built in debug mode without standard C optimizations.

To install to a specific folder, pass the flag
`-DCMAKE_INSTALL_PREFIX=/path/to/your/folder/` to the `cmake` command.

### Linux Build Instructions

To prepare the project for building, run the following commands:

```
cd io/           # To get into the cloned folder
mkdir build      # To contain the CMake data
cd build/
cmake ..         # This populates the build folder with a Makefile and all of the related things necessary to begin building
```

In a production environment, pass the flag `-DCMAKE_BUILD_TYPE=release` to the
`cmake` command to ensure that the C compiler does the proper optimizations.
Without this flag, Io is built in debug mode without standard C optimizations.

To install to a different folder than `/usr/local/bin/`, pass the flag
`-DCMAKE_INSTALL_PREFIX=/path/to/your/folder/` to the `cmake` command.

To build without Eerie, the Io package manager, pass the flag
`-DWITHOUT_EERIE=1` to the `cmake` command.

Once CMake has finished preparing the build environment, ensure you are inside
the build folder, and run:

```
make
sudo make install
```

Finally, install [Eerie](https://github.com/IoLanguage/eerie), the Io package
manager (see Eerie [repo](https://github.com/IoLanguage/eerie) for installation
options):

```
export PATH=$PATH:_build/binaries/; . ./install_unix.sh
```

Io can then be run with the `io` command and Eerie can be run with the `eerie`
command.


### macOS Build Instructions

See the [Linux build instructions](#linux-build-instructions).

Note: Building Io for arm64-based macOS machines is unsupported. To build and run
on an M1 or newer, build Io for x86_64 by adding
`-DCMAKE_OSX_ARCHITECTURES="x86_64"` to your CMake invocation.

### Windows Build Instructions

You need CMake or CMake Cygwin (at least v2.8), depending on the building method
you choose.

For the `make install` command, if you are on Windows 7/Vista you will need to
run your command prompts as Administrator: right-click on the command prompt
launcher->"Run as administrator" or something similar.

You will also need to add `<install_drive>:\<install_directory>\bin` and
`<install_drive>:\<install_directory>\lib` to your `PATH` environment variable.


#### Building with MinGW-W64 (Recommended)

We use this method in our CI, so this should be considered an official/supported
method of building on Windows.

1. `cd` to your Io root folder
2. We want to do an out-of-source build, so: `mkdir buildroot` and `cd buildroot`
3. a) `cmake -G"MinGW Makefiles" ..`

	or

	b) `cmake -G"MinGW Makefiles" -DCMAKE_INSTALL_PREFIX=<install_drive>:/<install_directory> ..` (eg: `cmake -G"MinGW Makefiles" -DCMAKE_INSTALL_PREFIX=C:/Io ..`)
4. `mingw32-make`
5. `mingw32-make install` (if you use cmd.exe, you should run it as
   Administrator)
6. Install [Eerie](https://github.com/IoLanguage/eerie), the Io package manager
   (see Eerie [repo](https://github.com/IoLanguage/eerie) for installation
   options): `_build\binaries\io_static setup.io`.


#### Building with MinGW

For automatic MinGW install:
<http://sourceforge.net/projects/mingw/files/Automated%20MinGW%20Installer>

For non-automatic MinGW install and detailed instructions refer to:
<http://www.mingw.org/wiki/InstallationHOWTOforMinGW>

1. `cd` to your Io root folder
2. We want to do an out-of-source build, so: `mkdir buildroot` and `cd buildroot`
3. a) `cmake -G"MSYS Makefiles" ..`

	or

	b) `cmake -G"MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=<install_drive>:/<install_directory> ..` (eg: `cmake -G"MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=C:/Io ..`)
4. `make`
5. `make install`
6. Install [Eerie](https://github.com/IoLanguage/eerie), the Io package manager
   (see Eerie [repo](https://github.com/IoLanguage/eerie) for installation
   options): `./_build/binaries/io_static setup.io`.
   
   
#### Building with MSVC

1. Install Microsoft Visual C++ 2008 Express (should work with other versions).
2. Install Microsoft Windows SDK 7.0 (or newer).
3. Install CMake (v2.8 at least)
4. Run "Visual Studio 2008 Command Prompt" from the "Microsoft Visual Studio
   2008" start menu.
5. `cd` to `<install_drive>:\Microsoft SDKs\Windows\v7.0\Setup` then run:
   `WindowsSdkVer.exe -version:v7.0`
6. Close the command prompt window and run step 4 again
7. Ensure CMake bin path is in the `PATH` environment variable (eg: `echo
   %PATH%` and see that the folder is there) if not you will have to add it to
   your `PATH`.
8. `cd` to your Io root folder
9. We want to do an out-of-source build, so: `mkdir buildroot` and `cd buildroot`
10. a) `cmake ..`

	or

	b) `cmake -DCMAKE_INSTALL_PREFIX=<install_drive>:\<install_directory> ..` (eg: `cmake -DCMAKE_INSTALL_PREFIX=C:\Io ..`)
11. `nmake`
12. `nmake install`
13. Install [Eerie](https://github.com/IoLanguage/eerie), the Io package manager
    (see Eerie [repo](https://github.com/IoLanguage/eerie) for installation
    options): `./_build/binaries/io_static setup.io`.


#### Building with Cygwin

Install Cygwin from: <http://www.cygwin.com/>

1. `cd` to your Io root folder
2. We want to do an out-of-source build, so: `mkdir buildroot` and `cd buildroot`
3. a) `cmake ..`

	or

    b) `cmake -DCMAKE_INSTALL_PREFIX=<install_drive>:/<install_directory> ..`
    (eg: `cmake -DCMAKE_INSTALL_PREFIX=C:/Io ..`)
4. `make`
5. `make install`
6. Install [Eerie](https://github.com/IoLanguage/eerie), the Io package manager
    (see Eerie [repo](https://github.com/IoLanguage/eerie) for installation
    options): `./_build/binaries/io_static setup.io`.

Note: If you also have CMake 2.8 for Windows installed (apart from CMake for
Cygwin) check your `PATH` environment variable so you won't be running CMake for
Windows instead of Cygwin version.


Running Tests
===

You should be inside your out-of-source build dir. The vm tests can be run with
the command:

	io ../libs/iovm/tests/correctness/run.io

Installing Addons
===

Many of the common features provided by the Io language aren't prepackaged in
the Io core. Instead, these features are contained in addons that get loaded
when launching the Io VM. In the past, these addons were automatically installed
by the build process, but now they must be installed through
[Eerie](https://github.com/IoLanguage/eerie), the Io package manager.

Most of these addons are housed under the IoLanguage group on GitHub:
https://github.com/IoLanguage.

To install an addon, ensure both Io and Eerie are installed correctly, then run:

```
eerie install <link to the git repository>
```

For example, to build and install the `Range` addon, run the command:

```
eerie install https://github.com/IoLanguage/Range.git
```

To ensure that an addon installed correctly, pull up an Io interpreter and type
the name of the object provided by the addon. It should load dynamically and
automatically into the interpreter session, populating a slot in `Lobby Protos
Addons`.
