#!/usr/bin/env python3
"""
TELOS Prototypal Bridge Proxy Interface Module

This module contains the proxy interface creation functions for the prototypal bridge.
Extracted from prototypal_bridge.py for modularization compliance.
"""

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


def create_proxy_interface(
    proxy_state: Dict[str, Any],
    forward_message_to_io_func: callable,
    proxy_registry: Dict[str, Dict[str, Any]]
) -> Dict[str, Any]:
    """
    Create the prototypal method interface for a proxy object.

    This implements the IoProxy behavior using a method dictionary,
    following the architectural mandate for prototypal interfaces.

    Args:
        proxy_state: The proxy state dictionary
        forward_message_to_io_func: Function to forward messages to Io
        proxy_registry: Registry of active proxies

    Returns:
        Dict containing the prototypal interface methods
    """

    def get_attribute(name: str) -> Any:
        """
        Get an attribute using prototypal delegation.

        First checks local slots, then delegates to the Io master object.
        """
        # Check local slots first (differential inheritance)
        if name in proxy_state['local_slots']:
            return proxy_state['local_slots'][name]

        # Delegate to master object via bridge
        try:
            return forward_message_to_io_func(proxy_state['io_master_handle'], name, None)
        except Exception as e:
            logger.warning(f"Failed to delegate '{name}' to Io master: {e}")
            raise AttributeError(f"'{proxy_state['object_id']}' object has no attribute '{name}'")

    def set_attribute(name: str, value: Any) -> bool:
        """
        Set an attribute using transactional local storage.

        Stores in local slots for immediate availability while optionally
        propagating to the master object for persistence.
        """
        try:
            # Store in local slots (differential inheritance)
            proxy_state['local_slots'][name] = value

            # TODO: Phase 2 enhancement - propagate to master object via transactional protocol
            # This would involve WAL logging and eventual consistency with the L3 ground truth

            return True
        except Exception as e:
            logger.error(f"Failed to set attribute '{name}': {e}")
            return False

    def clone() -> Any:
        """
        Create a prototypal clone of this proxy.

        The clone delegates to the same master but has independent local slots.
        """
        clone_id = f"{proxy_state['object_id']}_clone_{len(proxy_registry)}"

        # Create clone with same master handle but fresh local slots
        clone_state = {
            'io_master_handle': proxy_state['io_master_handle'],
            'object_id': clone_id,
            'local_slots': {},  # Empty for differential inheritance
            'metrics': _initialize_metrics_state(),
            'ref_count': 1
        }

        # Pin the handle again for the clone
        try:
            pin_result = lib.bridge_pin_object(clone_state['io_master_handle'])
            if pin_result != lib.BRIDGE_SUCCESS:
                logger.error(f"Failed to pin handle for clone: {pin_result}")
                return None

            # Register the clone
            proxy_registry[clone_id] = clone_state

            return create_proxy_interface(clone_state, forward_message_to_io_func, proxy_registry)
        except Exception as e:
            logger.error(f"Failed to create clone: {e}")
            return None

    def send_message(message_name: str, *args) -> Any:
        """
        Send a message to the master Io object via the bridge.
        """
        return forward_message_to_io_func(proxy_state['io_master_handle'], message_name, args)

    def get_master_handle() -> Any:
        """Get the Io VM master handle for inspection."""
        return proxy_state['io_master_handle']

    def get_object_id() -> str:
        """Get the unique object identifier."""
        return proxy_state['object_id']

    def get_local_slots() -> Dict[str, Any]:
        """Get the local slots dictionary."""
        return proxy_state['local_slots'].copy()

    def destroy() -> bool:
        """Clean up the proxy and unpin the master handle."""
        try:
            # Unpin the master handle
            lib.bridge_unpin_object(proxy_state['io_master_handle'])

            # Remove from registry
            if proxy_state['object_id'] in proxy_registry:
                del proxy_registry[proxy_state['object_id']]

            logger.debug(f"Destroyed proxy {proxy_state['object_id']}")
            return True
        except Exception as e:
            logger.error(f"Failed to destroy proxy {proxy_state['object_id']}: {e}")
            return False

    def get_dispatch_metrics() -> Any:
        """Return a snapshot of dispatch metrics for this proxy."""
        return _copy_metrics_state(proxy_state.get('metrics'))

    def reset_dispatch_metrics() -> Any:
        """Reset dispatch metrics for this proxy and return the cleared state."""
        proxy_state['metrics'] = _initialize_metrics_state()
        return _copy_metrics_state(proxy_state['metrics'])

    # Return the prototypal interface
    return {
        # Core prototypal operations
        'getattr': get_attribute,
        'setattr': set_attribute,
        'clone': clone,
        'send_message': send_message,

        # Inspection methods
        'get_master_handle': get_master_handle,
        'get_object_id': get_object_id,
        'get_local_slots': get_local_slots,
        'get_dispatch_metrics': get_dispatch_metrics,
        'reset_dispatch_metrics': reset_dispatch_metrics,

        # Lifecycle management
        'destroy': destroy,

        # Internal state (for debugging/validation)
        '_proxy_state': proxy_state
    }


def create_proxy(
    io_handle: Any,
    object_id: Optional[str],
    lib: Any,
    ffi: Any,
    _initialized: bool,
    _proxy_registry: Dict[str, Any],
    _initialize_metrics_state: callable,
    _create_proxy_interface: callable,
    forward_message_to_io_func: callable
) -> Optional[Dict[str, Any]]:
    """
    Create a new IoProxy object from an Io VM handle.

    This implements the TelosProxyObject creation protocol, returning a prototypal
    interface (method dictionary) rather than a class instance.

    Args:
        io_handle: Handle to the Io object to wrap
        object_id: Optional unique identifier for tracking
        lib: CFFI library instance
        ffi: CFFI FFI instance
        _initialized: Bridge initialization flag
        _proxy_registry: Registry of active proxies
        _initialize_metrics_state: Function to initialize metrics
        _create_proxy_interface: Function to create proxy interface
        forward_message_to_io_func: Function to forward messages

    Returns:
        dict: Prototypal IoProxy interface, or None on failure
    """
    if not _initialized:
        logger.error("Bridge not initialized - cannot create proxy")
        return None

    try:
        # Pin the Io object to prevent GC
        pin_result = lib.bridge_pin_object(io_handle)
        if pin_result != lib.BRIDGE_SUCCESS:
            logger.error(f"Failed to pin Io object: {pin_result}")
            return None

        # Generate unique proxy ID if not provided
        if not object_id:
            object_id = f"proxy_{id(io_handle)}_{len(_proxy_registry)}"

        # Create the proxy state
        proxy_state = {
            'io_master_handle': io_handle,
            'object_id': object_id,
            'local_slots': {},
            'metrics': _initialize_metrics_state(),
            'ref_count': 1
        }

        # Register the proxy
        _proxy_registry[object_id] = proxy_state

        # Return prototypal interface
        forward_func = lambda msg, args: forward_message_to_io_func(io_handle, msg, args)
        return _create_proxy_interface(proxy_state, forward_func, _proxy_registry)

    except Exception as e:
        logger.error(f"Exception creating proxy: {e}")
        # Cleanup on failure
        try:
            lib.bridge_unpin_object(io_handle)
        except:
            pass
        return None


# Placeholder functions that will be imported
def _initialize_metrics_state():
    """Placeholder - imported from metrics module."""
    pass

def _copy_metrics_state(state):
    """Placeholder - imported from metrics module."""
    pass

# Placeholder lib object
class MockLib:
    BRIDGE_SUCCESS = 0

lib = MockLib()