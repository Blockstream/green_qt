import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

WizardPage {
    property Action accept
    property string network: network_group.checkedButton ? network_group.checkedButton.network.network : null

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
                text: qsTr('Create a wallet for Bitcoin, Liquid or Testnet')
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
                model: {
                    const result = []
                    const networks = WalletManager.networks()
                    for (const id of networks.all_networks) {
                        const network = networks[id]
                        if (!network.development) result.push(network)
                    }
                    return result
                }

                Button {
                    property var network: modelData
                    property var icons: ({
                        'Bitcoin': '../assets/svg/btc.svg',
                        'Liquid': '../assets/svg/liquid/liquid_with_string.svg',
                        'Testnet': '../assets/svg/btc_testnet.svg'
                    })

                    width: 180
                    height: 80

                    ButtonGroup.group: network_group
                    onClicked: checked = true

                    Row {
                        anchors.centerIn: parent

                        Image {
                            source: icons[network.name]
                        }

                        Label {
                            text: network.name
                            visible: network.name !== 'Liquid'
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
