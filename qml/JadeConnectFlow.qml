import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

// Steps after picking a Jade: genuine check, firmware check, unlock or setup.
Item {
    // The context the unlock opened the device's session on, or the one given.
    signal deviceReady(JadeDevice device, Context context)
    signal closeClicked()
    required property StackViewPage page
    // A logged in wallet taking its device back unlocks on its own context.
    property Context context: null

    function connectBluetooth(device) {
        device.selectConnection(JadeDevice.Bluetooth)
        if (device.connected && device.bluetoothAvailable) {
            flow.genuineCheck(device)
            return
        }
        flow.page.pushPage(jade_bluetooth_pair_page, { device })
    }

    function connectUsb(device) {
        device.selectConnection(JadeDevice.USB)
        flow.genuineCheck(device)
    }

    function genuineCheck(device) {
        if (['JADE_V2', 'JADE_V2C'].includes(device.versionInfo.BOARD_TYPE)) {
            const efusemac = device.versionInfo.EFUSEMAC
            const check_genuine = Settings.isEventRegistered(UtilJS.jadeGenuineCheckEvent(efusemac, 'genuine'))
            const check_diy = Settings.isEventRegistered(UtilJS.jadeGenuineCheckEvent(efusemac, 'diy'))
            const check_skip = Settings.isEventRegistered(UtilJS.jadeGenuineCheckEvent(efusemac, 'skip'))
            // A unit reporting secure boot must pass the check, an earlier skip or DIY choice doesn't count
            const checked = device.secureBoot ? check_genuine : check_genuine || check_diy || check_skip
            if (!checked) {
                flow.page.pushPage(genuine_check_page, { device })
                return
            }
        }

        flow.processStateUnsaved(device)
    }

    function processStateUnsaved(device) {
        if (device.state === JadeDevice.StateUnsaved) {
            flow.processState(device)
            return
        }

        flow.firmwareCheck(device)
    }

    Timer {
        property JadeDevice device: null
        id: timer
        interval: 1000
        repeat: false
        onTriggered: flow.firmwareCheck(timer.device, true)
    }

    // A retry only waits for the request in flight: if the index could not be
    // fetched the flow goes on without it, as there is no update to offer.
    function firmwareCheck(device, waiting = false) {
        if (!device) return
        update_controller.device = device
        if (!waiting && !firmware_controller.fetching) firmware_controller.check(device)

        if (firmware_controller.fetching) {
            timer.device = device
            timer.restart()
            return
        }

        // With a cached index the firmwares are known already, skip the busy page when up to date
        if (!flow.debug && device.connected && 'BOARD_TYPE' in device.versionInfo) {
            const latest = flow.latestFirmware(device)
            if (!latest || device.version === latest.version) {
                flow.processState(device)
                return
            }
        }
        flow.page.pushPage(firmware_check_page, { device })
    }

    function latestFirmware(device) {
        for (const fw of update_controller.firmwares) {
            if (fw.config !== device.versionInfo.JADE_CONFIG?.toLowerCase()) continue
            if (!fw.upgrade) continue
            if (!fw.compatible) continue
            if (fw.has_delta) continue
            if (fw.latest) return fw
        }
        return null
    }

    function processState(device) {
        switch (device.state) {
        // An unlocked Jade goes through the unlock too: it opens the session and
        // identifies the device, which deviceReady consumers rely on.
        case JadeDevice.StateReady:
        case JadeDevice.StateTemporary:
        case JadeDevice.StateLocked:
            flow.page.pushPage(unlock_page, { device })
            return
        case JadeDevice.StateUninitialized:
        case JadeDevice.StateUnsaved:
            flow.page.pushPage(uninitialized_page, { device })
            return
        }
        console.log('nothing to show, jade state is', device.state)
    }

    readonly property bool debug: Qt.application.arguments.includes('--debugjade')
    id: flow
    visible: false

    JadeFirmwareController {
        id: firmware_controller
    }
    JadeFirmwareCheckController {
        id: update_controller
        index: firmware_controller.index
    }
    Instantiator {
        id: jade_devices
        model: DeviceListModel {
            type: Device.BlockstreamJade
        }
        delegate: QtObject {
            required property Device device
        }
    }

    Component {
        id: jade_bluetooth_pair_page
        JadeBluetoothPairPage {
            onDeviceSelected: (device) => flow.genuineCheck(device)
        }
    }

    Component {
        id: genuine_check_page
        JadeGenuineCheckPage {
            onCloseClicked: flow.closeClicked()
            onStart: (device) => flow.page.pushPage(genuine_checking_page, { device })
        }
    }

    Component {
        id: genuine_checking_page
        JadeGenuineCheckingPage {
            onCloseClicked: flow.closeClicked()
            onGenuine: (device) => flow.processStateUnsaved(device)
            onDiy: (device) => flow.processStateUnsaved(device)
        }
    }

    Component {
        id: unlock_page
        JadeUnlockView {
            id: page
            context: flow.context
            showRemember: true
            onCloseClicked: flow.closeClicked()
            onUnlockFinished: (context) => flow.deviceReady(page.device, context)
            onUnlockFailed: page.popPage()
        }
    }

    Component {
        id: uninitialized_page
        StackViewPage {
            required property JadeDevice device
            // Setup finished, wait for the refreshed version info to report the new state
            property bool done: false
            function next() {
                if (!page.done) return
                const state = page.device.state
                if (state === JadeDevice.StateUninitialized || state === JadeDevice.StateUnsaved) return
                page.done = false
                flow.processState(page.device)
            }
            Connections {
                target: page.device
                function onStateChanged() {
                    page.next()
                }
            }
            id: page
            title: page.device.name
            rightItem: RowLayout {
                spacing: 20
                LinkButton {
                    Layout.alignment: Qt.AlignCenter
                    text: qsTrId('id_setup_guide')
                    external: true
                    onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/19629901272345-Set-up-Jade')
                }
                CloseButton {
                    onClicked: flow.closeClicked()
                }
            }
            contentItem: JadeUninitializedView {
                device: page.device
                onSetupFinished: (context) => {
                    page.done = true
                    page.next()
                }
            }
        }
    }

    Component {
        id: firmware_check_page
        StackViewPage {
            required property JadeDevice device
            function check() {
                if (!page.device.connected || !('BOARD_TYPE' in page.device.versionInfo)) return
                if (firmware_controller.fetching) return
                timer.stop()
                const latest = flow.latestFirmware(page.device)
                if (flow.debug) {
                    page.replacePage(advanced_update_view, { device: page.device })
                } else if (latest && page.device.version !== latest.version) {
                    page.replacePage(basic_update_view, { device: page.device, firmware: latest })
                } else {
                    const device = page.device
                    page.StackView.view.pop(StackView.Immediate)
                    flow.processState(device)
                }
            }
            id: page
            title: qsTrId('id_firmware_upgrade')
            Timer {
                id: timer
                interval: 500
                repeat: true
                running: page.StackView.status === StackView.Active
                onTriggered: page.check()
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    Component {
        id: basic_update_view
        JadeBasicUpdateView {
            id: page
            fetching: false
            onCloseClicked: flow.closeClicked()
            onAdvancedClicked: page.replacePage(advanced_update_view, { device: page.device })
            onSkipClicked: flow.processState(page.device)
            onFirmwareSelected: (firmware) => flow.page.pushPage(confirm_update_page, { device: page.device, firmware })
        }
    }

    Component {
        id: advanced_update_view
        JadeAdvancedUpdateView {
            id: page
            showSkip: true
            onCloseClicked: flow.closeClicked()
            onSkipClicked: flow.processState(page.device)
            onFirmwareSelected: (firmware) => flow.page.pushPage(confirm_update_page, { device: page.device, firmware })
        }
    }

    Component {
        id: confirm_update_page
        JadeConfirmUpdatePage {
            // Captured before the update, the device can be gone once Jade reboots.
            property string name
            property int connectionType
            property bool usbRequired: false
            property bool gone: false
            Component.onCompleted: {
                page.name = page.device.name
                // No-radio firmware turns Bluetooth off, so Jade comes back over USB.
                page.usbRequired = page.firmware.config?.toLowerCase() === 'noradio' && page.device.connectionType === JadeDevice.Bluetooth
                page.connectionType = page.usbRequired ? JadeDevice.USB : page.device.connectionType
            }
            Connections {
                target: page.device
                function onConnectedChanged() {
                    if (!page.device.connected) page.gone = true
                }
            }
            id: page
            onUpdateFailed: page.StackView.view.pop()
            onUpdateFinished: page.StackView.view.replace(firmware_rebooting_page, { name: page.name, connectionType: page.connectionType, usbRequired: page.usbRequired, gone: page.gone })
        }
    }

    Component {
        id: firmware_rebooting_page
        JadeFirmwareUpdatedPage {
            required property string name
            required property int connectionType
            required property bool usbRequired
            // Set once Jade dropped the connection to reboot.
            property bool gone: false
            id: page
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 20
                visible: page.usbRequired
                font.pixelSize: 14
                opacity: 0.6
                text: qsTrId('Connect Jade with a USB cable to continue')
            }
            // ponytail: name match + 500ms poll, use DeviceManager signals if it misses fast reboots
            Timer {
                interval: 500
                repeat: true
                running: page.StackView.status === StackView.Active
                onTriggered: {
                    let device = null
                    for (let i = 0; i < jade_devices.count; ++i) {
                        const candidate = jade_devices.objectAt(i)?.device
                        if (candidate?.name === page.name) device = candidate
                    }
                    const available = !!device && device.connected
                        && (page.connectionType === JadeDevice.USB ? device.usbAvailable : device.bluetoothAvailable)
                    if (!page.gone) {
                        page.gone = !available
                        return
                    }
                    if (!available) return
                    device.selectConnection(page.connectionType)
                    page.StackView.view.pop(flow.page, StackView.Immediate)
                    flow.firmwareCheck(device)
                }
            }
        }
    }
}
