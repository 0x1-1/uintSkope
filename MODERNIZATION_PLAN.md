# uintSkope Modernization Plan (internal)

> Working document written during the modernization pass that turns the upstream
> NifSkope (`niftools/nifskope`, branch `develop`, commit `3a85ac5`) fork into
> **uintSkope** — a CMake + Qt 6 desktop application with automated CI/CD.
>
> This file captures the *starting state* and *intended steps*. The authoritative
> record of what actually happened is `MODERNIZATION_REPORT.md`.

---

## 1. Current build system

* **qmake** project: `NifSkope.pro` + `NifSkope_functions.pri` (version/sed/copy
  helpers) + `NifSkope_targets.pri` (lupdate/lrelease, docsys, doxygen targets).
* `TEMPLATE = app`, `TARGET = NifSkope`, `QT += xml opengl network widgets`.
* C++14 (`CONFIG += c++14`).
* Hand-rolled post-link copy steps that stage `nif.xml`, `kfm.xml`, `style.qss`,
  `shaders/`, README/CHANGELOG/LICENSE (renamed `.md`→`.txt`), and on Windows the
  Qt DLLs + `platforms`/`imageformats` plugins.
* Version macros injected via `DEFINES += NIFSKOPE_VERSION=...` / `NIFSKOPE_REVISION=...`
  computed from `build/VERSION` and `.git/HEAD`.

## 2. Current dependencies

| Dependency | Form | Decision |
|-----------|------|----------|
| `build/docsys` | git submodule (nifdocsys) — provides `nif.xml`, `kfm.xml` | **Keep submodule** (data files, required at runtime) |
| `lib/gli` | git submodule (gli + bundled glm) — DDS/texture loading | **Keep submodule** (header-only, `isystem` include) |
| `lib/qhull` | git submodule — convex hull for havok | **Keep submodule**, compile a minimal static lib; option for system qhull |
| `lib/zlib` | git submodule — BSA/compression | **Keep submodule**, compile into app; option for system zlib |
| `lib/NvTriStrip` | vendored source | Compile into core |
| `lib/fsengine` | vendored source (BSA archive engine) | Compile into core |
| `lib/lz4frame.c`,`lib/xxhash.c` | vendored source | Compile into core (`LZ4_STATIC XXH_PRIVATE_API`) |
| `lib/half.cpp`, `lib/dds.h`, `lib/dxgiformat.h` | vendored source/headers | Compile/include into core |
| `dep/NifMopp.dll` | prebuilt 32-bit Windows DLL (havok mopp) | Keep, install only on Win32 |

All four submodules are **already initialised and populated** in this worktree.

## 3. Current Qt version assumptions

* Targets **Qt 5.7+**, explicitly rejects < 5.7. Real environment here ships
  **Qt 6.10.2** (mingw_64 + msvc2022_64). Goal = build against Qt 6.
* Qt-6-removed / changed APIs that must be ported:
  * `QGLWidget` / `QGLFormat` → `QOpenGLWidget` / `QSurfaceFormat` (`glview.*`, `uvedit.*`) — **highest risk**, touches renderer scaffolding.
  * `QMetaType::registerComparators<NifValue>()` → removed; Qt 6 auto-detects (`main.cpp`, `nifvalue.h`).
  * `QString::SkipEmptyParts` → `Qt::SkipEmptyParts` (`version.cpp`, `nifvalue.cpp`, `obj.cpp`, `nifcheckboxlist.cpp`).
  * `QRegExp` → `QRegularExpression` (`nifskope.cpp`, `col.cpp`, `nifcheckboxlist.cpp`).
  * `QDesktopWidget` → `QScreen`/`QGuiApplication` (`nifskope.cpp`, `col.cpp`, `nifcheckboxlist.cpp`).
  * `QMatrix` → `QTransform` (`colorwheel.cpp`).
  * `QT += opengl` must add the Qt 6 `openglwidgets` module.
* Internal renderer uses legacy fixed-function GL (`glBegin/glEnd`). `QOpenGLWidget`
  with a compatibility-profile `QSurfaceFormat` keeps that working — the rendering
  bodies stay; only widget/context/format plumbing changes.

## 4. Current executable / app naming

* Target/exe: `NifSkope` / `NifSkope.exe`. Org `NifTools`, domain `niftools.org`.
* App display name, window title, About dialog all read "NifSkope".

