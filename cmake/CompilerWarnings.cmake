###############################################################################
# CompilerWarnings.cmake
#
# A deliberately conservative warning policy:
#   * first-party code gets -Wall -Wextra / -W4 -permissive-
#   * vendored sources compiled into the app are silenced (they are old, noisy,
#     and not ours to fix) so genuine warnings stay visible
#   * warnings-as-errors stays OFF until the tree is demonstrably clean
###############################################################################

# Multi-processor compilation for MSVC (build-speed, not a warning toggle).
add_compile_options($<$<CXX_COMPILER_ID:MSVC>:/MP>)

# Apply the first-party warning set to a target.
function(uintskope_apply_warnings target)
    if(NOT UINTSKOPE_ENABLE_WARNINGS)
        return()
    endif()

    set(_gcc_like -Wall -Wextra)
    set(_msvc     /W4 /permissive-)

    if(UINTSKOPE_WARNINGS_AS_ERRORS)
        list(APPEND _gcc_like -Werror)
        list(APPEND _msvc     /WX)
    endif()

    target_compile_options(${target} PRIVATE
        $<$<OR:$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>>:${_gcc_like}>
        $<$<CXX_COMPILER_ID:MSVC>:${_msvc}>)
endfunction()

# Silence warnings on specific (vendored) source files compiled into a target.
function(uintskope_quiet_sources)
    foreach(_src IN LISTS ARGN)
        if(MSVC)
            set_source_files_properties("${_src}" PROPERTIES COMPILE_OPTIONS "/w")
        else()
            set_source_files_properties("${_src}" PROPERTIES COMPILE_OPTIONS "-w")
        endif()
    endforeach()
endfunction()
