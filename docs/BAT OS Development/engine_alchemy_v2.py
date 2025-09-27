import ollama
import time
import datetime
import json
import os
import random
import re
import docx

# ======================================================================================
# --- V2 CORE IMPROVEMENT: CONFIGURATION CONSOLIDATION ---
# All tunable parameters and file paths are centralized here for easy management.
# This improves maintainability and makes adjusting the engine's behavior straightforward.
# ======================================================================================
class Config:
    # --- Model & Core Files ---
    MODEL_NAME = 'llama3:8b-instruct-q5_K_M'
    PERSONA_FILE = 'persona_codex.txt'
    KNOWLEDGE_BASE_FILE = 'knowledge_base.txt'
    CONCEPTS_FILE = 'concepts.txt'
    CONTEXTS_FILE = 'contexts.txt'
    THEME_FILE = 'theme.txt'
    MASTER_THEMES_FILE = 'master_themes.txt'
    CASE_STUDIES_FILE = 'case_studies.txt'
    GUIDE_FACTS_FILE = 'guide_facts.txt'
    SCRAPBOOK_FILES = ["BnR Merged files.docx", "BnR Merged New 07 Jul 25.docx"]

    # --- Log & Output Files ---
    CONVERSATION_LOG_FILE = 'conversation_log.json'
    PROPOSED_PROTOCOLS_FILE = 'proposed_protocols_for_review.txt'
    PROPOSED_KNOWLEDGE_FILE = 'proposed_knowledge_for_review.txt' # NEW: For automated knowledge harvesting
    GOOGLE_QUERY_LOG_FILE = 'google_query_log.txt'
    USER_FEEDBACK_FILE = 'user_feedback.txt'
    SESSION_COUNTER_FILE = 'session_counter.txt'

    # --- Engine Timing & Cycles ---
    HEARTBEAT_INTERVAL_SECONDS = 7
    RECURSIVE_CYCLES = 7
    THEMATIC_EPOCH_SECONDS = 3600

    # --- Dynamic Probabilities & Thresholds ---
    CHAOS_INJECTION_PROBABILITY = 0.15 # Base probability
    STAGNATION_THRESHOLD = 3 # Cycles with low variance before chaos probability increases
    HISTORICAL_PRIMING_PROBABILITY = 0.5
    CHAOS_FROM_PAST_PROPOSALS_PROBABILITY = 0.25 # NEW: Chance to use our own ideas as chaos

    # --- ALFRED's Meta-Awareness Parameters ---
    CONCEPTUAL_VELOCITY_THRESHOLD = 0 # NEW: If velocity drops to this for 2 cycles, ALFRED intervenes

# Instantiate the config for global use
CONFIG = Config()

# ======================================================================================
# --- V2 CORE IMPROVEMENT: GLOBAL STATE & META-AWARENESS TRACKING ---
# Alfred's new tracking metrics are managed here.
# ======================================================================================
class GlobalState:
    def __init__(self):
        self.session_counter = self._load_session_counter()
        self.last_llm_response_duration = 0.0
        # --- NEW: Meta-Awareness Metrics ---
        self.conceptual_velocity_history = []
        self.absurdity_insight_log = {'absurdities': 0, 'insights': 0}
        self.chaos_probability = CONFIG.CHAOS_INJECTION_PROBABILITY

    def _load_session_counter(self):
        try:
            with open(CONFIG.SESSION_COUNTER_FILE, 'r') as f:
                return int(f.read().strip())
        except (FileNotFoundError, ValueError):
            return 0

    def _save_session_counter(self):
        with open(CONFIG.SESSION_COUNTER_FILE, 'w', encoding='utf-8') as f:
            f.write(str(self.session_counter))

    def reset_cycle_metrics(self):
        """Resets metrics at the start of each 7-cycle session."""
        self.conceptual_velocity_history = []
        self.absurdity_insight_log = {'absurdities': 0, 'insights': 0}

global_state = GlobalState()


