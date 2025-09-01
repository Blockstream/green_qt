import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "jade.js" as JadeJS

AbstractDrawer {
    required property JadeDevice device
    onClosed: self.destroy()
    id: self
    edge: Qt.RightEdge
    contentItem: GStackView {
        initialItem: StackViewPage {
            title: self.device.name
            rightItem: CloseButton {
                onClicked: self.close()
            }
            contentItem: ColumnLayout {
                spacing: 10
                MultiImage {
                    Layout.alignment: Qt.AlignCenter
                    foreground: JadeJS.image(self.device, 0)
                    width: 352
                    height: 240
                }
                GridLayout {
                    rowSpacing: 10
                    columnSpacing: 20
                    columns: 2
                    KeyLabel {
                        text: qsTrId('id_model')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: {
                            const board_type = self.device.versionInfo.BOARD_TYPE
                            return board_type === 'JADE_V2' ? 'Jade Plus' : 'Jade Classic'
                        }
                    }
                    KeyLabel {
                        visible: {
                            const board_type = self.device.versionInfo.BOARD_TYPE
                            return board_type === 'JADE_V2'
                        }
                        text: 'Genuine check'
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        visible: {
                            const board_type = self.device.versionInfo.BOARD_TYPE
                            return board_type === 'JADE_V2'
                        }
                        text: {
                            const efusemac = self.device.versionInfo.EFUSEMAC
                            if (Settings.isEventRegistered({ efusemac, result: 'genuine', type: 'jade_genuine_check' })) {
                                return 'Your Jade is genuine!'
                            }
                            if (Settings.isEventRegistered({ efusemac, result: 'diy', type: 'jade_genuine_check' })) {
                                return 'This Jade is not genuine'
                            }
                            return 'Not checked'
                        }
                    }
                    Separator {
                    }
                    KeyLabel {
                        text: qsTrId('id_firmware')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device.version
                    }
                    KeyLabel {
                        text: qsTrId('Configuration')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: {
                            switch (self.device.versionInfo.JADE_CONFIG.toLowerCase()) {
                            case 'noradio': return 'No-Radio'
                            case 'ble': return 'Bluetooth'
                            }
                        }
                    }
                    KeyLabel {
                        text: 'State'
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device.versionInfo.JADE_STATE
                    }
                    KeyLabel {
                        text: 'Has PIN'
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device.versionInfo.JADE_CONFIG ? 'YES' : 'NO'
                    }
                    Separator {
                    }
                    KeyLabel {
                        text: qsTrId('id_connection')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: 'USB'
                    }
                    KeyLabel {
                        text: qsTrId('id_system_location')
                    }
                    CopyableLabel {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device.systemLocation
                    }
                    KeyLabel {
                        text: qsTrId('Battery')
                    }
                    Pane {
                        Layout.alignment: Qt.AlignRight
                        padding: 3
                        background: Rectangle {
                            border.width: 1
                            border.color: '#FFF'
                            color: 'transparent'
                            radius: 5
                        }
                        contentItem: RowLayout {
                            spacing: 1
                            Repeater {
                                model: 5
                                delegate: Rectangle {
                                    implicitWidth: 8
                                    implicitHeight: 8
                                    radius: 1
                                    color: 'green'
                                    opacity: 0.75
                                }
                            }
                        }
                    }
                    KeyLabel {
                        text: qsTrId('id_status')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: {
                            if (!self.device.connected) return 'Disconnected'
                            switch (self.device.status) {
                            case JadeDevice.StatusIdle: return 'Idle'
                            case JadeDevice.StatusHandleClientMessage: return 'Busy'
                            case JadeDevice.StatusHandleMenuNavigation: return 'Menu'
                            }
                        }
                    }
                    Separator {
                    }
                    KeyLabel {
                        text: qsTrId('XPUB Hash ID')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device?.session?.xpubHashId ?? 'N/A'
                        wrapMode: Label.WrapAnywhere
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: JSON.stringify(self.device.versionInfo, null, '  ')
                    visible: false
                    wrapMode: Label.WrapAnywhere
                }
                VSpacer {
                }
            }
        }
    }
    component Separator: Rectangle {
        Layout.bottomMargin: 10
        Layout.columnSpan: 2
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: 10
        color: '#313131'
    }
    component KeyLabel: Label {
        Layout.minimumWidth: 100
        color: '#929292'
        font.pixelSize: 14
        font.weight: 400
    }
}
