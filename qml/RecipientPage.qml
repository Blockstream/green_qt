import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Account account
    required property Asset asset
    property url url
    property Component page
    property list<Account> accounts
    property var assets
    property var error: null
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
            if (recipient.invoice) {
                if (!self.context.mainnet) {
                    error = 'Not supported in testnet.'
                    return null
                }
                if (self.context.watchonly) {
                    error = 'Not supported in watch-only.'
                    return null
                }
                if (self.context.wallet.login.device) {
                    error = 'Not supported with Hardware Wallet.'
                    return null
                }
                if (Settings.isEventRegistered({ invoice: recipient.input })) {
                    error = 'Invoice already paid.'
                    return null
                }
                if (!recipient.invoice.amount_milli_satoshis) {
                    error = 'Format not supported. Please paste an invoice with an amount.'
                    return null
                }
                network = 'liquid'
                asset_id = NetworkManager.network('liquid').policyAsset
                return submarine_swap_page
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
            return self.StackView.view.push(asset_selector_page, {
                assets: self.assets
            })
        }
        if (self.accounts.length > 1) {
            self.error = null
            return self.StackView.view.push(account_selector_page, {
                accounts: self.accounts,
                asset: self.assets[0].asset
            })
        }
        if (self.accounts.length === 1 && self.assets.length === 1) {
            self.error = null
            return self.StackView.view.push(self.page, {
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
        onClicked: self.closeClicked()
    }
    Component.onCompleted: {
        if (self.url && self.url.toString() !== '') {
            self.update(recipient_field.recipient)
        }
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
                self.StackView.view.push(submarine_swap_page, properties)
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
                self.StackView.view.push(submarine_swap_page, properties)
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
                self.StackView.view.push(submarine_swap_page, properties)
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
                    return self.StackView.view.push(self.page, {
                        account: accounts[0],
                        asset: asset,
                        input: recipient_field.input,
                        recipient: recipient_field.recipient
                    })
                }
                if (accounts.length > 1) {
                    return self.StackView.view.push(account_selector_page, {
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
                self.StackView.view.push(self.page, {
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