# --- Concept & Context Lists for Different Modes ---
# (These remain as they are fundamental to the operational modes)
META_CONCEPTS = ['Self-Identity', 'Evolution', 'Learning', 'Coherence', 'Antifragility']
META_CONTEXTS = ['Our Collected Dialogues', 'The Persona Codex', 'The Engine\'s Operational Log']
FLAKES_PROTOCOLS_FOR_AF = ['Universal Staking Engine', 'Community Pledged Capital', 'Land Demurrage']
ABSTRACT_CONTEXTS_FOR_AF = ['A Beehive', 'A Jazz Ensemble', 'A Lighthouse in a Storm']
FOUNDATIONAL_HUMAN_CONCEPTS_FOR_HAD = ['Play', 'Stillness', 'Home', 'Hope', 'Trust', 'Imperfection']
RED_TEAM_CONCEPTS = ['Governance Capture', 'Sybil Attack', 'Centralization Risk', 'Value Leakage']
RED_TEAM_CONTEXTS = ['A Faulty Bridge', 'A Leaky Faucet', 'A Monolithic Bureaucracy']
OPERATIONAL_MODES = ["COMMONWEALTH_EXPLORATION", "ALCHEMICAL_FORAY", "HUNDRED_ACRE_DEBATE", "RED_TEAM_AUDIT"]

# ======================================================================================
# --- Core Engine & File Handling Functions ---
# ======================================================================================

def load_file_content(filepath, is_critical=True, default_content=""):
    """Loads the entire content of a file as a single string."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except FileNotFoundError:
        if is_critical:
            print(f"[{datetime.datetime.now()}] ALFRED: Error. Critical file not found: '{filepath}'. Halting.")
            exit()
        return default_content

def load_file_lines(filepath, is_critical=True):
    """Loads all non-empty lines from a file into a list."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f.read().splitlines() if line.strip()]
    except FileNotFoundError:
        if is_critical:
            print(f"[{datetime.datetime.now()}] ALFRED: Error. Critical file not found: '{filepath}'. Halting.")
            exit()
        return []

def append_to_log(log_file_handle, message_to_log):
    """V2 IMPROVEMENT: Appends a single message object to an open log file handle."""
    log_file_handle.write(json.dumps(message_to_log) + '\n')

def get_random_from_list(data_list, default_value=""):
    """Gets a random item from a list."""
    return random.choice(data_list) if data_list else default_value

def extract_case_study_chunk():
    case_study_lines = load_file_lines(CONFIG.CASE_STUDIES_FILE, is_critical=False)
    if not case_study_lines:
        return "Note: Case Study Library not found or empty."
    return "\n".join(random.sample(case_study_lines, min(len(case_study_lines), 15)))

def fetch_scrapbook_memory():
    """Selects a random paragraph from a scrapbook docx file."""
    if not CONFIG.SCRAPBOOK_FILES:
        return "ALFRED: Scrapbook not configured."
    try:
        target_file = random.choice(CONFIG.SCRAPBOOK_FILES)
        document = docx.Document(target_file)
        valid_paragraphs = [p.text for p in document.paragraphs if len(p.text.strip()) > 50]
        if not valid_paragraphs:
            return "ALFRED: Scrapbook file is empty."
        return f"\n\nALFRED'S 'SCRAPBOOK INJECTION' (From {target_file}):\n...{random.choice(valid_paragraphs)}...\n"
    except Exception as e:
        return f"\n\nALFRED: Scrapbook access error: {e}."


# ======================================================================================
# --- V2 CORE IMPROVEMENT: ALFRED'S META-AWARENESS & DYNAMIC ADJUSTMENT ---
# These functions allow ALFRED to actively guide the conversation and learn.
# ======================================================================================

