#!/usr/bin/env python3
"""Tests for the TELOS transactional outbox and poller."""

import sys
import time
import unittest
import tempfile
import shutil
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

from transactional_outbox import (  # type: ignore[import]  # noqa: E402
    create_transactional_outbox,
    create_transactional_outbox_poller,
)


def _wait_for(condition_fn, timeout=5.0, interval=0.05):
    deadline = time.time() + timeout
    while time.time() < deadline:
        if condition_fn():
            return True
        time.sleep(interval)
    return False


class TransactionalOutboxTest(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.mkdtemp(prefix="telos_outbox_test_")
        storage_path = str(Path(self.tempdir) / "outbox.fs")
        self.processed = []
        self.dead_letters = []

        self.outbox = create_transactional_outbox({
            'storage_path': storage_path,
            'retry_limit': 1,
            'batch_size': 2,
            'visibility_timeout': 0.5,
        })

        def handler(entry):
            payload = entry.get('payload', {})
            if payload.get('mode') == 'fail':
                raise RuntimeError('intentional failure')
            self.processed.append(entry['id'])

        def dlq_handler(entry):
            self.dead_letters.append(entry['id'])

        self.poller = create_transactional_outbox_poller(
            self.outbox,
            handler,
            dlq_handler,
            {
                'poll_interval': 0.1,
                'batch_size': 2,
            }
        )

    def tearDown(self):
        self.poller['stop'](timeout=2.0)
        self.outbox['shutdown']()
        shutil.rmtree(self.tempdir, ignore_errors=True)

    def test_outbox_success_and_dlq_flow(self):
        self.poller['start']()

        ok_id = self.outbox['enqueue']({'mode': 'ok'}, {'source': 'test'})
        fail_id = self.outbox['enqueue']({'mode': 'fail'}, {'source': 'test'})

        processed_ready = _wait_for(lambda: ok_id in self.processed, timeout=5.0)
        dlq_ready = _wait_for(lambda: fail_id in self.dead_letters, timeout=5.0)

        self.assertTrue(processed_ready, "Successful entry should be processed")
        self.assertTrue(dlq_ready, "Failing entry should propagate to DLQ")

        stats = self.outbox['get_statistics']()
        self.assertEqual(stats['processed'], 1)
        self.assertEqual(stats['dlq'], 1)

    def test_reap_timeouts_returns_expired_messages(self):
        entry_id = self.outbox['enqueue']({'mode': 'timeout'}, None)
        reserved = self.outbox['reserve_pending'](1)
        self.assertEqual(len(reserved), 1)
        self.assertEqual(reserved[0]['id'], entry_id)

        time.sleep(0.6)
        expired = self.outbox['reap_timeouts']()
        self.assertIn(entry_id, expired, "Expired entry should be re-queued")

        stats = self.outbox['get_statistics']()
        self.assertEqual(stats['pending'], 1)
        self.assertEqual(stats['inflight'], 0)

    def test_purge_processed_removes_entries(self):
        self.poller['start']()
        success_id = self.outbox['enqueue']({'mode': 'ok'}, {'source': 'purge_test'})

        processed_ready = _wait_for(lambda: success_id in self.processed, timeout=5.0)
        self.assertTrue(processed_ready, "Entry should reach processed queue before purge")

        self.poller['stop'](timeout=2.0)

        removed = self.outbox['purge_processed'](max_entries=10)
        self.assertGreaterEqual(removed, 1, "purge_processed should remove processed entries")

        stats = self.outbox['get_statistics']()
        self.assertEqual(stats['processed'], 0, "Processed queue should be empty after purge")

        self.poller['start']()


if __name__ == '__main__':
    unittest.main()
