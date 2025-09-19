#include "IoState.h"
#include "IoObject.h"
#include "IoMessage.h"
#include "IoCFunction.h"
#include "IoNumber.h"

// TelOS addon init entry
void IoTelosInit(IoState *self, IoObject *context);

// Called by main to register C-level addons before IoState_init finishes
void IoAddonsInit(IoState *self, IoObject *context)
{
    // Initialize TelOS addon
    IoTelosInit(self, context);
}
