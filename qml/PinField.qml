import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    signal pinEntered(string pin)
    property alias pin: self.text
    property real digitSize: 64
    property real dotSize: self.digitSize * 10 / 64
    property real spacing: self.digitSize * 10 / 64
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
        self.pin += digit
    }

    function remove() {
        if (self.pin.length > 0) {
            self.pin = self.pin.slice(0, -1)
        }
    }
    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_Escape:
                return self.clear()
        }
    }
    onPinChanged: {
        if (self.pin.length === 6) {
            self.pinEntered(self.pin)
        }
    }
    id: self
    activeFocusOnTab: true
    bottomPadding: 0
    echoMode: TextField.NoEcho
    leftPadding: 0
    opacity: self.enabled ? 1 : 0.4
    rightPadding: 0
    topPadding: 0
    validator: RegularExpressionValidator {
        regularExpression: /[0-9]{6}/
    }
    cursorDelegate: Item {
    }
    background: RowLayout {
        spacing: self.spacing
        Digit { index: 0 }
        Digit { index: 1 }
        Digit { index: 2 }
        Digit { index: 3 }
        Digit { index: 4 }
        Digit { index: 5 }
    }
    component Digit: Item {
        required property int index
        id: digit
        implicitHeight: self.digitSize
        implicitWidth: self.digitSize
        opacity: self.enabled ? 1 : 0.5
        Rectangle {
            anchors.fill: parent
            border.width: 2
            border.color: self.activeFocus && digit.index === self.pin.length ? '#00BCFF' : '#333'
            color: Qt.alpha('#000000', 0.2)
            radius: 10
        }
        Rectangle {
            width: self.dotSize
            height: self.dotSize
            radius: self.dotSize / 2
            anchors.centerIn: parent
            visible: digit.index < self.pin.length
            color: self.enabled && self.activeFocus ? '#00BCFF' : '#333'
        }
    }
}
