#!/usr/bin/env python3
"""
TELOS Performance Benchmarking Framework

This module provides comprehensive performance benchmarking capabilities
for the TELOS neuro-symbolic cognitive architecture. It measures end-to-end
latency, throughput, and resource utilization across all architectural layers.

Key metrics measured:
- L3 write throughput (ZODB persistence)
- Replication lag (Transactional outbox)
- Query latency percentiles (Federated memory)
- LLM transduction response times
- HRC cognitive cycle duration
- Memory usage and GC pressure
"""

from __future__ import annotations

import gc
import json
import psutil
import statistics
import time
import tracemalloc
from contextlib import contextmanager
from typing import Any, Dict, List, Optional, Callable, Iterator
from dataclasses import dataclass, field
from pathlib import Path

# Import UvmObject for prototypal patterns
from .uvm_object import create_uvm_object

# Optional OpenTelemetry integration
try:
    from . import opentelemetry_bridge as otel_bridge
except ImportError:
    otel_bridge = None


def create_benchmark_result(
    operation: str,
    iterations: int,
    total_time: float,
    mean_latency: float,
    median_latency: float,
    p95_latency: float,
    p99_latency: float,
    min_latency: float,
    max_latency: float,
    latencies: List[float] = None,
    memory_delta: Optional[int] = None,
    gc_collections: Optional[List[int]] = None,
    throughput: Optional[float] = None,
    errors: int = 0,
    timestamp: float = None
) -> Any:
    """Create a benchmark result using UvmObject factory."""
    if latencies is None:
        latencies = []
    if timestamp is None:
        timestamp = time.time()
    
    return create_uvm_object({
        'operation': operation,
        'iterations': iterations,
        'total_time': total_time,
        'mean_latency': mean_latency,
        'median_latency': median_latency,
        'p95_latency': p95_latency,
        'p99_latency': p99_latency,
        'min_latency': min_latency,
        'max_latency': max_latency,
        'latencies': latencies,
        'memory_delta': memory_delta,
        'gc_collections': gc_collections,
        'throughput': throughput,
        'errors': errors,
        'timestamp': timestamp,
    })


def create_system_metrics(
    cpu_percent: float,
    memory_percent: float,
    memory_used_mb: float,
    disk_io_read_mb: float,
    disk_io_write_mb: float,
    network_bytes_sent: int,
    network_bytes_recv: int,
    timestamp: float = None
) -> Any:
    """Create system metrics using UvmObject factory."""
    if timestamp is None:
        timestamp = time.time()
    
    return create_uvm_object({
        'cpu_percent': cpu_percent,
        'memory_percent': memory_percent,
        'memory_used_mb': memory_used_mb,
        'disk_io_read_mb': disk_io_read_mb,
        'disk_io_write_mb': disk_io_write_mb,
        'network_bytes_sent': network_bytes_sent,
        'network_bytes_recv': network_bytes_recv,
        'timestamp': timestamp,
    })


def create_performance_benchmark_prototype(enable_tracing: bool = True, enable_memory_tracking: bool = True) -> Any:
    """Create a performance benchmark using UvmObject factory for pure prototypal design."""
    
    # Initialize optional dependencies
    tracer = None
    meter = None
    if otel_bridge and otel_bridge.is_enabled():
        state = otel_bridge.get_state()
        tracer = state.get('tracer')
        meter = state.get('meter')
    
    # Create the benchmark object with all methods
    benchmark = create_uvm_object({
        'enable_tracing': enable_tracing,
        'enable_memory_tracking': enable_memory_tracking,
        'results': [],  # List of benchmark result objects
        'system_metrics': [],  # List of system metrics objects
        'tracer': tracer,
        'meter': meter,
        '_memory_delta': None,
        '_peak_memory': None,
    })
    
    # Add methods to the benchmark object
    benchmark['_trace_context'] = lambda operation: _create_trace_context(benchmark, operation)
    benchmark['_memory_tracking'] = lambda: _create_memory_tracking(benchmark)
    benchmark['_capture_system_metrics'] = lambda: _capture_system_metrics_prototype(benchmark)
    benchmark['benchmark_operation'] = lambda operation, func, iterations=100, warmup_iterations=10, capture_system_metrics=False: _benchmark_operation(benchmark, operation, func, iterations, warmup_iterations, capture_system_metrics)
    benchmark['benchmark_llm_transduction'] = lambda transducer, test_prompts: _benchmark_llm_transduction(benchmark, transducer, test_prompts)
    benchmark['benchmark_zodb_operations'] = lambda concept_repo, test_concepts: _benchmark_zodb_operations(benchmark, concept_repo, test_concepts)
    benchmark['benchmark_federated_memory'] = lambda memory_system, test_queries: _benchmark_federated_memory(benchmark, memory_system, test_queries)
    benchmark['generate_report'] = lambda output_path=None: _generate_report(benchmark, output_path)
    benchmark['print_summary'] = lambda: _print_summary(benchmark)
    
    return benchmark


