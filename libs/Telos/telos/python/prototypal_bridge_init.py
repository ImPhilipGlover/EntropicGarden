#!/usr/bin/env python3
"""
TELOS Prototypal Bridge Initialization Module

This module contains the initialization and shutdown functions for the prototypal bridge.
Extracted from prototypal_bridge.py for modularization compliance.
"""

import logging
from typing import Any, Dict, Optional

logger = logging.getLogger(__name__)


def initialize_bridge(
    lib: Any,
    ffi: Any,
    _initialized: bool,
    _log_callback_cfunc: Any,
    worker_count: int
) -> tuple[bool, Any]:
    """
    Initialize the prototypal bridge system.

    Args:
        lib: CFFI library instance
        ffi: CFFI FFI instance
        _initialized: Current initialization state
        _log_callback_cfunc: Log callback function
        worker_count: Number of workers to initialize

    Returns:
        Tuple of (success, log_callback_cfunc)
    """
    if _initialized:
        return True, _log_callback_cfunc

    if worker_count <= 0:
        logger.warning(
            "Invalid bridge worker count %s provided; defaulting to 1 to satisfy C ABI contract",
            worker_count,
        )
        worker_count = 1

    try:
        # Create log callback function
        @ffi.callback("void(int, const char*)")
        def log_callback(level, message):
            msg = ffi.string(message).decode("utf-8", "replace")
            if level == 0:  # DEBUG
                logger.debug(msg)
            elif level == 1:  # INFO
                logger.info(msg)
            elif level == 2:  # WARNING
                logger.warning(msg)
            elif level == 3:  # ERROR
                logger.error(msg)
            else:
                logger.info(msg)  # Default to info

        _log_callback_cfunc = log_callback

        # Create BridgeConfig struct
        config = ffi.new("BridgeConfig*", {
            'max_workers': worker_count,
            'log_callback': _log_callback_cfunc
        })

        # Initialize the core bridge
        result = lib.bridge_initialize(config)
        if result == lib.BRIDGE_SUCCESS:
            logger.info("Prototypal Bridge Manager initialized successfully")
            return True, _log_callback_cfunc
        else:
            logger.error(f"Bridge initialization failed with code: {result}")
            return False, None
    except Exception as e:
        logger.error(f"Exception during bridge initialization: {e}")
        return False, None


def shutdown_bridge(
    lib: Any,
    _initialized: bool,
    _log_callback_cfunc: Any,
    _proxy_registry: Dict[str, Any]
) -> tuple[bool, Any]:
    """
    Shutdown the prototypal bridge system.

    Args:
        lib: CFFI library instance
        _initialized: Current initialization state
        _log_callback_cfunc: Log callback function
        _proxy_registry: Registry of active proxies

    Returns:
        Tuple of (success, log_callback_cfunc)
    """
    if not _initialized:
        return True, _log_callback_cfunc

    try:
        # Clean up all active proxies
        for proxy_id in list(_proxy_registry.keys()):
            # Note: destroy_proxy logic would need to be passed in or duplicated
            # For now, just unpin handles
            proxy_state = _proxy_registry.get(proxy_id)
            if proxy_state:
                try:
                    lib.bridge_unpin_object(proxy_state['io_master_handle'])
                except Exception as e:
                    logger.error(f"Failed to unpin proxy {proxy_id}: {e}")

        # Shutdown the core bridge
        lib.bridge_shutdown()
        _initialized = False
        _log_callback_cfunc = None
        logger.info("Prototypal Bridge Manager shutdown complete")
        return True, None
    except Exception as e:
        logger.error(f"Exception during bridge shutdown: {e}")
        return False, _log_callback_cfunc