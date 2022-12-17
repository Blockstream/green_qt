import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

ColumnLayout {
    required property JadeDevice device

    id: self
    spacing: constants.s3
    Layout.minimumWidth: implicitWidth

    JadeUpdateDialog {
        id: update_dialog
        device: self.device
    }

    Page {
        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: implicitWidth
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
                text: qsTrId('id_networks')
            }
            Label {
                text: {
                    const nets = self.device.versionInfo.JADE_NETWORKS
                    if (nets === 'ALL') return qsTrId('id_all_networks')
                    if (nets === 'TEST') return qsTrId('id_bitcoin_testnet_and_liquid')
                    if (nets === 'MAIN') return qsTrId('id_bitcoin_and_liquid')
                }
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
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.minimumWidth: implicitWidth
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
            rowSpacing: constants.s0
            Label {
                Layout.minimumWidth: 100
                Layout.minimumHeight: 32
                verticalAlignment: Label.AlignVCenter
                text: qsTrId('id_version')
            }
            Label {
                Layout.minimumHeight: 32
                Layout.fillWidth: true
                text: device.version
                verticalAlignment: Label.AlignVCenter
            }
            Label {
                Layout.minimumHeight: 32
                text: qsTrId('id_bluetooth')
                verticalAlignment: Label.AlignVCenter
            }
            Label {
                Layout.minimumHeight: 32
                text: device.versionInfo.JADE_CONFIG === 'NORADIO' ? qsTrId('id_not_available_noradio_build') : qsTrId('id_available')
                verticalAlignment: Label.AlignVCenter
            }
            Label {
                Layout.minimumHeight: 32
                visible: self.device.state !== JadeDevice.StateUnsaved
                text: qsTrId('id_update')
                verticalAlignment: Label.AlignVCenter
            }
            RowLayout {
                visible: self.device.state !== JadeDevice.StateUnsaved
                GButton {
                    padding: 4
                    topInset: 0
                    bottomInset: 0
                    highlighted: (self.device && self.device.updateRequired) || !!update_dialog.controller.firmwareAvailable
                    enabled: !firmware_controller.fetching
                    text: {
                        if (self.device.updateRequired) return qsTrId('id_new_jade_firmware_required')
                        const fw = update_dialog.controller.firmwareAvailable
                        if (fw) return `${fw.version} available`
                        return qsTrId('id_check_for_updates')
                    }
                    onClicked: {
                        if (Object.keys(firmware_controller.index).length === 0) {
                            firmware_controller.enabled = true
                        } else {
                            update_dialog.advancedUpdate()
                        }
                    }
                }
                BusyIndicator {
                    Layout.preferredHeight: 32
                    running: firmware_controller.fetching
                    visible: running
                }
                HSpacer {}
            }
        }
    }
    Loader {
        Layout.margins: constants.s2
        Layout.alignment: Qt.AlignCenter
        active: self.device.versionInfo.JADE_NETWORKS === 'TEST' && !Settings.enableTestnet
        visible: active
        sourceComponent: Label {
            horizontalAlignment: Text.AlignHCenter
            padding: 8
            background: Rectangle {
                radius: 4
                color: 'white'
            }
            font.capitalization: Font.AllUppercase
            font.styleName: 'Medium'
            color: 'black'
            font.pixelSize: 10
            text: qsTrId('id_jade_was_initialized_for_testnet') + '\n' + qsTrId('id_enable_testnet_in_app_settings')
        }
    }
    Page {
        Layout.fillWidth: true
        background: null
        visible: !self.device.updateRequired && !(self.device.versionInfo.JADE_NETWORKS === 'TEST' && !Settings.enableTestnet)
        header: Label {
            text: qsTrId('id_wallets')
            font.pixelSize: 20
            font.styleName: 'Bold'
            bottomPadding: constants.s1
        }
        contentItem: ColumnLayout {
            spacing: 0
            Pane {
                Layout.fillWidth: true
                padding: 0
                bottomPadding: 8
                background: Item {
                    Rectangle {
                        width: parent.width
                        height: 1
                        y: parent.height - 1
                        color: constants.c600
                    }
                }
                contentItem: RowLayout {
                    spacing: constants.s1
                    Label {
                        text: qsTrId('id_network')
                        color: constants.c300
                        Layout.minimumWidth: 150
                    }
                    Label {
                        text: qsTrId('Type')
                        color: constants.c300
                        Layout.minimumWidth: 150
                    }
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_wallet')
                        color: constants.c300
                    }
                    Label {
                        Layout.minimumWidth: 150
                        text: qsTrId('id_actions')
                        color: constants.c300
                    }
                }
            }
            Repeater {
                model: {
                    if (self.device.updateRequired) return []
                    const nets = self.device.versionInfo.JADE_NETWORKS
                    const networks = []
                    if (nets === 'ALL' || nets === 'MAIN') {
                        networks.push({ id: 'mainnet' })
                        networks.push({ id: 'electrum-mainnet' })
                        networks.push({ id: 'liquid' })
                        networks.push({ id: 'electrum-liquid', comingSoon: true })
                    }
                    if (Settings.enableTestnet && (nets === 'ALL' || nets === 'TEST')) {
                        networks.push({ id: 'testnet' })
                        networks.push({ id: 'electrum-testnet' })
                        networks.push({ id: 'testnet-liquid' })
                        networks.push({ id: 'electrum-testnet-liquid', comingSoon: true })
                    }
                    return networks
                }
                delegate: JadeViewDeviceNetwork {
                    comingSoon: !!modelData.comingSoon
                    network: NetworkManager.network(modelData.id)
                    device: self.device
                }
            }
        }
    }
    VSpacer {
    }
}
