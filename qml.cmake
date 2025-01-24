qt_add_resources(green "qtquickcontrols2"
    PREFIX "/"
    BASE qml
    FILES
        qml/qtquickcontrols2.conf
        qml/+windows/qtquickcontrols2.conf
)

SET(QML_FILES
    qml/analytics.js
    qml/jade.js
    qml/util.js
    qml/WalletSecuritySettingsView.qml
    qml/GCard.qml
    qml/TwoFactorEnableDialog.qml
    qml/DebugRectangle.qml
    qml/WalletGeneralSettingsView.qml
    qml/WalletsView.qml
    qml/TransactionView.qml
    qml/HSpacer.qml
    qml/WalletDialog.qml
    qml/StackViewPushAction.qml
    qml/SignLiquidTransactionResolverView.qml
    qml/GHeader.qml
    qml/Wallet2faSettingsView.qml
    qml/BlockstreamView.qml
    qml/GComboBox.qml
    qml/TwoFactorAuthExpiryDialog.qml
    qml/Tag.qml
    qml/AccountDelegate.qml
    qml/DeleteWalletDialog.qml
    qml/ChangePinDialog.qml
    qml/MnemonicView.qml
    qml/TwoFactorLimitDialog.qml
    qml/JadeUpdateDialog.qml
    qml/JadeSignMessageView.qml
    qml/MainMenuBar.qml
    qml/GTextField.qml
    qml/NLockTimeDialog.qml
    qml/MessageDialog.qml
    qml/GSwitch.qml
    qml/VSpacer.qml
    qml/AbstractDialog.qml
    qml/ControllerDialog.qml
    qml/WizardPage.qml
    qml/Spacer.qml
    qml/AssetDelegate.qml
    qml/RemoveWalletDialog.qml
    qml/DialogFooter.qml
    qml/OutputDelegate.qml
    qml/MnemonicPage.qml
    qml/PersistentLoader.qml
    qml/AnimLoader.qml
    qml/PreferencesView.qml
    qml/AssetDrawer.qml
    qml/AddressesListView.qml
    qml/AssetListView.qml
    qml/DescriptiveRadioButton.qml
    qml/SettingsPage.qml
    qml/CopyableLabel.qml
    qml/TransactionProgress.qml
    qml/QRCode.qml
    qml/JadeSignLiquidTransactionView.qml
    qml/GButton.qml
    qml/WordField.qml
    qml/WalletViewHeader.qml
    qml/AmountValidator.qml
    qml/DisableAllPinsDialog.qml
    qml/OutputsListView.qml
    qml/GPane.qml
    qml/main.qml
    qml/DialogHeader.qml
    qml/WalletSettingsDialog.qml
    qml/TransactionListView.qml
    qml/CancelTwoFactorResetDialog.qml
    qml/GTextArea.qml
    qml/Collapsible.qml
    qml/ScannerPopup.qml
    qml/DeviceImage.qml
    qml/DeviceBadge.qml
    qml/SelectCoinsView.qml
    qml/AccountView.qml
    qml/TwoFactorDisableDialog.qml
    qml/TransactionDelegate.qml
    qml/AnalyticsConsentDialog.qml
    qml/JadeSignTransactionView.qml
    qml/SideBar.qml
    qml/AlertView.qml
    qml/WalletAdvancedSettingsView.qml
    qml/RequestTwoFactorResetDialog.qml
    qml/BlinkAnimation.qml
    qml/EditableLabel.qml
    qml/FixedErrorBadge.qml
    qml/QRCodePopup.qml
    qml/GListView.qml
    qml/ProgressIndicator.qml
    qml/ScannerView.qml
    qml/StatusBar.qml
    qml/PinView.qml
    qml/GFlickable.qml
    qml/TransactionStatusBadge.qml
    qml/PopupBalloon.qml
    qml/SectionLabel.qml
    qml/AddressDelegate.qml
    qml/Constants.qml
    qml/SideButton.qml
    qml/SettingsBox.qml
    qml/WalletRecoverySettingsView.qml
    qml/CoinDelegate.qml
    qml/MainPage.qml
    qml/OverviewPage.qml
    qml/SetRecoveryEmailDialog.qml
    qml/MainPageHeader.qml
    qml/LedgerSignTransactionView.qml
    qml/AssetIcon.qml
    qml/AuthHandlerTaskView.qml
    qml/GetCredentialsView.qml
    qml/TaskDispatcherInspector.qml
    qml/TProgressBar.qml
    qml/TListView.qml
    qml/GMenu.qml
    qml/GStackView.qml
    qml/WalletDrawer.qml
    qml/CreateAccountDrawer.qml
    qml/ReceiveDrawer.qml
    qml/SendDrawer.qml
    qml/BackButton.qml
    qml/SendAccountAssetSelector.qml
    qml/AccountAssetField.qml
    qml/AddressField.qml
    qml/AmountField.qml
    qml/PrimaryButton.qml
    qml/RegularButton.qml
    qml/LinkButton.qml
    qml/CloseButton.qml
    qml/CopyAddressButton.qml
    qml/AssetField.qml
    qml/AssetSelector.qml
    qml/SearchField.qml
    qml/AssetsDrawer.qml
    qml/DrawerTitle.qml
    qml/FieldTitle.qml
    qml/CreateAccountPage.qml
    qml/SecurityPolicyButton.qml
    qml/WalletHeaderCard.qml
    qml/AssetsCard.qml
    qml/TotalBalanceCard.qml
    qml/PriceCard.qml
    qml/FeeRateCard.qml
    qml/CardBar.qml
    qml/StackViewPage.qml
    qml/SelectRecoveryKeyPage.qml
    qml/MnemonicSizeSelector.qml
    qml/XPubField.qml
    qml/InfoCard.qml
    qml/PrintButton.qml
    qml/TermOfServicePage.qml
    qml/AddWalletPage.qml
    qml/MnemonicWarningsPage.qml
    qml/MnemonicBackupPage.qml
    qml/MnemonicCheckPage.qml
    qml/WalletView.qml
    qml/PinField.qml
    qml/PinLoginPage.qml
    qml/LoadingPage.qml
    qml/SetupPinPage.qml
    qml/RegisterPage.qml
    qml/RestorePage.qml
    qml/RestoreCheckPage.qml
    qml/WatchOnlyWalletPage.qml
    qml/MultisigWatchOnlyAddPage.qml
    qml/WatchOnlyLoginPage.qml
    qml/UsernameField.qml
    qml/PasswordField.qml
    qml/WatchOnlyNetworkPage.qml
    qml/FreshWalletView.qml
    qml/AbstractDrawer.qml
    qml/WalletsDrawer.qml
    qml/AlreadyRestoredPage.qml
    qml/UseDevicePage.qml
    qml/ConnectJadePage.qml
    qml/JadePage.qml
    qml/JadeInitializedView.qml
    qml/JadeLoginView.qml
    qml/JadeUninitializedView.qml
    qml/JadeUnlockView.qml
    qml/JadeFirmwareConfigSelector.qml
    qml/ArchivedAccountsDialog.qml
    qml/JadeNotificationDialog.qml
    qml/SendPage.qml
    qml/SendConfirmPage.qml
    qml/PinPadButton.qml
    qml/TransactionCompletedPage.qml
    qml/TransactionDetailsDrawer.qml
    qml/GStackLayout.qml
    qml/DeploymentDialog.qml
    qml/TaskPageFactory.qml
    qml/SignMessagePage.qml
    qml/AddressDetailsDrawer.qml
    qml/CircleButton.qml
    qml/ShareButton.qml
    qml/AddressDetailsPage.qml
    qml/DevicePage.qml
    qml/JadeDeviceDelegate.qml
    qml/JadeInstructionsView.qml
    qml/JadeCard.qml
    qml/DevicePromptView.qml
    qml/JadeBasicUpdateView.qml
    qml/JadeAdvancedUpdateView.qml
    qml/JadeConfirmUpdatePage.qml
    qml/JadeUpdateDialog2.qml
    qml/JadeVerifyAddressPage.qml
    qml/Hint.qml
    qml/SplashPage.qml
    qml/AppPage.qml
    qml/WalletOptionsButton.qml
    qml/SelectFeePage.qml
    qml/AssetDetailsPage.qml
    qml/AppBanner.qml
    qml/ConnectLedgerPage.qml
    qml/LedgerPage.qml
    qml/LedgerDeviceDelegate.qml
    qml/TTextField.qml
    qml/ReceiveAccountAssetSelector.qml
    qml/ExportTransactionsDialog.qml
    qml/CompletedImage.qml
    qml/CanceledImage.qml
    qml/ExportAddressesDialog.qml
    qml/AddressVerifiedBadge.qml
    qml/NotificationsDrawer.qml
    qml/ErrorPage.qml
    qml/MultiImage.qml
    qml/TwoFactorEnableGenericView.qml
    qml/TwoFactorEnablePhoneView.qml
    qml/TwoFactorEnableGAuthPage.qml
    qml/SecureFundsPage.qml
    qml/JadeHttpRequestDialog.qml
    qml/LinkLabel.qml
    qml/PassphraseDialog.qml
    qml/SinglesigWatchOnlyAddPage.qml
    qml/WalletWatchOnlySettingsView.qml
    qml/JadeGetMasterBlindingKeyView.qml
    qml/StatusDrawer.qml
    qml/TwoFactorExpiredSelectAccountPage.qml
    qml/Bip21Footer.qml
    qml/TorFooter.qml
    qml/OutagePage.qml
    qml/RedepositPage.qml
    qml/RedepositConfirmPage.qml
    qml/RedepositLiquidPage.qml
    qml/RedepositLiquidConfirmPage.qml
    qml/Countries.qml
    qml/PhoneField.qml
    qml/UpdateUnspentsDrawer.qml
    qml/VFlickable.qml
    qml/JadeFirmwareUpdatedPage.qml
    qml/AddressLabel.qml
    qml/JadeGenuineCheckDialog.qml
    qml/PromoDrawer.qml
    qml/JadeGenuineCheckPage.qml
    qml/JadeGenuineCheckingPage.qml
    qml/PromoCard.qml
    qml/ReceivePage.qml
    qml/JadeDetailsDrawer.qml
    qml/HelpButton.qml
    qml/RequestSupportPage.qml
    qml/SupportSubmittedPage.qml
    qml/SupportDrawer.qml
)

if (GREEN_NO_RESOURCES)
    set(QML_FILES_2)
    target_compile_definitions(green PRIVATE SOURCE_DIR=${CMAKE_SOURCE_DIR})
else()
    set(QML_FILES_2 ${QML_FILES})
endif()

qt_add_qml_module(green
    URI Blockstream.Green
    VERSION 1.0
    NO_PLUGIN
    DEPENDENCIES QtQuick
    SOURCES src/networkmanager.cpp
    QML_FILES ${QML_FILES_2}
    #ENABLE_TYPE_COMPILER
    NO_CACHEGEN
    NO_LINT
)
