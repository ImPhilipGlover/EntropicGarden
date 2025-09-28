"""Concept-level operations for the federated memory fabric."""
from __future__ import annotations

import time
import uuid
from copy import deepcopy
from typing import Any, Callable, Dict, Iterable, List, Optional, Tuple

from .utils import normalize_vector, summarize_scores

ConceptRecord = Dict[str, Any]
ConceptManager = Dict[str, Callable[..., Any]]


def _now() -> float:
    return time.time()


def _vector_dim_from_state(state: Dict[str, Any]) -> Optional[int]:
    config = state.get("config", {})
    candidate = None
    if isinstance(config, dict):
        for layer in ("l1", "l2"):
            layer_config = config.get(layer)
            if isinstance(layer_config, dict) and "vector_dim" in layer_config:
                candidate = layer_config.get("vector_dim")
    try:
        if candidate is None:
            return None
        vector_dim = int(candidate)
        return vector_dim if vector_dim > 0 else None
    except Exception:
        return None


def _prepare_metadata(payload: Dict[str, Any]) -> Dict[str, Any]:
    metadata = payload.get("metadata")
    if not isinstance(metadata, dict):
        return {}
    return deepcopy(metadata)


def _vector_from_payload(payload: Dict[str, Any], *, expected_dim: Optional[int]) -> Optional[Any]:
    if "vector" in payload:
        source = payload.get("vector")
    else:
        source = payload.get("geometric_embedding")
    if source is None:
        return None
    return normalize_vector(source, expected_dim=expected_dim)


def _cache_metadata(record: ConceptRecord) -> Dict[str, Any]:
    metadata = deepcopy(record.get("metadata", {}))
    if record.get("name") is not None:
        metadata.setdefault("name", record["name"])
    metadata.setdefault("created_at", record.get("created_at"))
    metadata.setdefault("updated_at", record.get("updated_at"))
    return metadata


def _export_record(record: ConceptRecord, *, include_vector: bool = False) -> Dict[str, Any]:
    payload = {
        "oid": record.get("oid"),
        "name": record.get("name"),
        "metadata": deepcopy(record.get("metadata", {})),
        "created_at": record.get("created_at"),
        "updated_at": record.get("updated_at"),
    }
    if include_vector and record.get("vector") is not None:
        payload["geometric_embedding"] = record["vector"].tolist()
    return payload


def _propagate_to_caches(
    record: ConceptRecord,
    *,
    l1_manager: Optional[Dict[str, Any]],
    l2_manager: Optional[Dict[str, Any]],
) -> None:
    vector = record.get("vector")
    if vector is None:
        return
    metadata = _cache_metadata(record)
    if l2_manager and l2_manager.get("put"):
        try:
            l2_manager["put"](record["oid"], vector, metadata)
        except Exception:
            pass
    if l1_manager and l1_manager.get("put"):
        try:
            l1_manager["put"](record["oid"], vector, metadata)
        except Exception:
            pass


def _evict_from_caches(
    oid: str,
    *,
    l1_manager: Optional[Dict[str, Any]],
    l2_manager: Optional[Dict[str, Any]],
) -> List[str]:
    removed: List[str] = []
    if l1_manager and l1_manager.get("remove"):
        try:
            if l1_manager["remove"](oid):
                removed.append("l1")
        except Exception:
            pass
    if l2_manager and l2_manager.get("remove"):
        try:
            if l2_manager["remove"](oid):
                removed.append("l2")
        except Exception:
            pass
    return removed


def _persist_record(
    record: ConceptRecord,
    *,
    l3_store: Optional[Dict[str, Any]],
    delete: bool = False,
) -> None:
    if not l3_store:
        return
    if delete:
        delete_fn = l3_store.get("delete_concept")
        if delete_fn:
            try:
                delete_fn(record["oid"])
            except Exception:
                pass
        return
    store_fn = l3_store.get("store_concept")
    if store_fn:
        try:
            store_fn(_export_record(record, include_vector=True))
        except Exception:
            pass


