import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    signal networkSelected(Network network)
    required property bool electrum
    objectName: "WatchOnlyNetworkPage"
    id: self
    footer: null
    padding: 60
    ColumnLayout {
        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: false
        Layout.fillWidth: false
        Layout.maximumWidth: 400
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 26
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            text: qsTrId('id_choose_your_network')
            wrapMode: Label.WordWrap
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.bottomMargin: 20
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            font.pixelSize: 14
            font.weight: 400
            horizontalAlignment: Label.AlignHCenter
            opacity: 0.4
            text: qsTrId('id_blockstream_green_supports_both')
            wrapMode: Label.Wrap
        }
        Option {
            Layout.fillWidth: true
            network: NetworkManager.network(self.electrum ? 'electrum-mainnet' : 'mainnet')
            description: qsTrId('id_bitcoin_is_the_worlds_leading')
        }
        Option {
            Layout.fillWidth: true
            network: NetworkManager.network(self.electrum ? 'electrum-liquid' : 'liquid')
            description: qsTrId('id_the_liquid_network_is_a_bitcoin')
        }
    }

    component Option: AbstractButton {
        required property Network network
        property string description

        id: option
        padding: 20
        icon.source: UtilJS.iconFor(option.network)
        text: option.network.displayName
        background: Rectangle {
            color: Qt.lighter('#262626', option.hovered ? 1.2 : 1)
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                visible: option.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 20
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: 10
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 32
                        Layout.preferredWidth: 32
                        source: option.icon.source
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 16
                        font.weight: 600
                        text: option.text
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    text: option.description
                    visible: !!option.description
                    wrapMode: Label.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
        onClicked: {
            if (Settings.enableTestnet) {
                deployment_dialog.createObject(self, { network: option.network }).open()
            } else {
                self.networkSelected(option.network)
            }
        }
    }

    Component {
        id: deployment_dialog
        DeploymentDialog {
            required property Network network
            id: dialog
            onDeploymentSelected: (deployment) => {
                if (deployment === 'testnet') {
                    const testnet = {
                        'mainnet': 'testnet',
                        'electrum-mainnet': 'electrum-testnet',
                        'liquid': 'testnet-liquid',
                        'electrum-liquid': 'electrum-testnet-liquid',
                    }
                    const network = NetworkManager.network(testnet[dialog.network.id])
                    self.networkSelected(network)
                } else {
                    self.networkSelected(dialog.network)
                }
            }
        }
    }
}
