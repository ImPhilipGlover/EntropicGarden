"""
Federated memory operation handlers for TELOS workers.

This module contains handlers for federated memory operations that were
extracted from workers.py to maintain modular architecture and keep
individual files under 300 lines.
"""

from typing import Dict, Any, Optional
import traceback
import logging

# Import UvmObject for prototypal object creation
try:
    from .uvm_object import UvmObject, create_uvm_object
except ImportError:  # pragma: no cover - fallback for direct execution
    from uvm_object import UvmObject, create_uvm_object  # type: ignore

# Import federated memory dependencies
try:
    from .federated_memory import (
        FEDERATED_MEMORY_AVAILABLE,
        FEDERATED_MEMORY_IMPORT_ERROR,
        _federated_memory_module,
        _federated_memory_lock,
        _get_federated_memory_interface,
        _ensure_l1_cache_manager,
    )
except ImportError:
    # Fallback for when federated memory is not available
    FEDERATED_MEMORY_AVAILABLE = False
    FEDERATED_MEMORY_IMPORT_ERROR = "federated_memory module not available"
    _federated_memory_module = None
    _federated_memory_lock = None
    _get_federated_memory_interface = None
    _ensure_l1_cache_manager = None

from .worker_types import TelosWorkerError


def handle_federated_memory(worker_instance, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Expose federated memory controls and telemetry through the bridge."""
    logger = worker_instance.get_slot('logger')
    action = request_data.get('action', 'status')
    config_payload = request_data.get('config') or {}
    if not isinstance(config_payload, dict):
        config_payload = {}

    if not FEDERATED_MEMORY_AVAILABLE or _federated_memory_module is None:
        return {
            'success': False,
            'error': 'Federated memory module unavailable',
            'details': FEDERATED_MEMORY_IMPORT_ERROR,
        }

    try:
        with _federated_memory_lock:
            if action == 'initialize':
                settings = config_payload.get('settings')
                if not isinstance(settings, dict):
                    settings = config_payload if config_payload else None
                init_result = _federated_memory_module.initialize_memory_fabric(settings)
                fabric = _get_federated_memory_interface()
                status = fabric['get_status']()
                return {
                    'success': bool(init_result),
                    'initialized': bool(status.get('initialized', False)),
                    'status': status,
                }

            if action == 'shutdown':
                shutdown_result = _federated_memory_module.shutdown_memory_fabric()
                return {
                    'success': bool(shutdown_result),
                }

            fabric = _get_federated_memory_interface()

            if action in ('status', 'get_status'):
                status = fabric['get_status']()
                return {
                    'success': True,
                    'status': status,
                }

            if action in ('outbox_status', 'get_outbox_status'):
                status = fabric['get_outbox_status']()
                return {
                    'success': True,
                    'status': status,
                }

            if action in ('cache_statistics', 'get_cache_statistics'):
                stats = fabric['get_cache_statistics']()
                return {
                    'success': True,
                    'statistics': stats,
                }

            if action in ('validate', 'validate_architecture'):
                validation = fabric['validate']()
                response = dict(validation)
                response['success'] = bool(validation.get('valid', False))
                return response

            if action in ('l2_telemetry', 'get_l2_telemetry'):
                telemetry = fabric['get_l2_telemetry']()
                success = 'error' not in telemetry
                response = {
                    'success': success,
                    'telemetry': telemetry,
                }
                if not success:
                    response['error'] = telemetry.get('error', 'unknown error')
                return response

            if action in ('simulate_coordinator_failure', 'coordinator_failure_test'):
                result = fabric['simulate_coordinator_failure'](config_payload)
                response = dict(result)
                response['success'] = bool(result.get('success', False))
                return response

            if action == 'status_with_cache':
                status = fabric['get_status']()
                stats = fabric['get_cache_statistics']()
                return {
                    'success': True,
                    'status': status,
                    'statistics': stats,
                }

            if action in ('run_benchmark', 'benchmark'):
                result = fabric['run_benchmark'](config_payload)
                response = dict(result)
                response['success'] = bool(result.get('success', False))
                return response

            if action in ('get_benchmark_history', 'benchmark_history'):
                history = fabric['get_benchmark_history']()
                response = dict(history)
                limit_value = None
                if isinstance(config_payload, dict) and config_payload.get('limit') is not None:
                    try:
                        limit_value = max(0, int(config_payload['limit']))
                    except Exception:
                        limit_value = None
                if limit_value is not None:
                    history_list = response.get('history')
                    if isinstance(history_list, list):
                        response['history'] = history_list[:limit_value]
                response['success'] = True
                return response

            if action in ('get_benchmark_summary', 'benchmark_summary'):
                limit_arg: Optional[Any] = None
                if isinstance(config_payload, dict) and config_payload.get('limit') is not None:
                    limit_arg = config_payload.get('limit')
                elif config_payload not in ({}, None):
                    limit_arg = config_payload

                summary = fabric['get_benchmark_summary'](limit_arg)
                return {
                    'success': True,
                    'summary': summary,
                }

            if action in ('get_benchmark_alerts', 'benchmark_alerts'):
                options_payload: Optional[Dict[str, Any]] = None
                if isinstance(config_payload, dict) and config_payload:
                    options_payload = config_payload
                alerts_snapshot = fabric['get_benchmark_alerts'](options_payload)
                return {
                    'success': True,
                    'alerts': alerts_snapshot,
                }

            if action in ('configure_benchmark_alerts', 'benchmark_alerts_configure'):
                overrides = config_payload if isinstance(config_payload, dict) else None
                configured = fabric['configure_benchmark_alerts'](overrides)
                response = dict(configured)
                response['success'] = True
                return response

            if action in ('clear_benchmark_alerts', 'benchmark_alerts_clear'):
                cleared = fabric['clear_benchmark_alerts']()
                return {
                    'success': True,
                    'alerts': cleared,
                }

            if action in ('evaluate_benchmark_alerts', 'benchmark_alerts_evaluate'):
                options_payload: Optional[Dict[str, Any]] = None
                if isinstance(config_payload, dict) and config_payload:
                    options_payload = config_payload
                evaluation = fabric['evaluate_benchmark_alerts'](options_payload)
                response = dict(evaluation)
                response['success'] = True
                return response

            if action in ('get_benchmark_recommendations', 'benchmark_recommendations'):
                options_payload: Optional[Dict[str, Any]] = None
                if isinstance(config_payload, dict) and config_payload:
                    options_payload = config_payload
                recommendations = fabric['get_benchmark_recommendations'](options_payload)
                response = dict(recommendations)
                response['success'] = bool(recommendations.get('success', False))
                return response

            if action in ('clear_benchmark_recommendations', 'benchmark_recommendations_clear'):
                options_payload: Optional[Dict[str, Any]] = None
                if isinstance(config_payload, dict) and config_payload:
                    options_payload = config_payload
                cleared = fabric['clear_benchmark_recommendations'](options_payload)
                response = dict(cleared)
                response['success'] = bool(cleared.get('success', False))
                return response

            if action in ('apply_benchmark_recommendations', 'benchmark_recommendations_apply'):
                options_payload: Optional[Dict[str, Any]] = None
                if isinstance(config_payload, dict) and config_payload:
                    options_payload = config_payload
                applied = fabric['apply_benchmark_recommendations'](options_payload)
                response = dict(applied)
                response['success'] = bool(applied.get('success', False))
                return response

            if action in ('get_outbox_analytics', 'outbox_analytics'):
                options_payload: Optional[Dict[str, Any]] = None
                if isinstance(config_payload, dict) and config_payload:
                    options_payload = config_payload
                analytics = fabric['get_outbox_analytics'](options_payload)
                return {
                    'success': True,
                    'analytics': analytics,
                }

            if action in ('start_benchmark_daemon', 'benchmark_daemon_start'):
                result = fabric['start_benchmark_daemon'](config_payload)
                response = dict(result)
                response['success'] = bool(result.get('success', False))
                return response

            if action in ('stop_benchmark_daemon', 'benchmark_daemon_stop'):
                payload = config_payload if isinstance(config_payload, dict) else None
                result = fabric['stop_benchmark_daemon'](payload)
                response = dict(result)
                response['success'] = bool(result.get('success', False))
                return response

            if action in ('trigger_benchmark_run', 'benchmark_daemon_trigger'):
                result = fabric['trigger_benchmark_run'](config_payload)
                response = dict(result)
                response['success'] = bool(result.get('success', False))
                return response

            if action in ('benchmark_daemon_status', 'get_benchmark_daemon_status'):
                status = fabric['get_benchmark_daemon_status']()
                return {
                    'success': True,
                    'status': status,
                }

            if action in ('promote_l1', 'promote_l1_batch', 'process_l1_promotions'):
                manager = _ensure_l1_cache_manager()
                if manager is None:
                    return {
                        'success': False,
                        'error': 'l1_cache_manager_unavailable',
                    }

                raw_limit = config_payload.get('limit')
                limit: Optional[int] = None
                if raw_limit is not None:
                    try:
                        limit = max(0, int(raw_limit))
                    except Exception:
                        limit = None

                include_vectors = bool(config_payload.get('include_vectors', True))
                drained = manager['drain_promotions'](limit=limit, include_vectors=include_vectors)

                if not drained:
                    remaining_snapshot = manager['peek_promotions']()
                    return {
                        'success': True,
                        'attempted': 0,
                        'promoted': 0,
                        'failures': [],
                        'promoted_oids': [],
                        'remaining_queue': len(remaining_snapshot),
                    }

                promotion_options = {
                    'include_vectors': include_vectors,
                    'limit': limit,
                    'notify_coordinator': config_payload.get('notify_coordinator', True),
                }

                promotion_result = fabric['promote_l1_candidates'](drained, promotion_options)
                remaining_snapshot = manager['peek_promotions']()
                promotion_result = dict(promotion_result)
                promotion_result.setdefault('attempted', len(drained))
                promotion_result['remaining_queue'] = len(remaining_snapshot)
                promotion_result['success'] = bool(promotion_result.get('success', False))
                return promotion_result

            if action in ('trigger_promotions', 'promotion_cycle', 'trigger_promotion_cycle'):
                cycle_result = fabric['trigger_promotion_cycle'](config_payload)
                response = dict(cycle_result)
                response['success'] = bool(cycle_result.get('success', False))
                return response

            if action in ('promotion_daemon_status', 'get_promotion_daemon_status'):
                return {
                    'success': True,
                    'status': fabric['get_promotion_daemon_status'](),
                }

    except TelosWorkerError as exc:
        logger.error("Federated memory access error: %s", exc)
        return {
            'success': False,
            'error': str(exc),
        }
    except Exception as exc:  # pragma: no cover - defensive logging path
        logger.error("Federated memory action '%s' failed: %s", action, exc)
        logger.debug("Traceback: %s", traceback.format_exc())
        return {
            'success': False,
            'error': str(exc),
        }

    return {
        'success': False,
        'error': f"Unknown federated_memory action: {action}",
    }


def create_federated_memory_handlers() -> Dict[str, Any]:
    """
    Factory function to create federated memory handlers following prototypal principles.
    
    Returns:
        Dictionary of handler methods for federated memory operations
    """
    handlers = UvmObject()
    handlers['handle_federated_memory'] = handle_federated_memory
    return handlers