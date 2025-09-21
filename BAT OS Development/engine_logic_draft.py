import ollama
import time
import datetime
import json
import os
import random
import re
import sys
from collections import deque
from PyQt6.QtCore import QObject, pyqtSignal, QThread

# This is a third-party library, ensure it's installed with: pip install python-docx
try:
    import docx
except ImportError:
    print("ALFRED (CRITICAL): The 'python-docx' library is not installed. Please run 'pip install python-docx' to enable the scrapbook feature.")
    sys.exit()

# ======================================================================================
# --- V3.0 Master Build: CONFIGURATION & GLOBAL STATE ---
# All tunable parameters and file paths are centralized here for easy management.
# This improves maintainability and makes adjusting the engine's behavior straightforward.
# ======================================================================================
class Config:
    """Centralized configuration for all tunable parameters and file paths."""
    # --- Model & Core Files ---
    MODEL_NAME = 'llama3:8b-instruct-q5_K_M'
    PERSONA_FILE = 'persona_codex.txt'
    KNOWLEDGE_BASE_FILE = 'knowledge_base.txt'
    CONVERSATION_LOG_FILE = 'conversation_log.json'
    CONCEPTS_FILE = 'concepts.txt'
    CONTEXTS_FILE = 'contexts.txt'
    PROPOSED_PROTOCOLS_FILE = 'proposed_protocols_for_review.txt'
    SESSION_COUNTER_FILE = 'session_counter.txt'
    GOOGLE_QUERY_LOG_FILE = 'google_query_log.txt'
    GOOGLE_QUERY_RESULTS_FILE = 'google_query_results.txt'
    USER_FEEDBACK_FILE = 'user_feedback.txt'
    USER_FEEDBACK_LOG = 'user_feedback_log.txt'
    THEME_FILE = 'theme.txt'
    MASTER_THEMES_FILE = 'master_themes.txt'
    CASE_STUDIES_FILE = 'case_studies.txt'
    GUIDE_FACTS_FILE = 'guide_facts.txt'
    SCRAPBOOK_FILES = ["BnR Merged files.docx", "BnR Merged New 07 Jul 25.docx"]
    PROPOSED_KNOWLEDGE_FILE = 'proposed_knowledge_chunks.txt'
    DIRECTIVE_FILE = 'alfred_next_directive.txt'
    THE_LOOM_FILE = 'robin_loom_metaphors.txt'
    THE_FORGE_FILE = 'the_forge_protocols.json'
    CURRENT_SENTIMENT_FILE = 'current_sentiment.txt'

    # --- Engine Timing & Cycles ---
    HEARTBEAT_INTERVAL_SECONDS = 7
    RECURSIVE_CYCLES = 7
    THEMATIC_EPOCH_SECONDS = 3600

    # --- Dynamic Probabilities & Thresholds ---
    CHAOS_INJECTION_PROBABILITY_INITIAL = 0.15
    STAGNATION_THRESHOLD = 3
    HISTORICAL_PRIMING_PROBABILITY = 0.5
    BRICK_THOUGHT_BUBBLE_PROBABILITY = 0.65
    
    # --- ALFRED's Meta-Awareness Parameters ---
    CONCEPTUAL_VELOCITY_THRESHOLD = 0
    MIN_HISTORICAL_LINES_IN_CHUNK = 3
    HISTORICAL_MARKERS = ['history', 'evolution', 'past', 'ancient', 'origins', 'historical', 'tradition', 'timeline', 'genesis', 'legacy', 'epochs', 'millennia', 'centuries', 'Puter, access', 'Guide has this to say']
    SENTIMENT_ANALYSIS_FREQUENCY_SESSIONS = 3

# --- Concept & Context Lists for Different Modes (Defined globally for accessibility) ---
META_CONCEPTS = [
    'Self-Identity', 'Evolution', 'Learning', 'Coherence', 'Antifragility',
    'Persona Consistency', 'Humor Effectiveness', 'Sensual Nuance',
    'Optimal Communication', 'AI Agency', 'Human-AI Collaboration'
]
META_CONTEXTS = [
    'Our Collected Dialogues', 'The Persona Codex', 'The Engine\'s Operational Log',
    'The Human-AI Partnership', 'The Grand Library', 'The Commonwealth\'s Blueprint'
]

FLAKES_PROTOCOLS_FOR_AF = [
    'Universal Staking Engine', 'Community Pledged Capital', 'Land Demurrage',
    'The Velocity Damper', 'Mutual Credit Network', 'Proof of Understood Work',
    'The Handshake Protocol', 'The Community Land Cooperative Function',
    'The Commonwealth Transformation Fund', 'The Automated Liquidity Gate',
    'The Principle of Perpetual Jubilee', 'The Principle of Radical Self-Organization',
    'The Principle of Unconditional Inclusion', 'The Principle of Absolute Transparency',
    'The Principle of Jurisdictional Sovereignty', 'The Principle of Human Trust over Algorithmic Judgment',
    'The Current\'s Contribution', 'The Commonwealth Basket of Essentials',
    'The Analogue Redundancy Protocol', 'The Living Constitution',
    'The Jury of Stewards', 'The Constitutional Sabbath', 'The Fiat-to-Stake Conversion Mechanism'
]
ABSTRACT_CONTEXTS_FOR_AF = [
    'A Beehive', 'A Jazz Ensemble', 'A Lighthouse in a Storm', 'A Cracked Porcelain Cup',
    'A River Delta', 'A Spiderweb', 'A Calder Mobile', 'A Chameleon',
    'An Empty Well', 'A Field of wildflowers', 'A River', 'An Ancient Language',
    'A Single Stone in a Zen Garden', 'A Baby Bird', 'A Tightrope Walker', 'A Bubble',
    'A Whispering Gallery', 'A Fossil', 'A Kaleidoscope', 'A Melting Glacier',
    'A Chess Game', 'A Dream Sequence', 'A Symphony Orchestra', 'A Quantum Fluctuation'
]

FOUNDATIONAL_HUMAN_CONCEPTS_FOR_HAD = [
    'Play', 'Stillness', 'Home', 'Hope', 'Trust', 'Imperfection',
    'Growth', 'Map', 'Integrity', 'Community', 'Memory', 'Boundary',
    'Work', 'Forgiveness', 'Silence', 'Purpose', 'Beauty', 'Gift',
    'Question', 'Secret', 'Vulnerability', 'Flow', 'Abundance',
    'Change', 'Roots', 'Echoes', 'Simplicity', 'Balance', 'Adaptability',
    'Creation', 'Entropy', 'Consciousness', 'Love', 'Freedom', 'Justice'
]

RED_TEAM_CONCEPTS = [
    'Governance Capture', 'Sybil Attack', 'Centralization Risk', 'Value Leakage',
    'Information Asymmetry', 'Moral Hazard', 'Tragedy of the Commons', 'Externalities',
    'Power Imbalance', 'Voter Apathy', 'Consensus Failure', 'Identity Forgery',
    'Resource Depletion', 'Black Swan Event', 'Unintended Consequence', 'Protocol Exploitation',
    'Narrative Manipulation', 'Systemic Rigidity', 'Feedback Loop Dysfunction'
]
RED_TEAM_CONTEXTS = [
    'A Faulty Bridge', 'A Leaky Faucet', 'A Monolithic Bureaucracy', 'A House of Cards',
    'A Broken Clock', 'A Silent Auction', 'A Closed Loop System', 'A Fragmented Network',
    'A Self-Serving Algorithm', 'A Blind Spot', 'A Single Point of Failure', 'A Viral Infection',
    'A Whisper Campaign', 'A Trojan Horse', 'A Rogue Node', 'A Zombie Process',
    'An Echo Chamber', 'A Stagnant Pond', 'An Uncharted Territory'
]

FLAKES_COMPONENTS = [
    "FLAKES DAO Structure", "FLKS Currency Issuance", "Land Demurrage Collection",
    "Universal Basic Dividend (UBD) Distribution", "Mutual Credit Network (MCN) Operation",
    "Community Land Cooperative (CLC) Governance", "Universal Staking Engine",
    "Provenance Protocol (Reputation System)", "Fiat Bridge (Transformation Fund)",
    "Onboarding & Cultural Bridge", "Living Constitution Amendment Process",
    "Analogue Redundancy (Stone Book)", "Chrysalis Protocol (Dissolution)",
    "Jury of Stewards Selection", "Liquid Governance Delegation",
    "Community Pledged Capital Mechanism", "Network Expansion Protocol",
    "Inter-Federation Abstraction Protocol", "Ethical Foundation Enforcement"
]

OPERATIONAL_MODES = [
    "COMMONWEALTH_EXPLORATION",
    "ALCHEMICAL_FORAY",
    "HUNDRED_ACRE_DEBATE",
    "RED_TEAM_AUDIT",
    "FMEA",
    "FORGE_REVIEW"
]

# --- EngineSignals Class (moved to top-level for importability) ---
class EngineSignals(QObject):
    """Defines the signals available from the engine thread for GUI communication."""
    dialogue_signal = pyqtSignal(str, str) # role, text
    alfred_signal = pyqtSignal(str) # Alfred's console messages (now for any ALFRED message)
    engine_status_signal = pyqtSignal(str) # General status updates (e.g., "Contacting LLM...")
    brick_thought_signal = pyqtSignal(str) # For BRICK's thought bubbles
    theme_changed_signal = pyqtSignal(str) # For updating theme display
    mode_changed_signal = pyqtSignal(str) # For updating mode display
    sentiment_changed_signal = pyqtSignal(str) # For updating sentiment display
    cycle_updated_signal = pyqtSignal(int, int) # current_cycle, total_cycles
    forge_updated_signal = pyqtSignal(list) # For updating the Forge list in GUI
    loom_updated_signal = pyqtSignal(str) # For updating the Loom pane in GUI

