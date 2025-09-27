"""End-to-end validation for bridge_send_message via Python forwarder."""

import ctypes
import sys
from pathlib import Path

import _telos_bridge
from _telos_bridge import ffi, lib
from prototypal_bridge import (
    _global_bridge_manager,
    initialize_prototypal_bridge,
    shutdown_prototypal_bridge,
)


def _locate_telos_core() -> Path:
    module_path = Path(_telos_bridge.__file__).resolve()
    candidates = {
        "win32": "telos_core.dll",
        "darwin": "libtelos_core.dylib",
    }
    if sys.platform not in candidates:
        lib_name = "libtelos_core.so"
    else:
        lib_name = candidates[sys.platform]
    return module_path.parent / lib_name


def _load_iovm() -> ctypes.CDLL:
    lib_path = _locate_telos_core()
    if not lib_path.exists():
        raise RuntimeError(f"Unable to locate telos_core library at {lib_path}")
    return ctypes.CDLL(str(lib_path))


def test_forward_message_roundtrip() -> None:
    iovm = _load_iovm()

    iovm.IoState_new.restype = ctypes.c_void_p
    iovm.IoState_free.argtypes = [ctypes.c_void_p]
    iovm.IoState_argc_argv_.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    iovm.IoState_lobby.argtypes = [ctypes.c_void_p]
    iovm.IoState_lobby.restype = ctypes.c_void_p

    state_ptr = iovm.IoState_new()
    assert state_ptr, "IoState_new returned NULL"

    try:
        iovm.IoState_argc_argv_(state_ptr, 0, None)

        lib.bridge_clear_error()
        init_status = lib.bridge_initialize(1)
        assert init_status == lib.BRIDGE_SUCCESS, "bridge_initialize failed"

        assert initialize_prototypal_bridge(), "Python bridge initialization failed"

        lobby_ptr = iovm.IoState_lobby(state_ptr)
        assert lobby_ptr, "IoState_lobby returned NULL"

        forward_message = _global_bridge_manager['forward_message']
        io_handle = ffi.cast("IoObjectHandle", lobby_ptr)
        response = forward_message(io_handle, "type", ())
        assert response == "Object", f"Unexpected response from Io: {response!r}"

    finally:
        shutdown_prototypal_bridge()
        lib.bridge_shutdown()
        iovm.IoState_free(state_ptr)


if __name__ == "__main__":
    test_forward_message_roundtrip()
