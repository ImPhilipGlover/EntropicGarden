#include "synaptic_bridge.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "parson.h"

#ifdef HAVE_IOVM
#include <IoState.h>
#include <IoObject.h>
#include <IoMessage.h>
#include <IoSeq.h>
#include <IoNumber.h>
#include <IoList.h>
#include <IoMap.h>
#endif

/* =============================================================================
 * Io Object Serialization/Deserialization
 * =============================================================================
 */

#ifdef HAVE_IOVM
static const char* io_object_key_to_cstring(IoState* state, IoObject* key, char* buffer, size_t buffer_size) {
    if (key == NULL) {
        return "";
    }

    if (ISSEQ(key)) {
        return IoSeq_asCString((IoSeq*)key);
    }

    if (ISNUMBER(key)) {
        if (buffer_size > 0) {
            snprintf(buffer, buffer_size, "%.17g", IoNumber_asDouble((IoNumber*)key));
            buffer[buffer_size - 1] = '\0';
        }
        return buffer;
    }

    if (key == state->ioTrue) {
        return "true";
    }
    if (key == state->ioFalse) {
        return "false";
    }
    if (key == state->ioNil) {
        return "nil";
    }

    const char* name = IoObject_name(key);
    if (name != NULL) {
        return name;
    }

    if (buffer_size > 0) {
        snprintf(buffer, buffer_size, "object_%p", (void*)key);
        buffer[buffer_size - 1] = '\0';
    }
    return buffer;
}

static JSON_Value* io_object_to_json_value(IoState* state, IoObject* object);

static JSON_Value* io_list_to_json_array(IoState* state, IoList* list) {
    JSON_Value* array_value = json_value_init_array();
    if (array_value == NULL) {
        return NULL;
    }

    JSON_Array* array = json_value_get_array(array_value);
    size_t count = IoList_rawSize(list);

    for (size_t i = 0; i < count; i++) {
        IoObject* element = IoList_rawAt_(list, (int)i);
        JSON_Value* child = io_object_to_json_value(state, element);
        if (child == NULL) {
            json_value_free(array_value);
            return NULL;
        }
        if (json_array_append_value(array, child) != JSONSuccess) {
            json_value_free(child);
            json_value_free(array_value);
            return NULL;
        }
    }

    return array_value;
}

static JSON_Value* io_map_to_json_object(IoState* state, IoMap* map) {
    JSON_Value* object_value = json_value_init_object();
    if (object_value == NULL) {
        return NULL;
    }

    JSON_Object* json_object = json_value_get_object(object_value);
    PHash* hash = IoMap_rawHash(map);

    PHASH_FOREACH(hash, key, value, {
        IoObject* ioKey = (IoObject*)key;
        IoObject* ioValue = (IoObject*)value;
        char buffer[64];
        const char* key_cstr = io_object_key_to_cstring(state, ioKey, buffer, sizeof(buffer));
        JSON_Value* child = io_object_to_json_value(state, ioValue);
        if (child == NULL) {
            json_value_free(object_value);
            return NULL;
        }
        if (json_object_set_value(json_object, key_cstr, child) != JSONSuccess) {
            json_value_free(child);
            json_value_free(object_value);
            return NULL;
        }
    });

    return object_value;
}

static JSON_Value* io_object_to_json_value(IoState* state, IoObject* object) {
    if (object == NULL || object == state->ioNil) {
        return json_value_init_null();
    }

    if (object == state->ioTrue) {
        return json_value_init_boolean(1);
    }

    if (object == state->ioFalse) {
        return json_value_init_boolean(0);
    }

    if (ISNUMBER(object)) {
        return json_value_init_number(IoNumber_asDouble((IoNumber*)object));
    }

    if (ISSEQ(object)) {
        const char* str = IoSeq_asCString((IoSeq*)object);
        return json_value_init_string(str ? str : "");
    }

    if (ISLIST(object)) {
        return io_list_to_json_array(state, (IoList*)object);
    }

    if (ISMAP(object)) {
        return io_map_to_json_object(state, (IoMap*)object);
    }

    const char* description = IoObject_name(object);
    return json_value_init_string(description ? description : "object");
}

