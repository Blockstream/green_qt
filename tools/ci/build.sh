#!/bin/bash
set -eo pipefail

export GREEN_ENV=$([[ $CI_COMMIT_REF_NAME = release_* ]] && echo "Production" || echo "Testing")
export GREEN_BUILD_ID=$([[ $CI_COMMIT_REF_NAME = release_* ]] && echo "" || echo "-$CI_COMMIT_SHORT_SHA")

qt-cmake --preset ci
cmake --build build --parallel 4
