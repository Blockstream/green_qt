import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: self
    signal pinEntered(string pin)

    property var buffer: []
    readonly property bool empty: buffer.length === 0
    readonly property bool valid: buffer.length === 6
    readonly property var pin: buffer.length === 6 ? ({ value: buffer.join(''), valid: true, empty: false }) : ({ value: '', valid: false, empty: buffer.length === 0 })
    property string label: qsTrId('id_enter_pin')

    function addDigit(digit) {
        digit = parseInt(digit)
        if (digit < 0 && digit > 9) return
        if (buffer.length === 6) return
        buffer = buffer.concat(digit)
        if (buffer.length === 6) {
            self.pinEntered(buffer.join(''))
        }
    }

    function removeDigit() {
        if (buffer.length === 0) return
        buffer = buffer.slice(0, -1)
    }

    function clear() {
        buffer = []
    }

    function paste() {
        const text = Clipboard.text()
        if (text.match(/^\d{6}$/)) {
            self.buffer = text.split('')
            timer.restart()
        }
    }

    Timer {
        id: timer
        interval: 300
        repeat: false
        onTriggered: {
            if (self.pin.valid) {
                self.pinEntered(self.pin.value)
            }
        }
    }

    Shortcut {
        sequences: [StandardKey.Paste]
        onActivated: paste()
    }

    spacing: 16
    focusPolicy: Qt.StrongFocus
    opacity: self.enabled ? 1 : 0.5
    background: null

    Keys.onPressed: (event) => {
        switch (event.key) {
            case Qt.Key_0: return addDigit(0)
            case Qt.Key_1: return addDigit(1)
            case Qt.Key_2: return addDigit(2)
            case Qt.Key_3: return addDigit(3)
            case Qt.Key_4: return addDigit(4)
            case Qt.Key_5: return addDigit(5)
            case Qt.Key_6: return addDigit(6)
            case Qt.Key_7: return addDigit(7)
            case Qt.Key_8: return addDigit(8)
            case Qt.Key_9: return addDigit(9)
            case Qt.Key_Backspace: return removeDigit()
        }
    }

    header: RowLayout {
        spacing: 4
        Label {
            Layout.minimumHeight: 24
            Layout.alignment: Qt.AlignCenter
            verticalAlignment: Label.AlignVCenter
            visible: self.enabled && buffer.length === 0
            text: self.label
        }
        Pane {
            Layout.minimumHeight: 24
            Layout.alignment: Qt.AlignCenter
            padding: 8
            visible: !self.enabled || buffer.length > 0
            background: Rectangle {
                radius: height / 2
                border.width: 1
                border.color: 'white'
                color: 'transparent'
                opacity: 0.1
            }
            contentItem: RowLayout {
                Repeater {
                    model: 6
                    Rectangle {
                        Layout.alignment: Qt.AlignCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: 'white'
                        opacity: index < buffer.length ? 1 : 0.1
                    }
                }
            }
        }
    }

    contentItem: GridLayout {
        columns: 3
        columnSpacing: 4
        rowSpacing: 4

        Repeater {
            model: 9
            PinButton {
                enabled: !self.valid
                text: modelData + 1
                onClicked: {
                    self.forceActiveFocus()
                    self.addDigit(modelData + 1)
                }
            }
        }

        PinButton {
            enabled: !self.empty
            width: 32
            icon.source: 'qrc:/svg/arrow_left.svg'
            icon.width: 16
            icon.height: 16
            onClicked: {
                self.forceActiveFocus()
                self.removeDigit()
            }
        }

        PinButton {
            enabled: !self.valid
            text: '0'
            onClicked: {
                self.forceActiveFocus()
                self.addDigit(0)
            }
        }

        PinButton {
            enabled: !self.empty
            icon.source: 'qrc:/svg/cancel.svg'
            icon.height: 12
            icon.width: 12
            onClicked: {
                self.forceActiveFocus()
                self.clear()
            }
        }
    }

    component PinButton: Button {
        id: button
        background: Rectangle {
            color: 'white'
            opacity: button.enabled ? (button.down ? 0.05 : 0.0) + (button.hovered ? 0.05 : 0.0) + 0.05 : 0.02
        }
        font.pixelSize: 14
        flat: true
        topInset: 0
        bottomInset: 0
        topPadding: 0
        bottomPadding: 0
        Layout.minimumWidth: 64
        Layout.minimumHeight: 32
        Layout.fillHeight: true
        Layout.fillWidth: true
    }
}
