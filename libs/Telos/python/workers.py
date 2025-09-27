"""
TELOS Synaptic Bridge Python Workers (Prototypal Architecture)

This module implements a prototypal delegation system for Python workers,
emulating Io's prototype-based architecture for efficient message dispatch.
Each worker is a clone of a base prototype that can be extended through
slot assignment rather than inheritance.

This is a foundational implementation that establishes the architecture and will
be expanded as more capabilities are added to the system.
"""

import os
import sys
import logging
import multiprocessing
import multiprocessing.managers
from concurrent import futures
import contextlib
import numpy as np
from typing import Dict, Any, List, Optional, Tuple, Callable, TYPE_CHECKING
from multiprocessing import shared_memory
from dataclasses import dataclass
import json
import traceback
import shutil
import tempfile
import threading
import time
import types
from pathlib import Path

try:
    from .telemetry_store import (
        record_event as record_telemetry_event,
        snapshot_events as snapshot_telemetry_events,
        summarize_conflict_replay,
        build_conflict_replay_event,
        clear_events as clear_telemetry_events,
        DEFAULT_MAX_EVENTS as TELEMETRY_DEFAULT_MAX_EVENTS,
    )
except ImportError:  # pragma: no cover - fallback for direct imports
    from telemetry_store import (  # type: ignore
        record_event as record_telemetry_event,
        snapshot_events as snapshot_telemetry_events,
        summarize_conflict_replay,
        build_conflict_replay_event,
        clear_events as clear_telemetry_events,
        DEFAULT_MAX_EVENTS as TELEMETRY_DEFAULT_MAX_EVENTS,
    )

try:
    from . import prototypal_bridge
except ImportError:  # pragma: no cover - fallback for direct imports
    import prototypal_bridge  # type: ignore

try:
    from .l1_cache_manager import (
        create_l1_cache_manager,
        load_vector_from_shared_memory,
        store_vector_in_shared_memory,
        FAISS_AVAILABLE,
        FAISS_IMPORT_ERROR,
    )
except ImportError:  # pragma: no cover - fallback for direct imports
    from l1_cache_manager import (  # type: ignore
        create_l1_cache_manager,
        load_vector_from_shared_memory,
        store_vector_in_shared_memory,
        FAISS_AVAILABLE,
        FAISS_IMPORT_ERROR,
    )

try:
    from . import opentelemetry_bridge as otel_bridge
except ImportError:  # pragma: no cover - optional dependency path
    otel_bridge = None

try:
    from .llm_transducer import create_llm_transducer
except ImportError:  # pragma: no cover - fallback for direct imports
    from llm_transducer import create_llm_transducer  # type: ignore

if TYPE_CHECKING:
    from multiprocessing import Pool


@dataclass
class SharedMemoryHandle:
    """
    Handle for shared memory blocks used for zero-copy IPC.
    Corresponds to the C struct SharedMemoryHandle in synaptic_bridge.h
    """
    name: str
    offset: int = 0
    size: int = 0


"""
TELOS Synaptic Bridge Python Workers (Prototypal Architecture)

This module implements a prototypal delegation system for Python workers,
emulating Io's prototype-based architecture for efficient message dispatch.
Each worker is a clone of a base prototype that can be extended through
slot assignment rather than inheritance, following the architectural mandates
for systemic wholeness and prototypal emulation.

Based on the Prototypal Emulation Layer Design:
- Workers use differential inheritance (storing only local differences)
- Message forwarding for unresolved operations
- Local slots dictionary for fast cached access
- Identity preservation through prototype chains
"""

import os
import sys
import logging
import multiprocessing
import multiprocessing.managers
import numpy as np
from typing import Dict, Any, List, Optional, Tuple, Callable, TYPE_CHECKING
from multiprocessing import shared_memory
from dataclasses import dataclass
import json
import traceback
import shutil
import tempfile
import time
from pathlib import Path

if TYPE_CHECKING:
    from multiprocessing import Pool

try:
    from .transactional_outbox import (
        create_transactional_outbox,
        create_transactional_outbox_poller,
    )
except ImportError:  # pragma: no cover - fallback for direct imports
    from transactional_outbox import (  # type: ignore
        create_transactional_outbox,
        create_transactional_outbox_poller,
    )

try:
    from .zodb_manager import create_zodb_manager
except ImportError:  # pragma: no cover - fallback for direct imports
    from zodb_manager import create_zodb_manager  # type: ignore

try:
    from . import federated_memory as _federated_memory_module  # type: ignore
except ImportError:  # pragma: no cover - fallback for direct imports
    try:
        import federated_memory as _federated_memory_module  # type: ignore
    except ImportError as exc:  # pragma: no cover - optional dependency path
        _federated_memory_module = None  # type: ignore[assignment]
        FEDERATED_MEMORY_IMPORT_ERROR = str(exc)
    else:
        FEDERATED_MEMORY_IMPORT_ERROR = None
else:
    FEDERATED_MEMORY_IMPORT_ERROR = None


# Global prototype registry - the "Living Image" of worker prototypes
_worker_prototypes: Dict[str, 'PrototypalWorker'] = {}


_telemetry_store_proxy = None
_telemetry_lock_proxy = None
_telemetry_max_events = TELEMETRY_DEFAULT_MAX_EVENTS

_l1_cache_manager = None
_l1_cache_config: Dict[str, Any] = {
    'max_size': 2048,
    'vector_dim': 1536,
    'eviction_threshold': 0.8,
    'index_type': 'Flat',
    'promotion_threshold': 6,
    'promotion_requeue_step': 6,
    'eviction_batch_percent': 0.2,
    'max_promotion_queue': 2048,
}
_l1_cache_lock = threading.Lock()

FEDERATED_MEMORY_AVAILABLE = _federated_memory_module is not None
_federated_memory_lock = threading.Lock()


def _sanitize_trace_context(payload: Any) -> Dict[str, str]:
    if isinstance(payload, dict):
        sanitized: Dict[str, str] = {}
        traceparent = payload.get('traceparent')
        if traceparent is not None:
            value = str(traceparent).strip()
            if value:
                sanitized['traceparent'] = value
        tracestate = payload.get('tracestate')
        if tracestate is not None:
            value = str(tracestate).strip()
            if value:
                sanitized['tracestate'] = value
        return sanitized

    if isinstance(payload, str):
        value = payload.strip()
        if value:
            return {'traceparent': value}

    return {}


def _start_worker_span(operation: Optional[str], trace_context: Dict[str, str], attributes: Dict[str, Any]):
    if not otel_bridge or not otel_bridge.is_enabled():
        return contextlib.nullcontext()

    try:
        from opentelemetry import trace as ot_trace  # type: ignore
        from opentelemetry.trace import SpanKind  # type: ignore
        from opentelemetry.propagate import TraceContextTextMapPropagator  # type: ignore
    except Exception:  # pragma: no cover - OpenTelemetry optional
        return contextlib.nullcontext()

    carrier: Dict[str, str] = {}
    traceparent = trace_context.get('traceparent')
    if traceparent:
        carrier['traceparent'] = traceparent
    tracestate = trace_context.get('tracestate')
    if tracestate:
        carrier['tracestate'] = tracestate

    parent_context = TraceContextTextMapPropagator().extract(carrier=carrier)
    tracer = otel_bridge.get_state().get('tracer') if otel_bridge else None
    if tracer is None:
        tracer = ot_trace.get_tracer('telos.python.workers')

    span_name = f"telos.worker.{operation}" if operation else "telos.worker.operation"
    return tracer.start_as_current_span(
        span_name,
        context=parent_context,
        kind=SpanKind.SERVER,
        attributes=attributes,
    )


def _emit_conflict_replay_opentelemetry(event: Dict[str, Any]) -> None:
    """Emit OpenTelemetry metrics/traces for conflict replay events when available."""

    if not otel_bridge:
        return

    try:
        if otel_bridge.is_enabled():
            otel_bridge.emit_conflict_replay(event)
    except Exception as exc:  # pragma: no cover - defensive logging path
        logging.getLogger("telos.opentelemetry").debug(
            "OpenTelemetry conflict replay emission failed: %s", exc
        )


def configure_telemetry_context(store_proxy, lock_proxy, max_events=None):
    """Configure shared telemetry context for the worker process."""
    global _telemetry_store_proxy, _telemetry_lock_proxy, _telemetry_max_events
    _telemetry_store_proxy = store_proxy
    _telemetry_lock_proxy = lock_proxy

    if max_events is not None:
        try:
            _telemetry_max_events = max(1, int(max_events))
        except Exception:
            _telemetry_max_events = TELEMETRY_DEFAULT_MAX_EVENTS


