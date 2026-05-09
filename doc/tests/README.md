# Running and Writing Tests

This project uses CMake/CTest and Qt Test (`Qt6::Test`) for unit tests.

## Run Tests

From the repository root, use [`tools/test.sh`](../../tools/test.sh). It configures with `qt-cmake`, builds the default tree directory `build`, and runs CTest.

Configure, build, and run everything:

```sh
./tools/test.sh all
```

Other commands:

- Run tests matching a regex (same as `ctest -R`):

  ```sh
  ./tools/test.sh one test_smoke
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
- `CTEST_JUNIT_FILE` — if set, CTest writes JUnit XML there (used in CI for GitLab test reports)

If you need raw CMake/CTest invocations instead of the script, use the same build directory and flags as `tools/test.sh` (`qt-cmake -S . -B <dir> -DBUILD_TESTING=ON`, then `cmake --build` and `ctest --test-dir <dir>`).

## Add a New Test

Current tests live under `tests/unit`.

1. Create a new test source file in `tests/unit` (for example `tst_wallet.cpp`).
2. Add the file as a new test executable in `tests/unit/CMakeLists.txt` using `qt_add_executable(...)`.
3. Link at least `Qt6::Core` and `Qt6::Test`.
4. Register the executable with CTest using `add_test(...)`.

Example CMake entry:

```cmake
set(TEST_TARGET test_wallet)

qt_add_executable(${TEST_TARGET}
    tst_wallet.cpp
)

target_link_libraries(${TEST_TARGET}
    PRIVATE
    Qt6::Core
    Qt6::Test
)

add_test(NAME ${TEST_TARGET} COMMAND ${TEST_TARGET})
```
