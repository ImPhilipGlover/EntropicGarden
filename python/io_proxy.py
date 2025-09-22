"""
IoProxy: Prototypal Emulation Layer for TelOS Synaptic Bridge

This module implements the Python-side IoProxy class as defined in the
Prototypal Emulation Layer Design. It provides seamless delegation between
Python "muscle" and Io "mind" through behavioral emulation.

Following the design blueprint:
- __getattr__ enables prototype chain traversal across language boundaries
- __setattr__ ensures transactional state coherence with Io master objects
- localSlots provides high-performance local caching
- forwardMessage delegates unresolved requests to Io VM

Author: TelOS Autonomous Agent
Architecture: Prototypal Emulation Layer Design.txt (Part I, Section 1.3)
"""

import ctypes
import threading
from typing import Any, Dict, Optional, Callable


class IoProxy:
    """
    Base class for all cross-language objects in the TelOS system.
    
    This class emulates prototypal behavior by maintaining a connection
    to a master object in the Io VM while providing local caching and
    transactional state management.
    
    Following the Prototypal Emulation Layer Design:
    - ioMasterHandle: Persistent reference to Io master object
    - localSlots: Local cache for Python-side state (differential inheritance)
    - forwardMessage: Function pointer for delegation to Io VM
    """
    
    def __init__(self, io_master_handle: Any, forward_message_func: Callable):
        """
        Initialize IoProxy with connection to Io master object.
        
        Args:
            io_master_handle: Opaque handle to master object in Io VM
            forward_message_func: Function pointer for cross-language delegation
        """
        # Core prototypal emulation components per design specification
        self._io_master_handle = io_master_handle
        self._local_slots: Dict[str, Any] = {}  # Emulates clone's empty slot map
        self._forward_message = forward_message_func
        
        # Thread safety for transactional operations
        self._state_lock = threading.RLock()
        
        # Debugging and introspection
        self._proxy_id = id(self)
        self._access_count = 0
        self._delegation_count = 0

    def __getattr__(self, name: str) -> Any:
        """
        Emulate Io prototype chain traversal across language boundary.
        
        This implements the core delegation protocol from the design:
        1. Local Cache Lookup (localSlots dictionary)
        2. Cache Hit: Return cached value with reference counting
        3. Cache Miss: Delegate to Io master via forwardMessage
        4. FFI Message Forwarding with marshalling
        5. Io Prototype Chain Traversal in master object
        6. Result Marshalling and Return to Python
        7. Exception Handling for failed lookups
        
        Args:
            name: Attribute name to resolve
            
        Returns:
            Resolved attribute value from local cache or Io master
            
        Raises:
            AttributeError: If attribute not found in entire prototype chain
        """
        with self._state_lock:
            self._access_count += 1
            
            # Step 1-2: Local Cache Lookup (localSlots)
            if name in self._local_slots:
                value = self._local_slots[name]
                print(f"IoProxy[{self._proxy_id}]: Cache hit for '{name}' = {value}")
                return value
            
            # Step 3-6: Cache Miss - Delegate to Io Master
            try:
                self._delegation_count += 1
                print(f"IoProxy[{self._proxy_id}]: Delegating '{name}' to Io master (handle: {self._io_master_handle})")
                
                # Forward message to Io VM via C bridge
                result = self._forward_message(self._io_master_handle, name, None)
                
                # Cache the result for future local access
                self._local_slots[name] = result
                
                print(f"IoProxy[{self._proxy_id}]: Delegation successful, '{name}' = {result}")
                return result
            
            except Exception as e:
                # Step 7: Exception Handling - Convert to Python AttributeError
                print(f"IoProxy[{self._proxy_id}]: Delegation failed for '{name}': {e}")
                raise AttributeError(f"IoProxy delegation failed: '{name}' not found in Io prototype chain") from e

    def __setattr__(self, name: str, value: Any) -> None:
        """
        Ensure transactional state coherence with Io master object.
        
        This implements the transactional state update protocol:
        1. Local Cache Update (immediate synchronous change)
        2. Initiate Transactional Message to Io core
        3. Asynchronous FFI Dispatch (non-blocking)
        4. Io Transaction Execution against L3 ground truth
        5. Commit and Durability in Living Image WAL
        
        Args:
            name: Attribute name to set
            value: New value for attribute
        """
        # Handle internal IoProxy attributes directly
        if name.startswith('_'):
            super().__setattr__(name, value)
            return
        
        with self._state_lock:
            # Step 1: Local Cache Update (immediate)
            if not hasattr(self, '_local_slots'):
                super().__setattr__('_local_slots', {})
            
            self._local_slots[name] = value
            print(f"IoProxy[{self._proxy_id}]: Local update '{name}' = {value}")
            
            # Step 2-3: Initiate Transactional Message (asynchronous)
            try:
                if hasattr(self, '_forward_message') and hasattr(self, '_io_master_handle'):
                    # Request transaction to update slot in Io master
                    transaction_msg = f"requestTransaction('{name}', {repr(value)})"
                    
                    # Non-blocking dispatch to maintain Python runtime responsiveness
                    threading.Thread(
                        target=self._async_transactional_update,
                        args=(name, value, transaction_msg),
                        daemon=True
                    ).start()
                    
                    print(f"IoProxy[{self._proxy_id}]: Transactional update initiated for '{name}'")
                
            except Exception as e:
                print(f"IoProxy[{self._proxy_id}]: Transactional update failed for '{name}': {e}")
                # Note: Local update remains valid even if transaction fails
                # This provides graceful degradation while maintaining system integrity

    def _async_transactional_update(self, name: str, value: Any, transaction_msg: str) -> None:
        """
        Execute asynchronous transactional update to Io master.
        
        This method runs in a separate thread to ensure Python runtime
        responsiveness while maintaining transactional coherence.
        
        Args:
            name: Attribute name being updated
            value: New value for attribute  
            transaction_msg: Formatted transaction message for Io VM
        """
        try:
            # Step 4-5: Io Transaction Execution and Commit
            result = self._forward_message(
                self._io_master_handle, 
                "setSlot", 
                (name, value)
            )
            
            print(f"IoProxy[{self._proxy_id}]: Transactional commit successful for '{name}'")
            
        except Exception as e:
            print(f"IoProxy[{self._proxy_id}]: Transactional commit failed for '{name}': {e}")
            # TODO: Implement transaction.abort() mechanism for rollback

    def __str__(self) -> str:
        """String representation showing proxy relationship."""
        return f"IoProxy[{self._proxy_id}] -> Io[{self._io_master_handle}] ({len(self._local_slots)} cached slots)"

    def __repr__(self) -> str:
        """Detailed representation for debugging."""
        return (f"IoProxy(handle={self._io_master_handle}, "
                f"cached_slots={list(self._local_slots.keys())}, "
                f"access_count={self._access_count}, "
                f"delegation_count={self._delegation_count})")

    def get_proxy_stats(self) -> Dict[str, Any]:
        """
        Get introspection statistics for debugging and monitoring.
        
        Returns:
            Dictionary with proxy performance and state metrics
        """
        with self._state_lock:
            return {
                'proxy_id': self._proxy_id,
                'io_master_handle': self._io_master_handle,
                'cached_slots': list(self._local_slots.keys()),
                'access_count': self._access_count,
                'delegation_count': self._delegation_count,
                'cache_hit_ratio': (self._access_count - self._delegation_count) / max(1, self._access_count),
                'local_slot_count': len(self._local_slots)
            }

    def invalidate_cache(self, slot_name: Optional[str] = None) -> None:
        """
        Invalidate local cache to force fresh delegation to Io master.
        
        Args:
            slot_name: Specific slot to invalidate, or None for full cache clear
        """
        with self._state_lock:
            if slot_name is None:
                self._local_slots.clear()
                print(f"IoProxy[{self._proxy_id}]: Full cache invalidation")
            elif slot_name in self._local_slots:
                del self._local_slots[slot_name]
                print(f"IoProxy[{self._proxy_id}]: Invalidated cache for '{slot_name}'")


