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
    readonly property var spv: {
        const liquid = transaction.account.wallet.network.liquid
        const unconfirmed = (liquid && confirmations < 2) || (!liquid && confirmations < 6)
        if (unconfirmed) return null
        switch (transaction.spv) {
        case Transaction.Disabled:
        case Transaction.Unconfirmed:
        case Transaction.Verified:
            return null
        case Transaction.NotVerified:
            return { icon: 'qrc:/svg/tx-spv-not-verified.svg', text: qsTrId('id_invalid_merkle_proof') }
        case Transaction.NotLongest:
            return { icon: 'qrc:/svg/tx-spv-not-longest.svg', text: qsTrId('id_not_on_longest_chain') }
        case Transaction.InProgress:
            return { icon: 'qrc:/svg/tx-spv-in-progress.svg', text: qsTrId('id_verifying_transactions') }
        }
    }

    focusPolicy: Qt.ClickFocus
    hoverEnabled: true
    padding: constants.p3
    rightPadding: constants.p3 - constants.s1

    background: Rectangle {
        color: self.hovered ? constants.c700 : constants.c800
        radius: 4
        border.width: self.highlighted ? 1 : 0
        border.color: constants.g500
    }
    spacing: 8

    function txType(tx) {
        const memo = transaction.memo.trim().replace(/\n/g, ' ')
        const separator = memo === '' ? '' : ' - '
        if (transaction.type === Transaction.Incoming) {
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
        if (transaction.type === Transaction.Outgoing) {
            return qsTrId('id_sent') + separator + memo
        }
        if (transaction.type === Transaction.Redeposit) {
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
        spacing: constants.s1

        Label {
            text: formatTransactionTimestamp(tx)
            font.pixelSize: 12
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            opacity: 0.6
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: self.width * 0.3
            font.pixelSize: 16
            font.styleName: 'Medium'
            text: txType(tx)
            elide: Label.ElideRight
        }
        HSpacer {
        }
        TransactionStatusBadge {
            transaction: self.transaction
            confirmations: self.confirmations
            visible: confirmations < (transaction.account.wallet.network.liquid ? 1 : 6)
        }
        Loader {
            active: spv
            visible: active
            sourceComponent: Image {
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                source: spv.icon
                sourceSize.height: 24
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: Math.max(contentWidth, self.width / 5)
            Layout.minimumWidth: contentWidth
            color: transaction.type === Transaction.Incoming ? '#00b45a' : 'white'
            horizontalAlignment: Qt.AlignRight
            font.pixelSize: 16
            font.styleName: 'Medium'
            text: {
                if (transaction.amounts.length === 1) {
                    wallet.displayUnit
                    return transaction.amounts[0].formatAmount(true)
                } else {
                    return qsTrId('id_multiple_assets')
                }
            }
        }
        Item {
            implicitWidth: self.hovered || menu.visible ? actions_layout.width : 0
            Behavior on implicitWidth {
                SmoothedAnimation {
                    velocity: 400
                }
            }
            implicitHeight: actions_layout.height
            clip: true
            RowLayout {
                id: actions_layout
                spacing: constants.s0
                GToolButton {
                    icon.source: 'qrc:/svg/external_link.svg'
                    onClicked: transaction.openInExplorer()
                }
                GToolButton {
                    id: tool_button
                    icon.source: 'qrc:/svg/kebab.svg'
                    onClicked: menu.open()

                    Menu {
                        id: menu
                        MenuItem {
                            text: qsTrId('id_view_in_explorer')
                            onTriggered: transaction.openInExplorer()
                        }
                        MenuItem {
                            enabled: transaction.account.wallet.network.liquid
                            text: qsTrId('id_copy_unblinded_link')
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
                            enabled: transaction.data.can_rbf && !transaction.account.wallet.watchOnly
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
    }
}
