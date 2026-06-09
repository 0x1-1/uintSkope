###############################################################################
# uintSkope non-GUI smoke tests
#
# These are deliberately small and link only Qt6::Core. They validate logic that
# can be isolated from the GUI/renderer:
#   * version_logic   — the NifSkopeVersion parser/comparator (compiles version.cpp)
#   * xml_wellformed   — the shipped nif.xml / kfm.xml parse without XML errors
###############################################################################

# --- Version logic -----------------------------------------------------------
add_executable(test_version
    test_version.cpp
    "${CMAKE_SOURCE_DIR}/src/version.cpp")
target_include_directories(test_version PRIVATE "${CMAKE_SOURCE_DIR}/src")
target_link_libraries(test_version PRIVATE Qt6::Core)
add_test(NAME version_logic COMMAND test_version)

# --- NIF/KFM XML well-formedness --------------------------------------------
add_executable(test_xml_wellformed test_xml_wellformed.cpp)
target_link_libraries(test_xml_wellformed PRIVATE Qt6::Core)
target_compile_definitions(test_xml_wellformed PRIVATE
    "UINTSKOPE_NIF_XML=\"${CMAKE_SOURCE_DIR}/build/docsys/nifxml/nif.xml\""
    "UINTSKOPE_KFM_XML=\"${CMAKE_SOURCE_DIR}/build/docsys/kfmxml/kfm.xml\"")
add_test(NAME xml_wellformed COMMAND test_xml_wellformed)
