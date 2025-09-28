#include "synaptic_bridge.h"
#include <stdlib.h>
#include <string.h>

/* =============================================================================
 * VSA (Vector Symbolic Architecture) Operations
 * =============================================================================
 */

BridgeResult bridge_bind_vsa(const char* name, VSAHandle handle) {
    if (name == NULL || handle == NULL) {
        set_bridge_error("VSA name and handle cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    if (strlen(name) >= MAX_VSA_NAME_LENGTH) {
        set_bridge_error("VSA name too long (max %d characters)", MAX_VSA_NAME_LENGTH - 1);
        return BRIDGE_ERROR_INVALID_ARGUMENT;
    }

    // Find available binding slot
    int binding_index = -1;
    for (int i = 0; i < MAX_VSA_BINDINGS; i++) {
        if (g_bridge_state->vsa_bindings[i].handle == NULL) {
            binding_index = i;
            break;
        }
    }

    if (binding_index == -1) {
        set_bridge_error("No available VSA binding slots");
        return BRIDGE_ERROR_RESOURCE_EXHAUSTED;
    }

    // Check for name conflicts
    for (int i = 0; i < MAX_VSA_BINDINGS; i++) {
        if (g_bridge_state->vsa_bindings[i].handle != NULL &&
            strcmp(g_bridge_state->vsa_bindings[i].name, name) == 0) {
            set_bridge_error("VSA binding '%s' already exists", name);
            return BRIDGE_ERROR_ALREADY_EXISTS;
        }
    }

    g_bridge_state->vsa_bindings[binding_index].handle = handle;
    strncpy(g_bridge_state->vsa_bindings[binding_index].name, name, sizeof(g_bridge_state->vsa_bindings[binding_index].name) - 1);
    g_bridge_state->vsa_bindings[binding_index].name[sizeof(g_bridge_state->vsa_bindings[binding_index].name) - 1] = '\0';

    log_bridge_message(LOG_LEVEL_INFO, "Bound VSA '%s' to handle %p", name, handle);
    return BRIDGE_SUCCESS;
}

BridgeResult bridge_unbind_vsa(const char* name) {
    if (name == NULL) {
        set_bridge_error("VSA name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    for (int i = 0; i < MAX_VSA_BINDINGS; i++) {
        if (g_bridge_state->vsa_bindings[i].handle != NULL &&
            strcmp(g_bridge_state->vsa_bindings[i].name, name) == 0) {
            log_bridge_message(LOG_LEVEL_INFO, "Unbound VSA '%s'", name);
            g_bridge_state->vsa_bindings[i].handle = NULL;
            g_bridge_state->vsa_bindings[i].name[0] = '\0';
            return BRIDGE_SUCCESS;
        }
    }

    set_bridge_error("VSA binding '%s' not found", name);
    return BRIDGE_ERROR_NOT_FOUND;
}

BridgeResult bridge_query_vsa(const char* name, const SharedMemoryHandle* query_handle, const SharedMemoryHandle* result_handle) {
    if (name == NULL) {
        set_bridge_error("VSA name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    // Find VSA binding
    VSAHandle vsa_handle = NULL;
    for (int i = 0; i < MAX_VSA_BINDINGS; i++) {
        if (g_bridge_state->vsa_bindings[i].handle != NULL &&
            strcmp(g_bridge_state->vsa_bindings[i].name, name) == 0) {
            vsa_handle = g_bridge_state->vsa_bindings[i].handle;
            break;
        }
    }

    if (vsa_handle == NULL) {
        set_bridge_error("VSA binding '%s' not found", name);
        return BRIDGE_ERROR_NOT_FOUND;
    }

    // Read query from shared memory
    char* query_json = NULL;
    BridgeResult status = read_json_from_shared_memory(query_handle, &query_json, NULL);
    if (status != BRIDGE_SUCCESS) {
        return status;
    }

    // Perform VSA query (placeholder - actual implementation would call VSA library)
    log_bridge_message(LOG_LEVEL_DEBUG, "Querying VSA '%s' with: %s", name, query_json);

    // Placeholder result - in real implementation, this would process the query
    const char* result_json = "{\"result\": \"placeholder\", \"confidence\": 0.95}";

    // Write result to shared memory
    status = write_json_to_shared_memory(result_handle, result_json, strlen(result_json));
    free(query_json);

    if (status != BRIDGE_SUCCESS) {
        return status;
    }

    log_bridge_message(LOG_LEVEL_DEBUG, "VSA query completed for '%s'", name);
    return BRIDGE_SUCCESS;
}