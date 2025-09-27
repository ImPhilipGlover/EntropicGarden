/*
   telos_proxy.c - Prototypal Emulation Layer Implementation
   
   This file implements the TelosProxyObject structure and its associated
   behaviors, enabling true prototypal semantics across the C/Python bridge.
   
   The implementation follows the architectural mandate for prototypal behavior:
   objects delegate to prototypes via message passing, maintain local state
   for differential inheritance, and preserve identity across language boundaries.
*/

#include "telos_proxy.h"
#include "telos_proxy_internal.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef _WIN32
#include <windows.h>
#define getpid() GetCurrentProcessId()
#else
#include <unistd.h>
#endif

#ifndef Py_NewRef
#define Py_NewRef(obj) (Py_INCREF(obj), (obj))
#endif

#ifndef Py_XNewRef
#define Py_XNewRef(obj) ((obj) ? (Py_INCREF(obj), (obj)) : NULL)
#endif

// =============================================================================
// Forward Declarations
// =============================================================================

static PyObject* TelosProxy_GetMasterHandle(TelosProxyObject *self, PyObject *args);
static PyObject* TelosProxy_GetObjectId(TelosProxyObject *self, PyObject *args);
static PyObject* TelosProxy_GetLocalSlots(TelosProxyObject *self, PyObject *args);
static PyObject* TelosProxy_GetDispatchMetrics(TelosProxyObject *self, PyObject *args);
static PyObject* TelosProxy_ResetDispatchMetricsMethod(TelosProxyObject *self, PyObject *args);

static int TelosProxy_SetMetricStrict(PyObject *dict, const char *key, PyObject *value);
static int TelosProxy_SetMetricSilently(PyObject *dict, const char *key, PyObject *value);
static long long TelosProxy_ReadMetricLong(PyObject *dict, const char *key, long long fallback);
static double TelosProxy_ReadMetricDouble(PyObject *dict, const char *key, double fallback);
static int TelosProxy_EnsureMetricsInitialized(TelosProxyObject *self);
static int TelosProxy_UpdateHistory(TelosProxyObject *self, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text);
static PyObject* TelosProxy_CreateLatencyBuckets(void);
static PyObject* TelosProxy_GetLatencyBuckets(PyObject *metrics);
static int TelosProxy_UpdateLatencyBuckets(PyObject *metrics, double duration_ms);
static int TelosProxy_UpdateDurationExtremes(PyObject *metrics, double duration_ms);
static PyObject* TelosProxy_GetMessageStats(PyObject *metrics);
static PyObject* TelosProxy_GetOrCreateMessageEntry(PyObject *message_stats, const char *messageName);
static int TelosProxy_UpdateMessageStats(PyObject *metrics, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text);

static const double TELOS_PROXY_LATENCY_BOUNDS[] = {
    1.0,
    5.0,
    10.0,
    25.0,
    50.0,
    100.0,
    250.0,
    500.0,
    1000.0
};

static const char *TELOS_PROXY_LATENCY_LABELS[] = {
    "<=1ms",
    "<=5ms",
    "<=10ms",
    "<=25ms",
    "<=50ms",
    "<=100ms",
    "<=250ms",
    "<=500ms",
    "<=1000ms"
};

static const char *TELOS_PROXY_LATENCY_TERMINAL_LABEL = ">1000ms";

#define TELOS_PROXY_LATENCY_BUCKET_COUNT (sizeof(TELOS_PROXY_LATENCY_BOUNDS) / sizeof(double))

// =============================================================================
// Python Type Object Definition
// =============================================================================

