import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS

AbstractDialog {
    required property JadeDevice device
    readonly property bool debug_jade: Qt.application.arguments.indexOf('--debugjade') > 0
    property bool updated: false

    function quickUpdate() {
        stack_view.replace(jade_update_available_view, StackView.Immediate)
        self.open()
    }

    function advancedUpdate() {
        stack_view.replace(jade_firmware_list, StackView.Immediate)
        self.open()
    }

    function firmwareVersionAndType(version, config) {
        return `${version} (${config.toLowerCase() === 'noradio' ? qsTrId('id_noradio_firmware') : qsTrId('id_radio_firmware') })`
    }

    property JadeUpdateController controller: JadeUpdateController {
        index: firmware_controller.index
        device: self.device
        onActivityCreated: (activity) => {
            if (activity instanceof JadeUnlockActivity) {
                activity.failed.connect(() => { stack_view.pop() })
                activity.finished.connect(() => { stack_view.pop() })
                stack_view.push(jade_unlock_view, { activity })
            } else if (activity instanceof JadeUpdateActivity) {
                activity.failed.connect(() => { stack_view.pop() })
                stack_view.push(jade_update_view, { activity })
            }
        }
        onFirmwareAvailableChanged: {
            // we don't want to prompt firmware update
            // in when Jade setup is in progress
            if (self.device.state === JadeDevice.StateUnsaved) return

            if (firmwareAvailable) {
                self.quickUpdate()
            }
        }
        onUpdateStarted: {
            Analytics.recordEvent('ota_start', AnalyticsJS.segmentationFirmwareUpdate(Settings, self.device, controller.firmwareSelected))
        }
        onUpdateCompleted: {
            Analytics.recordEvent('ota_complete', AnalyticsJS.segmentationFirmwareUpdate(Settings, self.device, controller.firmwareSelected))
        }
    }

    readonly property int count: {
        if (self.debug_jade) return controller.firmwares.length
        let result = 0
        for (const fw of controller.firmwares) {
            if (!fw.upgrade) continue
            if (fw.has_delta) continue
            result ++
        }
        return result
    }

    id: self
    title: qsTrId('id_firmware_update')
    closePolicy: Dialog.NoAutoClose
    onClosed: if (updated) controller.disconnectDevice()
    onDeviceChanged: if (!device) self.close()
    width: 650
    height: 450
    contentItem: StackView {
        id: stack_view
        clip: true
        initialItem: null
    }

    Component {
        id: jade_update_available_view

        Page {
            background: null
            ColumnLayout {
                spacing: constants.s1
                VSpacer {
                }
                Label {
                    text: !!self.controller.firmwareAvailable ? `Firmware version ${self.controller.firmwareAvailable.version} is available for your Blockstream Jade.` : ''
                }
                VSpacer {
                }
            }
            footer: DialogFooter {
                HSpacer {
                }
                GButton {
                    large: true
                    text: qsTrId('id_cancel')
                    onClicked: self.reject()
                }
                GButton {
                    large: true
                    highlighted: true
                    text: qsTrId('id_next')
                    enabled: !controller.updating
                    onClicked: controller.update(self.controller.firmwareAvailable)
                }
            }
        }
    }

    Component {
        id: jade_unlock_view
        Loader {
            property JadeUnlockActivity activity
            id: self
            active: self.activity
            sourceComponent: ColumnLayout {
                spacing: 32
                VSpacer {
                }
                Label {
                    text: qsTrId('id_unlock_jade_to_continue')
                    Layout.alignment: Qt.AlignCenter
                }
                DeviceImage {
                    Layout.maximumHeight: 64
                    Layout.alignment: Qt.AlignCenter
                    device: self.activity.device
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: jade_update_view
        Loader {
            property JadeUpdateActivity activity
            id: self
            active: self.activity
            Connections {
                target: activity
                function onStatusChanged(status) {
                    if (status === Activity.Finished) updated = true
                }
            }
            sourceComponent: ColumnLayout {
                spacing: 32
                VSpacer {
                }
                Image {
                    Layout.alignment: Qt.AlignCenter
                    visible: self.activity.status === Activity.Finished
                    source: 'qrc:/svg/check.svg'
                    sourceSize.width: 64
                    sourceSize.height: 64
                }
                GridLayout {
                    Layout.fillWidth: false
                    Layout.fillHeight: false
                    Layout.alignment: Qt.AlignCenter
                    columns: 2
                    columnSpacing: 32
                    rowSpacing: 12
                    visible: self.activity.status === Activity.Pending
                    Label {
                        text: qsTrId('id_current_version') + ':'
                    }
                    Label {
                        text: firmwareVersionAndType(self.activity.device.version, self.activity.device.versionInfo["JADE_CONFIG"])
                    }
                    Label {
                        text: qsTrId('id_new_version') + ':'
                    }
                    Label {
                        text: firmwareVersionAndType(self.activity.firmware.version, self.activity.firmware.config)
                    }
                    Label {
                        text: qsTrId('id_hash')
                    }
                    Label {
                        text: {
                            const ge_0_1_46 = self.activity.device.versionGreaterOrEqualThan('0.1.46')
                            const fwhash = self.activity.firmware?.fwhash
                            const cmphash = self.activity.firmware?.cmphash
                            const hash = String(ge_0_1_46 && fwhash ? fwhash : cmphash)
                            return ge_0_1_46 ? hash.match(/.{1,8}/g).join(' ') : hash
                        }
                        Layout.maximumWidth: 200
                        wrapMode: Label.WrapAnywhere
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    visible: self.activity.status === Activity.Finished
                    text: qsTrId('id_firmware_update_completed')
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    visible: self.activity.status === Activity.Pending
                    text: self.activity.progress.indeterminate ? qsTrId('id_please_follow_the_instructions') : qsTrId('id_uploading_firmware')
                }
                ProgressBar {
                    Layout.alignment: Qt.AlignCenter
                    visible: self.activity.status === Activity.Pending
                    from: self.activity.progress.from
                    to: self.activity.progress.to
                    value: self.activity.progress.value
                    indeterminate: self.activity.progress.indeterminate
                    Behavior on value {
                        SmoothedAnimation { }
                    }
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: http_request_view
        RowLayout {
            required property JadeHttpRequestActivity activity
            required property string text
            id: self
            BusyIndicator {
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: self.text
            }
        }
    }

    Component {
        id: jade_firmware_list
        Page {
            padding: 0
            background: null
            GListView {
                ButtonGroup {
                    id: button_group
                }
                anchors.fill: parent
                clip: true
                model: {
                    const fws = []
                    for (const fw of controller.firmwares) {
                        if (!show_all_checkbox.checked) {
                            if (!fw.upgrade) continue
                            if (fw.has_delta) continue
                        }
                        fws.push(fw)
                    }
                    return fws
                }

                delegate: DescriptiveRadioButton {
                    leftPadding: 16
                    rightPadding: 16
                    tags: {
                        const tags = []
                        if (firmware.channel === 'beta') tags.push({ color: '#dba5ff', text: 'BETA' })
                        if (firmware.installed) tags.push({ color: constants.g300, text: qsTrId('id_current_version') })
                        if (self.debug_jade) tags.push({ color: '#ff6a00', text: firmware.delta ? 'DELTA' : 'FULL' })
                        return tags
                    }
                    property var firmware: modelData
                    property string name: {
                        if (firmware.config === 'ble') return qsTrId('id_radio_firmware') + ' ' + firmware.version
                        if (firmware.config === 'noradio') return qsTrId('id_noradio_firmware') + ' ' + firmware.version
                        return qsTrId('id_unknown_firmware') + ' ' + firmware.config + firmware.version
                    }
                    text: name
                    description: {
                        if (firmware.config === 'ble') return qsTrId('id_choose_this_version_to_connect')
                        if (firmware.config === 'noradio') return qsTrId('id_choose_this_version_to_disable')
                        return qsTrId('id_unknown_firmware')
                    }
                    checked: false
                    enabled: !firmware.installed
                    width: ListView.view.width
                    ButtonGroup.group: button_group
                }
            }
            footer: DialogFooter {
                CheckBox {
                    id: show_all_checkbox
                    visible: self.debug_jade
                    text: qsTrId('id_show_all')
                }
                HSpacer {
                }
                Label {
                    text: qsTrId('id_fetching_new_firmware')
                    visible: controller.fetching
                }
                BusyIndicator {
                    Layout.preferredHeight: 32
                    running: controller.fetching
                    visible: running
                }
                GButton {
                    large: true
                    text: qsTrId('id_next')
                    enabled: button_group.checkedButton && !controller.updating
                    onClicked: controller.update(button_group.checkedButton.firmware)
                }
            }
        }
    }
}
