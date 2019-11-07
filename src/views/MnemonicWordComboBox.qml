import Blockstream.Green 0.1
import QtQuick 2.0
import QtQuick.Controls 2.13

ComboBox {
    property int wordIndex
    property ComboBox previous

    editable: true
    enabled: !previous || previous.acceptableInput && previous.enabled
    displayText: `${wordIndex} - ${currentText}`
    leftPadding: height / 2
    model: filter(editText)
    validator: WordValidator {}
    onEditTextChanged: detectPaste(editText)

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: wordIndex
    }
}
