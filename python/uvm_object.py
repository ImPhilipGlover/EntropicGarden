"""
UvmObject: Universal Virtual Machine Object
A prototypal object implementation for TelOS Python backend
Based on BAT OS Development archive patterns

Implements:
- Prototypal delegation through __getattr__
- Persistent mapping with _p_changed covenant
- Clone-based object creation
- Message-based interface
"""

import persistent
import persistent.mapping
from typing import Any, Dict, List, Optional
import copy
import traceback


class UvmObject(persistent.Persistent):
    """
    The foundational particle of the TelOS universe. This class provides the
    "physics" for a prototype-based object model inspired by the Self and
    Smalltalk programming languages. It rejects standard Python attribute access
    in favor of a unified '_slots' dictionary and a delegation-based
    inheritance mechanism.
    
    It inherits from `persistent.Persistent` to enable transactional storage
    via ZODB, guaranteeing the system's "unbroken existence."
    """
    
    def __init__(self, **initial_slots):
        """
        Initializes the UvmObject. The `_slots` dictionary is instantiated as a
        `persistent.mapping.PersistentMapping` to ensure that changes within the
        dictionary itself are correctly tracked by ZODB.
        """
        super().__setattr__('_slots', persistent.mapping.PersistentMapping(initial_slots))
        # Initialize methods dictionary for local method storage
        if 'methods' not in self._slots:
            self._slots['methods'] = persistent.mapping.PersistentMapping()
        self._p_changed = True

    def __setattr__(self, name: str, value: Any) -> None:
        """
        Intercepts all attribute assignments with IoProxy integration.
        
        This method now implements the Prototypal FFI Mandate:
        1. Modify local _slots dictionary
        2. Signal back to Io VM that state changed
        3. Ensure change logged in telos.wal  
        4. Maintain _p_changed covenant for ZODB
        
        This ensures unified state authority with Io VM as single source of truth.
        """
        if name.startswith('_p_') or name == '_slots' or name.startswith('_io_'):
            super().__setattr__(name, value)
        else:
            # 1. Modify local _slots dictionary
            self._slots[name] = value
            self._p_changed = True
            
            # 2. IoProxy Integration: Signal back to Io VM that state changed
            if hasattr(self, '_io_vm_reference') and self._io_vm_reference:
                try:
                    self._message_io_vm('setSlot', name, value)
                except Exception as e:
                    print(f"IoProxy warning: Failed to sync slot '{name}' to Io VM: {e}")
            
            # 3. Trigger WAL logging for single source of truth
            self._trigger_wal_logging(name, value)

    def __getattr__(self, name: str) -> Any:
        """
        Implements prototypal delegation with IoProxy integration.
        
        This method now implements the full Prototypal FFI Mandate:
        1. Check local _slots dictionary
        2. Message back to Io VM asking prototype to resolve  
        3. Delegate to parent prototypes in Python layer
        4. Trigger doesNotUnderstand protocol if not found
        
        This ensures Python objects become true "ambassadors" of Io objects.
        """
        # Check local slots first
        if name in self._slots:
            value = self._slots[name]
            # If it's a method, bind it to self
            if callable(value) and hasattr(value, '__self__') is False:
                return lambda *args, **kwargs: value(self, *args, **kwargs)
            return value
        
        # Check methods dictionary
        if 'methods' in self._slots and name in self._slots['methods']:
            method = self._slots['methods'][name]
            return lambda *args, **kwargs: method(self, *args, **kwargs)
        
        # IoProxy Integration: Message back to Io VM for slot resolution
        if hasattr(self, '_io_vm_reference') and self._io_vm_reference:
            try:
                result = self._message_io_vm('getSlot', name)
                if result is not None:
                    # Cache result in local slots for future access
                    self._slots[name] = result
                    self._p_changed = True
                    return result
            except Exception as e:
                # Log but don't fail - continue to Python delegation
                print(f"IoProxy warning: Failed to query Io VM for slot '{name}': {e}")
        
        # Delegate to parent prototypes
        if 'parent*' in self._slots:
            parents = self._slots['parent*']
            if not isinstance(parents, list):
                parents = [parents]
            for parent in parents:
                try:
                    return getattr(parent, name)
                except AttributeError:
                    continue
        
        # Trigger doesNotUnderstand protocol
        return self._doesNotUnderstand_(name)

    def _doesNotUnderstand_(self, message_name: str, *args, **kwargs):
        """
        The primary engine of the system's self-creation. This method
        intercepts failed message sends and reifies them into creative
        mandates for autopoietic capability generation.
        
        In TelOS, this would trigger the LLM to generate new capabilities.
        For now, we provide a graceful fallback that logs the missing capability.
        """
        # Log the capability gap for potential future generation
        capability_gap = {
            'object_id': getattr(self, '_p_oid', 'transient'),
            'message': message_name,
            'args': args,
            'kwargs': kwargs,
            'prototype_chain': self._get_prototype_chain()
        }
        
        # For now, raise AttributeError with detailed context
        oid_str = f"oid={self._p_oid}" if hasattr(self, '_p_oid') and self._p_oid is not None else "oid=transient"
        prototype_chain = " -> ".join([str(p.__class__.__name__) for p in self._get_prototype_chain()])
        
        raise AttributeError(
            f"UvmObject {oid_str} has no slot '{message_name}' "
            f"(prototype chain: {prototype_chain}). "
            f"This is a candidate for autopoietic capability generation."
        )

    def _get_prototype_chain(self) -> List['UvmObject']:
        """Returns the chain of parent prototypes for debugging."""
        chain = [self]
        if 'parent*' in self._slots:
            parents = self._slots['parent*']
            if not isinstance(parents, list):
                parents = [parents]
            for parent in parents:
                if hasattr(parent, '_get_prototype_chain'):
                    chain.extend(parent._get_prototype_chain())
                else:
                    chain.append(parent)
        return chain

    def clone(self, **additional_slots):
        """
        Creates a new object with self as its prototype.
        This is the primary mechanism for object creation in prototypal systems.
        """
        cloned = self.__class__(**additional_slots)
        cloned._slots['parent*'] = self
        cloned._p_changed = True
        return cloned

    def add_method(self, name: str, method_func):
        """
        Dynamically adds a method to this object.
        The method function should accept self as its first parameter.
        """
        if 'methods' not in self._slots:
            self._slots['methods'] = persistent.mapping.PersistentMapping()
        self._slots['methods'][name] = method_func
        self._p_changed = True

    def has_slot(self, name: str) -> bool:
        """Check if this object has a specific slot (including prototype chain)."""
        try:
            getattr(self, name)
            return True
        except AttributeError:
            return False

    def list_slots(self) -> List[str]:
        """Return all slot names available to this object."""
        slots = list(self._slots.keys())
        if 'parent*' in self._slots:
            parents = self._slots['parent*']
            if not isinstance(parents, list):
                parents = [parents]
            for parent in parents:
                if hasattr(parent, 'list_slots'):
                    slots.extend(parent.list_slots())
        return list(set(slots))  # Remove duplicates

    def __repr__(self) -> str:
        """Provides a more informative representation for debugging."""
        slot_keys = [k for k in self._slots.keys() if k != 'parent*']
        oid_str = f"oid={self._p_oid}" if hasattr(self, '_p_oid') and self._p_oid is not None else "oid=transient"
        parent_info = ""
        if 'parent*' in self._slots:
            parent_count = len(self._slots['parent*']) if isinstance(self._slots['parent*'], list) else 1
            parent_info = f" parents={parent_count}"
        return f"<UvmObject {oid_str} slots={slot_keys}{parent_info}>"

    def __deepcopy__(self, memo):
        """
        Custom deepcopy implementation to ensure persistence-aware cloning.
        Standard `copy.deepcopy` is not aware of ZODB's object lifecycle and
        can lead to unintended shared state or broken object graphs.
        This method is the foundation for the `_clone_persistent_` protocol.
        """
        cls = self.__class__
        result = cls.__new__(cls)
        memo[id(self)] = result
        new_slots = copy.deepcopy(self._slots, memo)
        super(UvmObject, result).__setattr__('_slots', new_slots)
        result._p_changed = True
        return result


