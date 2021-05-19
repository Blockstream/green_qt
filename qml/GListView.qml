import QtQuick 2.12

ListView {
    id: self
    MouseArea {
        anchors.fill: parent
        onClicked: self.forceActiveFocus(Qt.MouseFocusReason)
        z: -1
    }
}
