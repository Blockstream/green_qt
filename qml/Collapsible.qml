import QtQuick

Item {
    property bool collapsed: false
    property alias animating: animation.running
    property real contentHeight: childrenRect.height + childrenRect.y
    property real contentWidth: childrenRect.width + childrenRect.x
    function toggle() {
        self.collapsed = !self.collapsed
    }
    id: self
    clip: self.animating || self.collapsed
    implicitWidth: self.contentWidth
    implicitHeight: self.collapsed ? 0 : self.contentHeight
    Behavior on implicitHeight {
        SmoothedAnimation {
            id: animation
            velocity: 1000
        }
    }
}
