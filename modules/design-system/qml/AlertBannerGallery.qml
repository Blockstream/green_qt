import Blockstream.Controls
import Blockstream.Theme
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    required property Colors colors
    property string lastEvent: 'Click an action, link, or dismiss control.'

    id: self
    spacing: 24
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        UiLabel {
            text: 'UiAlertBanner'
            typography: Theme.typography.titleSSemibold
            color: self.colors.textPrimary
        }
        UiLabel {
            Layout.fillWidth: true
            text: self.lastEvent
            typography: Theme.typography.bodyS
            color: self.colors.textSubtle
            wrapMode: Text.Wrap
        }
    }
    Pane {
        Layout.fillWidth: true
        padding: 12
        background: Rectangle {
            color: self.colors.surfaceBase
            border.color: self.colors.borderSubtle
            radius: 6
        }
        contentItem: ColumnLayout {
            spacing: 12
            UiAlertBanner {
                id: negative_banner
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                colors: self.colors
                variant: UiAlertBanner.Negative
                title: 'Payment failed'
                description: 'The network rejected this transaction. Check your fee rate and try again.'
                dismissible: true
                onDismissed: {
                    negative_banner.visible = false
                    self.lastEvent = 'Dismissed: Payment failed'
                }
                Row {
                    spacing: 8
                    UiButton {
                        size: UiButton.ExtraSmall
                        variant: UiButton.PrimaryInverted
                        colors: self.colors
                        text: 'Try again'
                        onClicked: self.lastEvent = 'Primary action: Try again'
                    }
                    UiButton {
                        size: UiButton.ExtraSmall
                        variant: UiButton.SecondaryInverted
                        colors: self.colors
                        text: 'Details'
                        onClicked: self.lastEvent = 'Secondary action: Details'
                    }
                }
            }
            UiAlertBanner {
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                colors: self.colors
                variant: UiAlertBanner.Warning
                title: 'Back up your wallet'
                description: 'Anyone with a copy of your recovery phrase can spend your funds. Keep these words offline and protected.'
                UiButton {
                    size: UiButton.ExtraSmall
                    variant: UiButton.PrimaryInverted
                    colors: self.colors
                    text: 'Back up'
                    onClicked: self.lastEvent = 'Primary action: Back up'
                }
            }
            UiAlertBanner {
                id: info_banner
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                colors: self.colors
                variant: UiAlertBanner.Info
                title: 'New firmware available'
                description: 'Update Jade to the latest firmware for security fixes and performance improvements.'
                dismissible: true
                onDismissed: {
                    info_banner.visible = false
                    self.lastEvent = 'Dismissed: New firmware available'
                }
                UiButton {
                    size: UiButton.ExtraSmall
                    variant: UiButton.SecondaryInverted
                    colors: self.colors
                    text: 'Later'
                    onClicked: self.lastEvent = 'Secondary action: Later'
                }
            }
            UiAlertBanner {
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                colors: self.colors
                variant: UiAlertBanner.Info
                title: 'Learn about 2FA'
                description: 'Two-factor authentication protects your funds if your device is lost or stolen.'
                UiLink {
                    colors: self.colors
                    size: UiLink.Medium
                    text: 'Read the guide'
                    url: 'https://help.blockstream.com/'
                    onLinkActivated: (url) => self.lastEvent = `Link activated: ${url}`
                }
            }
            UiAlertBanner {
                id: long_link_banner
                Layout.fillWidth: true
                Layout.maximumWidth: 280
                colors: self.colors
                variant: UiAlertBanner.Info
                title: 'Recovery help'
                description: 'Narrow dismissible banner with a long footer link.'
                dismissible: true
                onDismissed: {
                    long_link_banner.visible = false
                    self.lastEvent = 'Dismissed: Recovery help'
                }
                UiLink {
                    colors: self.colors
                    size: UiLink.Medium
                    text: 'Open the full recovery phrase guide with a very long translated label'
                    url: 'https://help.blockstream.com/'
                    onLinkActivated: (url) => self.lastEvent = `Link activated: ${url}`
                }
            }
            UiButton {
                visible: !negative_banner.visible || !info_banner.visible || !long_link_banner.visible
                size: UiButton.ExtraSmall
                variant: UiButton.Secondary
                colors: self.colors
                text: 'Restore dismissed banners'
                onClicked: {
                    negative_banner.visible = true
                    info_banner.visible = true
                    long_link_banner.visible = true
                    self.lastEvent = 'Restored dismissed banners.'
                }
            }
        }
    }
}
