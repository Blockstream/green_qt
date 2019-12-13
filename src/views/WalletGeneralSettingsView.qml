import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ColumnLayout {
    spacing: 30

    SettingsController {
        id: controller
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
        title: 'Currency'
        subtitle: 'Select your currency and pricing source'

        GridLayout {
            columns: 2

            Label {
                text: qsTr('id_reference_exchange_rate')
            }

            RowLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: currency_combo
                    flat: true
                    model: Object.keys(per_currency).sort()
                    currentIndex: model.indexOf(wallet.settings.pricing.currency)
                    onCurrentTextChanged: {
                        if (currentText === '') return
                        if (currentText === wallet.settings.pricing.currency) return
                        if (per_currency[currentText].indexOf(wallet.settings.pricing.exchange) < 0) return
                        controller.change({ pricing: { currency: currentText } })
                    }

                    Layout.fillWidth: true
                }

                ComboBox {
                    flat: true
                    model: per_currency[currency_combo.currentText].sort()
                    currentIndex: Math.max(0, model.indexOf(wallet.settings.pricing.exchange))
                    onCurrentTextChanged: {
                        if (currentText === '') return
                        if (currentText === wallet.settings.pricing.exchange) return
                        controller.change({ pricing: { currency: currency_combo.currentText, exchange: currentText } })
                    }
                    Layout.minimumWidth: 150
                }
            }

            Label {
                text: 'Show amounts in'
            }

            ComboBox {
                flat: true
                model: ['BTC', 'mBTC', '\u00B5BTC', 'bits', 'sats']
                currentIndex: model.indexOf(wallet.settings.unit)
                onCurrentTextChanged: {
                    if (currentText === '') return
                    if (currentText === wallet.settings.unit) return
                    controller.change({ unit: currentText })
                }
                Layout.fillWidth: true
            }
        }
    }

    SettingsBox {
        title: 'Notifications'
        subtitle: 'Notifications allow for improved security when configured for outgoing and for most up to date information when configuring for incoming'
        GridLayout {
            columns: 2
            Label {
                text: 'Incoming transactions'
            }

            Switch {
                checked: wallet.settings.notifications.email_incoming
            }

            Label {
                text: 'Outgoing transactions'
            }

            Switch {
                checked: wallet.settings.notifications.email_outgoing
            }
        }
    }
}
