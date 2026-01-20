import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Page {
    required property Context context
    objectName: "SettingsPage"
    id: self
    background: null
    padding: 0

    readonly property list<Session> sessions: {
        const ctx = self.context
        if (!ctx) return []
        const sessions = new Set()
        for (let i = 0; i < ctx.accounts.length; i++) {
            const account = ctx.accounts[i]
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
        active: UtilJS.effectiveVisible(self)
        name: 'WalletSettingsGeneral'
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }

    contentItem: RowLayout {
        spacing: 0
        Pane {
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            padding: 0
            topPadding: 20
            bottomPadding: 20
            leftPadding: 0
            rightPadding: 0
            background: Item {
                Rectangle {
                    width: 1
                    anchors.right: parent.right
                    height: parent.height
                    color: '#262626'
                }
            }
            contentItem: ColumnLayout {
                spacing: 4
                CategoryButton {
                    name: 'WalletSettingsGeneral'
                    index: 0
                    text: qsTrId('id_general')
                    icon.source: 'qrc:/svg2/gear.svg'
                }
                CategoryButton {
                    name: 'WalletSettingsWatchOnly'
                    index: 1
                    text: qsTrId('id_watchonly')
                    icon.source: 'qrc:/svg2/eye.svg'
                    visible: !self.context.watchonly
                }
                CategoryButton {
                    name: 'WalletSettings2FA'
                    index: 2
                    text: qsTrId('id_twofactor_authentication')
                    icon.source: 'qrc:/svg2/lock-simple-thin.svg'
                    enabled: !self.context.watchonly
                }
                VSpacer {
                }
            }
        }
        Pane {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 20
            leftPadding: 120
            rightPadding: 120
            background: null
            contentItem: StackLayout {
                id: stack_layout
                clip: true
                WalletGeneralSettingsView {
                    context: self.context
                }
                WalletWatchOnlySettingsView {
                    context: self.context
                }
                Wallet2faSettingsView {
                    context: self.context
                    sessions: self.sessions
                }
            }
        }
    }

    component CategoryButton: AbstractButton {
        required property string name
        required property int index
        readonly property bool isCurrent: stack_layout.currentIndex === button.index
        Layout.fillWidth: true
        id: button
        leftPadding: 16
        rightPadding: 16
        topPadding: 12
        bottomPadding: 12
        icon.width: 20
        icon.height: 20

        onClicked: {
            analytics_view.name = name
            stack_layout.currentIndex = index
        }

        background: Item {
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                radius: 8
                color: 'white'
                opacity: button.hovered && !button.isCurrent ? 0.1 : 0
                Behavior on opacity {
                    SmoothedAnimation {
                        velocity: 2
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: 'transparent'
                radius: 8
                border.width: 2
                border.color: '#00BCFF'
                visible: button.visualFocus
            }
            Rectangle {
                color: '#00BCFF'
                visible: button.visualFocus || button.isCurrent
                anchors.right: parent.right
                width: 2
                height: parent.height
            }
        }
        contentItem: Label {
            color: button.isCurrent ? '#FFFFFF' : '#A0A0A0'
            font.pixelSize: 14
            font.weight: 600
            opacity: button.enabled ? 1 : 0.4
            text: button.text
            wrapMode: Label.NoWrap
            elide: Label.ElideRight
        }
        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
    }
}
