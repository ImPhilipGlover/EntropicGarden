# TelOS System File Catalog

This catalog provides a comprehensive overview of all files in the TelOS system, organized by directory with brief descriptions of their capabilities and purposes.

## Root Directory Files

### Core System Files
- **AutoPrompt.txt**: PID control loop for autonomous development guidance, containing objectives, insights, risks, and tool workflows
- **CMakeLists.txt**: CMake build configuration for polyglot compilation (Io, C, Python)
- **README.md**: System overview and usage instructions
- **requirements.txt**: Python dependencies for the system

### Development Workflow
- **clean_and_build.io**: Io-orchestrated build process with integrated tool validation
- **cycle_complete.sh**: Workflow completion script
- **run.sh**: System execution script
- **run_log.md**: Operational history and decisions
- **system_status.md**: Current system health and priorities

### Compliance and Safety
- **ACTIVATION_README.md**: System activation instructions
- **CONTRIBUTING.md**: Contribution guidelines
- **LICENSE.txt**: Software license
- **safety_exclude.txt**: Safety exclusions for validation

### Logs and Archives
- **run_log_archive.md**: Archived operational logs
- **system_status_archive.md**: Archived system status
- **linter_output.txt**: Linting results
- **syntax_validation_report.txt**: Syntax validation output

## scripts/ - Tool and Process Directory

### Build and Integration Tools
- **clean_and_build.io**: Orchestrates full build process with pre/post validations
- **eradicate_mocks.io**: Scans codebase for mock implementations to ensure purity
- **compliance_enforcer.py**: Enforces mandatory file preambles for compliance
- **io_syntax_checker.sh**: Validates Io code for best practices and syntax
- **PrototypalLinter.io**: C/C++ and Python syntax validation via synaptic bridge
- **io_addon_checker.io**: Critical bridge health verification tool

### Autopoietic Processes
- **io_driven_health_check.io**: Self-healing health monitoring and optimization
- **llm_code_suggestions.io**: Collaborative code improvement using TelOS AI
- **train_llm_on_source.io**: Runtime LLM training on source code
- **launch_telos_ai.io**: Background TelOS AI process launcher
- **cognitive_evolution_monitor.io**: Cognitive development tracking and architectural improvement suggestions

### Utility Scripts
- **activation/activate_fractal_cognition.io**: Activates fractal cognition engine
- **activation/activate_llm_transduction.io**: Activates LLM transduction pipeline
- **build/clean_and_build.io**: Alternative build orchestrator
- **build/LivingBuild.io**: Living build system implementation
- **test/clean_test.io**: Test cleanup script
- **test/fresh_test.io**: Fresh test execution
- **test/minimal_test.io**: Minimal test suite
- **utils/AdaptiveLearningLoop.io**: Adaptive learning algorithms
- **utils/AutopoieticSelfHealing.io**: Self-healing orchestration
- **utils/ChaosEngineeringInjector.io**: Chaos engineering for resilience testing
- **utils/compliance_enforcer.py**: Duplicate compliance tool
- **utils/EmergenceDetector.io**: Detects emergent behaviors
- **utils/llm_code_suggestions.io**: Duplicate code suggestion tool
- **utils/MemoryConsolidator.io**: Memory management optimization
- **utils/repository_organization.io**: Repository organization utilities
- **utils/RuntimeErrorAnalyzer.io**: Runtime error analysis
- **utils/SelfDiagnosticAnalyzer.io**: Self-diagnostic capabilities
- **utils/SimpleSyntaxChecker.io**: Basic syntax checking
- **utils/syntax_checker.py**: Python syntax validation
- **utils/TelosAddonChecker.io**: Duplicate addon checking

## libs/ - Core Libraries

### TelOS Core Library (libs/Telos/)
- **__init__.py**: Python package initialization
- **telos_workers.py**: Python worker processes for computation
- **uvm_object.py**: UvmObject base class for prototypal programming

#### io/ - Io Cognitive Core
- **TelosBridge.io**: Main synaptic bridge veneer for Io-C-Python communication
- **Concept.io**: Concept prototype for knowledge representation
- **FractalCognitionEngine.io**: Fractal cognition implementation
- **HRCOrchestrator.io**: Hierarchical Reasoning Chain orchestration
- **VSARAGFusion.io**: Vector Symbolic Architecture + RAG fusion
- **ValidationGauntlet.io**: Comprehensive system validation
- **TelosCompiler.io**: Io-based compilation orchestration
- **self_healing.io**: Self-healing processes
- **telos_ai.io**: TelOS AI implementation
- **Various test and utility files**: Testing and utility scripts

