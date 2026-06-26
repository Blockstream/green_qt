## Building Blockstream on Linux

**Quick start:** Run the automated build script from the repository root:

```bash
./doc/linux/build.sh
```

The script checks prerequisites, builds dependencies, and compiles the app. If a step fails, run it again to resume. Use `./doc/linux/build.sh --restart` to start over.

---

### Prerequisites (manual setup)

- **Distro**: Ubuntu 22.04+ (or compatible). On Fedora/RHEL use `dnf install libcap-devel` (and the dnf equivalent of the packages below).
- **Packages** (roughly matching `ci/linux-x86_64/setup.sh`):

  ```bash
  sudo apt update
  sudo apt install -y \
    build-essential clang llvm-dev cmake ninja-build git python3 python3-venv python3-pip pkg-config \
    protobuf-compiler \
    libgl1-mesa-dev libfontconfig1-dev libfreetype6-dev \
    libcap-dev \
    libx11-dev libxext-dev libxfixes-dev libxi-dev libxrender-dev \
    libxcb1-dev libxkbcommon-dev libx11-xcb-dev libxcb-glx0-dev libxkbcommon-x11-dev \
    libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev \
    libxcb-sync0-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev \
    libxcb-render-util0-dev libxcb-util0-dev libxcb-xinerama0-dev libxcb-xkb-dev \
    libxkbcommon-dev libxkbcommon-x11-dev libxcb-xinput-dev libxcb-cursor-dev \
    libudev-dev libbluetooth-dev bluez libdbus-1-dev libpulse-dev \
    libwayland-dev wayland-protocols \
    yasm nasm curl ca-certificates wget \
    libtool autoconf libcurl4-openssl-dev libclang-dev libssl-dev
  ```

- **Rust**: Required for GDK build. Install via rustup:

  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  . "$HOME/.cargo/env"
  rustup install 1.81.0
  ```

### Clone the repository

```bash
git clone https://github.com/Blockstream/green_qt.git
cd green_qt
```

### Environment for dependency builds

Run:

```bash
export HOST=linux
export ARCH=x86_64
export PREFIX="$PWD/depends/linux-x86_64"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
export CMAKE_INSTALL_PREFIX="$PREFIX"
```

You can reuse this layout for local builds.

### Install Qt 6.11.1 (Qt Online Installer)

**Important**: You must install Qt from the online installer, not from source. QtWebEngine (required by the application) cannot be built statically and must come from the Qt online installer. Since QtWebEngine requires the full Qt installation, you need to install the entire Qt from the online installer.

1. Download the Qt online installer from `https://www.qt.io/download-qt-installer`
2. Install **Qt 6.11.1** for Linux (x86_64), including:
   - Qt Quick / Qt Quick Controls 2
   - Qt Widgets / Qt Quick Widgets
   - Qt XML / Qt Core5Compat
   - Qt Bluetooth
   - Qt SerialPort
   - Qt Multimedia
   - Qt WebEngine (extension)
   - Qt WebView
   - Qt WebChannel

3. Set the Qt installation path and update your environment (adjust the path to match your installation):

   ```bash
   export QT_ROOT="$HOME/Qt/6.11.1/gcc_64"
   export PATH="$QT_ROOT/bin:$PREFIX/bin:$PATH"
   export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX"
   ```

### Build third‑party dependencies

If you prefer to build dependencies manually instead of using `./doc/linux/build.sh`, run:

```bash
rm -rf "$PREFIX"

tools/buildgdk.sh --static
tools/buildbreakpad.sh
tools/buildcrashpad.sh
tools/buildgpgme.sh
tools/buildlibusb.sh
tools/buildhidapi.sh
tools/buildcountly.sh
tools/buildzxing.sh
tools/buildlibserialport.sh --disable-shared
tools/buildkdsingleapplication.sh
tools/buildlwk.sh
tools/buildglsdk.sh
tools/buildleveldb.sh
```

All of these install into `$PREFIX`. This is the slow part; subsequent builds can reuse the same prefix.

### Configure and build the app (qt-cmake)

For a **RelWithDebInfo** build, you can run:

```bash
qt-cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DGREEN_ENV=Development \
  -DGREEN_BUILD_ID="-dev" \
  -DGREEN_LOG_FILE=dev \
  -DENABLE_SENTRY=OFF
```

Then build:

```bash
cmake --build build --parallel 4
```

The resulting binary is:

- `build/blockstream`

Run it directly:

```bash
./build/blockstream
```

**Note**: You may need to set `LD_LIBRARY_PATH` at runtime to find Qt libraries:

```bash
export LD_LIBRARY_PATH="$QT_ROOT/lib:$LD_LIBRARY_PATH"
./build/blockstream
```

