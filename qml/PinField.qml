import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    signal pinEntered(string pin)
    property string pin: ''
    function clear() {
        self.pin = ''
    }
    function append(digit) {
        if (self.pin?.length < 6) {
            self.pin = self.pin + digit
            if (self.pin.length === 6) {
                self.pinEntered(self.pin)
            }
        }
    }
    function remove() {
        if (self.pin?.length > 0) {
            self.pin = self.pin.slice(0, -1)
        }
    }
    id: self
    opacity: self.enabled ? 1 : 0.4
    activeFocusOnTab: true
    onClicked: self.forceActiveFocus()
    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_0:
            case Qt.Key_1:
            case Qt.Key_2:
            case Qt.Key_3:
            case Qt.Key_4:
            case Qt.Key_5:
            case Qt.Key_6:
            case Qt.Key_7:
            case Qt.Key_8:
            case Qt.Key_9:
                return self.append(event.key - Qt.Key_0)
            case Qt.Key_Backspace:
                return self.remove()
        }
    }
    leftPadding: 0
    topPadding: 0
    bottomPadding: 0
    rightPadding: 0

    background: Item {
        Rectangle {
            border.width: 2
            border.color: '#00B45A'
            color: 'transparent'
            radius: 14
            anchors.fill: parent
            anchors.margins: -4
            z: -1
            visible: self.visualFocus
        }
    }
    contentItem: RowLayout {
        spacing: 10
        Digit { fill: self.pin.length > 0 }
        Digit { fill: self.pin.length > 1 }
        Digit { fill: self.pin.length > 2 }
        Digit { fill: self.pin.length > 3 }
        Digit { fill: self.pin.length > 4 }
        Digit { fill: self.pin.length > 5 }
    }

    component Digit: Rectangle {
        required property bool fill
        id: digit
        radius: 10
        implicitWidth: 43
        implicitHeight: 69
        color: '#FFF'
        opacity: self.enabled ? 1 : 0.5
        Rectangle {
            anchors.centerIn: parent
            radius: 7
            width: 14
            height: 14
            color: digit.fill ? '#212121' : '#D3D3D3'
        }
    }
}