#### python/ - Python Computational Substrate
- **bridge_metrics_handlers.py**: Metrics collection for bridge operations
- **llm_handlers.py**: LLM interaction handlers
- **process_pool.py**: Process pool management
- **shared_memory.py**: Shared memory management
- **worker_*.py**: Worker lifecycle and utilities
- **zodb_*.py**: ZODB persistence handlers
- **federated_memory/**: Federated memory system components

#### source/ - C Synaptic Bridge
- **synaptic_bridge.c/h**: Core synaptic bridge implementation
- **IoTelosBridge.c/h**: Io addon interface
- **TelosProxyObject.c/h**: Proxy object handling

#### tests/ - Test Suites
- **test_*.io**: Io-based test files for various components
- **test_*.py**: Python test files
- **test_*.c**: C test files

### IoVM Library (libs/iovm/)
- **Core Io language implementation**: Interpreter, compiler, standard library
- **source/**: C source files for IoVM
- **io/**: Io standard library files
- **tests/**: IoVM test suites

### BaseKit Library (libs/basekit/)
- **Core utilities**: Collections, memory management, threading
- **source/**: C implementation
- **tests/**: Unit tests

## build/ - Build Artifacts

### CMake Build Directory
- **CMakeCache.txt**: CMake configuration cache
- **Makefile**: Generated build makefile
- **CTestTestfile.cmake**: Test configuration
- **_build/**: Intermediate build files
- **addons/TelosBridge/**: Built Io addon
- **libs/**: Built libraries

## docs/ - Documentation

### System Documentation
- **BUILD_SYSTEM_ARCHITECTURE.md**: Build system design
- **DEVELOPERS.md**: Developer guide
- **MODULARIZATION_PLAN.md**: System modularization strategy
- **TELOS_MASTER_SYSTEM_LAYOUT.md**: System architecture overview

### Io Language Documentation
- **IoGuide.html**: Io language guide
- **IoCodingStandards.html**: Coding standards
- **IoTutorial.html**: Io tutorial
- **Io_Syntax_and_Best_Practices_Guide.md**: Best practices guide

### Research and Design
- **AI_Plan_Synthesis_High_Resolution_Blueprint.txt**: AI system blueprint
- **Design_Protocol_for_Dynamic_System_Resolution.txt**: Design protocols
- **TELOS_Implementation_Addendum_1.3.txt**: Implementation details
- **Tiered_Cache_Design_and_Optimization.txt**: Cache design
- **Extending_TELOS_Architecture_v1.4_Proposal.txt**: Architecture extensions

### Specialized Documentation
- **Compositional_Gauntlet_Design.md**: Validation framework
- **Mathematical_Functions_For_Knowledge_Discovery.txt**: Mathematical foundations
- **Neuro-Symbolic_Reasoning_Cycle_Implementation_Plan.txt**: Reasoning implementation
- **Prototypal_Emulation_Layer_Design.txt**: Prototypal design
- **Building_TelOS_with_Io_and_Morphic.txt**: UI framework
- **Io_Morphic_UI_with_WSLg_SDL2.txt**: Morphic UI implementation

## temp/ - Temporary Files

### Development Scratch
- **test_*.io**: Temporary test files
- **debug_*.io**: Debug scripts
- **temp_*.io**: Temporary utilities

## archive/ - Archived Files

### Future Phase Tests
- **test_*.io**: Archived test implementations
- **test_*.py**: Archived Python tests

## extras/ - Additional Resources

### Io Language Extensions
- **IoLanguageKit/**: Additional Io utilities
- **IoTest/**: Testing framework
- **Symbian/**: Platform-specific code
- **SyntaxHighlighters/**: Editor syntax highlighting
- **win32vc2005/**: Windows build support

### Documentation and Examples
- **BAT_OS_DEVELOPMENT_SYNTHESIS.md**: Development synthesis
- **COMPLETE_VICTORY.md**: Milestone documentation
- **demonstrate_living_build.io**: Build demonstration
- **self_improvement_demo.io**: Self-improvement demo

## .github/ - GitHub Configuration

- **copilot-instructions.md**: AI assistant instructions and file catalog
- **ISSUE_TEMPLATE/**: Issue templates
- **workflows/**: GitHub Actions workflows

## config/ - Configuration Files

- **otel_settings.json**: OpenTelemetry configuration

## deps/ - Dependencies

- **parson/**: JSON parsing library

## eerie/ - Alternative Build Environment

- **base/addons/TelosBridge/**: Alternative addon build
- **base/libs/Telos/**: Alternative library build

## .vscode/ - Development Environment

- **settings.json**: VS Code configuration
- **extensions.json**: Recommended extensions

## FILE_CATALOG.md - This File

This comprehensive catalog enables rapid navigation and understanding of the TelOS system's capabilities, ensuring efficient autonomous development and maintenance.