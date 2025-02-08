import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal loginFinished(Context context)
    signal firmwareUpdated()
    signal skip(Device device)
    signal closeClicked()
    signal detailsClicked()
    required property JadeDevice device
    required property bool login
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0
    readonly property bool ready: (self.device?.connected && 'BOARD_TYPE' in self.device?.versionInfo)
    StackView.onActivated: firmware_controller.check(self.device);
    JadeFirmwareController {
        id: firmware_controller
    }
    JadeFirmwareCheckController {
        id: update_controller
        index: firmware_controller.index
        device: self.device
    }
    id: self
    footer: null
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
        CircleButton {
            icon.source: 'qrc:/svg2/info.svg'
            visible: Qt.application.arguments.indexOf('--debugjade') > 0
            onClicked: self.detailsClicked()
        }
        WalletOptionsButton {
            wallet: null
            onCloseClicked: self.closeClicked()
        }
    }
    readonly property var firmwares: {
        if (!self.ready) return []
        if (firmware_controller.fetching) return []
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

    readonly property var latestFirmware: {
        if (!self.ready) return null
        if (firmware_controller.fetching) return null
        for (const firmware of self.firmwares) {
            if (firmware.latest) {
                return firmware
            }
        }
        return null
    }

    readonly property bool runningLatest: {
        if (!self.ready) return false
        if (firmware_controller.fetching) return false
        if (self.latestFirmware) {
            return self.device && self.device.version === self.latestFirmware.version
        }
        if (self.firmwares.length === 0) {
            return true
        }
        return false
    }

    property bool skipGenuineCheck: false

    function pushView() {
        if (stack_view.depth > 0) return
        if (!self.ready) return
        if (self.genuineCheckDialog) return
        if (firmware_controller.fetching) return
        console.log('can push view: stack view empty, device ready, no genuine check dialog, not fetching fws')
        if (self.device.versionInfo.BOARD_TYPE === 'JADE_V2') {
            if (!self.skipGenuineCheck) {
                const efusemac = self.device.versionInfo.EFUSEMAC
                const check_genuine = Settings.isEventRegistered({ efusemac, result: 'genuine', type: 'jade_genuine_check' })
                const check_diy = Settings.isEventRegistered({ efusemac, result: 'diy', type: 'jade_genuine_check' })
                const check_skip = Settings.isEventRegistered({ efusemac, result: 'skip', type: 'jade_genuine_check' })
                if (!check_genuine && !check_diy && !check_skip) {
                    self.openGenuineCheckDialog()
                    return
                }
            }
        }
        if (self.debug) {
            console.log('push advanced update view')
            stack_view.replace(null, advanced_update_view, StackView.PushTransition)
            return
        }
        if (self.runningLatest) {
            console.log('skip firmware update')
            skipFirmwareUpdate()
        } else if (self.latestFirmware) {
            console.log('skip firmware update')
            stack_view.replace(null, basic_update_view, { firmware: self.latestFirmware }, StackView.PushTransition)
        }
    }

    function skipFirmwareUpdate() {
        switch (self.device.state) {
        case JadeDevice.StateReady:
            stack_view.replace(null, login_view, { context: null, device: self.device }, StackView.PushTransition)
            break;
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            if (self.login) {
                stack_view.replace(null, unlock_view, { device: self.device }, StackView.PushTransition)
            } else {
                stack_view.replace(null, intialized_view, StackView.PushTransition)
            }
            break
        case JadeDevice.StateUninitialized:
        case JadeDevice.StateUnsaved:
            stack_view.replace(null, unintialized_view, StackView.PushTransition)
            break
        }
        console.log('nothing to show, jade state is', self.device.state)
    }

    function firmwareVersionAndType(version, config) {
        return `${version} (${config.toLowerCase() === 'noradio' ? qsTrId('id_noradio_firmware') : qsTrId('id_radio_firmware') })`
    }

    function registerEvent(result) {
        if (Settings.rememberDevices) {
            const efusemac = self.device.versionInfo.EFUSEMAC
            Settings.registerEvent({ efusemac, result, type: 'jade_genuine_check' })
        }
        self.skipGenuineCheck = true
    }


    property JadeGenuineCheckDialog genuineCheckDialog

    function openGenuineCheckDialog() {
        if (self.genuineCheckDialog) return
        self.genuineCheckDialog = genuine_check_dialog.createObject(self, { device: self.device })
        self.genuineCheckDialog.open()
    }

    Timer {
        interval: 500
        repeat: true
        running: true
        onTriggered: self.pushView()
    }

    contentItem: Item {
        BusyIndicator {
            anchors.centerIn: parent
            running: stack_view.depth === 0
            visible: stack_view.depth === 0
        }
        GStackView {
            anchors.fill: parent
            anchors.leftMargin: self.padding
            anchors.rightMargin: self.padding
            anchors.bottomMargin: self.padding
            id: stack_view
        }
    }

    Component {
        id: basic_update_view
        JadeBasicUpdateView {
            device: self.device
            fetching: firmware_controller.fetching
            onAdvancedClicked: stack_view.replace(null, advanced_update_view, StackView.PushTransition)
            onSkipClicked: self.skipFirmwareUpdate()
            onFirmwareSelected: (firmware) => stack_view.replace(null, confirm_update_view, { firmware }, StackView.PushTransition)
        }
    }

    Component {
        id: advanced_update_view
        JadeAdvancedUpdateView {
            device: self.device
            showSkip: true
            onSkipClicked: self.skipFirmwareUpdate()
            onGenuineCheckClicked: self.openGenuineCheckDialog()
            onFirmwareSelected: (firmware) => stack_view.replace(null, confirm_update_view, { firmware }, StackView.PushTransition)
        }
    }

    Component {
        id: genuine_check_dialog
        JadeGenuineCheckDialog {
            id: dialog
            autoCheck: false
            onGenuine: {
                self.registerEvent('genuine')
                dialog.close()
            }
            onDiy: {
                self.registerEvent('diy')
                dialog.close()
            }
            onSkip: {
                self.registerEvent('skip')
                dialog.close()
            }
            onAbort: {
                self.closeClicked()
            }
            onClosed: {
                self.genuineCheckDialog = null
            }
        }
    }

    Component {
        id: confirm_update_view
        JadeConfirmUpdatePage {
            device: self.device
            onUpdateFailed: stack_view.pop()
            onUpdateFinished: {
                stack_view.replace(null, firmware_updated_page, StackView.PushTransition)
                self.firmwareUpdated()
            }
        }
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            context: null
            showRemember: true
            onUnlockFinished: (context) => stack_view.replace(null, login_view, { context, device: self.device }, StackView.PushTransition)
            onUnlockFailed: stack_view.replace(null, intialized_view, StackView.PushTransition)
        }
    }

    Component {
        id: intialized_view
        JadeInitializedView {
            device: self.device
            latestFirmware: self.latestFirmware
            onLoginClicked: self.skipFirmwareUpdate()
            onUpdateClicked: stack_view.replace(null, basic_update_view, { firmware: self.latestFirmware }, StackView.PushTransition)
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
            onUpdateClicked: stack_view.replace(null, basic_update_view, { firmware: self.latestFirmware }, StackView.PushTransition)
            onSetupFinished: (context) => stack_view.replace(null, login_view, { context, device: self.device }, StackView.PushTransition)
        }
    }

    Component {
        id: firmware_updated_page
        JadeFirmwareUpdatedPage {
            onTimeout: stack_view.clear()
        }
    }
}
