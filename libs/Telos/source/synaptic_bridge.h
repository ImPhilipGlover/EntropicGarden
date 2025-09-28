/**
 * 
 * 
 * The Synaptic Bridge: Canonical C ABI Contract
 * 
 * This file constitutes the definitive, immutable definition of the Foreign Function Interface
 * between the Io cognitive core and the Python substrate. As mandated by the architectural
 * blueprints, all functions are declared with extern "C" to suppress C++ name mangling and
 * enforce standard C calling conventions, creating a stable, compiler-agnostic boundary.
 * 
 * This C ABI is the lingua franca of interoperability, providing a guarantee of stability
 * that is practically unmatched by any other language-level interface.
 */

#ifndef SYNAPTIC_BRIDGE_H
#define SYNAPTIC_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* =============================================================================
 * Constants
 * =============================================================================
 */

#define MAX_SHARED_MEMORY_POOLS 16
#define MAX_VSA_BINDINGS 32
#define MAX_VSA_NAME_LENGTH 64

/* =============================================================================
 * Internal Helper Functions
 * =============================================================================
 */

/**
 * GIL guard structure for Python thread safety
 */
typedef struct {
    int active;
    void* state;  /* PyGILState_STATE */
} GILGuard;

/**
 * Acquire the Python GIL.
 */
GILGuard acquire_gil(void);

/**
 * Release the Python GIL.
 */
void release_gil(GILGuard* guard);

/* =============================================================================
 * Core Data Types and Handles
 * =============================================================================
 */

/**
 * Opaque handle to an Io object. This is not a raw pointer to avoid GC issues.
 * Instead, it's a managed handle that has been explicitly registered with the 
 * Io VM's root set to prevent garbage collection.
 */
typedef void* IoObjectHandle;

/**
 * Handle to a shared memory block for zero-copy IPC of large data structures
 * (tensors, hypervectors, and large message payloads).
 */
typedef struct {
    const char* name;     /* Unique name of the shared memory block */
    size_t offset;        /* Byte offset within the block */
    size_t size;         /* Size of the data in bytes */
    void* data;          /* Mapped data pointer */
} SharedMemoryHandle;

/**
 * Internal shared memory pool structure
 */
typedef struct {
    char name[256];      /* Shared memory name */
    int fd;              /* File descriptor */
    size_t size;         /* Size of the memory block */
    void* data;          /* Mapped memory pointer */
} SharedMemoryPool;

/**
 * VSA handle type (opaque)
 */
typedef void* VSAHandle;

/**
 * VSA binding structure
 */
typedef struct {
    VSAHandle handle;
    char name[64];
} VSABinding;

/**
 * Log level enumeration
 */
typedef enum {
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO = 1,
    LOG_LEVEL_WARNING = 2,
    LOG_LEVEL_ERROR = 3
} LogLevel;

/**
 * Log callback function type
 */
typedef void (*LogCallback)(LogLevel level, const char* message);

/**
 * Bridge configuration structure
 */
typedef struct {
    int max_workers;
    LogCallback log_callback;
} BridgeConfig;

/**
 * Main bridge state structure
 */
typedef struct {
    BridgeConfig config;
    char error_buffer[1024];
    size_t error_length;
    SharedMemoryPool* shared_memory_pools[16];  /* MAX_SHARED_MEMORY_POOLS = 16 */
    VSABinding vsa_bindings[32];  /* MAX_VSA_BINDINGS = 32 */
} SynapticBridgeState;

/**
 * Error codes returned by bridge functions
 */
typedef enum {
    BRIDGE_SUCCESS = 0,
    BRIDGE_ERROR_NULL_POINTER = -1,
    BRIDGE_ERROR_INVALID_HANDLE = -2,
    BRIDGE_ERROR_MEMORY_ALLOCATION = -3,
    BRIDGE_ERROR_PYTHON_EXCEPTION = -4,
    BRIDGE_ERROR_SHARED_MEMORY = -5,
    BRIDGE_ERROR_TIMEOUT = -6,
    BRIDGE_ERROR_ALREADY_INITIALIZED = -7,
    BRIDGE_ERROR_NOT_INITIALIZED = -8,
    BRIDGE_ERROR_ALREADY_EXISTS = -9,
    BRIDGE_ERROR_NOT_FOUND = -10,
    BRIDGE_ERROR_INVALID_ARGUMENT = -11,
    BRIDGE_ERROR_RESOURCE_EXHAUSTED = -12
} BridgeResult;

/* =============================================================================
 * Lifecycle Management Functions
 * =============================================================================
 */

