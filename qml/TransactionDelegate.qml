import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ItemDelegate {
    required property Transaction transaction
    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)

    background.opacity: 0.4
    spacing: 8

    function txType(tx) {
        const memo = tx.memo.trim().replace(/\n/g, ' ')
        const separator = memo === '' ? '' : ' - '
        if (tx.type === 'incoming') {
            for (const o of tx.outputs) {
                if (o.is_relevant) {
                    return qsTrId('id_received') + separator + memo
                }
            }
        }
        if (tx.type === 'outgoing') {
            return qsTrId('id_sent') + separator + memo
        }
        if (tx.type === 'redeposit') {
            return qsTrId("id_redeposited") + separator + memo
        }
        return JSON.stringify(tx, null, '\t')
    }
    Action {
        id: copy_unblinding_data_action
        text: qsTrId('id_copy_unblinding_data')
        onTriggered: copyUnblindingData(tool_button, tx)
    }
    contentItem: RowLayout {
        spacing: 16

        ColumnLayout {
            Label {
                Layout.fillWidth: true
                text: formatDateTime(tx.created_at)
                opacity: 0.8
            }

            Label {
                Layout.fillWidth: true
                font.pixelSize: 14
                text: txType(tx)
                elide: Label.ElideRight
            }
        }

        ColumnLayout {
            Label {
                color: tx.type === 'incoming' ? Material.accentColor : Material.foreground
                Layout.alignment: Qt.AlignRight
                text: transaction.amounts.length > 1 ? qsTrId('id_multiple_assets') : transaction.amounts[0].formatAmount(true, transaction.account.wallet.settings.unit)
            }

            Label {
                Layout.alignment: Qt.AlignRight
                color: confirmations === 0 ? 'red' : 'white'
                text: transactionStatus(confirmations)
                visible: confirmations < (transaction.account.wallet.network.liquid ? 1 : 6)
            }
        }

        ToolButton {
            id: tool_button
            text: qsTrId('⋮')
            onClicked: menu.open()

            Menu {
                id: menu
                MenuItem {
                    text: qsTrId('id_view_in_explorer')
                    onTriggered: transaction.openInExplorer()
                }
                Repeater {
                    model: transaction.account.wallet.network.liquid ? [copy_unblinding_data_action] : []
                    MenuItem {
                        action: modelData
                    }
                }
                MenuItem {
                    enabled: transaction.data.can_rbf
                    text: qsTrId('id_increase_fee')
                    onTriggered: bump_fee_dialog.createObject(tool_button, { transaction }).open()
                }
                MenuSeparator {
                }
                MenuItem {
                    text: qsTrId('id_copy_transaction_id')
                    onTriggered: Clipboard.copy(transaction.data.txhash)
                }
            }
        }
    }
}
