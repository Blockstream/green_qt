import QtQuick 2.14
import QtQuick.Controls 2.14

Dialog {
    anchors.centerIn: parent
    Connections {
        target: wallet
        onConnectionChanged: reject()
    }
}
