import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "util.js" as UtilJS

Page {
    required property Context context
    required property Asset asset
    property bool advanced: false

    signal canceled()
    signal selected(account: Account, asset: Asset)
    signal create(asset: Asset)

    CreateAccountController {
        id: controller
        context: self.context
        asset: self.asset
    }

    id: self
    background: null
    header: Pane {
        background: null
        padding: 0
        bottomPadding: 20
        contentItem: RowLayout {
            BackButton {
                Layout.minimumWidth: Math.max(left_item.implicitWidth, right_item.implicitWidth)
                id: left_item
                onClicked: self.canceled()
            }
            HSpacer {
            }
            Label {
                font.family: 'SF Compact Display'
                font.pixelSize: 14
                font.weight: 600
                text: 'Create New Account'
            }
            HSpacer {
            }
            Item {
                Layout.minimumWidth: Math.max(left_item.implicitWidth, right_item.implicitWidth)
                id: right_item
            }
        }
    }

    component SecurityPolicyButton2: SecurityPolicyButton {
        required property string serverType
        Layout.fillWidth: true
        id: btn
        network: NetworkManager.networkWithServerType(self.asset.networkKey, btn.serverType)
    }

    component SinglesigButton: SecurityPolicyButton2 {
        serverType: 'electrum'
    }
    component MultisigButton: SecurityPolicyButton2 {
        serverType: 'green'
    }

    contentItem: Flickable {
        contentHeight: layout.height
        ColumnLayout {
            id: layout
            width: self.contentItem.width
            FieldTitle {
                text: 'Asset'
            }
            AssetField {
                Layout.fillWidth: true
                asset: controller.asset
                editable: false
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
                type: '2of3'
                tag: qsTrId('id_2of3')
                title: qsTrId('id_2of3_with_2fa')
                description: qsTrId('id_permanent_2fa_account_ideal_for')
                visible: self.advanced && self.asset.networkKey !== 'liquid'
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

}
