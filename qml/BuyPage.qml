import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

StackViewPage {
    signal showTransactions()
    required property Context context
    required property Account account
    property bool pendingVerify: false
    property string countryCode: 'US'
    readonly property string currencyCode: {
        const currency = self.context?.primarySession?.settings?.pricing?.currency ?? 'USD'
        return currency.toLowerCase()
    }
    property int remoteConfigVersion: 0
    readonly property var defaultAmounts: {
        const _ = self.remoteConfigVersion
        const config = BuyBitcoinQuoteService.getBuyDefaultValues()
        if (!config || typeof config !== 'object' || Array.isArray(config)) {
            return ['100', '200', '400']
        }
        const buyDefaults = (config.buy_default_values && typeof config.buy_default_values === 'object' && !Array.isArray(config.buy_default_values))
            ? config.buy_default_values
            : config
        if (!buyDefaults || typeof buyDefaults !== 'object' || Array.isArray(buyDefaults)) {
            return ['100', '200', '400']
        }
        const currencyValues = buyDefaults[self.currencyCode]
        if (currencyValues && Array.isArray(currencyValues) && currencyValues.length > 0) {
            return currencyValues.map(val => val.toString())
        }
        const usdValues = buyDefaults['usd']
        if (usdValues && Array.isArray(usdValues) && usdValues.length > 0) {
            return usdValues.map(val => val.toString())
        }
        return ['100', '200', '400']
    }
    Component.onCompleted: {
        const locale = Qt.locale()
        const parts = locale.name.split('_')
        self.countryCode = parts.length > 1 ? parts[1].toUpperCase() : (locale.country ? locale.country : 'US')
    }
    id: self
    title: 'Buy Bitcoin'
    leftItem: AbstractButton {
        padding: 8
        leftPadding: 12
        rightPadding: 12
        topPadding: 8
        bottomPadding: 8
        background: Rectangle {
            color: Qt.lighter('#181818', parent.hovered ? 1.2 : 1)
            radius: 4
            border.width: 1
            border.color: '#262626'
        }
        contentItem: RowLayout {
            spacing: 6
             Image {
                 id: flag_image
                 Layout.preferredWidth: 16
                 Layout.preferredHeight: 12
                 fillMode: Image.PreserveAspectFit
                 source: 'qrc:/flags/' + self.countryCode + '-flag.svg'
             }
            Image {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: 'qrc:/svg2/caret-down-white.svg'
                opacity: 0.6
            }
        }
        onClicked: self.StackView.view.push(null, country_selector_page, { selectedCountryCode: self.countryCode })
    }
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_amount')
        }
        TTextField {
            Layout.fillWidth: true
            id: amount_input
            focus: true
            Component.onCompleted: amount_input.forceActiveFocus()
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            validator: DoubleValidator { bottom: 0 }
            horizontalAlignment: TextInput.AlignHCenter
            font.pixelSize: 28
            font.weight: 600
            topPadding: (BuyBitcoinQuoteService.bestDestinationAmount > 0 || BuyBitcoinQuoteService.loading) ? 8 : 16
            bottomPadding: (BuyBitcoinQuoteService.bestDestinationAmount > 0 || BuyBitcoinQuoteService.loading) ? 26 : 16
            leftPadding: 28 + clear_button.width
            rightPadding: 28 + currency_label.width
            CircleButton {
                id: clear_button
                focusPolicy: Qt.NoFocus
                width: 22
                height: 22
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                visible: amount_input.text.length > 0
                icon.source: 'qrc:/svg2/x-circle.svg'
                onClicked: {
                    amount_input.text = ''
                    BuyBitcoinQuoteService.clearQuote()
                    amount_input.forceActiveFocus()
                }
            }
            Label {
                id: currency_label
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                color: '#FFFFFF'
                font.pixelSize: 14
                font.weight: 500
                opacity: 0.9
                text: self.context?.primarySession?.settings?.pricing?.currency ?? ''
            }
            Label {
                id: btc_amount_label
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                color: '#FFFFFF'
                font.pixelSize: 12
                font.weight: 500
                opacity: 0.7
                visible: (BuyBitcoinQuoteService.selectedDestinationAmount > 0 || BuyBitcoinQuoteService.bestDestinationAmount > 0) || BuyBitcoinQuoteService.loading
                text: {
                    if (BuyBitcoinQuoteService.loading) {
                        return 'Fetching best rate...'
                    }
                    const btcAmount = BuyBitcoinQuoteService.selectedDestinationAmount || BuyBitcoinQuoteService.bestDestinationAmount
                    if (btcAmount > 0) {
                        let formatted = btcAmount.toFixed(8)
                        formatted = formatted.replace(/\.?0+$/, '')
                        return '≈ ' + formatted + ' BTC'
                    }
                    return ''
                }
            }
            onTextChanged: {
                quote_fetch_timer.restart()
            }
        }
        Label {
            Layout.topMargin: 4
            Layout.leftMargin: 2
            color: '#FF6B6B'
            font.pixelSize: 12
            font.weight: 500
            visible: BuyBitcoinQuoteService.error.length > 0 && !BuyBitcoinQuoteService.loading
            text: BuyBitcoinQuoteService.error
            wrapMode: Label.Wrap
            Layout.fillWidth: true
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            spacing: 12
            Repeater {
                model: self.defaultAmounts
                delegate: AbstractButton {
                    required property string modelData
                    property bool selected: amount_input.text === modelData
                    Layout.fillWidth: true
                    padding: 10
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 10
                    bottomPadding: 10
                    background: Rectangle {
                        color: parent.selected ? '#062F4A' : Qt.lighter('#181818', parent.hovered ? 1.2 : 1)
                        radius: 5
                        border.width: 1
                        border.color: parent.selected ? '#4FD1FF' : '#262626'
                    }
                    contentItem: Label {
                        horizontalAlignment: Label.AlignHCenter
                        verticalAlignment: Label.AlignVCenter
                        font.pixelSize: 16
                        color: '#FFFFFF'
                        text: modelData
                    }
                    onClicked: {
                        amount_input.text = modelData
                        amount_input.forceActiveFocus()
                    }
                }
            }
        }
        FieldTitle {
            text: qsTrId('id_account')
        }
        AccountAssetField {
            Layout.fillWidth: true
            account: self.account
            asset: self.context.getOrCreateAsset('btc')
            readonly: false
            onClicked: self.StackView.view.push(null, account_selector_page)
        }
        FieldTitle {
            text: 'Exchange'
            visible: BuyBitcoinQuoteService.bestServiceProvider.length > 0 && BuyBitcoinQuoteService.bestDestinationAmount > 0
        }
        AbstractButton {
            Layout.fillWidth: true
            Layout.leftMargin: 2
            id: exchange_button
            visible: (BuyBitcoinQuoteService.selectedServiceProvider.length > 0 || BuyBitcoinQuoteService.bestServiceProvider.length > 0)
                  && (BuyBitcoinQuoteService.selectedDestinationAmount > 0 || BuyBitcoinQuoteService.bestDestinationAmount > 0)
            background: Rectangle {
                color: Qt.lighter('#181818', parent.hovered ? 1.2 : 1)
                radius: 5
                border.width: 1
                border.color: '#262626'
            }
            padding: 20
            contentItem: RowLayout {
                spacing: 10
                ProviderIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    providerName: BuyBitcoinQuoteService.selectedServiceProvider || BuyBitcoinQuoteService.bestServiceProvider
                }
                Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: '#FFFFFF'
                    font.pixelSize: 14
                    font.weight: 500
                    text: BuyBitcoinQuoteService.selectedServiceProvider || BuyBitcoinQuoteService.bestServiceProvider
                }
                RightArrowIndicator {
                    active: exchange_button.hovered
                }
            }
            onClicked: {
                const quotes = BuyBitcoinQuoteService.allQuotes
                self.StackView.view.push(quotes_list_page, {
                    quotes: quotes,
                    quoteService: BuyBitcoinQuoteService
                })
            }
        }
        ReceiveAddressController {
            id: receive_address_controller
            context: self.context
            account: self.account
            asset: self.account ? self.context.getOrCreateAsset(self.account.network.liquid ? self.account.network.policyAsset : 'btc') : null
            onAccountChanged: {
                self.pendingVerify = false
                if (account && !address) {
                    generate()
                }
            }
            onAddressChanged: {
                if (self.pendingVerify && receive_address_controller.address && self.StackView.view) {
                    self.pendingVerify = false
                    self.StackView.view.push(jade_verify_page, { context: self.context, address: receive_address_controller.address })
                }
                quote_fetch_timer.restart()
            }
        }
        Connections {
            target: BuyBitcoinQuoteService
            function onWidgetUrlChanged() {
                if (BuyBitcoinQuoteService.widgetUrl.length > 0) {
                    self.StackView.view.push(webview_page, {
                        widgetUrl: BuyBitcoinQuoteService.widgetUrl
                    })
                }
            }
        }
        Timer {
            id: quote_fetch_timer
            interval: 500
            onTriggered: {
                const amountText = amount_input.text.trim()
                const amount = parseFloat(amountText)
                const currency = self.context?.primarySession?.settings?.pricing?.currency ?? 'USD'
                const address = receive_address_controller.address?.address ?? ''

                if (amountText.length === 0 || amount <= 0 || !currency || !address || !self.countryCode) {
                    BuyBitcoinQuoteService.clearQuote()
                } else {
                    const walletHashedId = self.context?.xpubHashId ?? ''
                    BuyBitcoinQuoteService.fetchQuote(self.countryCode, amount, currency, address, walletHashedId)
                }
            }
        }
        Connections {
            target: BuyBitcoinQuoteService
            function onBuyDefaultValuesChanged() {
                // Increment version to trigger defaultAmounts recalculation
                self.remoteConfigVersion++
            }
        }
        VSpacer {
        }
        Label {
            Layout.topMargin: 4
            Layout.leftMargin: 2
            color: '#FF6B6B'
            font.pixelSize: 12
            font.weight: 500
            visible: BuyBitcoinQuoteService.widgetError.length > 0 && !BuyBitcoinQuoteService.widgetLoading
            text: BuyBitcoinQuoteService.widgetError
            wrapMode: Label.Wrap
            Layout.fillWidth: true
        }
        PrimaryButton {
            Layout.fillWidth: true
            icon.source: 'qrc:/svg3/arrow-line-up-right.svg'
            text: BuyBitcoinQuoteService.widgetLoading ? 'Loading...' : 'Buy Bitcoin'
            enabled: amount_input.text.length > 0 &&
                     parseFloat(amount_input.text) > 0 &&
                     BuyBitcoinQuoteService.error.length === 0 &&
                     !BuyBitcoinQuoteService.loading &&
                     (BuyBitcoinQuoteService.selectedServiceProvider.length > 0 || BuyBitcoinQuoteService.bestServiceProvider.length > 0) &&
                     !BuyBitcoinQuoteService.widgetLoading &&
                     receive_address_controller.address
            onClicked: {
                const serviceProvider = BuyBitcoinQuoteService.selectedServiceProvider || BuyBitcoinQuoteService.bestServiceProvider
                const amountText = amount_input.text.trim()
                const amount = parseFloat(amountText)
                const currency = self.context?.primarySession?.settings?.pricing?.currency ?? 'USD'
                const address = receive_address_controller.address?.address ?? ''

                if (serviceProvider && amount > 0 && currency && address && self.countryCode) {
                    const walletHashedId = self.context?.xpubHashId ?? ''
                    BuyBitcoinQuoteService.createWidgetSession(serviceProvider, self.countryCode, amount, currency, address, false, walletHashedId)
                }
            }
        }
        PrimaryButton {
            Layout.fillWidth: true
            icon.source: 'qrc:/svg3/arrow-line-up-right.svg'
            text: BuyBitcoinQuoteService.widgetLoading ? 'Loading...' : 'Buy Bitcoin (sandbox)'
            visible: Qt.application.arguments.indexOf('--debug') > 0
            enabled: amount_input.text.length > 0 &&
                     parseFloat(amount_input.text) > 0 &&
                     BuyBitcoinQuoteService.error.length === 0 &&
                     !BuyBitcoinQuoteService.loading &&
                     (BuyBitcoinQuoteService.selectedServiceProvider.length > 0 || BuyBitcoinQuoteService.bestServiceProvider.length > 0) &&
                     !BuyBitcoinQuoteService.widgetLoading &&
                     receive_address_controller.address
            onClicked: {
                const serviceProvider = BuyBitcoinQuoteService.selectedServiceProvider || BuyBitcoinQuoteService.bestServiceProvider
                const amountText = amount_input.text.trim()
                const amount = parseFloat(amountText)
                const currency = self.context?.primarySession?.settings?.pricing?.currency ?? 'USD'
                const address = receive_address_controller.address?.address ?? ''

                if (serviceProvider && amount > 0 && currency && address && self.countryCode) {
                    const walletHashedId = self.context?.xpubHashId ?? ''
                    BuyBitcoinQuoteService.createWidgetSession(serviceProvider, self.countryCode, amount, currency, address, true, walletHashedId)
                }
            }
        }
        RegularButton {
            Layout.fillWidth: true
            cyan: true
            text: 'Verify Address'
            enabled: self.account && receive_address_controller.address
            visible: self.context.wallet.login.device?.type === 'jade'
            onClicked: {
                if (receive_address_controller.address) {
                    self.StackView.view.push(jade_verify_page, { context: self.context, address: receive_address_controller.address })
                } else {
                    self.pendingVerify = true
                    receive_address_controller.generate()
                }
            }
        }
    }

    Component {
        id: jade_verify_page
        JadeVerifyAddressPage {
        }
    }
    Component {
        id: country_selector_page
        CountrySelectorPage {
            context: self.context
            onCountrySelected: (code) => {
                self.countryCode = code
                self.StackView.view.pop()
                amount_input.forceActiveFocus()
                quote_fetch_timer.restart()
            }
        }
    }
    Component {
        id: account_selector_page
        AccountSelectorPage {
            asset: self.context.getOrCreateAsset('btc')
            context: self.context
            message: 'Select the desired account you want to receive your bitcoin.'
            showAllAccounts: true
            onAccountClicked: (account) => {
                self.account = account
                self.StackView.view.pop()
                amount_input.forceActiveFocus()
            }
        }
    }
    Component {
        id: quotes_list_page
        QuotesListPage {
        }
    }
    Component {
        id: webview_page
        BuyWebViewPage {
            onCloseClicked: self.closeClicked()
            onShowTransactions: self.showTransactions()
        }
    }
}
