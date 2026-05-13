# CI and build

Conventions for CI configs, build scripts, and platform docs. Part of the repository agent instructions; start from [AGENTS.md](../../AGENTS.md).

## Where things live

- **ci/** — GitLab CI job definitions (`.yml`), Dockerfiles, and shared templates (`macos.yml`, `docker.yaml`, `lint.yml`, `package.yml`).
- **tools/** — Dependency and packaging scripts (`buildgdk.sh`, `buildhidapi.sh`, `test.sh`, `lint/cpplint.sh`, …).
- **doc/** — Human-facing build and test docs, often mirroring what CI and `tools/` do:
  - [doc/linux/README.md](../linux/README.md), [doc/linux/build.sh](../linux/build.sh)
  - [doc/macos/README.md](../macos/README.md), [doc/macos/build.sh](../macos/build.sh)
  - [doc/windows/README.md](../windows/README.md), [doc/windows/build.bat](../windows/build.bat), [doc/windows/build-dependencies.sh](../windows/build-dependencies.sh)
  - [doc/tests/README.md](../tests/README.md) (unit tests via [tools/test.sh](../../tools/test.sh))

## Platform parity in CI

Keep **OS-specific CI files in sync** when a change applies to more than one variant.

| Platform | Typical files to update together |
|----------|----------------------------------|
| **macOS** | `ci/macos-x86_64.yml` **and** `ci/macos-arm64.yml` (shared base: `ci/macos.yml`). Universal packaging may also touch `ci/macos-universal.yml`. |
| **Linux** | `ci/linux-x86_64.yml` and `ci/linux-x86_64/Dockerfile` / `ci/linux-x86_64/setup.sh` as needed. |
| **Windows** | `ci/windows-x86_64.yml`, `ci/windows-x86_64/`, and `ci/x64-windows/` helpers when the same step exists there. |

Example: adding a dependency build step on macOS usually means adding the same `tools/build*.sh` invocation to **both** `macos-x86_64:depends` and `macos-arm64:depends` (only `PREFIX`, `ARCH`, brew paths, and cache keys differ).

## When you change builds

If you change **how** the project is built (new dependency script, new CMake option, new test step, different `qt-cmake` flags, CI job script, …):

1. Update the matching **CI YAML** under `ci/`.
2. Update the relevant **`tools/`** script(s) if the logic lives there.
3. Update **`doc/**`** so local builds and CI stay aligned (README steps, `doc/*/build.sh`, `doc/tests/README.md`, etc.).

Do not change CI or `tools/` alone and leave `doc/` describing the old flow.

## Lint and packaging

- **Lint**: `ci/lint.yml` — keep in sync with [tools/lint/](../../tools/lint/) if lint commands change.
- **Release / packages**: `ci/package.yml`, platform package jobs — follow existing patterns in the same file family.
