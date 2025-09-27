"""Synaptic bridge smoke tests.

Ensures the compiled `_telos_bridge` module can load the canonical C
implementation and execute basic lifecycle calls without segmentation faults.
"""

from __future__ import annotations

import sys
import unittest
from multiprocessing import shared_memory
from pathlib import Path

MODULE_ROOT = Path(__file__).resolve().parents[1] / "Telos" / "python"
if str(MODULE_ROOT) not in sys.path:
    sys.path.insert(0, str(MODULE_ROOT))


class SynapticBridgeSmokeTest(unittest.TestCase):
    """Minimal lifecycle checks executed against the shared C bridge."""

    @classmethod
    def setUpClass(cls) -> None:
        from _telos_bridge import ffi, lib

        cls.ffi = ffi
        cls.lib = lib

    def test_initialize_and_shutdown_stub_mode(self) -> None:
        ffi = self.ffi
        lib = self.lib

        # Clear any prior error state and confirm buffer empty
        lib.bridge_clear_error()
        buf = ffi.new("char[256]")
        self.assertEqual(lib.bridge_get_last_error(buf, len(buf)), 0)
        self.assertEqual(ffi.string(buf), b"")

        # Initialize with stub workers. Even in stub mode we should receive success.
        result = lib.bridge_initialize(1)
        self.assertEqual(result, 0)

        # Retrieve the informational message populated during stub initialization.
        lib.bridge_get_last_error(buf, len(buf))
        message = ffi.string(buf)
        self.assertTrue(b"stub mode" in message or message == b"")

        # Shut down cleanly and ensure no error residue remains.
        lib.bridge_shutdown()
        lib.bridge_clear_error()
        lib.bridge_get_last_error(buf, len(buf))
        self.assertEqual(ffi.string(buf), b"")

    def test_shared_memory_roundtrip(self) -> None:
        ffi = self.ffi
        lib = self.lib

        # Ensure bridge is initialized
        lib.bridge_clear_error()
        result = lib.bridge_initialize(1)
        self.assertEqual(result, lib.BRIDGE_SUCCESS)

        handle = ffi.new("SharedMemoryHandle *")
        allocation_result = lib.bridge_create_shared_memory(1024, handle)
        self.assertEqual(allocation_result, lib.BRIDGE_SUCCESS)
        self.assertNotEqual(handle[0].name, ffi.NULL)

        mapped_ptr = ffi.new("void **")
        map_result = lib.bridge_map_shared_memory(handle, mapped_ptr)
        self.assertEqual(map_result, lib.BRIDGE_SUCCESS)
        self.assertNotEqual(mapped_ptr[0], ffi.NULL)

        # Populate the shared segment with a deterministic pattern
        buffer = ffi.buffer(mapped_ptr[0], handle[0].size)
        pattern = bytes(range(64)) * 16  # 1024 bytes
        buffer[:] = pattern

        # Attach via Python shared_memory to validate zero-copy visibility
        name = ffi.string(handle[0].name).decode()
        mirror = shared_memory.SharedMemory(name=name, create=False)
        try:
            self.assertEqual(bytes(mirror.buf[: len(pattern)]), pattern)
        finally:
            mirror.close()

        unmap_result = lib.bridge_unmap_shared_memory(handle, mapped_ptr[0])
        self.assertEqual(unmap_result, lib.BRIDGE_SUCCESS)

        destroy_result = lib.bridge_destroy_shared_memory(handle)
        self.assertEqual(destroy_result, lib.BRIDGE_SUCCESS)
        self.assertEqual(handle[0].name, ffi.NULL)

        lib.bridge_shutdown()


if __name__ == "__main__":
    unittest.main()
