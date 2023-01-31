import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Switch {
    id: self
    opacity: self.enabled ? 1 : 0.5
    indicator: Rectangle {
        implicitWidth: 42
        implicitHeight: 24
        x: self.width - self.indicator.width
        y: parent.height / 2 - height / 2
        radius: 12
        color: self.checked ? constants.g500 : constants.c500
        border.color: Qt.lighter(color)
        border.width: self.activeFocus ? 1 : 0
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
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
            width: 18
            height: 18
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
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    contentItem: Label {
        text: self.text
        opacity: enabled ? 1.0 : 0.3
        verticalAlignment: Text.AlignVCenter
        leftPadding: 0
        rightPadding: (self.text === '' ? 0 : self.spacing) + self.indicator.width
    }
}
