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
    # For testing purposes, create mock objects
    class MockFFI:
        def __init__(self):
            pass
    class MockLib:
        BRIDGE_SUCCESS = 0
        BRIDGE_ERROR_NULL_POINTER = -1
        def bridge_initialize(self, workers): return self.BRIDGE_SUCCESS
        def bridge_shutdown(self): pass
        def bridge_pin_object(self, handle): return self.BRIDGE_SUCCESS
        def bridge_unpin_object(self, handle): return self.BRIDGE_SUCCESS
    
    ffi = MockFFI()
    lib = MockLib()
    print("WARNING: Using mock bridge for testing - full functionality not available", file=sys.stderr)

# Set up logging
logger = logging.getLogger(__name__)

_LATENCY_BUCKET_BOUNDS = [
    1.0,
    5.0,
    10.0,
    25.0,
    50.0,
    100.0,
    250.0,
    500.0,
    1000.0,
]

_LATENCY_BUCKET_LABELS = [
    "<=1ms",
    "<=5ms",
    "<=10ms",
    "<=25ms",
    "<=50ms",
    "<=100ms",
    "<=250ms",
    "<=500ms",
    "<=1000ms",
]

_LATENCY_TERMINAL_LABEL = ">1000ms"

_ALL_LATENCY_BUCKET_LABELS = _LATENCY_BUCKET_LABELS + [_LATENCY_TERMINAL_LABEL]


def _initialize_latency_buckets() -> Dict[str, int]:
    return {label: 0 for label in _ALL_LATENCY_BUCKET_LABELS}


def _compute_percentiles(values: List[float], percentiles: Iterable[float]) -> Dict[str, float]:
    if not values:
        return {}

    sorted_values = sorted(values)
    count = len(sorted_values)
    results: Dict[str, float] = {}

    for percentile in percentiles:
        if percentile < 0.0 or percentile > 100.0:
            continue

        if count == 1:
            results[f"p{int(percentile)}"] = float(sorted_values[0])
            continue

        position = (percentile / 100.0) * (count - 1)
        lower_index = int(math.floor(position))
        upper_index = int(math.ceil(position))

        if lower_index == upper_index:
            value = float(sorted_values[lower_index])
        else:
            lower_value = float(sorted_values[lower_index])
            upper_value = float(sorted_values[upper_index])
            weight = position - lower_index
            value = lower_value + (upper_value - lower_value) * weight

        results[f"p{int(percentile)}"] = value

    return results


