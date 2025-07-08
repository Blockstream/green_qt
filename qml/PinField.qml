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
        readonly property bool visualFocus: self.visualFocus && digit.index === self.pin.length
        id: digit
        implicitWidth: 43
        implicitHeight: 69
        opacity: self.enabled ? 1 : 0.5
        Rectangle {
            anchors.fill: parent
            border.width: 2
            border.color: '#00BCFF'
            color: 'transparent'
            radius: 10
            visible: digit.visualFocus
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: digit.visualFocus ? 4 : 0
            color: '#FFF'
            radius: digit.visualFocus ? 6 : 10
        }
        Rectangle {
            anchors.centerIn: parent
            radius: 7
            width: 14
            height: 14
            color: digit.index < self.pin.length ? '#212121' : '#D3D3D3'
        }
    }
}
