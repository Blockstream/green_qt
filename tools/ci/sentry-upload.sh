#!/bin/bash
set -eo pipefail

# Pinned sentry-cli release. To bump: change SENTRY_CLI_VERSION, then update every
# checksum below with the output of
#   for a in Darwin-arm64 Darwin-x86_64 Linux-x86_64 Linux-aarch64 Windows-x86_64.exe; do
#     curl -sL "https://github.com/getsentry/sentry-cli/releases/download/$VERSION/sentry-cli-$a" | shasum -a 256
#   done
SENTRY_CLI_VERSION="3.6.2"

case "$(uname -s)-$(uname -m)" in
    Darwin-arm64)
        SENTRY_CLI_ASSET="sentry-cli-Darwin-arm64"
        SENTRY_CLI_SHA256="5a497deb1e388cc6445c09ddd6d2da4fc2aae8295405d6393c2e0ee635ca3687"
        ;;
    Darwin-x86_64)
        SENTRY_CLI_ASSET="sentry-cli-Darwin-x86_64"
        SENTRY_CLI_SHA256="efe0a5289cdd0ea8ff727b1228a1bea6c840f2da38152e8f9f5ced05bd6659cd"
        ;;
    Linux-x86_64)
        SENTRY_CLI_ASSET="sentry-cli-Linux-x86_64"
        SENTRY_CLI_SHA256="3a4bbf2c0d06378d4e59b337647483751a0a2b1603db5fd4991847d0cfd6478c"
        ;;
    Linux-aarch64 | Linux-arm64)
        SENTRY_CLI_ASSET="sentry-cli-Linux-aarch64"
        SENTRY_CLI_SHA256="ff112ecf694b7d6b3629a6228ed4e3f7a0d51401bdf48a5051a79d8749dccd06"
        ;;
    MINGW*-x86_64 | MSYS*-x86_64 | CYGWIN*-x86_64)
        SENTRY_CLI_ASSET="sentry-cli-Windows-x86_64.exe"
        SENTRY_CLI_SHA256="5c90cb0045cef3d3c36113c2aa21a7dcae11627d2d6e3098b679dea5b6681be3"
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
