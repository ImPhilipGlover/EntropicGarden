/*
   IoTelosUI.h
   */

#ifndef IOTELOSUI_DEFINED
#define IOTELOSUI_DEFINED 1

#include "IoObject.h"
#include "IoNumber.h"
#include "IoSeq.h"

// GLUT includes commented out until properly integrated
// #ifdef __APPLE__
// #include <GLUT/glut.h>
// #else
// #include <GL/glut.h>
// #endif

#define ISTELOSUI(self) IoObject_hasCloneFunc_(self, (IoTagCloneFunc *)IoTelosUI_rawClone)

typedef IoObject IoTelosUI;

IoTag *IoTelosUI_newTag(void *state);
IoTelosUI *IoTelosUI_proto(void *state);
IoTelosUI *IoTelosUI_rawClone(IoTelosUI *proto);
void IoTelosUI_free(IoTelosUI *self);

IoObject *IoTelosUI_createWindow(IoTelosUI *self, IoObject *locals, IoMessage *m);
IoObject *IoTelosUI_mainLoop(IoTelosUI *self, IoObject *locals, IoMessage *m);

#endif
