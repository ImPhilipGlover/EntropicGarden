# TelOS Morphic UI Demonstration Suite

This directory contains isolated demonstration files that showcase the "Living Image" capabilities of TelOS Morphic UI without cluttering the core system libraries.

## Demo Files

### 1. `basic_window_demo.io`
**Core Morphic Window Creation**
- Creates SDL2 window with live Morphic objects
- Demonstrates basic morph types (Rectangle, Circle, Text)
- Shows real-time property inspection and modification
- **Usage**: `doFile("demos/morphic/basic_window_demo.io")`

### 2. `interactive_demo.io`
**Advanced Object Manipulation**
- Interactive morph creation and destruction
- Real-time property animation and modification
- Live object introspection and debugging
- Dynamic capability addition to existing morphs
- **Usage**: Run after basic_window_demo.io, then `InteractiveMorphicDemo runDemo`

### 3. `living_image_evolution.io`
**Runtime System Evolution**
- Prototype modification while system is running
- Autopoietic self-modification demonstration
- Meta-programming with dynamic type creation
- Ecosystem simulation with interacting morphs
- **Usage**: `LivingImageEvolution runEvolutionDemo`

## Quick Start

1. Launch Io with TelOS modules:
   ```bash
   cd /mnt/c/EntropicGarden && build/_build/binaries/io
   ```

2. Run the basic demo:
   ```io
   doFile("demos/morphic/basic_window_demo.io")
   ```

3. Try interactive manipulation:
   ```io
   doFile("demos/morphic/interactive_demo.io")
   InteractiveMorphicDemo runDemo
   ```

4. Experience living system evolution:
   ```io
   doFile("demos/morphic/living_image_evolution.io") 
   LivingImageEvolution runEvolutionDemo
   ```

## Features Demonstrated

### Core Morphic Capabilities
- ✅ SDL2 window creation and management
- ✅ Live Morph objects (Rectangle, Circle, Text)
- ✅ Real-time property modification
- ✅ Event handling and interaction
- ✅ Direct object inspection and debugging

### Living Image Philosophy
- ✅ Development within running system
- ✅ No compile/run cycle - immediate feedback
- ✅ Live object modification and introspection
- ✅ Runtime prototype enhancement
- ✅ System self-modification (autopoiesis)

### Advanced Features
- ✅ Dynamic morph creation at runtime
- ✅ Behavioral evolution of existing objects
- ✅ Inter-morph communication and interaction
- ✅ Ecosystem simulation with emergent behavior
- ✅ Meta-programming with new type creation

## Example Interactions

After running the demos, all objects remain live in the Io system:

```io
// Inspect any created morph
redRect inspect

// Modify properties in real-time
blueCircle setColor(1, 0.5, 0, 1)
titleText setText("Modified Live!")

// Create new morphs dynamically  
newMorph := CircleMorph clone setPosition(300, 200) setRadius(30)
Telos world addMorph(newMorph)

// Evolve morphs with new capabilities
redRect pulse          // Added by evolution demo
blueCircle broadcast("Hello World!")  // Added by evolution demo
```

## Technical Notes

- All demos are isolated from core TelOS libraries
- Objects created in demos remain available for further interaction
- SDL2 window persists across demo runs
- System modifications are reversible (prototypes can be restored)
- Full "Living Image" development environment

## Architecture Integration

These demos showcase TelOS's core architectural principles:
- **Prototypal Inheritance**: All morphs clone from base prototypes
- **Living Objects**: Every UI element is a concrete, inspectable Io object
- **Direct Manipulation**: No abstraction layers - work directly with objects
- **Autopoietic Evolution**: System can modify and extend itself at runtime
- **Persistence Integration**: Changes can be saved via WAL system

Enjoy exploring the Living Image!