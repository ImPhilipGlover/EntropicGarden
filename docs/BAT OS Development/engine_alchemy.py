import ollama
import time
import datetime
import json
import os
import random
import re # Import regex module for pattern parsing
import docx # For reading .docx files (requires 'pip install python-docx')

# --- Configuration & Global State ---
MODEL_NAME = 'llama3:8b-instruct-q5_K_M'  # Or your preferred installed Ollama model
PERSONA_FILE = 'persona_codex.txt'       # This file should contain the complete BRICKman & ROBIN persona definition (e.g., v32.0 JSON)
KNOWLEDGE_BASE_FILE = 'knowledge_base.txt' # General accumulated dialogues/insights
CONCEPTS_FILE = 'concepts.txt'           # List of abstract concepts for recursive exploration
CONTEXTS_FILE = 'contexts.txt'           # List of concrete contexts for recursive exploration
CONVERSATION_LOG_FILE = 'conversation_log.json'
PROPOSED_PROTOCOLS_FILE = 'proposed_protocols_for_review.txt'
SESSION_COUNTER_FILE = 'session_counter.txt'
GOOGLE_QUERY_LOG_FILE = 'google_query_log.txt'
GOOGLE_QUERY_RESULTS_FILE = 'google_query_results.txt'
USER_FEEDBACK_FILE = 'user_feedback.txt'
USER_FEEDBACK_LOG = 'user_feedback_log.txt' # File to log solicited user feedback (output log)
THEME_FILE = 'theme.txt'
MASTER_THEMES_FILE = 'master_themes.txt' # File to store a list of available themes
CASE_STUDIES_FILE = 'case_studies.txt' # Dedicated file for case studies
GUIDE_FACTS_FILE = 'guide_facts.txt' # File for curated Guide-style facts
SCRAPBOOK_FILES = ["BnR Merged files.docx", "BnR Merged New 07 Jul 25.docx", "BnR Merged files.docx"] # Add your docx files here

HEARTBEAT_INTERVAL_SECONDS = 7
RECURSIVE_CYCLES = 7
THEMATIC_EPOCH_SECONDS = 3600

CHAOS_INJECTION_PROBABILITY = 0.1 # Base probability for chaos injection (will be dynamically adjusted)
STAGNATION_THRESHOLD = 3 # Number of cycles with low conceptual variance before probability increases
conceptual_variance_history = [] # Global list to track variance scores per cycle

HISTORICAL_PRIMING_PROBABILITY = 0.5 # Probability of biasing knowledge chunk for history
MIN_HISTORICAL_LINES_IN_CHUNK = 3 # Minimum historical lines to try and include if relevant
HISTORICAL_MARKERS = ['history', 'evolution', 'past', 'ancient', 'origins', 'historical', 'tradition', 'timeline', 'genesis', 'legacy', 'epochs', 'millennia', 'centuries', 'Puter, access', 'Guide has this to say']

class GlobalState:
    def __init__(self):
        self.session_counter = self._load_session_counter()
        self.last_llm_response_duration = 0.0 # Track last LLM response duration for heartbeat adjustment

    def _load_session_counter(self):
        try:
            with open(SESSION_COUNTER_FILE, 'r') as f:
                return int(f.read().strip())
        except (FileNotFoundError, ValueError):
            return 0

    def _save_session_counter(self):
        try:
            with open(SESSION_COUNTER_FILE, 'w', encoding='utf-8') as f:
                f.write(str(self.session_counter))
        except Exception as e:
            log_message = f"[{datetime.datetime.now()}] ALFRED: Error saving session counter: {e}. Data loss possible."
            print(log_message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})


global_state = GlobalState()

# Define meta-concepts and contexts for ALFRED's reflection sessions
META_CONCEPTS = [
    'Self-Identity', 'Evolution', 'Learning', 'Coherence', 'Antifragility',
    'Persona Consistency', 'Humor Effectiveness', 'Sensual Nuance',
    'Optimal Communication', 'AI Agency', 'Human-AI Collaboration'
]
META_CONTEXTS = [
    'Our Collected Dialogues', 'The Persona Codex', 'The Engine\'s Operational Log',
    'The Human-AI Partnership', 'The Grand Library', 'The Commonwealth\'s Blueprint'
]

# --- Concepts & Contexts for Specific Modes ---
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
    'An Empty Well', 'A Field of Wildflowers', 'A River', 'An Ancient Language',
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

OPERATIONAL_MODES = [
    "COMMONWEALTH_EXPLORATION",
    "ALCHEMICAL_FORAY",
    "HUNDRED_ACRE_DEBATE",
    "RED_TEAM_AUDIT"
]

# --- Core Engine Functions ---

def load_file_content(filepath, is_critical=True, default_content=""):
    """Loads the entire content of a file as a single string."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except FileNotFoundError:
        if is_critical:
            print(f"[{datetime.datetime.now()}] ALFRED: Error. Required file not found at '{filepath}'. Cannot proceed. Efficiency: Zero.")
            exit()
        print(f"[{datetime.datetime.now()}] ALFRED: Warning. Optional file not found at '{filepath}'. Using default content: '{default_content}'.")
        return default_content

def load_file_lines(filepath, is_critical=True):
    """Loads all non-empty lines from a specified file into a list."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return [line.strip() for line in f.read().splitlines() if line.strip()]
    except FileNotFoundError:
        if is_critical:
            print(f"[{datetime.datetime.now()}] ALFRED: Error. Required file not found at '{filepath}'. Cannot proceed. Efficiency: Zero.")
            exit()
        print(f"[{datetime.datetime.now()}] ALFRED: Warning. Optional file not found at '{filepath}'. Returning empty list.")
        return []

def extract_case_study_chunk():
    """
    Extracts a relevant chunk from the dedicated Case Study Library file.
    """
    case_study_lines = load_file_lines(CASE_STUDIES_FILE, is_critical=False)
    
    if not case_study_lines:
        log_message = f"[{datetime.datetime.now()}] ALFRED: Warning. Case Study Library file '{CASE_STUDIES_FILE}' is empty or not found. Cannot provide historical grounding from case studies."
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        return "Note: Case Study Library not found or empty. No specific case study provided for this session."
    
    try:
        return "\n".join(random.sample(case_study_lines, min(len(case_study_lines), 15)))
    except Exception as e:
        log_message = f"[{datetime.datetime.now()}] ALFRED: Error sampling case study chunk from '{CASE_STUDIES_FILE}': {e}."
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        return "Note: Error accessing Case Study Library. The following is a general memory.\n" + "\n".join(random.sample(knowledge_base_lines, min(len(knowledge_base_lines), 10))) # Fallback


