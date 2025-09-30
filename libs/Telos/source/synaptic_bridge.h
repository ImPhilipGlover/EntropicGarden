/**
 * synaptic_bridge.h - TELOS Synaptic Bridge C ABI
 *
 * This header defines the immutable C Application Binary Interface (ABI)
 * for the TELOS Synaptic Bridge, providing stable inter-language communication
 * between Io cognitive core and Python computational substrate.
 *
 * ALL FUNCTIONS MUST BE DECLARED WITH extern "C" FOR COMPILER AGNOSTIC STABILITY.
 * NO C++ FEATURES, NO PYTHON.H DEPENDENCIES, PURE C ABI ONLY.
 */

#ifndef SYNAPTIC_BRIDGE_H
#define SYNAPTIC_BRIDGE_H

#include <stddef.h>
#include <stdint.h>

// Forward declaration for PyObject to avoid Python.h dependency in header
#ifndef PyObject
typedef struct _object PyObject;
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * TYPE DEFINITIONS
 * ============================================================================ */

/**
 * IoObjectHandle - Opaque handle for Io objects in the bridge
 * Implementation details are hidden to ensure ABI stability across language boundaries.
 */
typedef void* IoObjectHandle;

/**
 * BridgeResult - Return codes for all bridge operations
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
    BRIDGE_ERROR_RESOURCE_EXHAUSTED = -12,
    BRIDGE_ERROR_NOT_IMPLEMENTED = -13,
    BRIDGE_ERROR_INITIALIZATION_FAILED = -14,
    BRIDGE_ERROR_SHARED_MEMORY_FAILED = -15,
    BRIDGE_ERROR_PYTHON_FAILED = -16,
    BRIDGE_ERROR_IO_FAILED = -17,
    BRIDGE_ERROR_UNKNOWN = -999
} BridgeResult;

/**
 * LogLevel - Logging levels for bridge operations
 */
typedef enum {
    LOG_LEVEL_DEBUG = 0,
    LOG_LEVEL_INFO = 1,
    LOG_LEVEL_WARNING = 2,
    LOG_LEVEL_ERROR = 3
} LogLevel;

/**
 * BridgeConfig - Configuration structure for bridge initialization
 */
typedef struct {
    int max_workers;
    const char* log_level;
    const char* log_file;
    size_t shared_memory_size;
    const char* worker_path;
    void (*log_callback)(int level, const char* message);
} BridgeConfig;

/**
 * SharedMemoryHandle - Opaque handle for shared memory operations
 * Implementation details are hidden to ensure ABI stability.
 */
typedef struct SharedMemoryHandle {
    const char* name;
    size_t offset;
    size_t size;
    void* data;
} SharedMemoryHandle;

/**
 * BridgeStatus - Status structure for bridge state queries
 */
typedef struct {
    int initialized;
    int max_workers;
    int active_workers;
} BridgeStatus;

/* ============================================================================
 * FUNCTION DECLARATIONS (MANDATORY extern "C")
 * ============================================================================ */

/**
 * bridge_create_config - Create a bridge configuration
 * @param max_workers: Maximum number of Python worker processes
 * @param log_level: Log level string ("DEBUG", "INFO", "WARNING", "ERROR")
 * @param log_file: Path to log file (NULL for stdout)
 * @param shared_memory_size: Size of shared memory pool in bytes
 * @param worker_path: Path to worker directory
 * @return: Pointer to BridgeConfig or NULL on failure
 */
BridgeConfig* bridge_create_config(int max_workers, const char* log_level,
                                  const char* log_file, size_t shared_memory_size,
                                  const char* worker_path);

/**
 * bridge_free_config - Free a bridge configuration
 * @param config: Configuration to free
 */
void bridge_free_config(BridgeConfig* config);

/**
 * bridge_initialize - Initialize the synaptic bridge
 * @param config: Bridge configuration
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 *
 * NOTE: Call bridge_get_last_error() for details on failure.
 */
BridgeResult bridge_initialize(const BridgeConfig* config);

/**
 * bridge_shutdown - Shutdown the synaptic bridge
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_shutdown(void);

/**
 * bridge_get_last_error - Get the last error message
 * @param buffer: Buffer to store error message
 * @param buffer_size: Size of buffer
 * @return: BRIDGE_SUCCESS if error retrieved, error code otherwise
 */
BridgeResult bridge_get_last_error(char* buffer, size_t buffer_size);

/**
 * bridge_clear_error - Clear the error state
 */
void bridge_clear_error(void);

/**
 * bridge_status - Get the current bridge status
 * @param status: Output status structure
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_status(BridgeStatus* status);

/**
 * status_simple - Simple status check for Io binding
 * @return: 0 if initialized, 1 if not initialized, -1 on error
 */
int status_simple(void);

/**
 * bridge_create_shared_memory - Create a shared memory block
 * @param size: Size of memory block in bytes
 * @param handle: Output handle for the created memory
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_create_shared_memory(size_t size, SharedMemoryHandle* handle);

/**
 * bridge_destroy_shared_memory - Destroy a shared memory block
 * @param handle: Handle to destroy
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_destroy_shared_memory(SharedMemoryHandle* handle);

/**
 * bridge_map_shared_memory - Map shared memory into process address space
 * @param handle: Handle to map
 * @param mapped_ptr: Output pointer to mapped memory
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_map_shared_memory(const SharedMemoryHandle* handle, void** mapped_ptr);

/**
 * bridge_unmap_shared_memory - Unmap shared memory from process address space
 * @param handle: Handle to unmap
 * @param mapped_ptr: Pointer returned by bridge_map_shared_memory
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_unmap_shared_memory(const SharedMemoryHandle* handle, void* mapped_ptr);

/**
 * bridge_submit_task - Submit a task to Python workers
 * @param task_json: JSON string describing the task
 * @param response_buffer: Buffer to store JSON response
 * @param buffer_size: Size of response buffer
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 *
 * Task JSON format:
 * {
 *   "operation": "function_name",
 *   "args": [...],
 *   "kwargs": {...}
 * }
 *
 * Response JSON format:
 * {
 *   "success": true|false,
 *   "result": ...,
 *   "error": "error message" (if success=false)
 * }
 */
BridgeResult bridge_submit_task(const char* task_json, char* response_buffer, size_t buffer_size);

/**
 * bridge_ping - Test bridge connectivity
 * @param message: Ping message
 * @param response_buffer: Buffer for response
 * @param buffer_size: Size of response buffer
 * @return: BRIDGE_SUCCESS on success, error code otherwise
 */
BridgeResult bridge_ping(const char* message, char* response_buffer, size_t buffer_size);

/**
 * bridge_forward_message_to_io - Forward message to Io VM for delegation
 * @param ioMasterHandle: Handle to the Io object
 * @param messageName: Name of the message/slot to access
 * @param args: Python tuple of arguments (NULL for attribute access)
 * @return: PyObject* result from Io delegation, or NULL on error
 *
 * NOTE: This function requires Python.h and is not part of the pure C ABI.
 * It is provided for internal bridge implementation use only.
 */
PyObject* bridge_forward_message_to_io(void* ioMasterHandle,
                                     const char* messageName,
                                     PyObject* args);

#ifdef __cplusplus
}
#endif

#endif /* SYNAPTIC_BRIDGE_H */