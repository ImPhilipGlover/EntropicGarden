#include "synaptic_bridge.h"
#include "IoState.h"
#include "IoObject.h"
#include "parson.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void print_bridge_error(const char *context) {
    char buffer[512] = {0};
    if (bridge_get_last_error(buffer, sizeof(buffer)) == BRIDGE_SUCCESS) {
        fprintf(stderr, "%s: %s\n", context, buffer);
    } else {
        fprintf(stderr, "%s: <unable to fetch error>\n", context);
    }
}

int main(void) {
    IoState *state = IoState_new();
    if (!state) {
        fprintf(stderr, "Failed to allocate IoState\n");
        return EXIT_FAILURE;
    }

    IoState_init(state);
    IoState_argc_argv_(state, 0, NULL);

    bridge_clear_error();
    BridgeConfig config = {1, NULL};  // max_workers = 1, log_callback = NULL
    BridgeResult init_status = bridge_initialize(&config);
    if (init_status != BRIDGE_SUCCESS) {
        print_bridge_error("bridge_initialize");
    }

    IoObject *lobby = IoState_lobby(state);
    assert(lobby != NULL);

    SharedMemoryHandle result_handle;
    memset(&result_handle, 0, sizeof(result_handle));

    const size_t buffer_size = 256;
    BridgeResult status = bridge_create_shared_memory(buffer_size, &result_handle);
    if (status != BRIDGE_SUCCESS) {
        print_bridge_error("bridge_create_shared_memory");
        IoState_free(state);
        return EXIT_FAILURE;
    }

    status = bridge_send_message((IoObjectHandle)lobby, "type", NULL, &result_handle);
    if (status != BRIDGE_SUCCESS) {
        print_bridge_error("bridge_send_message");
        bridge_destroy_shared_memory(&result_handle);
        IoState_free(state);
        return EXIT_FAILURE;
    }

    void *mapped_ptr = NULL;
    status = bridge_map_shared_memory(&result_handle, &mapped_ptr);
    if (status != BRIDGE_SUCCESS) {
        print_bridge_error("bridge_map_shared_memory");
        bridge_destroy_shared_memory(&result_handle);
        IoState_free(state);
        return EXIT_FAILURE;
    }

    const char *json_response = (const char *)mapped_ptr;
    JSON_Value *root = json_parse_string(json_response);
    if (!root) {
        fprintf(stderr, "Failed to parse bridge response: %s\n", json_response);
        bridge_unmap_shared_memory(&result_handle, mapped_ptr);
        bridge_destroy_shared_memory(&result_handle);
        IoState_free(state);
        return EXIT_FAILURE;
    }

    if (json_value_get_type(root) != JSONString) {
        fprintf(stderr, "Expected JSON string response but received type %d\n", (int)json_value_get_type(root));
        json_value_free(root);
        bridge_unmap_shared_memory(&result_handle, mapped_ptr);
        bridge_destroy_shared_memory(&result_handle);
        IoState_free(state);
        return EXIT_FAILURE;
    }

    const char *type_name = json_value_get_string(root);
    int success = (type_name != NULL && strcmp(type_name, "Object") == 0);

    if (!success) {
        fprintf(stderr, "Unexpected Io message response: %s\n", type_name ? type_name : "<null>");
    }

    json_value_free(root);
    bridge_unmap_shared_memory(&result_handle, mapped_ptr);
    bridge_destroy_shared_memory(&result_handle);

    bridge_shutdown();
    IoState_free(state);

    if (!success) {
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
