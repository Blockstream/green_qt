# Running and Writing Tests

This project uses CMake/CTest and Qt Test (`Qt6::Test`) for unit tests.

## Run Tests

From the repository root:

```sh
cmake -S . -B build-tests -DBUILD_TESTING=ON
cmake --build build-tests
ctest --test-dir build-tests --output-on-failure
```

Useful options:

- Run a specific test:

  ```sh
  ctest --test-dir build-tests -R test_smoke --output-on-failure
  ```

- List all discovered tests:

  ```sh
  ctest --test-dir build-tests -N
  ```

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
