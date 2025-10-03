# TELOS MASTER SYSTEM LAYOUT DOCUMENT
# ================================================================================================
# Version: 1.0 | Date: 2025-10-02 | Status: ACTIVE
# ================================================================================================
# This document defines the canonical directory structure and file organization for the TELOS
# neuro-symbolic operating system. All future development must adhere to this layout to maintain
# system coherence and enable efficient evolution.
# ================================================================================================

# ROOT DIRECTORY STRUCTURE
# ================================================================================================

EntropicGarden/                    # TELOS Project Root
├── .git/                         # Git repository (hidden)
├── .github/                      # GitHub configuration and workflows
├── .vscode/                      # VS Code workspace settings
├── docs/                         # Documentation and specifications
├── libs/                         # Core TELOS system libraries
├── scripts/                      # Automation and utility scripts
├── config/                       # Configuration files
├── tests/                        # Test suites and validation
├── build/                        # Build artifacts (gitignored)
├── temp/                         # Temporary files (gitignored)
├── backups/                      # Backup files and archives
├── archive/                      # Historical project artifacts
├── deps/                         # External dependencies
├── extras/                       # Supplementary tools and resources
├── eerie/                        # Eerie-specific components
├── addons/                       # Io addon extensions
├── .clang-format                 # Code formatting standards
├── .gitignore                    # Git ignore patterns
├── .gitattributes                # Git attributes
├── .gitmodules                   # Git submodules
├── CMakeLists.txt                # Root build configuration
├── README.md                     # Project overview and setup
├── LICENSE.txt                   # License information
├── CONTRIBUTING.md               # Contribution guidelines
├── requirements.txt              # Python dependencies
├── AutoPrompt.txt                # LLM control surface
├── run_log.md                    # Operational history
├── system_status.md              # System status tracking
└── run.sh                        # Primary execution script

# DIRECTORY PURPOSES AND ORGANIZATION PRINCIPLES
# ================================================================================================

## docs/ - Documentation and Specifications
# Purpose: Centralized knowledge base for TELOS architecture, protocols, and development
# Organization: Hierarchical by topic with clear naming conventions

docs/
├── architecture/                 # System architecture documents
│   ├── AI_Plan_Synthesis_Blueprint.txt
│   ├── Design_Protocol_Dynamic_Resolution.txt
│   ├── TELOS_Implementation_Addendum_1.3.txt
│   ├── Tiered_Cache_Design_Optimization.txt
│   ├── Extending_TELOS_Architecture_v1.4.txt
│   └── BUILD_SYSTEM_ARCHITECTURE.md
├── io/                          # Io language documentation
│   ├── IoGuide.html
│   ├── IoCodingStandards.html
│   ├── IoTutorial.html
│   ├── Io_Prototype_Programming_Training_Guide.txt
│   └── Io_Syntax_and_Best_Practices_Guide.md
├── protocols/                   # Operational protocols and workflows
│   ├── CYCLE_COMPLETION_WORKFLOW.md
│   ├── SYNTAX_TOOLKIT_README.md
│   └── ACTIVATION_README.md
└── api/                         # API documentation and references

## libs/Telos/ - Core System Libraries
# Purpose: Canonical implementation of TELOS neuro-symbolic architecture
# Organization: Language-separated with clear architectural boundaries

libs/Telos/
├── source/                      # C substrate (synaptic bridge ABI)
│   ├── synaptic_bridge.h        # Immutable C ABI contract
│   ├── synaptic_bridge.c        # Bridge implementation
│   ├── telos_core.h             # Core system headers
│   ├── telos_core.c             # Core system implementation
│   └── shared_memory.c          # Memory management
├── io/                          # Io cognitive core (prototypes)
│   ├── Concept.io               # Atomic knowledge unit prototype
│   ├── TelosBridge.io           # Synaptic bridge interface
│   ├── PrototypalLinter.io      # Code validation system
│   ├── FractalCognitionEngine.io # Cognitive processing
│   ├── SOARCognitiveArchitecture.io # SOAR implementation
│   └── HRCOrchestrator.io       # Human-Robot collaboration
├── python/                      # Python computational substrate
│   ├── telos_workers.py         # Worker process pool
│   ├── worker_handlers.py       # Task handlers
│   ├── uvm_object.py            # Prototypal emulation
│   ├── federated_memory.py      # Memory management
│   ├── llm_handlers.py          # LLM transduction
│   └── shared_memory_handlers.py # IPC management
└── tests/                       # Cross-language test harnesses
    ├── test_bridge_ping.io      # Bridge connectivity tests
    ├── test_synaptic_bridge.py  # Python bridge tests
    ├── test_concept_prototype.io # Io prototype tests
    └── validation_gauntlet/     # Comprehensive validation suite

