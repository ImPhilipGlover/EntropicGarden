# Prototypal FFI Architecture Mandate: Pure C Only

**CRITICAL ARCHITECTURAL DECISION: The TelOS FFI layer MUST use pure C, never C++**

## Philosophical Foundation

TelOS is built on **prototypal programming principles** where:
- Objects are living, breathing entities that can evolve at runtime
- Everything flows through message passing - no static hierarchies
- Type boundaries are fluid and can be modified dynamically
- Objects can become anything through delegation and cloning

**C++ fundamentally conflicts with this philosophy.**

## Why C++ is Prohibited for FFI

### 1. **Static Type System Impedance Mismatch**
```cpp
// C++ forces static thinking:
class TensorWrapper {
    PyObject* tensor_;
    std::vector<size_t> shape_;  // Fixed at compile time
};

// But Io needs runtime fluidity:
tensor shape := list(100, 200, 300)     # Can change at runtime
tensor canBecome(Matrix)                # Dynamic type evolution
tensor addBehavior("fft", fftBlock)     # Runtime behavior injection
```

### 2. **Class Hierarchies vs Prototypal Delegation**
- **C++ inheritance**: Static, compile-time hierarchies
- **Io delegation**: Dynamic chains that can be modified at runtime
- **Risk**: C++ thinking leaks into Io design, violating prototypal purity

### 3. **Memory Management Conflicts**
```cpp
// C++ RAII patterns assume ownership:
std::unique_ptr<PyObject> py_obj(create_python_object());

// Io GC system requires manual integration:
IoState_stackRetain_(state, io_obj);  // Explicit GC registration
// Two memory management systems create conflicts and bugs
```

### 4. **Exception Model Mismatch**
```cpp
// C++ exceptions are static types:
throw std::runtime_error("FFI failed");

// Io exceptions are living objects:
Exception raise("FFI failed")
  setSlot("context", contextObj)
  setSlot("recoveryAction", recoveryBlock)  # Can be modified at runtime
```

### 5. **Template System Rigidity**
- C++ templates require compile-time type knowledge
- Io objects can change their effective "type" at runtime
- Templates create rigid boundaries that don't match Io's fluidity

## Why Pure C is Required

### 1. **Philosophical Alignment**
- **C is procedural** - aligns with message-passing paradigm
- **No implicit OOP assumptions** - doesn't impose class-based thinking
- **Transparent operation** - what you see is what happens

### 2. **Direct Integration**
```c
// Clean mapping: C function -> Io method
IoObject* IoTelos_marshalData(IoTelos* self, IoObject* locals, IoMessage* m)
// Maps directly to: Telos marshalData
```

### 3. **Memory Model Clarity**
- **Single memory system**: Io's GC with explicit C malloc/free
- **No hidden operations**: No constructors/destructors running behind the scenes
- **Predictable cleanup**: Everything is explicit and debuggable

### 4. **Performance Characteristics**
- **No C++ runtime overhead**: No virtual function tables, RTTI, etc.
- **No template instantiation bloat**: Smaller binary size
- **Predictable performance**: No hidden complexity

### 5. **Error Handling Alignment**
```c
// C error handling integrates naturally with Io:
if (!py_obj) {
    IoState_error_(state, 0, "Python object creation failed");
    return IONIL(state);
}
// Creates Io exception object that can be inspected and modified
```

## Implementation Requirements

### 1. **All FFI Code Must Be Pure C**
- File extensions: `.c` and `.h` only
- No C++ dependencies (no pybind11, no std::, no classes)
- Use Python C API directly for maximum control

### 2. **Memory Management Integration**
```c
// Correct pattern for Python object wrapping:
typedef struct {
    PyObject* python_object;    // Python reference
    IoObject* io_wrapper;       // Io wrapper
    int gc_registered;          // GC state
} FFIObjectHandle;

// Proper cleanup integration:
void FFI_handleDestructor(void* data) {
    FFIObjectHandle* handle = (FFIObjectHandle*)data;
    Py_DECREF(handle->python_object);  // Release Python reference
    free(handle);                      // Free C memory
}
```

### 3. **Function Naming Convention**
```c
// All FFI functions use this pattern:
FFI_operationName()         // Internal FFI operations
IoTelos_operationName()     // Io-exposed methods
```

### 4. **No C++ Libraries**
Prohibited:
- pybind11 (C++ only)
- std:: containers
- boost libraries
- Any C++ template libraries

Required:
- Python C API (python.h)
- Standard C library (stdlib.h, string.h, etc.)
- POSIX functions for threading/async

## Historical Context

**Previous Mistake**: During Phase 1.2 implementation, I initially chose C++ with pybind11 because:
- Research documents emphasized "production-grade" and "rigorous" patterns
- pybind11 seemed easier than raw Python C API
- Modern C++ features appeared attractive

**Why This Was Wrong**: 
- Conflated "rigorous" with "complex"
- Ignored fundamental prototypal philosophy
- Created impedance mismatch between FFI layer and Io runtime

**Lesson**: Simplicity and philosophical alignment are more important than convenience libraries.

## Enforcement Mechanisms

### 1. **Build System Validation**
```cmake
# CMakeLists.txt must only compile .c files for FFI:
SET(IoTelos_SRCS
    source/IoTelos.c
    source/PrototypalFFI.c    # Pure C implementation
)
# NO .cpp files allowed
```

### 2. **Code Review Checklist**
Before any FFI code is merged:
- [ ] Uses only .c/.h files
- [ ] No C++ keywords (class, template, namespace, etc.)
- [ ] Uses Python C API directly
- [ ] Integrates with Io GC system properly
- [ ] No static type assumptions

### 3. **Documentation Requirements**
All FFI functions must document:
- How they maintain prototypal philosophy
- Memory management integration with Io GC
- Error propagation to Io exception system

## Future Developer Guidance

**For AI Agents**: When implementing any FFI functionality:
1. **Always start with pure C**
2. **Never suggest C++ "improvements"**
3. **Focus on prototypal philosophy alignment**
4. **Prefer explicit over implicit operations**

**For Human Developers**: 
- If you find yourself wanting C++ features, step back and ask if you're imposing class-based thinking on a prototypal system
- Complexity in the FFI layer undermines the dynamism that makes prototypal programming powerful
- When in doubt, choose the simpler C approach

## The Core Principle

**The FFI layer should be a transparent membrane, not a rigid boundary.**

C enables this transparency. C++ creates rigidity that conflicts with Io's living, breathing object model.

---

**This decision is architectural and non-negotiable. It preserves the philosophical integrity that makes TelOS unique.**