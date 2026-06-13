###############################################################################
# InstallRules.cmake
#
# Produces a self-contained, portable install tree that mirrors what the old
# qmake post-link copy steps staged next to the executable. This matters for
# correctness, not just tidiness: src/main.cpp does
#     QDir::setCurrent( qApp->applicationDirPath() );
# and then loads nif.xml / kfm.xml / shaders / style.qss by *relative* path, so
# those data files MUST live beside the binary at runtime.
###############################################################################

# Flat, portable layout: the executable, its Qt runtime (windeployqt/macdeployqt),
# and the data files all live together — matching the old qmake build and what
# src/main.cpp expects (it loads nif.xml etc. relative to applicationDirPath()).

# Where data lands relative to the install prefix. For a macOS bundle the
# binary is in uintSkope.app/Contents/MacOS, so data is placed there too.
if(APPLE)
    set(UINTSKOPE_DATA_DEST "uintSkope.app/Contents/MacOS")
    set(UINTSKOPE_BIN_DEST  ".")
else()
    set(UINTSKOPE_DATA_DEST ".")
    set(UINTSKOPE_BIN_DEST  ".")
endif()

#------------------------------------------------------------------------------
# Executable
#------------------------------------------------------------------------------
install(TARGETS uintSkope
    BUNDLE  DESTINATION "${UINTSKOPE_BIN_DEST}"
    RUNTIME DESTINATION "${UINTSKOPE_BIN_DEST}")

#------------------------------------------------------------------------------
# Runtime data (NIF/KFM format definitions, shaders, stylesheet)
#------------------------------------------------------------------------------
install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/build/docsys/nifxml/nif.xml"
        "${CMAKE_CURRENT_SOURCE_DIR}/build/docsys/kfmxml/kfm.xml"
        "${CMAKE_CURRENT_SOURCE_DIR}/res/style.qss"
    DESTINATION "${UINTSKOPE_DATA_DEST}")

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/res/shaders/"
    DESTINATION "${UINTSKOPE_DATA_DEST}/shaders")

#------------------------------------------------------------------------------
# Documentation shipped with the binary
#------------------------------------------------------------------------------
install(FILES
        "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
        "${CMAKE_CURRENT_SOURCE_DIR}/CHANGELOG.md"
        "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE.md"
        "${CMAKE_CURRENT_SOURCE_DIR}/NOTICE.md"
    DESTINATION "${UINTSKOPE_DATA_DEST}"
    OPTIONAL)

#------------------------------------------------------------------------------
# NifMopp.dll — prebuilt Havok MOPP helper, 32-bit Windows ONLY.
# (moppcode.cpp LoadLibrary()s it at runtime; 64-bit builds simply skip it.)
#------------------------------------------------------------------------------
if(WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 4)
    install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/dep/NifMopp.dll"
        DESTINATION "${UINTSKOPE_DATA_DEST}")
elseif(WIN32)
    # The bundled NifMopp.dll is 32-bit only; a 64-bit process cannot load it, so
    # MOPP (Havok collision) generation is unavailable on the default 64-bit build.
    # Surface this at configure time so packagers know the shipped build lacks it.
    message(WARNING
        "64-bit Windows build: the bundled NifMopp.dll is 32-bit only and will not "
        "be installed. 'Update MOPP Code' / 'Update All MOPP Code' will be "
        "unavailable in this build. See README (MOPP / Havok) for details.")
endif()

#------------------------------------------------------------------------------
# Qt runtime deployment — run windeployqt / macdeployqt directly on the INSTALLED
# executable so the Qt libraries and plugins land BESIDE it (the flat layout the
# app needs). Linux has no first-party Qt deploy tool: the release workflow
# bundles Qt into an AppImage via linuxdeploy, while a plain `cmake --install`
# stages only the binary + data and relies on the system Qt being present.
#------------------------------------------------------------------------------
get_filename_component(_uintskope_qt_bin "${Qt6_DIR}/../../../bin" ABSOLUTE)

if(WIN32)
    find_program(UINTSKOPE_WINDEPLOYQT NAMES windeployqt HINTS "${_uintskope_qt_bin}")
    if(UINTSKOPE_WINDEPLOYQT)
        install(CODE "
            message(STATUS \"Deploying Qt runtime with windeployqt...\")
            execute_process(
                COMMAND \"${UINTSKOPE_WINDEPLOYQT}\" --release --no-translations
                        \"\${CMAKE_INSTALL_PREFIX}/uintSkope.exe\"
                RESULT_VARIABLE _wdq_result)
            if(NOT _wdq_result EQUAL 0)
                message(WARNING \"windeployqt failed (\${_wdq_result}); Qt DLLs may be missing\")
            endif()
        ")
    else()
        message(WARNING "windeployqt not found near ${_uintskope_qt_bin}; install() will not bundle Qt DLLs.")
    endif()
elseif(APPLE)
    find_program(UINTSKOPE_MACDEPLOYQT NAMES macdeployqt HINTS "${_uintskope_qt_bin}")
    if(UINTSKOPE_MACDEPLOYQT)
        install(CODE "
            message(STATUS \"Deploying Qt runtime with macdeployqt...\")
            execute_process(
                COMMAND \"${UINTSKOPE_MACDEPLOYQT}\" \"\${CMAKE_INSTALL_PREFIX}/uintSkope.app\"
                RESULT_VARIABLE _mdq_result)
            if(NOT _mdq_result EQUAL 0)
                message(WARNING \"macdeployqt failed (\${_mdq_result})\")
            endif()
        ")
    endif()
endif()
