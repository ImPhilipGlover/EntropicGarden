"""
TelOS Compilation Handlers - Python workers for Io-orchestrated compilation
"""

import json
import os
import sys
from typing import Dict, List, Any, Optional
import importlib.util

# Add the project root to Python path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))))

def handle_documentation_review(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle documentation review requests from Io compiler.
    Forces read_file on documentation files and analyzes content for relevant guidance.
    """
    doc_path = task_data.get("doc_path", "")
    error_details = task_data.get("error_details", "")
    subsystem = task_data.get("subsystem", "system")

    print(f"🔍 Reviewing documentation: {doc_path}")
    print(f"   Error context: {error_details}")

    try:
        # Force read the documentation file
        full_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__)))), doc_path)

        if not os.path.exists(full_path):
            return {
                "success": False,
                "relevant": False,
                "guidance": f"Documentation file not found: {doc_path}"
            }

        with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        print(f"   📖 Read {len(content)} characters from {doc_path}")

        # Analyze content for relevant guidance based on error details
        guidance = analyze_documentation_content(content, error_details, doc_path, subsystem)

        relevant = len(guidance.strip()) > 0 and not guidance.startswith("No specific")

        return {
            "success": True,
            "relevant": relevant,
            "guidance": guidance,
            "content_length": len(content)
        }

    except Exception as e:
        print(f"   ❌ Error reading documentation {doc_path}: {str(e)}")
        return {
            "success": False,
            "relevant": False,
            "guidance": f"Failed to read documentation: {str(e)}"
        }

def analyze_documentation_content(content: str, error_details: str, doc_path: str, subsystem: str) -> str:
    """
    Analyze documentation content for relevant guidance based on error details.
    """
    content_lower = content.lower()
    error_lower = error_details.lower()

    guidance_parts = []

    # Io Prototypes & Persistence guidance
    if subsystem == "io" or "io" in error_lower:
        if "prototype" in content_lower or "clone" in content_lower:
            guidance_parts.append("Io prototypal programming: Use Object clone do(...) instead of class definitions")
        if "persistence" in content_lower or "zodb" in content_lower:
            guidance_parts.append("Persistence covenant: Every state-modifying method must call markChanged()")
        if "message passing" in content_lower:
            guidance_parts.append("Io patterns: Use message passing (object method args) instead of direct function calls")

    # Python/UvmObject guidance
    if subsystem == "python" or "uvmobject" in error_lower or "python" in error_lower:
        if "uvmobject" in content_lower:
            guidance_parts.append("UvmObject requirement: All Python classes must inherit from UvmObject for prototypal emulation")
        if "factory function" in content_lower:
            guidance_parts.append("UvmObject instantiation: Use create_uvm_object() factory functions instead of direct class instantiation")
        if "differential inheritance" in content_lower:
            guidance_parts.append("UvmObject patterns: Use clone() for inheritance instead of class hierarchies")

    # C/Synaptic Bridge guidance
    if subsystem == "c" or "bridge" in error_lower or "synaptic" in error_lower or "ffi" in error_lower:
        if "synaptic bridge" in content_lower or "c abi" in content_lower:
            guidance_parts.append("Synaptic bridge: Use extern \"C\" declarations for stable ABI, avoid C++ features")
        if "handle" in content_lower and "based" in content_lower:
            guidance_parts.append("Bridge patterns: Use opaque handles (IoObjectHandle, SharedMemoryHandle) for GC safety")
        if "two-call" in content_lower:
            guidance_parts.append("Error handling: Use two-call protocol - primary call returns sentinel, second call gets error details")

    # Memory/Cache guidance
    if subsystem == "memory" or "memory" in error_lower or "cache" in error_lower:
        if "shared memory" in content_lower:
            guidance_parts.append("Memory management: Use SharedMemoryHandle for zero-copy IPC with large tensors")
        if "tiered cache" in content_lower:
            guidance_parts.append("Caching: Implement L1/L2/L3 cache hierarchy with FAISS and transactional outbox")
        if "zodb" in content_lower and "cache" in content_lower:
            guidance_parts.append("Persistence caching: Use ZODB with transactional outbox for cache synchronization")

    # LLM/Transduction guidance
    if subsystem == "llm" or "llm" in error_lower or "model" in error_lower:
        if "transduction" in content_lower:
            guidance_parts.append("LLM integration: Use transduction pipeline for natural language processing")
        if "vsa" in content_lower and "rag" in content_lower:
            guidance_parts.append("Neuro-symbolic: Combine VSA algebra with RAG for intelligent behavior")

    # UI/Morphic guidance
    if subsystem == "ui" or "morphic" in error_lower or "ui" in error_lower:
        if "morphic" in content_lower:
            guidance_parts.append("Morphic UI: Use living, directly manipulable objects for interface construction")
        if "direct manipulation" in content_lower:
            guidance_parts.append("UI patterns: Users reshape and reprogram interface elements at runtime")

    # Generic architectural guidance
    if not guidance_parts:
        if "telos" in content_lower and "architecture" in content_lower:
            guidance_parts.append(f"Review {doc_path} for TelOS architectural patterns and design principles")
        elif "design protocol" in content_lower:
            guidance_parts.append(f"Check {doc_path} for dynamic system resolution patterns")
        elif "blueprint" in content_lower:
            guidance_parts.append(f"Consult {doc_path} for high-level system synthesis and planning")
        else:
            guidance_parts.append(f"No specific guidance found in {doc_path} for the reported error")

    return " ".join(guidance_parts)

def handle_compilation_task(task_json: str) -> str:
    """
    Main entry point for compilation tasks from Io via synaptic bridge.
    """
    try:
        task_data = json.loads(task_json)
        operation = task_data.get("operation", "")

        print(f"🔧 Processing compilation task: {operation}")

        if operation == "review_documentation":
            result = handle_documentation_review(task_data)
        elif operation == "validate_uvm_inheritance":
            result = handle_uvm_validation(task_data)
        elif operation == "validate_telos_proxy_patterns":
            result = handle_telos_proxy_validation(task_data)
        elif operation == "validate_uvm_object":
            result = handle_uvm_object_validation(task_data)
        else:
            result = {
                "success": False,
                "error": f"Unknown operation: {operation}"
            }

        return json.dumps(result)

    except Exception as e:
        error_result = {
            "success": False,
            "error": f"Task processing failed: {str(e)}"
        }
        return json.dumps(error_result)

# Import and use other handlers
def handle_uvm_validation(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle UvmObject inheritance validation"""
    try:
        from .uvm_object import validate_uvm_inheritance
        return validate_uvm_inheritance(task_data)
    except ImportError:
        return {"success": False, "error": "UvmObject validation not available"}

def handle_telos_proxy_validation(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle TelosProxyObject pattern validation"""
    # TODO: Implement C pattern validation
    return {"success": True, "violation_count": 0, "violations": []}

def handle_uvm_object_validation(task_data: Dict[str, Any]) -> Dict[str, Any]:
    """Handle UvmObject availability validation"""
    try:
        from .uvm_object import UvmObject
        return {"success": True, "message": "UvmObject is available"}
    except ImportError:
        return {"success": False, "error": "UvmObject not available"}