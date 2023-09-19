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
    contentItem: ColumnLayout {
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
        SecurityPolicyButton {
            Layout.fillWidth: true
            icon.source: 'qrc:/svg/singleSig.svg'
            type: 'SINGLESIG / LEGACY SEGWIT'
            title: 'Standard'
            description: 'Simple, portable, standard account, secured by your key, the recovery phrase.'
        }
        SecurityPolicyButton {
            Layout.fillWidth: true
            icon.source: 'qrc:/svg/multi-sig.svg'
            type: 'MULTISIG / 2OF2'
            title: '2FA Protected '
            description: 'Quick setup 2FA account, ideal for active spenders (2FA expires if you don\'t move funds every 6 months).'
        }
        VSpacer {
        }
    }
    footer: Pane {
        background: null
        padding: 0
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
