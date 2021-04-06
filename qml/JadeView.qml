import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

MainPage {
    id: self
    property alias count: devices_list_view.count
    readonly property string url: 'https://help.blockstream.com/hc/en-us/categories/900000061906-Blockstream-Jade'
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
        currentIndex: self.count === 0 ? 0 : 1
        ColumnLayout {
            spacing: 16
            Spacer {
            }
            Image {
                Layout.alignment: Qt.AlignHCenter
                source: 'qrc:/svg/blockstream_jade.svg'
            }
            Pane {
                Layout.topMargin: 40
                Layout.alignment: Qt.AlignHCenter
                background: Rectangle {
                    radius: 8
                    border.width: 2
                    border.color: constants.c600
                    color: 'transparent'
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
                        text: qsTrId('id_connect_your_jade_to_use_it')
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: qsTrId('id_need_help') + ' ' + link(url, qsTrId('id_visit_the_blockstream_help'))
                textFormat: Text.RichText
                color: 'white'
                onLinkActivated: Qt.openUrlExternally(url)
                background: MouseArea {
                    acceptedButtons: Qt.NoButton
                    cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
            Spacer {
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
                        if (devices_list_view.itemAtIndex(i).location === navigation.location) {
                            return i
                        }
                    }
                    return -1
                }

                delegate: Pane {
                    id: self
                    required property JadeDevice device
                    readonly property string location: '/jade/' + device.versionInfo.EFUSEMAC.slice(-6)
                    padding: 16
                    background: Rectangle {
                        radius: 8
                        color: constants.c700
                    }
                    contentItem: RowLayout {
                        spacing: 16
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            smooth: true
                            mipmap: true
                            fillMode: Image.PreserveAspectFit
                            horizontalAlignment: Image.AlignHCenter
                            verticalAlignment: Image.AlignVCenter
                            source: 'qrc:/svg/blockstream_jade.svg'
                            sourceSize.height: 64
                        }
                        GridLayout {
                            columnSpacing: 16
                            rowSpacing: 8
                            columns: 2
                            Label {
                                text: qsTrId('id_status')
                            }
                            Label {
                                text: {
                                    if (!device.versionInfo.JADE_HAS_PIN) return qsTrId('id_not_initialized')
                                    return qsTrId('id_initialized')
                                }
                            }
                            Label {
                                text: qsTrId('id_id')
                            }
                            Label {
                                text: device.versionInfo.EFUSEMAC.slice(-6)
                            }
                            Label {
                                text: qsTrId('id_firmware')
                            }
                            RowLayout {
                                Label {
                                    text: device.version
                                }
                                HSpacer {
                                }
                                GButton {
                                    text: qsTrId('id_update')
                                    onClicked: update_dialog.createObject(window, { device }).open()
                                }
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
                }
            }
            Pane {
                Layout.fillWidth: true
                Layout.fillHeight: true
                background: null
                contentItem: StackLayout {
                    currentIndex: devices_list_view.currentIndex
                    Repeater {
                        model: device_list_model
                        View {
                        }
                    }
                }
            }
        }
    }

    component NetworkSection: Page {
        id: self
        required property Network network
        required property JadeDevice device
        Layout.minimumWidth: 300
        padding: 16
        header: Pane {
            padding: 16
            background: null
            contentItem: RowLayout {
                spacing: 8
                Image {
                    source: icons[self.network.id]
                    sourceSize.width: 16
                    sourceSize.height: 16
                }
                Label {
                    Layout.fillWidth: true
                    text: self.network.name
                    font.styleName: 'Light'
                    font.pixelSize: 20
                }
            }
        }
        background: Rectangle {
            radius: 16
            color: constants.c700
        }
        JadeLoginController {
            id: controller
            device: self.device
            network: self.network.id
            onInvalidPin: self.ToolTip.show(qsTrId('id_invalid_pin'), 2000);
        }
        contentItem: RowLayout {
            Label {
                visible: controller.wallet && controller.wallet.authentication !== Wallet.Authenticated
                text: device.versionInfo.JADE_HAS_PIN ? qsTrId('id_enter_pin_on_jade') : qsTrId('id_setup_jade')
            }
            BusyIndicator {
                visible: controller.wallet && controller.wallet.authentication !== Wallet.Authenticated
            }
            GButton {
                visible: !controller.wallet
                text: device.versionInfo.JADE_HAS_PIN ? qsTrId('id_login') : qsTrId('id_setup_jade')
                onClicked: controller.login()
            }
            GButton {
                visible: controller.wallet && controller.wallet.authentication === Wallet.Authenticated
                text: qsTrId('id_go_to_wallet')
                onClicked: navigation.go(`/${self.network.id}/${controller.wallet.id}`)
            }
        }
    }

    component View: ColumnLayout {
        id: self
        required property JadeDevice device
        spacing: 16
        RowLayout {
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignCenter
            spacing: 16
            NetworkSection {
                network: NetworkManager.network('liquid')
                device: self.device
            }
            NetworkSection {
                network: NetworkManager.network('mainnet')
                device: self.device
            }
        }
        Item {
            Layout.fillHeight: true
            width: 1
        }
    }

    Component {
        id: update_dialog
        JadeUpdateDialog {
        }
    }
}