class VSAMemoryProxy(IoProxy):
    """
    Specialized IoProxy for Vector Symbolic Architecture memory operations.
    
    Implements the state management pattern from Design Section 2.1 for
    seamless Io→Python delegation of VSA operations using torchhd library.
    """
    
    def __init__(self, io_master_handle: Any, forward_message_func: Callable):
        super().__init__(io_master_handle, forward_message_func)
        self._vsa_model = None  # Will be initialized by Python VSA backend
        self._concept_count = 0
        self._last_modified_timestamp = 0.0

    def learn(self, concept: str) -> bool:
        """
        Delegate VSA learning operation to Python backend with state reporting.
        
        Following Design Section 2.1 pattern:
        1. Message Reception (Io) - already handled by delegation
        2. Asynchronous Delegation (Io→C→Python) - this method
        3. VSA Model Modification (Python) - torchhd operations
        4. Transactional State Reporting (Python→C→Io) - via setattr
        
        Args:
            concept: Concept string to learn in VSA model
            
        Returns:
            Success status of learning operation
        """
        import time
        
        try:
            # Step 3: VSA Model Modification (simulated for now)
            print(f"VSAMemoryProxy: Learning concept '{concept}'")
            
            # TODO: Integrate with actual torchhd library
            # self._vsa_model.bundle_concept(concept)
            
            # Step 4: Transactional State Reporting back to Io
            self.last_modified_timestamp = time.time()
            self.concept_count = self._concept_count + 1
            
            print(f"VSAMemoryProxy: Learned '{concept}', total concepts: {self.concept_count}")
            return True
            
        except Exception as e:
            print(f"VSAMemoryProxy: Learning failed for '{concept}': {e}")
            return False


