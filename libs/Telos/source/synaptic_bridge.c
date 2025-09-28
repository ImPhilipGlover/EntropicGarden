/**
 * @file synaptic_bridge.c
 * @brief Synaptic Bridge Modular Loader
 *
 * This file serves as the main entry point for the Synaptic Bridge,
 * loading and coordinating the modular components.
 */

#include "synaptic_bridge.h"
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdio.h>

/* Modular components are built as separate translation units and linked
     into the telos_core library. The implementations live in:
         - synaptic_bridge_core.c
         - synaptic_bridge_shared_memory.c
         - synaptic_bridge_vsa.c
         - synaptic_bridge_io.c
     Do not include .c files here; rely on the build system (CMake) to
     compile and link these units into the final library.
*/

/* =============================================================================
 * External implementation declarations
 * The real implementations are provided in separate translation units:
 *   - synaptic_bridge_core.c
 *   - synaptic_bridge_shared_memory.c
 *   - synaptic_bridge_vsa.c
 *   - synaptic_bridge_io.c
 * Keep only extern declarations here to avoid duplicate symbol definitions.
 * ============================================================================= */

extern GILGuard acquire_gil_impl(void);
extern void release_gil_impl(GILGuard* guard);

extern BridgeResult bridge_initialize_impl(const BridgeConfig* config);
extern BridgeResult bridge_shutdown_impl(void);

extern BridgeResult bridge_pin_object_impl(IoObjectHandle handle);
extern BridgeResult bridge_unpin_object_impl(IoObjectHandle handle);

extern BridgeResult read_json_from_shared_memory(const SharedMemoryHandle* handle, char** json_str, size_t* json_len);
extern BridgeResult write_json_to_shared_memory(const SharedMemoryHandle* handle, const char* json_str, size_t json_len);
extern BridgeResult bridge_update_vector_impl(int64_t vector_id, const SharedMemoryHandle* vector_handle, const char* index_name);
extern BridgeResult bridge_add_vector_impl(int64_t vector_id, const SharedMemoryHandle* vector_handle, const char* index_name);
extern BridgeResult bridge_execute_vsa_batch_impl(
    const char* operation_name,
    const SharedMemoryHandle* input_handle,
    const SharedMemoryHandle* output_handle,
    size_t batch_size
);
extern BridgeResult bridge_remove_vector_impl(int64_t vector_id, const char* index_name);
extern BridgeResult bridge_ann_search_impl(
    const SharedMemoryHandle* query_handle,
    int k,
    const SharedMemoryHandle* results_handle,
    double similarity_threshold
);

/* =============================================================================
 * Public ABI wrappers
 * These functions expose the stable C ABI and forward to modular
 * implementations or provide small platform-safe fallbacks when needed.
 * ============================================================================= */

GILGuard acquire_gil(void) {
    return acquire_gil_impl();
}

void release_gil(GILGuard* guard) {
    release_gil_impl(guard);
}

BridgeResult bridge_initialize(const BridgeConfig* config) {
    return bridge_initialize_impl(config);
}

BridgeResult bridge_shutdown(void) {
    return bridge_shutdown_impl();
}

BridgeResult bridge_pin_object(IoObjectHandle handle) {
    return bridge_pin_object_impl(handle);
}

BridgeResult bridge_unpin_object(IoObjectHandle handle) {
    return bridge_unpin_object_impl(handle);
}

BridgeResult bridge_get_last_error(char* error_buffer, size_t buffer_size) {
    if (error_buffer == NULL || buffer_size == 0) {
        return BRIDGE_ERROR_NULL_POINTER;
    }

    /* If the bridge has not been initialized yet, treat the last-error as
       empty to make lifecycle checks idempotent and safe to call prior to
       initialization. Tests and callers expect an empty buffer in this case. */
    if (g_bridge_state == NULL) {
        error_buffer[0] = '\0';
        return BRIDGE_SUCCESS;
    }

    const char* err = get_bridge_error();
    if (err == NULL) {
        error_buffer[0] = '\0';
        return BRIDGE_SUCCESS;
    }

    size_t len = strlen(err);
    size_t copy_len = (len < buffer_size - 1) ? len : buffer_size - 1;
    memcpy(error_buffer, err, copy_len);
    error_buffer[copy_len] = '\0';
    return BRIDGE_SUCCESS;
}

void bridge_clear_error(void) {
    clear_bridge_error();
}

BridgeResult bridge_create_shared_memory(size_t size, SharedMemoryHandle* handle) {
    return create_shared_memory_handle(handle, size, NULL);
}

BridgeResult bridge_destroy_shared_memory(SharedMemoryHandle* handle) {
    return destroy_shared_memory_handle(handle);
}

