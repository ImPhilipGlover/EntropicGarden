#!/usr/bin/env python3
"""Tests for OpenTelemetry integration within the TELOS Python substrate."""

import importlib
import json
import os
import sys
import tempfile
import time
import unittest
from concurrent import futures
from pathlib import Path
from types import ModuleType
from unittest import mock

# Ensure TELOS Python modules are importable
sys.path.insert(0, str(Path(__file__).parent.parent / "Telos" / "python"))

import opentelemetry_bridge  # type: ignore  # noqa: E402
import workers  # type: ignore  # noqa: E402
from telemetry_store import summarize_conflict_replay  # type: ignore  # noqa: E402

try:  # pragma: no cover - optional dependency import
    import grpc  # type: ignore[import]
    from opentelemetry.proto.collector.metrics.v1 import metrics_service_pb2  # type: ignore[import]
    from opentelemetry.proto.collector.metrics.v1 import metrics_service_pb2_grpc  # type: ignore[import]
    from opentelemetry.proto.collector.trace.v1 import trace_service_pb2  # type: ignore[import]
    from opentelemetry.proto.collector.trace.v1 import trace_service_pb2_grpc  # type: ignore[import]
except Exception:  # pragma: no cover - optional dependency import
    grpc = None  # type: ignore
    trace_service_pb2 = None  # type: ignore
    trace_service_pb2_grpc = None  # type: ignore
    metrics_service_pb2 = None  # type: ignore
    metrics_service_pb2_grpc = None  # type: ignore


if (
    grpc is not None
    and trace_service_pb2 is not None
    and trace_service_pb2_grpc is not None
    and metrics_service_pb2 is not None
    and metrics_service_pb2_grpc is not None
):

    class _InMemoryOtelCollector(
        trace_service_pb2_grpc.TraceServiceServicer,
        metrics_service_pb2_grpc.MetricsServiceServicer,
    ):
        """Simple OTLP gRPC collector capturing span and metric exports."""

        def __init__(self):
            self.spans = []
            self.metrics = []

        def Export(self, request, context):  # type: ignore[override]
            if isinstance(request, trace_service_pb2.ExportTraceServiceRequest):
                self.spans.append(request)
                return trace_service_pb2.ExportTraceServiceResponse()
            if isinstance(request, metrics_service_pb2.ExportMetricsServiceRequest):
                self.metrics.append(request)
                return metrics_service_pb2.ExportMetricsServiceResponse()
            return metrics_service_pb2.ExportMetricsServiceResponse()


else:  # pragma: no cover - optional dependency import

    _InMemoryOtelCollector = None  # type: ignore


