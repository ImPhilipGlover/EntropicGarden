#!/usr/bin/env python3
"""Unit tests for the federated memory L2 telemetry aggregator."""

import copy
import sys
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

# Ensure TELOS python modules are discoverable
sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

import federated_memory  # type: ignore


def _make_stub_l2_manager(statistics_blob):
    """Create a prototypal stub mimicking the L2 manager telemetry surface."""
    call_tracker = {'count': 0}

    def get_telemetry():
        call_tracker['count'] += 1
        return {
            'search_metrics': statistics_blob.get('search_metrics', {}),
            'eviction_history': statistics_blob.get('eviction_history', []),
            'diskann_metrics': statistics_blob.get('disk_index', {}).get('metrics', {}).get('diskann', {}),
            'search_engine_metrics': statistics_blob.get('disk_index', {}).get('metrics', {}).get('search', {}),
        }

    return (
        {
            'put': lambda *args, **kwargs: True,
            'get': lambda *args, **kwargs: None,
            'remove': lambda *args, **kwargs: True,
            'search_similar': lambda *args, **kwargs: [],
            'get_statistics': lambda: copy.deepcopy(statistics_blob),
            'get_telemetry': get_telemetry,
            'clear': lambda: None,
            'close': lambda: None,
            'get_all_oids': lambda: set(),
        },
        call_tracker,
    )


def _make_stub_coordinator(config):
    """Return a lightweight cache coordinator prototype for tests."""
    return {
        'start': lambda: True,
        'stop': lambda: None,
        'get_statistics': lambda: {'events_processed': 0, 'workers': config.get('workers', 0)},
        'is_running': lambda: True,
    }


STUB_L1_MANAGER = {
    'clear': lambda: None,
    'get_statistics': lambda: {},
    'put': lambda *args, **kwargs: True,
    'search_similar': lambda *args, **kwargs: [],
    'get': lambda *args, **kwargs: None,
}

STUB_L3_MANAGER = {
    'close': lambda: None,
    'store_concept': lambda payload: 'concept/test',
    'load_concept': lambda oid: None,
    'update_concept': lambda oid, updates: True,
    'get_statistics': lambda: {},
}

STUB_BRIDGE_MANAGER = {
    'initialize': lambda config: True,
    'shutdown': lambda: None,
    'get_status': lambda: {'state': 'stubbed'},
}


@contextmanager
def stubbed_fabric(statistics_blob):
    """Yield a federated memory fabric wired to the supplied L2 statistics."""
    stub_l2, telemetry_calls = _make_stub_l2_manager(statistics_blob)

    with tempfile.TemporaryDirectory() as tmp_dir:
        storage_path = str(Path(tmp_dir) / "l2-cache.h5")

        with (
            mock.patch("federated_memory.create_l2_cache_manager", side_effect=lambda *args, **kwargs: stub_l2),
            mock.patch("federated_memory.create_cache_coordinator", side_effect=lambda config: _make_stub_coordinator(config)),
            mock.patch("federated_memory.create_prototypal_bridge_manager", return_value=STUB_BRIDGE_MANAGER),
            mock.patch("federated_memory.create_l1_cache_manager", return_value=STUB_L1_MANAGER),
            mock.patch("federated_memory.create_zodb_manager", return_value=STUB_L3_MANAGER),
        ):
            fabric = federated_memory.create_federated_memory_fabric()
            init_ok = fabric['initialize']({
                'coordinator': {
                    'enable_l1': False,
                    'enable_l2': True,
                    'enable_l3': False,
                    'workers': 0,
                },
                'l2': {
                    'storage_path': storage_path,
                    'max_size': 32,
                    'vector_dim': 8,
                },
                'bridge': {
                    'workers': 0,
                },
            })
            if not init_ok:
                raise AssertionError("Federated memory fabric failed to initialize with stubs")

            try:
                yield fabric, telemetry_calls
            finally:
                fabric['shutdown']()


class TestL2Telemetry(unittest.TestCase):
    """Validate that get_l2_telemetry surfaces the expected signal."""

    def test_get_l2_telemetry_with_diskann_metrics(self):
        diskann_stats = {
            'search_metrics': {
                'queries': 5,
                'avg_latency_ms': 2.5,
                'last_latency_ms': 2.8,
                'avg_similarity': 0.72,
                'max_similarity': 0.91,
                'min_similarity': 0.43,
                'last_similarity_avg': 0.65,
                'last_result_count': 4,
                'total_results_returned': 12,
                'last_query_timestamp': '2025-10-14T12:34:56Z',
                'diskann_usage': {
                    'attempts': 4,
                    'successes': 3,
                    'failures': 1,
                },
            },
            'eviction_history': [
                {'oid': 'concept/alpha', 'reason': 'lru', 'timestamp': '2025-10-14T09:00:00Z'},
            ],
            'disk_index': {
                'metrics': {
                    'diskann': {
                        'attempts': 5,
                        'successes': 4,
                        'failures': 1,
                        'last_error': None,
                        'last_duration_ms': 1.7,
                        'last_used': '2025-10-14T12:34:56Z',
                    },
                    'search': {
                        'queries': 5,
                        'results_returned': 12,
                        'avg_results_per_query': 2.4,
                        'avg_similarity': 0.72,
                        'max_similarity': 0.91,
                        'min_similarity': 0.43,
                        'last_result_count': 4,
                        'last_similarity_avg': 0.65,
                    },
                },
            },
        }

        with stubbed_fabric(diskann_stats) as (fabric, telemetry_calls):
            telemetry = fabric['get_l2_telemetry']()
            self.assertNotIn('error', telemetry)
            self.assertEqual(telemetry['search_metrics']['queries'], 5)
            self.assertEqual(telemetry['eviction_history'], diskann_stats['eviction_history'])
            self.assertEqual(telemetry['diskann_metrics']['successes'], 4)
            self.assertEqual(
                telemetry['search_engine_metrics']['max_similarity'],
                diskann_stats['disk_index']['metrics']['search']['max_similarity'],
            )
            self.assertEqual(telemetry_calls['count'], 1)

            telemetry_round_two = fabric['get_l2_telemetry']()
            self.assertEqual(telemetry_round_two['diskann_metrics']['attempts'], 5)
            self.assertEqual(telemetry_calls['count'], 2)

    def test_get_l2_telemetry_without_diskann_metrics(self):
        fallback_stats = {
            'search_metrics': {
                'queries': 0,
                'avg_latency_ms': 0.0,
                'last_latency_ms': None,
                'avg_similarity': 0.0,
                'max_similarity': 0.0,
                'min_similarity': None,
                'last_similarity_avg': None,
                'last_result_count': 0,
                'total_results_returned': 0,
                'last_query_timestamp': None,
                'diskann_usage': {},
            },
            'eviction_history': [],
            'disk_index': {},
        }

        with stubbed_fabric(fallback_stats) as (fabric, telemetry_calls):
            telemetry = fabric['get_l2_telemetry']()
            self.assertNotIn('error', telemetry)
            self.assertEqual(telemetry['diskann_metrics'], {})
            self.assertEqual(telemetry['search_engine_metrics'], {})
            self.assertEqual(telemetry['search_metrics']['queries'], 0)
            self.assertEqual(telemetry_calls['count'], 1)


if __name__ == '__main__':
    unittest.main()
