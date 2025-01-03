import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

QtObject {
    signal closed()
    required property TaskGroupMonitor monitor
    required property StackView target
    readonly property Task task: {
        if (!self.monitor) return null
        const groups = self.monitor.groups
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i]
            const tasks = group.tasks
            for (let j = 0; j < tasks.length; j++) {
                const task = tasks[j]
                if (task.status !== Task.Active) continue
                return task
            }
        }
        return null
    }
    readonly property Resolver resolver: self.task?.resolver ?? null
    readonly property Prompt prompt: self.task?.prompt ?? null
    readonly property JadeGetMasterBlindingKeyActivity activity: {
        if (!self.monitor) return null
        const groups = self.monitor.groups
        for (let i = 0; i < groups.length; i++) {
            const group = groups[i]
            const tasks = group.tasks
            for (let j = 0; j < tasks.length; j++) {
                const task = tasks[j]
                if (task.status !== Task.Active) continue
                const activity = task.resolver?.activity
                if (activity instanceof JadeGetMasterBlindingKeyActivity) {
                    if (activity.ask) {
                        return activity
                    }
                }
            }
        }
        return null
    }
    property string title: ''

    onActivityChanged: {
        if (self.activity) {
            self.target.push(jade_get_master_blinding_key_dialog, { activity: self.activity })
        }
    }

    function push(page, props) {
        // TODO: pushed pages should have an attribute to better check
        // if replace should be called instead of push
        if (self.target.currentItem?.prompt) {
            self.target.replace(page, props, StackView.PushTransition)
        } else {
            self.target.push(page, props)
        }
    }

    id: self
    onPromptChanged: {
        const prompt = self.prompt
        if (prompt instanceof CodePrompt) {
            const status = prompt.result.status
            if (status === 'request_code') {
                const methods = prompt.result.methods
                self.push(method_view, { prompt, methods })
            } else if (status === 'resolve_code') {
                self.push(code_view, { prompt })
            }
            return
        }
        if (prompt instanceof DevicePrompt) {
            self.target.push(device_prompt_view, { context: self.task.session.context, prompt })
            return
        }
    }
    onResolverChanged: {
        const resolver = self.resolver
        if (!resolver) return
        if (resolver.device instanceof JadeDevice) {
            if (resolver instanceof SignMessageResolver) {
                const { message, path } = resolver.result.required_data
                if (message.length === 32 &&
                    message.startsWith('greenaddress.it      login ') &&
                    path.length === 1 &&
                    path[0] === 0x4741b11e) {
                    console.log('ignore sign message for login challenge')
                    return
                }

                self.target.push(jade_sign_message_view, { resolver })
                return
            }
            if (resolver instanceof SignTransactionResolver) {
                self.target.push(jade_sign_transaction_view, { resolver })
                return
            }
            if (resolver instanceof SignLiquidTransactionResolver) {
                self.target.push(jade_sign_liquid_transaction_view, { resolver })
                return
            }
        }
    }

    property Component device_prompt_view: DevicePromptView {
    }

    property Component method_view: StackViewPage {
        required property CodePrompt prompt
        required property var methods
        Connections {
            target: view.prompt
            function onResultChanged() {
                const prompt = view.prompt
                const status = prompt.result.status
                if (status === 'resolve_code') {
                    self.target.replace(code_view, { prompt }, StackView.PushTransition)
                }
            }
        }
        id: view
        title: self.title
        contentItem: ColumnLayout {
            spacing: 10
            VSpacer {
            }
            MultiImage {
                Layout.alignment: Qt.AlignCenter
                foreground: 'qrc:/png/2fa.png'
                width: 280
                height: 160
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.bottomMargin: 36
                horizontalAlignment: Qt.AlignHCenter
                font.pixelSize: 20
                font.weight: 800
                text: qsTrId('id_choose_method_to_authorize_the')
            }
            Repeater {
                model: view.methods
                delegate: AbstractButton {
                    property string method: modelData
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    id: delegate
                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 15
                    bottomPadding: 15
                    background: Rectangle {
                        color: Qt.lighter('#222226', delegate.hovered ? 1.2 : 1)
                        radius: 5
                    }
                    contentItem: RowLayout {
                        ColumnLayout {
                            Label {
                                Layout.fillWidth: true
                                color: '#FFF'
                                font.pixelSize: 14
                                font.weight: 500
                                text: UtilJS.twoFactorMethodLabel(method)
                            }
                            Label {
                                text: view.prompt.task.session.config[delegate.method].data
                                opacity: 0.6
                            }
                        }
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/next_arrow.svg'
                        }
                    }
                    onClicked: view.prompt.select(delegate.method)
                }
            }
            VSpacer {
            }
        }
    }

    property Component code_view: StackViewPage {
        required property CodePrompt prompt
        StackView.onActivated: {
            pin_field.enable()
            pin_field.clear()
            pin_field.forceActiveFocus()
        }
        Connections {
            target: view.prompt
            function onInvalidCode() {
                pin_field.enable()
                pin_field.clear()
                pin_field.forceActiveFocus()
                error_badge.error = 'id_invalid_twofactor_code'
            }
        }
        id: view
        title: self.title
        contentItem: ColumnLayout {
            VSpacer {
            }
            MultiImage {
                Layout.alignment: Qt.AlignCenter
                foreground: `qrc:/png/2fa_${view.prompt.result.method}.png`
                width: 280
                height: 160
                visible: !(view.prompt.task instanceof ChangeTwoFactorTask)
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: {
                    const label = UtilJS.twoFactorMethodLabel(view.prompt.result.method)
                    return qsTrId('id_please_provide_your_1s_code').arg(label)
                }
                font.pixelSize: 20
                font.weight: 800
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                Layout.maximumWidth: 250
                color: '#9A9A9A'
                font.pixelSize: 12
                font.weight: 600
                horizontalAlignment: Label.AlignHCenter
                text: qsTrId('id_to_authorize_the_transaction')
                visible: !(view.prompt.task instanceof ChangeTwoFactorTask)
                wrapMode: Label.WordWrap
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: view.prompt.task instanceof TwoFactorResetTask
                visible: active
                sourceComponent: Label {
                    text: view.prompt.task.email
                    color: constants.c100
                    font.pixelSize: 14
                }
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: {
                    const task = view.prompt.task
                    if (task instanceof TwoFactorResetTask) return false
                    const method = view.prompt.result.method
                    if (method === 'gauth') return false
                    return task.session.config[method].enabled
                }
                visible: active
                sourceComponent: Label {
                    text: {
                        const method = view.prompt.result.method
                        if (method === 'gauth') return qsTrId('id_authenticator_app')
                        return view.prompt.task.session.config[method].data
                    }
                    color: constants.c100
                    font.pixelSize: 14
                }
            }
            PinField {
                Layout.alignment: Qt.AlignCenter
                Layout.topMargin: 36
                Layout.bottomMargin: 20
                id: pin_field
                focus: true
                onPinChanged: error_badge.error = undefined
                onPinEntered: pin => {
                    view.prompt.resolve(pin)
                    pin_field.disable()
                }
            }
            FixedErrorBadge {
                Layout.alignment: Qt.AlignCenter
                Layout.bottomMargin: 20
                id: error_badge
            }
            PinPadButton {
                Layout.alignment: Qt.AlignCenter
                enabled: pin_field.enabled
                target: pin_field
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: view.prompt.result.method === 'telegram'
                visible: active
                sourceComponent: RowLayout {
                    readonly property url browser: view.prompt.result.auth_data.telegram_url
                    readonly property url app: view.prompt.result.auth_data.telegram_url.replace('https://t.me/', 'tg://resolve?domain=').replace('?start=', '&start=')
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
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: view.prompt.result.method !== 'gauth' && view.prompt.result.method !== 'telegram'
                visible: active
                opacity: view.prompt.result.attempts_remaining < 3 ? 1 : 0
                sourceComponent: Label {
                    text: qsTrId('id_attempts_remaining_d').arg(view.prompt.result.attempts_remaining)
                }
            }
            VSpacer {
            }
        }
    }

    property Component jade_sign_message_view: JadeSignMessageView {
        onFailed: self.target.pop()
        onSigned: self.target.pop()
    }
    property Component jade_sign_transaction_view: JadeSignTransactionView {
        onClosed: self.closed()
    }
    property Component jade_sign_liquid_transaction_view: JadeSignLiquidTransactionView {
        onClosed: self.closed()
    }
    property Component jade_get_master_blinding_key_dialog: JadeGetMasterBlindingKeyView {
    }

    /* TODO: refactor after ledger
    property Component jade_connect_view: ConnectJadePage {
        required property DeviceResolver resolver
        onDeviceSelected: (device) => self.target.push(jade_page, { device })
        padding: 0
        rightItem: Item {}
        footer: Item {}
    }
    */
}
