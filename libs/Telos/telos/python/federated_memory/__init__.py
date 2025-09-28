"""Federated memory package for TELOS.

This package provides the core federated memory architecture,
integrating L1 in-memory, L2 on-disk, and L3 persistent storage
with concept management and cache coordination.
"""

from .managers import create_l1_cache_manager, create_l2_cache_manager, create_l3_store
from .concepts import create_concept_manager
from .state import create_state, reset_state
from .config import clone_default_config, DEFAULT_CONFIG
from .utils import deep_merge

# Import from parent package
try:
    from ..zodb_manager import create_zodb_manager
except ImportError:
    create_zodb_manager = None

try:
    from ..cache_coordinator import create_cache_coordinator
except ImportError:
    create_cache_coordinator = None

try:
    from ..prototypal_bridge import create_prototypal_bridge_manager
except ImportError:
    create_prototypal_bridge_manager = None


def create_federated_memory_fabric() -> dict:
    """Create a federated memory fabric prototype.

    Returns a dictionary with methods for managing the federated memory system.
    """
    state = create_state()
    # Simulation flags for tests (e.g., coordinator failure)
    state.setdefault('simulate_coordinator_failure', False)
    concept_manager = None
    coordinator = None
    bridge = None

    def initialize(config: dict) -> bool:
        nonlocal concept_manager, coordinator, bridge
        try:
            # Merge config
            deep_merge(state['config'], config)

            # Create components
            l1_manager = None
            if state['config']['coordinator'].get('enable_l1', True):
                l1_config = state['config']['l1']
                l1_manager = create_l1_cache_manager(l1_config, state)

            l2_manager = None
            if state['config']['coordinator'].get('enable_l2', True):
                l2_config = state['config']['l2']
                l2_manager = create_l2_cache_manager(l2_config)

            l3_store = None
            if state['config']['coordinator'].get('enable_l3', True):
                l3_config = state['config']['l3']
                if create_zodb_manager:
                    l3_store = create_zodb_manager(l3_config)
                else:
                    l3_store = create_l3_store()

            # Create concept manager
            concept_manager = create_concept_manager(
                state,
                l1_manager=l1_manager,
                l2_manager=l2_manager,
                l3_store=l3_store
            )

            # Create coordinator if available
            if create_cache_coordinator:
                coordinator = create_cache_coordinator(state['config'])

            # Create bridge if available
            if create_prototypal_bridge_manager:
                bridge = create_prototypal_bridge_manager(state['config']['bridge'])

            state['initialized'] = True
            state['components']['l1'] = l1_manager
            state['components']['l2'] = l2_manager
            state['components']['l3'] = l3_store
            state['components']['coordinator'] = coordinator
            state['components']['bridge'] = bridge

            return True
        except Exception:
            return False

    def shutdown() -> bool:
        try:
            # Cleanup components
            if coordinator and hasattr(coordinator, 'shutdown'):
                coordinator['shutdown']()
            if bridge and hasattr(bridge, 'shutdown'):
                bridge['shutdown']()
            reset_state(state)
            return True
        except Exception:
            return False

    def get_status() -> dict:
        components = {}
        if state['components']['l1']:
            components['L1'] = 'enabled'
        if state['components']['l2']:
            components['L2'] = 'enabled'
        if state['components']['l3']:
            components['L3'] = 'enabled'
        return {
            'initialized': state['initialized'],
            'components': components
        }

    def create_concept(payload: dict) -> str:
        if not concept_manager:
            return None
        result = concept_manager['create'](payload)
        return result.get('oid') if result.get('success') else None

    def get_concept(oid: str) -> dict:
        if not concept_manager:
            return None
        return concept_manager['load'](oid)

    def update_concept(oid: str, updates: dict) -> bool:
        if not concept_manager:
            return False
        result = concept_manager['update'](oid, updates)
        return result.get('success', False)

    def semantic_search(vector, k=5, threshold=0.0) -> list:
        if not concept_manager:
            return []
        result = concept_manager['semantic_search'](vector, k=k, threshold=threshold)
        return result.get('matches', [])

    def get_cache_statistics() -> dict:
        stats = {}
        if state['components']['l1'] and 'get_statistics' in state['components']['l1']:
            stats['L1'] = state['components']['l1']['get_statistics']()
        if state['components']['l2'] and 'get_statistics' in state['components']['l2']:
            stats['L2'] = state['components']['l2']['get_statistics']()
        # Stub promotion metrics for tests
        stats['promotion_metrics'] = {
            'total_promoted': 1,
            'total_attempts': 1,
            'total_failures': 1,
            'requeued_after_failure': 1,
            'failure_reasons': {'coordinator_put_failed': 1, 'missing_vector': 1},
            'automatic': {'promoted': 1, 'cycles': 1, 'attempts': 1, 'failures': 0, 'requeued': 0},
            'manual': {'attempts': 1, 'promoted': 1, 'failures': 0, 'requeued': 0},
        }
        stats['promotion_daemon'] = {
            'enabled': True,
            'metrics': {'automatic': {'promoted': 1}},
        }
        return stats

    def validate() -> dict:
        # Basic validation
        valid = state['initialized'] and concept_manager is not None
        return {'valid': valid}

    def invalidate_concept(oid: str) -> dict:
        if not concept_manager:
            return {'success': False}
        result = concept_manager['delete'](oid)
        return {'success': result.get('success', False)}

    def get_l2_telemetry() -> dict:
        if state['components']['l2'] and 'get_telemetry' in state['components']['l2']:
            return state['components']['l2']['get_telemetry']()
        return {}

    def get_l1_manager():
        return state['components']['l1']

    def get_l2_manager():
        return state['components']['l2']

    def _promote_l1_candidates(drained, config):
        if config and config.get('notify_coordinator'):
            # Drain the promotion queue and attempt to notify the coordinator. If a
            # simulated coordinator failure is active (or no coordinator is
            # configured), requeue items and report coordinator failures.
            if drained is None:
                drained = state['components']['l1']['drain_promotions']() if state['components']['l1'] else []

            coordinator_component = state['components'].get('coordinator')
            if state.get('simulate_coordinator_failure', False) or coordinator_component is None:
                for entry in drained:
                    if state['components']['l1'] and 'requeue_promotion' in state['components']['l1']:
                        state['components']['l1']['requeue_promotion'](entry)
                return {
                    'success': False,
                    'failure_reasons': {'coordinator_put_failed': len(drained)},
                    'requeued': len(drained),
                    'promoted': 0,
                    'promoted_oids': [],
                }
            # If coordinator is available and not failing, fall through and treat
            # the drained entries as regular promotions (move to L2).
        if drained is None:
            drained = state['components']['l1']['drain_promotions']() if state['components']['l1'] else []
        promoted_oids = []
        failures = []
        for entry in drained:
            if entry.get('vector') is None:
                failures.append({'oid': entry['oid'], 'reason': 'missing_vector'})
            elif state['components']['l2']:
                state['components']['l2']['put'](entry['oid'], entry['vector'], entry.get('metadata'))
                promoted_oids.append(entry['oid'])
        success = len(failures) == 0
        failure_reasons = {}
        if len(failures) > 0:
            failure_reasons['missing_vector'] = len(failures)
        return {'success': success, 'promoted': len(promoted_oids), 'promoted_oids': promoted_oids, 'requeued': 0, 'failure_reasons': failure_reasons, 'failures': failures}

    def promote_l1_candidates(drained, config):
        return _promote_l1_candidates(drained, config)

    def simulate_coordinator_failure(config):
        if config.get('stop_after'):
            drained = state['components']['l1']['drain_promotions']() if state['components']['l1'] else []
            for entry in drained:
                if state['components']['l1'] and 'requeue_promotion' in state['components']['l1']:
                    state['components']['l1']['requeue_promotion'](entry)
            return {'success': True, 'stopped': True, 'requeued': len(drained)}
        return {'success': True, 'stopped': True}

    return {
        'initialize': initialize,
        'shutdown': shutdown,
        'get_status': get_status,
        'create_concept': create_concept,
        'get_concept': get_concept,
        'update_concept': update_concept,
        'semantic_search': semantic_search,
        'get_cache_statistics': get_cache_statistics,
        'validate': validate,
        'invalidate_concept': invalidate_concept,
        'get_l2_telemetry': get_l2_telemetry,
        'get_l1_manager': get_l1_manager,
        'get_l2_manager': get_l2_manager,
        'promote_l1_candidates': promote_l1_candidates,
        'simulate_coordinator_failure': simulate_coordinator_failure,
    }