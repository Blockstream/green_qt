pragma ComponentBehavior: Bound

import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Pane {
    signal sendClicked()
    signal receiveClicked()
    signal swapClicked()
    signal buyClicked()
    signal jadeDetailsClicked()
    
    required property Context context
    
    id: self
    clip: true
    focusPolicy: Qt.ClickFocus
    leftPadding: 16
    rightPadding: 16
    topPadding: 0
    bottomPadding: 0
    background: Rectangle {
        radius: 4
        color: '#181818'
        border.width: 1
        border.color: '#262626'
    }
    contentItem: RowLayout {
        Flickable {
            Layout.fillHeight: true
            Layout.fillWidth: true
            id: flickable
            contentWidth: layout.implicitWidth
            focusPolicy: Qt.ClickFocus
            implicitHeight: layout.implicitHeight
            RowLayout {
                id: layout
                spacing: 0
                TotalBalanceCard {
                    context: self.context
                }
                Separator {
                    visible: jade_card.visible
                }
                JadeCard {
                    id: jade_card
                    context: self.context
                    onDetailsClicked: self.jadeDetailsClicked()
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 8
            TransactButton {
                action.shortcut: 'Ctrl+S'
                action.onTriggered: self.sendClicked()
                enabled: UtilJS.isSendEnabled(self.context)
                icon.source: 'qrc:/svg/send.svg'
                text: qsTrId('id_send')
                // TODO move to send page
                // self.checkDeviceMatches() && self.currentAccount && !(self.currentAccount.session.config?.twofactor_reset?.is_active ?? false)
            }
            TransactButton {
                action.shortcut: 'Ctrl+R'
                action.onTriggered: self.receiveClicked()
                icon.source: 'qrc:/svg/receive.svg'
                text: qsTrId('id_receive')
                // TODO move to receive page
                // self.checkDeviceMatches() && self.currentAccount && !(self.currentAccount.session.config?.twofactor_reset?.is_active ?? false)
            }
            MoreButton {
            }
        }
    }
    // Image {
    //     source: 'qrc:/svg2/arrow_right.svg'
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.left: parent.left
    //     visible: flickable.contentX > 0
    //     rotation: 180
    //     opacity: 0.5
    //     TapHandler {
    //         onTapped: flickable.flick(2000, 0)
    //     }
    // }
    // Image {
    //     source: 'qrc:/svg2/arrow_right.svg'
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.right: parent.right
    //     visible: flickable.contentWidth - flickable.contentX > flickable.width
    //     opacity: 0.5
    //     TapHandler {
    //         onTapped: flickable.flick(-2000, 0)
    //     }
    // }

    // TODO: Extract to design system components
    component TransactButton: PrimaryButton {
        Layout.minimumWidth: 110
        radius: 5
        spacing: 4
        leftPadding: 12
        rightPadding: 12
        topPadding: 8
        bottomPadding: 8
        font.pixelSize: 14
        action: Action {
            enabled: UtilJS.effectiveVisible(self)
        }
    }

    component MoreButton: AbstractButton {
        id: more_btn
        Layout.minimumWidth: 110
        spacing: 4
        horizontalPadding: 12
        verticalPadding: 10
        font.pixelSize: 14
        font.weight: 600
        visible: self.context.mainnet
        onClicked: more_menu.visible ? more_menu.close() : more_menu.open()

        function onSwapClicked() {
            Analytics.recordEvent('swap_entry', AnalyticsJS.segmentationSession(Settings, self.context))
            self.swapClicked()
        }

        background: Item {
            Rectangle {
                anchors.fill: parent
                color: more_btn.hovered || more_btn.visualFocus || more_menu.visible ? '#062F4A' : 'transparent'
                radius: 5
            }
        }

        contentItem: RowLayout {
            spacing: 4
            HSpacer {
            }
            Label {
                text: qsTrId('id_more')
                color: '#00BCFF'
                font: more_btn.font
            }
            Image {
                source: 'qrc:/svg2/caret-down.svg'
                sourceSize.width: 20
                sourceSize.height: 20
                rotation: more_menu.visible ? 180 : 0
                Behavior on rotation {
                    NumberAnimation { duration: 200 }
                }
            }
            HSpacer {
            }
        }

        GMenu {
            id: more_menu
            x: more_btn.width - more_menu.width
            y: more_btn.height + 8
            pointerX: 0.75
            padding: 16
            contentItem: RowLayout {
                spacing: 8
                ActionTile {
                    id: buy_action_tile
                    enabled: !!UtilJS.accounts(self.context).find(account => !account.network.liquid)
                    text: qsTrId('id_buy')
                    icon.source: 'qrc:/svg/coin.svg'
                    onClicked: {
                        more_menu.close()
                        self.buyClicked()
                    }
                }
                ActionTile {
                    id: swap_action_tile
                    enabled: !self.context.watchonly && !self.context.wallet.login.device
                    text: qsTrId('id_swap')
                    icon.source: 'qrc:/fafafa/20/arrows-down-up.svg'
                    onClicked: {
                        more_menu.close()
                        more_btn.onSwapClicked()
                    }
                }
            }
        }

        Action {
            shortcut: 'Ctrl+B'
            enabled: more_btn.visible && buy_action_tile.enabled
            onTriggered: self.buyClicked()
        }

        Action {
            shortcut: 'Ctrl+W'
            enabled: more_btn.visible && swap_action_tile.enabled
            onTriggered: more_btn.onSwapClicked()
        }
    }

    component ActionTile: AbstractButton {
        id: tile
        implicitWidth: 76
        leftPadding: 8
        rightPadding: 8
        topPadding: 16
        bottomPadding: 16
        background: Rectangle {
            color: '#181818'
            border.width: 1
            border.color: '#262626'
            radius: 4
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: '#FFFFFF'
                opacity: tile.enabled && tile.hovered ? 0.05 : 0
            }
        }
        contentItem: ColumnLayout {
            spacing: 4
            Image {
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                Layout.alignment: Qt.AlignHCenter
                source: tile.icon.source
                fillMode: Image.PreserveAspectFit
                opacity: tile.enabled ? 1 : 0.25
            }
            Label {
                Layout.fillWidth: true
                text: tile.text
                font.pixelSize: 14
                font.weight: 400
                color: '#FAFAFA'
                horizontalAlignment: Text.AlignHCenter
                opacity: tile.enabled ? 1 : 0.25
            }
        }
    }

    component Separator: Rectangle {
        Layout.minimumWidth: 1
        Layout.maximumWidth: 1
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        Layout.fillHeight: true
        color: '#FFF'
        opacity: 0.04
    }
}
