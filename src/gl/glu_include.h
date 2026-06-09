#ifndef UINTSKOPE_GLU_INCLUDE_H
#define UINTSKOPE_GLU_INCLUDE_H

// GLU (gluProject / gluErrorString / tessellation) is not part of Qt and must be
// included carefully:
//   * On Windows, <GL/glu.h> uses the Win32 calling-convention macros
//     (APIENTRY / CALLBACK / WINGDIAPI) which come from <windows.h>, so it must be
//     included first. WIN32_LEAN_AND_MEAN keeps out the OLE/COM headers whose
//     'byte' typedef would otherwise clash with std::byte under C++17+.
#if defined(_WIN32)
#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  ifndef NOMINMAX
#    define NOMINMAX
#  endif
#  include <windows.h>
#endif

#if defined(__APPLE__)
#  include <OpenGL/glu.h>
#else
#  include <GL/glu.h>
#endif

#endif // UINTSKOPE_GLU_INCLUDE_H
