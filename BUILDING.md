# Building uintSkope

uintSkope uses a modern **CMake** build and targets **Qt 6**. This document covers
Windows, Linux and macOS.

## Prerequisites (all platforms)

| Tool | Minimum | Notes |
|------|---------|-------|
| CMake | 3.21 | Bundled with recent Qt installs and Visual Studio |
| Ninja | any recent | Recommended generator; bundled with Qt / VS |
| C++ compiler | C++20 | MSVC 2019+, GCC 10+, or Clang 12+ |
| Qt | 6.2+ | Widgets, Gui, Xml, Network, OpenGL, OpenGLWidgets |
| Git | any | Required for submodules and the version-revision stamp |

> **Note on OpenGL/GLU:** The renderer uses legacy fixed-function OpenGL and GLU
> (`gluProject`, `gluErrorString`, …). On Windows GLU is provided by `glu32`
> (system); on Linux install `libglu1-mesa-dev`; on macOS it comes with the SDK.

## 1. Get the source (with submodules)

uintSkope vendors several dependencies as git submodules
(`build/docsys`, `lib/gli`, `lib/qhull`, `lib/zlib`). They are **required** — the
build fails early with a clear message if they are missing.

```bash
git clone --recursive https://github.com/uintptr/uintSkope.git
cd uintSkope
# or, if already cloned:
git submodule update --init --recursive
```

## 2. Configure, build, test

The committed presets use the Ninja generator. Qt 6 must be discoverable — either
add Qt's `bin` to `PATH`, or pass `-DCMAKE_PREFIX_PATH=/path/to/qt/<kit>`.

```bash
cmake --preset release
cmake --build --preset release
ctest --preset release --output-on-failure
```

Presets available: `release`, `debug`, `ci-release`. Build output goes to
`out/build/<preset>/`.

### Machine-specific presets

Create a **`CMakeUserPresets.json`** (git-ignored) to pin your local toolchain so
`cmake --preset <name>` "just works". Example (Windows + MinGW Qt kit):

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "local-mingw",
      "inherits": "release",
      "cacheVariables": {
        "CMAKE_PREFIX_PATH": "C:/Qt/6.7.0/mingw_64",
        "CMAKE_C_COMPILER": "C:/Qt/Tools/mingw1310_64/bin/gcc.exe",
        "CMAKE_CXX_COMPILER": "C:/Qt/Tools/mingw1310_64/bin/g++.exe",
        "CMAKE_MAKE_PROGRAM": "C:/Qt/Tools/Ninja/ninja.exe"
      }
    }
  ]
}
```

## 3. Install (self-contained layout)

```bash
cmake --install out/build/release --prefix dist
```

This stages a **flat, portable layout** — the executable, the runtime data
(`nif.xml`, `kfm.xml`, `style.qss`, `shaders/`) and (on Windows/macOS) the bundled
Qt runtime, all together. This matters: the app sets its working directory to the
executable's directory and loads data by relative path.

---

## Platform specifics

### Windows — MSVC

1. Install Qt 6 (e.g. via the Qt Online Installer) with the **MSVC 2019/2022 64-bit**
   kit, plus the **Qt Image Formats** module.
2. From a *Developer Command Prompt / Developer PowerShell for VS* (so `cl.exe` is
   on `PATH`):

   ```bat
   cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:/Qt/6.7.0/msvc2022_64
   cmake --build build --parallel
   ctest --test-dir build --output-on-failure
   cmake --install build --prefix dist
   ```

   `cmake --install` runs `windeployqt` to bundle the Qt DLLs and plugins next to
   `uintSkope.exe`.

### Windows — MinGW

Use the Qt **mingw_64** kit and the MinGW toolchain that ships with Qt
(`C:/Qt/Tools/mingwXXXX_64`). No Developer Prompt is needed:

```bat
set PATH=C:\Qt\Tools\mingw1310_64\bin;C:\Qt\Tools\Ninja;%PATH%
cmake -B build -G Ninja -DCMAKE_PREFIX_PATH=C:/Qt/6.7.0/mingw_64 ^
  -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++
cmake --build build --parallel
```

### Linux

```bash
sudo apt-get install -y build-essential ninja-build cmake \
  libgl1-mesa-dev libglu1-mesa-dev mesa-common-dev
# Install Qt 6 (distro packages, the Qt installer, or aqtinstall).

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
ctest --test-dir build --output-on-failure
cmake --install build --prefix dist
```

There is no first-party Qt deploy tool on Linux, so the install tree depends on a
system Qt 6 + OpenGL runtime. For a self-contained bundle, use `linuxdeploy` with
its Qt plugin to build an AppImage (a future enhancement; not yet wired into CI).

### macOS

```bash
brew install ninja cmake
# Install Qt 6 (brew install qt, the Qt installer, or aqtinstall).

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="$(brew --prefix qt)"
cmake --build build --parallel
cmake --install build --prefix dist
```

`cmake --install` builds `uintSkope.app` and runs `macdeployqt` to bundle Qt into
the app bundle. The resulting `.app` is self-contained.

---

## Troubleshooting

**“Required submodule … is missing.”**
Run `git submodule update --init --recursive`.

**`find_package(Qt6)` fails / Qt not found.**
Add Qt's `bin` directory to `PATH`, or pass
`-DCMAKE_PREFIX_PATH=/path/to/Qt/<version>/<kit>`. Make sure you point at a *kit*
directory (the one containing `lib/cmake/Qt6`), not the Qt root.

**Windows: `GL/glu.h` parse errors (`expected ')' before '*'`).**
GLU needs the Win32 API macros from `<windows.h>`. uintSkope includes them via
`src/gl/glu_include.h`; if you add new GLU-using files, include that header rather
than `<GL/glu.h>` directly.

**Windows: `'byte' is ambiguous` (std::byte vs Windows `byte`).**
Ensure `WIN32_LEAN_AND_MEAN` is defined before any `<windows.h>` include (this
excludes the OLE/COM headers that define a conflicting `byte`).

**Linux: runtime error about missing `libGLU`/OpenGL.**
Install `libglu1-mesa-dev` (build) / the GLU + OpenGL runtime (run), and ensure a
working GL driver.

**App starts but shows “Error loading XML”.**
`nif.xml`/`kfm.xml` must sit next to the executable. Use `cmake --install` (which
stages them) rather than running the raw build-tree binary in isolation.
