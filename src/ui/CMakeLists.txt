# The UI layer is a static QML module ("IPTVX.UI").
# QML files are compiled ahead of time to C++ by qmlcachegen / qmlsc, which
# removes run-time parsing and lowers the memory spent on QML bytecode.

qt_add_library(iptvx_ui STATIC)

qt_add_qml_module(iptvx_ui
    URI IPTVX.UI
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml/IPTVX/UI
    QML_FILES
        qml/Main.qml
)

target_link_libraries(iptvx_ui PRIVATE
    Qt6::Quick
    Qt6::QuickControls2)

iptvx_configure_target(iptvx_ui)