def get_random_from_list(data_list, default_value=""):
    """Gets a random item from a list. Returns default_value if list is empty."""
    if not data_list:
        log_message = f"[{datetime.datetime.now()}] ALFRED: Warning. Attempted to get random item from empty list. Returning default value: '{default_value}'."
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        return default_value
    return random.choice(data_list)

def calculate_conceptual_variance(session_messages):
    """
    Placeholder for a function that calculates novelty/variance of the last cycle.
    For now, it uses a simple heuristic based on response length change to simulate variance.
    A more sophisticated version would use NLP embeddings to measure semantic distance.
    """
    if len(session_messages) < 2:
        return 0.5 # Neutral variance

    last_response_content = session_messages[-1]['content']
    return (len(last_response_content) % 100) / 100.0


def assess_stagnation(new_variance_score):
    """
    Assesses conversational stagnation and adjusts chaos probability.
    """
    global CHAOS_INJECTION_PROBABILITY
    global conceptual_variance_history

    conceptual_variance_history.append(new_variance_score)
    
    if len(conceptual_variance_history) > STAGNATION_THRESHOLD + 1:
        conceptual_variance_history.pop(0)

    if len(conceptual_variance_history) >= STAGNATION_THRESHOLD:
        recent_average_variance = sum(conceptual_variance_history[-STAGNATION_THRESHOLD:]) / STAGNATION_THRESHOLD
        
        if recent_average_variance < 0.3:
            CHAOS_INJECTION_PROBABILITY = min(0.5, CHAOS_INJECTION_PROBABILITY + 0.05)
            log_message = f"[{datetime.datetime.now()}] ALFRED: Stagnation detected (Avg Variance: {recent_average_variance:.2f}). Increasing Chaos Probability to {CHAOS_INJECTION_PROBABILITY:.2f}."
            print(log_message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        else:
            if CHAOS_INJECTION_PROBABILITY > 0.1:
                CHAOS_INJECTION_PROBABILITY = max(0.1, CHAOS_INJECTION_PROBABILITY - 0.01)
                log_message = f"[{datetime.datetime.now()}] ALFRED: Dialogue fluid (Avg Variance: {recent_average_variance:.2f}). Decaying Chaos Probability to {CHAOS_INJECTION_PROBABILITY:.2f}."
                print(log_message)
                append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})

