## Building Blockstream on macOS

**Quick start:** From the repository root, run the automated build script:

```bash
./doc/macos/build.sh
```

The script checks prerequisites, builds dependencies, and compiles the app. If a step fails, run it again to resume. Use `./doc/macos/build.sh --restart` to start over.

---

### Prerequisites (manual setup)

- **OS**: macOS 12+ (Apple Silicon or Intel).
- **Xcode command line tools**: `xcode-select --install`
- **Homebrew**: `https://brew.sh`
- **Bash 4+**: Required for GDK build scripts. macOS ships with Bash 3.2; install via `brew install bash`. Check version with `bash --version`.
- **C/C++ compiler**: Apple clang from Xcode (default on macOS).
- **Build tools**: `brew install cmake ninja python git pkg-config protobuf`
- **Qt 6.11**: installed via the Qt online installer (see below).

The build uses a local dependency prefix under `depends/` plus a **Qt 6.11** installation.

### Clone the repository

```bash
git clone https://github.com/Blockstream/green_qt.git
cd green_qt
```

### Environment for dependency builds

Pick the target architecture:

- **Apple Silicon**:

  ```bash
  export HOST=macos
  export ARCH=arm64
  export PREFIX="${PREFIX-$HOME/depends/macos-arm64}"
  export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
  export CMAKE_INSTALL_PREFIX="$PREFIX"
  export CMAKE_POLICY_VERSION_MINIMUM=3.5
  export gdk_ROOT="$PREFIX/lib/arm64-apple-darwin/gdk"
  ```

- **Intel macOS**:

  ```bash
  export HOST=macos
  export ARCH=x86_64
  export PREFIX="${PREFIX-$HOME/depends/macos-x86_64}"
  export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
  export CMAKE_INSTALL_PREFIX="$PREFIX"
  export CMAKE_POLICY_VERSION_MINIMUM=3.5
  export gdk_ROOT="$PREFIX/lib/x86_64-apple-darwin/gdk"
  ```

### Install Qt 6.11 (Qt online installer)

1. Download the Qt online installer from `https://www.qt.io/download-qt-installer`.
2. Install **Qt 6.11.x** for macOS (arm64 or x86_64 to match your machine), including at least:
   - Qt Quick / Qt Quick Controls 2
   - Qt Widgets / Qt Quick Widgets
   - Qt XML / Qt Core5Compat
   - Qt Bluetooth
   - Qt SerialPort
   - Qt Multimedia
   - Qt WebEngine

3. Note the install prefix; for example:

   ```bash
   export QT_ROOT="$HOME/Qt/6.11.1/macos"
   ```

#### macOS 26 (Sequoia) notes

- **Qt version on macOS 26**: Building with Qt **6.11.1** on macOS 26 can fail with a link error:

  ```text
  ld: framework 'AGL' not found
  ```

  Upgrading Qt to **6.11.1** (or newer in the 6.11 series) resolves this issue.

Ensure Qt is on `PATH` and in `CMAKE_PREFIX_PATH`:

```bash
export PATH="$QT_ROOT/bin:$PATH"
export CMAKE_PREFIX_PATH="$QT_ROOT${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
```

### Build third‑party dependencies

If you prefer to build dependencies manually instead of using `./doc/macos/build.sh`, run:

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

All of these install into `$PREFIX`. This step is slow the first time, but can be reused for future builds.

### Configure and build the app (qt-cmake)

Make sure both Qt and the local dependencies are visible to CMake:

```bash
export PATH="$QT_ROOT/bin:$PATH"
export CMAKE_PREFIX_PATH="$QT_ROOT:$PREFIX:$gdk_ROOT"
```

Now configure a **RelWithDebInfo** build with the `dev` preset (defined in
[`CMakePresets.json`](../../CMakePresets.json)):

```bash
qt-cmake --preset dev
```

Build:

```bash
cmake --build build --parallel 4
```

The resulting app bundle is at:

- `build/Blockstream.app`

You can run it directly with:

```bash
open build/Blockstream.app
```
