import QtQuick 2.14
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.13

Button {
    property bool large: false

    id: self
    font.pixelSize: self.large ? 14 : 12
    font.bold: true
    padding: self.large ? 16 : 12
    leftPadding: self.large ? 20 : 15
    rightPadding: self.large ? 20 : 15
    background: Rectangle {
        id: background
        radius: 4
        color: self.hovered ? constants.c600: constants.c500
        states: [
            State {
                when: !self.enabled
                PropertyChanges { target: background; color: constants.c700 }
            },
            State {
                when: self.pressed
                PropertyChanges { target: background; color: "white" }
            },
            State {
                when: self.highlighted && self.hovered
                PropertyChanges { target: background; color: constants.g600 }
            },
            State {
                when: self.highlighted
                PropertyChanges { target: background; color: constants.g500 }
            }
        ]
    }
    contentItem: Label {
        text: parent.text
        color: parent.pressed ? "black" : "white"
        opacity: self.enabled ? 1 : 0.5
        horizontalAlignment: Text.AlignHCenter
    }
}
