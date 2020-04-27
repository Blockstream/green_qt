import QtQuick 2.14
import QtQuick.Controls 2.14

Dialog {
    clip: true
    modal: true
    horizontalPadding: 16
    verticalPadding: 0
    anchors.centerIn: parent
    Overlay.modal: Rectangle {
        color: "#70000000"
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    Behavior on implicitHeight {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

}
