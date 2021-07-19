import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

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
    spacing: constants.p3

    Controller {
        id: controller
        wallet: self.wallet
    }

    SettingsBox {
        Layout.fillWidth: true
        title: qsTrId('id_bitcoin_denomination')
        enabled: !wallet.locked
        contentItem: RowLayout {
            spacing: constants.p1
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_show_bitcoin_amounts_in')
            }
            GComboBox {
                property var units: ['BTC', 'mBTC', '\u00B5BTC', 'bits', 'sats']
                model: units.map(unit => ({
                    text: wallet.network.liquid ? `L-${unit}` : unit,
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
                wrapMode: Label.WordWrap
            }
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_reference_exchange_rate')
            }
            RowLayout {
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
        active: !wallet.network.liquid && !wallet.network.electrum
        visible: active
        sourceComponent: SettingsBox {
            enabled: !wallet.locked
            title: qsTrId('id_watchonly_login')
            contentItem: RowLayout {
                spacing: 16
                GTextField {
                    id: username_field
                    text: wallet.username
                    placeholderText: qsTrId('id_username')
                }
                GTextField {
                    id: password_field
                    echoMode: TextField.Password
                    placeholderText: qsTrId('id_password')
                }
                HSpacer {
                }
                GButton {
                    large: false
                    text: qsTrId('id_update')
                    enabled: password_field.text !== ''
                    onClicked: {
                        wallet.setWatchOnly(username_field.text, password_field.text)
                        password_field.clear();
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
            title: qsTrId('id_notifications')
            enabled: !wallet.locked && !!wallet.config.email && wallet.config.email.confirmed
            contentItem: RowLayout {
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
        }
    }
}
