"""Configuration defaults for the federated memory fabric."""
from __future__ import annotations

from copy import deepcopy
from typing import Any, Dict

DEFAULT_CONFIG: Dict[str, Any] = {
    "l1": {
        "max_size": 2048,
        "vector_dim": 64,
        "promotion_threshold": 1,
    },
    "l2": {
        "max_size": 16384,
        "vector_dim": 64,
    },
    "l3": {
        "storage_path": "telos_concepts.fs",
    },
    "coordinator": {
        "enable_l1": True,
        "enable_l2": True,
        "enable_l3": True,
        "workers": 0,
    },
    "promotions": {
        "enabled": False,
        "interval_seconds": 1.0,
        "batch_limit": 64,
        "include_vectors": True,
        "notify_coordinator": True,
        "idle_sleep_seconds": 0.25,
        "requeue_on_failure": True,
    },
    "bridge": {
        "workers": 0,
    },
    "outbox": {
        "enabled": False,
        "storage_path": "telos_outbox.fs",
        "batch_size": 8,
        "visibility_timeout": 0.5,
    },
    "outbox_poller": {
        "enabled": False,
        "interval_seconds": 0.5,
        "batch_limit": 8,
    },
}


def clone_default_config() -> Dict[str, Any]:
    """Return a deep copy of the canonical default configuration."""

    return deepcopy(DEFAULT_CONFIG)
