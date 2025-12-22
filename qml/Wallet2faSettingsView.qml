import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Page {
    required property Context context
    required property list<Session> sessions
    readonly property Wallet wallet: context.wallet

    id: self
    background: null
    padding: 0
    verticalPadding: 20
    header: RowLayout {
        SessionSelector {
            id: selector
            sessions: self.sessions
        }
    }
    contentItem: GStackLayout {
        currentIndex: selector.currentIndex
        Repeater {
            model: self.sessions
            delegate: View {
                required property var modelData
                session: modelData
                network: modelData.network
            }
        }
    }

    component View: Flickable {
        required property Session session
        required property Network network
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: view
        clip: true
        contentWidth: view.width
        contentHeight: layout.height
        Controller {
            id: controller
            context: self.context
        }
        ColumnLayout {
            id: layout
            spacing: 16
            width: view.width
            SettingsBox {
                title: qsTrId('id_twofactor_authentication')
                enabled: !(view.session.config.twofactor_reset?.is_active ?? false)
                contentItem: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_enable_twofactor_authentication')
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        opacity: 0.6
                        text: qsTrId('id_tip_we_recommend_you_enable')
                        wrapMode: Text.WordWrap
                    }
                    Repeater {
                        model: {
                            const methods = view.session.config.all_methods || []
                            return methods.filter(method => {
                                switch (method) {
                                    case 'email': return true
                                    case 'sms': return true
                                    case 'phone': return true
                                    case 'gauth': return true
                                    case 'telegram': return true
                                    default: return false
                                }
                            })
                        }
                        delegate: AbstractButton {
                            required property var modelData
                            property string method: modelData
                            Layout.fillWidth: true
                            id: button
                            leftPadding: 20
                            rightPadding: 20
                            topPadding: 10
                            bottomPadding: 10
                            background: Rectangle {
                                radius: 5
                                color: Qt.lighter('#262626', button.hovered ? 1.2 : 1)
                            }
                            contentItem: RowLayout {
                                ColumnLayout {
                                    Label {
                                        Layout.fillWidth: true
                                        text: UtilJS.twoFactorMethodLabel(button.method)
                                    }
                                    Label {
                                        color: constants.c100
                                        font.pixelSize: 10
                                        font.weight: 400
                                        text: {
                                            if (!view.session.config[button.method].enabled) return qsTrId('id_disabled')
                                            if (button.method === 'gauth') return qsTrId('id_enabled')
                                            return view.session.config[button.method].data
                                        }
                                    }
                                }
                                GSwitch {
                                    opacity: 1
                                    enabled: false
                                    checked: view.session.config[method].enabled
                                }
                            }
                            onClicked: {
                                const enabled = view.session.config[modelData].enabled
                                const dialog = (enabled ? disable_dialog : enable_dialog).createObject(view, {
                                    context: self.context,
                                    session: view.session,
                                    method,
                                })
                                dialog.open();
                            }
                        }
                    }
                }
            }

            SettingsBox {
                title: qsTrId('id_2fa_threshold')
                enabled: !(view.session.config.twofactor_reset?.is_active ?? false)
                visible: !view.network.liquid && !!view.session.config.limits
                contentItem: AbstractButton {
                    id: button
                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 15
                    bottomPadding: 15
                    background: Rectangle {
                        radius: 5
                        color: Qt.lighter('#262626', button.hovered ? 1.2 : 1)
                    }
                    contentItem: RowLayout {
                        ColumnLayout {
                            spacing: 10
                            Label {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                font.pixelSize: 14
                                font.weight: 600
                                text: qsTrId('id_set_twofactor_threshold')
                                wrapMode: Text.WordWrap
                            }
                            Convert {
                                id: limit_convert
                                context: self.context
                                account: view.session.context.getOrCreateAccount(view.session.network, 0)
                                input: {
                                    if (view.session.config.limits?.is_fiat ?? false) {
                                        return { fiat: view.session.config.limits.fiat }
                                    } else {
                                        return { satoshi: view.session.config.limits?.satoshi ?? 0 }
                                    }
                                }
                                unit: view.session.unit
                            }
                            RowLayout {
                                Label {
                                    text: limit_convert.output.label
                                    font.pixelSize: 14
                                    font.weight: 500
                                }
                                Label {
                                    color: '#6F6F6F'
                                    font.pixelSize: 14
                                    font.weight: 500
                                    text: '~ ' + limit_convert.fiat.label
                                    visible: limit_convert.fiat.available
                                }
                            }
                        }
                        RightArrowIndicator {
                            active: true
                        }
                    }
                    onClicked: {
                        const drawer = set_twofactor_threshold_drawer.createObject(view, {
                            session: view.session,
                        })
                        drawer.open()
                    }
                }
            }

            SettingsBox {
                title: qsTrId('id_twofactor_authentication_expiry')
                visible: !view.session.network.liquid
                contentItem: AbstractButton {
                    id: button3
                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 15
                    bottomPadding: 15
                    background: Rectangle {
                        radius: 5
                        color: Qt.lighter('#262626', button3.hovered ? 1.2 : 1)
                    }
                    contentItem: RowLayout {
                        ColumnLayout {
                            spacing: 10
                            Label {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                font.pixelSize: 14
                                font.weight: 600
                                text: qsTrId('id_customize_2fa_expiration_of')
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                text: UtilJS.csvLabel(view.session.settings.csvtime)
                                font.pixelSize: 14
                                font.weight: 500
                            }
                        }
                        RightArrowIndicator {
                            active: button3.hovered
                        }
                    }
                    onClicked: {
                        const drawer = two_factor_auth_expiry_drawer.createObject(view, { session: view.session })
                        drawer.open()
                    }
                }
            }

            SettingsBox {
                title: qsTrId('id_request_twofactor_reset')
                contentItem: AbstractButton {
                    id: button2
                    leftPadding: 20
                    rightPadding: 20
                    topPadding: 15
                    bottomPadding: 15
                    enabled: {
                        if (view.session.config.twofactor_reset?.is_active ?? false) {
                            return true
                        } else {
                            return view.session.config.any_enabled || false
                        }
                    }
                    background: Rectangle {
                        radius: 5
                        color: Qt.lighter('#262626', button2.enabled && button2.hovered ? 1.2 : 1)
                    }
                    contentItem: RowLayout {
                        ColumnLayout {
                            spacing: 20
                            Label {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                font.pixelSize: 14
                                font.weight: 600
                                text: view.session.config.twofactor_reset?.is_active ?? false ? qsTrId('id_cancel_twofactor_reset') : qsTrId('id_reset')
                                wrapMode: Text.WordWrap
                            }
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                color: '#6F6F6F'
                                font.pixelSize: 14
                                font.weight: 500
                                text: {
                                    if (view.session.config.twofactor_reset?.is_active ?? false) {
                                        return qsTrId('id_your_wallet_is_locked_for_a').arg(view.session.config.twofactor_reset.days_remaining)
                                    } else {
                                        return qsTrId('id_start_a_2fa_reset_process_if')
                                    }
                                }
                                wrapMode: Label.WordWrap
                            }
                        }
                        RightArrowIndicator {
                            active: true
                            opacity: button2.enabled ? 1 : 0.6
                        }
                    }
                    onClicked: {
                        const locked = view.session.config.twofactor_reset?.is_active ?? false
                        const comp = locked ? cancel_drawer : request_drawer
                        const drawer = comp.createObject(view, { session: view.session })
                        drawer.open()
                    }
                }
            }
            Repeater {
                model: self.context.sessions.filter(session => !session.network.electrum && !session.network.liquid)
                delegate: SettingsBox {
                    required property var modelData
                    readonly property Session session: box.modelData
                    SessionController {
                        id: controller
                        context: self.context
                        session: box.session
                        onFailed: (error) => error_badge.raise(error)
                        onFinished: success_badge.raise('id_recovery_transaction_request')
                    }
                    id: box
                    title: 'Recovery Transactions'
                    contentItem: ColumnLayout {
                        AbstractButton {
                            Layout.fillWidth: true
                            id: button2
                            leftPadding: 20
                            rightPadding: 20
                            topPadding: 15
                            bottomPadding: 15
                            background: Rectangle {
                                radius: 5
                                color: Qt.lighter('#262626', button2.enabled && button2.hovered ? 1.2 : 1)
                            }
                            contentItem: RowLayout {
                                ColumnLayout {
                                    spacing: 20
                                    Label {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        font.pixelSize: 14
                                        font.weight: 600
                                        text: qsTrId('id_request_recovery_transactions')

                                        wrapMode: Text.WordWrap
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        color: '#6F6F6F'
                                        font.pixelSize: 14
                                        font.weight: 500
                                        text: qsTrId('id_recovery_transaction_emails') + ' ' + box.session.config.email?.data ?? 'N/A'
                                        wrapMode: Label.WordWrap
                                    }
                                }
                                RightArrowIndicator {
                                    active: true
                                    opacity: button2.enabled ? 1 : 0.6
                                    visible: controller.monitor.idle
                                }
                                ProgressIndicator {
                                    x: 10
                                    width: 24
                                    height: 24
                                    indeterminate: !controller.monitor.idle
                                    visible: !controller.monitor.idle
                                }
                            }
                            onClicked: {
                                if (controller.monitor.idle) {
                                    error_badge.clear()
                                    controller.sendRecoveryTransactions()
                                }
                            }
                        }
                        FixedErrorBadge {
                            Layout.fillWidth: true
                            id: error_badge
                        }
                        FixedErrorBadge {
                            Layout.fillWidth: true
                            id: success_badge
                            pointer: false
                            backgroundColor: '#00BCFF'
                        }
                    }
                }
            }
        }
    }

    Component {
        id: cancel_drawer
        CancelTwoFactorResetDrawer {
            context: self.context
        }
    }

    Component {
        id: request_drawer
        RequestTwoFactorResetDrawer {
            context: self.context
        }
    }

    Component {
        id: enable_dialog
        TwoFactorEnableDrawer {
        }
    }

    Component {
        id: disable_dialog
        TwoFactorDisableDrawer {
        }
    }

    Component {
        id: set_twofactor_threshold_drawer
        TwoFactorLimitDrawer {
            context: self.context
        }
    }

    Component {
        id: two_factor_auth_expiry_drawer
        TwoFactorAuthExpiryDialog {
            context: self.context
        }
    }

    component SessionSelector: Pane {
        signal sessionClicked(Session session)
        required property var sessions
        property int currentIndex: 0
        Layout.alignment: Qt.AlignCenter
        id: selector
        padding: 0
        background: Rectangle {
            border.width: 0.5
            border.color: '#313131'
            color: '#121414'
            radius: 4
        }
        contentItem: RowLayout {
            spacing: 0
            Repeater {
                model: selector.sessions
                delegate: Option {
                    id: option
                    checked: option.index === selector.currentIndex
                    onClicked: selector.currentIndex = option.index
                }
            }
        }
    }

    component Option: AbstractButton {
        required property int index
        required property var modelData
        readonly property Session session: modelData
        id: option
        implicitHeight: 35
        implicitWidth: 163
        background: Item {
            Rectangle {
                anchors.fill: parent
                visible: option.checked
                border.width: option.checked ? 1 : 0.5
                border.color: Qt.alpha('#FFF', 0.3)
                color: '#3A3A3D'
                radius: 4
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                border.width: 2
                border.color: '#00BCFF'
                color: 'transparent'
                radius: 8
                visible: option.visualFocus
            }
        }
        contentItem: Label {
            font.pixelSize: 12
            font.weight: 600
            horizontalAlignment: Label.AlignHCenter
            verticalAlignment: Label.AlignVCenter
            opacity: option.checked ? 1 : 0.3
            text: option.session.network.displayName
        }
    }

}
