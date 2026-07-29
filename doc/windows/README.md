## Building the Blockstream app for Windows

**Important:** The Windows build is split into two phases. **You must build GDK (and libserialport) first on Linux with MinGW** — they are cross-compiled and cannot be built natively on Windows for this project. The rest of the build (application, Countly, ZXing, hidapi, leveldb, LWK, GLSDK, etc.) is done on Windows with MSVC and Qt.

**Quick start:**

1. **Phase 1 (Linux):** In WSL2 or a Linux environment, run `./doc/windows/build-dependencies.sh` from the repo root. Copy the artifacts to `C:\depends\windows-x86_64` on your Windows machine.
2. **Phase 2 (Windows):** Open "x64 Native Tools Command Prompt for VS 2022", `cd` to the repo, and run `doc\windows\build.bat`.

Both scripts support resume on failure: run again to continue. Use `--restart` to start over.

---

## Overview

1. **Phase 1 (Linux with MinGW):** Build GDK and libserialport for Windows. This produces DLLs and `.def` files that you copy to your Windows machine.
2. **Phase 2 (Windows):** Install Visual Studio Build Tools and Qt, generate `.lib` import libraries for GDK/libserialport from `.def`, build the remaining native dependencies (Countly, KDSingleApplication, ZXing, hidapi, leveldb, LWK, GLSDK) with the `ci\x64-windows\*.bat` scripts, then build the application with CMake.

The layout expected by the main project is:

- **`C:\depends\windows-x86_64`** — MinGW-built dependencies (GDK, libserialport) from Phase 1: `bin/` (DLLs + `.def`), `lib/` (`.lib` created on Windows), `include/`
- **`C:\deps`** — Native Windows builds from Phase 2 (`countly`, `kdsingleapplication`, `zxing`, `hidapi`, `leveldb`, `lwk`, `glsdk`)
- CMake uses `CMAKE_PREFIX_PATH=C:\deps;C:\depends\windows-x86_64`

If you use different paths, adjust the steps and/or `CMakeLists.txt` (which currently hardcodes `C:/depends/windows-x86_64` for GDK on Windows).

---

## Phase 1: Build GDK and libserialport on Linux (MinGW)

GDK must be built on Linux with MinGW; the same applies to libserialport for the Windows target. You need a **Linux environment** with **bash** and the tools listed below. Use one of:

| Option                            | Console to use                                         | Notes                                                         |
| --------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------- |
| **WSL2** (recommended on Windows) | Ubuntu app or `wsl` in PowerShell, then a bash shell   | Easiest: same machine, access Windows drives under `/mnt/c/`. |
| **Docker**                        | Terminal on your host; commands run inside a container | Use `ci/windows-x86_64/Dockerfile` to match CI.        |
| **Native Linux**                  | Any terminal (e.g. GNOME Terminal) with bash           | Use if you already have Ubuntu/Debian.                        |

All commands in Phase 1 are meant to be run in a **bash** shell on that Linux environment (WSL2, inside Docker, or native Linux). Do not use PowerShell or Command Prompt for Phase 1.

---

### 1.1 Choose and prepare your Linux environment

#### Option A: WSL2 (Windows Subsystem for Linux)

1. **Install WSL2** (if not already installed):
   - Open PowerShell **as Administrator** and run:
     ```powershell
     wsl --install
     ```
   - Reboot if prompted. After reboot, an Ubuntu distribution is usually installed by default.
2. **Launch Linux:** From the Start menu open **Ubuntu** (or the distro you installed), or run `wsl` from PowerShell. You get a bash prompt, e.g. `user@hostname:~$`.
3. **Install Ubuntu packages** (see section 1.2 below) inside this WSL2 shell. The project can live on the Windows filesystem (e.g. `/mnt/c/Users/...`) or inside WSL (e.g. `~/green_qt`). Building from a path under `/home` is often faster than from `/mnt/c/`.

#### Option B: Docker

