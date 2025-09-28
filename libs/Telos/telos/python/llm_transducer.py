#!/usr/bin/env python3
"""TELOS LLM Transducer Prototype

This module provides the prototypal interface around the Ollama-powered
LLM transduction pipeline described in TELOS Implementation Addendum 1.3.
It purposefully avoids class-based abstractions, exposing a factory that
produces dictionaries of slots which can be cloned, configured, and
invoked by the worker substrate.
"""

from __future__ import annotations

import json
import os
import time
import logging
from typing import Any, Dict, Iterable, Optional, Tuple
from urllib import request as urllib_request
from urllib import error as urllib_error

logger = logging.getLogger(__name__)

_DEFAULT_ENDPOINT = "http://127.0.0.1:11434/api/chat"
_DEFAULT_MODEL = "llama3.1"
_DEFAULT_TIMEOUT = 45.0

_SIMULATION_ENV_FLAG = "TELOS_LLM_SIMULATION"


def _sanitize_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, (int, float)):
        return bool(int(value))
    if isinstance(value, str):
        lowered = value.strip().lower()
        if lowered in {"1", "true", "yes", "on", "enabled"}:
            return True
        if lowered in {"0", "false", "no", "off", "disabled"}:
            return False
    return False


def _gather_default_config() -> Dict[str, Any]:
    simulate_flag = _sanitize_bool(os.getenv(_SIMULATION_ENV_FLAG, "0"))
    return {
        "endpoint": _DEFAULT_ENDPOINT,
        "model": _DEFAULT_MODEL,
        "timeout": _DEFAULT_TIMEOUT,
        "simulate": simulate_flag,
        "default_temperature": 0.0,
        "max_retries": 2,
    }


def _clone_state(state: Dict[str, Any]) -> Dict[str, Any]:
    clone: Dict[str, Any] = {}
    for key, value in state.items():
        if isinstance(value, dict):
            clone[key] = dict(value)
        elif isinstance(value, (list, tuple)):
            clone[key] = list(value)
        else:
            clone[key] = value
    return clone


