# uintSkope Modernization Report

Modernization of the upstream **NifSkope** (`niftools/nifskope`, branch `develop`,
commit `3a85ac5`) into **uintSkope** — a CMake + Qt 6 desktop application with
GitHub Actions CI/CD.

This is the authoritative record of what changed and why. The planning notes are in
[MODERNIZATION_PLAN.md](MODERNIZATION_PLAN.md).

---

## 1. Summary of architectural changes

| Area | Before | After |
|------|--------|-------|
| Build system | qmake (`NifSkope.pro` + 2 `.pri`) | CMake ≥ 3.21 (`CMakeLists.txt`, presets, `cmake/` modules) |
| Language std | C++14 | C++20 |
| Qt | Qt 5.7+ | Qt 6 (2.6+; built & verified against 6.10.2) |
| Renderer widget | `QGLWidget` | `QOpenGLWidget` (compatibility profile) |
| XML parser | Qt SAX (`QXmlDefaultHandler`) | `QXmlStreamReader` pull parser |
| CI | Travis + AppVeyor (Qt 5.7) | GitHub Actions matrix (Win/Linux/macOS, Qt 6) |
| Release | manual 7z zips | tagged GitHub Release with checksummed artifacts |
| Product name | NifSkope | **uintSkope** (executable, window title, About, `--version`) |
| Deployment | hand-rolled qmake copy steps | CMake install + windeployqt/macdeployqt (flat layout) |

The NIF/KF/KFM **file-format behavior is intentionally unchanged**. Domain class
and file names (`NifModel`, `NifValue`, `NifItem`, `nifskope.cpp`, …) were kept —
only product/application-level identifiers were rebranded.

## 2. Files renamed / moved

- `.travis.yml` → `docs/legacy-ci/travis.yml` (deactivated; archived for reference)
- `appveyor.yml` → `docs/legacy-ci/appveyor.yml` (deactivated; archived)

No source files were renamed. The product is renamed via CMake target name
(`uintSkope` → `uintSkope.exe`/`.app`) and compiled-in branding macros, **not** by
renaming `nifskope.*`.

## 3. Files added

| File | Purpose |
|------|---------|
| `CMakeLists.txt` | Root build: version parsing, Qt6, target, options, branding macros |
| `CMakePresets.json` | Portable `release` / `debug` / `ci-release` presets (Ninja) |
| `cmake/Dependencies.cmake` | gli/qhull/zlib as targets; submodule checks; system-package options |
| `cmake/CompilerWarnings.cmake` | Warning policy (first-party only); vendored sources silenced |
| `cmake/InstallRules.cmake` | Flat install layout + windeployqt/macdeployqt |
| `src/gl/glu_include.h` | Windows-safe `<GL/glu.h>` wrapper (windows.h + LEAN_AND_MEAN first) |
| `tests/CMakeLists.txt`, `tests/test_version.cpp`, `tests/test_xml_wellformed.cpp` | Non-GUI smoke tests |
| `.github/workflows/ci.yml` | Matrix build & test |
| `.github/workflows/release.yml` | Packaged release + checksums + GitHub Release |
| `README.md` (rewritten), `BUILDING.md`, `NOTICE.md`, `MODERNIZATION_PLAN.md`, `MODERNIZATION_REPORT.md` | Documentation |
| `docs/legacy-ci/README.md` | Explains the archived CI configs |

## 4. Build system changes

- `cmake_minimum_required(VERSION 3.21)`, `project(uintSkope ...)`.
- Version: the human-facing string (e.g. `2.0.dev7`) is read from `build/VERSION`;
  a numeric `MAJOR.MINOR.PATCH` is derived for `project(VERSION ...)` (CMake
  requires numeric). Git revision via `git rev-parse --short=7 HEAD`. Both the
  legacy `NIFSKOPE_VERSION`/`NIFSKOPE_REVISION` macros (for existing code) and new
  `UINTSKOPE_*` macros are compiled in.
- AUTOMOC/AUTOUIC/AUTORCC enabled; `.ui` and `.qrc` listed as target sources.
  `src/gl/icontrollable.h` is listed explicitly (header-only `Q_OBJECT` class with
  no `.cpp`, otherwise AUTOMOC would miss it).
- Options: `UINTSKOPE_BUILD_TESTS`, `UINTSKOPE_ENABLE_WARNINGS`,
  `UINTSKOPE_WARNINGS_AS_ERRORS`, `UINTSKOPE_USE_SYSTEM_ZLIB`,
  `UINTSKOPE_USE_SYSTEM_QHULL`.
