import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "jade.js" as JadeJS

VFlickable {
    signal updateClicked()
    signal setupFinished(Context context)
    required property JadeDevice device
    required property var latestFirmware
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0
    function setup() {
        if (Settings.enableTestnet) {
            deployment_dialog.createObject(self).open()
        } else {
            controller.setup('mainnet')
        }
    }
    StackView.onActivated: self.setup()
    id: self
    spacing: 10
    JadeSetupController {
        id: controller
        device: self.device
        onHttpRequest: (request) => {
            const dialog = http_request_dialog.createObject(self, { request, context: null })
            dialog.open()
        }
        onSetupFinished: (context) => self.setupFinished(context)
    }
    SwipeView {
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: 400
        Layout.preferredHeight: 500
        clip: true
        interactive: false
        currentIndex: {
            const state = self.device.state
            const status = self.device.status
            if (state === JadeDevice.StateUninitialized) {
                return 0
            }
            if (state === JadeDevice.StateUnsaved) {
                return 1
            }
            return -1
        }
        StepPane {
            title: 'Create or Restore'
            image: JadeJS.image(self.device, 7)
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 325
                Layout.topMargin: 10
                busy: !(controller.monitor?.idle ?? true) || self.device.status === JadeDevice.StatusHandleClientMessage
                enabled: (controller.monitor?.idle ?? true) && self.device.status !== JadeDevice.StatusHandleClientMessage
                text: 'Set up Jade'
                onClicked: self.setup()
            }
        }
        StepPane {
            title: qsTrId('id_create_a_pin')
            image: JadeJS.image(self.device, 6)
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 325
                Layout.topMargin: 20
                busy: !(controller.monitor?.idle ?? true) || self.device.status === JadeDevice.StatusHandleClientMessage
                enabled: (controller.monitor?.idle ?? true) && self.device.status !== JadeDevice.StatusHandleClientMessage
                text: 'Set up Jade'
                onClicked: self.setup()
            }
        }
    }
    RegularButton {
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        enabled: (self.debug || self.latestFirmware) && self.device.status === JadeDevice.StatusIdle
        text: qsTrId('id_firmware_update')
        onClicked: self.updateClicked()
    }

    Component {
        id: http_request_dialog
        JadeHttpRequestDialog {
        }
    }

    Component {
        id: deployment_dialog
        DeploymentDialog {
            onDeploymentSelected: (deployment) => controller.setup(deployment)
        }
    }

    component StepPane: ColumnLayout {
        required property string title
        required property string image
        id: step_pane
        VSpacer {
        }
        MultiImage {
            Layout.alignment: Qt.AlignCenter
            foreground: step_pane.image
            width: 352
            height: 240
        }
        Pane {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 325
            Layout.topMargin: 20
            padding: 20
            background: Rectangle {
                radius: 4
                border.width: 2
                border.color: '#00BCFF'
                color: '#222226'
            }
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#00BCFF'
                    font.pixelSize: 12
                    font.weight: 600
                    font.capitalization: Font.AllUppercase
                    horizontalAlignment: Label.AlignHCenter
                    text: 'Set up your Jade'
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFFFFF'
                    font.pixelSize: 14
                    font.weight: 600
                    horizontalAlignment: Label.AlignHCenter
                    text: step_pane.title
                    wrapMode: Label.WordWrap
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#9C9C9C'
                    font.pixelSize: 12
                    font.weight: 400
                    horizontalAlignment: Label.AlignHCenter
                    text: 'Enter and confirm a unique PIN that you will enter to unlock Jade.'
                    wrapMode: Label.WordWrap
                }
            }
        }
    }
}
