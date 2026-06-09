# NOTICE

**uintSkope** is a community fork and modernization of **NifSkope**, the NIF file
viewer/editor developed by the **NIF File Format Library and Tools (NIFTools)**
project.

uintSkope is **not** an official NIFTools product and is **not endorsed by or
affiliated with** the NIFTools project. All references to NifSkope and NIFTools
are for attribution only.

---

## Upstream project

- **NifSkope** — https://github.com/niftools/nifskope
- **NIFTools** — https://www.niftools.org / https://forum.niftools.org
- The NIF/KF/KFM file format definitions (`nif.xml`, `kfm.xml`) come from the
  **nifdocsys** project — https://github.com/niftools/nifdocsys (vendored as the
  `build/docsys` submodule).

uintSkope retains NifSkope's original BSD license (see [LICENSE.md](LICENSE.md))
and contributor credits (see [CONTRIBUTORS.md](CONTRIBUTORS.md)). The copyright
and license headers in the source files are preserved unchanged.

> Copyright (c) 2005-2015, NIF File Format Library and Tools
> All rights reserved. (BSD 3-clause — see LICENSE.md)

---

## Third-party components

uintSkope bundles or links the following third-party software. Their licenses and
copyrights are retained:

| Component | Purpose | License / Copyright |
|-----------|---------|---------------------|
| **zlib** (`lib/zlib`, submodule) | compression (BSA, NIF) | zlib license — © 1995-2017 Jean-loup Gailly & Mark Adler |
| **qhull** (`lib/qhull`, submodule) | convex hulls (Havok) | Qhull license — © 1993-2015 C.B. Barber and The Geometry Center |
| **gli** + **glm** (`lib/gli`, submodule) | DDS/texture loading | MIT — © 2010-2016 G-Truc Creation |
| **LZ4** (`lib/lz4frame.c`, `lib/xxhash.*`) | BSA v105 decompression | BSD 2-clause — © 2011-2015 Yann Collet |
| **NvTriStrip** (`lib/NvTriStrip`) | triangle stripification | NVIDIA SDK license |
| **half** (`lib/half.*`) | 16-bit float support | — |
| **NifMopp.dll** (`dep/NifMopp.dll`) | Havok MOPP generation (Win32) | Uses Havok(R) — © 1999-2008 Havok.com Inc. |
| **Qt 6** | application framework | LGPLv3 / commercial — The Qt Company |

Full attribution text for these components is shown in the application's
**Help → About uintSkope** dialog.

---

## What this fork changes

uintSkope modernizes the build and tooling around NifSkope without altering the
NIF/KF/KFM file-format behavior. See [MODERNIZATION_REPORT.md](MODERNIZATION_REPORT.md)
for the full list of changes. In summary: a CMake build system, a Qt 6 port, and
GitHub Actions CI/CD replace the original qmake + Travis/AppVeyor setup.
