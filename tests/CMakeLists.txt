find_package(Qt6 REQUIRED COMPONENTS Test)

# iptvx_add_test(<name> SOURCES <files...>)
# Every test links the GUI-free core library only.
function(iptvx_add_test name)
    cmake_parse_arguments(ARG "" "" "SOURCES" ${ARGN})
    qt_add_executable(${name} ${ARG_SOURCES})
    target_link_libraries(${name} PRIVATE Qt6::Test iptvx_core)
    target_compile_definitions(${name} PRIVATE
        IPTVX_TEST_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/data")
    set_target_properties(${name} PROPERTIES MACOSX_BUNDLE FALSE WIN32_EXECUTABLE FALSE)
    iptvx_configure_target(${name})
    add_test(NAME ${name} COMMAND ${name})
endfunction()

iptvx_add_test(tst_channelstore SOURCES core/tst_channelstore.cpp)
iptvx_add_test(tst_m3uparser SOURCES core/tst_m3uparser.cpp)
iptvx_add_test(tst_sourcerepository SOURCES core/tst_sourcerepository.cpp)
