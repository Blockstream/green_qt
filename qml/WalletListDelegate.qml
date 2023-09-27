import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQml

ItemDelegate {
    required property Wallet wallet
    property bool valid: wallet.loginAttemptsRemaining > 0

    id: delegate
    padding: 0
    leftPadding: 8
    rightPadding: 8
    highlighted: ListView.isCurrentItem
    background: Rectangle {
        color: Qt.rgba(1, 1, 1, delegate.hovered ? 0.05 : 0)
        Rectangle {
            width: parent.width
            height: 1
            opacity: 0.1
            color: 'white'
            anchors.bottom: parent.bottom
        }
    }
    contentItem: RowLayout {
        spacing: constants.s1
        Label {
            text: wallet.name
            elide: Label.ElideRight
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth + 1
        }
        Loader {
            active: 'type' in wallet.deviceDetails
            visible: active
            sourceComponent: DeviceBadge {
                device: wallet.context?.device
                details: wallet.deviceDetails
            }
        }
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: wallet.context
            height: radius * 2
            width: radius * 2
            radius: 4
            color: constants.g500
        }
        HSpacer {
        }
        Label {
            visible: wallet.loginAttemptsRemaining === 0
            text: '\u26A0'
            font.pixelSize: 18
            ToolTip.text: qsTrId('id_no_attempts_remaining')
            ToolTip.visible: !valid && delegate.hovered
            ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
        }
        ToolButton {
            text: '\u22EF'
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            onClicked: wallet_menu.open()
            Menu {
                id: wallet_menu
                MenuItem {
                    enabled: wallet.context && !wallet.context.device
                    text: qsTrId('id_log_out')
                    onTriggered: wallet.disconnect()
                }
                MenuItem {
                    text: qsTrId('id_remove_wallet')
                    onClicked: remove_wallet_dialog.createObject(window, { wallet }).open()
                }
            }
        }
    }
    onClicked: {
        if (wallet.context) {
            navigation.set({ wallet: wallet.id })
        } else if ('type' in wallet.deviceDetails && !wallet.hasPinData) {
            const view = wallet.deviceDetails.type === 'jade' ? 'jade' : 'ledger'
            navigation.push({ view })
        } else {
            navigation.set({ flow: 'login', wallet: wallet.id })
        }
    }
}
