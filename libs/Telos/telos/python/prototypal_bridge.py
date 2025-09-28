#!/usr/bin/env python3
"""
TELOS Prototypal Emulation Layer Integration

This module provides the Python-side integration for the Prototypal Emulation Layer,
making IoProxy objects available for transparent Io-Python interaction through the
Synaptic Bridge. It implements the bridge between CFFI's function-only interface and
the full prototypal proxy system mandated by the architectural blueprints.

Following the architectural mandate for prototypal behavior, this module provides
factory functions that return method dictionaries, avoiding class-based abstractions
in the external interface.
"""

import json
import logging
from pathlib import Path
import sys
import time
import math
import copy
from typing import Any, Dict, Iterable, List, Optional, Union

# Import UvmObject for prototypal patterns
try:
    from uvm_object import create_uvm_object
except ImportError:
    # Fallback for direct execution
    import sys
    import os
    sys.path.insert(0, os.path.dirname(__file__))
    from uvm_object import create_uvm_object

# Ensure the package path is available for imports
_current_dir = Path(__file__).parent
if str(_current_dir) not in sys.path:
    sys.path.insert(0, str(_current_dir))

try:
    from .prototypal_bridge_utils import (
        _initialize_latency_buckets,
        _compute_percentiles,
        _LATENCY_BUCKET_LABELS,
        _LATENCY_TERMINAL_LABEL,
        _LATENCY_BUCKET_BOUNDS,
        _ALL_LATENCY_BUCKET_LABELS,
    )
    from .prototypal_bridge_memory import (
        _bridge_error_message,
        _create_shared_memory,
        _destroy_shared_memory,
        _write_bytes_to_shared_memory,
        _read_cstring_from_shared_memory,
    )
    from .prototypal_bridge_metrics import (
        _initialize_metrics_state,
        _copy_metrics_state,
        _record_summary_history,
        _calculate_summary_trend,
        _compute_per_proxy_health,
        _augment_summary_health,
        _summarize_metrics_map,
        _record_dispatch,
        _record_dispatch_for_handle,
        summarize_dispatch_metrics as _summarize_dispatch_metrics,
        get_dispatch_metrics as _get_dispatch_metrics,
        reset_dispatch_metrics as _reset_dispatch_metrics,
    )
    from .prototypal_bridge_analysis import (
        analyze_dispatch_metrics as _analyze_dispatch_metrics,
    )
    from .prototypal_bridge_messaging import (
        forward_message_to_io as _forward_message_to_io,
        _json_fallback,
    )
    from .prototypal_bridge_proxy import (
        create_proxy_interface as _create_proxy_interface,
        create_proxy as _create_proxy,
    )
    from .prototypal_bridge_cache import (
        create_transparent_cache_proxy as _create_transparent_cache_proxy,
    )
    from .prototypal_bridge_manager import create_prototypal_bridge_manager
except ImportError:
    from prototypal_bridge_utils import (  # type: ignore
        _initialize_latency_buckets,
        _compute_percentiles,
        _LATENCY_BUCKET_LABELS,
        _LATENCY_TERMINAL_LABEL,
        _LATENCY_BUCKET_BOUNDS,
        _ALL_LATENCY_BUCKET_LABELS,
    )
    from prototypal_bridge_memory import (  # type: ignore
        _bridge_error_message,
        _create_shared_memory,
        _destroy_shared_memory,
        _write_bytes_to_shared_memory,
        _read_cstring_from_shared_memory,
    )
    from prototypal_bridge_metrics import (  # type: ignore
        _initialize_metrics_state,
        _copy_metrics_state,
        _record_summary_history,
        _calculate_summary_trend,
        _compute_per_proxy_health,
        _augment_summary_health,
        _summarize_metrics_map,
        _record_dispatch,
        _record_dispatch_for_handle,
        summarize_dispatch_metrics as _summarize_dispatch_metrics,
        get_dispatch_metrics as _get_dispatch_metrics,
        reset_dispatch_metrics as _reset_dispatch_metrics,
    )
    from prototypal_bridge_analysis import (  # type: ignore
        analyze_dispatch_metrics as _analyze_dispatch_metrics,
    )
    from prototypal_bridge_messaging import (  # type: ignore
        forward_message_to_io as _forward_message_to_io,
        _json_fallback,
    )
    from prototypal_bridge_proxy import (  # type: ignore
        create_proxy_interface as _create_proxy_interface,
        create_proxy as _create_proxy,
    )
    from prototypal_bridge_cache import (  # type: ignore
        create_transparent_cache_proxy as _create_transparent_cache_proxy,
    )
    from prototypal_bridge_manager import create_prototypal_bridge_manager  # type: ignore

