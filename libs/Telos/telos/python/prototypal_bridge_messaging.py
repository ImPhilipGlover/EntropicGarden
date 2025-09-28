#!/usr/bin/env python3
"""
TELOS Prototypal Bridge Message Forwarding Module

This module contains the message forwarding functions for the prototypal bridge.
Extracted from prototypal_bridge.py for modularization compliance.
"""

import json
import time
from typing import Any, Optional


def forward_message_to_io(
    lib: Any,
    ffi: Any,
    io_handle: Any,
    message_name: str,
    args: Optional[tuple],
    _create_shared_memory: callable,
    _write_bytes_to_shared_memory: callable,
    _read_cstring_from_shared_memory: callable,
    _bridge_error_message: callable,
    _record_dispatch_for_handle: callable,
) -> Any:
    """
    Forward a message to the Io VM via the synaptic bridge while recording metrics.

    Args:
        lib: CFFI library instance
        ffi: CFFI FFI instance
        io_handle: Io VM handle
        message_name: Name of the message to send
        args: Arguments to pass with the message
        _create_shared_memory: Function to create shared memory
        _write_bytes_to_shared_memory: Function to write to shared memory
        _read_cstring_from_shared_memory: Function to read from shared memory
        _bridge_error_message: Function to get bridge error messages
        _record_dispatch_for_handle: Function to record dispatch metrics

    Returns:
        Parsed response from Io VM
    """
    args_handle = None
    result_handle = None
    success = False
    error_text: Optional[str] = None
    start_time = time.perf_counter()
    timestamp_s = time.time()

    try:
        args_ptr = ffi.NULL
        if args:
            args_list = list(args)
            args_json = json.dumps(args_list, default=_json_fallback)
            payload = (args_json + "\0").encode("utf-8")
            args_handle = _create_shared_memory(max(len(payload), 64))
            _write_bytes_to_shared_memory(args_handle, payload)
            args_ptr = args_handle

        message_bytes = message_name.encode("utf-8") + b"\0"
        result_buffer_size = 4096
        max_buffer_size = 1 << 20  # 1 MiB safety ceiling
        response_text: Optional[str] = None

        while True:
            result_handle = _create_shared_memory(result_buffer_size)
            status = lib.bridge_send_message(
                io_handle,
                message_bytes,
                args_ptr if args_ptr != ffi.NULL else ffi.NULL,
                result_handle,
            )

            if status == lib.BRIDGE_SUCCESS:
                response_text = _read_cstring_from_shared_memory(result_handle)
                break

            error_text = _bridge_error_message()
            _destroy_shared_memory(result_handle)
            result_handle = None

            if (
                status == lib.BRIDGE_ERROR_SHARED_MEMORY
                and "Result buffer too small" in error_text
                and result_buffer_size < max_buffer_size
            ):
                result_buffer_size *= 2
                continue

            raise RuntimeError(f"bridge_send_message failed ({status}): {error_text}")

        parsed_response: Any = None
        if response_text:
            try:
                parsed_response = json.loads(response_text)
            except json.JSONDecodeError:
                parsed_response = response_text

        success = True
        return parsed_response

    except Exception as exc:
        error_text = str(exc)
        raise

    finally:
        duration_ms = max((time.perf_counter() - start_time) * 1000.0, 0.0)
        _record_dispatch_for_handle(io_handle, message_name, success, duration_ms, timestamp_s, error_text)

        if args_handle is not None:
            _destroy_shared_memory(args_handle)
        if result_handle is not None:
            _destroy_shared_memory(result_handle)


def _json_fallback(value: Any) -> Any:
    """JSON serialization fallback for non-serializable values."""
    if isinstance(value, (bytes, bytearray)):
        return value.decode("utf-8", "replace")
    return value


def _destroy_shared_memory(handle: Any) -> None:
    """Destroy shared memory handle - imported from memory module."""
    # This is a placeholder - the actual function is in prototypal_bridge_memory
    pass