- Warnings (`-Wall -Wextra` / `/W4 /permissive-`) apply to first-party code only;
  vendored TUs are silenced to avoid noise. Warnings-as-errors stays OFF.
- C++20 was used throughout with **no per-file downgrade required**.

## 5. Dependency changes

All four submodules are kept (deterministic, offline builds). Decisions:

| Dependency | Form | Handling |
|-----------|------|----------|
| `build/docsys` (nif.xml/kfm.xml) | submodule | Kept; installed beside the binary |
| `lib/gli` (+glm) | submodule | Header-only `INTERFACE` target (SYSTEM includes) |
| `lib/qhull` | submodule | **Include-dir only** — `src/lib/qhull.cpp` is a unity include of qhull's `.c` files; compiling qhull separately would duplicate symbols |
| `lib/zlib` | submodule | Built as `uintskope_zlib` static lib; `UINTSKOPE_USE_SYSTEM_ZLIB` to opt into system zlib |
| `lib/lz4frame.c`, `lib/xxhash.*` | vendored | `lz4frame.c` compiled; **`xxhash.c` excluded** (with `XXH_PRIVATE_API` the impl is header-only and included by `lz4frame.c`; compiling `xxhash.c` too redefines every symbol) |
| `lib/NvTriStrip`, `lib/fsengine`, `lib/half` | vendored | Compiled into the app |
| `dep/NifMopp.dll` | prebuilt 32-bit | Installed only for 32-bit Windows builds |

`UINTSKOPE_USE_SYSTEM_QHULL` is provided but **experimental**: the qhull wrapper
`#include`s qhull's `.c` sources directly, so a system qhull (headers only) is not a
drop-in. The vendored path is the supported default.

## 6. Qt 6 migration notes

Ported APIs that were removed or changed in Qt 6:

| Qt 5 API | Qt 6 replacement | Files |
|----------|------------------|-------|
| `QGLWidget` / `QGLFormat` | `QOpenGLWidget` / `QSurfaceFormat` (compat profile) | `glview.*`, `uvedit.*` |
| `qglClearColor` / `swapBuffers` / `updateGL` | `glClearColor` helper / (auto) / `update` | `glview.*`, `uvedit.*` |
| GL context in ctor | resolved in `initializeGL()`, propagated via `Renderer::setContext()` | `glview.cpp`, `renderer.h` |
| `QXmlDefaultHandler` SAX + `QXmlAttributes` + `QXmlParseException` | `QXmlStreamReader` pull loop + adapter | `nifxml.cpp`, `kfmxml.cpp` |
| `QModelIndex::child(r,c)` (≈390 calls) | `idx.model()->index(r,c,idx)` via `getChildIndex()` helper | repo-wide |
| `QMetaType::registerComparators` | auto-detected from `operator==` | `main.cpp` |
| `QString::SkipEmptyParts` | `Qt::SkipEmptyParts` | 4 files |
| `QRegExp` / `setFilterRegExp` | `QRegularExpression` / `setFilterRegularExpression` | `nifskope.cpp`, `bsa.cpp`, … |
| `QMatrix` | `QTransform` | `colorwheel.cpp` |
| `QMap::insertMulti` | `QMultiMap` + `insert` | 3ds, skeleton, uvedit, … |
| `QAbstractItemView::viewOptions()` | `initViewItemOption()` | `nifview.*` |
| `QFontMetrics::width` | `horizontalAdvance` | `nifdelegate.cpp`, `floatslider.cpp`, `nifskope_ui.cpp` |
| `QWheelEvent::delta()` | `angleDelta().y()` | `glview.cpp`, `uvedit.cpp` |
| `Qt::MidButton`, `Qt::BackgroundColorRole`, `QPalette::Background`, `QPainter::HighQualityAntialiasing`, `QButtonGroup::buttonClicked(int)`, `QComboBox::activated(QString)`, `QLabel::pixmap()*`, `QLineF::angle(line)`, `QSet::fromList`, `QList::toStdList`, `QFileInfo::created`, `QFlags + int` | various | several files |
| `QGraphicsView`-related `setMargin` | `setContentsMargins` | layout widgets |
| `Triangle` as a `QMap` key | added `Triangle::operator<` (removed `qMapLessThanKey` specialization) | `niftypes.h`, `skeleton.cpp` |

Windows-specific build fixes:
- `WINDOWS_LEAN_AND_MEAN` typo → `WIN32_LEAN_AND_MEAN` (excludes OLE/COM headers
  whose `byte` typedef clashes with C++17 `std::byte`).
