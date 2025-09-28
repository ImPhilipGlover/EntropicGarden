"""
TELOS Process Pool Management

Process pool management implementing the GIL Quarantine Protocol.
"""

import multiprocessing
import logging
import os
import json
from typing import Dict, Any, Optional, List

try:
    from . import opentelemetry_bridge as otel_bridge
except ImportError:  # pragma: no cover - optional dependency path
    otel_bridge = None

from .worker_types import BaseWorker
from .worker_utils import _sanitize_trace_context, _telemetry_store_proxy, _telemetry_lock_proxy, _telemetry_max_events, configure_telemetry_context


# Global worker instance for process pool
_worker_instance: Optional[BaseWorker] = None


def _worker_execute(request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Global function that executes in worker processes.
    This function is called by the multiprocessing pool.
    """
    global _worker_instance

    if '_worker_instance' not in globals() or _worker_instance is None:
        # Fallback if worker wasn't properly initialized
        from .workers import create_base_worker
        _worker_instance = create_base_worker(os.getpid())

    sanitized_context = _sanitize_trace_context(request_data.get('trace_context'))
    payload = dict(request_data)
    if sanitized_context:
        payload['trace_context'] = sanitized_context
    else:
        payload.pop('trace_context', None)

    from .workers import execute_worker_request
    return execute_worker_request(_worker_instance, payload)


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
        self.telemetry_max_events = _telemetry_max_events
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
            from .shared_memory import create_shared_memory_manager
            self.shared_memory_manager = create_shared_memory_manager()

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
        from .workers import create_base_worker
        _worker_instance = create_base_worker(worker_id)

    def submit_task(self, request_data: Dict[str, Any]) -> Any:
        """Submit a task to the process pool and return a Future."""
        if not self.pool:
            raise RuntimeError("Process pool not initialized")

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
            configure_telemetry_context(None, None, _telemetry_max_events)
            self.telemetry_manager.shutdown()
            self.telemetry_manager = None
            self.telemetry_store = None
            self.telemetry_lock = None


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
        from .worker_exceptions import TelosWorkerError
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