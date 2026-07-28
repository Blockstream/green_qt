#!/bin/bash
set -eo pipefail

curl -sL https://sentry.io/get-cli | INSTALL_DIR=$PWD sh
./sentry-cli --url https://sentry.blockstream.io debug-files upload \
    --org "$SENTRY_ORG" \
    --project "$SENTRY_PROJECT" \
    --auth-token="$SENTRY_AUTH_TOKEN" \
    --log-level="$SENTRY_LOG_LEVEL" "${1:-build}"
