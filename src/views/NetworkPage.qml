import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

WizardPage {
    property Network network: network_group.checkedButton ? network_group.checkedButton.network : null
    onNetworkChanged: console.log(network.name, network.network)
    title: qsTr('id_choose_your_network')

    next: false

    RowLayout {
        spacing: 30
        anchors.centerIn: parent

        Column {
            spacing: 15
            width: 150

            Label {
                text: qsTr('id_choose_your_network')
                font.pixelSize: 24
            }

           Label {
                text: qsTr('id_create_a_wallet_for_bitcoin')
                font.pixelSize : 14
            }
        }

        Column {

            ButtonGroup {
                id: network_group
                exclusive: true
                onClicked: accept.trigger()
            }

            Repeater {
                model: NetworkManager.networks

                Button {
                    property var network: modelData

                    width: 180
                    height: 80

                    ButtonGroup.group: network_group
                    onClicked: checked = true

                    Row {
                        anchors.centerIn: parent

                        Image {
                            source:  '../' + logos[network.id]
                        }

                        Label {
                            text: network.name
                            visible: network.id !== 'liquid'
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