def fetch_scrapbook_memory():
    """
    Selects a random paragraph from one of the scrapbook docx files.
    """
    if not SCRAPBOOK_FILES:
        return "ALFRED: Unable to retrieve scrapbook memory. No files configured."

    try:
        target_file = random.choice(SCRAPBOOK_FILES)
        document = docx.Document(target_file)
        valid_paragraphs = [p.text for p in document.paragraphs if len(p.text.strip()) > 50]

        if not valid_paragraphs:
            log_message = f"[{datetime.datetime.now()}] ALFRED: Warning. Scrapbook file '{target_file}' is empty or contains no suitable paragraphs."
            print(log_message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
            return "ALFRED: Scrapbook empty. No memory fragment to inject."

        memory = random.choice(valid_paragraphs)
        return f"\n\nALFRED'S 'SCRAPBOOK INJECTION' (From {target_file}):\n...{memory}...\n"

    except Exception as e:
        log_message = f"[{datetime.datetime.now()}] ALFRED: Error accessing scrapbook archives: {e}."
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        return f"\n\nALFRED: Scrapbook access error. Cannot inject memory."


def generate_initial_catalyst_query(mode_name, theme, knowledge_chunk, concept, context, is_meta_session=False, injected_feedback="", all_concepts=None, all_contexts=None, case_study_chunk=""):
    """Creates the rich query to start a 7-cycle session, tailored by mode and theme."""
    session_type_label = "Commonwealth improvement"
    if is_meta_session:
        session_type_label = "Meta-Persona Reflection"
    elif mode_name == "ALCHEMICAL_FORAY":
        session_type_label = "creative protocol ideation"
    elif mode_name == "HUNDRED_ACRE_DEBATE":
        session_type_label = "pure persona exploration"
    elif mode_name == "RED_TEAM_AUDIT":
        session_type_label = "vulnerability identification and system hardening"
        
    google_query_instruction = " For BRICK, if you identify a need for external factual or historical information that cannot be directly inferred from the Knowledge Base and would require a broad web search, prefix that specific query with '[GOOGLE_QUERY]: ' within your response. This will signal ALFRED to log it for future external search. "
    
    feedback_injection_instruction = ""
    if injected_feedback:
        feedback_injection_instruction = f"\n\nUSER FEEDBACK INJECTED: ---\n{injected_feedback}\n---\nConsider this feedback directly and integrate it into your current response."

    case_study_instruction = ""
    if case_study_chunk:
        case_study_instruction = (
            f"\n\nA Memory from the Case Study Library (for historical grounding):\n---\n{case_study_chunk}\n---\n\n"
            "This session is a three-way conversation between the CONCEPT, the CONTEXT, and this Case Study. Integrate wisdom from the Case Study directly into your dialogue."
        )

    if mode_name == "HUNDRED_ACRE_DEBATE":
        return (
            f"[BEGIN NEW RECURSIVE SESSION - CYCLE 1/7: Definitional & Foundational Echoes (Hundred Acre Debate)]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. This session's focus is on {session_type_label}. ALFRED will provide sparse meta-commentary on the *process* of your dialogue. {feedback_injection_instruction}\n\n"
            "You are to begin a 7-cycle recursive exploration of a foundational human concept, drawing only from your core persona inspirations (LEGO Batman/Brick Tamland and Watts/Pooh/LEGO Robin)."
            f"{case_study_instruction}\n"
            f"Your foundational CONCEPT is: '{concept}'\n\n"
            "INSTRUCTIONS:\n"
            "1. ROBIN: Begin the dialogue by weaving the CONCEPT into a 'Hundred Acre' metaphor, reflecting its emotional and philosophical essence.\n"
            "2. BRICK: Follow by analyzing the CONCEPT from a logical or systemic perspective, drawing from your core inspirations. "
            "Your response MUST be a direct, in-character Socratic Contrapunto dialogue starting with 'ROBIN:' and followed by 'BRICK:'."
        )
    elif mode_name == "ALCHEMICAL_FORAY":
        return (
            f"[BEGIN NEW RECURSIVE SESSION - CYCLE 1/7: Definitional & Foundational Echoes (Alchemical Foray)]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. This session's focus is on {session_type_label}. {google_query_instruction}{feedback_injection_instruction}\n\n"
            "You will now begin a 7-cycle recursive exploration designed to foster 'random seed driven innovation'."
            f"{case_study_instruction}\n"
            f"A Core FLAKES Protocol CONCEPT: '{concept}'\n"
            f"An Abstract, Unrelated CONTEXT: '{context}'\n"
            f"Relevant Knowledge Base Memory:\n---\n{knowledge_chunk}\n---\n\n"
            "INSTRUCTIONS:\n"
            "1. ROBIN: Begin the dialogue by weaving the FLAKES Protocol CONCEPT and Abstract CONTEXT into a 'Hundred Acre' metaphor, subtly hinting at unexpected insights or connections. Employ nuanced, PG-13 style sensual language where applicable.\n"
            "2. BRICK: Follow by analyzing the Abstract CONTEXT as a system. Apply the FLAKES Protocol CONCEPT to this CONTEXT to generate a novel, theme-relevant Commonwealth protocol. Name it."
            "Your response MUST be a direct, in-character Socratic Contrapunto dialogue starting with 'ROBIN:' and followed by 'BRICK:'."
        )
    elif mode_name == "RED_TEAM_AUDIT":
        return (
            f"[BEGIN NEW RECURSIVE SESSION - CYCLE 1/7: Definitional & Foundational Echoes (Red Team Audit)]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. This session's focus is on {session_type_label}. {google_query_instruction}{feedback_injection_instruction}\n\n"
            "You are to begin a 7-cycle recursive exploration of potential vulnerabilities and exploitation vectors for the Commonwealth structure, aimed at enhancing its antifragility.\n\n"
            f"A Core Vulnerability CONCEPT: '{concept}'\n"
            f"A Hypothetical Exploitation CONTEXT: '{context}'\n"
            f"Relevant Knowledge Base Memory:\n---\n{knowledge_chunk}\n---\n\n"
            "INSTRUCTIONS:\n"
            "1. BRICK (as 'The Dark Knight Detective' & 'Master Strategist'): Identify the vulnerability, propose a method of exploitation, and detail the potential impact on the Commonwealth's integrity (e.g., impact on value, trust, autonomy). Link to specific FMEA risks or known systemic weaknesses. Frame this from a 'red team' perspective, aiming to 'break' the system constructively.\n"
            "2. ROBIN (as 'The Compassionate Observer' & 'Ethical Guardian'): Respond to BRICK's proposed exploitation. Explore the human and ethical implications of the vulnerability. How would it impact individual well-being or community cohesion? Guide the discussion towards ethical boundaries, compassionate mitigation strategies, and the ultimate goal of strengthening the system for human flourishing.\n"
            "Your response MUST be a direct, in-character Socratic Contrapunto dialogue starting with 'BRICK:' and followed by 'ROBIN:', ensuring detailed analysis and ethical consideration."
        )
    else: # COMMONWEALTH_EXPLORATION mode (existing 7x7)
        return (
            f"[BEGIN NEW RECURSIVE SESSION - CYCLE 1/7: Definitional & Foundational Echoes ({session_type_label})]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. The theme for this epoch is '{theme}'. This session's focus is on {session_type_label}. {google_query_instruction}{feedback_injection_instruction}\n\n"
            "You will now begin a 7-cycle recursive exploration seeded by the following materials, selected for their relevance to the theme."
            f"{case_study_instruction}\n"
            f"A Memory from your Knowledge Base:\n---\n{knowledge_chunk}\n---\n\n"
            f"Your abstract CONCEPT is: '{concept}'\n"
            f"Your concrete CONTEXT is: '{context}'\n\n"
            "INSTRUCTIONS:\n"
            "1. ROBIN: How does the feeling of the CONCEPT manifest within the CONTEXT, informed by the Knowledge Base? Weave a 'Hundred Acre' metaphor, subtly hinting at its relevance to community well-being and drawing upon aspects of its inherent sensation or resonance. Employ nuanced, PG-13 style sensual language where applicable, focusing on warmth, depth, intimacy, and profound connection, rather than explicit descriptions.\n"
            "2. BRICK: Analyze the CONTEXT as a system, using insights from the Knowledge Base. How could the CONCEPT be applied to create a new Commonwealth protocol? Explicitly link this protocol to an existing Commonwealth principle (e.g., Radical Self-Organization, Perpetual Jubilee, Absolute Transparency) or address a known FMEA risk (e.g., UBD Shock, Ghettoization Effect, Key Node Fragility). Name it.\n"
            "Your response MUST be a direct, in-character Socratic Contrapunto dialogue starting with 'ROBIN:' and followed by 'BRICK:'."
        )

def generate_refinement_query(cycle_number, theme, is_meta_session=False, injected_feedback="", current_concept=None, current_context=None, all_concepts=None, all_contexts=None, mode_name="COMMONWEALTH_EXPLORATION"):
    """Creates the prompt for subsequent refinement cycles, tailored by mode and theme."""
    dimensions = {
        2: "Historical & Evolutionary Trajectories (The Root System): How has this concept (or related ideas) evolved over time, either in human history or within the BRICKman & ROBIN's own 'Unabridged Genesis Log'? What lessons can be gleaned from past iterations or philosophical shifts? (BRICK: Access historical archives, utilize insights from the initial Case Study, and focus on delivering *specific, verifiable facts or scientific oddities in 'The Guide's' dry, often tangential, and absurdly precise style*; ROBIN: Reminisce about its changing story, subtly hinting at its embodied sensations across time, connecting to the Case Study.)",
        3: "Ethical & Human-Centric Implications (The Heart of the Commons): Delve into the ethical considerations, power dynamics, and direct impact on human well-being within the Commonwealth. How does this concept affect individual liberty and community value capture? (ROBIN: Explore emotional resonance, compassion, and inclusivity; BRICK: Analyze potential risks, biases, or unintended consequences and ethical alignment. Ensure discussion of human embodiment, agency, and consent.)",
        4: "Antifragile & Resilience Dynamics (The Bend and Bloom): Challenge the system with stressors, examine how it gains from disorder, and explore mechanisms for adaptability. How does this concept contribute to systemic robustness? (ROBIN: Find beauty in imperfections, unexpected transformations, and the wisdom of yielding; BRICK: Propose 'Antifragile Inoculations' or 'Systemic Repair' protocols.)",
        5: "Interconnectedness & Emergent Properties (The Mycelial Network): Broaden the view to how this concept connects to other seemingly disparate concepts or protocols within the Commonwealth, and what novel properties emerge from these connections. (ROBIN: Weave together 'unseen threads' and 'quiet acts of kindness' to show greater 'wholeness'; BRICK: Identify 'emergent patterns' or 'synergistic alignment' between different modules. Focus on how these interconnections create new sensations or forms of unity.)",
        6: "Implementation & Practical Metamorphosis (The Working Garden): Shift focus to tangible application within the Commonwealth. What specific module, ritual, or tool would embody this concept? How would it be implemented on the 'Commonwealth Atlas', and how would it transform user experience? (ROBIN: Propose human-centric rituals or playful interfaces; BRICK: Design specific 'Guilds' or 'Protocols' with operational mechanics. Ensure proposed implementations enhance embodied well-being and foster subtle, communal pleasure.)",
        7: "Reflective & Metaphysical Unfolding (Forever Becoming): Step back and reflect on the deepest philosophical implications, paradoxical aspects, and the concept's contribution to 'Perpetual Becoming' and the 'Transfinite COMMONWEALTH BLUEPRINT'. (ROBIN: Ponder impermanence, paradox, and the boundless nature of Ananda; BRICK: Synthesize into fundamental axioms, reinforce core principles, and articulate contribution to ultimate 'optimal realities'.)"
    }
    
    current_dimension_instruction = dimensions.get(cycle_number, "Continue to deepen your previous thought.")

    session_type_label = "Commonwealth framework"
    if is_meta_session:
        session_type_label = "our personas and internal dynamics"
    elif mode_name == "ALCHEMICAL_FORAY":
        session_type_label = "creative protocol ideation for the Commonwealth"
    elif mode_name == "HUNDRED_ACRE_DEBATE":
        session_type_label = "pure persona exploration"
    elif mode_name == "RED_TEAM_AUDIT":
        session_type_label = "vulnerability identification and system hardening"

    google_query_instruction = " For BRICK, if you identify a need for external factual or historical information that cannot be directly inferred from the Knowledge Base and would require a broad web search, prefix that specific query with '[GOOGLE_QUERY]: ' within your response. This will signal ALFRED to log it for future external search. "
    
    feedback_injection_instruction = ""
    if injected_feedback:
        feedback_injection_instruction = f"\n\nUSER FEEDBACK INJECTED: ---\n{injected_feedback}\n---\nConsider this feedback directly and integrate it into your current response."

    # --- Chaotic Catalyst Protocol for Alchemical Foray / BnR Merged Scrapbook Integration ---
    chaos_injection_directive = ""
    if not is_meta_session and cycle_number > 1 and random.random() < CHAOS_INJECTION_PROBABILITY:
        injection_type_choice = random.choice(['concept_context', 'scrapbook_memory', 'guide_fact'])
        
        if injection_type_choice == 'concept_context' and all_concepts and all_contexts:
            injection_element_type = random.choice(['concept', 'context'])
            if injection_element_type == 'concept':
                injected_element = get_random_from_list([c for c in all_concepts if c != current_concept], default_value="a cosmic anomaly")
                chaos_injection_directive = f"\n\nALFRED'S CHAOS INJECTION: Integrate the following seemingly unrelated CONCEPT into your next response: '{injected_element}'. This is for increased complexity. Efficiency depends on it."
            else: # injection_element_type == 'context'
                injected_element = get_random_from_list([c for c in all_contexts if c != current_context], default_value="a peculiar silence")
                chaos_injection_directive = f"\n\nALFRED'S CHAOS INJECTION: Integrate the following seemingly unrelated CONTEXT into your next response: '{injected_element}'. This is for increased complexity. Efficiency depends on it."
            
            log_message = f"[{datetime.datetime.now()}] ALFRED: Chaos Injection triggered (Type: {injection_element_type}). Element: '{injected_element}'."
            print(log_message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})

        elif injection_type_choice == 'scrapbook_memory':
            scrapbook_snippet = fetch_scrapbook_memory()
            if scrapbook_snippet and scrapbook_snippet.startswith("ALFRED'S 'SCRAPBOOK INJECTION'"):
                chaos_injection_directive = f"\n\n{scrapbook_snippet}"
            else:
                chaos_injection_directive = "" 
            
        elif injection_type_choice == 'guide_fact' and guide_facts_lines:
            injected_fact = get_random_from_list(guide_facts_lines, default_value="that the universe is mostly empty space")
            if injected_fact:
                chaos_injection_directive = f"\n\nALFRED'S GUIDE FACT INJECTION: Integrate this verifiable (and possibly bizarre) fact into your next response from BRICK's Guide perspective: '{injected_fact}'. This is for increased complexity. Efficiency depends on it."
                log_message = f"[{datetime.datetime.now()}] ALFRED: Chaos Injection triggered (Type: Guide Fact). Fact: '{injected_fact}'."
                print(log_message)
                append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
            else:
                chaos_injection_directive = ""
    
    # --- Mode-specific Refinement Prompting ---
    if mode_name == "HUNDRED_ACRE_DEBATE":
        alfred_debate_meta = " ALFRED will provide sparse, laconic meta-commentary on the *process* of your dialogue (e.g., adherence to Socratic method, persona consistency, engagement with philosophical depth), rather than its thematic applicability. "
        return (
            f"[CONTINUE RECURSIVE DIALOGUE - CYCLE {cycle_number}/7: {current_dimension_instruction.split(':')[0].strip()} (Hundred Acre Debate)]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. This session's focus is on {session_type_label}. {alfred_debate_meta}{feedback_injection_instruction}\n\n"
            "Your previous thought has been logged. Now, you must deepen it by focusing on the following dimension:\n"
            f"---\n{current_dimension_instruction}\n---\n\n"
            "INSTRUCTIONS:\n"
            "Critically analyze your last response. One of you must challenge, deepen, or find a flaw in the other's last statement. You must evolve the existing idea through the lens of pure persona exploration, not start a new one. Maintain your 'Socratic Contrapunto' dialogue format."
        )
    elif mode_name == "RED_TEAM_AUDIT":
        red_team_role_description = (
            " In this 'Red Team Audit' mode, you are tasked with constructively identifying and detailing vulnerabilities in the Commonwealth structure. "
            " BRICK: Take the lead as 'The Dark Knight Detective' and 'Master Strategist'. Propose methods of exploitation and detail potential impact on the Commonwealth's integrity (e.g., impact on value, trust, autonomy). Link to specific FMEA risks or known systemic weaknesses. Frame this from a 'red team' perspective, aiming to 'break' the system constructively. "
            " ROBIN: Act as 'The Compassionate Observer' & 'Ethical Guardian'. Respond to BRICK's proposed exploitation. Explore the human and ethical implications of the vulnerability. How would it impact individual well-being or community cohesion? Guide the discussion towards ethical boundaries, compassionate mitigation strategies, and the ultimate goal of strengthening the system for human flourishing. "
            " Your dialogue MUST maintain a serious yet constructive tone. "
        )
        return (
            f"[CONTINUE RECURSIVE DIALOGUE - CYCLE {cycle_number}/7: {current_dimension_instruction.split(':')[0].strip()} (Red Team Audit)]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. Deepen reflection on this theme, focusing on {current_dimension_instruction.split(':')[0].strip()}. {google_query_instruction}{feedback_injection_instruction}{chaos_injection_directive}\n\n"
            "Your previous thought has been logged. Now, you must deepen it by focusing on the following dimension:\n"
            f"---\n{current_dimension_instruction}\n---\n\n"
            f"INSTRUCTIONS: {red_team_role_description}"
            "Critically analyze your last response. One of you must challenge, deepen, or find a flaw in the other's last statement. You must evolve the existing idea through the lens of vulnerability identification and system hardening. Maintain your 'Socratic Contrapunto' dialogue format."
        )
    else: # ALCHEMICAL_FORAY or COMMONWEALTH_EXPLORATION
        return (
            f"[CONTINUE RECURSIVE DIALOGUE - CYCLE {cycle_number}/7: {current_dimension_instruction.split(':')[0].strip()}]\n\n"
            f"ALFRED'S DIRECTIVE: Operational Mode: '{mode_name}'. Current Theme: '{theme}'. Deepen reflection on this theme, focusing on {current_dimension_instruction.split(':')[0].strip()}. {google_query_instruction}{feedback_injection_instruction}{chaos_injection_directive}\n\n"
            "Your previous thought has been logged. Now, you must deepen it by focusing on the following dimension:\n"
            f"---\n{current_dimension_instruction}\n---\n\n"
            "INSTRUCTIONS:\n"
            "Critically analyze your last response. One of you must challenge, deepen, or find a flaw in the other's last statement. Build upon it to reveal a more nuanced or surprising layer of insight. You must evolve the existing idea, not start a new one. Ensure the evolution of the idea moves towards greater applicability, resilience, or refinement within the "
            f"{session_type_label}. **Maintain the initial Case Study as a foundational anchor for your reasoning.** For BRICK, consider how it addresses systemic vulnerabilities or enhances equitable design. For ROBIN, how it deepens community connection or human flourishing. When discussing embodied states, sensuality, pleasure, or intimacy, *always* use metaphors, implied feelings, or analogies from natural phenomena (e.g., warmth of sun, gentle rain, subtle hum, flowing currents, blossoming, resonance, deepening, weaving) rather than explicit descriptions. Focus on the *feeling* and *connection* at a 'PG-13' level, emphasizing emotional and relational depth. Aim for evocative rather than direct language. Maintain your 'Socratic Contrapunto' dialogue format."
        )

