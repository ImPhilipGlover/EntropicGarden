#!/usr/bin/env python3
"""
TELOS Transactional Outbox & Dead-Letter Queue

Implements a prototypal transactional outbox backed by ZODB and an associated
poller that reliably forwards messages while honoring the antifragile
requirements of the Phase 2 federated memory architecture. The design avoids
class-based abstractions and instead exposes factory functions that return
closures adhering to prototypal development principles.
"""

import logging
import threading
import time
import uuid
from datetime import datetime, timezone
from typing import Any, Callable, Dict, Iterable, Optional

import transaction

try:
    import ZODB
    import ZODB.FileStorage
    import ZEO
    from persistent.mapping import PersistentMapping
    from BTrees.OOBTree import OOBTree
    ZODB_AVAILABLE = True
except ImportError as import_error:
    ZODB_AVAILABLE = False
    ZODB_IMPORT_ERROR = str(import_error)

logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Helper utilities
# -----------------------------------------------------------------------------

def _resolve_storage(storage_path: Optional[str], zeo_address: Optional[tuple]):
    """Resolve the appropriate ZODB storage backend."""
    if zeo_address:
        logger.info("Transactional outbox connecting to ZEO server at %s", zeo_address)
        return ZEO.ClientStorage.ClientStorage(zeo_address)

    resolved_path = storage_path or 'telos_outbox.fs'
    logger.info("Transactional outbox using FileStorage at %s", resolved_path)
    return ZODB.FileStorage.FileStorage(resolved_path)


def _ensure_structures(root):
    """Ensure the persistent structures for the outbox exist."""
    if 'transactional_outbox' not in root:
        container = PersistentMapping()
        container['pending'] = OOBTree()
        container['inflight'] = OOBTree()
        container['processed'] = OOBTree()
        container['dlq'] = OOBTree()
        root['transactional_outbox'] = container
        transaction.commit()
        logger.info("Transactional outbox structures initialized")


# -----------------------------------------------------------------------------
# Transactional Outbox Factory
# -----------------------------------------------------------------------------

def create_transactional_outbox(config: Optional[Dict[str, Any]] = None) -> Dict[str, Callable]:
    """Create a prototypal transactional outbox backed by ZODB."""
    if not ZODB_AVAILABLE:
        raise RuntimeError(f"ZODB not available: {ZODB_IMPORT_ERROR}")

    config = config.copy() if isinstance(config, dict) else {}
    storage_path = config.get('storage_path')
    zeo_address = tuple(config['zeo_address']) if isinstance(config.get('zeo_address'), (list, tuple)) else config.get('zeo_address')
    retry_limit = int(config.get('retry_limit', 3))
    batch_size = int(config.get('batch_size', 16))
    visibility_timeout = float(config.get('visibility_timeout', 30.0))

    storage = _resolve_storage(storage_path, zeo_address)
    db = ZODB.DB(storage)
    _lock = threading.Lock()

    def _with_connection(fn: Callable[[PersistentMapping], Any]) -> Any:
        conn = db.open()
        try:
            root = conn.root()
            _ensure_structures(root)
            container: PersistentMapping = root['transactional_outbox']
            result = fn(container)
            return result
        finally:
            conn.close()

    def _now_iso() -> str:
        return datetime.now(timezone.utc).isoformat()

    def enqueue(payload: Dict[str, Any], metadata: Optional[Dict[str, Any]] = None) -> str:
        """Persist a new outbox entry."""
        entry_id = str(uuid.uuid4())
        metadata = metadata.copy() if isinstance(metadata, dict) else {}

        def _insert(container):
            pending = container['pending']
            pending[entry_id] = PersistentMapping({
                'id': entry_id,
                'payload': payload,
                'metadata': metadata,
                'attempts': 0,
                'created_at': _now_iso(),
                'updated_at': _now_iso(),
                'visibility_deadline': None,
            })
            transaction.commit()

        with _lock:
            _with_connection(_insert)

        logger.debug("Enqueued outbox message %s", entry_id)
        return entry_id

    def reserve_pending(limit: Optional[int] = None) -> Iterable[Dict[str, Any]]:
        """Atomically reserve pending entries for processing."""
        limit = int(limit or batch_size)

        def _reserve(container):
            now = time.time()
            pending = container['pending']
            inflight = container['inflight']
            reserved = []

            for entry_id, entry in list(pending.items()):
                if len(reserved) >= limit:
                    break
                entry['attempts'] = int(entry.get('attempts', 0)) + 1
                entry['updated_at'] = _now_iso()
                entry['visibility_deadline'] = now + visibility_timeout
                inflight[entry_id] = entry
                del pending[entry_id]
                reserved.append(dict(entry))

            transaction.commit()
            return reserved

        with _lock:
            return _with_connection(_reserve)

    def release_inflight(entry_id: str):
        """Return an in-flight entry back to the pending queue (e.g., timeout)."""

        def _release(container):
            inflight = container['inflight']
            pending = container['pending']
            if entry_id in inflight:
                entry = inflight[entry_id]
                entry['updated_at'] = _now_iso()
                entry['visibility_deadline'] = None
                pending[entry_id] = entry
                del inflight[entry_id]
                transaction.commit()

        with _lock:
            _with_connection(_release)

    def acknowledge(entry_id: str):
        """Mark an entry as processed successfully."""

        def _ack(container):
            inflight = container['inflight']
            processed = container['processed']
            if entry_id in inflight:
                entry = inflight[entry_id]
                entry['updated_at'] = _now_iso()
                processed[entry_id] = entry
                del inflight[entry_id]
                transaction.commit()

        with _lock:
            _with_connection(_ack)

    def fail(entry_id: str, reason: str):
        """Record a failure and move to DLQ when attempts exceed retry limit."""

        def _fail(container):
            inflight = container['inflight']
            dlq = container['dlq']
            pending = container['pending']
            entry = None

            if entry_id in inflight:
                entry = inflight[entry_id]
                del inflight[entry_id]
            elif entry_id in pending:
                entry = pending[entry_id]
                del pending[entry_id]

            if entry is None:
                transaction.commit()
                return

            entry['updated_at'] = _now_iso()
            entry.setdefault('failures', [])
            failure_timestamp = _now_iso()
            entry['failures'].append({'reason': reason, 'timestamp': failure_timestamp})
            entry['last_failure_reason'] = reason
            entry['last_failure_at'] = failure_timestamp

            if entry.get('attempts', 0) >= retry_limit:
                entry['dlq_at'] = failure_timestamp
                dlq[entry_id] = entry
            else:
                pending[entry_id] = entry

            transaction.commit()

        with _lock:
            _with_connection(_fail)

    def reap_timeouts():
        """Move any expired in-flight entries back to pending."""
        now = time.time()

        def _reap(container):
            inflight = container['inflight']
            pending = container['pending']
            expired = []
            for entry_id, entry in list(inflight.items()):
                deadline = entry.get('visibility_deadline')
                if deadline is not None and deadline <= now:
                    entry['visibility_deadline'] = None
                    pending[entry_id] = entry
                    del inflight[entry_id]
                    expired.append(entry_id)
            if expired:
                transaction.commit()
            return expired

        with _lock:
            return _with_connection(_reap)

    def get_statistics() -> Dict[str, Any]:
        """Return simple inventory statistics."""

        def _stats(container):
            return {
                'pending': len(container['pending']),
                'inflight': len(container['inflight']),
                'processed': len(container['processed']),
                'dlq': len(container['dlq']),
                'retry_limit': retry_limit,
                'batch_size': batch_size,
                'visibility_timeout': visibility_timeout,
            }

        with _lock:
            return _with_connection(_stats)

    def fetch_dlq(limit: Optional[int] = None):
        limit = int(limit or batch_size)

        def _fetch(container):
            dlq = container['dlq']
            entries = []
            for entry_id, entry in list(dlq.items())[:limit]:
                entries.append(dict(entry))
            transaction.commit()
            return entries

        with _lock:
            return _with_connection(_fetch)

    def purge_processed(max_entries: int = 100):
        """Remove old processed entries to keep storage compact."""

        def _purge(container):
            processed = container['processed']
            removed = 0
            for entry_id in list(processed.keys())[:max_entries]:
                del processed[entry_id]
                removed += 1
            if removed:
                transaction.commit()
            return removed

        with _lock:
            return _with_connection(_purge)

    def shutdown():
        """Close the underlying storage cleanly."""
        with _lock:
            db.close()
            storage.close()

    return {
        'enqueue': enqueue,
        'reserve_pending': reserve_pending,
        'release_inflight': release_inflight,
        'acknowledge': acknowledge,
        'fail': fail,
        'reap_timeouts': reap_timeouts,
        'fetch_dlq': fetch_dlq,
        'purge_processed': purge_processed,
        'get_statistics': get_statistics,
        'shutdown': shutdown,
        'config': lambda: {
            'storage_path': storage_path,
            'zeo_address': zeo_address,
            'retry_limit': retry_limit,
            'batch_size': batch_size,
            'visibility_timeout': visibility_timeout,
        },
    }


