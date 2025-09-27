#!/usr/bin/env python3
"""
Basic Tests for TELOS Synaptic Bridge Architecture

This test suite validates the foundational components of the TELOS system
including the Python worker pool, shared memory management, and basic
FFI contract compliance.
"""

import sys
import unittest
import tempfile
import multiprocessing
import os
from typing import Optional
from pathlib import Path

# Add the TELOS module roots to the path for namespace package resolution
_TEL0S_LIB_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(_TEL0S_LIB_ROOT))
sys.path.insert(0, str(_TEL0S_LIB_ROOT / "Telos" / "python"))

try:
    from Telos.python.workers import (
        initialize_workers,
        shutdown_workers,
        submit_worker_task,
        SharedMemoryHandle,
        TelosWorkerError,
    )
    WORKERS_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Could not import workers module: {e}")
    WORKERS_AVAILABLE = False
    get_memory_fabric = None

try:
    from Telos.python.federated_memory import get_memory_fabric  # type: ignore
    FEDERATED_MEMORY_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Could not import federated_memory module: {e}")
    get_memory_fabric = None
    FEDERATED_MEMORY_AVAILABLE = False

try:
    from Telos.python import prototypal_bridge  # type: ignore
    PROTOTYPAL_BRIDGE_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Could not import prototypal_bridge module: {e}")
    prototypal_bridge = None  # type: ignore
    PROTOTYPAL_BRIDGE_AVAILABLE = False


