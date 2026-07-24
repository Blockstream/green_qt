import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackLayout {
    required property AuthHandlerTask task
    readonly property Session session: task.session
    readonly property var authResult: {
        if (!task) return null
        if (task.prompt instanceof CodePrompt)
            return task.prompt.result
        return task.result
    }
    id: self

    currentIndex: UtilJS.findChildIndex(self, child => child.active)
    BusyView {
    }
    AnimLoader {
        active: self.authResult?.status === 'request_code'
        animated: true
        sourceComponent: RequestCodeView {
        }
    }
    AnimLoader {
        active: self.authResult?.status === 'resolve_code' && self.authResult?.method === 'email'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: self.authResult?.status === 'resolve_code' && self.authResult?.method === 'sms'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: self.authResult?.status === 'resolve_code' && self.authResult?.method === 'phone'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: self.authResult?.status === 'resolve_code' && self.authResult?.method === 'gauth'
        animated: true
        sourceComponent: ResolveTwoFactorCodeView {
        }
    }
    AnimLoader {
        active: self.authResult?.status === 'error'
        animated: true
        sourceComponent: ErrorView {
        }
    }
    AnimLoader {
        active: self.authResult?.status === 'done'
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
            model: self.authResult?.methods ?? []
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
            source: `qrc:/svg3/2fa_${self.authResult?.method ?? ''}.svg`
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
            active: self.session.config[self.authResult?.method]?.enabled && !(task instanceof TwoFactorResetTask)
            visible: active
            sourceComponent: Label {
                text: {
                    if (self.authResult?.method === 'gauth') return qsTrId('id_authenticator_app')
                    return self.session.config[self.authResult?.method]?.data
                }
                color: constants.c100
                font.pixelSize: 14
            }
        }
        PinView {
            Layout.alignment: Qt.AlignCenter
            id: keypad
            label: qsTrId('id_please_provide_your_1s_code').arg(self.authResult?.method ?? '')
            focus: true
            onPinEntered: pin => task.resolveCode(pin)
            Connections {
                target: task
                function onUpdated() { keypad.clear() }
            }
        }
        Loader {
            Layout.alignment: Qt.AlignCenter
            active: self.authResult?.method !== 'gauth'
            visible: active
            opacity: (self.authResult?.attempts_remaining ?? 3) < 3 ? 1 : 0
            sourceComponent: Label {
                text: qsTrId('id_attempts_remaining_d').arg(self.authResult?.attempts_remaining ?? 0)
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
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Label.Wrap
            text: UtilJS.formatError(self.authResult?.error ?? '')
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