# Helper functions for the prototypal benchmark object
def _create_trace_context(benchmark, operation: str):
    """Context manager for OpenTelemetry tracing."""
    from contextlib import contextmanager
    
    @contextmanager
    def trace_context():
        tracer = benchmark['tracer']
        if not tracer:
            yield
            return

        # Note: This would need proper span management in a real implementation
        yield
    
    return trace_context()


def _create_memory_tracking(benchmark):
    """Context manager for memory usage tracking."""
    from contextlib import contextmanager
    
    @contextmanager
    def memory_tracking():
        if not benchmark['enable_memory_tracking']:
            yield
            return

        tracemalloc.start()
        initial_memory = tracemalloc.get_traced_memory()[0]

        try:
            yield
        finally:
            current, peak = tracemalloc.get_traced_memory()
            tracemalloc.stop()
            benchmark['_memory_delta'] = current - initial_memory
            benchmark['_peak_memory'] = peak
    
    return memory_tracking()


def _capture_system_metrics_prototype(benchmark) -> Any:
    """Capture current system resource utilization."""
    process = psutil.Process()
    cpu_percent = process.cpu_percent()
    memory_info = process.memory_info()
    memory_percent = process.memory_percent()

    # Disk I/O (simplified - would need more sophisticated tracking for accuracy)
    disk_io = psutil.disk_io_counters()
    net_io = psutil.net_io_counters()

    return create_system_metrics(
        cpu_percent=cpu_percent,
        memory_percent=memory_percent,
        memory_used_mb=memory_info.rss / (1024 * 1024),
        disk_io_read_mb=disk_io.read_bytes / (1024 * 1024) if disk_io else 0,
        disk_io_write_mb=disk_io.write_bytes / (1024 * 1024) if disk_io else 0,
        network_bytes_sent=net_io.bytes_sent if net_io else 0,
        network_bytes_recv=net_io.bytes_recv if net_io else 0,
    )


def _benchmark_operation(benchmark, operation: str, func: Callable[[], Any], iterations: int = 100, warmup_iterations: int = 10, capture_system_metrics: bool = False) -> Any:
    """Benchmark a single operation with comprehensive metrics."""
    
    # Warmup phase
    for _ in range(warmup_iterations):
        try:
            func()
        except Exception:
            pass  # Ignore warmup errors

    # Garbage collection before benchmark
    gc.collect()
    initial_gc_counts = list(gc.get_count())

    latencies = []
    errors = 0

    # Capture initial system state
    if capture_system_metrics:
        initial_metrics = benchmark['_capture_system_metrics']()

    start_time = time.perf_counter()

    with benchmark['_memory_tracking']():
        for _ in range(iterations):
            iteration_start = time.perf_counter()

            try:
                func()
                iteration_end = time.perf_counter()
                latencies.append(iteration_end - iteration_start)
            except Exception:
                errors += 1
                latencies.append(time.perf_counter() - iteration_start)

    total_time = time.perf_counter() - start_time

    # Calculate statistics
    if latencies:
        mean_latency = statistics.mean(latencies)
        median_latency = statistics.median(latencies)
        p95_latency = statistics.quantiles(latencies, n=20)[18]  # 95th percentile
        p99_latency = statistics.quantiles(latencies, n=100)[98]  # 99th percentile
        min_latency = min(latencies)
        max_latency = max(latencies)
    else:
        mean_latency = median_latency = p95_latency = p99_latency = min_latency = max_latency = 0.0

    # Calculate throughput
    throughput = iterations / total_time if total_time > 0 else 0

    # Capture final system state
    if capture_system_metrics:
        final_metrics = benchmark['_capture_system_metrics']()
        benchmark['system_metrics'].extend([initial_metrics, final_metrics])

    # GC statistics
    final_gc_counts = list(gc.get_count())
    gc_collections = [final - initial for final, initial in zip(final_gc_counts, initial_gc_counts)]

    result = create_benchmark_result(
        operation=operation,
        iterations=iterations,
        total_time=total_time,
        mean_latency=mean_latency,
        median_latency=median_latency,
        p95_latency=p95_latency,
        p99_latency=p99_latency,
        min_latency=min_latency,
        max_latency=max_latency,
        latencies=latencies,
        memory_delta=benchmark['_memory_delta'],
        gc_collections=gc_collections,
        throughput=throughput,
        errors=errors,
    )

    benchmark['results'].append(result)
    return result