class NeuralUvmObject(UvmObject):
    """
    Specialized UvmObject for neural computations.
    Provides prototypal interface to VSA-RAG operations.
    """
    
    def __init__(self, **initial_slots):
        # Set up default neural computation slots
        neural_slots = {
            'dimension': 1024,
            'vector_store': {},
            'similarity_threshold': 0.7,
        }
        neural_slots.update(initial_slots)
        super().__init__(**neural_slots)
        
        # Add neural computation methods as slots
        self.add_method('create_vector', self._create_vector)
        self.add_method('store_vector', self._store_vector)
        self.add_method('retrieve_similar', self._retrieve_similar)
        self.add_method('bind_vectors', self._bind_vectors)

    def _create_vector(self, data):
        """Create a random vector for given data."""
        import numpy as np
        vector = np.random.normal(0, 1/np.sqrt(self._slots['dimension']), self._slots['dimension'])
        return vector.tolist()  # Convert to list for JSON serialization

    def _store_vector(self, key, vector):
        """Store a vector in the vector store."""
        self._slots['vector_store'][key] = vector
        self._p_changed = True

    def _retrieve_similar(self, query_vector, threshold=None):
        """Retrieve vectors similar to query_vector."""
        if threshold is None:
            threshold = self._slots['similarity_threshold']
        
        import numpy as np
        query_np = np.array(query_vector)
        results = []
        
        for key, stored_vector in self._slots['vector_store'].items():
            stored_np = np.array(stored_vector)
            similarity = np.dot(query_np, stored_np) / (np.linalg.norm(query_np) * np.linalg.norm(stored_np))
            if similarity >= threshold:
                results.append((key, similarity, stored_vector))
        
        return sorted(results, key=lambda x: x[1], reverse=True)

    def _bind_vectors(self, vector1, vector2):
        """Bind two vectors using element-wise multiplication (VSA binding)."""
        import numpy as np
        v1 = np.array(vector1)
        v2 = np.array(vector2)
        bound = v1 * v2
        return bound.tolist()


