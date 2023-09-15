import QtQuick

Item {
    id: self
    property bool collapsed: false
    property real contentHeight: 0
    property real contentWidth: 0
    function toggle() {
        self.collapsed = !self.collapsed
    }
    clip: true
    implicitWidth: contentWidth
    implicitHeight: self.collapsed ? 0 : self.contentHeight
    Behavior on implicitHeight {
        SmoothedAnimation {
            velocity: 1000
        }
    }
}
