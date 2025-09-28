"""
LLM Transducer Handler for TELOS Workers

This module contains the handler for LLM transducer operations,
extracted from workers.py for modularization.
"""

import json
from typing import Dict, Any, Optional

# Import UvmObject for prototypal object creation
try:
    from .uvm_object import UvmObject, create_uvm_object
except ImportError:  # pragma: no cover - fallback for direct execution
    from uvm_object import UvmObject, create_uvm_object  # type: ignore

from .llm_transducer import LLMTransducer


def handle_llm_transducer(worker, request_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Handle LLM transducer operations.

    Args:
        worker: The worker instance
        request_data: The request data containing operation parameters

    Returns:
        Dict containing the operation result
    """
    logger = worker.get_slot('logger')

    try:
        # Get the transduction type from the request
        transduction_type = request_data.get('type')
        if not transduction_type:
            return {
                'success': False,
                'error': 'Missing transduction type in request',
            }

        # Get the input data
        data = request_data.get('data', {})

        # Create or get LLM transducer instance
        transducer = LLMTransducer()

        # Route to appropriate transduction method
        if transduction_type == 'text_to_schema':
            result = _handle_text_to_schema(transducer, data, logger)
        elif transduction_type == 'schema_to_text':
            result = _handle_schema_to_text(transducer, data, logger)
        elif transduction_type == 'text_to_tool_call':
            result = _handle_text_to_tool_call(transducer, data, logger)
        elif transduction_type == 'status':
            result = _handle_status(transducer, logger)
        else:
            return {
                'success': False,
                'error': f'Unknown transduction type: {transduction_type}',
            }

        return {
            'success': True,
            'result': result,
        }

    except Exception as exc:
        logger.error("LLM transduction failed: %s", exc)
        return {
            'success': False,
            'error': str(exc),
        }


def _handle_text_to_schema(transducer: LLMTransducer, data: Dict[str, Any], logger) -> Dict[str, Any]:
    """Handle text to schema transduction."""
    text = data.get('text')
    schema = data.get('schema')
    options = data.get('options', {})

    if not text:
        raise ValueError("Missing 'text' in transduction data")

    logger.info("Transducing text to schema, text length: %d", len(text))

    # Use the transducer to process the request
    result = transducer.transduce_text_to_schema(text, schema, options)

    return result


def _handle_schema_to_text(transducer: LLMTransducer, data: Dict[str, Any], logger) -> Dict[str, Any]:
    """Handle schema to text transduction."""
    schema = data.get('schema')
    template = data.get('template')
    options = data.get('options', {})

    if not schema:
        raise ValueError("Missing 'schema' in transduction data")

    logger.info("Transducing schema to text, schema type: %s", type(schema).__name__)

    # Use the transducer to process the request
    result = transducer.transduce_schema_to_text(schema, template, options)

    return result


def _handle_text_to_tool_call(transducer: LLMTransducer, data: Dict[str, Any], logger) -> Dict[str, Any]:
    """Handle text to tool call transduction."""
    text = data.get('text')
    tools = data.get('tools')
    options = data.get('options', {})

    if not text:
        raise ValueError("Missing 'text' in transduction data")

    logger.info("Transducing text to tool call, text length: %d", len(text))

    # Use the transducer to process the request
    result = transducer.transduce_text_to_tool_call(text, tools, options)

    return result


def _handle_status(transducer: LLMTransducer, logger) -> Dict[str, Any]:
    """Handle status request."""
    logger.info("Getting LLM transducer status")

    # Get status from transducer
    status = transducer.get_status()

    return status


def create_llm_handlers() -> Dict[str, Any]:
    """
    Factory function to create LLM handlers following prototypal principles.
    
    Returns:
        Dictionary of handler methods for LLM operations
    """
    handlers = UvmObject()
    handlers['handle_llm_transducer'] = handle_llm_transducer
    return handlers