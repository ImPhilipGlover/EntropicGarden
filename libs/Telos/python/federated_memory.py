#!/usr/bin/env python3
"""
TELOS Phase 2 Federated Memory Integration

This module provides the complete integration of the Phase 2 Federated Memory Architecture,
bringing together the L1/L2/L3 cache layers with the Prototypal Emulation Layer to create
a unified, prototypal interface for the TELOS "Living Image."

Following architectural mandates, this provides prototypal factory functions that create
method dictionaries implementing the federated memory fabric as specified in the blueprints.
"""

import copy
import logging
import threading
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple, Union

import numpy as np

from cache_coordinator import create_cache_coordinator
from l1_cache_manager import create_l1_cache_manager
from l2_cache_manager import create_l2_cache_manager
from prototypal_bridge import (
    create_prototypal_bridge_manager,
    create_transparent_cache_proxy,
)
from transactional_outbox import (
    create_transactional_outbox,
    create_transactional_outbox_poller,
)
from zodb_manager import create_zodb_manager

logger = logging.getLogger(__name__)


def create_federated_memory_fabric():
    """Create and initialize the Phase 2 federated memory fabric."""

    default_config: Dict[str, Any] = {
        'l1': {
            'max_size': 10000,
            'vector_dim': 1024,
            'eviction_threshold': 0.8,
            'index_type': 'Flat'
        },
        'l2': {
            'storage_path': 'telos_l2_cache',
            'max_size': 1000000,
            'vector_dim': 1024
        },
        'l3': {
            'storage_path': 'telos_data.fs',
            'zeo_address': None
        },
        'coordinator': {
            'enable_l1': True,
            'enable_l2': True,
            'enable_l3': True,
            'l1_config': {},
            'l2_config': {},
            'l3_config': {}
        },
        'promotions': {
            'enabled': False,
            'interval_seconds': 1.0,
            'batch_limit': 128,
            'include_vectors': False,
            'notify_coordinator': True,
            'drain_limit': None,
            'idle_sleep_seconds': 0.25,
            'requeue_on_failure': True,
            'max_failure_samples': 32,
        },
        'bridge': {
            'workers': 4
        },
        'outbox': {
            'enabled': True,
            'storage_path': 'telos_outbox.fs',
            'zeo_address': None,
            'retry_limit': 5,
            'batch_size': 32,
            'visibility_timeout': 30.0,
        },
        'outbox_poller': {
            'enabled': True,
            'poll_interval': 0.5,
            'batch_size': 16,
            'idle_backoff_seconds': 0.25,
        }
    }

    # Internal component managers
    _l3_manager = None
    _l1_manager = None
    _l2_manager = None
    _cache_coordinator = None
    _bridge_manager = None
    _initialized = False
    _active_config: Dict[str, Any] = copy.deepcopy(default_config)
    _promotion_metrics: Dict[str, Any] = {
        'total_attempts': 0,
        'total_promoted': 0,
        'total_failures': 0,
        'requeued_after_failure': 0,
        'last_batch': {
            'count': 0,
            'promoted': 0,
            'failures': 0,
            'promoted_oids': [],
            'failure_reasons': {},
            'requeued': 0,
        },
        'failure_reasons': {},
        'failure_samples': [],
        'automatic': {
            'cycles': 0,
            'attempts': 0,
            'promoted': 0,
            'failures': 0,
            'last_result': None,
            'last_timestamp': None,
            'requeued': 0,
        },
        'manual': {
            'attempts': 0,
            'promoted': 0,
            'failures': 0,
            'last_result': None,
            'last_timestamp': None,
            'requeued': 0,
        },
    }
    _promotion_lock = threading.Lock()
    _promotion_config = copy.deepcopy(default_config['promotions'])
    _promotion_thread: Optional[threading.Thread] = None
    _promotion_stop_event: Optional[threading.Event] = None
    _promotion_wake_event: Optional[threading.Event] = None
    _promotion_runtime: Dict[str, Any] = {
        'cycles': 0,
        'last_result': None,
        'last_error': None,
        'last_run_started': None,
        'last_run_completed': None,
        'active': False,
    }

    MIN_BENCHMARK_INTERVAL = 0.1

    _benchmark_lock = threading.Lock()
    _benchmark_execution_lock = threading.Lock()
    _benchmark_state: Dict[str, Any] = {
        'last_run': None,
        'history': [],
        'max_history': 5,
        'daemon': {},
    }

    _benchmark_daemon_thread: Optional[threading.Thread] = None
    _benchmark_daemon_stop_event: Optional[threading.Event] = None
    _benchmark_daemon_wake_event: Optional[threading.Event] = None
    _benchmark_daemon_config: Dict[str, Any] = {
        'interval_seconds': 60.0,
        'options': {},
    }
    _benchmark_daemon_state: Dict[str, Any] = {
        'active': False,
        'runs': 0,
        'successful_runs': 0,
        'failed_runs': 0,
        'last_started': None,
        'last_completed': None,
        'last_duration_seconds': None,
        'last_error': None,
        'last_result': None,
        'next_run_eta': None,
    }

    _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)

    _benchmark_alert_lock = threading.Lock()
    _benchmark_alert_config: Dict[str, Any] = {
        'enabled': True,
        'history_window': 5,
        'max_history': 32,
        'thresholds': {
            'l3_tps_min': {
                'warning': 10.0,
                'critical': 5.0,
            },
            'replication_lag_p95_ms': {
                'warning': 500.0,
                'critical': 1500.0,
            },
            'hybrid_query_latency_p95_ms': {
                'warning': 400.0,
                'critical': 900.0,
            },
            'creation_latency_avg_ms': {
                'warning': 120.0,
                'critical': 300.0,
            },
            'update_latency_avg_ms': {
                'warning': 160.0,
                'critical': 360.0,
            },
            'consecutive_failures': {
                'warning': 1,
                'critical': 2,
            },
        },
    }
    _benchmark_alert_history: List[Dict[str, Any]] = []
    _benchmark_alert_runtime: Dict[str, Any] = {
        'last_evaluation_ts': None,
        'last_summary': None,
        'last_result': None,
        'last_severity': 'ok',
        'last_reasons': [],
        'last_event': None,
        'active': True,
    }

    _benchmark_recommendation_lock = threading.Lock()
    _benchmark_recommendations: List[Dict[str, Any]] = []
    _benchmark_recommendation_seq = 0

    _outbox_lock = threading.Lock()
    _transactional_outbox: Optional[Dict[str, Any]] = None
    _transactional_outbox_poller: Optional[Dict[str, Any]] = None
    _outbox_config: Dict[str, Any] = copy.deepcopy(default_config['outbox'])
    _outbox_poller_config: Dict[str, Any] = copy.deepcopy(default_config['outbox_poller'])
    OUTBOX_LATENCY_WINDOW = 128

    def _empty_latency_summary() -> Dict[str, Any]:
        return {
            'samples': 0,
            'avg_ms': None,
            'p95_ms': None,
            'max_ms': None,
            'min_ms': None,
        }

    _outbox_metrics: Dict[str, Any] = {
        'enqueued': 0,
        'processed': 0,
        'acknowledged': 0,
        'failures': 0,
        'dlq': 0,
        'last_entry_id': None,
        'last_processed_id': None,
        'last_failed_id': None,
        'last_error': None,
    'last_failure_context': None,
        'last_action': None,
        'last_entry_metadata': None,
    'last_entry_created_at': None,
        'last_latency_ms': None,
        'latency_samples_ms': [],
        'latency_summary': _empty_latency_summary(),
        'action_counts': {},
        'failure_reasons': {},
        'failure_contexts': {},
        'dlq_reasons': {},
        'latency_window': OUTBOX_LATENCY_WINDOW,
    }
    _outbox_runtime: Dict[str, Any] = {
        'enabled': False,
        'poller_enabled': False,
        'poller_running': False,
        'last_handler_error': None,
    }

    def _promotion_failure_sample_limit() -> int:
        try:
            return max(0, int(_promotion_config.get('max_failure_samples', 32)))
        except Exception:
            return 32

    def _should_requeue_failures() -> bool:
        return bool(_promotion_config.get('requeue_on_failure', True))

    def _deep_merge(target: Dict[str, Any], source: Dict[str, Any]):
        for key, value in source.items():
            if isinstance(value, dict) and isinstance(target.get(key), dict):
                _deep_merge(target[key], value)
            else:
                target[key] = value

    def _normalize_vector(vector_data: Any) -> Optional[np.ndarray]:
        if vector_data is None:
            return None
        array = np.asarray(vector_data, dtype=np.float32)
        if array.ndim > 1:
            array = array.reshape(-1)
        return array.copy()

    def _vector_to_serializable(vector: Optional[np.ndarray]) -> Optional[List[float]]:
        if vector is None:
            return None
        return vector.astype(np.float32).tolist()

    def _normalize_metadata(metadata: Any) -> Dict[str, Any]:
        if isinstance(metadata, dict):
            return copy.deepcopy(metadata)
        return {}

    def _percentile(values: List[float], pct: float) -> Optional[float]:
        if not values:
            return None
        ordered = sorted(values)
        if len(ordered) == 1:
            return ordered[0]
        percentile = max(0.0, min(100.0, float(pct))) / 100.0
        index = int(round(percentile * (len(ordered) - 1)))
        return ordered[index]

    def _summarize_series(values: List[float]) -> Dict[str, Any]:
        if not values:
            return {
                'count': 0,
                'avg_ms': None,
                'p95_ms': None,
                'max_ms': None,
            }

        total = sum(values)
        count = len(values)
        average = total / count
        p95_value = _percentile(values, 95.0)
        maximum = max(values)

        return {
            'count': count,
            'avg_ms': average,
            'p95_ms': p95_value,
            'max_ms': maximum,
        }

    def _snapshot_benchmark_state() -> Dict[str, Any]:
        with _benchmark_lock:
            return copy.deepcopy(_benchmark_state)

    def _record_benchmark_result(result: Dict[str, Any]):
        with _benchmark_lock:
            snapshot = {
                'timestamp': time.time(),
                'result': copy.deepcopy(result),
            }
            _benchmark_state['last_run'] = snapshot
            history: List[Dict[str, Any]] = _benchmark_state.get('history', [])
            history.insert(0, snapshot)
            max_history = _benchmark_state.get('max_history', 5)
            if len(history) > max_history:
                del history[max_history:]
            _benchmark_state['history'] = history
            _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)
        _evaluate_benchmark_alerts(result)

    def _collect_benchmark_history(limit: Optional[int] = None) -> Tuple[List[Dict[str, Any]], Dict[str, Any]]:
        snapshot = _snapshot_benchmark_state()
        history: List[Dict[str, Any]] = snapshot.get('history', [])
        clamped_history = history

        if limit is not None:
            try:
                limit_value = max(0, int(limit))
            except Exception:
                limit_value = None
            if limit_value is not None:
                clamped_history = history[:limit_value]

        return clamped_history, snapshot

    def _clamp_positive_int(value: Any, fallback: int, minimum: int = 1) -> int:
        try:
            coerced = int(value)
        except Exception:
            return max(minimum, fallback)
        return max(minimum, coerced)

    def _snapshot_alert_state(limit: Optional[int] = None) -> Dict[str, Any]:
        with _benchmark_alert_lock:
            history_snapshot = copy.deepcopy(_benchmark_alert_history)
            if limit is not None:
                try:
                    limit_value = max(0, int(limit))
                except Exception:
                    limit_value = None
                if limit_value is not None:
                    history_snapshot = history_snapshot[:limit_value]

            return {
                'config': copy.deepcopy(_benchmark_alert_config),
                'history': history_snapshot,
                'runtime': copy.deepcopy(_benchmark_alert_runtime),
            }

    def _update_alert_config(overrides: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        with _benchmark_alert_lock:
            working_copy = copy.deepcopy(_benchmark_alert_config)
            if isinstance(overrides, dict) and overrides:
                _deep_merge(working_copy, overrides)

            working_copy['history_window'] = _clamp_positive_int(
                working_copy.get('history_window', 5),
                fallback=5,
                minimum=1,
            )
            working_copy['max_history'] = _clamp_positive_int(
                working_copy.get('max_history', 32),
                fallback=32,
                minimum=1,
            )

            working_copy['enabled'] = bool(working_copy.get('enabled', True))

            _benchmark_alert_config.clear()
            _benchmark_alert_config.update(working_copy)
            _benchmark_alert_runtime['active'] = _benchmark_alert_config['enabled']

            return copy.deepcopy(_benchmark_alert_config)

    def _derive_recommendation_actions(reasons: List[Dict[str, Any]], severity: str) -> List[Dict[str, Any]]:
        action_types: List[str] = []
        seen: set[str] = set()

        for reason in reasons:
            metric = str(reason.get('metric', '')).lower()
            if metric == 'l3_tps_average':
                for action_type in ('run_benchmark', 'trigger_promotion_cycle', 'trigger_benchmark_run'):
                    if action_type not in seen:
                        seen.add(action_type)
                        action_types.append(action_type)
            elif metric == 'replication_lag_p95_ms':
                for action_type in ('flush_outbox', 'run_benchmark'):
                    if action_type not in seen:
                        seen.add(action_type)
                        action_types.append(action_type)
            elif metric in ('hybrid_query_latency_p95_ms', 'creation_latency_avg_ms', 'update_latency_avg_ms'):
                for action_type in ('trigger_promotion_cycle', 'run_benchmark'):
                    if action_type not in seen:
                        seen.add(action_type)
                        action_types.append(action_type)
            elif metric == 'consecutive_failures':
                for action_type in ('run_benchmark', 'trigger_benchmark_run'):
                    if action_type not in seen:
                        seen.add(action_type)
                        action_types.append(action_type)

        if not action_types and severity in ('warning', 'critical'):
            if 'run_benchmark' not in seen:
                action_types.append('run_benchmark')

        now_ts = time.time()
        return [
            {
                'type': action_type,
                'status': 'pending',
                'created_at': now_ts,
                'updated_at': None,
                'result': None,
            }
            for action_type in action_types
        ]

    def _enqueue_benchmark_recommendations(evaluation_payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        nonlocal _benchmark_recommendation_seq

        severity = evaluation_payload.get('severity', 'ok')
        if severity in (None, 'ok'):
            return None

        reasons = evaluation_payload.get('reasons') or []
        actions = _derive_recommendation_actions(reasons, str(severity))
        if not actions:
            return None

        summary_limit = evaluation_payload.get('summary_limit')
        manual = bool(evaluation_payload.get('manual', False))
        evaluation_ts = evaluation_payload.get('timestamp') or time.time()

        with _benchmark_recommendation_lock:
            _benchmark_recommendation_seq += 1
            rec_id = f"rec_{int(evaluation_ts * 1000)}_{_benchmark_recommendation_seq}"

            entry = {
                'id': rec_id,
                'timestamp': evaluation_ts,
                'severity': severity,
                'reasons': copy.deepcopy(reasons),
                'actions': actions,
                'status': 'pending',
                'manual': manual,
                'summary_limit': summary_limit,
                'source': 'benchmark_alert',
            }

            _benchmark_recommendations.insert(0, entry)
            max_history = _clamp_positive_int(
                _benchmark_alert_config.get('max_history', 32),
                fallback=32,
                minimum=1,
            )
            if len(_benchmark_recommendations) > max_history:
                del _benchmark_recommendations[max_history:]

            return copy.deepcopy(entry)

    def _summarize_numeric_series(values: List[float]) -> Dict[str, Any]:
        if not values:
            return {
                'samples': 0,
                'average': None,
                'p95': None,
                'max': None,
                'min': None,
            }

        ordered = sorted(values)
        samples = len(ordered)
        average = sum(ordered) / samples
        max_value = ordered[-1]
        min_value = ordered[0]
        p95_index = int(round(max(0.0, min(1.0, 0.95)) * (samples - 1)))
        p95_value = ordered[p95_index]

        return {
            'samples': samples,
            'average': average,
            'p95': p95_value,
            'max': max_value,
            'min': min_value,
        }

    def _aggregate_latency_metric(history_entries: List[Dict[str, Any]], metric_key: str) -> Dict[str, Any]:
        total_operations = 0
        weighted_duration = 0.0
        p95_values: List[float] = []
        max_values: List[float] = []
        min_values: List[float] = []
        sample_runs = 0

        for item in history_entries:
            result = item.get('result') or {}
            metrics = result.get('metrics') or {}
            bucket = metrics.get(metric_key)
            if not isinstance(bucket, dict):
                continue

            count = bucket.get('count')
            avg_ms = bucket.get('avg_ms') if 'avg_ms' in bucket else bucket.get('avg')
            p95_ms = bucket.get('p95_ms') if 'p95_ms' in bucket else bucket.get('p95')
            max_ms = bucket.get('max_ms') if 'max_ms' in bucket else bucket.get('max')
            min_ms = bucket.get('min_ms') if 'min_ms' in bucket else None

            if count is not None and avg_ms is not None:
                try:
                    operations = int(count)
                    avg_value = float(avg_ms)
                except Exception:
                    operations = 0
                    avg_value = None
                if operations > 0 and avg_value is not None:
                    total_operations += operations
                    weighted_duration += avg_value * operations
                    min_values.append(avg_value)
                    sample_runs += 1

            if p95_ms is not None:
                try:
                    p95_values.append(float(p95_ms))
                except Exception:
                    pass

            if max_ms is not None:
                try:
                    max_values.append(float(max_ms))
                except Exception:
                    pass

            if min_ms is not None:
                try:
                    min_values.append(float(min_ms))
                except Exception:
                    pass

        avg_ms = (weighted_duration / total_operations) if total_operations > 0 else None
        p95_aggregate = max(p95_values) if p95_values else None
        max_aggregate = max(max_values) if max_values else None
        min_aggregate = min(min_values) if min_values else None

        return {
            'runs_with_samples': sample_runs,
            'operations': total_operations,
            'avg_ms': avg_ms,
            'p95_ms': p95_aggregate,
            'max_ms': max_aggregate,
            'min_ms': min_aggregate,
        }

    def _reset_outbox_state():
        with _outbox_lock:
            _outbox_metrics.update({
                'enqueued': 0,
                'processed': 0,
                'acknowledged': 0,
                'failures': 0,
                'dlq': 0,
                'last_entry_id': None,
                'last_processed_id': None,
                'last_failed_id': None,
                'last_error': None,
                'last_failure_context': None,
                'last_action': None,
                'last_entry_metadata': None,
                'last_entry_created_at': None,
                'last_latency_ms': None,
            })
            _outbox_metrics['latency_samples_ms'] = []
            _outbox_metrics['latency_summary'] = _empty_latency_summary()
            _outbox_metrics['action_counts'] = {}
            _outbox_metrics['failure_reasons'] = {}
            _outbox_metrics['failure_contexts'] = {}
            _outbox_metrics['dlq_reasons'] = {}
            _outbox_runtime.update({
                'enabled': False,
                'poller_enabled': False,
                'poller_running': False,
                'last_handler_error': None,
            })

    def _outbox_available() -> bool:
        return _transactional_outbox is not None

    def _parse_iso_timestamp(value: Any) -> Optional[datetime]:
        if value is None:
            return None
        if isinstance(value, datetime):
            if value.tzinfo is None:
                return value.replace(tzinfo=timezone.utc)
            return value
        if isinstance(value, (int, float)):
            try:
                return datetime.fromtimestamp(float(value), tz=timezone.utc)
            except Exception:
                return None
        if isinstance(value, str):
            sanitized = value.strip()
            if not sanitized:
                return None
            try:
                return datetime.fromisoformat(sanitized)
            except ValueError:
                if sanitized.endswith('Z'):
                    try:
                        return datetime.fromisoformat(f"{sanitized[:-1]}+00:00")
                    except ValueError:
                        return None
                return None
        return None

    def _calculate_entry_latency_ms(entry: Dict[str, Any]) -> Optional[float]:
        created_at = _parse_iso_timestamp(entry.get('created_at'))
        if created_at is None:
            return None
        now = datetime.now(timezone.utc)
        delta = now - created_at
        return max(0.0, delta.total_seconds() * 1000.0)

    def _update_latency_statistics(latency_ms: Optional[float]):
        if latency_ms is None:
            return
        with _outbox_lock:
            samples: List[float] = _outbox_metrics.setdefault('latency_samples_ms', [])
            samples.append(float(latency_ms))
            if len(samples) > OUTBOX_LATENCY_WINDOW:
                del samples[0:len(samples) - OUTBOX_LATENCY_WINDOW]
            summary = _summarize_numeric_series(samples)
            _outbox_metrics['latency_summary'] = {
                'samples': summary.get('samples', 0),
                'avg_ms': summary.get('average'),
                'p95_ms': summary.get('p95'),
                'max_ms': summary.get('max'),
                'min_ms': summary.get('min'),
            }
            _outbox_metrics['last_latency_ms'] = float(latency_ms)

    def _record_outbox_failure(reason: Optional[str], entry_id: Optional[str] = None, context: Optional[str] = None):
        canonical_reason = str(reason) if reason else 'unspecified_failure'
        canonical_context = str(context) if context else None
        with _outbox_lock:
            _outbox_metrics['failures'] += 1
            _outbox_metrics['last_error'] = canonical_reason
            _outbox_metrics['last_failed_id'] = entry_id
            _outbox_metrics['last_failure_context'] = canonical_context
            _outbox_metrics['last_action'] = f"failure:{canonical_context}" if canonical_context else 'failure'
            reasons = _outbox_metrics.setdefault('failure_reasons', {})
            reasons[canonical_reason] = reasons.get(canonical_reason, 0) + 1
            if canonical_context is not None:
                contexts = _outbox_metrics.setdefault('failure_contexts', {})
                contexts[canonical_context] = contexts.get(canonical_context, 0) + 1

    def _record_dlq_reason(entry: Dict[str, Any]):
        failures = entry.get('failures') or []
        if not failures:
            return
        reason = failures[-1].get('reason')
        if reason is None:
            return
        with _outbox_lock:
            bucket = _outbox_metrics.setdefault('dlq_reasons', {})
            bucket[reason] = bucket.get(reason, 0) + 1

    def _sorted_counter(counter: Optional[Dict[str, int]]) -> List[Dict[str, Any]]:
        if not isinstance(counter, dict):
            return []
        ordered_keys = sorted(counter.keys(), key=lambda key: counter[key], reverse=True)
        return [{'label': key, 'count': counter[key]} for key in ordered_keys]

    def _enqueue_outbox_event(action: str, payload: Optional[Dict[str, Any]], metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not _outbox_available():
            return {
                'success': False,
                'error': 'transactional_outbox_unavailable',
            }

        entry_payload = {
            'action': str(action),
            'data': copy.deepcopy(payload) if isinstance(payload, dict) else {},
            'timestamp': time.time(),
        }
        metadata_payload = copy.deepcopy(metadata) if isinstance(metadata, dict) else {}
        metadata_payload.setdefault('source', 'federated_memory')
        metadata_payload.setdefault('action', action)

        try:
            entry_id = _transactional_outbox['enqueue'](entry_payload, metadata_payload)
        except Exception as exc:  # pragma: no cover - defensive
            _record_outbox_failure(str(exc), context='enqueue_outbox_event')
            return {
                'success': False,
                'error': str(exc),
            }

        with _outbox_lock:
            _outbox_metrics['enqueued'] += 1
            _outbox_metrics['last_entry_id'] = entry_id
            _outbox_metrics['last_entry_metadata'] = metadata_payload
            _outbox_metrics['last_action'] = f'enqueue:{action}'

        return {
            'success': True,
            'entry_id': entry_id,
        }

    def _handle_outbox_dlq(entry: Dict[str, Any]):
        _record_dlq_reason(entry)
        with _outbox_lock:
            _outbox_metrics['dlq'] += 1
            _outbox_metrics['last_processed_id'] = entry.get('id')
            _outbox_metrics['last_action'] = 'dlq'
            _outbox_metrics['last_entry_metadata'] = copy.deepcopy(entry.get('metadata') or {})
            _outbox_metrics['last_entry_created_at'] = entry.get('created_at')

    def _resolve_vector_for_event(oid: Optional[str], data: Dict[str, Any]) -> Tuple[Optional[np.ndarray], Dict[str, Any]]:
        vector_np = _normalize_vector(
            data.get('vector')
            or data.get('geometric_embedding')
            or data.get('cached_vector')
        )
        metadata = _normalize_metadata(data.get('metadata'))

        if vector_np is None and oid and _l3_manager:
            try:
                snapshot = _l3_manager['load_concept'](oid)
            except Exception as exc:  # pragma: no cover - defensive
                logger.warning("Failed to load concept %s while resolving outbox event: %s", oid, exc)
                snapshot = None
            if snapshot:
                vector_np = _normalize_vector(snapshot.get('geometric_embedding'))
                if not metadata:
                    metadata = _build_cache_metadata(snapshot, oid)

        return vector_np, metadata

    def _process_outbox_entry(entry: Dict[str, Any]) -> Dict[str, Any]:
        payload = entry.get('payload') or {}
        action = payload.get('action')
        data = payload.get('data') or {}
        entry_metadata = entry.get('metadata') or {}
        oid = data.get('oid') or entry_metadata.get('oid')

        if action in ('concept_created', 'concept_updated'):
            vector_np, metadata = _resolve_vector_for_event(oid, data)
            if vector_np is None:
                raise RuntimeError(f"Outbox entry {entry.get('id')} missing vector for oid={oid}")
            _propagate_vector(str(oid), vector_np, metadata)
            return {
                'success': True,
                'action': action,
                'oid': oid,
            }

        if action in ('concept_deleted', 'invalidate_concept'):
            if oid:
                invalidate_concept(str(oid))
            return {
                'success': True,
                'action': action,
                'oid': oid,
            }

        if action == 'bulk_ingest_l2':
            entries = data.get('entries') or []
            options = data.get('options') or {}
            response = bulk_ingest_l2(entries, options)
            if not response.get('success', False):
                raise RuntimeError(response.get('error', 'bulk_ingest_failed'))
            return {
                'success': True,
                'action': action,
                'ingested': response.get('ingested', 0),
            }

        raise RuntimeError(f"Unknown transactional outbox action: {action}")

    def _record_outbox_processing(result: Dict[str, Any], entry: Dict[str, Any]):
        entry_id = entry.get('id')
        payload = entry.get('payload') or {}
        action = result.get('action') or payload.get('action')
        metadata_snapshot = copy.deepcopy(entry.get('metadata') or {})
        created_at = entry.get('created_at')
        latency_ms = _calculate_entry_latency_ms(entry)

        with _outbox_lock:
            _outbox_metrics['processed'] += 1
            _outbox_metrics['acknowledged'] += 1
            _outbox_metrics['last_processed_id'] = entry_id
            _outbox_metrics['last_action'] = action
            _outbox_metrics['last_entry_metadata'] = metadata_snapshot
            _outbox_metrics['last_entry_created_at'] = created_at
            if action:
                counts = _outbox_metrics.setdefault('action_counts', {})
                counts[action] = counts.get(action, 0) + 1

        _update_latency_statistics(latency_ms)

        if result.get('error'):
            _record_outbox_failure(result['error'], entry_id=entry_id, context='process_result')

    def _start_outbox_poller(overrides: Optional[Dict[str, Any]] = None):
        nonlocal _transactional_outbox_poller
        if not _outbox_available():
            return

        poller_config = copy.deepcopy(_outbox_poller_config)
        if isinstance(overrides, dict):
            _deep_merge(poller_config, overrides)

        if not poller_config.get('enabled', True):
            with _outbox_lock:
                _outbox_runtime['poller_enabled'] = False
                _outbox_runtime['poller_running'] = False
            return

        if _transactional_outbox_poller and _transactional_outbox_poller.get('is_running', lambda: False)():
            with _outbox_lock:
                _outbox_runtime['poller_enabled'] = True
                _outbox_runtime['poller_running'] = True
            return

        def _handler(entry: Dict[str, Any]):
            try:
                result = _process_outbox_entry(entry)
            except Exception as exc:
                with _outbox_lock:
                    _outbox_metrics['last_entry_metadata'] = copy.deepcopy(entry.get('metadata') or {})
                    _outbox_metrics['last_entry_created_at'] = entry.get('created_at')
                _record_outbox_failure(str(exc), entry_id=entry.get('id'), context='poller_handler')
                raise
            _record_outbox_processing(result, entry)

        try:
            _transactional_outbox_poller = create_transactional_outbox_poller(
                _transactional_outbox,
                _handler,
                _handle_outbox_dlq,
                poller_config,
            )
            started = _transactional_outbox_poller['start']()
            with _outbox_lock:
                _outbox_runtime['poller_enabled'] = True
                _outbox_runtime['poller_running'] = bool(started)
                _outbox_runtime['enabled'] = True
        except Exception as exc:  # pragma: no cover - defensive
            _record_outbox_failure(str(exc), context='start_outbox_poller')
            with _outbox_lock:
                _outbox_runtime['poller_enabled'] = True
                _outbox_runtime['poller_running'] = False
                _outbox_runtime['last_handler_error'] = str(exc)
                _outbox_metrics['last_error'] = str(exc)

    def _stop_outbox_poller(timeout: Optional[float] = None):
        nonlocal _transactional_outbox_poller
        poller = _transactional_outbox_poller
        if not poller:
            with _outbox_lock:
                _outbox_runtime['poller_running'] = False
            return

        try:
            poller['stop'](timeout=timeout)
        except Exception as exc:  # pragma: no cover - defensive
            _record_outbox_failure(str(exc), context='stop_outbox_poller')
            with _outbox_lock:
                _outbox_runtime['last_handler_error'] = str(exc)
        finally:
            _transactional_outbox_poller = None
            with _outbox_lock:
                _outbox_runtime['poller_running'] = False

    def _process_outbox_batch(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not _outbox_available():
            return {
                'success': False,
                'error': 'transactional_outbox_unavailable',
            }

        if _transactional_outbox_poller and _transactional_outbox_poller.get('is_running', lambda: False)():
            return {
                'success': False,
                'error': 'outbox_poller_active',
            }

        options = options or {}
        limit = options.get('limit')
        if limit is not None:
            try:
                limit = max(1, int(limit))
            except Exception:
                limit = None

        try:
            _transactional_outbox['reap_timeouts']()
            entries = list(_transactional_outbox['reserve_pending'](limit))
        except Exception as exc:  # pragma: no cover - defensive
            _record_outbox_failure(str(exc), context='reserve_pending')
            return {
                'success': False,
                'error': str(exc),
            }

        processed_ids: List[str] = []
        failures: List[Dict[str, Any]] = []

        for entry in entries:
            entry_id = entry.get('id')
            try:
                result = _process_outbox_entry(entry)
            except Exception as exc:
                failures.append({'id': entry_id, 'error': str(exc)})
                with _outbox_lock:
                    _outbox_metrics['last_entry_metadata'] = copy.deepcopy(entry.get('metadata') or {})
                    _outbox_metrics['last_entry_created_at'] = entry.get('created_at')
                _record_outbox_failure(str(exc), entry_id=entry_id, context='process_outbox_batch')
                try:
                    _transactional_outbox['fail'](entry_id, str(exc))
                except Exception as fail_exc:  # pragma: no cover - defensive
                    failures[-1]['fail_error'] = str(fail_exc)
                continue

            try:
                _transactional_outbox['acknowledge'](entry_id)
            except Exception as exc:  # pragma: no cover - defensive
                failures.append({'id': entry_id, 'error': str(exc)})
                with _outbox_lock:
                    _outbox_metrics['last_entry_metadata'] = copy.deepcopy(entry.get('metadata') or {})
                    _outbox_metrics['last_entry_created_at'] = entry.get('created_at')
                _record_outbox_failure(str(exc), entry_id=entry_id, context='acknowledge_pending_batch')
                continue

            processed_ids.append(entry_id)
            _record_outbox_processing(result, entry)

        success = len(failures) == 0
        return {
            'success': success,
            'processed': processed_ids,
            'failures': failures,
            'remaining': len(processed_ids),
        }

    def run_benchmark(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not _initialized:
            result = {
                'success': False,
                'error': 'fabric_not_initialized',
            }
            _record_benchmark_result(result)
            return result
        with _benchmark_execution_lock:
            try:
                defaults: Dict[str, Any] = {
                    'concept_count': 24,
                    'vector_dim': int(_active_config.get('l1', {}).get('vector_dim', 256)),
                    'seed': 42,
                    'include_updates': False,
                    'update_ratio': 0.25,
                    'search': {
                        'ratio': 0.5,
                        'k': 3,
                        'threshold': 0.1,
                        'tiers': ['L1', 'L2'],
                    },
                    'outbox': {
                        'flush_interval': 4,
                        'limit': 64,
                        'stop_timeout': 2.0,
                        'restart_after': True,
                    },
                }

                benchmark_options = copy.deepcopy(defaults)
                if isinstance(options, dict):
                    _deep_merge(benchmark_options, options)

                concept_count = max(1, int(benchmark_options.get('concept_count', 24)))
                vector_dim = max(1, int(benchmark_options.get('vector_dim', defaults['vector_dim'])))
                seed = benchmark_options.get('seed', 42)

                search_options = benchmark_options.get('search') or {}
                search_ratio = float(search_options.get('ratio', defaults['search']['ratio']))
                search_ratio = max(0.0, min(1.0, search_ratio))
                search_k = max(1, int(search_options.get('k', defaults['search']['k'])))
                search_threshold = float(search_options.get('threshold', defaults['search']['threshold']))
                search_tiers = search_options.get('tiers') or defaults['search']['tiers']

                outbox_options = benchmark_options.get('outbox') or {}
                flush_interval = max(1, int(outbox_options.get('flush_interval', defaults['outbox']['flush_interval'])))
                flush_limit = max(1, int(outbox_options.get('limit', defaults['outbox']['limit'])))
                stop_timeout = float(outbox_options.get('stop_timeout', defaults['outbox']['stop_timeout']))
                restart_poller = bool(outbox_options.get('restart_after', True))

                include_updates = bool(benchmark_options.get('include_updates', False))
                update_ratio = float(benchmark_options.get('update_ratio', defaults['update_ratio'])) if include_updates else 0.0
                if include_updates:
                    update_ratio = max(0.0, min(1.0, update_ratio))

                benchmark_id = f"benchmark_{int(time.time() * 1000)}"
                rng = np.random.default_rng(seed)

                creation_durations_ms: List[float] = []
                update_durations_ms: List[float] = []
                search_latencies_ms: List[float] = []
                tier_latency_buckets: Dict[str, List[float]] = {}
                cache_hit_counts: Dict[str, int] = {}
                replication_lags_ms: List[float] = []
                pending_replication: Dict[str, float] = {}

                created_oids: List[str] = []
                errors: List[Dict[str, Any]] = []
                warnings: List[str] = []

                outbox_supported = _outbox_available()
                poller_was_running = False
                if outbox_supported and _transactional_outbox_poller and _transactional_outbox_poller.get('is_running', lambda: False)():
                    poller_was_running = True
                    _stop_outbox_poller(timeout=stop_timeout)

                outbox_flushes = 0
                replication_events_processed = 0

                def _drain_outbox_pending():
                    nonlocal outbox_flushes, replication_events_processed
                    if not outbox_supported:
                        return []
                    batch_start = time.perf_counter()
                    result = _process_outbox_batch({'limit': flush_limit})
                    outbox_flushes += 1
                    processed_ids = result.get('processed', [])
                    batch_end = time.perf_counter()
                    if processed_ids:
                        replication_events_processed += len(processed_ids)
                        for entry_id in processed_ids:
                            start_ts = pending_replication.pop(entry_id, None)
                            if start_ts is not None:
                                replication_lags_ms.append((batch_end - start_ts) * 1000.0)
                    return processed_ids

                workload_start = time.perf_counter()

                for index in range(concept_count):
                    vector = rng.standard_normal(vector_dim).astype(np.float32)
                    metadata = {
                        'benchmark': True,
                        'benchmark_id': benchmark_id,
                        'sequence': index,
                    }
                    payload = {
                        'name': f'{benchmark_id}_concept_{index}',
                        'geometric_embedding': vector.tolist(),
                        'metadata': metadata,
                    }

                    create_start = time.perf_counter()
                    concept_id = create_concept(payload)
                    create_end = time.perf_counter()
                    creation_durations_ms.append((create_end - create_start) * 1000.0)

                    if concept_id:
                        created_oids.append(concept_id)
                    else:
                        errors.append({'stage': 'create', 'index': index, 'error': 'create_failed'})

                    if outbox_supported and concept_id:
                        with _outbox_lock:
                            entry_id = _outbox_metrics.get('last_entry_id')
                        if entry_id:
                            pending_replication[entry_id] = create_end

                    if include_updates and concept_id and rng.random() < update_ratio:
                        update_payload = {
                            'metadata': {
                                'benchmark_update': True,
                                'timestamp': time.time(),
                                'sequence': index,
                            }
                        }
                        update_start = time.perf_counter()
                        update_success = update_concept(concept_id, update_payload)
                        update_end = time.perf_counter()
                        update_durations_ms.append((update_end - update_start) * 1000.0)
                        if not update_success:
                            errors.append({'stage': 'update', 'index': index, 'error': 'update_failed'})

                    if search_ratio > 0.0 and rng.random() < search_ratio:
                        search_start = time.perf_counter()
                        search_response = search_tiered(vector, {
                            'k': search_k,
                            'threshold': search_threshold,
                            'tiers': search_tiers,
                        })
                        search_end = time.perf_counter()
                        search_latencies_ms.append((search_end - search_start) * 1000.0)

                        if search_response.get('success'):
                            for concept in search_response.get('combined', []) or []:
                                level = concept.get('cache_level')
                                if level:
                                    cache_hit_counts[level] = cache_hit_counts.get(level, 0) + 1
                            tiers = search_response.get('tiers') or {}
                            for tier_name, tier_data in tiers.items():
                                tier_latency_buckets.setdefault(tier_name, []).append(float(tier_data.get('duration_ms', 0.0)))
                        else:
                            errors.append({
                                'stage': 'search',
                                'index': index,
                                'error': search_response.get('error', 'search_failed'),
                            })

                    if outbox_supported and (index + 1) % flush_interval == 0:
                        _drain_outbox_pending()

                if outbox_supported:
                    while pending_replication:
                        processed_ids = _drain_outbox_pending()
                        if not processed_ids:
                            break

                workload_end = time.perf_counter()

                if outbox_supported and poller_was_running and restart_poller:
                    _start_outbox_poller()
                elif outbox_supported and restart_poller and not poller_was_running:
                    _start_outbox_poller()

                duration_seconds = max(0.0, workload_end - workload_start)
                created_count = len(created_oids)
                l3_tps = (created_count / duration_seconds) if duration_seconds > 0 else None

                creation_summary = _summarize_series(creation_durations_ms)
                update_summary = _summarize_series(update_durations_ms)
                search_summary = _summarize_series(search_latencies_ms)
                replication_summary = _summarize_series(replication_lags_ms)
                tier_latency_summary = {
                    tier: _summarize_series(values)
                    for tier, values in tier_latency_buckets.items()
                }

                if pending_replication:
                    warnings.append('pending_replication_entries')

                if outbox_supported and replication_events_processed == 0:
                    warnings.append('no_replication_events_processed')

                final_outbox_status = _get_outbox_status() if outbox_supported else None

                metrics_payload = {
                    'duration_seconds': duration_seconds,
                    'l3_tps': l3_tps,
                    'creation': creation_summary,
                    'updates': update_summary,
                    'hybrid_query_latency': search_summary,
                    'replication_lag': replication_summary,
                    'replication_events_observed': len(replication_lags_ms),
                    'tier_latency': tier_latency_summary,
                    'cache_hits': cache_hit_counts,
                    'outbox': {
                        'supported': outbox_supported,
                        'flushes': outbox_flushes,
                        'processed': replication_events_processed,
                        'pending_after': len(pending_replication),
                        'status': final_outbox_status,
                    },
                }

                result = {
                    'success': len(errors) == 0,
                    'workload': {
                        'concepts_requested': concept_count,
                        'concepts_created': created_count,
                        'vector_dim': vector_dim,
                        'seed': seed,
                        'include_updates': include_updates,
                        'updates_applied': len(update_durations_ms),
                        'search_requests': len(search_latencies_ms),
                        'search_ratio': search_ratio,
                        'benchmark_id': benchmark_id,
                    },
                    'metrics': metrics_payload,
                    'errors': errors,
                    'warnings': warnings,
                }

                _record_benchmark_result(result)
                return result

            except Exception as exc:  # pragma: no cover - defensive path for daemon
                logger.error("Benchmark execution failed: %s", exc, exc_info=True)
                failure_payload = {
                    'success': False,
                    'error': str(exc),
                    'exception': exc.__class__.__name__,
                }
                _record_benchmark_result(failure_payload)
                return failure_payload

    def _benchmark_daemon_running() -> bool:
        thread = _benchmark_daemon_thread
        return thread is not None and thread.is_alive()

    def get_benchmark_daemon_status() -> Dict[str, Any]:
        running = _benchmark_daemon_running()
        with _benchmark_lock:
            status_snapshot = copy.deepcopy(_benchmark_daemon_state)
            status_snapshot['config'] = {
                'interval_seconds': _benchmark_daemon_config.get('interval_seconds'),
                'options': copy.deepcopy(_benchmark_daemon_config.get('options', {})),
            }
        status_snapshot['running'] = running
        return status_snapshot

    def _reconfigure_benchmark_daemon(config: Optional[Dict[str, Any]] = None, *, allow_interval: bool = True) -> None:
        nonlocal _benchmark_daemon_config

        if config is None:
            return

        if not isinstance(config, dict):
            return

        config_copy = copy.deepcopy(config)

        with _benchmark_lock:
            updated_config = copy.deepcopy(_benchmark_daemon_config)
            benchmark_overrides: Dict[str, Any] = copy.deepcopy(updated_config.get('options', {}))

            if allow_interval:
                interval_override = config_copy.pop('interval_seconds', None)
                if interval_override is not None:
                    try:
                        updated_config['interval_seconds'] = max(
                            MIN_BENCHMARK_INTERVAL,
                            float(interval_override),
                        )
                    except Exception:
                        pass

            options_override = config_copy.pop('options', None)
            if isinstance(options_override, dict):
                _deep_merge(benchmark_overrides, options_override)

            if config_copy:
                _deep_merge(benchmark_overrides, config_copy)

            updated_config['options'] = benchmark_overrides
            _benchmark_daemon_config = updated_config
            _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)

    def get_benchmark_history(limit: Optional[int] = None) -> Dict[str, Any]:
        history_entries, snapshot = _collect_benchmark_history(limit)
        history_payload = copy.deepcopy(snapshot)
        history_payload['history'] = history_entries

        limit_value = None
        if limit is not None:
            try:
                limit_value = max(0, int(limit))
            except Exception:
                limit_value = None

        history_payload['history_limit'] = limit_value
        history_payload['history_window'] = len(history_entries)
        history_payload['daemon_status'] = get_benchmark_daemon_status()
        return history_payload

    def get_benchmark_summary(limit: Optional[int] = None) -> Dict[str, Any]:
        history_entries, snapshot = _collect_benchmark_history(limit)
        total_available = len(snapshot.get('history', []))
        window_size = len(history_entries)

        success_runs = 0
        failure_runs = 0
        last_success_ts = None
        last_failure_ts = None
        l3_tps_values: List[float] = []
        warnings_set = set()

        for entry in history_entries:
            timestamp = entry.get('timestamp')
            result = entry.get('result') or {}
            if result.get('success'):
                success_runs += 1
                if timestamp is not None and last_success_ts is None:
                    last_success_ts = timestamp
            else:
                failure_runs += 1
                if timestamp is not None and last_failure_ts is None:
                    last_failure_ts = timestamp

            metrics = result.get('metrics') or {}
            l3_value = metrics.get('l3_tps')
            if l3_value is not None:
                try:
                    l3_tps_values.append(float(l3_value))
                except Exception:
                    pass

            entry_warnings = result.get('warnings') or []
            if isinstance(entry_warnings, list):
                for warning in entry_warnings:
                    warnings_set.add(str(warning))

        summary_payload: Dict[str, Any] = {
            'runs_considered': window_size,
            'runs_available': total_available,
            'successful_runs': success_runs,
            'failed_runs': failure_runs,
            'last_success_timestamp': last_success_ts,
            'last_failure_timestamp': last_failure_ts,
            'history_limit': limit,
            'warnings': sorted(warnings_set),
        }

        summary_payload['l3_tps'] = _summarize_numeric_series(l3_tps_values)
        summary_payload['creation_latency_ms'] = _aggregate_latency_metric(history_entries, 'creation')
        summary_payload['update_latency_ms'] = _aggregate_latency_metric(history_entries, 'updates')
        summary_payload['hybrid_query_latency_ms'] = _aggregate_latency_metric(history_entries, 'hybrid_query_latency')
        summary_payload['replication_lag_ms'] = _aggregate_latency_metric(history_entries, 'replication_lag')

        daemon_status = get_benchmark_daemon_status()
        summary_payload['daemon_status'] = daemon_status
        summary_payload['latest_run'] = history_entries[0] if history_entries else None

        return summary_payload

    def _evaluate_benchmark_alerts(
        latest_result: Optional[Dict[str, Any]] = None,
        *,
        manual: bool = False,
        override_limit: Optional[Any] = None,
    ) -> Dict[str, Any]:
        config_snapshot = copy.deepcopy(_benchmark_alert_config)
        enabled = bool(config_snapshot.get('enabled', True))

        summary_limit = config_snapshot.get('history_window', 5)
        summary_limit = _clamp_positive_int(summary_limit, fallback=5, minimum=1)
        if override_limit is not None:
            summary_limit = _clamp_positive_int(override_limit, fallback=summary_limit, minimum=1)

        history_entries, _ = _collect_benchmark_history(summary_limit)
        summary_payload = get_benchmark_summary(summary_limit)

        failure_runs = int(summary_payload.get('failed_runs') or 0)
        runs_considered = int(summary_payload.get('runs_considered') or 0)

        consecutive_failures = 0
        for entry in history_entries:
            entry_result = entry.get('result') or {}
            if entry_result.get('success'):
                break
            consecutive_failures += 1

        thresholds = config_snapshot.get('thresholds') or {}
        reasons: List[Dict[str, Any]] = []
        severity = 'ok'
        severity_rank = {'ok': 0, 'warning': 1, 'critical': 2}

        def _coerce_float(value: Any) -> Optional[float]:
            if value is None:
                return None
            try:
                return float(value)
            except Exception:
                return None

        def _register_reason(metric: str, level: str, observed: Any, threshold: Any, comparison: str, detail: Optional[str] = None):
            nonlocal severity
            normalized_level = level if level in severity_rank else 'warning'
            if severity_rank[normalized_level] > severity_rank[severity]:
                severity = normalized_level
            reason_payload = {
                'metric': metric,
                'severity': normalized_level,
                'observed': observed,
                'threshold': threshold,
                'comparison': comparison,
            }
            if detail is not None:
                reason_payload['detail'] = detail
            reasons.append(reason_payload)

        def _check_minimum(threshold_key: str, metric_label: str, observed_value: Optional[float]):
            if observed_value is None:
                return
            config_block = thresholds.get(threshold_key) or {}
            critical_threshold = _coerce_float(config_block.get('critical'))
            warning_threshold = _coerce_float(config_block.get('warning'))
            if critical_threshold is not None and observed_value < critical_threshold:
                _register_reason(metric_label, 'critical', observed_value, critical_threshold, 'minimum')
            elif warning_threshold is not None and observed_value < warning_threshold:
                _register_reason(metric_label, 'warning', observed_value, warning_threshold, 'minimum')

        def _check_maximum(threshold_key: str, metric_label: str, observed_value: Optional[float], value_label: str):
            if observed_value is None:
                return
            config_block = thresholds.get(threshold_key) or {}
            critical_threshold = _coerce_float(config_block.get('critical'))
            warning_threshold = _coerce_float(config_block.get('warning'))
            if critical_threshold is not None and observed_value > critical_threshold:
                _register_reason(metric_label, 'critical', observed_value, critical_threshold, f'max_{value_label}')
            elif warning_threshold is not None and observed_value > warning_threshold:
                _register_reason(metric_label, 'warning', observed_value, warning_threshold, f'max_{value_label}')

        l3_stats = summary_payload.get('l3_tps') or {}
        _check_minimum('l3_tps_min', 'l3_tps_average', _coerce_float(l3_stats.get('average')))

        replication_stats = summary_payload.get('replication_lag_ms') or {}
        _check_maximum('replication_lag_p95_ms', 'replication_lag_p95_ms', _coerce_float(replication_stats.get('p95_ms')), 'p95')

        hybrid_stats = summary_payload.get('hybrid_query_latency_ms') or {}
        _check_maximum('hybrid_query_latency_p95_ms', 'hybrid_query_latency_p95_ms', _coerce_float(hybrid_stats.get('p95_ms')), 'p95')

        creation_stats = summary_payload.get('creation_latency_ms') or {}
        _check_maximum('creation_latency_avg_ms', 'creation_latency_avg_ms', _coerce_float(creation_stats.get('avg_ms')), 'average')

        update_stats = summary_payload.get('update_latency_ms') or {}
        if update_stats.get('operations', 0):
            _check_maximum('update_latency_avg_ms', 'update_latency_avg_ms', _coerce_float(update_stats.get('avg_ms')), 'average')

        consecutive_thresholds = thresholds.get('consecutive_failures') or {}
        critical_consecutive = consecutive_thresholds.get('critical')
        warning_consecutive = consecutive_thresholds.get('warning')
        if critical_consecutive is not None:
            try:
                if consecutive_failures >= int(critical_consecutive):
                    _register_reason('consecutive_failures', 'critical', consecutive_failures, int(critical_consecutive), 'maximum')
            except Exception:
                pass
        if warning_consecutive is not None:
            try:
                if severity == 'ok' and consecutive_failures >= int(warning_consecutive):
                    _register_reason('consecutive_failures', 'warning', consecutive_failures, int(warning_consecutive), 'maximum')
            except Exception:
                pass

        evaluation_ts = time.time()
        evaluation_payload: Dict[str, Any] = {
            'enabled': enabled,
            'severity': severity,
            'reasons': copy.deepcopy(reasons),
            'summary_limit': summary_limit,
            'summary': summary_payload,
            'runs_considered': runs_considered,
            'failed_runs': failure_runs,
            'consecutive_failures': consecutive_failures,
            'timestamp': evaluation_ts,
            'manual': bool(manual),
        }
        if latest_result is not None:
            evaluation_payload['latest_result'] = copy.deepcopy(latest_result)

        emitted_event: Optional[Dict[str, Any]] = None
        with _benchmark_alert_lock:
            _benchmark_alert_runtime['last_evaluation_ts'] = evaluation_ts
            _benchmark_alert_runtime['last_summary'] = copy.deepcopy(summary_payload)
            _benchmark_alert_runtime['last_result'] = copy.deepcopy(latest_result) if latest_result is not None else None
            _benchmark_alert_runtime['last_severity'] = severity
            _benchmark_alert_runtime['last_reasons'] = copy.deepcopy(reasons)
            _benchmark_alert_runtime['active'] = enabled

            if enabled and severity != 'ok' and reasons:
                emitted_event = {
                    'timestamp': evaluation_ts,
                    'severity': severity,
                    'reasons': copy.deepcopy(reasons),
                    'summary': copy.deepcopy(summary_payload),
                    'manual': bool(manual),
                    'summary_limit': summary_limit,
                    'consecutive_failures': consecutive_failures,
                }
                if latest_result is not None:
                    emitted_event['latest_result'] = copy.deepcopy(latest_result)

                _benchmark_alert_history.insert(0, emitted_event)
                max_history = _clamp_positive_int(
                    config_snapshot.get('max_history', _benchmark_alert_config.get('max_history', 32)),
                    fallback=_benchmark_alert_config.get('max_history', 32),
                    minimum=1,
                )
                if len(_benchmark_alert_history) > max_history:
                    del _benchmark_alert_history[max_history:]
                _benchmark_alert_runtime['last_event'] = copy.deepcopy(emitted_event)

        evaluation_payload['alerts_emitted'] = emitted_event is not None
        if emitted_event is not None:
            evaluation_payload['event'] = emitted_event

        recommendation_entry = _enqueue_benchmark_recommendations(evaluation_payload)
        if recommendation_entry is not None:
            evaluation_payload['recommendation'] = recommendation_entry

        return evaluation_payload

    def get_benchmark_alerts(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        limit = None
        refresh = False
        if isinstance(options, dict):
            if options.get('limit') is not None:
                limit = options.get('limit')
            refresh = bool(options.get('refresh', False))

        if refresh:
            _evaluate_benchmark_alerts(manual=True, override_limit=limit)

        return _snapshot_alert_state(limit)

    def configure_benchmark_alerts(config: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        applied_config = _update_alert_config(config)
        evaluation = _evaluate_benchmark_alerts(manual=True)
        snapshot = _snapshot_alert_state()
        return {
            'config': applied_config,
            'evaluation': evaluation,
            'alerts': snapshot,
        }

    def clear_benchmark_alerts() -> Dict[str, Any]:
        with _benchmark_alert_lock:
            _benchmark_alert_history.clear()
            _benchmark_alert_runtime['last_event'] = None
            _benchmark_alert_runtime['last_reasons'] = []
        snapshot = _snapshot_alert_state()
        return snapshot

    def evaluate_benchmark_alerts(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        limit_override = None
        if isinstance(options, dict) and options.get('limit') is not None:
            limit_override = options.get('limit')

        evaluation = _evaluate_benchmark_alerts(manual=True, override_limit=limit_override)
        evaluation['alerts'] = _snapshot_alert_state(limit_override)
        return evaluation

    def _snapshot_recommendations(limit: Optional[Any] = None, ids: Optional[Set[str]] = None, include_completed: bool = True) -> Dict[str, Any]:
        with _benchmark_recommendation_lock:
            total = len(_benchmark_recommendations)
            entries: List[Dict[str, Any]] = []
            limit_value: Optional[int] = None
            if limit is not None:
                try:
                    limit_value = max(0, int(limit))
                except Exception:
                    limit_value = None

            for entry in _benchmark_recommendations:
                if ids is not None and entry['id'] not in ids:
                    continue
                if not include_completed and entry.get('status') == 'applied':
                    continue
                entries.append(copy.deepcopy(entry))
                if limit_value is not None and len(entries) >= limit_value:
                    break

        return {
            'total': total,
            'recommendations': entries,
        }

    def get_benchmark_recommendations(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        limit = None
        include_completed = True
        ids: Optional[Set[str]] = None

        if isinstance(options, dict):
            if options.get('limit') is not None:
                limit = options.get('limit')
            include_completed = bool(options.get('include_completed', True))
            raw_ids = options.get('ids')
            if isinstance(raw_ids, (list, tuple, set)):
                ids = {str(item) for item in raw_ids}
            elif isinstance(raw_ids, str):
                ids = {raw_ids}

        snapshot = _snapshot_recommendations(limit=limit, ids=ids, include_completed=include_completed)
        snapshot['success'] = True
        return snapshot

    def clear_benchmark_recommendations(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        ids: Optional[Set[str]] = None
        if isinstance(options, dict):
            raw_ids = options.get('ids')
            if isinstance(raw_ids, (list, tuple, set)):
                ids = {str(item) for item in raw_ids}
            elif isinstance(raw_ids, str):
                ids = {raw_ids}

        with _benchmark_recommendation_lock:
            if ids is None:
                _benchmark_recommendations.clear()
            else:
                _benchmark_recommendations[:] = [entry for entry in _benchmark_recommendations if entry['id'] not in ids]

        snapshot = _snapshot_recommendations()
        snapshot['success'] = True
        return snapshot

    def apply_benchmark_recommendations(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        limit = None
        include_completed = False
        ids: Optional[Set[str]] = None

        if isinstance(options, dict):
            if options.get('limit') is not None:
                limit = options.get('limit')
            include_completed = bool(options.get('include_completed', False))
            raw_ids = options.get('ids')
            if isinstance(raw_ids, (list, tuple, set)):
                ids = {str(item) for item in raw_ids}
            elif isinstance(raw_ids, str):
                ids = {raw_ids}

        selected: List[Dict[str, Any]] = []
        with _benchmark_recommendation_lock:
            limit_value: Optional[int] = None
            if limit is not None:
                try:
                    limit_value = max(0, int(limit))
                except Exception:
                    limit_value = None

            for entry in _benchmark_recommendations:
                if ids is not None and entry['id'] not in ids:
                    continue
                if not include_completed and entry.get('status') == 'applied':
                    continue
                entry['status'] = 'processing'
                for action in entry.get('actions', []):
                    if action.get('status') == 'pending':
                        action['status'] = 'processing'
                        action['updated_at'] = time.time()
                selected.append(entry)
                if limit_value is not None and len(selected) >= limit_value:
                    break

        def _execute_action(action: Dict[str, Any]) -> Dict[str, Any]:
            action_type = action.get('type')
            try:
                if action_type == 'flush_outbox':
                    result = _process_outbox_batch({'limit': _outbox_metrics.get('latency_window', 128)})
                elif action_type == 'trigger_promotion_cycle':
                    result = trigger_promotion_cycle({})
                elif action_type == 'trigger_benchmark_run':
                    result = trigger_benchmark_run({})
                elif action_type == 'run_benchmark':
                    probe_options = {
                        'concept_count': 6,
                        'vector_dim': int(_active_config.get('l1', {}).get('vector_dim', 64)),
                        'include_updates': False,
                        'search': {
                            'ratio': 0.5,
                            'k': 3,
                            'tiers': ['L1', 'L2'],
                        },
                    }
                    result = run_benchmark(probe_options)
                else:
                    raise ValueError(f"unknown recommendation action '{action_type}'")

                action['result'] = result
                action['updated_at'] = time.time()
                if result.get('success', False):
                    action['status'] = 'applied'
                else:
                    action['status'] = 'failed'
                    if 'error' in result:
                        action['error'] = result['error']
                return result
            except Exception as exc:
                action['status'] = 'failed'
                action['error'] = str(exc)
                action['updated_at'] = time.time()
                return {'success': False, 'error': str(exc)}

        summary: List[Dict[str, Any]] = []
        for entry in selected:
            entry_results: List[Dict[str, Any]] = []
            for action in entry.get('actions', []):
                if action.get('status') == 'processing':
                    result = _execute_action(action)
                    entry_results.append({
                        'type': action.get('type'),
                        'status': action.get('status'),
                        'result': result,
                        'error': action.get('error'),
                    })

            statuses = {action.get('status') for action in entry.get('actions', [])}
            if statuses == {'applied'}:
                entry['status'] = 'applied'
            elif 'applied' in statuses and 'failed' in statuses:
                entry['status'] = 'partial'
            elif statuses == {'failed'}:
                entry['status'] = 'failed'
            else:
                entry['status'] = list(statuses)[0] if statuses else 'pending'
            entry['last_applied'] = time.time()

            summary.append({
                'id': entry.get('id'),
                'status': entry.get('status'),
                'actions': entry_results,
            })

        snapshot = _snapshot_recommendations()
        snapshot['success'] = True
        snapshot['applied'] = summary
        return snapshot

    def start_benchmark_daemon(config: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        nonlocal _benchmark_daemon_thread, _benchmark_daemon_stop_event, _benchmark_daemon_wake_event

        if not _initialized:
            return {'success': False, 'error': 'fabric_not_initialized'}

        _reconfigure_benchmark_daemon(config, allow_interval=True)

        if _benchmark_daemon_running():
            if _benchmark_daemon_wake_event is not None:
                _benchmark_daemon_wake_event.set()
            return {
                'success': True,
                'reconfigured': True,
                'status': get_benchmark_daemon_status(),
            }

        stop_event = threading.Event()
        wake_event = threading.Event()
        wake_event.set()  # Run immediately on start

        def _daemon_loop():
            nonlocal stop_event, wake_event
            while not stop_event.is_set():
                with _benchmark_lock:
                    interval_seconds = max(
                        MIN_BENCHMARK_INTERVAL,
                        float(_benchmark_daemon_config.get('interval_seconds', 60.0)),
                    )
                    benchmark_options = copy.deepcopy(_benchmark_daemon_config.get('options', {}))

                triggered = wake_event.wait(timeout=interval_seconds)
                wake_event.clear()

                if stop_event.is_set():
                    break

                start_wall = time.time()
                start_perf = time.perf_counter()

                with _benchmark_lock:
                    _benchmark_daemon_state['active'] = True
                    _benchmark_daemon_state['last_started'] = start_wall
                    _benchmark_daemon_state['last_error'] = None
                    _benchmark_daemon_state['next_run_eta'] = None
                    _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)

                result = run_benchmark(benchmark_options)

                end_perf = time.perf_counter()
                end_wall = time.time()
                duration = max(0.0, end_perf - start_perf)

                with _benchmark_lock:
                    _benchmark_daemon_state['last_completed'] = end_wall
                    _benchmark_daemon_state['last_duration_seconds'] = duration
                    _benchmark_daemon_state['last_result'] = copy.deepcopy(result)
                    _benchmark_daemon_state['runs'] += 1
                    if result.get('success'):
                        _benchmark_daemon_state['successful_runs'] += 1
                        _benchmark_daemon_state['last_error'] = None
                    else:
                        _benchmark_daemon_state['failed_runs'] += 1
                        _benchmark_daemon_state['last_error'] = result.get('error') or result.get('errors')

                    if not stop_event.is_set():
                        _benchmark_daemon_state['next_run_eta'] = end_wall + interval_seconds
                    else:
                        _benchmark_daemon_state['next_run_eta'] = None

                    _benchmark_daemon_state['active'] = False

                    _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)

            with _benchmark_lock:
                _benchmark_daemon_state['active'] = False
                _benchmark_daemon_state['next_run_eta'] = None
                _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)

        _benchmark_daemon_stop_event = stop_event
        _benchmark_daemon_wake_event = wake_event
        _benchmark_daemon_thread = threading.Thread(
            target=_daemon_loop,
            name="TelosBenchmarkDaemon",
            daemon=True,
        )
        _benchmark_daemon_thread.start()

        return {
            'success': True,
            'status': get_benchmark_daemon_status(),
        }

    def trigger_benchmark_run(config: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not _benchmark_daemon_running():
            return {'success': False, 'error': 'benchmark_daemon_not_running'}

        if config:
            _reconfigure_benchmark_daemon(config, allow_interval=True)

        if _benchmark_daemon_wake_event is not None:
            _benchmark_daemon_wake_event.set()

        return {
            'success': True,
            'scheduled': True,
            'status': get_benchmark_daemon_status(),
        }

    def stop_benchmark_daemon(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        nonlocal _benchmark_daemon_thread, _benchmark_daemon_stop_event, _benchmark_daemon_wake_event

        timeout = None
        if isinstance(options, dict) and options.get('timeout') is not None:
            try:
                timeout = float(options['timeout'])
            except Exception:
                timeout = None

        thread = _benchmark_daemon_thread
        if thread is None:
            return {'success': True, 'status': get_benchmark_daemon_status()}

        if _benchmark_daemon_stop_event is not None:
            _benchmark_daemon_stop_event.set()
        if _benchmark_daemon_wake_event is not None:
            _benchmark_daemon_wake_event.set()

        thread.join(timeout=timeout if timeout is not None else 5.0)

        if thread.is_alive():
            return {
                'success': False,
                'error': 'benchmark_daemon_stop_timeout',
                'status': get_benchmark_daemon_status(),
            }

        _benchmark_daemon_thread = None
        _benchmark_daemon_stop_event = None
        _benchmark_daemon_wake_event = None

        with _benchmark_lock:
            _benchmark_daemon_state['active'] = False
            _benchmark_daemon_state['next_run_eta'] = None
            _benchmark_state['daemon'] = copy.deepcopy(_benchmark_daemon_state)

        return {
            'success': True,
            'status': get_benchmark_daemon_status(),
        }

    def _get_outbox_status() -> Dict[str, Any]:
        with _outbox_lock:
            metrics_snapshot = copy.deepcopy(_outbox_metrics)
            runtime_snapshot = copy.deepcopy(_outbox_runtime)

        runtime_snapshot['available'] = _outbox_available()
        if _transactional_outbox_poller and _transactional_outbox_poller.get('is_running', lambda: False)():
            runtime_snapshot['poller_running'] = True
        else:
            runtime_snapshot['poller_running'] = False

        inventory = None
        if _outbox_available():
            try:
                inventory = _transactional_outbox['get_statistics']()
            except Exception as exc:  # pragma: no cover - defensive
                runtime_snapshot['inventory_error'] = str(exc)
        status_payload = {
            'config': {
                'outbox': copy.deepcopy(_outbox_config),
                'poller': copy.deepcopy(_outbox_poller_config),
            },
            'metrics': metrics_snapshot,
            'runtime': runtime_snapshot,
        }
        if inventory is not None:
            status_payload['inventory'] = inventory
        return status_payload

    def _build_outbox_analytics(status_snapshot: Dict[str, Any], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options.copy() if isinstance(options, dict) else {}
        metrics = status_snapshot.get('metrics') or {}
        runtime = status_snapshot.get('runtime') or {}
        inventory = status_snapshot.get('inventory') or {}
        config = status_snapshot.get('config') or {}

        def _opt_int(value: Any) -> Optional[int]:
            if value is None:
                return None
            try:
                return int(value)
            except Exception:
                return None

        def _zero_int(value: Any) -> int:
            result = _opt_int(value)
            return result if result is not None else 0

        total_enqueued = _zero_int(metrics.get('enqueued'))
        total_processed = _zero_int(metrics.get('processed'))
        total_acknowledged = _zero_int(metrics.get('acknowledged'))
        total_failures = _zero_int(metrics.get('failures'))
        total_dlq = _zero_int(metrics.get('dlq'))

        attempts = total_processed + total_failures
        success_rate = (total_processed / attempts) if attempts else None
        failure_rate = (total_failures / attempts) if attempts else None
        ack_rate = (total_acknowledged / attempts) if attempts else None

        latency_summary = copy.deepcopy(metrics.get('latency_summary') or _empty_latency_summary())
        latency_samples = list(metrics.get('latency_samples_ms') or [])
        avg_latency_ms = latency_summary.get('avg_ms') or latency_summary.get('average')
        throughput_per_second = None
        if isinstance(avg_latency_ms, (int, float)) and avg_latency_ms > 0:
            throughput_per_second = 1000.0 / float(avg_latency_ms)

        action_counts = metrics.get('action_counts') or {}
        action_distribution = _sorted_counter(action_counts)
        top_action = action_distribution[0]['label'] if action_distribution else None

        failure_reasons = metrics.get('failure_reasons') or {}
        failure_contexts = metrics.get('failure_contexts') or {}
        dlq_reasons = metrics.get('dlq_reasons') or {}

        backlog_pending = _opt_int(inventory.get('pending'))
        backlog_inflight = _opt_int(inventory.get('inflight'))
        backlog_total = None
        if backlog_pending is not None or backlog_inflight is not None:
            backlog_total = (backlog_pending or 0) + (backlog_inflight or 0)

        latency_window = _zero_int(metrics.get('latency_window') or OUTBOX_LATENCY_WINDOW)
        include_samples = bool(options.get('include_latency_samples', False))

        backlog_threshold = options.get('backlog_threshold')
        if backlog_threshold is None:
            backlog_threshold = max(latency_window, 10)
        critical_backlog_threshold = options.get('critical_backlog_threshold')
        if critical_backlog_threshold is None:
            critical_backlog_threshold = backlog_threshold * 2

        warning_failure_rate = options.get('warning_failure_rate', 0.05)
        critical_failure_rate = options.get('critical_failure_rate', 0.2)

        health_status = 'healthy'
        health_reasons: List[str] = []
        if not runtime.get('available', True):
            health_status = 'offline'
            health_reasons.append('outbox_unavailable')
        else:
            if failure_rate is not None:
                if failure_rate > critical_failure_rate:
                    health_status = 'critical'
                    health_reasons.append('failure_rate_high')
                elif failure_rate > warning_failure_rate and health_status != 'critical':
                    health_status = 'degraded'
                    health_reasons.append('failure_rate_elevated')

            if backlog_total is not None:
                if backlog_total > critical_backlog_threshold:
                    health_status = 'critical'
                    health_reasons.append('backlog_exceeds_critical_threshold')
                elif backlog_total > backlog_threshold and health_status != 'critical':
                    health_status = 'degraded'
                    health_reasons.append('backlog_exceeds_threshold')

            if runtime.get('poller_enabled') and not runtime.get('poller_running'):
                if health_status == 'healthy':
                    health_status = 'degraded'
                health_reasons.append('poller_not_running')

        health_payload = {
            'status': health_status,
            'reasons': health_reasons,
            'metrics': {
                'failure_rate': failure_rate,
                'backlog_total': backlog_total,
                'poller_running': runtime.get('poller_running'),
            },
            'thresholds': {
                'warning_failure_rate': warning_failure_rate,
                'critical_failure_rate': critical_failure_rate,
                'backlog_threshold': backlog_threshold,
                'critical_backlog_threshold': critical_backlog_threshold,
            },
        }

        latency_payload: Dict[str, Any] = {
            'summary': latency_summary,
            'last_latency_ms': metrics.get('last_latency_ms'),
            'window': latency_window,
        }
        if include_samples:
            latency_payload['samples_ms'] = latency_samples

        analytics_payload = {
            'summary': {
                'enqueued': total_enqueued,
                'processed': total_processed,
                'acknowledged': total_acknowledged,
                'failures': total_failures,
                'dlq': total_dlq,
            },
            'rates': {
                'success_rate': success_rate,
                'failure_rate': failure_rate,
                'ack_rate': ack_rate,
                'throughput_per_second': throughput_per_second,
            },
            'latency': latency_payload,
            'actions': {
                'top_action': top_action,
                'distribution': action_distribution,
                'unique_actions': len(action_distribution),
            },
            'failures': {
                'total': total_failures,
                'last_error': metrics.get('last_error'),
                'last_failure_context': metrics.get('last_failure_context'),
                'last_failed_id': metrics.get('last_failed_id'),
                'reasons': _sorted_counter(failure_reasons),
                'contexts': _sorted_counter(failure_contexts),
            },
            'dlq': {
                'total': total_dlq,
                'reasons': _sorted_counter(dlq_reasons),
            },
            'backlog': {
                'pending': backlog_pending,
                'inflight': backlog_inflight,
                'total': backlog_total,
                'visibility_timeout': inventory.get('visibility_timeout'),
            },
            'recent': {
                'last_action': metrics.get('last_action'),
                'last_entry_id': metrics.get('last_entry_id'),
                'last_processed_id': metrics.get('last_processed_id'),
                'last_entry_metadata': copy.deepcopy(metrics.get('last_entry_metadata')),  # metadata may be nested
                'last_entry_created_at': metrics.get('last_entry_created_at'),
                'last_latency_ms': metrics.get('last_latency_ms'),
            },
            'runtime': copy.deepcopy(runtime),
            'config': copy.deepcopy(config),
            'health': health_payload,
        }

        return analytics_payload

    def get_outbox_analytics(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        status_snapshot = _get_outbox_status()
        analytics = _build_outbox_analytics(status_snapshot, options)
        analytics['status_snapshot'] = status_snapshot
        return analytics

    def _prepare_l2_ingest_entry(entry: Dict[str, Any], defaults: Optional[Dict[str, Any]] = None) -> Tuple[Optional[Dict[str, Any]], Optional[Dict[str, Any]]]:
        if not isinstance(entry, dict):
            return None, {'reason': 'entry_not_mapping'}

        defaults = defaults or {}
        oid = entry.get('oid') or entry.get('concept_id')
        if not oid:
            return None, {'reason': 'missing_oid'}

        vector_source = entry.get('vector')
        if vector_source is None and 'geometric_embedding' in entry:
            vector_source = entry.get('geometric_embedding')

        vector_np = _normalize_vector(vector_source)
        if vector_np is None or vector_np.size == 0:
            return None, {'reason': 'missing_vector', 'oid': oid}

        metadata_input = entry.get('metadata')
        metadata = _normalize_metadata(metadata_input)

        default_metadata = defaults.get('metadata') if isinstance(defaults.get('metadata'), dict) else {}
        if default_metadata:
            merged_metadata = copy.deepcopy(default_metadata)
            merged_metadata.update(metadata)
            metadata = merged_metadata

        ingest_source = entry.get('source') or defaults.get('source')
        if ingest_source and 'ingest_source' not in metadata:
            metadata['ingest_source'] = ingest_source

        normalized_entry = {
            'oid': oid,
            'vector': vector_np,
            'metadata': metadata
        }

        return normalized_entry, None

    def _build_cache_metadata(concept_payload: Dict[str, Any], concept_oid: str) -> Dict[str, Any]:
        metadata_field = concept_payload.get('metadata', {})
        metadata = copy.deepcopy(metadata_field) if isinstance(metadata_field, dict) else {}
        metadata['oid'] = concept_oid
        if 'tags' in concept_payload and 'tags' not in metadata:
            metadata['tags'] = concept_payload['tags']
        return metadata

    def _propagate_vector(concept_oid: str, vector: Optional[np.ndarray], metadata: Optional[Dict[str, Any]]):
        if vector is None:
            return

        payload_metadata = copy.deepcopy(metadata) if metadata else {'oid': concept_oid}

        try:
            if _cache_coordinator and _cache_coordinator.get('is_running', lambda: False)():
                _cache_coordinator['put'](concept_oid, vector, payload_metadata)
        except Exception as exc:
            logger.warning("Coordinator propagation failed for %s: %s", concept_oid, exc)

        if _l1_manager:
            try:
                _l1_manager['put'](concept_oid, vector, payload_metadata)
            except Exception as exc:
                logger.warning("L1 propagation failed for %s: %s", concept_oid, exc)

        if _l2_manager:
            try:
                _l2_manager['put'](concept_oid, vector, payload_metadata)
            except Exception as exc:
                logger.warning("L2 propagation failed for %s: %s", concept_oid, exc)

    def _promotion_daemon_running() -> bool:
        return _promotion_thread is not None and _promotion_thread.is_alive()

    def _stop_promotion_daemon():
        nonlocal _promotion_thread, _promotion_stop_event, _promotion_wake_event
        thread = _promotion_thread
        if thread is None:
            return

        if _promotion_stop_event is not None:
            _promotion_stop_event.set()
        if _promotion_wake_event is not None:
            _promotion_wake_event.set()

        thread.join(timeout=3.0)
        if thread.is_alive():
            logger.warning("Promotion daemon thread did not stop within timeout")

        _promotion_thread = None
        _promotion_stop_event = None
        _promotion_wake_event = None
        with _promotion_lock:
            _promotion_runtime['active'] = False

    def _perform_promotion_cycle(context: str = 'automatic', limit_override: Optional[int] = None) -> Dict[str, Any]:
        nonlocal _promotion_runtime

        if not _initialized:
            return {
                'success': False,
                'error': 'federated_memory_not_initialized',
                'attempted': 0,
                'promoted': 0,
                'failures': [],
                'promoted_oids': [],
                'context': context,
            }

        if _l1_manager is None or _l2_manager is None:
            error_reason = 'l1_manager_unavailable' if _l1_manager is None else 'l2_manager_unavailable'
            return {
                'success': False,
                'error': error_reason,
                'attempted': 0,
                'promoted': 0,
                'failures': [],
                'promoted_oids': [],
                'context': context,
            }

        try:
            queue_snapshot = _l1_manager['peek_promotions']()
        except Exception as exc:
            with _promotion_lock:
                _promotion_runtime['last_error'] = f"peek_failed: {exc}"
            logger.warning("Promotion daemon failed to inspect L1 queue: %s", exc)
            return {
                'success': False,
                'error': f'promotion_queue_inspection_failed: {exc}',
                'attempted': 0,
                'promoted': 0,
                'failures': [{'reason': 'peek_failed', 'details': str(exc)}],
                'promoted_oids': [],
                'context': context,
            }

        if not queue_snapshot and context == 'automatic':
            skipped_result = {
                'success': True,
                'attempted': 0,
                'promoted': 0,
                'failures': [],
                'promoted_oids': [],
                'context': context,
                'skipped': True,
            }
            with _promotion_lock:
                _promotion_runtime['last_result'] = copy.deepcopy(skipped_result)
                _promotion_runtime['last_error'] = None
            return skipped_result

        options: Dict[str, Any] = {
            'include_vectors': bool(_promotion_config.get('include_vectors', False)),
            'notify_coordinator': bool(_promotion_config.get('notify_coordinator', True)),
        }

        limit_value = limit_override if limit_override is not None else _promotion_config.get('batch_limit')
        if limit_value is not None:
            try:
                options['limit'] = max(0, int(limit_value))
            except Exception:
                pass

        drain_limit = _promotion_config.get('drain_limit')
        if drain_limit is not None and 'limit' not in options:
            try:
                options['limit'] = max(0, int(drain_limit))
            except Exception:
                pass

        start_time = time.time()
        result = promote_l1_candidates(None, options, context=context)

        with _promotion_lock:
            _promotion_runtime['last_result'] = copy.deepcopy(result)
            _promotion_runtime['last_run_started'] = start_time
            _promotion_runtime['last_run_completed'] = time.time()
            if result.get('success', False):
                _promotion_runtime['last_error'] = None
            else:
                _promotion_runtime['last_error'] = result.get('error') or result.get('failures')
            attempted = result.get('attempted', 0)
            should_increment = attempted > 0 or context != 'automatic'
            if should_increment:
                _promotion_runtime['cycles'] += 1

        return result

    def _start_promotion_daemon():
        nonlocal _promotion_thread, _promotion_stop_event, _promotion_wake_event

        if not _promotion_config.get('enabled', False):
            return

        if _l1_manager is None or _l2_manager is None:
            logger.info("Skipping promotion daemon startup (L1/L2 unavailable)")
            return

        if _promotion_daemon_running():
            return

        _promotion_stop_event = threading.Event()
        _promotion_wake_event = threading.Event()

        def _promotion_loop():
            nonlocal _promotion_stop_event, _promotion_wake_event
            logger.info(
                "Starting TELOS automatic promotion daemon (interval=%.3fs)",
                float(_promotion_config.get('interval_seconds', 1.0) or 1.0),
            )

            try:
                while _promotion_stop_event is not None and not _promotion_stop_event.is_set():
                    interval = float(_promotion_config.get('interval_seconds', 1.0) or 0.5)
                    if interval <= 0:
                        interval = 0.5

                    wake = _promotion_wake_event
                    if wake is not None:
                        wake.wait(timeout=interval)
                        wake.clear()

                    if _promotion_stop_event.is_set():
                        break

                    with _promotion_lock:
                        _promotion_runtime['active'] = True

                    result = _perform_promotion_cycle(context='automatic')

                    with _promotion_lock:
                        _promotion_runtime['active'] = False

                    if result.get('attempted', 0) == 0:
                        idle_sleep = float(_promotion_config.get('idle_sleep_seconds', 0.25) or 0.0)
                        if idle_sleep > 0:
                            time.sleep(min(idle_sleep, 0.5))

            finally:
                with _promotion_lock:
                    _promotion_runtime['active'] = False
                logger.info("TELOS automatic promotion daemon stopped")

        _promotion_thread = threading.Thread(
            target=_promotion_loop,
            name="TelosPromotionDaemon",
            daemon=True,
        )
        _promotion_thread.start()
        if _promotion_wake_event is not None:
            _promotion_wake_event.set()

    def trigger_promotion_cycle(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        limit_override: Optional[int] = None
        if isinstance(options, dict) and options.get('limit') is not None:
            try:
                limit_override = max(0, int(options['limit']))
            except Exception:
                limit_override = None

        result = _perform_promotion_cycle(context='manual_trigger', limit_override=limit_override)
        if _promotion_wake_event is not None:
            _promotion_wake_event.set()
        return result

    def get_promotion_daemon_status() -> Dict[str, Any]:
        with _promotion_lock:
            runtime_snapshot = copy.deepcopy(_promotion_runtime)
            metrics_snapshot = copy.deepcopy(_promotion_metrics)

        return {
            'enabled': bool(_promotion_config.get('enabled', False)),
            'thread_running': _promotion_daemon_running(),
            'config': copy.deepcopy(_promotion_config),
            'runtime': runtime_snapshot,
            'metrics': metrics_snapshot,
        }

    def promote_l1_candidates(
        candidates: Optional[List[Dict[str, Any]]] = None,
        options: Optional[Dict[str, Any]] = None,
        context: str = 'manual',
    ) -> Dict[str, Any]:
        """Ingest L1 promotion candidates into L2 (and coordinator) storage."""

        if not _initialized:
            return {
                'success': False,
                'error': 'federated_memory_not_initialized',
            }

        if _l2_manager is None:
            return {
                'success': False,
                'error': 'l2_manager_unavailable',
            }

        include_vectors = True
        limit = None
        notify_coordinator = True

        if isinstance(options, dict):
            include_vectors = bool(options.get('include_vectors', True))
            notify_coordinator = bool(options.get('notify_coordinator', True))
            raw_limit = options.get('limit')
            if raw_limit is not None:
                try:
                    limit = max(0, int(raw_limit))
                except Exception:
                    limit = None

        drained_candidates: List[Dict[str, Any]]
        if candidates is None:
            if _l1_manager is None:
                return {
                    'success': False,
                    'error': 'l1_manager_unavailable',
                }
            drained_candidates = _l1_manager['drain_promotions'](limit=limit, include_vectors=include_vectors)
        else:
            drained_candidates = list(candidates)

        attempted = len(drained_candidates)
        promoted: List[Dict[str, Any]] = []
        failures: List[Dict[str, Any]] = []
        failure_reason_counts: Dict[str, int] = {}
        requeued_after_failure = 0

        context_label = 'automatic' if context == 'automatic' else 'manual'
        context_timestamp = time.time()

        requeue_callable = None
        if _l1_manager is not None:
            candidate_requeue_slot = _l1_manager.get('requeue_promotion')
            if callable(candidate_requeue_slot):
                requeue_callable = candidate_requeue_slot

        requeue_enabled = _should_requeue_failures()

        for item in drained_candidates:
            candidate = dict(item) if isinstance(item, dict) else {}
            oid = candidate.get('oid')

            def _register_failure(reason: str, *, details: Optional[Any] = None, allow_requeue: bool = True):
                nonlocal requeued_after_failure
                entry: Dict[str, Any] = {
                    'oid': oid,
                    'reason': reason,
                    'context': context_label,
                    'timestamp': context_timestamp,
                }
                if details is not None:
                    entry['details'] = str(details)

                requeued_flag = False
                if (
                    allow_requeue
                    and requeue_enabled
                    and requeue_callable is not None
                    and oid
                ):
                    try:
                        requeued_flag = bool(requeue_callable(dict(candidate)))
                    except Exception as requeue_exc:
                        entry['requeue_error'] = str(requeue_exc)
                    else:
                        if requeued_flag:
                            requeued_after_failure += 1
                            entry['requeued'] = True

                failures.append(entry)
                failure_reason_counts[reason] = failure_reason_counts.get(reason, 0) + 1

            if not oid:
                _register_failure('missing_oid', allow_requeue=False)
                continue

            metadata = copy.deepcopy(candidate.get('metadata') or {})
            stats = candidate.get('stats') if isinstance(candidate, dict) else None
            if isinstance(stats, dict):
                priority = stats.get('priority')
                if priority is not None:
                    metadata.setdefault('l1_priority', priority)
                access_count = stats.get('access_count')
                if access_count is not None:
                    metadata.setdefault('l1_access_count', access_count)

            vector_payload = candidate.get('vector') if isinstance(candidate, dict) else None
            vector_np = _normalize_vector(vector_payload)

            if vector_np is None and _l1_manager is not None:
                try:
                    entry = _l1_manager['get'](oid)
                except Exception:
                    entry = None
                if entry and isinstance(entry, dict):
                    vector_np = _normalize_vector(entry.get('vector'))
                    entry_metadata = entry.get('metadata')
                    if isinstance(entry_metadata, dict):
                        for key, value in entry_metadata.items():
                            metadata.setdefault(key, value)

            if vector_np is None:
                _register_failure('missing_vector', allow_requeue=False)
                continue

            candidate['metadata'] = metadata
            candidate['vector'] = vector_np

            try:
                l2_success = _l2_manager['put'](oid, vector_np, metadata)
            except Exception as exc:
                _register_failure('l2_put_failed', details=exc)
                continue

            if l2_success is False:
                _register_failure('l2_put_rejected')
                continue

            if notify_coordinator and _cache_coordinator is not None:
                try:
                    coordinator_success = _cache_coordinator['put'](oid, vector_np, metadata)
                except Exception as exc:
                    _register_failure('coordinator_put_failed', details=exc)
                    continue

                if coordinator_success is False:
                    _register_failure('coordinator_put_rejected')
                    continue

            promoted.append({'oid': oid, 'metadata': metadata})

        promoted_oids = [entry['oid'] for entry in promoted]

        with _promotion_lock:
            _promotion_metrics['total_attempts'] += attempted
            _promotion_metrics['total_promoted'] += len(promoted)
            _promotion_metrics['total_failures'] += len(failures)
            _promotion_metrics['requeued_after_failure'] += requeued_after_failure
            _promotion_metrics['last_batch'] = {
                'count': attempted,
                'promoted': len(promoted),
                'failures': len(failures),
                'promoted_oids': promoted_oids,
                'failure_reasons': dict(failure_reason_counts),
                'requeued': requeued_after_failure,
            }

            reason_table = _promotion_metrics.setdefault('failure_reasons', {})
            for reason, count in failure_reason_counts.items():
                reason_table[reason] = reason_table.get(reason, 0) + count

            max_samples = _promotion_failure_sample_limit()
            if failures and max_samples != 0:
                for failure_entry in failures:
                    sample = {
                        'oid': failure_entry.get('oid'),
                        'reason': failure_entry.get('reason'),
                        'context': failure_entry.get('context'),
                        'timestamp': failure_entry.get('timestamp'),
                    }
                    if failure_entry.get('details') is not None:
                        sample['details'] = failure_entry['details']
                    if failure_entry.get('requeued'):
                        sample['requeued'] = True
                    _promotion_metrics['failure_samples'].append(sample)

                if max_samples > 0 and len(_promotion_metrics['failure_samples']) > max_samples:
                    _promotion_metrics['failure_samples'] = _promotion_metrics['failure_samples'][-max_samples:]

            bucket = _promotion_metrics['automatic'] if context_label == 'automatic' else _promotion_metrics['manual']
            bucket['attempts'] += attempted
            bucket['promoted'] += len(promoted)
            bucket['failures'] += len(failures)
            bucket['requeued'] = bucket.get('requeued', 0) + requeued_after_failure
            bucket['last_result'] = {
                'attempted': attempted,
                'promoted': len(promoted),
                'failures': len(failures),
                'failure_reasons': dict(failure_reason_counts),
                'promoted_oids': promoted_oids,
                'context': context_label,
                'requeued': requeued_after_failure,
            }
            bucket['last_timestamp'] = context_timestamp
            if context_label == 'automatic' and attempted > 0:
                bucket['cycles'] += 1

        return {
            'success': len(failures) == 0,
            'attempted': attempted,
            'promoted': len(promoted),
            'failures': failures,
            'failure_reasons': dict(failure_reason_counts),
            'requeued': requeued_after_failure,
            'promoted_oids': promoted_oids,
            'context': context_label,
        }

    def initialize(config: Optional[Dict[str, Any]] = None):
        """Initialize the complete federated memory architecture."""
        nonlocal _l3_manager, _l1_manager, _l2_manager, _cache_coordinator, _bridge_manager, _initialized, _active_config, _promotion_config, _promotion_thread, _promotion_stop_event, _promotion_wake_event, _promotion_runtime, _promotion_metrics, _transactional_outbox, _transactional_outbox_poller, _outbox_config, _outbox_poller_config

        if _initialized:
            logger.info("Federated memory fabric already initialized")
            return True

        merged_config = copy.deepcopy(default_config)

        if config:
            config_clone = copy.deepcopy(config)
            legacy_mapping = {
                'l3_database_path': ('l3', 'storage_path'),
                'l3_zeo_server': ('l3', 'zeo_address'),
                'l1_cache_size': ('l1', 'max_size'),
                'l1_dimensions': ('l1', 'vector_dim'),
                'l2_storage_path': ('l2', 'storage_path'),
                'l2_max_vectors': ('l2', 'max_size')
            }
            for legacy_key, (section, key) in legacy_mapping.items():
                if legacy_key in config_clone:
                    merged_config[section][key] = config_clone.pop(legacy_key)

            if 'coordinator_workers' in config_clone:
                merged_config['coordinator']['workers'] = int(config_clone.pop('coordinator_workers'))

            _deep_merge(merged_config, config_clone)

        try:
            logger.info("Initializing TELOS Federated Memory Architecture...")

            _stop_promotion_daemon()
            _stop_outbox_poller()

            with _promotion_lock:
                _promotion_config = copy.deepcopy(default_config['promotions'])
                promotion_overrides = merged_config.get('promotions') or {}
                if isinstance(promotion_overrides, dict):
                    _deep_merge(_promotion_config, promotion_overrides)

                _promotion_metrics['total_attempts'] = 0
                _promotion_metrics['total_promoted'] = 0
                _promotion_metrics['total_failures'] = 0
                _promotion_metrics['requeued_after_failure'] = 0
                _promotion_metrics['last_batch'] = {
                    'count': 0,
                    'promoted': 0,
                    'failures': 0,
                    'promoted_oids': [],
                    'failure_reasons': {},
                    'requeued': 0,
                }
                _promotion_metrics['failure_reasons'] = {}
                _promotion_metrics['failure_samples'] = []
                _promotion_metrics['automatic'] = {
                    'cycles': 0,
                    'attempts': 0,
                    'promoted': 0,
                    'failures': 0,
                    'last_result': None,
                    'last_timestamp': None,
                    'requeued': 0,
                }
                _promotion_metrics['manual'] = {
                    'attempts': 0,
                    'promoted': 0,
                    'failures': 0,
                    'last_result': None,
                    'last_timestamp': None,
                    'requeued': 0,
                }

                _promotion_runtime['cycles'] = 0
                _promotion_runtime['last_result'] = None
                _promotion_runtime['last_error'] = None
                _promotion_runtime['last_run_started'] = None
                _promotion_runtime['last_run_completed'] = None
                _promotion_runtime['active'] = False

            with _outbox_lock:
                _outbox_config = copy.deepcopy(default_config['outbox'])
                _outbox_poller_config = copy.deepcopy(default_config['outbox_poller'])
            _reset_outbox_state()

            outbox_overrides = merged_config.get('outbox') or {}
            if isinstance(outbox_overrides, dict):
                _deep_merge(_outbox_config, outbox_overrides)
            poller_overrides = merged_config.get('outbox_poller') or {}
            if isinstance(poller_overrides, dict):
                _deep_merge(_outbox_poller_config, poller_overrides)

            _transactional_outbox = None
            _transactional_outbox_poller = None

            if _outbox_config.get('enabled', True):
                try:
                    _transactional_outbox = create_transactional_outbox(_outbox_config)
                    with _outbox_lock:
                        _outbox_runtime['enabled'] = True
                except Exception as exc:
                    logger.warning("Transactional outbox unavailable: %s", exc)
                    with _outbox_lock:
                        _outbox_runtime['enabled'] = False
                        _outbox_metrics['last_error'] = str(exc)
                    _transactional_outbox = None
            else:
                with _outbox_lock:
                    _outbox_runtime['enabled'] = False

            l3_conf = merged_config['l3']
            l1_conf = merged_config['l1']
            l2_conf = merged_config['l2']
            coordinator_flags = merged_config['coordinator']
            enable_l1 = bool(coordinator_flags.get('enable_l1', True))
            enable_l2 = bool(coordinator_flags.get('enable_l2', True))
            enable_l3 = bool(coordinator_flags.get('enable_l3', True))

            l3_storage_path = str(Path(l3_conf['storage_path']).expanduser())
            Path(l3_storage_path).parent.mkdir(parents=True, exist_ok=True)

            zeo_address = l3_conf.get('zeo_address')
            if isinstance(zeo_address, str):
                host, _, port = zeo_address.partition(':')
                zeo_address = (host, int(port) if port else None) if host else None
            elif isinstance(zeo_address, list):
                zeo_address = tuple(zeo_address)

            if enable_l3:
                _l3_manager = create_zodb_manager(storage_path=l3_storage_path, zeo_address=zeo_address)
                logger.info("L3 ZODB manager ready at %s", l3_storage_path)
            else:
                logger.warning("L3 manager disabled via configuration")

            if enable_l1:
                l1_kwargs = {
                    'max_size': int(l1_conf['max_size']),
                    'vector_dim': int(l1_conf['vector_dim']),
                    'eviction_threshold': float(l1_conf.get('eviction_threshold', 0.8)),
                    'index_type': l1_conf.get('index_type', 'Flat'),
                }
                if 'promotion_threshold' in l1_conf:
                    l1_kwargs['promotion_threshold'] = int(l1_conf['promotion_threshold'])
                if 'promotion_requeue_step' in l1_conf:
                    l1_kwargs['promotion_requeue_step'] = int(l1_conf['promotion_requeue_step'])
                if 'eviction_batch_percent' in l1_conf:
                    l1_kwargs['eviction_batch_percent'] = float(l1_conf['eviction_batch_percent'])
                if 'max_promotion_queue' in l1_conf:
                    l1_kwargs['max_promotion_queue'] = int(l1_conf['max_promotion_queue'])

                _l1_manager = create_l1_cache_manager(**l1_kwargs)
                logger.info("L1 cache manager configured (size=%s, dim=%s)", l1_conf['max_size'], l1_conf['vector_dim'])
            else:
                logger.info("L1 cache manager disabled for this configuration")

            _l2_manager = None
            l2_storage_path = str(Path(l2_conf['storage_path']).expanduser())
            if enable_l2:
                Path(l2_storage_path).parent.mkdir(parents=True, exist_ok=True)
                _l2_manager = create_l2_cache_manager(
                    storage_path=l2_storage_path,
                    max_size=int(l2_conf['max_size']),
                    vector_dim=int(l2_conf['vector_dim'])
                )
                logger.info("L2 cache manager configured with storage %s", l2_storage_path)
            else:
                logger.info("L2 cache manager disabled for this configuration")

            coordinator_config = copy.deepcopy(merged_config['coordinator'])
            coord_l1 = coordinator_config.setdefault('l1_config', {})
            coord_l1.setdefault('max_size', int(l1_conf['max_size']))
            coord_l1.setdefault('vector_dim', int(l1_conf['vector_dim']))
            coord_l1.setdefault('index_type', l1_conf.get('index_type', 'Flat'))
            if 'promotion_threshold' in l1_conf and 'promotion_threshold' not in coord_l1:
                coord_l1['promotion_threshold'] = int(l1_conf['promotion_threshold'])
            if 'promotion_requeue_step' in l1_conf and 'promotion_requeue_step' not in coord_l1:
                coord_l1['promotion_requeue_step'] = int(l1_conf['promotion_requeue_step'])

            coord_l2 = coordinator_config.setdefault('l2_config', {})
            coord_l2.setdefault('storage_path', l2_storage_path)
            coord_l2.setdefault('max_size', int(l2_conf['max_size']))
            coord_l2.setdefault('vector_dim', int(l2_conf['vector_dim']))

            coord_l3 = coordinator_config.setdefault('l3_config', {})
            coord_l3.setdefault('storage_path', l3_storage_path)
            coord_l3.setdefault('zeo_address', zeo_address)
            if 'read_only' not in coord_l3:
                coord_l3['read_only'] = bool(enable_l3)

            coordinator_config.setdefault('workers', merged_config['coordinator'].get('workers', 2))
            _cache_coordinator = create_cache_coordinator(coordinator_config)
            if not _cache_coordinator['start']():
                raise RuntimeError("Cache coordinator failed to start")
            logger.info("Cache coordinator started")

            _bridge_manager = create_prototypal_bridge_manager()
            bridge_config = merged_config.get('bridge', {})
            bridge_config.setdefault('workers', merged_config['bridge'].get('workers', 4))
            if not _bridge_manager['initialize'](bridge_config):
                raise RuntimeError("Prototypal bridge failed to initialize")

            merged_config['outbox'] = copy.deepcopy(_outbox_config)
            merged_config['outbox_poller'] = copy.deepcopy(_outbox_poller_config)
            _active_config = merged_config
            _initialized = True
            logger.info("✅ TELOS Federated Memory Architecture initialized successfully")

            if _transactional_outbox:
                _start_outbox_poller()

            _start_promotion_daemon()
            return True

        except Exception as exc:
            logger.exception("Failed to initialize federated memory fabric: %s", exc)
            shutdown()
            return False

    def shutdown():
        """Shutdown all components of the federated memory architecture."""
        nonlocal _l3_manager, _l1_manager, _l2_manager, _cache_coordinator, _bridge_manager, _initialized, _active_config, _transactional_outbox, _transactional_outbox_poller

        if not any([_l3_manager, _l1_manager, _l2_manager, _cache_coordinator, _bridge_manager]) and not _initialized:
            return True

        logger.info("Shutting down TELOS Federated Memory Architecture...")

        _stop_promotion_daemon()
        _stop_outbox_poller(timeout=2.0)

        if _transactional_outbox:
            try:
                _transactional_outbox['shutdown']()
            except Exception as exc:
                logger.error("Error shutting down transactional outbox: %s", exc)
            _transactional_outbox = None

        if _cache_coordinator:
            try:
                _cache_coordinator['stop']()
            except Exception as exc:
                logger.error("Error stopping cache coordinator: %s", exc)
            _cache_coordinator = None

        if _bridge_manager:
            try:
                _bridge_manager['shutdown']()
            except Exception as exc:
                logger.error("Error shutting down bridge manager: %s", exc)
            _bridge_manager = None

        if _l2_manager:
            try:
                _l2_manager['close']()
            except Exception as exc:
                logger.error("Error closing L2 manager: %s", exc)
            _l2_manager = None

        if _l1_manager:
            try:
                _l1_manager['clear']()
            except Exception as exc:
                logger.error("Error clearing L1 manager: %s", exc)
            _l1_manager = None

        if _l3_manager:
            try:
                _l3_manager['close']()
            except Exception as exc:
                logger.error("Error closing L3 manager: %s", exc)
            _l3_manager = None

        _initialized = False
        _active_config = copy.deepcopy(default_config)
        _reset_outbox_state()

        logger.info("Federated memory fabric shutdown complete")
        return True

    def create_concept(concept_data: Dict[str, Any]) -> Optional[str]:
        """Create a new concept in the federated memory fabric."""
        if not _initialized:
            logger.error("Fabric not initialized - cannot create concept")
            return None

        if not isinstance(concept_data, dict):
            raise TypeError("concept_data must be a dictionary")

        payload = copy.deepcopy(concept_data)
        vector_np = _normalize_vector(payload.get('geometric_embedding'))
        if vector_np is not None:
            payload['geometric_embedding'] = _vector_to_serializable(vector_np)

        try:
            concept_oid = _l3_manager['store_concept'](payload)
            cache_metadata = _build_cache_metadata(payload, concept_oid)
            _propagate_vector(concept_oid, vector_np, cache_metadata)
            _enqueue_outbox_event(
                'concept_created',
                {
                    'oid': concept_oid,
                    'vector': payload.get('geometric_embedding'),
                    'metadata': cache_metadata,
                },
                {'origin': 'create_concept'},
            )
            logger.debug("Created concept %s", concept_oid)
            return concept_oid
        except Exception as exc:
            logger.error("Failed to create concept: %s", exc)
            return None

    def get_concept(object_id: str) -> Optional[Dict[str, Any]]:
        """Retrieve a concept from the federated memory fabric."""
        if not _initialized:
            logger.error("Fabric not initialized - cannot retrieve concept")
            return None

        try:
            return _l3_manager['load_concept'](object_id)
        except Exception as exc:
            logger.error("Failed to get concept %s: %s", object_id, exc)
            return None

    def update_concept(object_id: str, updates: Dict[str, Any]) -> bool:
        """Update a concept in the federated memory fabric."""
        if not _initialized:
            logger.error("Fabric not initialized - cannot update concept")
            return False

        if not isinstance(updates, dict):
            raise TypeError("updates must be a dictionary")

        update_payload = copy.deepcopy(updates)
        vector_np = None
        if 'geometric_embedding' in update_payload:
            vector_np = _normalize_vector(update_payload['geometric_embedding'])
            update_payload['geometric_embedding'] = _vector_to_serializable(vector_np)

        try:
            success = _l3_manager['update_concept'](object_id, update_payload)
            if success and vector_np is not None:
                cache_metadata = _build_cache_metadata(update_payload, object_id)
                _propagate_vector(object_id, vector_np, cache_metadata)
            if success:
                cache_metadata = _build_cache_metadata(update_payload, object_id)
                _enqueue_outbox_event(
                    'concept_updated',
                    {
                        'oid': object_id,
                        'vector': update_payload.get('geometric_embedding'),
                        'metadata': cache_metadata,
                    },
                    {'origin': 'update_concept'},
                )
            return success
        except Exception as exc:
            logger.error("Failed to update concept %s: %s", object_id, exc)
            return False

    def bulk_ingest_l2(entries: List[Dict[str, Any]], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Bulk-ingest vectors directly into L2 storage."""

        if not _initialized:
            return {'success': False, 'error': 'fabric_not_initialized'}

        if _l2_manager is None:
            return {'success': False, 'error': 'l2_unavailable'}

        options = options or {}
        defaults = options.get('defaults') if isinstance(options.get('defaults'), dict) else {}
        rebuild_requested = bool(options.get('rebuild', False))
        force_rebuild = bool(options.get('force_rebuild', False))
        auto_rebuild = options.get('auto_rebuild', True)
        rebuild_min_points = options.get('rebuild_min_points')

        prepared: List[Dict[str, Any]] = []
        prep_failures: List[Dict[str, Any]] = []

        for entry in entries or []:
            normalized, failure = _prepare_l2_ingest_entry(entry, defaults)
            if failure is not None:
                failure_payload = copy.deepcopy(failure)
                failure_payload['entry'] = {
                    'oid': entry.get('oid') if isinstance(entry, dict) else None
                }
                prep_failures.append(failure_payload)
                continue
            prepared.append(normalized)

        if not prepared:
            return {
                'success': False,
                'error': 'no_valid_entries',
                'failures': prep_failures,
                'requested': len(entries or [])
            }

        l2_response = _l2_manager['bulk_put'](
            prepared,
            rebuild=rebuild_requested,
            force_rebuild=force_rebuild,
            auto_rebuild=auto_rebuild,
            rebuild_min_points=rebuild_min_points
        )

        combined_failures = prep_failures + (l2_response.get('failures') or [])
        success = bool(l2_response.get('success')) and not prep_failures

        return {
            'success': success,
            'requested': len(entries or []),
            'accepted': len(prepared),
            'ingested': l2_response.get('ingested', 0),
            'failures': combined_failures,
            'l2_response': l2_response,
            'auto_rebuild_triggered': l2_response.get('auto_rebuild_triggered', False)
        }

    def rebuild_l2_diskann(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Trigger a manual rebuild of the L2 DiskANN index."""

        if not _initialized:
            return {'success': False, 'error': 'fabric_not_initialized'}

        if _l2_manager is None:
            return {'success': False, 'error': 'l2_unavailable'}

        options = options or {}
        force = bool(options.get('force', False))
        auto = bool(options.get('auto', False))

        rebuild_result = _l2_manager['rebuild_diskann'](force=force, auto=auto)
        return {
            'success': bool(rebuild_result.get('success')),
            'result': rebuild_result,
            'status': rebuild_result.get('status') or _l2_manager['get_diskann_status']()
        }

    def get_l2_diskann_status() -> Dict[str, Any]:
        if _l2_manager is None:
            return {
                'available': False,
                'error': 'l2_unavailable'
            }
        status = _l2_manager['get_diskann_status']()
        return status

    def search_similar_concepts(query_vector: Union[List[float], np.ndarray], k: int = 10, threshold: float = 0.7) -> List[Dict[str, Any]]:
        """Search for similar concepts using the L1/L2 cache hierarchy."""
        tiered = search_tiered(query_vector, {
            'k': k,
            'threshold': threshold
        })
        if not tiered.get('success'):
            return []
        return tiered.get('combined', [])[:k]

    def search_tiered(query_vector: Union[List[float], np.ndarray], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Perform tiered fan-out search across cache layers with telemetry."""

        if not _initialized:
            return {'success': False, 'error': 'fabric_not_initialized'}

        vector_np = _normalize_vector(query_vector)
        if vector_np is None:
            return {'success': False, 'error': 'query_vector_missing'}

        options = options or {}
        k = int(options.get('k', 10) or 10)
        threshold = float(options.get('threshold', 0.7) or 0.0)
        include_vectors = bool(options.get('include_vectors', False))
        requested_tiers = options.get('tiers') or ['L1', 'L2']

        combined: List[Dict[str, Any]] = []
        tier_details: Dict[str, Any] = {}
        seen: set[str] = set()

        for tier in requested_tiers:
            tier_name = str(tier).upper()
            manager = None
            if tier_name == 'L1':
                manager = _l1_manager
            elif tier_name == 'L2':
                manager = _l2_manager
            elif tier_name == 'L3':
                manager = None

            tier_start = time.perf_counter()
            tier_hits: List[Dict[str, Any]] = []
            tier_error: Optional[str] = None
            tier_added = 0

            if tier_name == 'L3':
                tier_details[tier_name] = {
                    'candidates': 0,
                    'hits': [],
                    'duration_ms': (time.perf_counter() - tier_start) * 1000.0,
                    'skipped': True,
                    'reason': 'l3_search_not_implemented'
                }
                continue

            if manager is None:
                tier_details[tier_name] = {
                    'candidates': 0,
                    'hits': [],
                    'duration_ms': (time.perf_counter() - tier_start) * 1000.0,
                    'skipped': True,
                    'reason': 'tier_unavailable'
                }
                continue

            try:
                tier_hits = manager['search_similar'](vector_np, k, threshold) or []
            except Exception as exc:
                tier_error = str(exc)
                logger.error("%s similarity search failed: %s", tier_name, exc)
                tier_hits = []

            duration_ms = (time.perf_counter() - tier_start) * 1000.0
            tier_results: List[Dict[str, Any]] = []

            for hit in tier_hits:
                if len(combined) >= k:
                    break

                oid = hit.get('oid') if isinstance(hit, dict) else None
                if not oid or oid in seen:
                    continue

                concept = _l3_manager['load_concept'](oid) if _l3_manager else None
                if concept:
                    concept = copy.deepcopy(concept)
                else:
                    concept = {'oid': oid}

                concept['similarity_score'] = hit.get('similarity_score') if isinstance(hit, dict) else None
                concept['cache_level'] = tier_name

                if include_vectors and isinstance(hit, dict) and hit.get('vector') is not None:
                    concept['cached_vector'] = _vector_to_serializable(_normalize_vector(hit.get('vector')))

                tier_results.append(concept)
                combined.append(concept)
                seen.add(oid)
                tier_added += 1

            tier_details[tier_name] = {
                'candidates': len(tier_hits),
                'hits': tier_results,
                'duration_ms': duration_ms,
                'error': tier_error,
                'added': tier_added
            }

            if len(combined) >= k:
                break

        metrics = {
            'returned': len(combined),
            'requested': k,
            'threshold': threshold,
            'tiers_consulted': list(tier_details.keys())
        }

        return {
            'success': True,
            'combined': combined[:k],
            'tiers': tier_details,
            'metrics': metrics
        }

    def invalidate_concept(object_id: str) -> Dict[str, Any]:
        """Invalidate a concept across cache layers without touching L3."""
        if not _initialized:
            logger.error("Fabric not initialized - cannot invalidate concept")
            return {}

        outcomes: Dict[str, Any] = {}

        if _cache_coordinator:
            try:
                event_result = _cache_coordinator['invalidate'](object_id)
                if event_result is not None:
                    outcomes['coordinator'] = event_result
            except Exception as exc:
                logger.warning("Coordinator invalidate failed for %s: %s", object_id, exc)

        for level_name, manager in (('L1', _l1_manager), ('L2', _l2_manager)):
            if manager:
                try:
                    outcomes[level_name] = manager['remove'](object_id)
                except Exception as exc:
                    logger.warning("%s invalidate failed for %s: %s", level_name, object_id, exc)
                    outcomes[level_name] = False

        return outcomes

    def create_prototypal_proxy(io_handle, object_id: Optional[str] = None):
        """Create a prototypal proxy for transparent Io-Python interaction."""
        if not _initialized or not _bridge_manager:
            logger.error("Bridge manager not available - cannot create proxy")
            return None

        return _bridge_manager['create_proxy'](io_handle, object_id)

    def get_transparent_cache_interface():
        """Get a transparent cache interface that Io prototypes can use directly."""
        if not _initialized:
            logger.error("Fabric not initialized - cache interface unavailable")
            return None

        cache_wrappers: Dict[str, Dict[str, Any]] = {}

        if _l1_manager:
            def _l1_put(oid: str, value: Any):
                vector = None
                metadata = {}
                if isinstance(value, dict):
                    vector = _normalize_vector(value.get('vector'))
                    metadata = value.get('metadata') or {}
                else:
                    vector = _normalize_vector(value)
                return _l1_manager['put'](oid, vector, metadata)

            def _l1_search(vector: Any, k: int = 5, threshold: float = 0.0):
                normalized = _normalize_vector(vector)
                if normalized is None:
                    return []
                return _l1_manager['search_similar'](normalized, k, threshold)

            cache_wrappers['L1'] = {
                'put': _l1_put,
                'get': _l1_manager['get'],
                'remove': _l1_manager['remove'],
                'search': _l1_search
            }

        if _l2_manager:
            def _l2_put(oid: str, value: Any):
                vector = None
                metadata = {}
                if isinstance(value, dict):
                    vector = _normalize_vector(value.get('vector'))
                    metadata = value.get('metadata') or {}
                else:
                    vector = _normalize_vector(value)
                return _l2_manager['put'](oid, vector, metadata)

            def _l2_search(vector: Any, k: int = 5, threshold: float = 0.0):
                normalized = _normalize_vector(vector)
                if normalized is None:
                    return []
                return _l2_manager['search_similar'](normalized, k, threshold)

            cache_wrappers['L2'] = {
                'put': _l2_put,
                'get': _l2_manager['get'],
                'remove': _l2_manager['remove'],
                'search': _l2_search
            }

        if _l3_manager:
            def _l3_put(oid: str, value: Any):
                payload = copy.deepcopy(value) if isinstance(value, dict) else {'geometric_embedding': value}
                payload.setdefault('oid', oid)
                vector = _normalize_vector(payload.get('geometric_embedding'))
                if vector is not None:
                    payload['geometric_embedding'] = _vector_to_serializable(vector)
                return _l3_manager['store_concept'](payload)

            def _l3_get(oid: str):
                return _l3_manager['load_concept'](oid)

            def _l3_remove(oid: str):
                return _l3_manager['delete_concept'](oid)

            cache_wrappers['L3'] = {
                'put': _l3_put,
                'get': _l3_get,
                'remove': _l3_remove,
                'search': lambda *args, **kwargs: []
            }

        return create_transparent_cache_proxy(cache_wrappers)

    def get_status():
        """Get comprehensive status of all federated memory components."""
        status: Dict[str, Any] = {
            'initialized': _initialized,
            'configuration': copy.deepcopy(_active_config) if _initialized else None,
            'components': {}
        }

        if _l3_manager:
            try:
                status['components']['L3'] = _l3_manager['get_statistics']()
            except Exception as exc:
                status['components']['L3'] = {'error': str(exc)}

        if _l1_manager:
            try:
                status['components']['L1'] = _l1_manager['get_statistics']()
            except Exception as exc:
                status['components']['L1'] = {'error': str(exc)}

        if _l2_manager:
            try:
                l2_stats = _l2_manager['get_statistics']()
                l2_stats['diskann_status'] = _l2_manager['get_diskann_status']()
                status['components']['L2'] = l2_stats
            except Exception as exc:
                status['components']['L2'] = {'error': str(exc)}

        if _l2_manager:
            try:
                status['l2_diskann'] = _l2_manager['get_diskann_status']()
            except Exception as exc:
                status['l2_diskann'] = {'error': str(exc)}

        status['benchmark'] = _snapshot_benchmark_state()

        if _cache_coordinator:
            try:
                status['components']['coordinator'] = {
                    'running': _cache_coordinator.get('is_running', lambda: False)(),
                    'statistics': _cache_coordinator['get_statistics']()
                }
            except Exception as exc:
                status['components']['coordinator'] = {'error': str(exc)}

        if _bridge_manager:
            try:
                status['components']['bridge'] = _bridge_manager['get_status']()
            except Exception as exc:
                status['components']['bridge'] = {'error': str(exc)}

        status['outbox'] = _get_outbox_status()
        status['promotion_daemon'] = get_promotion_daemon_status()

        return status

    def get_cache_statistics() -> Dict[str, Any]:
        """Summarize cache statistics for each active tier."""
        stats: Dict[str, Any] = {}

        if _l1_manager:
            try:
                stats['L1'] = _l1_manager['get_statistics']()
            except Exception as exc:
                stats['L1'] = {'error': str(exc)}

        if _l2_manager:
            try:
                stats['L2'] = _l2_manager['get_statistics']()
            except Exception as exc:
                stats['L2'] = {'error': str(exc)}

        if _cache_coordinator:
            try:
                stats['coordinator'] = _cache_coordinator['get_statistics']()
            except Exception as exc:
                stats['coordinator'] = {'error': str(exc)}

        stats['promotion_metrics'] = copy.deepcopy(_promotion_metrics)
        stats['promotion_daemon'] = get_promotion_daemon_status()
        stats['outbox'] = _get_outbox_status()

        return stats

    def get_l2_telemetry() -> Dict[str, Any]:
        """Provide focused L2 telemetry including DiskANN health and eviction history."""
        if not _l2_manager:
            return {'error': 'L2 cache manager unavailable'}

        try:
            stats = _l2_manager['get_statistics']()
            disk_index_metrics = stats.get('disk_index', {}).get('metrics', {})
            return {
                'search_metrics': stats.get('search_metrics', {}),
                'eviction_history': stats.get('eviction_history', []),
                'diskann_metrics': disk_index_metrics.get('diskann', {}),
                'search_engine_metrics': disk_index_metrics.get('search', {})
            }
        except Exception as exc:
            return {'error': str(exc)}

    def simulate_coordinator_failure(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Force the cache coordinator to terminate for failure-path testing."""
        if _cache_coordinator is None:
            return {'success': False, 'error': 'coordinator_unavailable'}

        simulate = _cache_coordinator.get('simulate_failure')
        if not callable(simulate):
            return {'success': False, 'error': 'simulate_failure_unavailable'}

        try:
            simulated = bool(simulate())
        except Exception as exc:
            return {'success': False, 'error': str(exc)}

        stopped = False
        if simulated and isinstance(options, dict) and options.get('stop_after'):
            stop_callable = _cache_coordinator.get('stop')
            if callable(stop_callable):
                try:
                    stop_callable()
                    stopped = True
                except Exception as exc:  # pragma: no cover - defensive
                    return {
                        'success': False,
                        'error': str(exc),
                        'simulated': simulated,
                        'stopped': False,
                    }

        return {
            'success': simulated,
            'simulated': simulated,
            'stopped': stopped,
        }

    def validate_architecture():
        """Validate the complete federated memory architecture."""
        if not _initialized:
            return {'valid': False, 'error': 'Architecture not initialized'}

        validation_results = {
            'valid': True,
            'components': {},
            'interactions': {}
        }

        temp_concept_id: Optional[str] = None

        try:
            if _l3_manager:
                try:
                    stats = _l3_manager['get_statistics']()
                    validation_results['components']['L3'] = {'statistics': stats}
                except Exception as exc:
                    validation_results['components']['L3'] = {'error': str(exc)}
                    validation_results['valid'] = False

            if _l1_manager:
                try:
                    validation_results['components']['L1'] = {'statistics': _l1_manager['get_statistics']()}
                except Exception as exc:
                    validation_results['components']['L1'] = {'error': str(exc)}
                    validation_results['valid'] = False

            if _l2_manager:
                try:
                    validation_results['components']['L2'] = {'statistics': _l2_manager['get_statistics']()}
                except Exception as exc:
                    validation_results['components']['L2'] = {'error': str(exc)}
                    validation_results['valid'] = False

            if _cache_coordinator:
                try:
                    validation_results['components']['coordinator'] = {
                        'running': _cache_coordinator.get('is_running', lambda: False)(),
                        'statistics': _cache_coordinator['get_statistics']()
                    }
                    if not validation_results['components']['coordinator']['running']:
                        validation_results['valid'] = False
                except Exception as exc:
                    validation_results['components']['coordinator'] = {'error': str(exc)}
                    validation_results['valid'] = False

            rng = np.random.default_rng(seed=2025)
            vector_dim = int(_active_config['l1']['vector_dim'])
            test_vector = rng.random(vector_dim, dtype=np.float32)

            test_concept_payload = {
                'name': 'validation_concept',
                'metadata': {'source': 'federated_memory_validation'},
                'geometric_embedding': test_vector.tolist()
            }

            temp_concept_id = create_concept(test_concept_payload)
            validation_results['interactions']['create'] = bool(temp_concept_id)
            if not temp_concept_id:
                validation_results['valid'] = False
                return validation_results

            retrieved = get_concept(temp_concept_id)
            validation_results['interactions']['retrieve'] = retrieved is not None
            if retrieved is None:
                validation_results['valid'] = False

            search_results = search_similar_concepts(test_vector, k=1, threshold=0.0)
            validation_results['interactions']['search'] = bool(search_results)
            if not search_results:
                validation_results['valid'] = False

        except Exception as exc:
            validation_results['valid'] = False
            validation_results['error'] = str(exc)
            logger.exception("Architecture validation failed: %s", exc)
        finally:
            if temp_concept_id:
                try:
                    if _cache_coordinator:
                        _cache_coordinator['invalidate'](temp_concept_id)
                    if _l1_manager:
                        _l1_manager['remove'](temp_concept_id)
                    if _l2_manager:
                        _l2_manager['remove'](temp_concept_id)
                    if _l3_manager:
                        _l3_manager['delete_concept'](temp_concept_id)
                except Exception as cleanup_exc:
                    logger.warning("Cleanup after validation failed: %s", cleanup_exc)

        return validation_results

    def start_outbox_poller(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        if not _outbox_available():
            return {'success': False, 'error': 'transactional_outbox_unavailable'}
        _start_outbox_poller(options)
        running = False
        if _transactional_outbox_poller:
            running = bool(_transactional_outbox_poller.get('is_running', lambda: False)())
        return {
            'success': running,
            'status': _get_outbox_status(),
        }

    def stop_outbox_poller(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        timeout = None
        if isinstance(options, dict) and options.get('timeout') is not None:
            try:
                timeout = float(options['timeout'])
            except Exception:
                timeout = None
        _stop_outbox_poller(timeout=timeout)
        return {
            'success': True,
            'status': _get_outbox_status(),
        }

    def process_outbox_batch(options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        return _process_outbox_batch(options)

    def enqueue_outbox_event(action: str, payload: Optional[Dict[str, Any]] = None, metadata: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        return _enqueue_outbox_event(action, payload, metadata)

    def get_outbox_status() -> Dict[str, Any]:
        return _get_outbox_status()

    def get_transactional_outbox():
        return _transactional_outbox

    # Return the complete federated memory interface
    return {
        # Lifecycle management
        'initialize': initialize,
        'shutdown': shutdown,

        # Core concept operations
        'create_concept': create_concept,
        'store_concept': create_concept,
        'get_concept': get_concept,
        'load_concept': get_concept,
        'update_concept': update_concept,
        'search_similar': search_similar_concepts,
        'semantic_search': search_similar_concepts,
        'search_tiered': search_tiered,
        'bulk_ingest_l2': bulk_ingest_l2,
        'rebuild_l2_diskann': rebuild_l2_diskann,
        'get_l2_diskann_status': get_l2_diskann_status,
        'invalidate_concept': invalidate_concept,

        # Prototypal integration
        'create_proxy': create_prototypal_proxy,
        'get_cache_interface': get_transparent_cache_interface,

        # System management
        'get_status': get_status,
        'get_cache_statistics': get_cache_statistics,
        'get_l2_telemetry': get_l2_telemetry,
        'simulate_coordinator_failure': simulate_coordinator_failure,
        'promote_l1_candidates': promote_l1_candidates,
        'trigger_promotion_cycle': trigger_promotion_cycle,
        'get_promotion_daemon_status': get_promotion_daemon_status,
        'validate': validate_architecture,
        'start_outbox_poller': start_outbox_poller,
        'stop_outbox_poller': stop_outbox_poller,
        'process_outbox_batch': process_outbox_batch,
        'enqueue_outbox_event': enqueue_outbox_event,
        'get_outbox_status': get_outbox_status,
        'get_outbox_analytics': get_outbox_analytics,
        'run_benchmark': run_benchmark,
        'get_benchmark_history': get_benchmark_history,
        'get_benchmark_summary': get_benchmark_summary,
        'get_benchmark_alerts': get_benchmark_alerts,
        'configure_benchmark_alerts': configure_benchmark_alerts,
        'clear_benchmark_alerts': clear_benchmark_alerts,
        'evaluate_benchmark_alerts': evaluate_benchmark_alerts,
        'get_benchmark_recommendations': get_benchmark_recommendations,
        'clear_benchmark_recommendations': clear_benchmark_recommendations,
        'apply_benchmark_recommendations': apply_benchmark_recommendations,
        'start_benchmark_daemon': start_benchmark_daemon,
        'stop_benchmark_daemon': stop_benchmark_daemon,
        'trigger_benchmark_run': trigger_benchmark_run,
        'get_benchmark_daemon_status': get_benchmark_daemon_status,

        # Component access (for advanced usage)
        'get_l3_manager': lambda: _l3_manager,
        'get_l1_manager': lambda: _l1_manager,
        'get_l2_manager': lambda: _l2_manager,
        'get_coordinator': lambda: _cache_coordinator,
        'get_bridge_manager': lambda: _bridge_manager,
        'get_transactional_outbox': get_transactional_outbox,
    }


# Global fabric instance
_global_memory_fabric = create_federated_memory_fabric()


def initialize_memory_fabric(config=None):
    """Initialize the global federated memory fabric."""
    return _global_memory_fabric['initialize'](config)


def shutdown_memory_fabric():
    """Shutdown the global federated memory fabric."""
    return _global_memory_fabric['shutdown']()


def get_memory_fabric():
    """Get the global federated memory fabric interface."""
    return _global_memory_fabric


def validate_memory_fabric():
    """Validate the global federated memory fabric."""
    return _global_memory_fabric['validate']()


if __name__ == "__main__":
    # Test the complete federated memory architecture
    print("🚀 Testing TELOS Phase 2 Federated Memory Architecture...")
    
    # Initialize
    if initialize_memory_fabric():
        print("✅ Federated Memory Fabric initialized")
        
        # Get status
        status = _global_memory_fabric['get_status']()
        print(f"📊 System Status: {status['initialized']}")
        print(f"🔧 Components: {list(status['components'].keys())}")
        
        # Validate architecture
        print("\n🔍 Validating architecture...")
        validation = validate_memory_fabric()
        if validation['valid']:
            print("✅ Architecture validation passed")
        else:
            print(f"❌ Architecture validation failed: {validation.get('error', 'Unknown error')}")
        
        # Test concept creation
        print("\n🧠 Testing concept operations...")
        test_concept = {
            'name': 'test_concept',
            'symbolic_hypervector': [1.0] * 1024,
            'geometric_embedding': [0.5] * 1024,
            'metadata': {'created_by': 'integration_test'}
        }
        
        concept_id = _global_memory_fabric['create_concept'](test_concept)
        if concept_id:
            print(f"✅ Created test concept: {concept_id}")
            
            # Test retrieval
            retrieved = _global_memory_fabric['get_concept'](concept_id)
            if retrieved:
                print(f"✅ Retrieved concept: {retrieved.get('name', 'unnamed')}")
            else:
                print("❌ Failed to retrieve concept")
        else:
            print("❌ Failed to create test concept")
        
        # Shutdown
        shutdown_memory_fabric()
        print("\n✅ Federated Memory Fabric shutdown complete")
    else:
        print("❌ Failed to initialize Federated Memory Fabric")
        exit(1)