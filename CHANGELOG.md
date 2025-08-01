# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.27] - 2025-07-28
### Changed:
- Updated application name, icon and installers
- Minor user interface improvements
- Option to dismiss new version banner

### Fixes:
- Handle network failure when setting the wallet pin

## [2.0.26] - 2025-07-10
### Changed:
- Green is now Blockstream App, application style is updated to match the rebrand
- Hardware wallet advertisement segmentation

### Fixes:
- Child process must receive datadir form the parent process
- Prevent multiple app settings dialogs

## [2.0.25] - 2025-04-23
### Fixes:
- Previous release had wrong version

## [2.0.24] - 2025-04-23
### Changed:
- Update GDK to 0.75.1

### Fixes:
- Amount parsing when changing from fiat denomination to Liquid asset

## [2.0.23] - 2025-03-27
### Fixes:
- Correct amount parsing when sending a Liquid asset
- Prevent a crash when the wallet logouts and a balance refresh was about to occur

## [2.0.22] - 2025-03-20
### Added:
- Option to request an email containing the user’s nLockTime transactions

### Fixes:
- Image size when a new Jade device is detected
- Correct location of crash reports on macOS and Linux

## [2.0.21] - 2025-03-07
### Added:
- Crash reporting

### Changed:
- Only check firmware for the connected Jade
- Liquid Bitcoin ticker to LBTC
- Updates translations
- Updates GDK to 0.74.3
- Updates Qt to 6.8.2

### Fixed:
- Prevent invalid transaction creation under slow networking
- Available amount displayed after manual coin selection

## [2.0.20] - 2025-02-03
### Added:
- Enable Liquid discounted fees for Confidential Transactions (CT).

### Fixed:
- Can not change transaction notes on watch-only

## [2.0.19] - 2025-01-27
### Added:
- Create support tickets from the application

## [2.0.18] - 2025-01-23
### Fixed:
- Revert Qt to 6.8.0 to fix crash on macOS Intel
- Prevent overflow of unit selector

## [2.0.17] - 2025-01-09
### Added:
- Graphical assets for Jade Plus
- Support video advertisement on Linux
- Show total spent amount in transaction details

### Changed:
- The default fee rate is now the 24 block fee rate estimate
- Match address display format in Jade address verification flow
- Updates Qt to 6.8.1

### Fixed:
- Display an error when the change output is dust in send flow
- Aspect ratio of advertisement videos
- Minor UI improvements

## [2.0.16] - 2024-12-19
### Added:
- Genuine check flow

### Changed:
- Enhanced advertisement
- Updates GDK to 0.74.1
- The default fee rate is now the minimum relay fee rate
- Stable Jade firmware update

## [2.0.15] - 2024-11-21
### Fixed:
- Layout of advertisement card in wallet overview
- Complete tracking of advertisement events
- Reset of analytics identifier

## [2.0.14] - 2024-11-14
### Changed:
- Static linkage of libicu

### Fixed:
- In-app advertisement on wallet overview
- Check for update on startup

## [2.0.13] - 2024-11-14
### Added:
- Support in-app advertisement

### Changed:
- Improvements in send flow
- Improvements in receive flow
- Updates Qt to 6.8.0
- Updates GDK to 0.73.3
- Improvements in Jade detection

## [2.0.12] - 2024-09-30
### Changed:
- Improve address verification with Jade on redeposit
- Updates GDK to 0.73.1

### Fixed:
- Generate redeposit address once

## [2.0.11] - 2024-09-24
### Added:
- Option to verify address on Jade in the redeposit 2FA expired coins flow
- Camera selector when scanning QR codes
- SPV status in the transaction details view

### Changed:
- Updates GDK to 0.73.0
- Relaxation of serial port scanning for Jade devices

### Fixed:
- Default fee rate in the bump transaction flow
- Keep the amount field empty after changing the unit in the send flow
- Do not block the GUI before while no account is created on fresh wallet

## [2.0.10] - 2024-09-02
### Fixed:
- Login with singlesig watch-only
- Ensure the application is usable with a smaller window size
- Improve detection of Tor circuit

## [2.0.9] - 2024-08-13
### Added:
- Phone field with country selector

### Changed:
- Updates GDK to 0.72.2

