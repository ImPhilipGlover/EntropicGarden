"""
Vector Operations Handlers for TELOS Workers

This module contains handlers for vector cache operations, extracted from workers.py
to maintain the 300-line architectural limit.
"""

from typing import Dict, Any, List, Optional
import logging

try:
    from .worker_utils import (
        _extract_vector_from_config,
        _prepare_vector_response,
        _ensure_l1_cache_manager,
        _l1_cache_config,
        FAISS_AVAILABLE,
    )
except ImportError:  # pragma: no cover - fallback for direct imports
    from worker_utils import (  # type: ignore
        _extract_vector_from_config,
        _prepare_vector_response,
        _ensure_l1_cache_manager,
        _l1_cache_config,
        FAISS_AVAILABLE,
    )


def handle_vector_operations(worker, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle vector cache operations routed from Io actors."""

    logger = worker.get_slot('logger')
    action = request_data.get('action') or request_data.get('vector_operation') or 'stats'
    config = request_data.get('config') or {}

    try:
        if action == 'configure':
            manager = _ensure_l1_cache_manager(config, reset=True)
            stats = manager['get_statistics']()
            return {
                'success': True,
                'config': dict(_l1_cache_config),
                'faiss_available': FAISS_AVAILABLE,
                'faiss_error': None,  # TODO: import FAISS_IMPORT_ERROR if needed
                'statistics': stats,
            }

        manager = _ensure_l1_cache_manager()

        if action == 'drain_promotions':
            raw_limit = config.get('limit')
            limit: Optional[int] = None
            if raw_limit is not None:
                try:
                    limit = max(0, int(raw_limit))
                except Exception:
                    limit = None

            include_vectors = bool(config.get('include_vectors'))
            drained = manager['drain_promotions'](limit=limit, include_vectors=include_vectors)
            return {
                'success': True,
                'count': len(drained),
                'candidates': drained,
            }

        if action == 'peek_promotions':
            snapshot = manager['peek_promotions']()
            return {
                'success': True,
                'count': len(snapshot),
                'candidates': snapshot,
            }

    except Exception as exc:
        logger.error("Failed to configure L1 cache manager: %s", exc)
        return {
            'success': False,
            'error': f"L1 cache manager unavailable: {exc}",
        }

    if action == 'put':
        oid = config.get('oid') or config.get('id') or config.get('concept_oid')
        if not oid:
            return {'success': False, 'error': 'vector put requires oid'}

        vector, error = _extract_vector_from_config(config)
        if vector is None:
            return {'success': False, 'error': error}

        metadata = config.get('metadata') or {}

        try:
            stored = manager['put'](str(oid), vector, metadata)
        except Exception as exc:  # pragma: no cover - defensive path
            logger.error("L1 put failed: %s", exc)
            return {'success': False, 'error': f"put failed: {exc}"}

        return {
            'success': bool(stored),
            'oid': str(oid),
            'stored': bool(stored),
            'vector_dim': int(vector.shape[0]),
        }

    if action == 'get':
        oid = config.get('oid') or config.get('id') or config.get('concept_oid')
        if not oid:
            return {'success': False, 'error': 'vector get requires oid'}

        entry = manager['get'](str(oid))
        if not entry:
            return {
                'success': False,
                'found': False,
                'oid': str(oid),
                'error': 'oid not found',
            }

        vector_payload, shm_descriptor = _prepare_vector_response(
            entry.get('vector'),
            {
                'include_vector': config.get('include_vector'),
                'use_shared_memory': config.get('vector_as_shared_memory'),
            },
        )

        response = {
            'success': True,
            'found': True,
            'oid': str(oid),
            'metadata': entry.get('metadata'),
            'stats': entry.get('stats'),
        }

        if vector_payload is not None:
            response['vector'] = vector_payload
        if shm_descriptor is not None:
            response['vector_shm'] = shm_descriptor

        return response

    if action == 'remove':
        oid = config.get('oid') or config.get('id') or config.get('concept_oid')
        if not oid:
            return {'success': False, 'error': 'vector remove requires oid'}

        removed = manager['remove'](str(oid))
        return {
            'success': True,
            'removed': bool(removed),
            'oid': str(oid),
        }

    if action == 'search':
        vector, error = _extract_vector_from_config(config, vector_key='query_vector', shm_key='query_vector_shm')
        if vector is None:
            return {'success': False, 'error': error}

        k = int(config.get('k', 5))
        threshold = float(config.get('threshold', 0.0))

        try:
            results = manager['search_similar'](vector, k=k, threshold=threshold)
        except Exception as exc:  # pragma: no cover - defensive path
            logger.error("L1 search failed: %s", exc)
            return {'success': False, 'error': f"search failed: {exc}"}

        include_vectors = config.get('include_vectors')
        vectors_shared = config.get('vectors_as_shared_memory')

        sanitized: List[Dict[str, Any]] = []
        for entry in results:
            vector_payload, shm_descriptor = _prepare_vector_response(
                entry.get('vector'),
                {
                    'include_vector': include_vectors,
                    'use_shared_memory': vectors_shared,
                },
            )

            item = {
                'oid': entry.get('oid'),
                'similarity_score': entry.get('similarity_score'),
                'metadata': entry.get('metadata'),
                'stats': entry.get('stats'),
            }

            if vector_payload is not None:
                item['vector'] = vector_payload
            if shm_descriptor is not None:
                item['vector_shm'] = shm_descriptor

            sanitized.append(item)

        return {
            'success': True,
            'results': sanitized,
            'count': len(sanitized),
            'k': k,
            'threshold': threshold,
        }

    if action == 'stats':
        stats = manager['get_statistics']()
        return {
            'success': True,
            'statistics': stats,
            'config': dict(_l1_cache_config),
            'faiss_available': FAISS_AVAILABLE,
        }

    if action == 'clear':
        manager['clear']()
        return {'success': True, 'cleared': True}

    if action == 'list_oids':
        oids = sorted(manager['get_all_oids']())
        return {'success': True, 'oids': oids, 'count': len(oids)}

    if action == 'warmup':
        entries = config.get('entries') or []
        inserted = 0
        errors: List[str] = []
        for entry in entries:
            oid = entry.get('oid')
            vector, error = _extract_vector_from_config(entry)
            metadata = entry.get('metadata') or {}
            if vector is None or not oid:
                errors.append(f"invalid entry for oid={oid}: {error}")
                continue
            if manager['put'](str(oid), vector, metadata):
                inserted += 1

        return {
            'success': True,
            'inserted': inserted,
            'errors': errors,
        }

    return {
        'success': False,
        'error': f"Unknown vector operation: {action}",
    }