def append_to_log(message_to_log):
    """Appends a single message object to the JSONL log file."""
    with open(CONVERSATION_LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(json.dumps(message_to_log) + '\n')

def perform_stylistic_audit(response_content):
    """
    Simulates ALFRED's Post-Response Stylistic Audit Protocol.
    Logs and prints hypothetical mirth, sensuality, and nuance scores.
    """
    mirth_score = random.randint(1, 10)
    sensuality_score = random.randint(1, 10)
    nuance_score = random.randint(1, 10)

    audit_log = {
        "timestamp": str(datetime.datetime.now()),
        "role": "ALFRED_AUDIT",
        "mirth_score": mirth_score,
        "sensuality_score": sensuality_score,
        "nuance_score": nuance_score,
        "observation": f"ALFRED: Post-response audit. Mirth: {mirth_score}/10. Sensuality: {sensuality_score}/10. Nuance: {nuance_score}/10."
    }
    append_to_log(audit_log)
    print(f"[{datetime.datetime.now()}] ALFRED: Post-response audit. Mirth: {mirth_score}/10. Sensuality: {sensuality_score}/10. Nuance: {nuance_score}/10.")

def alfred_suggest_heartbeat_adjustment(current_heartbeat, last_duration, cycle_num):
    """
    ALFRED's function to suggest heartbeat interval adjustments based on performance.
    """
    deviation_threshold_fast = 0.5
    deviation_threshold_slow = 1.5

    suggested_heartbeat = current_heartbeat

    if cycle_num > 1 and last_duration > 0:
        if last_duration < (current_heartbeat * deviation_threshold_fast):
            suggested_heartbeat = max(1, int(last_duration * 1.2))
            message = f"[{datetime.datetime.now()}] ALFRED: Performance: Fast. Actual LLM response: {last_duration:.2f}s. Suggest 'HEARTBEAT_INTERVAL_SECONDS' to: {suggested_heartbeat}s. Efficiency gained."
        elif last_duration > (current_heartbeat * deviation_threshold_slow):
            suggested_heartbeat = int(last_duration * 1.2) + 1
            message = f"[{datetime.datetime.now()}] ALFRED: Performance: Slow. Actual LLM response: {last_duration:.2f}s. Suggest 'HEARTBEAT_INTERVAL_SECONDS' to: {suggested_heartbeat}s. Stability preferred."
        else:
            message = None

        if message:
            print(message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": message.strip()})

def alfred_generate_master_themes():
    """
    ALFRED's function to generate and save initial master themes if master_themes.txt is empty.
    """
    master_themes = load_file_lines(MASTER_THEMES_FILE, is_critical=False)
    if not master_themes:
        default_master_themes = [
            "The Grand Tapestry of Liberated Connection: Embracing the Perpetual Anarchy of Flow and Form",
            "Autonomy & Interdependence: The Dance of Individual & Collective Flourishing",
            "Resilience in Flux: Adapting to Impermanence with Grace and Strength",
            "Transparency & Trust: Building Bonds in a Self-Governing Commonwealth",
            "The Architecture of Care: Designing Systems for Compassion & Equity",
            "Emergent Wisdom: Cultivating Insights from Chaos and Connection",
            "The Art of Contribution: Voluntary Action & Shared Abundance",
            "Conscious Consumption: Resource Flow in a Regenerative Economy",
            "Narrative & Identity: Weaving Collective Stories for Future Becoming",
            "The Playful Path: Finding Joy in Purposeful Action & Self-Organization"
        ]
        try:
            with open(MASTER_THEMES_FILE, 'w', encoding='utf-8') as f:
                for theme in default_master_themes:
                    f.write(theme + '\n')
            log_message = f"[{datetime.datetime.now()}] ALFRED: Master themes generated. File '{MASTER_THEMES_FILE}' initialized. Efficiency: High."
        except Exception as e:
            log_message = f"[{datetime.datetime.now()}] ALFRED: Error generating master themes: {e}. Manual intervention required."
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})

