import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
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
    VSpacer {
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
            image: 'qrc:/png/jade_7.png'
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 325
                Layout.topMargin: 10
                busy: self.device.status === JadeDevice.StatusHandleClientMessage
                enabled: self.device.status !== JadeDevice.StatusHandleClientMessage
                text: qsTrId('id_setup_jade')
                onClicked: self.setup()
            }
        }
        StepPane {
            title: qsTrId('id_create_a_pin')
            image: 'qrc:/png/jade_6.png'
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 325
                Layout.topMargin: 20
                busy: self.device.status === JadeDevice.StatusHandleClientMessage
                enabled: self.device.status !== JadeDevice.StatusHandleClientMessage
                text: qsTrId('id_setup_jade')
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
    VSpacer {
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
                border.color: '#00B45A'
                color: '#222226'
            }
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#00B45A'
                    font.pixelSize: 12
                    font.weight: 600
                    font.capitalization: Font.AllUppercase
                    horizontalAlignment: Label.AlignHCenter
                    text: qsTrId('id_setup_your_jade')
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
                    text: qsTrId('id_enter_and_confirm_a_unique_pin')
                    wrapMode: Label.WordWrap
                }
            }
        }
    }
}
