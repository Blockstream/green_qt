# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Singlesig wallet support for Ledger hardware devices
- Export account addresses to CSV file

### Changed
- Use electrum session for HTTP requests
- Jade automatic check for firmware updates
- Updates GDK to 0.0.53

### Fixed
- Prevent restoring an unexisting Multisig wallet

## [1.0.7] - 2022-04-13
### Added
- Singlesig wallet support for Blockstream Jade hardware devices
- Tor connection support also for singlesig wallets

### Changed
- Transaction details can now be copied to clipboard, simply by clicking on them
- Updates GDK to 0.0.51
- Jade firmware channel selector available as experimental feature, to test beta firmware versions
- Updates translations

### Fixed
- Crash on Jade setup
- Wrap 2FA label in wallet settings

## [1.0.6] - 2022-02-09
### Added
- Experimental support for archived accounts
- Refresh button to manually sync accounts, balances and transactions
- Automatically select new accounts after creating one
- Filter coins received before SegWit activation

### Changed
- Improve layout of outputs view
- Hover to show transaction options button

### Fixed
- Sign p2sh inputs with Ledger devices
- Show fiat denominated balance of Liquid accounts
- Show asset icon only if balance is positive

## [1.0.5] - 2022-01-21
### Added
- Automatic wallet restore, Green will find any wallet associated with your recovery phrase
- Improved transaction signing with Jade and Ledger, showing the transaction details to be confirmed on the hardware wallets
- SPV support for singlesig wallets, available in app settings
- Support connection to your personal electrum server, available in app settings
- Show indicators for tor, electrum servers and spv in the wallet status bar
- Pull down transaction list to refresh
- Show the available assets in account cards

### Changed
- Improved transaction details dialog
- Improved transaction list look and feel
- New icons for Liquid
- Updates GDK to 0.0.49

### Fixed
- Enable Jade login button after logout
- Restore wallet with 27 word recovery phrases
- Prevent long names to break the header layout
- Show correct amounts in review step
- Timestamp when exporting transactions to CSV file
- Show locked coins under the locked filter

## [1.0.4] - 2021-11-19
### Added
- Support for send to bech32m addresses, available 144 blocks after Taproot activation
- Creation and restore of singlesig wallets on Liquid testnet
- Manual coin selection for singlesig bitcoin wallets
- Wallet status bar

### Changed
- Updates GDK to 0.0.47.post1
- Automatically prompts for PIN on Jade again after a wrong attempt
- Detects and handles when Jade goes idle

### Fixed
- Closing dialogs takes the application to the original context
- URL with unblinding data for Liquid transactions on singlesig wallets
- Minimum width for titles in dialogs

## [1.0.3] - 2021-10-27
### Added
- Option to remember Watch-Only logins
- Supports creating and restoring Singlesig wallets on Liquid

### Changed
- Updates GDK to 0.0.46.post1
- Use test tickers in test networks for amounts

### Fixed
- Paste numbers with trailing whitespace in amount fields

## [1.0.2] - 2021-10-05
### Added
- Show fiat rate on wallet view header
- Show details to verify on jade when creating 2of2 accounts
- Setting for experimental features
- Release EV signed windows binaries

### Changed
- Fiat amounts are updated after receiving a ticker notification

### Fixed
- Ensure that window is correctly restored regardless of available screens changes
- Use correct vertical scrollbar in app settings

## [1.0.1] - 2021-09-30
### Added
- Option for creating 2of3 accounts with custom recovery phrase or BIP32 Extended Public Key
- Support for client-side Liquid transactions unblinding, available on Blockstream Jade 0.1.27+
- Option for filtering coins with expired 2FA
- Telegram 2FA method, available for testing in Bitcoin testnet
- Option to enable and disable the news section in the Home view

### Changed
- Uses BIP21 payment request message as transaction memo
- Shows QR Code scanner popup in send view
- Improvements to the news section layout in the Home view
- Updates GDK to 0.0.45.post1

### Fixed
- Jade address verification with 2of3 accounts
- Uses a consistent vertical scrollbar in all lists
- Drops Electrum from default wallet name
- Application log is now saved correctly
- Ignore expired server certs in Jade PIN requests

## [1.0.0] - 2021-09-07
### Added
- Warn on send dialog that Ledger Nano S supports a limited set of liquid assets
- Warn on receive dialog that Ledger Nano S supports a limited set of liquid assets
- Support for creating and restoring Singlesig wallets on Bitcoin Mainnet

### Changed
- Improve send performance and avoid generating multiple change addresses
- Show warning when sending with no available balance
- Make the whole address card clickable for copy to clipboard action

### Fixed
- Fix dialog error regression
- Fix filtering for not confidential coins
- Release session after fetching news feed and images
- Only show supported two factor authentication methods
- Refresh fiat amounts periodically

## [0.1.12] - 2021-08-19
### Added

### Changed

### Fixed
- Restore compability with macOS 10.13 High Sierra

## [0.1.11] - 2021-08-12
### Added
- News feed to home view

### Changed
- Fix missing 'all' label in liquid coins list
- Send Dialog - highlight review button, make it a primary button
- Auto-focus on 2FA input code field when prompted
- Show copy to clipboard button when hovering an address card
- Set coin selection strategy to manual

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
- Improves 2FA code error when all 3 attempts are used
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