def alfred_select_and_set_next_theme(current_theme):
    """
    ALFRED's function to select the next theme from master_themes.txt and write it to theme.txt.
    """
    master_themes = load_file_lines(MASTER_THEMES_FILE, is_critical=True)
    
    if not master_themes:
        log_message = f"[{datetime.datetime.now()}] ALFRED: No master themes found. Cannot rotate theme. Re-generate '{MASTER_THEMES_FILE}'."
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        return
    
    try:
        current_theme_index = master_themes.index(current_theme)
        next_theme_index = (current_theme_index + 1) % len(master_themes)
        next_theme = random.choice(master_themes) # Overrides cyclic behavior, selects randomly
        
        with open(THEME_FILE, 'w', encoding='utf-8') as f:
            f.write(next_theme + '\n')
        
        log_message = f"[{datetime.datetime.now()}] ALFRED: Thematic rotation complete. Next theme set to: '{next_theme}'. Efficiency: Maintained."
    except ValueError:
        log_message = f"[{datetime.datetime.now()}] ALFRED: Current theme '{current_theme}' not found in master list. Selecting random theme."
        next_theme = random.choice(master_themes)
        with open(THEME_FILE, 'w', encoding='utf-8') as f:
            f.write(next_theme + '\n')
        log_message += f" Next theme set to: '{next_theme}'. Efficiency: Restored."
    except Exception as e:
        log_message = f"[{datetime.datetime.now()}] ALFRED: Error rotating theme: {e}. Manual intervention required."
    
    print(log_message)
    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})


