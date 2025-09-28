# TELOS Test Suite CMakeLists.txt
# 
# This file configures the test suite for the TELOS system, including
# both Python tests and C/C++ unit tests when available.

cmake_minimum_required(VERSION 3.20)

# Find Python testing components
find_package(Python COMPONENTS Interpreter REQUIRED)

# Python test files
set(PYTHON_TEST_FILES
    "${CMAKE_CURRENT_SOURCE_DIR}/test_basic_architecture.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_synaptic_bridge.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_forward_message.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_phase2_federated_memory.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_federated_memory_promotions.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_transactional_outbox.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_zodb_manager.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_cache_coordinator_failures.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_l1_cache_manager.py"
    "${CMAKE_CURRENT_SOURCE_DIR}/test_l2_telemetry.py"
)

# Add Python tests
foreach(TEST_FILE ${PYTHON_TEST_FILES})
    if(EXISTS "${TEST_FILE}")
        get_filename_component(TEST_NAME "${TEST_FILE}" NAME_WE)
        set(py_test_env
            "PYTHONPATH=${CMAKE_CURRENT_SOURCE_DIR}/../Telos/python:$ENV{PYTHONPATH}"
            "TELOS_OTEL_SETTINGS_PATH=${TELOS_OTEL_SETTINGS_PATH}"
        )
        add_test(
            NAME "${TEST_NAME}"
            COMMAND ${Python_EXECUTABLE} "${TEST_FILE}"
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        )
        # Set PYTHONPATH to include our modules and expose telemetry config
        set_tests_properties("${TEST_NAME}" PROPERTIES
            ENVIRONMENT "${py_test_env}"
        )
    endif()
endforeach()

