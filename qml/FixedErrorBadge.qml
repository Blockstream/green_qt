import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Label {
    id: self
    property bool pointer: true
    property var error
    onErrorChanged: if (error) text = error
    scale: self.error ? 1 : 0
    Behavior on scale {
        SmoothedAnimation {
            velocity: 4
        }
    }
    color: 'white'
    font.bold: true
    font.pixelSize: 12
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
