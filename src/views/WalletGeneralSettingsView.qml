import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12
import '..'

ColumnLayout {
    spacing: 30

    function getCurrentIndex(blocks, model, prop) {
        for(var i = 0; i < model.count; i++) {
            if(blocks === model.get(i)[prop])
                return i;
        }
        return 0;
    }

    SettingsBox {
        title: 'Currency'
        subtitle: 'Select your currency and pricing source'

        GridLayout {
            columns: 2

            Label {
                text: 'Pricing source to use'
            }

            ComboBox {
                currentIndex: getCurrentIndex("%1 from %2".arg(wallet.settings.pricing.currency).arg(wallet.settings.pricing.exchange), sourceModel, "text")
                textRole: 'text'
                model: ListModel {
                    id: sourceModel
                    Component.onCompleted: {
                        for(var exchange in wallet.currencies.per_exchange) {
                            for(var currency of wallet.currencies.per_exchange[exchange]) {
                                append({"text": "%1 from %2".arg(currency).arg(exchange)})
                            }
                        }
                    }
                }
                width: 200
                padding: 10
            }

            Label {
                text: 'Show amounts in'
            }

            ComboBox {
                currentIndex: getCurrentIndex(wallet.settings.unit, unitModel, "text")
                textRole: 'text'
                model: ListModel {
                    id: unitModel

                    ListElement {
                        text: "BTC"
                        value: 100000000
                    }

                    ListElement {
                        text: "mBTC"
                        value: 100000
                    }

                    ListElement {
                        text: "μBTC"
                        value: 100
                    }

                    ListElement {
                        text: "sats"
                        value: 1
                    }
                }
                width: 200
                padding: 10
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
