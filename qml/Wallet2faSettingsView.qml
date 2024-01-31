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
                // enabled: !self.context.locked
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
                                color: Qt.lighter('#222226', button.hovered ? 1.2 : 1)
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
                title: qsTrId('id_set_twofactor_threshold')
                // enabled: !self.context.locked
                visible: !view.network.liquid && !!view.session.config.limits
                contentItem: RowLayout {
                    Label {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: qsTrId('id_set_a_limit_to_spend_without')
                        wrapMode: Text.WordWrap
                    }
                    GButton {
                        large: false
                        text: qsTrId('id_change')
                        onClicked: set_twofactor_threshold_dialog.createObject(stack_view).open()
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            SettingsBox {
                title: qsTrId('id_twofactor_authentication_expiry')
                visible: !wallet.network.liquid
                contentItem: RowLayout {
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_customize_2fa_expiration_of')
                        wrapMode: Text.WordWrap
                    }
                    GButton {
                        Layout.alignment: Qt.AlignRight
                        large: false
                        text: qsTrId('id_change')
                        onClicked: two_factor_auth_expiry_dialog.createObject(stack_view).open()
                    }
                }
            }

            SettingsBox {
                title: qsTrId('id_request_twofactor_reset')
                contentItem: RowLayout {
                    Label {
                        Layout.fillWidth: true
                        // text: self.context.locked ? qsTrId('wallet locked for %1 days').arg(view.session.config.twofactor_reset ? view.session.config.twofactor_reset.days_remaining : 0) : qsTrId('id_start_a_2fa_reset_process_if')
                        text: 'TODO'
                        wrapMode: Text.WordWrap
                    }
                    GButton {
                        large: false
                        Layout.alignment: Qt.AlignRight
                        enabled: view.session.config.any_enabled || false
                        // text: self.context.locked ? qsTrId('id_cancel_twofactor_reset') : qsTrId('id_reset')
                        text: 'TODO'
                        Component {
                            id: cancel_dialog
                            CancelTwoFactorResetDialog { }
                        }

                        Component {
                            id: request_dialog
                            RequestTwoFactorResetDialog {
                            }
                        }
    //                    onClicked: {
    //                        if (self.context.locked) {
    //                            cancel_dialog.createObject(stack_view, { wallet }).open()
    //                        } else {
    //                            request_dialog.createObject(stack_view, { wallet }).open()
    //                        }
    //                    }
                    }
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: enable_view
        StackViewPage {
            required property Session session
            required property string method
            id: xxx
            title: session.network.displayName + ' ' + xxx.method
            contentItem: Item {
            }
        }
    }

    Component {
        id: enable_dialog
        TwoFactorEnableDialog {
        }
    }

    Component {
        id: disable_dialog
        TwoFactorDisableDialog {
        }
    }

    Component {
        id: set_twofactor_threshold_dialog
        TwoFactorLimitDialog {
//            wallet: self.wallet
//            session: self.session
        }
    }

    Component {
        id: two_factor_auth_expiry_dialog
        TwoFactorAuthExpiryDialog {
//            wallet: self.wallet
//            session: self.session
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
                border.color: '#00B45A'
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
