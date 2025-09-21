/*
PrototypalFFI.h - Pure C FFI Interface Declarations
==================================================

Function declarations for the prototypal FFI implementation.
This maintains philosophical alignment with Io's dynamic object model.
*/

#ifndef PROTOTYPAL_FFI_H
#define PROTOTYPAL_FFI_H

#include "IoObject.h"
#include "IoState.h"
#include "IoMessage.h"
#include <Python.h>

// Forward declarations
typedef struct FFIObjectHandle FFIObjectHandle;
typedef struct PrototypalFFI PrototypalFFI;

// FFI Object Handle Structure
struct FFIObjectHandle {
    PyObject* python_object;    // Python object reference
    IoObject* io_wrapper;       // Io wrapper object
    int gc_registered;          // GC registration state
};

// Core FFI Management Functions
int FFI_initializePythonEnvironment(const char* venv_path);
void FFI_shutdown(void);

// Memory Management Functions
FFIObjectHandle* FFI_createHandle(IoState* state, PyObject* py_obj);
IoObject* FFI_handleWillFree(IoObject* self, IoObject* locals, IoMessage* m);

// Data Marshalling Functions
PyObject* FFI_marshalIoObject(IoObject* io_obj);
PyObject* FFI_marshalIoNumber(IoObject* io_obj);
PyObject* FFI_marshalIoSequence(IoObject* io_obj);
PyObject* FFI_marshalIoList(IoObject* io_obj);

IoObject* FFI_marshalPythonNumber(IoState* state, PyObject* py_obj);
IoObject* FFI_marshalPythonString(IoState* state, PyObject* py_obj);

// Error Handling Functions
void FFI_propagateError(IoState* state);

// Async Execution Functions
PyObject* FFI_executeAsync(const char* function_name, PyObject* args);

// Module and Function Management
PyObject* FFI_loadModule(const char* module_name);
PyObject* FFI_callFunction(PyObject* module, const char* function_name, PyObject* args);

#endif // PROTOTYPAL_FFI_H