class TestWorkerSystem(unittest.TestCase):
    """Test the Python worker pool system."""
    
    def setUp(self):
        """Set up test fixtures."""
        if not WORKERS_AVAILABLE:
            self.skipTest("Workers module not available")
    
    def tearDown(self):
        """Clean up after tests."""
        if WORKERS_AVAILABLE:
            try:
                shutdown_workers()
            except:
                pass  # Ignore errors during cleanup
    
    def test_worker_initialization(self):
        """Test that workers can be initialized and shut down."""
        result = initialize_workers(max_workers=2)
        self.assertTrue(result, "Worker initialization should succeed")
        
        shutdown_workers()
    
    def test_ping_request(self):
        """Test basic connectivity with a ping request."""
        self.assertTrue(initialize_workers(max_workers=1))
        
        result = submit_worker_task({
            'operation': 'ping',
            'message': 'test ping'
        })
        
        self.assertTrue(result['success'])
        self.assertIn('worker_id', result)
        self.assertEqual(result['message'], 'pong')
    
    def test_vsa_batch_stub(self):
        """Test VSA batch operation stub."""
        self.assertTrue(initialize_workers(max_workers=1))
        
        result = submit_worker_task({
            'operation': 'vsa_batch',
            'operation_name': 'bind',
            'batch_size': 5
        })
        
        self.assertTrue(result['success'])
        self.assertEqual(result['operation_name'], 'bind')
        self.assertEqual(result['batch_size'], 5)
    
    def test_ann_search_stub(self):
        """Test ANN search operation stub."""
        self.assertTrue(initialize_workers(max_workers=1))
        
        result = submit_worker_task({
            'operation': 'ann_search',
            'k': 10,
            'similarity_threshold': 0.8
        })
        
        self.assertTrue(result['success'])
        self.assertEqual(result['k'], 10)
        self.assertEqual(result['similarity_threshold'], 0.8)
    
    def test_vector_operations_l1_cache(self):
        """Exercise L1 cache operations through the vector handler."""

        self.assertTrue(initialize_workers(max_workers=1))

        configure = submit_worker_task({
            'operation': 'vector_operations',
            'action': 'configure',
            'config': {
                'max_size': 16,
                'vector_dim': 4,
                'eviction_threshold': 0.75,
                'index_type': 'Flat',
            },
        })
        self.assertTrue(configure['success'])
        self.assertEqual(configure['config']['vector_dim'], 4)

        base_vector = [0.1, 0.2, 0.3, 0.4]
        put_result = submit_worker_task({
            'operation': 'vector_operations',
            'action': 'put',
            'config': {
                'oid': 'concept/alpha',
                'vector': base_vector,
                'metadata': {'label': 'alpha'},
            },
        })
        self.assertTrue(put_result['success'])

        get_result = submit_worker_task({
            'operation': 'vector_operations',
            'action': 'get',
            'config': {
                'oid': 'concept/alpha',
                'include_vector': True,
            },
        })
        self.assertTrue(get_result['success'])
        self.assertEqual(get_result['metadata']['label'], 'alpha')
        self.assertEqual(len(get_result['vector']), len(base_vector))

        search_result = submit_worker_task({
            'operation': 'vector_operations',
            'action': 'search',
            'config': {
                'query_vector': base_vector,
                'k': 1,
            },
        })
        self.assertTrue(search_result['success'])
        self.assertGreaterEqual(search_result['count'], 1)
        top_result = search_result['results'][0]
        self.assertEqual(top_result['oid'], 'concept/alpha')

        stats = submit_worker_task({
            'operation': 'vector_operations',
            'action': 'stats',
        })
        self.assertTrue(stats['success'])
        self.assertGreaterEqual(stats['statistics']['current_size'], 1)
    
    def test_unknown_operation(self):
        """Test handling of unknown operations."""
        self.assertTrue(initialize_workers(max_workers=1))
        
        result = submit_worker_task({
            'operation': 'unknown_operation'
        })
        
        self.assertFalse(result['success'])
        self.assertIn('error', result)
        self.assertIn('Unknown operation', result['error'])
    
    def test_multiple_workers(self):
        """Test that multiple workers can handle requests concurrently."""
        self.assertTrue(initialize_workers(max_workers=3))
        
        import concurrent.futures
        
        # Submit multiple ping requests concurrently
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            futures = []
            for i in range(5):
                future = executor.submit(submit_worker_task, {
                    'operation': 'ping',
                    'message': f'ping {i}'
                })
                futures.append(future)
            
            # Collect results
            results = []
            for future in concurrent.futures.as_completed(futures):
                result = future.result()
                results.append(result)
        
        # All requests should succeed
        self.assertEqual(len(results), 5)
        for result in results:
            self.assertTrue(result['success'])
            self.assertEqual(result['message'], 'pong')

    def test_llm_transducer_simulation(self):
        """LLM transducer handler should return simulated structured output with metrics."""

        previous_flag = os.environ.get('TELOS_LLM_SIMULATION')
        os.environ['TELOS_LLM_SIMULATION'] = '1'

        def _restore_env(value: Optional[str]) -> None:
            if value is None:
                os.environ.pop('TELOS_LLM_SIMULATION', None)
            else:
                os.environ['TELOS_LLM_SIMULATION'] = value

        self.addCleanup(_restore_env, previous_flag)

        self.assertTrue(initialize_workers(max_workers=1))

        request_payload = {
            'operation': 'llm_transducer',
            'mode': 'transduceTextToSchema',
            'prompt': 'Extract structured purchase details from the provided sentence.',
            'text_input': 'User intends to buy 3 apples at a unit price of $5.',
            'output_schema': {
                'type': 'object',
                'properties': {
                    'intent': {'type': 'string'},
                    'quantity': {'type': 'number'},
                    'item': {'type': 'string'},
                    'unit_price': {'type': 'number'},
                },
            },
            'transducer_config': {'simulate': True},
            'include_metrics': True,
        }

        result = submit_worker_task(request_payload)

        self.assertTrue(result['success'])
        self.assertTrue(result.get('simulated'))
        self.assertIn('data', result)
        self.assertIn('metrics', result)
        self.assertEqual(result['mode'], 'transduce_text_to_schema')
        self.assertIn('intent', result['data'])


class TestSharedMemoryHandle(unittest.TestCase):
    """Test the SharedMemoryHandle data structure."""
    
    def test_shared_memory_handle_creation(self):
        """Test creation of shared memory handles."""
        if not WORKERS_AVAILABLE:
            self.skipTest("Workers module not available")
        
        handle = SharedMemoryHandle(name="test_block", offset=100, size=1024)
        self.assertEqual(handle.name, "test_block")
        self.assertEqual(handle.offset, 100)
        self.assertEqual(handle.size, 1024)
    
    def test_shared_memory_handle_defaults(self):
        """Test default values for shared memory handles."""
        if not WORKERS_AVAILABLE:
            self.skipTest("Workers module not available")
        
        handle = SharedMemoryHandle(name="test_block")
        self.assertEqual(handle.name, "test_block")
        self.assertEqual(handle.offset, 0)
        self.assertEqual(handle.size, 0)


