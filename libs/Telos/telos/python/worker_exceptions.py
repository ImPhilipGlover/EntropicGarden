"""
TELOS Worker Exceptions

Prototypal exception objects for TELOS worker operations.
No inheritance - pure prototypal design with delegation.
"""

from .uvm_object import create_uvm_object


class TelosProxyError(Exception):
    """
    Exception class for TELOS proxy operations.
    
    Inherits from Exception for Python compatibility while maintaining
    prototypal design through composition with UvmObject.
    """
    
    def __init__(self, message: str, slot_name: str = None, prototype_chain: list = None):
        super().__init__(message)
        
        # Create prototypal backing object
        self._proto = create_uvm_object({
            'message': message,
            'slot_name': slot_name,
            'prototype_chain': prototype_chain or [],
            'error_type': 'TelosProxyError',
            'timestamp': __import__('datetime').datetime.now().isoformat()
        })
        
        # Copy key attributes for direct access
        self.message = message
        self.slot_name = slot_name
        self.prototype_chain = prototype_chain or []
        self.error_type = 'TelosProxyError'
    
    def get_slot(self, name: str, default=None):
        """Prototypal slot lookup with delegation."""
        return getattr(self._proto, name, default)
    
    def set_slot(self, name: str, value):
        """Prototypal slot setting."""
        setattr(self._proto, name, value)
    
    def __str__(self):
        """String representation for compatibility."""
        chain_info = f" (slot: {self.slot_name})" if self.slot_name else ""
        return f"{self.error_type}: {self.message}{chain_info}"
    
    def __repr__(self):
        """Representation for debugging."""
        return f"{self.error_type}({self.message!r})"


class TelosWorkerError(Exception):
    """
    Exception class for TELOS worker operations.
    
    Inherits from Exception for Python compatibility while maintaining
    prototypal design through composition with UvmObject.
    """
    
    def __init__(self, message: str, worker_id: int = None, operation: str = None):
        super().__init__(message)
        
        # Create base proxy error and extend with worker-specific slots
        self._proto = create_uvm_object({
            'message': message,
            'worker_id': worker_id,
            'operation': operation,
            'error_type': 'TelosWorkerError',
            'timestamp': __import__('datetime').datetime.now().isoformat()
        })
        
        # Copy key attributes for direct access
        self.message = message
        self.worker_id = worker_id
        self.operation = operation
        self.error_type = 'TelosWorkerError'
        
        # Update message to include worker context
        if worker_id is not None:
            enhanced_message = f"Worker {worker_id}: {message}"
            if operation:
                enhanced_message = f"Worker {worker_id} operation '{operation}': {message}"
            self.message = enhanced_message
            self._proto.message = enhanced_message
    
    def get_slot(self, name: str, default=None):
        """Prototypal slot lookup with delegation."""
        return getattr(self._proto, name, default)
    
    def set_slot(self, name: str, value):
        """Prototypal slot setting."""
        setattr(self._proto, name, value)
    
    def __str__(self):
        """String representation for compatibility."""
        return f"{self.error_type}: {self.message}"
    
    def __repr__(self):
        """Representation for debugging."""
        return f"{self.error_type}({self.message!r})"


# Factory functions for backward compatibility
def create_telos_proxy_error(message: str, slot_name: str = None, prototype_chain: list = None):
    """
    Factory function for creating TelosProxyError instances.
    """
    return TelosProxyError(message, slot_name, prototype_chain)


def create_telos_worker_error(message: str, worker_id: int = None, operation: str = None):
    """
    Factory function for creating TelosWorkerError instances.
    """
    return TelosWorkerError(message, worker_id, operation)