import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

AbstractDialog {
    id: self
    title: 'Create Wallet'
    closePolicy: Popup.NoAutoClose

    width: 800
    height: 500

    signal networkSelected(var network)

    function select(network) {
        self.networkSelected(network)
        self.accept()
    }

    footer: DialogFooter {

    }

    contentItem: ColumnLayout {
        spacing: 40
        Label {
            text: qsTrId('id_choose_your_network')
            font.bold: true
            font.pixelSize: 24
        }
        Label {
            Layout.topMargin: -30
            Layout.fillWidth: true
            text: qsTrId('id_blockstream_green_supports_both')
            font.pixelSize: 12
            wrapMode: Label.WordWrap
        }
        RowLayout {
            spacing: 20
            NetworkCard {
                network: "mainnet"
                text: qsTrId("id_bitcoin_is_the_worlds_leading")
            }

            NetworkCard {
                network: "liquid"
                text: qsTrId("id_the_liquid_network_is_a_bitcoin")
            }

            HSpacer {
            }
        }
        Spacer {
        }
    }

    component NetworkCard: Button {
        id: self

        required property string network
        required property string label

        padding: 32
        Layout.fillWidth: true
        Layout.fillHeight: true
        background: Rectangle {
            color: parent.hovered?constants.c600:constants.c700
            radius: 4
        }
        contentItem: ColumnLayout {
            spacing: 20
            RowLayout {
                Layout.fillHeight: false
                spacing: 16
                Image {
                    source: icons[self.network]
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                }
                Label {
                    text: NetworkManager.network(self.network).name
                    font.pixelSize: 18
                }
            }
            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 200
                text: self.text
                font.pixelSize: 12
                wrapMode: Label.WordWrap
            }
        }
        onClicked: select(network)
    }
}
