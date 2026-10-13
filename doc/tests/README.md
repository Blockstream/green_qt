# Running and Writing Tests

This project uses CMake/CTest and Qt Test (`Qt6::Test`) for unit tests.

`test_icon_catalog` checks that the icon properties in `Icons.qml` and the resource
list in `modules/theme/assets/icons/CMakeLists.txt` match every SVG in `modules/theme/assets/icons/`,
with no missing files or unlisted SVGs.
Run it with `ctest --test-dir build -R test_icon_catalog --output-on-failure`,
or directly with `cmake -P modules/theme/tests/check_icons.cmake` (no build required).

## Run Tests

From the repository root, use [`tools/test.sh`](../../tools/test.sh). It configures with `qt-cmake`, builds the default tree directory `build`, and runs CTest.

Configure, build, and run everything:

```sh
./tools/test.sh all
```

Other commands:

- Run tests matching a regex (same as `ctest -R`):

  ```sh
  ./tools/test.sh one test_util
  ./tools/test.sh one "test_(util|json)"
  ```

- List discovered tests:

  ```sh
  ./tools/test.sh list
  ```

- Configure or build only:

  ```sh
  ./tools/test.sh configure
  ./tools/test.sh build
  ```

Environment overrides:

- `BUILD_DIR` — build directory (default: `build`). Example: `BUILD_DIR=build-tests ./tools/test.sh all`
- `QT_CMAKE_BIN` — path to `qt-cmake` if it is not on `PATH`
- `CTEST_JUNIT_FILE` — if set, CTest writes JUnit XML there (for GitLab test reports)

CI runs the tests in `linux-x86_64:build-appimage`, right after `tools/ci/build.sh` (which builds with `BUILD_TESTING` on by default), and fails the job if any test fails.

If you need raw CMake/CTest invocations instead of the script, use the same build directory and flags as `tools/test.sh` (`qt-cmake -S . -B <dir> -DBUILD_TESTING=ON`, then `cmake --build` and `ctest --test-dir <dir>`).

## Add a New Test

C++ unit tests live under `tests/unit`. QML tests for the `Blockstream.Controls` module live in
`qml/controls/tests` and run against the compiled module; QML tests for app components live in
`tests/qml` and run with `qmltestrunner` against stub types.

1. Create a new test source file in `tests/unit` (for example `tst_wallet.cpp`).
2. Register it in `tests/unit/CMakeLists.txt` with `add_unit_test(...)`, which creates the executable, links `Qt6::Test` and adds it to CTest.
3. List `blockstream_core` under `LIBRARIES` to test app code.

Example CMake entry:

```cmake
add_unit_test(
    NAME test_wallet
    SOURCES tst_wallet.cpp
    LIBRARIES blockstream_core
)
```