def _benchmark_llm_transduction(benchmark, transducer, test_prompts: List[str]) -> Any:
    """Specialized benchmark for LLM transduction operations."""
    def llm_operation():
        prompt = test_prompts[len(test_prompts) % len(test_prompts)]
        request = {
            "method": "generate",
            "prompt": prompt,
            "model": "test"
        }
        transducer.transduce(request)

    return benchmark['benchmark_operation'](
        "llm_transduction",
        llm_operation,
        iterations=min(50, len(test_prompts)),
        warmup_iterations=5
    )


def _benchmark_zodb_operations(benchmark, concept_repo, test_concepts: List[Dict]) -> Any:
    """Benchmark ZODB persistence operations."""
    def zodb_operation():
        concept = test_concepts[len(test_concepts) % len(test_concepts)]
        # Create a test concept
        test_concept = create_uvm_object(concept)
        concept_repo.save(test_concept)

    return benchmark['benchmark_operation'](
        "zodb_persistence",
        zodb_operation,
        iterations=min(100, len(test_concepts)),
        warmup_iterations=10
    )


def _benchmark_federated_memory(benchmark, memory_system, test_queries: List[str]) -> Any:
    """Benchmark federated memory query operations."""
    def memory_operation():
        query = test_queries[len(test_queries) % len(test_queries)]
        memory_system.query(query)

    return benchmark['benchmark_operation'](
        "federated_memory_query",
        memory_operation,
        iterations=min(200, len(test_queries)),
        warmup_iterations=20
    )


def _generate_report(benchmark, output_path: Optional[Path] = None) -> Dict[str, Any]:
    """Generate a comprehensive benchmark report."""
    report = {
        "timestamp": time.time(),
        "benchmark_results": [dict(result) for result in benchmark['results']],
        "system_metrics": [dict(metric) for metric in benchmark['system_metrics']],
        "summary": {
            "total_operations": len(benchmark['results']),
            "total_iterations": sum(r['iterations'] for r in benchmark['results']),
            "total_errors": sum(r['errors'] for r in benchmark['results']),
        }
    }

    if output_path:
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)

    return report


def _print_summary(benchmark) -> None:
    """Print a human-readable benchmark summary."""
    print("=== TELOS Performance Benchmark Results ===")
    print(f"Total benchmark operations: {len(benchmark['results'])}")
    print()

    for result in benchmark['results']:
        print(f"Operation: {result['operation']}")
        print(f"  Iterations: {result['iterations']}")
        print(f"  Total time: {result['total_time']:.3f}s")
        print(f"  Throughput: {result['throughput']:.2f} ops/sec")
        print(f"  Mean latency: {result['mean_latency']*1000:.2f}ms")
        print(f"  Median latency: {result['median_latency']*1000:.2f}ms")
        print(f"  P95 latency: {result['p95_latency']*1000:.2f}ms")
        print(f"  P99 latency: {result['p99_latency']*1000:.2f}ms")
        if result['memory_delta']:
            print(f"  Memory delta: {result['memory_delta'] / 1024:.1f} KB")
        if result['errors']:
            print(f"  Errors: {result['errors']}")
        print()


# Factory function for prototypal design (backwards compatibility)
def create_performance_benchmark(enable_tracing: bool = True, enable_memory_tracking: bool = True) -> Dict[str, Any]:
    """Factory function returning a prototypal performance benchmark dictionary."""
    benchmark = create_performance_benchmark_prototype(enable_tracing, enable_memory_tracking)
    
    # Return dictionary interface for backwards compatibility
    return {
        "benchmark_operation": benchmark['benchmark_operation'],
        "benchmark_llm_transduction": benchmark['benchmark_llm_transduction'],
        "benchmark_zodb_operations": benchmark['benchmark_zodb_operations'],
        "benchmark_federated_memory": benchmark['benchmark_federated_memory'],
        "generate_report": benchmark['generate_report'],
        "print_summary": benchmark['print_summary'],
        "results": benchmark['results'],
        "system_metrics": benchmark['system_metrics'],
    }