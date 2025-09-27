#!/usr/bin/env python3

"""
Simple test to isolate the bridge initialization issue
"""

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, '.')

def test_basic_import():
    """Test that we can import the bridge module"""
    try:
        import _telos_bridge
        print("✓ Successfully imported _telos_bridge")
        return _telos_bridge
    except Exception as e:
        print(f"✗ Failed to import _telos_bridge: {e}")
        return None

def test_ffi_import(bridge_module):
    """Test that we can import the ffi object"""
    try:
        from _telos_bridge import ffi
        print("✓ Successfully imported ffi")
        return ffi
    except Exception as e:
        print(f"✗ Failed to import ffi: {e}")
        return None

def test_function_existence(bridge_module):
    """Test that bridge functions exist"""
    try:
        lib = bridge_module.lib
        functions = [name for name in dir(lib) if name.startswith('bridge_')]
        print(f"✓ Found {len(functions)} bridge functions")
        for func in functions[:5]:  # Show first 5
            print(f"  - {func}")
        return lib
    except Exception as e:
        print(f"✗ Failed to access bridge functions: {e}")
        return None

def test_simple_function_call(lib, ffi):
    """Test calling a simple function that shouldn't crash"""
    try:
        # Test clear_error first - this should be safe
        print("Testing bridge_clear_error...")
        lib.bridge_clear_error()
        print("✓ bridge_clear_error succeeded")
        
        # Test get_last_error
        print("Testing bridge_get_last_error...")
        error_buffer = ffi.new('char[]', 256)
        result = lib.bridge_get_last_error(error_buffer, 256)
        error_str = ffi.string(error_buffer).decode('utf-8')
        print(f"✓ bridge_get_last_error succeeded: result={result}, error='{error_str}'")
        
        return True
    except Exception as e:
        print(f"✗ Simple function call failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_initialization(lib):
    """Test the problematic initialization function"""
    try:
        print("Testing bridge_initialize with debug...")
        
        # First, let's see if we can even get the function address
        init_func = getattr(lib, 'bridge_initialize', None)
        if init_func is None:
            print("✗ bridge_initialize function not found")
            return False
        
        print(f"✓ bridge_initialize function found: {init_func}")
        
        # Try to call it
        print("Calling bridge_initialize(4)...")
        result = init_func(4)
        print(f"✓ bridge_initialize succeeded: result={result}")
        
        return True
    except Exception as e:
        print(f"✗ bridge_initialize failed: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    print("=== TELOS Bridge Debug Test ===")
    
    # Test 1: Basic import
    bridge_module = test_basic_import()
    if not bridge_module:
        return 1
    
    # Test 2: FFI import
    ffi = test_ffi_import(bridge_module)
    if not ffi:
        return 1
    
    # Test 3: Function existence
    lib = test_function_existence(bridge_module)
    if not lib:
        return 1
    
    # Test 4: Simple function calls
    if not test_simple_function_call(lib, ffi):
        return 1
    
    # Test 5: The problematic initialization
    if not test_initialization(lib):
        return 1
    
    print("✓ All tests passed!")
    return 0

if __name__ == "__main__":
    sys.exit(main())