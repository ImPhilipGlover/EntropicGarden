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
# Base Prototype Definition
# ==============================================================================

def create_base_uvm_prototype():
    """
    Create the base UvmObject prototype.

    This is the fundamental building block of the TELOS universe,
    implementing pure prototype-based programming inspired by Self and Io.
    """
    # Bootstrap: Create base persistent object directly (can't use create_uvm_object yet)
    base = persistent.Persistent()
    base._slots = PersistentMapping()

    # Core delegation mechanism
    def __getattr__(self, name):
        """
        Core message-passing and delegation mechanism.

        Implements the prototype chain lookup following the TELOS
        architectural mandate for pure prototypal delegation.
        """
        # Skip special Python attributes and ZODB internals
        if name.startswith('__') or name.startswith('_p_') or name == '_slots':
            raise AttributeError(f"Special attribute '{name}' not found")

        # Check local slots first
        if name in self._slots:
            return self._slots[name]

        # Delegate to parent prototypes
        if 'parent*' in self._slots:
            for parent in self._slots['parent*']:
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

    # Persistence-aware attribute setting
    def __setattr__(self, name, value):
        """
        Ensures all attributes are stored in persistent _slots dictionary.

        This implements the Persistence Covenant - any state change triggers
        ZODB change detection via _p_changed = True.
        """
        if name == '_slots' or name.startswith('_p_'):
            # Special attributes handled directly
            object.__setattr__(self, name, value)
        else:
            # All other attributes go into _slots with persistence marking
            self._slots[name] = value
            self._p_changed = True

    # Slot management methods
    def set_slot(self, name, value):
        """
        Explicit slot setting method for clarity.
        """
        self._slots[name] = value
        self._p_changed = True

    def get_slot(self, name, default=None):
        """
        Explicit slot retrieval method.
        """
        return self._slots.get(name, default)

    def has_slot(self, name):
        """
        Check if slot exists locally (not in prototype chain).
        """
        return name in self._slots

    # Prototypal cloning
    def clone(self, **overrides):
        """
        Create a new prototype by cloning this one.

        This is the prototypal equivalent of instantiation - creates
        a new object that delegates to this one.
        """
        # Create clone with this object as parent
        clone_obj = create_uvm_object(parent_star=[self])

        # Apply any overrides
        for key, value in overrides.items():
            clone_obj._slots[key] = value

        return clone_obj

    # doesNotUnderstand protocol
    def doesNotUnderstand_(self, receiver, message_name):
        """
        Default doesNotUnderstand_ implementation.

        This can be overridden in derived prototypes to provide
        dynamic capability generation.
        """
        raise AttributeError(f"Message '{message_name}' not understood")

    # Persistence methods
    def markChanged(self):
        """
        Explicit persistence covenant fulfillment.
        """
        self._p_changed = True

    # Utility methods
    def __repr__(self):
        """
        Useful representation for debugging and inspection.
        """
        oid_bytes = getattr(self, '_p_oid', None)
        oid = int.from_bytes(oid_bytes, 'big') if oid_bytes else 'transient'
        keys = list(self._slots.keys()) if hasattr(self, '_slots') else []
        return f"<UvmObject OID:{oid} Slots:{keys}>"

    def __getstate__(self):
        """
        Custom pickling support for ZODB persistence.
        """
        state = object.__getstate__(self)
        # Filter out callable objects from _slots
        if '_slots' in state:
            state['_slots'] = {
                key: value for key, value in state['_slots'].items()
                if not callable(value)
            }
        return state

    def __setstate__(self, state):
        """
        Custom unpickling support for ZODB persistence.
        """
        object.__setstate__(self, state)
        # Reconstruct methods if this is a concept prototype
        if hasattr(self, '_slots') and 'oid' in self._slots:
            # This is a concept prototype - restore the markChanged method
            self._slots['markChanged'] = lambda: setattr(self, '_p_changed', True)

    # Attach methods to the prototype
    base.__getattr__ = __getattr__.__get__(base, type(base))
    base.__setattr__ = __setattr__.__get__(base, type(base))
    base.set_slot = set_slot.__get__(base, type(base))
    base.get_slot = get_slot.__get__(base, type(base))
    base.has_slot = has_slot.__get__(base, type(base))
    base.clone = clone.__get__(base, type(base))
    base.doesNotUnderstand_ = doesNotUnderstand_.__get__(base, type(base))
    base.markChanged = markChanged.__get__(base, type(base))
    base.__repr__ = __repr__.__get__(base, type(base))
    base.__getstate__ = __getstate__.__get__(base, type(base))
    base.__setstate__ = __setstate__.__get__(base, type(base))

    return base


# Global base prototype instance
_base_uvm_prototype = create_base_uvm_prototype()


# ==============================================================================
# Factory Functions for Prototypal Object Creation
# ==============================================================================

def create_uvm_object(**kwargs):
    """
    Factory function for creating UvmObject instances.

    This is the prototypal equivalent of a constructor - use this
    instead of class instantiation to maintain purity.

    Args:
        **kwargs: Initial slot values

    Returns:
        New UvmObject instance
    """
    # Clone the base prototype
    obj = _base_uvm_prototype.clone()

    # Set up initial slots
    for key, value in kwargs.items():
        if key == 'parent_star':
            # parent_star becomes the delegation chain
            obj._slots['parent*'] = PersistentList(value)
        else:
            obj._slots[key] = value

    return obj


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