/*
   IoTelosUI.h - Morphic UI Framework for TelOS
   Living, directly manipulable interface objects
   */

#ifndef IOTELOSUI_DEFINED
#define IOTELOSUI_DEFINED 1

#include "IoObject.h"
#include "IoState.h"

#define ISTELOSUI(self) IoObject_hasCloneFunc_(self, (IoTagCloneFunc *)IoTelosUI_rawClone)

typedef IoObject IoTelosUI;

IoTag *IoTelosUI_newTag(void *state);
IoTelosUI *IoTelosUI_proto(void *state);
IoTelosUI *IoTelosUI_rawClone(IoTelosUI *proto);
void IoTelosUI_free(IoTelosUI *self);

// Morphic API methods
IoObject *IoTelosUI_createWorld(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_mainLoop(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_createMorph(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_addSubmorph(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_removeSubmorph(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_draw(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_handleEvent(IoTelosUI *self, IoObject *locals, IoMessage *m);

// Helper functions
void IoTelosUI_drawWorld(IoTelosUI *self);
void IoTelosUI_drawMorph(IoTelosUI *self, IoObject *morph);
void IoTelosUI_processEvents(IoTelosUI *self);

// Morph-specific methods
IoObject *IoTelosUI_morphDraw(IoObject *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_morphContainsPoint(IoObject *self, IoObject *locals, IoMessage *m);

#endif
