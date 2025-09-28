"""
Bridge metrics operation handlers for TELOS workers.

This module contains handlers for bridge metrics operations that were
extracted from workers.py to maintain modular architecture and keep
individual files under 300 lines.
"""

import logging
import traceback
from typing import Dict, Any, List

# Import UvmObject for prototypal object creation
try:
    from .uvm_object import UvmObject, create_uvm_object
except ImportError:  # pragma: no cover - fallback for direct execution
    from uvm_object import UvmObject, create_uvm_object  # type: ignore

# Import prototypal bridge for metrics access
try:
    from . import prototypal_bridge
except ImportError:  # pragma: no cover - fallback for direct imports
    import prototypal_bridge  # type: ignore


def handle_bridge_metrics(worker_instance, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Expose prototypal bridge dispatch metrics to Io orchestrators."""
    try:
        logger = worker_instance.get_slot('logger')
    except Exception:
        logger = logging.getLogger('telos.worker.bridge_metrics')

    action = (request_data.get('action') or 'snapshot').lower()
    config = request_data.get('config') or {}

    proxy_id = config.get('proxy_id')
    raw_proxy_ids = config.get('proxy_ids')

    if isinstance(raw_proxy_ids, (list, tuple, set)):
        proxy_id_list = [str(pid) for pid in raw_proxy_ids if pid is not None]
    elif isinstance(raw_proxy_ids, str) and raw_proxy_ids:
        proxy_id_list = [raw_proxy_ids]
    elif raw_proxy_ids is None:
        proxy_id_list = None
    else:
        logger.debug("bridge_metrics received unsupported proxy_ids payload: %r", raw_proxy_ids)
        proxy_id_list = []

    summary_ids = None
    if proxy_id_list is not None:
        summary_ids = proxy_id_list
    elif proxy_id is not None:
        summary_ids = [str(proxy_id)]

    def _snapshot_many(proxy_ids: List[str]) -> Dict[str, Any]:
        return {
            pid: prototypal_bridge.get_dispatch_metrics(pid)
            for pid in proxy_ids
        }

    try:
        if action in ('snapshot', 'get', 'fetch'):
            if proxy_id_list is not None:
                metrics = _snapshot_many(proxy_id_list)
            else:
                metrics = prototypal_bridge.get_dispatch_metrics(proxy_id)

            return {
                'success': True,
                'metrics': metrics,
            }

        if action in ('summary', 'summarize'):
            summary = prototypal_bridge.summarize_dispatch_metrics(summary_ids)
            return {
                'success': True,
                'summary': summary,
            }

        if action in ('summary_history', 'history', 'history_get'):
            limit_value = config.get('limit')
            history = prototypal_bridge.get_summary_history(limit_value)
            return {
                'success': True,
                'history': history,
            }

        if action in ('summary_history_clear', 'history_clear'):
            prototypal_bridge.clear_summary_history()
            return {
                'success': True,
            }

        if action in (
            'summary_history_config',
            'history_config',
            'configure_summary_history',
        ):
            config_payload = prototypal_bridge.configure_summary_history(config)
            return {
                'success': True,
                'config': config_payload,
            }

        if action in ('analyze', 'analysis', 'diagnose'):
            analysis_payload = None
            raw_analysis = config.get('analysis')
            if isinstance(raw_analysis, dict):
                analysis_payload = raw_analysis
            else:
                thresholds = config.get('thresholds')
                if isinstance(thresholds, dict):
                    analysis_payload = {'thresholds': thresholds}

            analysis = prototypal_bridge.analyze_dispatch_metrics(summary_ids, analysis_payload)
            return {
                'success': True,
                'analysis': analysis,
            }

        if action in ('reset', 'clear'):
            if proxy_id_list is not None:
                reset_results = {
                    pid: bool(prototypal_bridge.reset_dispatch_metrics(pid))
                    for pid in proxy_id_list
                }
                success = all(reset_results.values()) if reset_results else False
                return {
                    'success': success,
                    'reset': reset_results,
                }

            reset_success = bool(prototypal_bridge.reset_dispatch_metrics(proxy_id))
            return {
                'success': reset_success,
            }

        if action in ('summary_reset', 'summarize_reset', 'summary-clear'):
            summary = prototypal_bridge.summarize_dispatch_metrics(summary_ids)

            if proxy_id_list is not None:
                reset_results = {
                    pid: bool(prototypal_bridge.reset_dispatch_metrics(pid))
                    for pid in proxy_id_list
                }
                success = all(reset_results.values()) if reset_results else False
                return {
                    'success': success,
                    'summary': summary,
                    'reset': reset_results,
                }

            if proxy_id is not None:
                reset_success = bool(prototypal_bridge.reset_dispatch_metrics(proxy_id))
                return {
                    'success': reset_success,
                    'summary': summary,
                }

            reset_success = bool(prototypal_bridge.reset_dispatch_metrics(None))
            return {
                'success': reset_success,
                'summary': summary,
            }

        if action in ('snapshot_reset', 'fetch_reset', 'snapshot-clear'):
            if proxy_id_list is not None:
                metrics = _snapshot_many(proxy_id_list)
                reset_results = {
                    pid: bool(prototypal_bridge.reset_dispatch_metrics(pid))
                    for pid in proxy_id_list
                }
                success = all(reset_results.values()) if reset_results else False
                return {
                    'success': success,
                    'metrics': metrics,
                    'reset': reset_results,
                }

            metrics = prototypal_bridge.get_dispatch_metrics(proxy_id)
            reset_success = bool(prototypal_bridge.reset_dispatch_metrics(proxy_id))
            return {
                'success': reset_success,
                'metrics': metrics,
            }

    except Exception as exc:  # pragma: no cover - defensive logging path
        logger.error("Bridge metrics action '%s' failed: %s", action, exc)
        logger.debug("Traceback: %s", traceback.format_exc())
        return {
            'success': False,
            'error': str(exc),
        }

    return {
        'success': False,
        'error': f"Unknown bridge_metrics action: {action}",
    }


def create_bridge_metrics_handlers() -> Dict[str, Any]:
    """
    Factory function to create bridge metrics handlers following prototypal principles.
    
    Returns:
        Dictionary of handler methods for bridge metrics operations
    """
    handlers = UvmObject()
    handlers['handle_bridge_metrics'] = handle_bridge_metrics
    return handlers