"""
Shared memory utilities for `prototypal_bridge.py` extracted to reduce module size.
These functions handle low-level shared memory operations with the C bridge.
"""

from typing import Any
import sys

try:
    # Try absolute import first
    try:
        import _telos_bridge  # type: ignore
        ffi = _telos_bridge.ffi
        lib = _telos_bridge.lib
    except ImportError:
        # Fall back to relative import (when used as package)
        from . import _telos_bridge
        ffi = _telos_bridge.ffi
        lib = _telos_bridge.lib
except ImportError:
    # For testing purposes, create mock objects
    class MockFFI:
        def __init__(self):
            pass
    class MockLib:
        BRIDGE_SUCCESS = 0
        BRIDGE_ERROR_NULL_POINTER = -1
        def bridge_create_shared_memory(self, size, handle): return self.BRIDGE_SUCCESS
        def bridge_destroy_shared_memory(self, handle): pass
        def bridge_map_shared_memory(self, handle, ptr): return self.BRIDGE_SUCCESS
        def bridge_unmap_shared_memory(self, handle, ptr): return self.BRIDGE_SUCCESS
        def bridge_get_last_error(self, buf, size): return self.BRIDGE_SUCCESS

    ffi = MockFFI()
    lib = MockLib()
    print("WARNING: Using mock bridge for testing - full functionality not available", file=sys.stderr)


def _bridge_error_message() -> str:
    """Get the last error message from the bridge."""
    buf = ffi.new("char[1024]")
    lib.bridge_get_last_error(buf, len(buf))
    return ffi.string(buf).decode("utf-8", "replace")


def _create_shared_memory(size: int):
    """Create a new shared memory block."""
    handle = ffi.new("SharedMemoryHandle *")
    result = lib.bridge_create_shared_memory(size, handle)
    if result != lib.BRIDGE_SUCCESS:
        error_text = _bridge_error_message()
        raise RuntimeError(f"Failed to create shared memory ({result}): {error_text}")
    return handle


def _destroy_shared_memory(handle) -> None:
    """Destroy a shared memory block."""
    if handle is None:
        return
    lib.bridge_destroy_shared_memory(handle)


def _write_bytes_to_shared_memory(handle, payload: bytes) -> None:
    """Write bytes to a shared memory block."""
    mapped_ptr = ffi.new("void **")
    status = lib.bridge_map_shared_memory(handle, mapped_ptr)
    if status != lib.BRIDGE_SUCCESS:
        error_text = _bridge_error_message()
        raise RuntimeError(f"Failed to map shared memory for write ({status}): {error_text}")

    buffer = ffi.buffer(mapped_ptr[0], handle[0].size)
    buffer[:] = b"\x00" * handle[0].size
    buffer[: len(payload)] = payload

    unmap_status = lib.bridge_unmap_shared_memory(handle, mapped_ptr[0])
    if unmap_status != lib.BRIDGE_SUCCESS:
        error_text = _bridge_error_message()
        raise RuntimeError(f"Failed to unmap shared memory after write ({unmap_status}): {error_text}")


def _read_cstring_from_shared_memory(handle) -> str:
    """Read a C string from a shared memory block."""
    mapped_ptr = ffi.new("void **")
    status = lib.bridge_map_shared_memory(handle, mapped_ptr)
    if status != lib.BRIDGE_SUCCESS:
        error_text = _bridge_error_message()
        raise RuntimeError(f"Failed to map shared memory for read ({status}): {error_text}")

    data = ffi.string(ffi.cast("char *", mapped_ptr[0]), handle[0].size)
    unmap_status = lib.bridge_unmap_shared_memory(handle, mapped_ptr[0])
    if unmap_status != lib.BRIDGE_SUCCESS:
        error_text = _bridge_error_message()
        raise RuntimeError(f"Failed to unmap shared memory after read ({unmap_status}): {error_text}")

    return data.decode("utf-8", "replace")