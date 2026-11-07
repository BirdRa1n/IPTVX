# iptvx_core: GUI-free domain layer (models, parsers, providers, storage).
# It must never link Qt GUI/QML so it stays testable and reusable.

qt_add_library(iptvx_core STATIC
    model/ChannelStore.cpp
    model/ChannelStore.h
    parser/M3uParser.cpp
    parser/M3uParser.h
    model/Source.h
    provider/XtreamClient.cpp
    provider/XtreamClient.h
    service/PlaylistLoader.cpp
    service/PlaylistLoader.h
    storage/Database.cpp
    storage/Database.h
    storage/SourceRepository.cpp
    storage/SourceRepository.h
    update/Release.cpp
    update/Release.h
    update/UpdateInstaller.cpp
    update/UpdateInstaller.h
    update/UpdateService.cpp
    update/UpdateService.h
    util/StringTable.h
)

target_include_directories(iptvx_core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(iptvx_core PUBLIC
    Qt6::Core
    Qt6::Concurrent
    Qt6::Network
    Qt6::Sql)

iptvx_configure_target(iptvx_core)
