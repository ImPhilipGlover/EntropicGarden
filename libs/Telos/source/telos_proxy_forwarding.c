/*
   telos_proxy_forwarding.c - Shared-memory forwarding and slot propagation

   This module concentrates the Telos proxy forwarding logic, keeping the
   core proxy definition lean while preserving prototypal behavior across
   the Synaptic Bridge.
*/

#include "telos_proxy_internal.h"

#include <stdbool.h>
#include <string.h>
#ifdef _WIN32
#include <windows.h>
#else
#include <time.h>
#include <sys/time.h>
#endif

static PyObject *s_json_module = NULL;
static PyObject *s_json_dumps = NULL;
static PyObject *s_json_loads = NULL;

static int ensure_json_helpers(void);
static PyObject* normalize_args_sequence(PyObject *args);
static PyObject* decode_bytes_like(PyObject *item);
static PyObject* read_utf8_from_shared_memory(const SharedMemoryHandle *handle);
static int write_bytes_to_shared_memory(const SharedMemoryHandle *handle, const char *payload, size_t length);
static void set_bridge_python_error(const char *context, BridgeResult status);
static void TelosProxy_TriggerDoesNotUnderstand(TelosProxyObject *self, const char *slot_name, PyObject *error_message);
static double telos_proxy_monotonic_ms(void);
static double telos_proxy_system_seconds(void);
static PyObject* telos_proxy_capture_error_string(void);

PyObject* TelosProxy_DefaultForwardMessage(IoObjectHandle handle, const char *messageName, PyObject *args) {
    if (handle == NULL || messageName == NULL) {
        PyErr_SetString(PyExc_ValueError, "Invalid handle or message name for forwarding");
        return NULL;
    }

    if (ensure_json_helpers() != 0) {
        return NULL;
    }

    PyObject *normalized_args = NULL;
    PyObject *args_json = NULL;
    PyObject *response_text = NULL;
    PyObject *result_object = NULL;

    SharedMemoryHandle args_handle = (SharedMemoryHandle){0};
    SharedMemoryHandle result_handle = (SharedMemoryHandle){0};
    bool args_handle_created = false;
    bool result_handle_created = false;

    normalized_args = normalize_args_sequence(args);
    if (normalized_args == NULL) {
        goto cleanup;
    }

    args_json = PyObject_CallFunctionObjArgs(s_json_dumps, normalized_args, NULL);
    if (args_json == NULL) {
        goto cleanup;
    }

    Py_ssize_t args_length = 0;
    const char *args_payload = PyUnicode_AsUTF8AndSize(args_json, &args_length);
    if (args_payload == NULL) {
        goto cleanup;
    }

    size_t args_buffer_size = (size_t)args_length + 1;
    if (args_buffer_size < 64) {
        args_buffer_size = 64;
    }

    BridgeResult status = bridge_create_shared_memory(args_buffer_size, &args_handle);
    if (status != BRIDGE_SUCCESS) {
        set_bridge_python_error("bridge_create_shared_memory", status);
        goto cleanup;
    }
    args_handle_created = true;

    if (write_bytes_to_shared_memory(&args_handle, args_payload, (size_t)args_length) != 0) {
        goto cleanup;
    }

    size_t result_buffer_size = 4096;
    const size_t max_result_buffer = (size_t)1 << 20;

    while (true) {
        status = bridge_create_shared_memory(result_buffer_size, &result_handle);
        if (status != BRIDGE_SUCCESS) {
            set_bridge_python_error("bridge_create_shared_memory", status);
            goto cleanup;
        }
        result_handle_created = true;

        status = bridge_send_message(handle, messageName, &args_handle, &result_handle);
        if (status == BRIDGE_SUCCESS) {
            break;
        }

        char error_buffer[1024] = {0};
        BridgeResult err_status = bridge_get_last_error(error_buffer, sizeof(error_buffer));
        const char *detail = (err_status == BRIDGE_SUCCESS && error_buffer[0] != '\0') ? error_buffer : NULL;

        bridge_destroy_shared_memory(&result_handle);
        memset(&result_handle, 0, sizeof(result_handle));
        result_handle_created = false;

        if (status == BRIDGE_ERROR_SHARED_MEMORY && detail && strstr(detail, "Result buffer too small") && result_buffer_size < max_result_buffer) {
            result_buffer_size *= 2;
            continue;
        }

        if (detail) {
            PyErr_Format(PyExc_RuntimeError, "bridge_send_message failed (%d): %s", status, detail);
        } else {
            set_bridge_python_error("bridge_send_message", status);
        }
        goto cleanup;
    }

    response_text = read_utf8_from_shared_memory(&result_handle);
    if (response_text == NULL) {
        goto cleanup;
    }

    result_object = PyObject_CallFunctionObjArgs(s_json_loads, response_text, NULL);
    if (result_object == NULL) {
        PyErr_Clear();
        Py_INCREF(response_text);
        result_object = response_text;
    }

cleanup:
    if (args_handle_created) {
        bridge_destroy_shared_memory(&args_handle);
        memset(&args_handle, 0, sizeof(args_handle));
    }
    if (result_handle_created) {
        bridge_destroy_shared_memory(&result_handle);
        memset(&result_handle, 0, sizeof(result_handle));
    }

    Py_XDECREF(normalized_args);
    Py_XDECREF(args_json);
    Py_XDECREF(response_text);

    if (PyErr_Occurred()) {
        Py_XDECREF(result_object);
        return NULL;
    }

    return result_object;
}

