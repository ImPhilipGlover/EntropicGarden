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
    from .performance_benchmark import create_performance_benchmark
except ImportError:  # pragma: no cover - fallback for direct imports
    from performance_benchmark import create_performance_benchmark  # type: ignore

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
    from .uvm_object import UvmObject, create_uvm_object
except ImportError:  # pragma: no cover - fallback for direct imports
    from uvm_object import UvmObject, create_uvm_object  # type: ignore

try:
    from .llm_transducer import create_llm_transducer
except ImportError:  # pragma: no cover - fallback for direct imports
    from llm_transducer import create_llm_transducer  # type: ignore

try:
    from .worker_types import PrototypalWorker, BaseWorker
except ImportError:  # pragma: no cover - fallback for direct imports
    from worker_types import PrototypalWorker, BaseWorker  # type: ignore

try:
    from .worker_exceptions import TelosProxyError, TelosWorkerError
except ImportError:  # pragma: no cover - fallback for direct imports
    from worker_exceptions import TelosProxyError, TelosWorkerError  # type: ignore

try:
    from .worker_utils import (
        _sanitize_trace_context,
        _start_worker_span,
        _emit_conflict_replay_opentelemetry,
        configure_telemetry_context,
        _normalize_l1_config,
        _ensure_l1_cache_manager,
        _resolve_shared_memory_name,
        _extract_vector_from_config,
        _prepare_vector_response,
        _get_federated_memory_interface,
        create_worker_prototype,
        get_worker_prototype,
        extend_worker_prototype,
    )
except ImportError:  # pragma: no cover - fallback for direct imports
    from worker_utils import (  # type: ignore
        _sanitize_trace_context,
        _start_worker_span,
        _emit_conflict_replay_opentelemetry,
        configure_telemetry_context,
        _normalize_l1_config,
        _ensure_l1_cache_manager,
        _resolve_shared_memory_name,
        _extract_vector_from_config,
        _prepare_vector_response,
        _get_federated_memory_interface,
        create_worker_prototype,
        get_worker_prototype,
        extend_worker_prototype,
    )
# NOTE: The implementation of the worker helper functions (vector extraction,
# shared-memory helpers, L1 cache normalization, and prototype registry) was
# moved into `libs/Telos/python/worker_utils.py` to reduce duplication and
# centralize shared state. The local duplicate implementations that previously
# followed have been removed so this module uses the shared implementations
# imported above.
try:
    # Import shared global state from worker_utils to avoid duplication
    from .worker_utils import (
        _worker_prototypes,
        _telemetry_store_proxy,
        _telemetry_lock_proxy,
        _telemetry_max_events,
        _l1_cache_manager,
        _l1_cache_config,
        _l1_cache_lock,
        FEDERATED_MEMORY_AVAILABLE,
        _federated_memory_module,
        FEDERATED_MEMORY_IMPORT_ERROR,
        _federated_memory_lock,
    )
except ImportError:  # pragma: no cover - fallback for direct imports
    from worker_utils import (  # type: ignore
        _worker_prototypes,
        _telemetry_store_proxy,
        _telemetry_lock_proxy,
        _telemetry_max_events,
        _l1_cache_manager,
        _l1_cache_config,
        _l1_cache_lock,
        FEDERATED_MEMORY_AVAILABLE,
        _federated_memory_module,
        FEDERATED_MEMORY_IMPORT_ERROR,
        _federated_memory_lock,
    )
try:
    from .shared_memory import create_shared_memory_manager
except ImportError:  # pragma: no cover - fallback for direct imports
    from shared_memory import create_shared_memory_manager  # type: ignore

try:
    from .process_pool import ProcessPoolManager, initialize_workers, submit_worker_task
except ImportError:  # pragma: no cover - fallback for direct imports
    from process_pool import ProcessPoolManager, initialize_workers, submit_worker_task  # type: ignore



# Temporarily disable problematic imports to resolve circular dependencies
# These will be re-enabled once the module structure is fixed

# try:
#     from .worker_handlers import handle_ping, handle_vsa_batch, handle_ann_search
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from worker_handlers import handle_ping, handle_vsa_batch, handle_ann_search  # type: ignore

# Stub functions for now
def handle_ping(worker, req):
    return {'success': True, 'message': 'pong'}

def handle_vsa_batch(worker, req):
    return {'success': False, 'error': 'VSA batch handler not implemented'}

