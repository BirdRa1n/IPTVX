qt_add_executable(iptvx
    DevTools.cpp
    DevTools.h
    main.cpp
    platform/WindowChrome.h)

if(APPLE)
    enable_language(OBJCXX)
    target_sources(iptvx PRIVATE platform/WindowChrome_mac.mm)
    target_link_libraries(iptvx PRIVATE "-framework AppKit")
else()
    target_sources(iptvx PRIVATE platform/WindowChrome.cpp)
endif()
target_include_directories(iptvx PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

# ---- App icon -------------------------------------------------------------
# Master artwork: resources/icons/iptvx.svg (regenerate with --target icons).
set(IPTVX_ICONS ${PROJECT_SOURCE_DIR}/resources/icons)
qt_add_resources(iptvx "app_icon"
    PREFIX /icons
    BASE ${IPTVX_ICONS}
    FILES ${IPTVX_ICONS}/iptvx-256.png)
if(APPLE)
    target_sources(iptvx PRIVATE ${IPTVX_ICONS}/iptvx.icns)
    set_source_files_properties(${IPTVX_ICONS}/iptvx.icns PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set_target_properties(iptvx PROPERTIES MACOSX_BUNDLE_ICON_FILE iptvx.icns)
elseif(WIN32)
    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/iptvx_icon.rc "IDI_ICON1 ICON \"${IPTVX_ICONS}/iptvx.ico\"\n")
    target_sources(iptvx PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/iptvx_icon.rc)
endif()

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
    iptvx_ui
    iptvx_uiplugin)

iptvx_configure_target(iptvx)

qt_add_translations(iptvx
    TS_FILE_DIR ${PROJECT_SOURCE_DIR}/i18n
    TS_FILE_BASE iptvx
    RESOURCE_PREFIX /i18n
    SOURCE_TARGETS iptvx iptvx_ui iptvx_core)

include(GNUInstallDirs)
install(TARGETS iptvx
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

if(UNIX AND NOT APPLE)
    install(FILES ${PROJECT_SOURCE_DIR}/resources/linux/io.github.birdra1n.iptvx.desktop
        DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
    install(FILES ${IPTVX_ICONS}/iptvx-256.png
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/256x256/apps
        RENAME io.github.birdra1n.iptvx.png)
    install(FILES ${IPTVX_ICONS}/iptvx.svg
        DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
        RENAME io.github.birdra1n.iptvx.svg)
endif()
