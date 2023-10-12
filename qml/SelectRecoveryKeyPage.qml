import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

StackViewPage {
    signal recoveryKey(var recovery_key)
    signal xpub(string xpub)

    id: self
    title: qsTrId('id_select_your_recovery_key')
    contentItem: ColumnLayout {
        Option {
            text: qsTrId('id_new_recovery_phrase')
            description: qsTrId('id_generate_a_new_recovery_phrase')
        }
        Option {
            text: qsTrId('id_existing_recovery_phrase')
            description: qsTrId('id_use_an_existing_recovery_phrase')
            onClicked: self.StackView.view.push(enter_recovery_phrase)
        }
        Option {
            text: qsTrId('id_use_a_public_key')
            description: qsTrId('id_use_an_xpub_for_which_you_own')
            onClicked: self.StackView.view.push(enter_xpub)
        }
        VSpacer {
        }
    }

    Component {
        id: enter_recovery_phrase
        StackViewPage {
            MnemonicEditorController {
                id: controller
                mnemonicSize: 12
            }
            title: qsTrId('id_enter_your_recovery_phrase')
            contentItem: ColumnLayout {
                spacing: 5
                MnemonicSizeSelector {
                    size: controller.mnemonicSize
                    onSizeClicked: (size) => { controller.mnemonicSize = size }
                }
                Pane {
                    Layout.fillWidth: true
                    Layout.topMargin: 25
                    background: null
                    padding: 0
                    focus: true
                    contentItem: GridLayout {
                        columns: 3
                        columnSpacing: 8
                        rowSpacing: 8
                        Repeater {
                            model: controller.mnemonicSize
                            WordField {
                                Layout.horizontalStretchFactor: 0
                                Layout.preferredWidth: 0
                                Layout.fillWidth: true
                                focus: index === 0
                                word: controller.words[index]
                            }
                        }
                    }
                }
                FixedErrorBadge {
                    Layout.alignment: Qt.AlignCenter
                    Layout.topMargin: 10
                    error: switch (controller.errors.mnemonic) {
                        case 'invalid': return qsTrId('id_invalid_recovery_phrase')
                    }
                }
                VSpacer {
                }
            }
            footer: Pane {
                background: null
                padding: 0
                bottomPadding: 20
                contentItem: RowLayout {
                    PrimaryButton {
                        Layout.fillWidth: true
                        enabled: controller.valid
                        text: qsTrId('id_next')
                        onClicked: self.recoveryKey(controller.mnemonic)
                    }
                }
            }
        }
    }


    Component {
        id: enter_xpub
        StackViewPage {
            id: page
            title: qsTrId('id_enter_your_xpub')
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: qsTrId('id_use_an_xpub_for_which_you_own')
                    wrapMode: Label.WordWrap
                }
                FieldTitle {
                    Layout.topMargin: 20
                    text: qsTrId('id_xpub')
                }
                XPubField {
                    Layout.fillWidth: true
                    id: xpub_field
                }
                VSpacer {
                }
            }
            footer: Pane {
                background: null
                padding: 0
                bottomPadding: 20
                contentItem: RowLayout {
                    PrimaryButton {
                        Layout.fillWidth: true
                        enabled: xpub_field.text !== ''
                        text: qsTrId('id_next')
                        onClicked: self.xpub(xpub_field.text)
                    }
                }
            }
        }
    }

    component Option: AbstractButton {
        required property string description
        Layout.fillWidth: true
        id: button
        padding: 20
        background: Rectangle {
            color: '#222226'
            radius: 5
            Rectangle {
                border.width: 2
                border.color: '#00B45A'
                color: 'transparent'
                radius: 9
                anchors.fill: parent
                anchors.margins: -4
                visible: button.visualFocus
            }
        }
        contentItem: RowLayout {
            spacing: 8
            ColumnLayout {
                spacing: 8
                Label {
                    font.family: 'SF Compact Display'
                    font.pixelSize: 16
                    font.weight: 600
                    text: button.text
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.family: 'SF Compact Display'
                    font.pixelSize: 12
                    font.weight: 400
                    opacity: 0.6
                    text: button.description
                    wrapMode: Label.WordWrap
                }
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/svg2/next_arrow.svg'
            }
        }
    }
}