static IoObject* json_value_to_io_object(IoState* state, JSON_Value* value) {
    if (value == NULL) {
        return NULL;
    }

    switch (json_value_get_type(value)) {
        case JSONNull:
            return state->ioNil;
        case JSONBoolean:
            return json_value_get_boolean(value) ? state->ioTrue : state->ioFalse;
        case JSONNumber:
            return (IoObject*)IoNumber_newWithDouble_(state, json_value_get_number(value));
        case JSONString:
            return (IoObject*)IoSeq_newWithCString_(state, json_value_get_string(value));
        case JSONArray: {
            JSON_Array* array = json_value_get_array(value);
            IoList* list = IoList_new(state);
            size_t count = json_array_get_count(array);
            for (size_t i = 0; i < count; i++) {
                IoObject* element = json_value_to_io_object(state, json_array_get_value(array, i));
                if (element == NULL) {
                    return NULL;
                }
                IoList_rawAppend_(list, element);
            }
            return (IoObject*)list;
        }
        case JSONObject: {
            JSON_Object* json_object = json_value_get_object(value);
            IoMap* map = IoMap_new(state);
            size_t count = json_object_get_count(json_object);
            for (size_t i = 0; i < count; i++) {
                const char* key = json_object_get_name(json_object, i);
                JSON_Value* entry_value = json_object_get_value_at(json_object, i);
                IoObject* io_value = json_value_to_io_object(state, entry_value);
                if (io_value == NULL) {
                    return NULL;
                }
                IoSymbol* key_symbol = IoState_symbolWithCString_(state, key ? key : "");
                IoMap_rawAtPut(map, key_symbol, io_value);
            }
            return (IoObject*)map;
        }
        case JSONError:
        default:
            return NULL;
    }
}
#endif /* HAVE_IOVM */

/* =============================================================================
 * Message Passing and Object Communication
 * =============================================================================
 */

