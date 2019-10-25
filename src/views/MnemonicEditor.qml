import Blockstream.Green 0.1
import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    property Action accept

    readonly property var mnemonic: {
        const words = []
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i)
            if (item.acceptableInput) {
                words.push(item.editText)
            }
        }
        return words
    }

    function filter(text) {
        const result = []
        if (text.length >= 2) {
            const match = text.substring(0, 2)
            for (const word of Wally.wordlist) {
                if (word.startsWith(match) && word !== text) result.push(word)
            }
        }
        if (result.length !== 1) {
            result.unshift(text)
        }
        return result
    }

    function detectPaste(text) {
        const ws = text.trim().split(' ')
        if (ws.length !== 24) return
        for (let i = 0; i < 24; ++i) {
            repeater.itemAt(i).editText = ws[i]
        }
    }

    function clear() {
        for (let i = 0; i < repeater.count; i++) {
            repeater.itemAt(i).editText = ''
        }
    }

    spacing: 32

    GridLayout {
        columns: 4

        Repeater {
            id: repeater
            model: 24

            ComboBox {
                id: combo_box
                editable: true
                enabled: index === 0 || repeater.itemAt(index - 1).acceptableInput && repeater.itemAt(index - 1).enabled
                displayText: `${index} - ${currentText}`
                leftPadding: height / 2
                model: filter(editText)
                validator: WordValidator {}
                onActivated: nextItemInFocusChain().nextItemInFocusChain().forceActiveFocus()
                onEditTextChanged: detectPaste(editText)

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: index
                }
            }
        }
    }

    RowLayout {
        Button {
            enabled: mnemonic.length > 0
            flat: true
            text: qsTr('id_clear')
            onClicked: clear()
        }
        ProgressBar {
            from: 0
            to: 24
            value: mnemonic.length
            Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Layout.fillWidth: true
        }
        Button {
            action: accept
            enabled: mnemonic.length === 24
            flat: true
        }
    }
}
