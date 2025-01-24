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
                    Label {
                        Layout.minimumWidth: 100
                        color: '#929292'
                        font.pixelSize: 14
                        font.weight: 400
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
                    Label {
                        Layout.minimumWidth: 100
                        color: '#929292'
                        font.pixelSize: 14
                        font.weight: 400
                        text: qsTrId('id_firmware')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device.version
                    }
                    Label {
                        Layout.minimumWidth: 100
                        color: '#929292'
                        font.pixelSize: 14
                        font.weight: 400
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
                    Label {
                        Layout.minimumWidth: 100
                        color: '#929292'
                        font.pixelSize: 14
                        font.weight: 400
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
                    Label {
                        Layout.minimumWidth: 100
                        color: '#929292'
                        font.pixelSize: 14
                        font.weight: 400
                        text: qsTrId('id_system_location')
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Label.AlignRight
                        text: self.device.systemLocation
                    }
                    Label {
                        Layout.minimumWidth: 100
                        color: '#929292'
                        font.pixelSize: 14
                        font.weight: 400
                        text: qsTrId('id_stauts')
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
}
