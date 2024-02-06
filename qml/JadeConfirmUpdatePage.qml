import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

Page {
    signal updateFailed()
    signal updateFinished()
    required property JadeDevice device
    required property var firmware
    function firmwareVersionAndType(version, config) {
        return `${version} (${config.toLowerCase() === 'noradio' ? qsTrId('id_noradio_firmware') : qsTrId('id_radio_firmware') })`
    }
    JadeFirmwareUpdateController {
        id: controller
        device: self.device
        firmware: self.firmware
        onDeviceDisconnected: self.updateFailed()
        onUnlockRequired: stack_view.replace(null, unlock_view, StackView.PushTransition)
        onUpdateStarted: {
            stack_view.replace(null, updating_view, StackView.PushTransition)
            Analytics.recordEvent('ota_start', AnalyticsJS.segmentationFirmwareUpdate(self.device, controller.firmware))
        }
        onUpdateFinished: {
            self.updateFinished()
            Analytics.recordEvent('ota_complete', AnalyticsJS.segmentationFirmwareUpdate(self.device, controller.firmware))
        }
        onUpdateFailed: self.updateFailed()
    }
    id: self
    background: null
    padding: 60
    contentItem: GStackView {
        id: stack_view
        initialItem: preparing_view
    }

    Component {
        id: preparing_view
        ColumnLayout {
            StackView.onActivated: controller.update()
            VSpacer {
            }
            BusyIndicator {
                Layout.alignment: Qt.AlignCenter
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_updating_firmware')
                font.pixelSize: 26
                font.weight: 600
            }
            VSpacer {
            }
        }
    }

    Component {
        id: updating_view
        ColumnLayout {
            spacing: 20
            VSpacer {
            }
            GridLayout {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignCenter
                columns: 2
                columnSpacing: 32
                rowSpacing: 12
                // visible: self.activity.status === Activity.Pending
                Label {
                    text: qsTrId('id_current_version') + ':'
                }
                Label {
                    text: firmwareVersionAndType(self.device.version, self.device.versionInfo["JADE_CONFIG"])
                }
                Label {
                    text: qsTrId('id_new_version') + ':'
                }
                Label {
                    text: firmwareVersionAndType(self.firmware.version, self.firmware.config)
                }
                Label {
                    text: qsTrId('id_hash')
                }
                Label {
                    text: {
                        const ge_0_1_46 = self.device.versionGreaterOrEqualThan('0.1.46')
                        const fwhash = self.firmware?.fwhash
                        const cmphash = self.firmware?.cmphash
                        const hash = String(ge_0_1_46 && fwhash ? fwhash : cmphash)
                        return ge_0_1_46 ? hash.match(/.{1,8}/g).join(' ') : hash
                    }
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.maximumWidth: 200
                    wrapMode: Label.Wrap
                }
            }
            ProgressBar {
                Layout.alignment: Qt.AlignCenter
                indeterminate: controller.progress < 0.05
                from: 0
                to: 1
                value: controller.progress
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 16
                font.weight: 600
                text: controller.progress < 0.05 ? qsTrId('id_please_follow_the_instructions') : qsTrId('id_uploading_firmware')
            }
            VSpacer {
            }
        }
    }

    Component {
        id: unlock_view
        JadeUnlockView {
            context: null
            device: self.device
            showRemember: false
            onUnlockFinished: stack_view.replace(null, preparing_view, StackView.PushTransition)
            onUnlockFailed: self.updateFailed()
        }
    }
}