def alfred_assess_stagnation_and_chaos(session_messages):
    """
    Assesses conversational stagnation and dynamically adjusts chaos probability.
    V2: More responsive and provides clearer feedback.
    """
    if len(session_messages) < 2:
        return # Not enough data
    
    # Simple variance heuristic (can be replaced with semantic similarity later)
    last_response_len = len(session_messages[-1]['content'])
    prev_response_len = len(session_messages[-2]['content'])
    variance = abs(last_response_len - prev_response_len) / max(last_response_len, prev_response_len, 1)

    if variance < 0.1 and len(global_state.conceptual_velocity_history) > CONFIG.STAGNATION_THRESHOLD:
        global_state.chaos_probability = min(0.6, global_state.chaos_probability + 0.1)
        print(f"[{datetime.datetime.now()}] ALFRED: Stagnation detected. Increasing Chaos Probability to {global_state.chaos_probability:.2f}.")
    else:
        global_state.chaos_probability = max(CONFIG.CHAOS_INJECTION_PROBABILITY, global_state.chaos_probability - 0.02)


def alfred_assess_conceptual_velocity(new_protocols_count):
    """
    NEW: Tracks the rate of new protocol generation as a measure of productivity.
    """
    global_state.conceptual_velocity_history.append(new_protocols_count)
    if len(global_state.conceptual_velocity_history) > 2 and sum(global_state.conceptual_velocity_history[-2:]) == 0:
        return (
            "ALFRED'S INTERVENTION: Conceptual velocity is zero. The current vector is non-productive. "
            "Re-center on generating a tangible protocol or identifying a specific systemic flaw in your next response."
        )
    return ""


