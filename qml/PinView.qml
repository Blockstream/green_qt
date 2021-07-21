import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

Column {
    property alias pin: field.pin

    function clear() {
        field.clear()
    }

    spacing: 24

    PinField {
        id: field
        anchors.horizontalCenter: parent.horizontalCenter
        Component.onCompleted: field.forceActiveFocus()
    }

    component PinButton: RoundButton {
        signal tapped()
        font.pixelSize: 18
        flat: true
        TapHandler {
            onTapped: parent.tapped()
        }
    }

    GridLayout {
        id: grid_layout
        columns: 3
        columnSpacing: 32
        rowSpacing: 0
        anchors.horizontalCenter: parent.horizontalCenter

        Repeater {
            model: 9
            PinButton {
                text: modelData + 1
                onTapped: {
                    field.forceActiveFocus()
                    field.addDigit(modelData + 1)
                }
            }
        }

        PinButton {
            enabled: !field.pin.empty
            width: 32
            icon.source: 'qrc:/svg/arrow_left.svg'
            icon.width: 24
            onTapped: {
                field.forceActiveFocus()
                field.removeDigit()
            }
        }

        PinButton {
            text: '0'
            onTapped: {
                field.forceActiveFocus()
                field.addDigit(0)
            }
        }

        PinButton {
            enabled: !field.pin.empty
            icon.source: 'qrc:/svg/cancel.svg'
            icon.height: 16
            icon.width: 16
            onTapped: {
                field.forceActiveFocus()
                field.clear()
            }
        }
    }
}
