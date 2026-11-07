# Shared compiler configuration for every IPTVX target.
#
# Usage: iptvx_configure_target(<target>)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
endif()

include(CheckIPOSupported)
check_ipo_supported(RESULT IPTVX_IPO_SUPPORTED OUTPUT _ipo_msg LANGUAGES CXX)

function(iptvx_configure_target target)
    if(MSVC)
        target_compile_options(${target} PRIVATE /W4 /permissive- /utf-8 /Zc:__cplusplus)
        if(IPTVX_WARNINGS_AS_ERRORS)
            target_compile_options(${target} PRIVATE /WX)
        endif()
    else()
        target_compile_options(${target} PRIVATE
            -Wall -Wextra -Wpedantic -Wshadow -Wnon-virtual-dtor
            -Wold-style-cast -Wcast-align -Woverloaded-virtual
            -Wnull-dereference -Wimplicit-fallthrough)
        if(IPTVX_WARNINGS_AS_ERRORS)
            target_compile_options(${target} PRIVATE -Werror)
        endif()
    endif()

    # Keep Qt strict: no implicit ASCII casts, no deprecated APIs.
    target_compile_definitions(${target} PRIVATE
        QT_NO_CAST_FROM_ASCII
        QT_NO_CAST_TO_ASCII
        QT_NO_URL_CAST_FROM_STRING
        QT_NO_NARROWING_CONVERSIONS_IN_CONNECT
        QT_USE_QSTRINGBUILDER
        QT_DISABLE_DEPRECATED_UP_TO=0x060800
        $<$<CONFIG:Release,MinSizeRel,RelWithDebInfo>:QT_NO_DEBUG_OUTPUT>)

    if(IPTVX_ENABLE_LTO AND IPTVX_IPO_SUPPORTED)
        set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
        set_property(TARGET ${target} PROPERTY INTERPROCEDURAL_OPTIMIZATION_MINSIZEREL ON)
    endif()
endfunction()
