import Blockstream.Green 0.1
import QtQuick 2.14
import QtQml 2.14
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.12

TextField {
    property Word word
    enabled: word.enabled
    focus: word.focus
    leftPadding: 32
    Binding on text {
        restoreMode: Binding.RestoreBinding
        when: !activeFocus
        value: word.text
    }
    onTextChanged: {
        if (activeFocus) {
            text = word.update(text);
        }
    }
    Keys.onPressed: {
        if (word.index > 0 && event.key === Qt.Key_Backspace && text === '') {
            nextItemInFocusChain(false).forceActiveFocus();
        }
    }
    ToolTip.text: word.suggestions.join(' ')
    ToolTip.visible: activeFocus && word.suggestions.length > 0
    ToolTip.toolTip.exit: null

    Label {
        anchors.baseline: parent.baseline
        x: 8
        text: word.index + 1
    }
}
