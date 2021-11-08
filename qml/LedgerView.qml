import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    id: self
    readonly property bool busy: {
        for (let i = 0; i < devices_list_view.count; ++i) {
            if (devices_list_view.itemAt(i).busy) return true
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
            spacing: constants.s1
            VSpacer {
                Layout.fillWidth: true
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg/ledger_nano_x.svg'
                sourceSize.height: 32
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_connect_your_ledger_to_use_it')
            }
            VSpacer {
            }
        }
        GFlickable {
            id: devices_flickable
            clip: true
            contentHeight: devices_column_layout.height
            ColumnLayout {
                spacing: constants.s1
                id: devices_column_layout
                width: devices_flickable.availableWidth
                Repeater {
                    id: devices_list_view
                    model: device_list_model
                    delegate: DeviceDelegate {
                        Layout.fillWidth: true
                    }
                }
            }
        }
/*
            spacing: 16
            GListView {
                id: devices_list_view
                ScrollIndicator.horizontal: ScrollIndicator { }
                Layout.alignment: Qt.AlignCenter
                implicitWidth: Math.min(contentWidth, parent.width)
                height: 200

                spacing: 16
                orientation: ListView.Horizontal
                currentIndex: {
                    if (devices_list_view.count === 0) return -1
                    for (let i = 0; i < devices_list_view.count; ++i) {
                        if (devices_list_view.itemAtIndex(i).location === navigation.location) {
                            return i
                        }
                    }
                    return 0
                }
                delegate: DeviceDelegate {
                }
            }
        }
*/
    }
    component DeviceDelegate: ItemDelegate {
        id: self
        required property LedgerDevice device
        readonly property string location: '/ledger/' + device.uuid
        required property int index
        LedgerDeviceController {
            id: controller
            device: self.device
        }
        padding: 32
        leftPadding: 32
        rightPadding: 32
        topPadding: 32
        bottomPadding: 32
        background: Rectangle {
            radius: 8
            color: ((navigation.location === '/ledger' && index === 0) || navigation.location === location) ? constants.c700 : constants.c800
        }
        onClicked: navigation.go(location)
        contentItem: RowLayout {
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
                Layout.fillWidth: true
                columnSpacing: 16
                rowSpacing: 8
                columns: 2
                Label {
                    text: qsTrId('id_model')
                }
                RowLayout {
                    spacing: constants.s1
                    Label {
                        Layout.alignment: Qt.AlignBaseline
                        text: switch(device.type) {
                            case Device.LedgerNanoS: return 'Nano S'
                            case Device.LedgerNanoX: return 'Nano X'
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignBaseline
                        visible: controller.status === 'outdated'
                        text: 'Update required'
                        background: Rectangle {
                            color: constants.r500
                            radius: 4
                        }
                        padding: 4
                    }
                    HSpacer {
                    }
                }
                Label {
                    text: qsTrId('id_connection')
                }
                Label {
                    text: 'USB'
                }
            }
            ColumnLayout {
                visible: controller.status !== 'outdated'
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
                GPane {
                    background: null
                    padding: 0
                    contentItem: RowLayout {
                        id: activities_row
                    }
                }
                RowLayout {
                    GButton {
                        large: true
                        visible: controller.network && !controller.wallet
                        icon.color: 'transparent'
                        icon.source: controller.network ? icons[controller.network.key] : ''
                        text: qsTrId('id_login')
                        onClicked: {
                            login_dialog.createObject(window, { controller }).open()
                            controller.login()
                        }
                    }
                    GButton {
                        visible: controller.status === 'done'
                        text: qsTrId('id_go_to_wallet')
                        onClicked: navigation.go(`/${controller.network.key}/${controller.wallet.id}`)
                    }
                    HSpacer {
                    }
                }
                Component {
                    id: login_dialog
                    LedgerLoginDialog {
                    }
                }
            }
        }
    }
}
