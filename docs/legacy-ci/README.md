# Legacy CI configuration (archived)

These are the **original NifSkope CI configurations**, kept here for historical
reference only. They are **no longer active** — they have been moved out of the
repository root so Travis CI and AppVeyor do not pick them up.

uintSkope's CI/CD now runs on **GitHub Actions**:

- [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) — matrix build & test (Windows/Linux/macOS, Qt 6)
- [`.github/workflows/release.yml`](../../.github/workflows/release.yml) — packaged release artifacts + checksums

| Legacy file | Original platform | Replaced by |
|-------------|-------------------|-------------|
| `travis.yml`   | Linux + macOS, Qt 5.7, qmake | GitHub Actions CI |
| `appveyor.yml` | Windows, VS2015, Qt 5.7, qmake → msbuild → 7z | GitHub Actions CI + Release |

Do not re-add these to the repository root.