PyObject* TelosProxy_InvokeForwardMessage(TelosProxyObject *self, const char *messageName, PyObject *args) {
    if (!self || self->forwardMessage == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "TelosProxyObject is missing forward handler");
        return NULL;
    }

    double start_ms = telos_proxy_monotonic_ms();
    double timestamp_s = telos_proxy_system_seconds();

    PyObject *result = self->forwardMessage(self->ioMasterHandle, messageName, args);

    double elapsed_ms = telos_proxy_monotonic_ms() - start_ms;
    if (elapsed_ms < 0.0) {
        elapsed_ms = 0.0;
    }

    PyObject *error_text = NULL;
    if (!result && PyErr_Occurred()) {
        error_text = telos_proxy_capture_error_string();
    }

    TelosProxy_RecordDispatch(self, messageName, result != NULL, elapsed_ms, timestamp_s, error_text);

    Py_XDECREF(error_text);
    return result;
}

PyObject* TelosProxy_GetAttr(TelosProxyObject *self, PyObject *name) {
    if (!TelosProxy_Validate(self)) {
        return NULL;
    }

    const char *attrName = PyUnicode_AsUTF8(name);
    if (!attrName) {
        return NULL;
    }

    if (PyDict_Contains(self->localSlots, name)) {
        PyObject *value = PyDict_GetItem(self->localSlots, name);
        Py_INCREF(value);
        return value;
    }

    if (self->forwardMessage) {
        PyObject *result = TelosProxy_InvokeForwardMessage(self, attrName, NULL);
        if (result) {
            return result;
        }

        if (PyErr_Occurred()) {
            PyObject *forward_type = NULL;
            PyObject *forward_value = NULL;
            PyObject *forward_trace = NULL;
            PyErr_Fetch(&forward_type, &forward_value, &forward_trace);

            PyObject *generic_value = PyObject_GenericGetAttr((PyObject *)self, name);
            if (generic_value) {
                Py_XDECREF(forward_type);
                Py_XDECREF(forward_value);
                Py_XDECREF(forward_trace);
                return generic_value;
            }

            PyObject *generic_type = NULL;
            PyObject *generic_value_obj = NULL;
            PyObject *generic_trace = NULL;
            PyErr_Fetch(&generic_type, &generic_value_obj, &generic_trace);

            int handled = TelosProxy_HandleForwardFailure(self, attrName, forward_type, forward_value, forward_trace);

            Py_XDECREF(generic_type);
            Py_XDECREF(generic_value_obj);
            Py_XDECREF(generic_trace);

            if (!handled) {
                PyErr_Restore(forward_type, forward_value, forward_trace);
            } else {
                Py_XDECREF(forward_type);
                Py_XDECREF(forward_value);
                Py_XDECREF(forward_trace);
            }
            return NULL;
        }
    }

    return PyObject_GenericGetAttr((PyObject *)self, name);
}

