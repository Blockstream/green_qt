import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Pane {
    required property Context context
    readonly property Wallet wallet: self.context.wallet

    Controller {
        id: controller
        context: self.context
    }

    id: self
    background: null
    padding: 0
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 16
            width: flickable.width
            SettingsBox {
                title: qsTrId('id_multisig') + ' ' + qsTrId('id_login')
                visible: multisig_repeater.count > 0
                contentItem: ColumnLayout {
                    spacing: 8
                    Repeater {
                        id: multisig_repeater
                        model: self.context.sessions.filter(session => !self.context.watchonly && !session.network.electrum)
                        delegate: AbstractButton {
                            required property var modelData
                            readonly property Session session: modelData
                            Layout.fillWidth: true
                            id: button
                            // TODO enabled: !wallet.locked
                            leftPadding: 20
                            rightPadding: 20
                            topPadding: 15
                            bottomPadding: 15
                            background: Rectangle {
                                radius: 5
                                color: Qt.lighter('#222226', button.hovered ? 1.2 : 1)
                            }
                            contentItem: RowLayout {
                                spacing: 20
                                ColumnLayout {
                                    Label {
                                        font.pixelSize: 14
                                        font.weight: 600
                                        text: button.session.network.displayName
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        font.pixelSize: 11
                                        font.weight: 400
                                        opacity: 0.6
                                        text: {
                                            if (button.session.username === '') return qsTrId('id_watchonly_disabled')
                                            return button.session.username
                                        }
                                    }
                                }
                                Image {
                                    Layout.alignment: Qt.AlignCenter
                                    source: 'qrc:/svg2/edit.svg'
                                }
                            }
                            onClicked: {
                                const dialog = watchonly_dialog.createObject(self, {
                                    context: self.context,
                                    session: button.session,
                                })
                                dialog.open()
                            }
                        }
                    }
                }
            }
            SettingsBox {
                title: qsTrId('id_singlesig') + ' ' + qsTrId('id_extended_public_keys')
                visible: singlesig_xpubs_repeater.count > 0
                contentItem: ColumnLayout {
                    spacing: 8
                    Repeater {
                        id: singlesig_xpubs_repeater
                        model: self.context.accounts.filter(account => !account.hidden && account.json.slip132_extended_pubkey)
                        delegate: SinglesigAccountPane {
                            required property var modelData
                            account: modelData
                            text: modelData.json.slip132_extended_pubkey
                        }
                    }
                }
            }
            SettingsBox {
                title: qsTrId('id_singlesig') + ' ' + qsTrId('id_output_descriptors')
                visible: singlesig_descriptors_repeater.count > 0
                contentItem: ColumnLayout {
                    spacing: 8
                    Repeater {
                        id: singlesig_descriptors_repeater
                        model: self.context.accounts.filter(account => !account.hidden && account.json.core_descriptors)
                        delegate: SinglesigAccountPane {
                            required property var modelData
                            account: modelData
                            text: modelData.json.core_descriptors.join('\n')
                        }
                    }
                }
            }
        }
    }

    Component {
        id: watchonly_dialog
        WalletDialog {
            required property Session session
            id: self
            header: null
            footer: null
            enabled: controller.monitor.idle
            width: 450
            height: 500
            WatchOnlyController {
                id: controller
                session: self.session
                onFailed: error => error_badge.error = error
                onFinished: ok_badge.error = 'Watch-only credentials updated successfully'
            }
            contentItem: StackViewPage {
                title: qsTrId('id_set_up_watchonly')
                rightItem: CloseButton {
                    onClicked: self.close()
                }
                contentItem: ColumnLayout {
                    spacing: 10
                    FieldTitle {
                        Layout.topMargin: 0
                        text: qsTrId('id_network')
                    }
                    Pane {
                        Layout.fillWidth: true
                        padding: 15
                        bottomPadding: 15
                        leftPadding: 20
                        rightPadding: 20
                        background: Rectangle {
                            color: '#181818'
                            radius: 5
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            Image {
                                Layout.alignment: Qt.AlignCenter
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24
                                source: UtilJS.iconFor(self.session.network)
                            }
                            Label {
                                Layout.fillWidth: true
                                color: '#FFF'
                                font.pixelSize: 14
                                font.weight: 600
                                text: self.session.network.displayName
                            }
                        }
                    }
                    FieldTitle {
                        text: qsTrId('id_username')
                    }
                    TTextField {
                        Layout.fillWidth: true
                        id: username_field
                        text: self.session.username
                        validator: FieldValidator {
                        }
                        onTextEdited: {
                            error_badge.clear()
                            ok_badge.clear()
                        }
                    }
                    FieldTitle {
                        text: qsTrId('id_password')
                    }
                    TTextField {
                        Layout.fillWidth: true
                        id: password_field
                        echoMode: TextField.Password
                        validator: FieldValidator {
                        }
                        onTextEdited: {
                            error_badge.clear()
                            ok_badge.clear()
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignCenter
                        font.pixelSize: 12
                        color: '#FFFFFF'
                        opacity: 0.6
                        text: qsTrId('id_at_least_8_characters_required')
                    }
                    VSpacer {
                    }
                    FixedErrorBadge {
                        Layout.alignment: Qt.AlignCenter
                        id: error_badge
                        pointer: false
                    }
                    FixedErrorBadge {
                        Layout.alignment: Qt.AlignCenter
                        id: ok_badge
                        pointer: false
                        backgroundColor: '#00BCFF'
                    }
                    VSpacer {
                    }
                }
                footerItem: RowLayout {
                    spacing: 10
                    RegularButton {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        enabled: self.session.username.length > 0
                        implicitWidth: 0
                        text: qsTrId('id_delete')
                        onClicked: {
                            error_badge.clear()
                            ok_badge.clear()
                            username_field.clear()
                            password_field.clear()
                            controller.clear()
                        }
                    }
                    PrimaryButton {
                        Layout.alignment: Qt.AlignCenter
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        implicitWidth: 0
                        text: qsTrId('id_update')
                        enabled: username_field.acceptableInput && password_field.acceptableInput
                        onClicked: {
                            ok_badge.clear()
                            error_badge.clear()
                            controller.update(username_field.text, password_field.text)
                        }
                        busy: !controller.monitor.idle
                    }
                }
            }
        }
    }

    component FieldValidator: RegularExpressionValidator {
        regularExpression: /^.{8,}$/
    }

    component SinglesigAccountPane: Pane {
        required property Account account
        required property string text
        Layout.fillWidth: true
        id: pane
        leftPadding: 20
        rightPadding: 20
        topPadding: 15
        bottomPadding: 15
        background: Rectangle {
            radius: 5
            color: '#222226'
        }
        contentItem: RowLayout {
            spacing: 10
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                Layout.fillHeight: false
                spacing: 10
                RowLayout {
                    spacing: 10
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 24
                        Layout.preferredWidth: 24
                        source: UtilJS.iconFor(pane.account.network)
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        font.pixelSize: 14
                        font.weight: 600
                        text: UtilJS.accountName(pane.account)
                        wrapMode: Label.Wrap
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 11
                    font.weight: 400
                    opacity: 0.6
                    text: pane.text
                    wrapMode: Label.WrapAnywhere
                }
            }
            CircleButton {
                Layout.alignment: Qt.AlignCenter
                icon.source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                onClicked: {
                    Clipboard.copy(pane.text)
                    timer.restart()
                }
                Timer {
                    id: timer
                    repeat: false
                    interval: 1000
                }
            }
            CircleButton {
                Layout.alignment: Qt.AlignCenter
                icon.source: 'qrc:/svg2/qrcode.svg'
                onClicked: qrcode_popup.open()
                QRCodePopup {
                    id: qrcode_popup
                    text: pane.text
                }
            }
        }
    }
}
