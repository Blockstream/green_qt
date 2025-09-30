import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    signal pinEntered(string pin)
    property string pin: ''
    function enable() {
        self.enabled = true
    }
    function disable() {
        self.enabled = false
    }
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
    background: null
    contentItem: RowLayout {
        spacing: 10
        Digit { index: 0 }
        Digit { index: 1 }
        Digit { index: 2 }
        Digit { index: 3 }
        Digit { index: 4 }
        Digit { index: 5 }
    }

    component Digit: Item {
        required property int index
        readonly property bool visualFocus: self.activeFocus && digit.index === self.pin.length
        id: digit
        implicitWidth: 69
        implicitHeight: 69
        opacity: self.enabled ? 1 : 0.5
        Rectangle {
            anchors.fill: parent
            border.width: 2
            border.color: digit.visualFocus ? '#00BCFF' : '#333'
            color: 'transparent'
            radius: 10
        }
        Label {
            anchors.centerIn: parent
            font.pixelSize: 26
            font.weight: 600
            text: '*'
            visible: digit.index < self.pin.length
            color: '#00BCFF'
        }
    }
}