int TelosProxy_SetAttr(TelosProxyObject *self, PyObject *name, PyObject *value) {
    if (!TelosProxy_Validate(self)) {
        return -1;
    }

    if (!PyUnicode_Check(name)) {
        PyErr_SetString(PyExc_TypeError, "Attribute name must be a string");
        return -1;
    }
    const char *slot_name = PyUnicode_AsUTF8(name);
    if (!slot_name) {
        return -1;
    }

    if (value == NULL) {
        int del_result = PyDict_DelItem(self->localSlots, name);
        if (del_result != 0) {
            if (PyErr_ExceptionMatches(PyExc_KeyError)) {
                PyObject *msg = PyUnicode_FromFormat("IoProxy has no slot '%s'", slot_name);
                PyErr_SetObject(PyExc_AttributeError, msg);
                Py_XDECREF(msg);
            }
            return -1;
        }

        if (TelosProxy_PropagateSlotDeletion(self, slot_name) != 0) {
            if (PyErr_Occurred()) {
                TelosProxy_WriteUnraisable("removeSlot", slot_name);
            }
        }
        return 0;
    }

    int result = PyDict_SetItem(self->localSlots, name, value);

    if (result != 0) {
        return result;
    }

    if (TelosProxy_PropagateSlotUpdate(self, slot_name, value) != 0) {
        if (PyErr_Occurred()) {
            TelosProxy_WriteUnraisable("setSlot", slot_name);
        }
    }

    return 0;
}

void TelosProxy_WriteUnraisable(const char *operation, const char *slot_name) {
    if (!PyErr_Occurred()) {
        return;
    }

    PyObject *context = NULL;
    if (operation && slot_name) {
        context = PyUnicode_FromFormat("IoProxy.%s('%s')", operation, slot_name);
    } else if (operation) {
        context = PyUnicode_FromFormat("IoProxy.%s", operation);
    }

    if (context) {
        PyErr_WriteUnraisable(context);
        Py_DECREF(context);
    } else {
        PyErr_WriteUnraisable(Py_None);
    }
}

int TelosProxy_HandleForwardFailure(TelosProxyObject *self, const char *attr_name, PyObject *err_type, PyObject *err_value, PyObject *err_trace) {
    (void)err_trace;

    int handled = 0;
    PyObject *error_string_obj = NULL;
    const char *error_cstring = NULL;

    if (err_value) {
        error_string_obj = PyObject_Str(err_value);
        if (error_string_obj) {
            error_cstring = PyUnicode_AsUTF8(error_string_obj);
        }
    }

    int is_missing_slot = 0;
    if (err_type && PyErr_GivenExceptionMatches(err_type, PyExc_AttributeError)) {
        is_missing_slot = 1;
    } else if (error_cstring && strstr(error_cstring, "not found")) {
        is_missing_slot = 1;
    }

    if (is_missing_slot) {
        PyObject *error_message = NULL;
        if (error_string_obj) {
            Py_INCREF(error_string_obj);
            error_message = error_string_obj;
        }

        TelosProxy_TriggerDoesNotUnderstand(self, attr_name, error_message);
        Py_XDECREF(error_message);

        PyObject *msg = PyUnicode_FromFormat("IoProxy has no slot '%s'", attr_name);
        if (msg) {
            PyErr_SetObject(PyExc_AttributeError, msg);
            Py_DECREF(msg);
        } else {
            PyErr_SetString(PyExc_AttributeError, "IoProxy slot lookup failed");
        }
        handled = 1;
    }

    Py_XDECREF(error_string_obj);
    return handled;
}

