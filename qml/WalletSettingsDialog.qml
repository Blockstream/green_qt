import Blockstream.Green
import Blockstream.Green.Core
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
        const sessions = new Set()
        for (let i = 0; i < self.context.accounts.length; i++) {
            const account = self.context.accounts[i]
            const session = account.session
            if (sessions.has(session)) continue
            if (session.network.electrum) continue
            sessions.add(session)
        }
        return [...sessions.values()].sort((a, b) => {
            if (!a.network.liquid && b.network.liquid) return -1
            if (a.network.liquid && !b.network.liquid) return 1
            return 0
        })
    }

    AnalyticsView {
        id: analytics_view
        active: self.opened
        name: 'WalletSettingsGeneral'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
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
        contentItem: Label {
            text: b.text
            Layout.fillWidth: true
            rightPadding: 12
            font.styleName: 'Regular'
        }
    }
    contentItem: RowLayout {
        id: layout
        spacing: 20
        ColumnLayout {
            id: side_bar
            Layout.fillWidth: false
            spacing: 10
            B {
                name: 'WalletSettingsGeneral'
                index: 0
                text: qsTrId('id_general')
            }
            B {
                name: 'WalletSettingsWatchOnly'
                index: 1
                text: qsTrId('id_watchonly')
                visible: !self.context.watchonly
            }
            B {
                name: 'WalletSettingsSecurity'
                index: 2
                text: qsTrId('id_security')
                enabled: !self.context.device
            }
            B {
                name: 'WalletSettings2FA'
                index: 3
                text: qsTrId('id_twofactor_authentication')
                enabled: !self.context.watchonly
            }
            B {
                name: 'WalletSettingsRecovery'
                index: 4
                text: qsTrId('id_recovery')
                enabled: self.context.wallet.login instanceof PinData
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
            WalletWatchOnlySettingsView {
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
                active: stack_layout.currentIndex === 4
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
