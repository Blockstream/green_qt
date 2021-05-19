import QtQuick 2.12

ListView {
    MouseArea {
        anchors.fill: parent
        onClicked: forceActiveFocus(Qt.MouseFocusReason)
        z: -1
    }
}