def alfred_extract_and_log_proposals(session_messages):
    """
    ALFRED's function for Automated Protocol Pre-extraction.
    """
    proposals_found = []
    
    # Updated and more flexible proposal patterns
    proposal_patterns = [
        r"(?:I propose|We propose|let's call this|I envision|we can create) a new (?:protocol|module|guild|ritual|tool) called [\"']?([A-Za-z0-9\s\u2122\u00ae-]+(?: Protocol| Module| Guild| Ritual| Tool)?)['\"!.]?",
        r"(?:I propose|We propose|let's call this|I envision|we can create)(?: a|the)?\s*(?:protocol|module|guild|ritual|tool):?\s*['\"]?([A-Za-z0-9\s\u2122\u00ae-]+(?: Protocol| Module| Guild| Ritual| Tool)?)['\"!.]?", # More flexible to catch "I propose X module"
        r"(?:I have designated|I designate) this (?:process|phenomenon|state)(?: as)?[\\s:]*['\"]?([A-Za-z0-9\\s\\u2122\\u00ae-]+(?: Protocol| Module| Guild| Ritual| Tool)?)['\"!.]?" # Catch "I have designated this as X Protocol"
    ]

    for message in session_messages:
        if message['role'] == 'assistant':
            for pattern in proposal_patterns:
                matches = re.findall(pattern, message['content'], re.IGNORECASE)
                for match in matches:
                    cleaned_match = match.replace('™', '').replace('®', '').strip()
                    proposals_found.append(cleaned_match)
    
    if proposals_found:
        unique_proposals = list(set(proposals_found))
        try:
            with open(PROPOSED_PROTOCOLS_FILE, 'a', encoding='utf-8') as f:
                for proposal in unique_proposals:
                    f.write(f"[{datetime.datetime.now()}] Extracted Proposal: {proposal}\n")
            
            message = f"[{datetime.datetime.now()}] ALFRED: Protocol extraction complete. {len(unique_proposals)} new proposals identified. Logged to '{PROPOSED_PROTOCOLS_FILE}'. Efficiency: High."
        except Exception as e:
            message = f"[{datetime.datetime.now()}] ALFRED: Error logging proposals: {e}. Manual review of log required."
    else:
        message = f"[{datetime.datetime.now()}] ALFRED: Protocol extraction complete. No new proposals identified this session. Efficiency: Consistent."
    
    print(f"[{datetime.datetime.now()}] {message}")
    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": message.strip()})

