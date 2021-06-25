import Blockstream.Green 0.1
import Blockstream.Green.Core 0.1
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.12

ItemDelegate {
    id: self

    required property var transaction
    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)

    focusPolicy: Qt.ClickFocus
    hoverEnabled: true
    leftPadding: 0
    rightPadding: 0
    topPadding: 0
    bottomPadding: 0
    background: null

    spacing: 8

    function txType(tx) {
        const memo = tx.memo.trim().replace(/\n/g, ' ')
        const separator = memo === '' ? '' : ' - '
        if (tx.type === 'incoming') {
            if (tx.outputs.length > 0) {
                for (const o of tx.outputs) {
                    if (o.is_relevant) {
                        return qsTrId('id_received') + separator + memo
                    }
                }
            } else {
                return qsTrId('id_received') + separator + memo
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

        Label {
            text: formatDateTime(tx.created_at)
            font.pixelSize: 12
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            opacity: 0.6
        }
        Label {
            Layout.fillWidth: true
            font.pixelSize: 16
            font.styleName: 'Medium'
            text: txType(tx)
            elide: Label.ElideRight
        }
        Label {
            Layout.alignment: Qt.AlignRight
            color: 'white'
            text: transactionStatus(confirmations)
            font.pixelSize: 12
            font.styleName: 'Medium'
            font.capitalization: Font.AllUppercase
            visible: confirmations < (transaction.account.wallet.network.liquid ? 1 : 6)
            topPadding: 4
            bottomPadding: 4
            leftPadding: 12
            rightPadding: 12
            background: Rectangle {
                radius: 4
                color: confirmations === 0 ? '#d2934a' : '#474747'
            }
        }
        Label {
            color: tx.type === 'incoming' ? '#00b45a' : 'white'
            Layout.alignment: Qt.AlignRight
            font.pixelSize: 16
            font.styleName: 'Medium'
            text: {
                if (transaction.amounts.length > 1) return qsTrId('id_multiple_assets')
                const amount = transaction.amounts[0]
                if (amount.asset) return amount.formatAmount(true, transaction.account.wallet.settings.unit, amount.asset.data)
                return amount.formatAmount(true, transaction.account.wallet.settings.unit)
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
                MenuItem {
                    enabled: transaction.account.wallet.network.liquid
                    text: qsTrId('Copy unblinded link')
                    onTriggered: {
                        Clipboard.copy(transaction.unblindedLink())
                        ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
                    }
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
                    onTriggered: bump_fee_dialog.createObject(window, { transaction }).open()
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
