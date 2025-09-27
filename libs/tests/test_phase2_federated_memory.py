#!/usr/bin/env python3
"""Lightweight validation of the Phase 2 federated memory fabric.

The goal of this script is to exercise the prototypal federated memory
interface without introducing any class-based scaffolding.  It focuses on the
core happy-path behaviours required by the architectural mandates:

* Configuration merging and initialization
* Concept creation / retrieval routed through ZODB (L3)
* Vector propagation into the cache hierarchy (L2 in this minimal setup)
* Similarity search via the fabric façade
* Cache statistics and invalidation helpers
* Graceful shutdown with shared resource cleanup

The script is intentionally written in a prototypal style (factory functions,
closures, and dictionaries) to remain compliant with the TELOS coding
conventions.  It is executed directly by CTest; success is reported via the exit
code and a short textual log.
"""

import json
import os
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Tuple
import time

import numpy as np

# ---------------------------------------------------------------------------
# Workspace bootstrap
# ---------------------------------------------------------------------------

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
PYTHON_ROOT = WORKSPACE_ROOT / "libs" / "Telos" / "python"
if str(PYTHON_ROOT) not in sys.path:
    sys.path.insert(0, str(PYTHON_ROOT))

import federated_memory


# ---------------------------------------------------------------------------
# Helper utilities (prototypal style)
# ---------------------------------------------------------------------------

def _record(name: str, passed: bool, details: str = "") -> Dict[str, Any]:
    return {
        "name": name,
        "passed": passed,
        "details": details,
    }


def _fabric_config(base_dir: Path) -> Dict[str, Any]:
    l3_path = base_dir / "concepts.fs"
    l2_dir = base_dir / "l2_cache"
    return {
        "l1": {  # keep values but disable via coordinator flags
            "max_size": 128,
            "vector_dim": 64,
            "index_type": "Flat",
        },
        "l2": {
            "storage_path": str(l2_dir),
            "max_size": 2048,
            "vector_dim": 64,
        },
        "l3": {
            "storage_path": str(l3_path),
            "zeo_address": None,
        },
        "coordinator": {
            "enable_l1": False,  # avoid FAISS dependency during CI
            "enable_l2": True,
            "enable_l3": True,
            "workers": 1,
            "l2_config": {
                "storage_path": str(l2_dir),
                "max_size": 2048,
                "vector_dim": 64,
            },
            "l3_config": {
                "storage_path": str(l3_path),
                "zeo_address": None,
            },
        },
        "bridge": {
            "workers": 1,
        },
    }


def _concept_payload(vector: np.ndarray) -> Dict[str, Any]:
    return {
        "name": "phase2_test_concept",
        "metadata": {"tags": ["integration", "phase2"]},
        "geometric_embedding": vector.astype(np.float32).tolist(),
    }


def _ensure_directory(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def _format_stats(stats: Dict[str, Any]) -> str:
    safe = {key: value for key, value in stats.items() if not key.startswith("_")}
    return json.dumps(safe, indent=2, default=str)


# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------

def run_phase2_fabric_validation() -> Tuple[bool, List[Dict[str, Any]]]:
    results: List[Dict[str, Any]] = []
    rng = np.random.default_rng(seed=20250926)
    temp_dir = tempfile.TemporaryDirectory(prefix="telos_phase2_")
    base_path = Path(temp_dir.name)
    fabric = federated_memory.create_federated_memory_fabric()

    try:
        config = _fabric_config(base_path)
        _ensure_directory(Path(config["l3"]["storage_path"]))
        _ensure_directory(Path(config["l2"]["storage_path"]))

        init_ok = fabric["initialize"](config)
        results.append(_record("initialize", init_ok))
        if not init_ok:
            return False, results

        status = fabric["get_status"]()
        status_ok = bool(status.get("initialized")) and "L3" in status.get("components", {})
        results.append(_record("status", status_ok, "fabric initialized" if status_ok else str(status)))

        vector = rng.random(config["l2"]["vector_dim"], dtype=np.float32)
        concept_id = fabric["create_concept"](_concept_payload(vector))
        create_ok = concept_id is not None
        results.append(_record("create_concept", create_ok, str(concept_id)))
        if not create_ok:
            return False, results

        retrieved = fabric["get_concept"](concept_id)
        retrieve_ok = bool(retrieved) and retrieved.get("oid") == concept_id
        results.append(_record("get_concept", retrieve_ok))

        updated = fabric["update_concept"](concept_id, {"metadata": {"tags": ["integration", "updated"]}})
        results.append(_record("update_concept", bool(updated)))

        # Allow the transactional outbox poller to process the update
        time.sleep(1.0)

        search_hits = fabric["semantic_search"](vector, k=1, threshold=0.0)
        search_ok = bool(search_hits) and search_hits[0].get("oid") == concept_id
        results.append(_record("semantic_search", search_ok, f"hits={len(search_hits)}"))

        cache_stats = fabric["get_cache_statistics"]()
        stats_ok = "L2" in cache_stats
        results.append(_record("cache_statistics", stats_ok, _format_stats(cache_stats)))

        validation = fabric["validate"]()
        validation_ok = bool(validation.get("valid"))
        results.append(_record("validate", validation_ok))

        invalidation = fabric["invalidate_concept"](concept_id)
        invalidate_ok = bool(invalidation)
        results.append(_record("invalidate", invalidate_ok, json.dumps(invalidation)))

        shutdown_ok = fabric["shutdown"]()
        results.append(_record("shutdown", bool(shutdown_ok)))

        all_passed = all(item["passed"] for item in results)
        return all_passed, results

    finally:
        # Ensure cleanup even if initialization failed part-way
        try:
            fabric["shutdown"]()
        except Exception:
            pass
        temp_dir.cleanup()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    success, test_results = run_phase2_fabric_validation()
    for entry in test_results:
        prefix = "PASS" if entry["passed"] else "FAIL"
        line = f"[{prefix}] {entry['name']}"
        if entry["details"]:
            line += f" :: {entry['details']}"
        print(line)
    sys.exit(0 if success else 1)