class TestBuildSystem(unittest.TestCase):
    """Test that the build system components are in place."""
    
    def test_synaptic_bridge_header_exists(self):
        """Test that the C ABI header file exists."""
        header_path = Path(__file__).parent.parent / "Telos" / "source" / "synaptic_bridge.h"
        self.assertTrue(header_path.exists(), f"Header file should exist at {header_path}")
    
    def test_cmake_file_exists(self):
        """Test that the CMakeLists.txt file exists."""
        cmake_path = Path(__file__).parent.parent.parent / "CMakeLists.txt"
        self.assertTrue(cmake_path.exists(), f"CMakeLists.txt should exist at {cmake_path}")
    
    def test_python_build_script_exists(self):
        """Test that the Python build script exists."""
        build_script = Path(__file__).parent.parent / "Telos" / "python" / "build_extension.py"
        self.assertTrue(build_script.exists(), f"Build script should exist at {build_script}")
    
    def test_concept_prototype_exists(self):
        """Test that the Concept prototype file exists."""
        concept_file = Path(__file__).parent.parent / "Telos" / "io" / "Concept.io"
        self.assertTrue(concept_file.exists(), f"Concept prototype should exist at {concept_file}")


class TestConceptPrototype(unittest.TestCase):
    """Test the Concept prototype by parsing its basic structure."""
    
    def test_concept_file_structure(self):
        """Test that the Concept.io file has expected structure."""
        concept_file = Path(__file__).parent.parent / "Telos" / "io" / "Concept.io"
        
        if not concept_file.exists():
            self.skipTest("Concept.io file not found")
        
        content = concept_file.read_text()
        
        # Check for key structural elements
        self.assertIn("Concept := Object clone do(", content)
        self.assertIn("oid := nil", content)
        self.assertIn("symbolicHypervectorName := nil", content)
        self.assertIn("geometricEmbeddingName := nil", content)
        self.assertIn("markChanged := method(", content)
        self.assertIn("init := method(", content)
        
        # Check for relationship lists
        self.assertIn("isA := list()", content)
        self.assertIn("partOf := list()", content)
        self.assertIn("abstractionOf := list()", content)
        self.assertIn("instanceOf := list()", content)

