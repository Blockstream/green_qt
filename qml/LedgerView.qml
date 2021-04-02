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
        contentItem: RowLayout {
            spacing: 16
            Label {
                text: qsTrId('id_ledger_devices')
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            HSpacer {
            }
            GButton {
                text: qsTrId('id_blockstream_store')
                highlighted: true
                large: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product-category/physical_storage/')
                font.capitalization: Font.MixedCase
                leftPadding: 18
                rightPadding: 18
            }
        }
    }
    contentItem: StackLayout {
        currentIndex: self.count === 0 ? 0 : 1
        ColumnLayout {
            spacing: 16
            Spacer {
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
                        text: qsTrId('id_connect_your_ledger_to_use_it')
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
                    if (devices_list_view.count === 0) return -1
                    for (let i = 0; i < devices_list_view.count; ++i) {
                        if (devices_list_view.itemAtIndex(i).location === window.location) {
                            return i
                        }
                    }
                    return 0
                }
                delegate: ItemDelegate {
                    required property LedgerDevice device
                    readonly property string location: '/ledger/' + device.uuid
                    required property int index
                    padding: 32
                    leftPadding: 32
                    rightPadding: 32
                    topPadding: 32
                    bottomPadding: 32
                    background: Rectangle {
                        radius: 8
                        color: ((window.location === '/ledger' && index === 0) || window.location === location) ? constants.c500 : hovered ? constants.c600 : constants.c700
                    }
                    onClicked: pushLocation(location)
                    contentItem: ColumnLayout {
                        spacing: 32
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            smooth: true
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                            sourceSize.height: 48
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
                                text: qsTrId('id_model')
                            }
                            Label {
                                text: switch(device.type) {
                                    case Device.LedgerNanoS: return 'Nano S'
                                    case Device.LedgerNanoX: return 'Nano X'
                                }
                            }
                            Label {
                                text: qsTrId('id_connection')
                            }
                            Label {
                                text: 'USB'
                            }
                        }
                    }
                }
            }
            StackLayout {
                Layout.fillHeight: false
                currentIndex: devices_list_view.currentIndex
                Repeater {
                    model: device_list_model
                    View {
                    }
                }
            }
            VSpacer {}
        }
    }

    component View: Pane {
        id: self
        required property LedgerDevice device
        LedgerDeviceController {
            id: controller
            device: self.device
            onActivityCreated: {
                if (activity instanceof SessionTorCircuitActivity) {
                    session_tor_cirtcuit_view.createObject(activities_row, { activity })
                } else if (activity instanceof SessionConnectActivity) {
                    session_connect_view.createObject(activities_row, { activity })
                }
            }
        }
        background: Rectangle {
            color: constants.c600
            radius: 8
        }
        contentItem: ColumnLayout {
            Label {
                visible: !controller.network
                text: qsTrId('id_select_an_app_on_s').arg(controller.device.name)
                horizontalAlignment: Label.AlignHCenter
                Layout.fillWidth: true
            }
            Label {
                visible: controller.status === 'locked'
                text: 'Unlock and select app'
            }
            Pane {
                background: null
                padding: 0
                contentItem: RowLayout {
                    id: activities_row
                }
            }
            RowLayout {
                GButton {
                    visible: controller.network && !controller.wallet
                    icon.color: 'transparent'
                    icon.source: controller.network ? icons[controller.network.id] : ''
                    text: qsTrId('id_login')
                    onClicked: controller.login()
                }
                GButton {
                    visible: controller.status === 'done'
                    text: qsTrId('id_go_to_wallet')
                    onClicked: pushLocation(`/${controller.network.id}/${controller.wallet.id}`)
                }
                HSpacer {
                }
            }
            ProgressBar {
                indeterminate: controller.indeterminate
                value: controller.progress
                visible: controller.status === 'login'
                Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }
}
