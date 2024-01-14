import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

QtObject {
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

    id: self
    onPromptChanged: {
        const prompt = self.prompt
        if (prompt instanceof CodePrompt) {
            self.target.push(code_prompt_view, { prompt })
            return
        }
        if (prompt instanceof DevicePrompt) {
            self.target.push(device_prompt_view, { context: self.task.session.context, prompt })
            return
        }
    }
    onResolverChanged: {
        const resolver = self.resolver


        if (resolver instanceof SignMessageResolver && resolver.device instanceof JadeDevice) {
            self.target.push(jade_sign_message_view, { resolver })
            return
        }

        if (resolver instanceof SignTransactionResolver && resolver.device instanceof JadeDevice) {
            if (!self.item) self.item = self.target.currentItem
            self.target.push(jade_sign_transaction_view, { resolver })
            return
        }

        if (resolver instanceof SignLiquidTransactionResolver && resolver.device instanceof JadeDevice) {
            self.target.push(jade_sign_liquid_transaction_view, { resolver })
            return
        }
    }

    property Component code_prompt_view: StackViewPage {
        required property CodePrompt prompt
        function handleResult() {
            const prompt = view.prompt
            const task = prompt.task
            const status = task.result.status
            if (status === 'request_code') {
                stack_view.replace(method_view, { prompt })
            } else if (status === 'resolve_code') {
                stack_view.replace(code_view, { prompt })
            }
        }

        id: view
        title: view.prompt.task.type
        StackView.onActivating: view.handleResult()
        Connections {
            target: view.prompt.task
            function onResultChanged() {
                view.handleResult()
            }
        }
        contentItem: GStackView {
            focus: true
            id: stack_view
        }
    }

    property Component device_prompt_view: DevicePromptView {
    }

    property Component method_view: StackViewPage {
        required property CodePrompt prompt
        id: view
        contentItem: ColumnLayout {
            spacing: 10
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: 'qrc:/png/2fa.png'
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
                model: view.prompt.methods
                delegate: AbstractButton {
                    property string method: modelData
                    Layout.alignment: Qt.AlignCenter
                    Layout.minimumWidth: 325
                    id: delegate
                    padding: 20
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
                                text: {
                                    const label = {
                                        email: 'id_email',
                                        gauth: 'id_authenticator_app',
                                        phone: 'id_phone_call',
                                        sms: 'id_sms',
                                        telegram: 'id_telegram'
                                    }
                                    return qsTrId(label[method])
                                }
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
        id: view
        contentItem: ColumnLayout {
            VSpacer {
            }
            Image {
                Layout.alignment: Qt.AlignCenter
                source: `qrc:/png/2fa_${view.prompt.task.result.method}.png`
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: qsTrId('id_please_provide_your_1s_code').arg(view.prompt.task.result.method)
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
                text: 'To authorize the transaction you need to enter your 2FA code.'
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
                active: view.prompt.task.session.config[view.prompt.task.result.method].enabled && !(view.prompt.task instanceof TwoFactorResetTask)
                visible: active
                sourceComponent: Label {
                    text: {
                        if (view.prompt.task.result.method === 'gauth') return qsTrId('id_authenticator_app')
                        return view.prompt.task.session.config[view.prompt.task.result.method].data
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
                onPinEntered: pin => view.prompt.resolve(pin)
            }
            PinPadButton {
                Layout.alignment: Qt.AlignCenter
                enabled: pin_field.enabled
                target: pin_field
            }
            Loader {
                Layout.alignment: Qt.AlignCenter
                active: view.prompt.task.result.method === 'telegram'
                visible: active
                sourceComponent: RowLayout {
                    readonly property url browser: view.prompt.task.result.auth_data.telegram_url
                    readonly property url app: view.prompt.task.result.auth_data.telegram_url.replace('https://t.me/', 'tg://resolve?domain=').replace('?start=', '&start=')
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
                active: view.prompt.task.result.method !== 'gauth' && view.prompt.task.result.method !== 'telegram'
                visible: active
                opacity: view.prompt.task.result.attempts_remaining < 3 ? 1 : 0
                sourceComponent: Label {
                    text: qsTrId('id_attempts_remaining_d').arg(view.prompt.task.result.attempts_remaining)
                }
            }
            VSpacer {
            }
        }
    }

    property Component jade_sign_message_view: JadeSignMessageView {}
    property Component jade_sign_transaction_view: JadeSignTransactionView {}
    property Component jade_sign_liquid_transaction_view: JadeSignLiquidTransactionView {}

    property Component jade_connect_view: ConnectJadePage {
        required property DeviceResolver resolver
        onDeviceSelected: (device) => stack_view.push(jade_page, { device })
        padding: 0
        rightItem: Item {}
        footer: Item {}
    }
}
