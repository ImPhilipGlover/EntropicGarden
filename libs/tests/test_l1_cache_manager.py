#!/usr/bin/env python3
"""Unit tests for the TELOS L1 cache manager."""

import sys
import unittest
from pathlib import Path

import numpy as np
import multiprocessing.shared_memory as shm

sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

from l1_cache_manager import (  # type: ignore
    create_l1_cache_manager,
    load_vector_from_shared_memory,
    store_vector_in_shared_memory,
)


class TestL1CacheManager(unittest.TestCase):
    """Validate core L1 cache operations independent of FAISS availability."""

    def setUp(self):
        self.manager = create_l1_cache_manager(max_size=8, vector_dim=4, index_type="Flat")
        self.vector_a = np.array([0.1, 0.2, 0.3, 0.4], dtype=np.float32)
        self.vector_b = np.array([0.11, 0.18, 0.31, 0.39], dtype=np.float32)

    def test_put_get_and_stats(self):
        self.assertTrue(self.manager["put"]("concept/alpha", self.vector_a, {"label": "alpha"}))
        self.assertTrue(self.manager["put"]("concept/beta", self.vector_b, {"label": "beta"}))

        entry = self.manager["get"]("concept/alpha")
        self.assertIsNotNone(entry)
        self.assertEqual(entry["metadata"]["label"], "alpha")
        np.testing.assert_allclose(entry["vector"], self.vector_a, rtol=1e-5, atol=1e-5)

        stats = self.manager["get_statistics"]()
        self.assertGreaterEqual(stats["current_size"], 2)
        self.assertIn("faiss_index", stats)
        self.assertIn("promotion_threshold", stats)
        self.assertGreaterEqual(stats["promotion_threshold"], 1)
        self.assertEqual(stats["promotion_queue_depth"], 0)

    def test_search_and_remove(self):
        self.manager["put"]("concept/alpha", self.vector_a, {"label": "alpha"})
        self.manager["put"]("concept/beta", self.vector_b, {"label": "beta"})

        results = self.manager["search_similar"](self.vector_a, k=2, threshold=-10.0)
        self.assertTrue(results)
        top = results[0]
        self.assertEqual(top["oid"], "concept/alpha")
        self.assertIn("similarity_score", top)

        removed = self.manager["remove"]("concept/alpha")
        self.assertTrue(removed)
        self.assertIsNone(self.manager["get"]("concept/alpha"))

    def test_shared_memory_helpers(self):
        shm_name = store_vector_in_shared_memory(self.vector_a)
        self.assertIsInstance(shm_name, str)
        restored = load_vector_from_shared_memory(shm_name)
        self.assertIsNotNone(restored)
        np.testing.assert_allclose(restored, self.vector_a, rtol=1e-5, atol=1e-5)
        handle = shm.SharedMemory(name=shm_name)
        handle.close()
        handle.unlink()

    def test_clear_resets_state(self):
        self.manager["put"]("concept/alpha", self.vector_a, {"label": "alpha"})
        self.manager["clear"]()
        stats = self.manager["get_statistics"]()
        self.assertEqual(stats["current_size"], 0)

    def test_promotion_queue_drains_and_requeues(self):
        manager = create_l1_cache_manager(
            max_size=8,
            vector_dim=4,
            promotion_threshold=2,
            promotion_requeue_step=2,
            eviction_batch_percent=0.5,
        )

        self.assertTrue(manager["put"]("concept/gamma", self.vector_a, {"label": "gamma"}))

        for _ in range(2):
            entry = manager["get"]("concept/gamma")
            self.assertIsNotNone(entry)

        drained = manager["drain_promotions"]()
        self.assertEqual(len(drained), 1)
        self.assertEqual(drained[0]["oid"], "concept/gamma")

        for _ in range(2):
            entry = manager["get"]("concept/gamma")
            self.assertIsNotNone(entry)

        peek = manager["peek_promotions"]()
        self.assertEqual(len(peek), 1)
        self.assertEqual(peek[0]["oid"], "concept/gamma")

    def test_eviction_updates_statistics(self):
        manager = create_l1_cache_manager(
            max_size=4,
            vector_dim=4,
            eviction_threshold=0.5,
            eviction_batch_percent=0.5,
            promotion_threshold=10,
        )

        for index in range(6):
            vector = np.random.randn(4).astype(np.float32)
            self.assertTrue(
                manager["put"](f"concept/{index}", vector, {"label": f"concept-{index}"})
            )

        stats = manager["get_statistics"]()
        self.assertGreaterEqual(stats["eviction_cycles"], 1)
        self.assertGreaterEqual(stats["evictions"], 1)
        self.assertLessEqual(stats["current_size"], stats["max_size"])


if __name__ == "__main__":
    unittest.main()
