import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    function updateCurrency(currency) {
        if (currency === self.session.settings.pricing.currency) return
        const exchange = self.session.settings.pricing.exchange
        const pricing = { currency, exchange }
        if (self.per_currency[currency].indexOf(self.session.settings.pricing.exchange) < 0) {
            pricing.exchange = self.per_currency[currency][0]
        }
        controller.changeSettings({ pricing })
    }

    Controller {
        id: controller
        context: self.context
    }

    id: self
    background: null
    padding: 0

    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 24

        // Bitcoin Denomination
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_bitcoin_denomination')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_show_bitcoin_amounts_in')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Control
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: denomination_combo.height
                GDropdown {
                    id: denomination_combo
                    anchors.right: parent.right
                    width: Math.min(100, parent.width)
                    property var units: ['BTC', 'mBTC', '\u00B5BTC', 'bits', 'sats']
                    enabled: !self.wallet.locked
                    model: units.map(unit => ({
                        text: self.context.getDisplayUnit(unit),
                        value: unit
                    }))
                    textRole: 'text'
                    valueRole: 'value'
                    currentValue: self.session.settings.unit
                    onValueChanged: (value) => {
                        if (value === '') return
                        if (value === self.session.settings.unit) return
                        controller.changeSettings({ unit: value })
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
        }

        // Currency
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_currency')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_select_a_fiat_currency_and')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8

                GDropdown {
                    id: currency_combo
                    Layout.alignment: Qt.AlignRight
                    width: Math.min(200, parent.width)
                    enabled: !self.wallet.locked
                    model: Object.keys(self.per_currency).sort().map(currency => ({
                        text: currency,
                        value: currency
                    }))
                    textRole: 'text'
                    valueRole: 'value'
                    currentValue: self.session.settings.pricing?.currency ?? ''
                    onValueChanged: (currency) => {
                        if (currency === '') return
                        self.updateCurrency(currency)
                    }
                }
                GDropdown {
                    id: exchange_combo
                    Layout.alignment: Qt.AlignRight
                    width: Math.min(200, parent.width)
                    enabled: !self.wallet.locked
                    model: currency_combo.currentValue ? self.per_currency[currency_combo.currentValue].sort().map(exchange => ({
                        text: exchange,
                        value: exchange
                    })) : []
                    textRole: 'text'
                    valueRole: 'value'
                    currentValue: self.session.settings.pricing?.exchange ?? ''
                    onValueChanged: (exchange) => {
                        if (exchange === '') return
                        if (exchange === self.session.settings.pricing.exchange) return
                        const currency = self.session.settings.pricing.currency
                        const pricing = { currency, exchange }
                        controller.changeSettings({ pricing })
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
        }

        // Auto-logout timeout
        RowLayout {
            Layout.fillWidth: true
            spacing: 20
            visible: !self.context.device

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_auto_logout_timeout')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_set_a_timeout_to_logout_after')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Control
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: timeout_combo.height
                GDropdown {
                    id: timeout_combo
                    anchors.right: parent.right
                    width: Math.min(200, parent.width)
                    model: [1, 2, 5, 10, 60].map(minutes => ({
                        text: qsTrId('id_1d_minutes').arg(minutes),
                        value: minutes
                    }))
                    textRole: 'text'
                    valueRole: 'value'
                    currentValue: self.session.settings.altimeout
                    onValueChanged: (minutes) => {
                        controller.changeSettings({ altimeout: minutes })
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: !self.context.device
        }

        // Notifications
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_notifications')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_receive_email_notifications_for')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }

            // Right: Controls
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8

                Repeater {
                    model: self.context.sessions.filter(session => !session.network.electrum)
                    delegate: AbstractButton {
                        required property var modelData
                        readonly property Session session: modelData
                        Layout.fillWidth: true
                        id: notification_button
                        leftPadding: 16
                        rightPadding: 16
                        topPadding: 12
                        bottomPadding: 12
                        enabled: !notification_button.session.locked && (notification_button.session.config.email?.confirmed ?? false)
                        background: Rectangle {
                            radius: 5
                            color: Qt.lighter('#262626', notification_button.enabled && notification_button.hovered ? 1.2 : 1)
                        }
                        contentItem: RowLayout {
                            spacing: 12
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    Layout.fillWidth: true
                                    font.pixelSize: 13
                                    font.weight: 600
                                    text: notification_button.session.network.displayName
                                }
                                Label {
                                    font.pixelSize: 11
                                    color: '#6F6F6F'
                                    text: notification_button.session.config.email?.confirmed ?? false ? notification_button.session.config.email.data : qsTrId('id_enable_2fa') + ' ' + qsTrId('id_email')
                                }
                            }
                            GSwitch {
                                checked: notification_button.session.settings?.notifications?.email_outgoing ?? false
                                enabled: false
                                opacity: 1
                                visible: notification_button.session.config.email?.confirmed ?? false
                            }
                        }
                        onClicked: {
                            const checked = notification_button.session.settings?.notifications?.email_outgoing
                            controller.changeSessionSettings(notification_button.session, {
                                notifications: {
                                    email_incoming: !checked,
                                    email_login: !checked,
                                    email_outgoing: !checked
                                }
                            })
                        }
                        HoverHandler {
                            cursorShape: notification_button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: support_box.visible
        }

        // Support
        RowLayout {
            id: support_box
            Layout.fillWidth: true
            spacing: 20
            visible: supportId !== ''

            readonly property string supportId: {
                return self.context.accounts
                    .filter(account => account.pointer === 0 && !account.network.electrum)
                    .map(account => `${account.network.data.bip21_prefix}:${account.json.receiving_id}`)
                    .join(',')
            }

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_support')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
            }

            // Right: Control
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                implicitHeight: support_button.height
                AbstractButton {
                    id: support_button
                    anchors.right: parent.right
                    width: Math.min(200, parent.width)
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 12
                    bottomPadding: 12
                    background: Rectangle {
                        radius: 5
                        color: Qt.lighter('#262626', support_button.hovered ? 1.2 : 1)
                    }
                    contentItem: RowLayout {
                        spacing: 12
                        Label {
                            Layout.fillWidth: true
                            font.pixelSize: 13
                            font.weight: 600
                            text: qsTrId('id_copy_support_id')
                        }
                        Image {
                            source: support_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
                        }
                    }
                    onClicked: {
                        Clipboard.copy(support_box.supportId)
                        support_timer.restart()
                    }
                    Timer {
                        id: support_timer
                        repeat: false
                        interval: 1000
                    }
                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        VSpacer {
        }
    }
}
