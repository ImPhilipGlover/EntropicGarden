cmake_minimum_required(VERSION 3.10)

PROJECT(IoTelos)

SET(IoTelos_VERSION_MAJOR 1)
SET(IoTelos_VERSION_MINOR 0)
SET(IoTelos_VERSION "${IoTelos_VERSION_MAJOR}.${IoTelos_VERSION_MINOR}")

# Prototypal FFI uses pure C - no C++ dependencies needed
# This maintains philosophical alignment with Io's dynamic object model

# For now, don't require GLUT - we'll implement a stub UI
# find_package(GLUT REQUIRED)
# find_package(OpenGL REQUIRED)

SET(IoTelos_SRCS
	source/IoTelos.c
	source/IoTelosCore.c
	source/IoTelosFFI.c
	source/IoTelosMorphic.c
	source/PrototypalFFI.c
)

SET(IoTelos_HDRS
	source/IoTelos.h
	source/IoTelosCore.h
	source/IoTelosFFI.h
	source/IoTelosMorphic.h
)

include_directories(
    ${CMAKE_SOURCE_DIR}/libs/basekit/source
    ${CMAKE_SOURCE_DIR}/libs/iovm/source
    ${CMAKE_SOURCE_DIR}/libs/coroutine/source
    ${CMAKE_SOURCE_DIR}/libs/garbagecollector/source
    ${PYTHON_INCLUDE_DIRS}
)

add_library(IoTelos SHARED ${IoTelos_SRCS} ${IoTelos_HDRS})

target_link_libraries(IoTelos
    basekit
    iovmall
    ${PYTHON_LIBRARIES}
    ${SDL2_LIBRARIES}
)

# Also build a static version for the static executable
add_library(IoTelos_static STATIC ${IoTelos_SRCS} ${IoTelos_HDRS})

target_link_libraries(IoTelos_static
    basekit
    iovmall_static
    ${PYTHON_LIBRARIES}
    ${SDL2_LIBRARIES}
)

# Optional SDL2 integration (best-effort)
option(TELOS_WITH_SDL2 "Build Telos with SDL2 window support" ON)
if(TELOS_WITH_SDL2)
    find_package(SDL2 QUIET)
    if(SDL2_FOUND)
        message(STATUS "Telos: SDL2 found, enabling window support")
        include_directories(${SDL2_INCLUDE_DIRS})
        target_compile_definitions(IoTelos PRIVATE TELOS_HAVE_SDL2=1)
        target_compile_definitions(IoTelos_static PRIVATE TELOS_HAVE_SDL2=1)
    else()
        message(STATUS "Telos: SDL2 not found; window support disabled")
    endif()
endif()
