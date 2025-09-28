"""Local prototype-based cache managers for the federated memory fabric."""
from __future__ import annotations

import itertools
from threading import Lock
from typing import Any, Dict, Iterable, List, Optional, Tuple

from .utils import clamp_positive_int, cosine_similarity, epoch_seconds, normalize_vector


def _copy_entry(entry: Dict[str, Any], *, include_vector: bool = True) -> Dict[str, Any]:
    vector = entry.get("vector")
    return {
        "oid": entry["oid"],
        "metadata": entry.get("metadata", {}).copy(),
        "stats": entry.get("stats", {}).copy(),
        **({"vector": vector.copy()} if include_vector and vector is not None else {}),
    }


def create_l1_cache_manager(config: Dict[str, Any], state: Dict[str, Any]) -> Dict[str, Any]:
    """Create an in-memory L1 cache manager prototype."""

    max_size = clamp_positive_int(config.get("max_size"), fallback=2048)
    vector_dim = clamp_positive_int(config.get("vector_dim"), fallback=64)
    promotion_threshold = clamp_positive_int(config.get("promotion_threshold"), fallback=2)

    store: Dict[str, Dict[str, Any]] = {}
    lock = Lock()

    def _flag_candidate(entry: Dict[str, Any]) -> None:
        with state["locks"]["promotion"]:
            pending = state["promotion"]["pending"]
            if any(item["oid"] == entry["oid"] for item in pending):
                return
            pending.append(_copy_entry(entry, include_vector=True))

    def put(oid: str, vector: Any, metadata: Optional[Dict[str, Any]] = None) -> bool:
        with lock:
            if len(store) >= max_size and oid not in store:
                oldest_oid = next(iter(store))
                del store[oldest_oid]
            entry = {
                "oid": oid,
                "vector": normalize_vector(vector, expected_dim=vector_dim),
                "metadata": (metadata or {}).copy(),
                "stats": {
                    "created_at": epoch_seconds(),
                    "last_access": epoch_seconds(),
                    "access_count": 0,
                },
            }
            store[oid] = entry
        return True

    def get(oid: str) -> Optional[Dict[str, Any]]:
        with lock:
            entry = store.get(oid)
            if entry is None:
                return None
            entry["stats"]["last_access"] = epoch_seconds()
            entry["stats"]["access_count"] += 1
            if entry["stats"]["access_count"] >= promotion_threshold:
                _flag_candidate(entry)
            return _copy_entry(entry)

    def peek_promotions(limit: Optional[int] = None) -> List[Dict[str, Any]]:
        with state["locks"]["promotion"]:
            pending = state["promotion"]["pending"]
            if limit is None:
                return [_copy_entry(entry) for entry in pending]
            return [_copy_entry(entry) for entry in itertools.islice(pending, limit)]

    def drain_promotions(limit: Optional[int] = None) -> List[Dict[str, Any]]:
        with state["locks"]["promotion"]:
            pending = state["promotion"]["pending"]
            if limit is None or limit >= len(pending):
                drained = pending[:]
                pending.clear()
                return [_copy_entry(entry) for entry in drained]
            drained = pending[:limit]
            del pending[:limit]
            return [_copy_entry(entry) for entry in drained]

    def requeue(entry: Dict[str, Any]) -> None:
        with state["locks"]["promotion"]:
            state["promotion"]["pending"].append(_copy_entry(entry))

    def remove(oid: str) -> bool:
        with lock:
            existed = oid in store
            store.pop(oid, None)
        return existed

    def clear() -> None:
        with lock:
            store.clear()
        with state["locks"]["promotion"]:
            state["promotion"]["pending"].clear()

    def search_similar(vector: Any, k: int = 5, threshold: float = 0.0) -> List[Tuple[str, float]]:
        query = normalize_vector(vector, expected_dim=vector_dim)
        if query is None:
            return []
        with lock:
            scores = []
            for entry in store.values():
                candidate = entry.get("vector")
                if candidate is None:
                    continue
                score = cosine_similarity(query, candidate)
                if score >= threshold:
                    scores.append((entry["oid"], score))
            scores.sort(key=lambda item: item[1], reverse=True)
            return scores[:k]

    def get_statistics() -> Dict[str, Any]:
        with lock:
            return {
                "count": len(store),
                "max_size": max_size,
                "promotion_threshold": promotion_threshold,
            }

    def get_all_oids() -> List[str]:
        with lock:
            return list(store.keys())

    return {
        "put": put,
        "get": get,
        "remove": remove,
        "clear": clear,
        "search_similar": search_similar,
        "get_statistics": get_statistics,
        "get_all_oids": get_all_oids,
        "peek_promotions": peek_promotions,
        "drain_promotions": drain_promotions,
        "requeue_promotion": requeue,
    }