// Method table for the proxy object - defined before type object
static PyMethodDef TelosProxy_methods[] = {
    {"clone", (PyCFunction)TelosProxy_Clone, METH_NOARGS, "Create a prototypal clone of this object"},
    {"getMasterHandle", (PyCFunction)TelosProxy_GetMasterHandle, METH_NOARGS, "Get the Io VM master handle"},
    {"getObjectId", (PyCFunction)TelosProxy_GetObjectId, METH_NOARGS, "Get the unique object identifier"},
    {"getLocalSlots", (PyCFunction)TelosProxy_GetLocalSlots, METH_NOARGS, "Get the local slots dictionary"},
    {"getDispatchMetrics", (PyCFunction)TelosProxy_GetDispatchMetrics, METH_NOARGS, "Copy of bridge dispatch metrics"},
    {"resetDispatchMetrics", (PyCFunction)TelosProxy_ResetDispatchMetricsMethod, METH_NOARGS, "Reset bridge dispatch metrics"},
    {NULL, NULL, 0, NULL}
};

/**
 * The Python type object for IoProxy.
 * 
 * This defines how Python interacts with TelosProxyObject instances,
 * setting up the method table, attribute access, and memory management.
 */
static PyTypeObject TelosProxyType = {
    PyVarObject_HEAD_INIT(NULL, 0)
    .tp_name = "telos_bridge.IoProxy",
    .tp_basicsize = sizeof(TelosProxyObject),
    .tp_itemsize = 0,
    .tp_flags = Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,
    .tp_doc = "IoProxy: Prototypal proxy for Io VM objects",
    .tp_dealloc = (destructor)TelosProxy_Dealloc,
    .tp_getattro = (getattrofunc)TelosProxy_GetAttr,
    .tp_setattro = (setattrofunc)TelosProxy_SetAttr,
    .tp_methods = TelosProxy_methods,
    .tp_new = PyType_GenericNew,
};

// =============================================================================
// Object Creation and Lifecycle Management
// =============================================================================

char* TelosProxy_GenerateObjectId(void) {
    // Generate a unique identifier using timestamp and process ID
    static unsigned long counter = 0;
    counter++;
    
    time_t now = time(NULL);
    unsigned long pid = (unsigned long)getpid();
    
    char *objectId = malloc(64);
    if (!objectId) {
        return NULL;
    }
    
    snprintf(objectId, 64, "proxy_%lu_%lu_%lu", now, pid, counter);
    return objectId;
}

TelosProxyObject* TelosProxy_CreateFromHandle(IoObjectHandle ioHandle, const char *objectId) {
    if (!ioHandle) {
        PyErr_SetString(PyExc_ValueError, "Cannot create proxy from NULL handle");
        return NULL;
    }
    
    // Pin the Io object to prevent garbage collection
    BridgeResult pinResult = bridge_pin_object(ioHandle);
    if (pinResult != BRIDGE_SUCCESS) {
        PyErr_SetString(PyExc_RuntimeError, "Failed to pin Io object for proxy creation");
        return NULL;
    }
    
    // Create the Python object
    TelosProxyObject *self = (TelosProxyObject *)TelosProxyType.tp_alloc(&TelosProxyType, 0);
    if (!self) {
        bridge_unpin_object(ioHandle);  // Cleanup on failure
        return NULL;
    }
    
    // Initialize the proxy fields
    self->ioMasterHandle = ioHandle;
    self->localSlots = PyDict_New();
    if (!self->localSlots) {
        Py_DECREF(self);
        bridge_unpin_object(ioHandle);
        return NULL;
    }

    self->dispatchMetrics = NULL;
    if (TelosProxy_ResetDispatchMetrics(self) != 0) {
        Py_DECREF(self);
        bridge_unpin_object(ioHandle);
        return NULL;
    }
    
    // Set up message forwarding
    self->forwardMessage = TelosProxy_DefaultForwardMessage;
    
    // Generate or copy object ID
    if (objectId) {
        self->objectId = malloc(strlen(objectId) + 1);
        if (self->objectId) {
            strcpy(self->objectId, objectId);
        }
    } else {
        self->objectId = TelosProxy_GenerateObjectId();
    }
    
    self->refCount = 1;
    
    return self;
}

