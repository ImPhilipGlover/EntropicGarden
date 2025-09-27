#!/usr/bin/env python3
"""
TELOS L3 ZODB Persistence Layer

This module implements the ground truth persistence layer for the TELOS
federated memory architecture. It provides ACID guarantees through ZODB's
transactional system and supports distributed access via ZEO client-server
architecture.

All concept objects flow through this layer as the authoritative source of
truth, with L1/L2 caches serving as performance optimization layers above it.

Architectural Compliance:
- Prototypal design principles (no classes, only factory functions and closures)
- ACID transactional integrity via ZODB
- ZEO client-server architecture for distributed access
- Integration with Synaptic Bridge FFI contract
"""

import os
import time
import logging
from typing import Dict, Any, Optional, List, Callable, Union, Iterable
from dataclasses import dataclass
import json
import uuid
from datetime import datetime, timezone

# ZODB imports
try:
    import ZODB
    import ZODB.FileStorage
    import ZEO
    import transaction
    from persistent import Persistent
    from persistent.mapping import PersistentMapping
    from BTrees.IOBTree import IOBTree
    from BTrees.OOBTree import OOBTree
    from ZODB.POSException import ConflictError
    ZODB_AVAILABLE = True
except ImportError as e:
    ZODB_AVAILABLE = False
    IMPORT_ERROR = str(e)

# Shared memory imports for zero-copy IPC
import multiprocessing.shared_memory as shm

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# =============================================================================
# ZODB Concept Persistent Object (Prototypal Style)
# =============================================================================

RELATIONSHIP_KEY_ALIASES: Dict[str, Iterable[str]] = {
    'is_a': ('is_a', 'isA'),
    'part_of': ('part_of', 'partOf'),
    'abstraction_of': ('abstraction_of', 'abstractionOf'),
    'instance_of': ('instance_of', 'instanceOf'),
    'associated_with': ('associated_with', 'associatedWith'),
}

RELATIONSHIP_ATTR_MAP: Dict[str, str] = {
    'is_a': 'is_a',
    'part_of': 'part_of',
    'abstraction_of': 'abstraction_of',
    'instance_of': 'instance_of',
    'associated_with': 'associated_with',
}


def _normalized_relationship_payload(payload: Optional[Dict[str, Any]]) -> Dict[str, List[str]]:
    if not isinstance(payload, dict):
        return {}

    normalized: Dict[str, List[str]] = {}
    for snake_key, aliases in RELATIONSHIP_KEY_ALIASES.items():
        found_key = None
        for alias in aliases:
            if alias in payload:
                found_key = alias
                break

        if found_key is None:
            continue

        raw_values = payload.get(found_key)
        serialised: List[str] = []

        if isinstance(raw_values, Iterable) and not isinstance(raw_values, (str, bytes, dict)):
            for entry in raw_values:
                if entry is None:
                    continue
                serialised.append(str(entry))

        normalized[snake_key] = serialised

    return normalized

