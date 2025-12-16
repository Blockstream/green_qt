import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal skipClicked()
    signal genuineCheckClicked()
    signal firmwareSelected(var firmware)
    required property JadeDevice device
    required property bool showSkip
    readonly property bool debug: Qt.application.arguments.indexOf('--debugjade') > 0
    id: self
    padding: 0
    background: Item {
        BusyIndicator {
            anchors.centerIn: parent
            running: firmware_controller.fetching
        }
    }
    StackView.onActivated: firmware_controller.check(self.device)
    JadeFirmwareController {
        id: firmware_controller
    }
    JadeFirmwareCheckController {
        id: update_controller
        index: firmware_controller.index
        device: self.device
    }
    header: null
    footerItem: ColumnLayout {
        Image {
            Layout.alignment: Qt.AlignCenter
            source: 'qrc:/svg2/warning.svg'
            visible: self.device.updateRequired
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 12
            font.weight: 600
            text: qsTrId('id_new_jade_firmware_required')
            visible: self.device.updateRequired
        }
        RowLayout {
            Layout.topMargin: 20
            CheckBox {
                Layout.alignment: Qt.AlignCenter
                id: left_item
                text: qsTrId('id_show_all')
                visible: self.debug
            }
            Item {
                Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(right_item) - UtilJS.effectiveWidth(left_item), 0)
            }
            HSpacer {
            }
            PrimaryButton {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 250
                enabled: button_group.checkedButton && self.device?.connected && self.device?.status === JadeDevice.StatusIdle
                text: qsTrId('id_continue')
                onClicked: self.firmwareSelected(button_group.checkedButton.firmware)
            }
            HSpacer {
            }
            Item {
                Layout.preferredWidth: Math.max(UtilJS.effectiveWidth(left_item) - UtilJS.effectiveWidth(right_item), 0)
            }
            LinkButton {
                Layout.alignment: Qt.AlignCenter
                id: right_item
                text: qsTrId('id_skip')
                visible: self.showSkip && !self.device.updateRequired
                onClicked: self.skipClicked()
            }
        }
    }
    contentItem: ColumnLayout {
        opacity: firmware_controller.fetching ? 0 : 1
        Behavior on opacity {
            SmoothedAnimation {
                velocity: 3
            }
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            font.pixelSize: 26
            font.weight: 600
            text: qsTrId('id_firmware_update')
            wrapMode: Label.WordWrap
        }
        JadeFirmwareConfigSelector {
            Layout.topMargin: 20
            id: config_selector
            config: self.device.versionInfo.JADE_CONFIG.toLowerCase()
            onConfigClicked: (config) => config_selector.config = config
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.minimumHeight: 80
            Layout.maximumWidth: 300
            Layout.preferredWidth: 0
            font.pixelSize: 12
            font.weight: 500
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            text: {
                if (config_selector.config === 'ble') {
                    return qsTrId('id_choose_this_version_to_connect')
                }
                if (config_selector.config === 'noradio') {
                    return qsTrId('id_choose_this_version_to_disable')
                }
                return qsTrId('id_unknown_firmware')
            }
            wrapMode: Label.WordWrap
        }
        ButtonGroup {
            id: button_group
        }
        ListView {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            Layout.minimumWidth: 325
            Layout.minimumHeight: 300
            ScrollIndicator.vertical: ScrollIndicator {}
            clip: true
            spacing: 0
            model: {
                const fws = []
                for (const fw of update_controller.firmwares) {
                    if (fw.config !== config_selector.config) continue
                    if (fw.has_delta) continue
                    if (!fw.installed && !left_item.checked) {
                        if (!fw.compatible) continue
                        if (!fw.upgrade) continue
                    }
                    fws.push(fw)
                }
                return fws.sort((a, b) => a.index < b.index ? 1 : a.index > b.index ? -1 : 0)
            }
            delegate: FirmwareButton {
                focus: index === 0
                firmware: modelData
                topInset: 5
                leftInset: 5
                rightInset: 5
                bottomInset: 5
                width: ListView.view.width
                ButtonGroup.group: button_group
            }
        }
    }

    component OptionButton: AbstractButton {
        property var tags: []
        Layout.alignment: Qt.AlignCenter
        Layout.minimumWidth: 325
        id: control
        checkable: true
        padding: 20
        background: Rectangle {
            color: Qt.lighter('#262626', control.down ? 1.5 : control.enabled && control.hovered ? 1.2 : 1)
            radius: 5
            border.width: control.checked ? 2 : 0
            border.color: '#00BCFF'
            Rectangle {
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                visible: control.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: constants.s1
            Label {
                Layout.fillWidth: true
                text: control.text
                font.pixelSize: 14
                font.weight: 600
            }
            Repeater {
                model: control.tags
                delegate: Label {
                    padding: 4
                    leftPadding: 8
                    rightPadding: 8
                    background: Rectangle {
                        border.color: modelData.color
                        border.width: 1
                        color: 'transparent'
                        radius: height / 2
                    }
                    text: modelData.text
                    font.pixelSize: 10
                    font.weight: 400
                    font.capitalization: Font.AllUppercase
                    color: modelData.color
                }
            }
        }
    }

    component FirmwareButton: OptionButton {
        property var firmware
        tags: {
            const tags = []
            if (firmware.latest) tags.push({ color: '#FFFFFF', text: 'LATEST' })
            if (firmware.channel === 'beta') tags.push({ color: '#dba5ff', text: 'BETA' })
            if (firmware.installed) tags.push({ color: '#00BCFF', text: qsTrId('id_current_version') })
            return tags
        }
        id: control
        text: control.firmware.version
        enabled: !control.firmware.installed
        checked: false
    }}
