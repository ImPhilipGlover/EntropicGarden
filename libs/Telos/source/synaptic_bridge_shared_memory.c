#include "synaptic_bridge.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

/* =============================================================================
 * Shared Memory Management
 * =============================================================================
 */

SharedMemoryPool* create_shared_memory_pool(size_t size, const char* name_prefix) {
    if (size == 0 || name_prefix == NULL) {
        set_bridge_error("Invalid size or name prefix for shared memory pool");
        return NULL;
    }

    SharedMemoryPool* pool = (SharedMemoryPool*)malloc(sizeof(SharedMemoryPool));
    if (pool == NULL) {
        set_bridge_error("Failed to allocate shared memory pool structure");
        return NULL;
    }

    memset(pool, 0, sizeof(SharedMemoryPool));
    pool->size = size;

    // Generate unique name
    snprintf(pool->name, sizeof(pool->name), "/%s_%d", name_prefix, getpid());

    // Create shared memory segment
    pool->fd = shm_open(pool->name, O_CREAT | O_RDWR, 0666);
    if (pool->fd == -1) {
        set_bridge_error("Failed to create shared memory segment: %s", strerror(errno));
        free(pool);
        return NULL;
    }

    // Set size
    if (ftruncate(pool->fd, size) == -1) {
        set_bridge_error("Failed to set shared memory size: %s", strerror(errno));
        close(pool->fd);
        shm_unlink(pool->name);
        free(pool);
        return NULL;
    }

    // Map memory
    pool->data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, pool->fd, 0);
    if (pool->data == MAP_FAILED) {
        set_bridge_error("Failed to map shared memory: %s", strerror(errno));
        close(pool->fd);
        shm_unlink(pool->name);
        free(pool);
        return NULL;
    }

    log_bridge_message(LOG_LEVEL_INFO, "Created shared memory pool '%s' of size %zu", pool->name, size);
    return pool;
}

void destroy_shared_memory_pool(SharedMemoryPool* pool) {
    if (pool == NULL) {
        return;
    }

    if (pool->data != NULL && pool->data != MAP_FAILED) {
        munmap(pool->data, pool->size);
    }

    if (pool->fd != -1) {
        close(pool->fd);
    }

    if (pool->name[0] != '\0') {
        shm_unlink(pool->name);
    }

    free(pool);
    log_bridge_message(LOG_LEVEL_INFO, "Destroyed shared memory pool");
}

BridgeResult create_shared_memory_handle(SharedMemoryHandle* handle, size_t size, const char* name) {
    if (handle == NULL || size == 0) {
        set_bridge_error("Invalid handle or size for shared memory creation");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Find available pool slot
    int pool_index = -1;
    for (int i = 0; i < MAX_SHARED_MEMORY_POOLS; i++) {
        if (g_bridge_state->shared_memory_pools[i] == NULL) {
            pool_index = i;
            break;
        }
    }

    if (pool_index == -1) {
        set_bridge_error("No available shared memory pool slots");
        return BRIDGE_ERROR_RESOURCE_EXHAUSTED;
    }

    const char* name_prefix = name ? name : "bridge_pool";
    SharedMemoryPool* pool = create_shared_memory_pool(size, name_prefix);
    if (pool == NULL) {
        return BRIDGE_ERROR_SHARED_MEMORY;
    }

    g_bridge_state->shared_memory_pools[pool_index] = pool;

     /* Give the caller an owned copy of the pool name so the caller-visible
         handle remains valid independent of the pool allocation lifetime.
         destroy_shared_memory_handle will free this allocation. */
     handle->name = strdup(pool->name);
    handle->size = size;
    handle->data = pool->data;

    log_bridge_message(LOG_LEVEL_DEBUG, "Created shared memory handle '%s'", handle->name);
    return BRIDGE_SUCCESS;
}

BridgeResult destroy_shared_memory_handle(SharedMemoryHandle* handle) {
    if (handle == NULL || handle->name == NULL) {
        set_bridge_error("Invalid shared memory handle");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Find and remove pool
    for (int i = 0; i < MAX_SHARED_MEMORY_POOLS; i++) {
        if (g_bridge_state->shared_memory_pools[i] != NULL &&
            strcmp(g_bridge_state->shared_memory_pools[i]->name, handle->name) == 0) {
                destroy_shared_memory_pool(g_bridge_state->shared_memory_pools[i]);
                g_bridge_state->shared_memory_pools[i] = NULL;
                log_bridge_message(LOG_LEVEL_DEBUG, "Destroyed shared memory handle '%s'", handle->name);
                /* Free the caller-owned name copy and clear the caller-visible
                    handle fields to indicate the handle is no longer valid. */
                free((void*)handle->name);
                handle->name = NULL;
                handle->size = 0;
                handle->offset = 0;
                handle->data = NULL;
            return BRIDGE_SUCCESS;
        }
    }

    set_bridge_error("Shared memory handle '%s' not found", handle->name);
    return BRIDGE_ERROR_INVALID_HANDLE;
}

BridgeResult read_json_from_shared_memory(const SharedMemoryHandle* handle, char** json_buffer, size_t* json_length) {
    if (handle == NULL || handle->name == NULL || json_buffer == NULL) {
        set_bridge_error("Invalid parameters for shared memory read");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Find pool
    SharedMemoryPool* pool = NULL;
    for (int i = 0; i < MAX_SHARED_MEMORY_POOLS; i++) {
        if (g_bridge_state->shared_memory_pools[i] != NULL &&
            strcmp(g_bridge_state->shared_memory_pools[i]->name, handle->name) == 0) {
            pool = g_bridge_state->shared_memory_pools[i];
            break;
        }
    }

    if (pool == NULL) {
        set_bridge_error("Shared memory pool '%s' not found", handle->name);
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    // Read null-terminated string from shared memory
    const char* data = (const char*)pool->data;
    size_t length = strnlen(data, pool->size);
    if (length >= pool->size) {
        set_bridge_error("Shared memory data is not null-terminated");
        return BRIDGE_ERROR_SHARED_MEMORY;
    }

    *json_buffer = (char*)malloc(length + 1);
    if (*json_buffer == NULL) {
        set_bridge_error("Failed to allocate JSON buffer");
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    memcpy(*json_buffer, data, length + 1);
    if (json_length) {
        *json_length = length;
    }

    return BRIDGE_SUCCESS;
}

BridgeResult write_json_to_shared_memory(const SharedMemoryHandle* handle, const char* json_data, size_t json_length) {
    if (handle == NULL || handle->name == NULL || json_data == NULL) {
        set_bridge_error("Invalid parameters for shared memory write");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Find pool
    SharedMemoryPool* pool = NULL;
    for (int i = 0; i < MAX_SHARED_MEMORY_POOLS; i++) {
        if (g_bridge_state->shared_memory_pools[i] != NULL &&
            strcmp(g_bridge_state->shared_memory_pools[i]->name, handle->name) == 0) {
            pool = g_bridge_state->shared_memory_pools[i];
            break;
        }
    }

    if (pool == NULL) {
        set_bridge_error("Shared memory pool '%s' not found", handle->name);
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    if (json_length >= pool->size) {
        set_bridge_error("JSON data too large for shared memory pool (need %zu, have %zu)", json_length + 1, pool->size);
        return BRIDGE_ERROR_SHARED_MEMORY;
    }

    // Write data with null terminator
    memcpy(pool->data, json_data, json_length);
    ((char*)pool->data)[json_length] = '\0';

    return BRIDGE_SUCCESS;
}