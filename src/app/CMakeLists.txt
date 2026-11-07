qt_add_executable(iptvx
    main.cpp)

set_target_properties(iptvx PROPERTIES
    OUTPUT_NAME IPTVX
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER io.github.birdra1n.iptvx
    MACOSX_BUNDLE_BUNDLE_NAME IPTVX
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    WIN32_EXECUTABLE TRUE)

target_compile_definitions(iptvx PRIVATE IPTVX_VERSION="${PROJECT_VERSION}")

target_link_libraries(iptvx PRIVATE
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    iptvx_uiplugin)

iptvx_configure_target(iptvx)

qt_add_translations(iptvx
    TS_FILE_DIR ${PROJECT_SOURCE_DIR}/i18n
    TS_FILE_BASE iptvx
    RESOURCE_PREFIX /i18n
    SOURCE_TARGETS iptvx iptvx_ui)

include(GNUInstallDirs)
install(TARGETS iptvx
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
