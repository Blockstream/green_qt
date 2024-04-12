import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal firmwareUpdated()
    signal skip(Device device)
    signal closeClicked()
    required property JadeDevice device
    required property bool login
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0
    leftItem: BackButton {
        onClicked: {
            if (stack_view.currentItem && stack_view.currentItem.StackView.index > 0) {
                stack_view.pop()
            } else {
                self.StackView.view.pop()
            }
        }
        visible: stack_view.currentItem && stack_view.currentItem.StackView.index > 0 || self.StackView.index > 0
        enabled: stack_view.currentItem && stack_view.currentItem.StackView.status === StackView.Active && self.StackView.status === StackView.Active
    }
    JadeFirmwareCheckController {
        id: update_controller
        index: firmware_controller.index
        device: self.device
    }
    id: self
    padding: 60
    title: self.device.name
    rightItem: RowLayout {
        Layout.topMargin: 20
        spacing: 20
        LinkButton {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_setup_guide')
            visible: self.device.state === JadeDevice.StateUninitialized
            onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
        }
        WalletOptionsButton {
            wallet: null
            onCloseClicked: self.closeClicked()
        }
    }
    readonly property var firmwares: {
        const fws = []
        for (const fw of update_controller.firmwares) {
            if (fw.config !== self.device.versionInfo.JADE_CONFIG.toLowerCase()) continue
            if (!fw.upgrade) continue
            if (!fw.compatible) continue
            if (fw.has_delta) continue
            fws.push(fw)
        }
        return fws
    }

    property var latestFirmware: {
        for (const firmware of self.firmwares) {
            if (firmware.latest) {
                return firmware
            }
        }
        return null
    }

    onLatestFirmwareChanged: self.pushView()

    function pushView(replace = false) {
        if (!replace && stack_view.depth > 0) return
        if (self.debug) {
            if (replace) {
                stack_view.replace(advanced_update_view, StackView.PushTransition)
            } else {
                stack_view.push(advanced_update_view)
            }
            return
        }
        if (!self.device.connected) return
        if (!self.device.updateRequired) {
            skipFirmwareUpdate()
        } else if (self.latestFirmware) {
            if (replace) {
                stack_view.replace(basic_update_view, { firmware: self.latestFirmware }, StackView.PushTransition)
            } else {
                stack_view.push(basic_update_view, { firmware: self.latestFirmware })
            }
        }
    }

    function skipFirmwareUpdate() {
        switch (self.device.state) {
        case JadeDevice.StateReady:
            stack_view.push(login_view, { context: null, device: self.device })
            break;
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            if (self.login) {
                stack_view.push(unlock_view, { device: self.device })
            } else {
                stack_view.push(intialized_view)
            }
            break
        case JadeDevice.StateUninitialized:
        case JadeDevice.StateUnsaved:
            stack_view.push(unintialized_view)
            break
        }
    }

    function firmwareVersionAndType(version, config) {
        return `${version} (${config.toLowerCase() === 'noradio' ? qsTrId('id_noradio_firmware') : qsTrId('id_radio_firmware') })`
    }

    Component.onCompleted: pushView()

    contentItem: Item {
        BusyIndicator {
            anchors.centerIn: parent
            running: stack_view.depth === 0 && firmware_controller.fetching
            visible: stack_view.depth === 0
        }
        GStackView {
            anchors.fill: parent
            anchors.leftMargin: self.padding
            anchors.rightMargin: self.padding
            id: stack_view
        }
    }

    Component {
        id: basic_update_view
        JadeBasicUpdateView {
            device: self.device
            fetching: firmware_controller.fetching
            onAdvancedClicked: stack_view.push(advanced_update_view)
            onSkipClicked: self.skipFirmwareUpdate()
            onFirmwareSelected: (firmware) => stack_view.push(confirm_update_view, { firmware })
        }
    }

    Component {
        id: advanced_update_view
        JadeAdvancedUpdateView {
            device: self.device
            showSkip: true
            onSkipClicked: self.skipFirmwareUpdate()
            onFirmwareSelected: (firmware) => stack_view.push(confirm_update_view, { firmware })
        }
    }

    Component {
        id: confirm_update_view
        JadeConfirmUpdatePage {
            device: self.device
            onUpdateFailed: stack_view.pop()
            onUpdateFinished: {
                stack_view.replace(null, waiting_page, StackView.PushTransition)
                self.firmwareUpdated()
            }
        }
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            context: null
            showRemember: true
            onUnlockFinished: (context) => stack_view.push(login_view, { context, device: self.device })
            onUnlockFailed: stack_view.replace(null, intialized_view, StackView.PushTransition)
        }
    }

    Component {
        id: intialized_view
        JadeInitializedView {
            device: self.device
            latestFirmware: self.latestFirmware
            onLoginClicked: self.skipFirmwareUpdate()
            onUpdateClicked: stack_view.push(basic_update_view, { firmware: self.latestFirmware })
        }
    }

    Component {
        id: login_view
        JadeLoginView {
            onLoginFinished: (context) => self.loginFinished(context)
            onLoginFailed: self.loginFinished(context)
        }
    }

    Component {
        id: unintialized_view
        JadeUninitializedView {
            device: self.device
            latestFirmware: self.latestFirmware
            onUpdateClicked: stack_view.push(basic_update_view, { firmware: self.latestFirmware })
            onSetupFinished: (context) => stack_view.replace(null, login_view, { context, device: self.device }, StackView.PushTransition)
        }
    }

    Component {
        id: waiting_page
        ColumnLayout {
            readonly property bool ready: !stack_view.busy && self.device.connected
            id: view
            onReadyChanged: {
                if (view.ready) {
                    self.pushView(true)
                }
            }
            VSpacer {
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                font.pixelSize: 22
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_connecting_to_your_device')
                wrapMode: Label.WordWrap
            }
            VSpacer {
            }
        }
    }
}
