# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Cache ledger xpubs in memory only.
- Add script to automate tag and version bump.
- Add CHANGELOG.md.

### Changed
- Abstract Device and refactor Ledger support accordingly.
- Use git if available for the app version, otherwise use CI env vars.
- Switch to C++17.

### Fixed
- Improve ledger signing to suppress unverified inputs warning.
- Use latest Google Auth token when enabling Google Auth two factor.