## scripts/ - Automation and Utilities
# Purpose: Maintainable automation for development workflows
# Organization: Categorized by function with clear naming

scripts/
├── activation/                  # System activation scripts
│   ├── activate_fractal_cognition.io
│   ├── activate_llm_transduction.io
│   ├── activate_now.sh
│   └── simple_activation.io
├── build/                       # Build and compilation
│   ├── clean_and_build.io       # Canonical build process
│   ├── clean_test.io            # Test build process
│   └── LivingBuild.io           # Dynamic build system
├── test/                        # Testing automation
│   ├── fresh_test.io            # Clean test execution
│   ├── minimal_test.io          # Minimal test suite
│   └── eradicate_mocks.io       # Mock eradication
├── utils/                       # Utility scripts
│   ├── repo_audit.sh            # Repository compliance audit
│   ├── clean_repo.sh            # Repository cleanup
│   ├── syntax_checker.sh        # Syntax validation
│   ├── error_pattern_analyzer.sh # Error analysis
│   └── cycle_initiate.sh        # Cycle initialization
└── debug/                       # Debugging tools
    ├── debug_chaos.io           # Chaos engineering debug
    ├── debug_config.io          # Configuration debug
    └── debug_federated.io       # Memory debug

## config/ - Configuration Files
# Purpose: Centralized configuration management
# Organization: Environment-specific with clear separation

config/
├── otel_settings.json           # Observability configuration
├── default_config.json          # Default system settings
├── development.json             # Development environment
├── testing.json                 # Test environment
└── production.json              # Production environment

## tests/ - Test Suites and Validation
# Purpose: Comprehensive validation of system integrity
# Organization: Parallel to source structure

tests/
├── unit/                        # Unit tests
├── integration/                 # Integration tests
├── validation/                  # Architectural validation
├── performance/                 # Performance benchmarks
└── chaos/                       # Chaos engineering tests

## build/ - Build Artifacts (GITIGNORED)
# Purpose: Temporary build outputs
# Organization: CMake-generated structure

build/
├── CMakeCache.txt
├── CMakeFiles/
├── Makefile
├── compile_commands.json
├── libtelos_core.so
├── _build/
└── CTestTestfile.cmake

## temp/ - Temporary Files (GITIGNORED)
# Purpose: Scratch space for development
# Organization: Ad-hoc, cleaned regularly

temp/
├── debug_outputs/
├── test_artifacts/
└── scratch/

## backups/ - Backup Files and Archives
# Purpose: Historical preservation and recovery
# Organization: Dated and categorized

backups/
├── AutoPrompt_{date}_{purpose}.txt
├── system_status_{date}.md
├── run_log_{date}.md
└── code_snapshots/

## archive/ - Historical Project Artifacts
# Purpose: Long-term historical record
# Organization: Chronological by project phase

archive/
├── phase1_initial_design/
├── phase2_implementation/
├── phase3_validation/
└── future_phase_tests/

## deps/ - External Dependencies
# Purpose: Third-party libraries and tools
# Organization: Library-specific subdirectories

deps/
├── parson/                      # JSON parsing library
├── IoLanguageKit/               # Io language distribution
└── IoTest/                      # Io testing framework

## extras/ - Supplementary Tools and Resources
# Purpose: Supporting tools not core to TELOS
# Organization: Tool-specific organization