1. **Install Docker Desktop for Windows** (or Docker Engine on Linux) and ensure Docker is running.
2. **Build the CI image** (from the repo root on Windows or Linux, in PowerShell or a normal terminal):
   ```bash
   docker build -f ci/windows-x86_64/Dockerfile -t green-windows-deps .
   ```
   That image already builds GDK and libserialport and puts them in `/depends`. To get the artifacts on your Windows machine, run a container and copy `/depends` out, e.g. (from PowerShell, after creating `C:\depends`):
   ```powershell
   docker run --rm -v C:\depends:/out green-windows-deps cp -a /depends /out/
   ```
   Then use `C:\depends\depends\windows-x86_64` (or move it to `C:\depends\windows-x86_64`) for Phase 2. Alternatively, use WSL2 or native Linux and follow sections 1.2–1.6 below to install tools and build step by step.

#### Option C: Native Linux (e.g. Ubuntu)

Use your usual terminal (bash). Install the packages from section 1.2 with `apt` as shown.

---

### 1.2 Install required packages (Debian/Ubuntu)

**1. Update the package list and install basics:**

```bash
sudo apt update
sudo apt install -y software-properties-common curl ca-certificates wget
```

**2. Install MinGW cross-compiler and build tools:**

These are required to build Windows DLLs from Linux. Install the MinGW toolchain and the `gendef` tool (used later to create `.def` files from DLLs):

```bash
sudo apt install -y \
  g++-mingw-w64-x86-64 \
  gcc-mingw-w64-x86-64 \
  mingw-w64 \
  mingw-w64-tools
```

**3. Install CMake, Git, and general build dependencies:**

```bash
sudo apt install -y \
  cmake \
  git \
  protobuf-compiler \
  unzip \
  automake \
  autoconf \
  pkg-config \
  libtool \
  build-essential \
  ninja-build
```

**4. Install Python (for GDK’s build scripts):**

```bash
sudo apt install -y \
  python3-venv \
  python3-pip \
  python3-setuptools \
  virtualenv
```

**5. Install libraries needed by GDK (X11, Mesa, etc.):**

GDK’s build uses several system libraries. Install at least:

```bash
sudo apt install -y \
  libgl1-mesa-dev \
  libx11-dev \
  libxcb1-dev \
  libxkbcommon-dev \
  libxcb-xkb-dev \
  libudev-dev
```

**6. Install Rust and add the Windows target (required for GDK):**

Run this in the same bash shell (do not use `sudo` for rustup):

```bash
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.88.0
source "$HOME/.cargo/env"
rustup target add x86_64-pc-windows-gnu
```

- The first command installs Rust (or updates it) with toolchain 1.88.0. If you already have Rust, ensure `rustc --version` reports 1.88.0 or higher.
- `source "$HOME/.cargo/env"` adds Rust to your PATH for this session; add it to `~/.bashrc` if you want it in every new shell.
- The last line adds the 64-bit Windows (GNU) target so GDK can be built for Windows.

**Verify:** In the same bash shell, run:

```bash
x86_64-w64-mingw32-g++-posix --version
rustc --version
gendef --version
protoc --version
```

You should see version output for the MinGW compiler, Rust, `gendef`, and `protoc`. If `gendef` is not found, ensure `mingw-w64-tools` is installed. If `protoc` is not found, install `protobuf-compiler`.

---

### 1.3 Clone the repo and set environment variables

**1. Clone the repository** (if you have not already), e.g.:

```bash
git clone https://github.com/Blockstream/green_qt.git
cd green_qt
```

If the repo is already on your Windows drive (e.g. under WSL2 at `/mnt/c/Users/.../green_qt`), just `cd` to that path.

**2. Set environment variables and create the prefix directory:**

Run these from the **project root** (directory that contains `tools/buildgdk.sh`). Replace `$PWD` with the full path to the repo if you prefer.

```bash
export PREFIX=/depends/windows-x86_64
export HOST=windows
export ARCH=x86_64
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export CMAKE_INSTALL_PREFIX=$PREFIX
export CMAKE_TOOLCHAIN_FILE=$PWD/cmake/mingw-w64-x86_64.cmake

mkdir -p $PREFIX/bin $PREFIX/lib $PREFIX/include
```

