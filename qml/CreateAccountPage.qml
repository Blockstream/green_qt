import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import "util.js" as UtilJS

StackViewPage {
    required property Context context
    required property Asset asset
    required property bool editableAsset
    property bool advanced: false

    signal created(account: Account)

    id: self
    title: qsTrId('id_create_new_account')

    component SecurityPolicyButton2: SecurityPolicyButton {
        required property string serverType
        required property string type
        id: btn
        network: NetworkManager.networkWithServerType(self.asset.networkKey, btn.serverType)
        action: Action {
            onTriggered: {
                self.StackView.view.push(controller_page, {
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

    component LightningButton: SecurityPolicyButton {
        beta: true
        description: 'Fast transactions on the Lightning Network, powered by Greenlight.'
        icon.source: 'qrc:/svg2/lightning.svg'
        network: null
        tag: 'fastest'
        tagColor: '#D8A800'
        text: 'lightning'
        title: qsTrId('id_lightning')
        visible: Settings.enableExperimental
        action: Action {
            onTriggered: {
                self.StackView.view.push(lightning_page);
            }
        }
    }

    contentItem: Flickable {
        clip: true
        contentHeight: layout.height
        ScrollIndicator.vertical: ScrollIndicator {
        }
        ColumnLayout {
            id: layout
            width: self.contentItem.width
            FieldTitle {
                text: 'Asset'
            }
            AssetField {
                Layout.fillWidth: true
                id: asset_field
                asset: self.asset
                editable: self.editableAsset
                onClicked: {
                    if (self.editableAsset) {
                        self.StackView.view.push(asset_selector, { asset: asset_field.asset })
                    }
                }
            }
            FieldTitle {
                Layout.topMargin: 15
                text: 'Security Policy'
            }
            SinglesigButton {
                type: 'p2wpkh'
                tag: qsTrId('id_native_segwit')
                title: qsTrId('id_standard')
                description: qsTrId('id_cheaper_singlesig_option')
            }
            LightningButton {
            }
            SinglesigButton {
                type: 'p2sh-p2wpkh'
                tag: qsTrId('id_legacy_segwit')
                title: qsTrId('id_legacy_segwit')
                description: qsTrId('id_simple_portable_standard')
                visible: self.advanced
            }
            MultisigButton {
                type: '2of2'
                tag: qsTrId('id_2of2')
                title: qsTrId('id_2fa_protected')
                description: qsTrId('id_quick_setup_2fa_account_ideal')
            }
            MultisigButton {
                id: multisig_2of3_button
                type: '2of3'
                tag: qsTrId('id_2of3')
                title: qsTrId('id_2of3_with_2fa')
                description: qsTrId('id_permanent_2fa_account_ideal_for')
                visible: self.advanced && self.asset.networkKey !== 'liquid'
                action: Action {
                    onTriggered: {
                        self.StackView.view.push(select_recovery_key_page, {
                            network: multisig_2of3_button.network,
                            type: multisig_2of3_button.type,
                        })
                    }
                }
            }
            MultisigButton {
                type: '2of2_no_recovery'
                tag: qsTrId('id_amp')
                title: qsTrId('id_amp')
                description: qsTrId('id_account_for_special_assets')
                visible: self.advanced && self.asset.networkKey === 'liquid'
            }
        }
    }
    footer: Pane {
        background: null
        padding: 0
        topPadding: 20
        bottomPadding: 20
        contentItem: RowLayout {
            HSpacer {
            }
            LinkButton {
                text: self.advanced ? qsTrId('id_hide_advanced_options') : qsTrId('id_show_advanced_options')
                onClicked: self.advanced = !self.advanced
            }
            HSpacer {
            }
        }
    }

    Component {
        id: controller_page
        Page {
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
                onCreated: (account) => self.created(account)
            }

            id: page
            background: null
            header: null
            contentItem: ColumnLayout {
                BusyIndicator {
                    Layout.alignment: Qt.AlignCenter
                }
                TaskDispatcherInspector {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    dispatcher: controller.dispatcher
                }
            }
        }
    }

    Component {
        id: lightning_page
        StackViewPage {
            title: qsTrId('id_lightning')
            contentItem: ColumnLayout {
                spacing: 40
                VSpacer {
                }
                RowLayout {
                    Layout.alignment: Qt.AlignCenter
                    Layout.fillWidth: false
                    spacing: 8
                    Label {
                        color: '#FFF'
                        font.family: 'SF Compact Display'
                        font.pixelSize: 16
                        font.weight: 600
                        text: qsTrId('id_lightning')
                    }
                    Image {
                        source: 'qrc:/svg2/lightning.svg'
                    }
                }
                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    color: '#FFF'
                    font.family: 'SF Compact Display'
                    font.pixelSize: 14
                    font.weight: 400
                    horizontalAlignment: Qt.AlignCenter
                    text: `This feature is coming soon on desktop, but it's already available on Green mobile now!`
                    wrapMode: Label.WordWrap
                }
                LinkButton {
                    Layout.alignment: Qt.AlignCenter
                    text: 'https://blockstream.com/green'
                    onClicked: Qt.openUrlExternally('https://blockstream.com/green')
                }
                VSpacer {
                }
            }
        }
    }

    Component {
        id: select_recovery_key_page
        SelectRecoveryKeyPage {
            required property Network network
            required property string type
            id: page
            onRecoveryKey: (mnemonic) => {
                self.StackView.view.push(controller_page, {
                    network: page.network,
                    type: page.type,
                    mnemonic,
                })
            }
            onXpub: (xpub) => {
                self.StackView.view.push(controller_page, {
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
            onSelected: (asset) => {
                self.asset = asset
                self.StackView.view.pop()
            }
        }
    }
}