- `src/gl/glu_include.h` pulls `<windows.h>` (lean) before `<GL/glu.h>`.

Cross-window GL resource sharing is now enabled globally via
`Qt::AA_ShareOpenGLContexts` (was a per-widget share object).

## 7. CI/CD changes

- **`.github/workflows/ci.yml`** — triggers on push, PR and manual dispatch.
  Matrix: `windows-latest` (MSVC), `ubuntu-latest` (GCC), `macos-latest` (Clang).
  Steps: checkout (recursive submodules) → install Qt 6 (`jurplel/install-qt-action`,
  `qtimageformats`) → platform deps (Ninja, MSVC env, GL/GLU on Linux) → CMake
  configure (Ninja, Release, warnings on) → build → `ctest` → upload build log on
  failure. `permissions: contents: read`.
- **`.github/workflows/release.yml`** — see §8.
- Travis/AppVeyor archived under `docs/legacy-ci/`.

## 8. Release workflow details

- Triggers: tag push matching `v*`, or manual `workflow_dispatch` (with a `tag` input).
- `permissions: contents: write`; uses the default `GITHUB_TOKEN` (no PATs/secrets).
- `package` matrix job per OS: build (Release) → `cmake --install --prefix dist`
  (runs windeployqt/macdeployqt) → package:
  - Windows → `uintSkope-windows-x64.zip` (flat, self-contained)
  - Linux → `uintSkope-linux-x64.tar.gz` (install output; depends on system Qt 6 — see limitations)
  - macOS → `uintSkope-macos-arm64.zip` (self-contained `.app`; single-arch, not universal)
  - each with a `.sha256` sidecar.
- `release` job: downloads all artifacts, generates a combined `SHA256SUMS`, and
  creates a **draft** GitHub Release (`softprops/action-gh-release@v2`) with the
  archives + checksums attached. Draft so a human can sanity-check before publishing.

Artifact names, package paths, and checksum/upload steps were cross-checked for
consistency, and the local equivalent (`cmake --install` + zip) was verified to
produce a runnable, self-contained tree (see §10).

## 9. Known limitations / not completed

- **Local build/test platform:** verified on **Windows with the Qt 6.10.2 mingw_64
  kit + MinGW 13.1 + Ninja**. The MSVC, Linux and macOS paths are exercised only by
  CI (not run on this machine) — CI may surface platform-specific issues.
- **GUI not exercised end-to-end:** the app builds, links, and runs to the point of
  CLI handling (`--version` works standalone). A full interactive render/edit
  session and the **supersampled screenshot-to-FBO** path (which relied on
  `QGLWidget` semantics) need runtime validation under `QOpenGLWidget`; the code
  compiles and the normal viewport path is preserved, but the FBO screenshot path
  is flagged in `glview.cpp` for follow-up.
- **Linux release artifact** is a tarball of the install output and **requires a
  system Qt 6 + OpenGL runtime**; a self-contained AppImage (`linuxdeploy`) is a
  documented future enhancement, intentionally not wired in unverified.
- **macOS artifact is single-arch** (runner arch), not a universal binary.
- **Settings location moved** to the `uintSkope` key (the app is rebranded), so an
  existing NifSkope install's settings do not carry over. Documented in `main.cpp`.
- **README badge URL** assumes the `0x1-1/uintSkope` repo; adjust if the remote differs.
- `UINTSKOPE_USE_SYSTEM_QHULL` is experimental (see §5).

## 10. Commands executed & results

Toolchain (local): CMake 3.30.5, Ninja, MinGW GCC 13.1.0, Qt 6.10.2 (mingw_64).

```
cmake --preset local-mingw                          # configure: OK
cmake --build --preset local-mingw                  # build:     OK, uintSkope.exe (6.6 MB)
ctest --preset local-mingw                           # tests:     2/2 passed (version_logic, xml_wellformed)
cmake --install out/build/local-mingw                # install:   OK, windeployqt ran
env -i PATH=System32 ./uintSkope.exe --version       # run:       "uintSkope 2.0 2.0.dev7" (standalone, no Qt on PATH)
```

Build error count over the port: 733 → 207 → 28 → 1 → **0** (then a link-stage
AUTOMOC fix) → clean. Final state: **0 compile errors, 0 link errors, 2/2 tests
passing, runnable self-contained install (~81 MB) verified**.

YAML for both workflows validated with `yaml.safe_load` (structure + triggers OK).