def _normalize_l1_config(overrides: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    config = dict(_l1_cache_config)
    if not overrides:
        return config

    if 'max_size' in overrides and overrides['max_size'] is not None:
        try:
            config['max_size'] = max(1, int(overrides['max_size']))
        except Exception:
            pass

    if 'vector_dim' in overrides and overrides['vector_dim'] is not None:
        try:
            config['vector_dim'] = max(1, int(overrides['vector_dim']))
        except Exception:
            pass

    if 'eviction_threshold' in overrides and overrides['eviction_threshold'] is not None:
        try:
            value = float(overrides['eviction_threshold'])
            config['eviction_threshold'] = min(0.999, max(0.05, value))
        except Exception:
            pass

    if 'index_type' in overrides and overrides['index_type']:
        config['index_type'] = str(overrides['index_type'])

    if 'promotion_threshold' in overrides and overrides['promotion_threshold'] is not None:
        try:
            config['promotion_threshold'] = max(1, int(overrides['promotion_threshold']))
        except Exception:
            pass

    if 'promotion_requeue_step' in overrides and overrides['promotion_requeue_step'] is not None:
        try:
            config['promotion_requeue_step'] = max(1, int(overrides['promotion_requeue_step']))
        except Exception:
            pass

    if 'eviction_batch_percent' in overrides and overrides['eviction_batch_percent'] is not None:
        try:
            value = float(overrides['eviction_batch_percent'])
            config['eviction_batch_percent'] = min(0.5, max(0.05, value))
        except Exception:
            pass

    if 'max_promotion_queue' in overrides and overrides['max_promotion_queue'] is not None:
        try:
            config['max_promotion_queue'] = max(32, int(overrides['max_promotion_queue']))
        except Exception:
            pass

    return config


def _ensure_l1_cache_manager(overrides: Optional[Dict[str, Any]] = None, reset: bool = False):
    global _l1_cache_manager, _l1_cache_config

    with _l1_cache_lock:
        desired_config = _normalize_l1_config(overrides)
        needs_rebuild = (
            reset
            or _l1_cache_manager is None
            or any(
                desired_config.get(key) != _l1_cache_config.get(key)
                for key in desired_config.keys()
            )
        )

        if needs_rebuild:
            manager = create_l1_cache_manager(
                max_size=int(desired_config['max_size']),
                vector_dim=int(desired_config['vector_dim']),
                eviction_threshold=float(desired_config['eviction_threshold']),
                index_type=str(desired_config['index_type']),
                promotion_threshold=int(desired_config['promotion_threshold']),
                promotion_requeue_step=int(desired_config['promotion_requeue_step']),
                eviction_batch_percent=float(desired_config['eviction_batch_percent']),
                max_promotion_queue=int(desired_config['max_promotion_queue']),
            )
            _l1_cache_manager = manager
            _l1_cache_config = desired_config

        return _l1_cache_manager


def _resolve_shared_memory_name(descriptor: Any, *, label: str) -> Tuple[Optional[str], Optional[str]]:
    if descriptor is None:
        return None, f"missing {label} shared memory descriptor"

    if isinstance(descriptor, str):
        if descriptor.strip():
            return descriptor, None
        return None, f"{label} shared memory name is empty"

    if isinstance(descriptor, dict):
        raw_name = descriptor.get('name')
        if raw_name is None or str(raw_name).strip() == '':
            return None, f"{label} shared memory descriptor missing name"

        offset = descriptor.get('offset')
        if offset not in (None, 0):
            return None, f"{label} shared memory offset {offset} not supported"

        return str(raw_name), None

    return None, f"{label} shared memory descriptor must be a string or map"


def _extract_vector_from_config(config: Dict[str, Any], vector_key: str = 'vector', shm_key: str = 'vector_shm') -> Tuple[Optional[np.ndarray], Optional[str]]:
    if vector_key in config and config[vector_key] is not None:
        try:
            array = np.asarray(config[vector_key], dtype=np.float32)
            if array.ndim == 2 and 1 in array.shape:
                array = array.reshape(-1)
            if array.ndim != 1:
                return None, "vector payload must be one-dimensional"
            return array.copy(), None
        except Exception as exc:
            return None, f"invalid vector payload: {exc}"

    shm_descriptor = config.get(shm_key)
    if shm_descriptor is not None:
        shm_name, shm_error = _resolve_shared_memory_name(shm_descriptor, label=shm_key)
        if shm_error:
            return None, shm_error

        if shm_name:
            vector = load_vector_from_shared_memory(shm_name)
            if vector is None:
                return None, f"unable to load vector from shared memory '{shm_name}'"
            return vector, None

    return None, "missing vector payload"


def _prepare_vector_response(vector: Optional[np.ndarray], options: Dict[str, Any]) -> Tuple[Optional[List[float]], Optional[Dict[str, Any]]]:
    if vector is None:
        return None, None

    prefer_shared = bool(options.get('use_shared_memory'))
    include_vector = bool(options.get('include_vector'))

    if prefer_shared:
        shm_name = store_vector_in_shared_memory(vector)
        if shm_name is not None:
            vector_bytes = vector.astype(np.float32, copy=False)
            descriptor = {
                'name': shm_name,
                'offset': 0,
                'size': int(vector_bytes.size * 4 + 4),
            }
            return None, descriptor

    if include_vector:
        return vector.astype(np.float32).tolist(), None

    return None, None


def _get_federated_memory_interface():
    if not FEDERATED_MEMORY_AVAILABLE or _federated_memory_module is None:
        message = "Federated memory module unavailable"
        if 'FEDERATED_MEMORY_IMPORT_ERROR' in globals() and FEDERATED_MEMORY_IMPORT_ERROR:
            message = f"{message}: {FEDERATED_MEMORY_IMPORT_ERROR}"
        raise TelosWorkerError(message)

    try:
        return _federated_memory_module.get_memory_fabric()
    except Exception as exc:  # pragma: no cover - defensive path
        raise TelosWorkerError(f"Unable to access federated memory fabric: {exc}") from exc


def create_worker_prototype(prototype_name: str, base_prototype: str = None) -> 'PrototypalWorker':
    """
    Create and register a new worker prototype.
    This emulates Io's prototype creation and registration mechanism.
    
    Args:
        prototype_name: Name of the new prototype
        base_prototype: Name of the prototype to clone from (defaults to BaseWorker)
    
    Returns:
        The new prototype instance
    """
    if base_prototype and base_prototype in _worker_prototypes:
        # Clone existing prototype
        prototype = _worker_prototypes[base_prototype].clone(prototype_name)
    else:
        # Create new base prototype
        prototype = PrototypalWorker(prototype_name)
    
    # Register in global prototype registry
    _worker_prototypes[prototype_name] = prototype
    
    return prototype


def get_worker_prototype(prototype_name: str) -> Optional['PrototypalWorker']:
    """Get a registered worker prototype by name."""
    return _worker_prototypes.get(prototype_name)


def extend_worker_prototype(prototype_name: str, slot_name: str, handler_func: Callable):
    """
    Extend a worker prototype with a new operation handler.
    This enables runtime extension of worker capabilities.
    
    Args:
        prototype_name: Name of the prototype to extend
        slot_name: Name of the slot to add (e.g., 'handle_new_operation')
        handler_func: Function to handle the operation
    """
    if prototype_name in _worker_prototypes:
        prototype = _worker_prototypes[prototype_name]
        prototype.set_slot(slot_name, handler_func)
        return True
    return False


class TelosProxyError(Exception):
    """Exception for prototypal delegation errors."""
    pass


class TelosWorkerError(Exception):
    """Base exception for TELOS worker errors."""
    pass


class PrototypalWorker:
    """
    Base prototypal worker implementing differential inheritance.
    
    This class emulates Io's prototypal behavior:
    - Local slots store only differences from the prototype
    - Message forwarding for unresolved operations
    - Clone-based extension rather than class inheritance
    - Identity preservation through prototype chain
    """
    
    def __init__(self, prototype_name: str = "BaseWorker", master_handle=None):
        # Core prototypal identity
        self.prototype_name = prototype_name
        self.master_handle = master_handle  # Link to master object (like ioMasterHandle)
        
        # Local slots - stores only the differences from prototype
        # This is the Python equivalent of Io's slots dictionary
        self._local_slots: Dict[str, Any] = {}
        
        # Prototype chain for delegation (like Io's Protos list)
        self._protos: List['PrototypalWorker'] = []
        
        # Message forwarding function (like forwardMessage in TelosProxyObject)
        self._forward_message: Optional[Callable] = None
        
        # Worker-specific state
        self._worker_id = None
        self._logger = None
        
    def clone(self, new_name: str = None) -> 'PrototypalWorker':
        """
        Clone this prototype, creating a new instance with differential inheritance.
        This emulates Io's clone operation.
        """
        clone_name = new_name or f"{self.prototype_name}_Clone"
        clone = PrototypalWorker(clone_name, master_handle=self.master_handle)
        
        # Set up prototype chain - this clone delegates to self
        clone._protos = [self] + self._protos
        
        # Clone inherits the forwarding mechanism
        clone._forward_message = self._forward_message
        
        # Initialize empty local slots (differences only)
        clone._local_slots = {}
        
        return clone
    
    def set_slot(self, slot_name: str, value: Any):
        """
        Set a slot value (emulates Io's setSlot).
        This stores the value locally and triggers transactional update if needed.
        """
        # Store in local slots (the "differences")
        self._local_slots[slot_name] = value
        
        # If we have a master handle, trigger transactional coherence
        if self.master_handle and self._forward_message:
            try:
                # Asynchronous FFI dispatch to maintain transactional coherence
                # This emulates the protocol from the architectural documents
                self._forward_message(self.master_handle, "setSlot", (slot_name, value))
            except Exception as e:
                # Log but don't fail - local cache is updated
                if self._logger:
                    self._logger.warning(f"Transactional setSlot failed: {e}")
    
    def get_slot(self, slot_name: str, default=None):
        """
        Get a slot value with prototypal delegation (emulates Io's slot lookup).
        Implements the precise sequence from the architectural documents.
        """
        # 1. Local Cache Lookup (fast path)
        if slot_name in self._local_slots:
            return self._local_slots[slot_name]
        
        # 2. Prototype Chain Traversal (delegation)
        for proto in self._protos:
            if hasattr(proto, 'get_slot'):
                try:
                    value = proto.get_slot(slot_name, None)
                    if value is not None:
                        return value
                except TelosProxyError:
                    continue
        
        # 3. FFI Message Forwarding (if connected to Io master)
        if self.master_handle and self._forward_message:
            try:
                return self._forward_message(self.master_handle, slot_name, ())
            except Exception as e:
                if self._logger:
                    self._logger.debug(f"FFI delegation failed for {slot_name}: {e}")
        
        # 4. Default or raise error
        if default is not None:
            return default
        
        # Emulate Io's doesNotUnderstand_ protocol
        return self._handle_does_not_understand(slot_name)
    
    def _handle_does_not_understand(self, slot_name: str):
        """
        Handle unresolved slot access (emulates Io's doesNotUnderstand_).
        This is where autopoietic learning can be triggered.
        """
        # This could trigger the GenerativeKernel for runtime code generation
        # For now, raise an error but preserve the context
        error_msg = f"Slot '{slot_name}' not found in prototype chain for {self.prototype_name}"
        if self._logger:
            self._logger.info(f"doesNotUnderstand: {slot_name} on {self.prototype_name}")
        raise TelosProxyError(error_msg)
    
    def __getattr__(self, name: str):
        """
        Python's __getattr__ hook - implements prototypal delegation.
        This is the key mechanism that makes the prototypal behavior transparent.
        """
        return self.get_slot(name)
    
    def __setattr__(self, name: str, value: Any):
        """
        Python's __setattr__ hook - ensures transactional coherence.
        Direct implementation of the architectural mandates.
        """
        # Handle internal attributes normally
        if name.startswith('_') or name in ('prototype_name', 'master_handle'):
            super().__setattr__(name, value)
        else:
            # Use prototypal setSlot for all other attributes
            self.set_slot(name, value)


class SharedMemoryManager:
    """
    Manager for shared memory lifecycle following the architectural mandates.
    
    The architectural blueprints specify that the SharedMemoryManager process
    is the sole owner and is responsible for calling unlink() on shutdown.
    All other consumer processes must only call close().
    
    CRITICAL: This class must handle the case where worker processes (which are
    daemon processes) cannot create their own SharedMemoryManager instances.
    """
    
    def __init__(self):
        self.managed_blocks: Dict[str, shared_memory.SharedMemory] = {}
        # Check if we're in the main process by trying to create a manager
        self._is_main_process = False
        self._manager = None
        
        # Try to determine if we can create a SharedMemoryManager
        # Only the main process can do this
        try:
            # This will fail in daemon processes (workers)
            test_manager = multiprocessing.managers.SharedMemoryManager()
            test_manager.start()
            test_manager.shutdown()  # Clean up test manager
            
            # If we get here, we can create the real manager
            self._manager = multiprocessing.managers.SharedMemoryManager()
            self._manager.start()
            self._is_main_process = True
            
        except (AssertionError, RuntimeError) as e:
            if "daemonic processes" in str(e) or "cannot start" in str(e):
                # Worker process - cannot create SharedMemoryManager
                self._manager = None
                self._is_main_process = False
            else:
                raise
    
    def create_block(self, size: int) -> SharedMemoryHandle:
        """Create a new shared memory block (main process only)."""
        if not self._is_main_process:
            # Worker processes should create blocks directly using multiprocessing.shared_memory
            # This is allowed even in daemon processes
            try:
                shm = shared_memory.SharedMemory(create=True, size=size)
                handle = SharedMemoryHandle(name=shm.name, offset=0, size=size)
                # Store the reference but mark it as worker-created
                self.managed_blocks[shm.name] = shm
                return handle
            except Exception as e:
                raise TelosWorkerError(f"Worker process failed to create shared memory block: {e}")
            
        try:
            shm = self._manager.SharedMemory(size=size)
            handle = SharedMemoryHandle(name=shm.name, offset=0, size=size)
            self.managed_blocks[shm.name] = shm
            return handle
        except Exception as e:
            raise TelosWorkerError(f"Failed to create shared memory block: {e}")
    
    def get_block(self, handle: SharedMemoryHandle) -> shared_memory.SharedMemory:
        """Get an existing shared memory block by handle."""
        if handle.name in self.managed_blocks:
            return self.managed_blocks[handle.name]
        
        try:
            # Attach to existing block (works in both main and worker processes)
            shm = shared_memory.SharedMemory(name=handle.name, create=False)
            # Cache the reference but don't store it permanently in workers
            if self._is_main_process:
                self.managed_blocks[handle.name] = shm
            return shm
        except Exception as e:
            raise TelosWorkerError(f"Failed to attach to shared memory block {handle.name}: {e}")
    
    def cleanup(self):
        """Clean up all managed blocks. Called on shutdown."""
        for name, shm in self.managed_blocks.items():
            try:
                if self._is_main_process:
                    # Main process should unlink to actually free the memory
                    try:
                        shm.unlink()
                    except Exception as e:
                        logging.warning(f"Error unlinking shared memory block {name}: {e}")
                shm.close()  # All processes should close their references
            except Exception as e:
                logging.warning(f"Error closing shared memory block {name}: {e}")
        
        self.managed_blocks.clear()
        
        # Only shutdown the manager if we created it (main process)
        if self._is_main_process and self._manager is not None:
            try:
                self._manager.shutdown()
            except Exception as e:
                logging.warning(f"Error shutting down SharedMemoryManager: {e}")


class BaseWorker(PrototypalWorker):
    """
    Base prototypal worker implementing the TELOS worker protocol.
    
    This worker follows prototypal patterns:
    - Inherits from PrototypalWorker for delegation behavior
    - Uses local slots for worker-specific state
    - Can be cloned and extended rather than subclassed
    - Implements message forwarding for operation dispatch
    """
    
    def __init__(self, worker_id: int, prototype_name: str = "BaseWorker"):
        # Initialize prototypal base
        super().__init__(prototype_name)
        
        # Set worker-specific slots
        self.set_slot('worker_id', worker_id)
        self.set_slot('memory_manager', SharedMemoryManager())
        self.set_slot('llm_transducer', create_llm_transducer())
        
        # Setup logging and cache the logger
        self._setup_logging()
        
        # Register standard operation handlers in local slots
        self._register_operation_handlers()
    
    def _setup_logging(self):
        """Set up process-specific logging."""
        worker_id = self.get_slot('worker_id')
        logging.basicConfig(
            level=logging.INFO,
            format=f'[Worker-{worker_id}] %(asctime)s - %(levelname)s - %(message)s',
            handlers=[logging.StreamHandler()]
        )
        self._logger = logging.getLogger(f'telos.worker.{worker_id}')
        self.set_slot('logger', self._logger)
    
    def _register_operation_handlers(self):
        """
        Register operation handlers using prototypal slots.
        This enables dynamic dispatch without hard-coded conditionals.
        """
        # Register handlers in local slots for efficient dispatch
        self.set_slot('handle_vsa_batch', self._handle_vsa_batch)
        self.set_slot('handle_ann_search', self._handle_ann_search)
        self.set_slot('handle_vector_operations', self._handle_vector_operations)
        self.set_slot('handle_shared_memory', self._handle_shared_memory)
        self.set_slot('handle_ping', self._handle_ping)
        self.set_slot('handle_transactional_outbox', self._handle_transactional_outbox)
        self.set_slot('handle_zodb_manager', self._handle_zodb_manager)
        self.set_slot('handle_telemetry', self._handle_telemetry)
        self.set_slot('handle_opentelemetry', self._handle_opentelemetry)
        self.set_slot('handle_federated_memory', self._handle_federated_memory)
        self.set_slot('handle_bridge_metrics', self._handle_bridge_metrics)
        self.set_slot('handle_llm_transducer', self._handle_llm_transducer)
    
    def _ensure_llm_transducer(self) -> Dict[str, Any]:
        transducer = self.get_slot('llm_transducer')
        if not isinstance(transducer, dict) or 'execute' not in transducer:
            transducer = create_llm_transducer()
            self.set_slot('llm_transducer', transducer)
        return transducer

    def _normalize_handle_descriptor(self, descriptor: Dict[str, Any]) -> SharedMemoryHandle:
        if not isinstance(descriptor, dict):
            raise TelosWorkerError("Shared memory descriptor must be a dict")

        name = descriptor.get('name')
        if not isinstance(name, str) or not name:
            raise TelosWorkerError("Shared memory descriptor missing name")

        try:
            offset = int(descriptor.get('offset', 0) or 0)
        except (TypeError, ValueError):
            offset = 0

        try:
            size = int(descriptor.get('size', 0) or 0)
        except (TypeError, ValueError):
            size = 0

        return SharedMemoryHandle(name=name, offset=max(0, offset), size=max(0, size))

    def _read_shared_memory_text(self, descriptor: Dict[str, Any]) -> str:
        handle = self._normalize_handle_descriptor(descriptor)
        memory_manager = self.get_slot('memory_manager')
        if not isinstance(memory_manager, SharedMemoryManager):
            raise TelosWorkerError("Shared memory manager unavailable in worker")

        shm = memory_manager.get_block(handle)
        try:
            buffer = shm.buf
            total_size = len(buffer)
            offset = min(handle.offset, total_size)
            length = handle.size if handle.size > 0 else total_size - offset
            end = min(total_size, offset + length)
            raw = bytes(buffer[offset:end])
        finally:
            shm.close()

        null_index = raw.find(b'\0')
        if null_index >= 0:
            raw = raw[:null_index]
        return raw.decode('utf-8', errors='ignore')

    def _write_shared_memory_json(self, descriptor: Dict[str, Any], payload: Any) -> None:
        text = payload if isinstance(payload, str) else json.dumps(payload, ensure_ascii=False)
        encoded = text.encode('utf-8')

        handle = self._normalize_handle_descriptor(descriptor)
        memory_manager = self.get_slot('memory_manager')
        if not isinstance(memory_manager, SharedMemoryManager):
            raise TelosWorkerError("Shared memory manager unavailable in worker")

        shm = memory_manager.get_block(handle)
        try:
            buffer = shm.buf
            total_size = len(buffer)
            offset = min(handle.offset, total_size)
            capacity = handle.size if handle.size > 0 else total_size - offset

            required = len(encoded) + 1  # include null terminator
            if required > capacity:
                raise TelosWorkerError(
                    f"Response payload of {len(encoded)} bytes exceeds shared memory capacity {capacity}"
                )

            buffer[offset:offset + len(encoded)] = encoded
            terminator_index = offset + len(encoded)
            if terminator_index < offset + capacity:
                buffer[terminator_index] = 0
        finally:
            shm.close()

    def execute_request(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a request using prototypal message dispatch with trace context propagation.
        """
        request_trace_context = _sanitize_trace_context(request_data.get('trace_context'))
        payload: Dict[str, Any] = dict(request_data)  # Ensure we have a fresh copy of the request data
        if request_trace_context:
            payload['trace_context'] = request_trace_context
        else:
            payload.pop('trace_context', None)

        try:
            operation = payload.get('operation')
            if not operation:
                raise TelosWorkerError("No operation specified in request")

            attributes = {
                'telos.worker.operation': operation,
                'telos.worker.id': self.get_slot('worker_id'),
            }
            if request_trace_context.get('traceparent'):
                attributes['telos.trace.traceparent'] = request_trace_context['traceparent']

            with _start_worker_span(operation, request_trace_context, attributes):
                handler_name = f'handle_{operation}'
                try:
                    handler = self.get_slot(handler_name)
                    if callable(handler):
                        result = handler(payload)
                        if isinstance(result, dict) and request_trace_context:
                            result.setdefault('trace_context', dict(request_trace_context))
                        return result
                    raise TelosProxyError(f"Handler {handler_name} is not callable")
                except TelosProxyError:
                    raise TelosWorkerError(f"Unknown operation: {operation}")

        except Exception as e:
            logger = self.get_slot('logger')
            logger.error(f"Error executing request: {e}")
            logger.error(f"Traceback: {traceback.format_exc()}")
            error_response = {
                'success': False,
                'error': str(e),
                'traceback': traceback.format_exc(),
            }
            if request_trace_context:
                error_response['trace_context'] = dict(request_trace_context)
            return error_response
    
    def _handle_ping(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle ping request for testing connectivity."""
        return {
            'success': True,
            'worker_id': self.get_slot('worker_id'),
            'message': 'pong'
        }
    
    def _handle_vsa_batch(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle VSA batch operations.
        This is a stub implementation that will be expanded when VSA operations are implemented.
        """
        operation_name = request_data.get('operation_name', 'unknown')
        batch_size = request_data.get('batch_size', 0)
        
        logger = self.get_slot('logger')
        logger.info(f"Processing VSA batch operation: {operation_name}, batch_size: {batch_size}")
        
        # For now, return a stub response
        return {
            'success': True,
            'operation_name': operation_name,
            'batch_size': batch_size,
            'message': 'VSA batch processing not yet implemented'
        }
    
    def _handle_ann_search(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle approximate nearest neighbor search.
        This is a stub implementation that will be expanded when ANN indices are implemented.
        """
        k = request_data.get('k', 5)
        similarity_threshold = request_data.get('similarity_threshold', 0.0)
        
        logger = self.get_slot('logger')
        logger.info(f"Processing ANN search: k={k}, threshold={similarity_threshold}")
        
        # For now, return a stub response
        return {
            'success': True,
            'k': k,
            'similarity_threshold': similarity_threshold,
            'results': [],
            'message': 'ANN search not yet implemented'
        }
    
    def _handle_vector_operations(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Handle vector cache operations routed from Io actors."""

        logger = self.get_slot('logger')
        action = request_data.get('action') or request_data.get('vector_operation') or 'stats'
        config = request_data.get('config') or {}

        try:
            if action == 'configure':
                manager = _ensure_l1_cache_manager(config, reset=True)
                stats = manager['get_statistics']()
                return {
                    'success': True,
                    'config': dict(_l1_cache_config),
                    'faiss_available': FAISS_AVAILABLE,
                    'faiss_error': FAISS_IMPORT_ERROR,
                    'statistics': stats,
                }

            manager = _ensure_l1_cache_manager()

        except Exception as exc:
            logger.error("Failed to configure L1 cache manager: %s", exc)
            return {
                'success': False,
                'error': f"L1 cache manager unavailable: {exc}",
            }

            if action == 'drain_promotions':
                raw_limit = config.get('limit')
                limit: Optional[int] = None
                if raw_limit is not None:
                    try:
                        limit = max(0, int(raw_limit))
                    except Exception:
                        limit = None

                include_vectors = bool(config.get('include_vectors'))
                drained = manager['drain_promotions'](limit=limit, include_vectors=include_vectors)
                return {
                    'success': True,
                    'count': len(drained),
                    'candidates': drained,
                }

            if action == 'peek_promotions':
                snapshot = manager['peek_promotions']()
                return {
                    'success': True,
                    'count': len(snapshot),
                    'candidates': snapshot,
                }

        if action == 'put':
            oid = config.get('oid') or config.get('id') or config.get('concept_oid')
            if not oid:
                return {'success': False, 'error': 'vector put requires oid'}

            vector, error = _extract_vector_from_config(config)
            if vector is None:
                return {'success': False, 'error': error}

            metadata = config.get('metadata') or {}

            try:
                stored = manager['put'](str(oid), vector, metadata)
            except Exception as exc:  # pragma: no cover - defensive path
                logger.error("L1 put failed: %s", exc)
                return {'success': False, 'error': f"put failed: {exc}"}

            return {
                'success': bool(stored),
                'oid': str(oid),
                'stored': bool(stored),
                'vector_dim': int(vector.shape[0]),
            }

        if action == 'get':
            oid = config.get('oid') or config.get('id') or config.get('concept_oid')
            if not oid:
                return {'success': False, 'error': 'vector get requires oid'}

            entry = manager['get'](str(oid))
            if not entry:
                return {
                    'success': False,
                    'found': False,
                    'oid': str(oid),
                    'error': 'oid not found',
                }

            vector_payload, shm_descriptor = _prepare_vector_response(
                entry.get('vector'),
                {
                    'include_vector': config.get('include_vector'),
                    'use_shared_memory': config.get('vector_as_shared_memory'),
                },
            )

            response = {
                'success': True,
                'found': True,
                'oid': str(oid),
                'metadata': entry.get('metadata'),
                'stats': entry.get('stats'),
            }

            if vector_payload is not None:
                response['vector'] = vector_payload
            if shm_descriptor is not None:
                response['vector_shm'] = shm_descriptor

            return response

        if action == 'remove':
            oid = config.get('oid') or config.get('id') or config.get('concept_oid')
            if not oid:
                return {'success': False, 'error': 'vector remove requires oid'}

            removed = manager['remove'](str(oid))
            return {
                'success': True,
                'removed': bool(removed),
                'oid': str(oid),
            }

        if action == 'search':
            vector, error = _extract_vector_from_config(config, vector_key='query_vector', shm_key='query_vector_shm')
            if vector is None:
                return {'success': False, 'error': error}

            k = int(config.get('k', 5))
            threshold = float(config.get('threshold', 0.0))

            try:
                results = manager['search_similar'](vector, k=k, threshold=threshold)
            except Exception as exc:  # pragma: no cover - defensive path
                logger.error("L1 search failed: %s", exc)
                return {'success': False, 'error': f"search failed: {exc}"}

            include_vectors = config.get('include_vectors')
            vectors_shared = config.get('vectors_as_shared_memory')

            sanitized: List[Dict[str, Any]] = []
            for entry in results:
                vector_payload, shm_descriptor = _prepare_vector_response(
                    entry.get('vector'),
                    {
                        'include_vector': include_vectors,
                        'use_shared_memory': vectors_shared,
                    },
                )

                item = {
                    'oid': entry.get('oid'),
                    'similarity_score': entry.get('similarity_score'),
                    'metadata': entry.get('metadata'),
                    'stats': entry.get('stats'),
                }

                if vector_payload is not None:
                    item['vector'] = vector_payload
                if shm_descriptor is not None:
                    item['vector_shm'] = shm_descriptor

                sanitized.append(item)

            return {
                'success': True,
                'results': sanitized,
                'count': len(sanitized),
                'k': k,
                'threshold': threshold,
            }

        if action == 'stats':
            stats = manager['get_statistics']()
            return {
                'success': True,
                'statistics': stats,
                'config': dict(_l1_cache_config),
                'faiss_available': FAISS_AVAILABLE,
            }

        if action == 'clear':
            manager['clear']()
            return {'success': True, 'cleared': True}

        if action == 'list_oids':
            oids = sorted(manager['get_all_oids']())
            return {'success': True, 'oids': oids, 'count': len(oids)}

        if action == 'warmup':
            entries = config.get('entries') or []
            inserted = 0
            errors: List[str] = []
            for entry in entries:
                oid = entry.get('oid')
                vector, error = _extract_vector_from_config(entry)
                metadata = entry.get('metadata') or {}
                if vector is None or not oid:
                    errors.append(f"invalid entry for oid={oid}: {error}")
                    continue
                if manager['put'](str(oid), vector, metadata):
                    inserted += 1

            return {
                'success': True,
                'inserted': inserted,
                'errors': errors,
            }

        return {
            'success': False,
            'error': f"Unknown vector operation: {action}",
        }

    def _handle_transactional_outbox(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Bridge transactional outbox operations for Io-driven harnesses."""
        action = request_data.get('action', 'run_scenario')
        config = request_data.get('config', {}) or {}

        if action == 'run_scenario':
            return self._transactional_outbox_run_scenario(config)

        if action in ('dlq_snapshot', 'dlq_inspect'):
            return self._transactional_outbox_dlq_snapshot(config)

        if action == 'purge_processed':
            return self._transactional_outbox_purge_processed(config)

        if action == 'enqueue_matrix':
            return self._transactional_outbox_enqueue_matrix(config)

        return {
            'success': False,
            'error': f"Unknown transactional_outbox action: {action}"
        }

    def _transactional_outbox_run_scenario(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a reliability scenario mirroring the Python unit test."""
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_outbox_worker_")
        storage_path = Path(tempdir) / "outbox.fs"

        outbox = None
        poller = None
        processed: List[str] = []
        dead_letters: List[str] = []

        outbox_conf = {
            'storage_path': str(storage_path),
            'retry_limit': int(config.get('retry_limit', 1)),
            'batch_size': int(config.get('outbox_batch_size', 2)),
            'visibility_timeout': float(config.get('visibility_timeout', 0.5)),
        }

        poller_conf = {
            'poll_interval': float(config.get('poll_interval', 0.1)),
            'batch_size': int(config.get('poll_batch_size', 2)),
        }

        wait_timeout = float(config.get('timeout', 5.0))
        sleep_interval = float(config.get('sleep_interval', 0.05))

        try:
            outbox = create_transactional_outbox(outbox_conf)

            def handler(entry: Dict[str, Any]) -> None:
                payload = entry.get('payload', {})
                if payload.get('mode') == 'fail':
                    raise RuntimeError('intentional failure')
                processed.append(entry['id'])

            def dlq_handler(entry: Dict[str, Any]) -> None:
                dead_letters.append(entry['id'])

            poller = create_transactional_outbox_poller(outbox, handler, dlq_handler, poller_conf)
            poller['start']()

            ok_id = outbox['enqueue']({'mode': 'ok'}, {'source': 'worker'})
            fail_id = outbox['enqueue']({'mode': 'fail'}, {'source': 'worker'})

            deadline = time.time() + wait_timeout
            while time.time() < deadline:
                if ok_id in processed and fail_id in dead_letters:
                    break
                time.sleep(sleep_interval)

            if poller is not None:
                poller['stop'](timeout=2.0)
                poller = None

            stats = outbox['get_statistics']()
            outbox['shutdown']()
            outbox = None

            success = (ok_id in processed) and (fail_id in dead_letters)
            if not success:
                logger.warning(
                    "Transactional outbox scenario incomplete: processed=%s dead_letters=%s",
                    processed,
                    dead_letters,
                )

            return {
                'success': success,
                'ok_id': ok_id,
                'fail_id': fail_id,
                'processed': processed,
                'dead_letters': dead_letters,
                'stats': stats,
            }

        except Exception as exc:
            logger.error("Transactional outbox scenario failed: %s", exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
                'processed': processed,
                'dead_letters': dead_letters,
            }

        finally:
            try:
                if poller is not None:
                    poller['stop'](timeout=1.0)
            except Exception:
                pass

            try:
                if outbox is not None:
                    outbox['shutdown']()
            except Exception:
                pass

            shutil.rmtree(tempdir, ignore_errors=True)

    def _transactional_outbox_dlq_snapshot(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Produce a DLQ snapshot after exercising enqueue/poller flows."""
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_outbox_dlq_")
        storage_path = Path(tempdir) / "outbox.fs"

        outbox = None
        poller = None
        processed: List[str] = []
        dead_letters: List[str] = []

        payloads = config.get('payloads') or [
            {'mode': 'ok'},
            {'mode': 'fail'},
        ]

        metadata_list = config.get('metadata') or [{} for _ in payloads]
        poller_conf = {
            'poll_interval': float(config.get('poll_interval', 0.05)),
            'batch_size': int(config.get('poll_batch_size', 2)),
        }

        wait_timeout = float(config.get('timeout', 5.0))
        sleep_interval = float(config.get('sleep_interval', 0.05))

        dlq_limit = int(config.get('dlq_limit', len(payloads)))
        preserve_storage = bool(config.get('preserve_storage'))

        try:
            outbox = create_transactional_outbox({
                'storage_path': str(storage_path),
                'retry_limit': int(config.get('retry_limit', 1)),
                'batch_size': int(config.get('outbox_batch_size', 2)),
                'visibility_timeout': float(config.get('visibility_timeout', 0.5)),
            })

            def handler(entry: Dict[str, Any]) -> None:
                processed.append(entry['id'])

            def dlq_handler(entry: Dict[str, Any]) -> None:
                dead_letters.append(entry['id'])

            poller = create_transactional_outbox_poller(outbox, handler, dlq_handler, poller_conf)
            poller['start']()

            enqueued: List[str] = []
            for index, payload in enumerate(payloads):
                metadata = metadata_list[index] if index < len(metadata_list) else {}
                try:
                    entry_id = outbox['enqueue'](payload, metadata)
                    enqueued.append(entry_id)
                except Exception as exc:  # pragma: no cover - defensive guard
                    logger.error("Failed to enqueue payload %s: %s", index, exc)

            deadline = time.time() + wait_timeout
            while time.time() < deadline:
                if len(processed) + len(dead_letters) >= len(enqueued):
                    break
                time.sleep(sleep_interval)

            if poller is not None:
                poller['stop'](timeout=2.0)
                poller = None

            stats = outbox['get_statistics']()
            dlq_entries = outbox['fetch_dlq'](dlq_limit)
            inflight = outbox['reserve_pending'](len(enqueued))
            requeued_ids = []
            if inflight:
                for item in inflight:
                    requeued_ids.append(item['id'])
                    outbox['release_inflight'](item['id'])

            return {
                'success': True,
                'enqueued': enqueued,
                'processed': processed,
                'dead_letters': dead_letters,
                'statistics': stats,
                'dlq_entries': dlq_entries,
                'requeued': requeued_ids,
                'storage_path': str(storage_path),
            }

        except Exception as exc:
            logger.error("DLQ snapshot failed: %s", exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if poller is not None:
                    poller['stop'](timeout=1.0)
            except Exception:
                pass

            try:
                if outbox is not None:
                    outbox['shutdown']()
            except Exception:
                pass

            if not preserve_storage:
                shutil.rmtree(tempdir, ignore_errors=True)

    def _transactional_outbox_purge_processed(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Purge processed entries from a persistent outbox store."""
        logger = self.get_slot('logger')
        storage_path = config.get('storage_path')
        if not storage_path:
            return {
                'success': False,
                'error': 'purge_processed requires storage_path',
            }

        max_entries = int(config.get('max_entries', 100))
        zeo_address = config.get('zeo_address')

        outbox = None

        try:
            outbox = create_transactional_outbox({
                'storage_path': storage_path,
                'zeo_address': tuple(zeo_address) if isinstance(zeo_address, (list, tuple)) else zeo_address,
            })

            removed = outbox['purge_processed'](max_entries)
            stats = outbox['get_statistics']()

            return {
                'success': True,
                'removed': removed,
                'statistics': stats,
            }

        except Exception as exc:
            logger.error("Purge processed failed: %s", exc)
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if outbox is not None:
                    outbox['shutdown']()
            except Exception:
                pass

    def _transactional_outbox_enqueue_matrix(self, config: Dict[str, Any]) -> Dict[str, Any]:
        """Enqueue a matrix of payloads and report per-status counts."""
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_outbox_matrix_")
        storage_path = Path(tempdir) / "outbox.fs"

        payload_matrix = config.get('matrix')
        if not payload_matrix or not isinstance(payload_matrix, list):
            shutil.rmtree(tempdir, ignore_errors=True)
            return {
                'success': False,
                'error': 'enqueue_matrix requires a non-empty matrix list',
            }

        outbox = None
        poller = None

        counters = {
            'processed': 0,
            'dead_letters': 0,
            'errors': [],
        }

        try:
            outbox = create_transactional_outbox({
                'storage_path': str(storage_path),
                'retry_limit': int(config.get('retry_limit', 2)),
                'batch_size': int(config.get('outbox_batch_size', 4)),
                'visibility_timeout': float(config.get('visibility_timeout', 1.0)),
            })

            def handler(entry: Dict[str, Any]) -> None:
                counters['processed'] += 1

            def dlq_handler(entry: Dict[str, Any]) -> None:
                counters['dead_letters'] += 1

            poller = create_transactional_outbox_poller(outbox, handler, dlq_handler, {
                'poll_interval': float(config.get('poll_interval', 0.05)),
                'batch_size': int(config.get('poll_batch_size', 4)),
            })
            poller['start']()

            entry_ids: List[str] = []
            for row in payload_matrix:
                payload = row.get('payload') if isinstance(row, dict) else None
                metadata = row.get('metadata') if isinstance(row, dict) else None
                if payload is None:
                    counters['errors'].append('missing_payload')
                    continue
                try:
                    entry_id = outbox['enqueue'](payload, metadata)
                    entry_ids.append(entry_id)
                except Exception as exc:  # pragma: no cover - defensive
                    counters['errors'].append(str(exc))

            deadline = time.time() + float(config.get('timeout', 6.0))
            while time.time() < deadline:
                remaining = len(entry_ids) - (counters['processed'] + counters['dead_letters'])
                if remaining <= 0:
                    break
                time.sleep(float(config.get('sleep_interval', 0.05)))

            stats = outbox['get_statistics']()
            dlq_entries = outbox['fetch_dlq'](len(entry_ids))

            return {
                'success': True,
                'matrix_size': len(payload_matrix),
                'entry_ids': entry_ids,
                'metrics': counters,
                'statistics': stats,
                'dlq_entries': dlq_entries,
            }

        except Exception as exc:
            logger.error("enqueue_matrix failed: %s", exc)
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if poller is not None:
                    poller['stop'](timeout=1.5)
            except Exception:
                pass

            try:
                if outbox is not None:
                    outbox['shutdown']()
            except Exception:
                pass

            shutil.rmtree(tempdir, ignore_errors=True)

    def _handle_zodb_manager(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Bridge ZODB manager operations for Io-driven harnesses."""
        logger = self.get_slot('logger')
        action = request_data.get('action', 'run_smoke')  # Default action for ZODB manager
        config = request_data.get('config', {}) or {}
        trace_context = _sanitize_trace_context(request_data.get('trace_context'))

        state = self.get_slot('_zodb_manager_state', None)
        if state is None:
            state = {
                'manager': None,
                'config': None,
                'ephemeral_dir': None,
            }
            self.set_slot('_zodb_manager_state', state)

        def _extract_manager_config(payload: Dict[str, Any]) -> Dict[str, Any]:
            if not isinstance(payload, dict):
                return {}

            manager_cfg = {}
            raw = payload.get('manager') if isinstance(payload.get('manager'), dict) else {}
            if raw:
                manager_cfg.update(raw)

            for key in ('storage_path', 'zeo_host', 'zeo_port', 'read_only', 'mode'):
                if key in payload and key not in manager_cfg:
                    manager_cfg[key] = payload[key]
            return manager_cfg

        def _normalize_manager_config(raw_cfg: Dict[str, Any]) -> Dict[str, Any]:
            if not raw_cfg:
                return {}

            normalized: Dict[str, Any] = {}

            storage_path = raw_cfg.get('storage_path')
            if storage_path is not None:
                normalized['storage_path'] = str(storage_path)

            zeo_host = raw_cfg.get('zeo_host')
            if zeo_host is not None:
                normalized['zeo_host'] = str(zeo_host)

            zeo_port = raw_cfg.get('zeo_port')
            if zeo_port is not None:
                try:
                    normalized['zeo_port'] = int(zeo_port)
                except Exception:
                    normalized['zeo_port'] = zeo_port

            if 'read_only' in raw_cfg:
                normalized['read_only'] = bool(raw_cfg.get('read_only'))

            if 'mode' in raw_cfg and raw_cfg.get('mode') is not None:
                normalized['mode'] = str(raw_cfg.get('mode'))

            return normalized

        def _cleanup_manager_state():
            manager = state.get('manager')
            if manager is not None:
                try:
                    manager['close']()
                except Exception:
                    logger.debug("Error closing persistent ZODB manager", exc_info=True)
            state['manager'] = None
            state['config'] = None

            ephemeral_dir = state.get('ephemeral_dir')
            if ephemeral_dir is not None:
                shutil.rmtree(ephemeral_dir, ignore_errors=True)
            state['ephemeral_dir'] = None

        def _ensure_manager(raw_cfg: Dict[str, Any]) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
            requested_cfg = _normalize_manager_config(raw_cfg)

            if state.get('manager') is not None:
                current_cfg = state.get('config') or {}
                if requested_cfg:
                    merged_cfg = dict(current_cfg)
                    merged_cfg.update(requested_cfg)
                    requested_cfg = _normalize_manager_config(merged_cfg)
                else:
                    requested_cfg = current_cfg

                if requested_cfg == current_cfg:
                    return state['manager'], None

                _cleanup_manager_state()

            final_cfg = requested_cfg or {}

            raw_mode = final_cfg.get('mode')
            mode = raw_mode.lower() if isinstance(raw_mode, str) else None
            storage_path = final_cfg.get('storage_path')
            ephemeral_dir = None

            if mode == 'ephemeral':
                ephemeral_dir = tempfile.mkdtemp(prefix="telos_zodb_worker_live_")
                storage_path = str(Path(ephemeral_dir) / "concepts.fs")
                final_cfg['mode'] = 'ephemeral'
            else:
                if storage_path is None:
                    storage_path = str(Path.cwd() / "telos_concepts.fs")
                storage_path = str(Path(storage_path))
                Path(storage_path).parent.mkdir(parents=True, exist_ok=True)
                final_cfg['mode'] = 'persistent'

            final_cfg['storage_path'] = storage_path

            zeo_host = final_cfg.get('zeo_host')
            zeo_port = final_cfg.get('zeo_port')
            read_only = bool(final_cfg.get('read_only', False))

            zeo_address = None
            if zeo_host is not None and zeo_port is not None:
                zeo_address = (zeo_host, zeo_port)

            try:
                manager = create_zodb_manager(
                    storage_path=storage_path,
                    zeo_address=zeo_address,
                    read_only=read_only,
                )
            except Exception as exc:
                if ephemeral_dir is not None:
                    shutil.rmtree(ephemeral_dir, ignore_errors=True)
                logger.error("Failed to initialize persistent ZODB manager: %s", exc)
                return None, str(exc)

            state['manager'] = manager
            state['config'] = {
                'storage_path': storage_path,
                'zeo_host': zeo_host,
                'zeo_port': zeo_port,
                'read_only': read_only,
                'mode': final_cfg.get('mode'),
            }
            state['ephemeral_dir'] = ephemeral_dir

            return manager, None

        def _require_manager(raw_cfg: Dict[str, Any]) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
            manager = state.get('manager')
            if manager is not None:
                return manager, None

            manager, error = _ensure_manager(raw_cfg)
            if manager is None and error is None:
                return None, "ZODB manager is not initialized"
            return manager, error

        manager_config = _extract_manager_config(config)

        if action == 'initialize':
            _cleanup_manager_state()
            manager, error = _ensure_manager(manager_config)
            if manager is None:
                return {
                    'success': False,
                    'error': error or 'failed to initialize zodb manager',
                }

            applied = state.get('config') or {}
            return {
                'success': True,
                'storage_path': applied.get('storage_path'),
                'mode': applied.get('mode'),
                'read_only': applied.get('read_only', False),
                'zeo_host': applied.get('zeo_host'),
                'zeo_port': applied.get('zeo_port'),
            }

        if action == 'shutdown':
            _cleanup_manager_state()
            return {'success': True}

        if action == 'store_concept':
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            concept_payload = config.get('concept')
            if not isinstance(concept_payload, dict):
                return {'success': False, 'error': 'concept payload must be a map'}

            try:
                oid = manager['store_concept'](concept_payload)
                return {'success': True, 'oid': oid}
            except Exception as exc:
                logger.error("store_concept failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action == 'load_concept':
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            oid = config.get('oid')
            if not oid:
                return {'success': False, 'error': 'oid is required'}

            try:
                result = manager['load_concept'](str(oid))
                return {'success': True, 'concept': result}
            except Exception as exc:
                logger.error("load_concept failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action == 'update_concept':
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            oid = config.get('oid')
            updates = config.get('updates')
            if not oid or not isinstance(updates, dict):
                return {'success': False, 'error': 'oid and updates payload required'}

            try:
                updated = manager['update_concept'](str(oid), updates)
                return {'success': bool(updated), 'updated': bool(updated)}
            except Exception as exc:
                logger.error("update_concept failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action == 'delete_concept':
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            oid = config.get('oid')
            if not oid:
                return {'success': False, 'error': 'oid is required'}

            try:
                deleted = manager['delete_concept'](str(oid))
                return {'success': bool(deleted), 'deleted': bool(deleted)}
            except Exception as exc:
                logger.error("delete_concept failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action in ('list_concepts', 'list'):
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            limit = config.get('limit', 100)
            offset = config.get('offset', 0)

            try:
                concepts = manager['list_concepts'](int(limit), int(offset))
            except Exception as exc:
                logger.error("list_concepts failed: %s", exc)
                return {'success': False, 'error': str(exc)}

            return {
                'success': True,
                'oids': concepts,
                'count': len(concepts),
            }

        if action in ('get_statistics', 'statistics'):
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            try:
                stats = manager['get_statistics']()
                return {
                    'success': True,
                    'statistics': stats,
                }
            except Exception as exc:
                logger.error("get_statistics failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action in ('mark_changed', 'mark_object_changed'):
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            oid = config.get('oid')
            if not oid:
                return {'success': False, 'error': 'oid is required'}

            try:
                manager['mark_object_changed'](str(oid))
                return {'success': True}
            except Exception as exc:
                logger.error("mark_object_changed failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action in ('commit', 'commit_transaction'):
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            try:
                manager['commit_transaction']()
                return {'success': True}
            except Exception as exc:
                logger.error("commit_transaction failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action in ('abort', 'abort_transaction'):
            manager, error = _require_manager(manager_config)
            if manager is None:
                return {'success': False, 'error': error}

            try:
                manager['abort_transaction']()
                return {'success': True}
            except Exception as exc:
                logger.error("abort_transaction failed: %s", exc)
                return {'success': False, 'error': str(exc)}

        if action == 'run_smoke':
            return self._zodb_manager_run_smoke(config)

        if action == 'run_read_only':
            return self._zodb_manager_run_read_only(config)

        if action == 'run_commit_abort':
            return self._zodb_manager_run_commit_abort(config)

        if action == 'run_all':
            smoke_result = self._zodb_manager_run_smoke(config)
            if not smoke_result.get('success', False):
                return {
                    'success': False,
                    'error': 'zodb_smoke_failed',
                    'smoke': smoke_result,
                }

            read_only_result = self._zodb_manager_run_read_only(config)
            if not read_only_result.get('success', False):
                return {
                    'success': False,
                    'error': 'zodb_read_only_failed',
                    'read_only': read_only_result,
                }

            commit_abort_result = self._zodb_manager_run_commit_abort(config)
            if not commit_abort_result.get('success', False):
                return {
                    'success': False,
                    'error': 'zodb_commit_abort_failed',
                    'commit_abort': commit_abort_result,
                }

            return {
                'success': True,
                'smoke': smoke_result,
                'read_only': read_only_result,
                'commit_abort': commit_abort_result,
            }

        if action == 'run_fault_injection':
            return self._zodb_manager_run_fault(config, trace_context)

        return {
            'success': False,
            'error': f"Unknown zodb_manager action: {action}",
        }

    def _handle_federated_memory(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Expose federated memory controls and telemetry through the bridge."""

        logger = self.get_slot('logger')
        action = request_data.get('action', 'status')
        config_payload = request_data.get('config') or {}
        if not isinstance(config_payload, dict):
            config_payload = {}

        if not FEDERATED_MEMORY_AVAILABLE or _federated_memory_module is None:
            return {
                'success': False,
                'error': 'Federated memory module unavailable',
                'details': FEDERATED_MEMORY_IMPORT_ERROR,
            }

        try:
            with _federated_memory_lock:
                if action == 'initialize':
                    settings = config_payload.get('settings')
                    if not isinstance(settings, dict):
                        settings = config_payload if config_payload else None

                    init_result = _federated_memory_module.initialize_memory_fabric(settings)
                    fabric = _get_federated_memory_interface()
                    status = fabric['get_status']()
                    return {
                        'success': bool(init_result),
                        'initialized': bool(status.get('initialized', False)),
                        'status': status,
                    }

                if action == 'shutdown':
                    shutdown_result = _federated_memory_module.shutdown_memory_fabric()
                    return {
                        'success': bool(shutdown_result),
                    }

                fabric = _get_federated_memory_interface()

                if action in ('status', 'get_status'):
                    status = fabric['get_status']()
                    return {
                        'success': True,
                        'status': status,
                    }

                if action in ('outbox_status', 'get_outbox_status'):
                    status = fabric['get_outbox_status']()
                    return {
                        'success': True,
                        'status': status,
                    }

                if action in ('cache_statistics', 'get_cache_statistics'):
                    stats = fabric['get_cache_statistics']()
                    return {
                        'success': True,
                        'statistics': stats,
                    }

                if action in ('validate', 'validate_architecture'):
                    validation = fabric['validate']()
                    response = dict(validation)
                    response['success'] = bool(validation.get('valid', False))
                    return response

                if action in ('l2_telemetry', 'get_l2_telemetry'):
                    telemetry = fabric['get_l2_telemetry']()
                    success = 'error' not in telemetry
                    response = {
                        'success': success,
                        'telemetry': telemetry,
                    }
                    if not success:
                        response['error'] = telemetry.get('error', 'unknown error')
                    return response

                if action in ('simulate_coordinator_failure', 'coordinator_failure_test'):
                    result = fabric['simulate_coordinator_failure'](config_payload)
                    response = dict(result)
                    response['success'] = bool(result.get('success', False))
                    return response

                if action == 'status_with_cache':
                    status = fabric['get_status']()
                    stats = fabric['get_cache_statistics']()
                    return {
                        'success': True,
                        'status': status,
                        'statistics': stats,
                    }

                if action in ('run_benchmark', 'benchmark'):
                    result = fabric['run_benchmark'](config_payload)
                    response = dict(result)
                    response['success'] = bool(result.get('success', False))
                    return response

                if action in ('get_benchmark_history', 'benchmark_history'):
                    history = fabric['get_benchmark_history']()
                    response = dict(history)
                    limit_value = None
                    if isinstance(config_payload, dict) and config_payload.get('limit') is not None:
                        try:
                            limit_value = max(0, int(config_payload['limit']))
                        except Exception:
                            limit_value = None
                    if limit_value is not None:
                        history_list = response.get('history')
                        if isinstance(history_list, list):
                            response['history'] = history_list[:limit_value]
                    response['success'] = True
                    return response

                if action in ('get_benchmark_summary', 'benchmark_summary'):
                    limit_arg: Optional[Any] = None
                    if isinstance(config_payload, dict) and config_payload.get('limit') is not None:
                        limit_arg = config_payload.get('limit')
                    elif config_payload not in ({}, None):
                        limit_arg = config_payload

                    summary = fabric['get_benchmark_summary'](limit_arg)
                    return {
                        'success': True,
                        'summary': summary,
                    }

                if action in ('get_benchmark_alerts', 'benchmark_alerts'):
                    options_payload: Optional[Dict[str, Any]] = None
                    if isinstance(config_payload, dict) and config_payload:
                        options_payload = config_payload
                    alerts_snapshot = fabric['get_benchmark_alerts'](options_payload)
                    return {
                        'success': True,
                        'alerts': alerts_snapshot,
                    }

                if action in ('configure_benchmark_alerts', 'benchmark_alerts_configure'):
                    overrides = config_payload if isinstance(config_payload, dict) else None
                    configured = fabric['configure_benchmark_alerts'](overrides)
                    response = dict(configured)
                    response['success'] = True
                    return response

                if action in ('clear_benchmark_alerts', 'benchmark_alerts_clear'):
                    cleared = fabric['clear_benchmark_alerts']()
                    return {
                        'success': True,
                        'alerts': cleared,
                    }

                if action in ('evaluate_benchmark_alerts', 'benchmark_alerts_evaluate'):
                    options_payload: Optional[Dict[str, Any]] = None
                    if isinstance(config_payload, dict) and config_payload:
                        options_payload = config_payload
                    evaluation = fabric['evaluate_benchmark_alerts'](options_payload)
                    response = dict(evaluation)
                    response['success'] = True
                    return response

                if action in ('get_benchmark_recommendations', 'benchmark_recommendations'):
                    options_payload: Optional[Dict[str, Any]] = None
                    if isinstance(config_payload, dict) and config_payload:
                        options_payload = config_payload
                    recommendations = fabric['get_benchmark_recommendations'](options_payload)
                    response = dict(recommendations)
                    response['success'] = bool(recommendations.get('success', False))
                    return response

                if action in ('clear_benchmark_recommendations', 'benchmark_recommendations_clear'):
                    options_payload: Optional[Dict[str, Any]] = None
                    if isinstance(config_payload, dict) and config_payload:
                        options_payload = config_payload
                    cleared = fabric['clear_benchmark_recommendations'](options_payload)
                    response = dict(cleared)
                    response['success'] = bool(cleared.get('success', False))
                    return response

                if action in ('apply_benchmark_recommendations', 'benchmark_recommendations_apply'):
                    options_payload: Optional[Dict[str, Any]] = None
                    if isinstance(config_payload, dict) and config_payload:
                        options_payload = config_payload
                    applied = fabric['apply_benchmark_recommendations'](options_payload)
                    response = dict(applied)
                    response['success'] = bool(applied.get('success', False))
                    return response

                if action in ('get_outbox_analytics', 'outbox_analytics'):
                    options_payload: Optional[Dict[str, Any]] = None
                    if isinstance(config_payload, dict) and config_payload:
                        options_payload = config_payload
                    analytics = fabric['get_outbox_analytics'](options_payload)
                    return {
                        'success': True,
                        'analytics': analytics,
                    }

                if action in ('start_benchmark_daemon', 'benchmark_daemon_start'):
                    result = fabric['start_benchmark_daemon'](config_payload)
                    response = dict(result)
                    response['success'] = bool(result.get('success', False))
                    return response

                if action in ('stop_benchmark_daemon', 'benchmark_daemon_stop'):
                    payload = config_payload if isinstance(config_payload, dict) else None
                    result = fabric['stop_benchmark_daemon'](payload)
                    response = dict(result)
                    response['success'] = bool(result.get('success', False))
                    return response

                if action in ('trigger_benchmark_run', 'benchmark_daemon_trigger'):
                    result = fabric['trigger_benchmark_run'](config_payload)
                    response = dict(result)
                    response['success'] = bool(result.get('success', False))
                    return response

                if action in ('benchmark_daemon_status', 'get_benchmark_daemon_status'):
                    status = fabric['get_benchmark_daemon_status']()
                    return {
                        'success': True,
                        'status': status,
                    }

                if action in ('promote_l1', 'promote_l1_batch', 'process_l1_promotions'):
                    manager = _ensure_l1_cache_manager()
                    if manager is None:
                        return {
                            'success': False,
                            'error': 'l1_cache_manager_unavailable',
                        }

                    raw_limit = config_payload.get('limit')
                    limit: Optional[int] = None
                    if raw_limit is not None:
                        try:
                            limit = max(0, int(raw_limit))
                        except Exception:
                            limit = None

                    include_vectors = bool(config_payload.get('include_vectors', True))
                    drained = manager['drain_promotions'](limit=limit, include_vectors=include_vectors)

                    if not drained:
                        remaining_snapshot = manager['peek_promotions']()
                        return {
                            'success': True,
                            'attempted': 0,
                            'promoted': 0,
                            'failures': [],
                            'promoted_oids': [],
                            'remaining_queue': len(remaining_snapshot),
                        }

                    promotion_options = {
                        'include_vectors': include_vectors,
                        'limit': limit,
                        'notify_coordinator': config_payload.get('notify_coordinator', True),
                    }

                    promotion_result = fabric['promote_l1_candidates'](drained, promotion_options)
                    remaining_snapshot = manager['peek_promotions']()
                    promotion_result = dict(promotion_result)
                    promotion_result.setdefault('attempted', len(drained))
                    promotion_result['remaining_queue'] = len(remaining_snapshot)
                    promotion_result['success'] = bool(promotion_result.get('success', False))
                    return promotion_result

                if action in ('trigger_promotions', 'promotion_cycle', 'trigger_promotion_cycle'):
                    cycle_result = fabric['trigger_promotion_cycle'](config_payload)
                    response = dict(cycle_result)
                    response['success'] = bool(cycle_result.get('success', False))
                    return response

                if action in ('promotion_daemon_status', 'get_promotion_daemon_status'):
                    return {
                        'success': True,
                        'status': fabric['get_promotion_daemon_status'](),
                    }

        except TelosWorkerError as exc:
            logger.error("Federated memory access error: %s", exc)
            return {
                'success': False,
                'error': str(exc),
            }
        except Exception as exc:  # pragma: no cover - defensive logging path
            logger.error("Federated memory action '%s' failed: %s", action, exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        return {
            'success': False,
            'error': f"Unknown federated_memory action: {action}",
        }

    def _handle_telemetry(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Expose telemetry snapshots and summaries to Io harnesses."""
        action = request_data.get('action', 'snapshot')
        config = request_data.get('config', {}) or {}

        if action == 'snapshot':
            limit = config.get('limit')
            try:
                limit_value = int(limit) if limit is not None else None
            except (TypeError, ValueError):
                limit_value = None

            events = snapshot_telemetry_events(
                _telemetry_store_proxy,
                _telemetry_lock_proxy,
                limit=limit_value,
            )
            return {
                'success': True,
                'events': events,
            }

        if action == 'summary':
            summary = summarize_conflict_replay(
                _telemetry_store_proxy,
                _telemetry_lock_proxy,
            )
            summary['success'] = True
            return summary

        if action == 'clear':
            clear_telemetry_events(
                _telemetry_store_proxy,
                _telemetry_lock_proxy,
            )
            return {'success': True}

        return {
            'success': False,
            'error': f"Unknown telemetry action: {action}",
        }

    def _handle_bridge_metrics(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Expose prototypal bridge dispatch metrics to Io orchestrators."""

        try:
            logger = self.get_slot('logger')
        except Exception:
            logger = logging.getLogger('telos.worker.bridge_metrics')

        action = (request_data.get('action') or 'snapshot').lower()
        config = request_data.get('config') or {}

        proxy_id = config.get('proxy_id')
        raw_proxy_ids = config.get('proxy_ids')

        if isinstance(raw_proxy_ids, (list, tuple, set)):
            proxy_id_list = [str(pid) for pid in raw_proxy_ids if pid is not None]
        elif isinstance(raw_proxy_ids, str) and raw_proxy_ids:
            proxy_id_list = [raw_proxy_ids]
        elif raw_proxy_ids is None:
            proxy_id_list = None
        else:
            logger.debug("bridge_metrics received unsupported proxy_ids payload: %r", raw_proxy_ids)
            proxy_id_list = []

        summary_ids = None
        if proxy_id_list is not None:
            summary_ids = proxy_id_list
        elif proxy_id is not None:
            summary_ids = [str(proxy_id)]

        def _snapshot_many(proxy_ids: List[str]) -> Dict[str, Any]:
            return {
                pid: prototypal_bridge.get_dispatch_metrics(pid)
                for pid in proxy_ids
            }

        try:
            if action in ('snapshot', 'get', 'fetch'):
                if proxy_id_list is not None:
                    metrics = _snapshot_many(proxy_id_list)
                else:
                    metrics = prototypal_bridge.get_dispatch_metrics(proxy_id)

                return {
                    'success': True,
                    'metrics': metrics,
                }

            if action in ('summary', 'summarize'):
                summary = prototypal_bridge.summarize_dispatch_metrics(summary_ids)
                return {
                    'success': True,
                    'summary': summary,
                }

            if action in ('summary_history', 'history', 'history_get'):
                limit_value = config.get('limit')
                history = prototypal_bridge.get_summary_history(limit_value)
                return {
                    'success': True,
                    'history': history,
                }

            if action in ('summary_history_clear', 'history_clear'):
                prototypal_bridge.clear_summary_history()
                return {
                    'success': True,
                }

            if action in (
                'summary_history_config',
                'history_config',
                'configure_summary_history',
            ):
                config_payload = prototypal_bridge.configure_summary_history(config)
                return {
                    'success': True,
                    'config': config_payload,
                }

            if action in ('analyze', 'analysis', 'diagnose'):
                analysis_payload = None
                raw_analysis = config.get('analysis')
                if isinstance(raw_analysis, dict):
                    analysis_payload = raw_analysis
                else:
                    thresholds = config.get('thresholds')
                    if isinstance(thresholds, dict):
                        analysis_payload = {'thresholds': thresholds}

                analysis = prototypal_bridge.analyze_dispatch_metrics(summary_ids, analysis_payload)
                return {
                    'success': True,
                    'analysis': analysis,
                }

            if action in ('reset', 'clear'):
                if proxy_id_list is not None:
                    reset_results = {
                        pid: bool(prototypal_bridge.reset_dispatch_metrics(pid))
                        for pid in proxy_id_list
                    }
                    success = all(reset_results.values()) if reset_results else False
                    return {
                        'success': success,
                        'reset': reset_results,
                    }

                reset_success = bool(prototypal_bridge.reset_dispatch_metrics(proxy_id))
                return {
                    'success': reset_success,
                }

            if action in ('summary_reset', 'summarize_reset', 'summary-clear'):
                summary = prototypal_bridge.summarize_dispatch_metrics(summary_ids)

                if proxy_id_list is not None:
                    reset_results = {
                        pid: bool(prototypal_bridge.reset_dispatch_metrics(pid))
                        for pid in proxy_id_list
                    }
                    success = all(reset_results.values()) if reset_results else False
                    return {
                        'success': success,
                        'summary': summary,
                        'reset': reset_results,
                    }

                if proxy_id is not None:
                    reset_success = bool(prototypal_bridge.reset_dispatch_metrics(proxy_id))
                    return {
                        'success': reset_success,
                        'summary': summary,
                    }

                reset_success = bool(prototypal_bridge.reset_dispatch_metrics(None))
                return {
                    'success': reset_success,
                    'summary': summary,
                }

            if action in ('snapshot_reset', 'fetch_reset', 'snapshot-clear'):
                if proxy_id_list is not None:
                    metrics = _snapshot_many(proxy_id_list)
                    reset_results = {
                        pid: bool(prototypal_bridge.reset_dispatch_metrics(pid))
                        for pid in proxy_id_list
                    }
                    success = all(reset_results.values()) if reset_results else False
                    return {
                        'success': success,
                        'metrics': metrics,
                        'reset': reset_results,
                    }

                metrics = prototypal_bridge.get_dispatch_metrics(proxy_id)
                reset_success = bool(prototypal_bridge.reset_dispatch_metrics(proxy_id))
                return {
                    'success': reset_success,
                    'metrics': metrics,
                }

        except Exception as exc:  # pragma: no cover - defensive logging path
            logger.error("Bridge metrics action '%s' failed: %s", action, exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        return {
            'success': False,
            'error': f"Unknown bridge_metrics action: {action}",
        }

    def _handle_opentelemetry(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """Expose OpenTelemetry validation helpers to Io harnesses."""

        action = request_data.get('action', 'self_test')
        config = request_data.get('config', {}) or {}
        trace_context = _sanitize_trace_context(request_data.get('trace_context'))

        if action == 'self_test':
            return self._opentelemetry_run_self_test(config, trace_context)

        return {
            'success': False,
            'error': f"Unknown opentelemetry action: {action}",
        }

    def _opentelemetry_run_self_test(self, config: Dict[str, Any], trace_context: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        """Run an OTLP roundtrip using the shared bridge instrumentation."""

        logger = self.get_slot('logger')

        if otel_bridge is None:
            return {
                'success': False,
                'error': 'OpenTelemetry bridge is unavailable in this environment',
            }

        try:  # pragma: no cover - dependency availability varies
            import grpc  # type: ignore
            from opentelemetry.proto.collector.metrics.v1 import metrics_service_pb2  # type: ignore
            from opentelemetry.proto.collector.metrics.v1 import metrics_service_pb2_grpc  # type: ignore
            from opentelemetry.proto.collector.trace.v1 import trace_service_pb2  # type: ignore
            from opentelemetry.proto.collector.trace.v1 import trace_service_pb2_grpc  # type: ignore
        except Exception as exc:  # pragma: no cover - optional dependency path
            logger.info("OTLP dependencies unavailable: %s", exc)
            return {
                'success': False,
                'error': f"OTLP dependencies unavailable: {exc}",
            }

        collector = types.SimpleNamespace(spans=[], metrics=[])

        def _export(this, request, context):  # noqa: ANN001 - grpc signature
            if isinstance(request, trace_service_pb2.ExportTraceServiceRequest):
                this.spans.append(request)
                return trace_service_pb2.ExportTraceServiceResponse()
            if isinstance(request, metrics_service_pb2.ExportMetricsServiceRequest):
                this.metrics.append(request)
                return metrics_service_pb2.ExportMetricsServiceResponse()
            return metrics_service_pb2.ExportMetricsServiceResponse()

        collector.Export = _export.__get__(collector, type(collector))  # type: ignore[attr-defined]

        max_workers = config.get('max_workers', 4)
        try:
            worker_count = max(1, int(max_workers))
        except Exception:
            worker_count = 4

        server = grpc.server(futures.ThreadPoolExecutor(max_workers=worker_count))  # type: ignore[arg-type]
        trace_service_pb2_grpc.add_TraceServiceServicer_to_server(collector, server)  # type: ignore[attr-defined]
        metrics_service_pb2_grpc.add_MetricsServiceServicer_to_server(collector, server)  # type: ignore[attr-defined]
        port = server.add_insecure_port("127.0.0.1:0")
        server.start()

        endpoint = f"127.0.0.1:{port}"
        env_overrides = {
            "TELOS_OTEL_EXPORTER_ENDPOINT": endpoint,
            "TELOS_OTEL_EXPORTER_INSECURE": "true",
            "TELOS_OTEL_SETTINGS_PATH": "",
        }

        removed_keys = ["TELOS_OTEL_EXPORTER_HEADERS"]
        original_env: Dict[str, Optional[str]] = {}

        try:
            for key, value in env_overrides.items():
                original_env[key] = os.environ.get(key)
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

            for key in removed_keys:
                original_env[key] = os.environ.get(key)
                os.environ.pop(key, None)

            otel_bridge.shutdown()
            state = otel_bridge.configure_opentelemetry({
                "otel.self_test": "collector",
                "otel.worker_id": str(self.get_slot('worker_id')),
            })

            if not state.get('enabled'):
                return {
                    'success': False,
                    'error': state.get('error') or 'OpenTelemetry bridge failed to configure',
                }

            tracer = state.get('tracer')
            meter = state.get('meter')
            instruments = state.get('instruments', {}) or {}

            if tracer is None or meter is None:
                return {
                    'success': False,
                    'error': 'OpenTelemetry providers unavailable after configuration',
                }

            span_name = config.get('span_name', 'telos.otlp.self_test')
            with tracer.start_as_current_span(span_name) as span:  # type: ignore[union-attr]
                span.set_attribute('telos.otlp.mode', 'self_test')  # type: ignore[union-attr]
                span.set_attribute('telos.otlp.endpoint', endpoint)  # type: ignore[union-attr]

            iterations = max(1, int(config.get('iterations', 3)))
            errors = max(1, int(config.get('errors', 2)))
            start_ts = time.time()
            error_entries = []
            for index in range(errors):
                error_entries.append({
                    'index': index,
                    'duration': 0.1 + (0.05 * index),
                    'message': f"otlp-self-test-{index}",
                })

            metrics_payload = {
                'iterations': iterations,
                'error_count': errors,
                'errors': error_entries,
                'start_timestamp': start_ts,
                'end_timestamp': start_ts + 0.5,
            }

            event = build_conflict_replay_event(
                worker_id=self.get_slot('worker_id'),
                metrics=metrics_payload,
                captured_error=error_entries[-1]['message'],
                request_context={
                    'mode': 'otlp_self_test',
                    'requested_iterations': iterations,
                },
                trace_context=trace_context,
            )

            record_telemetry_event(
                _telemetry_store_proxy,
                _telemetry_lock_proxy,
                event,
                max_events=_telemetry_max_events,
            )

            counter_iterations = instruments.get('conflict_iterations')
            histogram_duration = instruments.get('conflict_duration')

            if counter_iterations is not None:
                counter_iterations.add(iterations, attributes={'telos.otlp.mode': 'self_test'})  # type: ignore[union-attr]
            if histogram_duration is not None:
                histogram_duration.record(0.42, attributes={'telos.otlp.mode': 'self_test'})  # type: ignore[union-attr]

            _emit_conflict_replay_opentelemetry(event)

            flush_timeout = max(1000, int(config.get('flush_timeout_millis', 5000)))
            flush_ok = otel_bridge.force_flush(timeout_millis=flush_timeout)

            deadline = time.time() + float(config.get('collector_deadline', 5.0))
            poll_interval = float(config.get('collector_poll_interval', 0.05))
            while time.time() < deadline:
                if collector.spans and collector.metrics:
                    break
                time.sleep(poll_interval)

            span_names: List[str] = []
            if collector.spans:
                try:
                    exported_span = (
                        collector.spans[-1]
                        .resource_spans[0]
                        .scope_spans[0]
                        .spans[0]
                    )
                    span_names.append(exported_span.name)
                except Exception:  # pragma: no cover - defensive parsing
                    logger.debug("Unable to parse exported span payload", exc_info=True)

            metric_names: List[str] = []
            if collector.metrics:
                try:
                    latest_metrics = collector.metrics[-1]
                    for resource_metrics in latest_metrics.resource_metrics:
                        for scope in resource_metrics.scope_metrics:
                            for metric in scope.metrics:
                                metric_names.append(metric.name)
                except Exception:  # pragma: no cover - defensive parsing
                    logger.debug("Unable to parse exported metric payload", exc_info=True)

            success = bool(collector.spans) and bool(collector.metrics) and flush_ok

            return {
                'success': success,
                'endpoint': endpoint,
                'flush_ok': flush_ok,
                'span_names': span_names,
                'metric_names': metric_names,
                'collector_span_count': len(collector.spans),
                'collector_metric_count': len(collector.metrics),
            }

        finally:
            try:
                otel_bridge.shutdown()
            except Exception:
                pass

            try:
                server.stop(0)
            except Exception:
                pass

            for key, value in original_env.items():
                if value is None:
                    os.environ.pop(key, None)
                else:
                    os.environ[key] = value

    def _zodb_manager_run_smoke(self, config: Dict[str, Any]) -> Dict[str, Any]:
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_zodb_worker_")
        storage_path = Path(tempdir) / "concepts.fs"

        manager = None

        try:
            manager = create_zodb_manager(storage_path=str(storage_path))

            concept_payload = config.get('concept_payload') or {
                'label': 'Worker Concept',
                'metadata': {'source': 'zodb_worker_smoke'},
                'confidence': 0.88,
            }

            oid = manager['store_concept'](concept_payload)
            if not isinstance(oid, str):
                raise RuntimeError('store_concept did not return string OID')

            loaded = manager['load_concept'](oid)
            if not loaded:
                raise RuntimeError('load_concept returned empty payload')

            update_label = config.get('update_label', 'Worker Concept Updated')
            updated = manager['update_concept'](oid, {'label': update_label})
            if not updated:
                raise RuntimeError('update_concept returned False')

            reloaded = manager['load_concept'](oid)
            if not reloaded or reloaded.get('label') != update_label:
                raise RuntimeError('Concept label did not update as expected')

            stats = manager['get_statistics']()
            removed = manager['delete_concept'](oid)
            if not removed:
                raise RuntimeError('delete_concept returned False')

            after_delete = manager['load_concept'](oid)
            if after_delete is not None:
                raise RuntimeError('Concept still present after delete operation')

            return {
                'success': True,
                'oid': oid,
                'initial_label': loaded.get('label'),
                'updated_label': reloaded.get('label'),
                'stats': stats,
                'after_delete': after_delete,
            }

        except Exception as exc:
            logger.error("ZODB smoke scenario failed: %s", exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if manager is not None:
                    manager['close']()
            except Exception:
                pass

            shutil.rmtree(tempdir, ignore_errors=True)

    def _zodb_manager_run_read_only(self, config: Dict[str, Any]) -> Dict[str, Any]:
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_zodb_worker_ro_")
        storage_path = Path(tempdir) / "concepts_ro.fs"

        writer = None
        reader = None

        try:
            concept_payload = config.get('concept_payload') or {
                'label': 'Read Only Concept',
                'metadata': {'source': 'zodb_worker_read_only'},
            }

            writer = create_zodb_manager(storage_path=str(storage_path))
            oid = writer['store_concept'](concept_payload)
            writer['close']()
            writer = None

            reader = create_zodb_manager(storage_path=str(storage_path), read_only=True)

            snapshot = reader['load_concept'](oid)

            write_failures = {}

            try:
                reader['store_concept']({'label': 'should fail'})
                write_failures['store'] = None
            except Exception as store_exc:  # pragma: no cover - failure expected
                write_failures['store'] = str(store_exc)

            try:
                reader['update_concept'](oid, {'label': 'should fail'})
                write_failures['update'] = None
            except Exception as update_exc:  # pragma: no cover - failure expected
                write_failures['update'] = str(update_exc)

            try:
                reader['delete_concept'](oid)
                write_failures['delete'] = None
            except Exception as delete_exc:  # pragma: no cover - failure expected
                write_failures['delete'] = str(delete_exc)

            success = (
                snapshot is not None
                and snapshot.get('label') == concept_payload.get('label')
                and all(write_failures.get(key) for key in ('store', 'update', 'delete'))
            )

            if not success:
                logger.warning(
                    "ZODB read-only scenario incomplete: snapshot=%s failures=%s",
                    snapshot,
                    write_failures,
                )

            return {
                'success': success,
                'oid': oid,
                'snapshot': snapshot,
                'write_failures': write_failures,
                'is_read_only': reader['is_read_only'](),
            }

        except Exception as exc:
            logger.error("ZODB read-only scenario failed: %s", exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if reader is not None:
                    reader['close']()
            except Exception:
                pass

            try:
                if writer is not None:
                    writer['close']()
            except Exception:
                pass

            shutil.rmtree(tempdir, ignore_errors=True)

    def _zodb_manager_run_commit_abort(self, config: Dict[str, Any]) -> Dict[str, Any]:
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_zodb_worker_commit_")
        storage_path = Path(tempdir) / "concepts_commit.fs"

        manager = None

        try:
            concept_payload = config.get('concept_payload') or {
                'label': 'Commit Abort Concept',
                'metadata': {'source': 'zodb_worker_commit_abort'},
            }

            transient_label = config.get('transient_label', 'Transient Label')
            committed_label = config.get('committed_label', 'Committed Label')

            manager = create_zodb_manager(storage_path=str(storage_path))
            oid = manager['store_concept'](concept_payload)
            baseline_snapshot = manager['get_concept_snapshot'](oid)

            if baseline_snapshot is None:
                raise RuntimeError('Baseline snapshot missing after store')

            mutate_ok = manager['mutate_concept_without_commit'](oid, {'label': transient_label})
            if not mutate_ok:
                raise RuntimeError('mutate_concept_without_commit failed for transient change')

            manager['abort_transaction']()

            after_abort = manager['load_concept'](oid)
            if after_abort is None or after_abort.get('label') != baseline_snapshot.get('label'):
                raise RuntimeError('Abort transaction did not restore baseline label')

            mutate_ok = manager['mutate_concept_without_commit'](oid, {'label': committed_label})
            if not mutate_ok:
                raise RuntimeError('mutate_concept_without_commit failed for committed change')

            manager['commit_transaction']()

            after_commit = manager['load_concept'](oid)
            if after_commit is None or after_commit.get('label') != committed_label:
                raise RuntimeError('Commit transaction did not persist committed label')

            return {
                'success': True,
                'oid': oid,
                'baseline': baseline_snapshot,
                'after_abort': after_abort,
                'after_commit': after_commit,
            }

        except Exception as exc:
            logger.error("ZODB commit/abort scenario failed: %s", exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if manager is not None:
                    manager['close']()
            except Exception:
                pass

            shutil.rmtree(tempdir, ignore_errors=True)

    def _zodb_manager_run_fault(self, config: Dict[str, Any], trace_context: Optional[Dict[str, str]] = None) -> Dict[str, Any]:
        logger = self.get_slot('logger')
        tempdir = tempfile.mkdtemp(prefix="telos_zodb_worker_fault_")
        storage_path = Path(tempdir) / "concepts_fault.fs"

        manager = None
        mode = config.get('mode', 'conflict')
        propagate = bool(config.get('propagate', False))

        try:
            manager = create_zodb_manager(storage_path=str(storage_path))

            fault_result: Dict[str, Any] = {
                'mode': mode,
                'propagate': propagate,
                'captured_error': None,
                'metrics': {}
            }

            try:
                if mode == 'conflict':
                    manager['force_conflict_error']()
                elif mode == 'disk_full':
                    manager['force_disk_error']()
                elif mode == 'unhandled':
                    manager['force_unhandled_error']()
                elif mode == 'conflict_replay':
                    iterations = int(config.get('iterations', 3) or 1)
                    if iterations < 1:
                        iterations = 1

                    metrics: Dict[str, Any] = {
                        'iterations': iterations,
                        'start_timestamp': time.time(),
                        'errors': [],
                        'error_count': 0,
                    }

                    for index in range(iterations):
                        attempt_start = time.time()
                        try:
                            manager['force_conflict_error']()
                        except Exception as conflict_exc:  # Expected path
                            duration = time.time() - attempt_start
                            metrics['errors'].append({
                                'index': index,
                                'message': str(conflict_exc),
                                'duration': duration,
                            })
                        else:  # pragma: no cover - unexpected success path
                            metrics['errors'].append({
                                'index': index,
                                'message': '',
                                'duration': time.time() - attempt_start,
                            })

                    metrics['end_timestamp'] = time.time()
                    metrics['error_count'] = len([entry for entry in metrics['errors'] if entry.get('message')])
                    fault_result['metrics'] = metrics
                    if metrics['errors']:
                        fault_result['captured_error'] = metrics['errors'][-1].get('message')
                    else:
                        fault_result['captured_error'] = fault_result.get('captured_error') or ''

                    telemetry_context = {
                        'requested_iterations': iterations,
                        'propagate': propagate,
                    }
                    telemetry_event = build_conflict_replay_event(
                        self.get_slot('worker_id'),
                        metrics,
                        fault_result.get('captured_error'),
                        telemetry_context,
                        trace_context=trace_context if trace_context else None,
                    )
                    record_telemetry_event(
                        _telemetry_store_proxy,
                        _telemetry_lock_proxy,
                        telemetry_event,
                        _telemetry_max_events,
                    )
                    _emit_conflict_replay_opentelemetry(telemetry_event)
                else:
                    raise ValueError(f"Unknown fault mode: {mode}")

            except Exception as exc:
                fault_result['captured_error'] = str(exc)

                if mode == 'unhandled' and propagate:
                    # Re-raise to allow bridge error propagation testing
                    raise

            return {
                'success': True,
                'fault': fault_result,
            }

        except Exception as exc:
            logger.error("ZODB fault injection scenario failed: %s", exc)
            logger.debug("Traceback: %s", traceback.format_exc())
            return {
                'success': False,
                'error': str(exc),
            }

        finally:
            try:
                if manager is not None:
                    manager['close']()
            except Exception:
                pass

            shutil.rmtree(tempdir, ignore_errors=True)
    
    def _handle_shared_memory(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle shared memory operations (create, destroy, map, unmap).
        This implements the zero-copy IPC protocol mandated by the architecture.
        """
        memory_operation = request_data.get('memory_operation', 'unknown')
        logger = self.get_slot('logger')
        memory_manager = self.get_slot('memory_manager')
        
        try:
            if memory_operation == 'create':
                size = request_data.get('size', 0)
                if size <= 0:
                    raise TelosWorkerError(f"Invalid size for shared memory creation: {size}")
                
                logger.info(f"Creating shared memory block of size {size}")
                handle = memory_manager.create_block(size)
                
                return {
                    'success': True,
                    'name': handle.name,
                    'size': handle.size,
                    'offset': handle.offset
                }
                
            elif memory_operation == 'destroy':
                name = request_data.get('name')
                if not name:
                    raise TelosWorkerError("Missing name for shared memory destruction")
                
                logger.info(f"Destroying shared memory block: {name}")
                
                # Find and close the block
                if name in memory_manager.managed_blocks:
                    shm = memory_manager.managed_blocks[name]
                    try:
                        # Only unlink if we're the main process
                        if memory_manager._is_main_process:
                            shm.unlink()
                        shm.close()
                    except Exception as e:
                        logger.warning(f"Error during shared memory cleanup: {e}")
                    finally:
                        del memory_manager.managed_blocks[name]
                
                return {'success': True}
                
            elif memory_operation == 'map':
                name = request_data.get('name')
                offset = request_data.get('offset', 0)
                size = request_data.get('size', 0)
                
                if not name:
                    raise TelosWorkerError("Missing name for shared memory mapping")
                
                logger.info(f"Mapping shared memory block: {name}, offset={offset}, size={size}")
                
                handle = SharedMemoryHandle(name=name, offset=offset, size=size)
                shm = memory_manager.get_block(handle)
                
                # Return the memory address as an integer using ctypes
                import ctypes
                try:
                    # Get the address of the shared memory buffer
                    addr = ctypes.addressof(shm.buf)
                    return {
                        'success': True,
                        'mapped_ptr': addr
                    }
                except Exception as e:
                    logger.error(f"Failed to get buffer address: {e}")
                    return {
                        'success': True,
                        'mapped_ptr': 0  # Return 0 as a fallback - C code will handle this
                    }
                
            elif memory_operation == 'unmap':
                name = request_data.get('name')
                mapped_ptr = request_data.get('mapped_ptr')
                
                if not name:
                    raise TelosWorkerError("Missing name for shared memory unmapping")
                
                logger.info(f"Unmapping shared memory block: {name}")
                
                # In our current implementation, unmapping is a no-op since we're using
                # Python's multiprocessing.shared_memory which handles cleanup automatically
                return {'success': True}
                
            else:
                raise TelosWorkerError(f"Unknown memory operation: {memory_operation}")
                
        except Exception as e:
            logger.error(f"Shared memory operation failed: {e}")
            return {
                'success': False,
                'error': str(e),
                'memory_operation': memory_operation
            }
    
    def _handle_llm_transducer(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        logger = self.get_slot('logger')

        try:
            transducer = self._ensure_llm_transducer()
        except Exception as exc:
            logger.error("LLM transducer unavailable: %s", exc)
            return {
                'success': False,
                'error': f"LLM transducer unavailable: {exc}",
            }

        payload: Dict[str, Any] = dict(request_data)
        payload.pop('operation', None)

        include_metrics = bool(payload.pop('include_metrics', False) or request_data.get('include_metrics'))

        config_overrides = payload.pop('transducer_config', None)
        if isinstance(config_overrides, dict):
            try:
                transducer['configure'](config_overrides)
            except Exception as exc:
                logger.error("Failed to configure LLM transducer: %s", exc)
                return {
                    'success': False,
                    'error': f"Failed to configure LLM transducer: {exc}",
                }

        shared_handles = payload.pop('shared_memory_handles', None)
        handle_alias_targets: Dict[str, str] = {
            'prompt': 'prompt',
            'prompt_shared_memory': 'prompt',
            'prompt_handle': 'prompt',
            'text_input': 'text_input',
            'text_input_handle': 'text_input',
            'schema_input': 'schema_input',
            'schema_input_handle': 'schema_input',
            'context': 'context',
            'context_handle': 'context',
            'output_schema': 'output_schema',
            'output_schema_handle': 'output_schema',
            'available_tools': 'available_tools',
            'available_tools_handle': 'available_tools',
            'response': 'response',
            'response_shared_memory': 'response',
            'response_handle': 'response',
        }

        handle_descriptors: Dict[str, Dict[str, Any]] = {}

        if isinstance(shared_handles, dict):
            for key, descriptor in shared_handles.items():
                if isinstance(descriptor, dict) and isinstance(descriptor.get('name'), str):
                    handle_descriptors[key] = descriptor

        for alias in handle_alias_targets.keys():
            descriptor = request_data.get(alias)
            if isinstance(descriptor, dict) and isinstance(descriptor.get('name'), str):
                handle_descriptors.setdefault(alias, descriptor)
                payload.pop(alias, None)

        response_descriptor: Optional[Dict[str, Any]] = None

        for descriptor_key, descriptor in list(handle_descriptors.items()):
            target = handle_alias_targets.get(descriptor_key, descriptor_key)

            if target == 'response':
                response_descriptor = descriptor
                continue

            try:
                text_value = self._read_shared_memory_text(descriptor)
            except Exception as exc:
                logger.error("Failed to read shared memory %s: %s", descriptor_key, exc)
                return {
                    'success': False,
                    'error': f"Failed to read shared memory '{descriptor_key}': {exc}",
                }

            if target in {'schema_input', 'output_schema', 'available_tools', 'context'}:
                try:
                    decoded = json.loads(text_value)
                except json.JSONDecodeError:
                    decoded = text_value
                payload[target] = decoded
            else:
                payload[target] = text_value

        try:
            execute = transducer.get('execute')
            if not callable(execute):
                raise TelosWorkerError('LLM transducer missing execute slot')
            result = execute(payload)
        except Exception as exc:
            logger.error("LLM transduction failed: %s", exc)
            return {
                'success': False,
                'error': str(exc),
            }

        if not isinstance(result, dict):
            logger.error("LLM transducer returned non-dict result")
            return {
                'success': False,
                'error': 'LLM transducer returned unexpected result type',
            }

        if include_metrics:
            metrics_fn = transducer.get('get_metrics')
            if callable(metrics_fn):
                try:
                    metrics = metrics_fn()
                except Exception as exc:  # pragma: no cover - defensive path
                    logger.debug("Failed to collect LLM metrics: %s", exc)
                else:
                    result = dict(result)
                    result['metrics'] = metrics

        if response_descriptor is not None:
            try:
                self._write_shared_memory_json(response_descriptor, result)
                handle = self._normalize_handle_descriptor(response_descriptor)
                result = dict(result)
                result['written_to_shared_memory'] = True
                result['response_handle'] = {
                    'name': handle.name,
                    'offset': handle.offset,
                    'size': handle.size,
                }
            except Exception as exc:
                logger.error("Failed to write LLM response to shared memory: %s", exc)
                return {
                    'success': False,
                    'error': f"Failed to write response to shared memory: {exc}",
                }

        return result

    def cleanup(self):
        """Clean up worker resources."""
        memory_manager = self.get_slot('memory_manager')
        worker_id = self.get_slot('worker_id')
        logger = self.get_slot('logger')
        
        memory_manager.cleanup()
        logger.info(f"Worker {worker_id} cleaned up")


class ProcessPoolManager:
    """
    Manager for the Python process pool that implements the GIL Quarantine Protocol.
    
    This class manages the lifecycle of worker processes and provides the interface
    for submitting tasks to the pool. It also manages the central SharedMemoryManager
    to avoid issues with daemon processes trying to create their own managers.
    """
    
    def __init__(self, max_workers: int = None):
        if max_workers is None:
            max_workers = max(1, multiprocessing.cpu_count() - 1)
        
        self.max_workers = max_workers
        self.pool = None  # multiprocessing.Pool instance
        self.shared_memory_manager = None  # Central SharedMemoryManager
        self.telemetry_manager = None
        self.telemetry_store = None
        self.telemetry_lock = None
        self.telemetry_max_events = TELEMETRY_DEFAULT_MAX_EVENTS
        self._setup_logging()
        self.otel_resource_attributes = self._collect_opentelemetry_attributes()
        self.otel_collector_config: Dict[str, Any] = {}
        if otel_bridge:
            try:
                self.otel_collector_config = otel_bridge.load_collector_config()
            except Exception as exc:  # pragma: no cover - defensive logging path
                self.logger.debug("Failed to load OpenTelemetry collector config: %s", exc)
    
    def _setup_logging(self):
        """Set up logging for the pool manager."""
        logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger('telos.pool_manager')

    def _collect_opentelemetry_attributes(self) -> Dict[str, Any]:
        """Build the base set of OpenTelemetry resource attributes for workers."""

        if not otel_bridge:
            return {}

        attrs: Dict[str, Any] = {
            "telos.worker.pool_size": self.max_workers,
        }

        env_payload = os.environ.get("TELOS_OTEL_RESOURCE")
        if env_payload:
            try:
                parsed = json.loads(env_payload)
                if isinstance(parsed, dict):
                    for key, value in parsed.items():
                        if value is None:
                            continue
                        attrs[str(key)] = value
            except json.JSONDecodeError as exc:  # pragma: no cover - configuration issue path
                self.logger.warning(
                    "Failed to parse TELOS_OTEL_RESOURCE JSON: %s", exc
                )

        return attrs
    
    def initialize(self) -> bool:
        """Initialize the process pool and shared memory manager."""
        try:
            self.logger.info(f"Initializing process pool with {self.max_workers} workers")

            if otel_bridge and self.otel_collector_config:
                collector_endpoint = self.otel_collector_config.get("endpoint", "default-env")
                self.logger.info(
                    "OpenTelemetry exporter configured for endpoint=%s (insecure=%s)",
                    collector_endpoint,
                    self.otel_collector_config.get("insecure", False),
                )
            
            # Create the central shared memory manager FIRST
            self.shared_memory_manager = SharedMemoryManager()

            # Create telemetry manager for cross-process metrics aggregation
            self.telemetry_manager = multiprocessing.Manager()
            self.telemetry_store = self.telemetry_manager.list()
            self.telemetry_lock = self.telemetry_manager.Lock()
            
            # Create the process pool
            self.pool = multiprocessing.Pool(
                processes=self.max_workers,
                initializer=self._worker_initializer,
                initargs=(
                    self.telemetry_store,
                    self.telemetry_lock,
                    self.telemetry_max_events,
                    self.otel_resource_attributes,
                ),
            )
            
            self.logger.info("Process pool initialized successfully")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to initialize process pool: {e}")
            return False
    
    @staticmethod
    def _worker_initializer(
        telemetry_store_proxy,
        telemetry_lock_proxy,
        telemetry_max_events,
        resource_attributes: Optional[Dict[str, Any]] = None,
    ):
        """Initialize a worker process."""
        # Each worker gets a unique ID
        worker_id = os.getpid()  # Use PID as unique identifier
        configure_telemetry_context(telemetry_store_proxy, telemetry_lock_proxy, telemetry_max_events)

        init_logger = logging.getLogger('telos.worker.init')

        if otel_bridge:
            try:
                worker_attrs: Dict[str, Any] = dict(resource_attributes or {})
                worker_attrs["telos.worker.pid"] = worker_id
                worker_attrs.setdefault("telos.worker.process_kind", "process_pool_worker")
                state = otel_bridge.configure_opentelemetry(worker_attrs)
                if state.get("error"):
                    init_logger.debug("OpenTelemetry disabled for worker %s: %s", worker_id, state["error"])
            except Exception as exc:  # pragma: no cover - defensive logging path
                init_logger.debug(
                    "OpenTelemetry configuration failed in worker %s: %s", worker_id, exc
                )
        
        # Create the worker instance and store it globally in the worker process
        global _worker_instance
        _worker_instance = BaseWorker(worker_id)
    
    def submit_task(self, request_data: Dict[str, Any]) -> Any:
        """Submit a task to the process pool and return a Future."""
        if not self.pool:
            raise TelosWorkerError("Process pool not initialized")

        sanitized_context = _sanitize_trace_context(request_data.get('trace_context'))
        payload = dict(request_data)
        if sanitized_context:
            payload['trace_context'] = sanitized_context
        else:
            payload.pop('trace_context', None)

        return self.pool.apply_async(_worker_execute, (payload,))
    
    def shutdown(self):
        """Shutdown the process pool and shared memory manager."""
        if self.pool:
            self.logger.info("Shutting down process pool")
            self.pool.close()
            self.pool.join()
            self.pool = None
            self.logger.info("Process pool shutdown complete")
        
        # Clean up the shared memory manager
        if self.shared_memory_manager:
            self.logger.info("Cleaning up shared memory manager")
            self.shared_memory_manager.cleanup()
            self.shared_memory_manager = None

        if self.telemetry_manager:
            self.logger.info("Shutting down telemetry manager")
            configure_telemetry_context(None, None, TELEMETRY_DEFAULT_MAX_EVENTS)
            self.telemetry_manager.shutdown()
            self.telemetry_manager = None
            self.telemetry_store = None
            self.telemetry_lock = None


def _worker_execute(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Global function that executes in worker processes.
    This function is called by the multiprocessing pool.
    """
    global _worker_instance
    
    if '_worker_instance' not in globals():
        # Fallback if worker wasn't properly initialized
        _worker_instance = BaseWorker(os.getpid())
    
    sanitized_context = _sanitize_trace_context(request_data.get('trace_context'))
    payload = dict(request_data)
    if sanitized_context:
        payload['trace_context'] = sanitized_context
    else:
        payload.pop('trace_context', None)

    return _worker_instance.execute_request(payload)


# Global process pool manager instance
_pool_manager: Optional[ProcessPoolManager] = None


def initialize_workers(max_workers: int = None) -> bool:
    """
    Initialize the global worker pool.
    This function is called from the C bridge.
    """
    global _pool_manager
    
    if _pool_manager is not None:
        logging.warning("Worker pool already initialized")
        return True
    
    _pool_manager = ProcessPoolManager(max_workers)
    return _pool_manager.initialize()


def shutdown_workers():
    """
    Shutdown the global worker pool.
    This function is called from the C bridge.
    """
    global _pool_manager
    
    if _pool_manager is not None:
        _pool_manager.shutdown()
        _pool_manager = None


def submit_worker_task(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Submit a task to the worker pool and wait for the result.
    This function is called from the C bridge.
    """
    global _pool_manager
    
    if _pool_manager is None:
        raise TelosWorkerError("Worker pool not initialized")
    
    sanitized_context = _sanitize_trace_context(request_data.get('trace_context'))
    payload = dict(request_data)
    if sanitized_context:
        payload['trace_context'] = sanitized_context
    else:
        payload.pop('trace_context', None)

    # Submit the task and wait for result
    future = _pool_manager.submit_task(payload)
    result = future.get(timeout=30)  # 30 second timeout

    if isinstance(result, dict) and sanitized_context:
        result.setdefault('trace_context', dict(sanitized_context))

    return result


if __name__ == "__main__":
    # Simple test of the worker system
    print("Testing TELOS worker system...")
    
    # Initialize workers
    if not initialize_workers(2):
        print("Failed to initialize workers")
        sys.exit(1)
    
    try:
        # Test ping
        result = submit_worker_task({
            'operation': 'ping',
            'message': 'Hello from main process'
        })
        print(f"Ping result: {result}")
        
        # Test VSA batch
        result = submit_worker_task({
            'operation': 'vsa_batch',
            'operation_name': 'bind',
            'batch_size': 10
        })
        print(f"VSA batch result: {result}")
        
    except Exception as e:
        print(f"Test failed: {e}")
    
    finally:
        shutdown_workers()
        print("Test complete")


# Initialize the base worker prototype in the global registry
# This creates the foundational prototype that all workers can clone from
def _initialize_base_prototypes():
    """Initialize the base worker prototypes in the global registry."""
    if "BaseWorker" not in _worker_prototypes:
        # Create the foundational BaseWorker prototype
        base_prototype = PrototypalWorker("BaseWorker")
        
        # Register core operation handlers
        base_prototype.set_slot('handle_ping', lambda req: {
            'success': True,
            'message': 'pong',
            'prototype_name': base_prototype.prototype_name
        })
        
        _worker_prototypes["BaseWorker"] = base_prototype


# Initialize prototypes when module is loaded
_initialize_base_prototypes()