import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.13
import QtQuick.Controls 2.13
import QtQuick.Layouts 1.13

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
                source: iconFor(wallet)
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
        segmentation: segmentationSession(self.wallet)
    }
}
