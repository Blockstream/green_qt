import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

WalletDrawer {
    required property Session session
    WatchOnlyController {
        id: watch_only_controller
        session: self.session
        onFailed: error => error_badge.error = error
        onFinished: ok_badge.error = 'Watch-only credentials updated successfully'
    }
    id: self
    contentItem: StackViewPage {
        enabled: watch_only_controller.monitor.idle
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

    component FieldValidator: RegularExpressionValidator {
        regularExpression: /^.{8,}$/
    }
}
