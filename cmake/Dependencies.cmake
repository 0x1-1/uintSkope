###############################################################################
# Dependencies.cmake
#
# Declares the third-party dependencies of uintSkope as imported/interface
# targets:
#
#   uintskope::gli    header-only gli + glm (DDS/texture handling)   [submodule]
#   uintskope::qhull  qhull convex-hull library                      [submodule]
#   uintskope::zlib   zlib compression                               [submodule | system]
#
# Vendored-by-default for deterministic builds; system packages are opt-in via
# UINTSKOPE_USE_SYSTEM_ZLIB / UINTSKOPE_USE_SYSTEM_QHULL.
###############################################################################

set(_uintskope_lib "${CMAKE_CURRENT_SOURCE_DIR}/lib")

#------------------------------------------------------------------------------
# Submodule sanity check — fail early with an actionable message.
#------------------------------------------------------------------------------
function(_uintskope_require_submodule probe name)
    if(NOT EXISTS "${probe}")
        message(FATAL_ERROR
            "Required submodule '${name}' is missing (expected: ${probe}).\n"
            "Initialize submodules with:\n"
            "    git submodule update --init --recursive")
    endif()
endfunction()

_uintskope_require_submodule("${_uintskope_lib}/gli/gli/gli.hpp"            "lib/gli")
_uintskope_require_submodule("${CMAKE_CURRENT_SOURCE_DIR}/build/docsys/nifxml/nif.xml" "build/docsys")

#==============================================================================
# gli + glm  (header-only)
#==============================================================================
# gltexloaders.h includes <gli.hpp>; gli internally pulls in <glm/...>. These
# match the include dirs the old qmake 'gli' scope added. Marked SYSTEM so the
# (large, old) third-party headers don't drown first-party code in warnings.
add_library(uintskope_gli INTERFACE)
target_include_directories(uintskope_gli SYSTEM INTERFACE
    "${_uintskope_lib}/gli/gli"
    "${_uintskope_lib}/gli/external")
add_library(uintskope::gli ALIAS uintskope_gli)

#==============================================================================
# qhull
#==============================================================================
# NOTE: src/lib/qhull.cpp is a *unity include* wrapper — it does
#   extern "C" { #include <libqhull/libqhull.c> ... }
# pulling the non-reentrant qhull sources directly into one translation unit.
# Therefore the vendored path must provide ONLY the include directory; compiling
# qhull as a separate library would cause duplicate-symbol link errors.
add_library(uintskope_qhull INTERFACE)
if(UINTSKOPE_USE_SYSTEM_QHULL)
    # Best-effort system support. Because the wrapper #includes qhull's *.c
    # sources by path, a system qhull must expose the same <libqhull/...c>
    # layout; most distro packages ship headers only. Prefer the vendored copy.
    find_package(Qhull CONFIG QUIET)
    if(Qhull_FOUND)
        message(STATUS "qhull: using system package (experimental; vendored is recommended)")
        target_link_libraries(uintskope_qhull INTERFACE Qhull::qhullstatic)
    else()
        message(WARNING "UINTSKOPE_USE_SYSTEM_QHULL=ON but no system qhull found; falling back to vendored.")
        set(UINTSKOPE_USE_SYSTEM_QHULL OFF CACHE BOOL "" FORCE)
    endif()
endif()
if(NOT UINTSKOPE_USE_SYSTEM_QHULL)
    _uintskope_require_submodule("${_uintskope_lib}/qhull/src/libqhull/libqhull.c" "lib/qhull")
    target_include_directories(uintskope_qhull SYSTEM INTERFACE "${_uintskope_lib}/qhull/src")
endif()
add_library(uintskope::qhull ALIAS uintskope_qhull)

#==============================================================================
# zlib
#==============================================================================
if(UINTSKOPE_USE_SYSTEM_ZLIB)
    find_package(ZLIB REQUIRED)
    message(STATUS "zlib: using system package (${ZLIB_VERSION_STRING})")
    # bsa.cpp includes "zlib/zlib.h"; the app already has lib/ on its include
    # path. System headers are <zlib.h>, so we additionally expose the system
    # include dir's parent shim is not portable — instead we rely on the app's
    # own include of <zlib.h> fallback. Vendored remains the supported default.
    add_library(uintskope_zlib INTERFACE)
    target_link_libraries(uintskope_zlib INTERFACE ZLIB::ZLIB)
    add_library(uintskope::zlib ALIAS uintskope_zlib)
else()
    _uintskope_require_submodule("${_uintskope_lib}/zlib/zlib.h" "lib/zlib")
    file(GLOB _uintskope_zlib_sources CONFIGURE_DEPENDS "${_uintskope_lib}/zlib/*.c")
    add_library(uintskope_zlib STATIC ${_uintskope_zlib_sources})
    # Consumers do #include "zlib/zlib.h" → expose lib/ as a SYSTEM include.
    target_include_directories(uintskope_zlib SYSTEM PUBLIC "${_uintskope_lib}")
    target_include_directories(uintskope_zlib PRIVATE "${_uintskope_lib}/zlib")

    # zlib's own build performs check_include_file(unistd.h Z_HAVE_UNISTD_H).
    # We compile the shipped sources without running that configure step, so
    # zconf.h never includes <unistd.h> and gzlib.c/gzread.c call lseek/read/
    # close with no declaration — an error, not a warning, on Clang 16+.
    # PUBLIC because zconf.h also picks z_off_t from this define (off_t vs
    # long); the library and its consumers must agree.
    include(CheckIncludeFile)
    check_include_file(unistd.h UINTSKOPE_HAVE_UNISTD_H)
    if(UINTSKOPE_HAVE_UNISTD_H)
        target_compile_definitions(uintskope_zlib PUBLIC Z_HAVE_UNISTD_H)
    endif()

    if(APPLE)
        # Workaround, not a fix: on Apple <unistd.h> pulls in TargetConditionals.h,
        # which defines TARGET_OS_MAC, and this (old) zlib's zutil.h then does
        #     #ifndef fdopen
        #     #  define fdopen(fd,mode) NULL
        # which mangles the SDK's own fdopen declaration in <stdio.h>. Pre-defining
        # fdopen to itself satisfies that guard and leaves the real function alone.
        # Upstream zlib dropped the TARGET_OS_MAC branch; updating the submodule is
        # the real fix.
        target_compile_definitions(uintskope_zlib PRIVATE fdopen=fdopen)
    endif()
    if(MSVC)
        target_compile_definitions(uintskope_zlib PRIVATE _CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_DEPRECATE)
        target_compile_options(uintskope_zlib PRIVATE /w)
    else()
        target_compile_options(uintskope_zlib PRIVATE -w)
    endif()
    set_target_properties(uintskope_zlib PROPERTIES POSITION_INDEPENDENT_CODE ON)
    add_library(uintskope::zlib ALIAS uintskope_zlib)
endif()

unset(_uintskope_lib)