class TestOpenTelemetryBridge(unittest.TestCase):
    """Validate behaviour of the OpenTelemetry bridge helpers."""

    def tearDown(self):
        """Reset module state after every test to avoid cross-test contamination."""
        importlib.reload(opentelemetry_bridge)

    def test_configure_handles_missing_sdk_gracefully(self):
        """Configuration should surface a clear error when the SDK is unavailable."""

        original_import = __import__

        def fake_import(name, globals=None, locals=None, fromlist=(), level=0):
            if name.startswith("opentelemetry"):
                raise ImportError("simulated-missing-sdk")
            return original_import(name, globals, locals, fromlist, level)

        with mock.patch("builtins.__import__", side_effect=fake_import):
            importlib.reload(opentelemetry_bridge)
            state = opentelemetry_bridge.configure_opentelemetry()
            self.assertFalse(state.get("enabled"), "Bridge should stay disabled when SDK is missing")
            self.assertIn("OpenTelemetry SDK unavailable", state.get("error", ""))

    def test_collector_config_prefers_environment_over_file(self):
        """Environment variables should override file-based collector settings."""

        file_payload = {
            "endpoint": "grpc://file-endpoint:4317",
            "headers": "Authorization=Bearer file-token",
            "insecure": "false",
        }

        with tempfile.NamedTemporaryFile("w", delete=False) as handle:
            json.dump(file_payload, handle)
            settings_path = handle.name

        env_payload = {
            "TELOS_OTEL_SETTINGS_PATH": settings_path,
            "TELOS_OTEL_EXPORTER_ENDPOINT": "grpc://env-endpoint:4317",
            "TELOS_OTEL_EXPORTER_HEADERS": "Authorization=Bearer env-token,Custom=Value",
            "TELOS_OTEL_EXPORTER_INSECURE": "true",
        }

        try:
            with mock.patch.dict(os.environ, env_payload, clear=False):
                config = opentelemetry_bridge.load_collector_config()

            self.assertEqual(config.get("endpoint"), "grpc://env-endpoint:4317")
            self.assertEqual(
                config.get("headers"),
                {"Authorization": "Bearer env-token", "Custom": "Value"},
            )
            self.assertTrue(config.get("insecure"))
        finally:
            os.unlink(settings_path)

    def test_prepare_exporter_kwargs_normalises_values(self):
        """Exporter kwargs should be normalised to the expected types."""

        config = {
            "endpoint": "grpc://collector:4317",
            "headers": [
                ("Authorization", "Bearer token"),
                ("x-extra", 42),
            ],
            "insecure": "yes",
        }

        kwargs = opentelemetry_bridge._prepare_exporter_kwargs(config)
        self.assertEqual(kwargs.get("endpoint"), "grpc://collector:4317")
        self.assertEqual(
            kwargs.get("headers"),
            {"Authorization": "Bearer token", "x-extra": "42"},
        )
        self.assertTrue(kwargs.get("insecure"))

    def test_force_flush_and_shutdown_delegate_to_providers(self):
        """Force flush and shutdown should call into configured providers."""

        def build_stub_modules():
            root = ModuleType("opentelemetry")
            root.__path__ = []  # type: ignore[attr-defined]

            metrics_mod = ModuleType("opentelemetry.metrics")
            trace_mod = ModuleType("opentelemetry.trace")
            exporter_metric_mod = ModuleType("opentelemetry.exporter.otlp.proto.grpc.metric_exporter")
            exporter_trace_mod = ModuleType("opentelemetry.exporter.otlp.proto.grpc.trace_exporter")
            sdk_metrics_mod = ModuleType("opentelemetry.sdk.metrics")
            sdk_metrics_export_mod = ModuleType("opentelemetry.sdk.metrics.export")
            sdk_resources_mod = ModuleType("opentelemetry.sdk.resources")
            sdk_trace_mod = ModuleType("opentelemetry.sdk.trace")
            sdk_trace_export_mod = ModuleType("opentelemetry.sdk.trace.export")

            class DummyTracer:
                def __init__(self, name):
                    self.name = name

            class DummyTracerProvider:
                def __init__(self, resource=None):
                    self.resource = resource
                    self.processors = []
                    self.force_flush_args = []
                    self.shutdown_args = []

                def add_span_processor(self, processor):
                    self.processors.append(processor)

                def force_flush(self, timeout=None):
                    self.force_flush_args.append(timeout)
                    return True

                def shutdown(self, timeout=None):
                    self.shutdown_args.append(timeout)
                    return True

            class DummyMeterProvider:
                def __init__(self, resource=None, metric_readers=None):
                    self.resource = resource
                    self.metric_readers = metric_readers or []
                    self.force_flush_args = []
                    self.shutdown_args = []

                def force_flush(self, timeout_millis=None):
                    self.force_flush_args.append(timeout_millis)
                    return True

                def shutdown(self, timeout_millis=None):
                    self.shutdown_args.append(timeout_millis)
                    return True

            class DummyMeter:
                def create_counter(self, *_, **__):
                    class Counter:
                        def add(self, *_args, **_kwargs):
                            return None

                    return Counter()

                def create_histogram(self, *_, **__):
                    class Histogram:
                        def record(self, *_args, **_kwargs):
                            return None

                    return Histogram()

            def set_tracer_provider(provider):
                trace_mod._provider = provider  # type: ignore[attr-defined]

            def get_tracer(name):
                return DummyTracer(name)

            def set_meter_provider(provider):
                metrics_mod._provider = provider  # type: ignore[attr-defined]

            def get_meter(name):
                metrics_mod._meter_name = name  # type: ignore[attr-defined]
                return DummyMeter()

            class DummyBatchSpanProcessor:
                def __init__(self, exporter):
                    self.exporter = exporter

            class DummyOTLPSpanExporter:
                def __init__(self, **kwargs):
                    self.kwargs = kwargs

            class DummyOTLPMetricExporter:
                def __init__(self, **kwargs):
                    self.kwargs = kwargs

            class DummyMetricReader:
                def __init__(self, exporter):
                    self.exporter = exporter

            class DummyResource:
                def __init__(self, attributes):
                    self.attributes = attributes

                @staticmethod
                def create(attributes):
                    return DummyResource(attributes)

            root.metrics = metrics_mod  # type: ignore[attr-defined]
            root.trace = trace_mod  # type: ignore[attr-defined]

            metrics_mod.set_meter_provider = set_meter_provider  # type: ignore[attr-defined]
            metrics_mod.get_meter = get_meter  # type: ignore[attr-defined]

            trace_mod.set_tracer_provider = set_tracer_provider  # type: ignore[attr-defined]
            trace_mod.get_tracer = get_tracer  # type: ignore[attr-defined]

            exporter_metric_mod.OTLPMetricExporter = DummyOTLPMetricExporter  # type: ignore[attr-defined]
            exporter_trace_mod.OTLPSpanExporter = DummyOTLPSpanExporter  # type: ignore[attr-defined]

            sdk_metrics_mod.MeterProvider = DummyMeterProvider  # type: ignore[attr-defined]
            sdk_metrics_export_mod.PeriodicExportingMetricReader = DummyMetricReader  # type: ignore[attr-defined]
            sdk_resources_mod.Resource = DummyResource  # type: ignore[attr-defined]
            sdk_trace_mod.TracerProvider = DummyTracerProvider  # type: ignore[attr-defined]
            sdk_trace_export_mod.BatchSpanProcessor = DummyBatchSpanProcessor  # type: ignore[attr-defined]

            return {
                "opentelemetry": root,
                "opentelemetry.metrics": metrics_mod,
                "opentelemetry.trace": trace_mod,
                "opentelemetry.exporter.otlp.proto.grpc.metric_exporter": exporter_metric_mod,
                "opentelemetry.exporter.otlp.proto.grpc.trace_exporter": exporter_trace_mod,
                "opentelemetry.sdk.metrics": sdk_metrics_mod,
                "opentelemetry.sdk.metrics.export": sdk_metrics_export_mod,
                "opentelemetry.sdk.resources": sdk_resources_mod,
                "opentelemetry.sdk.trace": sdk_trace_mod,
                "opentelemetry.sdk.trace.export": sdk_trace_export_mod,
            }

        stub_modules = build_stub_modules()

        with mock.patch.dict(sys.modules, stub_modules):
            importlib.reload(opentelemetry_bridge)
            state = opentelemetry_bridge.configure_opentelemetry()

            self.assertTrue(state.get("enabled"))
            tracer_provider = state.get("tracer_provider")
            meter_provider = state.get("meter_provider")

            self.assertIsNotNone(tracer_provider)
            self.assertIsNotNone(meter_provider)

            flushed = opentelemetry_bridge.force_flush(timeout_millis=1200)
            self.assertTrue(flushed)
            self.assertAlmostEqual(tracer_provider.force_flush_args[-1], 1.2)
            self.assertEqual(meter_provider.force_flush_args[-1], 1200)

            shutdown_result = opentelemetry_bridge.shutdown(timeout_millis=3000)
            self.assertTrue(shutdown_result)
            self.assertAlmostEqual(tracer_provider.shutdown_args[-1], 3.0)
            self.assertEqual(meter_provider.shutdown_args[-1], 3000)
            self.assertFalse(opentelemetry_bridge.is_enabled())

    @unittest.skipIf(_InMemoryOtelCollector is None, "OTLP gRPC dependencies not available")
    def test_otlp_export_roundtrip_flushes_spans_and_metrics(self):
        """End-to-end OTLP export should reach a local collector for spans and metrics."""

        collector = _InMemoryOtelCollector()
        server = grpc.server(futures.ThreadPoolExecutor(max_workers=4))  # type: ignore[arg-type]
        trace_service_pb2_grpc.add_TraceServiceServicer_to_server(collector, server)  # type: ignore[attr-defined]
        metrics_service_pb2_grpc.add_MetricsServiceServicer_to_server(collector, server)  # type: ignore[attr-defined]
        port = server.add_insecure_port("127.0.0.1:0")
        server.start()

        endpoint = f"127.0.0.1:{port}"
        env_payload = {
            "TELOS_OTEL_EXPORTER_ENDPOINT": endpoint,
            "TELOS_OTEL_EXPORTER_INSECURE": "true",
            "TELOS_OTEL_SETTINGS_PATH": "",
        }

        try:
            with mock.patch.dict(os.environ, env_payload, clear=False):
                state = opentelemetry_bridge.configure_opentelemetry(
                    {"otel.test": "collector"}
                )

                tracer = state.get("tracer")
                meter = state.get("meter")

                self.assertIsNotNone(tracer)
                self.assertIsNotNone(meter)

                with tracer.start_as_current_span("collector-test-span") as span:  # type: ignore[union-attr]
                    span.set_attribute("otel.test.attr", True)

                instruments = state.get("instruments", {})
                counter_iterations = instruments.get("conflict_iterations")
                histogram_duration = instruments.get("conflict_duration")

                self.assertIsNotNone(counter_iterations)
                self.assertIsNotNone(histogram_duration)

                counter_iterations.add(5, attributes={"component": "test"})  # type: ignore[union-attr]
                histogram_duration.record(0.5, attributes={"component": "test"})  # type: ignore[union-attr]

                flushed = opentelemetry_bridge.force_flush(timeout_millis=5000)
                self.assertTrue(flushed)

                deadline = time.time() + 5.0
                while time.time() < deadline:
                    if collector.spans and collector.metrics:
                        break
                    time.sleep(0.05)

                self.assertTrue(collector.spans, "collector did not receive span export")
                self.assertTrue(collector.metrics, "collector did not receive metric export")

                exported_span = (
                    collector.spans[-1]
                    .resource_spans[0]
                    .scope_spans[0]
                    .spans[0]
                )
                self.assertEqual(exported_span.name, "collector-test-span")

                exported_metric_names = [
                    metric.name
                    for scope in collector.metrics[-1].resource_metrics[0].scope_metrics
                    for metric in scope.metrics
                ]
                self.assertIn("telos.conflict_replay.iterations", exported_metric_names)
        finally:
            opentelemetry_bridge.shutdown()
            server.stop(0)

    def test_conflict_summary_computes_new_kpis(self):
        """Summaries should surface percentile, ratios, and wallclock aggregation."""

        class DummyLock:
            def __enter__(self):
                return None

            def __exit__(self, exc_type, exc, tb):
                return False

        trace_context = {
            "traceparent": "00-1234567890abcdef1234567890abcdef-1234567890abcdef-01",
            "tracestate": "vendor=value",
        }
        store = [
            {
                "type": "conflict_replay",
                "metrics": {
                    "iterations": 4,
                    "error_count": 4,
                    "errors": [
                        {"duration": 0.10},
                        {"duration": 0.20},
                        {"duration": 0.15},
                        {"duration": 0.25},
                    ],
                    "start_timestamp": 10.0,
                    "end_timestamp": 12.5,
                },
                "trace_context": trace_context,
            }
        ]

        summary = summarize_conflict_replay(store, DummyLock())
        self.assertEqual(summary.get("event_count"), 1)
        self.assertAlmostEqual(summary.get("total_iterations"), 4)
        self.assertGreater(summary.get("p95_iteration_duration"), 0.0)
        self.assertGreater(summary.get("errors_per_iteration"), 0.0)
        self.assertGreater(summary.get("total_replay_wallclock"), 0.0)
        self.assertEqual(summary.get("trace_context"), trace_context)


