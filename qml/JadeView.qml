import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    id: self
    property alias count: devices_list_view.count
    readonly property string url: 'https://help.blockstream.com/hc/en-us/categories/900000061906-Blockstream-Jade'

    function formatDeviceState(state) {
        switch (state) {
            case JadeDevice.StateLocked:
                return qsTrId('Locked')
            case JadeDevice.StateTemporary:
            case JadeDevice.StateReady:
                return qsTrId('Ready')
            case JadeDevice.StateUnsaved:
            case JadeDevice.StateUninitialized:
                return qsTrId('Uninitialized')
            default:
                return qsTrId('Unknonw')
        }
    }

    JadeDeviceSerialPortDiscoveryAgent {
    }
    DeviceListModel {
        id: device_list_model
        type: Device.BlockstreamJade
    }
    header: MainPageHeader {
        contentItem: RowLayout {
            spacing: 12
            Label {
                text: qsTrId('Blockstream Devices')
                font.pixelSize: 24
                font.styleName: 'Medium'
            }
            Label {
                visible: self.count > 0
                text: self.count
                color: constants.c800
                font.pixelSize: 12
                font.styleName: 'Medium'
                horizontalAlignment: Label.AlignHCenter
                leftPadding: 6
                rightPadding: 6
                background: Rectangle {
                    color: 'white'
                    radius: 4
                }
            }
            HSpacer {
            }
            GButton {
                text: qsTrId('id_get_jade')
                highlighted: true
                large: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product/blockstream-jade/')
            }
        }
    }
    contentItem: StackLayout {
        currentIndex: devices_list_view.count === 0 ? 0 : 1
        ColumnLayout {
            spacing: constants.s1
            VSpacer {
                Layout.fillWidth: true
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg/blockstream_jade.svg'
                sourceSize.height: 32
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_connect_your_jade_to_use_it')
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_need_help') + ' ' + link(url, qsTrId('id_visit_the_blockstream_help'))
                textFormat: Text.RichText
                color: 'white'
                onLinkActivated: Qt.openUrlExternally(url)
                background: MouseArea {
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
            VSpacer {
            }
        }
        SplitView {
            focusPolicy: Qt.ClickFocus
            handle: Item {
                implicitWidth: 32
                implicitHeight: parent.height
            }
            GListView {
                SplitView.minimumWidth: 300
                id: devices_list_view
                model: device_list_model
                spacing: 0
                currentIndex: {
                    for (let i = 0; i < devices_list_view.count; ++i) {
                        if (devices_list_view.itemAtIndex(i).location === navigation.location) {
                            return i
                        }
                    }
                    return 0
                }
                delegate: Button {
                    id: self
                    required property JadeDevice device
                    readonly property string location: '/jade/' + device.versionInfo.EFUSEMAC.slice(-6)
                    width: ListView.view.contentWidth
                    onClicked: navigation.go(location)
                    padding: 16
                    highlighted: ListView.isCurrentItem
                    background: Rectangle {
                        radius: 4
                        border.width: 1
                        color: self.highlighted ? constants.c700 : self.hovered ? constants.c700 : constants.c800
                        border.color: self.highlighted ? constants.g500 : constants.c700
                    }
                    contentItem: ColumnLayout {
                        spacing: 16
                        Label {
                            Layout.fillWidth: true
                            text: `Jade ${device.versionInfo.EFUSEMAC.slice(-6)}`
                            font.pixelSize: 16
                        }
                        RowLayout {
                            spacing: 16
                            Image {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24
                                source: 'qrc:/svg/usbAlt.svg'
                            }
                            Image {
                                Layout.alignment: Qt.AlignLeft
                                smooth: true
                                mipmap: true
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignHCenter
                                verticalAlignment: Image.AlignVCenter
                                source: 'qrc:/svg/blockstream_jade.svg'
                                sourceSize.height: 24
                            }
                            HSpacer {
                            }
                            Label {
                                font.pixelSize: 10
                                font.capitalization: Font.AllUppercase
                                leftPadding: 8
                                rightPadding: 8
                                topPadding: 4
                                bottomPadding: 4
                                color: 'white'
                                background: Rectangle {
                                    color: constants.c400
                                    radius: 4
                                }
                                text: formatDeviceState(device.state)
                            }
                        }
                    }
                }
            }
            StackLayout {
                SplitView.fillWidth: true
                currentIndex: devices_list_view.currentIndex
                Repeater {
                    model: device_list_model
                    View {
                    }
                }
            }
        }
    }

    component NetworkSection: Pane {
        id: self
        required property Network network
        required property JadeDevice device
        Layout.fillWidth: true
        enabled: controller.enabled
        background: null
        padding: 0
        JadeLoginController {
            id: controller
            device: self.device
            network: self.network.id
            onInvalidPin: self.ToolTip.show(qsTrId('id_invalid_pin'), 2000);
        }
        contentItem: RowLayout {
            spacing: constants.s1
            Image {
                source: icons[self.network.key]
                sourceSize.width: 24
                sourceSize.height: 24
            }
            Label {
                Layout.fillWidth: true
                text: self.network.displayName
//                font.styleName: 'Light'
//                font.pixelSize: 20
            }
            Label {
                visible: controller.wallet
                text: controller.wallet ? controller.wallet.name : 'N/A'
            }
            GButton {
                visible: !controller.wallet || controller.wallet.authentication !== Wallet.Authenticated
                enabled: !controller.active
                text: switch (device.state) {
                    case JadeDevice.StateReady:
                    case JadeDevice.StateTemporary:
                        return qsTrId('id_login')
                    case JadeDevice.StateLocked:
                        return qsTrId('id_unlock_and_login')
                    default:
                        return qsTrId('id_setup_jade')
                }
                onClicked: controller.active = true
            }
            GButton {
                visible: controller.wallet && controller.wallet.authentication === Wallet.Authenticated
                text: qsTrId('id_go_to_wallet')
                onClicked: navigation.go(`/${self.network.key}/${controller.wallet.id}`)
            }
        }
    }

    component View: ColumnLayout {
        id: self
        required property JadeDevice device
        spacing: constants.s2
        RowLayout {
            Layout.fillHeight: false
            spacing: constants.s2
            Page {
                Layout.fillWidth: true
                background: null
                header: Label {
                    text: qsTrId('id_details')
                    font.pixelSize: 20
                    font.styleName: 'Bold'
                    bottomPadding: constants.s1
                }
                contentItem: GridLayout {
                    columns: 2
                    columnSpacing: constants.s2
                    rowSpacing: constants.s1
                    Label {
                        text: qsTrId('id_id')
                    }
                    Label {
                        text: device.versionInfo.EFUSEMAC.slice(-6)
                    }
                    Label {
                        text: qsTrId('id_status')
                    }
                    Label {
                        Layout.fillWidth: true
                        text: formatDeviceState(device.state)
                    }
                    Label {
                        text: qsTrId('id_connection')
                    }
                    Label {
                        text: 'USB'
                    }
                    Label {
                        text: qsTrId('id_system_location')
                    }
                    Label {
                        text: device.systemLocation
                    }
                }
            }
            Page {
                Layout.fillWidth: true
                background: null
                header: Label {
                    text: qsTrId('id_firmware')
                    font.pixelSize: 20
                    font.styleName: 'Bold'
                    bottomPadding: constants.s1
                }
                contentItem: GridLayout {
                    columns: 2
                    columnSpacing: constants.s2
                    rowSpacing: constants.s1
                    Label {
                        text: qsTrId('id_version')
                    }
                    Label {
                        Layout.fillWidth: true
                        text: device.version
                    }
                    Label {
                        text: qsTrId('Bluetooth')
                    }
                    Label {
                        text: device.versionInfo.JADE_CONFIG === 'NORADIO' ? qsTrId('id_not_supported') : qsTrId('id_supported')
                    }
                    Label {
                        text: qsTrId('id_update')
                    }
                    GButton {
                        highlighted: self.device.updateRequired
                        text: self.device.updateRequired ? qsTrId('id_new_jade_firmware_required') : qsTrId('id_check_for_updates')
                        onClicked: update_dialog.createObject(window, { device }).open()
                    }
                }
            }
        }
        Page {
            Layout.fillWidth: true
            background: null
            header: Label {
                text: qsTrId('id_wallets')
                font.pixelSize: 20
                font.styleName: 'Bold'
                bottomPadding: constants.s1
            }
            contentItem: ColumnLayout {
                spacing: constants.s1
                NetworkSection {
                    visible: !self.device.updateRequired
                    network: NetworkManager.network('liquid')
                    device: self.device
                }
                NetworkSection {
                    visible: !self.device.updateRequired
                    network: NetworkManager.network('mainnet')
                    device: self.device
                }
                NetworkSection {
                    visible: !self.device.updateRequired && Settings.enableTestnet
                    network: NetworkManager.network('testnet')
                    device: self.device
                }
                NetworkSection {
                    visible: !self.device.updateRequired && Settings.enableTestnet
                    network: NetworkManager.network('testnet-liquid')
                    device: self.device
                }
            }
        }
        VSpacer {
        }
    }

    Component {
        id: update_dialog
        JadeUpdateDialog {
        }
    }
}