- `PREFIX` is where GDK and libserialport will be installed (headers, DLLs, etc.). Using `/depends/windows-x86_64` matches CI; you can use another path and then copy that folder to Windows later.
- `HOST=windows` tells the build scripts to cross-compile for Windows (MinGW).
- `CMAKE_TOOLCHAIN_FILE` points to the project’s MinGW CMake file so that CMake uses the MinGW compiler.

**3. Load Rust in this shell** (if you did not add it to `~/.bashrc`):

```bash
source "$HOME/.cargo/env"
```

---

### 1.4 Build GDK for Windows

Still in the **same bash shell**, from the **project root** (`green_qt`), with the variables above set:

**1. Build dependencies:**

```bash
./tools/buildgdk.sh
```

- `buildgdk.sh`: clones GDK, sets up a Python venv, and runs the GDK build with `--mingw-w64` (because `HOST=windows`). When it finishes, GDK is installed under `$PREFIX`; the DLL is also produced in the build tree.

**2. Copy the DLL and generate the `.def` file:**

The DLL is built at `build/gdk/build-windows-mingw-w64/src/libgreen_gdk.dll`. Copy it into `$PREFIX/bin` and run `gendef` to create a `.def` file (needed on Windows for MSVC to create an import library):

```bash
cp build/gdk/build-windows-mingw-w64/src/libgreen_gdk.dll $PREFIX/bin/
cd $PREFIX/bin && gendef libgreen_gdk.dll && cd -
```

`gendef` creates `libgreen_gdk.def` in the current directory (`$PREFIX/bin`). Headers should already be under `$PREFIX/include/gdk` (and `include/gdk/libwally-core` if present) from the GDK install step; if not, the `buildgdk.sh` script’s install target should have put them there—check `$PREFIX/include` and adjust if your layout differs.

---

### 1.5 Build libserialport for Windows

In the **same bash shell**, with the **same environment variables** still set (`PREFIX`, `HOST=windows`, etc.), from the **project root**:

**1. Build libserialport:**

```bash
./tools/buildlibserialport.sh
```

This configures and builds libserialport for `x86_64-w64-mingw32` and installs into `$PREFIX`. The DLL is typically installed to `$PREFIX/bin/libserialport-0.dll`.

**2. Generate the `.def` file for the DLL:**

```bash
cd $PREFIX/bin && gendef libserialport-0.dll && cd -
```

If the DLL is elsewhere (e.g. `$PREFIX/lib`), adjust the path. You should now have `libserialport-0.def` in `$PREFIX/bin`.

---

### 1.6 Copy Phase 1 artifacts to Windows

Copy the **entire** `$PREFIX` tree to your Windows machine so that Phase 2 can use it.

- **From WSL2:** The Windows `C:` drive is usually at `/mnt/c`. For example, to copy to `C:\depends\windows-x86_64`:

  ```bash
  mkdir -p /mnt/c/depends
  cp -a $PREFIX /mnt/c/depends/windows-x86_64
  ```

- **From Docker:** Mount the repo (and optionally a host directory for `depends`) when running the container, or copy the built `$PREFIX` out of the container with `docker cp` after the build.

- **From another machine:** Use `scp`, a USB drive, or a shared folder to copy the folder that `$PREFIX` points to (e.g. `/depends/windows-x86_64`) to `C:\depends\windows-x86_64` on the Windows PC where you will run Phase 2.

**Check that on Windows you have:**

