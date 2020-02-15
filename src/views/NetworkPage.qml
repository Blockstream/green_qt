import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property string title: qsTrId('id_choose_your_network')
    property list<Action> actions: [
        Action {
            text: qsTrId('id_back')
            onTriggered: back()
        }
    ]
    property Network network
    signal back()
    signal next()

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Row {
        id: content
        spacing: 30
        anchors.centerIn: parent

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr('id_create_a_wallet_for_bitcoin')
            font.pixelSize : 14
        }

        Column {
            Repeater {
                model: NetworkManager.networks

                Button {
                    width: 180
                    height: 80

                    onClicked: {
                        network = modelData;
                        next();
                    }

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
}
