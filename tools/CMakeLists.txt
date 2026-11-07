# Developer tools (not shipped). Enable with -DIPTVX_BUILD_TOOLS=ON.

find_package(Qt6 REQUIRED COMPONENTS Svg)

# Renders resources/icons/iptvx.svg into iconset / ico / png.
# Regenerate the committed icons with:  cmake --build <dir> --target icons
qt_add_executable(iptvx_icongen icon-render/main.cpp)
set_target_properties(iptvx_icongen PROPERTIES MACOSX_BUNDLE FALSE WIN32_EXECUTABLE FALSE)
target_link_libraries(iptvx_icongen PRIVATE Qt6::Gui Qt6::Svg)
iptvx_configure_target(iptvx_icongen)

set(_icons_dir ${PROJECT_SOURCE_DIR}/resources/icons)
set(_icons_cmds
    COMMAND $<TARGET_FILE:iptvx_icongen> ${_icons_dir}/iptvx.svg ${CMAKE_CURRENT_BINARY_DIR}/icons
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx.ico ${_icons_dir}/
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_icons_dir}/hicolor
    COMMAND ${CMAKE_COMMAND} -E copy
        ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-16.png ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-24.png
        ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-32.png ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-48.png
        ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-64.png ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-128.png
        ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-256.png ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx-512.png
        ${_icons_dir}/hicolor/)
if(APPLE)
    list(APPEND _icons_cmds
        COMMAND iconutil -c icns ${CMAKE_CURRENT_BINARY_DIR}/icons/iptvx.iconset -o ${_icons_dir}/iptvx.icns)
endif()
add_custom_target(icons ${_icons_cmds}
    DEPENDS iptvx_icongen
    COMMENT "Rendering app icons from iptvx.svg"
    VERBATIM)
