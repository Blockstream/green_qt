import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Pane {
    required property Context context
    readonly property Wallet wallet: self.context.wallet
    readonly property Session session: self.context.primarySession

    readonly property var per_currency: {
        const result = {}
        const per_exchange = self.session.currencies?.per_exchange
        if (per_exchange) {
            for (const [exchange, currencies] of Object.entries(per_exchange)) {
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

    Controller {
        id: controller
        context: self.context
    }

    id: self
    background: null
    padding: 0
    contentItem: Flickable {
        ScrollIndicator.vertical: ScrollIndicator {
        }
        id: flickable
        clip: true
        contentWidth: flickable.width
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            spacing: 16
            width: flickable.width
            SettingsBox {
                title: qsTrId('id_bitcoin_denomination')
                enabled: !wallet.locked
                contentItem: RowLayout {
                    spacing: 10
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
                        currentIndex: units.indexOf(self.session.settings.unit)
                        onCurrentValueChanged: {
                            if (currentValue === '') return
                            if (currentValue === self.session.settings.unit) return
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
                        text: qsTrId('id_select_a_fiat_currency_and')
                        wrapMode: Text.WordWrap
                    }
                    Label {
                        Layout.fillWidth: true
                        Layout.minimumWidth: contentWidth
                        text: qsTrId('id_reference_exchange_rate')
                    }
                    RowLayout {
                        spacing: 10
                        GComboBox {
                            id: currency_combo
                            Layout.fillWidth: true
                            width: 200
                            model: Object.keys(self.per_currency).sort()
                            currentIndex: model.indexOf(self.session.settings.pricing?.currency ?? '')
                            onCurrentTextChanged: {
                                if (!focus) return
                                const currency = currentText
                                if (currency === '') return
                                if (currency === self.session.settings.pricing.currency) return
                                const exchange = self.session.settings.pricing.exchange
                                const pricing = { currency, exchange }
                                if (self.per_currency[currency].indexOf(self.session.settings.pricing.exchange) < 0) {
                                    pricing.exchange = self.per_currency[currentText][0]
                                }
                                controller.changeSettings({ pricing })
                            }
                            popup.contentItem.implicitHeight: 300
                        }
                        HSpacer {
                        }
                        GComboBox {
                            id: exchange_combo
                            Layout.fillWidth: true
                            width: 200
                            model: currency_combo.currentText ? per_currency[currency_combo.currentText].sort() : []
                            currentIndex: self.session.settings.pricing ? Math.max(0, model.indexOf(self.session.settings.pricing.exchange)) : 0
                            onCurrentTextChanged: {
                                if (!focus) return
                                const exchange = currentText
                                if (exchange === '') return
                                if (exchange === self.session.settings.pricing.exchange) return
                                const currency = self.session.settings.pricing.currency
                                const pricing = { currency, exchange }
                                controller.changeSettings({ pricing })
                            }
                            Layout.minimumWidth: 150
                        }
                    }
                }
            }

            SettingsBox {
                title: qsTrId('id_notifications')
                contentItem: ColumnLayout {
                    spacing: 8
                    Label {
                        Layout.fillWidth: true
                        text: qsTrId('id_receive_email_notifications_for')
                    }
                    Repeater {
                        model: self.context.sessions.filter(session => !session.network.electrum)
                        delegate: AbstractButton {
                            required property var modelData
                            readonly property Session session: modelData
                            Layout.fillWidth: true
                            id: button
                            leftPadding: 20
                            rightPadding: 20
                            topPadding: 15
                            bottomPadding: 15
                            enabled: !button.session.locked && (button.session.config.email?.confirmed ?? false)
                            background: Rectangle {
                                radius: 5
                                color: Qt.lighter('#222226', button.enabled && button.hovered ? 1.2 : 1)
                            }
                            contentItem: RowLayout {
                                spacing: 20
                                ColumnLayout {
                                    Layout.fillWidth: false
                                    Label {
                                        font.pixelSize: 14
                                        font.weight: 600
                                        text: button.session.network.displayName
                                    }
                                    Label {
                                        font.pixelSize: 11
                                        font.weight: 400
                                        opacity: 0.6
                                        text: button.session.config.email?.confirmed ?? false ? button.session.config.email.data : qsTrId('id_enable_2fa') + ' ' + qsTrId('id_email')
                                    }
                                }
                                HSpacer {
                                }
                                GSwitch {
                                    checked: button.session.settings?.notifications?.email_outgoing ?? false
                                    enabled: false
                                    opacity: 1
                                    visible: button.session.config.email?.confirmed ?? false
                                }
                            }
                            onClicked: {
                                const checked = button.session.settings?.notifications?.email_outgoing
                                controller.changeSessionSettings(button.session, {
                                    notifications: {
                                        email_incoming: !checked,
                                        email_login: !checked,
                                        email_outgoing: !checked
                                    }
                                });
                            }
                        }
                    }
                }
            }

            SettingsBox {
                readonly property string supportId: {
                    return self.context.accounts
                        .filter(account => account.pointer === 0 && !account.network.electrum)
                        .map(account => `${account.network.data.bip21_prefix}:${account.json.receiving_id}`)
                        .join(',')
                }
                id: support_box
                title: qsTrId('id_support')
                visible: support_box.supportId !== ''
                contentItem: ColumnLayout {
                    AbstractButton {
                        Layout.fillWidth: true
                        id: button
                        leftPadding: 20
                        rightPadding: 20
                        topPadding: 15
                        bottomPadding: 15
                        background: Rectangle {
                            radius: 5
                            color: Qt.lighter('#222226', button.hovered ? 1.2 : 1)
                        }
                        contentItem: RowLayout {
                            spacing: 20
                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                font.pixelSize: 14
                                font.weight: 600
                                text: qsTrId('id_copy_support_id')
                            }
                            Image {
                                source: timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                            }
                        }
                        onClicked: {
                            Clipboard.copy(support_box.supportId)
                            timer.restart()
                        }
                        Timer {
                            id: timer
                            repeat: false
                            interval: 1000
                        }
                    }
                }
            }
        }
    }
}
