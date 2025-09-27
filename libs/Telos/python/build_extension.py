#!/usr/bin/env python3
"""
TELOS Python Extension Builder using CFFI

This script generates the Python C extension module for the TELOS Synaptic Bridge
using CFFI in API mode. It reads the canonical C header file and generates the
corresponding Python bindings, ensuring both sides of the bridge are compiled
against the exact same contract.

This script is invoked by CMake as part of the unified build process.
"""

import os
import shutil
import sys
from pathlib import Path
from cffi import FFI

def main():
    """Generate the CFFI Python extension."""
    
    # Determine paths
    script_dir = Path(__file__).parent
    source_dir = script_dir.parent / "source"
    header_file = source_dir / "synaptic_bridge.h"
    
    print(f"Building TELOS Python extension...")
    print(f"Source directory: {source_dir}")
    print(f"Header file: {header_file}")
    
    if not header_file.exists():
        print(f"ERROR: Header file not found: {header_file}", file=sys.stderr)
        sys.exit(1)
    
    telos_core_lib = os.environ.get("TELOS_CORE_LIB")
    telos_core_libdir = os.environ.get("TELOS_CORE_LIBDIR")
    telos_core_includedir = os.environ.get("TELOS_CORE_INCLUDEDIR", str(source_dir))

    if not telos_core_lib or not telos_core_libdir:
        print("ERROR: TELOS core library location not provided. Ensure CMake exports TELOS_CORE_LIB and TELOS_CORE_LIBDIR.", file=sys.stderr)
        sys.exit(1)

    print(f"Linking against telos_core library: {telos_core_lib}")
    print(f"Library directory: {telos_core_libdir}")

    if not Path(telos_core_lib).exists():
        print(f"ERROR: telos_core library not found at {telos_core_lib}", file=sys.stderr)
        sys.exit(1)

    if not Path(telos_core_libdir).exists():
        print(f"ERROR: telos_core library directory not found at {telos_core_libdir}", file=sys.stderr)
        sys.exit(1)

    # Create CFFI builder
    ffibuilder = FFI()

    # Extract the declarations mirrored from the canonical header
    declarations = """
        // Core type definitions
        typedef void* IoObjectHandle;
        
        typedef struct {
            const char* name;
            size_t offset;
            size_t size;
        } SharedMemoryHandle;
        
        typedef enum {
            BRIDGE_SUCCESS = 0,
            BRIDGE_ERROR_NULL_POINTER = -1,
            BRIDGE_ERROR_INVALID_HANDLE = -2,
            BRIDGE_ERROR_MEMORY_ALLOCATION = -3,
            BRIDGE_ERROR_PYTHON_EXCEPTION = -4,
            BRIDGE_ERROR_SHARED_MEMORY = -5,
            BRIDGE_ERROR_TIMEOUT = -6
        } BridgeResult;
        
        // Lifecycle management
        BridgeResult bridge_initialize(int max_workers);
        void bridge_shutdown(void);
        BridgeResult bridge_pin_object(IoObjectHandle handle);
        BridgeResult bridge_unpin_object(IoObjectHandle handle);
        
        // Error handling
        BridgeResult bridge_get_last_error(char* error_buffer, size_t buffer_size);
        void bridge_clear_error(void);
        
        // Shared memory management
        BridgeResult bridge_create_shared_memory(size_t size, SharedMemoryHandle* handle);
        BridgeResult bridge_destroy_shared_memory(const SharedMemoryHandle* handle);
        BridgeResult bridge_map_shared_memory(const SharedMemoryHandle* handle, void** mapped_ptr);
        BridgeResult bridge_unmap_shared_memory(const SharedMemoryHandle* handle, void* mapped_ptr);
        
        // Core computational functions
        BridgeResult bridge_execute_vsa_batch(const char* operation_name,
                                            const SharedMemoryHandle* input_handle,
                                            const SharedMemoryHandle* output_handle,
                                            size_t batch_size);
        
        BridgeResult bridge_ann_search(const SharedMemoryHandle* query_handle,
                                     int k,
                                     const SharedMemoryHandle* results_handle,
                                     double similarity_threshold);
        
        BridgeResult bridge_add_vector(int64_t vector_id,
                                     const SharedMemoryHandle* vector_handle,
                                     const char* index_name);
        
        BridgeResult bridge_update_vector(int64_t vector_id,
                                        const SharedMemoryHandle* vector_handle,
                                        const char* index_name);
        
        BridgeResult bridge_remove_vector(int64_t vector_id,
                                        const char* index_name);
        
        // Message passing
        BridgeResult bridge_send_message(IoObjectHandle target_handle,
                                       const char* message_name,
                                       const SharedMemoryHandle* args_handle,
                                       const SharedMemoryHandle* result_handle);
        
        BridgeResult bridge_get_slot(IoObjectHandle object_handle,
                                   const char* slot_name,
                                   const SharedMemoryHandle* result_handle);
        
        BridgeResult bridge_set_slot(IoObjectHandle object_handle,
                                   const char* slot_name,
                                   const SharedMemoryHandle* value_handle);
    """
    
    # Define the C declarations for CFFI
    ffibuilder.cdef(declarations)
    
    extra_link_args = []
    runtime_library_dirs = []

    if sys.platform != "win32":
        # Ensure the extension can locate libtelos_core at runtime when it resides
        # beside the compiled module.
        extra_link_args.append("-Wl,-rpath,$ORIGIN")
        runtime_library_dirs.append(telos_core_libdir)

    ffibuilder.set_source(
        "_telos_bridge",
        '#include "synaptic_bridge.h"',
        include_dirs=[str(source_dir), str(telos_core_includedir)],
        libraries=["telos_core"],
        library_dirs=[telos_core_libdir],
        runtime_library_dirs=runtime_library_dirs,
        extra_link_args=extra_link_args,
    )
    
    # Generate the extension
    try:
        print("Generating CFFI extension...")
        ffibuilder.compile(tmpdir=script_dir, verbose=True)
        print("Successfully generated TELOS Python extension")

        # Copy the telos_core runtime library next to the generated module for reliable loading
        try:
            lib_path = Path(telos_core_lib)
            dest_path = script_dir / lib_path.name
            if lib_path != dest_path:
                shutil.copy2(lib_path, dest_path)
                print(f"Copied telos_core runtime to {dest_path}")
        except Exception as copy_error:
            print(f"WARNING: Failed to copy telos_core runtime library: {copy_error}")

        # Create a marker file to indicate successful build
        marker_file = script_dir / "_telos_bridge.c"
        marker_file.touch()

    except Exception as e:
        print(f"ERROR: Failed to generate extension: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()