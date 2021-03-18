import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    required property JadeDevice device
    property bool updated: false
    id: self
    title: 'Over-The-Air Firmware Update'
    closePolicy: Dialog.NoAutoClose
    onClosed: {
        if (updated) controller.disconnectDevice()
        destroy()
    }
    onOpened: controller.check()
    onDeviceChanged: if (!device) self.close()

    width: 550
    height: 450

    JadeUpdateController {
        id: controller
        channel: channel_combo_box.currentValue
        device: self.device
        onActivityCreated: {
            if (activity instanceof SessionTorCircuitActivity) {
                session_tor_cirtcuit_view.createObject(activities_row, { activity })
            } else if (activity instanceof SessionConnectActivity) {
                session_connect_view.createObject(activities_row, { activity })
            } else if (activity instanceof JadeChannelRequestActivity) {
                const view = http_request_view.createObject(activities_row, { activity, text: 'Fetching list' })
                activity.finished.connect(() => {
                    stack_view.push(select_view)
                    view.destroy()
                })
            } else if (activity instanceof JadeBinaryRequestActivity) {
                const view = http_request_view.createObject(activities_row, { activity, text: 'Downloading firmware' })
                activity.finished.connect(() => {
                    stack_view.push(select_view)
                    view.destroy()
                })
            } else if (activity instanceof JadeUnlockActivity) {
                activity.failed.connect(() => { stack_view.pop() })
                activity.finished.connect(() => { stack_view.pop() })
                stack_view.push(jade_unlock_view, { activity })
            } else if (activity instanceof JadeUpdateActivity) {
                activity.failed.connect(() => { stack_view.pop() })
                stack_view.push(jade_update_view, { activity })
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
                    text: 'Unlock Jade to Update Firmware'
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
                        text: 'Current:'
                    }
                    Label {
                        text: self.activity.device.version
                    }
                    Label {
                        text: 'New:'
                    }
                    Label {
                        text: self.activity.firmware.version
                    }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    visible: self.activity.status === Activity.Pending
                    text: self.activity.progress.indeterminate ? 'Follow instructions on device' : 'Uploading firmware'
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

    property Item select_view: ColumnLayout {
        ButtonGroup {
            id: button_group
        }
        ComboBox {
            id: channel_combo_box
            visible: Qt.application.arguments.indexOf('--debugjade') > 0
            enabled: controller.session && controller.session.connected
            Layout.fillWidth: true
            flat: true
            valueRole: 'channel'
            textRole: 'text'
            model: ListModel {
                ListElement {
                    text: 'Latest Channel'
                    channel: 'LATEST'
                }
                ListElement {
                    text: 'Beta Channel'
                    channel: 'BETA'
                }
                ListElement {
                    text: 'Previous Channel'
                    channel: 'PREVIOUS'
                }
            }
        }
        Repeater {
            model: controller.firmwares
            delegate: DescriptiveRadioButton {
                property var firmware: modelData
                property string name: {
                    if (firmware.config === 'ble') return 'BLE Firmware ' + firmware.version
                    if (firmware.config === 'noradio') return 'No-Radio Firmware ' + firmware.version
                    return 'Unknown Firmware ' + firmware.config + firmware.version
                }
                text: name + (firmware.installed ? ' (INSTALLED)' : '')
                description: {
                    if (firmware.config === 'ble') return 'Choose this firmware if you want to connect to your Blockstream Jade also wireless via BLE.'
                    if (firmware.config === 'noradio') return 'Choose this firmware if you want to disable all radio connections on your Blockstream Jade. This will make your Blockstream Jade incompatible with iOS devices.'
                    return 'Unknown firmware version'
                }
                checked: false
                enabled: !firmware.installed
                ButtonGroup.group: button_group
                Layout.fillWidth: true
            }
        }
        VSpacer {
        }
    }

    contentItem: StackView {
        id: stack_view
        initialItem: ColumnLayout {
            spacing: 32
            VSpacer {
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: controller.session && controller.session.connected ? 'Loading' : 'Establishing session'
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            VSpacer {
            }
        }
    }
    footer: DialogFooter {
        Pane {
            background: Item {}
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        HSpacer {
        }
        Button {
            Layout.fillWidth: false
            flat: true
            text: qsTrId('id_next')
            enabled: button_group.checkedButton
            visible: stack_view.currentItem === select_view
            onClicked: controller.update(button_group.checkedButton.firmware)
        }
    }
}
