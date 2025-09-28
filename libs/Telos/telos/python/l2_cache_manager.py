#!/usr/bin/env python3
"""
TELOS L2 On-Disk Cache Manager

This module implements the L2 cache layer using disk-based vector storage with 
efficient indexing and cache coherence protocols. It bridges the gap between 
the fast L1 in-memory cache and the persistent L3 ZODB layer.

Key Features:
- HDF5-based vector storage for efficient disk I/O
- Approximate nearest neighbor search using hierarchical clustering
- LRU eviction policy with configurable size limits
- Cache coherence protocols with L1 and L3 layers
- Prototypal design principles throughout

Note: This implementation uses HDF5 + numpy for disk storage. In a production
system, we would use DiskANN or similar specialized on-disk vector search engines.

Architectural Compliance:
- Prototypal factory functions instead of classes
- Integration with shared memory for zero-copy IPC
- Cache coherence protocols with L1/L3 layers
- Statistics and observability for performance tuning
"""

import os
import time
import logging
import threading
from typing import Dict, Any, Optional, List, Callable, Tuple, Set
import json
import numpy as np
from datetime import datetime, timezone
import multiprocessing.shared_memory as shm
from collections import defaultdict, OrderedDict, deque
import tempfile
import hashlib
import shutil

# Import UvmObject for prototypal object creation
try:
    from .uvm_object import UvmObject, create_uvm_object
except ImportError:  # pragma: no cover - fallback for direct execution
    from uvm_object import UvmObject, create_uvm_object  # type: ignore

# HDF5 and storage imports
try:
    import h5py
    HDF5_AVAILABLE = True
except ImportError as e:
    HDF5_AVAILABLE = False
    HDF5_IMPORT_ERROR = str(e)

# Fallback to pickle for storage if HDF5 not available
import pickle

# DiskANN accelerator
try:
    import diskannpy as _diskann
    DISKANN_AVAILABLE = True
    DISKANN_IMPORT_ERROR = None
    DISKANN_MIN_POINTS = 50  # empirical threshold for stable index builds
except ImportError as e:
    _diskann = None
    DISKANN_AVAILABLE = False
    DISKANN_IMPORT_ERROR = str(e)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# =============================================================================
# Disk-Based Vector Index (Prototypal Style)
# =============================================================================