if(TARGET IoTelosBridge AND TARGET telos_core)
    add_executable(telos_io_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_io_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_io_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_io_runner IoTelosBridge)

    target_compile_definitions(telos_io_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_bridge_smoke.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_io_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_bridge_io COMMAND telos_io_runner)

    add_executable(telos_bridge_metrics_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_bridge_metrics_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_bridge_metrics_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_bridge_metrics_runner IoTelosBridge)

    target_compile_definitions(telos_bridge_metrics_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_bridge_metrics_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_bridge_metrics_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_bridge_metrics_io COMMAND telos_bridge_metrics_runner)

    add_executable(telos_outbox_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_outbox_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_outbox_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_outbox_runner IoTelosBridge)

    target_compile_definitions(telos_outbox_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_outbox_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_outbox_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_outbox_io COMMAND telos_outbox_runner)

    add_executable(telos_zodb_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_zodb_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_zodb_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_zodb_runner IoTelosBridge)

    target_compile_definitions(telos_zodb_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_zodb_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_zodb_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_zodb_io COMMAND telos_zodb_runner)

    add_executable(telos_zodb_manager_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_zodb_manager_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_zodb_manager_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_zodb_manager_runner IoTelosBridge)

    target_compile_definitions(telos_zodb_manager_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_zodb_manager_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_zodb_manager_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_zodb_manager_io COMMAND telos_zodb_manager_runner)

    add_executable(telos_concept_repository_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_concept_repository_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_concept_repository_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_concept_repository_runner IoTelosBridge)

    target_compile_definitions(telos_concept_repository_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_concept_repository_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_concept_repository_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_concept_repository_io COMMAND telos_concept_repository_runner)

    add_executable(telos_l1_cache_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_l1_cache_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_l1_cache_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_l1_cache_runner IoTelosBridge)

    target_compile_definitions(telos_l1_cache_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_l1_cache_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_l1_cache_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_l1_cache_io COMMAND telos_l1_cache_runner)

    add_executable(telos_federated_memory_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_federated_memory_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_federated_memory_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_federated_memory_runner IoTelosBridge)

    target_compile_definitions(telos_federated_memory_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_federated_memory_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_federated_memory_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_federated_memory_io COMMAND telos_federated_memory_runner)

    add_executable(telos_federated_memory_benchmark_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_federated_memory_benchmark_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_federated_memory_benchmark_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_federated_memory_benchmark_runner IoTelosBridge)

    target_compile_definitions(telos_federated_memory_benchmark_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_federated_memory_benchmark_harness.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_federated_memory_benchmark_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_federated_memory_benchmark_io COMMAND telos_federated_memory_benchmark_runner)

    add_executable(telos_hrc_runner "${CMAKE_CURRENT_SOURCE_DIR}/telos_io_runner.c")

    target_include_directories(telos_hrc_runner PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(telos_hrc_runner PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(telos_hrc_runner IoTelosBridge)

    target_compile_definitions(telos_hrc_runner PRIVATE
        TELOS_IO_SCRIPT_PATH="${CMAKE_CURRENT_SOURCE_DIR}/telos_hrc_smoke.io"
        TELOS_ADDON_SEARCH_PATH="${CMAKE_BINARY_DIR}/addons"
    )

    set_target_properties(telos_hrc_runner PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME telos_hrc_io COMMAND telos_hrc_runner)

    add_executable(synaptic_bridge_message_test "${CMAKE_CURRENT_SOURCE_DIR}/test_bridge_send_message.c")

    target_include_directories(synaptic_bridge_message_test PRIVATE
        ${IOVM_INCLUDE_DIR}
        ${GC_INCLUDE_DIR}
        ${BASEKIT_INCLUDE_DIR}
        ${COROUTINE_INCLUDE_DIR}
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(synaptic_bridge_message_test PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    add_dependencies(synaptic_bridge_message_test IoTelosBridge)

    set_target_properties(synaptic_bridge_message_test PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME bridge_send_message_c COMMAND synaptic_bridge_message_test)

    # Small lifecycle test for shared memory handles
    add_executable(shared_memory_lifecycle_test "${CMAKE_CURRENT_SOURCE_DIR}/test_shared_memory_lifecycle.c")

    target_include_directories(shared_memory_lifecycle_test PRIVATE
        ${TELOS_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/deps/parson
    )

    target_link_libraries(shared_memory_lifecycle_test PRIVATE
        telos_core
        iovmall
        basekit
        coroutine
        garbagecollector
    )

    set_target_properties(shared_memory_lifecycle_test PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
        BUILD_RPATH "${CMAKE_BINARY_DIR};${CMAKE_BINARY_DIR}/_build/dll"
    )

    add_test(NAME shared_memory_lifecycle COMMAND shared_memory_lifecycle_test)

    set(test_env_vars
        "PYTHONPATH=${CMAKE_CURRENT_SOURCE_DIR}/../Telos/python:$ENV{PYTHONPATH}"
        "TELOS_ADDON_PATH=${CMAKE_BINARY_DIR}/addons"
        "TELOS_OTEL_SETTINGS_PATH=${TELOS_OTEL_SETTINGS_PATH}"
    )

    if(UNIX)
        list(APPEND test_env_vars "LD_LIBRARY_PATH=${CMAKE_BINARY_DIR}:${CMAKE_BINARY_DIR}/_build/dll:$ENV{LD_LIBRARY_PATH}")
    elseif(APPLE)
        list(APPEND test_env_vars "DYLD_LIBRARY_PATH=${CMAKE_BINARY_DIR}:${CMAKE_BINARY_DIR}/_build/dll:$ENV{DYLD_LIBRARY_PATH}")
    endif()

    set_tests_properties(telos_bridge_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_bridge_metrics_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_outbox_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_zodb_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_zodb_manager_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_concept_repository_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_l1_cache_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_federated_memory_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_federated_memory_benchmark_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(telos_hrc_io PROPERTIES ENVIRONMENT "${test_env_vars}")
    set_tests_properties(bridge_send_message_c PROPERTIES ENVIRONMENT "${test_env_vars}")
endif()

if(TARGET io)
    # Add a test for the Compositional Gauntlet validation harness
    add_test(
        NAME gauntlet-validation
        COMMAND ${CMAKE_COMMAND} -E env
            "IO_PLATFORM_PATH=${PROJECT_BINARY_DIR}/addons"
            $<TARGET_FILE:io> "${CMAKE_CURRENT_SOURCE_DIR}/gauntlet_validation.io"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )

    # Set a 300-second timeout as per the mandate
    set_tests_properties(gauntlet-validation PROPERTIES
        TIMEOUT 300
        FAIL_REGULAR_EXPRESSION "FATAL"
    )
    message(STATUS "Added test: gauntlet-validation with 300s timeout")
else()
    message(WARNING "Io executable not found. Skipping gauntlet-validation test.")
endif()

# Add convenience target to run all tests
add_custom_target(run_all_tests
    COMMAND ${CMAKE_CTEST_COMMAND} --verbose
    DEPENDS telos_python_extension
    COMMENT "Running all TELOS tests"
)

message(STATUS "Configured TELOS test suite with ${Python_EXECUTABLE}")