### Fixed:
- Send BTC with Ledger devices
- Verify address with Jade
- Prevent Watch-Only login when password is empty
- Fee rate label when custom fee is selected
- Reinstate lock and unlock of dust outputs in bitcoin multisig

## [2.0.8] - 2024-07-09
### Added:
- Flow to redeposit 2FA expired coins
- Notification for 2FA expired coins
- Notification for partial service outage
- Expose status of wallet connections
- Show banner for login alert
- Show banner for system messages
- Show banner for two factor expired outputs

### Changed:
- Updates Qt to 6.7.2

## [2.0.7] - 2024-06-11
### Changed:
- Setting to remember devices
- Updates Qt to 6.7.1
- Updates GDK to 0.71.3
- Improved asset registry loading

## [2.0.6] - 2024-05-22
### Changed:
- Experimental support to unlock Jade in QR mode
- Better QR Code scanning

### Fixed:
- Do not disable send and receive buttons
- Request camera permission when required
- Application startup in macOS Sonoma

## [2.0.5] - 2024-05-08
### Added:
- Add or import singlesig watch-only wallet
- New watch-only section in wallet settings dialog
- Expose extended public keys and output descriptors of singlesig accounts
- Handle external BIP21 payment on Linux
- Option to scramble login keypad

### Fixed:
- Reinstate 2FA expire settings

## [2.0.4] - 2024-04-22
### Added:
- BIP39 passphrase login
- Handle external BIP21 payment on macOS and Windows
- Support signing message with software wallet

### Changed:
- Updates Qt to 6.7.0
- Updates GDK to 0.71.0

### Fixed:
- QR Code for Authenticator app in Two-Factor authentication settings
- Only show fee amount for redeposits
- Sign Liquid transaction with Ledger Nano S
- Show insufficient funds for fee error

## [2.0.3] - 2024-03-28
### Added:
- Notice when Jade is configured with a custom oracle server
- Show mismatch warning on the setup PIN view

### Fixed
- Better GUI around login with Jade
- Usage with Tor

## [2.0.2] - 2024-03-13
### Added:
- Button to clear address field

### Changed:
- Improved onboarding flow
- Improments in the Watch-Only login view
- Reinstate 2FA reset notification and request/cancel options
- Add general section in app settings
- Update GDK to 0.70.3

### Fixed
- Crash on login when Ledger device is idle
- Incorrect negative balance

## [2.0.1] - 2024-03-05
### Added:
- Manual coin selection for L-BTC
- List relevant accounts in the assets details
- Filter for non confidential coins

### Changed:
- Adjust scanning for Jade device ferquency

### Fixed
- Preserve transaction memo on increate transaction speed
- Fixed watch only login on liquid
- Fix busy indicator of primary buttons
- Restore with QR Code while some words are filled
- Avoid slow application quit
- Layout of manual coin selection view

## [2.0.0] - 2024-02-29
### Added
- New UI and UX: the user experience has been simplified and streamlined with a more polished, intuitive interface for easier access to key features
- All-in-one UX: use your existing wallets for both your Bitcoin and Liquid accounts across singlesig and assisted multisig. You have the flexibility to choose whether to combine Bitcoin and Liquid accounts or not, and thus to organize your mainchain and second-layer stacks as you deem fit.
- Simpler onboarding for new Jade users, minimizing ambiguity and errors during the initial setup

## [1.2.5] - 2023-07-19
### Changed
- Navigate to hardware device view from wallets view

### Fixed
- Crash on Jade setup

## [1.2.4] - 2023-07-13

### Added
- Liquid Singlesig with Jade

### Fixed
- Remove local analytics details after disabling on settings
- Change preferred currency or exchange on singlesig wallet

## [1.2.3] - 2023-06-21
### Changed
- Bigger QR Codes to aid scanning with Jade

### Fixed
- Support temporary Recovery Phrase Login with Jade
- Handle sign message error with Jade
- Sending with minium fee rate on Liquid singlesig
- Click on new version notification to open download page
- Regression in analytics initialization

## [1.2.2] - 2023-06-21
### Added
- Pass hash of uncompressed firmware when updating Jade

### Changed
- Better error messages in increase fee dialog
- CI process for signing for Windows