int TelosProxy_PropagateSlotUpdate(TelosProxyObject *self, const char *slot_name, PyObject *value) {
    if (self == NULL || self->forwardMessage == NULL || slot_name == NULL) {
        return 0;
    }

    PyObject *slot_py = PyUnicode_FromString(slot_name);
    if (slot_py == NULL) {
        return -1;
    }

    PyObject *args_tuple = PyTuple_New(2);
    if (args_tuple == NULL) {
        Py_DECREF(slot_py);
        return -1;
    }

    PyTuple_SET_ITEM(args_tuple, 0, slot_py);
    Py_INCREF(value);
    PyTuple_SET_ITEM(args_tuple, 1, value);

    PyObject *result = TelosProxy_InvokeForwardMessage(self, "setSlot", args_tuple);
    Py_XDECREF(result);
    Py_DECREF(args_tuple);

    if (result == NULL && PyErr_Occurred()) {
        return -1;
    }
    return 0;
}

int TelosProxy_PropagateSlotDeletion(TelosProxyObject *self, const char *slot_name) {
    if (self == NULL || self->forwardMessage == NULL || slot_name == NULL) {
        return 0;
    }

    PyObject *slot_py = PyUnicode_FromString(slot_name);
    if (slot_py == NULL) {
        return -1;
    }

    PyObject *args_tuple = PyTuple_New(1);
    if (args_tuple == NULL) {
        Py_DECREF(slot_py);
        return -1;
    }

    PyTuple_SET_ITEM(args_tuple, 0, slot_py);

    PyObject *result = TelosProxy_InvokeForwardMessage(self, "removeSlot", args_tuple);
    Py_XDECREF(result);
    Py_DECREF(args_tuple);

    if (result == NULL && PyErr_Occurred()) {
        return -1;
    }
    return 0;
}

static void TelosProxy_TriggerDoesNotUnderstand(TelosProxyObject *self, const char *slot_name, PyObject *error_message) {
    if (self == NULL || self->forwardMessage == NULL || slot_name == NULL) {
        return;
    }

    PyObject *payload = PyDict_New();
    if (payload == NULL) {
        PyErr_Clear();
        return;
    }

    PyObject *slot_value = PyUnicode_FromString(slot_name);
    if (slot_value && PyDict_SetItemString(payload, "slot", slot_value) != 0) {
        Py_DECREF(slot_value);
        Py_DECREF(payload);
        PyErr_Clear();
        return;
    }
    Py_XDECREF(slot_value);

    if (self->objectId) {
        PyObject *object_id = PyUnicode_FromString(self->objectId);
        if (object_id) {
            if (PyDict_SetItemString(payload, "objectId", object_id) != 0) {
                Py_DECREF(object_id);
                Py_DECREF(payload);
                PyErr_Clear();
                return;
            }
            Py_DECREF(object_id);
        } else {
            PyErr_Clear();
        }
    }

    if (error_message) {
        if (PyDict_SetItemString(payload, "error", error_message) != 0) {
            Py_DECREF(payload);
            PyErr_Clear();
            return;
        }
    }

    PyObject *args_tuple = PyTuple_New(1);
    if (args_tuple == NULL) {
        Py_DECREF(payload);
        PyErr_Clear();
        return;
    }

    PyTuple_SET_ITEM(args_tuple, 0, payload);

    PyObject *result = TelosProxy_InvokeForwardMessage(self, "proxyDidNotUnderstand_", args_tuple);
    Py_XDECREF(result);
    Py_DECREF(args_tuple);

    if (PyErr_Occurred()) {
        TelosProxy_WriteUnraisable("proxyDidNotUnderstand_", slot_name);
    }
}

static int ensure_json_helpers(void) {
    if (s_json_dumps != NULL && s_json_loads != NULL) {
        return 0;
    }

    PyObject *module = PyImport_ImportModule("json");
    if (module == NULL) {
        return -1;
    }

    PyObject *dumps = PyObject_GetAttrString(module, "dumps");
    if (dumps == NULL) {
        Py_DECREF(module);
        return -1;
    }

    PyObject *loads = PyObject_GetAttrString(module, "loads");
    if (loads == NULL) {
        Py_DECREF(module);
        Py_DECREF(dumps);
        return -1;
    }

    s_json_module = module;
    s_json_dumps = dumps;
    s_json_loads = loads;
    return 0;
}

