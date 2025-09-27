#!/usr/bin/env python3
"""Smoke tests for the TELOS ZODB manager."""

import sys
import tempfile
import shutil
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

from zodb_manager import create_zodb_manager  # noqa: E402


class ZODBManagerSmokeTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.mkdtemp(prefix="telos_zodb_test_")
        self.storage_path = str(Path(self.tempdir) / "concepts.fs")

    def tearDown(self):
        shutil.rmtree(self.tempdir, ignore_errors=True)

    def test_read_write_lifecycle(self):
        manager = create_zodb_manager(storage_path=self.storage_path)
        try:
            concept_payload = {
                'label': 'Lifecycle Concept',
                'metadata': {'source': 'test_read_write'},
                'confidence': 0.9,
            }
            oid = manager['store_concept'](concept_payload)
            self.assertIsInstance(oid, str)

            loaded = manager['load_concept'](oid)
            self.assertIsNotNone(loaded)
            self.assertEqual(loaded['label'], 'Lifecycle Concept')

            updated = manager['update_concept'](oid, {'label': 'Updated Concept'})
            self.assertTrue(updated)
            reloaded = manager['load_concept'](oid)
            self.assertEqual(reloaded['label'], 'Updated Concept')

            stats = manager['get_statistics']()
            self.assertGreaterEqual(stats['total_concepts'], 1)

            removed = manager['delete_concept'](oid)
            self.assertTrue(removed)
            self.assertIsNone(manager['load_concept'](oid))
        finally:
            manager['close']()

    def test_read_only_guardrails(self):
        writer = create_zodb_manager(storage_path=self.storage_path)
        concept_payload = {
            'label': 'Read Only Concept',
            'metadata': {'source': 'test_read_only'},
        }
        oid = writer['store_concept'](concept_payload)
        writer['close']()

        read_only_manager = create_zodb_manager(storage_path=self.storage_path, read_only=True)
        try:
            loaded = read_only_manager['load_concept'](oid)
            self.assertEqual(loaded['label'], 'Read Only Concept')

            with self.assertRaises(RuntimeError):
                read_only_manager['store_concept']({'label': 'Should Fail'})

            with self.assertRaises(RuntimeError):
                read_only_manager['update_concept'](oid, {'label': 'Should Fail'})

            with self.assertRaises(RuntimeError):
                read_only_manager['delete_concept'](oid)
        finally:
            read_only_manager['close']()

    def test_relationship_persistence(self):
        manager = create_zodb_manager(storage_path=self.storage_path)
        try:
            related_payload = {
                'label': 'Relationship Target',
                'confidence': 0.77,
            }
            related_oid = manager['store_concept'](related_payload)

            concept_payload = {
                'label': 'Relationship Source',
                'relationships': {
                    'is_a': [related_oid],
                    'associated_with': [related_oid],
                },
            }
            source_oid = manager['store_concept'](concept_payload)

            loaded = manager['load_concept'](source_oid)
            self.assertIn(related_oid, loaded['relationships']['is_a'])
            self.assertIn(related_oid, loaded['relationships']['associated_with'])

            manager['update_concept'](source_oid, {
                'relationships': {
                    'is_a': [],
                    'associated_with': [],
                }
            })

            cleared = manager['load_concept'](source_oid)
            self.assertEqual(cleared['relationships']['is_a'], [])
            self.assertEqual(cleared['relationships']['associated_with'], [])
        finally:
            manager['close']()


if __name__ == '__main__':
    unittest.main()
