import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    property alias mnemonic: controller.mnemonic
    property alias completed: controller.completed
    property bool failed: controller.attempts === 0

    MnemonicQuizController {
        id: controller
    }

    spacing: 16
    VSpacer {
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: qsTrId('id_check_your_backup')
        font.pixelSize: 20
    }
    GridLayout {
        Layout.fillWidth: false
        Layout.alignment: Qt.AlignHCenter
        columnSpacing: 2
        rowSpacing: 2
        columns: 6
        flow: GridLayout.LeftToRight

        Repeater {
            model: controller.words
            delegate: Button {
                property MnemonicQuizWord word: modelData
                Layout.fillWidth: true
                id: button
                padding: 18
                background: Rectangle {
                    radius: 4
                    color: Qt.rgba(1, 1, 1, button.activeFocus || hovered ? 0.05 : 0)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, button.activeFocus || hovered ? 0.1 : 0)
                }
                contentItem: RowLayout {
                    Label {
                        Layout.minimumWidth: 24
                        text: `${index + 1}`
                        textFormat: Text.RichText
                        font.pixelSize : 12
                        color: word.correct ? Material.accentColor : 'red'
                        horizontalAlignment: Label.AlignRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: word.value
                        textFormat: Text.RichText
                        font.pixelSize : 15
                    }
                }
                onClicked: menu.open()
                Menu {
                    id: menu
                    Repeater {
                        model: word.options
                        MenuItem {
                            text: modelData
                            onClicked: controller.change(word, modelData)
                        }
                    }
                }
            }
        }
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: qsTrId('id_attempts_remaining_d').arg(controller.attempts)
        font.pixelSize: 15
    }
    VSpacer {
    }
}