class TestWorkerOpenTelemetryIntegration(unittest.TestCase):
    """Ensure worker helpers integrate with the OpenTelemetry bridge."""

    def tearDown(self):
        """Restore the workers module bridge reference after tests."""
        importlib.reload(workers)

    def test_conflict_replay_emission_delegates_to_bridge(self):
        """Conflict replay events should be forwarded to the bridge when enabled."""

        captured = {}

        class StubBridge:
            def is_enabled(self):
                return True

            def emit_conflict_replay(self, event):
                captured["event"] = event
                return True

        with mock.patch.object(workers, "otel_bridge", StubBridge()):
            workers._emit_conflict_replay_opentelemetry({"foo": "bar"})

        self.assertEqual(captured.get("event"), {"foo": "bar"})

    def test_conflict_replay_emission_ignores_when_disabled(self):
        """No emission should occur when the bridge reports it is disabled."""

        class DisabledBridge:
            def is_enabled(self):
                return False

            def emit_conflict_replay(self, event):  # pragma: no cover - should not be called
                raise AssertionError("emit_conflict_replay should not be invoked when disabled")

        with mock.patch.object(workers, "otel_bridge", DisabledBridge()):
            # Should not raise even though emit_conflict_replay would assert if called
            workers._emit_conflict_replay_opentelemetry({"ignored": True})


if __name__ == "__main__":
    unittest.main()