# Import the CFFI bridge
try:
    # Try relative import first (when used as package)
    try:
        from . import _telos_bridge
        ffi = _telos_bridge.ffi
        lib = _telos_bridge.lib
    except ImportError:
        # Fall back to direct import (when run as standalone)
        import _telos_bridge  # type: ignore
        ffi = _telos_bridge.ffi
        lib = _telos_bridge.lib
except ImportError:
    # For testing purposes, create mock objects using UvmObject factory functions
    def create_mock_ffi():
        """Create a mock FFI object using UvmObject factory."""
        return create_uvm_object({
            '__init__': lambda self: None,
        })

    def create_mock_lib():
        """Create a mock library object using UvmObject factory."""
        return create_uvm_object({
            'BRIDGE_SUCCESS': 0,
            'BRIDGE_ERROR_NULL_POINTER': -1,
            'bridge_initialize': lambda self, workers: self['BRIDGE_SUCCESS'],
            'bridge_shutdown': lambda self: None,
            'bridge_pin_object': lambda self, handle: self['BRIDGE_SUCCESS'],
            'bridge_unpin_object': lambda self, handle: self['BRIDGE_SUCCESS'],
        })
    
    ffi = create_mock_ffi()
    lib = create_mock_lib()
    print("WARNING: Using mock bridge for testing - full functionality not available", file=sys.stderr)

# Set up logging
logger = logging.getLogger(__name__)

# Latency bucket helpers are extracted into prototypal_bridge_utils for modularization


# Global manager instance (initialized on first import)
_global_bridge_manager = create_prototypal_bridge_manager()

# Export the prototypal interface functions
def initialize_prototypal_bridge(options=None):
    """Initialize the global prototypal bridge manager."""
    return _global_bridge_manager['initialize'](options)

def shutdown_prototypal_bridge():
    """Shutdown the global prototypal bridge manager."""
    return _global_bridge_manager['shutdown']()

def create_io_proxy(io_handle, object_id=None):
    """Create a new IoProxy from an Io VM handle."""
    return _global_bridge_manager['create_proxy'](io_handle, object_id)

def get_bridge_status():
    """Get the current bridge status."""
    return _global_bridge_manager['get_status']()


def get_dispatch_metrics(proxy_id: Optional[str] = None):
    """Retrieve dispatch metrics for a specific proxy or all proxies."""
    return _global_bridge_manager['get_dispatch_metrics'](proxy_id)


def reset_dispatch_metrics(proxy_id: Optional[str] = None) -> bool:
    """Reset dispatch metrics for a specific proxy or all proxies."""
    return _global_bridge_manager['reset_dispatch_metrics'](proxy_id)


def summarize_dispatch_metrics(proxy_ids: Optional[Iterable[str]] = None) -> Dict[str, Any]:
    """Aggregate dispatch metrics across selected proxies (or all proxies)."""
    return _global_bridge_manager['summarize_dispatch_metrics'](proxy_ids)


def analyze_dispatch_metrics(
    proxy_ids: Optional[Iterable[str]] = None,
    analysis_options: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Derive anomaly and remediation guidance for bridge dispatch metrics."""
    return _global_bridge_manager['analyze_dispatch_metrics'](proxy_ids, analysis_options)


def get_summary_history(limit: Optional[Union[int, str]] = None) -> List[Dict[str, Any]]:
    """Expose the recorded summary history."""
    return _global_bridge_manager['get_summary_history'](limit)


def clear_summary_history() -> bool:
    """Clear accumulated summary history."""
    return bool(_global_bridge_manager['clear_summary_history']())


def configure_summary_history(options: Optional[Union[int, Dict[str, Any]]] = None) -> Dict[str, Any]:
    """Configure summary history retention and return the active settings."""
    return _global_bridge_manager['configure_summary_history'](options)


def create_transparent_cache_proxy(cache_manager_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Create a transparent proxy for cache operations."""
    return _create_transparent_cache_proxy(cache_manager_dict)


if __name__ == "__main__":
    # Simple test of the prototypal bridge
    print("Testing TELOS Prototypal Bridge...")
    
    # Initialize
    if initialize_prototypal_bridge():
        print("✅ Bridge initialized successfully")
        
        # Get status
        status = get_bridge_status()
        print(f"📊 Status: {status}")
        
        # TODO: Create test proxy when IoVM integration is ready
        
        # Shutdown
        shutdown_prototypal_bridge()
        print("✅ Bridge shutdown successfully")
    else:
        print("❌ Bridge initialization failed")
        sys.exit(1)