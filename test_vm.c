// Simple test to see if Io VM is working
#include "IoState.h"

void IoAddonsInit(IoObject *context);

int main() {
    IoState *self = IoState_new();
    IoState_init(self);
    
    // Try to execute a simple string
    IoObject *result = IoState_doCString_(self, "42");
    
    printf("Result: %p\n", result);
    if (result) {
        printf("Got some result\n");
    } else {
        printf("No result\n");
    }
    
    IoState_free(self);
    return 0;
}