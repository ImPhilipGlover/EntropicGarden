/*
   IoTelosUI.c
   */

#include "IoTelosUI.h"
#include "IoState.h"
#include "IoCFunction.h"
#include <stdlib.h>
#include <string.h>

static const char *protoId = "TelosUI";

IoTag *IoTelosUI_newTag(void *state)
{
	IoTag *tag = IoTag_newWithName_(protoId);
	IoTag_state_(tag, state);
	IoTag_cloneFunc_(tag, (IoTagCloneFunc *)IoTelosUI_rawClone);
	IoTag_freeFunc_(tag, (IoTagFreeFunc *)IoTelosUI_free);
	return tag;
}

IoTelosUI *IoTelosUI_proto(void *state)
{
	IoObject *self = IoObject_new(state);
	IoObject_tag_(self, IoTelosUI_newTag(state));

	IoState_registerProtoWithId_(state, self, protoId);

	{
		IoMethodTable methodTable[] = {
			{"createWindow", IoTelosUI_createWindow},
			{"mainLoop", IoTelosUI_mainLoop},
			{NULL, NULL},
		};
		IoObject_addMethodTable_(self, methodTable);
	}

	return self;
}

IoTelosUI *IoTelosUI_rawClone(IoTelosUI *proto)
{
	IoObject *self = IoObject_rawClonePrimitive(proto);
	return self;
}

void IoTelosUI_free(IoTelosUI *self)
{
}

// --- GLUT callbacks and functions ---
// For now, stub implementations until GLUT is properly set up
void display()
{
    // Stub display function
    printf("TelosUI: Display callback (GLUT not yet integrated)\n");
}

IoObject *IoTelosUI_createWindow(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    // Stub window creation
    printf("TelosUI: Creating window (GLUT integration pending)\n");
    printf("TelosUI: Window would be 640x480 at position 100,100\n");
    return self;
}

IoObject *IoTelosUI_mainLoop(IoTelosUI *self, IoObject *locals, IoMessage *m)
{
    // Stub main loop
    printf("TelosUI: Entering main loop (GLUT integration pending)\n");
    printf("TelosUI: Main loop would handle events and rendering\n");
    return self;
}