void TelosProxy_Dealloc(TelosProxyObject *self) {
    if (!self) return;
    
    // Unpin the Io object handle
    if (self->ioMasterHandle) {
        bridge_unpin_object(self->ioMasterHandle);
        self->ioMasterHandle = NULL;
    }
    
    // Release local slots dictionary
    Py_XDECREF(self->localSlots);
    self->localSlots = NULL;
    
    Py_XDECREF(self->dispatchMetrics);
    self->dispatchMetrics = NULL;

    // Free object ID
    if (self->objectId) {
        free(self->objectId);
        self->objectId = NULL;
    }
    
    // Call Python's deallocation
    Py_TYPE(self)->tp_free((PyObject *)self);
}

// =============================================================================
// Prototypal Behavior Implementation
// =============================================================================

PyObject* TelosProxy_Clone(TelosProxyObject *self, PyObject *args) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }
    
    // Create a new proxy that delegates to the same master
    // but has independent local slots (true prototypal cloning)
    TelosProxyObject *clone = TelosProxy_CreateFromHandle(self->ioMasterHandle, NULL);
    if (!clone) {
        return NULL;
    }
    
    // The clone starts with empty local slots, implementing differential inheritance
    // Any changes to the clone will be stored in its local slots while still
    // delegating to the original master for unchanged behavior
    
    return (PyObject *)clone;
}

// =============================================================================
// Validation and Helper Functions
// =============================================================================

int TelosProxy_Validate(TelosProxyObject *self) {
    if (!self) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject is NULL");
        return 0;
    }
    
    if (!Py_IS_TYPE(self, &TelosProxyType)) {
        PyErr_SetString(PyExc_TypeError, "Object is not a TelosProxyObject");
        return 0;
    }
    
    if (!self->ioMasterHandle) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject has NULL master handle");
        return 0;
    }
    
    if (!self->localSlots || !PyDict_Check(self->localSlots)) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject has invalid local slots");
        return 0;
    }

    if (!self->dispatchMetrics || !PyDict_Check(self->dispatchMetrics)) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject has invalid dispatch metrics");
        return 0;
    }
    
    return 1; // Valid
}

// =============================================================================
// Python Type Registration
// =============================================================================

int TelosProxy_InitType(PyObject *module) {
    if (PyType_Ready(&TelosProxyType) < 0) {
        return -1;
    }
    
    Py_INCREF(&TelosProxyType);
    if (PyModule_AddObject(module, "IoProxy", (PyObject *)&TelosProxyType) < 0) {
        Py_DECREF(&TelosProxyType);
        return -1;
    }
    
    return 0;
}

// =============================================================================
// Dispatch Metrics Helpers
// =============================================================================

static PyObject* TelosProxy_CreateLatencyBuckets(void) {
    PyObject *buckets = PyDict_New();
    if (!buckets) {
        return NULL;
    }

    for (size_t idx = 0; idx < TELOS_PROXY_LATENCY_BUCKET_COUNT; ++idx) {
        if (TelosProxy_SetMetricStrict(buckets, TELOS_PROXY_LATENCY_LABELS[idx], PyLong_FromLong(0)) != 0) {
            Py_DECREF(buckets);
            return NULL;
        }
    }

    if (TelosProxy_SetMetricStrict(buckets, TELOS_PROXY_LATENCY_TERMINAL_LABEL, PyLong_FromLong(0)) != 0) {
        Py_DECREF(buckets);
        return NULL;
    }

    return buckets;
}

static PyObject* TelosProxy_GetLatencyBuckets(PyObject *metrics) {
    if (!metrics || !PyDict_Check(metrics)) {
        return NULL;
    }

    PyObject *latencyBuckets = PyDict_GetItemString(metrics, "latencyBuckets");
    if (latencyBuckets && PyDict_Check(latencyBuckets)) {
        return latencyBuckets;
    }

    PyObject *fresh = TelosProxy_CreateLatencyBuckets();
    if (!fresh) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "latencyBucketsInit");
        PyErr_Clear();
        return NULL;
    }

    if (TelosProxy_SetMetricSilently(metrics, "latencyBuckets", fresh) != 0) {
        return NULL;
    }

    return PyDict_GetItemString(metrics, "latencyBuckets");
}