def create_l2_cache_manager(config: Dict[str, Any]) -> Dict[str, Any]:
    """Create an in-memory L2 cache manager prototype."""

    max_size = clamp_positive_int(config.get("max_size"), fallback=16384)
    vector_dim = clamp_positive_int(config.get("vector_dim"), fallback=64)

    store: Dict[str, Dict[str, Any]] = {}
    lock = Lock()

    def put(oid: str, vector: Any, metadata: Optional[Dict[str, Any]] = None) -> bool:
        with lock:
            if len(store) >= max_size and oid not in store:
                oldest_oid = next(iter(store))
                del store[oldest_oid]
            store[oid] = {
                "oid": oid,
                "vector": normalize_vector(vector, expected_dim=vector_dim),
                "metadata": (metadata or {}).copy(),
                "stats": {
                    "created_at": epoch_seconds(),
                    "last_access": epoch_seconds(),
                    "access_count": 0,
                },
            }
        return True

    def get(oid: str) -> Optional[Dict[str, Any]]:
        with lock:
            entry = store.get(oid)
            if entry is None:
                return None
            entry["stats"]["last_access"] = epoch_seconds()
            entry["stats"]["access_count"] += 1
            return _copy_entry(entry)

    def remove(oid: str) -> bool:
        with lock:
            existed = oid in store
            store.pop(oid, None)
        return existed

    def clear() -> None:
        with lock:
            store.clear()

    def search_similar(vector: Any, k: int = 10, threshold: float = 0.0) -> List[Tuple[str, float]]:
        query = normalize_vector(vector, expected_dim=vector_dim)
        if query is None:
            return []
        with lock:
            scores = []
            for entry in store.values():
                candidate = entry.get("vector")
                if candidate is None:
                    continue
                score = cosine_similarity(query, candidate)
                if score >= threshold:
                    scores.append((entry["oid"], score))
            scores.sort(key=lambda item: item[1], reverse=True)
            return scores[:k]

    def get_statistics() -> Dict[str, Any]:
        with lock:
            return {
                "count": len(store),
                "max_size": max_size,
                "vector_dim": vector_dim,
            }

    def get_all_entries() -> List[Dict[str, Any]]:
        with lock:
            return [_copy_entry(entry) for entry in store.values()]

    return {
        "put": put,
        "get": get,
        "remove": remove,
        "clear": clear,
        "search_similar": search_similar,
        "get_statistics": get_statistics,
        "get_all_entries": get_all_entries,
    }


def create_l3_store() -> Dict[str, Any]:
    """Create a simple concept store prototype."""

    store: Dict[str, Dict[str, Any]] = {}
    lock = Lock()

    def store_concept(concept: Dict[str, Any]) -> None:
        with lock:
            store[concept["oid"]] = concept

    def load_concept(oid: str) -> Optional[Dict[str, Any]]:
        with lock:
            item = store.get(oid)
            return item.copy() if item else None

    def delete_concept(oid: str) -> bool:
        with lock:
            return store.pop(oid, None) is not None

    def all_concepts() -> Iterable[Dict[str, Any]]:
        with lock:
            return [concept.copy() for concept in store.values()]

    return {
        "store_concept": store_concept,
        "load_concept": load_concept,
        "delete_concept": delete_concept,
        "all_concepts": all_concepts,
    }
