import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

RowLayout {
    property Network network

    spacing: 30
    anchors.centerIn: parent

    Column {
        spacing: 15
        width: 150

        Label {
            text: qsTr('id_create_a_wallet_for_bitcoin')
            font.pixelSize : 14
        }
    }

    Column {
        Repeater {
            model: NetworkManager.networks

            Button {
                width: 180
                height: 80

                onClicked: network = modelData

                Row {
                    anchors.centerIn: parent

                    Image {
                        source:  '../' + logos[modelData.id]
                    }

                    Label {
                        text: modelData.name
                        visible: modelData.id !== 'liquid'
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
