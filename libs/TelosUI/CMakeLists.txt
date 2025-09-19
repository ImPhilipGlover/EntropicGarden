cmake_minimum_required(VERSION 3.10)

PROJECT(IoTelosUI)

SET(IoTelosUI_VERSION_MAJOR 1)
SET(IoTelosUI_VERSION_MINOR 0)
SET(IoTelosUI_VERSION "${IoTelosUI_VERSION_MAJOR}.${IoTelosUI_VERSION_MINOR}")

# For now, don't require GLUT - we'll implement a stub UI
# find_package(GLUT REQUIRED)
# find_package(OpenGL REQUIRED)

SET(IoTelosUI_SRCS
	source/IoTelosUI.c
)

SET(IoTelosUI_HDRS
	source/IoTelosUI.h
)

include_directories(
    ${CMAKE_SOURCE_DIR}/libs/basekit/source
    ${CMAKE_SOURCE_DIR}/libs/iovm/source
    # ${GLUT_INCLUDE_DIRS}
    # ${OPENGL_INCLUDE_DIRS}
)

add_library(IoTelosUI SHARED ${IoTelosUI_SRCS} ${IoTelosUI_HDRS})

target_link_libraries(IoTelosUI
    iovmall_static
    # ${GLUT_LIBRARIES}
    # ${OPENGL_LIBRARIES}
)

# Also build a static version for the static executable
add_library(IoTelosUI_static STATIC ${IoTelosUI_SRCS} ${IoTelosUI_HDRS})

target_link_libraries(IoTelosUI_static
    iovmall_static
    # ${GLUT_LIBRARIES}
    # ${OPENGL_LIBRARIES}
)
