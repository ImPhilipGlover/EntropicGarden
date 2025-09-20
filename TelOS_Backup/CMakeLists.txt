cmake_minimum_required(VERSION 3.10)

PROJECT(IoTelos)

SET(IoTelos_VERSION_MAJOR 1)
SET(IoTelos_VERSION_MINOR 0)
SET(IoTelos_VERSION "${IoTelos_VERSION_MAJOR}.${IoTelos_VERSION_MINOR}")

# For now, don't require GLUT - we'll implement a stub UI
# find_package(GLUT REQUIRED)
# find_package(OpenGL REQUIRED)

SET(IoTelos_SRCS
	source/IoTelos.c
)

SET(IoTelos_HDRS
	source/IoTelos.h
)

include_directories(
    ${CMAKE_SOURCE_DIR}/libs/basekit/source
    ${CMAKE_SOURCE_DIR}/libs/iovm/source
    # ${GLUT_INCLUDE_DIRS}
    # ${OPENGL_INCLUDE_DIRS}
)

add_library(IoTelos SHARED ${IoTelos_SRCS} ${IoTelos_HDRS})

target_link_libraries(IoTelos
    basekit
    # ${GLUT_LIBRARIES}
    # ${OPENGL_LIBRARIES}
)

# Also build a static version for the static executable
add_library(IoTelos_static STATIC ${IoTelos_SRCS} ${IoTelos_HDRS})

target_link_libraries(IoTelos_static
    basekit
    # ${GLUT_LIBRARIES}
    # ${OPENGL_LIBRARIES}
)
