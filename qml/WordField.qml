import Blockstream.Green 0.1
import QtQuick 2.14
import QtQml 2.14
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

GTextField {
    id: self
    property Word word
    readonly property bool invalid: word.suggestions.length === 0 && self.text.length > 2
    enabled: word.enabled
    leftPadding: 40
    Binding on text {
        restoreMode: Binding.RestoreBinding
        when: !activeFocus
        value: word.text
    }
    onTextChanged: {
        if (activeFocus) {
            text = word.update(text.trim());
            if (word.suggestions.length === 1 && text === word.suggestions[0]) {
                nextItemInFocusChain().forceActiveFocus()
            }
        }
    }

    Keys.onTabPressed: {
        if (word.suggestions.length === 1) {
            text = word.suggestions[0]
        }
        nextItemInFocusChain().forceActiveFocus()
    }
    Keys.onPressed: {
        if (word.index > 0 && event.key === Qt.Key_Backspace && text === '') {
            nextItemInFocusChain(false).forceActiveFocus();
        }
    }
    ToolTip.text: self.invalid ? qsTrId('id_not_a_valid_word') : word.suggestions.join(' ')
    ToolTip.visible: activeFocus && (word.suggestions.length > 1 || (word.suggestions.length === 1 && word.suggestions[0] !== self.text) || self.invalid)
    ToolTip.toolTip.exit: null

    Label {
        anchors.baseline: parent.baseline
        x: 8
        width: 24
        horizontalAlignment: Qt.AlignRight
        text: word.index + 1
        color: self.invalid ? 'red' : 'white'
    }
}
