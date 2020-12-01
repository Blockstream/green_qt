import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: view
    required property Wallet wallet
    property string title: qsTrId('id_general')

    spacing: 30

    Controller {
        id: controller
        wallet: view.wallet
    }

    property var per_currency: {
        const result = {}
        for (const [exchange, currencies] of Object.entries(wallet.currencies.per_exchange)) {
            for (const currency of currencies) {
                if (currency in result) {
                    result[currency].push(exchange)
                } else {
                    result[currency] = [exchange]
                }
            }
        }
        return result
    }

    SettingsBox {
        Layout.fillWidth: true
        title: qsTrId('id_bitcoin_denomination')
        enabled: !wallet.locked
        RowLayout {
            anchors.fill: parent
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_show_bitcoin_amounts_in')
            }
            ComboBox {
                flat: true
                width: 200
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
        ColumnLayout {
            anchors.fill: parent
            Label {
                Layout.fillWidth: true
                text: qsTrId('id_select_a_fiat_currency_and') // TODO: update string
                wrapMode: Label.WordWrap
            }
            RowLayout {
                Label {
                    Layout.fillWidth: true
                    Layout.minimumWidth: contentWidth
                    text: qsTrId('id_reference_exchange_rate')
                }
                ComboBox {
                    id: currency_combo
                    flat: true
                    width: 200
                    model: Object.keys(per_currency).sort()
                    currentIndex: model.indexOf(wallet.settings.pricing.currency)
                    onCurrentTextChanged: {
                        if (!focus) return
                        const currency = currentText
                        if (currency === '') return
                        if (currency === wallet.settings.pricing.currency) return
                        const pricing = { currency }
                        if (per_currency[currency].indexOf(wallet.settings.pricing.exchange) < 0) {
                            pricing.exchange = per_currency[currentText][0]
                        }
                        controller.changeSettings({ pricing })
                    }
                }
                ComboBox {
                    id: exchange_combo
                    flat: true
                    width: 200
                    model: currency_combo.currentText ? per_currency[currency_combo.currentText].sort() : []
                    currentIndex: Math.max(0, model.indexOf(wallet.settings.pricing.exchange))
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

    SettingsBox {
        title: qsTrId('id_notifications')
        enabled: !wallet.locked && wallet.config.email.confirmed
        RowLayout {
            anchors.fill: parent
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_receive_email_notifications_for')
            }
            Switch {
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
