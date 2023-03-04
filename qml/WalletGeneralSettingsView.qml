import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

ColumnLayout {
    required property Wallet wallet
    readonly property var per_currency: {
        const result = {}
        if (self.wallet.currencies && self.wallet.currencies.per_exchange) {
            for (const [exchange, currencies] of Object.entries(self.wallet.currencies.per_exchange)) {
                for (const currency of currencies) {
                    if (currency in result) {
                        result[currency].push(exchange)
                    } else {
                        result[currency] = [exchange]
                    }
                }
            }
        }
        return result
    }

    id: self
    spacing: constants.p2

    Controller {
        id: controller
        wallet: self.wallet
    }

    SettingsBox {
        Layout.fillWidth: true
        title: qsTrId('id_bitcoin_denomination')
        enabled: !wallet.locked
        contentItem: RowLayout {
            spacing: constants.s1
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_show_bitcoin_amounts_in')
            }
            GComboBox {
                property var units: ['BTC', 'mBTC', '\u00B5BTC', 'bits', 'sats']
                model: units.map(unit => ({
                    text: wallet.getDisplayUnit(unit),
                    value: unit
                }))
                textRole: 'text'
                valueRole: 'value'
                currentIndex: units.indexOf(wallet.settings.unit)
                onCurrentValueChanged: {
                    if (currentValue === '') return
                    if (currentValue === wallet.settings.unit) return
                    controller.changeSettings({ unit: currentValue })
                }
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_currency')
        enabled: !wallet.locked
        contentItem: ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_select_a_fiat_currency_and') // TODO: update string
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_reference_exchange_rate')
            }
            RowLayout {
                spacing: constants.s1
                GComboBox {
                    id: currency_combo
                    Layout.fillWidth: true
                    width: 200
                    model: Object.keys(self.per_currency).sort()
                    currentIndex: model.indexOf(self.wallet.settings.pricing ? self.wallet.settings.pricing.currency : '')
                    onCurrentTextChanged: {
                        if (!focus) return
                        const currency = currentText
                        if (currency === '') return
                        if (currency === self.wallet.settings.pricing.currency) return
                        const pricing = { currency }
                        if (self.per_currency[currency].indexOf(wallet.settings.pricing.exchange) < 0) {
                            pricing.exchange = self.per_currency[currentText][0]
                        }
                        controller.changeSettings({ pricing })
                    }
                }
                HSpacer {
                }
                GComboBox {
                    id: exchange_combo
                    Layout.fillWidth: true
                    width: 200
                    model: currency_combo.currentText ? per_currency[currency_combo.currentText].sort() : []
                    currentIndex: self.wallet.settings.pricing ? Math.max(0, model.indexOf(self.wallet.settings.pricing.exchange)) : 0
                    onCurrentTextChanged: {
                        if (!focus) return
                        const exchange = currentText
                        if (exchange === '') return
                        if (exchange === wallet.settings.pricing.exchange) return
                        controller.changeSettings({ pricing: { exchange } })
                    }
                    Layout.minimumWidth: 150
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !wallet.network.electrum
        visible: active
        sourceComponent: SettingsBox {
            enabled: !wallet.locked
            title: qsTrId('id_watchonly_login')
            contentItem: ColumnLayout {
                Layout.fillHeight: false

                Pane {
                    padding: 0
                    Layout.fillWidth: true
                    background: null
                    contentItem: RowLayout {
                        Layout.fillHeight: false
                        spacing: constants.p0
                        GTextField {
                            id: username_field
                            text: wallet.username
                            placeholderText: qsTrId('id_username')
                            validator: FieldValidator {
                            }
                            Check {
                                checked: username_field.acceptableInput
                            }
                        }
                        GTextField {
                            id: password_field
                            echoMode: TextField.Password
                            placeholderText: qsTrId('id_password')
                            validator: FieldValidator {
                            }
                            Check {
                                checked: password_field.acceptableInput
                            }
                        }
                        GButton {
                            large: false
                            text: qsTrId('id_update')
                            enabled: username_field.acceptableInput && password_field.acceptableInput
                            onClicked: {
                                wallet.setWatchOnly(username_field.text, password_field.text)
                                password_field.clear();
                            }
                        }
                        GButton {
                            large: false
                            enabled: wallet.username.length > 0
                            text: qsTrId('id_delete')
                            onClicked: wallet.clearWatchOnly()
                        }
                    }
                }

                Label {
                    text: "Username and password should have 8 characters or more"
                    font.pixelSize: 12
                    color: constants.c50
                }
            }
        }

        Connections {
            target: wallet
            function onWatchOnlyUpdateSuccess() {
                const dialog = message_dialog.createObject(window, {
                  title: qsTrId('id_success'),
                  message: 'Watch-only credentials updated successfully.',
                })
                dialog.open()
            }
            function onWatchOnlyUpdateFailure() {
                const dialog = message_dialog.createObject(window, {
                    title: qsTrId('id_warning'),
                    message: 'Failed to set new watch-only credentials.',
                })
                dialog.open()
            }
        }

        Component {
            id: message_dialog
            MessageDialog {
                id: dialog
                wallet: self.wallet
                width: 350
                actions: [
                    Action {
                        text: qsTrId('id_ok')
                        onTriggered: dialog.reject()
                    }
                ]
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !wallet.network.electrum && !!wallet.config.email
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_notifications')
            enabled: !wallet.locked && !!wallet.config.email && wallet.config.email.confirmed
            contentItem: ColumnLayout {
                RowLayout {
                    Label {
                        Layout.fillWidth: true
                        Layout.minimumWidth: contentWidth
                        text: qsTrId('id_receive_email_notifications_for')
                    }
                    GSwitch {
                        Binding on checked {
                            value: wallet.settings.notifications ? (wallet.settings.notifications.email_outgoing && wallet.settings.notifications.email_outgoing) : false
                        }
                        onClicked: {
                            checked = wallet.settings.notifications.email_outgoing;
                            controller.changeSettings({
                                notifications: {
                                    email_incoming: !checked,
                                    email_outgoing: !checked
                                }
                            });
                        }
                    }
                }
                Pane {
                    Layout.fillWidth: true
                    visible: wallet.config.email.confirmed
                    background: Rectangle {
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)
                        radius: 8
                        color: 'transparent'
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        Label {
                            Layout.fillWidth: true
                            text: qsTrId('id_email_address')
                            font.styleName: 'Regular'
                            font.capitalization: Font.Capitalize
                        }
                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Label.AlignRight
                            text: wallet.config.email.data
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    Loader {
        Layout.fillWidth: true
        active: !wallet.network.electrum
        visible: active
        sourceComponent: SettingsBox {
            title: qsTrId('id_support')
            contentItem: AccountIdBadge {
                amp: false
                account: wallet.accounts[0] ?? null
            }
        }
    }

    component FieldValidator : RegularExpressionValidator {
        regularExpression: /^.{8,}$/
    }

    component Check : Image {
        property bool checked: false

        id: self
        source: 'qrc:/svg/check.svg'
        width: 16
        height: 16
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 8

        Desaturate {
            visible: !checked
            anchors.fill: self
            source: self
            desaturation: 1
        }
    }
}
