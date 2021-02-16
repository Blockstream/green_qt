import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    id: self
    readonly property bool busy: {
        for (let i = 0; i < devices_list_view.count; ++i) {
            if (devices_list_view.itemAtIndex(i).busy) return true
        }
        return false
    }
    property alias count: devices_list_view.count
    DeviceDiscoveryAgent {
    }
    DeviceListModel {
        id: device_list_model
        vendor: Device.Ledger
    }
    header: MainPageHeader {
        padding: 16
        background: Item { }
        contentItem: RowLayout {
            spacing: 16
            Image {
                source: 'qrc:/svg/ledger-logo.svg'
                sourceSize.height: 32
            }
            Label {
                text: 'Ledger Devices'
                font.pixelSize: 24
                font.family: 'Roboto'
                font.styleName: 'Thin'
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Button {
                text: 'Store'
                highlighted: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product-category/physical_storage/')
            }
        }
    }
    contentItem: StackLayout {
        currentIndex: self.count === 0 ? 0 : 1
        ColumnLayout {
            spacing: 16
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Flipable {
                id: flipable
                property bool flipped: false
                width: Math.max(nano_s_image.width, nano_x_image.width)
                height: Math.max(nano_s_image.height, nano_x_image.height)
                Layout.alignment: Qt.AlignHCenter
                front: Image {
                    id: nano_x_image
                    anchors.centerIn: parent
                    source: 'qrc:/svg/ledger_nano_x.svg'
                }
                back: Image {
                    id: nano_s_image
                    anchors.centerIn: parent
                    source: 'qrc:/svg/ledger_nano_s.svg'
                }
                transform: Rotation {
                    id: rotation
                    origin.x: flipable.width / 2
                    origin.y: flipable.height / 2
                    axis.x: 1
                    axis.y: 0
                    axis.z: 0
                    angle: flipable.flipped ? 180 : 0
                    Behavior on angle {
                        SmoothedAnimation { }
                    }
                }
                Timer {
                    repeat: true
                    running: true
                    interval: 3000
                    onTriggered: flipable.flipped = !flipable.flipped
                }
            }
            Pane {
                Layout.topMargin: 40
                Layout.alignment: Qt.AlignHCenter
                background: Rectangle {
                    radius: 8
                    border.width: 2
                    border.color: constants.c600
                    color: "transparent"
                }
                contentItem: RowLayout {
                    spacing: 16
                    Image {
                        Layout.alignment: Qt.AlignVCenter
                        sourceSize.width: 32
                        sourceSize.height: 32
                        fillMode: Image.PreserveAspectFit
                        source: 'qrc:/svg/usbAlt.svg'
                        clip: true
                    }
                    Label {
                        Layout.alignment: Qt.AlignVCenter
                        text: `Connect your Ledger Nano ${flipable.flipped ? 'S' : 'X'} to use it with Green`
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
        ColumnLayout {
            spacing: 16
            ListView {
                id: devices_list_view
                ScrollIndicator.horizontal: ScrollIndicator { }
                Layout.alignment: Qt.AlignCenter
                implicitWidth: Math.min(contentWidth, parent.width)
                height: 200
                model: device_list_model
                spacing: 16
                orientation: ListView.Horizontal
                currentIndex: {
                    for (let i = 0; i < devices_list_view.count; ++i) {
                        if (devices_list_view.itemAtIndex(i).location === window.location) {
                            return i
                        }
                    }
                    return -1
                }
                delegate: Pane {
                    required property LedgerDevice device
                    readonly property string location: '/ledger/' + device.uuid
                    padding: 16
                    background: Rectangle {
                        radius: 8
                        color: constants.c700
                    }
                    contentItem: ColumnLayout {
                        spacing: 16
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            smooth: true
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                            sourceSize.height: 32
                            source: switch(device.type) {
                                case Device.LedgerNanoS: return 'qrc:/svg/ledger_nano_s.svg'
                                case Device.LedgerNanoX: return 'qrc:/svg/ledger_nano_x.svg'
                            }
                        }
                        GridLayout {
                            columnSpacing: 16
                            rowSpacing: 8
                            columns: 2
                            Label {
                                text: 'Model'
                            }
                            Label {
                                text: switch(device.type) {
                                    case Device.LedgerNanoS: return 'Nano S'
                                    case Device.LedgerNanoX: return 'Nano X'
                                }
                            }
                            Label {
                                text: 'Connection'
                            }
                            Label {
                                text: 'USB'
                            }
                        }
                    }
                }
            }
            StackLayout {
                currentIndex: devices_list_view.currentIndex
                Repeater {
                    model: device_list_model
                    Pane {
                        background: Item {
                        }
                        contentItem: Item {
                        }
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                width: 1
            }
        }
    }
}
