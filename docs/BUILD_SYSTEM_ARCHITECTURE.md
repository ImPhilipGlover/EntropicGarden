# TELOS Build System Architecture

## Overview

The TELOS build system implements a unified polyglot architecture that orchestrates the compilation and integration of Io, C/C++, and Python components through a single CMake-based build process. The system follows the architectural principle of Io mind controlling Python muscle via the synaptic bridge.

## Build Stages

### Stage 1: IoVM Build
The build process begins with the Io Virtual Machine (IoVM), which serves as the cognitive core of the TELOS system.

**Dependencies:**
- basekit (fundamental Io types and utilities)
- garbagecollector (Boehm GC for memory management)
- coroutine (coroutine implementation)

**Build Command:**
```bash
cmake --build . --target basekit
cmake --build . --target garbagecollector
cmake --build . --target coroutine
cmake --build . --target iovm
```

### Stage 2: Synaptic Bridge C ABI
The synaptic bridge provides the immutable C Application Binary Interface (ABI) that forms the nervous system connecting Io cognitive core to Python computational substrate.

**Components:**
- `synaptic_bridge.h/c` - Core bridge functions and data structures
- `TelosProxyObject.h/c` - Python object proxy management
- `parson.c` - JSON parsing library

**Build Command:**
```bash
cmake --build . --target telos_core
```

### Stage 3: Python CFFI Extension
Python components are built as CFFI extensions that interface with the synaptic bridge.

**Build Process:**
1. CMake custom command invokes Python script to generate C extension
2. Extension links against telos_core library
3. Provides Python bindings for bridge functions

**Build Command:**
```bash
cmake --build . --target telos_python_extension
```

### Stage 4: Io Addon Implementation (TelosBridge)

The Io addon provides high-level Io language bindings to the TELOS synaptic bridge C ABI functions. This is the critical integration point where Io gains access to the bridge functionality.

#### Io Addon Architecture

The Io addon consists of three main components:

1. **Io Veneer (TelosBridge.io)** - High-level Io interface
2. **C Binding Layer (IoTelosBridge.c)** - C functions that interface with Io VM
3. **Header Interface (IoTelosBridge.h)** - C declarations for addon functions

#### Explicit Io Addon Implementation Steps

##### Step 1: Io Veneer Implementation (TelosBridge.io)

Create the Io prototype that provides the high-level interface:

```io
// TELOS Synaptic Bridge Io Veneer
// Provides high-level Io interface to the TelosBridge addon

Telos := Object clone do(
    Bridge := TelosBridge clone  // TelosBridge is the C addon prototype
)

Telos Bridge do(
    initialize := method(configMap,
        // Initialize with configuration map
        config := configMap
        if(config isNil, config = Map clone)
        self proto initialize(config)
    ),

    status := method(
        // Get bridge status as Io Map
        statusCode := self proto status()
        statusMap := Map clone
        if(statusCode == 0,
            statusMap atPut("initialized", true)
            statusMap atPut("maxWorkers", 4)
            statusMap atPut("activeWorkers", 0)
        ,
            statusMap atPut("initialized", false)
            statusMap atPut("error", "status check failed")
        )
        statusMap
    ),

    submitTask := method(taskMap,
        // Submit JSON task to Python workers
        jsonRequest := taskMap asJson
        jsonResponse := self proto submitTask(jsonRequest, 8192)
        parsedResponse := Lobby doString("return " .. jsonResponse)
        parsedResponse
    )
)

// Make Telos namespace globally available
Lobby Telos := Telos
```

**Key Implementation Details:**
- Uses `TelosBridge clone` to create instance from C addon prototype
- Methods delegate to `self proto` (the C addon) for actual implementation
- JSON serialization/deserialization for task communication
- Error handling with Io exceptions

##### Step 2: C Binding Layer Implementation (IoTelosBridge.c)

Implement the C functions that interface with the Io VM:

```c
#include "IoTelosBridge.h"
#include "synaptic_bridge.h"

// Io VM integration macros
#define IOOBJECT_ISTYPE(self, typeName) \
    IoObject_hasCloneFunc_(self, (IoTagCloneFunc *)Io##typeName##_rawClone)

#define IONUMBER(num) IoState_numberWithDouble_((IoState *)IOSTATE, (double)num)
#define CSTRING(uString) IoSeq_asCString(uString)

// Global prototypes
static IoTelosBridge *IoTelosBridgeProto = NULL;

// Core bridge methods
IoObject *IoTelosBridge_initialize(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    // Extract config from Io Map and call bridge_initialize()
    BridgeConfig* config = bridge_create_config(max_workers, "INFO", "telos_bridge.log", 1024 * 1024, "workers");
    BridgeResult result = bridge_initialize(config);
    bridge_free_config(config);
    return result == BRIDGE_SUCCESS ? self : IONIL(self);
}

IoObject *IoTelosBridge_status(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    BridgeStatus status;
    BridgeResult result = bridge_status(&status);
    return IONUMBER(status.initialized ? 0 : 1);
}

IoObject *IoTelosBridge_submitTask(IoTelosBridge *self, IoObject *locals, IoMessage *m) {
    // Get JSON string argument and call bridge_submit_task()
    IoObject *jsonObj = IoMessage_locals_valueArgAt_(m, locals, 0);
    const char *json_str = CSTRING(jsonObj);
    char response_buffer[8192];
    BridgeResult result = bridge_submit_task(json_str, response_buffer, sizeof(response_buffer));
    return IoSeq_newWithCString_(IOSTATE, response_buffer);
}

// Prototype creation
IoTelosBridge *IoTelosBridge_proto(void *state) {
    IoState *self = (IoState *)state;
    if (IoTelosBridgeProto == NULL) {
        IoTelosBridgeProto = IoObject_new(self);
        // Add methods to prototype
        IoObject_addMethod_(IoTelosBridgeProto, IoState_symbolWithCString_(self, "initialize"), IoTelosBridge_initialize);
        IoObject_addMethod_(IoTelosBridgeProto, IoState_symbolWithCString_(self, "status"), IoTelosBridge_status);
        IoObject_addMethod_(IoTelosBridgeProto, IoState_symbolWithCString_(self, "submitTask"), IoTelosBridge_submitTask);
    }
    return IoTelosBridgeProto;
}

// Addon initialization
void IoTelosBridgeInit(IoObject *context) {
    IoState *state = IoObject_state(context);
    // Register TelosBridge prototype in addon context
    IoObject_setSlot_to_(context, IoState_symbolWithCString_(state, "TelosBridge"), IoTelosBridge_proto(state));
}
```

