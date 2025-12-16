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

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 24

        // Multisig Login
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            visible: multisig_repeater.count > 0

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_multisig') + ' ' + qsTrId('id_login')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_set_up_watchonly_credentials')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8

                Repeater {
                    id: multisig_repeater
                    model: self.context.sessions.filter(session => !self.context.watchonly && !session.network.electrum)
                    delegate: AbstractButton {
                        required property var modelData
                        readonly property Session session: modelData
                        Layout.fillWidth: true
                        id: multisig_button
                        leftPadding: 16
                        rightPadding: 16
                        topPadding: 12
                        bottomPadding: 12
                        background: Rectangle {
                            radius: 5
                            color: Qt.lighter('#262626', multisig_button.hovered ? 1.2 : 1)
                        }
                        contentItem: RowLayout {
                            spacing: 12
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    font.pixelSize: 13
                                    font.weight: 600
                                    text: multisig_button.session.network.displayName
                                }
                                Label {
                                    font.pixelSize: 11
                                    color: '#6F6F6F'
                                    text: {
                                        if (multisig_button.session.username === '') return qsTrId('id_watchonly_disabled')
                                        return multisig_button.session.username
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
                                session: multisig_button.session,
                            })
                            dialog.open()
                        }
                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: multisig_repeater.count > 0 && singlesig_xpubs_repeater.count > 0
        }

        // Singlesig Extended Public Keys
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            visible: singlesig_xpubs_repeater.count > 0

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_singlesig') + ' ' + qsTrId('id_extended_public_keys')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_export_your_extended_public')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
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

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: singlesig_xpubs_repeater.count > 0 && singlesig_descriptors_repeater.count > 0
        }

        // Singlesig Output Descriptors
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            visible: singlesig_descriptors_repeater.count > 0

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_singlesig') + ' ' + qsTrId('id_output_descriptors')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_export_your_output_descriptors')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
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

        VSpacer {
        }
    }

    Component {
        id: watchonly_dialog
        WalletDialog {
            required property Session session
            id: dialog
            header: null
            footer: null
            enabled: watch_only_controller.monitor.idle
            width: 450
            height: 500
            WatchOnlyController {
                id: watch_only_controller
                session: dialog.session
                onFailed: error => error_badge.error = error
                onFinished: ok_badge.error = 'Watch-only credentials updated successfully'
            }
            contentItem: StackViewPage {
                title: qsTrId('id_set_up_watchonly')
                rightItem: CloseButton {
                    onClicked: dialog.close()
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
                                source: UtilJS.iconFor(dialog.session.network)
                            }
                            Label {
                                Layout.fillWidth: true
                                color: '#FFF'
                                font.pixelSize: 14
                                font.weight: 600
                                text: dialog.session.network.displayName
                            }
                        }
                    }
                    FieldTitle {
                        text: qsTrId('id_username')
                    }
                    TTextField {
                        Layout.fillWidth: true
                        id: username_field
                        text: dialog.session.username
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
                        enabled: dialog.session.username.length > 0
                        implicitWidth: 0
                        text: qsTrId('id_delete')
                        onClicked: {
                            error_badge.clear()
                            ok_badge.clear()
                            username_field.clear()
                            password_field.clear()
                            watch_only_controller.clear()
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
                            watch_only_controller.update(username_field.text, password_field.text)
                        }
                        busy: !watch_only_controller.monitor.idle
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
        leftPadding: 16
        rightPadding: 16
        topPadding: 12
        bottomPadding: 12
        background: Rectangle {
            radius: 5
            color: '#262626'
        }
        contentItem: RowLayout {
            spacing: 10
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RowLayout {
                    spacing: 8
                    Image {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: 20
                        source: UtilJS.iconFor(pane.account.network)
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 0
                        font.pixelSize: 13
                        font.weight: 600
                        text: UtilJS.accountName(pane.account)
                        wrapMode: Label.Wrap
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    font.pixelSize: 11
                    color: '#6F6F6F'
                    text: pane.text
                    wrapMode: Label.WrapAnywhere
                }
            }
            CircleButton {
                Layout.alignment: Qt.AlignCenter
                icon.source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                onClicked: {
                    Clipboard.copy(pane.text)
                    copy_timer.restart()
                }
                Timer {
                    id: copy_timer
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
