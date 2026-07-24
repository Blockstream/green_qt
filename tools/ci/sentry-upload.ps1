#!/usr/bin/env pwsh
# Windows counterpart of tools/ci/sentry-upload.sh, which covers macOS and Linux.
# The GitLab windows runner has no bash, so the pinning logic is mirrored here.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Pinned sentry-cli release. Keep the version in sync with SENTRY_CLI_VERSION in
# tools/ci/sentry-upload.sh. To bump: change $SentryCliVersion, then update the
# checksum below with the output of
#   curl -sL "https://github.com/getsentry/sentry-cli/releases/download/$VERSION/sentry-cli-Windows-x86_64.exe" | shasum -a 256
$SentryCliVersion = "3.6.2"
$SentryCliAsset = "sentry-cli-Windows-x86_64.exe"
$SentryCliSha256 = "5c90cb0045cef3d3c36113c2aa21a7dcae11627d2d6e3098b679dea5b6681be3"

function Get-Sha256($path) {
    (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLower()
}

$SymbolsPath = if ($args.Count -gt 0) { $args[0] } else { "build" }
$SentryCli = Join-Path $PWD "sentry-cli.exe"

if (-not (Test-Path $SentryCli) -or (Get-Sha256 $SentryCli) -ne $SentryCliSha256) {
    $download = "$SentryCli.download"
    Invoke-WebRequest -UseBasicParsing -OutFile $download `
        "https://github.com/getsentry/sentry-cli/releases/download/$SentryCliVersion/$SentryCliAsset"
    $actual = Get-Sha256 $download
    if ($actual -ne $SentryCliSha256) {
        Remove-Item -Force $download
        [Console]::Error.WriteLine("sentry-cli: checksum mismatch for $SentryCliAsset $SentryCliVersion")
        [Console]::Error.WriteLine("  expected $SentryCliSha256")
        [Console]::Error.WriteLine("  actual   $actual")
        exit 1
    }
    Move-Item -Force $download $SentryCli
}

& $SentryCli --url https://sentry.blockstream.io debug-files upload `
    --org $env:SENTRY_ORG `
    --project $env:SENTRY_PROJECT `
    --auth-token="$env:SENTRY_AUTH_TOKEN" `
    --log-level="$env:SENTRY_LOG_LEVEL" $SymbolsPath
exit $LASTEXITCODE
