/*
   IoTelosCore.h - Core System Interface Header
   Extracted from monolithic IoTelos.c for modular architecture
*/

#ifndef IOTELOS_CORE_H
#define IOTELOS_CORE_H

#include "IoState.h"
#include "IoObject.h"
#include "IoMessage.h"

// IoTelos type is defined in IoTelos.h - use IoObject typedef
typedef IoObject IoTelos;

#include "IoTag.h"

// Core system functions
IoTag *IoTelos_newTag(void *state);
IoTelos *IoTelos_proto(void *state);
IoTelos *IoTelos_rawClone(IoTelos *proto);
IoTelos *IoTelos_new(void *state);
void IoTelos_free(IoTelos *self);
void IoTelos_mark(IoTelos *self);

// Module initialization
void IoTelosCore_Init(IoState *state);
void IoTelosCore_registerProto(IoState *state);

// Prototype registration
IoObject *IoTelos_protoId(IoTelos *self, IoObject *locals, IoMessage *m);

// GC Pinning API - Critical for FFI Bridge Safety
void IoTelos_pinObject(IoObject *object);
void IoTelos_unpinObject(IoObject *object);
void IoTelos_unpinAllObjects(void);

#endif // IOTELOS_CORE_H