def handle_ann_search(worker, req):
    return {'success': False, 'error': 'ANN search handler not implemented'}

# try:
#     from .transactional_outbox_handlers import handle_transactional_outbox
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from transactional_outbox_handlers import handle_transactional_outbox  # type: ignore

def handle_transactional_outbox(worker, req):
    return {'success': False, 'error': 'Transactional outbox handler not implemented'}

# try:
#     from .zodb_handlers import handle_zodb_manager
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from zodb_handlers import handle_zodb_manager  # type: ignore

def handle_zodb_manager(worker, req):
    return {'success': False, 'error': 'ZODB manager handler not implemented'}

# try:
#     from .federated_memory_handlers import handle_federated_memory
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from federated_memory_handlers import handle_federated_memory  # type: ignore

def handle_federated_memory(worker, req):
    return {'success': False, 'error': 'Federated memory handler not implemented'}



# try:
#     from .opentelemetry_handlers import handle_opentelemetry
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from opentelemetry_handlers import handle_opentelemetry  # type: ignore

def handle_opentelemetry(worker, req):
    return {'success': False, 'error': 'OpenTelemetry handler not implemented'}



# try:
#     from .bridge_metrics_handlers import handle_bridge_metrics
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from bridge_metrics_handlers import handle_bridge_metrics  # type: ignore

def handle_bridge_metrics(worker, req):
    return {'success': False, 'error': 'Bridge metrics handler not implemented'}



# try:
#     from .llm_handlers import handle_llm_transducer
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from llm_handlers import handle_llm_transducer  # type: ignore

def handle_llm_transducer(worker, req):
    return {'success': False, 'error': 'LLM transducer handler not implemented'}

# try:
#     from .compilation_handlers import handle_telos_compiler
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from compilation_handlers import handle_telos_compiler  # type: ignore

def handle_telos_compiler(req):
    return {'success': False, 'error': 'TelOS compiler handler not implemented'}



def handle_validate_uvm_object(req):
    """Validate that UvmObject is available and functional."""
    try:
        from .uvm_object import create_uvm_object, UvmObject
        # Test basic UvmObject creation
        test_obj = create_uvm_object({'test': 'value'})
        if not hasattr(test_obj, 'get_slot'):
            return {'success': False, 'error': 'UvmObject missing get_slot method'}
        if test_obj.get_slot('test') != 'value':
            return {'success': False, 'error': 'UvmObject slot access failed'}
        return {'success': True, 'message': 'UvmObject validation passed'}
    except Exception as e:
        return {'success': False, 'error': f'UvmObject validation failed: {str(e)}'}