class TestFederatedMemoryOutbox(unittest.TestCase):
    """Exercise transactional outbox hooks within the federated memory fabric."""

    def setUp(self):
        if not FEDERATED_MEMORY_AVAILABLE:
            self.skipTest("Federated memory module unavailable")
        self.fabric = get_memory_fabric()
        try:
            self.fabric['shutdown']()
        except Exception:
            pass

    def tearDown(self):
        if not FEDERATED_MEMORY_AVAILABLE:
            return
        try:
            self.fabric['shutdown']()
        except Exception:
            pass

    def test_outbox_rehydrates_l1_cache(self):
        """Queued outbox events should repopulate the L1 cache when processed manually."""

        with tempfile.TemporaryDirectory() as tempdir:
            base_path = Path(tempdir)
            config = {
                'l1': {
                    'max_size': 8,
                    'vector_dim': 4,
                },
                'l2': {
                    'storage_path': str(base_path / 'l2'),
                    'max_size': 16,
                    'vector_dim': 4,
                },
                'l3': {
                    'storage_path': str(base_path / 'concepts.fs'),
                    'zeo_address': None,
                },
                'coordinator': {
                    'enable_l1': True,
                    'enable_l2': False,
                    'enable_l3': True,
                },
                'promotions': {
                    'enabled': False,
                },
                'outbox': {
                    'enabled': True,
                    'storage_path': str(base_path / 'outbox.fs'),
                    'batch_size': 4,
                    'visibility_timeout': 0.25,
                },
                'outbox_poller': {
                    'enabled': False,
                },
            }

            self.assertTrue(self.fabric['initialize'](config))

            try:
                concept_payload = {
                    'name': 'outbox_concept',
                    'metadata': {'label': 'outbox'},
                    'geometric_embedding': [0.1, 0.2, 0.3, 0.4],
                }

                concept_id = self.fabric['create_concept'](concept_payload)
                self.assertIsNotNone(concept_id)

                l1_manager = self.fabric['get_l1_manager']()
                self.assertIsNotNone(l1_manager)
                l1_manager['remove'](concept_id)
                self.assertIsNone(l1_manager['get'](concept_id))

                batch_result = self.fabric['process_outbox_batch']({'limit': 4})
                self.assertTrue(batch_result['success'])
                self.assertGreaterEqual(len(batch_result['processed']), 1)
                self.assertEqual(batch_result['failures'], [])

                restored_entry = l1_manager['get'](concept_id)
                self.assertIsNotNone(restored_entry)
                self.assertIsNotNone(restored_entry['vector'])
                self.assertEqual(len(restored_entry['vector']), 4)
                self.assertEqual(restored_entry['metadata'].get('label'), 'outbox')

                outbox_status = self.fabric['get_outbox_status']()
                metrics = outbox_status.get('metrics', {})
                self.assertGreaterEqual(metrics.get('acknowledged', 0), 1)
                self.assertGreaterEqual(metrics.get('processed', 0), 1)
            finally:
                self.fabric['shutdown']()

    def test_outbox_analytics_report(self):
        """Enhanced analytics should surface latency, rates, and health signals."""

        with tempfile.TemporaryDirectory() as tempdir:
            base_path = Path(tempdir)
            config = {
                'l1': {
                    'max_size': 8,
                    'vector_dim': 4,
                },
                'l2': {
                    'storage_path': str(base_path / 'l2'),
                    'max_size': 16,
                    'vector_dim': 4,
                },
                'l3': {
                    'storage_path': str(base_path / 'concepts.fs'),
                    'zeo_address': None,
                },
                'coordinator': {
                    'enable_l1': True,
                    'enable_l2': False,
                    'enable_l3': True,
                },
                'promotions': {
                    'enabled': False,
                },
                'outbox': {
                    'enabled': True,
                    'storage_path': str(base_path / 'outbox.fs'),
                    'batch_size': 4,
                    'visibility_timeout': 0.25,
                },
                'outbox_poller': {
                    'enabled': False,
                },
            }

            self.assertTrue(self.fabric['initialize'](config))

            try:
                concept_payload = {
                    'name': 'analytics_concept',
                    'metadata': {'label': 'analytics'},
                    'geometric_embedding': [0.5, 0.4, 0.3, 0.2],
                }

                concept_id = self.fabric['create_concept'](concept_payload)
                self.assertIsNotNone(concept_id)

                batch_result = self.fabric['process_outbox_batch']({'limit': 4})
                self.assertTrue(batch_result['success'])
                self.assertGreaterEqual(len(batch_result['processed']), 1)

                analytics = self.fabric['get_outbox_analytics']()
                self.assertIn('summary', analytics)
                self.assertGreaterEqual(analytics['summary']['processed'], 1)
                self.assertEqual(analytics['summary']['failures'], 0)

                self.assertIn('rates', analytics)
                self.assertIsNotNone(analytics['rates']['success_rate'])
                self.assertLessEqual(analytics['rates']['failure_rate'] or 0, 0.05)

                latency_summary = analytics['latency']['summary']
                self.assertGreaterEqual(latency_summary.get('samples', 0), 1)

                actions = analytics['actions']
                self.assertGreaterEqual(actions.get('unique_actions', 0), 1)
                top_action = actions['distribution'][0]
                self.assertEqual(top_action['label'], 'concept_created')

                health = analytics['health']
                self.assertIn(health['status'], {'healthy', 'degraded'})

                backlog = analytics['backlog']
                self.assertEqual(backlog.get('pending'), 0)
                self.assertEqual(backlog.get('inflight'), 0)

                analytics_with_samples = self.fabric['get_outbox_analytics']({'include_latency_samples': True})
                samples_payload = analytics_with_samples['latency'].get('samples_ms')
                self.assertIsNotNone(samples_payload)
                self.assertGreaterEqual(len(samples_payload), 1)

                snapshot = analytics_with_samples.get('status_snapshot')
                self.assertIn('metrics', snapshot)
            finally:
                self.fabric['shutdown']()