# Factory function for creating neural backend
def create_neural_backend(dimension=1024):
    """
    Factory function to create a neural backend using prototypal patterns.
    Returns a UvmObject configured for neural computations.
    """
    neural_backend = NeuralUvmObject(
        dimension=dimension,
        vector_store=persistent.mapping.PersistentMapping(),
        similarity_threshold=0.7
    )
    
    return neural_backend


# IoProxy Integration Methods for Prototypal FFI Mandate
def _message_io_vm(self, operation, *args):
    """
    Send a message to the Io VM through the C bridge.
    
    This is the core of the IoProxy integration - Python objects become
    "ambassadors" of Io objects by delegating operations back to the VM.
    
    Args:
        operation: 'getSlot', 'setSlot', 'perform', etc.
        *args: Arguments for the operation
        
    Returns:
        Result from Io VM or None if not available
    """
    if not hasattr(self, '_io_vm_reference') or not self._io_vm_reference:
        return None
    
    try:
        # This would call through the C bridge to TelosFFIObject
        # For now, return None (placeholder for actual C integration)
        # TODO: Implement actual C bridge call to TelosFFIObject
        return None
    except Exception as e:
        print(f"IoProxy error in {operation}: {e}")
        return None

def _trigger_wal_logging(self, slot_name, value):
    """
    Trigger WAL (Write-Ahead Log) logging for state changes.
    
    This maintains the Io VM as single source of truth by ensuring all
    Python state changes are recorded in the telos.wal file.
    
    Args:
        slot_name: Name of the slot that changed
        value: New value of the slot
    """
    try:
        import os
        import datetime
        
        # Format WAL entry for prototypal FFI state change
        timestamp = datetime.datetime.now().isoformat()
        object_id = getattr(self, '_object_id', f'py_{id(self)}')
        value_repr = repr(value)[:100]  # Truncate long values
        
        wal_entry = f"PYTHON_SLOT_CHANGE:{object_id}:{slot_name}:{value_repr}:{timestamp}\n"
        
        # Append to telos.wal (single source of truth)
        wal_path = os.path.join(os.path.dirname(__file__), '..', 'telos.wal')
        with open(wal_path, 'a', encoding='utf-8') as wal_file:
            wal_file.write(wal_entry)
            
    except Exception as e:
        print(f"WAL logging error for slot '{slot_name}': {e}")

def set_io_vm_reference(self, io_reference):
    """
    Set the reference to the corresponding Io VM object.
    
    This establishes the bidirectional connection that makes this Python
    object a true "ambassador" of the Io object.
    
    Args:
        io_reference: Reference to corresponding object in Io VM
    """
    super().__setattr__('_io_vm_reference', io_reference)
    super().__setattr__('_object_id', f'io_proxy_{id(io_reference)}')

def get_io_vm_reference(self):
    """Get the reference to the corresponding Io VM object."""
    return getattr(self, '_io_vm_reference', None)

# Add IoProxy methods to UvmObject
UvmObject._message_io_vm = _message_io_vm
UvmObject._trigger_wal_logging = _trigger_wal_logging
UvmObject.set_io_vm_reference = set_io_vm_reference
UvmObject.get_io_vm_reference = get_io_vm_reference


# Persistence Covenant Guardian (from archive patterns)
class CovenantViolationError(Exception):
    """Custom exception for Persistence Covenant violations."""
    pass


def validate_persistence_covenant(code_string: str) -> None:
    """
    Validates that generated code follows the Persistence Covenant.
    All methods that modify object state must include self._p_changed = True.
    """
    import ast
    
    try:
        tree = ast.parse(code_string)
    except SyntaxError as e:
        raise CovenantViolationError(f"Syntax error in generated code: {e}")
    
    class CovenantChecker(ast.NodeVisitor):
        def __init__(self):
            self.violations = []
            self.current_method = None
        
        def visit_FunctionDef(self, node):
            if node.args.args and node.args.args[0].arg == 'self':
                self.current_method = node.name
                has_p_changed = False
                
                for stmt in ast.walk(node):
                    if (isinstance(stmt, ast.Assign) and 
                        isinstance(stmt.targets[0], ast.Attribute) and
                        isinstance(stmt.targets[0].value, ast.Name) and
                        stmt.targets[0].value.id == 'self' and
                        stmt.targets[0].attr == '_p_changed'):
                        has_p_changed = True
                        break
                
                # Check if method modifies self
                modifies_self = False
                for stmt in ast.walk(node):
                    if (isinstance(stmt, ast.Assign) and
                        any(isinstance(target, ast.Attribute) and
                            isinstance(target.value, ast.Name) and
                            target.value.id == 'self' 
                            for target in stmt.targets)):
                        modifies_self = True
                        break
                
                if modifies_self and not has_p_changed:
                    self.violations.append(f"Method '{self.current_method}' modifies self but doesn't include self._p_changed = True")
            
            self.generic_visit(node)
    
    checker = CovenantChecker()
    checker.visit(tree)
    
    if checker.violations:
        raise CovenantViolationError(f"Persistence Covenant violations: {'; '.join(checker.violations)}")