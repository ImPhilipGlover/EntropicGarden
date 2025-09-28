"""
Utility helpers for `prototypal_bridge.py` extracted to reduce module size.
These are small, stateless functions safe to extract and re-use.
"""
import math
from typing import Any, Dict, Iterable, List

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


# Upper bounds for each latency bucket in milliseconds. The terminal bucket is represented
# by float('inf') to indicate an unbounded upper range.
_LATENCY_BUCKET_BOUNDS = [
    1,
    5,
    10,
    25,
    50,
    100,
    250,
    500,
    1000,
]


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
