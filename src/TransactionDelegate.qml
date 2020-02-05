import Blockstream.Green 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ItemDelegate {
    property Transaction transaction
    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)

    background.opacity: 0.4
    spacing: 8

    function address(tx) {
        if (tx.type === 'incoming') {
            for (const o of tx.outputs) {
                if (o.is_relevant) {
                    return o.address
                }
            }
        }
        if (tx.type === 'outgoing') {
            return tx.addressees[0]
        }
        if (tx.type === 'redeposit') {
            return qsTr("id_redeposited")
        }
        return JSON.stringify(tx, null, '\t')
    }

    contentItem: RowLayout {
        spacing: 16

        Image {
            source: tx.type === 'incoming' ? 'assets/svg/received.svg' : 'assets/svg/sent.svg'
        }

        ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: formatDateTime(tx.created_at)
                opacity: 0.8
            }

            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                text: address(tx)
            }
        }

        ColumnLayout {
            Label {
                color: tx.type === 'incoming' ? Material.accentColor : Material.foreground
                Layout.alignment: Qt.AlignRight
                text: transaction.amounts.length > 1 ? qsTr('id_multiple_assets') : transaction.amounts[0].formatAmount(wallet.settings.unit)
            }

            Label {
                Layout.alignment: Qt.AlignRight
                color: confirmations === 0 ? 'red' : 'white'
                text: transactionStatus(confirmations)
                visible: confirmations < (wallet.liquid ? 1 : 6)
            }
        }

        ToolButton {
            text: qsTr('⋮')
            onClicked: menu.open()

            Menu {
                id: menu

                MenuItem {
                    text: qsTr('id_view_in_explorer')
                    onTriggered: transaction.openInExplorer()
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_increase_fee')
                }

                MenuSeparator { }

                MenuItem {
                    text: qsTr('id_copy_transaction_id')
                    onTriggered: transaction.copyTxhashToClipboard()
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_copy_details')
                }

                MenuItem {
                    enabled: false
                    text: qsTr('id_copy_raw_transaction')
                }
            }
        }
    }
}