class TestPrototypalBridgeMetrics(unittest.TestCase):
    """Validate aggregated metrics emitted by the prototypal bridge."""

    def test_summary_includes_latency_histogram(self):
        if not PROTOTYPAL_BRIDGE_AVAILABLE:
            self.skipTest("Prototypal bridge module unavailable")

        metrics_map = {
            'proxyA': {
                'invocations': 3,
                'failures': 1,
                'averageDurationMs': 12.0,
                'successRate': 2.0 / 3.0,
                'failureRate': 1.0 / 3.0,
                'lastTimestamp': 101.0,
                'recent': [
                    {'message': 'ping', 'success': True, 'durationMs': 5.0, 'timestamp': 99.0},
                    {'message': 'ping', 'success': False, 'durationMs': 15.0, 'timestamp': 100.0},
                ],
                'latencyBuckets': {
                    '<=5ms': 1,
                    '<=25ms': 1,
                },
                'minDurationMs': 5.0,
                'maxDurationMs': 15.0,
                'messageStats': {
                    'ping': {
                        'invocations': 3,
                        'failures': 1,
                        'cumulativeDurationMs': 30.0,
                        'averageDurationMs': 10.0,
                        'lastDurationMs': 15.0,
                        'lastTimestamp': 100.0,
                        'lastOutcome': 'failure',
                        'lastError': 'timeout',
                        'minDurationMs': 5.0,
                        'maxDurationMs': 15.0,
                        'successRate': 2.0 / 3.0,
                        'failureRate': 1.0 / 3.0,
                        'successStreak': 0,
                    },
                },
            },
            'proxyB': {
                'invocations': 2,
                'failures': 0,
                'averageDurationMs': 24.0,
                'successRate': 1.0,
                'failureRate': 0.0,
                'lastTimestamp': 102.0,
                'recent': [
                    {'message': 'lookup', 'success': True, 'durationMs': 8.0, 'timestamp': 101.0},
                    {'message': 'lookup', 'success': True, 'durationMs': 40.0, 'timestamp': 102.0},
                ],
                'latencyBuckets': {
                    '<=10ms': 1,
                    '>1000ms': 1,
                },
                'minDurationMs': 8.0,
                'maxDurationMs': 40.0,
                'messageStats': {
                    'lookup': {
                        'invocations': 2,
                        'failures': 0,
                        'cumulativeDurationMs': 48.0,
                        'averageDurationMs': 24.0,
                        'lastDurationMs': 40.0,
                        'lastTimestamp': 102.0,
                        'lastOutcome': 'success',
                        'lastError': None,
                        'minDurationMs': 8.0,
                        'maxDurationMs': 40.0,
                        'successRate': 1.0,
                        'failureRate': 0.0,
                        'successStreak': 2,
                    },
                },
            },
        }

        manager = prototypal_bridge._global_bridge_manager  # type: ignore[attr-defined]
        registry = manager['_registry']

        original_registry = {pid: dict(state) for pid, state in registry.items()}

        def restore_registry():
            registry.clear()
            for pid, state in original_registry.items():
                registry[pid] = state

        self.addCleanup(restore_registry)

        registry.clear()
        for proxy_id, metrics in metrics_map.items():
            registry[proxy_id] = {
                'io_master_handle': f"handle:{proxy_id}",
                'metrics': dict(metrics),
            }

        summary = prototypal_bridge.summarize_dispatch_metrics()

        self.assertEqual(summary['proxyCount'], 2)
        self.assertEqual(summary['totalInvocations'], 5)
        self.assertEqual(summary['totalFailures'], 1)

        self.assertEqual(summary['latencyBucketTotal'], 4)
        latency_buckets = summary['latencyBuckets']
        self.assertEqual(latency_buckets['<=5ms'], 1)
        self.assertEqual(latency_buckets['<=25ms'], 1)
        self.assertEqual(latency_buckets['<=10ms'], 1)
        self.assertEqual(latency_buckets['>1000ms'], 1)

        distribution = summary['latencyBucketDistribution']
        self.assertAlmostEqual(distribution['<=5ms'], 0.25, places=4)
        self.assertAlmostEqual(distribution['<=25ms'], 0.25, places=4)
        self.assertAlmostEqual(distribution['<=10ms'], 0.25, places=4)
        self.assertAlmostEqual(distribution['>1000ms'], 0.25, places=4)

        self.assertEqual(summary['minDurationMs'], 5.0)
        self.assertEqual(summary['maxDurationMs'], 40.0)
        self.assertEqual(summary['recentSampleCount'], 4)
        self.assertEqual(summary['slowestRecent'][0]['durationMs'], 40.0)

        percentiles = summary['durationPercentiles']
        self.assertAlmostEqual(percentiles['p50'], 11.5, places=2)
        self.assertAlmostEqual(percentiles['p90'], 32.5, places=2)
        self.assertAlmostEqual(percentiles['p95'], 36.25, places=2)

        # Ensure per-proxy snapshots remain available for downstream dashboards
        self.assertIn('perProxy', summary)
        self.assertIn('proxyA', summary['perProxy'])

        # Message-level analytics should surface aggregated rollups and leaderboards
        message_rollup = summary['messageRollup']
        self.assertIn('ping', message_rollup)
        self.assertIn('lookup', message_rollup)
        ping_rollup = message_rollup['ping']
        self.assertEqual(ping_rollup['invocations'], 3)
        self.assertEqual(ping_rollup['failures'], 1)
        self.assertAlmostEqual(ping_rollup['averageDurationMs'], 10.0)
        self.assertEqual(ping_rollup['sourceCount'], 1)
        self.assertEqual(ping_rollup['sources'][0]['proxyId'], 'proxyA')

        analytics = summary['messageAnalytics']
        failure_messages = [entry['message'] for entry in analytics['topFailureRate']]
        self.assertIn('ping', failure_messages)
        recent_failures = [entry['message'] for entry in analytics['recentFailures']]
        self.assertIn('ping', recent_failures)
        average_messages = [entry['message'] for entry in analytics['topAverageDuration']]
        self.assertIn('lookup', average_messages)

        # Top messages should now provide recent and aggregate counts
        self.assertTrue(all('recentCount' in entry for entry in summary['topMessages']))
        self.assertTrue(all('totalInvocations' in entry for entry in summary['topMessages']))

        self.assertIn('healthScore', summary)
        self.assertGreaterEqual(summary['healthScore'], 0.0)
        self.assertLessEqual(summary['healthScore'], 100.0)
        self.assertIn('healthFlags', summary)
        self.assertIn('perProxyHealth', summary)
        proxy_health = summary['perProxyHealth']
        self.assertIn('proxyA', proxy_health)
        self.assertIn('proxyB', proxy_health)
        self.assertGreaterEqual(
            proxy_health['proxyB']['score'], proxy_health['proxyA']['score']
        )
        self.assertGreater(
            proxy_health['proxyA']['recentFailures'],
            proxy_health['proxyB']['recentFailures'],
        )
        self.assertIn('trend', summary)
        self.assertIn('failureRate', summary['trend'])
        self.assertIsNone(summary['trend']['failureRate']['baseline'])
        self.assertIsNone(summary['trend']['failureRate']['delta'])

        analysis = prototypal_bridge.analyze_dispatch_metrics()
        self.assertIsInstance(analysis, dict)
        proxy_findings = analysis.get('proxyFindings')
        self.assertIsInstance(proxy_findings, list)
        self.assertGreaterEqual(len(proxy_findings), 2)

        findings_by_proxy = {
            item.get('proxyId'): item
            for item in proxy_findings
            if isinstance(item, dict)
        }
        self.assertIn('proxyA', findings_by_proxy)
        self.assertIn('proxyB', findings_by_proxy)

        proxy_a_finding = findings_by_proxy['proxyA']
        proxy_b_finding = findings_by_proxy['proxyB']

        self.assertEqual(proxy_a_finding['severity'], 'critical')
        self.assertEqual(proxy_b_finding['severity'], 'ok')

        a_reasons = proxy_a_finding.get('reasons', [])
        self.assertTrue(any('failure_rate' in reason for reason in a_reasons))
        a_actions = proxy_a_finding.get('suggestedActions', [])
        self.assertIn('inspect_proxy', a_actions)

        analysis_summary = analysis.get('summary')
        self.assertIsInstance(analysis_summary, dict)
        self.assertEqual(analysis_summary.get('proxyCount'), summary.get('proxyCount'))


