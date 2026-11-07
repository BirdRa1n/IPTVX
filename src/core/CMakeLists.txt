# iptvx_core: GUI-free domain layer (models, parsers, providers, storage).
# It must never link Qt GUI/QML so it stays testable and reusable.

qt_add_library(iptvx_core STATIC
    model/ChannelStore.cpp
    model/ChannelStore.h
    parser/M3uParser.cpp
    parser/M3uParser.h
    util/StringTable.h
)

target_include_directories(iptvx_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(iptvx_core PUBLIC
    Qt6::Core)

iptvx_configure_target(iptvx_core)
