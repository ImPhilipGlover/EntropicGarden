#!/usr/bin/env python3
"""Failure handling tests for the cache coordinator."""

import sys
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

from cache_coordinator import create_cache_coordinator  # noqa: E402


class CacheCoordinatorFailureTests(unittest.TestCase):
    def setUp(self):
        self.coordinator = create_cache_coordinator({
            'enable_l1': False,
            'enable_l2': False,
            'enable_l3': False,
            'auto_restart': True,
        })

    def tearDown(self):
        try:
            self.coordinator['stop']()
        finally:
            self.coordinator = None

    def test_auto_restart_after_worker_crash(self):
        self.assertTrue(self.coordinator['start']())
        self.assertTrue(self.coordinator['is_running']())

        self.assertTrue(self.coordinator['simulate_failure']())
        time.sleep(0.2)
        self.assertFalse(self.coordinator['is_running']())

        self.assertTrue(self.coordinator['invalidate']('missing-oid'))
        self.assertTrue(self.coordinator['is_running']())

    def test_stop_prevents_auto_restart(self):
        self.assertTrue(self.coordinator['start']())
        self.coordinator['stop']()
        self.assertFalse(self.coordinator['is_running']())
        with self.assertRaises(RuntimeError):
            self.coordinator['invalidate']('after-stop')


if __name__ == '__main__':
    unittest.main()
