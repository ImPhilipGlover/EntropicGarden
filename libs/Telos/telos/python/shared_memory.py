"""
TELOS Shared Memory Management

Shared memory lifecycle management following architec        try:
            import multiprocessing.shared_memory as shared_memory
            shm = manager._manager.SharedMemory(size=size)
            handle = create_shared_memory_handle(name=shm.name, offset=0, size=size)
            manager.managed_blocks[shm.name] = shm
            return handlemandates.
"""

import multiprocessing
import multiprocessing.managers
import logging
from typing import Dict, Any

from .worker_exceptions import TelosWorkerError
from .uvm_object import create_uvm_object


def create_shared_memory_handle(name: str, offset: int = 0, size: int = 0) -> Any:
    """
    Create a handle for shared memory blocks used for zero-copy IPC.
    Corresponds to the C struct SharedMemoryHandle in synaptic_bridge.h
    """
    return create_uvm_object({
        'name': name,
        'offset': offset,
        'size': size,
    })


def create_shared_memory_manager() -> Any:
    """
    Create a manager for shared memory lifecycle following the architectural mandates.

    The architectural blueprints specify that the SharedMemoryManager process
    is the sole owner and is responsible for calling unlink() on shutdown.
    All other consumer processes must only call close().

    CRITICAL: This class must handle the case where worker processes (which are
    daemon processes) cannot create their own SharedMemoryManager instances.
    """
    
    # Create the manager object
    manager = create_uvm_object({
        'managed_blocks': {},
        '_is_main_process': False,
        '_manager': None,
    })
    
    # Initialize the manager (equivalent to __init__)
    def _init_manager():
        # Check if we're in the main process by trying to create a manager
        manager._is_main_process = False
        manager._manager = None

        # Try to determine if we can create a SharedMemoryManager
        # Only the main process can do this
        try:
            # This will fail in daemon processes (workers)
            test_manager = multiprocessing.managers.SharedMemoryManager()
            test_manager.start()
            test_manager.shutdown()  # Clean up test manager

            # If we get here, we can create the real manager
            manager._manager = multiprocessing.managers.SharedMemoryManager()
            manager._manager.start()
            manager._is_main_process = True

        except (AssertionError, RuntimeError) as e:
            if "daemonic processes" in str(e) or "cannot start" in str(e):
                # Worker process - cannot create SharedMemoryManager
                manager._manager = None
                manager._is_main_process = False
            else:
                raise
    
    # Initialize the manager
    _init_manager()
    
    # Add methods to the manager object
    def create_block(size: int) -> Any:
        """Create a new shared memory block (main process only)."""
        if not manager['_is_main_process']:
            # Worker processes should create blocks directly using multiprocessing.shared_memory
            # This is allowed even in daemon processes
            try:
                import multiprocessing.shared_memory as shared_memory
                shm = shared_memory.SharedMemory(create=True, size=size)
                handle = create_shared_memory_handle(name=shm.name, offset=0, size=size)
                # Store the reference but mark it as worker-created
                manager.managed_blocks[shm.name] = shm
                return handle
            except Exception as e:
                raise TelosWorkerError(f"Worker process failed to create shared memory block: {e}")

        try:
            import multiprocessing.shared_memory as shared_memory
            shm = manager['_manager'].SharedMemory(size=size)
            handle = create_shared_memory_handle(name=shm.name, offset=0, size=size)
            manager['managed_blocks'][shm.name] = shm
            return handle
        except Exception as e:
            raise TelosWorkerError(f"Failed to create shared memory block: {e}")

    def get_block(handle: Any):
        """Get an existing shared memory block by handle."""
        if handle['name'] in manager.managed_blocks:
            return manager.managed_blocks[handle['name']]

        try:
            # Attach to existing block (works in both main and worker processes)
            import multiprocessing.shared_memory as shared_memory
            shm = shared_memory.SharedMemory(name=handle['name'], create=False)
            # Cache the reference but don't store it permanently in workers
            if manager._is_main_process:
                manager.managed_blocks[handle['name']] = shm
            return shm
        except Exception as e:
            raise TelosWorkerError(f"Failed to attach to shared memory block {handle['name']}: {e}")

    def cleanup():
        """Clean up all managed blocks. Called on shutdown."""
        for name, shm in manager.managed_blocks.items():
            try:
                if manager._is_main_process:
                    # Main process should unlink to actually free the memory
                    try:
                        shm.unlink()
                    except Exception as e:
                        logging.warning(f"Error unlinking shared memory block {name}: {e}")
                shm.close()  # All processes should close their references
            except Exception as e:
                logging.warning(f"Error closing shared memory block {name}: {e}")

        manager.managed_blocks.clear()

        # Only shutdown the manager if we created it (main process)
        if manager._is_main_process and manager._manager is not None:
            try:
                manager._manager.shutdown()
            except Exception as e:
                logging.warning(f"Error shutting down SharedMemoryManager: {e}")
    
    # Attach methods to the manager object
    manager.create_block = create_block
    manager.get_block = get_block
    manager.cleanup = cleanup
    
    return manager