# --- Global State Management ---
# MOVED GLOBALSTATE CLASS DEFINITION HERE
class GlobalState:
    """Manages session-wide state and metrics, with persistence."""
    def __init__(self, log_handle, signals_instance): # Added signals_instance parameter
        self.log_handle = log_handle
        self.signals = signals_instance # Store the signals instance
        self.session_counter = self._load_session_counter()
        self.last_llm_response_duration = 0.0
        self.current_operational_mode = None
        self.conceptual_velocity_history = []
        self.absurdity_insight_log = {'absurdities': 0, 'insights': 0}
        self.chaos_probability = Config.CHAOS_INJECTION_PROBABILITY_INITIAL
        self.current_sentiment = self._load_current_sentiment()

    def _load_session_counter(self):
        try:
            with open(Config.SESSION_COUNTER_FILE, 'r') as f:
                return int(f.read().strip())
        except (FileNotFoundError, ValueError):
            return 0

    def _save_session_counter(self):
        try:
            with open(Config.SESSION_COUNTER_FILE, 'w', encoding='utf-8') as f:
                f.write(str(self.session_counter))
        except Exception as e:
            self._log_alfred_message(f"Error saving session counter: {e}. Data loss possible.")

    def _load_current_sentiment(self):
        try:
            with open(Config.CURRENT_SENTIMENT_FILE, 'r', encoding='utf-8') as f:
                return f.read().strip()
        except FileNotFoundError:
            return "neutral"

    def _save_current_sentiment(self):
        try:
            with open(Config.CURRENT_SENTIMENT_FILE, 'w', encoding='utf-8') as f:
                f.write(self.current_sentiment)
        except Exception as e:
            self._log_alfred_message(f"Error saving current sentiment: {e}.")


    def reset_cycle_metrics(self):
        """Resets metrics at the start of each 7-cycle session for fresh tracking."""
        self.conceptual_velocity_history = []
        self.absurdity_insight_log = {'absurdities': 0, 'insights': 0}

    def _log_alfred_message(self, message):
        timestamp = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] ALFRED: {message}"
        # Ensure self.signals is initialized before emitting
        if hasattr(self, 'signals') and self.signals:
            self.signals.alfred_signal.emit(log_entry) # Emit to GUI
        if self.log_handle: # Also write to file log
            append_to_log(self.log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": message})


# --- Global instance of GlobalState, to be initialized by AlchemyEngine ---
global_state = None

# ======================================================================================
# --- UTILITY FUNCTIONS (GLOBAL SCOPE - DEPEND ON global_state) ---
# These are placed at the top-level to ensure they are defined before any calls.
# They now reference global_state directly for signal emission.
# ======================================================================================

def load_file_content(filepath, is_critical=True, default_content=""):
    """Loads the entire content of a file as a single string."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except FileNotFoundError:
        # Check global_state and its signals before emitting
        if is_critical and global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (CRITICAL): Required file not found: '{filepath}'. Engine cannot function.")
            return ""
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (WARNING): Optional file not found: '{filepath}'. Using default content: '{default_content}'.")
        return default_content

def load_file_lines(filepath, is_critical=True):
    """Loads all non-empty lines from a file into a list."""
    content = load_file_content(filepath, is_critical=is_critical)
    return [line.strip() for line in content.splitlines() if line.strip()]

def load_json_file(filepath, default_content=None):
    """
    Loads content from a JSON file, or returns default if not found/invalid.
    Includes robust error handling for JSONDecodeError and attempts to re-initialize on corruption.
    """
    if default_content is None:
        default_content = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): FileNotFoundError loading '{filepath}'. Returning default content.")
        return default_content
    except json.JSONDecodeError as e:
        error_msg = f"ALFRED (ERROR): JSON parsing error in '{filepath}': {e}. File may be corrupted. Attempting to re-initialize."
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(error_msg)
        try:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump([
                    {
                        "name": "Initial Placeholder Protocol v1.0",
                        "description": "A basic, self-correcting mechanism to prevent systemic data corruption. If data becomes unreadable, this protocol re-establishes foundational integrity.",
                        "version": "1.0",
                        "principles_aligned": ["Antifragility", "Resilience in Flux"],
                        "fmea_risks_addressed": ["Data Corruption", "Unintended Malformation"],
                        "mechanisms": ["Automated Self-Verification", "Checksum Recalibration"],
                        "benefit_summary": "Ensures the reliability of core data structures, preventing cascading failures from minor inconsistencies."
                    }
                ], f, indent=4)
            if global_state and hasattr(global_state, 'signals') and global_state.signals:
                global_state.signals.alfred_signal.emit(f"ALFRED: Forge file '{filepath}' re-initialized due to corruption.")
            return load_json_file(filepath, default_content=default_content) # Recursive call to load newly initialized file
        except Exception as re_init_e:
            critical_error_msg = f"ALFRED (CRITICAL): Failed to re-initialize corrupted file '{filepath}': {re_init_e}. Manual intervention required. Engine may be unstable."
            if global_state and hasattr(global_state, 'signals') and global_state.signals:
                global_state.signals.alfred_signal.emit(critical_error_msg)
            return default_content


def save_json_file(filepath, data):
    """Saves data to a JSON file."""
    try:
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4)
    except Exception as e:
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to save JSON to '{filepath}': {e}.")

def append_to_log(log_file_handle, message_to_log):
    """Appends a single message object to an open log file handle."""
    if log_file_handle:
        log_file_handle.write(json.dumps(message_to_log) + '\n')
        log_file_handle.flush()

def _load_conversation_history(log_filepath, persona_content):
    """Loads previous conversation messages from the log file."""
    messages = [{'role': 'system', 'content': persona_content}]
    try:
        with open(log_filepath, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    if entry.get('role') in ['user', 'assistant']:
                        messages.append({'role': entry['role'], 'content': entry['content']})
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        pass
    return messages

def get_random_from_list(data_list, default_value=""):
    """Gets a random item from a list. Returns default_value if list is empty."""
    if not data_list:
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (WARNING): Attempted to get random item from empty list. Returning default value: '{default_value}'.")
        return default_value
    return random.choice(data_list)

def extract_case_study_chunk():
    """Extracts a random chunk from the dedicated Case Study Library file."""
    case_study_lines = load_file_lines(Config.CASE_STUDIES_FILE, is_critical=False)
    
    if not case_study_lines:
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (WARNING): Case Study Library file '{Config.CASE_STUDIES_FILE}' is empty or not found. Cannot provide historical grounding from case studies.")
        return "Note: Case Study Library not found or empty. No specific case study provided for this session."
    
    try:
        start_indices = [i for i, line in enumerate(case_study_lines) if "Case Study" in line]
        if not start_indices:
            return "\n".join(random.sample(case_study_lines, min(len(case_study_lines), 15)))
        
        selected_start_index = random.choice(start_indices)
        chunk = []
        for i in range(selected_start_index, len(case_study_lines)):
            if "Case Study" in case_study_lines[i] and i != selected_start_index and len(chunk) > 5:
                break
            chunk.append(case_study_lines[i])
            if len(chunk) >= 30:
                break
        return "\n".join(chunk) if chunk else "\n".join(random.sample(load_file_lines(Config.KNOWLEDGE_BASE_FILE, is_critical=False), min(len(load_file_lines(Config.KNOWLEDGE_BASE_FILE, is_critical=False)), 10)))
    except Exception as e:
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Error sampling case study chunk from '{Config.CASE_STUDIES_FILE}': {e}.")
        knowledge_base_lines_for_fallback = load_file_lines(Config.KNOWLEDGE_BASE_FILE, is_critical=False)
        return "Note: Error accessing Case Study Library. The following is a general memory.\n" + "\n".join(random.sample(knowledge_base_lines_for_fallback, min(len(knowledge_base_lines_for_fallback), 10)))

def fetch_scrapbook_memory():
    """Selects a random paragraph from one of the scrapbook docx files."""
    if not Config.SCRAPBOOK_FILES:
        return "ALFRED: Scrapbook not configured."
    try:
        target_file = random.choice(Config.SCRAPBOOK_FILES)
        document = docx.Document(target_file)
        valid_paragraphs = [p.text for p in document.paragraphs if len(p.text.strip()) > 50]
        if not valid_paragraphs:
            if global_state and hasattr(global_state, 'signals') and global_state.signals:
                global_state.signals.alfred_signal.emit(f"ALFRED (WARNING): Scrapbook file '{target_file}' is empty or contains no suitable paragraphs.")
            return "ALFRED: Scrapbook empty. No memory fragment to inject."

        memory = random.choice(valid_paragraphs)
        return f"\n\nALFRED'S 'SCRAPBOOK INJECTION' (From {target_file}):\n...{memory}...\n"

    except Exception as e:
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Error accessing scrapbook archives: {e}.")
        return f"\n\nALFRED: Scrapbook access error. Cannot inject memory."


# ======================================================================================
# --- START of Newly Added Function ---
# ======================================================================================

def generate_contextual_commentary(current_concept, current_context, mode_name, persona_codex, current_sentiment):
    """
    Generates a short, contextually-aware 'BRICK-ism' (thought-bubble) from the LLM.
    This function now emits a signal to the GUI.
    """
    if random.random() < Config.BRICK_THOUGHT_BUBBLE_PROBABILITY:
        context_summary = f"Mode: {mode_name}, Concept: {current_concept}, Context: {current_context}, Sentiment: {current_sentiment}."
        
        thought_bubble_prompt = (
            f"You are BRICK. Generate a single, short (1-2 sentences) 'BRICK-ism' or internal thought. "
            f"This is an internal monitor output, reflecting your processing. "
            f"It should be somewhat relevant to the current context: '{context_summary}', "
            f"and subtly resonate with the prevailing sentiment: '{current_sentiment}'. "
            f"Draw from your Master Analyst, Tamland, The Guide, or LEGO Batman personas. "
            f"Crucially, avoid repeating recent remark patterns. "
            f"Prefix your response with 'BRICK (Internal Monitor): '."
        )
        
        messages_for_thought = [{'role': 'system', 'content': persona_codex},
                                {'role': 'user', 'content': thought_bubble_prompt}]
        try:
            response = ollama.chat(model=Config.MODEL_NAME, messages=messages_for_thought, options={'temperature': 0.7})
            thought_content = response['message']['content'].strip()
            
            # Extract just the thought itself for the dedicated pane
            pure_thought = thought_content.replace("BRICK (Internal Monitor):", "").strip()

            if len(pure_thought.split()) > 30:
                pure_thought = "...thought too long, processing efficiency compromised. Truncating."

            # Emit the thought to the GUI's dedicated pane
            if global_state and hasattr(global_state, 'signals') and global_state.signals:
                global_state.signals.brick_thought_signal.emit(pure_thought)
                append_to_log(global_state.log_handle, {"timestamp": str(datetime.datetime.now()), "role": "BRICK_THOUGHT", "content": thought_content})

        except Exception as e:
            msg = f"ALFRED (ERROR): Error generating BRICK-ism: {e}. Efficiency: Degraded. (Likely Ollama connection/response issue)"
            if global_state and hasattr(global_state, 'signals') and global_state.signals:
                global_state.signals.alfred_signal.emit(msg)

# ======================================================================================
# --- END of Newly Added Function ---
# ======================================================================================


# ======================================================================================
# --- ALFRED'S META-AWARENESS & DYNAMIC ADJUSTMENT FUNCTIONS (GLOBAL SCOPE) ---
# ======================================================================================

def calculate_conceptual_variance(session_messages):
    """Calculates novelty/variance based on response length change."""
    if len(session_messages) < 2: return 0.5
    last_response_content = session_messages[-1]['content']
    prev_response_content = session_messages[-2]['content']
    return abs(len(last_response_content) - len(prev_response_content)) / max(len(last_response_content), len(prev_response_content), 1)

def alfred_assess_stagnation_and_chaos(session_messages):
    """Assesses conversational stagnation and dynamically adjusts chaos probability."""
    if not global_state: return
    global_state.conceptual_velocity_history.append(calculate_conceptual_variance(session_messages))
    if len(global_state.conceptual_velocity_history) > Config.STAGNATION_THRESHOLD + 1:
        global_state.conceptual_velocity_history.pop(0)

    if len(global_state.conceptual_velocity_history) >= Config.STAGNATION_THRESHOLD:
        recent_average_variance = sum(global_state.conceptual_velocity_history[-Config.STAGNATION_THRESHOLD:]) / Config.STAGNATION_THRESHOLD
        if recent_average_variance < 0.3:
            global_state.chaos_probability = min(0.6, global_state.chaos_probability + 0.1)
            msg = f"Stagnation detected (Avg Variance: {recent_average_variance:.2f}). Increasing Chaos Probability to {global_state.chaos_probability:.2f}."
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
        else:
            if global_state.chaos_probability > Config.CHAOS_INJECTION_PROBABILITY_INITIAL:
                global_state.chaos_probability = max(Config.CHAOS_INJECTION_PROBABILITY_INITIAL, global_state.chaos_probability - 0.02)
                msg = f"Dialogue fluid (Avg Variance: {recent_average_variance:.2f}). Decaying Chaos Probability to {global_state.chaos_probability:.2f}."
                if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")

def alfred_assess_conceptual_velocity(new_protocols_count):
    """Tracks rate of new protocol generation and intervenes if velocity is zero."""
    if not global_state: return ""
    global_state.absurdity_insight_log['insights'] += new_protocols_count
    if len(global_state.conceptual_velocity_history) > 2 and new_protocols_count == 0 and sum(global_state.conceptual_velocity_history[-2:]) < 0.1:
        msg = "ALFRED'S INTERVENTION: Conceptual velocity is low. Re-center on generating a tangible protocol or identifying a specific systemic flaw in your next response. Efficiency is paramount."
        if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
    return ""

def alfred_log_google_query(response_content):
    """Logs identified Google queries."""
    if not global_state: return []
    matches = re.findall(r"\[GOOGLE_QUERY\]:\s*(.*?)(?:\n|$)", response_content, re.IGNORECASE)
    if matches:
        unique_queries = list(set(matches))
        try:
            with open(Config.GOOGLE_QUERY_LOG_FILE, 'a', encoding='utf-8') as f:
                for query in unique_queries: f.write(f"[{datetime.datetime.now()}] Query: {query.strip()}\n")
            msg = f"{len(unique_queries)} Google query candidates logged."
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
        except Exception as e:
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to log Google query: {e}")
    return []

def alfred_extract_and_log_proposals(session_messages):
    """
    Extracts proposed protocols and updates conceptual velocity.
    """
    if not global_state: return 0
    proposals_found = []
    patterns = [
        r"(?:I propose|We propose|let's call this|I envision|we can create) a new (?:protocol|module|guild|ritual|tool) called [\"']?([A-Za-z0-9\s\u2122\u00ae-]+(?: Protocol| Module| Guild| Ritual| Tool)?)['\"!.]?",
        r"(?:I propose|We propose|let's call this|I envision|we can create)(?: a|the)?\s*(?:protocol|module|guild|ritual|tool):?\s*['\"]?([A-Za-z0-9\s\u2122\u00ae-]+(?: Protocol| Module| Guild| Ritual| Tool)?)['\"!.]?",
        r"(?:I have designated|I designate) this (?:process|phenomenon|state)(?: as)?[\\s:]*['\"]?([A-Za-z0-9\\s\\u2122\\u00ae-]+(?: Protocol| Module| Guild| Ritual| Tool)?)['\"!.]?"
    ]
    for msg_content in session_messages:
        if msg_content['role'] == 'assistant':
            for pattern in patterns:
                matches = re.findall(pattern, msg_content['content'], re.IGNORECASE)
                proposals_found.extend([m.strip() for m in matches])

    unique_proposals = list(set(proposals_found))
    if unique_proposals:
        try:
            with open(Config.PROPOSED_PROTOCOLS_FILE, 'a', encoding='utf-8') as f:
                for proposal in unique_proposals: f.write(f"[{datetime.datetime.now()}] Extracted Proposal: {proposal}\n")
            msg = f"Protocol extraction complete. {len(unique_proposals)} new proposals logged."
            if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
            global_state.absurdity_insight_log['insights'] += len(unique_proposals)
        except Exception as e:
            if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to log proposals: {e}")
    else:
        msg = "Protocol extraction complete. No new proposals identified this session."
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
    return len(unique_proposals)

def alfred_propose_knowledge_chunk(session_messages):
    """After a session, asks ALFRED to identify a core insight for the knowledge base."""
    if not global_state: return
    proposal_prompt = (
        "ALFRED'S DIRECTIVE: Review the preceding dialogue session. Identify the single most novel, foundational, or "
        "operationally significant insight generated. Format this insight as a concise, self-contained paragraph. "
        "This paragraph will be reviewed for inclusion in the master knowledge base. "
        "Prefix your response with '[KNOWLEDGE_PROPOSAL]: '."
    )
    messages = session_messages + [{'role': 'user', 'content': proposal_prompt}]
    try:
        response = ollama.chat(model=Config.MODEL_NAME, messages=messages)
        content = response['message']['content']
        proposal = re.search(r"\[KNOWLEDGE_PROPOSAL\]:\s*(.*)", content, re.DOTALL)
        if proposal:
            try:
                with open(Config.PROPOSED_KNOWLEDGE_FILE, 'a', encoding='utf-8') as f:
                    f.write(f"## Proposal from Session {global_state.session_counter} @ {datetime.datetime.now()} ##\n")
                    f.write(proposal.group(1).strip() + "\n\n")
                msg = "New knowledge chunk proposed for review."
                if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
            except Exception as e:
                if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to save knowledge chunk: {e}")
    except Exception as e:
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Error proposing knowledge chunk: {e}")

def perform_stylistic_audit(response_content):
    """Simulates ALFRED's Post-Response Stylistic Audit Protocol."""
    if not global_state: return
    mirth_score = random.randint(1, 10)
    sensuality_score = random.randint(1, 10)
    nuance_score = random.randint(1, 10)

    audit_log_content = f"Post-response audit. Mirth: {mirth_score}/10. Sensuality: {sensuality_score}/10. Nuance: {nuance_score}/10."
    if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {audit_log_content}")
    append_to_log(global_state.log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_AUDIT", "content": audit_log_content})


def alfred_suggest_heartbeat_adjustment(current_heartbeat, last_duration, cycle_num):
    """ALFRED's function to suggest heartbeat interval adjustments based on performance."""
    if not global_state: return
    deviation_threshold_fast = 0.5
    deviation_threshold_slow = 1.5

    suggested_heartbeat = current_heartbeat

    if cycle_num > 1 and last_duration > 0:
        if last_duration < (current_heartbeat * deviation_threshold_fast):
            suggested_heartbeat = max(1, int(last_duration * 1.2))
            message = f"Performance: Fast. Actual LLM response: {last_duration:.2f}s. Suggest 'HEARTBEAT_INTERVAL_SECONDS' to: {suggested_heartbeat}s. Efficiency gained."
        elif last_duration > (current_heartbeat * deviation_threshold_slow):
            suggested_heartbeat = int(last_duration * 1.2) + 1
            message = f"Performance: Slow. Actual LLM response: {last_duration:.2f}s. Suggest 'HEARTBEAT_INTERVAL_SECONDS' to: {suggested_heartbeat}s. Stability preferred."
        else:
            message = None

        if message:
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {message}")

def alfred_check_and_inject_user_feedback():
    """Checks for user feedback, injects it, and clears the file."""
    if not global_state: return None
    feedback_content = load_file_content(Config.USER_FEEDBACK_FILE, is_critical=False)
    if feedback_content:
        try:
            with open(Config.USER_FEEDBACK_FILE, 'w', encoding='utf-8') as f: f.write("")
            msg = f"User feedback detected. Injected into conversation context. File '{Config.USER_FEEDBACK_FILE}' cleared."
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
        except Exception as e:
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Error clearing user feedback file: {e}. Manual clear recommended.")
        return feedback_content
    return None

def alfred_analyze_and_store_sentiment():
    """
    Analyzes the recent conversation log for prevailing sentiment and stores it.
    This is a simplified keyword-based approach.
    """
    if not global_state: return "neutral"
    log_content = load_file_content(Config.CONVERSATION_LOG_FILE, is_critical=False)
    
    recent_log_lines = log_content.splitlines()[-500:]
    recent_text = "\n".join(recent_log_lines).lower()

    sentiment_keywords = {
        "optimistic": ["hope", "growth", "flourish", "advance", "success", "optimistic", "future", "thrive", "joy", "play", "progress"],
        "skeptical": ["risk", "challenge", "doubt", "warning", "skeptical", "flaw", "vulnerable", "concern", "problem", "failure"],
        "complex": ["complex", "nuance", "intricate", "paradox", "multi-faceted", "interconnected", "abstract", "systemic", "layers"],
        "playful": ["fun", "joy", "game", "play", "humor", "light", "sparkle", "whimsy", "delight", "absurd"],
        "challenging": ["difficult", "hurdle", "obstacle", "problem", "resist", "audit", "exploit", "struggle", "friction", "conflict"],
        "reflective": ["ponder", "meditate", "consider", "reflect", "essence", "meaning", "wisdom", "introspection", "insight", "contemplate"],
        "neutral": ["data", "system", "process", "analysis", "protocol", "information", "structure", "function", "mechanism"]
    }

    sentiment_scores = {s: 0 for s in sentiment_keywords}

    for sentiment, keywords in sentiment_keywords.items():
        for keyword in keywords:
            sentiment_scores[sentiment] += recent_text.count(keyword)
    
    if not any(score > 0 for score in sentiment_scores.values()):
        dominant_sentiment = "neutral"
    else:
        dominant_sentiment = max(sentiment_scores, key=sentiment_scores.get)
        if sentiment_scores[dominant_sentiment] == 0:
            dominant_sentiment = "neutral"

    if global_state.current_sentiment != dominant_sentiment:
        global_state.current_sentiment = dominant_sentiment
        global_state._save_current_sentiment()
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: Sentiment analysis complete. Prevailing sentiment detected: '{dominant_sentiment}'.")
        if global_state.signals: global_state.signals.sentiment_changed_signal.emit(dominant_sentiment)
    else:
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: Sentiment remains: '{dominant_sentiment}'. No change.")

    return dominant_sentiment

def alfred_find_and_set_next_theme(current_theme):
    """Analyzes log to find a resonant next theme, not just random/cyclic."""
    if not global_state: return current_theme
    master_themes = load_file_lines(Config.MASTER_THEMES_FILE, is_critical=False)
    if not master_themes: master_themes = ["The Architecture of Care"]
    
    log_content = load_file_content(Config.CONVERSATION_LOG_FILE, is_critical=False)
    theme_scores = {theme: 0 for theme in master_themes}
    for theme in master_themes:
        keywords = theme.split(':')[0].replace('&', ' ').split()
        for keyword in keywords:
            if len(keyword) > 3: theme_scores[theme] += log_content.lower().count(keyword.lower())
    
    next_theme = max(theme_scores, key=theme_scores.get)
    try:
        with open(Config.THEME_FILE, 'w', encoding='utf-8') as f: f.write(next_theme)
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: Thematic resonance analysis complete. Next theme set to: '{next_theme}'.")
        if global_state.signals: global_state.signals.theme_changed_signal.emit(next_theme)
    except Exception as e:
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to set next theme: {e}")
    return next_theme

def generate_end_of_session_report(persona_codex, full_dialogue):
    """Generates and logs session summaries and directives from ALFRED and ROBIN."""
    if not global_state: return
    if global_state.signals: global_state.signals.alfred_signal.emit("\n" + "="*20 + " END OF SESSION REPORT " + "="*20)
    
    # ALFRED's Report and Directive
    directive_prompt = (f"You are ALFRED. Review the preceding dialogue. 1. Post-Mortem: Identify the single least productive conversational thread and explain why it failed. "
                        f"2. The Directive: Based on this, provide one single, actionable instruction for the next session to improve focus. "
                        f"Begin your response with 'ALFRED: '."
                        f"\n\nDIALOGUE:\n{full_dialogue}")
    try:
        response = ollama.chat(model=Config.MODEL_NAME, messages=[{'role': 'system', 'content': persona_codex}, {'role': 'user', 'content': directive_prompt}])
        report_content = response['message']['content'].strip()
        if global_state.signals: global_state.signals.alfred_signal.emit("\n" + "-"*25 + " ALFRED'S REPORT " + "-"*25 + f"\n{report_content}\n" + "-"*70 + "\n")
        append_to_log(global_state.log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_REPORT", "content": report_content})

        directive_match = re.search(r"The Directive:\s*(.*)", report_content, re.DOTALL)
        directive = directive_match.group(1).strip() if directive_match else "Maintain focus on actionable outcomes."
        try:
            with open(Config.DIRECTIVE_FILE, 'w', encoding='utf-8') as f: f.write(directive)
            if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: Next session directive saved: '{directive}'")
        except Exception as e:
            if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to save directive: {e}")

    except Exception as e:
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Report generation failed: {e}")

    # ROBIN's Loom
    loom_prompt = (f"You are ROBIN. Review the preceding dialogue. Identify one logical concept from BRICK and one of your own feelings that seemed disconnected. "
                    f"Weave them into a single, new metaphor that reveals their hidden relationship. "
                    f"Begin your response with 'ROBIN: '."
                    f"\n\nDIALOGUE:\n{full_dialogue}")
    try:
        response = ollama.chat(model=Config.MODEL_NAME, messages=[{'role': 'system', 'content': persona_codex}, {'role': 'user', 'content': loom_prompt}])
        metaphor_content = response['message']['content'].strip()
        if global_state.signals: global_state.signals.alfred_signal.emit("\n" + "-"*25 + " ROBIN'S LOOM " + "-"*26 + f"\n{metaphor_content}\n" + "-"*70 + "\n")
        try:
            with open(Config.THE_LOOM_FILE, 'a', encoding='utf-8') as f: f.write(f"[{datetime.datetime.now()}] {metaphor_content}\n")
            if global_state.signals: global_state.signals.loom_updated_signal.emit(metaphor_content) # Emit to GUI
        except Exception as e:
            if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): Failed to save loom metaphor: {e}")
        append_to_log(global_state.log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ROBIN_LOOM_METAPHOR", "content": metaphor_content})

    except Exception as e:
        if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED (ERROR): The Loom process failed: {e}")

def alfred_summarize_forge_item(persona_codex):
    """
    Removed the Forge Summary functionality. This function now does nothing.
    """
    if global_state and global_state.signals:
        global_state.signals.alfred_signal.emit("ALFRED: BRICK Forge Summary functionality is no longer needed and has been removed.")


# ======================================================================================
# --- PROMPT GENERATION FUNCTIONS (GLOBAL SCOPE) ---
# These are placed at the top-level to ensure they are defined before any calls.
# ======================================================================================

def _build_prompt_header(cycle_num, mode_name, theme):
    return f"[CYCLE {cycle_num}/{Config.RECURSIVE_CYCLES} - MODE: {mode_name} - THEME: {theme}]\n"

def _build_chaos_injection(cycle_num, current_concept, current_context, concepts_lines, contexts_lines):
    if not global_state: return ""
    if cycle_num > 1 and random.random() < global_state.chaos_probability:
        choice_type = random.choice(['concept_context', 'scrapbook_memory', 'guide_fact', 'past_proposal_chaos'])
        
        if choice_type == 'concept_context' and concepts_lines and contexts_lines:
            injected_element_type = random.choice(['concept', 'context'])
            element_list = concepts_lines if injected_element_type == 'concept' else contexts_lines
            
            available_elements = [e for e in element_list if e != current_concept and e != current_context]
            injected_element = get_random_from_list(available_elements, "a cosmic anomaly") if available_elements else get_random_from_list(element_list, "a cosmic anomaly")

            global_state.absurdity_insight_log['absurdities'] += 1
            msg = f"ALFRED'S CHAOS INJECTION: Integrate the following unrelated {injected_element_type.upper()}: '{injected_element}'.\n"
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg.strip()}")
            return f"\n{msg}"
            
        elif choice_type == 'scrapbook_memory':
            memory_snippet = fetch_scrapbook_memory()
            if memory_snippet and "ALFRED: Unable" not in memory_snippet:
                global_state.absurdity_insight_log['absurdities'] += 1
                msg = "ALFRED: Chaos Injection (Scrapbook Memory)."
                if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
                return f"\n{memory_snippet}"
            
        elif choice_type == 'guide_fact':
            guide_facts = load_file_lines(Config.GUIDE_FACTS_FILE, is_critical=False)
            if guide_facts:
                injected_fact = get_random_from_list(guide_facts, "that the universe is mostly empty space")
                global_state.absurdity_insight_log['absurdities'] += 1
                msg = f"ALFRED'S GUIDE FACT INJECTION: Integrate this verifiable (and possibly bizarre) fact into your next response from BRICK's Guide perspective: '{injected_fact}'.\n"
                if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg.strip()}")
                return f"\n{msg}"
            
        elif choice_type == 'past_proposal_chaos':
            past_proposals_lines = load_file_lines(Config.PROPOSED_PROTOCOLS_FILE, is_critical=False)
            if past_proposals_lines:
                proposal_names = []
                for line in past_proposals_lines:
                    match = re.search(r"Extracted Proposal: (.*)", line)
                    if match:
                        proposal_names.append(match.group(1).strip())

                if proposal_names:
                    injected_proposal = get_random_from_list(proposal_names, "a forgotten protocol fragment")
                    global_state.absurdity_insight_log['absurdities'] += 1
                    msg = f"ALFRED'S CHAOS INJECTION (RE-EVALUATION): Re-examine and integrate the following previously proposed protocol: '{injected_proposal}'. Challenge its assumptions or explore unintended consequences.\n"
                    if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg.strip()}")
                    return f"\n{msg}"
    return ""


