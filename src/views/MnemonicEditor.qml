import Blockstream.Green 0.1
import QtQuick 2.0
import QtQuick.Controls 2.13
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

WizardPage {
    readonly property var mnemonic: {
        const words = []
        for (let i = 0; i < passwordProtected ? 27 : 24; i++) {
            const item = combo(i)
            if (!item) break
            if (item.acceptableInput) {
                words.push(item.editText)
            }
        }
        return words
    }

    readonly property bool passwordProtected: password_protected_checkbox.checked

    function filter(text) {
        const result = []
        if (text.length >= 2) {
            const match = text.substring(0, 2)
            for (const word of Wally.wordlist) {
                if (word.startsWith(match) && word !== text) result.push(word)
            }
        }
        result.unshift(text)
        return result
    }

    function detectPaste(text) {
        const ws = text.trim().split(/\s+/)
        if (ws.length !== 24 && ws.length !== 27) return
        for (let i = 0; i < ws.length; ++i) {
            combo(i).editText = ws[i]
        }
        password_protected_checkbox.checked = ws.length === 27
    }

    function clear() {
        for (let i = 0; i < 27; i++) {
            combo(i).editText = ''
        }
        password_protected_checkbox.checked = false
    }

    function combo(index) {
        if (index < 0) return null
        if (repeater.count + checksum.count !== 27) return null
        if (index < 24) return repeater.itemAt(index)
        return checksum.itemAt(index - 24)
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 32

        GridLayout {
            columns: 4

            Repeater {
                id: repeater
                model: 24

                MnemonicWordComboBox {
                    wordIndex: index + 1
                    previous: combo(index - 1)
                }
            }
        }

        Page {
            Layout.alignment: Qt.AlignHCenter
            header: CheckBox  {
                id: password_protected_checkbox
                text: qsTr('id_password_protected')
                onCheckedChanged: if (!checked) {
                    combo(24).editText = ''
                    combo(25).editText = ''
                    combo(26).editText = ''
                }
            }

            RowLayout {
                visible: passwordProtected

                Repeater {
                    id: checksum
                    model: 3

                    MnemonicWordComboBox {
                        wordIndex: 24 + index + 1
                        previous: combo(24 + index - 1)
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
            Item {
                Layout.fillWidth: true
            }
            ProgressBar {
                from: 0
                to: passwordProtected ? 27 : 24
                value: mnemonic.length
                Behavior on value { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Layout.fillWidth: true
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                action: accept
                enabled: mnemonic.length === (passwordProtected ? 27 : 24)
                flat: true
            }
        }
    }
}