# try:
#     from .transactional_outbox_scenarios import run_scenario as transactional_outbox_run_scenario
#     from .transactional_outbox_scenarios import dlq_snapshot as transactional_outbox_dlq_snapshot
#     from .transactional_outbox_scenarios import purge_processed as transactional_outbox_purge_processed
#     from .transactional_outbox_scenarios import enqueue_matrix as transactional_outbox_enqueue_matrix
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from transactional_outbox_scenarios import (  # type: ignore
#         run_scenario as transactional_outbox_run_scenario,
#         dlq_snapshot as transactional_outbox_dlq_snapshot,
#         purge_processed as transactional_outbox_purge_processed,
#         enqueue_matrix as transactional_outbox_enqueue_matrix,
#     )

# Stub functions for scenarios
def transactional_outbox_run_scenario(*args, **kwargs):
    return {'success': False, 'error': 'Transactional outbox scenario not implemented'}

def transactional_outbox_dlq_snapshot(*args, **kwargs):
    return {'success': False, 'error': 'Transactional outbox DLQ snapshot not implemented'}

def transactional_outbox_purge_processed(*args, **kwargs):
    return {'success': False, 'error': 'Transactional outbox purge processed not implemented'}

def transactional_outbox_enqueue_matrix(*args, **kwargs):
    return {'success': False, 'error': 'Transactional outbox enqueue matrix not implemented'}

# try:
#     from .zodb_scenarios import run_smoke as zodb_run_smoke
#     from .zodb_scenarios import run_read_only as zodb_run_read_only
#     from .zodb_scenarios import run_commit_abort as zodb_run_commit_abort
#     from .zodb_scenarios import run_fault as zodb_run_fault
# except ImportError:  # pragma: no cover - fallback for direct imports
#     from zodb_scenarios import (  # type: ignore
#         run_smoke as zodb_run_smoke,
#         run_read_only as zodb_run_read_only,
#         run_commit_abort as zodb_run_commit_abort,
#         run_fault as zodb_run_fault,
#     )

# Stub functions for ZODB scenarios
def zodb_run_smoke(*args, **kwargs):
    return {'success': False, 'error': 'ZODB smoke test not implemented'}

def zodb_run_read_only(*args, **kwargs):
    return {'success': False, 'error': 'ZODB read-only test not implemented'}

def zodb_run_commit_abort(*args, **kwargs):
    return {'success': False, 'error': 'ZODB commit-abort test not implemented'}

def zodb_run_fault(*args, **kwargs):
    return {'success': False, 'error': 'ZODB fault test not implemented'}



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




def create_base_worker(worker_id: int, prototype_name: str = "BaseWorker"):
    """
    Factory function for creating BaseWorker instances.

    This follows prototypal patterns by using factory functions
    instead of class constructors for object creation.

    Args:
        worker_id: Unique identifier for this worker
        prototype_name: Name of the prototype to base this on

    Returns:
        Prototypal worker object
    """
    # Get the base prototype from the registry
    if prototype_name in _worker_prototypes:
        base_prototype = _worker_prototypes[prototype_name]
    else:
        # Fallback to creating a basic prototype
        base_prototype = PrototypalWorker(prototype_name)

    # Clone the prototype (prototypal inheritance)
    worker = base_prototype.clone()

    # Set worker-specific slots
    worker.set_slot('worker_id', worker_id)
    worker.set_slot('memory_manager', create_shared_memory_manager())
    worker.set_slot('llm_transducer', create_llm_transducer())

    # Setup logging and cache the logger
    _setup_worker_logging(worker)

    # Register standard operation handlers in local slots
    _register_worker_operation_handlers(worker)

    # Add doesNotUnderstand protocol for dynamic behavior extension
    def doesNotUnderstand_(receiver, message_name):
        """Default doesNotUnderstand implementation for workers."""
        logger = receiver.get_slot('logger')
        logger.warning(f"Worker does not understand message: {message_name}")
        return None

    worker.set_slot('doesNotUnderstand_', doesNotUnderstand_)

    return worker


def _setup_worker_logging(worker):
    """Set up process-specific logging for a worker."""
    worker_id = worker.get_slot('worker_id')
    logging.basicConfig(
        level=logging.INFO,
        format=f'[Worker-{worker_id}] %(asctime)s - %(levelname)s - %(message)s',
        handlers=[logging.StreamHandler()]
    )
    logger = logging.getLogger(f'telos.worker.{worker_id}')
    worker.set_slot('logger', logger)


def _register_worker_operation_handlers(worker):
    """
    Register operation handlers using prototypal slots.
    This enables dynamic dispatch without hard-coded conditionals.
    """
    # Register handlers in local slots for efficient dispatch
    worker.set_slot('handle_vsa_batch', lambda req: handle_vsa_batch(worker, req))
    worker.set_slot('handle_ann_search', lambda req: handle_ann_search(worker, req))
    # worker.set_slot('handle_vector_operations', lambda req: handle_vector_operations(worker, req))  # TODO: Fix import
    worker.set_slot('handle_shared_memory', lambda req: _handle_shared_memory_worker(worker, req))
    worker.set_slot('handle_ping', lambda req: handle_ping(worker, req))
    worker.set_slot('handle_transactional_outbox', lambda req: handle_transactional_outbox(worker, req))
    worker.set_slot('handle_zodb_manager', lambda req: handle_zodb_manager(worker, req))
    worker.set_slot('handle_telemetry', lambda req: _handle_telemetry_worker(worker, req))
    worker.set_slot('handle_opentelemetry', lambda req: handle_opentelemetry(worker, req))
    worker.set_slot('handle_federated_memory', lambda req: handle_federated_memory(worker, req))
    worker.set_slot('handle_bridge_metrics', lambda req: handle_bridge_metrics(worker, req))
    worker.set_slot('handle_llm_transducer', lambda req: handle_llm_transducer(worker, req))
    worker.set_slot('handle_llm_transduction', lambda req: handle_llm_transducer(worker, req))
    worker.set_slot('handle_telos_compiler', lambda req: handle_telos_compiler(req))
    worker.set_slot('handle_validate_uvm_object', lambda req: handle_validate_uvm_object(req))


def _handle_shared_memory_worker(worker, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle shared memory operations (stub implementation)."""
    logger = worker.get_slot('logger')
    logger.info("Received shared memory operation (stub)")
    return {'success': True, 'message': 'shared memory stubbed'}


def _handle_vector_operations_worker(worker, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle vector operations (stub implementation)."""
    logger = worker.get_slot('logger')
    logger.info("Received vector operation (stub)")
    return {'success': True, 'message': 'vector operations stubbed'}


def _handle_telemetry_worker(worker, request_data: Dict[str, Any]) -> Dict[str, Any]:
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


def execute_worker_request(worker, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Execute a request using prototypal message dispatch with trace context propagation.
    """
    request_trace_context = _sanitize_trace_context(request_data.get('trace_context'))
    payload = dict(request_data)  # Ensure we have a fresh copy of the request data
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
            'telos.worker.id': worker.get_slot('worker_id'),
        }
        if request_trace_context.get('traceparent'):
            attributes['telos.trace.traceparent'] = request_trace_context['traceparent']

        with _start_worker_span(operation, request_trace_context, attributes):
            handler_name = f'handle_{operation}'
            try:
                handler = worker.get_slot(handler_name)
                if callable(handler):
                    result = handler(payload)
                    if isinstance(result, dict) and request_trace_context:
                        result.setdefault('trace_context', dict(request_trace_context))
                    return result
                raise TelosProxyError(f"Handler {handler_name} is not callable")
            except TelosProxyError:
                raise TelosWorkerError(f"Unknown operation: {operation}")

    except Exception as e:
        logger = worker.get_slot('logger')
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


def cleanup_worker(worker):
    """Clean up worker resources."""
    memory_manager = worker.get_slot('memory_manager')
    worker_id = worker.get_slot('worker_id')
    logger = worker.get_slot('logger')

    if memory_manager:
        memory_manager.cleanup()
    logger.info(f"Worker {worker_id} cleaned up")



def _worker_execute(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Global function that executes in worker processes.
    This function is called by the multiprocessing pool.
    """
    global _worker_instance

    if '_worker_instance' not in globals():
        # Fallback if worker wasn't properly initialized
        _worker_instance = create_base_worker(os.getpid())

    sanitized_context = _sanitize_trace_context(request_data.get('trace_context'))
    payload = dict(request_data)
    if sanitized_context:
        payload['trace_context'] = sanitized_context
    else:
        payload.pop('trace_context', None)

    return execute_worker_request(_worker_instance, payload)



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

        # Performance benchmarking handlers
        base_prototype.set_slot('handle_create_performance_benchmark', lambda req: {
            'success': True,
            'benchmarker': create_performance_benchmark(
                enable_tracing=req.get('enable_tracing', True),
                enable_memory_tracking=req.get('enable_memory_tracking', True)
            )
        })

        base_prototype.set_slot('handle_benchmark_llm_transduction', lambda req: {
            'success': True,
            'result': req.get('benchmarker', {}).get('benchmark_llm_transduction')(
                req.get('transducer'),
                req.get('test_prompts', [])
            )
        })

        base_prototype.set_slot('handle_benchmark_zodb_operations', lambda req: {
            'success': True,
            'result': req.get('benchmarker', {}).get('benchmark_zodb_operations')(
                req.get('concept_repo'),
                req.get('test_concepts', [])
            )
        })

        base_prototype.set_slot('handle_benchmark_federated_memory', lambda req: {
            'success': True,
            'result': req.get('benchmarker', {}).get('benchmark_federated_memory')(
                req.get('memory_system'),
                req.get('test_queries', [])
            )
        })

        base_prototype.set_slot('handle_generate_benchmark_report', lambda req: {
            'success': True,
            'result': req.get('benchmarker', {}).get('generate_report')(
                req.get('output_path')
            )
        })

        base_prototype.set_slot('handle_print_benchmark_summary', lambda req: {
            'success': True,
            'result': req.get('benchmarker', {}).get('print_summary')()
        })
        
        _worker_prototypes["BaseWorker"] = base_prototype


# Initialize prototypes when module is loaded
_initialize_base_prototypes()