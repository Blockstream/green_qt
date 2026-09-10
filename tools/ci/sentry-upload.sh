#!/bin/bash
set -eo pipefail

# Pinned sentry-cli release. To bump: change SENTRY_CLI_VERSION, then update every
# checksum below with the output of
#   for a in Darwin-arm64 Darwin-x86_64 Linux-x86_64 Linux-aarch64; do
#     curl -sL "https://github.com/getsentry/sentry-cli/releases/download/$VERSION/sentry-cli-$a" | shasum -a 256
#   done
# Windows is pinned separately in tools/ci/sentry-upload.ps1 — bump it too.
SENTRY_CLI_VERSION="3.7.0"

case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)
        SENTRY_CLI_ASSET="sentry-cli-Darwin-arm64"
        SENTRY_CLI_SHA256="c66564094fbe56ee3b359f7574541f858b8d1df0328a0a759da972fbf1886048"
        ;;
    Darwin-x86_64)
        SENTRY_CLI_ASSET="sentry-cli-Darwin-x86_64"
        SENTRY_CLI_SHA256="fcd74786b4d95c6b7531662607897aadd5ab5d64c5d0468a6f4bd97ad04bedb8"
        ;;
    Linux-x86_64)
        SENTRY_CLI_ASSET="sentry-cli-Linux-x86_64"
        SENTRY_CLI_SHA256="cec71d46a7cc394c94b6e75f1601985c710d457376c546ef3975567b3671563b"
        ;;
    Linux-aarch64 | Linux-arm64)
        SENTRY_CLI_ASSET="sentry-cli-Linux-aarch64"
        SENTRY_CLI_SHA256="69cc0e951f663a332fd3bb3069e443cb3748abbfce497ae2caac6d5a9ec7ae65"
        ;;
    *)
        echo "sentry-cli: unsupported platform $(uname -s)-$(uname -m)" >&2
        exit 1
        ;;
esac

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

SENTRY_CLI="$PWD/sentry-cli"

if [ ! -x "$SENTRY_CLI" ] || [ "$(sha256 "$SENTRY_CLI")" != "$SENTRY_CLI_SHA256" ]; then
    curl -fsSL -o "$SENTRY_CLI.download" \
        "https://github.com/getsentry/sentry-cli/releases/download/$SENTRY_CLI_VERSION/$SENTRY_CLI_ASSET"
    actual=$(sha256 "$SENTRY_CLI.download")
    if [ "$actual" != "$SENTRY_CLI_SHA256" ]; then
        echo "sentry-cli: checksum mismatch for $SENTRY_CLI_ASSET $SENTRY_CLI_VERSION" >&2
        echo "  expected $SENTRY_CLI_SHA256" >&2
        echo "  actual   $actual" >&2
        rm -f "$SENTRY_CLI.download"
        exit 1
    fi
    chmod +x "$SENTRY_CLI.download"
    mv "$SENTRY_CLI.download" "$SENTRY_CLI"
fi

"$SENTRY_CLI" --url https://sentry.blockstream.io debug-files upload \
    --org "$SENTRY_ORG" \
    --project "$SENTRY_PROJECT" \
    --auth-token="$SENTRY_AUTH_TOKEN" \
    --log-level="$SENTRY_LOG_LEVEL" "${1:-build}"
