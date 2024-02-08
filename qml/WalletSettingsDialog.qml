import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

WalletDialog {
    id: self
    height: 650
    width: 900
    icon: 'qrc:/svg/gearFill.svg'
    title: qsTrId('id_settings')

    readonly property list<Session> sessions: {
        const sessions = []
        for (let i = 0; i < self.context.sessions.length; i++) {
            const session = self.context.sessions[i]
            if (session.network.electrum) continue
            sessions.push(session)
        }
        return sessions.sort((a, b) => {
            if (!a.network.liquid && b.network.liquid) return -1
            if (a.network.liquid && !b.network.liquid) return 1
            return 0
        })
    }

    AnalyticsView {
        id: analytics_view
        active: self.opened
        name: 'WalletSettingsGeneral'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.wallet)
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
                visible: b.enabled && b.hovered
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
                text: qsTrId('id_general')
                icon.source: 'qrc:/svg/preferences.svg'
            }
            B {
                name: 'WalletSettingsSecurity'
                index: 1
                text: qsTrId('id_security')
                icon.source: 'qrc:/svg/security.svg'
                enabled: !self.context.device
            }
            B {
                name: 'WalletSettings2FA'
                index: 2
                text: qsTrId('id_twofactor_authentication')
                icon.source: 'qrc:/svg/2fa_general.svg'
            }
            B {
                name: 'WalletSettingsRecovery'
                index: 3
                text: qsTrId('id_recovery')
                icon.source: 'qrc:/svg/recovery.svg'
                enabled: !self.context.device
            }
            VSpacer { }
        }
        StackLayout {
            id: stack_layout
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            WalletGeneralSettingsView {
                context: self.context
            }
            WalletSecuritySettingsView {
                context: self.context
            }
            Wallet2faSettingsView {
                context: self.context
                sessions: self.sessions
            }
            Loader {
                active: stack_layout.currentIndex === 3
                sourceComponent: GFlickable {
                    id: recovery_settings_flickable
                    contentHeight: recovery_view.height
                    WalletRecoverySettingsView {
                        id: recovery_view
                        width: recovery_settings_flickable.availableWidth
                        context: self.context
                    }
                }
            }
        }
    }
}