BridgeResult bridge_send_message(
    IoObjectHandle target_handle,
    const char* message_name,
    const SharedMemoryHandle* args_handle,
    const SharedMemoryHandle* result_handle) {
    
    if (target_handle == NULL || message_name == NULL) {
        set_bridge_error("Target handle and message name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }
#ifndef HAVE_IOVM
    set_bridge_error("IoVM integration not available in this build");
    return BRIDGE_ERROR_INVALID_HANDLE;
#else
    IoObject* target = (IoObject*)target_handle;
    if (target == NULL) {
        set_bridge_error("Invalid Io object handle");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoState* state = IoObject_state(target);
    if (state == NULL) {
        set_bridge_error("Io object has no associated state");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoSymbol* message_symbol = IoState_symbolWithCString_(state, message_name);
    if (message_symbol == NULL) {
        set_bridge_error("Failed to resolve message symbol '%s'", message_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    IoSymbol* label_symbol = IoState_symbolWithCString_(state, "bridge_send_message");
    IoMessage* message = IoMessage_newWithName_label_(state, message_symbol, label_symbol);
    if (message == NULL) {
        set_bridge_error("Failed to allocate Io message for '%s'", message_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    char* args_json = NULL;
    JSON_Value* args_root = NULL;
    BridgeResult status = BRIDGE_SUCCESS;
    void* mapped_args_ptr = NULL;
    void* mapped_result_ptr = NULL;

    if (args_handle != NULL && args_handle->name != NULL) {
        status = bridge_map_shared_memory(args_handle, &mapped_args_ptr);
        if (status != BRIDGE_SUCCESS) {
            goto cleanup;
        }

        size_t args_buffer_size = args_handle->size;
        if (args_buffer_size == 0) {
            set_bridge_error("Shared memory handle '%s' has zero size", args_handle->name);
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        const char* args_cstr = (const char*)mapped_args_ptr;
        size_t args_len = strnlen(args_cstr, args_buffer_size);
        if (args_len >= args_buffer_size) {
            set_bridge_error("Shared memory arguments for '%s' are not null-terminated", args_handle->name);
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        args_json = (char*)malloc(args_len + 1);
        if (args_json == NULL) {
            set_bridge_error("Failed to allocate buffer for arguments JSON");
            status = BRIDGE_ERROR_MEMORY_ALLOCATION;
            goto cleanup;
        }

        memcpy(args_json, args_cstr, args_len);
        args_json[args_len] = '\0';

        args_root = json_parse_string(args_json);
        if (args_root == NULL || json_value_get_type(args_root) != JSONArray) {
            set_bridge_error("Shared memory arguments must encode a JSON array");
            status = BRIDGE_ERROR_SHARED_MEMORY;
            goto cleanup;
        }

        JSON_Array* args_array = json_value_get_array(args_root);
        size_t arg_count = json_array_get_count(args_array);
        for (size_t i = 0; i < arg_count; i++) {
            JSON_Value* arg_value = json_array_get_value(args_array, i);
            IoObject* io_arg = json_value_to_io_object(state, arg_value);
            if (io_arg == NULL) {
                set_bridge_error("Unsupported argument type at index %zu", i);
                status = BRIDGE_ERROR_SHARED_MEMORY;
                goto cleanup;
            }
            IoMessage_addCachedArg_(message, io_arg);
        }
    }

    IoObject* result_obj = IoMessage_locals_performOn_(message, target, target);
    if (result_obj == NULL) {
        result_obj = state->ioNil;
    }

    if (result_handle != NULL && result_handle->name != NULL) {
        JSON_Value* result_json = io_object_to_json_value(state, result_obj);
        if (result_json == NULL) {
            set_bridge_error("Failed to serialize Io result to JSON");
            status = BRIDGE_ERROR_PYTHON_EXCEPTION;
            goto cleanup;
        }

        char* serialized = json_serialize_to_string(result_json);
        if (serialized == NULL) {
            json_value_free(result_json);
            set_bridge_error("Failed to serialize JSON result to string");
            status = BRIDGE_ERROR_MEMORY_ALLOCATION;
            goto cleanup;
        }

        size_t serialized_len = strlen(serialized);
        size_t result_buffer_size = result_handle->size;
        if (result_buffer_size == 0 || serialized_len + 1 > result_buffer_size) {
            set_bridge_error("Result buffer too small for serialized response (%zu bytes required)", serialized_len + 1);
            status = BRIDGE_ERROR_SHARED_MEMORY;
            json_free_serialized_string(serialized);
            json_value_free(result_json);
            goto cleanup;
        }

        status = bridge_map_shared_memory(result_handle, &mapped_result_ptr);
        if (status != BRIDGE_SUCCESS) {
            json_free_serialized_string(serialized);
            json_value_free(result_json);
            goto cleanup;
        }

        char* result_dest = (char*)mapped_result_ptr;
        /* Zero the destination and copy the serialized JSON including a null terminator
           to ensure consumers using json_parse_string see a properly terminated C string. */
        if (result_buffer_size > 0) {
            memset(result_dest, 0, result_buffer_size);
            memcpy(result_dest, serialized, serialized_len);
            /* Ensure null terminator is present */
            result_dest[serialized_len] = '\0';
        }

        BridgeResult unmap_status = bridge_unmap_shared_memory(result_handle, mapped_result_ptr);
        mapped_result_ptr = NULL;
        if (unmap_status != BRIDGE_SUCCESS && status == BRIDGE_SUCCESS) {
            status = unmap_status;
        }

        json_free_serialized_string(serialized);
        json_value_free(result_json);

        if (status != BRIDGE_SUCCESS) {
            goto cleanup;
        }
    }

cleanup:
    if (mapped_args_ptr != NULL && args_handle != NULL && args_handle->name != NULL) {
        bridge_unmap_shared_memory(args_handle, mapped_args_ptr);
    }
    if (mapped_result_ptr != NULL && result_handle != NULL && result_handle->name != NULL) {
        bridge_unmap_shared_memory(result_handle, mapped_result_ptr);
    }
    if (args_root) {
        json_value_free(args_root);
    }
    if (args_json) {
        free(args_json);
    }

    return status;
#endif
}

BridgeResult bridge_get_slot(
    IoObjectHandle object_handle,
    const char* slot_name,
    const SharedMemoryHandle* result_handle) {
    
    if (object_handle == NULL || slot_name == NULL) {
        set_bridge_error("Object handle and slot name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }
#ifndef HAVE_IOVM
    set_bridge_error("IoVM integration not available in this build");
    return BRIDGE_ERROR_INVALID_HANDLE;
#else
    IoObject* object = (IoObject*)object_handle;
    if (object == NULL) {
        set_bridge_error("Invalid Io object handle");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoState* state = IoObject_state(object);
    if (state == NULL) {
        set_bridge_error("Io object has no associated state");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoSymbol* slot_symbol = IoState_symbolWithCString_(state, slot_name);
    if (slot_symbol == NULL) {
        set_bridge_error("Failed to resolve slot symbol '%s'", slot_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    IoObject* value = IoObject_getSlot_(object, slot_symbol);
    if (value == NULL) {
        set_bridge_error("Slot '%s' not found on Io object", slot_name);
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    if (result_handle != NULL && result_handle->name != NULL) {
        JSON_Value* result_json = io_object_to_json_value(state, value);
        if (result_json == NULL) {
            set_bridge_error("Failed to serialize Io slot to JSON");
            return BRIDGE_ERROR_PYTHON_EXCEPTION;
        }

        char* serialized = json_serialize_to_string(result_json);
        if (serialized == NULL) {
            json_value_free(result_json);
            set_bridge_error("Failed to serialize JSON result to string");
            return BRIDGE_ERROR_MEMORY_ALLOCATION;
        }

        BridgeResult status = write_json_to_shared_memory(result_handle, serialized, strlen(serialized));
        json_free_serialized_string(serialized);
        json_value_free(result_json);
        return status;
    }

    return BRIDGE_SUCCESS;
#endif
}

BridgeResult bridge_set_slot(
    IoObjectHandle object_handle,
    const char* slot_name,
    const SharedMemoryHandle* value_handle) {
    
    if (object_handle == NULL || slot_name == NULL) {
        set_bridge_error("Object handle and slot name cannot be NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }
#ifndef HAVE_IOVM
    set_bridge_error("IoVM integration not available in this build");
    return BRIDGE_ERROR_INVALID_HANDLE;
#else
    if (value_handle == NULL || value_handle->name == NULL) {
        set_bridge_error("Shared memory handle for value is NULL");
        return BRIDGE_ERROR_NULL_POINTER;
    }

    IoObject* object = (IoObject*)object_handle;
    if (object == NULL) {
        set_bridge_error("Invalid Io object handle");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoState* state = IoObject_state(object);
    if (state == NULL) {
        set_bridge_error("Io object has no associated state");
        return BRIDGE_ERROR_INVALID_HANDLE;
    }

    IoSymbol* slot_symbol = IoState_symbolWithCString_(state, slot_name);
    if (slot_symbol == NULL) {
        set_bridge_error("Failed to resolve slot symbol '%s'", slot_name);
        return BRIDGE_ERROR_MEMORY_ALLOCATION;
    }

    char* value_json = NULL;
    JSON_Value* root = NULL;
    BridgeResult status = read_json_from_shared_memory(value_handle, &value_json, NULL);
    if (status != BRIDGE_SUCCESS) {
        goto cleanup;
    }

    root = json_parse_string(value_json);
    if (root == NULL) {
        set_bridge_error("Shared memory value must encode valid JSON");
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    IoObject* value_object = json_value_to_io_object(state, root);
    if (value_object == NULL) {
        set_bridge_error("Unsupported value type for slot '%s'", slot_name);
        status = BRIDGE_ERROR_SHARED_MEMORY;
        goto cleanup;
    }

    IoObject_setSlot_to_(object, slot_symbol, value_object);
    status = BRIDGE_SUCCESS;

cleanup:
    if (root) {
        json_value_free(root);
    }
    if (value_json) {
        free(value_json);
    }
    return status;
#endif
}

BridgeResult bridge_pin_object_impl(IoObjectHandle handle) {
    // Stub implementation - Io object pinning not yet implemented
    (void)handle;
    return BRIDGE_SUCCESS;
}

BridgeResult bridge_unpin_object_impl(IoObjectHandle handle) {
    // Stub implementation - Io object unpinning not yet implemented
    (void)handle;
    return BRIDGE_SUCCESS;
}