/**
 * Initialize the Python substrate and process pool.
 * Must be called before any other bridge functions.
 * 
 * @param config Configuration structure
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_initialize(const BridgeConfig* config);

/**
 * Shutdown the Python substrate and clean up all resources.
 * This function blocks until all worker processes have terminated.
 * 
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_shutdown(void);

/**
 * Pin an Io object to prevent garbage collection while referenced by Python.
 * This must be called before passing an IoObjectHandle to Python.
 * 
 * @param handle The Io object handle to pin
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_pin_object(IoObjectHandle handle);

/**
 * Unpin an Io object, allowing it to be garbage collected.
 * This is called from PyCapsule destructor callbacks.
 * 
 * @param handle The Io object handle to unpin
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_unpin_object(IoObjectHandle handle);

/* =============================================================================
 * Error Handling and Propagation
 * =============================================================================
 */

/**
 * Get the last Python error that occurred in the bridge.
 * This implements the second call in the two-call error protocol.
 * 
 * @param error_buffer Buffer to receive the error message
 * @param buffer_size Size of the error buffer
 * @return BRIDGE_SUCCESS if error retrieved, error code otherwise
 */
BridgeResult bridge_get_last_error(char* error_buffer, size_t buffer_size);

/**
 * Clear any pending Python error state.
 * Should be called after handling an error.
 */
void bridge_clear_error(void);



/* =============================================================================
 * Shared Memory Management
 * =============================================================================
 */

/**
 * Create a new shared memory block for zero-copy data transfer.
 * 
 * @param size Size of the memory block in bytes
 * @param handle Output parameter for the memory handle
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_create_shared_memory(size_t size, SharedMemoryHandle* handle);

/**
 * Destroy a shared memory block and free its resources.
 * Only the creating process should call this function.
 * 
 * @param handle Handle to the memory block to destroy
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_destroy_shared_memory(SharedMemoryHandle* handle);

/**
 * Map a shared memory block into the current process address space.
 * 
 * @param handle Handle to the memory block
 * @param mapped_ptr Output parameter for the mapped memory pointer
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_map_shared_memory(const SharedMemoryHandle* handle, void** mapped_ptr);

/**
 * Unmap a shared memory block from the current process address space.
 * 
 * @param handle Handle to the memory block
 * @param mapped_ptr Pointer returned by bridge_map_shared_memory
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_unmap_shared_memory(const SharedMemoryHandle* handle, void* mapped_ptr);

/**
 * Create a shared memory handle.
 */
BridgeResult create_shared_memory_handle(SharedMemoryHandle* handle, size_t size, const char* name);

/**
 * Destroy a shared memory handle.
 */
BridgeResult destroy_shared_memory_handle(SharedMemoryHandle* handle);

/**
 * Read JSON from shared memory.
 */
BridgeResult read_json_from_shared_memory(const SharedMemoryHandle* handle, char** json_buffer, size_t* json_length);

/**
 * Write JSON to shared memory.
 */
BridgeResult write_json_to_shared_memory(const SharedMemoryHandle* handle, const char* json_data, size_t json_length);

/**
 * Destroy a shared memory pool.
 */
void destroy_shared_memory_pool(SharedMemoryPool* pool);

/* =============================================================================
 * Core Computational Functions
 * =============================================================================
 */

/**
 * Execute a batch of VSA operations in the Python substrate.
 * This implements the coarse-grained batching protocol to amortize IPC overhead.
 * 
 * @param operation_name Name of the VSA operation ("bind", "unbind", "cleanup", etc.)
 * @param input_handle Handle to shared memory containing input data
 * @param output_handle Handle to shared memory to receive output data  
 * @param batch_size Number of operations in the batch
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_execute_vsa_batch(
    const char* operation_name,
    const SharedMemoryHandle* input_handle,
    const SharedMemoryHandle* output_handle,
    size_t batch_size
);

/**
 * Perform approximate nearest neighbor search in the L1/L2 cache.
 * 
 * @param query_handle Handle to shared memory containing query vector
 * @param k Number of nearest neighbors to return
 * @param results_handle Handle to shared memory to receive results
 * @param similarity_threshold Minimum similarity threshold for results
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_ann_search(
    const SharedMemoryHandle* query_handle,
    int k,
    const SharedMemoryHandle* results_handle,
    double similarity_threshold
);

/**
 * Add a vector to the L1/L2 ANN indexes.
 * 
 * @param vector_id Unique integer ID for the vector
 * @param vector_handle Handle to shared memory containing the vector data
 * @param index_name Name of the index to update ("L1" or "L2")
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_add_vector(
    int64_t vector_id,
    const SharedMemoryHandle* vector_handle,
    const char* index_name
);

/**
 * Update an existing vector in the L1/L2 ANN indexes.
 * 
 * @param vector_id ID of the vector to update
 * @param vector_handle Handle to shared memory containing the new vector data
 * @param index_name Name of the index to update ("L1" or "L2")
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_update_vector(
    int64_t vector_id,
    const SharedMemoryHandle* vector_handle,
    const char* index_name
);

/**
 * Remove a vector from the L1/L2 ANN indexes.
 * 
 * @param vector_id ID of the vector to remove
 * @param index_name Name of the index to update ("L1" or "L2")
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_remove_vector(
    int64_t vector_id,
    const char* index_name
);

/**
 * Submit a JSON-encoded task to the Python worker pool and receive a JSON result.
 * The request payload must be provided via shared memory to preserve zero-copy semantics.
 *
 * @param request_handle Shared memory handle containing UTF-8 JSON request
 * @param response_handle Shared memory handle that will receive UTF-8 JSON response
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_submit_json_task(
    const SharedMemoryHandle* request_handle,
    const SharedMemoryHandle* response_handle
);

/* Implementation functions (internal) */
BridgeResult bridge_submit_json_task_impl(
    const SharedMemoryHandle* request_handle,
    const SharedMemoryHandle* response_handle
);