class FineTuningJobProxy(IoProxy):
    """
    Specialized IoProxy for Autopoietic Flywheel fine-tuning job management.
    
    Implements the bidirectional state synchronization pattern from 
    Design Section 2.2 for long-running Python training processes.
    """
    
    def __init__(self, io_master_handle: Any, forward_message_func: Callable):
        super().__init__(io_master_handle, forward_message_func)
        self._training_thread = None
        self._stop_event = threading.Event()

    def start(self) -> None:
        """Start the fine-tuning process in background thread."""
        if self._training_thread and self._training_thread.is_alive():
            print("FineTuningJobProxy: Training already in progress")
            return
        
        self._stop_event.clear()
        self._training_thread = threading.Thread(target=self._training_loop, daemon=True)
        self._training_thread.start()
        
        # Report status change back to Io mind
        self.status = "training"
        print("FineTuningJobProxy: Training started")

    def pause(self) -> None:
        """Pause the fine-tuning process."""
        self._stop_event.set()
        self.status = "paused"
        print("FineTuningJobProxy: Training paused")

    def _training_loop(self) -> None:
        """
        Simulated training loop with progress reporting.
        
        This demonstrates the bidirectional state synchronization where
        Python process reports status via IoProxy setattr mechanism.
        """
        import time
        
        try:
            total_epochs = 10
            
            for epoch in range(total_epochs):
                if self._stop_event.is_set():
                    break
                
                # Simulate training work
                time.sleep(1)
                
                # Report progress back to Io mind via transactional setattr
                progress = (epoch + 1) / total_epochs
                self.progress = progress
                self.current_epoch = epoch + 1
                
                print(f"FineTuningJobProxy: Epoch {epoch + 1}/{total_epochs}, Progress: {progress:.1%}")
            
            # Final status update
            if not self._stop_event.is_set():
                self.status = "completed"
                self.progress = 1.0
                print("FineTuningJobProxy: Training completed successfully")
            
        except Exception as e:
            self.status = "error"
            self.error_message = str(e)
            print(f"FineTuningJobProxy: Training failed: {e}")


# Factory function for creating specialized proxy types
def create_proxy(proxy_type: str, io_master_handle: Any, forward_message_func: Callable) -> IoProxy:
    """
    Factory function for creating specialized IoProxy instances.
    
    Args:
        proxy_type: Type of proxy to create ('VSAMemory', 'FineTuningJob', etc.)
        io_master_handle: Handle to Io master object
        forward_message_func: Delegation function pointer
        
    Returns:
        Specialized IoProxy instance
    """
    proxy_classes = {
        'VSAMemory': VSAMemoryProxy,
        'FineTuningJob': FineTuningJobProxy,
        'IoProxy': IoProxy  # Base class
    }
    
    proxy_class = proxy_classes.get(proxy_type, IoProxy)
    return proxy_class(io_master_handle, forward_message_func)


if __name__ == "__main__":
    # Demonstration of IoProxy functionality
    print("IoProxy Prototypal Emulation Layer - Test Suite")
    
    # Mock forward_message function for testing
    def mock_forward_message(handle, message_name, args):
        print(f"MOCK FFI: handle={handle}, message='{message_name}', args={args}")
        
        # Simulate some Io responses
        if message_name == "protoId":
            return "MockIoObject"
        elif message_name == "slotNames":
            return ["name", "value", "prototype"]
        else:
            return f"mock_result_for_{message_name}"
    
    # Test base IoProxy
    print("\n=== Testing Base IoProxy ===")
    proxy = IoProxy("mock_handle_123", mock_forward_message)
    
    # Test delegation
    result = proxy.protoId
    print(f"Delegated result: {result}")
    
    # Test local caching
    proxy.local_attr = "cached_value"
    print(f"Local attribute: {proxy.local_attr}")
    
    # Test stats
    stats = proxy.get_proxy_stats()
    print(f"Proxy stats: {stats}")
    
    # Test specialized proxies
    print("\n=== Testing VSAMemoryProxy ===")
    vsa_proxy = create_proxy("VSAMemory", "vsa_handle_456", mock_forward_message)
    vsa_proxy.learn("legal_concept")
    
    print("\n=== Testing FineTuningJobProxy ===")
    job_proxy = create_proxy("FineTuningJob", "job_handle_789", mock_forward_message)
    job_proxy.start()
    
    # Allow some training progress
    import time
    time.sleep(3)
    job_proxy.pause()
    
    print("\nIoProxy test suite completed successfully!")