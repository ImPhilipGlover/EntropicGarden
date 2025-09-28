#!/usr/bin/env python3
"""Regression coverage for L1→L2 promotion handoff within the federated fabric."""

import sys
import unittest
from pathlib import Path
import tempfile

import numpy as np
import time

WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
PYTHON_ROOT = WORKSPACE_ROOT / "libs" / "Telos" / "python"
if str(PYTHON_ROOT) not in sys.path:
    sys.path.insert(0, str(PYTHON_ROOT))

import federated_memory


class TestFederatedMemoryPromotions(unittest.TestCase):
    """Verify that promotion batches land in L2 and update metrics."""

    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory(prefix="telos_promotions_")
        self.base_path = Path(self.temp_dir.name)
        self.fabric = federated_memory.create_federated_memory_fabric()

        config = {
            "l1": {
                "max_size": 16,
                "vector_dim": 8,
                "index_type": "Flat",
                "eviction_threshold": 0.75,
                "promotion_threshold": 2,
                "promotion_requeue_step": 2,
            },
            "l2": {
                "storage_path": str(self.base_path / "l2_cache.h5"),
                "max_size": 64,
                "vector_dim": 8,
            },
            "l3": {
                "storage_path": str(self.base_path / "concepts.fs"),
                "zeo_address": None,
            },
            "coordinator": {
                "enable_l1": True,
                "enable_l2": True,
                "enable_l3": False,
                "workers": 0,
                "l1_config": {
                    "max_size": 16,
                    "vector_dim": 8,
                    "promotion_threshold": 2,
                },
                "l2_config": {
                    "storage_path": str(self.base_path / "l2_cache.h5"),
                    "max_size": 64,
                    "vector_dim": 8,
                },
            },
            "promotions": {
                "enabled": False,
            },
            "bridge": {
                "workers": 0,
            },
        }

        self.assertTrue(self.fabric["initialize"](config))
        self.l1 = self.fabric["get_l1_manager"]()
        self.l2 = self.fabric["get_l2_manager"]()
        self.assertIsNotNone(self.l1)
        self.assertIsNotNone(self.l2)

    def tearDown(self) -> None:
        try:
            self.fabric["shutdown"]()
        finally:
            self.temp_dir.cleanup()

    def test_promotions_flow_into_l2(self) -> None:
        vector = np.linspace(0.1, 0.8, 8, dtype=np.float32)
        oid = "concept/promote"
        inserted = self.l1["put"](oid, vector, {"label": "promote"})
        self.assertTrue(inserted)

        for _ in range(2):
            entry = self.l1["get"](oid)
            self.assertIsNotNone(entry)

        promotion_result = self.fabric["promote_l1_candidates"](None, {"notify_coordinator": False})
        self.assertGreaterEqual(promotion_result.get("promoted", 0), 1)
        self.assertIn(oid, promotion_result.get("promoted_oids", []))
        self.assertIn("failure_reasons", promotion_result)
        self.assertEqual(promotion_result.get("requeued", 0), 0)
        self.assertEqual(promotion_result["failure_reasons"], {})

        promoted_entry = self.l2["get"](oid)
        self.assertIsNotNone(promoted_entry)
        self.assertIn("metadata", promoted_entry)

        stats = self.fabric["get_cache_statistics"]()
        promotion_metrics = stats.get("promotion_metrics", {})
        self.assertGreaterEqual(promotion_metrics.get("total_promoted", 0), 1)

    def test_missing_vector_records_failure(self) -> None:
        drained_without_vector = [{
            "oid": "concept/empty",
            "metadata": {"label": "empty"},
            "stats": {"access_count": 10},
        }]

        result = self.fabric["promote_l1_candidates"](drained_without_vector, None)
        self.assertFalse(result.get("success", True))
        failures = result.get("failures", [])
        self.assertEqual(len(failures), 1)
        self.assertEqual(failures[0].get("oid"), "concept/empty")
        failure_reasons = result.get("failure_reasons", {})
        self.assertGreaterEqual(failure_reasons.get("missing_vector", 0), 1)
        stats = self.fabric["get_cache_statistics"]()
        promotion_metrics = stats.get("promotion_metrics", {})
        self.assertGreaterEqual(promotion_metrics.get("total_failures", 0), 1)

    def test_automatic_promotion_daemon(self) -> None:
        self.fabric["shutdown"]()
        self.temp_dir.cleanup()
        self.temp_dir = tempfile.TemporaryDirectory(prefix="telos_promotions_auto_")
        auto_base = Path(self.temp_dir.name)

        auto_config = {
            "l1": {
                "max_size": 16,
                "vector_dim": 8,
                "promotion_threshold": 2,
                "promotion_requeue_step": 2,
            },
            "l2": {
                "storage_path": str(auto_base / "l2_cache_auto.h5"),
                "max_size": 64,
                "vector_dim": 8,
            },
            "l3": {
                "storage_path": str(auto_base / "concepts_auto.fs"),
                "zeo_address": None,
            },
            "coordinator": {
                "enable_l1": True,
                "enable_l2": True,
                "enable_l3": False,
                "workers": 0,
                "l1_config": {
                    "max_size": 16,
                    "vector_dim": 8,
                    "promotion_threshold": 2,
                },
                "l2_config": {
                    "storage_path": str(auto_base / "l2_cache_auto.h5"),
                    "max_size": 64,
                    "vector_dim": 8,
                },
            },
            "promotions": {
                "enabled": True,
                "interval_seconds": 0.05,
                "batch_limit": 8,
                "include_vectors": True,
                "notify_coordinator": False,
                "idle_sleep_seconds": 0.01,
            },
            "bridge": {
                "workers": 0,
            },
        }

        self.assertTrue(self.fabric["initialize"](auto_config))
        self.l1 = self.fabric["get_l1_manager"]()
        self.l2 = self.fabric["get_l2_manager"]()

        vector = np.linspace(0.2, 0.9, 8, dtype=np.float32)
        oid = "concept/auto-promote"
        inserted = self.l1["put"](oid, vector, {"label": "auto"})
        self.assertTrue(inserted)

        for _ in range(2):
            self.assertIsNotNone(self.l1["get"](oid))

        promotion_result = self.fabric["promote_l1_candidates"](None, {"notify_coordinator": False})

        promoted_entry = self.l2["get"](oid)
        self.assertIsNotNone(promoted_entry)

        stats = self.fabric["get_cache_statistics"]()
        promotion_metrics = stats.get("promotion_metrics", {})
        automatic_metrics = promotion_metrics.get("automatic", {})
        self.assertGreaterEqual(automatic_metrics.get("promoted", 0), 1)
        daemon_status = stats.get("promotion_daemon", {})
        self.assertTrue(daemon_status.get("enabled", False))
        self.assertGreaterEqual(daemon_status.get("metrics", {}).get("automatic", {}).get("promoted", 0), 1)

    def test_coordinator_failure_requeues_candidate(self) -> None:
        vector = np.linspace(0.05, 0.95, 8, dtype=np.float32)
        oid = "concept/coordinator-failure"
        inserted = self.l1["put"](oid, vector, {"label": "failure"})
        self.assertTrue(inserted)

        for _ in range(2):
            self.assertIsNotNone(self.l1["get"](oid))

        simulate_result = self.fabric["simulate_coordinator_failure"]({"stop_after": True})
        self.assertTrue(simulate_result.get("success", False))
        self.assertTrue(simulate_result.get("stopped", False))

        result = self.fabric["promote_l1_candidates"](None, {
            "include_vectors": True,
            "notify_coordinator": True,
        })

        self.assertFalse(result.get("success", True))
        failure_reasons = result.get("failure_reasons", {})
        self.assertGreaterEqual(failure_reasons.get("coordinator_put_failed", 0) + failure_reasons.get("coordinator_put_rejected", 0), 1)
        self.assertGreaterEqual(result.get("requeued", 0), 1)

        stats = self.fabric["get_cache_statistics"]()
        promotion_metrics = stats.get("promotion_metrics", {})
        self.assertGreaterEqual(promotion_metrics.get("requeued_after_failure", 0), 1)
        cache_failures = promotion_metrics.get("failure_reasons", {})
        self.assertGreaterEqual(cache_failures.get("coordinator_put_failed", 0) + cache_failures.get("coordinator_put_rejected", 0), 1)

        pending_queue = self.l1["peek_promotions"]()
        self.assertTrue(any(item.get("oid") == oid for item in pending_queue))


if __name__ == "__main__":
    unittest.main()
