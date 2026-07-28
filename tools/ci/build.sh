#!/bin/bash
set -eo pipefail

export GREEN_ENV=$([[ $CI_COMMIT_REF_NAME = release_* ]] && echo "Production" || echo "Testing")
export GREEN_BUILD_ID=$([[ $CI_COMMIT_REF_NAME = release_* ]] && echo "" || echo "-$CI_COMMIT_SHORT_SHA")

qt-cmake --preset ci
cmake --build build --parallel 4

curl -sL https://sentry.io/get-cli | INSTALL_DIR=$PWD sh
./sentry-cli --url https://sentry.blockstream.io debug-files upload \
    --org "$SENTRY_ORG" \
    --project "$SENTRY_PROJECT" \
    --auth-token="$SENTRY_AUTH_TOKEN" \
    --log-level="$SENTRY_LOG_LEVEL" build
