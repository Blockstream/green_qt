import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property string title: qsTrId('id_write_down_your_mnemonic_on')
    property alias mnemonic: view.mnemonic
    property list<Action> actions: [
        Action {
            text: qsTrId('id_back')
            onTriggered: back()
        },
        Action {
            text: qsTrId('id_continue')
            onTriggered: next()
        }
    ]
    signal back();
    signal next();

    MnemonicView {
        id: view
        anchors.centerIn: parent
    }
}
