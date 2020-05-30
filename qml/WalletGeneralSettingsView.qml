import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    property string title: qsTrId('id_general')

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
        title: qsTrId('id_bitcoin_denomination')
        description: qsTrId('id_show_bitcoin_amounts_in')
        enabled: !wallet.locked

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
                controller.change({ unit: currentValue })
            }
        }
    }

    SettingsBox {
        title: qsTrId('id_currency')
        description: qsTrId('id_select_a_fiat_currency_and') // TODO: update string
        enabled: !wallet.locked

        GridLayout {
            columns: 2
            Layout.alignment: Qt.AlignRight

            Label {
                text: qsTrId('id_reference_exchange_rate')
            }

            RowLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: currency_combo
                    flat: true
                    width: 200
                    model: Object.keys(per_currency).sort()
                    currentIndex: model.indexOf(wallet.settings.pricing.currency)
                    onCurrentTextChanged: {
                        if (currentText === '') return
                        if (currentText === wallet.settings.pricing.currency) return
                        if (per_currency[currentText].indexOf(wallet.settings.pricing.exchange) < 0) return
                        controller.change({ pricing: { currency: currentText } })
                    }

                    //Layout.fillWidth: true
                }

                ComboBox {
                    id: exchange_combo
                    flat: true
                    width: 200
                    model: currency_combo.currentText ? per_currency[currency_combo.currentText].sort() : []
                    currentIndex: Math.max(0, model.indexOf(wallet.settings.pricing.exchange))
                    onCurrentTextChanged: {
                        if (!focus) return
                        if (currentText === '') return
                        if (currentText === wallet.settings.pricing.exchange) return
                        controller.change({ pricing: { currency: currency_combo.currentText, exchange: currentText } })
                    }
                    Layout.minimumWidth: 150
                }
            }
        }
    }

    SettingsBox {
        title: 'Notifications'
        description: qsTrId('id_receive_email_notifications_for')
        enabled: !wallet.locked && wallet.config.email.confirmed

        Switch {
            Binding on checked {
                value: wallet.settings.notifications ? (wallet.settings.notifications.email_outgoing && wallet.settings.notifications.email_outgoing) : false
            }
            onClicked: {
                checked = wallet.settings.notifications.email_outgoing;
                controller.change({
                    notifications: {
                        email_incoming: !checked,
                        email_outgoing: !checked
                    }
                });
            }
        }
    }
}
