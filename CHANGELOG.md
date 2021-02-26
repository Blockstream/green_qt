# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed
- Prettify home view and change side button icon
- Prevent rejecting signup and restore dialogs with outside click
- Drop wallet storage format from beta versions

### Fixed
- Improve link appearance in all platforms and change hover cursor
- Fix alert message when 2f reset is under dispute

## [0.1.0] - 2021-02-22
### Added
- Add Jade and Ledger views for hardware wallets management
- Add support for Blockstream Jade for both bitcoin and liquid wallets.
- Add a top level view for each network
- Use same window geometry after restart.
- Add support for app/global settings.
- Use Roboto font throughout
- Enable qtconnectivity and qtserialport to support jade
- Cache ledger xpubs in memory only.
- Add script to automate tag and version bump.
- Add copy unblinded link to liquid transactions options
- Add ability to change 2FA expiry time under wallet recovery settings
- Add CHANGELOG.md.

### Changed
- Overhaul sidebar with sections
- Update docker images with libusb and hidapi
- Bump GDK to 0.0.40
- Abstract Device and refactor Ledger support accordingly.
- Use git if available for the app version, otherwise use CI env vars.
- Switch to C++17.

### Fixed
- Allow login with tor or custom proxy when using hardware wallets.
- Allow only one instance of Blockstream Green to run at the same time.
- Update unconfirmed transactions when a block arrives.
- Improve ledger signing to suppress unverified inputs warning.
- Use latest Google Auth token when enabling Google Auth two factor.
- Fix mnemonic editor layout.
- Fix compatibility with mac OS 10.13