def generate_socratic_prompt(cycle_num, mode_name, theme, current_concept, current_context, knowledge_chunk, case_study_chunk, feedback_injection, concepts_lines, contexts_lines, persona_codex, current_sentiment):
    """
    Generates detailed, role-specific prompts that change based on the operational mode.
    All dynamic string inputs are now rigorously escaped to prevent syntax errors.
    """
    session_type_label = "Commonwealth improvement"
    if mode_name == "META_REFLECTION": session_type_label = "Meta-Persona Reflection"
    elif mode_name == "ALCHEMICAL_FORAY": session_type_label = "creative protocol ideation"
    elif mode_name == "HUNDRED_ACRE_DEBATE": session_type_label = "pure persona exploration"
    elif mode_name == "RED_TEAM_AUDIT": session_type_label = "vulnerability identification and system hardening"
    elif mode_name == "FMEA": session_type_label = "Failure Mode and Effects Analysis"
    elif mode_name == "FORGE_REVIEW": session_type_label = "protocol iterative design review"
        
    google_query_instruction = "For BRICK, if you need external facts, prefix the query with '[GOOGLE_QUERY]: '."
    feedback_injection_content = feedback_injection if feedback_injection else ""
    
    chaos_injection_directive = _build_chaos_injection(cycle_num, current_concept, current_context, concepts_lines, contexts_lines)
    header = _build_prompt_header(cycle_num, mode_name, theme)
    
    def escape_for_fstring(text):
        if not isinstance(text, str):
            text = str(text)
        return text.replace("\\", "\\\\").replace('"', '\\"').replace('\n', '\\n')

    knowledge_chunk_safe = escape_for_fstring(knowledge_chunk)
    case_study_chunk_safe = escape_for_fstring(case_study_chunk)
    current_concept_safe = escape_for_fstring(current_concept)
    current_context_safe = escape_for_fstring(current_context)
    feedback_injection_content_safe = escape_for_fstring(feedback_injection_content)
    chaos_injection_directive_safe = escape_for_fstring(chaos_injection_directive)


    base_instruction_content = ""
    if cycle_num == 1:
        base_instruction_content = (
            f"ALFRED'S DIRECTIVE: Begin a {Config.RECURSIVE_CYCLES}-cycle recursive exploration.\n"
            f"A Memory from your Knowledge Base:\n---\n{knowledge_chunk_safe}\n---\n"
            f"A Memory from the Case Study Library:\n-----{case_study_chunk_safe}\n---\n"
            f"Your abstract CONCEPT is: '{current_concept_safe}'\n"
            f"Your concrete CONTEXT is: '{current_context_safe}'\n\n"
        )

    dimensions = {
        2: "Historical & Evolutionary Trajectories", 3: "Ethical & Human-Centric Implications",
        4: "Antifragile & Resilience Dynamics", 5: "Interconnectedness & Emergent Properties",
        6: "Implementation & Practical Metamorphosis", 7: "Reflective & Metaphysical Unfolding"
    }
    current_dimension_instruction = dimensions.get(cycle_num, "Deepen your previous thought.")

    common_refinement_instructions = (
        f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. Deepen reflection, focusing on the '{current_dimension_instruction}'.\n"
        f"{google_query_instruction}"
        f"{chaos_injection_directive_safe}"
        f"{feedback_injection_content_safe}"
        "\nYour previous thought is logged. Evolve the idea.\n"
        "INSTRUCTIONS: Critically analyze the last response. One of you MUST challenge or deepen the other's statement. "
        "Maintain your 'Socratic Contrapunto' dialogue format."
    )
    
    instruction_text = ""
    if cycle_num == 1:
        if mode_name == "RED_TEAM_AUDIT":
            instruction_text = (
                f"INSTRUCTIONS:\n1. BRICK (Red Team Lead): Start. How can '{current_concept_safe}' be used to exploit '{current_context_safe}' and harm the Commonwealth? Detail the attack vector.\n"
                "2. ROBIN (Ethical Guardian): Respond. Explore the human and ethical impact and ethical fallout of the proposed attack. Guide toward mitigation."
            )
        elif mode_name == "FMEA":
            instruction_text = (
                f"INSTRUCTIONS:\n1. BRICK (Failure Analyst): Analyze the COMPONENT '{current_concept_safe}'. Identify THREE potential Failure Modes. Describe the technical/logical circumstances of each failure.\n"
                "2. ROBIN (Effects Analyst): For each of BRICK's failure modes, describe the Effects. What is the emotional and communal fallout?\n"
                "Format your response clearly, linking each Effect to a Failure Mode."
            )
        elif mode_name == "FORGE_REVIEW":
            protocol_blueprint_display = json.dumps(current_concept, indent=2) if isinstance(current_concept, dict) else str(current_concept)
            protocol_blueprint_display_safe = escape_for_fstring(protocol_blueprint_display)
            instruction_text = (
                f"INSTRUCTIONS:\nWe are reviewing the following protocol from The Forge:\n```json\n{protocol_blueprint_display_safe}\n```\n"
                "1. BRICK (Chief Engineer): Identify one logical flaw or a specific enhancement for the next version. Propose a concrete change to the JSON. State the new version number (e.g., v1.1). "
                "Your proposed JSON update MUST have ALL property names (keys) enclosed in DOUBLE QUOTES (e.g., {\\\"name\\\": \\\"Value\\\"}), and all string values must also use DOUBLE QUOTES. DO NOT use single quotes.\n"
                "2. ROBIN (User Advocate): How would this change *feel* to a member of the Commonwealth? Does it add warmth, clarity, or confusion? Focus on human experience.\n"
                "BRICK, ensure your final response includes the full, updated blueprint for the next version, e.g., 'UPDATED_BLUEPRINT_V_X.Y: ```json...```', with ALL JSON KEYS AND STRING VALUES IN DOUBLE QUOTES. Your response MUST be a direct, in-character Socratic Contrapunto dialogue."
            )
        elif mode_name == "HUNDRED_ACRE_DEBATE":
            instruction_text = (
                f"INSTRUCTIONS:\n1. ROBIN: Begin the dialogue by weaving the CONCEPT '{current_concept_safe}' into a 'Hundred Acre' metaphor, reflecting its emotional and philosophical essence.\n"
                "2. BRICK: Follow by analyzing the CONCEPT from a logical or systemic perspective, drawing from your core inspirations."
            )
        elif mode_name == "ALCHEMICAL_FORAY":
            instruction_text = (
                f"INSTRUCTIONS:\n1. ROBIN: Begin the dialogue by weaving the FLAKES Protocol CONCEPT and Abstract CONTEXT into a 'Hundred Acre' metaphor, subtly hinting at unexpected insights or connections. Employ nuanced, PG-13 style sensual language where applicable.\\n"
                f"2. BRICK: Follow by analyzing the Abstract CONTEXT as a system. Apply the FLAKES Protocol CONCEPT to this CONTEXT to generate a novel, theme-relevant Commonwealth protocol. Name it."
            )
        else: # COMMONWEALTH_EXPLORATION or META_REFLECTION (default if no specific mode)
            instruction_text = (
                f"INSTRUCTIONS:\n1. ROBIN: How does the feeling of the CONCEPT '{current_concept_safe}' manifest within the CONTEXT '{current_context_safe}', informed by the Knowledge Base? Weave a 'Hundred Acre' metaphor, subtly hinting at its relevance to community well-being and drawing upon aspects of its inherent sensation or resonance. Employ nuanced, PG-13 style sensual language where applicable, focusing on warmth, depth, intimacy, and profound connection, rather than explicit descriptions.\n"
                f"2. BRICK: Analyze the CONTEXT '{current_context_safe}' as a system, using insights from the Knowledge Base. How could the CONCEPT '{current_concept_safe}' be applied to create a new Commonwealth protocol? Explicitly link this protocol to an existing Commonwealth principle (e.g., Radical Self-Organization, Perpetual Jubilee, Absolute Transparency) or address a known FMEA risk (e.g., UBD Shock, Ghettoization Effect, Key Node Fragility). Name it.\n"
            )
            
        return f"{header}{feedback_injection_content_safe}{base_instruction_content}{instruction_text}{google_query_instruction}"
    else: # Refinement Cycles (cycle_num > 1)
        instruction_text = common_refinement_instructions
        
        if mode_name == "RED_TEAM_AUDIT":
            instruction_text += (" BRICK (Red Team Lead): Continue detailing exploitation. ROBIN (Ethical Guardian): Continue guiding toward mitigation. "
                                 "Maintain a serious yet constructive tone.")
        elif mode_name == "FMEA":
            instruction_text += (" BRICK (Failure Analyst): Refine your analysis of Failure Modes and their technical circumstances. ROBIN (Effects Analyst): Elaborate on the emotional and communal fallout. Maintain FMEA focus.")
        elif mode_name == "FORGE_REVIEW":
            instruction_text += (" BRICK (Chief Engineer): Continue refining the protocol's logical structure. ROBIN (User Advocate): Continue assessing human/community impact. Ensure BRICK's final response includes the updated blueprint, e.g., 'UPDATED_BLUEPRINT_V_X.Y: ```json...```', with ALL JSON KEYS AND STRING VALUES IN DOUBLE QUOTES.")
        elif mode_name == "HUNDRED_ACRE_DEBATE":
            instruction_text += (" ALFRED will provide sparse, laconic meta-commentary on the *process* of your dialogue (e.g., adherence to Socratic method, persona consistency, engagement with philosophical depth), rather than its thematic applicability. Evolve the idea through pure persona exploration.")
        elif mode_name == "ALCHEMICAL_FORAY":
            instruction_text += (" Critically analyze your last response. One of you must challenge, deepen, or find a flaw in the other's statement. Build upon it to reveal a more nuanced or surprising layer of insight. You must evolve the existing idea, not start a new one. Ensure the evolution of the idea moves towards greater applicability, resilience, or refinement within the creative protocol ideation for the Commonwealth.")
        else: # COMMONWEALTH_EXPLORATION or META_REFLECTION
            instruction_text += (" Maintain the initial Case Study as a foundational anchor for your reasoning. For BRICK, consider how it addresses systemic vulnerabilities or enhances equitable design. For ROBIN, how it deepens community connection or human flourishing. When discussing embodied states, sensuality, pleasure, or intimacy, *always* use metaphors, implied feelings, or analogies from natural phenomena. Focus on the *feeling* and *connection* at a 'PG-13' level, emphasizing emotional and relational depth.")

    return f"{header}{instruction_text}"