def create_llm_transducer(initial_config: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Factory that returns a prototypal LLM transducer dictionary."""

    state: Dict[str, Any] = {
        "config": _gather_default_config(),
        "metrics": {
            "requests": 0,
            "failures": 0,
            "latencies": [],
            "last_error": None,
        },
    }

    if initial_config:
        state["config"].update(initial_config)

    def _set_config(options: Optional[Dict[str, Any]]) -> Dict[str, Any]:
        if not options:
            return dict(state["config"])

        for key, value in options.items():
            if key == "simulate":
                state["config"][key] = _sanitize_bool(value)
            elif key in {"endpoint", "model"} and isinstance(value, str):
                state["config"][key] = value.strip()
            elif key == "timeout":
                try:
                    parsed = float(value)
                    if parsed > 0.0:
                        state["config"][key] = parsed
                except (TypeError, ValueError):
                    logger.warning("Ignored invalid timeout value for LLM transducer")
            elif key == "default_temperature":
                try:
                    state["config"][key] = float(value)
                except (TypeError, ValueError):
                    logger.debug("Failed to parse temperature override: %s", value)
            elif key == "max_retries":
                try:
                    retries = int(value)
                    if retries >= 0:
                        state["config"][key] = retries
                except (TypeError, ValueError):
                    logger.debug("Failed to parse max_retries override: %s", value)
            else:
                state["config"][key] = value

        return dict(state["config"])

    def _clone(overrides: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        cloned = create_llm_transducer(_clone_state(state["config"]))
        if overrides:
            cloned["configure"](overrides)
        return cloned

    def _record_metrics(success: bool, latency_ms: float, error: Optional[str]) -> None:
        metrics = state["metrics"]
        metrics["requests"] += 1
        if not success:
            metrics["failures"] += 1
            metrics["last_error"] = error
        metrics["latencies"].append(latency_ms)
        if len(metrics["latencies"]) > 256:
            metrics["latencies"] = metrics["latencies"][-256:]

    def _build_prompt(payload: Dict[str, Any]) -> str:
        prompt = payload.get("prompt")
        if isinstance(prompt, str) and prompt.strip():
            return prompt
        template = payload.get("prompt_template")
        if isinstance(template, dict):
            persona = template.get("persona") or template.get("persona_priming")
            instructions = template.get("instructions") or template.get("output_instructions")
            context_items = template.get("context") or template.get("context_injection")
            segments: Iterable[str] = []
            parts = []
            if persona:
                parts.append(str(persona))
            if instructions:
                parts.append(str(instructions))
            if context_items:
                try:
                    if isinstance(context_items, dict):
                        rendered_context = json.dumps(context_items, indent=2, ensure_ascii=False)
                        parts.append(f"Context:\n{rendered_context}")
                except Exception:
                    parts.append(str(context_items))
            segments = parts
            return "\n\n".join(segment for segment in segments if segment)
        raise ValueError("LLM transducer request missing prompt content")

    def _simulate_response(mode: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        preview = payload.get("text_input") or payload.get("schema_input") or payload.get("prompt")
        if isinstance(preview, str):
            preview = preview.strip()
            tokens = preview.split()
            preview = " ".join(tokens[:24]) if tokens else ""
        simulated = {
            "success": True,
            "mode": mode,
            "simulated": True,
            "schema_name": payload.get("output_schema_name"),
            "tool_call": None,
            "text_preview": preview,
            "timestamp": time.time(),
        }
        if mode == "transduce_text_to_schema":
            schema = payload.get("output_schema") or {}
            if isinstance(schema, dict):
                simulated["data"] = {
                    key: f"<simulated:{key}>" for key in schema.get("properties", {}).keys()
                }
            else:
                simulated["data"] = {"summary": preview, "confidence": 0.42}
        elif mode == "transduce_schema_to_text":
            simulated["text"] = f"Simulated explanation for payload ({preview or 'no preview'})"
        elif mode == "transduce_text_to_tool_call":
            tools = payload.get("available_tools") or []
            chosen = tools[0] if tools else None
            if isinstance(chosen, dict):
                simulated["tool_call"] = {
                    "name": chosen.get("name", "unknown_tool"),
                    "arguments": {"simulated": True},
                }
            else:
                simulated["tool_call"] = None
        return simulated

    def _invoke_ollama(mode: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        config = state["config"]
        request_body: Dict[str, Any] = {
            "model": config["model"],
            "stream": False,
            "options": {
                "temperature": payload.get("temperature", config.get("default_temperature", 0.0)),
            },
        }

        prompt = _build_prompt(payload)
        system_prompt = payload.get("system_prompt")

        if mode == "transduce_schema_to_text":
            messages = [
                {"role": "system", "content": system_prompt or "You are a precise transducer."},
                {"role": "user", "content": prompt},
            ]
            request_body["messages"] = messages
        else:
            schema = payload.get("output_schema") or payload.get("output_schema_dict")
            if schema:
                request_body["format"] = schema
            messages = [
                {"role": "system", "content": system_prompt or "You are a precise transducer."},
                {"role": "user", "content": prompt},
            ]
            request_body["messages"] = messages

        tools = payload.get("available_tools")
        if mode == "transduce_text_to_tool_call" and tools:
            request_body["tools"] = tools

        attempt = 0
        max_retries = int(config.get("max_retries", 0) or 0)
        endpoint = config.get("endpoint", _DEFAULT_ENDPOINT)
        encoded = json.dumps(request_body).encode("utf-8")

        while True:
            attempt += 1
            try:
                http_request = urllib_request.Request(
                    endpoint,
                    data=encoded,
                    headers={"Content-Type": "application/json"},
                    method="POST",
                )
                with urllib_request.urlopen(http_request, timeout=float(config.get("timeout", _DEFAULT_TIMEOUT))) as response:
                    payload_bytes = response.read()
                decoded = json.loads(payload_bytes.decode("utf-8"))
                return {
                    "success": True,
                    "mode": mode,
                    "raw_response": decoded,
                }
            except (urllib_error.URLError, urllib_error.HTTPError, TimeoutError) as exc:  # type: ignore[arg-type]
                if attempt > max_retries:
                    raise RuntimeError(f"Ollama request failed after {attempt} attempts: {exc}")
                time.sleep(min(0.5 * attempt, 2.0))
            except json.JSONDecodeError as exc:
                raise RuntimeError(f"Failed to decode Ollama response: {exc}")

    def _execute(payload: Dict[str, Any]) -> Dict[str, Any]:
        if not isinstance(payload, dict):
            raise TypeError("LLM transducer payload must be a dict")

        raw_mode = payload.get("mode") or payload.get("message") or payload.get("operation_name")
        if not raw_mode:
            raise ValueError("LLM transducer requests must include a mode")

        normalized = str(raw_mode).strip().lower()
        mode_map = {
            "transducetexttoschema": "transduce_text_to_schema",
            "text_to_schema": "transduce_text_to_schema",
            "transducetexttotoolcall": "transduce_text_to_tool_call",
            "text_to_tool_call": "transduce_text_to_tool_call",
            "transduceschematotext": "transduce_schema_to_text",
            "schema_to_text": "transduce_schema_to_text",
        }
        mode = mode_map.get(normalized, normalized)

        start = time.perf_counter()
        success = False
        error_message: Optional[str] = None

        try:
            if state["config"].get("simulate") or payload.get("simulate"):
                result = _simulate_response(mode, payload)
            else:
                result = _invoke_ollama(mode, payload)
            success = bool(result.get("success"))
            return result
        except Exception as exc:
            error_message = str(exc)
            logger.error("LLM transduction failed: %s", exc)
            return {
                "success": False,
                "mode": mode,
                "error": error_message,
                "simulated": False,
            }
        finally:
            elapsed_ms = (time.perf_counter() - start) * 1000.0
            _record_metrics(success, elapsed_ms, error_message)

    def _get_metrics() -> Dict[str, Any]:
        metrics = dict(state["metrics"])
        latencies = metrics.get("latencies", [])
        if latencies:
            metrics["p50"] = _percentile(latencies, 0.50)
            metrics["p95"] = _percentile(latencies, 0.95)
            metrics["p99"] = _percentile(latencies, 0.99)
        return metrics

    return {
        "configure": _set_config,
        "clone": _clone,
        "execute": _execute,
        "get_config": lambda: dict(state["config"]),
        "get_metrics": _get_metrics,
    }


def _percentile(values: Iterable[float], percentile: float) -> Optional[float]:
    try:
        ordered = sorted(float(v) for v in values)
    except Exception:
        return None
    if not ordered:
        return None
    if percentile <= 0:
        return ordered[0]
    if percentile >= 1:
        return ordered[-1]
    position = percentile * (len(ordered) - 1)
    lower = int(position)
    upper = min(lower + 1, len(ordered) - 1)
    weight = position - lower
    return ordered[lower] * (1.0 - weight) + ordered[upper] * weight
