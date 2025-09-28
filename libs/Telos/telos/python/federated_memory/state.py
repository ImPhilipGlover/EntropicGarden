"""Shared state management for the federated memory fabric."""
from __future__ import annotations

from copy import deepcopy
from threading import Event, Lock
from typing import Any, Dict

from .config import DEFAULT_CONFIG


PROMOTION_METRIC_TEMPLATE: Dict[str, Any] = {
    "total_attempts": 0,
    "total_promoted": 0,
    "total_failures": 0,
    "requeued_after_failure": 0,
    "failure_reasons": {},
    "last_batch": {
        "count": 0,
        "promoted": 0,
        "failures": 0,
        "promoted_oids": [],
        "failure_reasons": {},
        "requeued": 0,
    },
    "automatic": {
        "cycles": 0,
        "attempts": 0,
        "promoted": 0,
        "failures": 0,
        "requeued": 0,
        "last_result": None,
        "last_timestamp": None,
    },
    "manual": {
        "attempts": 0,
        "promoted": 0,
        "failures": 0,
        "requeued": 0,
        "last_result": None,
        "last_timestamp": None,
    },
}


def create_state() -> Dict[str, Any]:
    """Instantiate a new fabric state dictionary with default values."""

    promotion_metrics = deepcopy(PROMOTION_METRIC_TEMPLATE)
    promotion_config = deepcopy(DEFAULT_CONFIG["promotions"])

    return {
        "config": deepcopy(DEFAULT_CONFIG),
        "initialized": False,
        "components": {
            "l1": None,
            "l2": None,
            "l3": None,
            "coordinator": None,
            "bridge": None,
        },
        "concept_store": {},
        "locks": {
            "concepts": Lock(),
            "promotion": Lock(),
            "outbox": Lock(),
        },
        "outbox": {
            "entries": [],
            "metrics": {
                "enqueued": 0,
                "processed": 0,
                "acknowledged": 0,
                "failures": 0,
            },
            "latency_samples": [],
            "last_action": None,
            "last_processed_at": None,
            "config": deepcopy(DEFAULT_CONFIG.get("outbox", {})),
        },
        "promotion": {
            "config": promotion_config,
            "metrics": promotion_metrics,
            "pending": [],
            "daemon": {
                "thread": None,
                "stop_event": Event(),
            },
            "forced_failure": False,
        },
    }


def reset_state(state: Dict[str, Any]) -> None:
    """Return *state* to its post-construction defaults."""

    state["config"] = deepcopy(DEFAULT_CONFIG)
    state["initialized"] = False
    state["components"] = {key: None for key in state["components"]}
    state["concept_store"].clear()
    state["locks"]["outbox"] = Lock()
    state["outbox"]["entries"].clear()
    state["outbox"]["metrics"].clear()
    state["outbox"]["metrics"].update({
        "enqueued": 0,
        "processed": 0,
        "acknowledged": 0,
        "failures": 0,
    })
    state["outbox"]["latency_samples"] = []
    state["outbox"]["last_action"] = None
    state["outbox"]["last_processed_at"] = None
    state["outbox"]["config"] = deepcopy(DEFAULT_CONFIG.get("outbox", {}))
    state["promotion"]["config"] = deepcopy(DEFAULT_CONFIG["promotions"])
    state["promotion"]["metrics"].clear()
    state["promotion"]["metrics"].update(deepcopy(PROMOTION_METRIC_TEMPLATE))
    state["promotion"]["pending"].clear()
    state["promotion"]["forced_failure"] = False
    daemon = state["promotion"]["daemon"]
    daemon["stop_event"].set()
    daemon["thread"] = None
    daemon["stop_event"] = Event()
