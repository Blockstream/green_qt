import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset

    property url url
    property bool lightningOnly: false
    property Component page
    property list<Account> accounts
    property var assets
    property var error: null
    readonly property bool closeBlocked: lightning_send_controller.busy

    function updateLightningInvoice(recipient) {
        if (!self.context.mainnet) {
            self.error = { code: 'Not supported in testnet.', visible: true }
            return
        }
        if (self.context.watchonly) {
            self.error = { code: 'Not supported in watch-only.', visible: true }
            return
        }
        if (self.context.wallet.login.device) {
            self.error = { code: 'Not supported with Hardware Wallet.', visible: true }
            return
        }
        if (Settings.isEventRegistered({ invoice: recipient.input })) {
            self.error = { code: 'Invoice already paid.', visible: true }
            return
        }

        lightning_send_controller.input = recipient.input
        lightning_send_controller.invoice = recipient.invoice.invoice ?? recipient.input

        if (lightning_send_controller.error.length > 0) {
            self.error = {
                code: lightning_send_controller.error,
                visible: true
            }
            return
        }

        if (lightning_send_controller.sources.length > 1) {
            self.error = null
            return self.pushPage(payment_source_selector_page, {
                sources: lightning_send_controller.sources
            })
        }

        if (!lightning_send_controller.selectedSource) {
            self.error = {
                code: lightning_send_controller.error || 'id_insufficient_funds',
                visible: true
            }
            return
        }

        self.error = null
        self.pushPaymentSource(lightning_send_controller.selectedSource)
    }

    function pushPaymentSource(source) {
        lightning_send_controller.selectedSource = source

        if (source.type === PaymentSource.Lightning) {
            return lightning_send_controller.amountless
                ? self.pushPage(lightning_send_amountless_page)
                : self.pushPage(lightning_send_confirm_page)
        }

        if (lightning_send_controller.amountless) {
            self.error = { code: 'Amountless invoices require Lightning account', visible: true }
            return
        }

        self.pushPage(submarine_swap_page, {
            account: source.account,
            asset: source.asset,
            input: recipient_field.input,
            recipient: recipient_field.recipient
        })
    }

    function update(recipient) {
        let asset, asset_id, error, network

        if (recipient.error) {
            if (recipient.error.includes('DNS resolution failed')) {
                self.error = { code: 'DNS resolution failed', visible: true }
            } else {
                const code = recipient.error
                    .replace('Reqwest error: ', '')
                self.error = { code, visible: true }
            }
            return
        }

        if (recipient.invoice) {
            return self.updateLightningInvoice(recipient)
        }

        self.page = (() => {
            if (recipient.bip353) {
                network = 'liquid'
                asset_id = NetworkManager.network('liquid').policyAsset
                return bip353_page
            }
            if (recipient.bolt12) {
                network = 'liquid'
                asset_id = NetworkManager.network('liquid').policyAsset
                return bolt12_page
            }
            if (recipient.lnurl) {
                network = 'liquid'
                asset_id = NetworkManager.network('liquid').policyAsset
                return lnurl_page
            }
            if (recipient.address) {
                network = recipient.address.network
                return send_page
            }
            return null
        })()

        self.accounts = (() => {
            if (self.account && network) {
                if (self.account.network.key === network) {
                    return [self.account]
                } else {
                    return []
                }
            }
            if (network) {
                return UtilJS.accounts(self.context)
                    .filter(account => account.network.key === network)
                    .filter(account => !asset_id || account.json.satoshi[asset_id] > 0)
            }
            return []
        })()

        self.assets = (() => {
            const assets = new Map
            for (const account of self.accounts) {
                for (const id in account.json.satoshi) {
                    if (asset_id && asset_id !== id) continue
                    const satoshi = account.json.satoshi[id]
                    if (!satoshi) continue
                    const asset = self.context.getOrCreateAsset(id)
                    let sum = assets.get(asset)
                    if (sum) {
                        sum.satoshi += satoshi
                    } else {
                        sum = { satoshi, asset }
                        assets.set(asset, sum)
                    }
                }
            }
            return [...assets.values()]
                .filter((a) => !self.asset || a.asset.id === self.asset.id)
                .sort((a, b) => {
                    if (a.asset.weight > b.asset.weight) return -1
                    if (b.asset.weight > a.asset.weight) return 1
                    if (b.asset.weight === 0) {
                        if (a.asset.icon && !b.asset.icon) return -1
                        if (!a.asset.icon && b.asset.icon) return 1
                        if (Object.keys(a.asset.data).length > 0 && Object.keys(b.asset.data).length === 0) return -1
                        if (Object.keys(a.asset.data).length === 0 && Object.keys(b.asset.data).length > 0) return 1
                    }
                    return a.asset.name.localeCompare(b.asset.name)
                })
        })()
        if (error) {
            self.error = { code: error, visible: true }
            return
        }
        if (!self.page) {
            self.error = { code: 'id_invalid_address', visible: recipient_field.text !== '' }
            return
        }
        if (self.accounts.length === 0) {
            self.error = { code: 'No account available', visible: true }
        }
        if (self.assets.length === 0) {
            self.error = { code: 'No asset available', visible: true }
            return
        }
        if (self.assets.length > 1) {
            self.error = null
            return self.pushPage(asset_selector_page, {
                assets: self.assets
            })
        }
        if (self.accounts.length > 1) {
            self.error = null
            return self.pushPage(account_selector_page, {
                accounts: self.accounts,
                asset: self.assets[0].asset
            })
        }
        if (self.accounts.length === 1 && self.assets.length === 1) {
            self.error = null
            return self.pushPage(self.page, {
                account: self.accounts[0],
                asset: self.assets[0].asset,
                input: recipient_field.input,
                recipient: recipient_field.recipient
            })
        }
        self.error = { code: 'unknown error', visible: true }
    }

    id: self
    title: qsTrId('id_recipient')
    rightItem: CloseButton {
        enabled: !self.closeBlocked
        onClicked: self.closeClicked()
    }
    Component.onCompleted: {
        if (self.url && self.url.toString() !== '') {
            self.update(recipient_field.recipient)
        }
    }
    LightningSendController {
        id: lightning_send_controller
        context: self.context
        lightningOnly: self.lightningOnly
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        AlertView {
            Layout.bottomMargin: 15
            alert: AnalyticsAlert {
                screen: 'Send'
                network: self.account?.network.id ?? ''
            }
        }
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_account__asset')
            visible: self.account
        }
        AccountAssetField {
            Layout.fillWidth: true
            id: account_asset_field
            account: self.account
            asset: self.asset
            readonly: true
            visible: self.account
        }
        FieldTitle {
            Layout.topMargin: self.account ? 20 : 0
            text: qsTrId('id_send_to')
        }
        RecipientField {
            id: recipient_field
            text: self.url
            error: self.error?.visible ? self.error.code : null
            onRecipientChanged: self.update(recipient_field.recipient)
        }
        ErrorPane {
            Layout.topMargin: -15
            Layout.bottomMargin: 15
            error: self.error?.visible ? self.error?.code : null
        }
        // FieldTitle {
        //     text: 'ACCOUNTS'
        // }
        // Repeater {
        //     model: self.accounts
        //     delegate: Label {
        //         text: UtilJS.accountName(modelData)
        //     }
        // }
        // FieldTitle {
        //     text: 'ASSETS'
        // }
        // Repeater {
        //     model: self.assets
        //     delegate: Label {
        //         text: modelData.id
        //     }
        // }
        // FieldTitle {
        //     text: 'RECIPIENT'
        // }
        // Label {
        //     Layout.fillWidth: true
        //     Layout.preferredWidth: 0
        //     text: JSON.stringify(recipient_field.recipient, null, 4)
        //     font.pixelSize: 10
        //     wrapMode: Label.WrapAtWordBoundaryOrAnywhere
        // }
        VSpacer {
        }
    }
    footerItem: PrimaryButton {
        enabled: self.error === null
        text: qsTrId('id_next')
        onClicked: {
            self.update(recipient_field.recipient)
        }
    }

    Component {
        id: bolt12_page
        Bolt12Page {
            context: self.context
            onCloseClicked: self.closeClicked()
            onContinueClicked: (properties) => {
                self.pushPage(submarine_swap_page, properties)
            }
        }
    }

    Component {
        id: lnurl_page
        LnurlPage {
            context: self.context
            input: recipient_field.input
            recipient: recipient_field.recipient
            onCloseClicked: self.closeClicked()
            onContinueClicked: (properties) => {
                self.pushPage(submarine_swap_page, properties)
            }
        }
    }

    Component {
        id: bip353_page
        Bip353Page {
            context: self.context
            input: recipient_field.input
            recipient: recipient_field.recipient
            onCloseClicked: self.closeClicked()
            onContinueClicked: (properties) => {
                self.pushPage(submarine_swap_page, properties)
            }
        }
    }

    Component {
        id: submarine_swap_page
        SubmarineSwapPage {
            context: self.context
            fiat: false
            input: recipient_field.input
            recipient: recipient_field.recipient
            unit: self.context.primarySession.unit
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: payment_source_selector_page
        PaymentSourceSelectorPage {
            context: self.context
            onSourceClicked: (source) => {
                self.pushPaymentSource(source)
            }
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: lightning_send_amountless_page
        LightningAmountlessPage {
            context: self.context
            controller: lightning_send_controller
            onNextClicked: self.pushPage(lightning_send_confirm_page)
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: lightning_send_confirm_page
        LightningSendConfirmPage {
            context: self.context
            controller: lightning_send_controller
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: send_page
        SendDetailsPage {
            id: page
            context: self.context
            input: recipient_field.input
            recipient: recipient_field.recipient
            onCloseClicked: self.closeClicked()
        }
    }
    Component {
        id: asset_selector_page
        AssetSelectorPage {
            id: page
            context: self.context
            onAssetClicked: (asset) => {
                const accounts = UtilJS.accounts(self.context).filter(account => (account.json.satoshi[asset.key] ?? 0) !== 0)
                if (accounts.length === 1) {
                    return self.pushPage(self.page, {
                        account: accounts[0],
                        asset: asset,
                        input: recipient_field.input,
                        recipient: recipient_field.recipient
                    })
                }
                if (accounts.length > 1) {
                    return self.pushPage(account_selector_page, {
                        accounts,
                        asset,
                    })
                }
            }
        }
    }
    Component {
        id: account_selector_page
        AccountSelectorPage {
            id: page
            context: self.context
            message: ''
            onAccountClicked: (account) => {
                self.pushPage(self.page, {
                    account,
                    asset: page.asset,
                    input: recipient_field.input,
                    recipient: recipient_field.recipient
                })
            }
            onCloseClicked: self.closeClicked()
        }
    }
}