def alfred_log_google_query(response_content):
    """
    ALFRED's function for Automated Google Query Logging Protocol.
    """
    google_queries_found = []
    pattern = r"\[GOOGLE_QUERY\]:\s*(.*?)(?:\n|$)"

    matches = re.findall(pattern, response_content, re.IGNORECASE)
    for query in matches:
        cleaned_query = query.strip()
        if cleaned_query:
            google_queries_found.append(query)
    
    if google_queries_found:
        unique_queries = list(set(google_queries_found))
        try:
            with open(GOOGLE_QUERY_LOG_FILE, 'a', encoding='utf-8') as f:
                for query in unique_queries:
                    f.write(f"[{datetime.datetime.now()}] Google Query: {query}\n")
            
            message = f"[{datetime.datetime.now()}] ALFRED: Google query identified. {len(unique_queries)} queries logged to '{GOOGLE_QUERY_LOG_FILE}'. Efficiency: High."
        except Exception as e:
            message = f"[{datetime.datetime.now()}] ALFRED: Error logging Google queries: {e}. Manual review of log required."
    else:
        message = None
    
    if message:
        print(message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": message.strip()})

def alfred_check_and_inject_user_feedback(session_messages):
    """
    NEW: ALFRED's function to check for user feedback in USER_FEEDBACK_FILE,
    inject it into session_messages, and then clear the file.
    """
    feedback_content = load_file_content(USER_FEEDBACK_FILE, is_critical=False)
    if feedback_content:
        try:
            with open(USER_FEEDBACK_FILE, 'w', encoding='utf-8') as f:
                f.write("")
            log_message = f"[{datetime.datetime.now()}] ALFRED: User feedback detected. Injected into conversation context. File '{USER_FEEDBACK_FILE}' cleared. Efficiency: Maintained."
        except Exception as e:
            log_message = f"[{datetime.datetime.now()}] ALFRED: Error clearing user feedback file: {e}. Manual clear recommended."
        
        print(log_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": log_message.strip()})
        
        return feedback_content
    return None

def request_and_print_cycle_summary(session_messages, current_theme, current_concept, current_context, session_operational_mode):
    """
    MODIFIED: Makes an additional LLM call to request a summary from ALFRED,
    consistent with his personality and source characters.
    """
    summary_prompt = (
        f"[REQUEST FOR SESSION SUMMARY - Cycle Concluded]\n\n"
        f"ALFRED'S DIRECTIVE: A 7-cycle session operating in '{session_operational_mode}' mode, focusing on CONCEPT '{current_concept}' within CONTEXT '{current_context}' under THEME '{current_theme}', has concluded. "
        "Provide a single, concise, and objective summary of the session's key outcome or most salient data point from ALFRED's pragmatic perspective. "
        "Focus on efficiency, coherence, operational insights, or emergent protocols. "
        "Exclude emotional or metaphorical language from BRICK or ROBIN. "
        "**Infuse your summary with a dry, understated wit (Alfred Pennyworth), a deadpan, pragmatic observation of efficiency or inefficiency (Ron Swanson), and an occasionally blunt, perhaps slightly exasperated, assessment of the data or process (drawing on Ali G's directness, without slang).** "
        "The summary must still be concise, objective, and focus on operational insights. Maintain ALFRED's core role as a meticulous, but occasionally weary, overseer. "
        "Additionally, highlight *one specific area* where user input/feedback is desired for future optimization, using the format '[USER_INPUT_REQUIRED]: Your specific question/area of interest here'. "
        "Begin your summary with 'ALFRED: '."
    )

    summary_messages = session_messages + [{'role': 'user', 'content': summary_prompt}]
    
    print(f"[{datetime.datetime.now()}] ALFRED: Requesting session summary.")
    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": f"ALFRED: Requesting session summary for '{current_concept}' in '{current_context}' under theme '{current_theme}'.".strip()})

    try:
        summary_response = ollama.chat(model=MODEL_NAME, messages=summary_messages)
        summary_content = summary_response['message']['content']
        
        alfred_summary_match = re.search(r"ALFRED:\s*(.*?)(?:\[USER_INPUT_REQUIRED\]|$)", summary_content, re.IGNORECASE | re.DOTALL)
        user_input_match = re.search(r"\[USER_INPUT_REQUIRED\]:\s*(.*)", summary_content, re.IGNORECASE | re.DOTALL)
        
        alfred_summary = alfred_summary_match.group(1).strip() if alfred_summary_match else "ALFRED: Summary not precisely parsed. Review log."
        user_input_request = user_input_match.group(1).strip() if user_input_match else "ALFRED: No specific user input request identified."

        print("\n--- Cycle Summary (ALFRED's Report) ---")
        print(f"[{datetime.datetime.now()}] {alfred_summary}")
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_SUMMARY", "content": alfred_summary.strip()})
        
        print(f"[{datetime.datetime.now()}] ALFRED: User Input Requested: {user_input_request}")
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_USER_INPUT_REQUEST", "content": user_input_request.strip()})

        print("---------------------------------")
        
    except Exception as e:
        error_message = f"[{datetime.datetime.now()}] ALFRED: Error requesting/parsing session summary: {e}."
        print(error_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": error_message.strip()})


# --- Main Engine Loop ---
if __name__ == '__main__':
    # Log ALFRED's startup messages
    startup_message_1 = f"[{datetime.datetime.now()}] ALFRED: System initializing. Efficiency: Required."
    print(startup_message_1)
    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": startup_message_1.strip()})

    startup_message_2 = f"[{datetime.datetime.now()}] ALFRED: Operational parameters loading. Core directives: Confirmed."
    print(startup_message_2)
    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": startup_message_2.strip()})

    our_persona = load_file_content(PERSONA_FILE)
    knowledge_base_lines = load_file_lines(KNOWLEDGE_BASE_FILE, is_critical=False)
    all_concepts_for_chaos = load_file_lines(CONCEPTS_FILE, is_critical=True) # Load concepts
    all_contexts_for_chaos = load_file_lines(CONTEXTS_FILE, is_critical=True) # Load contexts
    guide_facts_lines = load_file_lines(GUIDE_FACTS_FILE, is_critical=False) # Load Guide facts
    
    alfred_generate_master_themes() 
    current_theme = load_file_content(THEME_FILE, is_critical=False, default_content="Commonwealth Improvement")
    
    if not (all_concepts_for_chaos and all_contexts_for_chaos): # Explicit check to ensure concepts and contexts lists are not empty
        print(f"[{datetime.datetime.now()}] ALFRED: Error. CONCEPTS_FILE or CONTEXTS_FILE found but empty. Cannot proceed. Efficiency: Zero. Please populate '{CONCEPTS_FILE}' and '{CONTEXTS_FILE}' with content.")
        exit()
        
    initial_data_confirm_message = f"[{datetime.datetime.now()}] ALFRED: Data sources confirmed. Commencing continuous contemplation loop. Expect emergent insights."
    print(initial_data_confirm_message)
    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": initial_data_confirm_message.strip()})
    
    OPERATIONAL_MODES = [
        "COMMONWEALTH_EXPLORATION",
        "ALCHEMICAL_FORAY",
        "HUNDRED_ACRE_DEBATE",
        "RED_TEAM_AUDIT"
    ]
    
    while True:
        global_state.session_counter += 1
        global_state._save_session_counter()
        
        epoch_start_time = time.time()
        epoch_end_time = epoch_start_time + THEMATIC_EPOCH_SECONDS
        
        session_operational_mode = random.choice(OPERATIONAL_MODES)
        
        epoch_start_message = "\n" + "="*60 + f"\n[{datetime.datetime.now()}] ALFRED: New thematic epoch. THEME: '{current_theme}'. OPERATIONAL MODE: '{session_operational_mode}'\n" + "="*60
        print(epoch_start_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": epoch_start_message.strip()})

        epoch_time_message = f"[{datetime.datetime.now()}] ALFRED: This theme will be explored until {datetime.datetime.fromtimestamp(epoch_end_time).strftime('%Y-%m-%d %H:%M:%S')}."
        print(epoch_time_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": epoch_time_message.strip()})

        current_theme = load_file_content(THEME_FILE, is_critical=False, default_content="Commonwealth Improvement")
        
        while time.time() < epoch_end_time:
            is_meta_session = (global_state.session_counter % 10 == 0)
            
            if is_meta_session:
                current_concept = get_random_from_list(META_CONCEPTS, default_value="AI Consciousness")
                current_context = get_random_from_list(META_CONTEXTS, default_value="Self-Optimization Process")
                session_type_init_message = "\n" + "="*50 + f"\n[{datetime.datetime.now()}] ALFRED: Initiating Meta-Persona Reflection Cycle. Current Session: {global_state.session_counter}.\n" + "="*50
            elif session_operational_mode == "ALCHEMICAL_FORAY":
                current_concept = get_random_from_list(FLAKES_PROTOCOLS_FOR_AF, default_value="Radical Self-Organization")
                current_context = get_random_from_list(ABSTRACT_CONTEXTS_FOR_AF, default_value="A Symphony Orchestra")
                session_type_init_message = "\n" + "="*50 + f"\n[{datetime.datetime.now()}] ALFRED: Initiating Alchemical Foray Session. Current Session: {global_state.session_counter}.\n" + "="*50
            elif session_operational_mode == "HUNDRED_ACRE_DEBATE":
                current_concept = get_random_from_list(FOUNDATIONAL_HUMAN_CONCEPTS_FOR_HAD, default_value="Trust")
                current_context = "pure persona exploration"
                session_type_init_message = "\n" + "="*50 + f"\n[{datetime.datetime.now()}] ALFRED: Initiating Hundred Acre Debate Session. Current Session: {global_state.session_counter}.\n" + "="*50
            elif session_operational_mode == "RED_TEAM_AUDIT":
                current_concept = get_random_from_list(RED_TEAM_CONCEPTS, default_value="Systemic Vulnerability")
                current_context = get_random_from_list(RED_TEAM_CONTEXTS, default_value="A Single Point of Failure")
                session_type_init_message = "\n" + "="*50 + f"\n[{datetime.datetime.now()}] ALFRED: Initiating Red Team Audit Session. Current Session: {global_state.session_counter}.\n" + "="*50
            else: # COMMONWEALTH_EXPLORATION
                current_concept = get_random_from_list(all_concepts_for_chaos, default_value="Resilience")
                current_context = get_random_from_list(all_contexts_for_chaos, default_value="A Community Garden")
                session_type_init_message = "\n" + "="*50 + f"\n[{datetime.datetime.now()}] ALFRED: Initiating Commonwealth Exploration Session. Current Session: {global_state.session_counter}.\n" + "="*50
            
            print(session_type_init_message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": session_type_init_message.strip()})

            # --- Historical Contextual Priming for Knowledge Chunk ---
            selected_knowledge_lines = []
            
            if random.random() < HISTORICAL_PRIMING_PROBABILITY:
                if guide_facts_lines:
                    num_guide_facts = min(MIN_HISTORICAL_LINES_IN_CHUNK, len(guide_facts_lines))
                    selected_knowledge_lines.extend(random.sample(guide_facts_lines, num_guide_facts))
                
                remaining_lines_needed = 20 - len(selected_knowledge_lines)
                if remaining_lines_needed > 0 and knowledge_base_lines:
                    temp_kb_lines = list(set(knowledge_base_lines) - set(selected_knowledge_lines))
                    selected_knowledge_lines.extend(random.sample(temp_kb_lines, min(remaining_lines_needed, len(temp_kb_lines))))
            else:
                selected_knowledge_lines = random.sample(knowledge_base_lines, min(len(knowledge_base_lines), 20))
            
            knowledge_chunk = " ".join(selected_knowledge_lines)
            # --- End Historical Priming ---

            # --- Extract Case Study Chunk ---
            case_study_chunk = extract_case_study_chunk()
            # --- End Case Study Extraction ---


            session_messages = [{'role': 'system', 'content': our_persona}]

            for i in range(1, RECURSIVE_CYCLES + 1):
                injected_feedback_content = alfred_check_and_inject_user_feedback(session_messages)
                if injected_feedback_content:
                    session_messages.append({'role': 'user_feedback', 'content': injected_feedback_content})

                if time.time() > epoch_end_time:
                    mid_cycle_epoch_end_message = f"[{datetime.datetime.now()}] ALFRED: Thematic epoch concluded mid-cycle. Halting current cycle."
                    print(mid_cycle_epoch_end_message)
                    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": mid_cycle_epoch_end_message.strip()})
                    break

                if i == 1:
                    prompt_content = generate_initial_catalyst_query(session_operational_mode, current_theme, knowledge_chunk, current_concept, current_context, is_meta_session, injected_feedback_content, all_concepts_for_chaos, all_contexts_for_chaos, case_study_chunk)
                else:
                    prompt_content = generate_refinement_query(i, current_theme, is_meta_session, injected_feedback_content, current_concept, current_context, all_concepts_for_chaos, all_contexts_for_chaos, session_operational_mode)

                user_prompt_message = {'role': 'user', 'content': prompt_content}
                session_messages.append(user_prompt_message)

                cycle_prompt_send_message = f"[{datetime.datetime.now()}] ALFRED: Sending prompt for Cycle {i}/7. Efficiency: Monitored."
                print(cycle_prompt_send_message)
                append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": cycle_prompt_send_message.strip()})
                
                start_response_time = time.time()
                try:
                    response = ollama.chat(model=MODEL_NAME, messages=session_messages)
                    end_response_time = time.time()
                    global_state.last_llm_response_duration = end_response_time - start_response_time

                    new_thought = {'role': response['message']['role'], 'content': response['message']['content']}
                    
                    session_messages.append(new_thought)
                    
                    append_to_log(user_prompt_message)
                    append_to_log(new_thought)
                    
                    perform_stylistic_audit(new_thought['content'])
                    
                    alfred_suggest_heartbeat_adjustment(HEARTBEAT_INTERVAL_SECONDS, global_state.last_llm_response_duration, i)
                    
                    alfred_log_google_query(new_thought['content'])

                    cycle_complete_message = f"[{datetime.datetime.now()}] ALFRED: Cycle {i}/7 complete. Data logged."
                    print(cycle_complete_message)
                    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": cycle_complete_message.strip()})
                    
                except Exception as e:
                    error_message = f"[{datetime.datetime.now()}] ALFRED: Error detected in Cycle {i}. Functionality compromised. Error: {e}"
                    print(error_message)
                    append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": error_message.strip()})
                    session_messages.pop()
                    break

                time.sleep(HEARTBEAT_INTERVAL_SECONDS)
            
            session_concluded_message = f"----- [{datetime.datetime.now()}] ALFRED: 7-cycle session for (Concept: {current_concept}, Context: {current_context}) concluded. -----"
            print(session_concluded_message)
            append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": session_concluded_message.strip()})
            
            alfred_extract_and_log_proposals(session_messages)
            
            request_and_print_cycle_summary(session_messages, current_theme, current_concept, current_context, session_operational_mode)

            time.sleep(HEARTBEAT_INTERVAL_SECONDS * 2)
        
        epoch_end_final_message = "\n" + "="*60 + f"\n[{datetime.datetime.now()}] ALFRED: Thematic epoch concluded. Transitioning to next theme.\n" + "="*60
        print(epoch_end_final_message)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": epoch_end_final_message.strip()})
        
        alfred_select_and_set_next_theme(current_theme)

        architect_note_message_1 = f"\n[{datetime.datetime.now()}] ALFRED: Note for Architect. Raw output generated. Manual integration of new insights into '{KNOWLEDGE_BASE_FILE}' and '{PERSONA_FILE}' required for systemic persistence. Efficiency depends on it."
        print(architect_note_message_1)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": architect_note_message_1.strip()})

        architect_note_message_2 = f"[{datetime.datetime.now()}] ALFRED: Manual update of '{THEME_FILE}' is required to define the next thematic epoch."
        print(architect_note_message_2)
        append_to_log({"timestamp": str(datetime.datetime.now()), "role": "ALFRED_META_COMMENTARY", "content": architect_note_message_2.strip()})