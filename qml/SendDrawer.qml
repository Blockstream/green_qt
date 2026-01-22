import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

WalletDrawer {
    property Asset asset
    property url url
    id: self
    objectName: "SendDrawer"
    closePolicy: AbstractDrawer.CloseOnEscape
    minimumContentWidth: 450
    contentItem: GStackView {
        id: stack_view
        initialItem: RecipientPage {
            onCloseClicked: self.close()
        }
    }
    AnalyticsView {
        name: 'Send'
        active: true
        segmentation: AnalyticsJS.segmentationSession(Settings, self.context)
    }
    onClosed: {
        if (self.url && stack_view.currentItem instanceof SendPage) {
            WalletManager.openUrl = self.url
        }
    }

    function selectAccounts(asset) {
        return self.context.accounts.filter(account => !account.hidden && (account.json.satoshi[asset.key] ?? 0) !== 0)
    }

    component RecipientPage: StackViewPage {
        property string address_input
        property list<Account> accounts
        property list<Asset> assets
        property bool nextEnabled: false
        property var error
        function update() {
            const network = controller.networks[0]

            page.accounts = (() => {
                if (!network) {
                    return []
                }
                if (network.liquid && !controller.bip21.assetid) {
                    return self.context.accounts.filter(account => !account.hidden && account.network.liquid)
                }
                return self.selectAccounts(controller.asset)
            })()

            page.assets = (() => {
                const assets = new Map
                for (const account of page.accounts) {
                    if (controller.networks && controller.networks.indexOf(account.network) < 0) continue
                    for (let asset_id in account.json.satoshi) {
                        const satoshi = account.json.satoshi[asset_id]
                        if (satoshi === 0) continue
                        const asset = context.getOrCreateAsset(asset_id)
                        let sum = assets.get(asset)
                        if (sum) {
                            sum.satoshi += satoshi
                        } else {
                            sum = { satoshi, asset }
                            assets.set(asset, sum)
                        }
                    }
                }
                return [...assets.values()].sort((a, b) => {
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

            page.error = (() => {
                if (address_field.text.trim().length === 0) {
                    return null
                }
                if (controller.errors.length > 0) {
                    return controller.errors[0]
                }
                if (page.accounts?.length === 0) {
                    return 'id_no_available_accounts'
                }
                if (network.liquid && !controller.bip21.assetid && page.assets.length === 0) {
                    return 'id_no_available_accounts'
                }
                return null
            })()

            page.nextEnabled = (() => {
                if ((page.accounts?.length ?? 0) === 0) {
                    return false
                }
                if (!network) {
                    return false
                }
                if (network.liquid && !controller.bip21.assetid) {
                    return page.assets.length > 0
                }
                return true
            })()
        }

        function next() {
            const network = controller.networks[0]
            if (!network) return

            if (network.liquid && !controller.bip21.assetid && page.assets.length > 0) {
                stack_view.push(asset_selector_page, {
                    address: controller.address,
                    amount: controller.amount,
                    assets: page.assets,
                    input: page.address_input,
                    networks: controller.networks
                })
            } else {
                if (page.accounts.length > 1) {
                    stack_view.push(account_selector_page, {
                        accounts: page.accounts,
                        address: controller.address,
                        amount: controller.amount,
                        asset: controller.asset,
                        input: page.address_input,
                    })
                } else if (page.accounts.length === 1) {
                    stack_view.push(send_details_page, {
                        account: page.accounts[0],
                        address: controller.address,
                        amount: controller.amount,
                        input: page.address_input,
                        asset: controller.asset,
                    })
                }
            }
        }

        id: page
        title: qsTrId('id_send')
        rightItem: CloseButton {
            onClicked: page.closeClicked()
        }
        footerItem: PrimaryButton {
            enabled: page.nextEnabled
            text: qsTrId('id_next')
            onClicked: page.next()
        }

        contentItem: VFlickable {
            alignment: Qt.AlignTop
            spacing: 5
            FieldTitle {
                Layout.topMargin: 0
                text: qsTrId('id_send_to')
            }
            GTextArea {
                property string previousText: ''
                Layout.fillWidth: true
                Layout.minimumHeight: 200
                id: address_field
                focus: true
                rightPadding: 15
                bottomPadding: 50
                error: page.error
                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottomMargin: 13
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10
                    CircleButton {
                        activeFocusOnTab: false
                        icon.source: 'qrc:/svg2/paste.svg'
                        onClicked: {
                            address_field.clear()
                            address_field.paste()
                        }
                    }
                    CircleButton {
                        activeFocusOnTab: false
                        enabled: scanner_popup.available && !scanner_popup.visible
                        icon.source: 'qrc:/svg2/qrcode.svg'
                        onClicked: scanner_popup.requestPermissionAndOpen()
                        ScannerPopup {
                            id: scanner_popup
                            onCodeScanned: (code) => {
                                page.address_input = 'scan'
                                address_field.text = code
                            }
                        }
                    }
                    HSpacer {
                    }
                    CircleButton {
                        enabled: address_field.text.length > 0
                        activeFocusOnTab: false
                        icon.source: 'qrc:/svg2/x-circle.svg'
                        onClicked: {
                            address_field.clear()
                        }
                    }
                }
                onTextChanged: {
                    page.address_input = address_field.text.length === 0 ? '' : Math.abs(address_field.previousText.length - address_field.text.length) > 1 ? 'paste' : 'type'
                    address_field.previousText = address_field.text
                }
            }
            ErrorPane {
                Layout.topMargin: -20
                error: address_field.error
            }
            AddressValidationController {
                id: controller
                context: self.context
                input: address_field.text.trim()
                onAssetChanged: asset_field.asset = controller.asset
                onUpdated: {
                    page.update()
                    if (page.address_input === 'type') return
                    page.next()
                }
            }
            ColumnLayout {
                Layout.fillHeight: false
                Layout.topMargin: 10
                spacing: 5
                visible: controller.networks.length > 0
                FieldTitle {
                    text: qsTrId('id_asset')
                    visible: asset_field.visible
                }
                AssetField {
                    Layout.fillWidth: true
                    id: asset_field
                    editable: false
                    visible: !controller.networks[0]?.liquid || !!controller.bip21?.assetid
                }
                FieldTitle {
                    text: (controller.networks[0]?.displayName ?? '') + ' ' + qsTrId('id_address')
                }
                AddressLabel {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    address: controller.address
                    padding: 20
                    background: Rectangle {
                        color: '#181818'
                        radius: 5
                    }
                }
                FieldTitle {
                    text: qsTrId('id_amount')
                    visible: amount_field.visible
                }
                AmountField {
                    Layout.fillWidth: true
                    id: amount_field
                    readOnly: true
                    session: self.context.getOrCreateSession(controller.networks[0])
                    visible: Object.keys(controller.amount).length > 0
                    convert: Convert {
                        asset: controller.asset
                        context: self.context
                        input: controller.amount
                        unit: self.context.getOrCreateSession(controller.networks[0])?.unit ?? 'btc'
                    }
                }
            }
            VSpacer {
            }
        }
    }

    Component {
        id: asset_selector_page
        AssetSelectorPage {
            required property string address
            required property var amount
            required property string input
            id: page
            context: self.context
            onAssetClicked: (asset) => {
                const accounts = self.selectAccounts(asset)
                if (accounts.length > 1) {
                    stack_view.push(account_selector_page, {
                        accounts,
                        address: page.address,
                        amount: page.amount,
                        asset,
                        input: page.input,
                    })
                } else if (accounts.length === 1) {
                    stack_view.push(send_details_page, {
                        account: accounts[0],
                        address: page.address,
                        amount: page.amount,
                        input: page.input,
                        asset: asset,
                    })
                }
            }
        }
    }

    Component {
        id: account_selector_page
        AccountSelectorPage {
            required property string address
            required property var amount
            required property string input
            id: page
            context: self.context
            message: ''
            onAccountClicked: (account) => {
                stack_view.push(send_details_page, {
                    account,
                    address: page.address,
                    amount: page.amount,
                    input: page.input,
                    asset: page.asset,
                })
            }
        }
    }

    Component {
        id: send_details_page
        SendDetailsPage {
            context: self.context
            onCloseClicked: self.close()
        }
    }
}
