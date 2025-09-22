/*
   IoTelos.h - TelOS Modular Architecture Coordinator
   Orchestrates Core, FFI, Morphic, Persistence, Memory, and Persona modules
   */

#ifndef IOTELOS_DEFINED
#define IOTELOS_DEFINED 1

#include "IoObject.h"
#include "IoState.h"

// Include modular headers
#include "IoTelosCore.h"
#include "IoTelosFFI.h"

#define ISTELOS(self) IoObject_hasCloneFunc_(self, (IoTagCloneFunc *)IoTelos_rawClone)

typedef IoObject IoTelos;

// Main module initialization
void IoTelosInit(IoState *self, IoObject *context);

// TelOS Core API methods
IoObject *IoTelos_getPythonVersion(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_transactional_setSlot(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_openWindow(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_closeWindow(IoTelos *self, IoObject *locals, IoMessage *m);

// Rigorous FFI API methods
IoObject *IoTelos_initializeFFI(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_shutdownFFI(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_marshalIoToPython(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_marshalPythonToIo(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_wrapTensor(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_executeAsync(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_waitForFuture(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_loadModule(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_callFunction(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_createInstance(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_callMethod(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_getObjectType(IoTelos *self, IoObject *locals, IoMessage *m);

// Prototypal FFI Mandate methods
IoObject *IoTelos_createFFIProxy(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_proxyGetSlot(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_proxySetSlot(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_proxyPerform(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_proxyClone(IoTelos *self, IoObject *locals, IoMessage *m);

// Morphic API methods
IoObject *IoTelos_createWorld(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_mainLoop(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_createMorph(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_addSubmorph(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_removeSubmorph(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_draw(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_handleEvent(IoTelos *self, IoObject *locals, IoMessage *m);

// Helper functions
void IoTelos_drawWorld(IoTelos *self);
void IoTelos_drawMorph(IoTelos *self, IoObject *morph);
void IoTelos_processEvents(IoTelos *self);

// Morph-specific methods
IoObject *IoTelos_morphDraw(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_morphContainsPoint(IoObject *self, IoObject *locals, IoMessage *m);

#endif
