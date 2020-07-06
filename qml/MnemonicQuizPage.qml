import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

Item {
    property alias mnemonic: view.mnemonic
    property string title: qsTrId('id_check_your_backup')
    property list<Action> actions: [
        Action {
            text: qsTrId('id_back')
            onTriggered: back()
        }
    ]
    signal back()
    signal next()

    function reset() {
        view.reset();
    }

    implicitWidth: view.implicitWidth
    implicitHeight: view.implicitHeight

    MnemonicQuizView {
        id: view
        anchors.centerIn: parent
        onCompleteChanged: {
            if (complete) {
                next()
            }
        }
    }
}
