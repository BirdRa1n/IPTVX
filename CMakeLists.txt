cmake_minimum_required(VERSION 3.21)

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

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(CompilerSettings)

# ---------------------------------------------------------------------------
# Qt
# ---------------------------------------------------------------------------
find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core Concurrent Network Sql Gui Qml Quick QuickControls2 Multimedia LinguistTools)

qt_standard_project_setup(
    REQUIRES 6.8
    I18N_SOURCE_LANGUAGE en
    I18N_TRANSLATED_LANGUAGES pt_BR)

qt_policy(SET QTP0004 NEW)

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
add_subdirectory(src/core)
add_subdirectory(src/ui)
add_subdirectory(src/app)
