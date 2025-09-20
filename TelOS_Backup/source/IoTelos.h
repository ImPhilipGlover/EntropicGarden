/*
   IoTelos.h - TelOS Synaptic Bridge: FFI, Persistence, and UI Stubs
   The zygote's first pillars: mind touching muscle, heartbeat, and glance
   */

#ifndef IOTELOS_DEFINED
#define IOTELOS_DEFINED 1

#include "IoObject.h"
#include "IoState.h"

#define ISTELOS(self) IoObject_hasCloneFunc_(self, (IoTagCloneFunc *)IoTelos_rawClone)

typedef IoObject IoTelos;

IoTag *IoTelos_newTag(void *state);
IoTelos *IoTelos_proto(void *state);
IoTelos *IoTelos_rawClone(IoTelos *proto);
void IoTelos_free(IoTelos *self);

// TelOS Core API methods
IoObject *IoTelos_getPythonVersion(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_transactional_setSlot(IoTelos *self, IoObject *locals, IoMessage *m);
IoObject *IoTelos_openWindow(IoTelos *self, IoObject *locals, IoMessage *m);

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
