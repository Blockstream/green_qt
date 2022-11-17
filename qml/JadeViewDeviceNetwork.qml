import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

import "analytics.js" as AnalyticsJS

Pane {
    id: self
    property bool comingSoon
    property Network network
    property JadeDevice device
    Layout.fillWidth: true
    Layout.preferredHeight: 60
    enabled: controller.enabled
    background: Item {
        Rectangle {
            width: parent.width
            height: 1
            y: parent.height - 1
            color: constants.c600
        }
    }
    padding: 0
    bottomPadding: 8
    topPadding: 8
    JadeLoginController {
        id: controller
        device: comingSoon ? null : self.device
        network: self.network.id
        onInvalidPin: self.ToolTip.show(qsTrId('id_invalid_pin'), 2000);
        onLoginDone: Analytics.recordEvent('wallet_login', AnalyticsJS.segmentationWalletLogin(controller.wallet, { method: 'hardware' }))
    }
    contentItem: RowLayout {
        spacing: constants.s1
        RowLayout {
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            spacing: constants.s1
            Image {
                source: iconFor(self.network)
                sourceSize.width: 24
                sourceSize.height: 24
            }
            Label {
                Layout.fillWidth: true
                text: self.network.displayName
            }
        }
        RowLayout {
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            spacing: constants.s1
            Image {
                fillMode: Image.PreserveAspectFit
                sourceSize.height: 24
                sourceSize.width: 24
                source: self.network.electrum ? 'qrc:/svg/key.svg' : 'qrc:/svg/multi-sig.svg'
            }
            Label {
                Layout.fillWidth: true
                text: self.network.electrum ? qsTrId('id_singlesig') : qsTrId('id_multisig_shield')
                ToolTip.delay: 300
                ToolTip.visible: mouse_area.containsMouse
                ToolTip.text: self.network.electrum
                      ? qsTrId('id_your_funds_are_secured_by_a')
                      : qsTrId('id_your_funds_are_secured_by')
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    id: mouse_area
                }
            }
        }
        Label {
            Layout.fillWidth: true
            text: controller.wallet ? controller.wallet.name : ''
        }
        RowLayout {
            visible: !comingSoon
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            GButton {
                visible: !controller.wallet || controller.wallet.authentication !== Wallet.Authenticated
                enabled: !controller.active
                text: switch (device.state) {
                    case JadeDevice.StateReady:
                    case JadeDevice.StateTemporary:
                        return qsTrId('id_login')
                    case JadeDevice.StateLocked:
                        return qsTrId('id_unlock')
                    default:
                        return qsTrId('id_setup_jade')
                }
                onClicked: controller.active = true
            }
            GButton {
                visible: controller.wallet && controller.wallet.authentication === Wallet.Authenticated
                text: qsTrId('id_go_to_wallet')
                onClicked: navigation.go(`/${self.network.key}/${controller.wallet.id}`)
            }
        }
        RowLayout {
            visible: comingSoon
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            Label {
                background: Rectangle {
                    color: 'yellow'
                    radius: height / 2
                }
                color: 'black'
                leftPadding: 8
                rightPadding: 8
                topPadding: 2
                bottomPadding: 2
                text: qsTrId('id_coming_soon')
                font.pixelSize: 10
                font.styleName: 'Medium'
                font.capitalization: Font.AllUppercase
            }
        }
    }
}
