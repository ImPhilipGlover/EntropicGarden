"""
TELOS OpenTelemetry Bridge (Prototype-Oriented Helpers)

This module provides functional helpers that allow the Python worker
substrate to emit OpenTelemetry traces and metrics without introducing
class-based abstractions. The implementation defers imports until
configuration time so that OpenTelemetry remains an optional dependency
and the worker can continue to operate when the SDK is unavailable.
"""

from __future__ import annotations

import json
import logging
import os
import socket
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

_OTEL_STATE: Dict[str, Any] = {
    "enabled": False,
    "error": None,
    "resource": None,
    "tracer": None,
    "meter": None,
    "tracer_provider": None,
    "meter_provider": None,
    "instruments": {},
}

# Attribute name constants to avoid typos
_SERVICE_NAME = "service.name"
_SERVICE_VERSION = "service.version"
_SERVICE_INSTANCE = "service.instance.id"
_HOST_NAME = "host.name"
_PROCESS_PID = "process.pid"
_TELOS_COMPONENT = "telos.component"

_SETTINGS_PATH_ENV = "TELOS_OTEL_SETTINGS_PATH"
_ENDPOINT_ENV = "TELOS_OTEL_EXPORTER_ENDPOINT"
_HEADERS_ENV = "TELOS_OTEL_EXPORTER_HEADERS"
_INSECURE_ENV = "TELOS_OTEL_EXPORTER_INSECURE"


def _parse_headers(raw: Any) -> Dict[str, str]:
    if raw is None:
        return {}

    if isinstance(raw, dict):
        return {str(key): str(value) for key, value in raw.items() if key is not None}

    if isinstance(raw, (list, tuple)):
        parsed: Dict[str, str] = {}
        for entry in raw:
            if not isinstance(entry, (list, tuple)) or len(entry) != 2:
                continue
            key, value = entry
            parsed[str(key)] = str(value)
        return parsed

    if isinstance(raw, str):
        tokens = raw.replace(";", ",").split(",")
        parsed: Dict[str, str] = {}
        for token in tokens:
            item = token.strip()
            if not item or "=" not in item:
                continue
            key, value = item.split("=", 1)
            parsed[key.strip()] = value.strip()
        return parsed

    return {}


def _parse_bool(value: Any) -> Optional[bool]:
    if isinstance(value, bool):
        return value
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return bool(value)
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"1", "true", "yes", "on"}:
            return True
        if lowered in {"0", "false", "no", "off"}:
            return False
    return None


def _load_collector_config() -> Dict[str, Any]:
    config: Dict[str, Any] = {}

    settings_path = os.environ.get(_SETTINGS_PATH_ENV)
    if settings_path:
        try:
            payload = Path(settings_path)
            if payload.exists():
                data = json.loads(payload.read_text(encoding="utf-8"))
                if isinstance(data, dict):
                    config.update(data)
        except Exception as exc:  # pragma: no cover - diagnostic path only
            logging.getLogger("telos.opentelemetry").debug(
                "Failed to load OTEL config from %s: %s", settings_path, exc
            )

    endpoint = os.environ.get(_ENDPOINT_ENV)
    if endpoint:
        config["endpoint"] = endpoint

    headers_env = os.environ.get(_HEADERS_ENV)
    if headers_env:
        config["headers"] = _parse_headers(headers_env)
    elif "headers" in config:
        config["headers"] = _parse_headers(config["headers"])

    insecure_flag = os.environ.get(_INSECURE_ENV)
    if insecure_flag is not None:
        parsed = _parse_bool(insecure_flag)
        if parsed is not None:
            config["insecure"] = parsed
    elif "insecure" in config:
        parsed = _parse_bool(config["insecure"])
        if parsed is not None:
            config["insecure"] = parsed
        else:
            config.pop("insecure", None)

    return config


def load_collector_config() -> Dict[str, Any]:
    """Return a shallow copy of the collector configuration for inspection."""

    return dict(_load_collector_config())


