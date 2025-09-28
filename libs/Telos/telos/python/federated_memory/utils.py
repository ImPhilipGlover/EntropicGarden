"""Utility helpers shared across the federated memory package."""
from __future__ import annotations

import math
import time
from typing import Any, Dict, Iterable, Mapping, MutableMapping, Optional

import numpy as np


def deep_merge(base: MutableMapping[str, Any], overrides: Optional[Mapping[str, Any]]) -> MutableMapping[str, Any]:
    """Recursively merge *overrides* into *base* in-place."""

    if overrides is None:
        return base

    for key, value in overrides.items():
        if isinstance(value, Mapping) and isinstance(base.get(key), MutableMapping):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base


def normalize_vector(vector: Any, *, expected_dim: Optional[int] = None) -> Optional[np.ndarray]:
    """Convert *vector* into a 1-D float32 numpy array."""

    if vector is None:
        return None

    array = np.asarray(vector, dtype=np.float32)
    if array.ndim != 1:
        array = array.reshape(-1)

    if expected_dim is not None and array.shape[0] != expected_dim:
        raise ValueError(f"vector dimension mismatch: expected {expected_dim}, got {array.shape[0]}")

    return array.copy()


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Return the cosine similarity between *a* and *b*."""

    denom = np.linalg.norm(a) * np.linalg.norm(b)
    if denom == 0:
        return 0.0
    return float(np.dot(a, b) / denom)


def summarize_scores(entries: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    """Produce simple summary statistics for similarity scores."""

    scores = [entry.get("score", 0.0) for entry in entries]
    if not scores:
        return {"count": 0, "avg": 0.0, "max": 0.0}

    return {"count": len(scores), "avg": sum(scores) / len(scores), "max": max(scores)}


def epoch_seconds() -> float:
    """Return the current time in seconds since the epoch."""

    return time.time()


def clamp_positive_int(value: Any, fallback: int, minimum: int = 1) -> int:
    """Best-effort conversion of *value* to a bounded positive integer."""

    try:
        result = int(value)
    except Exception:
        return max(minimum, fallback)
    return max(minimum, result)


def rolling_average(samples: Iterable[float]) -> Optional[float]:
    """Compute the average of *samples* or ``None`` when empty."""

    samples = list(samples)
    if not samples:
        return None
    return sum(samples) / len(samples)
