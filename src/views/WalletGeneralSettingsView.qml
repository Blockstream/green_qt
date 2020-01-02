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
        title: qsTr('id_currency')
        description: qsTr('id_select_a_fiat_currency_and')

        GridLayout {
            columns: 2
            Layout.alignment: Qt.AlignRight

            Label {
                text: qsTr('id_reference_exchange_rate')
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
                    flat: true
                    width: 200
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
                text: qsTr('id_show_bitcoin_amounts_in')
            }

            ComboBox {
                flat: true
                width: 200
                model: ['BTC', 'mBTC', '\u00B5BTC', 'bits', 'sats']
                currentIndex: model.indexOf(wallet.settings.unit)
                onCurrentTextChanged: {
                    if (currentText === '') return
                    if (currentText === wallet.settings.unit) return
                    controller.change({ unit: currentText })
                }
            }
        }
    }

    SettingsBox {
        title: 'Notifications'
        description: qsTr('id_receive_email_notifications_for')


        GridLayout {
            columns: 2
            Label {
                text: qsTr('id_received')
            }

            Switch {
                checked: wallet.settings.notifications.email_incoming
            }

            Label {
                text: qsTr('id_sent')
            }

            Switch {
                checked: wallet.settings.notifications.email_outgoing
            }
        }
    }
}
