import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

Column {
    readonly property string pin: field.pin
    readonly property bool valid: field.valid

    function clear() {
        field.clear()
    }

    spacing: 8

    PinField {
        id: field
        focus: true
        anchors.horizontalCenter: parent.horizontalCenter
    }

    GridLayout {
        id: grid_layout
        columns: 3
        columnSpacing: 16
        rowSpacing: 8
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: 9

            Button {
                hoverEnabled: false
                flat: true
                text: modelData + 1
                onPressed: field.addDigit(modelData + 1)
            }
        }

        Button {
            hoverEnabled: false
            enabled: !field.empty
            flat: true
            width: 32
            icon.source: 'qrc:/svg/arrow_left.svg'
            icon.width: 24
            onPressed: field.removeDigit()
        }

        Button {
            hoverEnabled: false
            enabled: !field.valid
            flat: true
            text: '0'
            onPressed: field.addDigit(0)
        }

        Button {
            hoverEnabled: false
            enabled: !field.empty
            flat: true
            icon.source: 'qrc:/svg/cancel.svg'
            icon.height: 16
            icon.width: 16
            onPressed: field.clear()
        }
    }
}