static int TelosProxy_UpdateLatencyBuckets(PyObject *metrics, double duration_ms) {
    PyObject *latencyBuckets = TelosProxy_GetLatencyBuckets(metrics);
    if (!latencyBuckets || !PyDict_Check(latencyBuckets)) {
        return -1;
    }

    const char *bucket_label = TELOS_PROXY_LATENCY_TERMINAL_LABEL;
    for (size_t idx = 0; idx < TELOS_PROXY_LATENCY_BUCKET_COUNT; ++idx) {
        if (duration_ms <= TELOS_PROXY_LATENCY_BOUNDS[idx]) {
            bucket_label = TELOS_PROXY_LATENCY_LABELS[idx];
            break;
        }
    }

    PyObject *current = PyDict_GetItemString(latencyBuckets, bucket_label);
    long long count = 0;
    if (current) {
        count = PyLong_AsLongLong(current);
        if (PyErr_Occurred()) {
            PyErr_Clear();
            count = 0;
        }
    }

    if (TelosProxy_SetMetricSilently(latencyBuckets, bucket_label, PyLong_FromLongLong(count + 1)) != 0) {
        return -1;
    }

    return 0;
}

static int TelosProxy_UpdateDurationExtremes(PyObject *metrics, double duration_ms) {
    if (!metrics || !PyDict_Check(metrics)) {
        return -1;
    }

    PyObject *min_obj = PyDict_GetItemString(metrics, "minDurationMs");
    int has_min = (min_obj && min_obj != Py_None);
    double min_value = 0.0;
    if (has_min) {
        min_value = PyFloat_AsDouble(min_obj);
        if (PyErr_Occurred()) {
            PyErr_Clear();
            has_min = 0;
        }
    }

    if (!has_min || duration_ms < min_value) {
        if (TelosProxy_SetMetricSilently(metrics, "minDurationMs", PyFloat_FromDouble(duration_ms)) != 0) {
            return -1;
        }
    }

    PyObject *max_obj = PyDict_GetItemString(metrics, "maxDurationMs");
    int has_max = (max_obj && max_obj != Py_None);
    double max_value = 0.0;
    if (has_max) {
        max_value = PyFloat_AsDouble(max_obj);
        if (PyErr_Occurred()) {
            PyErr_Clear();
            has_max = 0;
        }
    }

    if (!has_max || duration_ms > max_value) {
        if (TelosProxy_SetMetricSilently(metrics, "maxDurationMs", PyFloat_FromDouble(duration_ms)) != 0) {
            return -1;
        }
    }

    return 0;
}

static PyObject* TelosProxy_GetMessageStats(PyObject *metrics) {
    if (!metrics || !PyDict_Check(metrics)) {
        return NULL;
    }

    PyObject *messageStats = PyDict_GetItemString(metrics, "messageStats");
    if (messageStats && PyDict_Check(messageStats)) {
        return messageStats;
    }

    PyObject *fresh = PyDict_New();
    if (!fresh) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "messageStatsInit");
        PyErr_Clear();
        return NULL;
    }

    if (TelosProxy_SetMetricSilently(metrics, "messageStats", fresh) != 0) {
        return NULL;
    }

    return PyDict_GetItemString(metrics, "messageStats");
}

