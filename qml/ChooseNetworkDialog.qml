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
            text: 'Choose your wallet network'
            font.bold: true
            font.pixelSize: 24
        }
        Label {
            Layout.topMargin: -30
            Layout.fillWidth: true
            text: 'Blockstream Green supports both Bitcoin and Liquid Network.'
            font.pixelSize: 12
            wrapMode: Label.WordWrap
        }
        RowLayout {
            spacing: 20
            NetworkCard {
                network: "mainnet"
                text: "Bitcoin is the world's leading P2P cryptocurrenty network. Select to send and receive bitcoin."
            }

            NetworkCard {
                network: "liquid"
                text: "The Liquid Network is a Bitcoin sidechain. Select to send and receive Liquid Bitcoin (L-BTC), Tether (USDt), and other Liquid assets."
            }

            Item {
                Layout.fillWidth: true
                Layout.minimumWidth: 200
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
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