BridgeResult bridge_ann_search_impl(
    const SharedMemoryHandle* query_handle,
    int k,
    const SharedMemoryHandle* results_handle,
    double similarity_threshold
);

/* =============================================================================
 * Message Passing and Object Communication
 * =============================================================================
 */

/**
 * Send a message to an Io object via the bridge.
 * This enables Python code to communicate with Io objects.
 * 
 * @param target_handle Handle to the target Io object
 * @param message_name Name of the message to send
 * @param args_handle Handle to shared memory containing serialized arguments (optional)
 * @param result_handle Handle to shared memory to receive serialized result (optional)
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_send_message(
    IoObjectHandle target_handle,
    const char* message_name,
    const SharedMemoryHandle* args_handle,
    const SharedMemoryHandle* result_handle
);

/**
 * Get the value of a slot from an Io object without activating it.
 * 
 * @param object_handle Handle to the Io object
 * @param slot_name Name of the slot to retrieve
 * @param result_handle Handle to shared memory to receive the slot value
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_get_slot(
    IoObjectHandle object_handle,
    const char* slot_name,
    const SharedMemoryHandle* result_handle
);

/**
 * Set the value of a slot in an Io object.
 * 
 * @param object_handle Handle to the Io object
 * @param slot_name Name of the slot to set
 * @param value_handle Handle to shared memory containing the new value
 * @return BRIDGE_SUCCESS on success, error code on failure
 */
BridgeResult bridge_set_slot(
    IoObjectHandle object_handle,
    const char* slot_name,
    const SharedMemoryHandle* value_handle
);

/**
 * Bind a VSA handle to a name.
 */
BridgeResult bridge_bind_vsa(const char* name, VSAHandle handle);

/**
 * Unbind a VSA handle.
 */
BridgeResult bridge_unbind_vsa(const char* name);

/**
 * Query a VSA.
 */
BridgeResult bridge_query_vsa(const char* name, const SharedMemoryHandle* query_handle, const SharedMemoryHandle* result_handle);

/* =============================================================================
 * Error handling functions
 * =============================================================================
 */

void set_bridge_error(const char* format, ...);
const char* get_bridge_error(void);
void clear_bridge_error(void);
void log_bridge_message(LogLevel level, const char* format, ...);

/* =============================================================================
 * Shared memory functions
 * =============================================================================
 */

BridgeResult create_shared_memory_handle(SharedMemoryHandle* handle, size_t size, const char* name);
BridgeResult destroy_shared_memory_handle(SharedMemoryHandle* handle);
BridgeResult write_json_to_shared_memory(const SharedMemoryHandle* handle, const char* json_data, size_t json_length);
BridgeResult read_json_from_shared_memory(const SharedMemoryHandle* handle, char** json_buffer, size_t* json_length);

/* =============================================================================
 * VSA functions
 * =============================================================================
 */

int bind_vsa(const char* name, void* binding_data);
int unbind_vsa(const char* name);
void* query_vsa(const char* name);

/* =============================================================================
 * Io integration functions
 * =============================================================================
 */

char* serialize_io_object(void* io_object);
void* deserialize_io_object(const char* json_data);
BridgeResult bridge_send_message(void* io_object, const char* message_name, const SharedMemoryHandle* args_handle, const SharedMemoryHandle* result_handle);
BridgeResult bridge_get_slot(void* io_object, const char* slot_name, const SharedMemoryHandle* result_handle);
BridgeResult bridge_set_slot(void* io_object, const char* slot_name, const SharedMemoryHandle* value_handle);

#ifdef __cplusplus
}
#endif

#endif /* SYNAPTIC_BRIDGE_H */

/* Global bridge state */
extern SynapticBridgeState* g_bridge_state;