- `C:\depends\windows-x86_64\bin\` — `libgreen_gdk.dll`, `libgreen_gdk.def`, `libserialport-0.dll`, `libserialport-0.def`
- `C:\depends\windows-x86_64\include\` — GDK and libserialport headers (e.g. `gdk/`, `libwally-core/`, and serialport headers)
- `C:\depends\windows-x86_64\lib\` — can be empty for now; Phase 2 will create `libgreen_gdk.lib` and `libserialport-0.lib` here from the `.def` files.

---

## Phase 2: Build on Windows

### 2.1 Prerequisites

- **Visual Studio 2022 Build Tools** (or full Visual Studio) with:
  - C++ build tools
  - CMake
  - Ninja
- **Qt 6.11.1** (or the version used in CI) for MSVC 2022 64-bit, e.g. installed under `C:\qt\6.11.1\msvc2022_64`.
- **Git** and **7-Zip** (e.g. via Chocolatey), for cloning and extracting sources.
- **Rust** via `rustup` for the native LWK and GLSDK steps:
  - Default toolchain: `1.88.0`
  - Extra toolchain used in LWK: `1.85.0-x86_64-pc-windows-msvc`
- **Python** (for GDK was already used on Linux; not required on Windows for the steps below).
- **Protobuf compiler** (`protoc`) to build GLSDK.

### 2.2 Create import libraries (.lib) from .def files

MSVC needs `.lib` import libraries to link against the MinGW-built DLLs. From a **x64 Native Tools Command Prompt for VS 2022** (or after running `vcvarsall.bat x64`):

```bat
lib /def:C:\depends\windows-x86_64\bin\libgreen_gdk.def /out:C:\depends\windows-x86_64\lib\libgreen_gdk.lib /machine:x64
lib /def:C:\depends\windows-x86_64\bin\libserialport-0.def /out:C:\depends\windows-x86_64\lib\libserialport-0.lib /machine:x64
```

### 2.3 Build native dependencies (Countly, KDSingleApplication, ZXing, hidapi, leveldb, LWK, GLSDK)

The CI builds these on Windows in the `x64-windows` image; see `ci/x64-windows/*.bat`. Set the prefix and use the same compiler environment (e.g. `vcvarsall.bat x64`):

```bat
set PREFIX=C:\deps
```

Then run (from a directory where you have the repo and where the scripts can clone dependencies):

- **Countly:** `ci\x64-windows\countly.bat`
- **KDSingleApplication:** `ci\x64-windows\kdsingleapplication.bat` (expects Qt at `\qt\6.11.1\msvc2022_64`; adjust if your Qt path is different)
- **ZXing:** `ci\x64-windows\zxing.bat`
- **hidapi:** `ci\x64-windows\hidapi.bat`
- **leveldb:** `ci\x64-windows\leveldb.bat`
- **LWK:** `ci\x64-windows\lwk.bat`
- **GLSDK:** `ci\x64-windows\glsdk.bat`

Each script clones the dependency, configures with CMake, builds, and installs into `%PREFIX%`. Ensure `PREFIX` is set and that the VS environment is active.

### 2.4 Configure and build the application

From the repository root, in a command prompt where **Visual Studio environment is loaded** (e.g. `vcvarsall.bat x64`):

```bat
set PREFIX=C:\deps
set CMAKE_PREFIX_PATH=C:\deps;C:\depends\windows-x86_64

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
```

`CMAKE_PREFIX_PATH` (set above) is read from the environment, and the remaining options
come from the `dev-windows` preset in [`CMakePresets.json`](../../CMakePresets.json). If you
use a different VS or Qt path, adjust the next lines accordingly:

```bat
call C:\qt\6.11.1\msvc2022_64\bin\qt-cmake --preset dev-windows

cmake --build bld --config RelWithDebInfo
```

For a production-style build (e.g. release), override the preset on the command line:

```bat
-DGREEN_ENV=Production -DGREEN_BUILD_ID=
```

### 2.5 Deploy Qt and copy DLLs

After a successful build:

```bat
C:\qt\6.11.1\msvc2022_64\bin\windeployqt.exe --qmldir qml bld\RelWithDebInfo\blockstream.exe

copy C:\depends\windows-x86_64\bin\libgreen_gdk.dll bld\RelWithDebInfo\
copy C:\depends\windows-x86_64\bin\libserialport-0.dll bld\RelWithDebInfo\
```

The executable and required DLLs will be in `bld\RelWithDebInfo\`.
