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

static void TelosProxy_TriggerDoesNotUnderstand(TelosProxyObject *self, const char *slot_name, PyObject *error_message);

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
