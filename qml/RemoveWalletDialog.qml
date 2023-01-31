import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

AbstractDialog {
    property Wallet wallet

    id: self
    title: qsTrId('id_remove_wallet')
    modal: true
    onAccepted: {
        WalletManager.removeWallet(wallet)
        Analytics.recordEvent('wallet_delete')
    }
    contentItem: ColumnLayout {
        spacing: constants.s1
        SectionLabel {
            text: qsTrId('id_name')
        }
        Label {
            text: wallet.name
        }
        SectionLabel {
            text: qsTrId('id_network')
        }
        RowLayout {
            Layout.fillHeight: false
            spacing: 8
            Image {
                sourceSize.width: 16
                sourceSize.height: 16
                source: UtilJS.iconFor(wallet)
            }
            Label {
                Layout.fillWidth: true
                text: wallet.network.displayName
            }
        }
        SectionLabel {
            text: qsTrId('id_confirm_action')
        }
        GTextField {
            Layout.minimumWidth: 300
            Layout.fillWidth: true
            id: confirm_field
            placeholderText: qsTrId('id_confirm_by_typing_the_wallet')
        }
        Label {
            text: qsTrId('id_backup_your_mnemonic_before')
        }
    }
    footer: DialogFooter {
        HSpacer {
        }
        GButton {
            enabled: confirm_field.text === wallet.name
            destructive: true
            large: true
            text: qsTrId('id_remove')
            onClicked: accept()
        }
    }

    AnalyticsView {
        active: self.opened
        name: 'DeleteWallet'
        segmentation: AnalyticsJS.segmentationSession(self.wallet)
    }
}
