import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Switch {
    property color baseColor: self.checked ? '#00DD6E' : Qt.alpha('#000', 0.4)
    Behavior on baseColor {
        ColorAnimation {
            duration: 200
        }
    }
    id: self
    opacity: self.enabled ? 1 : 0.5
    indicator: Item {
        implicitWidth: 48
        implicitHeight: 28
        x: self.width - self.indicator.width
        y: parent.height / 2 - height / 2
        Rectangle {
            anchors.fill: parent
            anchors.margins: self.visualFocus ? 4 : 0
            color: Qt.lighter(self.baseColor, self.enabled && self.hovered ? 1.2 : 1)
            radius: height / 2
        }
        Rectangle {
            id: circle
            x: self.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            Behavior on x {
                SmoothedAnimation {
                    velocity: 100
                }
            }
            width: 22
            height: 22
            scale: self.down ? 0.75 : 1
            transformOrigin: Item.Center
            Behavior on scale {
                SmoothedAnimation {
                    velocity: 2
                }
            }
            radius: height / 2
            color: 'white'
        }
    }
    leftPadding: self.text.length > 0 ? 8 : 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    background: Item {
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: height / 2
            anchors.fill: parent
            visible: self.visualFocus
        }
    }
    contentItem: Label {
        text: self.text
        opacity: enabled ? 1.0 : 0.3
        verticalAlignment: Text.AlignVCenter
        elide: Label.ElideRight
        leftPadding: 0
        rightPadding: (self.text === '' ? 0 : self.spacing) + self.indicator.width
    }
}
