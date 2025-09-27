/*
   telos_proxy.h - Prototypal Emulation Layer Core Structure
   
   This header defines the TelosProxyObject structure, which is the cornerstone
   of the prototypal emulation layer. This structure enables differential inheritance
   across the C/Python bridge, allowing Python code to interact with Io objects
   using native prototypal semantics.
   
   Following architectural mandates, this is a pure C struct (not C++) to ensure
   ABI stability and cross-language compatibility. The design embodies differential
   inheritance: local state stores "differences" while delegating behavior to
   the master prototype in the Io VM.
*/

#ifndef TELOS_PROXY_H
#define TELOS_PROXY_H

#include <Python.h>
#include <structmember.h>
#include "synaptic_bridge.h"

#ifdef __cplusplus
extern "C" {
#endif

// =============================================================================
// TelosProxyObject: Universal Ambassador Structure
// =============================================================================

/**
 * TelosProxyObject: A universal ambassador for an Io object within the C and Python runtimes.
 * 
 * This struct defines the memory layout for the IoProxy Python type and is the
 * physical embodiment of differential inheritance. It stores local state (the
 * "differences") and delegates all other behavior to its master object in the Io VM.
 * 
 * The design follows the rigorous FFI protocols specified in the architectural
 * blueprints, using handle-based references to prevent premature garbage collection
 * and maintain referential integrity across language boundaries.
 */
typedef struct {
    /**
     * Standard Python object header - MUST be first member.
     * 
     * This macro ensures the struct is a valid PyObject, allowing the Python
     * interpreter to manage memory and type information correctly. The placement
     * as the first member is critical for Python C API compatibility.
     */
    PyObject_HEAD
    
    /**
     * Persistent, GC-safe reference to the master object in the Io VM.
     * 
     * This is NOT a raw pointer to an IoObject (which would be unsafe due to GC).
     * Instead, it's an opaque handle that has been registered with the Io VM's
     * root set to prevent garbage collection for the lifetime of this proxy.
     * 
     * The handle is obtained through bridge_pin_object() and released via
     * bridge_unpin_object() to maintain proper lifecycle management.
     */
    IoObjectHandle ioMasterHandle;
    
    /**
     * Local slot storage for differential inheritance.
     * 
     * This PyObject* points to a Python dictionary that serves as the local
     * storage for the proxy. It holds any attributes that have been set on
     * the Python side, directly emulating the "differences" stored in a
     * cloned Io object. This enables true differential inheritance where
     * only modified/new slots are stored locally.
     */
    PyObject *localSlots;
    
    /**
     * Function pointer for message delegation across the FFI boundary.
     * 
     * This is the active mechanism for prototypal emulation. When an attribute
     * is not found in localSlots, this function is called to delegate the
     * message to the master object in the Io VM. This implements the prototype
     * chain lookup across the language boundary.
     * 
     * Signature: (handle, messageName, args) -> PyObject*
     */
    PyObject* (*forwardMessage)(IoObjectHandle handle, const char *messageName, PyObject *args);
    
    /**
     * Unique object identifier for cross-layer tracking.
     * 
     * This string identifier enables correlation between the proxy object and
     * its master in logging, debugging, and persistence operations. It's
     * particularly crucial for WAL (Write-Ahead Logging) and transactional
     * state management.
     */
    char *objectId;
    
    /**
     * Dispatch metrics for bridge instrumentation.
     *
     * Captures invocation counters, latency aggregates, recent history, and
     * last-error context so Io-initiated monitoring can observe bridge health
     * without bypassing the prototypal veneer.
     */
    PyObject *dispatchMetrics;

    /**
     * Reference count for manual memory management.
     * 
     * This tracks the number of active references to the proxy object across
     * the system. When the count reaches zero, the proxy can safely release
     * its IoVM handle and deallocate its resources.
     */
    int refCount;
    
} TelosProxyObject;

// =============================================================================
// Python Type Definition and Registration Functions
// =============================================================================

/**
 * Initialize the IoProxy Python type and register it with the interpreter.
 * 
 * This function must be called during module initialization to make the
 * IoProxy type available to Python code. It sets up all the necessary
 * type slots for proper Python integration.
 * 
 * Returns: 0 on success, -1 on failure
 */
int TelosProxy_InitType(PyObject *module);

/**
 * Create a new TelosProxyObject instance from an Io object handle.
 * 
 * This is the factory function for creating proxy objects. It performs
 * the necessary setup including handle pinning, slot initialization,
 * and reference counting setup.
 * 
 * @param ioHandle: Handle to the Io object to wrap
 * @param objectId: Unique identifier for tracking (copied, can be NULL)
 * @return: New TelosProxyObject instance, or NULL on failure
 */
TelosProxyObject* TelosProxy_CreateFromHandle(IoObjectHandle ioHandle, const char *objectId);

/**
 * Default message forwarding implementation.
 * 
 * This provides the standard implementation of cross-language message
 * delegation. It can be overridden for specialized proxy types, but
 * this default implementation handles the common case of forwarding
 * messages to the Io VM through the synaptic bridge.
 * 
 * @param handle: Io object handle to send message to
 * @param messageName: Name of the message/method to invoke
 * @param args: Python tuple of arguments (can be NULL for no args)
 * @return: Python object result, or NULL on failure
 */
PyObject* TelosProxy_DefaultForwardMessage(IoObjectHandle handle, const char *messageName, PyObject *args);

// =============================================================================
// Prototypal Behavior Implementation Functions
// =============================================================================

/**
 * Implementation of __getattr__ for prototypal delegation.
 * 
 * This function first checks localSlots for the attribute. If not found,
 * it delegates to the master object via forwardMessage. This implements
 * the core prototype chain behavior across the language boundary.
 */
PyObject* TelosProxy_GetAttr(TelosProxyObject *self, PyObject *name);

/**
 * Implementation of __setattr__ for transactional state management.
 * 
 * This function stores attributes in localSlots (for differential inheritance)
 * while also optionally propagating changes back to the master object for
 * consistency. Supports transactional semantics with rollback capabilities.
 */
int TelosProxy_SetAttr(TelosProxyObject *self, PyObject *name, PyObject *value);

/**
 * Implementation of object deallocation with proper cleanup.
 * 
 * This function handles the complete cleanup lifecycle including unpinning
 * the IoVM handle, releasing localSlots, freeing objectId, and calling
 * the Python object deallocator.
 */
void TelosProxy_Dealloc(TelosProxyObject *self);

/**
 * Object cloning implementation for prototypal behavior.
 * 
 * Creates a new proxy object that delegates to the same master but has
 * independent localSlots. This enables true prototypal cloning semantics
 * across the language boundary.
 */
PyObject* TelosProxy_Clone(TelosProxyObject *self, PyObject *args);

// =============================================================================
// Internal Helper Functions
// =============================================================================

/**
 * Validate TelosProxyObject integrity.
 * 
 * Performs comprehensive validation of the proxy object state including
 * handle validity, slot dictionary integrity, and reference count consistency.
 * Used for debugging and defensive programming.
 * 
 * @param self: Proxy object to validate
 * @return: 1 if valid, 0 if invalid (with Python exception set)
 */
int TelosProxy_Validate(TelosProxyObject *self);

/**
 * Generate unique object identifier for new proxy.
 * 
 * Creates a unique identifier string for tracking purposes. The caller
 * is responsible for freeing the returned string.
 * 
 * @return: Newly allocated unique identifier string
 */
char* TelosProxy_GenerateObjectId(void);

/**
 * Forward invocation helper with metrics instrumentation.
 *
 * Routes all bridge-bound messages through a single choke point so latency,
 * failure context, and recent history are recorded alongside the returned
 * value. Args are treated as borrowed references consistent with the Python C
 * API expectations for call helpers.
 */
PyObject* TelosProxy_InvokeForwardMessage(TelosProxyObject *self, const char *messageName, PyObject *args);

/**
 * Produce a shallow copy of the dispatch metrics for external inspection.
 */
PyObject* TelosProxy_CopyDispatchMetrics(TelosProxyObject *self);

/**
 * Reset the dispatch metrics state to its baseline counters/history.
 */
int TelosProxy_ResetDispatchMetrics(TelosProxyObject *self);

/**
 * Record a dispatch outcome, updating counters, history, and aggregates.
 */
int TelosProxy_RecordDispatch(TelosProxyObject *self, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text);

#ifdef __cplusplus
}
#endif

#endif // TELOS_PROXY_H