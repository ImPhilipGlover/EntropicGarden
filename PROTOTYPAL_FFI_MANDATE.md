# CRITICAL ARCHITECTURAL MANDATE: Pure C FFI Only

## ⚠️ **IMMEDIATE ACTION REQUIRED FOR ALL DEVELOPERS** ⚠️

**DECISION**: TelOS FFI layer MUST use pure C. C++ is prohibited.

**REASON**: C++ static type system and class hierarchies fundamentally conflict with Io's prototypal philosophy of living, breathing objects that evolve at runtime.

## Quick Reference

### ✅ **ALLOWED - Pure C Implementation**
```c
// File: PrototypalFFI.c
typedef struct {
    PyObject* python_object;
    IoObject* io_wrapper;
} FFIObjectHandle;

IoObject* IoTelos_marshalData(IoTelos* self, IoObject* locals, IoMessage* m) {
    // Direct function mapping to Io method
}
```

### ❌ **PROHIBITED - C++ Implementation**
```cpp
// File: RigorousFFI.cpp - DO NOT USE
class RigorousFFI {
    std::unordered_map<std::string, py::object> modules;
};
```

## Why This Matters

1. **Prototypal Purity**: Io objects can change behavior at runtime. C++ static types conflict with this.
2. **Memory Integration**: Io GC system needs explicit integration, not C++ RAII.
3. **Philosophical Alignment**: C is procedural like Io's message-passing, C++ is class-based.

## Implementation Status

- ✅ **PrototypalFFI.c**: Pure C implementation created
- ❌ **RigorousFFI.cpp**: C++ implementation - will be removed
- ✅ **CMakeLists.txt**: Updated to compile only .c files

## For Future AI Agents

**NEVER suggest C++ for FFI work. Always use pure C with Python C API.**

Read full details in: `docs/Prototypal_FFI_Architecture_Mandate.md`

---
*This mandate preserves TelOS's prototypal integrity and prevents architectural corruption.*