## 5. Current packaging / release state

* **AppVeyor** (`appveyor.yml`): Windows VS2015, Qt 5.7, qmake → msbuild → 7z zip
  artifacts (`nifskope_<platform>[_debug].zip`).
* **Travis** (`.travis.yml`): Linux/macOS, Qt 5.7, qmake → make; clang static analysis.
* NSIS installers under `install/win-install/`, Linux `.desktop`/`.spec`/mime XML
  under `install/linux-install/`.
* No GitHub Actions, no checksums, no GitHub Release automation.

## 6. Required migration steps

1. Create branch `modernize-uintSkope`; ensure submodules initialised.
2. **CMake build system**: root `CMakeLists.txt`, `CMakePresets.json`,
   `cmake/Dependencies.cmake`, `cmake/CompilerWarnings.cmake`, `cmake/InstallRules.cmake`.
   * `cmake_minimum_required(VERSION 3.21)`, C++20.
   * `find_package(Qt6 ... Widgets Xml Network OpenGL OpenGLWidgets)`.
   * AUTOMOC/AUTOUIC/AUTORCC; compile `.ui`, `.qrc`.
   * Submodule presence checks with actionable error.
   * Options: `UINTSKOPE_BUILD_TESTS`, `UINTSKOPE_ENABLE_WARNINGS`,
     `UINTSKOPE_WARNINGS_AS_ERRORS`, `UINTSKOPE_USE_SYSTEM_ZLIB`, `UINTSKOPE_USE_SYSTEM_QHULL`.
   * Generate `uintskope_version.h` (configure-time) with version + git revision.
3. **Qt 6 source port**: the API table in §3 — smallest reliable edits, build-tested.
4. **Branding**: exe target `uintSkope`, window title, About dialog, app/display
   names, README title, artifact names — while keeping domain class names
   (`NifModel`, `NifValue`, `NifSkopeVersion`, …) and all upstream attribution/licence.
5. **GitHub Actions**: `.github/workflows/ci.yml` (matrix Win/Linux/macOS) +
   `release.yml` (tag `v*` / dispatch → packaged artifacts + checksums + Release).
6. **Packaging**: `windeployqt`/`macdeployqt` via install rules + CPack-style zips/tarball.
7. **Docs**: `README.md`, `BUILDING.md`, `NOTICE.md`, `CHANGELOG.md`,
   `MODERNIZATION_REPORT.md`.
8. **Tests**: non-GUI smoke tests (version logic, XML load) behind `UINTSKOPE_BUILD_TESTS`.
9. **Cleanup**: retire Travis/AppVeyor (documented), modernise `.gitignore`.
10. **Verify**: configure + build (Qt 6.10.2 mingw_64 + Ninja) + ctest; record results.

## 7. Known risks

* **Renderer port** (`QGLWidget`→`QOpenGLWidget`) is the deepest change; context
  sharing / `makeCurrent` / format semantics differ. Mitigation: compatibility
  `QSurfaceFormat`, keep render bodies, build often.
* **`registerComparators` removal** requires `NifValue` to expose `operator==`/`<`
  visible to Qt 6's metatype system, or sort/compare features regress.
* Hand-rolled qmake copy steps → must be faithfully reproduced as CMake install
  rules so runtime data (xml/shaders/qss/plugins) is present next to the exe.
* `dep/NifMopp.dll` is 32-bit only; 64-bit builds disable mopp code path (already
  guarded by `win32:contains(QT_ARCH, i386)` upstream).
* Local build uses MinGW kit; CI will additionally exercise MSVC + Linux + macOS,
  which may surface platform-specific issues not visible locally.

## 8. Decisions taken (so I don't blind-rename)

* Keep all `NifSkope*` **domain/class** identifiers and the `nifskope.*` source
  filenames (renaming them is high-risk and the format domain genuinely is "NIF").
* Rename only **product/app-level** visible identifiers + add new branding.
* Prefer **Qt 6 REQUIRED** (no Qt 5 fallback path) to match the project goal.
* Local verification toolchain: **Qt 6.10.2 `mingw_64` + MinGW 13.1.0 + CMake 3.30.5 + Ninja**
  (self-contained, no `vcvarsall` needed); MSVC reserved for CI.
