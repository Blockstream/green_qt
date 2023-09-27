import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Label {
    id: self
    property bool pointer: true
    property var error
    function clear() {
        self.error = undefined
    }

    visible: self.text !== ''
    text: self.error ? (self.error.startsWith('id_') ? qsTrId(self.error) : self.error) : ''
    scale: self.error ? 1 : 0
    Behavior on scale {
        SmoothedAnimation {
            velocity: 4
        }
    }
    color: 'white'
    font.family: 'SF Compact Display'
    font.pixelSize: 16
    font.weight: 700
    topPadding: 4
    bottomPadding: 4
    leftPadding: 16
    rightPadding: 16
    background: Rectangle {
        radius: 4
        color: constants.r500
        Item {
            visible: pointer
            x: parent.width / 2
            Rectangle {
                width: 8
                height: 8
                rotation: 45
                color: constants.r500
                transformOrigin: Item.Center
                anchors.centerIn: parent
            }
        }
    }
}
