###############################################################################
# uintSkope — modern CMake build
#
# A maintained CMake + Qt 6 fork/modernization of NifSkope
# (https://github.com/niftools/nifskope). NifSkope and the NIF file format are
# the work of the NIF File Format Library and Tools project; see LICENSE.md,
# CONTRIBUTORS.md and NOTICE.md. uintSkope is NOT officially endorsed by NIFTools.
###############################################################################

cmake_minimum_required(VERSION 3.21)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

#------------------------------------------------------------------------------
# Version
#
# The canonical, human-facing version string lives in build/VERSION (e.g.
# "2.0.dev7"). It is intentionally NOT a plain semver string — the application's
# NifSkopeVersion class parses dev/alpha/beta/rc suffixes. CMake's project()
# command only accepts numeric MAJOR.MINOR.PATCH, so we derive a numeric triple
# for project() but feed the *full* string to the compiled-in version macros so
# the existing version logic keeps working unchanged.
#------------------------------------------------------------------------------
file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/build/VERSION" UINTSKOPE_VERSION_STRING LIMIT_COUNT 1)
string(STRIP "${UINTSKOPE_VERSION_STRING}" UINTSKOPE_VERSION_STRING)

if(UINTSKOPE_VERSION_STRING MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)")
    # Fully numeric MAJOR.MINOR.PATCH (e.g. "2.1.3").
    set(_uintskope_major "${CMAKE_MATCH_1}")
    set(_uintskope_minor "${CMAKE_MATCH_2}")
    set(_uintskope_patch "${CMAKE_MATCH_3}")
elseif(UINTSKOPE_VERSION_STRING MATCHES "^([0-9]+)\\.([0-9]+)")
    # MAJOR.MINOR with a non-numeric tail (e.g. "2.0.dev7") → patch 0.
    set(_uintskope_major "${CMAKE_MATCH_1}")
    set(_uintskope_minor "${CMAKE_MATCH_2}")
    set(_uintskope_patch 0)
else()
    message(WARNING "Could not parse build/VERSION ('${UINTSKOPE_VERSION_STRING}'); defaulting to 0.0.0")
    set(_uintskope_major 0)
    set(_uintskope_minor 0)
    set(_uintskope_patch 0)
endif()

project(uintSkope
    VERSION   ${_uintskope_major}.${_uintskope_minor}.${_uintskope_patch}
    DESCRIPTION "Modernized fork of NifSkope for viewing/editing NetImmerse/Gamebryo NIF, KF and KFM files"
    HOMEPAGE_URL "https://github.com/uintptr/uintSkope"
    LANGUAGES C CXX
)