static PyObject* decode_bytes_like(PyObject *item) {
    if (PyBytes_Check(item)) {
        return PyUnicode_DecodeUTF8(PyBytes_AS_STRING(item), PyBytes_GET_SIZE(item), "replace");
    }

    if (PyByteArray_Check(item)) {
        return PyUnicode_DecodeUTF8(PyByteArray_AS_STRING(item), PyByteArray_GET_SIZE(item), "replace");
    }

    Py_INCREF(item);
    return item;
}

static PyObject* normalize_args_sequence(PyObject *args) {
    if (args == NULL || args == Py_None) {
        return PyList_New(0);
    }

    if (PyUnicode_Check(args) || PyBytes_Check(args) || PyByteArray_Check(args)) {
        PyObject *single_list = PyList_New(1);
        if (single_list == NULL) {
            return NULL;
        }
        PyObject *normalized = decode_bytes_like(args);
        if (normalized == NULL) {
            Py_DECREF(single_list);
            return NULL;
        }
        PyList_SET_ITEM(single_list, 0, normalized);
        return single_list;
    }

    PyObject *sequence = NULL;
    if (PyTuple_Check(args) || PyList_Check(args)) {
        sequence = PySequence_Fast(args, "Expected iterable arguments");
    } else if (PySequence_Check(args)) {
        sequence = PySequence_Fast(args, "Expected iterable arguments");
    }

    if (sequence == NULL) {
        if (!PyErr_Occurred()) {
            PyObject *single_list = PyList_New(1);
            if (single_list == NULL) {
                return NULL;
            }
            PyObject *normalized = decode_bytes_like(args);
            if (normalized == NULL) {
                Py_DECREF(single_list);
                return NULL;
            }
            PyList_SET_ITEM(single_list, 0, normalized);
            return single_list;
        }
        return NULL;
    }

    Py_ssize_t size = PySequence_Fast_GET_SIZE(sequence);
    PyObject **items = PySequence_Fast_ITEMS(sequence);
    PyObject *normalized_list = PyList_New(size);
    if (normalized_list == NULL) {
        Py_DECREF(sequence);
        return NULL;
    }

    for (Py_ssize_t i = 0; i < size; ++i) {
        PyObject *normalized = decode_bytes_like(items[i]);
        if (normalized == NULL) {
            Py_DECREF(sequence);
            Py_DECREF(normalized_list);
            return NULL;
        }
        PyList_SET_ITEM(normalized_list, i, normalized);
    }

    Py_DECREF(sequence);
    return normalized_list;
}

static void set_bridge_python_error(const char *context, BridgeResult status) {
    char buffer[1024] = {0};
    BridgeResult err_status = bridge_get_last_error(buffer, sizeof(buffer));
    if (err_status == BRIDGE_SUCCESS && buffer[0] != '\0') {
        PyErr_Format(PyExc_RuntimeError, "%s failed (%d): %s", context, status, buffer);
    } else {
        PyErr_Format(PyExc_RuntimeError, "%s failed with status %d", context, status);
    }
}

static int write_bytes_to_shared_memory(const SharedMemoryHandle *handle, const char *payload, size_t length) {
    if (handle == NULL || handle->name == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "Shared memory handle is NULL");
        return -1;
    }

    void *mapped_ptr = NULL;
    BridgeResult status = bridge_map_shared_memory(handle, &mapped_ptr);
    if (status != BRIDGE_SUCCESS) {
        set_bridge_python_error("bridge_map_shared_memory", status);
        return -1;
    }

    if (length + 1 > handle->size) {
        bridge_unmap_shared_memory(handle, mapped_ptr);
        PyErr_SetString(PyExc_RuntimeError, "Shared memory buffer too small for payload");
        return -1;
    }

    char *target = (char *)mapped_ptr;
    memcpy(target, payload, length);
    target[length] = '\0';
    if (handle->size > length + 1) {
        memset(target + length + 1, 0, handle->size - (length + 1));
    }

    status = bridge_unmap_shared_memory(handle, mapped_ptr);
    if (status != BRIDGE_SUCCESS) {
        set_bridge_python_error("bridge_unmap_shared_memory", status);
        return -1;
    }

    return 0;
}

