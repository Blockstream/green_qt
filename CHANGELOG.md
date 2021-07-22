# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added

### Changed
- Auto-focus on 2FA input code field when prompted

### Fixed

## [0.1.10] - 2021-07-22
### Added
- Support manual coin selection in Bitcoin Multisig Shield wallets
- Saving application log to file
- Default SegWit accounts in new Singlesig wallets
- Add shortcut buttons to Asset and Transactions lists in overview view
- Validation on amount input fields
- Icon indicating whether a wallet is Singlesig or Multisig Shield

### Changed
- Improves for Jade hardware
- Improves look and feel to user interface controls
- Improves address validation on Jade, now triggered manually
- Overview 'Transactions' label renamed to 'Latest Transactions', now showing 10 scrollable results
- Improves layout details of some settings panels
- Improves Watch-Only login dialog
- Improves remove wallet dialog

### Fixed
- Fixes crash when mnemonic is invalid
- Fixes missing account name for Watch-Only wallets
- Fixes setup of μBTC denominated 2FA threshold

## [0.1.9] - 2021-07-01
### Added
- Support for creating and restoring Singlesig wallets on Bitcoin Testnet
- Notifications for application updates

### Changed

### Fixed
- Fixed crash when loading wallet with 2FA reset
- Reduce high CPU/GPU usage when application is idle
- Update GDK to 0.0.43

## [0.1.8] - 2021-06-15
### Added
- Use Anti-Exfil protocol with Jade
- Enforce minimum Ledger firmware version

### Changed
- Build GDK with rust enabled for singlesig support
- Update GDK to 0.0.42.post1
- Restore dialog now requires to choose between 12, 24 or 27 words mnemonics
- Improved wallet settings layout
- Under settings, always show scrollbars if content is scrollable

### Fixed
- Fix crash after autologout with transaction or asset dialog open
- Handle long messages in system message dialog
- Fix login with Jade when user uses an incorrect PIN

## [0.1.7] - 2021-05-21
### Added
- Support searching for transaction hash or memo
- Allow to rename main account
- Persist wallet hash id
- Add copyable label with transaction hash to the end of send flow

### Changed
- Improved wallet toolbar in wallet view
- Show asset details in a dialog
- Show transaction details in a dialog
- Remove window menu bar
- Update GDK to 0.0.42

### Fixed
- Display main account name if set
- Highlight matched side bar button when collapsed
- Use scrollable list view in firmwares listing

## [0.1.6] - 2021-05-05
### Added
- Support for temporary watch-only login
- Setup watch-only credentials in wallet settings
- Add coins tab to account view
- Show 2FA method when 2FA is requested
- Add support to lock coins labeled as dust

### Changed
- Make remove wallet button destructive

### Fixed
- Prevent endless dialogs loop when restoring wallet

## [0.1.5] - 2021-04-20
### Added
- Add disable all pins security setting
- Add view with list of generated addresses
- Support searching for a generated address
- Restore AMP wallets
- Warn when input is not a valid BIP39 word
- Language selector in application settings

### Changed
- Send and receive buttons moved from account card to toolbar

### Fixed
- Show error when restore fails

## [0.1.4] - 2021-04-07
### Added

### Changed

### Fixed
- Fix Two Factor Limit dialog layout
- Don't use old string ids

## [0.1.3] - 2021-04-07
### Added
- AMP wallet creating flow
- Support in-place renaming in wallet title view

### Changed
- Rename exectuable from Green.exe to "Blockstream Green.exe" on Windows
- Do not ask for wallet name on signup and restore
- Use secondary buttons on devices views
- Do not auto complete words in restore dialog
- Complete word on tab press if it matches just one suggestion
- Update translations for AMP accounts

### Fixed
- Minor GUI adjustments
- Elide dialog title and show tooltip with full title when truncated
- During restore wallet use default name if no name is specified

## [0.1.2] - 2021-04-01
### Added
- Bundle Green as installer for Windows
- Jade Over-The-Air Update support
- Support shared build in windows
- Add 'recently used wallets' and 'create wallet' sections to home view

### Changed
- Expose 2FA available method's data
- Update GDK to 0.0.41
- Use data dir to store app settings
- Bring primary window to front when attempting to launch another instance in Windows and MacOS
- Add connection and tor feedback when logging in with pin, mnemonic and hardware wallets
- Overhaul the threading model to improve handling of async operations
- Add a command line flag to expose multiple update channels for Jade
- Update translations

### Fixed
- Fix hover events after opening a dialog
- Prevent key dialogs to be closed by clicking outside
- Fix keyboard focus when opening change pin dialog

## [0.1.1] - 2021-03-04
### Added

### Changed
- Always send prevout when signing a transaction with Jade
- 2FA auto-advance at last digit
- Use Blockstream icon instead of Jade icon
- Remove precision from asset details view
- Improve layout and look of transaction list
- Update app settings title and icon
- Prettify home view and change side button icon
- Prevent rejecting signup and restore dialogs with outside click
- Drop wallet storage format from beta versions

### Fixed
- Correctly render asset icons
- Make device thumbnail clickable only in wallet view
- Improve font weight throughout
- Improve link appearance in all platforms and change hover cursor
- Improve 2FA icons and descriptions
- Fix alert message when 2FA reset is under dispute
- Fix PIN button enable state inconsistency when setting a new PIN

## [0.1.0] - 2021-02-22
### Added
- Add Jade and Ledger views for hardware wallets management
- Add support for Blockstream Jade for both Bitcoin and Liquid wallets
- Add a top level view for each network
- Use same window geometry after restart
- Add support for app/global settings
- Use Roboto font throughout
- Enable qtconnectivity and qtserialport to support jade
- Cache Ledger xpubs in memory only
- Add script to automate tag and version bump
- Add copy unblinded link to Liquid transactions options
- Add ability to change 2FA expiry time under wallet recovery settings
- Add CHANGELOG.md

### Changed
- Overhaul sidebar with sections
- Update docker images with libusb and hidapi
- Bump GDK to 0.0.40
- Abstract Device and refactor Ledger support accordingly
- Use git if available for the app version, otherwise use CI env vars
- Switch to C++17

### Fixed
- Allow login with Tor or custom proxy when using hardware wallets
- Allow only one instance of Blockstream Green to run at the same time
- Update unconfirmed transactions when a block arrives
- Improve Ledger signing to suppress unverified inputs warning
- Use latest Google Auth token when enabling Google Auth 2FA
- Fix mnemonic editor layout
- Fix compatibility with macOS 10.13