def _prepare_exporter_kwargs(config: Dict[str, Any]) -> Dict[str, Any]:
    kwargs: Dict[str, Any] = {}

    endpoint = config.get("endpoint")
    if isinstance(endpoint, str) and endpoint.strip():
        kwargs["endpoint"] = endpoint.strip()

    headers = _parse_headers(config.get("headers"))
    if headers:
        kwargs["headers"] = headers

    insecure_flag = _parse_bool(config.get("insecure"))
    if insecure_flag is not None:
        kwargs["insecure"] = insecure_flag

    return kwargs


def _merge_attributes(base: Dict[str, Any], extra: Optional[Dict[str, Any]]) -> Dict[str, Any]:
    merged = dict(base)
    if extra:
        for key, value in extra.items():
            if value is None:
                continue
            merged[str(key)] = value
    return merged


def configure_opentelemetry(resource_attributes: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Configure global OpenTelemetry providers if the SDK is available.

    Returns the internal state dictionary so callers can inspect whether the
    configuration succeeded. This function is idempotent; repeated calls are
    inexpensive and return the cached state.
    """

    if _OTEL_STATE.get("enabled"):
        return _OTEL_STATE

    try:
        from opentelemetry import metrics as ot_metrics
        from opentelemetry import trace as ot_trace
        from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
        from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
        from opentelemetry.sdk.metrics import MeterProvider
        from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
        from opentelemetry.sdk.resources import Resource
        from opentelemetry.sdk.trace import TracerProvider
        from opentelemetry.sdk.trace.export import BatchSpanProcessor
    except Exception as exc:  # pragma: no cover - optional dependency path
        _OTEL_STATE["error"] = f"OpenTelemetry SDK unavailable: {exc}"
        logging.getLogger("telos.opentelemetry").debug(_OTEL_STATE["error"])
        return _OTEL_STATE

    default_attrs: Dict[str, Any] = {
        _SERVICE_NAME: "telos.python_worker",
        _SERVICE_VERSION: os.environ.get("TELOS_VERSION", "0.0.0"),
        _SERVICE_INSTANCE: str(os.getpid()),
        _HOST_NAME: socket.gethostname(),
        _PROCESS_PID: os.getpid(),
        _TELOS_COMPONENT: "python_worker",
    }

    resource = Resource.create(_merge_attributes(default_attrs, resource_attributes))

    collector_config = _load_collector_config()
    span_kwargs = _prepare_exporter_kwargs(collector_config)
    metric_kwargs = dict(span_kwargs)

    tracer_provider = TracerProvider(resource=resource)
    tracer_provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(**span_kwargs)))
    ot_trace.set_tracer_provider(tracer_provider)
    tracer = ot_trace.get_tracer("telos.python.workers")

    metric_reader = PeriodicExportingMetricReader(OTLPMetricExporter(**metric_kwargs))
    meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
    ot_metrics.set_meter_provider(meter_provider)
    meter = ot_metrics.get_meter("telos.python.workers")

    instruments = {
        "conflict_iterations": meter.create_counter(
            name="telos.conflict_replay.iterations",
            description="Total iterations executed during conflict replay",
            unit="{iteration}",
        ),
        "conflict_errors": meter.create_counter(
            name="telos.conflict_replay.errors",
            description="Total errors observed during conflict replay",
            unit="{error}",
        ),
        "conflict_duration": meter.create_histogram(
            name="telos.conflict_replay.attempt_duration",
            description="Duration of individual conflict replay attempts",
            unit="s",
        ),
    }

    _OTEL_STATE.update(
        {
            "enabled": True,
            "resource": resource,
            "tracer": tracer,
            "meter": meter,
            "tracer_provider": tracer_provider,
            "meter_provider": meter_provider,
            "instruments": instruments,
            "error": None,
            "collector": collector_config,
            "exporter_kwargs": span_kwargs,
        }
    )

    collector_desc = span_kwargs.get("endpoint", "default-env")
    logging.getLogger("telos.opentelemetry").info(
        "OpenTelemetry configured for TELOS workers (endpoint=%s, insecure=%s)",
        collector_desc,
        span_kwargs.get("insecure", False),
    )
    return _OTEL_STATE


def is_enabled() -> bool:
    """Return True when OpenTelemetry has been successfully configured."""

    return bool(_OTEL_STATE.get("enabled"))


def force_flush(timeout_millis: int = 5000) -> bool:
    """Force flush configured providers to expedite exports for testing."""

    if not is_enabled():
        return False

    success = True

    tracer_provider = _OTEL_STATE.get("tracer_provider")
    if tracer_provider is not None:
        try:
            result = tracer_provider.force_flush(timeout_millis / 1000.0)
        except TypeError:
            result = tracer_provider.force_flush()
        success = bool(result) and success

    meter_provider = _OTEL_STATE.get("meter_provider")
    if meter_provider is not None and hasattr(meter_provider, "force_flush"):
        try:
            result = meter_provider.force_flush(timeout_millis=timeout_millis)
        except TypeError:
            result = meter_provider.force_flush()
        success = bool(result) and success

    return success


def shutdown(timeout_millis: int = 5000) -> bool:
    """Shut down providers, flushing outstanding telemetry when possible."""

    if not is_enabled():
        return True

    success = True

    tracer_provider = _OTEL_STATE.get("tracer_provider")
    if tracer_provider is not None and hasattr(tracer_provider, "shutdown"):
        try:
            result = tracer_provider.shutdown(timeout_millis / 1000.0)
        except TypeError:
            result = tracer_provider.shutdown()
        success = bool(result) and success

    meter_provider = _OTEL_STATE.get("meter_provider")
    if meter_provider is not None and hasattr(meter_provider, "shutdown"):
        try:
            result = meter_provider.shutdown(timeout_millis=timeout_millis)
        except TypeError:
            result = meter_provider.shutdown()
        success = bool(result) and success

    _OTEL_STATE.update(
        {
            "enabled": False,
            "tracer": None,
            "meter": None,
            "tracer_provider": None,
            "meter_provider": None,
            "instruments": {},
        }
    )

    return success


def _current_instruments() -> Dict[str, Any]:
    if not is_enabled():
        return {}

    return _OTEL_STATE.get("instruments", {}) or {}


def _normalize_trace_context(payload: Any) -> Dict[str, str]:
    if isinstance(payload, dict):
        normalized: Dict[str, str] = {}
        traceparent = payload.get("traceparent")
        if traceparent:
            normalized["traceparent"] = str(traceparent)
        tracestate = payload.get("tracestate")
        if tracestate:
            normalized["tracestate"] = str(tracestate)
        return normalized
    return {}


def _event_attributes(event: Dict[str, Any]) -> Dict[str, Any]:
    base_attributes = {
        "telemetry.type": event.get("type", "unknown"),
        "telos.worker_id": event.get("worker_id"),
    }

    request_context = event.get("request_context")
    if isinstance(request_context, dict):
        for key, value in request_context.items():
            base_attributes[f"telemetry.context.{key}"] = value

    metrics_payload = event.get("metrics")
    if isinstance(metrics_payload, dict):
        for key, value in metrics_payload.items():
            if isinstance(value, (int, float, str, bool)):
                base_attributes[f"telemetry.metrics.{key}"] = value

    if event.get("captured_error"):
        base_attributes["telemetry.captured_error"] = event.get("captured_error")

    trace_ctx = _normalize_trace_context(event.get("trace_context"))
    if trace_ctx.get("traceparent"):
        base_attributes["telemetry.trace.traceparent"] = trace_ctx["traceparent"]
    if trace_ctx.get("tracestate"):
        base_attributes["telemetry.trace.tracestate"] = trace_ctx["tracestate"]

    return base_attributes


def _record_histogram_values(values: Iterable[float], histogram, attributes: Dict[str, Any]) -> None:
    for value in values:
        try:
            histogram.record(float(value), attributes=attributes)
        except Exception as exc:  # pragma: no cover - defensive logging
            logging.getLogger("telos.opentelemetry").debug(
                "Failed to record histogram value %s: %s", value, exc
            )


def emit_conflict_replay(event: Dict[str, Any]) -> bool:
    """Emit OpenTelemetry traces and metrics for a conflict replay event."""

    if not is_enabled():
        return False

    instruments = _current_instruments()
    attributes = _event_attributes(event)
    metrics_payload = event.get("metrics") or {}

    iterations = int(metrics_payload.get("iterations", 0) or 0)
    errors = int(metrics_payload.get("error_count", 0) or 0)

    counter_iterations = instruments.get("conflict_iterations")
    counter_errors = instruments.get("conflict_errors")
    histogram_duration = instruments.get("conflict_duration")

    if counter_iterations is not None and iterations:
        counter_iterations.add(iterations, attributes=attributes)
    if counter_errors is not None and errors:
        counter_errors.add(errors, attributes=attributes)

    error_entries = []
    raw_entries = metrics_payload.get("errors")
    if isinstance(raw_entries, list):
        for entry in raw_entries:
            if not isinstance(entry, dict):
                continue
            duration = entry.get("duration", 0.0) or 0.0
            error_entries.append(
                {
                    "index": int(entry.get("index", 0) or 0),
                    "duration": float(duration),
                    "message": entry.get("message") or "",
                }
            )

    if histogram_duration is not None and error_entries:
        _record_histogram_values((entry["duration"] for entry in error_entries), histogram_duration, attributes)

    tracer = _OTEL_STATE.get("tracer")
    if tracer is not None:
        from opentelemetry.trace import Status, StatusCode, SpanKind

        span_name = "telos.conflict_replay"

        span_cm = None
        trace_ctx = _normalize_trace_context(event.get("trace_context"))
        if trace_ctx:
            try:
                from opentelemetry.propagate import TraceContextTextMapPropagator

                carrier = dict(trace_ctx)
                parent_context = TraceContextTextMapPropagator().extract(carrier=carrier)
                span_cm = tracer.start_as_current_span(
                    span_name,
                    context=parent_context,
                    kind=SpanKind.SERVER,
                    attributes=attributes,
                )
            except Exception:  # pragma: no cover - propagator optional path
                logging.getLogger("telos.opentelemetry").debug(
                    "Failed to apply trace context to conflict replay span",
                    exc_info=True,
                )

        if span_cm is None:
            span_cm = tracer.start_as_current_span(span_name, attributes=attributes)

        with span_cm as span:
            if error_entries:
                for entry in error_entries:
                    span.add_event(
                        name="conflict_replay.retry",
                        attributes={
                            "retry.index": entry["index"],
                            "retry.duration": entry["duration"],
                            "retry.message": entry["message"],
                        },
                    )
            captured_error = event.get("captured_error")
            if captured_error:
                span.set_status(Status(StatusCode.ERROR, description=str(captured_error)))
            else:
                span.set_status(Status(StatusCode.OK))

    return True


def emit_generic_event(event: Dict[str, Any]) -> bool:
    """Emit a trace-only representation of an arbitrary telemetry event."""

    if not is_enabled():
        return False

    tracer = _OTEL_STATE.get("tracer")
    if tracer is None:
        return False

    attributes = _event_attributes(event)
    span_name = f"telos.{attributes.get('telemetry.type', 'event')}"
    span_cm = None
    trace_ctx = _normalize_trace_context(event.get("trace_context"))
    if trace_ctx:
        try:
            from opentelemetry.propagate import TraceContextTextMapPropagator
            from opentelemetry.trace import SpanKind

            carrier = dict(trace_ctx)
            parent_context = TraceContextTextMapPropagator().extract(carrier=carrier)
            span_cm = tracer.start_as_current_span(
                span_name,
                context=parent_context,
                kind=SpanKind.SERVER,
                attributes=attributes,
            )
        except Exception:  # pragma: no cover - propagator optional path
            logging.getLogger("telos.opentelemetry").debug(
                "Failed to apply trace context to generic span",
                exc_info=True,
            )

    if span_cm is None:
        span_cm = tracer.start_as_current_span(span_name, attributes=attributes)

    with span_cm:
        pass

    return True


def get_state() -> Dict[str, Any]:
    """Return a shallow copy of the OpenTelemetry state for inspection/testing."""

    return dict(_OTEL_STATE)
