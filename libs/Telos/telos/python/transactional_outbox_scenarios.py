"""
Transactional Outbox Scenario Handlers

This module contains scenario execution methods for transactional outbox operations.
These methods were extracted from workers.py to maintain the 300-line file limit.
"""

import tempfile
import shutil
import time
from pathlib import Path
from typing import Dict, Any, List


def run_scenario(config: Dict[str, Any], logger) -> Dict[str, Any]:
    """Execute a reliability scenario mirroring the Python unit test."""
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
        # Import here to avoid circular imports
        from .transactional_outbox import create_transactional_outbox, create_transactional_outbox_poller

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
        import traceback
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


def dlq_snapshot(config: Dict[str, Any], logger) -> Dict[str, Any]:
    """Produce a DLQ snapshot after exercising enqueue/poller flows."""
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
        # Import here to avoid circular imports
        from .transactional_outbox import create_transactional_outbox, create_transactional_outbox_poller

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
        import traceback
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


def purge_processed(config: Dict[str, Any], logger) -> Dict[str, Any]:
    """Purge processed entries from a persistent outbox store."""
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
        # Import here to avoid circular imports
        from .transactional_outbox import create_transactional_outbox

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


def enqueue_matrix(config: Dict[str, Any], logger) -> Dict[str, Any]:
    """Enqueue a matrix of payloads and report per-status counts."""
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
        # Import here to avoid circular imports
        from .transactional_outbox import create_transactional_outbox, create_transactional_outbox_poller

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