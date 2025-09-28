/* Small unit test for SharedMemoryHandle lifecycle */
#include "../Telos/source/synaptic_bridge.h"
#include <stdio.h>
#include <string.h>

int main(void) {
    SharedMemoryHandle handle;
    memset(&handle, 0, sizeof(handle));

    /* Ensure global bridge state exists for the test harness. The real
       bridge_initialize path is not invoked in this lightweight test, so
       create a minimal SynapticBridgeState with NULL pool slots to allow
       create_shared_memory_handle to find an available slot. */
    extern SynapticBridgeState* g_bridge_state;
    g_bridge_state = (SynapticBridgeState*)malloc(sizeof(SynapticBridgeState));
    if (g_bridge_state == NULL) {
        fprintf(stderr, "Failed to allocate g_bridge_state\n");
        return 5;
    }
    memset(g_bridge_state, 0, sizeof(*g_bridge_state));

    BridgeResult r = create_shared_memory_handle(&handle, 1024, "testpool");
    if (r != BRIDGE_SUCCESS) {
        fprintf(stderr, "create_shared_memory_handle failed\n");
        return 1;
    }

    if (handle.name == NULL) {
        fprintf(stderr, "expected handle.name to be non-NULL after create\n");
        return 2;
    }

    r = destroy_shared_memory_handle(&handle);
    if (r != BRIDGE_SUCCESS) {
        fprintf(stderr, "destroy_shared_memory_handle failed\n");
        return 3;
    }

    if (handle.name != NULL) {
        fprintf(stderr, "expected handle.name to be NULL after destroy\n");
        return 4;
    }

    printf("SharedMemoryHandle lifecycle test passed\n");

    /* Clean up test-allocated bridge state */
    free(g_bridge_state);
    g_bridge_state = NULL;

    return 0;
}
