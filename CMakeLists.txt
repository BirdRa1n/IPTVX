cmake_minimum_required(VERSION 3.21)

# Oldest macOS the app runs on. Must be set before project(); matches the
# minimum supported by the Qt release we build with (Qt 6.12: macOS 14.4).
# Without it the binary would require the SDK's macOS version.
set(CMAKE_OSX_DEPLOYMENT_TARGET "14.4" CACHE STRING "Minimum macOS version")

project(IPTVX
    VERSION 0.1.0
    DESCRIPTION "A fast, memory-efficient IPTV player built with Qt and C++"
    HOMEPAGE_URL "https://github.com/BirdRa1n/IPTVX"
    LANGUAGES CXX)

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------
option(IPTVX_BUILD_TESTS "Build the unit test suite" ON)
option(IPTVX_WARNINGS_AS_ERRORS "Treat compiler warnings as errors" OFF)
option(IPTVX_ENABLE_LTO "Enable link-time optimisation in release builds" ON)
option(IPTVX_BUILD_TOOLS "Build developer tools (icon renderer)" OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CompilerSettings)

# ---------------------------------------------------------------------------
# Qt
# ---------------------------------------------------------------------------
find_package(Qt6 6.9 REQUIRED COMPONENTS
    Core Concurrent Network Sql Gui Qml Quick QuickControls2 Multimedia LinguistTools)

qt_standard_project_setup(
    REQUIRES 6.9
    I18N_SOURCE_LANGUAGE en
    I18N_TRANSLATED_LANGUAGES pt_BR)

qt_policy(SET QTP0004 NEW)

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
add_subdirectory(src/core)
add_subdirectory(src/ui)
add_subdirectory(src/app)

if(IPTVX_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

if(IPTVX_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