def create_prototypal_bridge_manager():
    """
    Factory function creating a prototypal bridge manager that handles IoProxy creation
    and management following architectural mandates for prototypal behavior.
    
    Returns:
        dict: Method dictionary implementing prototypal interface
    """
    
    # Internal state (closure variables)
    _proxy_registry = {}  # Track active proxies
    _initialized = False
    _summary_history: List[Dict[str, Any]] = []
    _summary_history_limit = 64

    def _initialize_metrics_state() -> Dict[str, Any]:
        """Create a fresh metrics state following the dispatch schema."""

        return {
            'invocations': 0,
            'failures': 0,
            'cumulativeDurationMs': 0.0,
            'averageDurationMs': 0.0,
            'lastDurationMs': 0.0,
            'failureRate': 0.0,
            'successRate': 1.0,
            'successStreak': 0,
            'recentLimit': 16,
            'recent': [],
            'lastTimestamp': 0.0,
            'lastOutcome': 'n/a',
            'lastMessage': None,
            'lastError': None,
            'latencyBuckets': _initialize_latency_buckets(),
            'minDurationMs': None,
            'maxDurationMs': 0.0,
        }

    def _copy_metrics_state(metrics: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        """Return a defensive copy of the metrics state for external consumers."""

        if not metrics:
            return None

        snapshot = dict(metrics)
        recent_entries = metrics.get('recent')
        if isinstance(recent_entries, list):
            snapshot['recent'] = [dict(entry) for entry in recent_entries]

        latency_buckets = metrics.get('latencyBuckets')
        if isinstance(latency_buckets, dict):
            snapshot['latencyBuckets'] = dict(latency_buckets)
        return snapshot

    def _record_summary_history(summary_payload: Dict[str, Any]) -> None:
        """Capture a timestamped copy of the latest summary for historical inspection."""

        nonlocal _summary_history_limit

        try:
            trimmed_summary: Dict[str, Any] = {}
            for key, value in summary_payload.items():
                if key == 'perProxy':
                    continue
                trimmed_summary[key] = copy.deepcopy(value)

            percentiles = summary_payload.get('durationPercentiles') or {}
            if isinstance(percentiles, dict) and 'p95' in percentiles:
                try:
                    trimmed_summary['durationPercentiles_p95'] = float(percentiles.get('p95'))
                except (TypeError, ValueError):
                    pass

            entry: Dict[str, Any] = {
                'timestamp': time.time(),
                'summary': trimmed_summary,
            }

            per_proxy = summary_payload.get('perProxy')
            if isinstance(per_proxy, dict):
                entry['proxyIds'] = list(per_proxy.keys())

            _summary_history.append(entry)

            while len(_summary_history) > _summary_history_limit:
                del _summary_history[0]

        except Exception:  # pragma: no cover - defensive logging path
            logger.debug("Failed to record bridge summary history", exc_info=True)

    def _calculate_summary_trend(current_value: float, history_key: str) -> Dict[str, Optional[float]]:
        if not _summary_history:
            return {
                'current': current_value,
                'baseline': None,
                'delta': None,
            }

        running_total = 0.0
        count = 0
        for entry in _summary_history[-8:]:
            summary_slice = entry.get('summary')
            if not isinstance(summary_slice, dict):
                continue
            historical_value = summary_slice.get(history_key)
            if historical_value is None:
                continue
            try:
                running_total += float(historical_value)
                count += 1
            except (TypeError, ValueError):
                continue

        if count == 0:
            return {
                'current': current_value,
                'baseline': None,
                'delta': None,
            }

        baseline = running_total / count
        return {
            'current': current_value,
            'baseline': baseline,
            'delta': current_value - baseline,
        }

    def _compute_per_proxy_health(proxy_id: str, metrics: Dict[str, Any]) -> Dict[str, Any]:
        failure_rate = float(metrics.get('failureRate', 0.0) or 0.0)
        avg_duration = float(metrics.get('averageDurationMs', 0.0) or 0.0)
        max_duration = float(metrics.get('maxDurationMs', 0.0) or 0.0)

        recent_entries = metrics.get('recent') or []
        recent_failures = 0
        slow_samples = 0
        for entry in recent_entries:
            if not isinstance(entry, dict):
                continue
            duration_value = entry.get('durationMs')
            try:
                duration = float(duration_value)
            except (TypeError, ValueError):
                duration = 0.0
            if not entry.get('success'):
                recent_failures += 1
            if duration > 250.0:
                slow_samples += 1

        score = 100.0
        flags: List[str] = []

        if failure_rate > 0.05:
            penalty = min(50.0, (failure_rate - 0.05) * 400.0)
            score -= penalty
            flags.append('elevated_failure_rate')

        if recent_failures > 0 and failure_rate > 0.0:
            score -= min(20.0, recent_failures * 5.0)
            flags.append('recent_failures')

        if avg_duration > 100.0:
            penalty = min(25.0, (avg_duration - 100.0) * 0.1)
            score -= penalty
            flags.append('high_average_latency')

        if max_duration > 500.0:
            score -= 10.0
            flags.append('slow_outlier')

        if slow_samples > 3:
            score -= min(15.0, slow_samples * 2.0)
            flags.append('slow_recent_samples')

        score = max(0.0, min(100.0, score))

        return {
            'score': score,
            'flags': flags,
            'failureRate': failure_rate,
            'averageDurationMs': avg_duration,
            'maxDurationMs': max_duration,
            'recentFailures': recent_failures,
        }

    def _augment_summary_health(summary: Dict[str, Any], metrics_map: Dict[str, Dict[str, Any]]) -> None:
        per_proxy_health: Dict[str, Any] = {}
        total_score = 0.0
        scored_proxies = 0
        aggregate_flags: Dict[str, int] = {}

        for proxy_id, metrics in metrics_map.items():
            if not isinstance(metrics, dict):
                continue
            health = _compute_per_proxy_health(proxy_id, metrics)
            per_proxy_health[proxy_id] = health
            total_score += health['score']
            scored_proxies += 1
            for flag in health['flags']:
                aggregate_flags[flag] = aggregate_flags.get(flag, 0) + 1

        summary['perProxyHealth'] = per_proxy_health

        if scored_proxies:
            average_score = total_score / scored_proxies
        else:
            average_score = 100.0

        summary['healthScore'] = average_score
        summary['healthFlags'] = sorted(aggregate_flags.keys())

        failure_trend = _calculate_summary_trend(summary.get('failureRate', 0.0) or 0.0, 'failureRate')
        percentile_map = summary.get('durationPercentiles') or {}
        p95_value = float(percentile_map.get('p95', 0.0) or 0.0)
        latency_trend = _calculate_summary_trend(p95_value, 'durationPercentiles_p95')

        summary['trend'] = {
            'failureRate': failure_trend,
            'p95DurationMs': latency_trend,
        }

    def get_summary_history(limit: Optional[Union[int, str]] = None) -> List[Dict[str, Any]]:
        """Return a copy of the recorded summary history, honoring optional bounds."""

        if limit is not None:
            try:
                requested = int(limit)
            except (TypeError, ValueError):
                raise ValueError("Summary history limit must be an integer")

            if requested < 1:
                raise ValueError("Summary history limit must be positive")

            slice_size = min(requested, len(_summary_history))
        else:
            slice_size = len(_summary_history)

        if slice_size <= 0:
            return []

        selected = _summary_history[-slice_size:]
        return [copy.deepcopy(entry) for entry in selected]

    def clear_summary_history() -> bool:
        """Reset the accumulated summary history."""

        _summary_history.clear()
        return True

    def configure_summary_history(options: Optional[Union[int, Dict[str, Any]]] = None) -> Dict[str, Any]:
        """Update history retention parameters and report the active configuration."""

        nonlocal _summary_history_limit

        limit_value: Optional[Any]
        if isinstance(options, dict):
            limit_value = options.get('limit')
            if limit_value is None:
                limit_value = options.get('maxEntries')
            if limit_value is None:
                limit_value = options.get('max_entries')
        else:
            limit_value = options

        if limit_value is not None:
            try:
                parsed_limit = int(limit_value)
            except (TypeError, ValueError):
                raise ValueError("Summary history limit must be an integer")

            if parsed_limit < 1:
                raise ValueError("Summary history limit must be positive")

            if parsed_limit > 1024:
                parsed_limit = 1024

            _summary_history_limit = parsed_limit

            while len(_summary_history) > _summary_history_limit:
                del _summary_history[0]

        return {
            'limit': _summary_history_limit,
            'size': len(_summary_history),
        }

    def _summarize_metrics_map(metrics_map: Dict[str, Dict[str, Any]]) -> Dict[str, Any]:
        """Build an aggregate summary across multiple proxy metrics payloads."""

        proxy_count = len(metrics_map)
        if proxy_count == 0:
            empty_buckets = _initialize_latency_buckets()
            return {
                'proxyCount': 0,
                'totalInvocations': 0,
                'totalFailures': 0,
                'successRate': 1.0,
                'failureRate': 0.0,
                'averageDurationMs': 0.0,
                'lastActivityTimestamp': 0.0,
                'lastActivityProxy': None,
                'topMessages': [],
                'slowestRecent': [],
                'recentSampleCount': 0,
                'latencyBuckets': empty_buckets,
                'latencyBucketTotal': 0,
                'latencyBucketDistribution': {label: 0.0 for label in empty_buckets},
                'minDurationMs': None,
                'maxDurationMs': None,
                'durationPercentiles': {},
            }

        total_invocations = 0
        total_failures = 0
        weighted_duration = 0.0
        last_activity_timestamp = 0.0
        last_activity_proxy: Optional[str] = None
        message_counts: Dict[str, int] = {}
        recent_samples: List[Dict[str, Any]] = []
        bucket_rollup = _initialize_latency_buckets()
        bucket_total = 0
        global_min_duration: Optional[float] = None
        global_max_duration: Optional[float] = None
        percentile_samples: List[float] = []
        message_rollup: Dict[str, Dict[str, Any]] = {}

        for proxy_id, metrics in metrics_map.items():
            if not isinstance(metrics, dict):
                continue

            invocations = int(metrics.get('invocations', 0) or 0)
            failures = int(metrics.get('failures', 0) or 0)
            avg_duration = float(metrics.get('averageDurationMs', 0.0) or 0.0)
            last_timestamp = float(metrics.get('lastTimestamp', 0.0) or 0.0)

            total_invocations += invocations
            total_failures += failures
            if invocations > 0:
                weighted_duration += avg_duration * invocations

            min_duration_value = metrics.get('minDurationMs')
            max_duration_value = metrics.get('maxDurationMs')

            try:
                if min_duration_value is not None:
                    min_candidate = float(min_duration_value)
                    if global_min_duration is None or min_candidate < global_min_duration:
                        global_min_duration = min_candidate
            except (TypeError, ValueError):
                pass

            try:
                if max_duration_value is not None:
                    max_candidate = float(max_duration_value)
                    if global_max_duration is None or max_candidate > global_max_duration:
                        global_max_duration = max_candidate
            except (TypeError, ValueError):
                pass

            if last_timestamp >= last_activity_timestamp:
                last_activity_timestamp = last_timestamp
                last_activity_proxy = proxy_id

            recent_entries = metrics.get('recent') or []
            if isinstance(recent_entries, list):
                for entry in recent_entries:
                    if not isinstance(entry, dict):
                        continue

                    message_name = entry.get('message') or 'unknown'
                    message_counts[message_name] = message_counts.get(message_name, 0) + 1

                    duration_value = entry.get('durationMs')
                    if duration_value is None:
                        continue

                    duration = float(duration_value)
                    percentile_samples.append(duration)
                    recent_samples.append({
                        'proxyId': proxy_id,
                        'message': message_name,
                        'success': bool(entry.get('success')),
                        'durationMs': duration,
                        'timestamp': float(entry.get('timestamp', 0.0) or 0.0),
                        'error': entry.get('error'),
                    })

            message_stats = metrics.get('messageStats')
            if isinstance(message_stats, dict):
                for message_name, entry in message_stats.items():
                    if not isinstance(entry, dict):
                        continue

                    aggregate = message_rollup.setdefault(message_name, {
                        'message': message_name,
                        'invocations': 0,
                        'failures': 0,
                        'cumulativeDurationMs': 0.0,
                        'minDurationMs': None,
                        'maxDurationMs': None,
                        'lastTimestamp': 0.0,
                        'lastOutcome': None,
                        'lastDurationMs': None,
                        'lastError': None,
                        'lastSourceProxy': None,
                        'sources': {},
                    })

                    entry_invocations = int(entry.get('invocations', 0) or 0)
                    entry_failures = int(entry.get('failures', 0) or 0)
                    entry_cumulative = float(entry.get('cumulativeDurationMs', 0.0) or 0.0)
                    entry_last_timestamp = float(entry.get('lastTimestamp', 0.0) or 0.0)
                    entry_last_duration = float(entry.get('lastDurationMs', 0.0) or 0.0)
                    entry_last_outcome = entry.get('lastOutcome')
                    entry_last_error = entry.get('lastError')

                    if entry_last_error is not None and not isinstance(entry_last_error, str):
                        try:
                            entry_last_error = str(entry_last_error)
                        except Exception:  # pragma: no cover - defensive fallback
                            entry_last_error = repr(entry_last_error)

                    entry_min = entry.get('minDurationMs')
                    entry_min_value: Optional[float]
                    try:
                        entry_min_value = None if entry_min is None else float(entry_min)
                    except (TypeError, ValueError):
                        entry_min_value = None

                    entry_max = entry.get('maxDurationMs')
                    entry_max_value: Optional[float]
                    try:
                        entry_max_value = None if entry_max is None else float(entry_max)
                    except (TypeError, ValueError):
                        entry_max_value = None

                    aggregate['invocations'] += entry_invocations
                    aggregate['failures'] += entry_failures
                    aggregate['cumulativeDurationMs'] += entry_cumulative

                    current_min = aggregate.get('minDurationMs')
                    if entry_min_value is not None:
                        if current_min is None or entry_min_value < current_min:
                            aggregate['minDurationMs'] = entry_min_value

                    current_max = aggregate.get('maxDurationMs')
                    if entry_max_value is not None:
                        if current_max is None or entry_max_value > current_max:
                            aggregate['maxDurationMs'] = entry_max_value

                    if entry_last_timestamp >= aggregate.get('lastTimestamp', 0.0):
                        aggregate['lastTimestamp'] = entry_last_timestamp
                        aggregate['lastOutcome'] = entry_last_outcome
                        aggregate['lastDurationMs'] = entry_last_duration
                        aggregate['lastError'] = entry_last_error
                        aggregate['lastSourceProxy'] = proxy_id

                    sources_map = aggregate.setdefault('sources', {})
                    if not isinstance(sources_map, dict):
                        sources_map = {}
                        aggregate['sources'] = sources_map
                    source_entry = sources_map.setdefault(proxy_id, {
                        'proxyId': proxy_id,
                        'invocations': 0,
                        'failures': 0,
                        'lastTimestamp': 0.0,
                        'lastOutcome': None,
                        'lastDurationMs': 0.0,
                    })

                    source_entry['invocations'] += entry_invocations
                    source_entry['failures'] += entry_failures
                    if entry_last_timestamp >= source_entry.get('lastTimestamp', 0.0):
                        source_entry['lastTimestamp'] = entry_last_timestamp
                        source_entry['lastOutcome'] = entry_last_outcome
                        source_entry['lastDurationMs'] = entry_last_duration

            latency_buckets = metrics.get('latencyBuckets')
            if isinstance(latency_buckets, dict):
                for label in _ALL_LATENCY_BUCKET_LABELS:
                    bucket_count = latency_buckets.get(label)
                    try:
                        count_value = int(bucket_count or 0)
                    except (TypeError, ValueError):
                        count_value = 0
                    if count_value:
                        bucket_rollup[label] += count_value
                        bucket_total += count_value

        failure_rate = (total_failures / total_invocations) if total_invocations else 0.0
        failure_rate = min(max(failure_rate, 0.0), 1.0)
        success_rate = 1.0 - failure_rate
        average_duration = (weighted_duration / total_invocations) if total_invocations else 0.0

        message_rollup_serialized: Dict[str, Dict[str, Any]] = {}
        for message, aggregate in message_rollup.items():
            invocations = int(aggregate.get('invocations', 0) or 0)
            failures = int(aggregate.get('failures', 0) or 0)
            cumulative_duration = float(aggregate.get('cumulativeDurationMs', 0.0) or 0.0)
            min_duration = aggregate.get('minDurationMs')
            max_duration = aggregate.get('maxDurationMs')
            last_timestamp = float(aggregate.get('lastTimestamp', 0.0) or 0.0)
            last_outcome = aggregate.get('lastOutcome')
            last_duration = aggregate.get('lastDurationMs')
            last_error = aggregate.get('lastError')
            last_source = aggregate.get('lastSourceProxy')

            failure_rate_message = (failures / invocations) if invocations else 0.0
            failure_rate_message = min(max(failure_rate_message, 0.0), 1.0)
            success_rate_message = 1.0 - failure_rate_message
            average_duration_message = (cumulative_duration / invocations) if invocations else 0.0

            sources_map = aggregate.get('sources', {})
            if not isinstance(sources_map, dict):
                sources_map = {}
            source_entries = list(sources_map.values())
            for source_entry in source_entries:
                source_entry.setdefault('proxyId', source_entry.get('proxyId'))
                source_entry['invocations'] = int(source_entry.get('invocations', 0) or 0)
                source_entry['failures'] = int(source_entry.get('failures', 0) or 0)
                source_entry['lastTimestamp'] = float(source_entry.get('lastTimestamp', 0.0) or 0.0)
                source_entry['lastDurationMs'] = float(source_entry.get('lastDurationMs', 0.0) or 0.0)

            source_entries.sort(key=lambda item: item.get('invocations', 0), reverse=True)
            trimmed_sources = source_entries[:5]
            source_overflow = max(len(source_entries) - len(trimmed_sources), 0)

            message_rollup_serialized[message] = {
                'message': message,
                'invocations': invocations,
                'failures': failures,
                'failureRate': failure_rate_message,
                'successRate': success_rate_message,
                'averageDurationMs': average_duration_message,
                'cumulativeDurationMs': cumulative_duration,
                'minDurationMs': min_duration,
                'maxDurationMs': max_duration,
                'lastTimestamp': last_timestamp,
                'lastOutcome': last_outcome,
                'lastDurationMs': last_duration,
                'lastError': last_error,
                'lastSourceProxy': last_source,
                'sourceCount': len(source_entries),
                'sourcesOverflow': source_overflow,
                'sources': trimmed_sources,
            }

        histogram_pairs = sorted(message_counts.items(), key=lambda pair: pair[1], reverse=True)
        top_messages: List[Dict[str, Any]] = []
        for message, count in histogram_pairs[:5]:
            rollup_data = message_rollup_serialized.get(message, {})
            top_messages.append({
                'message': message,
                'recentCount': count,
                'totalInvocations': rollup_data.get('invocations'),
                'failureRate': rollup_data.get('failureRate'),
                'averageDurationMs': rollup_data.get('averageDurationMs'),
            })

        recent_samples.sort(key=lambda sample: sample.get('durationMs', 0.0), reverse=True)
        slowest_recent = recent_samples[:5]

        bucket_distribution = {
            label: (bucket_rollup[label] / bucket_total) if bucket_total else 0.0
            for label in bucket_rollup
        }

        percentile_stats = _compute_percentiles(percentile_samples, (50.0, 75.0, 90.0, 95.0, 99.0))

        rollup_items = list(message_rollup_serialized.items())
        top_failure_entries: List[Dict[str, Any]] = []
        for message, data in rollup_items:
            invocations = data.get('invocations', 0)
            failure_rate_message = float(data.get('failureRate', 0.0) or 0.0)
            if invocations and failure_rate_message > 0.0:
                top_failure_entries.append({
                    'message': message,
                    'failureRate': failure_rate_message,
                    'invocations': invocations,
                    'failures': data.get('failures', 0),
                    'averageDurationMs': data.get('averageDurationMs'),
                    'lastTimestamp': data.get('lastTimestamp'),
                    'lastOutcome': data.get('lastOutcome'),
                    'lastDurationMs': data.get('lastDurationMs'),
                    'sourceCount': data.get('sourceCount'),
                })

        top_failure_entries.sort(key=lambda item: (item.get('failureRate', 0.0), item.get('invocations', 0)), reverse=True)
        top_failure_entries = top_failure_entries[:5]

        top_duration_entries: List[Dict[str, Any]] = []
        for message, data in rollup_items:
            invocations = data.get('invocations', 0)
            avg_duration = float(data.get('averageDurationMs', 0.0) or 0.0)
            if invocations:
                top_duration_entries.append({
                    'message': message,
                    'averageDurationMs': avg_duration,
                    'invocations': invocations,
                    'failures': data.get('failures', 0),
                    'failureRate': data.get('failureRate', 0.0),
                    'lastTimestamp': data.get('lastTimestamp'),
                    'lastOutcome': data.get('lastOutcome'),
                    'sourceCount': data.get('sourceCount'),
                })

        top_duration_entries.sort(key=lambda item: item.get('averageDurationMs', 0.0), reverse=True)
        top_duration_entries = top_duration_entries[:5]

        recent_failure_entries: List[Dict[str, Any]] = []
        for message, data in rollup_items:
            if data.get('lastOutcome') == 'failure':
                recent_failure_entries.append({
                    'message': message,
                    'lastTimestamp': data.get('lastTimestamp'),
                    'lastDurationMs': data.get('lastDurationMs'),
                    'lastError': data.get('lastError'),
                    'sourceCount': data.get('sourceCount'),
                    'invocations': data.get('invocations'),
                })

        recent_failure_entries.sort(key=lambda item: item.get('lastTimestamp', 0.0) or 0.0, reverse=True)
        recent_failure_entries = recent_failure_entries[:5]

        return {
            'proxyCount': proxy_count,
            'totalInvocations': total_invocations,
            'totalFailures': total_failures,
            'successRate': success_rate,
            'failureRate': failure_rate,
            'averageDurationMs': average_duration,
            'lastActivityTimestamp': last_activity_timestamp,
            'lastActivityProxy': last_activity_proxy,
            'topMessages': top_messages,
            'slowestRecent': slowest_recent,
            'recentSampleCount': len(recent_samples),
            'latencyBuckets': bucket_rollup,
            'latencyBucketTotal': bucket_total,
            'latencyBucketDistribution': bucket_distribution,
            'minDurationMs': global_min_duration,
            'maxDurationMs': global_max_duration,
            'durationPercentiles': percentile_stats,
            'messageRollup': message_rollup_serialized,
            'messageAnalytics': {
                'topFailureRate': top_failure_entries,
                'topAverageDuration': top_duration_entries,
                'recentFailures': recent_failure_entries,
            },
        }

    def _record_dispatch(proxy_state: Dict[str, Any], message_name: str, success: bool,
                         duration_ms: float, timestamp_s: float, error_text: Optional[str]) -> None:
        """Update per-proxy metrics after a dispatch completes."""

        metrics = proxy_state.setdefault('metrics', _initialize_metrics_state())

        metrics['invocations'] += 1
        if not success:
            metrics['failures'] += 1
            metrics['successStreak'] = 0
        else:
            metrics['successStreak'] += 1

        duration_value = max(duration_ms, 0.0)

        metrics['cumulativeDurationMs'] += duration_value
        invocations = metrics['invocations'] or 1
        metrics['averageDurationMs'] = metrics['cumulativeDurationMs'] / invocations
        metrics['lastDurationMs'] = duration_value
        metrics['failureRate'] = metrics['failures'] / invocations
        metrics['failureRate'] = min(max(metrics['failureRate'], 0.0), 1.0)
        metrics['successRate'] = 1.0 - metrics['failureRate']
        metrics['lastMessage'] = message_name
        metrics['lastOutcome'] = 'success' if success else 'failure'
        metrics['lastTimestamp'] = timestamp_s
        metrics['lastError'] = error_text

        if metrics.get('minDurationMs') is None or duration_value < float(metrics['minDurationMs']):
            metrics['minDurationMs'] = duration_value
        metrics['maxDurationMs'] = max(float(metrics.get('maxDurationMs') or 0.0), duration_value)

        latency_buckets = metrics.get('latencyBuckets')
        if not isinstance(latency_buckets, dict):
            latency_buckets = _initialize_latency_buckets()
            metrics['latencyBuckets'] = latency_buckets

        bucket_label = _LATENCY_TERMINAL_LABEL
        for bound, label in zip(_LATENCY_BUCKET_BOUNDS, _LATENCY_BUCKET_LABELS):
            if duration_value <= bound:
                bucket_label = label
                break
        latency_buckets[bucket_label] = latency_buckets.get(bucket_label, 0) + 1

        recent_limit = metrics.get('recentLimit') or 16
        recent_entries = metrics.setdefault('recent', [])
        entry = {
            'message': message_name,
            'success': success,
            'durationMs': duration_value,
            'timestamp': timestamp_s,
        }
        if error_text:
            entry['error'] = error_text
        recent_entries.append(entry)
        if len(recent_entries) > recent_limit:
            del recent_entries[:len(recent_entries) - recent_limit]

    def _record_dispatch_for_handle(io_handle: Any, message_name: str, success: bool,
                                     duration_ms: float, timestamp_s: float,
                                     error_text: Optional[str]) -> None:
        """Record dispatch metrics for every proxy bound to the Io handle."""

        for proxy_state in _proxy_registry.values():
            if proxy_state.get('io_master_handle') == io_handle:
                _record_dispatch(proxy_state, message_name, success, duration_ms, timestamp_s, error_text)

    def _bridge_error_message() -> str:
        buf = ffi.new("char[1024]")
        lib.bridge_get_last_error(buf, len(buf))
        return ffi.string(buf).decode("utf-8", "replace")

    def _create_shared_memory(size: int):
        handle = ffi.new("SharedMemoryHandle *")
        result = lib.bridge_create_shared_memory(size, handle)
        if result != lib.BRIDGE_SUCCESS:
            error_text = _bridge_error_message()
            raise RuntimeError(f"Failed to create shared memory ({result}): {error_text}")
        return handle

    def _destroy_shared_memory(handle) -> None:
        if handle is None:
            return
        lib.bridge_destroy_shared_memory(handle)

    def _write_bytes_to_shared_memory(handle, payload: bytes) -> None:
        mapped_ptr = ffi.new("void **")
        status = lib.bridge_map_shared_memory(handle, mapped_ptr)
        if status != lib.BRIDGE_SUCCESS:
            error_text = _bridge_error_message()
            raise RuntimeError(f"Failed to map shared memory for write ({status}): {error_text}")

        buffer = ffi.buffer(mapped_ptr[0], handle[0].size)
        buffer[:] = b"\x00" * handle[0].size
        buffer[: len(payload)] = payload

        unmap_status = lib.bridge_unmap_shared_memory(handle, mapped_ptr[0])
        if unmap_status != lib.BRIDGE_SUCCESS:
            error_text = _bridge_error_message()
            raise RuntimeError(f"Failed to unmap shared memory after write ({unmap_status}): {error_text}")

    def _read_cstring_from_shared_memory(handle) -> str:
        mapped_ptr = ffi.new("void **")
        status = lib.bridge_map_shared_memory(handle, mapped_ptr)
        if status != lib.BRIDGE_SUCCESS:
            error_text = _bridge_error_message()
            raise RuntimeError(f"Failed to map shared memory for read ({status}): {error_text}")

        data = ffi.string(ffi.cast("char *", mapped_ptr[0]), handle[0].size)
        unmap_status = lib.bridge_unmap_shared_memory(handle, mapped_ptr[0])
        if unmap_status != lib.BRIDGE_SUCCESS:
            error_text = _bridge_error_message()
            raise RuntimeError(f"Failed to unmap shared memory after read ({unmap_status}): {error_text}")

        return data.decode("utf-8", "replace")
    
    def initialize(options=None):
        """Initialize the prototypal bridge system."""
        nonlocal _initialized
        if _initialized:
            return True

        worker_count = 4
        if options is not None:
            if isinstance(options, dict):
                worker_count = int(options.get('workers', worker_count))
            elif isinstance(options, (int, float)):
                worker_count = int(options)

        if worker_count <= 0:
            logger.warning(
                "Invalid bridge worker count %s provided; defaulting to 1 to satisfy C ABI contract",
                worker_count,
            )
            worker_count = 1

        try:
            # Initialize the core bridge
            result = lib.bridge_initialize(worker_count)
            if result == lib.BRIDGE_SUCCESS:
                _initialized = True
                logger.info("Prototypal Bridge Manager initialized successfully")
                return True
            else:
                logger.error(f"Bridge initialization failed with code: {result}")
                return False
        except Exception as e:
            logger.error(f"Exception during bridge initialization: {e}")
            return False
    
    def shutdown():
        """Shutdown the prototypal bridge system."""
        nonlocal _initialized
        if not _initialized:
            return
            
        try:
            # Clean up all active proxies
            for proxy_id in list(_proxy_registry.keys()):
                destroy_proxy(proxy_id)
            
            # Shutdown the core bridge
            lib.bridge_shutdown()
            _initialized = False
            logger.info("Prototypal Bridge Manager shutdown complete")
        except Exception as e:
            logger.error(f"Exception during bridge shutdown: {e}")
    
    def create_proxy(io_handle: Any, object_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Create a new IoProxy object from an Io VM handle.
        
        This implements the TelosProxyObject creation protocol, returning a prototypal
        interface (method dictionary) rather than a class instance.
        
        Args:
            io_handle: Handle to the Io object to wrap
            object_id: Optional unique identifier for tracking
            
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
            return create_proxy_interface(proxy_state)
            
        except Exception as e:
            logger.error(f"Exception creating proxy: {e}")
            # Cleanup on failure
            try:
                lib.bridge_unpin_object(io_handle)
            except:
                pass
            return None
    
    def create_proxy_interface(proxy_state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create the prototypal method interface for a proxy object.
        
        This implements the IoProxy behavior using a method dictionary,
        following the architectural mandate for prototypal interfaces.
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
                return forward_message_to_io(proxy_state['io_master_handle'], name, None)
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
        
        def clone():
            """
            Create a prototypal clone of this proxy.
            
            The clone delegates to the same master but has independent local slots.
            """
            clone_id = f"{proxy_state['object_id']}_clone_{len(_proxy_registry)}"
            
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
                _proxy_registry[clone_id] = clone_state
                
                return create_proxy_interface(clone_state)
            except Exception as e:
                logger.error(f"Failed to create clone: {e}")
                return None
        
        def send_message(message_name: str, *args) -> Any:
            """
            Send a message to the master Io object via the bridge.
            """
            return forward_message_to_io(proxy_state['io_master_handle'], message_name, args)
        
        def get_master_handle():
            """Get the Io VM master handle for inspection."""
            return proxy_state['io_master_handle']
        
        def get_object_id():
            """Get the unique object identifier."""
            return proxy_state['object_id']
        
        def get_local_slots():
            """Get the local slots dictionary."""
            return proxy_state['local_slots'].copy()
        
        def destroy():
            """Clean up the proxy and unpin the master handle."""
            try:
                # Unpin the master handle
                lib.bridge_unpin_object(proxy_state['io_master_handle'])
                
                # Remove from registry
                if proxy_state['object_id'] in _proxy_registry:
                    del _proxy_registry[proxy_state['object_id']]
                
                logger.debug(f"Destroyed proxy {proxy_state['object_id']}")
                return True
            except Exception as e:
                logger.error(f"Failed to destroy proxy {proxy_state['object_id']}: {e}")
                return False
        
        def get_dispatch_metrics():
            """Return a snapshot of dispatch metrics for this proxy."""
            return _copy_metrics_state(proxy_state.get('metrics'))

        def reset_dispatch_metrics():
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
    
    def _json_fallback(value: Any) -> Any:
        if isinstance(value, (bytes, bytearray)):
            return value.decode("utf-8", "replace")
        return value

    def forward_message_to_io(io_handle: Any, message_name: str, args: Optional[tuple]) -> Any:
        """Forward a message to the Io VM via the synaptic bridge while recording metrics."""
        if not _initialized:
            raise RuntimeError("Bridge not initialized - call initialize() first")

        args_handle = None
        result_handle = None
        success = False
        error_text: Optional[str] = None
        start_time = time.perf_counter()
        timestamp_s = time.time()

        try:
            args_ptr = ffi.NULL
            if args:
                args_list = list(args)
                args_json = json.dumps(args_list, default=_json_fallback)
                payload = (args_json + "\0").encode("utf-8")
                args_handle = _create_shared_memory(max(len(payload), 64))
                _write_bytes_to_shared_memory(args_handle, payload)
                args_ptr = args_handle

            message_bytes = message_name.encode("utf-8") + b"\0"
            result_buffer_size = 4096
            max_buffer_size = 1 << 20  # 1 MiB safety ceiling
            response_text: Optional[str] = None

            while True:
                result_handle = _create_shared_memory(result_buffer_size)
                status = lib.bridge_send_message(
                    io_handle,
                    message_bytes,
                    args_ptr if args_ptr != ffi.NULL else ffi.NULL,
                    result_handle,
                )

                if status == lib.BRIDGE_SUCCESS:
                    response_text = _read_cstring_from_shared_memory(result_handle)
                    break

                error_text = _bridge_error_message()
                _destroy_shared_memory(result_handle)
                result_handle = None

                if (
                    status == lib.BRIDGE_ERROR_SHARED_MEMORY
                    and "Result buffer too small" in error_text
                    and result_buffer_size < max_buffer_size
                ):
                    result_buffer_size *= 2
                    logger.debug("Result buffer expanded to %d bytes", result_buffer_size)
                    continue

                raise RuntimeError(f"bridge_send_message failed ({status}): {error_text}")

            parsed_response: Any = None
            if response_text:
                try:
                    parsed_response = json.loads(response_text)
                except json.JSONDecodeError:
                    logger.debug("Received non-JSON response from Io: %s", response_text)
                    parsed_response = response_text

            success = True
            return parsed_response

        except Exception as exc:
            error_text = str(exc)
            raise

        finally:
            duration_ms = max((time.perf_counter() - start_time) * 1000.0, 0.0)
            _record_dispatch_for_handle(io_handle, message_name, success, duration_ms, timestamp_s, error_text)

            if args_handle is not None:
                _destroy_shared_memory(args_handle)
            if result_handle is not None:
                _destroy_shared_memory(result_handle)
    
    def destroy_proxy(proxy_id: str) -> bool:
        """Destroy a specific proxy by ID."""
        if proxy_id in _proxy_registry:
            proxy_state = _proxy_registry[proxy_id]
            try:
                lib.bridge_unpin_object(proxy_state['io_master_handle'])
                del _proxy_registry[proxy_id]
                logger.debug(f"Destroyed proxy {proxy_id}")
                return True
            except Exception as e:
                logger.error(f"Failed to destroy proxy {proxy_id}: {e}")
        return False
    
    def get_status():
        """Get bridge manager status."""
        return {
            'initialized': _initialized,
            'active_proxies': len(_proxy_registry),
            'proxy_ids': list(_proxy_registry.keys())
        }

    def get_dispatch_metrics(proxy_id: Optional[str] = None) -> Any:
        """Retrieve dispatch metrics for a specific proxy or all proxies."""

        if proxy_id is not None:
            state = _proxy_registry.get(proxy_id)
            return _copy_metrics_state(state.get('metrics')) if state else None

        return {
            pid: _copy_metrics_state(state.get('metrics'))
            for pid, state in _proxy_registry.items()
            if state.get('metrics') is not None
        }

    def reset_dispatch_metrics(proxy_id: Optional[str] = None) -> bool:
        """Reset metrics for a specific proxy or all proxies."""

        if proxy_id is not None:
            state = _proxy_registry.get(proxy_id)
            if not state:
                return False
            state['metrics'] = _initialize_metrics_state()
            return True

        changed = False
        for state in _proxy_registry.values():
            state['metrics'] = _initialize_metrics_state()
            changed = True
        return changed

    def summarize_dispatch_metrics(proxy_ids: Optional[Iterable[str]] = None) -> Dict[str, Any]:
        """Compute an aggregate summary for selected proxies (or all proxies)."""

        metrics_map: Dict[str, Dict[str, Any]] = {}

        if proxy_ids is None:
            for pid, state in _proxy_registry.items():
                snapshot = _copy_metrics_state(state.get('metrics'))
                if snapshot is not None:
                    metrics_map[str(pid)] = snapshot
        else:
            for pid in proxy_ids:
                key = str(pid)
                state = _proxy_registry.get(key)
                if not state:
                    continue
                snapshot = _copy_metrics_state(state.get('metrics'))
                if snapshot is not None:
                    metrics_map[key] = snapshot

        summary = _summarize_metrics_map(metrics_map)
        summary['perProxy'] = metrics_map
        _augment_summary_health(summary, metrics_map)
        _record_summary_history(summary)
        return summary

    def analyze_dispatch_metrics(
        proxy_ids: Optional[Iterable[str]] = None,
        analysis_options: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Derive anomaly and remediation insights from dispatch metrics."""

        summary = summarize_dispatch_metrics(proxy_ids)

        options: Dict[str, Any] = {}
        if isinstance(analysis_options, dict):
            options = dict(analysis_options)

        default_thresholds = {
            'failure_rate_warning': 0.05,
            'failure_rate_critical': 0.2,
            'average_duration_warning_ms': 150.0,
            'average_duration_critical_ms': 350.0,
            'max_duration_warning_ms': 500.0,
            'max_duration_critical_ms': 1000.0,
            'health_score_warning': 70.0,
            'health_score_critical': 50.0,
            'recent_failure_warning': 1,
            'recent_failure_critical': 3,
            'slow_sample_threshold_ms': 250.0,
            'slow_sample_warning': 3,
            'slow_sample_critical': 6,
            'message_failure_rate_warning': 0.1,
            'message_failure_rate_critical': 0.25,
            'message_duration_warning_ms': 250.0,
            'message_duration_critical_ms': 600.0,
        }

        user_thresholds = options.get('thresholds') if isinstance(options.get('thresholds'), dict) else None
        if user_thresholds:
            for key, value in user_thresholds.items():
                try:
                    default_thresholds[key] = float(value)
                except (TypeError, ValueError):
                    continue

        severity_order = {'ok': 0, 'warning': 1, 'critical': 2}

        def escalate(current: str, target: str) -> str:
            if severity_order.get(target, 0) > severity_order.get(current, 0):
                return target
            return current

        proxy_findings: List[Dict[str, Any]] = []
        recommendations: List[str] = []

        metrics_map = summary.get('perProxy') or {}
        health_map = summary.get('perProxyHealth') or {}

        slow_threshold = float(default_thresholds['slow_sample_threshold_ms'])

        for proxy_id, metrics in metrics_map.items():
            if not isinstance(metrics, dict):
                continue

            health = health_map.get(proxy_id, {}) if isinstance(health_map, dict) else {}

            failure_rate = float(metrics.get('failureRate', 0.0) or 0.0)
            avg_duration = float(metrics.get('averageDurationMs', 0.0) or 0.0)
            max_duration = float(metrics.get('maxDurationMs', 0.0) or 0.0)
            success_rate = float(metrics.get('successRate', 1.0) or 0.0)
            invocations = int(metrics.get('invocations', 0) or 0)

            health_score = float(health.get('score', 100.0) or 100.0)
            health_flags = list(health.get('flags', [])) if isinstance(health.get('flags'), list) else []
            recent_failures = int(health.get('recentFailures', 0) or 0)

            recent_entries = metrics.get('recent') if isinstance(metrics.get('recent'), list) else []
            slow_samples = 0
            if recent_entries:
                for entry in recent_entries:
                    if not isinstance(entry, dict):
                        continue
                    try:
                        duration_value = float(entry.get('durationMs', 0.0) or 0.0)
                    except (TypeError, ValueError):
                        duration_value = 0.0
                    if duration_value >= slow_threshold:
                        slow_samples += 1

            severity = 'ok'
            reasons: List[str] = []
            proxy_recommendations: List[str] = []

            if health_score <= default_thresholds['health_score_critical']:
                severity = escalate(severity, 'critical')
                reasons.append('health_score_below_critical')
                proxy_recommendations.append('inspect_proxy')
            elif health_score <= default_thresholds['health_score_warning']:
                severity = escalate(severity, 'warning')
                reasons.append('health_score_below_warning')

            if failure_rate >= default_thresholds['failure_rate_critical']:
                severity = escalate(severity, 'critical')
                reasons.append('failure_rate_exceeds_critical')
                proxy_recommendations.append('increase_workers')
            elif failure_rate >= default_thresholds['failure_rate_warning']:
                severity = escalate(severity, 'warning')
                reasons.append('failure_rate_exceeds_warning')

            if recent_failures >= default_thresholds['recent_failure_critical']:
                severity = escalate(severity, 'critical')
                reasons.append('repeated_recent_failures')
                proxy_recommendations.append('investigate_recent_failures')
            elif recent_failures >= default_thresholds['recent_failure_warning']:
                severity = escalate(severity, 'warning')
                reasons.append('recent_failures_present')

            if avg_duration >= default_thresholds['average_duration_critical_ms']:
                severity = escalate(severity, 'critical')
                reasons.append('average_latency_exceeds_critical')
                proxy_recommendations.append('profile_latency')
            elif avg_duration >= default_thresholds['average_duration_warning_ms']:
                severity = escalate(severity, 'warning')
                reasons.append('average_latency_exceeds_warning')

            if max_duration >= default_thresholds['max_duration_critical_ms']:
                severity = escalate(severity, 'critical')
                reasons.append('max_latency_exceeds_critical')
                proxy_recommendations.append('profile_latency')
            elif max_duration >= default_thresholds['max_duration_warning_ms']:
                severity = escalate(severity, 'warning')
                reasons.append('max_latency_exceeds_warning')

            if slow_samples >= default_thresholds['slow_sample_critical']:
                severity = escalate(severity, 'critical')
                reasons.append('slow_samples_exceed_critical')
            elif slow_samples >= default_thresholds['slow_sample_warning']:
                severity = escalate(severity, 'warning')
                reasons.append('slow_samples_exceed_warning')

            for flag in health_flags:
                if flag in {'elevated_failure_rate', 'recent_failures', 'slow_outlier'}:
                    severity = escalate(severity, 'warning')
                    reasons.append(f'health_flag:{flag}')

            if severity != 'ok' and not proxy_recommendations:
                proxy_recommendations.append('inspect_proxy')

            for action in proxy_recommendations:
                if action not in recommendations:
                    recommendations.append(action)

            proxy_findings.append({
                'proxyId': proxy_id,
                'severity': severity,
                'reasons': reasons,
                'metrics': {
                    'invocations': invocations,
                    'successRate': success_rate,
                    'failureRate': failure_rate,
                    'averageDurationMs': avg_duration,
                    'maxDurationMs': max_duration,
                    'slowSampleCount': slow_samples,
                },
                'health': {
                    'score': health_score,
                    'flags': health_flags,
                    'recentFailures': recent_failures,
                },
                'suggestedActions': proxy_recommendations,
            })

        proxy_findings.sort(key=lambda entry: severity_order.get(entry.get('severity', 'ok'), 0), reverse=True)

        analytics = summary.get('messageAnalytics') or {}
        message_findings_map: Dict[str, Dict[str, Any]] = {}

        def register_message(entry: Dict[str, Any], reason: str, severity: str) -> None:
            if not isinstance(entry, dict):
                return
            message_name = entry.get('message')
            if message_name is None:
                return
            key = str(message_name)
            payload = message_findings_map.setdefault(key, {
                'message': key,
                'reasons': [],
                'severity': 'ok',
                'metrics': {},
            })
            payload['severity'] = escalate(payload.get('severity', 'ok'), severity)
            reasons_list = payload.setdefault('reasons', [])
            if reason not in reasons_list:
                reasons_list.append(reason)
            metrics_bucket = payload.setdefault('metrics', {})
            for field in (
                'failureRate',
                'invocations',
                'averageDurationMs',
                'lastDurationMs',
                'lastTimestamp',
                'sourceCount',
            ):
                if field in entry and field not in metrics_bucket:
                    metrics_bucket[field] = entry[field]

        failure_entries = analytics.get('topFailureRate') or []
        for entry in failure_entries:
            try:
                failure_rate = float(entry.get('failureRate', 0.0) or 0.0)
            except (TypeError, ValueError):
                failure_rate = 0.0
            if failure_rate >= default_thresholds['message_failure_rate_critical']:
                register_message(entry, 'failure_rate_exceeds_critical', 'critical')
            elif failure_rate >= default_thresholds['message_failure_rate_warning']:
                register_message(entry, 'failure_rate_exceeds_warning', 'warning')

        duration_entries = analytics.get('topAverageDuration') or []
        for entry in duration_entries:
            try:
                avg_duration = float(entry.get('averageDurationMs', 0.0) or 0.0)
            except (TypeError, ValueError):
                avg_duration = 0.0
            if avg_duration >= default_thresholds['message_duration_critical_ms']:
                register_message(entry, 'average_latency_exceeds_critical', 'critical')
            elif avg_duration >= default_thresholds['message_duration_warning_ms']:
                register_message(entry, 'average_latency_exceeds_warning', 'warning')

        recent_failure_entries = analytics.get('recentFailures') or []
        for entry in recent_failure_entries:
            register_message(entry, 'recent_failure_observed', 'warning')

        message_findings = list(message_findings_map.values())
        message_findings.sort(key=lambda entry: severity_order.get(entry.get('severity', 'ok'), 0), reverse=True)

        analysis_payload: Dict[str, Any] = {
            'timestamp': time.time(),
            'summary': {
                'proxyCount': summary.get('proxyCount'),
                'totalInvocations': summary.get('totalInvocations'),
                'totalFailures': summary.get('totalFailures'),
                'successRate': summary.get('successRate'),
                'failureRate': summary.get('failureRate'),
                'healthScore': summary.get('healthScore'),
                'healthFlags': summary.get('healthFlags'),
                'trend': summary.get('trend'),
            },
            'historySize': len(_summary_history),
            'proxyFindings': proxy_findings,
            'messageFindings': message_findings,
            'recommendations': recommendations,
        }

        return analysis_payload
    
    # Return the prototypal manager interface
    return {
        'initialize': initialize,
        'shutdown': shutdown,
        'create_proxy': create_proxy,
        'destroy_proxy': destroy_proxy,
        'get_status': get_status,
        'get_dispatch_metrics': get_dispatch_metrics,
        'reset_dispatch_metrics': reset_dispatch_metrics,
        'summarize_dispatch_metrics': summarize_dispatch_metrics,
        'get_summary_history': get_summary_history,
        'clear_summary_history': clear_summary_history,
        'configure_summary_history': configure_summary_history,
        'forward_message': forward_message_to_io,
        'analyze_dispatch_metrics': analyze_dispatch_metrics,
        
        # Internal access for debugging
        '_registry': _proxy_registry
    }


def create_transparent_cache_proxy(cache_manager_dict: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a transparent proxy that delegates cache operations to the appropriate
    L1/L2/L3 cache managers while maintaining prototypal interface semantics.
    
    This enables Io prototypes to transparently interact with the Python-side
    cache systems without knowing they're crossing language boundaries.
    
    Args:
        cache_manager_dict: Dictionary containing L1, L2, L3 cache manager interfaces
        
    Returns:
        dict: Transparent cache proxy interface
    """
    
    def get_from_cache(key: str, cache_level: str = "auto"):
        """
        Retrieve a value from the appropriate cache level.
        
        Args:
            key: Cache key to retrieve
            cache_level: "L1", "L2", "L3", or "auto" for automatic selection
        """
        try:
            if cache_level == "auto":
                # Try L1 first (fastest), then L2, then L3
                for level in ["L1", "L2", "L3"]:
                    if level in cache_manager_dict:
                        result = cache_manager_dict[level]['get'](key)
                        if result is not None:
                            return result
                return None
            else:
                # Direct cache level access
                if cache_level in cache_manager_dict:
                    return cache_manager_dict[cache_level]['get'](key)
                else:
                    raise ValueError(f"Unknown cache level: {cache_level}")
        except Exception as e:
            logger.error(f"Cache get operation failed: {e}")
            return None
    
    def put_in_cache(key: str, value: Any, cache_level: str = "L3"):
        """
        Store a value in the specified cache level.
        
        Args:
            key: Cache key
            value: Value to store
            cache_level: Target cache level ("L1", "L2", or "L3")
        """
        try:
            if cache_level in cache_manager_dict:
                return cache_manager_dict[cache_level]['put'](key, value)
            else:
                raise ValueError(f"Unknown cache level: {cache_level}")
        except Exception as e:
            logger.error(f"Cache put operation failed: {e}")
            return False
    
    def search_similar(query_vector: Any, k: int = 5, threshold: float = 0.0):
        """
        Perform similarity search across the cache hierarchy.
        
        Uses the L1 cache for speed if available, falls back to L2 for comprehensive search.
        """
        try:
            # Try L1 first for speed
            if "L1" in cache_manager_dict:
                result = cache_manager_dict["L1"]['search'](query_vector, k, threshold)
                if result and len(result) >= k:
                    return result
            
            # Fall back to L2 for comprehensive search  
            if "L2" in cache_manager_dict:
                return cache_manager_dict["L2"]['search'](query_vector, k, threshold)
                
            logger.warning("No suitable cache available for similarity search")
            return []
        except Exception as e:
            logger.error(f"Cache search operation failed: {e}")
            return []
    
    def invalidate_key(key: str):
        """Invalidate a key across all cache levels."""
        results = {}
        for level in ["L1", "L2", "L3"]:
            if level in cache_manager_dict:
                try:
                    results[level] = cache_manager_dict[level]['remove'](key)
                except Exception as e:
                    logger.error(f"Failed to invalidate {key} from {level}: {e}")
                    results[level] = False
        return results
    
    return {
        'get': get_from_cache,
        'put': put_in_cache,
        'search': search_similar,
        'invalidate': invalidate_key
    }


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