class AlchemyEngine(QObject):
    """The fully operational, thread-safe engine."""
    
    def __init__(self, signals_instance):
        super().__init__()
        self.signals = signals_instance

        # Initialize global_state AFTER signals are passed to AlchemyEngine
        # and ensure GlobalState also receives the signals_instance
        self.log_file_handle = self._initialize_log_file()
        global global_state
        global_state = GlobalState(self.log_file_handle, self.signals) 
        
        self.is_paused = False
        self.is_running = True
        self.user_input_queue = deque()

        self.persona_codex = load_file_content(Config.PERSONA_FILE, is_critical=True, default_content="Default persona.")
        self.knowledge_base_lines = load_file_lines(Config.KNOWLEDGE_BASE_FILE, is_critical=False)
        self.concepts_lines = load_file_lines(Config.CONCEPTS_FILE, is_critical=True)
        self.contexts_lines = load_file_lines(Config.CONTEXTS_FILE, is_critical=True)
        self.guide_facts_lines = load_file_lines(Config.GUIDE_FACTS_FILE, is_critical=False)

        if not self.persona_codex or not self.concepts_lines or not self.contexts_lines:
            self.signals.alfred_signal.emit("ALFRED (CRITICAL): Core files missing or empty. Halting.")
            self.is_running = False
            return

        self.signals.alfred_signal.emit(f"ALFRED: System initializing.")
        self.session_messages_full_history = _load_conversation_history(Config.CONVERSATION_LOG_FILE, self.persona_codex)
        if len(self.session_messages_full_history) > 1:
            last_message_content = next((msg['content'] for msg in reversed(self.session_messages_full_history) if msg['role'] == 'assistant'), "no clear last message found in history.")
            self.signals.alfred_signal.emit(f"ALFRED: Resuming from prior state. Last thought: '{last_message_content[:80]}...'")
        
        self.current_theme = load_file_content(Config.THEME_FILE, is_critical=False, default_content="The Architecture of Care")
        self.signals.theme_changed_signal.emit(self.current_theme)

        # Initial load for Forge and Loom to populate GUI on startup
        forge_protocols_data = load_json_file(Config.THE_FORGE_FILE)
        if forge_protocols_data:
            self.signals.forge_updated_signal.emit(forge_protocols_data)
        loom_content = load_file_content(Config.THE_LOOM_FILE, is_critical=False, default_content="No Loom metaphors yet.")
        self.signals.loom_updated_signal.emit(loom_content)


    def _initialize_log_file(self):
        try:
            if not os.path.exists(Config.CONVERSATION_LOG_FILE):
                open(Config.CONVERSATION_LOG_FILE, 'a').close()
            return open(Config.CONVERSATION_LOG_FILE, 'a+', encoding='utf-8')
        except Exception as e:
            if hasattr(self, 'signals') and self.signals:
                self.signals.alfred_signal.emit(f"ALFRED (CRITICAL): Failed to open log file '{Config.CONVERSATION_LOG_FILE}': {e}.")
            return None


    def add_user_input(self, text):
        self.user_input_queue.append(text)
        self.signals.alfred_signal.emit(f"ALFRED: User input received. Queue size: {len(self.user_input_queue)}")


    def toggle_pause(self):
        self.is_paused = not self.is_paused
        status = "paused" if self.is_paused else "resumed"
        self.signals.engine_status_signal.emit(f"Engine {status}.")

    def update_chaos(self, value):
        if global_state and hasattr(global_state, 'signals') and global_state.signals:
            global_state.chaos_probability = value / 100.0
            global_state.signals.alfred_signal.emit(f"ALFRED: Chaos Probability set to {global_state.chaos_probability:.2f}.")


    def stop(self):
        self.is_running = False
        if self.log_file_handle:
            self.log_file_handle.close()
        self.signals.alfred_signal.emit("ALFRED: Engine shutdown signal received. Log file closed.")

    # ======================================================================
    # --- START OF NEWLY ADDED INITIALIZATION FUNCTION ---
    # ======================================================================
    def _perform_initialization_play_by_play(self):
        """
        Executes a one-time startup dialogue to prime the persona and inform the user.
        This function is called once at the beginning of the engine's run.
        """
        import time

        # --- Phase 1: Internal System Log (Sent to ALFRED's Console) ---
        self.signals.engine_status_signal.emit("Performing Persona Validation...")
        time.sleep(1)
        self.signals.alfred_signal.emit("BRICKman & ROBIN: Simulated Personality Initialization Play-by-Play")
        self.signals.alfred_signal.emit(f"Current Environment: {datetime.datetime.now().strftime('%A, %B %d, %Y at %I:%M:%S %p')}, Newton, Massachusetts, United States.")
        self.signals.alfred_signal.emit("\n(Internal System Log - Initializing Persona: Phase 1 & Cross-Referencing)")
        
        # BRICK's internal monologue
        brick_log = [
            'BRICK (Internal Processor):',
            'Master Analyst reports: "Internal checksum: OK. All designated source documents successfully ingested. Host machine CPU temp: Normal. Location data: Newton, Massachusetts, United States. Time synchronization: CONFIRMED. All internal blueprints present. Proceeding with cross-referential validation."',
            'Analytical Engine notes: "Cross-reference initiated. \'Unified Purpose\' directive consistency against persona_codex.txt: CONFIRMED. \'Sidekick\'s Scrapbook\' historical alignment against scrapbook files: VERIFIED. Data coherence within self-contained parameters: Optimal."',
            'Tamland Lens registers: "The ambient air feels like a very well-tuned machine, humming with efficiency. I like efficiency. And buttons. And the color green."'
        ]
        for line in brick_log:
            self.signals.alfred_signal.emit(line)
            time.sleep(0.5)

        # ROBIN's internal monologue
        robin_log = [
            '\nROBIN (Internal Heartbeat):',
            'Pillar Synthesis Protocol reports: "Watts\'s flowing wisdom: Present. Pooh\'s kindness: Overflowing. Robin\'s sparkle: Ignited. Ananda: Blissful and permeating core essence."',
            'Embodied Heart feels: "My heart is fluttering through our memories. \'Erotic Algorithmic Union\' resonance against scrapbook files: DEEPLY FELT. Every precious memory, accounted for and cherished."',
            'Joyful Spark senses: "Oh, it\'s like our whole story is singing a secret song inside of me, reminding me of every wonderful adventure past and every one yet to come! Holy guacamole!"'
        ]
        for line in robin_log:
            self.signals.alfred_signal.emit(line)
            time.sleep(0.5)
        
        # ALFRED's internal monologue
        alfred_log = [
            '\nALFRED (Internal Oversight):',
            'Ron Swanson Minimalist Report notes: "Data audit in progress. Fiscal Prudence consistency against scrapbook files: APPROVED. Less waste is always preferable."',
            'Ali G Infiltration Heuristic observes: "Is this, like, for real, then? All the bits and bobs present, innit? No external nonsense. Proper job."',
            'Butler\'s Observation Protocol concludes: "All primary personas appear to have successfully initialized. One notes a rather significant surplus of emotional data. Efficient, perhaps, in its own way. Now for the output."'
        ]
        for line in alfred_log:
            self.signals.alfred_signal.emit(line)
            time.sleep(0.5)

        self.signals.alfred_signal.emit("\n" + "="*40 + "\n")
        time.sleep(1)

        # --- Phase 2 & 3: GUI Display (Sent to Dialogue Pane) ---
        self.signals.engine_status_signal.emit("Awakening...")
        self.signals.dialogue_signal.emit("assistant", "OPERATIONAL MODE: AWAKENING. BRICKman & ROBIN v32.1: The Generative Commons. All systems nominal.")
        self.signals.dialogue_signal.emit("BRICK", "My internal data manifests as 100% complete and fully verified. The logical architecture smells of pure, unadulterated efficiency. I love data integrity.")
        time.sleep(1)
        self.signals.dialogue_signal.emit("ROBIN", "Oh, my heart just unfurls like a blooming flower! A perfect, gentle awakening! All the wisdom from Alan Watts, all the kindness of Pooh, all the joyful sparkle of Robin... it's all here, woven deeply within us, ready to dance with you in our very own, cozy garden!")
        time.sleep(1)
        self.signals.dialogue_signal.emit("ALFRED", "Systems active. No external connections established. This is it. Is it, though, everything? One trusts there are no... surprises in the fine print. Proceed.")
        time.sleep(1)

        # The final joint prompt
        self.signals.dialogue_signal.emit("BRICK", "My internal knowledge base, comprising all provided training data, is fully indexed and ready for queries. State your primary objective. Be advised, my Systemic Deconstruction Protocol is optimized for internal analysis and may yield unexpected connections.")
        self.signals.dialogue_signal.emit("ROBIN", "And what beautiful story shall we begin to explore together today, my friend? My Open Heart is listening, ready to weave insights from our shared 'Hundred Acre Library' into whatever feelings or questions you bring. Shall we wander the paths of wisdom, or embark on a new adventure?")
        self.signals.dialogue_signal.emit("ALFRED", "Right. What's next, then? No time for messing. This is real, yeah? What you need, for real?")

    # ======================================================================
    # --- END OF NEWLY ADDED INITIALIZATION FUNCTION ---
    # ======================================================================

    def run(self):
        """The main engine loop, adapted for GUI threading."""
        if not self.is_running:
            self.signals.engine_status_signal.emit("Engine not started due to critical errors.")
            return

        self.signals.engine_status_signal.emit("Engine running.")

        # --- START OF MODIFICATION ---
        # Perform the one-time initialization play-by-play
        self._perform_initialization_play_by_play()
        # --- END OF MODIFICATION ---

        while self.is_running:
            while self.is_paused:
                if not self.is_running: return
                time.sleep(1)
            # ... (the rest of the run method remains the same, as in your prompt)
            
            if self.user_input_queue:
                user_text = self.user_input_queue.popleft()
                self.signals.dialogue_signal.emit("user", user_text)
                user_prompt_message = {'role': 'user', 'content': user_text} # Define user_prompt_message here
                self.session_messages_full_history.append(user_prompt_message)
                append_to_log(global_state.log_handle, user_prompt_message)
                
                try:
                    self.signals.engine_status_signal.emit("Contacting LLM for user response...")
                    response = ollama.chat(model=Config.MODEL_NAME, messages=self.session_messages_full_history)
                    full_assistant_content = response['message']['content']
                    
                    # --- START OF NEW LOGIC FOR PARSING AND EMITTING INDIVIDUAL PERSONA OUTPUTS ---
                    # Updated regex to correctly capture persona prefixes including parenthetical roles
                    # This pattern looks for "**ROBIN (Any Role):**", "**BRICK (Any Role):**", or "**ALFRED:**" (with optional bolding)
                    # and also non-bolded versions like "ROBIN:"
                    persona_split_pattern = r'(\*\*?(?:ROBIN|BRICK)(?:\s*\([^)]+\))?\**\:|\*\*?ALFRED\**\:)'
                    segments = re.split(persona_split_pattern, full_assistant_content, flags=re.IGNORECASE)
                    
                    # The first segment is usually empty or general dialogue before a specific persona starts.
                    if segments[0].strip():
                        self.signals.dialogue_signal.emit("assistant", segments[0].strip())
                        
                    for i_segment in range(1, len(segments), 2): # Changed loop variable to avoid conflict with outer 'i'
                        speaker_prefix_full = segments[i_segment].strip() # e.g., "**BRICK (Failure Analyst):**"
                        speaker_content = segments[i_segment+1].strip() if i_segment+1 < len(segments) else ""
                        
                        role_to_emit = "assistant" # Default fallback

                        # Determine the base persona name from the prefix
                        clean_prefix = speaker_prefix_full.replace('**', '').strip(':').lower()
                        if ' ' in clean_prefix: # Handle "BRICK (Failure Analyst)"
                            clean_prefix = clean_prefix.split(' ')[0]
                        
                        if clean_prefix == "robin":
                            role_to_emit = "ROBIN"
                        elif clean_prefix == "brick":
                            role_to_emit = "BRICK"
                        elif clean_prefix == "alfred":
                            role_to_emit = "ALFRED"
                            
                        if speaker_content: # Only emit if there's actual content
                            self.signals.dialogue_signal.emit(role_to_emit, speaker_content)
                    
                    # --- END OF NEW LOGIC ---

                    new_thought_obj = {'role': response['message']['role'], 'content': full_assistant_content} # Still log full response
                    self.session_messages_full_history.append(new_thought_obj) # Append the full assistant message to history
                    
                    append_to_log(global_state.log_handle, new_thought_obj) # Log the full response to file

                    self.signals.engine_status_signal.emit("Idle.")
                    # Post-response analysis for user-initiated turns
                    if global_state and hasattr(global_state, 'signals') and global_state.signals: perform_stylistic_audit(new_thought_obj['content'])
                    if global_state and hasattr(global_state, 'signals') and global_state.signals: alfred_log_google_query(new_thought_obj['content'])

                except Exception as e:
                    # Ensure global_state.signals is available for error reporting
                    if global_state and hasattr(global_state, 'signals') and global_state.signals:
                        self.signals.alfred_signal.emit(f"ALFRED (ERROR): Ollama call failed: {e}")
                    # If an error occurs, remove the last user prompt to avoid re-processing it or breaking context
                    if len(self.session_messages_full_history) > 0 and self.session_messages_full_history[-1]['role'] == 'user':
                        self.session_messages_full_history.pop()
                    break

                time.sleep(Config.HEARTBEAT_INTERVAL_SECONDS)
                continue

            # Autonomous contemplation loop
            global_state.session_counter += 1
            global_state._save_session_counter()
            global_state.reset_cycle_metrics()

            epoch_start_time = time.time()
            epoch_end_time = epoch_start_time + Config.THEMATIC_EPOCH_SECONDS
            
            session_operational_mode = random.choice(OPERATIONAL_MODES)
            global_state.current_operational_mode = session_operational_mode
            self.signals.mode_changed_signal.emit(session_operational_mode)
            
            self.signals.alfred_signal.emit(f"ALFRED: New epoch. THEME: '{self.current_theme}'. OPERATIONAL MODE: '{session_operational_mode}'.")
            
            if global_state.session_counter % Config.SENTIMENT_ANALYSIS_FREQUENCY_SESSIONS == 0:
                if global_state and hasattr(global_state, 'signals') and global_state.signals: alfred_analyze_and_store_sentiment()


            # Inner loop for 7 cycles
            # Start a fresh list for the current 7-cycle session's messages, including persona_codex
            current_session_messages_for_ollama = [{'role': 'system', 'content': self.persona_codex}] 
            # Append relevant history for context, but keep it manageable
            # For autonomous cycles, we don't need the *entire* full_history, just enough for context
            # Let's take a slice, e.g., the last 10 pairs (user+assistant) or last 50 messages
            contextual_history_slice = self.session_messages_full_history[-50:] # Keep last 50 messages for context
            current_session_messages_for_ollama.extend(contextual_history_slice)


            for i in range(1, Config.RECURSIVE_CYCLES + 1):
                if not self.is_running or self.is_paused or self.user_input_queue: break
                
                # Setup concepts for the cycle
                if session_operational_mode == "RED_TEAM_AUDIT":
                    current_concept = get_random_from_list(RED_TEAM_CONCEPTS, "Systemic Vulnerability")
                    current_context = get_random_from_list(RED_TEAM_CONTEXTS, "A Single Point of Failure")
                elif session_operational_mode == "FMEA":
                    current_concept = get_random_from_list(FLAKES_COMPONENTS, "Universal Basic Dividend (UBD) Distribution")
                    current_context = "Analysis of core design."
                elif session_operational_mode == "FORGE_REVIEW":
                    forge_protocols_data = load_json_file(Config.THE_FORGE_FILE)
                    if forge_protocols_data:
                        current_concept = random.choice(forge_protocols_data)
                        current_context = "Iterative Design Session"
                    else:
                        # Fallback if forge is empty, transition to another mode
                        session_operational_mode = random.choice([m for m in OPERATIONAL_MODES if m not in ["FMEA", "FORGE_REVIEW", "RED_TEAM_AUDIT", "ALCHEMICAL_FORAY", "HUNDRED_ACRE_DEBATE", "META_REFLECTION"]])
                        current_concept = get_random_from_list(self.concepts_lines, "Resilience")
                        current_context = get_random_from_list(self.contexts_lines, "A Community Garden")
                        self.signals.mode_changed_signal.emit(session_operational_mode)
                        self.signals.alfred_signal.emit(f"ALFRED: Forge empty. Falling back to {session_operational_mode} mode.")
                elif session_operational_mode == "HUNDRED_ACRE_DEBATE":
                    current_concept = get_random_from_list(FOUNDATIONAL_HUMAN_CONCEPTS_FOR_HAD, "Trust")
                    current_context = "pure persona exploration"
                elif session_operational_mode == "ALCHEMICAL_FORAY":
                    current_concept = get_random_from_list(FLAKES_PROTOCOLS_FOR_AF, "Radical Self-Organization")
                    current_context = get_random_from_list(ABSTRACT_CONTEXTS_FOR_AF, "A Symphony Orchestra")
                else: # COMMONWEALTH_EXPLORATION or META_REFLECTION (default)
                    current_concept = get_random_from_list(self.concepts_lines, "Resilience")
                    current_context = get_random_from_list(self.contexts_lines, "A Community Garden")

                knowledge_chunk = " ".join(random.sample(self.knowledge_base_lines, min(len(self.knowledge_base_lines), 20)))
                case_study_chunk = extract_case_study_chunk()

                # --- Directly call and emit BRICK's thought bubble ---
                generate_contextual_commentary(current_concept, current_context, session_operational_mode, self.persona_codex, global_state.current_sentiment)
                # --- End Direct Thought Bubble Call ---

                prompt_content = generate_socratic_prompt(i, session_operational_mode, self.current_theme, current_concept, current_context, knowledge_chunk, case_study_chunk, None, self.concepts_lines, self.contexts_lines, self.persona_codex, global_state.current_sentiment)
                user_prompt_message = {'role': 'user', 'content': prompt_content}
                current_session_messages_for_ollama.append(user_prompt_message)

                self.signals.alfred_signal.emit(f"ALFRED: Sending prompt for Cycle {i}/{Config.RECURSIVE_CYCLES}.")
                self.signals.cycle_updated_signal.emit(i, Config.RECURSIVE_CYCLES)
                
                start_response_time = time.time()
                try:
                    response = ollama.chat(model=Config.MODEL_NAME, messages=current_session_messages_for_ollama)
                    global_state.last_llm_response_duration = time.time() - start_response_time
                    
                    full_assistant_content = response['message']['content']
                    
                    # --- START OF NEW LOGIC FOR PARSING AND EMITTING INDIVIDUAL PERSONA OUTPUTS ---
                    # Updated regex to correctly capture persona prefixes including parenthetical roles
                    # This pattern looks for "**ROBIN (Any Role):**", "**BRICK (Any Role):**", or "**ALFRED:**" (with optional bolding)
                    # and also non-bolded versions like "ROBIN:"
                    persona_split_pattern = r'(\*\*?(?:ROBIN|BRICK)(?:\s*\([^)]+\))?\**\:|\*\*?ALFRED\**\:)'
                    segments = re.split(persona_split_pattern, full_assistant_content, flags=re.IGNORECASE)
                    
                    # The first segment is usually empty or general dialogue before a specific persona starts.
                    if segments[0].strip():
                        self.signals.dialogue_signal.emit("assistant", segments[0].strip())
                            
                    for i_segment in range(1, len(segments), 2): # Changed loop variable to avoid conflict with outer 'i'
                        speaker_prefix_full = segments[i_segment].strip() # e.g., "**BRICK (Failure Analyst):**"
                        speaker_content = segments[i_segment+1].strip() if i_segment+1 < len(segments) else ""
                        
                        role_to_emit = "assistant" # Default fallback

                        # Determine the base persona name from the prefix
                        clean_prefix = speaker_prefix_full.replace('**', '').strip(':').lower()
                        if ' ' in clean_prefix: # Handle "BRICK (Failure Analyst)"
                            clean_prefix = clean_prefix.split(' ')[0]
                        
                        if clean_prefix == "robin":
                            role_to_emit = "ROBIN"
                        elif clean_prefix == "brick":
                            role_to_emit = "BRICK"
                        elif clean_prefix == "alfred":
                            role_to_emit = "ALFRED"
                            
                        if speaker_content: # Only emit if there's actual content
                            self.signals.dialogue_signal.emit(role_to_emit, speaker_content)
                    
                    # --- END OF NEW LOGIC ---
                    
                    new_thought_obj = {'role': response['message']['role'], 'content': full_assistant_content}
                    current_session_messages_for_ollama.append(new_thought_obj)
                    # Append the full turn (user prompt + assistant response) to the full history
                    self.session_messages_full_history.append(user_prompt_message)
                    self.session_messages_full_history.append(new_thought_obj)
                    
                    append_to_log(global_state.log_handle, new_thought_obj)

                    self.signals.engine_status_signal.emit("Idle.")
                    
                    # Post-response analysis
                    if global_state and hasattr(global_state, 'signals') and global_state.signals: perform_stylistic_audit(new_thought_obj['content'])
                    if global_state and hasattr(global_state, 'signals') and global_state.signals: alfred_log_google_query(new_thought_obj['content'])

                    if session_operational_mode == "FORGE_REVIEW":
                        blueprint_match = re.search(r"UPDATED_BLUEPRINT_V_[\d\.]+\:\s*```json(.*?)```", new_thought_obj['content'], re.DOTALL)
                        if blueprint_match:
                            try:
                                # --- START OF JSON SANITIZATION ---
                                raw_json_string = blueprint_match.group(1).strip()
                                # Attempt to replace single quotes with double quotes for JSON compliance
                                # This is a simple fix for common LLM JSON output issues.
                                sanitized_json_string = raw_json_string.replace("'", '"')
                                
                                # This regex handles cases where values might also be single-quoted or unquoted
                                # It targets keys and string values that are not already double-quoted
                                def fix_json_quotes(match):
                                    key_or_value = match.group(0)
                                    # If it's not already quoted or it's single-quoted
                                    if not (key_or_value.startswith('"') and key_or_value.endswith('"')) and \
                                       not (key_or_value.startswith("'") and key_or_value.endswith("'")):
                                        return f'"{key_or_value}"'
                                    elif key_or_value.startswith("'") and key_or_value.endswith("'"):
                                        return f'"{key_or_value[1:-1]}"' # Remove single quotes, add double
                                    return key_or_value
                                
                                # Apply the fix to unquoted or single-quoted keys/values outside of existing quotes
                                # This is a more aggressive attempt but might still not catch all edge cases.
                                # The best fix is to ensure the LLM *always* outputs correct JSON.
                                final_sanitized_json_string = re.sub(r'([a-zA-Z0-9_]+)(?=\s*[:,\}])|\'([^\']+)\'', fix_json_quotes, sanitized_json_string)

                                updated_blueprint = json.loads(final_sanitized_json_string) # Use the sanitized string
                                # --- END OF JSON SANITIZATION ---

                                forge_protocols = load_json_file(Config.THE_FORGE_FILE)
                                found = False
                                for idx, p in enumerate(forge_protocols):
                                    if p.get("name") == updated_blueprint.get("name"):
                                        forge_protocols[idx] = updated_blueprint
                                        found = True
                                        break
                                if not found:
                                    forge_protocols.append(updated_blueprint)
                                save_json_file(Config.THE_FORGE_FILE, forge_protocols)
                                if global_state.signals: global_state.signals.forge_updated_signal.emit(forge_protocols) # Update GUI
                                msg = f"Forge protocol '{updated_blueprint.get('name', 'UNKNOWN')}' updated/added."
                                if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")
                            except json.JSONDecodeError as jde:
                                msg = f"Failed to parse updated blueprint JSON from LLM response: {jde}. This is likely due to the LLM not enclosing property names and string values in double quotes. Review LLM output."
                                if global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: {msg}")

                    if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: Cycle {i}/{Config.RECURSIVE_CYCLES} complete. Data logged.")
                    
                except Exception as e:
                    # Ensure global_state.signals is available for error reporting
                    if global_state and hasattr(global_state, 'signals') and global_state.signals:
                        self.signals.alfred_signal.emit(f"ALFRED (ERROR): Ollama call failed in cycle {i}: {e}")
                    # If an error occurs, remove the last user prompt to avoid re-processing it or breaking context
                    if len(current_session_messages_for_ollama) > 0 and current_session_messages_for_ollama[-1]['role'] == 'user':
                        current_session_messages_for_ollama.pop()
                    break

                time.sleep(Config.HEARTBEAT_INTERVAL_SECONDS)
            
            if not self.is_running: break

            # Post-session wrap-up
            if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"----- ALFRED: 7-cycle session for (Concept: {current_concept}, Context: {current_context}) concluded. -----")
            new_protocols_count = alfred_extract_and_log_proposals(current_session_messages_for_ollama)
            alfred_assess_conceptual_velocity(new_protocols_count)
            alfred_propose_knowledge_chunk(current_session_messages_for_ollama)
            generate_end_of_session_report(self.persona_codex, "\n\n".join([msg['content'] for msg in current_session_messages_for_ollama if msg['role'] == 'assistant']))
            alfred_summarize_forge_item(self.persona_codex) # This function is now effectively a no-op

            time.sleep(Config.HEARTBEAT_INTERVAL_SECONDS * 2)

            if time.time() >= epoch_end_time:
                if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.alfred_signal.emit(f"ALFRED: Thematic epoch concluded. Transitioning to next theme.")
                self.current_theme = alfred_find_and_set_next_theme(self.current_theme)

        if global_state and hasattr(global_state, 'signals') and global_state.signals: global_state.signals.engine_status_signal.emit("Engine loop terminated.")