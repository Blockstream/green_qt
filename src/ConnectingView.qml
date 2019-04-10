import QtQuick 2.0
import QtQuick.Controls 2.5

Item {
    Column {
        anchors.centerIn: parent
        spacing: 32

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: true
        }
        Label {
            text: 'CONNECTING'
        }
    }
}
