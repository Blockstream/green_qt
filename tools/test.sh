#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-build}"
QT_CMAKE_BIN="${QT_CMAKE_BIN:-qt-cmake}"

usage() {
    cat <<'EOF'
Usage:
  ./tools/test.sh configure
  ./tools/test.sh build
  ./tools/test.sh all
  ./tools/test.sh one <suite_regex>
  ./tools/test.sh js
  ./tools/test.sh js-one <suite_regex>
  ./tools/test.sh list

Environment overrides:
  BUILD_DIR=<dir>        Build directory (default: build)
  QT_CMAKE_BIN=<path>    qt-cmake command/path (default: qt-cmake from PATH)
  CTEST_JUNIT_FILE=<path> If set, write JUnit XML for GitLab test reports (ctest --output-junit)

Examples:
  ./tools/test.sh all
  ./tools/test.sh one test_json
  ./tools/test.sh one "test_(util|json)"
  ./tools/test.sh js
  ./tools/test.sh js-one util
EOF
}

configure_tests() {
    if ! command -v "$QT_CMAKE_BIN" >/dev/null 2>&1; then
        echo "Could not find '$QT_CMAKE_BIN' in PATH."
        echo "Set QT_CMAKE_BIN to an explicit path or add qt-cmake to PATH."
        exit 1
    fi
    "$QT_CMAKE_BIN" -S "$ROOT_DIR" -B "$ROOT_DIR/$BUILD_DIR" -DBUILD_TESTING=ON
}

build_tests() {
    local build_path="$ROOT_DIR/$BUILD_DIR"
    mapfile -t test_targets < <(
        cmake --build "$build_path" --target help \
            | awk '/^\.\.\. test_[A-Za-z0-9_]+$/ { t=$2; if (t !~ /(autogen|qmlimportscan|timestamp|copy_qml|copy_res|other_files|qmltyperegistration|lrelease|lupdate)/) print t }'
    )

    if [[ ${#test_targets[@]} -eq 0 ]]; then
        echo "No buildable test_* targets found in $build_path."
        return 0
    fi

    cmake --build "$build_path" --target "${test_targets[@]}"
}

run_all_tests() {
    local ctest_args=(--test-dir "$ROOT_DIR/$BUILD_DIR" --output-on-failure)
    if [[ -n "${CTEST_JUNIT_FILE:-}" ]]; then
        mkdir -p "$(dirname "$CTEST_JUNIT_FILE")"
        ctest_args+=(--output-junit "$CTEST_JUNIT_FILE")
    fi
    ctest "${ctest_args[@]}"
}

run_one_test() {
    local suite_regex="${1:-}"
    if [[ -z "$suite_regex" ]]; then
        echo "Missing suite regex for 'one' command."
        usage
        exit 1
    fi
    ctest --test-dir "$ROOT_DIR/$BUILD_DIR" -R "$suite_regex" --output-on-failure
}

run_js_tests() {
    ctest --test-dir "$ROOT_DIR/$BUILD_DIR" -R "test_js_" --output-on-failure
}

run_one_js_test() {
    local suite_regex="${1:-}"
    if [[ -z "$suite_regex" ]]; then
        echo "Missing suite regex for 'js-one' command."
        usage
        exit 1
    fi
    ctest --test-dir "$ROOT_DIR/$BUILD_DIR" -R "test_js_.*${suite_regex}" --output-on-failure
}

list_tests() {
    ctest --test-dir "$ROOT_DIR/$BUILD_DIR" -N
}

main() {
    local cmd="${1:-}"
    case "$cmd" in
        configure)
            configure_tests
            ;;
        build)
            build_tests
            ;;
        all)
            configure_tests
            build_tests
            run_all_tests
            ;;
        one)
            configure_tests
            build_tests
            run_one_test "${2:-}"
            ;;
        js)
            configure_tests
            run_js_tests
            ;;
        js-one)
            configure_tests
            run_one_js_test "${2:-}"
            ;;
        list)
            list_tests
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
