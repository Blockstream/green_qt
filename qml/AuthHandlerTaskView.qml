import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackLayout {
    required property AuthHandlerTask task
    readonly property Session session: task.session
    id: self

    currentIndex: UtilJS.findChildIndex(self, child => child.active)
    BusyView {
    }
    AnimLoader {
        active: task.result.status === 'request_code'
        animated: true
        sourceComponent: RequestCodeView {
        }
    }
    AnimLoader {
        active: task.result.status === 'resolve_code' && task.result.method === 'email'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: task.result.status === 'resolve_code' && task.result.method === 'sms'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: task.result.status === 'resolve_code' && task.result.method === 'phone'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: task.result.status === 'resolve_code' && task.result.method === 'gauth'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: task.result.status === 'resolve_code' && task.result.method === 'telegram'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: task.result.status === 'error'
        animated: true
        sourceComponent: ErrorView {
        }
    }
    AnimLoader {
        active: task.result.status === 'done'
        animated: true
        sourceComponent: DoneView {
        }
    }

    component RequestCodeView: ColumnLayout {
        id: request_code_view
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId('id_choose_method_to_authorize_the')
        }
        Repeater {
            model: task.result?.methods ?? []
            Button {
                property string method: modelData
                icon.source: `qrc:/svg3/2fa_${method}.svg`
                icon.color: 'transparent'
                flat: true
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                text: UtilJS.twoFactorMethodLabel(method)
                focus: true
                onClicked: {
                    request_code_view.enabled = false
                    task.requestCode(method)
                }
            }
        }
        VSpacer {
        }
    }

    component ResolveTwoFactorCodeView: ColumnLayout {
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignCenter
            source: `qrc:/svg3/2fa_${task.result.method}.svg`
            sourceSize.width: 32
            sourceSize.height: 32
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            active: task instanceof TwoFactorResetTask
            visible: active
            sourceComponent: Label {
                text: task.email
                color: constants.c100
                font.pixelSize: 14
            }
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            active: self.session.config[task.result.method].enabled && !(task instanceof TwoFactorResetTask)
            visible: active
            sourceComponent: Label {
                text: {
                    if (task.result.method === 'gauth') return qsTrId('id_authenticator_app')
                    return self.session.config[task.result.method].data
                }
                color: constants.c100
                font.pixelSize: 14
            }
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            active: task.result.method === 'telegram'
            visible: active
            sourceComponent: RowLayout {
                readonly property url browser: task.result.auth_data.telegram_url
                readonly property url app: task.result.auth_data.telegram_url.replace('https://t.me/', 'tg://resolve?domain=').replace('?start=', '&start=')
                spacing: constants.s1
                ColumnLayout {
                    GButton {
                        Layout.fillWidth: true
                        text: 'Open in Browser'
                        onClicked: Qt.openUrlExternally(browser)
                    }
                    GButton {
                        Layout.fillWidth: true
                        text: 'Open Telegram'
                        onClicked: Qt.openUrlExternally(app)
                    }
                }
                QRCode {
                    text: app
                }
            }
        }
        PinView {
            Layout.alignment: Qt.AlignCenter
            id: keypad
            label: qsTrId('id_please_provide_your_1s_code').arg(task.result.method)
            focus: true
            onPinEntered: pin => task.resolveCode(pin)
            Connections {
                target: task
                function onUpdated() { keypad.clear() }
            }
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            active: task.result.method !== 'gauth' && task.result.method !== 'telegram'
            visible: active
            opacity: task.result.attempts_remaining < 3 ? 1 : 0
            sourceComponent: Label {
                text: qsTrId('id_attempts_remaining_d').arg(task.result.attempts_remaining)
            }
        }
        VSpacer {
        }
    }

    component BusyView: ColumnLayout {
        Spacer {
        }
        BusyIndicator {
            Layout.alignment: Qt.AlignCenter
        }
        VSpacer {
        }
    }

    component ErrorView: ColumnLayout {
        VSpacer {
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            text: qsTrId(task.result.error)
        }
        VSpacer {
        }
    }

    component DoneView: ColumnLayout {
        VSpacer {
        }
        Image {
            Layout.alignment: Qt.AlignHCenter
            source: 'qrc:/svg/check.svg'
            sourceSize.width: 64
            sourceSize.height: 64
        }
        Label {
            text: qsTrId('id_done')
            font.pixelSize: 20
            Layout.fillWidth: true
            horizontalAlignment: Label.AlignHCenter
        }
        VSpacer {
        }
    }
}
