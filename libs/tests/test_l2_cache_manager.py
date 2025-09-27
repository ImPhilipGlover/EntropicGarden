#!/usr/bin/env python3
"""Unit tests for the TELOS L2 cache manager."""

import os
import sys
import tempfile
import unittest
from pathlib import Path

import numpy as np

# Add the TELOS Python modules to the path
sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

from l2_cache_manager import create_l2_cache_manager, DISKANN_AVAILABLE


class TestL2CacheManager(unittest.TestCase):
    """Validate basic L2 cache behaviours including DiskANN-backed search."""

    def setUp(self):
        fd, self._storage_path = tempfile.mkstemp(suffix=".h5")
        os.close(fd)
        self.cache = create_l2_cache_manager(
            storage_path=self._storage_path,
            max_size=128,
            vector_dim=16,
        )

    def tearDown(self):
        try:
            self.cache['clear']()
            self.cache['close']()
        finally:
            if os.path.exists(self._storage_path):
                try:
                    os.unlink(self._storage_path)
                except OSError:
                    pass

    def test_put_get_remove_and_search(self):
        """Exercise the core cache APIs and ensure similarity search works."""
        base_vector = np.random.randn(16).astype(np.float32)
        neighbor_vector = base_vector + (np.random.randn(16) * 0.01).astype(np.float32)
        distant_vector = np.random.randn(16).astype(np.float32)

        self.assertTrue(self.cache['put']('concept:a', base_vector, {'label': 'base'}))
        self.assertTrue(self.cache['put']('concept:b', neighbor_vector, {'label': 'neighbor'}))
        self.assertTrue(self.cache['put']('concept:c', distant_vector, {'label': 'distant'}))

        entry = self.cache['get']('concept:a')
        self.assertIsNotNone(entry)
        self.assertEqual(entry['metadata']['label'], 'base')
        self.assertTrue(np.allclose(entry['vector'], base_vector, atol=1e-6))

        search_results = self.cache['search_similar'](base_vector, k=2, threshold=0.0)
        self.assertGreaterEqual(len(search_results), 1)
        top_match_ids = {result['oid'] for result in search_results}
        self.assertIn('concept:a', top_match_ids)

        removed = self.cache['remove']('concept:c')
        self.assertTrue(removed)
        self.assertIsNone(self.cache['get']('concept:c'))

        stats = self.cache['get_statistics']()
        self.assertGreaterEqual(stats['current_size'], 2)
        self.assertEqual(stats['disk_index']['diskann_enabled'], DISKANN_AVAILABLE)


if __name__ == "__main__":
    unittest.main()