static PyObject* TelosProxy_GetOrCreateMessageEntry(PyObject *message_stats, const char *messageName) {
    if (!message_stats || !PyDict_Check(message_stats)) {
        return NULL;
    }

    const char *key = messageName ? messageName : "<null>";
    PyObject *entry = PyDict_GetItemString(message_stats, key);
    if (entry && PyDict_Check(entry)) {
        return entry;
    }

    PyObject *fresh = PyDict_New();
    if (!fresh) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "messageEntryInit");
        PyErr_Clear();
        return NULL;
    }

    if (TelosProxy_SetMetricStrict(fresh, "invocations", PyLong_FromLong(0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "failures", PyLong_FromLong(0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "cumulativeDurationMs", PyFloat_FromDouble(0.0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "averageDurationMs", PyFloat_FromDouble(0.0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "lastDurationMs", PyFloat_FromDouble(0.0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "failureRate", PyFloat_FromDouble(0.0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "successRate", PyFloat_FromDouble(1.0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "successStreak", PyLong_FromLong(0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "lastTimestamp", PyFloat_FromDouble(0.0)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "lastOutcome", PyUnicode_FromString("n/a")) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "lastError", Py_NewRef(Py_None)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "minDurationMs", Py_NewRef(Py_None)) != 0) goto error;
    if (TelosProxy_SetMetricStrict(fresh, "maxDurationMs", PyFloat_FromDouble(0.0)) != 0) goto error;

    if (PyDict_SetItemString(message_stats, key, fresh) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "messageEntryStore");
        PyErr_Clear();
        goto error;
    }

    Py_DECREF(fresh);
    return PyDict_GetItemString(message_stats, key);

error:
    Py_DECREF(fresh);
    return NULL;
}

static int TelosProxy_UpdateMessageStats(PyObject *metrics, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text) {
    PyObject *message_stats = TelosProxy_GetMessageStats(metrics);
    if (!message_stats) {
        return -1;
    }

    PyObject *entry = TelosProxy_GetOrCreateMessageEntry(message_stats, messageName);
    if (!entry || !PyDict_Check(entry)) {
        return -1;
    }

    long long prior_invocations = TelosProxy_ReadMetricLong(entry, "invocations", 0);
    long long prior_failures = TelosProxy_ReadMetricLong(entry, "failures", 0);
    double prior_cumulative = TelosProxy_ReadMetricDouble(entry, "cumulativeDurationMs", 0.0);
    long long prior_streak = TelosProxy_ReadMetricLong(entry, "successStreak", 0);

    long long new_invocations = prior_invocations + 1;
    long long new_failures = prior_failures + (success ? 0 : 1);
    double new_cumulative = prior_cumulative + duration_ms;
    double failure_rate = new_invocations > 0 ? (double)new_failures / (double)new_invocations : 0.0;
    if (failure_rate < 0.0) failure_rate = 0.0;
    if (failure_rate > 1.0) failure_rate = 1.0;
    double success_rate = 1.0 - failure_rate;
    if (success_rate < 0.0) success_rate = 0.0;
    if (success_rate > 1.0) success_rate = 1.0;
    double average = new_invocations > 0 ? new_cumulative / (double)new_invocations : 0.0;
    long long new_streak = success ? (prior_streak + 1) : 0;

    TelosProxy_SetMetricSilently(entry, "invocations", PyLong_FromLongLong(new_invocations));
    TelosProxy_SetMetricSilently(entry, "failures", PyLong_FromLongLong(new_failures));
    TelosProxy_SetMetricSilently(entry, "cumulativeDurationMs", PyFloat_FromDouble(new_cumulative));
    TelosProxy_SetMetricSilently(entry, "averageDurationMs", PyFloat_FromDouble(average));
    TelosProxy_SetMetricSilently(entry, "lastDurationMs", PyFloat_FromDouble(duration_ms));
    TelosProxy_SetMetricSilently(entry, "failureRate", PyFloat_FromDouble(failure_rate));
    TelosProxy_SetMetricSilently(entry, "successRate", PyFloat_FromDouble(success_rate));
    TelosProxy_SetMetricSilently(entry, "successStreak", PyLong_FromLongLong(new_streak));
    TelosProxy_SetMetricSilently(entry, "lastTimestamp", PyFloat_FromDouble(timestamp_s));
    TelosProxy_SetMetricSilently(entry, "lastOutcome", PyUnicode_FromString(success ? "success" : "failure"));

    if (error_text && !success) {
        TelosProxy_SetMetricSilently(entry, "lastError", Py_NewRef(error_text));
    } else {
        TelosProxy_SetMetricSilently(entry, "lastError", Py_NewRef(Py_None));
    }

    if (TelosProxy_UpdateDurationExtremes(entry, duration_ms) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "messageDurationExtremes");
        PyErr_Clear();
    }

    return 0;
}

static int TelosProxy_SetMetricStrict(PyObject *dict, const char *key, PyObject *value) {
    if (!dict || !value) {
        Py_XDECREF(value);
        return -1;
    }

    if (PyDict_SetItemString(dict, key, value) != 0) {
        Py_DECREF(value);
        return -1;
    }

    Py_DECREF(value);
    return 0;
}

static int TelosProxy_SetMetricSilently(PyObject *dict, const char *key, PyObject *value) {
    if (!dict) {
        Py_XDECREF(value);
        return -1;
    }

    if (!value) {
        TelosProxy_WriteUnraisable("dispatchMetrics", key);
        PyErr_Clear();
        return -1;
    }

    if (PyDict_SetItemString(dict, key, value) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", key);
        PyErr_Clear();
        Py_DECREF(value);
        return -1;
    }

    Py_DECREF(value);
    return 0;
}

static long long TelosProxy_ReadMetricLong(PyObject *dict, const char *key, long long fallback) {
    if (!dict) {
        return fallback;
    }

    PyObject *item = PyDict_GetItemString(dict, key);
    if (!item) {
        return fallback;
    }

    long long result = PyLong_AsLongLong(item);
    if (PyErr_Occurred()) {
        PyErr_Clear();
        return fallback;
    }

    return result;
}

static double TelosProxy_ReadMetricDouble(PyObject *dict, const char *key, double fallback) {
    if (!dict) {
        return fallback;
    }

    PyObject *item = PyDict_GetItemString(dict, key);
    if (!item) {
        return fallback;
    }

    double result = PyFloat_AsDouble(item);
    if (PyErr_Occurred()) {
        PyErr_Clear();
        return fallback;
    }

    return result;
}

static int TelosProxy_EnsureMetricsInitialized(TelosProxyObject *self) {
    if (!self) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject is NULL");
        return -1;
    }

    if (self->dispatchMetrics && PyDict_Check(self->dispatchMetrics)) {
        return 0;
    }

    Py_XDECREF(self->dispatchMetrics);
    self->dispatchMetrics = NULL;
    return TelosProxy_ResetDispatchMetrics(self);
}

int TelosProxy_ResetDispatchMetrics(TelosProxyObject *self) {
    if (!self) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject is NULL");
        return -1;
    }

    if (self->dispatchMetrics && !PyDict_Check(self->dispatchMetrics)) {
        Py_DECREF(self->dispatchMetrics);
        self->dispatchMetrics = NULL;
    }

    if (!self->dispatchMetrics) {
        self->dispatchMetrics = PyDict_New();
        if (!self->dispatchMetrics) {
            return -1;
        }
    } else {
        PyDict_Clear(self->dispatchMetrics);
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "invocations", PyLong_FromLong(0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "failures", PyLong_FromLong(0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "cumulativeDurationMs", PyFloat_FromDouble(0.0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "averageDurationMs", PyFloat_FromDouble(0.0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "lastDurationMs", PyFloat_FromDouble(0.0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "failureRate", PyFloat_FromDouble(0.0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "successRate", PyFloat_FromDouble(1.0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "successStreak", PyLong_FromLong(0)) != 0) {
        goto error;
    }
    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "recentLimit", PyLong_FromLong(16)) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "recent", PyList_New(0)) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "lastTimestamp", PyFloat_FromDouble(0.0)) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "lastOutcome", PyUnicode_FromString("n/a")) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "lastMessage", Py_NewRef(Py_None)) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "lastError", Py_NewRef(Py_None)) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "minDurationMs", Py_NewRef(Py_None)) != 0) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "maxDurationMs", PyFloat_FromDouble(0.0)) != 0) {
        goto error;
    }

    PyObject *latencyBuckets = TelosProxy_CreateLatencyBuckets();
    if (!latencyBuckets) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "latencyBuckets", latencyBuckets) != 0) {
        goto error;
    }

    PyObject *messageStats = PyDict_New();
    if (!messageStats) {
        goto error;
    }

    if (TelosProxy_SetMetricStrict(self->dispatchMetrics, "messageStats", messageStats) != 0) {
        goto error;
    }

    return 0;