# -----------------------------------------------------------------------------
# Transactional Outbox Poller
# -----------------------------------------------------------------------------

def create_transactional_outbox_poller(outbox: Dict[str, Callable], handler: Callable[[Dict[str, Any]], None],
                                       dlq_handler: Optional[Callable[[Dict[str, Any]], None]] = None,
                                       config: Optional[Dict[str, Any]] = None) -> Dict[str, Callable]:
    """Create a background poller that processes the transactional outbox."""
    config = config.copy() if isinstance(config, dict) else {}
    poll_interval = float(config.get('poll_interval', 1.0))
    batch_size = int(config.get('batch_size', outbox['config']().get('batch_size', 16)))

    _stop_event = threading.Event()
    _thread: Optional[threading.Thread] = None

    def _process_entry(entry: Dict[str, Any]):
        entry_id = entry.get('id')
        try:
            handler(entry)
            outbox['acknowledge'](entry_id)
        except Exception as exc:  # noqa: BLE001 intentional broad capture
            logger.warning("Outbox handler error for %s: %s", entry_id, exc)
            outbox['fail'](entry_id, str(exc))
            if dlq_handler:
                dlq_entries = outbox['fetch_dlq'](1)
                if dlq_entries:
                    try:
                        dlq_handler(dlq_entries[0])
                    except Exception as dlq_exc:  # noqa: BLE001
                        logger.error("DLQ handler error for %s: %s", entry_id, dlq_exc)

    def _poll_loop():
        logger.info("Transactional outbox poller started")
        while not _stop_event.is_set():
            outbox['reap_timeouts']()
            entries = outbox['reserve_pending'](batch_size)
            if not entries:
                _stop_event.wait(poll_interval)
                continue
            for entry in entries:
                if _stop_event.is_set():
                    break
                _process_entry(entry)
        logger.info("Transactional outbox poller stopped")

    def start():
        nonlocal _thread
        if _thread and _thread.is_alive():
            logger.warning("Transactional outbox poller already running")
            return False
        _stop_event.clear()
        _thread = threading.Thread(target=_poll_loop, name="TransactionalOutboxPoller", daemon=True)
        _thread.start()
        return True

    def stop(timeout: Optional[float] = None):
        _stop_event.set()
        if _thread:
            _thread.join(timeout=timeout)

    return {
        'start': start,
        'stop': stop,
        'is_running': lambda: _thread.is_alive() if _thread else False,
    }
