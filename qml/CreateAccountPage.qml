import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "analytics.js" as AnalyticsJS

StackViewPage {
    signal created(account: Account)
    required property Context context
    required property Asset asset
    required property bool editableAsset
    property bool advanced: false
    property bool anyLiquid: false
    property bool anyAMP: false

    component SecurityPolicyButton2: SecurityPolicyButton {
        required property string serverType
        required property string type
        property string networkKey: self.asset?.networkKey ?? (self.context.mainnet ? 'liquid' : 'testnet-liquid')
        id: btn
        network: NetworkManager.networkWithServerType(self.context.deployment, btn.networkKey, btn.serverType)
        action: Action {
            onTriggered: {
                self.pushPage(controller_page, {
                    network: btn.network,
                    type: btn.type,
                })
            }
        }
    }

    component SinglesigButton: SecurityPolicyButton2 {
        serverType: 'electrum'
    }
    component MultisigButton: SecurityPolicyButton2 {
        serverType: 'green'
    }

    id: self
    title: qsTrId('id_create_new_account')
    rightItem: CloseButton {
        onClicked: self.closeClicked()
    }
    contentItem: VFlickable {
        alignment: Qt.AlignTop
        spacing: 5
        FieldTitle {
            Layout.topMargin: 0
            text: qsTrId('id_asset')
        }
        AssetField {
            Layout.fillWidth: true
            id: asset_field
            asset: self.asset
            anyLiquid: self.anyLiquid
            anyAMP: self.anyAMP
            editable: self.editableAsset
            onClicked: {
                if (self.editableAsset) {
                    self.pushPage(asset_selector, {
                        context: self.context,
                        asset: asset_field.asset,
                    })
                }
            }
        }
        FieldTitle {
            text: 'Security Policy'
        }
        SinglesigButton {
            type: 'p2wpkh'
            tag: qsTrId('id_native_segwit')
            title: qsTrId('id_standard')
            description: qsTrId('id_cheaper_singlesig_option')
            visible: self.asset && !self.asset.amp || self.anyLiquid
        }
        SinglesigButton {
            type: 'p2sh-p2wpkh'
            tag: qsTrId('id_legacy_segwit')
            title: qsTrId('id_legacy_segwit')
            description: qsTrId('id_simple_portable_standard')
            visible: !self.anyAMP && !self.asset?.amp && self.advanced
        }
        MultisigButton {
            id: multisig_2of2_button
            type: '2of2'
            tag: qsTrId('id_2of2')
            title: qsTrId('id_2fa_protected')
            description: qsTrId('id_quick_setup_2fa_account_ideal')
            visible: {
                if (!((self.asset && !self.asset.amp || self.anyLiquid) && !self.hasLiquidExpectAMP)) {
                    return false
                }
                if (multisig_2of2_button.network.liquid) {
                    return self.hasMultisigLiquidExceptAMP
                }
                return self.hasMultisigBitcoin
            }
        }
        MultisigButton {
            id: multisig_2of3_button
            type: '2of3'
            tag: qsTrId('id_2of3')
            title: qsTrId('id_2of3_with_2fa')
            description: qsTrId('id_permanent_2fa_account_ideal_for')
            visible: {
                if (!(!self.anyAMP && (self.anyLiquid || self.advanced && self.asset?.networkKey !== 'liquid' && self.asset?.networkKey !== 'testnet-liquid') && !self.asset?.amp)) {
                    return false
                }
                if (multisig_2of3_button.network.liquid) {
                    return self.hasMultisigLiquidExceptAMP
                }
                return self.hasMultisigBitcoin
            }
            action: Action {
                onTriggered: {
                    self.pushPage(select_recovery_key_page, {
                        network: multisig_2of3_button.network,
                        type: multisig_2of3_button.type,
                    })
                }
            }
        }
        MultisigButton {
            id: amp_button
            type: '2of2_no_recovery'
            tag: qsTrId('id_amp')
            title: qsTrId('id_amp')
            description: qsTrId('id_account_for_special_assets')
            visible: {
                if (!self.context.mainnet) return false
                if (!amp_button.network.liquid) return false
                if (!(self.anyLiquid || self.anyAMP || self.asset?.amp || self.advanced && self.asset?.networkKey === 'liquid')) {
                    return false
                }
                return self.hasMultisigLiquidExceptAMP || !self.hasMultisigLiquidAMP
            }
        }
        Label {
            Layout.topMargin: 10
            text: 'AMP Account already exists.'
            visible: {
                if (amp_button.visible) {
                    return false
                }
                if (!amp_button.network.liquid) {
                    return false
                }
                if (!(self.anyAMP || self.asset?.amp)) {
                    return false
                }
                return self.hasMultisigLiquidAMP
            }
        }
        VSpacer {
        }
    }
    readonly property bool hasMultisigBitcoin: self.context.accounts.some(account => !account.network.electrum && !account.network.liquid)
    readonly property bool hasMultisigLiquidExceptAMP: self.context.accounts.some(account => !account.network.electrum && account.network.liquid && !account.amp0 && (account.pointer > 0 || !account.hidden))
    readonly property bool hasMultisigLiquidAMP: self.context.accounts.some(account => !account.network.electrum && account.network.liquid && account.amp0)

    footerItem: RowLayout {
        HSpacer {
        }
        LinkButton {
            text: self.advanced ? qsTrId('id_hide_advanced_options') : qsTrId('id_show_advanced_options')
            onClicked: self.advanced = !self.advanced
            visible: !self.anyAMP && !self.asset?.amp
        }
        HSpacer {
        }
    }

    Component {
        id: controller_page
        StackViewPage {
            required property Network network
            required property string type
            property var mnemonic: []
            property string xpub: ''

            StackView.onActivated: controller.create()

            CreateAccountController {
                id: controller
                context: self.context
                asset: self.asset
                network: page.network
                type: page.type
                recoveryMnemonic: page.mnemonic
                recoveryXpub: page.xpub
                onCreated: (account) => {
                    Analytics.recordEvent('account_create', AnalyticsJS.segmentationSubAccount(Settings, account))
                    self.created(account)
                }
                onFailed: (error) => self.replacePage(error_page, { error })
            }

            TaskPageFactory {
                title: self.title
                monitor: controller.monitor
                target: stack_view
            }

            id: page
            title: self.title
            contentItem: GStackView {
                id: stack_view
                initialItem: ColumnLayout {
                    VSpacer {
                    }
                    BusyIndicator {
                        Layout.alignment: Qt.AlignCenter
                    }
                    VSpacer {
                    }
                }
            }
        }
    }

    Component {
        id: error_page
        ErrorPage {
            title: self.title
        }
    }

    Component {
        id: select_recovery_key_page
        SelectRecoveryKeyPage {
            required property string type
            id: page
            onRecoveryKey: (mnemonic) => {
                self.pushPage(controller_page, {
                    network: page.network,
                    type: page.type,
                    mnemonic,
                })
            }
            onXpub: (xpub) => {
                self.pushPage(controller_page, {
                    network: page.network,
                    type: page.type,
                    xpub,
                })
            }
        }
    }

    Component {
        id: asset_selector
        AssetSelector {
            onAssetClicked: (asset) => {
                self.asset = asset
                self.anyLiquid = false
                self.anyAMP = false
                self.popPage()
            }
            onAnyLiquidClicked: {
                self.asset = null
                self.anyLiquid = true
                self.anyAMP = false
                self.popPage()
            }
            onAnyAMPClicked: {
                self.asset = null
                self.anyLiquid = false
                self.anyAMP = true
                self.popPage()
            }
        }
    }
}