**Key Implementation Details:**
- Uses Io VM API functions for object creation and method binding
- Implements Io calling conventions (self, locals, message parameters)
- Converts between Io and C data types
- Error handling through Io exceptions
- Prototype-based method dispatch

##### Step 3: Header Interface (IoTelosBridge.h)

Define the C interface for the addon:

```c
#ifndef IO_TELOS_BRIDGE_H
#define IO_TELOS_BRIDGE_H

#include "IoObject.h"

// Type definitions
typedef IoObject IoTelosBridge;

// Function declarations
IoTelosBridge *IoTelosBridge_proto(void *state);
void IoTelosBridgeInit(IoObject *context);

#endif /* IO_TELOS_BRIDGE_H */
```

##### Step 4: CMake Integration

The addon is built as a shared library module through CMake:

```cmake
# Io addon build (only if IoVM is available)
if(IOVM_FOUND)
    add_library(IoTelosBridge MODULE "${TELOS_SOURCE_DIR}/IoTelosBridge.c")
    target_include_directories(IoTelosBridge PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
    )
    target_link_libraries(IoTelosBridge PRIVATE
        telos_core iovmall basekit coroutine garbagecollector
    )
    set_target_properties(IoTelosBridge PROPERTIES
        OUTPUT_NAME "IoTelosBridge"
        LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/addons/TelosBridge"
    )
    # Copy Io veneer file to addon directory
    add_custom_command(TARGET IoTelosBridge POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${TELOS_IO_DIR}/TelosBridge.io"
        "${PROJECT_BINARY_DIR}/addons/TelosBridge/io/TelosBridge.io"
    )
endif()
```

**Key Integration Details:**
- Built as `MODULE` library (shared library for dynamic loading)
- Links against IoVM libraries and telos_core
- Output placed in `addons/TelosBridge/` directory
- Io veneer file copied to `addons/TelosBridge/io/`

##### Step 5: Addon Loading and Usage

The addon is loaded dynamically by Io:

```io
// Load the addon
doFile("build/addons/TelosBridge/io/TelosBridge.io")

// Use the bridge
bridge := Telos Bridge
bridge initialize(Map clone)
status := bridge status
result := bridge submitTask(Map clone atPut("operation", "test"))
```

**Loading Methods:**
1. **doFile()** - Direct loading of Io veneer file
2. **AddonLoader** - Io's built-in addon loading system
3. **Dynamic Path Resolution** - Io searches addon paths automatically

#### Io Addon Best Practices

1. **Pure Prototypes**: All Io code uses `Object clone do(...)` pattern
2. **Message Passing**: All operations are method calls, no direct property access
3. **Error Handling**: Use Io exceptions for error propagation
4. **Memory Management**: Rely on Io's garbage collector
5. **Type Safety**: Validate argument types before processing
6. **JSON Communication**: Use JSON for complex data exchange with C layer

### Stage 5: Integration Testing

The final stage validates the complete Io → C → Python pipeline:

**Test Commands:**
```bash
# Run Io-orchestrated tests
ctest --timeout 300

# AddressSanitizer memory safety testing
cmake --build . --config RelWithDebInfo-ASan
ctest --timeout 300
```

## Build Dependencies

```
IoVM (iovmall)
├── basekit
├── garbagecollector
└── coroutine

TelosBridge Addon (IoTelosBridge)
├── iovmall
├── telos_core
├── basekit
├── garbagecollector
└── coroutine

Python Extension (telos_python_extension)
└── telos_core
```

## Development Workflow

1. **Clean Build**: Use Io-orchestrated `clean_and_build.io` script
2. **Incremental Builds**: Use `cmake --build . --target <component>`
3. **Testing**: Run `ctest` for comprehensive validation
4. **Debugging**: Use verbose output and AddressSanitizer for memory issues

## Troubleshooting

- **IoVM Build Failures**: Ensure all IoVM dependencies are built first
- **Addon Loading Issues**: Check `LD_LIBRARY_PATH` includes addon directory
- **Bridge Communication**: Verify JSON serialization/deserialization
- **Memory Issues**: Use AddressSanitizer builds for leak detection
