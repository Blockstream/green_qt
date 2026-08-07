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

    function updateCurrency(currency) {
        if (currency === self.session.settings.pricing.currency) return
        const exchange = self.session.settings.pricing.exchange
        const pricing = { currency, exchange }
        if (!self.per_currency[currency].includes(exchange)) {
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
                GComboBox {
                    id: denomination_combo
                    anchors.right: parent.right
                    property var units: ['BTC', 'mBTC', '\u00B5BTC', 'bits', 'sats']
                    enabled: !self.wallet.locked
                    model: units.map(unit => ({
                        text: self.context.getDisplayUnit(unit),
                        value: unit
                    }))
                    textRole: 'text'
                    valueRole: 'value'
                    currentIndex: denomination_combo.units.indexOf(self.session.settings.unit)
                    onActivated: (index) => {
                        const value = denomination_combo.model[index].value
                        if (value === '' || value === self.session.settings.unit) return
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

                GComboBox {
                    id: currency_combo
                    Layout.alignment: Qt.AlignRight
                    enabled: !self.wallet.locked
                    model: Object.keys(self.per_currency).sort().map(currency => ({
                        text: currency,
                        value: currency
                    }))
                    textRole: 'text'
                    valueRole: 'value'
                    currentIndex: {
                        const currency = self.session.settings.pricing?.currency ?? ''
                        if (!currency) return -1
                        return currency_combo.model.findIndex(item => item.value === currency)
                    }
                    onActivated: (index) => {
                        const currency = currency_combo.model[index].value
                        if (currency === '') return
                        self.updateCurrency(currency)
                    }
                }
                GComboBox {
                    id: exchange_combo
                    popup.width: 160
                    enabled: !self.wallet.locked
                    model: {
                        const currencyIndex = currency_combo.currentIndex
                        if (currencyIndex < 0) return []
                        const currency = currency_combo.model[currencyIndex]?.value
                        return currency ? self.per_currency[currency].sort().map(exchange => ({
                            text: exchange,
                            value: exchange
                        })) : []
                    }
                    textRole: 'text'
                    valueRole: 'value'
                    currentIndex: {
                        const exchange = self.session.settings.pricing?.exchange ?? ''
                        if (!exchange) return -1
                        return exchange_combo.model.findIndex(item => item.value === exchange)
                    }
                    onActivated: (index) => {
                        const exchange = exchange_combo.model[index].value

                        if (exchange === '' || exchange === self.session.settings.pricing.exchange) return
                        const currency = self.session.settings.pricing.currency
                        controller.changeSettings({ pricing: { currency, exchange } })
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
                GComboBox {
                    id: timeout_combo
                    anchors.right: parent.right
                    model: [1, 2, 5, 10, 60].map(minutes => ({
                        text: qsTrId('id_1d_minutes').arg(minutes),
                        value: minutes
                    }))
                    textRole: 'text'
                    valueRole: 'value'
                    currentIndex: {
                        const value = self.session.settings.altimeout
                        return timeout_combo.model.findIndex(item => item.value === value)
                    }
                    onActivated: (index) => {
                        const minutes = timeout_combo.model[index].value
                        controller.changeSettings({ altimeout: minutes })
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: notifications_box.visible
        }

        RowLayout {
            id: notifications_box
            Layout.fillWidth: true
            spacing: 20
            visible: self.context.sessions.some(session => !session.network.electrum)
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
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: recovery_email_box.visible
        }

        RowLayout {
            id: recovery_email_box
            Layout.fillWidth: true
            spacing: 20
            readonly property var legacyRecoverySessions: self.context.sessions.filter(session => !session.network.electrum && !session.network.liquid)
            visible: recovery_email_rows.hasVisibleRows
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 4
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_recovery_transactions')
                    font.pixelSize: 14
                    font.weight: 600
                    color: '#FFFFFF'
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTrId('id_use_your_email_to_receive')
                    font.pixelSize: 13
                    color: '#6F6F6F'
                    wrapMode: Label.Wrap
                }
            }
            ColumnLayout {
                id: recovery_email_rows
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignTop
                spacing: 8
                property bool hasVisibleRows: false
                function updateVisibleRows() {
                    let visible = false
                    for (let i = 0; i < recovery_sessions_repeater.count; ++i) {
                        const item = recovery_sessions_repeater.itemAt(i)
                        if (item && item.visible) {
                            visible = true
                            break
                        }
                    }
                    if (hasVisibleRows !== visible) hasVisibleRows = visible
                }
                Component.onCompleted: updateVisibleRows()
                Repeater {
                    id: recovery_sessions_repeater
                    model: recovery_email_box.legacyRecoverySessions
                    onItemAdded: recovery_email_rows.updateVisibleRows()
                    onItemRemoved: recovery_email_rows.updateVisibleRows()
                    delegate: ColumnLayout {
                        id: recovery_session_row
                        required property var modelData
                        readonly property Session session: modelData
                        readonly property Account mainAccount: self.context.getOrCreateAccount(session.network, 0)
                        readonly property bool hasPreCsvNlocktimeCoins: pre_csv_probe.count > 0
                        readonly property bool emailConfigured: session.config.email?.confirmed ?? false
                        Layout.fillWidth: true
                        spacing: 8
                        visible: hasPreCsvNlocktimeCoins
                        onVisibleChanged: recovery_email_rows.updateVisibleRows()
                        OutputListModelFilter {
                            id: pre_csv_outputs
                            filter: "!csv"
                            model: OutputListModel {
                                account: recovery_session_row.mainAccount
                            }
                        }
                        ListView {
                            id: pre_csv_probe
                            visible: false
                            interactive: false
                            model: pre_csv_outputs
                            onCountChanged: recovery_email_rows.updateVisibleRows()
                        }
                        AbstractButton {
                            Layout.fillWidth: true
                            id: recovery_email_button
                            leftPadding: 16
                            rightPadding: 16
                            topPadding: 12
                            bottomPadding: 12
                            visible: !recovery_session_row.emailConfigured
                            background: Rectangle {
                                radius: 5
                                color: Qt.lighter('#262626', recovery_email_button.hovered ? 1.2 : 1)
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
                                        text: recovery_session_row.session.network.displayName
                                    }
                                    Label {
                                        font.pixelSize: 11
                                        color: '#6F6F6F'
                                        text: qsTrId('id_set_an_email_for_recovery')
                                    }
                                }
                                RightArrowIndicator {
                                    active: recovery_email_button.hovered
                                }
                            }
                            onClicked: {
                                const dialog = set_recovery_email_dialog.createObject(recovery_email_button, {
                                    context: self.context,
                                    session: recovery_session_row.session,
                                })
                                dialog.open()
                            }
                        }
                        Pane {
                            Layout.fillWidth: true
                            id: recovery_email_configured_row
                            visible: recovery_session_row.emailConfigured
                            leftPadding: 16
                            rightPadding: 16
                            topPadding: 12
                            bottomPadding: 12
                            background: Rectangle {
                                radius: 5
                                color: '#262626'
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
                                        text: recovery_session_row.session.network.displayName
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        font.pixelSize: 11
                                        color: '#6F6F6F'
                                        text: qsTrId('id_recovery_transaction_emails') + ' ' + (recovery_session_row.session.config.email?.data ?? '')
                                        wrapMode: Label.Wrap
                                    }
                                }
                                Image {
                                    source: 'qrc:/svg2/check.svg'
                                }
                            }
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
            // AMP account creation can briefly expose the empty Liquid pointer-0
            // account before hiding it, which would make this row flicker.
            visible: supportId !== '' && !amp_account_section.creatingAccount

            readonly property string supportId: {
                const ids = UtilJS.accounts(self.context)
                    .filter(account => account.pointer === 0 && !account.network.electrum)
                    .map(account => `${account.network.data.bip21_prefix}:${account.json.receiving_id}`)
                const lightningNodeId = self.context.lightningNodeInfo?.id ?? ''
                if (lightningNodeId) ids.push(`lightning:${lightningNodeId}`)
                return ids.join(',')
            }

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignVCenter
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
                CopyButton {
                    id: support_button
                    anchors.right: parent.right
                    width: Math.min(200, parent.width)
                    title: qsTrId('id_copy_support_id')
                    copyText: support_box.supportId
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: lightning_box.visible
        }

        // Lightning
        RowLayout {
            id: lightning_box
            spacing: 20
            Layout.fillWidth: true
            visible: !self.context.bip39 && self.context.mainnet && !self.context.watchonly && !self.context.device

            // Left: Label
            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.minimumWidth: (lightning_box.width - lightning_box.spacing) / 2
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Label {
                        text: self.context.lightningEnabled ? 'Lightning Network (Beta)' : 'Lightning Network'
                        font.pixelSize: 14
                        font.weight: 600
                        color: '#FFFFFF'
                    }
                    LinkButton {
                        text: qsTrId('id_learn_more')
                        font.pixelSize: 12
                        external: true
                        visible: self.context.lightningEnabled
                        onClicked: Qt.openUrlExternally('https://help.blockstream.com/hc/en-us/articles/18788578831897-Understand-Lightning-support-in-the-Blockstream-app')
                    }
                }
            }

            // Right: Control
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: self.context.lightningEnabled ? lightning_node_button.implicitHeight : lightning_button.implicitHeight
                AbstractButton {
                    id: lightning_button
                    anchors.right: parent.right
                    anchors.top: parent.top
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 8
                    bottomPadding: 8
                    visible: !self.context.lightningEnabled
                    background: Rectangle {
                        color: '#FFF'
                        radius: 4
                        opacity: 0.2
                        visible: lightning_button.hovered
                    }
                    contentItem: RowLayout {
                        spacing: 4
                        opacity: 0.7
                        Label {
                            color: '#FFFFFF'
                            font.pixelSize: 14
                            font.weight: 500
                            text: 'Beta'
                        }
                        Image {
                            Layout.alignment: Qt.AlignCenter
                            source: 'qrc:/svg2/caret-down-white.svg'
                            rotation: -90
                        }
                    }
                    onClicked: {
                        const drawer = enable_lightning_drawer.createObject(self, { context: self.context })
                        drawer.open()
                    }
                }
                CopyButton {
                    id: lightning_node_button
                    anchors.left: parent.left
                    anchors.right: parent.right
                    visible: self.context.lightningEnabled
                    title: 'Lightning Node'
                    subtitle: self.context.lightningNodeInfo?.id ?? 'Not available'
                    subtitleElide: Label.ElideMiddle
                    copyText: self.context.lightningNodeInfo?.id ?? ''
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: '#262626'
            visible: amp_account_section.visible
        }

        AmpAccountSettingsSection {
            id: amp_account_section
            Layout.fillWidth: true
            context: self.context
        }

        VSpacer {
        }
    }

    Component {
        id: enable_lightning_drawer
        EnableLightningDrawer {
        }
    }

    component CopyButton: AbstractButton {
        property string title
        property string subtitle: ''
        property string copyText: ''
        property int subtitleElide: Label.ElideRight

        id: copy_button
        leftPadding: 16
        rightPadding: 16
        topPadding: 12
        bottomPadding: 12

        background: Rectangle {
            radius: 5
            color: Qt.lighter('#262626', copy_button.hovered ? 1.2 : 1)
        }

        contentItem: RowLayout {
            spacing: 12
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    Layout.fillWidth: true
                    color: '#FFFFFF'
                    font.pixelSize: 13
                    font.weight: 600
                    text: copy_button.title
                    elide: Label.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    visible: copy_button.subtitle !== ''
                    color: '#6F6F6F'
                    font.pixelSize: 11
                    font.weight: 400
                    text: copy_button.subtitle
                    elide: copy_button.subtitleElide
                }
            }
            Image {
                source: copy_timer.running ? 'qrc:/svg2/check.svg' : 'qrc:/svg2/copy.svg'
            }
        }

        onClicked: {
            Clipboard.copy(copy_button.copyText)
            copy_timer.restart()
        }

        Timer {
            id: copy_timer
            repeat: false
            interval: 1000
        }
    }

    Component {
        id: set_recovery_email_dialog
        SetRecoveryEmailDialog {
        }
    }
}
