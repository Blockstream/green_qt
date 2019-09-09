import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

FocusScope {
    id: root

    property string buffer: ''
    property string pin: buffer.length === 6 ? buffer : ''
    property bool empty: buffer.length === 0
    property bool valid: buffer.length === 6

    function addDigit(digit) {
        digit = parseInt(digit)
        if (digit < 0 && digit > 9) return
        if (buffer.length === 6) return
        buffer = buffer + digit
    }

    function removeDigit() {
        if (buffer.length === 0) return
        buffer = buffer.slice(0, -1)
    }

    function clear() {
        buffer = ''
    }

    activeFocusOnTab: true
    width: row_layout.width
    height: row_layout.height
    implicitWidth: row_layout.implicitWidth
    implicitHeight: row_layout.implicitHeight

    Keys.onPressed: {
        if (event.key === Qt.Key_0) return addDigit(0)
        if (event.key === Qt.Key_1) return addDigit(1)
        if (event.key === Qt.Key_2) return addDigit(2)
        if (event.key === Qt.Key_3) return addDigit(3)
        if (event.key === Qt.Key_4) return addDigit(4)
        if (event.key === Qt.Key_5) return addDigit(5)
        if (event.key === Qt.Key_6) return addDigit(6)
        if (event.key === Qt.Key_7) return addDigit(7)
        if (event.key === Qt.Key_8) return addDigit(8)
        if (event.key === Qt.Key_9) return addDigit(9)
        if (event.key === Qt.Key_Backspace) removeDigit()
        if (event.key === Qt.Key_Escape) clear()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.forceActiveFocus()
    }

    RowLayout {
        id: row_layout

        anchors.centerIn: parent
        Layout.alignment: Qt.AlignCenter

        spacing: 8

        Repeater {
            model: 6

            Rectangle {
                width: 32
                height: 32
                radius: 16
                opacity: enabled ? 1 : 0.5
                color: Qt.rgba(1, 1, 1, buffer.length === modelData && root.activeFocus ? 0.1 : 0)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, buffer.length === modelData && root.activeFocus ? 0.4 : 0.2)

                Rectangle {
                    anchors.centerIn: parent
                    height: 2 * radius
                    width: height
                    radius: 3
                    color: 'white'
                    visible: buffer.length > modelData
                }
            }
        }
    }
}
