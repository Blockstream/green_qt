import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Pane {
    id: self
    property bool comingSoon
    property Network network
    property JadeDevice device
    Layout.fillWidth: true
//    Layout.preferredHeight: 60
//    enabled: controller.enabled
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
        onLoginDone: () => {
            Analytics.recordEvent('wallet_login', AnalyticsJS.segmentationWalletLogin(controller.wallet, { method: 'hardware' }))
            navigation.push({ view: self.network.key, wallet: controller.wallet.id })
        }
        onSetPin: (info) => {
            Analytics.recordEvent('jade_initialize', AnalyticsJS.segmentationSession(controller.wallet))
        }
    }
    contentItem: RowLayout {
        spacing: constants.s1
        RowLayout {
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            spacing: constants.s1
            Image {
                source: UtilJS.iconFor(self.network)
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
        ProgressBar {
            Layout.maximumWidth: 32
            Layout.minimumWidth: 32
            visible: controller.dispatcher.busy
            indeterminate: visible
        }
        RowLayout {
            visible: !comingSoon
            Layout.fillWidth: false
            Layout.minimumWidth: 150
            Loader {
                active: device?.state === JadeDevice.StateLocked // !controller?.wallet?.context &&
                visible: active
                sourceComponent: GButton {
                    enabled: !device.unlocking
                    text: qsTrId('id_unlock')
                    onClicked: controller.unlock()
                }
            }
            Loader {
                active: (device?.state === JadeDevice.StateReady || device?.state === JadeDevice.StateTemporary) && !controller.wallet?.context
                visible: active
                sourceComponent: GButton {
                    enabled: !controller.dispatcher.busy
                    text: qsTrId('id_login')
                    onClicked: controller.login()
                }
            }
            Loader {
                active: device?.state === JadeDevice.StateUninitialized
                visible: active
                sourceComponent: GButton {
                    enabled: !controller.dispatcher.busy
                    text: qsTrId('id_setup_jade')
                    onClicked: controller.setup()
                }
            }
            Loader {
                active: controller?.wallet?.context ?? false
                visible: active
                sourceComponent: GButton {
                    text: qsTrId('id_go_to_wallet')
                    onClicked: navigation.push({ view: self.network.key, wallet: controller.wallet.id })
                }
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
                font.weight: 400
                font.styleName: 'Regular'
                font.capitalization: Font.AllUppercase
            }
        }
//        TaskDispatcherInspector {
//            Layout.minimumHeight: 80
//            Layout.minimumWidth: 200
//            dispatcher: controller.dispatcher
//        }
    }
}