error:
    Py_CLEAR(self->dispatchMetrics);
    return -1;
}

PyObject* TelosProxy_CopyDispatchMetrics(TelosProxyObject *self) {
    if (TelosProxy_EnsureMetricsInitialized(self) != 0) {
        return NULL;
    }

    return PyDict_Copy(self->dispatchMetrics);
}

static PyObject* TelosProxy_GetDispatchMetrics(TelosProxyObject *self, PyObject *args) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }

    return TelosProxy_CopyDispatchMetrics(self);
}

static PyObject* TelosProxy_ResetDispatchMetricsMethod(TelosProxyObject *self, PyObject *args) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }

    if (TelosProxy_ResetDispatchMetrics(self) != 0) {
        return NULL;
    }

    Py_RETURN_NONE;
}

static int TelosProxy_UpdateHistory(TelosProxyObject *self, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text) {
    if (!self || TelosProxy_EnsureMetricsInitialized(self) != 0) {
        return -1;
    }

    PyObject *metrics = self->dispatchMetrics;
    PyObject *recent = PyDict_GetItemString(metrics, "recent");
    if (!recent || !PyList_Check(recent)) {
        if (TelosProxy_SetMetricSilently(metrics, "recent", PyList_New(0)) != 0) {
            return -1;
        }
        recent = PyDict_GetItemString(metrics, "recent");
    }

    PyObject *entry = PyDict_New();
    if (!entry) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "recentEntry");
        PyErr_Clear();
        return -1;
    }

    TelosProxy_SetMetricSilently(entry, "message", PyUnicode_FromString(messageName ? messageName : "<null>"));
    TelosProxy_SetMetricSilently(entry, "success", PyBool_FromLong(success));
    TelosProxy_SetMetricSilently(entry, "durationMs", PyFloat_FromDouble(duration_ms));
    TelosProxy_SetMetricSilently(entry, "timestamp", PyFloat_FromDouble(timestamp_s));

    if (!success && error_text) {
        TelosProxy_SetMetricSilently(entry, "error", Py_NewRef(error_text));
    }

    if (PyList_Append(recent, entry) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "recentAppend");
        PyErr_Clear();
        Py_DECREF(entry);
        return -1;
    }

    Py_DECREF(entry);

    long long limit = TelosProxy_ReadMetricLong(metrics, "recentLimit", 16);
    if (limit < 1) {
        limit = 1;
    }

    while (1) {
        Py_ssize_t current_size = PyList_Size(recent);
        if (current_size < 0) {
            PyErr_Clear();
            break;
        }

        if ((long long)current_size <= limit) {
            break;
        }

        if (PySequence_DelItem(recent, 0) != 0) {
            TelosProxy_WriteUnraisable("dispatchMetrics", "recentTrim");
            PyErr_Clear();
            break;
        }
    }

    return 0;
}

