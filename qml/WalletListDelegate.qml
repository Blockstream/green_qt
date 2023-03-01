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
        Image {
            fillMode: Image.PreserveAspectFit
            sourceSize.height: 24
            sourceSize.width: 24
            source: delegate.wallet.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
        }
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
                device: wallet.device
                details: wallet.deviceDetails
            }
        }
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            visible: wallet.ready
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
                    enabled: wallet.session && wallet.session.connected && wallet.authentication === Wallet.Authenticated && !wallet.device
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
    onClicked: navigation.set({ view: wallet.network.key, wallet: wallet.id })
}
