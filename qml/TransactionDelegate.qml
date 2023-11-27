import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ItemDelegate {
    signal transactionClicked(Transaction transaction)
    required property Transaction transaction
    required property Account account
    required property Context context

    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)
    readonly property var spv: {
        const liquid = transaction.account.network.liquid
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

    onClicked: self.transactionClicked(transaction)

    id: self
    focusPolicy: Qt.ClickFocus
    hoverEnabled: true
    topPadding: 16
    leftPadding: 16
    rightPadding: 16
    bottomPadding: 16

    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#FFFFFF'
            opacity: 0.1
            width: parent.width
            height: 1
            y: parent.height - 1
        }
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
            return qsTrId('id_redeposited') + separator + memo
        }
        if (transaction.type === Transaction.Mixed) {
            return qsTrId('id_swap') + separator + memo
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
            text: UtilJS.formatTransactionTimestamp(tx)
            font.pixelSize: 12
            font.capitalization: Font.AllUppercase
            font.styleName: 'Regular'
            opacity: 0.6
        }
        Label {
            Layout.fillWidth: true
            Layout.maximumWidth: self.width * 0.3
            font.pixelSize: 14
            font.styleName: 'Medium'
            text: txType(tx)
            elide: Label.ElideRight
        }
        HSpacer {
        }
        TransactionStatusBadge {
            transaction: self.transaction
            confirmations: self.confirmations
            visible: confirmations < (transaction.account.network.liquid ? 1 : 6)
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
        ColumnLayout {
            spacing: constants.s1
            Layout.fillWidth: false
            Repeater {
                model: Object.entries(transaction.data.satoshi)
                Label {
                    visible: {
                        const network = transaction.account.network
                        const [id, amount] = modelData
                        if (network.liquid && transaction.type === Transaction.Outgoing && id === network.policyAsset && amount === -transaction.data.fee) return false
                        return true
                    }
                    Layout.alignment: Qt.AlignRight
                    color: modelData[1] > 0 ? '#00b45a' : 'white'
                    font.pixelSize: 14
                    font.styleName: 'Medium'
                    text: {
                        const account = self.transaction.account
                        const network = account.network
                        const [id, amount] = modelData
                        if (network.liquid) {
                            return self.context.getOrCreateAsset(id).formatAmount(amount, true)
                        } else {
                            return formatAmount(account, amount)
                        }
                    }
                }
            }
        }
        /*
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
                            enabled: transaction.account.network.liquid
                            text: qsTrId('id_copy_unblinded_link')
                            onTriggered: {
                                Clipboard.copy(transaction.unblindedLink())
                                ToolTip.show(qsTrId('id_copied_to_clipboard'), 1000)
                            }
                        }
                        Repeater {
                            model: transaction.account.network.liquid ? [copy_unblinding_data_action] : []
                            MenuItem {
                                action: modelData
                            }
                        }
                        MenuItem {
                            enabled: transaction.data.can_rbf && !self.context.watchonly
                            text: qsTrId('id_increase_fee')
                            onTriggered: bump_fee_dialog.createObject(window, { transaction }).open()
                        }
                        MenuSeparator {
                        }
                        MenuItem {
                            text: qsTrId('id_copy_transaction_id')
                            onTriggered: {
                                Clipboard.copy(transaction.data.txhash)
                                Analytics.recordEvent('share_transaction', AnalyticsJS.segmentationShareTransaction(transaction.account))
                            }
                        }
                    }
                }
            }
        }
        */
    }
}