def run_basic_tests():
    """Run a basic subset of tests for quick validation."""
    print("=" * 60)
    print("TELOS Basic Architecture Tests")
    print("=" * 60)
    
    # Create a test suite with just the essential tests
    suite = unittest.TestSuite()
    
    # Add build system tests (these should always pass)
    suite.addTest(TestBuildSystem('test_synaptic_bridge_header_exists'))
    suite.addTest(TestBuildSystem('test_cmake_file_exists'))
    suite.addTest(TestBuildSystem('test_python_build_script_exists'))
    suite.addTest(TestBuildSystem('test_concept_prototype_exists'))
    
    # Add concept prototype test
    suite.addTest(TestConceptPrototype('test_concept_file_structure'))
    
    # Add worker tests if available
    if WORKERS_AVAILABLE:
        suite.addTest(TestWorkerSystem('test_worker_initialization'))
        suite.addTest(TestWorkerSystem('test_ping_request'))
    
    # Run the tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    if result.wasSuccessful():
        print("\n✓ All basic tests passed!")
        return True
    else:
        print(f"\n✗ {len(result.failures)} test(s) failed, {len(result.errors)} error(s)")
        return False


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--basic":
        success = run_basic_tests()
        sys.exit(0 if success else 1)
    else:
        unittest.main()