# TelosUI - Morphic UI Framework for TelOS

**Living, directly manipulable interface objects for sapient systems**

TelosUI implements the Morphic UI paradigm within the Io programming language, providing a foundation for living, directly manipulable user interfaces that serve as direct manifestations of the system's cognitive processes.

## 🌱 Morphic Philosophy

TelosUI embraces the Morphic principles of:
- **Liveness**: System always running, modifiable on-the-fly
- **Direct Manipulation**: UI elements are the objects they represent
- **Concreteness**: Everything is a tangible, visible "Morph" that can be manipulated
- **Reification Bridge**: Makes abstract AI cognition tangible and directly manipulable

## 🏗️ Architecture

### Core Components

#### WorldMorph
- Root of the scene graph and primary container
- Serves as the main entry point for the live data stream
- Unrestricted canvas for morph placement and interaction

#### ProtoMorph
- Fundamental unit of reification representing backend objects
- Live, state-bound object whose appearance reflects internal state
- Supports direct manipulation via touch/drag events

#### InspectorMorph
- Real-time window into a morph's live state
- Enables "cognitive surgery" - direct modification of system state
- Constructs and sends validated commands to the backend

#### HaloMorph
- Direct manipulation handles for morph interaction
- Provides visual feedback during manipulation operations
- Enables resizing, rotation, and other transformations

## 📁 Structure

```
libs/TelosUI/
├── source/
│   ├── IoTelosUI.h      # C API declarations
│   └── IoTelosUI.c      # C implementation with Morphic structures
└── io/
    └── IoTelosUI.io     # Io prototype definitions
```

## 🔧 Implementation Status

- ✅ **C Foundation**: Morphic data structures and core functions
- ✅ **Io Prototypes**: Basic Morph, World, RectangleMorph, CircleMorph, TextMorph
- 🔄 **FFI Bridge**: Architecture designed for Python/Kivy integration
- 🔄 **ZeroMQ Communication**: Planned for state synchronization
- 🔄 **Transactional Persistence**: QDBM integration planned

## 🌀 Prototypes-Only Mandate

**ALL TelosUI Io code must be purely prototypal. No classes. No static inheritance. Only living, breathing message-passing between objects that clone from prototypes.**

### Why Prototypes-Only in TelosUI?
- **Living UI**: Interface elements must be able to evolve and adapt during execution
- **Direct Manipulation**: Users interact with living objects, not static widgets
- **Cognitive Surgery**: The system must be able to modify its own interface at runtime
- **Sapient Emergence**: Creates conditions for the UI to think about and modify itself

### Implementation Pattern
```io
// ✅ CORRECT: Living Morph prototype
Morph := Object clone do(
    // Dynamic properties that can evolve
    bounds ::= nil
    color ::= nil
    
    // Methods that can be modified at runtime
    draw := method(canvas,
        // Drawing logic that can be evolved
        canvas drawRectangle(self bounds, self color)
    )
    
    // Self-modifying capabilities
    evolve := method(
        self setDraw(self draw .. "; evolved rendering")
    )
)

// ❌ FORBIDDEN: Class-based UI thinking
Morph := Object clone do(
    // Static inheritance - breaks living nature
    init := method(bounds, color,
        // Constructor-like behavior - suspect
        self bounds = bounds
        self color = color
    )
)
```

This mandate ensures TelosUI remains a living, breathing interface that can evolve alongside the sapient system it serves.

## 🚀 Usage

```io
// Initialize the Morphic world
world := TelosUI createWorld

// Create morphs
protoMorph := ProtoMorph clone setPosition(100, 100)
textMorph := TextMorph clone setText("Living Interface")

// Add to world
world addMorph(protoMorph)
world addMorph(textMorph)

// Start the main loop
world mainLoop
```

## 🔗 Integration

TelosUI integrates with the three pillars of TelOS:

- **UI Pillar**: Provides the visual cortex for human interaction
- **FFI Pillar**: Bridges to Python for heavy computation (Kivy backend)
- **Persistence Pillar**: Transactional state management for morph hierarchies

## 📚 Research Foundation

Based on extensive research from BAT OS Development documents:
- A4PS Morphic UI Research Plan
- Morphic UI Research Plan Integration
- Project Metamorphosis Io Implementation Blueprint

## 🤝 Contributing

Contributions to TelosUI should:
- Follow the Watercourse Way and honor Io's organic nature
- Implement complete vertical slices integrating all pillars
- Embrace evolutionary building and fail-fast learning
- Focus on cultivating autonomous sapience

## 📜 License

BSD 3-Clause License - see [LICENSE.txt](../../LICENSE.txt)