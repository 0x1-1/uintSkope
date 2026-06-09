# uintSkope

[![CI](https://github.com/0x1-1/uintSkope/actions/workflows/ci.yml/badge.svg)](https://github.com/0x1-1/uintSkope/actions/workflows/ci.yml)

**uintSkope** is a maintained, modernized fork of
[**NifSkope**](https://github.com/niftools/nifskope) — a desktop tool for opening,
viewing and editing the **NetImmerse / Gamebryo** file formats used by games such
as Morrowind, Oblivion, Skyrim, Fallout 3, Fallout: New Vegas, Civilization IV and
many others.

> uintSkope is an independent community fork. It is **not affiliated with or
> endorsed by** the NIFTools project. See [NOTICE.md](NOTICE.md).

This fork keeps NifSkope's file-format behavior intact while modernizing the
project around it: a **CMake** build system, a **Qt 6** port, and **GitHub Actions**
CI/CD with automatic release artifacts. See
[MODERNIZATION_REPORT.md](MODERNIZATION_REPORT.md) for the full list of changes.

---

## Supported file types

| Format | Extensions |
|--------|-----------|
| NIF (NetImmerse/Gamebryo) | `.nif`, `.btr`, `.bto`, `.nifcache`, `.texcache`, `.pcpatch`, `.jmi` |
| KF (Keyframe animation) | `.kf`, `.kfa` |
| KFM (Keyframe motion) | `.kfm` |
| Textures | `.dds` (and via Qt image plugins) |
| Archives | Bethesda `.bsa` / `.ba2` (browse & extract) |
| Import / export | Wavefront `.obj`, `.3ds`, COLLADA `.dae` |

NIF/KF/KFM format definitions are provided by the bundled
[`nifdocsys`](https://github.com/niftools/nifdocsys) data (`nif.xml`, `kfm.xml`).

## Supported platforms

- **Windows** 10/11 (x64) — MSVC or MinGW
- **Linux** (x64) — GCC/Clang, requires an OpenGL driver
- **macOS** — Apple Clang

Requires **Qt 6** (6.2 or newer) at build time.

---

## Building

Quick start (any platform with CMake ≥ 3.21, Ninja, a C++20 compiler and Qt 6):

```bash
git clone --recursive https://github.com/0x1-1/uintSkope.git
cd uintSkope

# If you cloned without --recursive:
git submodule update --init --recursive

cmake --preset release      # Qt 6 must be discoverable (CMAKE_PREFIX_PATH or PATH)
cmake --build --preset release
ctest --preset release --output-on-failure
```

Run the result, or produce a self-contained install tree:

```bash
cmake --install out/build/release --prefix dist
```

On Windows/macOS this stages the executable together with its Qt runtime
(`windeployqt`/`macdeployqt`) and the data files, ready to zip.

See **[BUILDING.md](BUILDING.md)** for detailed per-platform instructions,
Qt installation notes, and troubleshooting.

### Build options

| Option | Default | Purpose |
|--------|---------|---------|
| `UINTSKOPE_BUILD_TESTS` | `ON` | Build the non-GUI smoke tests |
| `UINTSKOPE_ENABLE_WARNINGS` | `ON` | `-Wall -Wextra` / `/W4 /permissive-` on first-party code |
| `UINTSKOPE_WARNINGS_AS_ERRORS` | `OFF` | Treat warnings as errors |
| `UINTSKOPE_USE_SYSTEM_ZLIB` | `OFF` | Use system zlib instead of the vendored copy |
| `UINTSKOPE_USE_SYSTEM_QHULL` | `OFF` | Use system qhull (experimental — see BUILDING.md) |

---

## Relationship to NifSkope

uintSkope is a fork of NifSkope at `niftools/nifskope`. **All original copyright,
license headers, and contributor credits are preserved unchanged.** The NIF file
format and NifSkope itself are the work of the NIFTools community
([forum](https://forum.niftools.org), [Discord](https://discord.gg/ZFjdN4x)).

For questions about the **NIF format**, please use the upstream NIFTools channels.
For issues specific to **uintSkope** (the build system, packaging, Qt 6 behavior),
use this repository's issue tracker.

## License & attribution

- uintSkope retains NifSkope's **BSD license** — see [LICENSE.md](LICENSE.md).
- Contributors — see [CONTRIBUTORS.md](CONTRIBUTORS.md).
- Third-party components & attribution — see [NOTICE.md](NOTICE.md).
- Troubleshooting — see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
- Changes — see [CHANGELOG.md](CHANGELOG.md).
