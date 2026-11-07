set_source_files_properties(qml/theme/Theme.qml qml/Session.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

# The UI layer is a static QML module ("IPTVX.UI").
# QML files are compiled ahead of time to C++ by qmlcachegen / qmlsc, which
# removes run-time parsing and lowers the memory spent on QML bytecode.

qt_add_library(iptvx_ui STATIC)

qt_add_qml_module(iptvx_ui
    URI IPTVX.UI
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/IPTVX/UI
    SOURCES
        ArtworkNetworkFactory.cpp
        ArtworkNetworkFactory.h
        Library.cpp
        Library.h
        Updates.cpp
        Updates.h
        models/ChannelListModel.cpp
        models/ChannelListModel.h
        models/SourceListModel.cpp
        models/SourceListModel.h
    QML_FILES
        qml/Main.qml
        qml/Session.qml
        qml/shell/CommandPalette.qml
        qml/shell/Rail.qml
        qml/shell/TopBar.qml
        qml/theme/Theme.qml
        qml/pages/DashboardPage.qml
        qml/pages/LiveTvPage.qml
        qml/pages/SettingsPage.qml
        qml/player/MiniPlayer.qml
        qml/player/VideoPlayer.qml
        qml/sheets/AddSourceSheet.qml
        qml/sheets/UpdateSheet.qml
        qml/components/ChannelRow.qml
        qml/components/EmptyState.qml
        qml/components/ChannelLogo.qml
        qml/components/Icon.qml
        qml/components/PillButton.qml
        qml/components/SearchField.qml
        qml/components/SegmentedControl.qml
        qml/components/Chip.qml
        qml/components/ToggleSwitch.qml
)

target_include_directories(iptvx_ui PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(iptvx_ui
    PUBLIC
        iptvx_core
        Qt6::Quick
    PRIVATE
        Qt6::QuickControls2
        Qt6::Multimedia)

# GitHub repository queried for updates (owner/name).
set(IPTVX_UPDATE_REPO "BirdRa1n/IPTVX" CACHE STRING "GitHub repository that publishes IPTVX releases")
target_compile_definitions(iptvx_ui PRIVATE IPTVX_UPDATE_REPO="${IPTVX_UPDATE_REPO}")

iptvx_configure_target(iptvx_ui)
