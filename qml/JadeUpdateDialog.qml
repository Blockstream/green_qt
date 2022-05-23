import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    required property JadeDevice device
    property bool updated: false
    id: self
    title: qsTrId('id_firmware_update')
    closePolicy: Dialog.NoAutoClose
    onClosed: if (updated) controller.disconnectDevice()
    onOpened: controller.check()
    Component.onCompleted: controller.check()
    onDeviceChanged: if (!device) self.close()

    width: 550
    height: 450

    property JadeUpdateController controller: JadeUpdateController {
        channel: channel_combo_box.currentValue
        device: self.device
        onActivityCreated: {
            if (activity instanceof JadeChannelRequestActivity) {
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
                        text: self.activity.device.version
                    }
                    Label {
                        text: qsTrId('id_new_version') + ':'
                    }
                    Label {
                        text: self.activity.firmware.version
                    }
                    Label {
                        text: 'Hash'
                    }
                    Label {
                        text: self.activity.firmware.hash
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

    property Item select_view: ColumnLayout {
        ButtonGroup {
            id: button_group
        }
        GComboBox {
            id: channel_combo_box
            visible: Settings.enableExperimental
            enabled: HttpManager.session && HttpManager.session.connected
            Layout.fillWidth: true
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
        GListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: controller.firmwares
            delegate: DescriptiveRadioButton {
                leftPadding: 16
                rightPadding: 16
                property var firmware: modelData
                property string name: {
                    if (firmware.config === 'ble') return qsTrId('id_radio_firmware') + ' ' + firmware.version
                    if (firmware.config === 'noradio') return qsTrId('id_noradio_firmware') + ' ' + firmware.version
                    return qsTrId('id_unknown_firmware') + ' ' + firmware.config + firmware.version
                }
                text: name + (firmware.installed ? ' (INSTALLED)' : '')
                description: {
                    if (firmware.config === 'ble') return qsTrId('id_choose_this_version_to_connect')
                    if (firmware.config === 'noradio') return qsTrId('id_choose_this_version_to_disable')
                    return qsTrId('id_unknown_firmware')
                }
                checked: false
                enabled: !firmware.installed
                width: ListView.view.contentWidth
                ButtonGroup.group: button_group
            }
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
                text: HttpManager.session && HttpManager.session.connected ? qsTrId('id_loading') : qsTrId('id_establishing_session')
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            VSpacer {
            }
        }
    }
    footer: DialogFooter {
        GPane {
            background: null
            padding: 0
            contentItem: RowLayout {
                id: activities_row
            }
        }
        HSpacer {
        }
        GButton {
            Layout.fillWidth: false
            large: true
            text: qsTrId('id_next')
            enabled: button_group.checkedButton
            visible: stack_view.currentItem === select_view
            onClicked: controller.update(button_group.checkedButton.firmware)
        }
    }
}
