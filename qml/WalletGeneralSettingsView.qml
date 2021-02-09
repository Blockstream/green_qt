import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ColumnLayout {
    id: self
    required property Wallet wallet
    property string title: qsTrId('id_general')

    spacing: 8

    Controller {
        id: controller
        wallet: self.wallet
    }

    readonly property var per_currency: {
        const result = {}
        if (self.wallet.currencies) {
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

    RowLayout {
        Image {
            source: 'qrc:/svg/preferences.svg'
            sourceSize.height: 16
        }
        Label {
            Layout.fillWidth: true
            text: 'General'
            font.pixelSize: 20
            font.styleName: 'Light'
        }
        ToolButton {
            flat: true
            icon.source: 'qrc:/svg/cancel.svg'
            icon.width: 16
            icon.height: 16
        }
    }
    SettingsBox {
        Layout.fillWidth: true
        title: qsTrId('id_bitcoin_denomination')
        enabled: !wallet.locked
        contentItem: RowLayout {
            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: contentWidth
                text: qsTrId('id_show_bitcoin_amounts_in')
            }
            ComboBox {
                //Layout.fillWidth: true
                //Layout.mini
                flat: true
//                width: 200
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
                ComboBox {
                    id: currency_combo
                    Layout.fillWidth: true
                    flat: true
                    width: 200
                    model: Object.keys(per_currency).sort()
                    currentIndex: model.indexOf(self.wallet.settings.pricing ? self.wallet.settings.pricing.currency : '')
                    onCurrentTextChanged: {
                        if (!focus) return
                        const currency = currentText
                        if (currency === '') return
                        if (currency === self.wallet.settings.pricing.currency) return
                        const pricing = { currency }
                        if (per_currency[currency].indexOf(wallet.settings.pricing.exchange) < 0) {
                            pricing.exchange = per_currency[currentText][0]
                        }
                        controller.changeSettings({ pricing })
                    }
                }
                ComboBox {
                    id: exchange_combo
                    Layout.fillWidth: true
                    flat: true
                    width: 200
                    model: currency_combo.currentText ? per_currency[currency_combo.currentText].sort() : []
                    currentIndex: Math.max(0, model.indexOf(self.wallet.settings.pricing.exchange))
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
        contentItem: RowLayout {
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
