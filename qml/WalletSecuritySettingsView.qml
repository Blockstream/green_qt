import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Pane {
    required property Context context
    readonly property Wallet wallet: self.context.wallet
    Controller {
        id: controller
        context: self.wallet.context
    }
    id: self
    background: null
    padding: 0
    contentItem: ColumnLayout {
        spacing: 16
        SettingsBox {
            title: qsTrId('id_security')
            visible: false
            contentItem: ColumnLayout {
                spacing: constants.s1
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_disable_pin_access_for_this')
                    wrapMode: Text.WordWrap
                }
                AbstractButton {
                    Layout.fillWidth: true
                    id: disable_button
                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 15
                    bottomPadding: 15
                    background: Rectangle {
                        radius: 5
                        color: Qt.alpha(Qt.lighter('#F00', disable_button.hovered ? 1.2 : 1), 0.2)
                    }
                    contentItem: RowLayout {
                        Label {
                            Layout.fillWidth: true
                            text: qsTrId('id_disable_pin_access')
                        }
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/right.svg'
                        }
                    }
                    onClicked: {
                        const dialog = disable_all_pins_dialog.createObject(self, {
                            context: self.context,
                        })
                        dialog.open()
                    }
                }
            }
        }

        SettingsBox {
            title: qsTrId('id_access')
            visible: !self.context.watchonly && !(self.context.device?.type ?? false)
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_enable_or_change_your_pin_to')
                    wrapMode: Text.WordWrap
                }
                AbstractButton {
                    Layout.fillWidth: true
                    id: button
                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 15
                    bottomPadding: 15
                    background: Rectangle {
                        radius: 5
                        color: Qt.lighter('#222226', button.enabled && button.hovered ? 1.2 : 1)
                    }
                    contentItem: RowLayout {
                        Label {
                            Layout.fillWidth: true
                            text: qsTrId('id_change_pin')
                        }
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/edit.svg'
                        }
                    }
                    onClicked: {
                        const dialog = change_pin_dialog.createObject(self, {
                            context: self.context,
                        })
                        dialog.open()
                    }
                }
            }
        }

        SettingsBox {
            title: qsTrId('id_auto_logout_timeout')
            enabled: !self.context.locked
            visible: !self.context.device
            contentItem: ColumnLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    text: qsTrId('id_set_a_timeout_to_logout_after')
                    wrapMode: Label.WordWrap
                }
                GComboBox {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    model: [1, 2, 5, 10, 60]
                    width: 150
                    delegate: ItemDelegate {
                        background: null
                        width: parent.width
                        text: qsTrId('id_1d_minutes').arg(modelData)
                    }
                    displayText: qsTrId('id_1d_minutes').arg(currentText)
                    onCurrentTextChanged: controller.changeSettings({ altimeout: model[currentIndex] })
                    currentIndex: model.indexOf(self.context.primarySession.settings.altimeout)
                }
            }
        }
        VSpacer {
        }
    }

    Component {
        id: change_pin_dialog
        ChangePinDialog {
        }
    }

    Component {
        id: disable_all_pins_dialog
        DisableAllPinsDialog {
            // wallet: self.wallet
        }
    }
}