class PersistentConcept(Persistent):
    """
    ZODB-compatible persistent concept storage.
    
    This class serves as the storage substrate for the TELOS concept system.
    While it uses a class structure for ZODB compatibility, the external
    interface follows prototypal principles through factory functions.
    """
    
    def __init__(self, oid: str = None, **kwargs):
        super().__init__()
        
        # Core data slots (matching Concept.io specification)
        self.oid = oid or str(uuid.uuid4())
        self.symbolic_hypervector_name = kwargs.get('symbolic_hypervector_name')
        self.geometric_embedding_name = kwargs.get('geometric_embedding_name')
        self.label = kwargs.get('label')
        self.created_at = kwargs.get('created_at', datetime.now(timezone.utc))
        self.last_modified = datetime.now(timezone.utc)
        
        # Relational links (stored as persistent structures)
        self.is_a = IOBTree()
        self.part_of = IOBTree()
        self.abstraction_of = IOBTree()
        self.instance_of = IOBTree()
        self.associated_with = IOBTree()
        
        # Metadata
        self.confidence = float(kwargs.get('confidence', 1.0))
        self.usage_count = int(kwargs.get('usage_count', 0))
        self.source = kwargs.get('source', 'unknown')
        
        relationships = kwargs.get('relationships')
        if relationships:
            self._apply_relationships(relationships)

        # Mark as changed to ensure persistence
        self._p_changed = True

    def _reset_relationship_btree(self, attr: str, values: List[str]):
        tree = IOBTree()
        for value in values:
            key = hash(value) % (2 ** 31)
            tree[key] = value
        setattr(self, attr, tree)
        self._p_changed = True

    def _apply_relationships(self, relationships: Dict[str, Any]):
        normalized = _normalized_relationship_payload(relationships)
        for snake_key, attr_name in RELATIONSHIP_ATTR_MAP.items():
            values = normalized.get(snake_key)
            if values is None:
                continue
            self._reset_relationship_btree(attr_name, values)
    
    def record_usage(self):
        """Update usage statistics and mark as changed."""
        self.usage_count += 1
        self.last_modified = datetime.now(timezone.utc)
        self._p_changed = True
        
    def add_relationship(self, relation_type: str, target_oid: str):
        """Add a relationship to another concept."""
        relation_btree = getattr(self, relation_type, None)
        if relation_btree is None:
            raise ValueError(f"Unknown relation type: {relation_type}")
        
        # Use target_oid hash as key for BTree efficiency
        key = hash(target_oid) % (2**31)  # Ensure 31-bit int for IOBTree
        relation_btree[key] = target_oid
        self._p_changed = True
        
    def remove_relationship(self, relation_type: str, target_oid: str):
        """Remove a relationship to another concept."""
        relation_btree = getattr(self, relation_type, None)
        if relation_btree is None:
            raise ValueError(f"Unknown relation type: {relation_type}")
        
        key = hash(target_oid) % (2**31)
        if key in relation_btree:
            del relation_btree[key]
            self._p_changed = True
            
    def get_related(self, relation_type: str) -> List[str]:
        """Get all related concept OIDs of a specific type."""
        relation_btree = getattr(self, relation_type, None)
        if relation_btree is None:
            raise ValueError(f"Unknown relation type: {relation_type}")
        
        return list(relation_btree.values())
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary representation."""
        return {
            'oid': self.oid,
            'label': self.label,
            'symbolic_hypervector_name': self.symbolic_hypervector_name,
            'geometric_embedding_name': self.geometric_embedding_name,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_modified': self.last_modified.isoformat() if self.last_modified else None,
            'confidence': self.confidence,
            'usage_count': self.usage_count,
            'source': self.source,
            'relationships': {
                'is_a': list(self.is_a.values()),
                'part_of': list(self.part_of.values()),
                'abstraction_of': list(self.abstraction_of.values()),
                'instance_of': list(self.instance_of.values()),
                'associated_with': list(self.associated_with.values())
            }
        }

def create_persistent_concept(oid: str = None, **kwargs) -> PersistentConcept:
    """
    Factory function to create a persistent concept object.
    
    This follows prototypal principles by using a factory function rather
    than direct class instantiation.
    """
    if not ZODB_AVAILABLE:
        raise RuntimeError(f"ZODB not available: {IMPORT_ERROR}")
    
    return PersistentConcept(oid, **kwargs)

# =============================================================================
# Prototypal ZODB Manager Factory
# =============================================================================

def create_zodb_manager(
    storage_path: str = None,
    zeo_address: tuple = None,
    read_only: bool = False
) -> Dict[str, Callable]:
    """
    Factory function to create a ZODB manager following prototypal principles.
    
    Returns a dictionary of methods (closure) that maintains internal state
    for database connection, transaction management, and concept operations.
    
    Args:
    storage_path: Path to FileStorage database file (for standalone mode)
    zeo_address: (host, port) tuple for ZEO client connection
    read_only: Open the storage in read-only mode (for shared access)
    """
    if not ZODB_AVAILABLE:
        raise RuntimeError(f"ZODB not available: {IMPORT_ERROR}")
    
    # Internal state (closure variables)
    _db = None
    _connection = None
    _root = None
    _concepts_btree = None
    _storage_path = storage_path or os.path.join(os.getcwd(), 'telos_concepts.fs')
    _zeo_address = zeo_address
    _read_only = bool(read_only)
    
    def _initialize():
        """Initialize database connection and root structures."""
        nonlocal _db, _connection, _root, _concepts_btree
        
        try:
            # Choose storage type based on configuration
            if _zeo_address:
                # ZEO client mode for distributed access
                logger.info(f"Connecting to ZEO server at {_zeo_address}")
                storage = ZEO.ClientStorage.ClientStorage(_zeo_address, read_only=_read_only)
            else:
                # Standalone FileStorage mode
                logger.info(f"Using FileStorage at {_storage_path}")
                storage = ZODB.FileStorage.FileStorage(_storage_path, read_only=_read_only)
            
            _db = ZODB.DB(storage)
            _connection = _db.open()
            _root = _connection.root()
            
            # Initialize concepts BTree if not exists
            if 'concepts' not in _root:
                _root['concepts'] = OOBTree()
                transaction.commit()
                logger.info("Initialized concepts BTree in database root")
            
            _concepts_btree = _root['concepts']
            logger.info("ZODB Manager initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize ZODB manager: {e}")
            raise
    
    def _ensure_connected():
        """Ensure database connection is active."""
        if _connection is None or _connection.opened is None:
            _initialize()
    
    def close():
        """Close database connection."""
        nonlocal _db, _connection, _root, _concepts_btree
        
        if _connection:
            _connection.close()
            _connection = None
        if _db:
            _db.close()
            _db = None
        
        _root = None
        _concepts_btree = None
        logger.info("ZODB Manager closed")
    
    def store_concept(concept_data: Dict[str, Any]) -> str:
        """
        Store a concept in the persistent database.
        
        Args:
            concept_data: Dictionary containing concept fields
            
        Returns:
            String OID of the stored concept
        """
        if _read_only:
            raise RuntimeError("ZODB manager is read-only; cannot store concepts")

        _ensure_connected()
        
        try:
            # Create persistent concept object
            oid = concept_data.get('oid', str(uuid.uuid4()))
            # Remove oid from concept_data to avoid duplicate keyword argument
            concept_fields = {k: v for k, v in concept_data.items() if k != 'oid'}
            concept = create_persistent_concept(oid=oid, **concept_fields)
            
            # Store in concepts BTree
            _concepts_btree[oid] = concept
            
            # Commit transaction for ACID compliance
            transaction.commit()
            
            logger.debug(f"Stored concept {oid} in persistent database")
            return oid
            
        except Exception as e:
            # Rollback on any error
            transaction.abort()
            logger.error(f"Failed to store concept: {e}")
            raise
    
    def load_concept(oid: str) -> Optional[Dict[str, Any]]:
        """
        Load a concept from the persistent database.
        
        Args:
            oid: Object identifier
            
        Returns:
            Dictionary representation of concept or None if not found
        """
        _ensure_connected()
        
        try:
            concept = _concepts_btree.get(oid)
            if concept is None:
                return None

            if _read_only:
                return concept.to_dict()

            # Record usage statistics
            concept.record_usage()
            transaction.commit()

            return concept.to_dict()
            
        except Exception as e:
            transaction.abort()
            logger.error(f"Failed to load concept {oid}: {e}")
            raise
    
    def update_concept(oid: str, updates: Dict[str, Any]) -> bool:
        """
        Update an existing concept in the database.
        
        Args:
            oid: Object identifier
            updates: Dictionary of fields to update
            
        Returns:
            True if successful, False if concept not found
        """
        if _read_only:
            raise RuntimeError("ZODB manager is read-only; cannot update concepts")

        _ensure_connected()
        
        try:
            concept = _concepts_btree.get(oid)
            if concept is None:
                return False
            
            updates_payload = dict(updates)
            relationships_payload = updates_payload.pop('relationships', None)

            # Apply updates
            for field, value in updates_payload.items():
                if hasattr(concept, field):
                    setattr(concept, field, value)
            
            if relationships_payload is not None:
                concept._apply_relationships(relationships_payload)

            concept.last_modified = datetime.now(timezone.utc)
            concept._p_changed = True
            
            transaction.commit()
            logger.debug(f"Updated concept {oid}")
            return True
            
        except Exception as e:
            transaction.abort()
            logger.error(f"Failed to update concept {oid}: {e}")
            raise
    
    def mutate_concept_without_commit(oid: str, updates: Dict[str, Any]) -> bool:
        """Apply updates while leaving commit control to the caller."""
        if _read_only:
            raise RuntimeError("ZODB manager is read-only; cannot mutate concepts")

        _ensure_connected()

        try:
            concept = _concepts_btree.get(oid)
            if concept is None:
                return False

            updates_payload = dict(updates)
            relationships_payload = updates_payload.pop('relationships', None)

            for field, value in updates_payload.items():
                if hasattr(concept, field):
                    setattr(concept, field, value)

            if relationships_payload is not None:
                concept._apply_relationships(relationships_payload)

            concept.last_modified = datetime.now(timezone.utc)
            concept._p_changed = True
            return True

        except Exception as e:
            transaction.abort()
            logger.error(f"Failed to mutate concept {oid} without commit: {e}")
            raise

    def delete_concept(oid: str) -> bool:
        """
        Delete a concept from the database.
        
        Args:
            oid: Object identifier
            
        Returns:
            True if deleted, False if not found
        """
        if _read_only:
            raise RuntimeError("ZODB manager is read-only; cannot delete concepts")

        _ensure_connected()
        
        try:
            if oid in _concepts_btree:
                del _concepts_btree[oid]
                transaction.commit()
                logger.debug(f"Deleted concept {oid}")
                return True
            else:
                return False
                
        except Exception as e:
            transaction.abort()
            logger.error(f"Failed to delete concept {oid}: {e}")
            raise
    
    def list_concepts(limit: int = 100, offset: int = 0) -> List[str]:
        """
        List concept OIDs in the database.
        
        Args:
            limit: Maximum number of OIDs to return
            offset: Number of OIDs to skip
            
        Returns:
            List of concept OIDs
        """
        _ensure_connected()
        
        try:
            keys = list(_concepts_btree.keys())[offset:offset+limit]
            return keys
            
        except Exception as e:
            logger.error(f"Failed to list concepts: {e}")
            raise
    
    def get_statistics() -> Dict[str, Any]:
        """Get database statistics."""
        _ensure_connected()
        
        try:
            total_concepts = len(_concepts_btree)
            
            # Calculate storage statistics if using FileStorage
            storage_size = 0
            if hasattr(_db.storage, '_file'):
                try:
                    storage_size = os.path.getsize(_storage_path)
                except:
                    pass
            
            return {
                'total_concepts': total_concepts,
                'storage_size_bytes': storage_size,
                'storage_path': _storage_path,
                'zeo_address': _zeo_address,
                'connection_active': _connection is not None
            }
            
        except Exception as e:
            logger.error(f"Failed to get statistics: {e}")
            return {}

    def get_concept_snapshot(oid: str) -> Optional[Dict[str, Any]]:
        """Return the current concept dictionary without mutating usage statistics."""
        _ensure_connected()

        try:
            concept = _concepts_btree.get(oid)
            if concept is None:
                return None

            return concept.to_dict()

        except Exception as e:
            logger.error(f"Failed to snapshot concept {oid}: {e}")
            raise

    def force_conflict_error() -> None:
        """Raise a simulated ZODB ConflictError for harness validation."""
        _ensure_connected()
        raise ConflictError("Simulated conflict error for harness validation")

    def force_disk_error() -> None:
        """Raise an IOError mimicking disk exhaustion."""
        _ensure_connected()
        raise IOError("Simulated disk full condition for harness validation")

    def force_unhandled_error() -> None:
        """Raise an unhandled runtime error to exercise two-call protocol."""
        _ensure_connected()
        raise RuntimeError("Simulated unhandled persistence failure")
    
    def mark_object_changed(oid: str):
        """
        Mark a concept object as changed for persistence.
        
        This method is called by the FFI bridge when Io objects are modified.
        """
        _ensure_connected()
        
        try:
            concept = _concepts_btree.get(oid)
            if concept:
                concept._p_changed = True
                # Don't commit here - let the calling context decide when to commit
                logger.debug(f"Marked concept {oid} as changed")
            
        except Exception as e:
            logger.error(f"Failed to mark concept {oid} as changed: {e}")
    
    def commit_transaction():
        """Commit the current transaction."""
        try:
            transaction.commit()
            logger.debug("Transaction committed successfully")
        except Exception as e:
            logger.error(f"Failed to commit transaction: {e}")
            transaction.abort()
            raise
    
    def abort_transaction():
        """Abort the current transaction."""
        try:
            transaction.abort()
            logger.debug("Transaction aborted")
        except Exception as e:
            logger.error(f"Failed to abort transaction: {e}")
    
    # Initialize on creation
    _initialize()
    
    # Return the prototypal interface (closure with methods)
    return {
        'store_concept': store_concept,
        'load_concept': load_concept,
        'update_concept': update_concept,
    'mutate_concept_without_commit': mutate_concept_without_commit,
        'delete_concept': delete_concept,
        'list_concepts': list_concepts,
        'get_statistics': get_statistics,
    'get_concept_snapshot': get_concept_snapshot,
    'force_conflict_error': force_conflict_error,
    'force_disk_error': force_disk_error,
    'force_unhandled_error': force_unhandled_error,
        'mark_object_changed': mark_object_changed,
        'commit_transaction': commit_transaction,
        'abort_transaction': abort_transaction,
        'close': close,
        'is_read_only': lambda: _read_only
    }

# =============================================================================
# FFI Bridge Integration Functions
# =============================================================================

def create_ffi_bridge_functions():
    """
    Create FFI-compatible bridge functions for the Synaptic Bridge.
    
    These functions provide a stable C ABI interface that can be called
    from the Synaptic Bridge to interact with the ZODB persistence layer.
    """
    
    # Global manager instance
    _zodb_manager = None
    
    def initialize_zodb_manager(storage_path: str = None, zeo_host: str = None, zeo_port: int = None):
        """Initialize the ZODB manager (called from C)."""
        nonlocal _zodb_manager
        
        zeo_address = (zeo_host, zeo_port) if zeo_host and zeo_port else None
        _zodb_manager = create_zodb_manager(storage_path, zeo_address)
        return True
    
    def store_concept_ffi(concept_json: str) -> str:
        """Store concept via FFI (called from C)."""
        if _zodb_manager is None:
            raise RuntimeError("ZODB manager not initialized")
        
        concept_data = json.loads(concept_json)
        return _zodb_manager['store_concept'](concept_data)
    
    def load_concept_ffi(oid: str) -> str:
        """Load concept via FFI (called from C)."""
        if _zodb_manager is None:
            raise RuntimeError("ZODB manager not initialized")
        
        concept = _zodb_manager['load_concept'](oid)
        return json.dumps(concept) if concept else ""
    
    def mark_changed_ffi(oid: str):
        """Mark concept as changed via FFI (called from C)."""
        if _zodb_manager is None:
            raise RuntimeError("ZODB manager not initialized")
        
        _zodb_manager['mark_object_changed'](oid)
        return True
    
    def commit_transaction_ffi():
        """Commit transaction via FFI (called from C)."""
        if _zodb_manager is None:
            raise RuntimeError("ZODB manager not initialized")
        
        _zodb_manager['commit_transaction']()
        return True
    
    return {
        'initialize_zodb_manager': initialize_zodb_manager,
        'store_concept_ffi': store_concept_ffi,
        'load_concept_ffi': load_concept_ffi,
        'mark_changed_ffi': mark_changed_ffi,
        'commit_transaction_ffi': commit_transaction_ffi
    }

# =============================================================================
# Module Initialization
# =============================================================================

if __name__ == "__main__":
    # Simple test of the ZODB manager
    print("Testing TELOS ZODB Manager...")
    
    if not ZODB_AVAILABLE:
        print(f"ZODB not available: {IMPORT_ERROR}")
        print("Install with: pip install ZODB ZEO")
        exit(1)
    
    # Create test manager
    manager = create_zodb_manager()
    
    try:
        # Test concept storage
        test_concept = {
            'label': 'Test Concept',
            'confidence': 0.95,
            'source': 'test'
        }
        
        oid = manager['store_concept'](test_concept)
        print(f"Stored concept with OID: {oid}")
        
        # Test concept retrieval
        loaded = manager['load_concept'](oid)
        print(f"Loaded concept: {loaded['label']}")
        
        # Test statistics
        stats = manager['get_statistics']()
        print(f"Database contains {stats['total_concepts']} concepts")
        
        print("ZODB Manager test completed successfully!")
        
    finally:
        manager['close']()