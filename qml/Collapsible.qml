import QtQuick

Item {
    property bool collapsed: false
    readonly property bool animating: animation.running
    property real contentHeight: childrenRect.height + childrenRect.y
    property real contentWidth: childrenRect.width + childrenRect.x
    property real animationVelocity: 1000
    property bool horizontalCollapse: false
    property bool verticalCollapse: true
    property real position: self.collapsed ? 0 : 1
    function toggle() {
        self.collapsed = !self.collapsed
    }
    id: self
    clip: self.animating || self.collapsed
    implicitWidth: (self.horizontalCollapse ? self.position : 1) * self.contentWidth
    implicitHeight: (self.verticalCollapse ? self.position : 1) * self.contentHeight
    Behavior on position {
        SmoothedAnimation {
            id: animation
            velocity: self.animationVelocity / 100
        }
    }
}