#------------------------------------------------------------------------------
# Git revision (abbreviated hash) — replicates the qmake getRevision() helper.
#------------------------------------------------------------------------------
set(UINTSKOPE_REVISION "")
find_package(Git QUIET)
if(GIT_FOUND AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.git")
    execute_process(
        COMMAND "${GIT_EXECUTABLE}" rev-parse --short=7 HEAD
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        OUTPUT_VARIABLE UINTSKOPE_REVISION
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
endif()

message(STATUS "uintSkope version : ${UINTSKOPE_VERSION_STRING} (numeric ${PROJECT_VERSION})")
message(STATUS "uintSkope revision: ${UINTSKOPE_REVISION}")

#------------------------------------------------------------------------------
# Global settings
#------------------------------------------------------------------------------
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
endif()

# C++20 is the project default. Document any per-file downgrade in MODERNIZATION_REPORT.md.
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_C_STANDARD 11)

# Qt code generators. The .ui/.qrc files are listed as target sources below.
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
# .ui forms live in two dirs; let AUTOUIC find ui_*.h regardless of includer.
set(CMAKE_AUTOUIC_SEARCH_PATHS
    "${CMAKE_CURRENT_SOURCE_DIR}/src/ui"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/ui/widgets")

# Default the install prefix to a self-contained dist/ folder, like the old
# qmake build that staged everything next to the executable.
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/dist" CACHE PATH "Install prefix" FORCE)
endif()

#------------------------------------------------------------------------------
# Options
#------------------------------------------------------------------------------
option(UINTSKOPE_BUILD_TESTS        "Build uintSkope non-GUI smoke tests"            ON)
option(UINTSKOPE_ENABLE_WARNINGS    "Enable a sane warning set on first-party code"  ON)
option(UINTSKOPE_WARNINGS_AS_ERRORS "Treat warnings as errors (off until tree clean)" OFF)
option(UINTSKOPE_USE_SYSTEM_ZLIB    "Use system zlib instead of the vendored copy"   OFF)
option(UINTSKOPE_USE_SYSTEM_QHULL   "Use system qhull instead of the vendored copy"  OFF)

#------------------------------------------------------------------------------
# Qt 6
#------------------------------------------------------------------------------
find_package(Qt6 6.2 REQUIRED COMPONENTS Core Gui Widgets Xml Network OpenGL OpenGLWidgets)
qt_standard_project_setup()

# Platform OpenGL + GLU (Qt 6 no longer ships GLU; the renderer uses gluProject etc.)
set(OpenGL_GL_PREFERENCE GLVND)
find_package(OpenGL REQUIRED)

include(Dependencies)
include(CompilerWarnings)

#------------------------------------------------------------------------------
# First-party sources (authoritative list, ported from NifSkope.pro)
#------------------------------------------------------------------------------
set(UINTSKOPE_SOURCES
    src/data/niftypes.cpp
    src/data/nifvalue.cpp
    src/gl/bsshape.cpp
    src/gl/controllers.cpp
    src/gl/glcontroller.cpp
    src/gl/glmarker.cpp
    src/gl/glmesh.cpp
    src/gl/glnode.cpp
    src/gl/glparticles.cpp
    src/gl/glproperty.cpp
    src/gl/glscene.cpp
    src/gl/gltex.cpp
    src/gl/gltexloaders.cpp
    src/gl/gltools.cpp
    src/gl/renderer.cpp
    src/io/material.cpp
    src/io/nifstream.cpp
    src/lib/importex/3ds.cpp
    src/lib/importex/importex.cpp
    src/lib/importex/obj.cpp
    src/lib/importex/col.cpp
    src/lib/nvtristripwrapper.cpp
    src/lib/qhull.cpp
    src/model/basemodel.cpp
    src/model/kfmmodel.cpp
    src/model/nifdelegate.cpp
    src/model/nifmodel.cpp
    src/model/nifproxymodel.cpp
    src/model/undocommands.cpp
    src/spells/animation.cpp
    src/spells/blocks.cpp
    src/spells/bounds.cpp
    src/spells/color.cpp
    src/spells/flags.cpp
    src/spells/fo3only.cpp
    src/spells/havok.cpp
    src/spells/headerstring.cpp
    src/spells/light.cpp
    src/spells/materialedit.cpp
    src/spells/mesh.cpp
    src/spells/misc.cpp
    src/spells/moppcode.cpp
    src/spells/morphctrl.cpp
    src/spells/normals.cpp
    src/spells/optimize.cpp
    src/spells/sanitize.cpp
    src/spells/skeleton.cpp
    src/spells/stringpalette.cpp
    src/spells/strippify.cpp
    src/spells/tangentspace.cpp
    src/spells/texture.cpp
    src/spells/transform.cpp
    src/ui/widgets/colorwheel.cpp
    src/ui/widgets/fileselect.cpp
    src/ui/widgets/floatedit.cpp
    src/ui/widgets/floatslider.cpp
    src/ui/widgets/groupbox.cpp
    src/ui/widgets/inspect.cpp
    src/ui/widgets/lightingwidget.cpp
    src/ui/widgets/nifcheckboxlist.cpp
    src/ui/widgets/nifeditors.cpp
    src/ui/widgets/nifview.cpp
    src/ui/widgets/refrbrowser.cpp
    src/ui/widgets/uvedit.cpp
    src/ui/widgets/valueedit.cpp
    src/ui/widgets/xmlcheck.cpp
    src/ui/about_dialog.cpp
    src/ui/checkablemessagebox.cpp
    src/ui/settingsdialog.cpp
    src/ui/settingspane.cpp
    src/xml/kfmxml.cpp
    src/xml/nifexpr.cpp
    src/xml/nifxml.cpp
    src/glview.cpp
    src/main.cpp
    src/message.cpp
    src/nifskope.cpp
    src/nifskope_ui.cpp
    src/spellbook.cpp
    src/version.cpp
)

# Vendored sources compiled directly into the application (matches the .pro).
set(UINTSKOPE_VENDORED_SOURCES
    lib/half.cpp
    lib/fsengine/bsa.cpp
    lib/fsengine/fsengine.cpp
    lib/fsengine/fsmanager.cpp
    lib/NvTriStrip/NvTriStrip.cpp
    lib/NvTriStrip/NvTriStripObjects.cpp
    lib/NvTriStrip/VertexCache.cpp
    lib/lz4frame.c
    # NOTE: lib/xxhash.c is intentionally NOT compiled. With XXH_PRIVATE_API the
    # full implementation lives in xxhash.h and is included inline by lz4frame.c;
    # compiling xxhash.c too would redefine every XXH_* symbol.
)

# Qt Designer forms and Qt resource collections (compiled by AUTOUIC/AUTORCC).
set(UINTSKOPE_FORMS
    src/ui/about_dialog.ui
    src/ui/checkablemessagebox.ui
    src/ui/nifskope.ui
    src/ui/settingsdialog.ui
    src/ui/settingsgeneral.ui
    src/ui/settingsrender.ui
    src/ui/settingsresources.ui
    src/ui/widgets/lightingwidget.ui
)
set(UINTSKOPE_RESOURCES res/nifskope.qrc)

#------------------------------------------------------------------------------
# Executable target: uintSkope
#
# Single application target for now. The reusable "core" (data/model/io/xml) and
# the "app" (ui/gl/main) are kept in clearly separated source groups above so a
# future split into uintSkope_core + uintSkope_app is mechanical, not a rewrite.
#------------------------------------------------------------------------------
qt_add_executable(uintSkope WIN32 MACOSX_BUNDLE
    ${UINTSKOPE_SOURCES}
    ${UINTSKOPE_VENDORED_SOURCES}
    ${UINTSKOPE_FORMS}
    ${UINTSKOPE_RESOURCES}
    # Header-only Q_OBJECT class (no matching .cpp) — listed so AUTOMOC moc's it.
    src/gl/icontrollable.h
)

set_target_properties(uintSkope PROPERTIES
    OUTPUT_NAME "uintSkope"
    # macOS .app metadata
    MACOSX_BUNDLE_BUNDLE_NAME "uintSkope"
    MACOSX_BUNDLE_GUI_IDENTIFIER "org.uintskope.uintSkope"
    MACOSX_BUNDLE_BUNDLE_VERSION "${UINTSKOPE_VERSION_STRING}"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
)

# Windows executable icon / version resource.
if(WIN32)
    target_sources(uintSkope PRIVATE res/icon.rc)
endif()

target_include_directories(uintSkope PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"            # for #include "lib/half.h", "lib/dds.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"        # for "data/...", "gl/...", "model/..."
    "${CMAKE_CURRENT_SOURCE_DIR}/lib"        # for <fsengine/...>, "dds.h", "zlib/zlib.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/lib/fsengine"
    "${CMAKE_CURRENT_SOURCE_DIR}/lib/NvTriStrip"  # for "NvTriStrip.h"
)

target_compile_definitions(uintSkope PRIVATE
    # --- Branding / version ------------------------------------------------
    UINTSKOPE_NAME="uintSkope"
    UINTSKOPE_UPSTREAM_NAME="NifSkope"
    UINTSKOPE_VERSION="${UINTSKOPE_VERSION_STRING}"
    # --- Backward-compatible macros consumed by existing code --------------
    NIFSKOPE_VERSION="${UINTSKOPE_VERSION_STRING}"
    # --- Qt deprecation hygiene (carried over from NifSkope.pro) -----------
    QT_NO_CAST_FROM_BYTEARRAY
    QT_NO_URL_CAST_FROM_STRING
    QT_DISABLE_DEPRECATED_BEFORE=0x050300
    # --- Vendored lz4/xxhash configuration (global in the old .pro) --------
    LZ4_STATIC
    XXH_PRIVATE_API
)

if(UINTSKOPE_REVISION)
    target_compile_definitions(uintSkope PRIVATE
        UINTSKOPE_REVISION="${UINTSKOPE_REVISION}"
        NIFSKOPE_REVISION="${UINTSKOPE_REVISION}")
endif()

# Suppress console window noise except in Debug (parity with the old build).
target_compile_definitions(uintSkope PRIVATE $<$<NOT:$<CONFIG:Debug>>:QT_NO_DEBUG_OUTPUT>)

if(WIN32)
    target_compile_definitions(uintSkope PRIVATE EDIT_ON_ACTIVATE)
endif()

target_link_libraries(uintSkope PRIVATE
    Qt6::Core Qt6::Gui Qt6::Widgets Qt6::Xml Qt6::Network
    Qt6::OpenGL Qt6::OpenGLWidgets
    OpenGL::GL
    uintskope::gli
    uintskope::qhull
    uintskope::zlib
)

# GLU: only where a real GLU exists (Windows/Linux). Qt 6 dropped its GL helpers.
if(TARGET OpenGL::GLU)
    target_link_libraries(uintSkope PRIVATE OpenGL::GLU)
endif()

if(APPLE)
    target_link_libraries(uintSkope PRIVATE "-framework CoreFoundation")
endif()

uintskope_apply_warnings(uintSkope)
# Vendored TUs (and the qhull unity-include wrapper) are silenced — not ours to fix.
uintskope_quiet_sources(${UINTSKOPE_VENDORED_SOURCES} src/lib/qhull.cpp)

include(InstallRules)

#------------------------------------------------------------------------------
# Tests
#------------------------------------------------------------------------------
if(UINTSKOPE_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
