/*
   IoTelos.h - Modular TelOS Architecture Main Header
   Coordinates Core, FFI, Morphic, Persistence, Memory, and Persona modules
   Designed for clean separation of concerns and targeted debugging
*/

#ifndef IOTELOS_H
#define IOTELOS_H

#include "IoState.h"
#include "IoObject.h"
#include "IoMessage.h"

// Forward declarations for modular architecture
typedef IoObject IoTelos;

// Main TelOS initialization
void IoTelosInit(IoState *state, IoObject *context);

// Module initialization functions (implemented by respective modules)
void IoTelosCore_Init(IoState *state);
void IoTelosFFI_Init(IoState *state);

// Common utilities shared across modules
IoTelos *IoTelos_proto(void *state);
IoTelos *IoTelos_new(void *state);

#endif // IOTELOS_H