# TelOS System Decluttering Plan - Modular Architecture Alignment

## Executive Summary

**Issue Identified**: TelOS has successfully evolved to a modular architecture, but legacy monolithic files remain, creating confusion and potential conflicts. A comprehensive system decluttering is needed to align with proper Io addon patterns.

**Current State**: 
- ✅ **Modular C Architecture**: `IoTelosCore.c`, `IoTelosFFI.c`, `PrototypalFFI.c` properly separated
- ✅ **Modular Io Architecture**: `TelosCore.io`, `TelosFFI.io`, `TelosMorphic.io`, etc. properly separated  
- ❌ **Legacy Monoliths**: `IoTelos.c`, `IoTelos.io` still present, causing confusion
- ❌ **Inconsistent Loading**: Samples trying to load deprecated monolithic files

## 🎯 Decluttering Action Plan

### Phase 1: Deprecate Monolithic Files

**Files to Archive/Remove**:

#### C Layer Monoliths
- `libs/Telos/source/IoTelos.c` → Archive as `IoTelos_deprecated.c`
- `libs/Telos/source/IoTelos.h` → Archive as `IoTelos_deprecated.h`

#### Io Layer Monoliths  
- `libs/Telos/io/IoTelos.io` → Archive as `IoTelos_deprecated.io`
- `libs/Telos/io/IoTelos_backup.io` → Remove (already backup)
- `libs/Telos/io/IoTelos_clean.io` → Remove (redundant)
- `libs/Telos/io/IoTelos.io.corrupted` → Remove (corrupted)

### Phase 2: Update Build System

**Current CMakeLists.txt Structure**:
```cmake
SET(IoTelos_SRCS
    source/IoTelos_new.c      # ← Active entry point
    source/IoTelosCore.c      # ← Modular core
    source/IoTelosFFI.c       # ← Modular FFI
    source/PrototypalFFI.c    # ← Prototypal patterns
)
```

**Action**: Rename `IoTelos_new.c` → `IoTelos.c` as the clean entry point

### Phase 3: Establish Proper Io Addon Loading Pattern

**Current Problem**: Samples trying to load `doFile("libs/Telos/io/IoTelos.io")`

**Io Addon Best Practice**: Follow `libs/iovm/io/` patterns where:
1. C addon auto-registers prototypes 
2. Io modules loaded automatically or via proper addon mechanism
3. No manual `doFile()` required for core functionality

**Proposed Structure**:
```
libs/Telos/
├── source/
│   ├── IoTelos.c           # Main entry point (renamed from IoTelos_new.c)
│   ├── IoTelosCore.c       # Core module
│   ├── IoTelosFFI.c        # FFI bridge  
│   └── PrototypalFFI.c     # Prototypal patterns
├── io/
│   ├── 00-TelosCore.io     # Auto-loaded first (core prototypes)
│   ├── 01-TelosFFI.io      # Auto-loaded second (FFI prototypes)
│   ├── 02-TelosMorphic.io  # Auto-loaded third (UI prototypes)
│   ├── 03-TelosPersistence.io # Auto-loaded fourth (persistence)
│   └── [other modules]     # Additional modular components
```

### Phase 4: Update Sample Loading Patterns

**Replace**:
```io
doFile("libs/Telos/io/TelosCore.io")  # Manual loading
```

**With**:
```io
// Telos addon auto-loaded by C initialization
// Prototypes immediately available after VM startup
world := Telos createWorld
```

## 🏗️ Proper Io Addon Architecture

### Following Io Source Patterns

Based on `libs/iovm/addons/` structure, TelOS should:

1. **Auto-Register in C**: Use `IoState_setBindingsInitCallback` properly
2. **Auto-Load Io Files**: Load modular Io files in dependency order  
3. **Immediate Availability**: `Telos` prototype available without manual loading
4. **Modular Organization**: Each subsystem in separate files

### Reference: Existing Io Addons

Looking at Io VM structure:
- Addons register automatically during VM initialization
- Io prototype files loaded in proper dependency order
- No manual `doFile()` required for standard functionality

## 🧹 Specific Decluttering Actions

### Immediate Actions

1. **Archive Monoliths**:
   ```bash
   cd /mnt/c/EntropicGarden/libs/Telos/source
   mv IoTelos.c IoTelos_deprecated.c
   mv IoTelos.h IoTelos_deprecated.h
   mv IoTelos_new.c IoTelos.c
   
   cd ../io
   mv IoTelos.io IoTelos_deprecated.io
   rm IoTelos_backup.io IoTelos_clean.io IoTelos.io.corrupted
   ```

2. **Update CMakeLists.txt**:
   ```cmake
   SET(IoTelos_SRCS
       source/IoTelos.c          # Clean entry point
       source/IoTelosCore.c      # Modular core
       source/IoTelosFFI.c       # Modular FFI  
       source/PrototypalFFI.c    # Prototypal patterns
   )
   ```

3. **Fix Auto-Loading**: Implement proper Io file auto-loading in C initialization

4. **Update Samples**: Remove manual `doFile()` calls for core modules

### Validation

**Success Criteria**:
- `io -e "writeln(Telos type)"` works without manual loading
- Samples work without explicit `doFile()` for core modules
- Clean separation between core (auto-loaded) and optional modules
- No conflicts between old monolithic and new modular files

## 🎯 Benefits

1. **Clarity**: Clear modular structure aligned with Io patterns
2. **Maintainability**: Each subsystem in dedicated files
3. **Performance**: Proper dependency loading order
4. **Io Compliance**: Follows established Io addon conventions
5. **Developer Experience**: No manual loading ceremony for core functionality

## 📋 Next Steps

1. **Execute Phase 1-2**: Archive monoliths, update build system
2. **Test Modular Loading**: Verify clean addon initialization  
3. **Update Samples**: Remove deprecated loading patterns
4. **Document New Structure**: Update guides and examples
5. **Validate Regression**: Ensure all existing functionality preserved

---

**This decluttering aligns TelOS with proper Io addon architecture while preserving the sophisticated modular functionality already achieved.**