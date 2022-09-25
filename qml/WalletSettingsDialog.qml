import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WalletDialog {
    id: self
    width: 900
    height: 600
    icon: 'qrc:/svg/gearFill.svg'
    title: qsTrId('id_settings')

    AnalyticsView {
        id: analytics_view
        active: self.opened
        name: 'WalletSettingsGeneral'
        segmentation: segmentationSession(self.wallet)
    }

    component B: Button {
        id: b
        required property string name
        required property int index
        Layout.fillWidth: true
        flat: true
        topPadding: 8
        bottomPadding: 8
        leftPadding: 16
        rightPadding: 16
        topInset: 0
        leftInset: 0
        rightInset: 0
        bottomInset: 0
        icon.width: 24
        icon.height: 24
        icon.color: 'white'
        highlighted: stack_layout.currentIndex === index
        onClicked: {
            analytics_view.name = name
            stack_layout.currentIndex = index
        }
        background: Item {
            Rectangle {
                anchors.fill: parent
                visible: b.highlighted
                color: constants.c500
                radius: 4
            }
            Rectangle {
                anchors.fill: parent
                visible: b.hovered
                color: constants.c300
                radius: 4
            }
        }
        contentItem: RowLayout {
            spacing: 16
            Image {
                source: b.icon.source
                sourceSize.width: b.icon.width
                sourceSize.height: b.icon.height
            }
            Label {
                text: b.text
                Layout.fillWidth: true
                rightPadding: 12
                font.styleName: 'Regular'
            }
        }
    }
    contentItem: RowLayout {
        id: layout
        spacing: constants.p3
        ColumnLayout {
            id: side_bar
            Layout.fillWidth: false
            spacing: constants.p1
            B {
                name: 'WalletSettingsGeneral'
                index: 0
                text: 'General'
                icon.source: 'qrc:/svg/preferences.svg'
            }
            B {
                name: 'WalletSettingsSecurity'
                index: 1
                text: 'Security'
                icon.source: 'qrc:/svg/security.svg'
                enabled: !self.wallet.device
            }
            B {
                name: 'WalletSettings2FA'
                index: 2
                text: 'Two Factor Authentication'
                icon.source: 'qrc:/svg/2fa_general.svg'
                enabled: !self.wallet.network.electrum
            }
            B {
                name: 'WalletSettingsRecovery'
                index: 3
                text: 'Recovery'
                icon.source: 'qrc:/svg/recovery.svg'
            }
            VSpacer { }
        }
        StackLayout {
            id: stack_layout
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            GFlickable {
                id: general_settings_flickable
                contentHeight: general_view.height
                interactive: false
                WalletGeneralSettingsView {
                    id: general_view
                    width: general_settings_flickable.availableWidth
                    wallet: self.wallet
                }
            }

            GFlickable {
                id: security_settings_flickable
                contentHeight: security_view.height
                interactive: false
                WalletSecuritySettingsView {
                    id: security_view
                    width: security_settings_flickable.availableWidth
                    wallet: self.wallet
                }
            }

            Loader {
                active: !self.wallet.network.electrum
                sourceComponent: GFlickable {
                    id: two_factor_settings_flickable
                    contentHeight: two_factor_auth_view.height
                    Wallet2faSettingsView {
                        id: two_factor_auth_view
                        width: two_factor_settings_flickable.availableWidth
                        wallet: self.wallet
                    }
                }
            }

            GFlickable {
                id: recovery_settings_flickable
                contentHeight: recovery_view.height
                WalletRecoverySettingsView {
                    id: recovery_view
                    width: recovery_settings_flickable.availableWidth
                    wallet: self.wallet
                }
            }
        }
    }
}