### Fixed

## [1.2.1] - 2023-06-09
### Changed
- Updated analytics library
- Display Jade's firmware hash in groups of 8 characters

### Fixed
- Improved Jade discovery to avoid application misbehavior
- Remove Wayland support from Appimage binary
- Adjusted font weight to improve readability
- Regression around macOS bundle name
- Log file name was empty

## [1.2.0] - 2023-05-18
### Added
- MacOS universal build
- Support Wayland

### Changed
- Improved stability
- Minor GUI cleanups
- Updates GDK to 0.0.62
- Updates Qt to 6.4.2
- Updates hidapi to 0.13.1
- Updates qzxing to support Qt 6
- Switches to cmake build

### Fixed
- Support Ledger Bitcoin Legacy
- Avoid using invalid or unreachable proxy

## [1.1.6] - 2022-12-23
### Added

### Changed
- Avoid Jade firmware update when Jade is being setup

### Fixed
- Fix Jade device state typo

## [1.1.5] - 2022-11-14
### Added

### Changed
- Updates GDK to 0.0.56
- Improve Jade firmware version handling

### Fixed
- Fix watch only login button trim
- Popup with button to copy being activated below dialogs
- Fix view state when changing between selected account
- Fix compiler warning raised on session.h event property
- Improve receive address while validating on device
- Improve receive dialog footer padding consistency

## [1.1.4] - 2022-10-05
### Added
- Support for incremental Jade firmware update
- Enable Request Two-Factor Reset for liquid
- Add quick action on the sidebar to create wallet
- Show confirmed email (if exists) under general settings email notifications checkbox
- Total amount for outgoing transactions
- Ability to delete a watch-only login
- Notify with when a Jade firmware update is available

### Changed
- Make account archiving non experimental
- Add feedback to user when updating wallet watch-only settings
- Enable jade channel selector via command line option
- Increased the size of sign up dialog titles
- Moved empty transactions list label to top left of the container
- In order to setup watch-only, username and password require 8+ characters
- Add indication of logged in wallets in sidebar and network view wallets list
- Added cancel button to change pin dialog
- Reduced application icon size
- Replace support button by help icon
- Display total amount on transaction list (for BTC and L-BTC only)
- Show firmware type (radio/no radio) next to current/new firmware version when confirming the update for Jade.

### Fixed
- Jade emergency restore login
- Fix liquid payment request according to BIP21
- Limit height of language selector
- Ensure at least one account is not archived
- Automatically refresh address list
- Tor activity indicator visibility when loging into singlesig wallets
- Signup dialogs back button functionality and visibility
- Prevent send dialog address textfield grow container
- In transaction details, hide entity label when empty
- Enhanced consistency of paddings and alignments of UI containers
- Allow to rename unselected accounts
- Improve layout of Jade firmware details
- Fix remove wallet dialog button padding
- Add cancel button to disable pin access dialog
- Disable pin input when restoring a wallet
- Disable firmware update dialog next button after being clicked
- Visibility of warning icon when controller dialog results in error
- Give feedback to user after successfull pin change

## [1.1.3] - 2022-07-18
### Added
- Enable list addresses and coins on Singlesig wallets
- Support section in general settings to copy Support ID

### Changed
- Enable watch-only login for multisig shield liquid wallets
- Disable option to speedup transaction on watch-only wallets

### Fixed
- Improved Jade serial port communication

## [1.1.2] - 2022-06-28
### Added

### Changed
- Refactor json conversion

### Fixed
- Fix utf8 memo
- Fix for assets with no ticker or issuer
## [1.1.1] - 2022-06-17
### Added

### Changed
- Updates GDK to 0.0.54.post1

### Fixed
- Net value of redeposits after sending

## [1.1.0] - 2022-06-02
### Added
- Singlesig Bitcoin wallet support for Ledger hardware devices
- New experimental feature, export account addresses to .csv file

### Changed
- Automatic check for Jade firmware updates upon plug-in
- Uses Electrum session for HTTP requests
- Updates GDK to 0.0.53

### Fixed
- Prevent restoring a non existing multisig shield wallets
- Show correct recipient address in transaction details dialog
- Disable option to create account on watch-only wallets

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