static PyObject* read_utf8_from_shared_memory(const SharedMemoryHandle *handle) {
    if (handle == NULL || handle->name == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "Shared memory handle is NULL");
        return NULL;
    }

    void *mapped_ptr = NULL;
    BridgeResult status = bridge_map_shared_memory(handle, &mapped_ptr);
    if (status != BRIDGE_SUCCESS) {
        set_bridge_python_error("bridge_map_shared_memory", status);
        return NULL;
    }

    const char *raw = (const char *)mapped_ptr;
    size_t max_length = handle->size;
    size_t actual_length = 0;
    while (actual_length < max_length && raw[actual_length] != '\0') {
        actual_length++;
    }

    PyObject *unicode = PyUnicode_DecodeUTF8(raw, actual_length, "replace");

    status = bridge_unmap_shared_memory(handle, mapped_ptr);
    if (status != BRIDGE_SUCCESS) {
        Py_XDECREF(unicode);
        set_bridge_python_error("bridge_unmap_shared_memory", status);
        return NULL;
    }

    return unicode;
}

static double telos_proxy_monotonic_ms(void) {
#ifdef _WIN32
    LARGE_INTEGER frequency;
    LARGE_INTEGER counter;
    if (!QueryPerformanceFrequency(&frequency) || frequency.QuadPart == 0 || !QueryPerformanceCounter(&counter)) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "monotonicClock");
        PyErr_Clear();
        return 0.0;
    }
    return (double)counter.QuadPart * 1000.0 / (double)frequency.QuadPart;
#else
#if defined(CLOCK_MONOTONIC)
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0) {
        return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1e6;
    }
#endif
    struct timeval tv;
    if (gettimeofday(&tv, NULL) == 0) {
        return (double)tv.tv_sec * 1000.0 + (double)tv.tv_usec / 1e3;
    }
    TelosProxy_WriteUnraisable("dispatchMetrics", "monotonicClock");
    PyErr_Clear();
    return 0.0;
#endif
}

static double telos_proxy_system_seconds(void) {
#ifdef _WIN32
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER uli;
    uli.LowPart = ft.dwLowDateTime;
    uli.HighPart = ft.dwHighDateTime;
    const double WINDOWS_TICK = 10000000.0; // 1 tick = 100ns
    const double SEC_TO_UNIX_EPOCH = 11644473600.0; // seconds between 1601 and 1970
    return (double)uli.QuadPart / WINDOWS_TICK - SEC_TO_UNIX_EPOCH;
#else
    struct timeval tv;
    if (gettimeofday(&tv, NULL) != 0) {
        TelosProxy_WriteUnraisable("dispatchMetrics", "systemClock");
        PyErr_Clear();
        return 0.0;
    }
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
#endif
}

static PyObject* telos_proxy_capture_error_string(void) {
    if (!PyErr_Occurred()) {
        return NULL;
    }

    PyObject *ptype = NULL;
    PyObject *pvalue = NULL;
    PyObject *ptrace = NULL;
    PyErr_GetExcInfo(&ptype, &pvalue, &ptrace);

    PyObject *message = NULL;
    PyObject *source = pvalue ? pvalue : ptype;
    if (source) {
        message = PyObject_Str(source);
        if (!message && PyErr_Occurred()) {
            TelosProxy_WriteUnraisable("dispatchMetrics", "errorString");
            PyErr_Clear();
        }
    }

    PyErr_SetExcInfo(ptype, pvalue, ptrace);
    return message;
}
