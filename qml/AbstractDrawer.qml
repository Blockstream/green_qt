import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Drawer {
    property real minimumContentWidth: 400
    property real preferredContentWidth: 0

    id: self
    clip: true
    height: parent.height
    interactive: self.visible
    topPadding: 30
    bottomPadding: 30
    leftPadding: 32 + self.leftMargin
    rightPadding: 32
    z: 2

    contentWidth: Math.max(self.minimumContentWidth, self.preferredContentWidth)
    Behavior on contentWidth {
        SmoothedAnimation {
            velocity: 500
        }
    }

    Overlay.modal: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.position * -0.05
        blurEnabled: true
        blurMax: 64
        blur: self.position
        source: ApplicationWindow.contentItem
    }

    Overlay.modeless: MultiEffect {
        anchors.fill: parent
        autoPaddingEnabled: false
        brightness: self.position * -0.05
        blurEnabled: true
        blurMax: 32
        blur: self.position
        source: ApplicationWindow.contentItem
    }

    background: Rectangle {
        color: Qt.alpha('#232323', 0.90)
        Rectangle {
            color: '#383838'
            width: 1
            height: parent.height
            x: self.edge === Qt.RightEdge ? 0 : parent.width - 1
        }
    }
}
