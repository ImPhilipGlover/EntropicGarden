# TelOS WSL Development Setup Guide

## Why WSL is Required

The Io Language has fundamental Windows compatibility issues with modern SDK versions:
- `snprintf` macro conflicts with Windows SDK
- `stdint.h` type redefinitions 
- Missing POSIX functions (`getcwd`, `getpid`)
- Various portability issues

**Solution**: Use WSL2 Ubuntu where Io builds and runs perfectly in its native Unix environment.

## Prerequisites

1. **WSL2 Ubuntu**: Should already be installed (`wsl --list --verbose`)
2. **Windows Project**: EntropicGarden accessible at `/mnt/c/EntropicGarden`

## Development Workflow

### 1. Enter WSL Environment
```bash
# From Windows PowerShell
wsl -d Ubuntu
```

### 2. Navigate to Project
```bash
cd /mnt/c/EntropicGarden
```

### 3. Clean Build Process
```bash
# Clean any Windows build artifacts
rm -rf build

# Configure with CMake (uses GCC 13.3.0)
cmake -S . -B build

# Build with parallel jobs
make -C build -j4
```

### 4. Execute Io Code
```bash
# Test basic functionality
./build/_build/binaries/io -e 'writeln("Hello from WSL!")'

# Run Io files
./build/_build/binaries/io script.io

# Interactive mode
./build/_build/binaries/io
```

## Built Artifacts

After successful build in WSL:
- `build/_build/binaries/io` - Dynamic executable
- `build/_build/binaries/io_static` - Static executable  
- `build/_build/dll/lib*.so` - Shared libraries
- `libs/iovm/source/IoVMInit.c` - Generated VM initialization (169KB)

## Key Fixes Applied

### Cross-Platform io2c Path
```cmake
# Before (Windows-specific)
COMMAND ${PROJECT_BINARY_DIR}/_build/binaries/Release/io2c.exe

# After (Cross-platform)
COMMAND $<TARGET_FILE:io2c>
```

### Build Tools Available in WSL Ubuntu
- GCC 13.3.0 - Full C compilation
- CMake - Project configuration
- Make - Build automation
- Git - Version control

## File System Access

- **Windows → WSL**: `/mnt/c/EntropicGarden`
- **WSL → Windows**: Files created in WSL are accessible from Windows Explorer
- **Edit from Windows**: VS Code, editors work seamlessly with WSL files

## TelOS Integration

1. **Current Status**: Clean Io VM successfully built and ready
2. **Next Step**: Integrate TelOS addon from `TelOS_Backup/` directory
3. **Testing**: Verify three pillars (Synaptic Bridge, Transactional Living Image, Morphic UI Canvas)

## Development Philosophy

This WSL solution embodies the TelOS "watercourse way":
- Flow around obstacles rather than fighting them
- Adapt to natural environments where tools thrive
- Maintain architectural integrity while being pragmatic about implementation

---
**Remember**: All Io development must be done from within WSL Ubuntu. Windows compatibility remains broken upstream.