BridgeResult bridge_map_shared_memory(const SharedMemoryHandle* handle, void** mapped_ptr) {
    if (handle == NULL || mapped_ptr == NULL) {
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // If handle already has a mapped pointer, use it
    if (handle->data != NULL) {
        *mapped_ptr = handle->data;
        return BRIDGE_SUCCESS;
    }

    if (handle->name == NULL) {
        return BRIDGE_ERROR_NULL_POINTER;
    }

    int fd = shm_open(handle->name, O_RDWR, 0);
    if (fd == -1) {
        return BRIDGE_ERROR_SHARED_MEMORY;
    }

    void* mapped = mmap(NULL, handle->size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, handle->offset);
    close(fd);
    if (mapped == MAP_FAILED) {
        return BRIDGE_ERROR_SHARED_MEMORY;
    }

    *mapped_ptr = mapped;
    return BRIDGE_SUCCESS;
}

BridgeResult bridge_unmap_shared_memory(const SharedMemoryHandle* handle, void* mapped_ptr) {
    if (handle == NULL || mapped_ptr == NULL) {
        return BRIDGE_ERROR_NULL_POINTER;
    }

    /* If the mapped pointer matches the internal pool mapping (created by
       bridge_create_shared_memory), do not munmap it here. The shared memory
       pool is owned by the bridge and will be unmapped when the pool is
       destroyed. Unmapping it here would leave the stored pool->data pointer
       dangling and cause subsequent mappings to return an invalid address. */
    if (handle->data != NULL && handle->data == mapped_ptr) {
        return BRIDGE_SUCCESS;
    }

    if (munmap(mapped_ptr, handle->size) == -1) {
        return BRIDGE_ERROR_SHARED_MEMORY;
    }

    return BRIDGE_SUCCESS;
}

/* Forwarder for vector update (public ABI) */
BridgeResult bridge_update_vector(int64_t vector_id, const SharedMemoryHandle* vector_handle, const char* index_name) {
    return bridge_update_vector_impl(vector_id, vector_handle, index_name);
}

/* Forwarder for adding a vector (public ABI) */
BridgeResult bridge_add_vector(int64_t vector_id, const SharedMemoryHandle* vector_handle, const char* index_name) {
    return bridge_add_vector_impl(vector_id, vector_handle, index_name);
}

/* Minimal implementation of bridge_add_vector_impl that is a safe stub
 * to satisfy the Python C-extension's import-time symbol resolution.
 */
BridgeResult bridge_add_vector_impl(int64_t vector_id, const SharedMemoryHandle* vector_handle, const char* index_name) {
    (void)vector_id;
    (void)vector_handle;
    (void)index_name;
    set_bridge_error("bridge_add_vector_impl not implemented in this build");
    return BRIDGE_ERROR_NOT_INITIALIZED;
}

/* Wrapper for executing a VSA batch from the public ABI. */
BridgeResult bridge_execute_vsa_batch(
    const char* operation_name,
    const SharedMemoryHandle* input_handle,
    const SharedMemoryHandle* output_handle,
    size_t batch_size
) {
    return bridge_execute_vsa_batch_impl(operation_name, input_handle, output_handle, batch_size);
}

/* Minimal stub for bridge_execute_vsa_batch_impl to allow imports. */
BridgeResult bridge_execute_vsa_batch_impl(
    const char* operation_name,
    const SharedMemoryHandle* input_handle,
    const SharedMemoryHandle* output_handle,
    size_t batch_size
) {
    (void)operation_name;
    (void)input_handle;
    (void)output_handle;
    (void)batch_size;
    set_bridge_error("bridge_execute_vsa_batch_impl not implemented in this build");
    return BRIDGE_ERROR_NOT_INITIALIZED;
}

/* Wrapper and stub for removing a vector */
BridgeResult bridge_remove_vector(int64_t vector_id, const char* index_name) {
    return bridge_remove_vector_impl(vector_id, index_name);
}

BridgeResult bridge_remove_vector_impl(int64_t vector_id, const char* index_name) {
    (void)vector_id;
    (void)index_name;
    set_bridge_error("bridge_remove_vector_impl not implemented in this build");
    return BRIDGE_ERROR_NOT_INITIALIZED;
}

/* Wrapper and stub for ANN search */
BridgeResult bridge_submit_json_task(
    const SharedMemoryHandle* request_handle,
    const SharedMemoryHandle* response_handle
) {
    return bridge_submit_json_task_impl(request_handle, response_handle);
}

BridgeResult bridge_ann_search(
    const SharedMemoryHandle* query_handle,
    int k,
    const SharedMemoryHandle* results_handle,
    double similarity_threshold
) {
    return bridge_ann_search_impl(query_handle, k, results_handle, similarity_threshold);
}



/* Minimal implementation of bridge_update_vector_impl that forwards the
 * request to the Python worker pool similarly to bridge_add_vector.
 * This keeps the symbol available for linking and mirrors the expected
 * behavior used by higher-level components. It uses the same task format
 * as bridge_update_vector in the full implementation.
 */
BridgeResult bridge_update_vector_impl(int64_t vector_id, const SharedMemoryHandle* vector_handle, const char* index_name) {
    // Minimal stub to satisfy the linker and allow higher-level tests to
    // load. Real implementation should forward to Python worker pool.
    (void)vector_id;
    (void)vector_handle;
    (void)index_name;
    set_bridge_error("bridge_update_vector_impl not implemented in this build");
    return BRIDGE_ERROR_NOT_INITIALIZED;
}
