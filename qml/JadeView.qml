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
            spacing: 16
            Image {
                source: 'qrc:/svg/jade_logo_white_on_transparent_rgb.svg'
                sourceSize.height: 32
            }
            Item {
                Layout.fillWidth: true
                height: 1
            }
            Button {
                text: 'Get Jade'
                highlighted: true
                onClicked: Qt.openUrlExternally('https://store.blockstream.com/product/blockstream-jade/')
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
                        text: 'Connect your Jade hardware wallet to use it with Green'
                    }
                }
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                text: `<a href="${url}">Learn more about Blockstream Jade in our help center</a>`
                textFormat: Text.RichText
                color: 'white'
                onLinkActivated: Qt.openUrlExternally(url)
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
                                text: 'Status'
                            }
                            Label {
                                text: {
                                    if (!device.versionInfo.JADE_HAS_PIN) return 'Not initialized'
                                    return 'Initialized'
                                }
                            }
                            Label {
                                text: 'ID'
                            }
                            Label {
                                text: device.versionInfo.EFUSEMAC.slice(-6)
                            }
                            Label {
                                text: 'Firmware'
                            }
                            Label {
                                text: device.version
                            }
                            Label {
                                text: 'Connection'
                            }
                            Label {
                                text: 'USB'
                            }
                            Label {
                                text: 'System Location'
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
                background: Item {
                }
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
            background: Item {}
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
        JadeController {
            id: controller
            device: self.device
            network: self.network.id
            onInvalidPin: self.ToolTip.show(qsTrId('Invalid PIN'), 2000);
        }
        contentItem: RowLayout {
            Label {
                visible: controller.wallet && controller.wallet.authentication !== Wallet.Authenticated
                text: device.versionInfo.JADE_HAS_PIN ? 'Enter PIN on Jade' : 'Setup mnemonic on Jade'
            }
            BusyIndicator {
                visible: controller.wallet && controller.wallet.authentication !== Wallet.Authenticated
            }
            Button {
                flat: true
                visible: !controller.wallet
                text: device.versionInfo.JADE_HAS_PIN ? 'Login' : 'Setup'
                onClicked: controller.login()
            }
            Button {
                flat: true
                visible: controller.wallet && controller.wallet.authentication === Wallet.Authenticated
                text: 'Go to wallet'
                onClicked: pushLocation(`/${self.network.id}/${controller.wallet.id}`)
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
}