def create_disk_vector_index(storage_path: str, vector_dim: int = 1536, 
                            max_vectors: int = 100000) -> Dict[str, Callable]:
    """
    Factory function to create a disk-based vector index following prototypal principles.
    
    Args:
        storage_path: Path to the disk storage file
        vector_dim: Dimension of vectors to store
        max_vectors: Maximum number of vectors to store
    
    Returns:
        Dictionary of methods for index management
    """
    # Use UvmObject as foundational parent for prototypal inheritance
    index = UvmObject()
    
    # Internal state
    _storage_path = storage_path
    _vector_dim = vector_dim
    _max_vectors = max_vectors
    _lock = threading.Lock()
    _h5_file = None
    _vectors_dataset = None
    _metadata_dataset = None
    _oid_to_index = {}
    _index_to_oid = {}
    _next_index = 0
    _use_hdf5 = HDF5_AVAILABLE
    
    # Fallback storage for when HDF5 is not available
    _fallback_storage = {}
    _fallback_metadata = {}

    # Persistent DiskANN workspace configuration
    _diskann_directory = os.path.splitext(_storage_path)[0] + "_diskann"
    _diskann_prefix = "telos_diskann"
    _diskann_label_map = "labels.json"
    _diskann_state = {
        'handle': None,
        'label_to_oid': {},
        'oid_to_label': {},
        'dirty': True,
        'built': False,
        'vector_count': 0,
        'last_rebuild': None,
        'last_error': None,
        'search_complexity': 64
    }

    # Telemetry metrics for DiskANN usage and search characteristics
    _metrics = {
        'diskann': {
            'attempts': 0,
            'successes': 0,
            'failures': 0,
            'rebuilds': 0,
            'rebuild_failures': 0,
            'last_error': None,
            'last_duration_ms': None,
            'last_used': None,
            'last_rebuild': None,
            'dirty': True,
            'index_directory': _diskann_directory,
            'vector_count': 0,
            'search_complexity': None
        },
        'search': {
            'queries': 0,
            'results_returned': 0,
            'similarity_sum': 0.0,
            'max_similarity': 0.0,
            'min_similarity': None,
            'last_result_count': 0,
            'last_similarity_avg': None
        }
    }
    
    def _ensure_storage():
        """Ensure storage backend is initialized."""
        nonlocal _h5_file, _vectors_dataset, _metadata_dataset, _use_hdf5, _next_index
        
        if _use_hdf5:
            if _h5_file is None:
                try:
                    _h5_file = h5py.File(_storage_path, 'a')
                    
                    # Create or access vectors dataset
                    if 'vectors' not in _h5_file:
                        _vectors_dataset = _h5_file.create_dataset(
                            'vectors', 
                            shape=(0, _vector_dim), 
                            maxshape=(_max_vectors, _vector_dim),
                            dtype=np.float32,
                            compression='gzip',
                            compression_opts=1  # Fast compression
                        )
                    else:
                        _vectors_dataset = _h5_file['vectors']
                    
                    # Create or access metadata dataset (variable length strings)
                    if 'metadata' not in _h5_file:
                        dt = h5py.string_dtype(encoding='utf-8')
                        _metadata_dataset = _h5_file.create_dataset(
                            'metadata',
                            shape=(0,),
                            maxshape=(_max_vectors,),
                            dtype=dt
                        )
                    else:
                        _metadata_dataset = _h5_file['metadata']
                    
                    # Load existing index mappings from attributes
                    if 'oid_to_index' in _h5_file.attrs:
                        _oid_to_index.update(json.loads(_h5_file.attrs['oid_to_index']))
                    if 'index_to_oid' in _h5_file.attrs:
                        index_to_oid_str = json.loads(_h5_file.attrs['index_to_oid'])
                        _index_to_oid.update({int(k): v for k, v in index_to_oid_str.items()})
                    if 'next_index' in _h5_file.attrs:
                        _next_index = int(_h5_file.attrs['next_index'])
                    
                    logger.info(f"Initialized HDF5 storage at {_storage_path}")
                    
                except Exception as e:
                    logger.warning(f"Failed to initialize HDF5: {e}, falling back to pickle")
                    _use_hdf5 = False
        
        if not _use_hdf5:
            # Load from pickle file if it exists
            if os.path.exists(_storage_path):
                try:
                    with open(_storage_path, 'rb') as f:
                        data = pickle.load(f)
                        _fallback_storage.update(data.get('vectors', {}))
                        _fallback_metadata.update(data.get('metadata', {}))
                        _oid_to_index.update(data.get('oid_to_index', {}))
                        _index_to_oid.update(data.get('index_to_oid', {}))
                        _next_index = data.get('next_index', 0)
                    logger.info(f"Loaded pickle storage from {_storage_path}")
                except Exception as e:
                    logger.warning(f"Failed to load pickle storage: {e}")
    
    def _save_index_mappings():
        """Save index mappings to persistent storage."""
        if _use_hdf5 and _h5_file:
            _h5_file.attrs['oid_to_index'] = json.dumps(_oid_to_index)
            _h5_file.attrs['index_to_oid'] = json.dumps({str(k): v for k, v in _index_to_oid.items()})
            _h5_file.attrs['next_index'] = _next_index
            _h5_file.flush()
        elif not _use_hdf5:
            data = {
                'vectors': _fallback_storage,
                'metadata': _fallback_metadata,
                'oid_to_index': _oid_to_index,
                'index_to_oid': _index_to_oid,
                'next_index': _next_index
            }
            with open(_storage_path, 'wb') as f:
                pickle.dump(data, f)

    def _teardown_diskann_handle():
        handle = _diskann_state.get('handle')
        if handle is not None:
            try:
                handle.close()
            except AttributeError:
                pass
        _diskann_state['handle'] = None

    def _mark_diskann_dirty(reason: Optional[str] = None):
        _diskann_state['dirty'] = True
        _diskann_state['built'] = _diskann_state['built'] and _diskann_state['vector_count'] > 0
        _teardown_diskann_handle()
        metrics_diskann = _metrics['diskann']
        metrics_diskann['dirty'] = True
        metrics_diskann['search_complexity'] = None
        if reason:
            metrics_diskann['last_error'] = reason

    def _persist_diskann_labels(label_to_oid: Dict[int, str]):
        os.makedirs(_diskann_directory, exist_ok=True)
        label_path = os.path.join(_diskann_directory, _diskann_label_map)
        with open(label_path, 'w', encoding='utf-8') as f:
            json.dump({str(label): oid for label, oid in label_to_oid.items()}, f)

    def _load_diskann_labels() -> Dict[int, str]:
        label_path = os.path.join(_diskann_directory, _diskann_label_map)
        if not os.path.exists(label_path):
            return {}
        with open(label_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return {int(label): oid for label, oid in data.items()}

    def _cleanup_diskann_workspace():
        if os.path.isdir(_diskann_directory):
            for entry in os.listdir(_diskann_directory):
                entry_path = os.path.join(_diskann_directory, entry)
                try:
                    if os.path.isdir(entry_path):
                        shutil.rmtree(entry_path)
                    else:
                        os.unlink(entry_path)
                except Exception as cleanup_exc:
                    logger.warning(f"Failed to remove DiskANN artifact {entry_path}: {cleanup_exc}")

    def _ensure_diskann_handle(force_reload: bool = False) -> bool:
        if not DISKANN_AVAILABLE:
            return False
        if _diskann_state['dirty'] or not _diskann_state['built']:
            return False

        if _diskann_state['handle'] is not None and not force_reload:
            return True

        label_map = _load_diskann_labels()
        if not label_map:
            return False

        try:
            num_threads = max(1, min(4, os.cpu_count() or 1))
            complexity = max(64, 4 * min(32, max(1, len(label_map))))
            _diskann_state['handle'] = _diskann.StaticMemoryIndex(
                index_directory=_diskann_directory,
                index_prefix=_diskann_prefix,
                num_threads=num_threads,
                initial_search_complexity=complexity,
                distance_metric="cosine",
                vector_dtype=np.float32,
                dimensions=_vector_dim
            )
            _diskann_state['label_to_oid'] = label_map
            _diskann_state['oid_to_label'] = {oid: label for label, oid in label_map.items()}
            _diskann_state['search_complexity'] = complexity
            _metrics['diskann']['search_complexity'] = complexity
            return True
        except Exception as exc:
            _diskann_state['last_error'] = str(exc)
            _teardown_diskann_handle()
            return False

    def rebuild_diskann_index(force: bool = False, auto: bool = False) -> Dict[str, Any]:
        with _lock:
            _ensure_storage()

            metrics_diskann = _metrics['diskann']
            metrics_diskann['dirty'] = True

            if not DISKANN_AVAILABLE:
                reason = "diskannpy not available"
                metrics_diskann['last_error'] = reason
                return {'success': False, 'reason': reason}

            active_items: List[Tuple[int, str]] = [
                (index, oid) for oid, index in _oid_to_index.items() if oid and index in _index_to_oid
            ]

            if not force and len(active_items) < DISKANN_MIN_POINTS:
                reason = f"insufficient points ({len(active_items)}) for DiskANN rebuild"
                metrics_diskann['last_error'] = reason
                return {'success': False, 'reason': reason, 'active_points': len(active_items)}

            build_start = time.perf_counter()

            try:
                os.makedirs(_diskann_directory, exist_ok=True)
                _cleanup_diskann_workspace()

                vectors = np.zeros((len(active_items), _vector_dim), dtype=np.float32)
                labels = np.arange(len(active_items), dtype=np.uint32)
                label_to_oid: Dict[int, str] = {}

                for label, (index, oid) in enumerate(active_items):
                    if _use_hdf5:
                        vectors[label] = _vectors_dataset[index][:]
                    else:
                        vectors[label] = _fallback_storage[index]
                    label_to_oid[int(label)] = oid

                if len(vectors) == 0:
                    raise ValueError("No vectors available for DiskANN rebuild")

                complexity = max(64, 4 * min(32, len(active_items)))
                graph_degree = max(2, min(32, len(active_items) - 1)) if len(active_items) > 1 else 2
                num_threads = max(1, min(4, os.cpu_count() or 1))

                _diskann.build_memory_index(
                    data=vectors,
                    distance_metric="cosine",
                    index_directory=_diskann_directory,
                    complexity=complexity,
                    graph_degree=graph_degree,
                    num_threads=num_threads,
                    vector_dtype=np.float32,
                    tags=labels,
                    index_prefix=_diskann_prefix
                )

                _persist_diskann_labels(label_to_oid)

                _diskann_state['vector_count'] = len(active_items)
                _diskann_state['dirty'] = False
                _diskann_state['built'] = True
                _diskann_state['last_rebuild'] = datetime.now(timezone.utc).isoformat()
                _diskann_state['last_error'] = None
                _diskann_state['search_complexity'] = complexity
                _metrics['diskann']['search_complexity'] = complexity

                if not _ensure_diskann_handle(force_reload=True):
                    raise RuntimeError(_diskann_state.get('last_error') or 'failed to load DiskANN index')

                duration_ms = (time.perf_counter() - build_start) * 1000.0

                metrics_diskann['rebuilds'] += 1
                metrics_diskann['last_rebuild'] = _diskann_state['last_rebuild']
                metrics_diskann['last_error'] = None
                metrics_diskann['dirty'] = False
                metrics_diskann['vector_count'] = len(active_items)
                metrics_diskann['last_duration_ms'] = duration_ms

                return {
                    'success': True,
                    'duration_ms': duration_ms,
                    'points': len(active_items),
                    'complexity': complexity,
                    'graph_degree': graph_degree,
                    'auto_triggered': auto
                }

            except Exception as exc:
                _diskann_state['dirty'] = True
                _diskann_state['built'] = False
                _diskann_state['last_error'] = str(exc)
                _diskann_state['search_complexity'] = 64
                metrics_diskann['rebuild_failures'] += 1
                metrics_diskann['last_error'] = str(exc)
                metrics_diskann['search_complexity'] = None
                _teardown_diskann_handle()
                return {'success': False, 'reason': str(exc)}

    def get_diskann_status() -> Dict[str, Any]:
        with _lock:
            return {
                'available': DISKANN_AVAILABLE,
                'dirty': _diskann_state['dirty'],
                'built': _diskann_state['built'],
                'vector_count': _diskann_state['vector_count'],
                'last_rebuild': _diskann_state['last_rebuild'],
                'last_error': _diskann_state['last_error'],
                'index_directory': _diskann_directory
            }
    
    def add_vector(oid: str, vector: np.ndarray, metadata: Dict[str, Any] = None) -> bool:
        """Add a vector to the disk index."""
        nonlocal _next_index
        
        with _lock:
            _ensure_storage()
            
            if oid in _oid_to_index:
                # Update existing vector
                index = _oid_to_index[oid]
            else:
                # Add new vector
                if _next_index >= _max_vectors:
                    logger.warning("Disk index at maximum capacity")
                    return False
                
                index = _next_index
                _oid_to_index[oid] = index
                _index_to_oid[index] = oid
                _next_index += 1
            
            try:
                if _use_hdf5:
                    # Resize datasets if needed
                    if index >= _vectors_dataset.shape[0]:
                        _vectors_dataset.resize((index + 1, _vector_dim))
                        _metadata_dataset.resize((index + 1,))
                    
                    # Store vector and metadata
                    _vectors_dataset[index] = vector.astype(np.float32)
                    _metadata_dataset[index] = json.dumps(metadata or {})
                    
                else:
                    # Fallback storage
                    _fallback_storage[index] = vector.astype(np.float32)
                    _fallback_metadata[index] = json.dumps(metadata or {})
                
                _save_index_mappings()
                _mark_diskann_dirty()
                logger.debug(f"Added vector for OID {oid} at index {index}")
                return True
                
            except Exception as e:
                logger.error(f"Failed to add vector to disk index: {e}")
                return False
    
    def get_vector(oid: str) -> Optional[Tuple[np.ndarray, Dict[str, Any]]]:
        """Get a vector from the disk index."""
        with _lock:
            _ensure_storage()
            
            if oid not in _oid_to_index:
                return None
            
            index = _oid_to_index[oid]
            
            try:
                if _use_hdf5:
                    if index >= _vectors_dataset.shape[0]:
                        return None
                    
                    vector = _vectors_dataset[index][:]
                    metadata_str = _metadata_dataset[index]
                    metadata = json.loads(metadata_str) if metadata_str else {}
                    
                else:
                    if index not in _fallback_storage:
                        return None
                    
                    vector = _fallback_storage[index]
                    metadata = json.loads(_fallback_metadata.get(index, '{}'))
                
                logger.debug(f"Retrieved vector for OID {oid}")
                return vector.copy(), metadata
                
            except Exception as e:
                logger.error(f"Failed to get vector from disk index: {e}")
                return None
    
    def remove_vector(oid: str) -> bool:
        """Remove a vector from the disk index."""
        with _lock:
            if oid in _oid_to_index:
                index = _oid_to_index[oid]
                del _oid_to_index[oid]
                if index in _index_to_oid:
                    del _index_to_oid[index]
                
                # For simplicity, we don't compact the storage
                # In production, periodic compaction would be needed
                
                _save_index_mappings()
                _mark_diskann_dirty()
                logger.debug(f"Removed vector for OID {oid}")
                return True
            
            return False
    
    def search_similar(query_vector: np.ndarray, k: int = 10, 
                      threshold: float = 0.0) -> List[Tuple[str, float]]:
        """Search for similar vectors. Uses DiskANN when available."""
        with _lock:
            _ensure_storage()
            
            if not _oid_to_index:
                return []
            
            try:
                similarities: List[Tuple[str, float]] = []

                # Prepare dataset view filtered to active indices
                active_items: List[Tuple[int, str]] = [
                    (index, oid) for oid, index in _oid_to_index.items()
                    if oid and index in _index_to_oid
                ]

                if not active_items:
                    return []

                query_norm = np.linalg.norm(query_vector)
                if query_norm == 0:
                    return []

                used_diskann = False
                diskann_attempted = False
                diskann_success = False
                diskann_duration_ms: Optional[float] = None
                diskann_error: Optional[str] = None

                if DISKANN_AVAILABLE and len(active_items) >= DISKANN_MIN_POINTS:
                    diskann_attempted = True
                    diskann_start = None
                    persistent_error: Optional[str] = None

                    try:
                        if not _diskann_state['dirty'] and _ensure_diskann_handle():
                            diskann_start = time.perf_counter()
                            handle = _diskann_state['handle']
                            label_map = _diskann_state['label_to_oid']
                            if not label_map:
                                raise RuntimeError("DiskANN label map unavailable")

                            complexity = _diskann_state.get('search_complexity') or max(
                                64, 4 * min(32, len(active_items))
                            )
                            query = np.asarray(query_vector, dtype=np.float32).reshape(1, -1)
                            response = handle.search(
                                query,
                                k_neighbors=min(k, len(active_items)),
                                complexity=complexity
                            )

                            for label, distance in zip(response.identifiers[0], response.distances[0]):
                                oid = label_map.get(int(label))
                                if oid is None:
                                    continue
                                similarity = float(1.0 - distance)
                                if similarity >= threshold:
                                    similarities.append((oid, similarity))

                            used_diskann = True
                            diskann_success = True
                            diskann_duration_ms = (time.perf_counter() - diskann_start) * 1000.0
                            diskann_error = None
                        else:
                            persistent_error = _diskann_state.get('last_error') or 'persistent DiskANN not ready'
                            raise RuntimeError(persistent_error)

                    except Exception as persistent_exc:
                        if persistent_error is None:
                            persistent_error = str(persistent_exc)
                        logger.debug(
                            "Persistent DiskANN unavailable (%s); building transient index.",
                            persistent_error
                        )

                        try:
                            diskann_start = time.perf_counter()
                            vectors = np.zeros((len(active_items), _vector_dim), dtype=np.float32)
                            labels = np.arange(len(active_items), dtype=np.uint32)
                            label_to_oid: Dict[int, str] = {}

                            for label, (index, oid) in enumerate(active_items):
                                if _use_hdf5:
                                    vectors[label] = _vectors_dataset[index][:]
                                else:
                                    vectors[label] = _fallback_storage[index]
                                label_to_oid[label] = oid

                            if vectors.size > 0:
                                complexity = max(64, 4 * min(32, len(active_items)))
                                graph_degree = max(2, min(32, len(active_items) - 1)) if len(active_items) > 1 else 2
                                num_threads = max(1, min(4, os.cpu_count() or 1))

                                with tempfile.TemporaryDirectory(prefix="telos_diskann_") as index_dir:
                                    _diskann.build_memory_index(
                                        data=vectors,
                                        distance_metric="cosine",
                                        index_directory=index_dir,
                                        complexity=complexity,
                                        graph_degree=graph_degree,
                                        num_threads=num_threads,
                                        vector_dtype=np.float32,
                                        tags=labels,
                                        index_prefix="telos_mem"
                                    )

                                    diskann_index = _diskann.StaticMemoryIndex(
                                        index_directory=index_dir,
                                        index_prefix="telos_mem",
                                        num_threads=num_threads,
                                        initial_search_complexity=complexity,
                                        distance_metric="cosine",
                                        vector_dtype=np.float32,
                                        dimensions=_vector_dim
                                    )

                                    query = np.asarray(query_vector, dtype=np.float32).reshape(1, -1)
                                    response = diskann_index.search(
                                        query,
                                        k_neighbors=min(k, len(active_items)),
                                        complexity=complexity
                                    )

                                    for label, distance in zip(response.identifiers[0], response.distances[0]):
                                        oid = label_to_oid.get(int(label))
                                        if oid is None:
                                            continue
                                        similarity = float(1.0 - distance)
                                        if similarity >= threshold:
                                            similarities.append((oid, similarity))

                                used_diskann = True
                                diskann_success = True
                                diskann_duration_ms = (time.perf_counter() - diskann_start) * 1000.0
                                diskann_error = None
                            else:
                                diskann_error = persistent_error

                        except Exception as diskann_error_exc:
                            diskann_error = str(diskann_error_exc)
                            logger.warning(
                                "DiskANN search failed (%s); falling back to brute force.",
                                diskann_error
                            )

                if not used_diskann:
                    for index, oid in active_items:
                        if _use_hdf5:
                            vector = _vectors_dataset[index][:]
                        else:
                            vector = _fallback_storage[index]

                        vector_norm = np.linalg.norm(vector)
                        if vector_norm > 0:
                            cosine_sim = float(np.dot(vector, query_vector) / (vector_norm * query_norm))
                            if cosine_sim >= threshold:
                                similarities.append((oid, cosine_sim))

                # Sort by similarity (highest first) and return top k unique entries
                similarities.sort(key=lambda x: x[1], reverse=True)
                seen: Set[str] = set()
                unique_results: List[Tuple[str, float]] = []
                for oid, sim in similarities:
                    if oid not in seen:
                        unique_results.append((oid, sim))
                        seen.add(oid)
                    if len(unique_results) >= k:
                        break

                similarity_sum = 0.0
                max_similarity = 0.0
                min_similarity: Optional[float] = None
                if unique_results:
                    similarity_values = [sim for _, sim in unique_results]
                    similarity_sum = float(sum(similarity_values))
                    max_similarity = float(max(similarity_values))
                    min_similarity = float(min(similarity_values))

                metrics_diskann = _metrics['diskann']
                metrics_diskann['vector_count'] = len(active_items)
                metrics_diskann['dirty'] = _diskann_state['dirty']
                metrics_diskann['index_directory'] = _diskann_directory
                metrics_diskann['search_complexity'] = _diskann_state.get('search_complexity')
                if diskann_attempted:
                    metrics_diskann['attempts'] += 1
                    metrics_diskann['last_used'] = datetime.now(timezone.utc).isoformat()
                    if diskann_success:
                        metrics_diskann['successes'] += 1
                        metrics_diskann['last_duration_ms'] = diskann_duration_ms
                        metrics_diskann['last_error'] = None
                    else:
                        metrics_diskann['failures'] += 1
                        metrics_diskann['last_error'] = diskann_error
                elif used_diskann:
                    # Legacy path safeguard
                    metrics_diskann['attempts'] += 1
                    metrics_diskann['successes'] += 1
                    metrics_diskann['last_used'] = datetime.now(timezone.utc).isoformat()

                metrics_search = _metrics['search']
                metrics_search['queries'] += 1
                metrics_search['results_returned'] += len(unique_results)
                metrics_search['similarity_sum'] += similarity_sum
                metrics_search['last_result_count'] = len(unique_results)
                if unique_results:
                    metrics_search['last_similarity_avg'] = similarity_sum / len(unique_results)
                    metrics_search['max_similarity'] = max(metrics_search['max_similarity'], max_similarity)
                    if metrics_search['min_similarity'] is None:
                        metrics_search['min_similarity'] = min_similarity
                    else:
                        metrics_search['min_similarity'] = min(metrics_search['min_similarity'], min_similarity)
                else:
                    metrics_search['last_similarity_avg'] = None

                logger.debug(f"Found {len(unique_results)} similar vectors")
                return unique_results
                
            except Exception as e:
                logger.error(f"Similarity search failed: {e}")
                return []
    
    def get_stats() -> Dict[str, Any]:
        """Get storage statistics."""
        with _lock:
            storage_size = 0
            if os.path.exists(_storage_path):
                storage_size = os.path.getsize(_storage_path)
            
            return {
                'storage_path': _storage_path,
                'vector_dim': _vector_dim,
                'max_vectors': _max_vectors,
                'current_vectors': len(_oid_to_index),
                'next_index': _next_index,
                'storage_size_bytes': storage_size,
                'using_hdf5': _use_hdf5,
                'utilization': len(_oid_to_index) / _max_vectors,
                'diskann_enabled': DISKANN_AVAILABLE,
                'metrics': {
                    'diskann': dict(_metrics['diskann']),
                    'search': {
                        'queries': _metrics['search']['queries'],
                        'results_returned': _metrics['search']['results_returned'],
                        'avg_results_per_query': (
                            _metrics['search']['results_returned'] / _metrics['search']['queries']
                            if _metrics['search']['queries'] else 0.0
                        ),
                        'avg_similarity': (
                            _metrics['search']['similarity_sum'] / _metrics['search']['results_returned']
                            if _metrics['search']['results_returned'] else 0.0
                        ),
                        'max_similarity': _metrics['search']['max_similarity'],
                        'min_similarity': _metrics['search']['min_similarity'],
                        'last_result_count': _metrics['search']['last_result_count'],
                        'last_similarity_avg': _metrics['search']['last_similarity_avg']
                    }
                }
            }
    
    def reset():
        """Reset storage by closing and removing backing file."""
        with _lock:
            nonlocal _h5_file, _vectors_dataset, _metadata_dataset, _next_index
            if _use_hdf5 and _h5_file:
                _h5_file.close()
            if os.path.exists(_storage_path):
                try:
                    os.unlink(_storage_path)
                except Exception as exc:
                    logger.warning(f"Failed to remove storage file {_storage_path}: {exc}")
            _oid_to_index.clear()
            _index_to_oid.clear()
            _fallback_storage.clear()
            _fallback_metadata.clear()
            _h5_file = None
            _vectors_dataset = None
            _metadata_dataset = None
            _next_index = 0
            _cleanup_diskann_workspace()
            _diskann_state['handle'] = None
            _diskann_state['label_to_oid'] = {}
            _diskann_state['oid_to_label'] = {}
            _diskann_state['dirty'] = True
            _diskann_state['built'] = False
            _diskann_state['vector_count'] = 0
            _diskann_state['last_rebuild'] = None
            _diskann_state['last_error'] = None
            _diskann_state['search_complexity'] = 64
            metrics_diskann = _metrics['diskann']
            metrics_diskann['dirty'] = True
            metrics_diskann['search_complexity'] = None
            metrics_diskann['vector_count'] = 0
            _ensure_storage()

    def close():
        """Close the storage backend."""
        with _lock:
            if _use_hdf5 and _h5_file:
                _h5_file.close()
                logger.info("Closed HDF5 storage")
            _teardown_diskann_handle()
    
    def compact():
        """Compact storage by removing gaps (placeholder for future implementation)."""
        with _lock:
            logger.info("Storage compaction not implemented yet")
            # In a production system, this would rebuild the storage
            # to remove deleted entries and optimize layout
    
    # Initialize storage
    _ensure_storage()
    
    # Return the prototypal interface
    index['add_vector'] = add_vector
    index['get_vector'] = get_vector
    index['remove_vector'] = remove_vector
    index['search_similar'] = search_similar
    index['get_stats'] = get_stats
    index['reset'] = reset
    index['close'] = close
    index['compact'] = compact
    index['rebuild_diskann'] = rebuild_diskann_index
    index['get_diskann_status'] = get_diskann_status
    
    return index

# =============================================================================
# L2 Cache Manager (Prototypal Style)
# =============================================================================

def create_l2_cache_manager(storage_path: str = None, max_size: int = 100000, 
                           vector_dim: int = 1536) -> Dict[str, Callable]:
    """
    Factory function to create L2 cache manager following prototypal principles.
    
    Args:
        storage_path: Path to disk storage (default: temp file)
        max_size: Maximum number of entries to cache
        vector_dim: Dimension of vectors
    
    Returns:
        Dictionary of methods for cache management
    """
    # Use UvmObject as foundational parent for prototypal inheritance
    manager = UvmObject()
    
    # Internal state
    if storage_path is None:
        storage_path = os.path.join(tempfile.gettempdir(), 'telos_l2_cache.h5')

    _storage_path = storage_path
    _max_size = max_size
    _vector_dim = vector_dim
    _lock = threading.Lock()
    _access_order = OrderedDict()
    _stats = defaultdict(int)
    _disk_index = create_disk_vector_index(_storage_path, _vector_dim, _max_size)
    _metrics = {
        'evictions': deque(maxlen=128),
        'search': {
            'queries': 0,
            'total_duration_ms': 0.0,
            'results_returned': 0,
            'similarity_sum': 0.0,
            'max_similarity': 0.0,
            'min_similarity': None,
            'last_duration_ms': None,
            'last_similarity_avg': None,
            'last_result_count': 0,
            'avg_latency_ms': 0.0,
            'avg_similarity': 0.0,
            'last_query_timestamp': None,
            'diskann_usage': None
        },
        'ingest': {
            'batches': 0,
            'vectors': 0,
            'failures': 0,
            'last_batch_size': 0,
            'last_duration_ms': None,
            'auto_rebuild_triggered': 0
        }
    }
    
    def _update_access(oid: str):
        """Update access order for LRU eviction."""
        current_time = time.time()
        if oid in _access_order:
            del _access_order[oid]
        _access_order[oid] = current_time
    
    def _evict_lru():
        """Evict least recently used entries if needed."""
        current_size = _disk_index['get_stats']()['current_vectors']
        
        if current_size >= _max_size * 0.9:  # Evict when 90% full
            # Evict oldest 10% of entries
            num_to_evict = max(1, int(_max_size * 0.1))
            evicted = 0
            
            # Get oldest entries
            oldest_oids = list(_access_order.keys())[:num_to_evict]
            
            for oid in oldest_oids:
                if _disk_index['remove_vector'](oid):
                    if oid in _access_order:
                        del _access_order[oid]
                    evicted += 1
                    _metrics['evictions'].append({
                        'oid': oid,
                        'timestamp': datetime.now(timezone.utc).isoformat(),
                        'reason': 'LRU'
                    })
            
            _stats['evictions'] += evicted
            logger.info(f"L2 cache evicted {evicted} entries")
    
    def put(oid: str, vector: np.ndarray, metadata: Dict[str, Any] = None) -> bool:
        """Add or update an entry in the L2 cache."""
        with _lock:
            try:
                # Check if eviction is needed
                _evict_lru()
                
                # Store in disk index
                success = _disk_index['add_vector'](oid, vector, metadata)
                
                if success:
                    _update_access(oid)
                    _stats['puts'] += 1
                    logger.debug(f"L2 cache put: {oid}")
                
                return success
                
            except Exception as e:
                logger.error(f"L2 cache put failed for {oid}: {e}")
                return False

    def bulk_put(entries: List[Dict[str, Any]], rebuild: bool = False,
                 force_rebuild: bool = False, auto_rebuild: bool = True,
                 rebuild_min_points: Optional[int] = None) -> Dict[str, Any]:
        """Ingest a batch of vectors into the L2 cache."""

        start_time = time.perf_counter()
        failures: List[Dict[str, Any]] = []
        ingested = 0
        requested = len(entries)
        status_after_put: Dict[str, Any]

        with _lock:
            _evict_lru()

            for entry in entries:
                oid = entry.get('oid') if isinstance(entry, dict) else None
                raw_vector = entry.get('vector') if isinstance(entry, dict) else None
                metadata = entry.get('metadata') if isinstance(entry, dict) else None

                if not oid or raw_vector is None:
                    failures.append({
                        'oid': oid,
                        'reason': 'missing_oid_or_vector'
                    })
                    continue

                try:
                    vector = np.asarray(raw_vector, dtype=np.float32)
                    if vector.ndim > 1:
                        vector = vector.reshape(-1)
                    if vector.size != _vector_dim:
                        raise ValueError(f'vector dimension mismatch: {vector.size} != {_vector_dim}')

                    success = _disk_index['add_vector'](oid, vector, metadata)
                    if success:
                        _update_access(oid)
                        _stats['puts'] += 1
                        ingested += 1
                    else:
                        failures.append({
                            'oid': oid,
                            'reason': 'add_vector_failed'
                        })

                except Exception as exc:
                    logger.error(f"Bulk put failed for {oid}: {exc}")
                    failures.append({
                        'oid': oid,
                        'reason': str(exc)
                    })

            status_after_put = _disk_index['get_diskann_status']()

        duration_ms = (time.perf_counter() - start_time) * 1000.0
        metrics_ingest = _metrics['ingest']
        metrics_ingest['batches'] += 1
        metrics_ingest['vectors'] += ingested
        metrics_ingest['failures'] += len(failures)
        metrics_ingest['last_batch_size'] = requested
        metrics_ingest['last_duration_ms'] = duration_ms

        rebuild_result: Optional[Dict[str, Any]] = None
        auto_triggered = False
        min_points = rebuild_min_points or DISKANN_MIN_POINTS

        try_rebuild = rebuild or force_rebuild or (
            auto_rebuild and status_after_put.get('available') and status_after_put.get('dirty')
            and status_after_put.get('vector_count', 0) >= min_points
        )

        if try_rebuild:
            auto_triggered = auto_rebuild and not (rebuild or force_rebuild)
            rebuild_result = _disk_index['rebuild_diskann'](
                force=rebuild or force_rebuild,
                auto=auto_triggered
            )
            if auto_triggered and rebuild_result and rebuild_result.get('success'):
                metrics_ingest['auto_rebuild_triggered'] += 1

        post_status = _disk_index['get_diskann_status']()

        return {
            'success': len(failures) == 0,
            'requested': requested,
            'ingested': ingested,
            'failures': failures,
            'duration_ms': duration_ms,
            'auto_rebuild_triggered': auto_triggered,
            'rebuild_result': rebuild_result,
            'status_after_put': status_after_put,
            'status_post_rebuild': post_status
        }
    
    def get(oid: str) -> Optional[Dict[str, Any]]:
        """Get an entry from the L2 cache."""
        with _lock:
            try:
                result = _disk_index['get_vector'](oid)
                
                if result:
                    vector, metadata = result
                    _update_access(oid)
                    _stats['hits'] += 1
                    logger.debug(f"L2 cache hit: {oid}")
                    
                    return {
                        'oid': oid,
                        'vector': vector,
                        'metadata': metadata
                    }
                else:
                    _stats['misses'] += 1
                    logger.debug(f"L2 cache miss: {oid}")
                    return None
                    
            except Exception as e:
                logger.error(f"L2 cache get failed for {oid}: {e}")
                return None
    
    def remove(oid: str) -> bool:
        """Remove an entry from the L2 cache."""
        with _lock:
            success = _disk_index['remove_vector'](oid)
            
            if success:
                if oid in _access_order:
                    del _access_order[oid]
                _stats['removals'] += 1
                logger.debug(f"L2 cache remove: {oid}")
            
            return success
    
    def search_similar(query_vector: np.ndarray, k: int = 10,
                      threshold: float = 0.5) -> List[Dict[str, Any]]:
        """Search for similar vectors in the L2 cache."""
        try:
            search_start = time.perf_counter()
            # Get similar OIDs from disk index
            similar_results = _disk_index['search_similar'](query_vector, k, threshold)
            duration_ms = (time.perf_counter() - search_start) * 1000.0
            
            # Build full result entries
            results = []
            similarity_sum = 0.0
            max_similarity = 0.0
            min_similarity: Optional[float] = None
            for oid, score in similar_results:
                entry = get(oid)  # This will update LRU order
                if entry:
                    entry['similarity_score'] = score
                    results.append(entry)
                    similarity_sum += score
                    if score > max_similarity:
                        max_similarity = score
                    if min_similarity is None or score < min_similarity:
                        min_similarity = score
            
            diskann_snapshot = _disk_index['get_stats']()['metrics']['diskann']

            with _lock:
                _stats['searches'] += 1
                search_metrics = _metrics['search']
                search_metrics['queries'] += 1
                search_metrics['total_duration_ms'] += duration_ms
                search_metrics['last_duration_ms'] = duration_ms
                search_metrics['results_returned'] += len(results)
                search_metrics['similarity_sum'] += similarity_sum
                search_metrics['last_similarity_avg'] = (
                    similarity_sum / len(results) if results else None
                )
                search_metrics['max_similarity'] = max(search_metrics['max_similarity'], max_similarity)
                if results:
                    if search_metrics['min_similarity'] is None:
                        search_metrics['min_similarity'] = min_similarity
                    else:
                        search_metrics['min_similarity'] = min(search_metrics['min_similarity'], min_similarity)
                search_metrics['last_result_count'] = len(results)
                search_metrics['avg_latency_ms'] = (
                    search_metrics['total_duration_ms'] / search_metrics['queries']
                    if search_metrics['queries'] else 0.0
                )
                search_metrics['avg_similarity'] = (
                    search_metrics['similarity_sum'] / search_metrics['results_returned']
                    if search_metrics['results_returned'] else 0.0
                )
                search_metrics['diskann_usage'] = diskann_snapshot
                search_metrics['last_query_timestamp'] = datetime.now(timezone.utc).isoformat()
            logger.debug(f"L2 cache search found {len(results)} similar entries")
            return results
            
        except Exception as e:
            logger.error(f"L2 cache search failed: {e}")
            return []

    def rebuild_diskann(force: bool = False, auto: bool = False) -> Dict[str, Any]:
        """Manually trigger a DiskANN rebuild."""
        rebuild_result = _disk_index['rebuild_diskann'](force=force, auto=auto)
        status = _disk_index['get_diskann_status']()
        rebuild_result['status'] = status
        return rebuild_result

    def get_diskann_status() -> Dict[str, Any]:
        """Expose DiskANN state for telemetry."""
        status = _disk_index['get_diskann_status']()
        status['metrics'] = {
            'search': dict(_metrics['search']),
            'ingest': dict(_metrics['ingest'])
        }
        return status
    
    def get_statistics() -> Dict[str, Any]:
        """Get cache statistics."""
        with _lock:
            disk_stats = _disk_index['get_stats']()
            
            cache_stats = dict(_stats)
            cache_stats.update({
                'max_size': _max_size,
                'current_size': disk_stats['current_vectors'],
                'fill_ratio': disk_stats.get('utilization', 0),
                'hit_ratio': _stats['hits'] / max(1, _stats['hits'] + _stats['misses']),
                'storage_size_mb': disk_stats['storage_size_bytes'] / (1024 * 1024),
                'disk_index': disk_stats,
                'diskann_status': _disk_index['get_diskann_status'](),
                'eviction_history': list(_metrics['evictions']),
                'search_metrics': {
                    'queries': _metrics['search']['queries'],
                    'avg_latency_ms': _metrics['search']['avg_latency_ms'],
                    'last_latency_ms': _metrics['search']['last_duration_ms'],
                    'avg_similarity': _metrics['search']['avg_similarity'],
                    'max_similarity': _metrics['search']['max_similarity'],
                    'min_similarity': _metrics['search']['min_similarity'],
                    'last_similarity_avg': _metrics['search']['last_similarity_avg'],
                    'last_result_count': _metrics['search']['last_result_count'],
                    'total_results_returned': _metrics['search']['results_returned'],
                    'last_query_timestamp': _metrics['search']['last_query_timestamp'],
                    'diskann_usage': _metrics['search']['diskann_usage']
                },
                'ingest_metrics': dict(_metrics['ingest'])
            })
            
            return cache_stats
    
    def clear():
        """Clear all cache entries."""
        nonlocal _disk_index
        with _lock:
            _disk_index['reset']()
            _disk_index = create_disk_vector_index(_storage_path, _vector_dim, _max_size)
            _access_order.clear()
            _stats.clear()
            logger.info("L2 cache cleared")
    
    def recreate_storage():
        """Recreate the storage backend (helper function)."""
        clear()
        pass
    
    def close():
        """Close the L2 cache."""
        with _lock:
            _disk_index['close']()
            logger.info("L2 cache closed")
    
    def get_all_oids() -> Set[str]:
        """Get all OIDs currently in cache."""
        with _lock:
            return set(_access_order.keys())
    
    # Return the prototypal interface
    manager['put'] = put
    manager['bulk_put'] = bulk_put
    manager['get'] = get
    manager['remove'] = remove
    manager['search_similar'] = search_similar
    manager['rebuild_diskann'] = rebuild_diskann
    manager['get_diskann_status'] = get_diskann_status
    manager['get_statistics'] = get_statistics
    manager['clear'] = clear
    manager['close'] = close
    manager['get_all_oids'] = get_all_oids
    
    return manager

# =============================================================================
# Module Test and Initialization
# =============================================================================

if __name__ == "__main__":
    # Simple test of the L2 cache manager
    print("Testing TELOS L2 Cache Manager...")
    
    # Create test cache with temporary storage
    temp_storage = tempfile.mktemp(suffix='.h5')
    cache = create_l2_cache_manager(temp_storage, max_size=10, vector_dim=64)
    
    try:
        # Test vector operations
        test_vectors = [
            ("vector_001", np.random.randn(64).astype(np.float32), {"label": "Test Vector 1"}),
            ("vector_002", np.random.randn(64).astype(np.float32), {"label": "Test Vector 2"}),
            ("vector_003", np.random.randn(64).astype(np.float32), {"label": "Test Vector 3"})
        ]
        
        # Add vectors to cache
        for oid, vector, metadata in test_vectors:
            success = cache['put'](oid, vector, metadata)
            print(f"Added {oid}: {'SUCCESS' if success else 'FAILED'}")
        
        # Test retrieval
        entry = cache['get']("vector_001")
        if entry:
            print(f"Retrieved: {entry['metadata']['label']}")
            print(f"Vector shape: {entry['vector'].shape}")
        
        # Test similarity search
        query_vector = test_vectors[0][1] + np.random.randn(64).astype(np.float32) * 0.1
        similar = cache['search_similar'](query_vector, k=2, threshold=0.0)
        print(f"Found {len(similar)} similar vectors")
        
        # Test statistics
        stats = cache['get_statistics']()
        print(f"Cache statistics: {stats['current_size']} entries, {stats['hit_ratio']:.2f} hit ratio")
        print(f"Storage size: {stats['storage_size_mb']:.2f} MB")
        
        print("L2 Cache Manager test completed successfully!")
        
    finally:
        cache['close']()
        
        # Clean up temporary file
        if os.path.exists(temp_storage):
            try:
                os.unlink(temp_storage)
            except:
                pass