import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

Column {
    property alias pin: field.pin
    property alias valid: field.valid

    function clear() {
        field.clear()
    }

    spacing: 8

    PinField {
        id: field
        focus: true
        anchors.horizontalCenter: parent.horizontalCenter
    }

    component PinButton: RoundButton {
        signal tapped()
        flat: true
        TapHandler {
            onTapped: parent.tapped()
        }
    }

    GridLayout {
        id: grid_layout
        columns: 3
        columnSpacing: 16
        rowSpacing: 8
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: 9
            PinButton {
                text: modelData + 1
                onTapped: field.addDigit(modelData + 1)
            }
        }

        PinButton {
            enabled: !field.empty
            width: 32
            icon.source: 'qrc:/svg/arrow_left.svg'
            icon.width: 24
            onTapped: field.removeDigit()
        }

        PinButton {
            enabled: !field.valid
            text: '0'
            onTapped: field.addDigit(0)
        }

        PinButton {
            enabled: !field.empty
            icon.source: 'qrc:/svg/cancel.svg'
            icon.height: 16
            icon.width: 16
            onTapped: field.clear()
        }
    }
}