int TelosProxy_RecordDispatch(TelosProxyObject *self, const char *messageName, int success, double duration_ms, double timestamp_s, PyObject *error_text) {
    if (TelosProxy_EnsureMetricsInitialized(self) != 0) {
        return -1;
    }

    PyObject *metrics = self->dispatchMetrics;

    if (duration_ms < 0.0) {
        duration_ms = 0.0;
    }

    long long prior_invocations = TelosProxy_ReadMetricLong(metrics, "invocations", 0);
    long long prior_failures = TelosProxy_ReadMetricLong(metrics, "failures", 0);
    double prior_cumulative = TelosProxy_ReadMetricDouble(metrics, "cumulativeDurationMs", 0.0);
    long long prior_streak = TelosProxy_ReadMetricLong(metrics, "successStreak", 0);

    long long new_invocations = prior_invocations + 1;
    long long new_failures = prior_failures + (success ? 0 : 1);
    double new_cumulative = prior_cumulative + duration_ms;
    double failure_rate = new_invocations > 0 ? (double)new_failures / (double)new_invocations : 0.0;
    if (failure_rate < 0.0) {
        failure_rate = 0.0;
    }
    if (failure_rate > 1.0) {
        failure_rate = 1.0;
    }
    double success_rate = 1.0 - failure_rate;
    if (success_rate < 0.0) {
        success_rate = 0.0;
    }
    if (success_rate > 1.0) {
        success_rate = 1.0;
    }
    double average = new_invocations > 0 ? new_cumulative / (double)new_invocations : 0.0;
    long long new_streak = success ? (prior_streak + 1) : 0;

    TelosProxy_SetMetricSilently(metrics, "invocations", PyLong_FromLongLong(new_invocations));
    TelosProxy_SetMetricSilently(metrics, "failures", PyLong_FromLongLong(new_failures));
    TelosProxy_SetMetricSilently(metrics, "cumulativeDurationMs", PyFloat_FromDouble(new_cumulative));
    TelosProxy_SetMetricSilently(metrics, "averageDurationMs", PyFloat_FromDouble(average));
    TelosProxy_SetMetricSilently(metrics, "lastDurationMs", PyFloat_FromDouble(duration_ms));
    TelosProxy_SetMetricSilently(metrics, "failureRate", PyFloat_FromDouble(failure_rate));
    TelosProxy_SetMetricSilently(metrics, "successRate", PyFloat_FromDouble(success_rate));
    TelosProxy_SetMetricSilently(metrics, "successStreak", PyLong_FromLongLong(new_streak));

    if (TelosProxy_UpdateDurationExtremes(metrics, duration_ms) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "durationExtremes");
        PyErr_Clear();
    }

    if (TelosProxy_UpdateLatencyBuckets(metrics, duration_ms) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "latencyBucketsUpdate");
        PyErr_Clear();
    }

    TelosProxy_SetMetricSilently(metrics, "lastMessage", PyUnicode_FromString(messageName ? messageName : "<null>"));
    TelosProxy_SetMetricSilently(metrics, "lastOutcome", PyUnicode_FromString(success ? "success" : "failure"));
    TelosProxy_SetMetricSilently(metrics, "lastTimestamp", PyFloat_FromDouble(timestamp_s));

    if (error_text) {
        TelosProxy_SetMetricSilently(metrics, "lastError", Py_NewRef(error_text));
    } else {
        TelosProxy_SetMetricSilently(metrics, "lastError", Py_NewRef(Py_None));
    }

    if (TelosProxy_UpdateMessageStats(metrics, messageName, success, duration_ms, timestamp_s, error_text) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "messageStatsUpdate");
        PyErr_Clear();
    }

    TelosProxy_UpdateHistory(self, messageName, success, duration_ms, timestamp_s, error_text);

    return 0;
}

// Additional Methods for Future Extensions
// =============================================================================

/**
 * Get the master handle for inspection (debugging/internal use)
 */
static PyObject* TelosProxy_GetMasterHandle(TelosProxyObject *self, PyObject *args) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }
    
    return PyLong_FromVoidPtr(self->ioMasterHandle);
}

/**
 * Get the object ID for tracking purposes
 */
static PyObject* TelosProxy_GetObjectId(TelosProxyObject *self, PyObject *args) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }
    
    if (self->objectId) {
        return PyUnicode_FromString(self->objectId);
    }
    
    Py_RETURN_NONE;
}

/**
 * Get local slots dictionary for inspection
 */
static PyObject* TelosProxy_GetLocalSlots(TelosProxyObject *self, PyObject *args) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }
    
    Py_INCREF(self->localSlots);
    return self->localSlots;
}
