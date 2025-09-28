#!/usr/bin/env python3
"""
TELOS Prototypal Bridge Cache Proxy Module

This module contains the cache proxy functions for the prototypal bridge.
Extracted from prototypal_bridge.py for modularization compliance.
"""

import logging
from typing import Any, Dict

logger = logging.getLogger(__name__)


def create_transparent_cache_proxy(cache_manager_dict: Dict[str, Any]) -> Dict[str, Any]:
    """
    Create a transparent proxy that delegates cache operations to the appropriate
    L1/L2/L3 cache managers while maintaining prototypal interface semantics.

    This enables Io prototypes to transparently interact with the Python-side
    cache systems without knowing they're crossing language boundaries.

    Args:
        cache_manager_dict: Dictionary containing L1, L2, L3 cache manager interfaces

    Returns:
        dict: Transparent cache proxy interface
    """

    def get_from_cache(key: str, cache_level: str = "auto"):
        """
        Retrieve a value from the appropriate cache level.

        Args:
            key: Cache key to retrieve
            cache_level: "L1", "L2", "L3", or "auto" for automatic selection
        """
        try:
            if cache_level == "auto":
                # Try L1 first (fastest), then L2, then L3
                for level in ["L1", "L2", "L3"]:
                    if level in cache_manager_dict:
                        result = cache_manager_dict[level]['get'](key)
                        if result is not None:
                            return result
                return None
            else:
                # Direct cache level access
                if cache_level in cache_manager_dict:
                    return cache_manager_dict[cache_level]['get'](key)
                else:
                    raise ValueError(f"Unknown cache level: {cache_level}")
        except Exception as e:
            logger.error(f"Cache get operation failed: {e}")
            return None

    def put_in_cache(key: str, value: Any, cache_level: str = "L3"):
        """
        Store a value in the specified cache level.

        Args:
            key: Cache key
            value: Value to store
            cache_level: Target cache level ("L1", "L2", or "L3")
        """
        try:
            if cache_level in cache_manager_dict:
                return cache_manager_dict[cache_level]['put'](key, value)
            else:
                raise ValueError(f"Unknown cache level: {cache_level}")
        except Exception as e:
            logger.error(f"Cache put operation failed: {e}")
            return False

    def search_similar(query_vector: Any, k: int = 5, threshold: float = 0.0):
        """
        Perform similarity search across the cache hierarchy.

        Uses the L1 cache for speed if available, falls back to L2 for comprehensive search.
        """
        try:
            # Try L1 first for speed
            if "L1" in cache_manager_dict:
                result = cache_manager_dict["L1"]['search'](query_vector, k, threshold)
                if result and len(result) >= k:
                    return result

            # Fall back to L2 for comprehensive search
            if "L2" in cache_manager_dict:
                return cache_manager_dict["L2"]['search'](query_vector, k, threshold)

            logger.warning("No suitable cache available for similarity search")
            return []
        except Exception as e:
            logger.error(f"Cache search operation failed: {e}")
            return []

    def invalidate_key(key: str):
        """Invalidate a key across all cache levels."""
        results = {}
        for level in ["L1", "L2", "L3"]:
            if level in cache_manager_dict:
                try:
                    results[level] = cache_manager_dict[level]['remove'](key)
                except Exception as e:
                    logger.error(f"Failed to invalidate {key} from {level}: {e}")
                    results[level] = False
        return results

    return {
        'get': get_from_cache,
        'put': put_in_cache,
        'search': search_similar,
        'invalidate': invalidate_key
    }