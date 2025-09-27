/**
 * IoTelosBridge - Io Addon for TELOS Synaptic Bridge
 * 
 * This addon provides the Io language interface to the TELOS Synaptic Bridge,
 * following the canonical IoVM addon pattern and enforcing prototypal behavior
 * throughout the bridge interface. All methods delegate to the C ABI functions
 * defined in synaptic_bridge.h.
 */

#ifndef IOTELOS_BRIDGE_H
#define IOTELOS_BRIDGE_H

#include "IoObject.h"

#ifdef __cplusplus
extern "C" {
#endif

/* =============================================================================
 * Forward Declarations
 * =============================================================================
 */

typedef IoObject IoTelosBridge;
typedef IoObject IoSharedMemoryHandle;

/* =============================================================================
 * IoTelosBridge Prototype Functions
 * =============================================================================
 */

/**
 * Initialize the IoTelosBridge prototype and register it with the IoState.
 * This follows the standard IoVM addon initialization pattern.
 */
IoTelosBridge *IoTelosBridge_proto(void *state);

/**
 * Create a new IoTelosBridge instance by cloning the prototype.
 */
IoTelosBridge *IoTelosBridge_rawClone(IoTelosBridge *proto);

/**
 * Create a new IoTelosBridge instance with default initialization.
 */
IoTelosBridge *IoTelosBridge_new(void *state);

/* =============================================================================
 * Bridge Lifecycle Methods (Io-callable)
 * =============================================================================
 */

/**
 * Initialize the bridge with a specified number of worker processes.
 * Usage: bridge initialize(4)
 */
IoObject *IoTelosBridge_initialize(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Shutdown the bridge and cleanup all resources.
 * Usage: bridge shutdown
 */
IoObject *IoTelosBridge_shutdown(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Get the current status of the bridge.
 * Usage: bridge status
 */
IoObject *IoTelosBridge_status(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/* =============================================================================
 * Shared Memory Methods (Io-callable)
 * =============================================================================
 */

/**
 * Create a shared memory block for zero-copy data transfer.
 * Usage: handle := bridge createSharedMemory(size)
 */
IoObject *IoTelosBridge_createSharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Destroy a shared memory block.
 * Usage: bridge destroySharedMemory(handle)
 */
IoObject *IoTelosBridge_destroySharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Map a shared memory block into the current process.
 * Usage: ptr := bridge mapSharedMemory(handle)  
 */
IoObject *IoTelosBridge_mapSharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Unmap a shared memory block from the current process.
 * Usage: bridge unmapSharedMemory(handle, ptr)
 */
IoObject *IoTelosBridge_unmapSharedMemory(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/* =============================================================================
 * VSA and ANN Methods (Io-callable)
 * =============================================================================
 */

/**
 * Execute a batch of VSA operations.
 * Usage: result := bridge executeVSABatch(operationName, inputHandle, outputHandle, batchSize)
 */
IoObject *IoTelosBridge_executeVSABatch(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Perform approximate nearest neighbor search.
 * Usage: results := bridge annSearch(queryHandle, k, resultsHandle, threshold)
 */
IoObject *IoTelosBridge_annSearch(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Add a vector to the L1/L2 cache indexes.
 * Usage: result := bridge addVector(vectorId, vectorHandle, indexName)
 */
IoObject *IoTelosBridge_addVector(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Update a vector in the L1/L2 cache indexes.
 * Usage: result := bridge updateVector(vectorId, vectorHandle, indexName)
 */
IoObject *IoTelosBridge_updateVector(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Remove a vector from the L1/L2 cache indexes.
 * Usage: result := bridge removeVector(vectorId, indexName)
 */
IoObject *IoTelosBridge_removeVector(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/* =============================================================================
 * Error Handling Methods (Io-callable)
 * =============================================================================
 */

/**
 * Get the last error from the bridge.
 * Usage: errorMsg := bridge getLastError
 */
IoObject *IoTelosBridge_getLastError(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/**
 * Clear any pending errors in the bridge.
 * Usage: bridge clearError
 */
IoObject *IoTelosBridge_clearError(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/* =============================================================================
 * Utility and Testing Methods (Io-callable)
 * =============================================================================
 */

/**
 * Ping test to verify bridge connectivity.
 * Usage: response := bridge ping("test message")
 */
IoObject *IoTelosBridge_ping(IoTelosBridge *self, IoObject *locals, IoMessage *m);

/* =============================================================================
 * IoSharedMemoryHandle Prototype Functions
 * =============================================================================
 */

/**
 * Initialize the IoSharedMemoryHandle prototype.
 */
IoSharedMemoryHandle *IoSharedMemoryHandle_proto(void *state);

/**
 * Create a new IoSharedMemoryHandle instance.
 */
IoSharedMemoryHandle *IoSharedMemoryHandle_new(void *state);

/**
 * Create a new IoSharedMemoryHandle with specific values.
 */
IoSharedMemoryHandle *IoSharedMemoryHandle_newWithData(void *state, 
                                                        const char *name, 
                                                        size_t offset, 
                                                        size_t size);

/* =============================================================================
 * IoSharedMemoryHandle Methods (Io-callable)
 * =============================================================================
 */

/**
 * Get the name of the shared memory block.
 * Usage: name := handle name
 */
IoObject *IoSharedMemoryHandle_name(IoSharedMemoryHandle *self, IoObject *locals, IoMessage *m);

/**
 * Get the offset within the shared memory block.
 * Usage: offset := handle offset
 */
IoObject *IoSharedMemoryHandle_offset(IoSharedMemoryHandle *self, IoObject *locals, IoMessage *m);

/**
 * Get the size of the data in the shared memory block.
 * Usage: size := handle size
 */
IoObject *IoSharedMemoryHandle_size(IoSharedMemoryHandle *self, IoObject *locals, IoMessage *m);

/* =============================================================================
 * Addon Entry Point
 * =============================================================================
 */

void IoTelosBridgeInit(IoObject *context);

#ifdef __cplusplus
}
#endif

#endif /* IOTELOS_BRIDGE_H */