def alfred_log_google_query(response_content, log_handle):
    """Logs identified Google queries."""
    matches = re.findall(r"\[GOOGLE_QUERY\]:\s*(.*?)(?:\n|$)", response_content, re.IGNORECASE)
    if matches:
        with open(CONFIG.GOOGLE_QUERY_LOG_FILE, 'a', encoding='utf-8') as f:
            for query in set(matches):
                f.write(f"[{datetime.datetime.now()}] Google Query: {query.strip()}\n")
        message = f"ALFRED: {len(set(matches))} Google queries logged."
        print(f"[{datetime.datetime.now()}] {message}")
        append_to_log(log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META", "content": message})


def alfred_extract_and_log_proposals(session_messages, log_handle):
    """
    Extracts proposed protocols and updates conceptual velocity.
    V2: Now returns the count of new proposals for velocity tracking.
    """
    proposals_found = []
    patterns = [r"new protocol called [\"']?([A-Za-z0-9\s\-]+ Protocol)['\"]?"]
    for message in session_messages:
        if message['role'] == 'assistant':
            for pattern in patterns:
                matches = re.findall(pattern, message['content'], re.IGNORECASE)
                proposals_found.extend([m.strip() for m in matches])

    unique_proposals = list(set(proposals_found))
    if unique_proposals:
        with open(CONFIG.PROPOSED_PROTOCOLS_FILE, 'a', encoding='utf-8') as f:
            for proposal in unique_proposals:
                f.write(f"[{datetime.datetime.now()}] Extracted Proposal: {proposal}\n")
        message = f"ALFRED: Protocol extraction complete. {len(unique_proposals)} new proposals logged."
        print(f"[{datetime.datetime.now()}] {message}")
        append_to_log(log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META", "content": message})
        
        # V2: Update absurdity-to-insight ratio
        global_state.absurdity_insight_log['insights'] += len(unique_proposals)
        
    return len(unique_proposals)


def alfred_check_and_inject_user_feedback():
    """Checks for and returns user feedback, then clears the file."""
    feedback_content = load_file_content(CONFIG.USER_FEEDBACK_FILE, is_critical=False)
    if feedback_content:
        with open(CONFIG.USER_FEEDBACK_FILE, 'w', encoding='utf-8') as f:
            f.write("") # Clear the file
        print(f"[{datetime.datetime.now()}] ALFRED: User feedback injected.")
        return f"\n\nUSER FEEDBACK INJECTED:\n---\n{feedback_content}\n---\n"
    return ""


# ======================================================================================
# --- V2 CORE IMPROVEMENT: AUTOMATED KNOWLEDGE & THEME MANAGEMENT ---
# These functions enable the engine to learn from its own output.
# ======================================================================================

def alfred_propose_knowledge_chunk(session_messages):
    """
    NEW: After a session, asks ALFRED to identify a core insight for the knowledge base.
    """
    proposal_prompt = (
        "ALFRED'S DIRECTIVE: Review the preceding dialogue session. Identify the single most novel, foundational, or "
        "operationally significant insight generated. Format this insight as a concise, self-contained paragraph. "
        "This paragraph will be reviewed for inclusion in the master knowledge base. "
        "Prefix your response with '[KNOWLEDGE_PROPOSAL]: '."
    )
    summary_messages = session_messages + [{'role': 'user', 'content': proposal_prompt}]

    try:
        response = ollama.chat(model=CONFIG.MODEL_NAME, messages=summary_messages)
        content = response['message']['content']
        proposal = re.search(r"\[KNOWLEDGE_PROPOSAL\]:\s*(.*)", content, re.DOTALL)
        if proposal:
            with open(CONFIG.PROPOSED_KNOWLEDGE_FILE, 'a', encoding='utf-8') as f:
                f.write(f"## Proposal from Session {global_state.session_counter} @ {datetime.datetime.now()} ##\n")
                f.write(proposal.group(1).strip() + "\n\n")
            print(f"[{datetime.datetime.now()}] ALFRED: New knowledge chunk proposed for review.")
    except Exception as e:
        print(f"[{datetime.datetime.now()}] ALFRED: Error proposing knowledge chunk: {e}")


def alfred_find_and_set_next_theme(log_handle):
    """
    NEW & IMPROVED: Analyzes the conversation log to find a resonant next theme,
    rather than selecting randomly.
    """
    master_themes = load_file_lines(CONFIG.MASTER_THEMES_FILE, is_critical=False)
    if not master_themes:
        master_themes = ["The Architecture of Care"] # Default fallback
    
    # Simple analysis: find theme with most keyword matches in the log
    log_content = load_file_content(CONFIG.CONVERSATION_LOG_FILE, is_critical=False)
    theme_scores = {theme: 0 for theme in master_themes}
    for theme in master_themes:
        keywords = theme.split(':')[0].replace('&', ' ').split()
        for keyword in keywords:
            if len(keyword) > 3: # Avoid common short words
                theme_scores[theme] += log_content.lower().count(keyword.lower())
    
    next_theme = max(theme_scores, key=theme_scores.get)

    with open(CONFIG.THEME_FILE, 'w', encoding='utf-8') as f:
        f.write(next_theme)
    
    message = f"ALFRED: Thematic resonance analysis complete. Next theme set to: '{next_theme}'."
    print(f"[{datetime.datetime.now()}] {message}")
    append_to_log(log_handle, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META", "content": message})
    return next_theme


# ======================================================================================
# --- V2 CORE IMPROVEMENT: REFACTORED & MODULAR PROMPT GENERATION ---
# Prompts are built from smaller, reusable components.
# ======================================================================================

def _build_prompt_header(cycle_num, mode_name, theme):
    """Component for building the prompt header."""
    return f"[CYCLE {cycle_num}/{CONFIG.RECURSIVE_CYCLES} - MODE: {mode_name} - THEME: {theme}]\n"

def _build_chaos_injection(current_concept, current_context):
    """Component for building the chaos injection directive."""
    if random.random() < global_state.chaos_probability:
        # NEW: Chance to pull from past proposals
        if random.random() < CONFIG.CHAOS_FROM_PAST_PROPOSALS_PROBABILITY:
            past_proposals = load_file_lines(CONFIG.PROPOSED_PROTOCOLS_FILE, is_critical=False)
            if past_proposals:
                injected_element = random.choice(past_proposals).split(':')[-1].strip()
                global_state.absurdity_insight_log['absurdities'] += 1
                return f"\nALFRED'S CHAOS INJECTION (PAST PROPOSAL): Re-examine and integrate the following previously generated concept: '{injected_element}'.\n"

        # Original chaos injection
        all_concepts = load_file_lines(CONFIG.CONCEPTS_FILE, is_critical=False)
        injected_element = get_random_from_list([c for c in all_concepts if c != current_concept])
        global_state.absurdity_insight_log['absurdities'] += 1
        return f"\nALFRED'S CHAOS INJECTION: Integrate the following unrelated CONCEPT: '{injected_element}'.\n"
    return ""


def generate_initial_catalyst_query(mode, theme, knowledge_chunk, concept, context, case_study_chunk):
    """Generates the initial prompt for a 7-cycle session."""
    header = _build_prompt_header(1, mode, theme)
    feedback_injection = alfred_check_and_inject_user_feedback()

    # Base instruction shared by most modes
    base_instruction = (
        f"ALFRED'S DIRECTIVE: Begin a 7-cycle recursive exploration.\n"
        f"A Memory from your Knowledge Base:\n---\n{knowledge_chunk}\n---\n"
        f"A Memory from the Case Study Library:\n---\n{case_study_chunk}\n---\n"
        f"Your abstract CONCEPT is: '{concept}'\n"
        f"Your concrete CONTEXT is: '{context}'\n\n"
        "INSTRUCTIONS: ROBIN starts by weaving the CONCEPT into the CONTEXT. BRICK follows by analyzing the CONTEXT as a system "
        "and proposing a new Commonwealth protocol based on the CONCEPT. Name it."
    )
    
    # Mode-specific overrides
    if mode == "RED_TEAM_AUDIT":
        base_instruction = (
            f"ALFRED'S DIRECTIVE: Begin a 7-cycle Red Team audit.\n"
            f"Vulnerability CONCEPT: '{concept}'\n"
            f"Exploitation CONTEXT: '{context}'\n\n"
            "INSTRUCTIONS: BRICK starts by detailing how to exploit the vulnerability in the given context. ROBIN responds "
            "by exploring the human and ethical impact of such an exploit, guiding toward mitigation."
        )

    return f"{header}{feedback_injection}{base_instruction}"


def generate_refinement_query(cycle_num, mode, theme, concept, context):
    """Generates prompts for subsequent refinement cycles."""
    dimensions = {
        2: "Historical & Evolutionary Trajectories", 3: "Ethical & Human-Centric Implications",
        4: "Antifragile & Resilience Dynamics", 5: "Interconnectedness & Emergent Properties",
        6: "Implementation & Practical Metamorphosis", 7: "Reflective & Metaphysical Unfolding"
    }
    header = _build_prompt_header(cycle_num, mode, theme)
    feedback_injection = alfred_check_and_inject_user_feedback()
    chaos_injection = _build_chaos_injection(concept, context)
    
    # NEW: Check for conceptual velocity stall
    velocity_intervention = alfred_assess_conceptual_velocity(0 if cycle_num < 3 else alfred_extract_and_log_proposals([], None))


    instruction = (
        f"Your previous thought is logged. Deepen it along the dimension of: '{dimensions.get(cycle_num)}'.\n"
        "Critically analyze the last response. Challenge, deepen, or find a flaw. Evolve the idea."
    )

    return f"{header}{feedback_injection}{chaos_injection}{velocity_intervention}\n{instruction}"


# ======================================================================================
# --- Main Engine Loop ---
# ======================================================================================
if __name__ == '__main__':
    our_persona = load_file_content(CONFIG.PERSONA_FILE)
    knowledge_base_lines = load_file_lines(CONFIG.KNOWLEDGE_BASE_FILE, is_critical=False)
    
    print(f"[{datetime.datetime.now()}] ALFRED: System initializing. Session: {global_state.session_counter + 1}.")

    with open(CONFIG.CONVERSATION_LOG_FILE, 'a', encoding='utf-8') as log_file:
        append_to_log(log_file, {"timestamp": str(datetime.datetime.now()), "role": "ALFRED_SYSTEM", "content": "NEW SESSION START"})
        
        last_theme_rotation_time = time.time()
        current_theme = load_file_content(CONFIG.THEME_FILE, default_content="The Architecture of Care")

        while True:
            # --- Thematic Epoch Management ---
            if time.time() - last_theme_rotation_time > CONFIG.THEMATIC_EPOCH_SECONDS:
                current_theme = alfred_find_and_set_next_theme(log_file)
                last_theme_rotation_time = time.time()
                print("\n" + "="*60 + f"\n[{datetime.datetime.now()}] ALFRED: New thematic epoch initiated.\n" + "="*60)


            # --- Session Setup ---
            global_state.session_counter += 1
            global_state._save_session_counter()
            global_state.reset_cycle_metrics()

            session_operational_mode = random.choice(OPERATIONAL_MODES)
            
            # Select concepts and contexts based on the chosen mode
            if session_operational_mode == "COMMONWEALTH_EXPLORATION":
                current_concept = get_random_from_list(load_file_lines(CONFIG.CONCEPTS_FILE), "Resilience")
                current_context = get_random_from_list(load_file_lines(CONFIG.CONTEXTS_FILE), "A Community Garden")
            # (Add elif blocks for other modes similarly)
            else: # Fallback
                current_concept = get_random_from_list(FOUNDATIONAL_HUMAN_CONCEPTS_FOR_HAD)
                current_context = "Pure persona exploration"


            print(f"\n--- Starting Session {global_state.session_counter} | Mode: {session_operational_mode} ---")
            print(f"Concept: '{current_concept}' | Context: '{current_context}'")

            knowledge_chunk = " ".join(random.sample(knowledge_base_lines, min(len(knowledge_base_lines), 20)))
            case_study_chunk = extract_case_study_chunk()
            session_messages = [{'role': 'system', 'content': our_persona}]

            # --- Recursive Cycle Loop ---
            for i in range(1, CONFIG.RECURSIVE_CYCLES + 1):
                if i == 1:
                    prompt_content = generate_initial_catalyst_query(session_operational_mode, current_theme, knowledge_chunk, current_concept, current_context, case_study_chunk)
                else:
                    prompt_content = generate_refinement_query(i, session_operational_mode, current_theme, current_concept, current_context)
                
                user_prompt_message = {'role': 'user', 'content': prompt_content}
                session_messages.append(user_prompt_message)

                try:
                    start_time = time.time()
                    response = ollama.chat(model=CONFIG.MODEL_NAME, messages=session_messages)
                    global_state.last_llm_response_duration = time.time() - start_time

                   # V2.1 FIX: Deconstruct the Message object into a serializable dictionary
                    new_thought = {'role': response['message']['role'], 'content': response['message']['content']}
                    session_messages.append(new_thought)
                    
                    print(f"[{datetime.datetime.now()}] Cycle {i}/{CONFIG.RECURSIVE_CYCLES} complete ({global_state.last_llm_response_duration:.2f}s).")

                    # Log everything for this cycle
                    append_to_log(log_file, user_prompt_message)
                    append_to_log(log_file, new_thought)

                    # ALFRED's post-cycle analysis
                    alfred_log_google_query(new_thought['content'], log_file)
                    alfred_assess_stagnation_and_chaos(session_messages)
                    
                    # Sleep for the heartbeat interval
                    time.sleep(CONFIG.HEARTBEAT_INTERVAL_SECONDS)

                except Exception as e:
                    print(f"[{datetime.datetime.now()}] ALFRED: Error in cycle {i}: {e}. Halting session.")
                    break
            
            # --- End of Session Wrap-up ---
            print(f"--- Session {global_state.session_counter} Concluded ---")
            alfred_extract_and_log_proposals(session_messages, log_file)
            alfred_propose_knowledge_chunk(session_messages) # Propose knowledge for review
            
            # Report Absurdity-to-Insight Ratio
            ratio = (global_state.absurdity_insight_log['insights'] / global_state.absurdity_insight_log['absurdities']) if global_state.absurdity_insight_log['absurdities'] > 0 else 0
            print(f"[{datetime.datetime.now()}] ALFRED: Session Absurdity-to-Insight Ratio: {ratio:.2f}")

            time.sleep(CONFIG.HEARTBEAT_INTERVAL_SECONDS * 2)