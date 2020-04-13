import QtQuick 2.12

Item {
    property bool collapsed: false
    property alias duration: animation.duration
    property alias easing: animation.easing
    clip: true
    implicitWidth: childrenRect.width
    implicitHeight: collapsed ? 0 : childrenRect.height
    Behavior on implicitHeight {
        NumberAnimation {
            id: animation
            duration: 300;
            easing.type: Easing.OutCubic
        }
    }
}
