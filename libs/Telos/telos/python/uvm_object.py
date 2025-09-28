# ==============================================================================
# TELOS UvmObject - Prototypal Base Class
#
# ARCHITECT: GitHub Copilot
# DATE: 2025-09-27
#
# DESCRIPTION:
# This file implements the UvmObject base prototype for TELOS, following the
# prototype-based programming pattern from the BAT OS architecture. All TELOS
# Python objects should be based on this prototype to ensure prototypal purity
# and ZODB persistence compatibility.
#
# KEY FEATURES:
# - Prototype-based object model (no classes, only delegation)
# - ZODB persistence with automatic change detection
# - Message passing through __getattr__ delegation
# - Persistence Covenant enforcement
# - doesNotUnderstand_ protocol for dynamic capability generation
# ==============================================================================

import persistent
from persistent.mapping import PersistentMapping
from persistent.list import PersistentList


# ==============================================================================
# UvmObject Class - Prototypal Base Class
# ==============================================================================

class TelosPersistent(persistent.Persistent):
    """
    Custom persistent class that allows slots attribute for TELOS objects.
    """
    def __init__(self):
        super().__init__()
        self.slots = PersistentMapping()


class UvmObject:
    """
    Base class for TELOS prototypal objects.
    
    This provides prototype-like delegation through the _slots mechanism
    and parent* chains, with ZODB persistence through composition.
    """
    
    def __init__(self, **kwargs):
        # Use custom persistent class that allows slots
        self._persistent = TelosPersistent()
        
        # Handle special parent_star parameter
        if 'parent_star' in kwargs:
            self._persistent.slots['parent*'] = PersistentList(kwargs.pop('parent_star'))
        
        # Set initial slots
        for key, value in kwargs.items():
            self._persistent.slots[key] = value
    
    def __getattr__(self, name):
        """
        Core message-passing and delegation mechanism.
        """
        # Skip special Python attributes and ZODB internals
        if name.startswith('__') or name.startswith('_p_') or name in ('_persistent', '_slots'):
            raise AttributeError(f"Special attribute '{name}' not found")

        # Check local slots first
        if name in self._persistent.slots:
            return self._persistent.slots[name]

        # Delegate to parent prototypes
        if 'parent*' in self._persistent.slots:
            for parent in self._persistent.slots['parent*']:
                try:
                    return getattr(parent, name)
                except AttributeError:
                    continue

        # Final fallback: doesNotUnderstand_ protocol
        try:
            return self.doesNotUnderstand_(self, name)
        except AttributeError:
            raise AttributeError(
                f"TELOS Message '{name}' not understood and doesNotUnderstand_ "
                "protocol missing from prototype chain!"
            )
    
    def __setattr__(self, name, value):
        """
        Ensures all attributes are stored in persistent _slots dictionary.
        """
        if name in ('_persistent',):
            # Special attributes handled directly
            object.__setattr__(self, name, value)
        else:
            # All other attributes go into _slots with persistence marking
            if hasattr(self, '_persistent'):
                self._persistent.slots[name] = value
                self._persistent._p_changed = True
            else:
                # During initialization
                object.__setattr__(self, name, value)
    
    def set_slot(self, name, value):
        """Explicit slot setting method."""
        self._persistent.slots[name] = value
        self._persistent._p_changed = True
    
    def get_slot(self, name, default=None):
        """Explicit slot retrieval method."""
        return self._persistent.slots.get(name, default)
    
    def has_slot(self, name):
        """Check if slot exists locally."""
        return name in self._persistent.slots
    
    def clone(self, **overrides):
        """Create a new object by cloning this one."""
        # Create clone with this object as parent
        clone_obj = UvmObject(parent_star=[self])
        
        # Apply any overrides
        for key, value in overrides.items():
            clone_obj._persistent.slots[key] = value
        
        return clone_obj
    
    def doesNotUnderstand_(self, receiver, message_name):
        """Default doesNotUnderstand_ implementation."""
        raise AttributeError(f"Message '{message_name}' not understood")
    
    def markChanged(self):
        """Explicit persistence covenant fulfillment."""
        self._persistent._p_changed = True
    
    def __repr__(self):
        oid_bytes = getattr(self._persistent, '_p_oid', None)
        oid = int.from_bytes(oid_bytes, 'big') if oid_bytes else 'transient'
        keys = list(self._persistent.slots.keys()) if hasattr(self._persistent, 'slots') else []
        return f"<UvmObject OID:{oid} Slots:{keys}>"


# ==============================================================================
# Factory Functions for Prototypal Object Creation
# ==============================================================================

def create_base_uvm_prototype():
    """Create the base UvmObject prototype."""
    return UvmObject()


# Global base prototype instance
_base_uvm_prototype = create_base_uvm_prototype()


def create_uvm_object(initial_props=None, **kwargs):
    """
    Factory function for creating UvmObject instances.
    
    This follows the TELOS architectural mandate for factory functions
    instead of direct class instantiation.
    
    Args:
        initial_props: Dictionary of initial properties (optional)
        **kwargs: Additional initial properties
        
    Returns:
        UvmObject instance
    """
    if initial_props is None:
        initial_props = {}
    initial_props.update(kwargs)
    return UvmObject(**initial_props)


def create_concept_prototype(**kwargs):
    """
    Factory function for creating Concept prototypes.

    Concepts are the atomic units of knowledge in TELOS,
    unifying symbolic hypervectors, geometric embeddings,
    and graph relations.

    Args:
        **kwargs: Initial concept properties

    Returns:
        Concept prototype
    """
    concept = create_uvm_object(
        # Core data slots
        oid=None,
        symbolicHypervectorName=None,
        geometricEmbeddingName=None,

        # Relational links
        isA=PersistentList(),
        partOf=PersistentList(),
        abstractionOf=PersistentList(),
        instanceOf=PersistentList(),
        associatedWith=PersistentList(),

        **kwargs
    )

    return concept


def create_worker_prototype(**kwargs):
    """
    Factory function for creating worker prototypes.

    Workers handle the computational "muscle" of TELOS,
    executing tasks in the GIL-quarantined process pool.

    Args:
        **kwargs: Initial worker properties

    Returns:
        Worker prototype
    """
    worker = create_uvm_object(
        status='idle',
        task_queue=PersistentList(),
        result_handlers=PersistentMapping(),
        **kwargs
    )

    return worker