def _hydrate_record(payload: Dict[str, Any], *, vector_dim: Optional[int]) -> ConceptRecord:
    metadata = _prepare_metadata(payload)
    vector = _vector_from_payload(payload, expected_dim=vector_dim)
    created_at = payload.get("created_at", _now())
    updated_at = payload.get("updated_at", created_at)
    return {
        "oid": payload.get("oid"),
        "name": payload.get("name"),
        "metadata": metadata,
        "vector": vector,
        "created_at": created_at,
        "updated_at": updated_at,
    }


def create_concept_manager(
    state: Dict[str, Any],
    *,
    l1_manager: Optional[Dict[str, Any]] = None,
    l2_manager: Optional[Dict[str, Any]] = None,
    l3_store: Optional[Dict[str, Any]] = None,
) -> ConceptManager:
    """Return a prototype-style concept manager bound to *state*."""

    concept_lock = state.setdefault("locks", {}).setdefault("concepts", None)
    if concept_lock is None:
        raise ValueError("state missing concepts lock")

    def _concept_store() -> Dict[str, ConceptRecord]:
        return state.setdefault("concept_store", {})

    vector_dim = _vector_dim_from_state(state)

    def _with_lock(fn: Callable[[], Any]) -> Any:
        with concept_lock:
            return fn()

    def create(payload: Dict[str, Any], *, propagate: bool = True, persist: bool = True) -> Dict[str, Any]:
        if not isinstance(payload, dict):
            return {"success": False, "error": "payload must be a mapping"}
        oid = str(payload.get("oid") or f"concept/{uuid.uuid4()}")
        record = _hydrate_record({**payload, "oid": oid}, vector_dim=vector_dim)
        record["created_at"] = _now()
        record["updated_at"] = record["created_at"]

        def _store() -> ConceptRecord:
            store = _concept_store()
            store[oid] = record
            return record

        stored_record = _with_lock(_store)

        if propagate:
            _propagate_to_caches(stored_record, l1_manager=l1_manager, l2_manager=l2_manager)
        if persist:
            _persist_record(stored_record, l3_store=l3_store)

        return {"success": True, "oid": oid, "concept": _export_record(stored_record)}

    def load(oid: str, *, include_vector: bool = False, refresh_caches: bool = False) -> Optional[Dict[str, Any]]:
        if not oid:
            return None

        def _local_lookup() -> Optional[ConceptRecord]:
            return _concept_store().get(oid)

        record = _with_lock(_local_lookup)
        if record is None and l3_store and l3_store.get("load_concept"):
            persisted = l3_store["load_concept"](oid)
            if persisted:
                hydrated = _hydrate_record(persisted, vector_dim=vector_dim)

                def _store_hydrated() -> ConceptRecord:
                    store = _concept_store()
                    store[oid] = hydrated
                    return hydrated

                record = _with_lock(_store_hydrated)
        if record is None:
            return None

        if refresh_caches:
            _propagate_to_caches(record, l1_manager=l1_manager, l2_manager=l2_manager)

        return _export_record(record, include_vector=include_vector)

    def update(oid: str, updates: Dict[str, Any], *, propagate: bool = True, persist: bool = True) -> Dict[str, Any]:
        if not isinstance(updates, dict):
            return {"success": False, "error": "updates must be a mapping"}

        def _mutate() -> Tuple[bool, Optional[ConceptRecord]]:
            store = _concept_store()
            record = store.get(oid)
            if record is None:
                return False, None
            changed = False
            if "name" in updates:
                record["name"] = updates.get("name")
                changed = True
            if "metadata" in updates and isinstance(updates.get("metadata"), dict):
                record.setdefault("metadata", {}).update(deepcopy(updates["metadata"]))
                changed = True
            if "vector" in updates or "geometric_embedding" in updates:
                vector = _vector_from_payload(updates, expected_dim=vector_dim)
                record["vector"] = vector
                changed = True
            if changed:
                record["updated_at"] = _now()
            return changed, record

        changed, record = _with_lock(_mutate)
        if not changed or record is None:
            return {"success": False, "error": "concept not found or no changes"}

        vector = record.get("vector")
        if propagate:
            if vector is not None:
                _propagate_to_caches(record, l1_manager=l1_manager, l2_manager=l2_manager)
            else:
                _evict_from_caches(oid, l1_manager=l1_manager, l2_manager=l2_manager)
        if persist:
            _persist_record(record, l3_store=l3_store)

        return {"success": True, "concept": _export_record(record)}

    def delete(oid: str, *, remove_from_caches: bool = True, remove_from_store: bool = True) -> Dict[str, Any]:
        def _remove() -> Optional[ConceptRecord]:
            return _concept_store().pop(oid, None)

        record = _with_lock(_remove)
        if record is None:
            return {"success": False, "error": "concept not found"}

        removed_levels: List[str] = []
        if remove_from_caches:
            removed_levels = _evict_from_caches(oid, l1_manager=l1_manager, l2_manager=l2_manager)
        if remove_from_store:
            _persist_record(record, l3_store=l3_store, delete=True)

        return {
            "success": True,
            "oid": oid,
            "removed_levels": removed_levels,
        }

    def list_all(*, include_vector: bool = False) -> List[Dict[str, Any]]:
        def _snapshot() -> List[Dict[str, Any]]:
            return [_export_record(record, include_vector=include_vector) for record in _concept_store().values()]

        return _with_lock(_snapshot)

    def semantic_search(
        vector: Iterable[float],
        *,
        k: int = 5,
        threshold: float = 0.0,
        include_metadata: bool = True,
    ) -> Dict[str, Any]:
        if not l2_manager or not l2_manager.get("search_similar"):
            return {"matches": [], "summary": {"count": 0, "avg": 0.0, "max": 0.0}}
        query_vector = _vector_from_payload({"vector": vector}, expected_dim=vector_dim)
        if query_vector is None:
            return {"matches": [], "summary": {"count": 0, "avg": 0.0, "max": 0.0}}
        try:
            raw_results = l2_manager["search_similar"](query_vector, k=k, threshold=threshold)
        except Exception:
            return {"matches": [], "summary": {"count": 0, "avg": 0.0, "max": 0.0}}

        matches: List[Dict[str, Any]] = []
        for item in raw_results or []:
            if isinstance(item, tuple) and len(item) == 2:
                oid, score = item
            elif isinstance(item, dict):
                oid = item.get("oid")
                score = item.get("score", item.get("similarity_score"))
            else:
                continue
            concept = load(oid, include_vector=False) if include_metadata else {"oid": oid}
            if concept is None:
                concept = {"oid": oid}
            concept["score"] = float(score or 0.0)
            matches.append(concept)

        summary = summarize_scores(matches)
        return {"matches": matches, "summary": summary}

    def refresh_cache(oid: str) -> Dict[str, Any]:
        concept = load(oid, include_vector=False)
        if concept is None:
            return {"success": False, "error": "concept not found"}
        record = _with_lock(lambda: _concept_store().get(oid))
        if record is None:
            return {"success": False, "error": "concept missing from state"}
        _propagate_to_caches(record, l1_manager=l1_manager, l2_manager=l2_manager)
        return {"success": True, "oid": oid}

    def statistics() -> Dict[str, Any]:
        def _snapshot() -> Dict[str, Any]:
            store = _concept_store()
            return {
                "count": len(store),
                "vector_dim": vector_dim,
                "has_l1": bool(l1_manager),
                "has_l2": bool(l2_manager),
                "has_l3": bool(l3_store),
            }

        return _with_lock(_snapshot)

    return {
        "create": create,
        "load": load,
        "update": update,
        "delete": delete,
        "list": list_all,
        "semantic_search": semantic_search,
        "refresh_cache": refresh_cache,
        "statistics": statistics,
    }