extras/
├── IoLanguageKit/               # Extended Io tools
├── IoTest/                      # Testing extensions
└── development_tools/

## eerie/ - Eerie-Specific Components
# Purpose: Eerie visualization system
# Organization: Eerie's internal structure

eerie/
├── base/                        # Core Eerie functionality
└── extensions/                  # Eerie extensions

## addons/ - Io Addon Extensions
# Purpose: Compiled Io extensions
# Organization: Addon-specific directories

addons/
├── TelosBridge/                 # Synaptic bridge addon
└── PrototypalLinter/            # Linting addon

# FILE NAMING CONVENTIONS
# ================================================================================================

## General Rules
- Use snake_case for multi-word filenames
- Use descriptive names that indicate purpose
- Include file type extensions (.io, .py, .c, .h, .md, .txt, .sh, .json)
- Avoid generic names like "test", "debug", "temp"

## Language-Specific Conventions
- **Io Files**: PascalCase for prototype names, descriptive suffixes (.io)
- **Python Files**: snake_case, descriptive module names (.py)
- **C Files**: snake_case, clear purpose indication (.c, .h)
- **Shell Scripts**: snake_case, action-oriented names (.sh)
- **Documentation**: Title_Case_With_Underscores (.md, .txt, .html)

## Version Control
- Use semantic versioning for releases
- Tag important commits with descriptive messages
- Maintain clean commit history
- Use feature branches for development

# MAINTENANCE PROTOCOLS
# ================================================================================================

## Regular Audits
- **Weekly**: Run `scripts/utils/repo_audit.sh` to check compliance
- **Monthly**: Review and clean `temp/` and `build/` directories
- **Quarterly**: Archive old backups and reorganize as needed

## Cleanup Procedures
- **Automated**: Use `scripts/utils/clean_repo.sh` for routine cleanup
- **Manual**: Review root directory for misplaced files
- **Archival**: Move completed projects to `archive/` with proper documentation

## Evolution Guidelines
- **Extensions**: Add new directories under appropriate parent categories
- **Modifications**: Update this document when structure changes
- **Deprecations**: Move deprecated structures to `archive/` with migration notes

# COMPLIANCE ENFORCEMENT
# ================================================================================================

## Automated Checking
- Repository audit scripts must pass before commits
- Pre-commit hooks enforce naming conventions
- CI/CD pipelines validate directory structure

## Manual Review
- Code reviews must check file placement
- Documentation updates required for structural changes
- Regular compliance audits by maintainers

## Consequences
- Non-compliant files block system builds
- Repository clutter prevents efficient development
- Structural violations require immediate correction

# FUTURE EVOLUTION PATTERNS
# ================================================================================================

## Scalability Considerations
- Horizontal scaling: Add service-specific subdirectories
- Vertical scaling: Deepen existing hierarchical structure
- Modular expansion: Create feature-specific library modules

## Integration Points
- External APIs: `libs/Telos/integrations/`
- Third-party tools: `extras/integrations/`
- Cross-project dependencies: `deps/shared/`

## Migration Strategies
- Gradual refactoring: Move files incrementally
- Compatibility layers: Maintain backward compatibility
- Documentation updates: Reflect structural changes immediately

# APPENDIX: CURRENT VIOLATIONS AND MIGRATION PLAN
# ================================================================================================

## Identified Issues
- Multiple temporary files in root directory
- Scattered debug and test artifacts
- Inconsistent backup file organization
- Build artifacts at root level

## Migration Priority
1. **HIGH**: Move all temp/debug/test files to appropriate directories
2. **MEDIUM**: Consolidate backup files into backups/ directory
3. **LOW**: Reorganize scripts into categorized subdirectories

## Implementation Timeline
- **Phase 1 (Immediate)**: Root directory cleanup
- **Phase 2 (Week 1)**: Script reorganization
- **Phase 3 (Month 1)**: Complete structural alignment

# ================================================================================================
# END OF MASTER SYSTEM LAYOUT DOCUMENT
# ================================================================================================